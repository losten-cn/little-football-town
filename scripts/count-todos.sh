#!/usr/bin/env bash
# count-todos.sh — Count TODO/FIXME/HACK markers in the codebase.
#
# Background. Sprint retrospectives can track TODO/FIXME/HACK occurrence
# trends as a "is technical debt growing or shrinking" hygiene signal,
# not a hard gate.
#
# Two complementary scopes are tracked because the broad project-root
# grep is typically inflated by third-party / vendor code drops, which
# carry their own TODO/FIXME markers unrelated to your project's debt:
#
#   1. Project-code-only (FORWARD-COMPARABLE): only the directories where
#      YOU author code — comparable across sprints.
#   2. Broad (INFLATED — third-party drops): the broader source root —
#      includes vendor code; useful for sanity-checking that the forward-
#      comparable signal isn't masking a real growth trend.
#
# Adapt this script to your project. The two arrays below are the only
# project-specific knobs:
#
#   PROJECT_SCOPES — directories where you author code (forward-comparable)
#   BROAD_SCOPE    — the broader source root (vendor-inflated)
#
# Default values below assume a Unity-shaped project layout. For other
# engines / project shapes, edit:
#   - Godot: PROJECT_SCOPES=("scripts/" "tests/"); BROAD_SCOPE="."
#   - Unreal: PROJECT_SCOPES=("Source/" "Plugins/<YourPlugin>/"); BROAD_SCOPE="Source/"
#   - Generic: PROJECT_SCOPES=("src/" "tests/"); BROAD_SCOPE="."
#
# Usage:
#   tools/dev/count-todos.sh                  # both scopes (default; retro shape)
#   tools/dev/count-todos.sh --project-only   # project-code-only count
#   tools/dev/count-todos.sh --broad-only     # broad scope count
#   tools/dev/count-todos.sh --json           # JSON output for tooling
#   tools/dev/count-todos.sh --help
#
# Exit codes:
#   0  success
#   1  user error (bad args)
#   2  expected scope directory missing (project root mismatch)

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly MARKER_PATTERN='TODO\|FIXME\|HACK'

# === PROJECT-SPECIFIC CONFIGURATION ===
# Edit these two values to match your project's directory layout.

# Project-code-only scopes (forward-comparable across sprints).
# These are the directories where YOU author code. Comparable across
# sprints because they don't include vendor / third-party drops.
readonly -a PROJECT_SCOPES=(
    "src/"
    "tests/"
)

# Broad scope (third-party-inflated; sanity-check signal only).
# This is the broader source root that may include vendor code.
readonly BROAD_SCOPE="."

# Display name for the broad scope (used in human-readable output).
# Replace if you renamed BROAD_SCOPE.
readonly BROAD_SCOPE_DISPLAY="(broad)"

# === END PROJECT-SPECIFIC CONFIGURATION ===

log() { printf '[count-todos] %s\n' "$*" >&2; }
die() { log "ERROR: $1"; exit "${2:-1}"; }

usage() {
    sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

# Verify project root by checking at least one PROJECT_SCOPE exists.
verify_project_root() {
    local scope
    for scope in "${PROJECT_SCOPES[@]}"; do
        [[ -d "$scope" ]] && return 0
    done
    die "no PROJECT_SCOPES directory found (${PROJECT_SCOPES[*]}) — run from project root or edit the script's PROJECT_SCOPES array" 2
}

# Count markers in a list of scope paths. Skips missing scopes silently
# (some scopes may not exist yet in early sprints).
# Returns "<occurrence_count> <file_count>" to stdout.
count_markers() {
    local -a scopes=("$@")
    local -a existing_scopes=()
    local scope
    for scope in "${scopes[@]}"; do
        [[ -d "$scope" ]] && existing_scopes+=("$scope")
    done

    if (( ${#existing_scopes[@]} == 0 )); then
        printf '0 0\n'
        return 0
    fi

    local occurrences files
    occurrences=$(grep -rIn "$MARKER_PATTERN" "${existing_scopes[@]}" 2>/dev/null | wc -l)
    files=$(grep -rIln "$MARKER_PATTERN" "${existing_scopes[@]}" 2>/dev/null | wc -l)
    printf '%s %s\n' "$occurrences" "$files"
}

# --- subcommand: --project-only -------------------------------------------
do_project_only() {
    verify_project_root
    local result
    result=$(count_markers "${PROJECT_SCOPES[@]}")
    local occ files
    read -r occ files <<< "$result"
    printf 'project-code-only: %d occurrences in %d files (%s)\n' \
        "$occ" "$files" "$(IFS=' + '; echo "${PROJECT_SCOPES[*]}")"
}

# --- subcommand: --broad-only ---------------------------------------------
do_broad_only() {
    verify_project_root
    local result
    result=$(count_markers "$BROAD_SCOPE")
    local occ files
    read -r occ files <<< "$result"
    printf 'broad %s: %d occurrences in %d files (may include third-party drops; non-comparable)\n' \
        "$BROAD_SCOPE_DISPLAY" "$occ" "$files"
}

# --- subcommand: --json ---------------------------------------------------
do_json() {
    verify_project_root
    local project_result broad_result
    project_result=$(count_markers "${PROJECT_SCOPES[@]}")
    broad_result=$(count_markers "$BROAD_SCOPE")
    local project_occ project_files broad_occ broad_files
    read -r project_occ project_files <<< "$project_result"
    read -r broad_occ broad_files <<< "$broad_result"
    local project_scopes_json
    project_scopes_json=$(printf '"%s",' "${PROJECT_SCOPES[@]}" | sed 's/,$//')
    cat <<EOF
{
  "project_code_only": {
    "occurrences": $project_occ,
    "files": $project_files,
    "scopes": [$project_scopes_json],
    "note": "forward-comparable across sprints"
  },
  "broad": {
    "occurrences": $broad_occ,
    "files": $broad_files,
    "scopes": ["$BROAD_SCOPE"],
    "note": "may include third-party drops; inflated; non-comparable across sprints"
  }
}
EOF
}

# --- subcommand: default (both scopes) ------------------------------------
do_default() {
    verify_project_root
    local project_result broad_result
    project_result=$(count_markers "${PROJECT_SCOPES[@]}")
    broad_result=$(count_markers "$BROAD_SCOPE")
    local project_occ project_files broad_occ broad_files
    read -r project_occ project_files <<< "$project_result"
    read -r broad_occ broad_files <<< "$broad_result"

    printf 'TODO/FIXME/HACK counter — retro-row format\n'
    printf '\n'
    printf '  project-code-only (forward-comparable):\n'
    printf '    %d occurrences in %d files\n' "$project_occ" "$project_files"
    printf '    scopes: %s\n' "$(IFS=' + '; echo "${PROJECT_SCOPES[*]}")"
    printf '\n'
    printf '  broad %s (possibly third-party-inflated; sanity-check only):\n' "$BROAD_SCOPE_DISPLAY"
    printf '    %d occurrences in %d files\n' "$broad_occ" "$broad_files"
    printf '    scope: %s recursive\n' "$BROAD_SCOPE"
    printf '\n'
    printf '  Use project-code-only number for cross-sprint trend tracking.\n'
    printf '  The broad number rises with vendor / third-party drops — do not\n'
    printf '  compare a post-vendor-drop broad count to a pre-vendor-drop one.\n'
}

# --- entry point ----------------------------------------------------------
main() {
    case "${1:-}" in
        --help|-h) usage ;;
        --project-only) do_project_only ;;
        --broad-only) do_broad_only ;;
        --json) do_json ;;
        "") do_default ;;
        *) die "unknown argument: $1 (try --help)" 1 ;;
    esac
}

main "$@"
