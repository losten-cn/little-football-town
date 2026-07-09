#!/usr/bin/env bash
# gdd-lookup.sh — Resolve a GDD slug + section identifier to a Read offset/limit.
#
# Part of the corpus-compression workstream (see
# production/proposals/2026-05-13-gdd-corpus-compression.md). Queries
# design/gdd/_anchors.json — built by tools/dev/gdd-summary.sh — to turn a
# human-readable section reference into exact Read parameters. Pairs with
# tools/dev/partial-read-helper.sh (which is pattern-based; this one is
# heading-based).
#
# Usage:
#   tools/dev/gdd-lookup.sh <slug> <section>
#   tools/dev/gdd-lookup.sh <slug> <section> --emit-read
#   tools/dev/gdd-lookup.sh <slug> --list
#   tools/dev/gdd-lookup.sh --help
#
# Section matching:
#   - Exact: "§F.2 Global Strain Pressure (GSP)" — match a §-heading verbatim
#   - Prefix: "§F.2" or "F.2" — matches first section whose heading starts here
#   - Fuzzy: "global strain" — case-insensitive substring against headings
#   The leading "§" is optional in input; the JSON always stores it.
#
# Examples:
#   gdd-lookup.sh b4 "§F.2"
#   gdd-lookup.sh b4 "F.2"                  # leading § optional
#   gdd-lookup.sh b4 "global strain"        # fuzzy substring (case-insensitive)
#   gdd-lookup.sh b4 "§F.2" --emit-read     # prints the Read tool call
#   gdd-lookup.sh b4 --list                 # list all H2+H3 anchors for the GDD
#
# Output (default):
#   FILE=design/gdd/b4-strain-failure-system.md
#   SECTION=§F.2 Global Strain Pressure (GSP)
#   OFFSET=722
#   LIMIT=34
#   LINE_END=755
#
# Output (--emit-read):
#   Read("design/gdd/b4-strain-failure-system.md", offset=722, limit=34)
#
# Exit codes:
#   0  success
#   1  user error (bad args)
#   2  missing required file (anchors.json, GDD)
#   3  no match (slug or section not found)
#   4  ambiguous fuzzy match (more than one section matched substring)

set -uo pipefail

ANCHORS_FILE="design/gdd/_anchors.json"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

show_help() { sed -n '2,/^$/p' "$0" | sed 's/^# \?//'; exit 0; }

# Locate the anchors entry for a slug. Returns the JSON object as a single line
# on stdout. Slug may match the .slug field directly, or be a fuzzy prefix.
find_file_entry() {
    local slug="$1"
    jq -e --arg s "$slug" '
        .files
        | to_entries
        | map(select(.value.slug == $s or (.key | startswith($s + ".")) or (.key | startswith($s + "-"))))
        | if length == 0 then null
          elif length > 1 then error("ambiguous slug")
          else .[0]
          end
    ' "$ANCHORS_FILE" 2>/dev/null
}

# Given a file-entry JSON and a query, return the matched section object or null.
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
        # Prefer the shortest heading (most likely the parent, e.g. "§F.2" over "§F.2.3")
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
    [[ -z "$file_entry" || "$file_entry" == "null" ]] && die "no GDD matches slug '$slug'" 3
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

[[ ! -f "$ANCHORS_FILE" ]] && die "$ANCHORS_FILE not found — run tools/dev/gdd-summary.sh --all first" 2

slug="$1"
shift

if [[ $# -gt 0 && "$1" == "--list" ]]; then
    list_sections "$slug"
    exit 0
fi

[[ $# -lt 1 ]] && die "missing section argument (try '$0 $slug --list')" 1

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
    die "no GDD matches slug '$slug' (try $0 without a slug to see options)" 3
fi

match=$(match_section "$file_entry" "$section") || true
if [[ -z "$match" ]]; then
    die "no section matched '$section' in slug '$slug' (try '$0 $slug --list')" 3
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
