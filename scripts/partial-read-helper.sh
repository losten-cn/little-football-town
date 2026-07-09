#!/usr/bin/env bash
# partial-read-helper.sh — locate lines in a large file and emit suggested
# Read --offset --limit ranges, so Claude can satisfy the harness "Edit must Read"
# rule with a tiny partial Read instead of a full-file Read.
#
# The harness check is satisfied by ANY prior Read of a file — full or partial.
# For known-large files (production/deferred-items.md, sprint-N.md, design docs),
# a full Read can spend 40k+ tokens; a 5-line partial Read costs ~200. This script
# takes a file + a grep pattern and outputs line ranges suitable for partial Reads,
# plus the matching content so the caller can confirm it has the right anchor
# before issuing the Edit.
#
# Usage:
#   tools/dev/partial-read-helper.sh <file> <pattern>
#   tools/dev/partial-read-helper.sh production/deferred-items.md "OPEN-078"
#   tools/dev/partial-read-helper.sh production/sprints/sprint-N.md "SPR-N-035" --context 1
#   tools/dev/partial-read-helper.sh design/gdd/some-doc.md "SectionAnchor" --max 3
#
# Options:
#   --context N    lines of surrounding context per match (default 2)
#   --max N        max matches to emit (default 5; use 0 for unlimited)
#   --ere          treat pattern as ERE (default is fixed-string grep -F)
#
# Output (stdout, structured):
#   FILE=<path>
#   PATTERN=<pattern>
#   FILE_LINES=<total line count>
#   MATCH_COUNT=<n>          (count BEFORE --max truncation)
#   EMITTED=<n>              (count actually shown after --max)
#   --- MATCHES ---
#   MATCH=1 LINE=L OFFSET=O LIMIT=W
#   <line L-context>:<text>
#   <...>:<text>
#   <line L+context>:<text>
#   ---
#   MATCH=2 LINE=L OFFSET=O LIMIT=W
#   ...
#
# OFFSET/LIMIT match the Claude Code Read tool's parameters exactly:
#   Read("<path>", offset=O, limit=W)
# After issuing that partial Read, the harness allows Edit on <path>.
#
# Exit codes:
#   0 — at least one match found (or 0 matches with valid args)
#   1 — usage / file-not-found / argument error

set -euo pipefail

FILE=""
PATTERN=""
CONTEXT=2
MAX_MATCHES=5
USE_ERE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context) CONTEXT="$2"; shift 2 ;;
    --max) MAX_MATCHES="$2"; shift 2 ;;
    --ere) USE_ERE=true; shift ;;
    -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
    *)
      if [[ -z "$FILE" ]]; then FILE="$1"; shift
      elif [[ -z "$PATTERN" ]]; then PATTERN="$1"; shift
      else echo "ERROR: unexpected arg: $1" >&2; exit 1
      fi ;;
  esac
done

if [[ -z "$FILE" || -z "$PATTERN" ]]; then
  echo "usage: tools/dev/partial-read-helper.sh <file> <pattern> [--context N] [--max N] [--ere]" >&2
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: file not found: $FILE" >&2
  exit 1
fi

if ! [[ "$CONTEXT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --context must be a non-negative integer (got: $CONTEXT)" >&2
  exit 1
fi
if ! [[ "$MAX_MATCHES" =~ ^[0-9]+$ ]]; then
  echo "ERROR: --max must be a non-negative integer (got: $MAX_MATCHES)" >&2
  exit 1
fi

FILE_LINES=$(wc -l < "$FILE")

# Find matching line numbers. -F (fixed string) is the safe default; -E for ERE.
GREP_FLAGS="-nF"
if [[ "$USE_ERE" == true ]]; then GREP_FLAGS="-nE"; fi

set +o pipefail
mapfile -t LINE_NUMS < <(grep $GREP_FLAGS "$PATTERN" "$FILE" 2>/dev/null | cut -d: -f1)
set -o pipefail

MATCH_COUNT=${#LINE_NUMS[@]}

# Apply --max truncation (0 = unlimited).
EMITTED=$MATCH_COUNT
if [[ "$MAX_MATCHES" -gt 0 && "$MATCH_COUNT" -gt "$MAX_MATCHES" ]]; then
  EMITTED=$MAX_MATCHES
fi

echo "FILE=$FILE"
echo "PATTERN=$PATTERN"
echo "FILE_LINES=$FILE_LINES"
echo "MATCH_COUNT=$MATCH_COUNT"
echo "EMITTED=$EMITTED"

if [[ "$MATCH_COUNT" -eq 0 ]]; then
  echo "(no matches — pattern not found in file)"
  exit 0
fi

echo "--- MATCHES ---"

for ((i=0; i<EMITTED; i++)); do
  LINE=${LINE_NUMS[$i]}
  OFFSET=$(( LINE - CONTEXT ))
  if [[ "$OFFSET" -lt 1 ]]; then OFFSET=1; fi
  END=$(( LINE + CONTEXT ))
  if [[ "$END" -gt "$FILE_LINES" ]]; then END=$FILE_LINES; fi
  LIMIT=$(( END - OFFSET + 1 ))

  echo "MATCH=$((i+1)) LINE=$LINE OFFSET=$OFFSET LIMIT=$LIMIT"
  # Emit the context window with line numbers (cat -n style).
  sed -n "${OFFSET},${END}p" "$FILE" | nl -ba -w4 -s': ' -v "$OFFSET"
  echo "---"
done

if [[ "$EMITTED" -lt "$MATCH_COUNT" ]]; then
  echo "(truncated to first $EMITTED of $MATCH_COUNT matches; pass --max 0 for all)"
fi
