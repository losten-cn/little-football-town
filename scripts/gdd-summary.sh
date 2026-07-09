#!/usr/bin/env bash
# gdd-summary.sh — Generate per-GDD summary digests + section-anchor index.
#
# Part of the corpus-compression workstream (see
# production/proposals/2026-05-13-gdd-corpus-compression.md). A summary is a
# 200-line-capped digest of a GDD that review skills load instead of full-Reading
# the source GDD. Anchors are precomputed offset/limit ranges for partial-Read
# fallback when a specific section's content IS needed.
#
# Sources of truth:
#   - design/gdd/<slug>.md           (source GDD; the truth)
#   - design/registry/entities.yaml  (cross-doc entity registry; existing schema)
#   - design/gdd/systems-index.md    (status column for §A)
#
# Outputs:
#   - design/gdd/_summaries/<slug>.md  (one per GDD; 200-line hard cap)
#   - design/gdd/_anchors.json         (single merged index, one entry per GDD)
#
# Usage:
#   tools/dev/gdd-summary.sh <slug>          # regenerate one GDD's summary + anchors entry
#   tools/dev/gdd-summary.sh --all           # regenerate every GDD in design/gdd/
#   tools/dev/gdd-summary.sh --check         # exit non-zero if any summary is stale (mtime < source)
#   tools/dev/gdd-summary.sh --help          # show this header
#
# Slug examples: b4 (matches b4-strain-failure-system.md), autosave (matches
# a11-autosave-crash-recovery.md), engine-architecture (exact filename minus .md).
# Slug match is fuzzy: any GDD whose filename starts with "<slug>-" or equals
# "<slug>.md" matches. If multiple match, --all is required.
#
# Token math: full B4 read = 1943 lines ≈ 30k tokens. Summary read ≈ 2k tokens.
# 15× saving per cross-doc lookup that doesn't need a specific section.
#
# Exit codes:
#   0  success
#   1  user error (bad args, ambiguous slug)
#   2  missing required file (GDD, systems-index, registry)
#   3  stale summary detected in --check mode
#   4  internal error (parser failure, jq failure)

set -uo pipefail

GDD_DIR="design/gdd"
SUMMARIES_DIR="${GDD_DIR}/_summaries"
ANCHORS_FILE="${GDD_DIR}/_anchors.json"
REGISTRY="design/registry/entities.yaml"
SYSTEMS_INDEX="${GDD_DIR}/systems-index.md"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }
log() { echo "[gdd-summary] $*" >&2; }

show_help() { sed -n '2,/^$/p' "$0" | sed 's/^# \?//'; exit 0; }

# ---------------------------------------------------------------
# Resolve a slug to a GDD file path. Returns absolute filename on stdout.
# ---------------------------------------------------------------
resolve_slug() {
    local slug="$1"
    local matches
    # Exact filename match takes priority
    if [[ -f "${GDD_DIR}/${slug}.md" ]]; then
        echo "${GDD_DIR}/${slug}.md"
        return 0
    fi
    # Fuzzy: any file starting with "<slug>-"
    mapfile -t matches < <(find "${GDD_DIR}" -maxdepth 1 -type f -name "${slug}-*.md" 2>/dev/null | sort)
    if (( ${#matches[@]} == 0 )); then
        die "no GDD matches slug '${slug}' (looked in ${GDD_DIR})" 2
    fi
    if (( ${#matches[@]} > 1 )); then
        echo "ambiguous slug '${slug}' — multiple matches:" >&2
        printf '  %s\n' "${matches[@]}" >&2
        die "use the full filename slug or run --all" 1
    fi
    echo "${matches[0]}"
}

# ---------------------------------------------------------------
# Derive the slug from a GDD filename. b4-strain-failure-system.md -> b4
# For non-prefixed files (e.g. a1-engine-architecture.md), returns filename minus .md.
# ---------------------------------------------------------------
slug_from_path() {
    local f base
    f="$1"
    base="$(basename "$f" .md)"
    # If base matches <prefix>-..., prefix is the slug for B/A/D/E/F/G/N letters
    if [[ "$base" =~ ^([a-z][0-9]+)- ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "$base"
    fi
}

# ---------------------------------------------------------------
# Walk H2 headings + immediate H3 headings, emit line ranges as TSV:
#   <heading>\t<line_start>\t<line_end>
# H2 boundaries are explicit; the LAST H2's end is the file's last line.
# H3s are emitted with their own line ranges (next H2 or H3 boundary).
# ---------------------------------------------------------------
emit_anchors_tsv() {
    # Output format: <level>\t<heading>\t<line_start>\t<line_end>
    # where <level> is "H2" or "H3". Callers can filter by level.
    local gdd="$1"
    local total
    total=$(wc -l < "$gdd")
    awk -v total="$total" '
        /^## / {
            if (last_h2_line > 0) {
                # close out previous H2
                print "H2\t" prev_heading "\t" last_h2_line "\t" (NR-1)
            }
            # also close out trailing H3 from previous H2 if any
            if (last_h3_line > 0) {
                print "H3\t" prev_h3 "\t" last_h3_line "\t" (NR-1)
                last_h3_line = 0
            }
            prev_heading = substr($0, 4)
            last_h2_line = NR
            next
        }
        /^### / {
            if (last_h3_line > 0) {
                print "H3\t" prev_h3 "\t" last_h3_line "\t" (NR-1)
            }
            prev_h3 = substr($0, 5)
            last_h3_line = NR
            next
        }
        END {
            if (last_h3_line > 0) {
                print "H3\t" prev_h3 "\t" last_h3_line "\t" total
            }
            if (last_h2_line > 0) {
                print "H2\t" prev_heading "\t" last_h2_line "\t" total
            }
        }
    ' "$gdd"
}

# ---------------------------------------------------------------
# Pull the review status from systems-index.md for a given slug.
# Returns: canonical status prefix (e.g. "Approved 2026-05-15 [std]"),
# or "Unknown" if not found, or "n/a" for Content-Ref / Quick-Spec rows.
# Per Group 1 doc-hygiene rewrite 2026-05-15: column 6 is review status,
# column 5 is the priority tier (MVP/VS/Alpha/FV).
# ---------------------------------------------------------------
# Map a summary slug to the systems-index short code.
# Examples: "b11" → "B11"; "c1-some-system-name" → "C1"; "engine-architecture" → "A1".
# Strategy: if slug starts with <letter><digits>, that IS the code. Otherwise
# look up the GDD path in systems-index col 7 to find its code.
slug_to_index_code() {
    local slug="$1"
    # Short-code style (b11, c4, d1, etc): leading letter+digits
    if [[ "$slug" =~ ^([a-z][0-9]+)(-.*)?$ ]]; then
        echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]'
        return
    fi
    # Full-name style (engine-architecture, save-load-system, etc): grep the systems-index
    # for a row whose col 7 references this slug.
    local code
    code=$(awk -F'|' -v needle="${slug}.md" '
        /^\| [A-Z][0-9]+ / {
            src=$7; gsub(/^ +| +$|`/, "", src)
            if (src ~ needle) { c=$2; gsub(/^ +| +$/, "", c); print c; exit }
        }
    ' "$SYSTEMS_INDEX")
    echo "${code:-UNKNOWN}"
}

status_from_index() {
    local code
    code=$(slug_to_index_code "$1")
    local row
    row=$(grep -E "^\| ${code} " "$SYSTEMS_INDEX" 2>/dev/null | head -1)
    [[ -z "$row" ]] && { echo "Unknown"; return; }
    # 6th pipe-delimited field is review status. Strip the "— see reviews/..." pointer
    # for the summary header; the full review-log path lives in the log itself.
    echo "$row" | awk -F'|' '{
        s=$6; gsub(/^ +| +$/, "", s);
        sub(/ +— see reviews\/.*$/, "", s);
        print s
    }' | head -c 80
}

# ---------------------------------------------------------------
# Pull the priority tier (MVP/VS/Alpha/FV/Quick-Spec/Content-Ref) from
# systems-index.md for a given slug. Column 5.
# ---------------------------------------------------------------
tier_from_index() {
    local code
    code=$(slug_to_index_code "$1")
    local row
    row=$(grep -E "^\| ${code} " "$SYSTEMS_INDEX" 2>/dev/null | head -1)
    [[ -z "$row" ]] && { echo "Unknown"; return; }
    echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $5); print $5}' | head -c 60
}

# ---------------------------------------------------------------
# Find registry entries (formulas[] + constants[]) where source == this GDD,
# or referenced_by[] mentions this GDD. Returns entry names as a sorted list.
# Uses grep, NOT a YAML parser — registry's flat indentation lets us cheat.
# ---------------------------------------------------------------
registry_entries_for_gdd() {
    local gdd_path="$1"
    [[ ! -f "$REGISTRY" ]] && return 0
    # Owner entries: scan blocks; record names where the block's `source:` line == this path
    # Walk the registry: each `- name: X` opens a block until the next `- name:` or section end
    awk -v target="$gdd_path" '
        /^  - name: / {
            if (name && (owner == target || ref_match)) print (owner == target ? "OWNS" : "USES") "\t" name
            name = $0; sub(/^  - name: /, "", name)
            owner = ""
            ref_match = 0
        }
        /^    source: / {
            owner = $0; sub(/^    source: /, "", owner)
        }
        /^      - / && in_refs {
            line = $0; sub(/^      - /, "", line)
            # split off trailing comment
            sub(/[[:space:]]+#.*$/, "", line)
            if (line == target) ref_match = 1
        }
        /^    referenced_by:/ { in_refs = 1; next }
        /^    [a-z_]+:/ && in_refs && !/^    referenced_by:/ { in_refs = 0 }
        END {
            if (name && (owner == target || ref_match)) print (owner == target ? "OWNS" : "USES") "\t" name
        }
    ' "$REGISTRY" | sort -u
}

# ---------------------------------------------------------------
# Harvest AC headings. Supports four project conventions:
#   (a) H3 form:           `### AC-N [tag] — short description`        (B4, B7)
#   (b) Bold form:         `**AC-N — short description.**`             (B8)
#   (c) Bold-period form:  `**AC-N.M. Short description.** [tag]`      (B16, A4, A9)
#   (d) Bulleted bold:     `- **AC-N (tag). Short description.** ...`  (B14, B1, A6)
# Splits on the FIRST " — " (em-dash) OR ". " (period+space) after the AC-ID,
# whichever comes first. Tags like [Logic]/[L]/(Logic) are stripped.
# Returns: AC-ID<TAB>line<TAB>summary
# ---------------------------------------------------------------
emit_ac_list() {
    local gdd="$1"
    # Match `### AC-` (H3), `**AC-` (bold), or `- **AC-` (bulleted bold) at line start.
    grep -nE '^(### AC-|\*\*AC-|- \*\*AC-)' "$gdd" 2>/dev/null | awk -F: '
        {
            line = $1
            rest = $0
            sub(/^[0-9]+:/, "", rest)
            # Strip the leading marker(s) so the AC-ID is at position 1.
            sub(/^### /, "", rest)
            sub(/^- \*\*/, "", rest)
            sub(/^\*\*/, "", rest)
            # Strip a (tag) parenthetical immediately after the AC-ID
            # (e.g., `AC-1 (Logic).` → `AC-1.`). POSIX awk has no sub() backrefs,
            # so we use match() to capture the AC-ID, then rebuild without the tag.
            if (match(rest, /^AC-[A-Za-z0-9.]+ \([^)]+\)/) > 0) {
                acid_end = RSTART + RLENGTH - 1
                # AC-ID is everything before the " (": find that space.
                paren_start = index(rest, " (")
                acid_only = substr(rest, 1, paren_start - 1)
                rest = acid_only substr(rest, acid_end + 1)
            }
            # Strip a trailing closing-bold marker if present.
            sub(/\*\*[[:space:]]*(\[[^]]+\])?[[:space:]]*$/, "", rest)
            # Multi-line AC detection: if `**` still remains anywhere in `rest`,
            # the AC title continues on subsequent lines (e.g. A6 form
            # `- **AC-1 (Tag).** **GIVEN** ...`). In that case the heading line
            # itself has no summary — drop it; the line number is enough.
            if (index(rest, "**") > 0) {
                # Cut everything from the first remaining `**` onward.
                cut_pos = index(rest, "**")
                rest = substr(rest, 1, cut_pos - 1)
                # Trim trailing whitespace and a trailing period.
                sub(/[[:space:]]*\.?[[:space:]]*$/, "", rest)
                acid = rest
                summary = ""
            } else {
                # Single-line AC: split on " — " (em-dash) OR ". " (period+space),
                # whichever comes first.
                em_pos = index(rest, " — ")
                dot_pos = index(rest, ". ")
                if (em_pos > 0 && (dot_pos == 0 || em_pos < dot_pos)) {
                    split_pos = em_pos
                    split_len = length(" — ")
                } else if (dot_pos > 0) {
                    split_pos = dot_pos
                    split_len = length(". ")
                } else {
                    split_pos = 0
                }
                if (split_pos > 0) {
                    acid = substr(rest, 1, split_pos - 1)
                    summary = substr(rest, split_pos + split_len)
                } else {
                    acid = rest
                    summary = ""
                }
            }
            print acid "\t" line "\t" summary
        }
    '
}

# ---------------------------------------------------------------
# Generate a single GDD's summary file. Caps at 200 content lines.
# ---------------------------------------------------------------
generate_summary() {
    local gdd_path="$1"
    local slug
    slug=$(slug_from_path "$gdd_path")
    local out="${SUMMARIES_DIR}/${slug}.md"
    local source_lines
    source_lines=$(wc -l < "$gdd_path")
    local generated_at
    generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local source_date
    source_date=$(date -u -r "$gdd_path" +"%Y-%m-%dT%H:%M:%SZ")
    local status
    status=$(status_from_index "$slug")
    tier=$(tier_from_index "$slug")

    mkdir -p "$SUMMARIES_DIR"

    {
        echo "# GDD Summary — ${slug}"
        echo ""
        echo "> **Auto-generated.** Regenerate via \`tools/dev/gdd-summary.sh ${slug}\`."
        echo "> **Do not edit by hand.** Source GDD: \`${gdd_path}\` (${source_lines} lines)."
        echo "> Generated: ${generated_at}. Source mtime: ${source_date}."
        echo ""
        echo "## A. Status"
        echo ""
        echo "- **Review status:** ${status}"
        echo "- **Priority tier:** ${tier}"
        echo "- **Source file:** \`${gdd_path}\`"
        echo "- **Source line count:** ${source_lines}"
        echo ""
        echo "## B. Section anchors (line ranges in source GDD)"
        echo ""
        echo "*H2 sections only; H3 anchors live in \`design/gdd/_anchors.json\` for precise lookup.*"
        echo "*For section content, use \`tools/dev/gdd-lookup.sh ${slug} \"<§heading>\"\` or partial-Read directly.*"
        echo ""
        # Emit only H2 anchors in §B (H3s live in _anchors.json for precise lookup
        # but inflate the summary). emit_anchors_tsv tags rows with H2/H3 in $1.
        emit_anchors_tsv "$gdd_path" \
            | awk -F'\t' '$1 == "H2" { print $3 "\t" $2 "\t" $4 }' \
            | sort -n \
            | awk -F'\t' '{ printf "- §%s — L%s–L%s\n", $2, $1, $3 }'
        echo ""
        echo "## C. Registry entries (from \`${REGISTRY}\`)"
        echo ""
        local reg_entries
        reg_entries=$(registry_entries_for_gdd "$gdd_path")
        if [[ -z "$reg_entries" ]]; then
            echo "*(none — this GDD owns or references no cross-doc registry entries)*"
        else
            echo "### Owned by this GDD"
            echo "$reg_entries" | awk -F'\t' '$1=="OWNS" {print "- `" $2 "`"}'
            echo ""
            echo "### Referenced by this GDD (owned elsewhere)"
            echo "$reg_entries" | awk -F'\t' '$1=="USES" {print "- `" $2 "`"}'
        fi
        echo ""
        echo "## D. Acceptance criteria (IDs + headings; for body text, partial-Read §H/§I/§J)"
        echo ""
        local ac_list ac_count
        ac_list=$(emit_ac_list "$gdd_path")
        ac_count=$(echo "$ac_list" | grep -c . || true)
        if [[ -z "$ac_list" ]]; then
            echo "*(no \`### AC-\` headings detected)*"
        else
            echo "$ac_list" | awk -F'\t' '{ printf "- **%s** (L%s) — %s\n", $1, $2, $3 }' | head -30
            if (( ac_count > 30 )); then
                echo ""
                echo "*(showing first 30 of ${ac_count}; full list in source GDD)*"
            fi
        fi
        echo ""
        echo "## E. Recovery / Reference"
        echo ""
        echo "- To partial-Read a specific section: \`tools/dev/gdd-lookup.sh ${slug} \"<§heading>\"\`"
        echo "- To grep a pattern anywhere: \`tools/dev/partial-read-helper.sh ${gdd_path} \"<pattern>\"\`"
        echo "- To regenerate this summary: \`tools/dev/gdd-summary.sh ${slug}\`"
    } > "$out"

    # Enforce hard cap (200 content lines)
    local generated_lines
    generated_lines=$(wc -l < "$out")
    if (( generated_lines > 200 )); then
        log "WARN: ${slug} summary is ${generated_lines} lines (cap is 200) — truncating"
        head -200 "$out" > "${out}.tmp" && mv "${out}.tmp" "$out"
        echo "" >> "$out"
        echo "*(truncated at 200 lines; see source GDD for full content)*" >> "$out"
    fi

    log "wrote ${out} (${generated_lines} lines)"
}

# ---------------------------------------------------------------
# Merge a single GDD's anchors into _anchors.json.
# Uses jq to keep a deterministic merge; creates the file if missing.
# ---------------------------------------------------------------
update_anchors() {
    local gdd_path="$1"
    local slug
    slug=$(slug_from_path "$gdd_path")
    local base
    base=$(basename "$gdd_path")
    local total
    total=$(wc -l < "$gdd_path")
    local generated_at
    generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Build a JSON object for this GDD's sections.
    local sections_json
    # emit_anchors_tsv columns: level(H2|H3) \t heading \t line_start \t line_end
    sections_json=$(emit_anchors_tsv "$gdd_path" | jq -Rs '
        split("\n")
        | map(select(length > 0))
        | map(split("\t"))
        | map({key: ("§" + .[1]),
               value: {level: .[0],
                       line_start: (.[2] | tonumber),
                       line_end: (.[3] | tonumber),
                       line_count: ((.[3] | tonumber) - (.[2] | tonumber) + 1)}})
        | from_entries
    ')

    local file_entry
    file_entry=$(jq -n \
        --arg path "$gdd_path" \
        --arg slug "$slug" \
        --argjson total "$total" \
        --argjson sections "$sections_json" \
        '{path: $path, slug: $slug, total_lines: $total, sections: $sections}')

    if [[ -f "$ANCHORS_FILE" ]]; then
        # merge into existing
        jq --arg base "$base" \
           --arg ts "$generated_at" \
           --argjson entry "$file_entry" \
           '.generated = $ts | .files[$base] = $entry' \
           "$ANCHORS_FILE" > "${ANCHORS_FILE}.tmp" \
        && mv "${ANCHORS_FILE}.tmp" "$ANCHORS_FILE"
    else
        # fresh file
        jq -n --arg base "$base" \
              --arg ts "$generated_at" \
              --argjson entry "$file_entry" \
              '{version: 1, generated: $ts, files: {($base): $entry}}' \
              > "$ANCHORS_FILE"
    fi
    log "updated ${ANCHORS_FILE} for ${slug}"
}

# ---------------------------------------------------------------
# --check mode: stale if summary missing, source -nt summary, OR the
# `Source mtime:` line recorded inside the summary doesn't match the
# current source mtime. The recorded-mtime check is the load-bearing
# one — it catches the edge case where source and summary share the
# same to-the-second mtime (common when an Edit hook regenerates the
# summary immediately after the source edit; bash `-nt` is second-
# resolution and returns false). This pattern hit twice on 2026-05-17
# (n4 in n-cluster-verify, n9 in n9-n10-verify).
# ---------------------------------------------------------------
check_freshness() {
    local stale_count=0
    while IFS= read -r -d '' gdd; do
        local slug
        slug=$(slug_from_path "$gdd")
        local summary="${SUMMARIES_DIR}/${slug}.md"
        case "$slug" in
            systems-index|gdd-cross-review-*|game-concept) continue ;;
        esac
        if [[ ! -f "$summary" ]]; then
            echo "STALE: ${slug} (no summary)"
            stale_count=$((stale_count + 1))
            continue
        fi
        if [[ "$gdd" -nt "$summary" ]]; then
            echo "STALE: ${slug} (source newer than summary)"
            stale_count=$((stale_count + 1))
            continue
        fi
        # Recorded-mtime check (catches same-second writes that defeat -nt).
        # Summary line: `> Generated: <ts>. Source mtime: <iso-ts>.`
        local recorded_mtime
        recorded_mtime=$(grep -oE 'Source mtime: [0-9T:-]+Z' "$summary" \
                         | head -1 \
                         | sed -E 's/^Source mtime: //')
        if [[ -n "$recorded_mtime" ]]; then
            local current_mtime
            current_mtime=$(date -u -r "$gdd" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || true)
            if [[ -n "$current_mtime" && "$recorded_mtime" != "$current_mtime" ]]; then
                echo "STALE: ${slug} (recorded source mtime ${recorded_mtime} ≠ current ${current_mtime})"
                stale_count=$((stale_count + 1))
                continue
            fi
        fi
    done < <(find "$GDD_DIR" -maxdepth 1 -type f -name '*.md' -print0)
    if (( stale_count > 0 )); then
        echo "${stale_count} stale summary/summaries detected" >&2
        exit 3
    fi
    log "all summaries fresh"
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------

[[ $# -eq 0 ]] && { show_help; }

case "$1" in
    --help|-h)
        show_help
        ;;
    --check)
        [[ ! -f "$SYSTEMS_INDEX" ]] && die "${SYSTEMS_INDEX} not found" 2
        check_freshness
        ;;
    --all)
        [[ ! -f "$SYSTEMS_INDEX" ]] && die "${SYSTEMS_INDEX} not found" 2
        count=0
        while IFS= read -r -d '' gdd; do
            slug=$(slug_from_path "$gdd")
            # Skip meta files
            case "$slug" in
                systems-index|gdd-cross-review-*|game-concept) continue ;;
            esac
            generate_summary "$gdd"
            update_anchors "$gdd"
            count=$((count + 1))
        done < <(find "$GDD_DIR" -maxdepth 1 -type f -name '*.md' -print0)
        log "regenerated ${count} summaries"
        ;;
    --*)
        die "unknown flag '$1' (try --help)" 1
        ;;
    *)
        [[ ! -f "$SYSTEMS_INDEX" ]] && die "${SYSTEMS_INDEX} not found" 2
        gdd_path=$(resolve_slug "$1")
        generate_summary "$gdd_path"
        update_anchors "$gdd_path"
        ;;
esac
