#!/usr/bin/env bash
# adr-summary.sh — ADR-corpus summary helper.
#
# Part of the ADR-corpus-compression workstream (see
# production/proposals/2026-05-19-adr-corpus-compression.md). Counterpart to
# tools/dev/gdd-summary.sh. Maintains docs/architecture/_anchors.json and
# emits/checks docs/architecture/_summaries/adr-NNNN.md files.
#
# Sources of truth:
#   - docs/architecture/adr-NNNN-*.md   (source ADR; the truth)
#   - docs/architecture/control-manifest.md  (cross-ref for Required/Forbidden/Guardrails)
#
# Outputs:
#   - docs/architecture/_summaries/adr-NNNN.md  (one per ADR; 200-line cap)
#   - docs/architecture/_anchors.json           (single merged index)
#
# Usage:
#   tools/dev/adr-summary.sh <NNNN>              # print one summary (cat)
#   tools/dev/adr-summary.sh --all               # print every summary in order
#   tools/dev/adr-summary.sh --check             # exit non-zero if any summary stale
#   tools/dev/adr-summary.sh --layer <name>      # print summaries for one layer
#   tools/dev/adr-summary.sh --rebuild-anchors   # regenerate _anchors.json from ADR headers
#   tools/dev/adr-summary.sh --help
#
# Slug accepted as: 0017, 17, adr-0017, ADR-0017. Always normalised to adr-0017.
#
# Layer values: foundation, core, feature, presentation. Match is case-insensitive
# against the "Layer:" line in each summary's §A.
#
# Token math: full ADR-0017 read ≈ 5.5k tokens. Summary read ≈ 1.5k tokens.
# Full ADR set (21 files): ~120k tokens. Full summary set: ~38k tokens (~3.2× compression).
#
# Regenerating summaries themselves: not done by this helper in v1.0. Summary
# regeneration requires content extraction from §Decision / §Alternatives /
# §Verification etc. and is currently done via subagent prompts at proposal-
# execution time. After --check flags a stale summary, manually re-extract or
# re-run the proposal's Phase A pass.
#
# Exit codes:
#   0  success
#   1  user error (bad args, ambiguous slug)
#   2  missing required file (ADR, control-manifest, anchors.json)
#   3  stale summary detected in --check mode
#   4  internal error (jq failure)

set -uo pipefail

ARCH_DIR="docs/architecture"
SUMMARIES_DIR="${ARCH_DIR}/_summaries"
ANCHORS_FILE="${ARCH_DIR}/_anchors.json"
CONTROL_MANIFEST="${ARCH_DIR}/control-manifest.md"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }
log() { echo "[adr-summary] $*" >&2; }

show_help() { sed -n '2,/^$/p' "$0" | sed 's/^# \?//'; exit 0; }

canonicalise_slug() {
    local raw="$1"
    local n="${raw#[Aa][Dd][Rr]-}"
    [[ "$n" =~ ^[0-9]+$ ]] || { echo ""; return; }
    n=$((10#$n))
    printf "adr-%04d\n" "$n"
}

# Find the source ADR file for a canonical slug. Echo path or empty.
find_source_adr() {
    local slug="$1"
    local candidates
    candidates=( "$ARCH_DIR"/${slug}-*.md )
    [[ -f "${candidates[0]}" ]] && echo "${candidates[0]}"
}

# Find the summary file for a canonical slug.
find_summary() {
    local slug="$1"
    local f="$SUMMARIES_DIR/${slug}.md"
    [[ -f "$f" ]] && echo "$f"
}

# --- subcommand: --check ---------------------------------------------------
do_check() {
    [[ -f "$ANCHORS_FILE" ]] || die "$ANCHORS_FILE not found — run --rebuild-anchors first" 2
    local stale=0
    local missing=0
    local total=0
    while IFS= read -r adr; do
        total=$((total + 1))
        local slug
        slug=$(basename "$adr" .md)
        slug="${slug%%-*}"  # adr-0001-engine-... → adr
        # Re-derive from filename pattern adr-NNNN-...md
        local num
        num=$(basename "$adr" | grep -oP 'adr-\K[0-9]+')
        slug="adr-$num"
        local summary
        summary=$(find_summary "$slug")
        if [[ -z "$summary" ]]; then
            log "MISSING: $slug.md (no summary file)"
            missing=$((missing + 1))
            continue
        fi
        # Compare mtimes
        local adr_mtime summary_mtime
        adr_mtime=$(stat -c %Y "$adr")
        summary_mtime=$(stat -c %Y "$summary")
        if (( adr_mtime > summary_mtime )); then
            log "STALE: $slug.md (source $adr newer than summary)"
            stale=$((stale + 1))
        fi
    done < <(find "$ARCH_DIR" -maxdepth 1 -name 'adr-*.md' -type f | sort)
    log "checked: $total ADRs; missing: $missing; stale: $stale"
    if (( stale + missing > 0 )); then
        exit 3
    fi
}

# --- subcommand: --rebuild-anchors -----------------------------------------
do_rebuild_anchors() {
    # Build _anchors.json from H2 headers in each ADR source file.
    # Schema matches GDD anchors: { version, generated, files: { <slug>: {...} } }
    local tmp
    tmp=$(mktemp)
    trap "rm -f $tmp" EXIT

    {
        echo '{'
        echo '  "version": 1,'
        printf '  "generated": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo '  "files": {'
        local first=1
        while IFS= read -r adr; do
            local num path total mtime
            num=$(basename "$adr" | grep -oP 'adr-\K[0-9]+')
            local slug="adr-$num"
            path="$adr"
            total=$(wc -l < "$adr")
            mtime=$(date -u -d "@$(stat -c %Y "$adr")" +%Y-%m-%dT%H:%M:%SZ)

            (( first )) || echo ','
            first=0
            printf '    "%s": {\n' "$slug"
            printf '      "slug": "%s",\n' "$slug"
            printf '      "path": "%s",\n' "$path"
            printf '      "total_lines": %d,\n' "$total"
            printf '      "source_mtime": "%s",\n' "$mtime"
            echo '      "sections": {'

            # Extract H2 headers: lineno|heading (without "## " prefix)
            local prev_line=""
            local prev_heading=""
            local first_section=1
            local entries
            entries=$(grep -nE '^## ' "$adr" | sed 's/:## /|/')
            local last_line
            last_line=$(echo "$entries" | tail -1 | cut -d'|' -f1)
            local headings
            mapfile -t headings < <(echo "$entries")
            local i=0
            local n=${#headings[@]}
            while (( i < n )); do
                local cur="${headings[i]}"
                local ln="${cur%%|*}"
                local hd="${cur#*|}"
                local next_ln
                if (( i + 1 < n )); then
                    local next="${headings[i+1]}"
                    next_ln="${next%%|*}"
                    end=$((next_ln - 1))
                else
                    end=$total
                fi
                local lc=$((end - ln + 1))
                (( first_section )) || echo ','
                first_section=0
                printf '        "§%s": {\n' "$(echo "$hd" | sed 's/"/\\"/g')"
                printf '          "line_start": %d,\n' "$ln"
                printf '          "line_end": %d,\n' "$end"
                printf '          "line_count": %d\n' "$lc"
                printf '        }'
                i=$((i + 1))
            done
            echo
            echo '      }'
            printf '    }'
        done < <(find "$ARCH_DIR" -maxdepth 1 -name 'adr-*.md' -type f | sort)
        echo
        echo '  }'
        echo '}'
    } > "$tmp"

    # Validate JSON
    if ! jq empty "$tmp" 2>/dev/null; then
        die "rebuilt anchors JSON failed validation (see $tmp)" 4
    fi
    mv "$tmp" "$ANCHORS_FILE"
    trap - EXIT
    log "rebuilt $ANCHORS_FILE ($(jq '.files | length' "$ANCHORS_FILE") ADRs)"
}

# --- subcommand: --for / single-slug print ---------------------------------
do_print_one() {
    local slug="$1"
    local f
    f=$(find_summary "$slug")
    [[ -z "$f" ]] && die "no summary at $SUMMARIES_DIR/$slug.md" 2
    cat "$f"
}

# --- subcommand: --all -----------------------------------------------------
do_print_all() {
    local n=0
    while IFS= read -r f; do
        cat "$f"
        echo
        echo '---'
        echo
        n=$((n + 1))
    done < <(find "$SUMMARIES_DIR" -maxdepth 1 -name 'adr-*.md' -type f | sort)
    log "printed $n summaries"
}

# --- subcommand: --layer <name> --------------------------------------------
do_print_layer() {
    local layer="$1"
    local layer_lower
    layer_lower=$(echo "$layer" | tr '[:upper:]' '[:lower:]')
    local n=0
    while IFS= read -r f; do
        # Read line `- **Layer:** ...` from §A
        local layer_line
        layer_line=$(grep -m1 -iE '^\s*-\s*\*\*Layer:\*\*' "$f" | tr '[:upper:]' '[:lower:]')
        if [[ "$layer_line" == *"$layer_lower"* ]]; then
            cat "$f"
            echo
            echo '---'
            echo
            n=$((n + 1))
        fi
    done < <(find "$SUMMARIES_DIR" -maxdepth 1 -name 'adr-*.md' -type f | sort)
    log "printed $n summaries for layer '$layer'"
    (( n == 0 )) && exit 3
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------

[[ $# -eq 0 ]] && show_help

case "$1" in
    --help|-h) show_help ;;
    --check) do_check ;;
    --all) do_print_all ;;
    --rebuild-anchors) do_rebuild_anchors ;;
    --layer)
        [[ $# -lt 2 ]] && die "missing layer name (foundation|core|feature|presentation)" 1
        do_print_layer "$2"
        ;;
    --for)
        [[ $# -lt 2 ]] && die "missing ADR number" 1
        slug=$(canonicalise_slug "$2")
        [[ -z "$slug" ]] && die "invalid ADR number '$2'" 1
        do_print_one "$slug"
        ;;
    *)
        # Treat first arg as a slug
        slug=$(canonicalise_slug "$1")
        [[ -z "$slug" ]] && die "unknown subcommand or invalid slug '$1' (try --help)" 1
        do_print_one "$slug"
        ;;
esac
