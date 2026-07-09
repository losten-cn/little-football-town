#!/usr/bin/env bash
# registry-lookup.sh — Resolve a registry entry name to a Read offset/limit.
#
# Sibling of gdd-lookup.sh. Reads design/registry/_summary/anchors.json
# (built by registry-summary.sh) to turn an entry name into exact Read params.
#
# Usage:
#   tools/dev/registry-lookup.sh <name>
#   tools/dev/registry-lookup.sh <name> --emit-read
#   tools/dev/registry-lookup.sh --list [<section>]
#   tools/dev/registry-lookup.sh --help
#
# Match strategy: exact name first, then case-insensitive substring (must
# match exactly one entry to succeed; ambiguity is an error).
#
# Output (default):
#   FILE=design/registry/entities.yaml
#   NAME=sim_tick_rate_hz
#   SECTION=constants
#   SOURCE=design/gdd/a1-engine-architecture.md
#   N_REFS=4
#   STATUS=active
#   OFFSET=1713
#   LIMIT=15
#   LINE_END=1727
#
# Output (--emit-read):
#   Read("design/registry/entities.yaml", offset=1713, limit=15)
#
# Exit codes:
#   0 success
#   1 user error
#   2 missing anchors file
#   3 no match
#   4 ambiguous fuzzy match

set -uo pipefail

ANCHORS="design/registry/_summary/anchors.json"
REGISTRY="design/registry/entities.yaml"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }
show_help() { sed -n '2,/^$/p' "$0" | sed 's/^# \?//'; exit 0; }

[[ $# -eq 0 ]] && show_help
case "$1" in --help|-h) show_help ;; esac

[[ ! -f "$ANCHORS" ]] && die "$ANCHORS not found — run tools/dev/registry-summary.sh first" 2

if [[ "$1" == "--list" ]]; then
    section="${2:-}"
    if [[ -n "$section" ]]; then
        jq -r --arg s "$section" '
            .entries
            | to_entries
            | map(select(.value.section == $s))
            | sort_by(.value.line_start)
            | map("  L\(.value.line_start)-L\(.value.line_end) (\(.value.line_count)L) \(.key)  [src=\(.value.source) refs=\(.value.n_refs) status=\(.value.status)]")
            | .[]
        ' "$ANCHORS"
    else
        jq -r '
            .entries
            | to_entries
            | sort_by(.value.line_start)
            | map("  L\(.value.line_start)-L\(.value.line_end) (\(.value.line_count)L) [\(.value.section)] \(.key)")
            | .[]
        ' "$ANCHORS"
    fi
    exit 0
fi

name="$1"
shift
emit_read=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --emit-read) emit_read=1; shift ;;
        *) die "unknown flag '$1'" 1 ;;
    esac
done

# Pass 1: exact match
entry=$(jq --arg n "$name" '.entries[$n] // empty' "$ANCHORS")
matched_name="$name"

# Pass 2: case-insensitive substring (must be exactly 1 match)
if [[ -z "$entry" ]]; then
    matches=$(jq -r --arg q "$(echo "$name" | tr '[:upper:]' '[:lower:]')" '
        .entries
        | to_entries
        | map(select((.key | ascii_downcase) | contains($q)))
        | map(.key)
        | .[]
    ' "$ANCHORS")
    count=$(echo "$matches" | grep -c . || true)
    if (( count == 0 )); then
        die "no entry matches '$name' (try --list)" 3
    elif (( count > 1 )); then
        echo "AMBIGUOUS: '$name' matched $count entries:" >&2
        echo "$matches" | sed 's/^/  /' >&2
        exit 4
    fi
    matched_name="$matches"
    entry=$(jq --arg n "$matched_name" '.entries[$n]' "$ANCHORS")
fi

section=$(echo "$entry" | jq -r '.section')
src=$(echo "$entry" | jq -r '.source')
refs=$(echo "$entry" | jq -r '.n_refs')
status=$(echo "$entry" | jq -r '.status')
line_start=$(echo "$entry" | jq -r '.line_start')
line_end=$(echo "$entry" | jq -r '.line_end')
line_count=$(echo "$entry" | jq -r '.line_count')

if (( emit_read )); then
    echo "Read(\"$REGISTRY\", offset=$line_start, limit=$line_count)"
else
    echo "FILE=$REGISTRY"
    echo "NAME=$matched_name"
    echo "SECTION=$section"
    echo "SOURCE=$src"
    echo "N_REFS=$refs"
    echo "STATUS=$status"
    echo "OFFSET=$line_start"
    echo "LIMIT=$line_count"
    echo "LINE_END=$line_end"
fi
