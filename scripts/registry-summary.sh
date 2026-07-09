#!/usr/bin/env bash
# registry-summary.sh — Generate a token-cheap summary of design/registry/entities.yaml.
#
# Sibling of gdd-summary.sh. The registry is 4500+ lines / 96k tokens — too large
# for a single Read. This script produces a per-section name index plus a
# one-line-per-entry digest that review skills load instead of full-Reading the
# registry. For a specific entry's full record, callers use registry-lookup.sh.
#
# Outputs:
#   - design/registry/_summary/index.md      (counts + name index, ~3-5k tokens)
#   - design/registry/_summary/digest.md     (one line per entry: name|section|source|n_refs|status)
#   - design/registry/_summary/anchors.json  (per-entry line ranges for lookup)
#
# Usage:
#   tools/dev/registry-summary.sh              # regenerate all summary artifacts
#   tools/dev/registry-summary.sh --check      # exit 3 if summary stale (mtime < registry)
#   tools/dev/registry-summary.sh --help       # show this header
#
# Exit codes:
#   0  success
#   1  user error
#   2  missing registry file
#   3  stale (in --check mode only)

set -uo pipefail

REGISTRY="design/registry/entities.yaml"
OUT_DIR="design/registry/_summary"
INDEX_OUT="${OUT_DIR}/index.md"
DIGEST_OUT="${OUT_DIR}/digest.md"
ANCHORS_OUT="${OUT_DIR}/anchors.json"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }
log() { echo "[registry-summary] $*" >&2; }
show_help() { sed -n '2,/^$/p' "$0" | sed 's/^# \?//'; exit 0; }

# ---------------------------------------------------------------
# Walk the registry and emit per-entry TSV rows:
#   <section>\t<name>\t<line_start>\t<line_end>\t<source>\t<n_refs>\t<status>
# Sections: entities | items | formulas | constants
# Entry boundary: a `  - name: X` line opens a block until the next
# `  - name: Y` line, the next `<section>:` header, or EOF.
# ---------------------------------------------------------------
emit_entries_tsv() {
    awk '
        function flush(end_line) {
            if (cur_name != "") {
                refs = ref_count
                src = (cur_src == "" ? "-" : cur_src)
                stat = (cur_stat == "" ? "-" : cur_stat)
                print cur_section "\t" cur_name "\t" cur_start "\t" end_line "\t" src "\t" refs "\t" stat
            }
            cur_name = ""; cur_src = ""; cur_stat = ""
            ref_count = 0; in_refs = 0
        }
        # Top-level section headers (no indent)
        /^entities:/   { flush(NR-1); cur_section = "entities";  next }
        /^items:/      { flush(NR-1); cur_section = "items";     next }
        /^formulas:/   { flush(NR-1); cur_section = "formulas";  next }
        /^constants:/  { flush(NR-1); cur_section = "constants"; next }
        # Entry start
        /^  - name: / {
            flush(NR-1)
            cur_name = $0; sub(/^  - name: /, "", cur_name)
            # strip inline comment
            sub(/[[:space:]]+#.*$/, "", cur_name)
            cur_start = NR
            next
        }
        /^    source: / {
            cur_src = $0; sub(/^    source: /, "", cur_src)
            sub(/[[:space:]]+#.*$/, "", cur_src)
        }
        /^    status: / {
            cur_stat = $0; sub(/^    status: /, "", cur_stat)
            sub(/[[:space:]]+#.*$/, "", cur_stat)
        }
        /^    referenced_by:/ { in_refs = 1; next }
        /^      - / && in_refs { ref_count++; next }
        # Any other 4-space-indented key closes referenced_by block
        /^    [a-z_]+:/ && in_refs { in_refs = 0 }
        END { flush(NR) }
    ' "$REGISTRY"
}

generate() {
    [[ ! -f "$REGISTRY" ]] && die "registry not found: $REGISTRY" 2
    mkdir -p "$OUT_DIR"

    local generated_at source_lines source_date
    generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    source_lines=$(wc -l < "$REGISTRY")
    source_date=$(date -u -r "$REGISTRY" +"%Y-%m-%dT%H:%M:%SZ")

    local tsv
    tsv=$(emit_entries_tsv)

    # Per-section counts
    local n_ent n_itm n_for n_con n_total
    n_ent=$(echo "$tsv" | awk -F'\t' '$1=="entities"{n++} END{print n+0}')
    n_itm=$(echo "$tsv" | awk -F'\t' '$1=="items"{n++} END{print n+0}')
    n_for=$(echo "$tsv" | awk -F'\t' '$1=="formulas"{n++} END{print n+0}')
    n_con=$(echo "$tsv" | awk -F'\t' '$1=="constants"{n++} END{print n+0}')
    n_total=$((n_ent + n_itm + n_for + n_con))

    # ---- index.md: counts + name index by section ----
    {
        echo "# Registry Summary — Index"
        echo ""
        echo "> **Auto-generated.** Regenerate via \`tools/dev/registry-summary.sh\`."
        echo "> **Do not edit by hand.** Source: \`${REGISTRY}\` (${source_lines} lines)."
        echo "> Generated: ${generated_at}. Source mtime: ${source_date}."
        echo ""
        echo "## Counts"
        echo ""
        echo "| Section | Entries |"
        echo "|---------|---------|"
        echo "| entities | ${n_ent} |"
        echo "| items | ${n_itm} |"
        echo "| formulas | ${n_for} |"
        echo "| constants | ${n_con} |"
        echo "| **TOTAL** | **${n_total}** |"
        echo ""
        echo "## Name index by section"
        echo ""
        for sec in entities items formulas constants; do
            echo "### ${sec}"
            echo ""
            local names
            names=$(echo "$tsv" | awk -F'\t' -v s="$sec" '$1==s{print "- `" $2 "`"}')
            if [[ -z "$names" ]]; then
                echo "*(none)*"
            else
                echo "$names"
            fi
            echo ""
        done
        echo "## Recovery"
        echo ""
        echo "- For one entry's full record: \`tools/dev/registry-lookup.sh <name>\`"
        echo "- For invariant violations: \`tools/dev/registry-selfcheck.sh\`"
        echo "- For one-line-per-entry digest: see \`${DIGEST_OUT}\`"
    } > "$INDEX_OUT"

    # ---- digest.md: one line per entry ----
    {
        echo "# Registry Digest"
        echo ""
        echo "> Auto-generated. One line per entry. Format: name | section | source | n_refs | status"
        echo "> Source: \`${REGISTRY}\` (${source_lines} lines). Generated: ${generated_at}."
        echo ""
        echo '```'
        echo "$tsv" | awk -F'\t' '{ printf "%-50s | %-9s | %-55s | refs=%2d | %s\n", $2, $1, $5, $6, $7 }'
        echo '```'
    } > "$DIGEST_OUT"

    # ---- anchors.json: per-entry line ranges for registry-lookup.sh ----
    {
        echo "$tsv" | awk -F'\t' '
            BEGIN { print "{"; print "  \"version\": 1,"; printf "  \"entries\": {\n"; first=1 }
            {
                if (!first) printf ",\n"
                first=0
                # JSON-escape name (basic)
                name=$2
                gsub(/\\/, "\\\\", name)
                gsub(/"/, "\\\"", name)
                printf "    \"%s\": {\"section\": \"%s\", \"line_start\": %s, \"line_end\": %s, \"line_count\": %d, \"source\": \"%s\", \"n_refs\": %s, \"status\": \"%s\"}", name, $1, $3, $4, ($4-$3+1), $5, $6, $7
            }
            END { printf "\n  }\n}\n" }
        '
    } > "$ANCHORS_OUT"

    log "wrote ${INDEX_OUT} (${n_total} entries indexed)"
    log "wrote ${DIGEST_OUT}"
    log "wrote ${ANCHORS_OUT}"
}

check_freshness() {
    [[ ! -f "$REGISTRY" ]] && die "registry not found: $REGISTRY" 2
    for f in "$INDEX_OUT" "$DIGEST_OUT" "$ANCHORS_OUT"; do
        if [[ ! -f "$f" ]]; then
            echo "STALE: $f missing" >&2
            exit 3
        fi
        if [[ "$REGISTRY" -nt "$f" ]]; then
            echo "STALE: $f older than registry" >&2
            exit 3
        fi
    done
    log "registry summary fresh"
}

[[ $# -eq 0 ]] && { generate; exit 0; }
case "$1" in
    --help|-h) show_help ;;
    --check) check_freshness ;;
    --all)   generate ;;
    *)       die "unknown flag '$1' (try --help)" 1 ;;
esac
