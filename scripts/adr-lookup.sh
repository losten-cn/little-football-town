#!/usr/bin/env bash
# adr-lookup.sh — Resolve an ADR slug + section identifier to a Read offset/limit.
#
# Part of the ADR-corpus-compression workstream (see
# production/proposals/2026-05-19-adr-corpus-compression.md). Queries
# docs/architecture/_anchors.json — built by tools/dev/adr-summary.sh — to
# turn a human-readable section reference into exact Read parameters. Pairs
# with tools/dev/partial-read-helper.sh (which is pattern-based; this one is
# heading-based). Direct port of tools/dev/gdd-lookup.sh.
#
# Usage:
#   tools/dev/adr-lookup.sh <slug> <section>
#   tools/dev/adr-lookup.sh <slug> <section> --emit-read
#   tools/dev/adr-lookup.sh <slug> --list
#   tools/dev/adr-lookup.sh --help
#
# Slug match:
#   - 4-digit zero-padded: 0017, adr-0017, ADR-0017 — all match adr-0017
#   - Short form: 17 — matches adr-0017 (zero-pads to 4 digits)
#
# Section matching:
#   - Exact: "§Decision" — match a §-heading verbatim
#   - Prefix: "§Imp" or "Imp" — matches first section whose heading starts here
#   - Fuzzy: "decision" — case-insensitive substring against headings
#   The leading "§" is optional in input; the JSON always stores it.
#
# Examples:
#   adr-lookup.sh 0017 "§Decision"
#   adr-lookup.sh 17 "decision"             # short slug, fuzzy section
#   adr-lookup.sh adr-0017 "implementation" # alternate slug forms
#   adr-lookup.sh 0017 "decision" --emit-read   # prints the Read tool call
#   adr-lookup.sh 0017 --list               # list all H2 anchors for the ADR
#
# Output (default):
#   FILE=docs/architecture/adr-0017-some-decision-slug.md
#   SECTION=§Decision
#   OFFSET=74
#   LIMIT=215
#   LINE_END=288
#
# Output (--emit-read):
#   Read("docs/architecture/adr-0017-some-decision-slug.md", offset=74, limit=215)
#
# Exit codes:
#   0  success
#   1  user error (bad args)
#   2  missing required file (anchors.json, ADR)
#   3  no match (slug or section not found)
#   4  ambiguous fuzzy match (more than one section matched substring)

set -uo pipefail

ANCHORS_FILE="docs/architecture/_anchors.json"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

show_help() { sed -n '2,/^$/p' "$0" | sed 's/^# \?//'; exit 0; }

# Normalise slug input to canonical "adr-NNNN" form.
# Accepts: 17, 0017, adr-17, adr-0017, ADR-0017, ADR-17.
canonicalise_slug() {
    local raw="$1"
    # Strip optional "ADR-" or "adr-" prefix
    local n="${raw#[Aa][Dd][Rr]-}"
    # Validate it's all digits
    if ! [[ "$n" =~ ^[0-9]+$ ]]; then
        echo ""
        return
    fi
    # Strip leading zeros (else printf %d treats as octal: 0017 → 15 dec)
    n=$((10#$n))
    # Zero-pad to 4 digits
    printf "adr-%04d\n" "$n"
}

# Locate the anchors entry for a slug. Returns the JSON object as a single line
# on stdout, or empty if not found.
find_file_entry() {
    local slug="$1"
    jq -e --arg s "$slug" '
        .files
        | to_entries
        | map(select(.value.slug == $s or .key == $s))
        | if length == 0 then null
          elif length > 1 then error("ambiguous slug")
          else .[0]
          end
    ' "$ANCHORS_FILE" 2>/dev/null
}

# Given a file-entry JSON and a query, return the matched section object or empty.
# Strategy: exact heading first, then prefix, then fuzzy substring.
match_section() {
    local file_entry="$1"
    local query="$2"
    # Normalise: strip leading § from the query for prefix/fuzzy passes
    local q_strip="${query#§}"
    local q_lower
    q_lower=$(echo "$q_strip" | tr '[:upper:]' '[:lower:]')

    # Pass 1 — exact match (with or without leading §)
    local exact
    exact=$(echo "$file_entry" | jq -e --arg q "$query" '.value.sections[$q] // empty' 2>/dev/null)
    if [[ -n "$exact" ]]; then
        echo "$file_entry" | jq -e --arg q "$query" '{heading: $q, range: .value.sections[$q]}'
        return 0
    fi
    exact=$(echo "$file_entry" | jq -e --arg q "§$q_strip" '.value.sections[$q] // empty' 2>/dev/null)
    if [[ -n "$exact" ]]; then
        echo "$file_entry" | jq -e --arg q "§$q_strip" '{heading: $q, range: .value.sections[$q]}'
        return 0
    fi

    # Pass 2 — prefix match (heading starts with "§<q_strip>" or "§<q_strip> ")
    local prefix_matches
    prefix_matches=$(echo "$file_entry" | jq --arg p "§$q_strip" '
        .value.sections
        | to_entries
        | map(select(.key == $p or (.key | startswith($p + " ")) or (.key | startswith($p + "."))))
    ')
    local prefix_count
    prefix_count=$(echo "$prefix_matches" | jq 'length')
    if (( prefix_count == 1 )); then
        echo "$prefix_matches" | jq '.[0] | {heading: .key, range: .value}'
        return 0
    elif (( prefix_count > 1 )); then
        # Prefer the shortest heading
        echo "$prefix_matches" | jq 'sort_by(.key | length) | .[0] | {heading: .key, range: .value}'
        return 0
    fi

    # Pass 3 — fuzzy substring (case-insensitive)
    local fuzzy_matches
    fuzzy_matches=$(echo "$file_entry" | jq --arg q "$q_lower" '
        .value.sections
        | to_entries
        | map(select((.key | ascii_downcase) | contains($q)))
    ')
    local fuzzy_count
    fuzzy_count=$(echo "$fuzzy_matches" | jq 'length')
    if (( fuzzy_count == 1 )); then
        echo "$fuzzy_matches" | jq '.[0] | {heading: .key, range: .value}'
        return 0
    elif (( fuzzy_count > 1 )); then
        echo "AMBIGUOUS: fuzzy query '$query' matched $fuzzy_count sections:" >&2
        echo "$fuzzy_matches" | jq -r '.[] | "  " + .key' >&2
        exit 4
    fi
    return 1
}

# --list mode
list_sections() {
    local slug="$1"
    local file_entry
    file_entry=$(find_file_entry "$slug")
    [[ -z "$file_entry" || "$file_entry" == "null" ]] && die "no ADR matches slug '$slug'" 3
    local path total
    path=$(echo "$file_entry" | jq -r '.value.path')
    total=$(echo "$file_entry" | jq -r '.value.total_lines')
    echo "FILE=$path"
    echo "TOTAL_LINES=$total"
    echo "--- sections (sorted by line_start) ---"
    echo "$file_entry" | jq -r '
        .value.sections
        | to_entries
        | sort_by(.value.line_start)
        | map("  L\(.value.line_start)-L\(.value.line_end) (\(.value.line_count) lines)  \(.key)")
        | .[]
    '
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------

[[ $# -eq 0 ]] && show_help

case "$1" in
    --help|-h) show_help ;;
esac

[[ ! -f "$ANCHORS_FILE" ]] && die "$ANCHORS_FILE not found — run tools/dev/adr-summary.sh --all first" 2

raw_slug="$1"
shift

slug=$(canonicalise_slug "$raw_slug")
[[ -z "$slug" ]] && die "invalid slug '$raw_slug' (expected ADR number like 0017, 17, or adr-0017)" 1

if [[ $# -gt 0 && "$1" == "--list" ]]; then
    list_sections "$slug"
    exit 0
fi

[[ $# -lt 1 ]] && die "missing section argument (try '$0 $raw_slug --list')" 1

section="$1"
shift
emit_read=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --emit-read) emit_read=1; shift ;;
        *) die "unknown flag '$1'" 1 ;;
    esac
done

file_entry=$(find_file_entry "$slug")
if [[ -z "$file_entry" || "$file_entry" == "null" ]]; then
    die "no ADR matches slug '$slug' (canonical form of '$raw_slug')" 3
fi

match=$(match_section "$file_entry" "$section") || true
if [[ -z "$match" ]]; then
    die "no section matched '$section' in slug '$slug' (try '$0 $raw_slug --list')" 3
fi

path=$(echo "$file_entry" | jq -r '.value.path')
heading=$(echo "$match" | jq -r '.heading')
line_start=$(echo "$match" | jq -r '.range.line_start')
line_end=$(echo "$match" | jq -r '.range.line_end')
line_count=$(echo "$match" | jq -r '.range.line_count')

if (( emit_read )); then
    echo "Read(\"$path\", offset=$line_start, limit=$line_count)"
else
    echo "FILE=$path"
    echo "SECTION=$heading"
    echo "OFFSET=$line_start"
    echo "LIMIT=$line_count"
    echo "LINE_END=$line_end"
fi
