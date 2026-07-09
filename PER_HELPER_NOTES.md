# Per-Helper Notes

> One section per script: **what it does**, **when it pays off**, **what to adapt**, and **integration touch-points**. Adopt one at a time; measure before adopting the next.

---

## `partial-read-helper.sh` — the universal foundation

**What it does.** Locates a pattern in a file via `grep -n`, computes a defensible Read offset/limit window around it, and emits the Read call Claude should issue.

**Usage:**
```bash
tools/dev/partial-read-helper.sh design/gdd/big-gdd.md "Acceptance Criteria"
# → Found 1 match for "Acceptance Criteria" at line 412.
# → Suggested Read call: Read("design/gdd/big-gdd.md", offset=400, limit=80)
```

**When it pays off.** Any file >500 lines that you need to look at a specific section of. Avoids reading the full file. Token cost: ~200 vs ~40k for a full read. This is the lowest-friction helper to adopt and the highest-impact for early CCGS projects.

**What to adapt.** Nothing. Works on any text file with grep-able anchors. Project-agnostic.

**Integration touch-points** (when to suggest this helper in skill workflows):
- `/design-review`, `/code-review`, `/architecture-review` — when the skill needs to read a specific GDD/ADR section.
- `/dev-story` — when the story file references a specific ADR section.
- `/story-readiness` — when verifying a specific AC against the GDD.
- Any skill that does "find X in file Y and read the surrounding context."

**Notes.**
- The harness "Edit must Read first" rule is satisfied by ANY prior Read — partial counts.
- Read with `limit: 200` is the soft cap I recommend even when you don't have an anchor (the Read tool fails opaquely past ~25k tokens on the Claude Code web client).

---

## `rotate-active.sh` — incremental archival of session state

**What it does.** Reads `production/session-state/active.md`. If the file exceeds 200 lines, splits by `## Session Extract` anchors, keeps the 5 newest in the active file, and archives the rest to `production/session-logs/active-archive-YYYY-MM-DD.md`.

**Usage:**
```bash
bash tools/dev/rotate-active.sh
# STATUS=rotated
# KEPT=5
# ARCHIVED=12
# ARCHIVE=production/session-logs/active-archive-2026-05-30.md
```

Or when under threshold:
```bash
# STATUS=skipped-under-threshold
# KEPT=7
# ARCHIVED=0
```

**When it pays off.** When `active.md` has accumulated 5+ sessions of state. The file becomes the load-bearing memory between compactions, and unbounded growth makes session-start hooks expensive. Rotation keeps the file at a usable size while preserving the full audit trail.

**What to adapt.**
- Schema: the rotator splits by `## Session Extract — YYYY-MM-DD — Title` anchors. If your project uses a different schema, edit the regex in the script. See `docs/active-md-template.md` for the canonical schema.
- Threshold (200 lines): tunable in the script. The 5-newest-extracts default works for sprint-per-week pace; tune up if you write more extracts per sprint.

**Integration touch-points.**
- `.claude/hooks/session-stop.sh` — call rotator on session end.
- `.claude/skills/story-done/SKILL.md` — call rotator after writing the close-out Session Extract (Phase 7).
- `.claude/hooks/validate-active-md.sh` (recommended) — warn on PostToolUse if a writer used a non-conforming H2 anchor.

**Notes.**
- Adopt this together with `docs/active-md-template.md`. Half-adoption (rotator without the schema) produces silent rotation failures because the rotator can't find the anchors.
- Bulk-rotation fallback: if the file is over threshold but has fewer than 6 `Session Extract` anchors, the rotator archives the whole body and resets — STATUS=rotated-bulk.

---

## `dedupe-deferred.sh` — register summary + cap-pressure

**What it does.** Summarises `production/deferred-items.md` (the OPEN/RESOLVED register for tech-debt / forward-pointers / scoped-out work). Returns counts, next minted ID, cap pressure, and (with `--grep`) duplicate-by-description checks.

**Usage:**
```bash
tools/dev/dedupe-deferred.sh
# OPEN=24
# RESOLVED=28
# TOTAL=52
# NEXT_ID=OPEN-054
# HIGHEST_ID=OPEN-053
# CAP=50
# CAP_PRESSURE=ok
# DUPLICATE_IDS=

tools/dev/dedupe-deferred.sh --grep "fallback substitution"
# Searches OPEN + RESOLVED bodies for the phrase; returns matching rows.
```

**When it pays off.** As soon as you have 10+ OPEN items. The register grows fast in mid-sprint planning; full-reading it through Read costs 5-15k tokens per skill invocation. The helper emits ~50 tokens.

**What to adapt.**
- File path: hardcoded to `production/deferred-items.md`. Adjust if your project uses a different location.
- Cap threshold (50): tunable. The cap protects against unbounded forward-pointer accumulation. Lower it if your project wants tighter sprint-cleanup discipline.
- OPEN-NNN format: the script assumes 3-digit zero-padded sequence. If you use a different ID format, edit the regex.

**Integration touch-points.** Almost every skill that mints or queries OPEN-NNN entries:
- `/code-review` — when adding deferred items from a review.
- `/sprint-plan` — when scanning existing OPEN-NNN for sprint inclusion.
- `/story-readiness` — when checking trigger conditions on existing entries.
- `/story-done` — when verifying closures (OPEN-NNN → RESOLVED-NNN flips).
- `/scope-check`, `/tech-debt`, `/retrospective` — all read register state.

**Notes.**
- The CAP_PRESSURE flag turns to `warn` past the configured threshold. Skills should surface that to the user instead of silently absorbing it.
- The `NEXT_ID` output is the authoritative source for minting new entries — never let Claude guess the next ID by reading the register.

---

## `adr-summary.sh` + `adr-lookup.sh` — ADR corpus compression

**What it does.**
- `adr-summary.sh` builds and reads pre-computed per-ADR summaries at `docs/architecture/_summaries/adr-NNNN.md` (~1.5k tokens each vs ~5-10k for the full ADR — ~3.2× compression).
- `adr-lookup.sh` resolves an ADR number + section heading to a Read offset/limit (`partial-read-helper.sh` specialised for ADRs).

**Usage:**
```bash
# Summary surface
tools/dev/adr-summary.sh --all          # all summaries, one block each
tools/dev/adr-summary.sh 0023            # one ADR's summary
tools/dev/adr-summary.sh --check         # detect staleness (summaries older than source ADRs)
tools/dev/adr-summary.sh --layer foundation  # one architectural layer

# Lookup surface
tools/dev/adr-lookup.sh 0023 --list      # list all section headings + line ranges
tools/dev/adr-lookup.sh 0023 Decision    # emit Read call for the Decision section
tools/dev/adr-lookup.sh 0023 Decision --emit-read
# Read("docs/architecture/adr-0023-some-decision-slug.md", offset=145, limit=444)
```

**When it pays off.** As soon as you have 10+ ADRs. `/architecture-review`, `/create-stories`, `/dev-story`, `/story-readiness` all query the ADR corpus repeatedly. The summary layer drops review-class skill spend on ADR reads by ~3-5×.

**What to adapt.**
- ADR location: hardcoded to `docs/architecture/adr-NNNN-*.md`. Adjust the glob if your project uses a different naming convention.
- Summary location: `docs/architecture/_summaries/adr-NNNN.md` is the default. Pick somewhere `.gitignore`-friendly if you don't want to commit them, OR commit them and let CI keep them fresh (see hook integration below).
- Layer classification: the `--layer foundation|core|feature|presentation` flag uses a manifest at `docs/architecture/_summaries/_layers.json`. Author the manifest manually or skip the flag.

**Integration touch-points.**
- `.claude/hooks/validate-adr-write.sh` — re-run `adr-summary.sh --rebuild` for the modified ADR on PostToolUse. Keeps summaries fresh.
- `/create-epics`, `/create-stories` — call `adr-summary.sh` instead of full-Reading ADRs.
- `/story-readiness`, `/dev-story` — call `adr-lookup.sh` for specific section lookups.
- `CLAUDE.md` — reference both in the project helpers section.

**Notes.**
- The summary format is project-specific (per-ADR doc fields, decision summary, consequences, related ADRs). You'll likely want to tweak the summary template — see the script's `--rebuild-anchors` mode and the example output to understand the schema.
- Stale-summary detection (`--check`) is critical. Without it, summaries drift silently when an ADR is edited but the summary isn't regenerated.

---

## `gdd-summary.sh` + `gdd-lookup.sh` — GDD corpus compression

**What it does.** Same shape as the ADR pair but for game design docs at `design/gdd/`.

**Usage:**
```bash
tools/dev/gdd-summary.sh combat            # one GDD's summary
tools/dev/gdd-summary.sh --all             # all
tools/dev/gdd-summary.sh --check           # staleness detection
tools/dev/gdd-lookup.sh combat "Acceptance Criteria" --emit-read
```

**When it pays off.** As soon as you have 10+ GDDs. This is the largest single context-cost win — GDDs are typically the biggest files in a CCGS project. On a ~100-GDD deployment, `/review-all-gdds` dropped from ~430k → ~63k tokens when GDD summaries shipped (~85% reduction).

**What to adapt.** Same as ADR pair, but for GDD location + summary location. The per-GDD summary schema (Overview, Player Fantasy, Mechanics summary, Open Questions, Status) is project-specific — adapt the template.

**Integration touch-points.**
- `.claude/hooks/validate-gdd-write.sh` — re-run summary rebuild on PostToolUse.
- Every review-class skill (`/design-review`, `/review-all-gdds`, `/consistency-check`, `/architecture-review`) — refit to read summaries first, escalate to partial reads as needed.
- `/design-system` — partial-read the current section being authored; never full-read the GDD.

---

## `registry-summary.sh` + `registry-lookup.sh` — entity registry compression

**What it does.** Summarises and looks up entries in a large entity registry (typical scenario: a registry at `design/registry/entities.yaml` grows past ~100k tokens; the summary layer drops it to ~5k for cross-reference queries).

**Usage:**
```bash
tools/dev/registry-summary.sh           # counts + top categories
tools/dev/registry-summary.sh --check   # staleness
tools/dev/registry-lookup.sh --id=some_entity_id
tools/dev/registry-lookup.sh --by-source=some_gdd.md
```

**When it pays off.** If your project uses a single canonical YAML/JSON registry for entities, items, abilities, or any other cross-referenced corpus, AND it grows past ~5k tokens.

**What to adapt.** Heavily. The registry schema is project-specific. The source deployment's registry had fields like `semantic_key`, `source_gdd`, `referenced_by`, `mvp_status` — your registry will have different fields. Use these scripts as a structural template; rewrite the parsing logic.

**Integration touch-points.**
- `.claude/hooks/validate-registry-write.sh` — refresh summary on write.
- `/consistency-check` — verify entity references across the corpus.
- `/architecture-review`, `/design-system` — query the registry without full-reading.

---

## `count-todos.sh` — tech-debt indicator

**What it does.** Walks the project for TODO / FIXME / HACK / XXX markers in source code; emits counts by category + by directory + (optional) growth-trend vs a saved baseline.

**Usage:**
```bash
tools/dev/count-todos.sh
# TODO=12
# FIXME=3
# HACK=1
# XXX=0
# TOTAL=16
# BY_DIR: src/combat=4, src/ui=2, ...
```

**When it pays off.** As a retrospective/health-check signal. Track the count over sprints — growing TODO counts are usually forward-pointer authoring (acceptable), but stable-or-decreasing means active cleanup.

**What to adapt.** The directories scanned (the script ships with engine-specific scope paths from its source deployment) and the marker tokens (TODO/FIXME/HACK/XXX). Most projects need only minor tweaks to point at their source-code roots.

**Integration touch-points.**
- `/retrospective` — report the count as a sprint-over-sprint trend indicator.
- `/tech-debt` — baseline source for the debt register.

**Notes.** Don't over-index on this metric. Forward-pointer TODOs (e.g., `// TODO: refit when X lands sprint-N+1`) are healthy; stale-debt TODOs (`// TODO: fix this`) are not. The count alone doesn't distinguish them — use it as a directional signal, not a hard target.

---

## What's NOT in this bundle (and why)

The source deployment's `tools/dev/` directory has 13 additional scripts that are intentionally excluded because they encode project-specific design rules:

- `check-pillar-names.sh`, `check-bidirectionality.sh`, `check-residue.sh`, `check-provisional-contracts.sh`, `check-locked-constant-citations.sh`, `check-gdd-headers.sh`, `check-skill-vs-rules.sh`, `check-status-drift.sh`, `check-phase-drift.sh`, `registry-selfcheck.sh`, `registry-migrate-source.sh` — these all enforce project-specific conventions (design-pillar naming, GDD section bidirectionality, status-tag vocabulary, phase-token canonical set, etc.). Useful as **patterns** for your own project's convention enforcement — read the patterns and adapt them. NOT useful as drop-in code.
- Two engine-specific test runners — skip unless you use the same engine + DI stack.

If you want a description of any of these as a starting template for your own project's convention enforcement, ask in the issue thread.
