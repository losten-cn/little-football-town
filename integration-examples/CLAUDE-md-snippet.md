# CLAUDE.md snippet — Project Helpers section

Drop this into your project's `CLAUDE.md` (typically near the bottom, after the engine + technical preferences sections). Adapt the helpers list to what you've actually installed.

---

## Project Helpers (tools/dev/)

The following bash helpers are project-wide. ALL skills SHOULD use them when applicable to avoid loading large files into agent context:

- **`tools/dev/partial-read-helper.sh <file> <pattern>`** — locate a pattern in
  a large file and emit `Read` offset/limit ranges for partial reads. Use this
  when the target file is >500 lines and you need to find a specific anchor.
  Token cost: ~200 vs ~40k for a full read. The harness "Edit must Read first"
  rule is satisfied by ANY prior `Read` — partial counts.

- **`tools/dev/rotate-active.sh`** — rotate `production/session-state/active.md`
  when it exceeds 200 lines. Keeps 5 newest extracts; archives the rest to
  `production/session-logs/active-archive-YYYY-MM-DD.md`. Run after `/story-done`
  or on demand.

- **`tools/dev/dedupe-deferred.sh`** — summarise `production/deferred-items.md`
  without loading it. Returns counts, next ID, cap pressure, duplicates. ALL
  skills that interact with the deferred register MUST read it through this
  helper, not by direct `Read` of the register.

- **`tools/dev/gdd-summary.sh <slug> | --all | --check`** — GDD corpus summary
  layer. Per-GDD summaries live at `design/gdd/_summaries/<slug>.md` (~1.5k
  tokens each vs ~30k full); use `--check` to detect staleness.

- **`tools/dev/gdd-lookup.sh <slug> <section> [--emit-read | --list]`** —
  resolve a GDD slug + section to a Read offset/limit. Heading-based.

- **`tools/dev/registry-summary.sh | --check`** — registry corpus summary
  layer for `design/registry/entities.yaml` (when it grows past ~5k tokens).
  Use the summary index instead of full registry reads.

- **`tools/dev/registry-lookup.sh`** — fetch one or more entities from the
  registry without loading the whole file.

- **`tools/dev/adr-summary.sh <NNNN> | --all | --check | --layer <name> | --rebuild-anchors`** —
  ADR corpus summary layer. Per-ADR summaries at
  `docs/architecture/_summaries/adr-NNNN.md` (~1.5k tokens each vs ~5–10k
  full ADR; ~3.2× compression for full set). Use `--layer foundation|core|feature|presentation`
  to emit one layer's set.

- **`tools/dev/adr-lookup.sh <NNNN> <section> [--emit-read | --list]`** —
  resolve an ADR number + section to a Read offset/limit. Heading-based.

When a workflow pattern repeats and burns context, add a helper to `tools/dev/`
and reference it here. Helpers are documented in their own `--help` output.

**Three-tier read budget (load-bearing).** `/create-epics`, `/create-stories`,
`/dev-story`, and `/story-readiness` (and any other skill that queries the
ADR/GDD corpus) should default to a Tier 1 (summaries + manifest) / Tier 2
(anchor-targeted partial reads) / Tier 3 (full read with justification)
discipline. Tier 3 reads require a one-sentence justification in the
user-facing turn.

---

## Context Management

@.claude/docs/context-management.md

> **Load-bearing:** the "Remediation Trigger" section of
> `context-management.md` is the always-loaded backstop for token-cost
> drift. If you notice repeated full-Reads, expensive grep/scan
> duplication across skills, or a new corpus growing past the GDD-style
> inflection without a summary layer, **flag it as a proposal** before
> continuing the task.

---

## active.md Template Convention

@.claude/docs/active-md-template.md

> **Applies to:** every skill, hook, or agent that writes to
> `production/session-state/active.md`. The rotator splits the file by
> `## Session Extract — …` anchors; non-conforming top-level H2s are
> invisible to incremental rotation.
