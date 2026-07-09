#!/usr/bin/env bash
# rotate-active.sh — rotate production/session-state/active.md.
#
# Active.md uses newest-on-top ordering. /story-done and /dev-story PREPEND new
# extracts after the 4-line header, so the bottom is the oldest. We KEEP the top
# N extracts and ARCHIVE everything older.
#
# Usage:
#   tools/dev/rotate-active.sh                   # rotate iff line count > 200
#   tools/dev/rotate-active.sh --force           # always rotate (if >=KEEP+1 extracts)
#   tools/dev/rotate-active.sh --threshold 150   # custom line threshold
#   tools/dev/rotate-active.sh --keep 5          # keep 5 newest (default 3)
#
# Exit codes:
#   0  rotated, or no rotation needed (no error)
#   1  bad arguments / file not found / sed boundary error
#
# Output (stdout, structured):
#   STATUS=rotated|rotated-bulk|skipped-under-threshold|skipped-too-few-extracts|skipped-no-file
#   KEPT=N
#   ARCHIVED=M
#   ARCHIVE_PATH=production/session-logs/active-archive-YYYY-MM-DD.md  (only when rotated)
#
# Bulk-rotation fallback: if line count exceeds threshold but the file has fewer
# than KEEP+1 `## Session Extract` anchors (e.g., long-form authoring that bloated
# active.md without using the per-extract schema), the WHOLE current body is
# archived and active.md is reset to a fresh 4-line header. STATUS=rotated-bulk.

set -euo pipefail

ACTIVE="production/session-state/active.md"
ARCHIVE_DIR="production/session-logs"
THRESHOLD=200
KEEP=5
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --keep) KEEP="$2"; shift 2 ;;
    --active) ACTIVE="$2"; shift 2 ;;
    --archive-dir) ARCHIVE_DIR="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,22p' "$0"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$ACTIVE" ]]; then
  echo "STATUS=skipped-no-file"
  echo "KEPT=0"
  echo "ARCHIVED=0"
  exit 0
fi

LINES=$(wc -l < "$ACTIVE")

if [[ "$FORCE" -eq 0 && "$LINES" -le "$THRESHOLD" ]]; then
  echo "STATUS=skipped-under-threshold"
  echo "KEPT=$(grep -c '^## Session Extract' "$ACTIVE" || true)"
  echo "ARCHIVED=0"
  exit 0
fi

# Find CUTOFF = line number of the (KEEP+1)th '## Session Extract' from the top.
# Everything from CUTOFF to EOF is archived; lines 1..CUTOFF-1 stay in active.
CUTOFF_LINE_NUM=$((KEEP + 1))
CUTOFF=$(grep -n '^## Session Extract' "$ACTIVE" \
         | sed -n "${CUTOFF_LINE_NUM}p" | cut -d: -f1)

if [[ -z "$CUTOFF" ]]; then
  EXTRACTS=$(grep -c '^## Session Extract' "$ACTIVE" || true)
  # Bulk-rotation fallback: file is over threshold but lacks enough Session Extract
  # anchors to do a normal rotation. Archive the entire body and reset active.md
  # to a fresh header. This catches long-form authoring sessions that bloated
  # active.md under a non-extract schema.
  mkdir -p "$ARCHIVE_DIR"
  TODAY=$(date +%Y-%m-%d)
  ARCHIVE="$ARCHIVE_DIR/active-archive-$TODAY.md"
  if [[ ! -f "$ARCHIVE" ]]; then
    printf '# Active Session Archive — rotated %s\n\nOriginally part of `%s`. Rotated by tools/dev/rotate-active.sh when the file exceeded %s lines.\n\n---\n\n' \
      "$TODAY" "$ACTIVE" "$THRESHOLD" > "$ARCHIVE"
  fi
  {
    echo "## Bulk Rotation — $(date -Iseconds)"
    echo ""
    echo "Archived because active.md exceeded $THRESHOLD lines ($LINES) but had"
    echo "fewer than $((KEEP + 1)) \`## Session Extract\` anchors ($EXTRACTS found)."
    echo "Likely cause: long-form authoring (GDD, ADR, review) wrote to active.md"
    echo "without using the per-extract schema. See .claude/docs/active-md-template.md."
    echo ""
    cat "$ACTIVE"
    echo ""
    echo "---"
    echo ""
  } >> "$ARCHIVE"
  # Reset active.md to a minimal header.
  cat > "$ACTIVE" <<EOF
# Active Session State

(rotated $(date -Iseconds) — previous body archived to $ARCHIVE)

EOF
  echo "STATUS=rotated-bulk"
  echo "KEPT=0"
  echo "ARCHIVED=1"
  echo "ARCHIVE_PATH=$ARCHIVE"
  exit 0
fi

mkdir -p "$ARCHIVE_DIR"
TODAY=$(date +%Y-%m-%d)
ARCHIVE="$ARCHIVE_DIR/active-archive-$TODAY.md"

if [[ ! -f "$ARCHIVE" ]]; then
  printf '# Active Session Archive — rotated %s\n\nOriginally part of `%s`. Rotated by tools/dev/rotate-active.sh when the file exceeded %s lines.\n\n---\n\n' \
    "$TODAY" "$ACTIVE" "$THRESHOLD" > "$ARCHIVE"
fi

ARCHIVED_BEFORE=$(grep -c '^## Session Extract' "$ARCHIVE" 2>/dev/null || echo 0)
sed -n "${CUTOFF},\$p" "$ACTIVE" >> "$ARCHIVE"
ARCHIVED_AFTER=$(grep -c '^## Session Extract' "$ARCHIVE" 2>/dev/null || echo 0)
ARCHIVED=$((ARCHIVED_AFTER - ARCHIVED_BEFORE))

# Rewrite active.md as: 4-line header + lines 5..CUTOFF-1.
TMP="${ACTIVE}.tmp"
{ head -4 "$ACTIVE"; sed -n "5,$((CUTOFF - 1))p" "$ACTIVE"; } > "$TMP"
mv "$TMP" "$ACTIVE"

KEPT=$(grep -c '^## Session Extract' "$ACTIVE" || true)

# Sanity: if KEPT != KEEP, something drifted (probably <KEEP+1 extracts existed).
echo "STATUS=rotated"
echo "KEPT=$KEPT"
echo "ARCHIVED=$ARCHIVED"
echo "ARCHIVE_PATH=$ARCHIVE"
