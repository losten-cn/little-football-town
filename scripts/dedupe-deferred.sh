#!/usr/bin/env bash
# dedupe-deferred.sh — summarize production/deferred-items.md without loading it.
#
# The register is ~40k tokens; this script crunches it on disk and emits only the
# summary lines a skill needs (counts, next ID, duplicates, cap pressure).
#
# Usage:
#   tools/dev/dedupe-deferred.sh              # summary only
#   tools/dev/dedupe-deferred.sh --top N      # also list top N OPEN rows (one-line each)
#   tools/dev/dedupe-deferred.sh --grep PATTERN  # list OPEN rows matching PATTERN (case-insensitive ERE)
#   tools/dev/dedupe-deferred.sh --wont-fix-infra  # list RESOLVED rows annotated WONT-FIX-UNTIL-INFRA (revisit-when-infra-lands)
#   tools/dev/dedupe-deferred.sh --file PATH  # use a non-default register
#
# Output (stdout, structured key=value):
#   OPEN=N                        (active OPEN-NNN rows minus any annotated legacy-in-place (RESOLVED:))
#   RESOLVED=N                    (sum of legacy-in-place OPEN-NNN (RESOLVED:) + relocated RESOLVED-NNN rows)
#   TOTAL=N                       (OPEN + RESOLVED — all distinct register entries; not just OPEN count)
#   NEXT_ID=OPEN-NNN              (the next sequential ID to mint; scans both OPEN-NNN and RESOLVED-NNN ID space)
#   HIGHEST_ID=OPEN-NNN           (always formatted as OPEN-NNN regardless of whether the source row is OPEN or RESOLVED)
#   CAP=50
#   CAP_PRESSURE=ok|warn|over     (warn at >=45 OPEN; over at >=50)
#   DUPLICATE_IDS=OPEN-001 OPEN-077 ...   (space-sep list, empty if none; scope: OPEN-NNN bullets only)
#
# When --top or --grep is set, a section is appended:
#   --- TOP N OPEN ---
#   OPEN-NNN [SEV] [AREA] description (truncated to 200c)
#   ...

set -euo pipefail

REGISTER="production/deferred-items.md"
TOP=0
GREP_PATTERN=""
WONT_FIX_INFRA=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --top) TOP="$2"; shift 2 ;;
    --grep) GREP_PATTERN="$2"; shift 2 ;;
    --wont-fix-infra) WONT_FIX_INFRA=1; shift 1 ;;
    --file) REGISTER="$2"; shift 2 ;;
    -h|--help) sed -n '2,23p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$REGISTER" ]]; then
  echo "ERROR: register not found at $REGISTER" >&2
  exit 1
fi

# State source-of-truth: two row shapes count as RESOLVED.
# Earlier regex looked for `[ ]/[x]` checkbox prefixes that no skill ever wrote —
# silently miscounted to 0/0 (revised 2026-05-06 to match actual format spec).
# Strict: require digits — the file header has literal `OPEN-NNN` format examples
# in fenced code blocks that must not be counted.
#
# Two RESOLVED row shapes (both are counted — a real register may have a mix):
#   1. Legacy in-place annotation: `^- OPEN-NNN ... (RESOLVED[ :-]...` — OPEN row
#      kept under `## OPEN items` with a `(RESOLVED:` token tagging the state.
#   2. Relocated format: `^- RESOLVED-NNN [was OPEN-NNN, ...]` — row moved to
#      the `## RESOLVED items` section with a new `RESOLVED-NNN` ID.
# Older corpora may carry shape 1; newer ones favour shape 2. Both are valid;
# legacy shape preserved for backward compat in case any historical entry
# hasn't been migrated.
OPEN_TOTAL=$(grep -cE '^- OPEN-[0-9]{3}' "$REGISTER" || true)
RESOLVED_INPLACE=$(grep -E '^- OPEN-[0-9]{3}' "$REGISTER" | grep -cE '\(RESOLVED[ :-]' || true)
RESOLVED_RELOCATED=$(grep -cE '^- RESOLVED-[0-9]{3}' "$REGISTER" || true)
RESOLVED=$((RESOLVED_INPLACE + RESOLVED_RELOCATED))
OPEN=$((OPEN_TOTAL - RESOLVED_INPLACE))
TOTAL=$((OPEN_TOTAL + RESOLVED_RELOCATED))

# Highest existing ID across BOTH open and resolved (so we don't reuse IDs).
# Scan picks up: standalone OPEN-NNN bullets, "was OPEN-NNN" backreferences inside
# relocated RESOLVED-NNN rows, AND RESOLVED-NNN IDs themselves (the relocated-
# format ID inherits the original number, but a body-text forward-target like
# "mark this RESOLVED-NNN" can still exceed the highest OPEN-NNN bullet — scan
# both shapes to be robust).
# Empty-register guard: under set -euo pipefail, `grep -o` returns exit-1 on
# zero matches (empty register, bootstrap state, or --file <PATH> pointing at
# a fresh file), pipefail propagates, and the command substitution aborts
# before any output. Disable pipefail for this single command-sub so the
# empty-string fallback wins.
set +o pipefail
HIGHEST_NUM=$(grep -oE '(OPEN|RESOLVED)-[0-9]{3}' "$REGISTER" | sed -E 's/^(OPEN|RESOLVED)-//' | sort -un | tail -1)
set -o pipefail
HIGHEST_NUM=${HIGHEST_NUM:-0}
NEXT_NUM=$((10#$HIGHEST_NUM + 1))
HIGHEST_ID=$(printf "OPEN-%03d" "$((10#$HIGHEST_NUM))")
NEXT_ID=$(printf "OPEN-%03d" "$NEXT_NUM")

# Duplicate IDs: any OPEN-NNN that appears at the start of more than one row.
# Empty-register guard: same pipefail rationale as HIGHEST_NUM above —
# `grep -o` returns exit-1 on zero matches.
set +o pipefail
DUPLICATE_IDS=$(grep -oE '^- OPEN-[0-9]{3}' "$REGISTER" \
                | awk '{print $NF}' | sort | uniq -d | tr '\n' ' ' | sed 's/ $//')
set -o pipefail

CAP=50
if [[ "$OPEN" -ge "$CAP" ]]; then
  CAP_PRESSURE="over"
elif [[ "$OPEN" -ge $((CAP - 5)) ]]; then
  CAP_PRESSURE="warn"
else
  CAP_PRESSURE="ok"
fi

echo "OPEN=$OPEN"
echo "RESOLVED=$RESOLVED"
echo "TOTAL=$TOTAL"
echo "NEXT_ID=$NEXT_ID"
echo "HIGHEST_ID=$HIGHEST_ID"
echo "CAP=$CAP"
echo "CAP_PRESSURE=$CAP_PRESSURE"
echo "DUPLICATE_IDS=$DUPLICATE_IDS"

if [[ "$TOP" -gt 0 ]]; then
  echo "--- TOP $TOP OPEN ---"
  # awk avoids the grep|head SIGPIPE under pipefail; truncate to 220c.
  # OPEN = row without `(RESOLVED[ :-]` annotation (matches RESOLVED:, RESOLVED-AS-..., RESOLVED 2026-...).
  awk -v n="$TOP" '/^- OPEN-[0-9]{3}/ && !/\(RESOLVED[ :-]/ {print substr($0, 1, 220); if (++c >= n) exit}' "$REGISTER"
fi

if [[ -n "$GREP_PATTERN" ]]; then
  echo "--- GREP OPEN matching: $GREP_PATTERN ---"
  # Disable pipefail for this block — grep | grep with no matches must not crash.
  set +o pipefail
  matches=$(grep -E '^- OPEN-[0-9]{3}' "$REGISTER" | grep -vE '\(RESOLVED[ :-]' | grep -iE "$GREP_PATTERN" | cut -c1-220)
  set -o pipefail
  if [[ -z "$matches" ]]; then
    echo "(no matches)"
  else
    echo "$matches"
  fi
fi

if [[ "$WONT_FIX_INFRA" -eq 1 ]]; then
  echo "--- RESOLVED WONT-FIX-UNTIL-INFRA (revisit when infra lands) ---"
  set +o pipefail
  matches=$(grep -E '^- OPEN-[0-9]{3}' "$REGISTER" | grep -F 'WONT-FIX-UNTIL-INFRA' | cut -c1-260)
  set -o pipefail
  if [[ -z "$matches" ]]; then
    echo "(no matches)"
  else
    echo "$matches"
  fi
fi
