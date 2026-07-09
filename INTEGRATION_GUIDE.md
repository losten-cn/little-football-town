# Integration Guide

> How to wire these helpers into your CCGS project's skills, hooks, and CLAUDE.md. Adopt one helper + its integration touch-points at a time, verify the impact, then move to the next.

---

## Phase 0 — Install the scripts

Drop everything in `scripts/` into your project's `tools/dev/` directory:

```bash
mkdir -p tools/dev
cp -R ccgs-context-helpers-2026-05-30/scripts/* tools/dev/
chmod +x tools/dev/*.sh
```

Verify each script runs without crashing on an empty input:

```bash
# Universal helper — should always work
tools/dev/partial-read-helper.sh tools/dev/partial-read-helper.sh "Usage"

# Register helper — requires production/deferred-items.md to exist;
# create an empty stub if you don't have one yet:
mkdir -p production
touch production/deferred-items.md
tools/dev/dedupe-deferred.sh
```

Output should show `OPEN=0`, `RESOLVED=0`, `NEXT_ID=OPEN-001` (or your start ID).

---

## Phase 1 — Adopt `partial-read-helper.sh`

This is the lowest-friction, highest-ROI starting move. No project state changes required.

**Add to your `CLAUDE.md`:**

```markdown
## Project Helpers (tools/dev/)

ALL skills SHOULD use these when applicable to avoid loading large files into agent context:

- **`tools/dev/partial-read-helper.sh <file> <pattern>`** — locate a pattern
  in a large file and emit `Read` offset/limit ranges for partial reads.
  Use this when the target file is >500 lines and you need a specific
  anchor. Token cost: ~200 vs ~40k for a full read. The harness "Edit must
  Read first" rule is satisfied by ANY prior `Read` — partial counts.
```

**Mention it in your largest skill files** (e.g., `/design-review`, `/code-review`):

```markdown
**For files >500 lines**, use `tools/dev/partial-read-helper.sh` to find anchor
points first rather than a full read.
```

**Memory entry** (optional but recommended): copy `memory-reference/feedback_large_file_reads.md` into your `~/.claude/projects/<your-project>/memory/` directory and add the title to your `MEMORY.md` index. This makes Claude self-correct when reaching for a full Read of a large file.

---

## Phase 2 — Adopt the Remediation Trigger backstop

This is the always-loaded behavioural rule that catches systemic context-cost drift.

**Add to your `.claude/docs/`** directory:

```bash
cp ccgs-context-helpers-2026-05-30/docs/context-management.md .claude/docs/
```

The file ships with a `## Remediation Trigger — flag context-cost issues, don't just live with them` section that is the load-bearing piece.

**Reference it from your `CLAUDE.md`:**

```markdown
## Context Management

@.claude/docs/context-management.md

> **Load-bearing:** the "Remediation Trigger" section of
> `context-management.md` is the always-loaded backstop for token-cost
> drift. If you notice repeated full-Reads, expensive grep/scan
> duplication across skills, or a new corpus growing past the GDD-style
> inflection without a summary layer, **flag it as a proposal** before
> continuing the task.
```

The `@.claude/docs/...` syntax is CCGS's auto-include directive — it loads the file's content into the CLAUDE.md context.

**Memory entry:** copy `memory-reference/feedback_remediation_trigger.md` into your memory directory.

This adoption is text-only — no scripts, no hooks. The behavioural rule sits behind the helpers.

---

## Phase 3 — Adopt `dedupe-deferred.sh` (if you have a register)

Skip this phase if your project doesn't use `production/deferred-items.md` for tech-debt / forward-pointers / scoped-out work. If you DO use a register, this is the highest-ROI integration after Phase 1.

**Add to your `CLAUDE.md` helpers section:**

```markdown
- **`tools/dev/dedupe-deferred.sh`** — summarise `production/deferred-items.md`
  without loading it. Returns counts, next ID, cap pressure, duplicates.
  ALL skills that interact with the deferred register MUST read it through
  this helper, not by direct `Read` of the register.
```

**Add a "Deferred-item write protocol" section to skills that mint OPEN-NNN entries** — `/code-review` is the canonical example:

```markdown
**Deferred-item write protocol (MANDATORY).** Per `CLAUDE.md` Project Helpers
and `production/deferred-policy.md` §6, deferred IDs are minted sequentially
and the helper is the authority. Before appending a new OPEN-NNN row:

1. Run `tools/dev/dedupe-deferred.sh` and parse `NEXT_ID=OPEN-NNN` from
   stdout. Use that ID — never guess or read the register directly.
2. Run `tools/dev/dedupe-deferred.sh --grep "<short description>"` to check
   for duplicate-by-description before appending.
3. Append the new row via Edit. Format: `- OPEN-NNN [SEV-tier] [area] description`.
4. After append, re-run `tools/dev/dedupe-deferred.sh` to confirm
   `CAP_PRESSURE=ok` and the entry counts incremented correctly.

Skipping the helper risks duplicate IDs if two sessions race.
```

**Author `production/deferred-policy.md`** if you don't have one — it defines the cap, the closure protocol (OPEN-NNN → RESOLVED-NNN flip + relocation under a `## RESOLVED items` H2), and the format. Ask in the issue thread if you want a starting template.

---

## Phase 4 — Adopt `rotate-active.sh` + the Session Extract schema

This is the rotation pattern for `production/session-state/active.md`. Adopt the schema and the rotator together.

**Install the schema doc:**

```bash
cp ccgs-context-helpers-2026-05-30/docs/active-md-template.md .claude/docs/
```

**Reference it from `CLAUDE.md`:**

```markdown
## active.md Template Convention

@.claude/docs/active-md-template.md

> **Applies to:** every skill, hook, or agent that writes to
> `production/session-state/active.md`. The rotator splits the file by
> `## Session Extract — …` anchors; non-conforming top-level H2s are
> invisible to incremental rotation and trigger bulk rotation only when
> the file exceeds 200 lines.
```

**Update writers to use the schema.** Every skill that writes to `active.md` (typically `/story-done`, `/dev-story`, `/design-review`, hooks like `session-stop.sh`) needs to emit:

```markdown
## Session Extract — YYYY-MM-DD HH:MM — [Short Title]

- **TL;DR:** <≤200 chars, single line, plain prose>

[body]
```

PREPEND new extracts after the header, never append at the bottom — newest-on-top so the rotator keeps the most-recent.

**Hook the rotator into session-stop:**

```bash
# .claude/hooks/session-stop.sh
#!/bin/bash
# ... your existing session-stop logic ...
bash tools/dev/rotate-active.sh
```

**Hook the rotator into `/story-done` Phase 7** after the Session Extract write:

```markdown
### Active.md rotation (post-update)

After appending the Session Extract, silently run:

    bash tools/dev/rotate-active.sh

If the helper output reports `STATUS=rotated`, briefly note in conversation:
"Rotated active.md — [N] extracts archived to [path]." Otherwise no note.
```

**Optional: add `.claude/hooks/validate-active-md.sh`** as a PostToolUse hook that warns when a writer used a non-conforming top-level H2. A short reference implementation is in `integration-examples/hook-keep-index-fresh.md`.

---

## Phase 5 — Adopt corpus summary helpers as your corpora grow

The summary helpers (`adr-summary.sh`, `gdd-summary.sh`, `registry-summary.sh`) are higher-friction adoptions because they require:

1. Authoring per-item summary templates.
2. Adding PostToolUse hooks to keep summaries fresh.
3. Refitting consumer skills to read summaries first.

**Trigger threshold.** Don't adopt these until you hit the second `/review-all-gdds` (or equivalent) invocation that spends >100k tokens on full-Reads. That's the signal that the corpus has reached the inflection.

**For each corpus you want to summarise:**

1. **Author per-item summaries.** Walk your corpus and create `_summaries/<item>.md` files (~1-2k tokens each). The summary schema is project-specific — for GDDs it's typically Overview + Player Fantasy + Detailed Design highlights + Open Questions + Status; for ADRs it's Summary + Decision Summary + Consequences + Related ADRs.

2. **Install the matching helper.** Adapt the `<domain>-summary.sh` + `<domain>-lookup.sh` pair to your project's file paths.

3. **Add a PostToolUse hook** that re-runs the summary rebuild when an item is edited. The hook script body:

   ```bash
   # .claude/hooks/validate-gdd-write.sh — example shape
   #!/bin/bash
   file="$1"
   if [[ "$file" =~ ^design/gdd/.*\.md$ ]]; then
     bash tools/dev/gdd-summary.sh "$(basename "$file" .md)" --rebuild
   fi
   ```

4. **Refit consumer skills** to call the summary helper instead of full-Reading. Example diff for a `/design-review`-shape skill:

   ```diff
   - Read each GDD in scope (typically 3-5 GDDs, each ~30k tokens).
   + Read summaries via `tools/dev/gdd-summary.sh --all` (Tier 1).
   + Escalate to anchor-targeted partial reads via `gdd-lookup.sh` (Tier 2).
   + Full-read a GDD (Tier 3) only when authoring or auditing structure.
   ```

5. **Reference both in CLAUDE.md** Project Helpers section.

See `integration-examples/skill-3-tier-read-budget-refit.md` for a full example.

---

## Phase 6 — Adopt `count-todos.sh` (optional / retrospective signal)

Low-priority adoption. Useful if you want sprint-over-sprint tech-debt trend data; not load-bearing for context-cost.

```bash
tools/dev/count-todos.sh
```

Reference from `/retrospective` and `/tech-debt` skills.

---

## Per-skill integration touch-points (quick reference table)

| Skill | Touch-point | Helper to add |
|---|---|---|
| `/design-review` | Reading the target GDD's sections | `partial-read-helper.sh`, `gdd-lookup.sh` |
| `/design-review` | Reading sibling GDDs for cross-reference | `gdd-summary.sh --all` (Tier 1) |
| `/review-all-gdds` | Iterating the GDD corpus | `gdd-summary.sh --all` |
| `/consistency-check` | Cross-GDD entity references | `registry-summary.sh`, `registry-lookup.sh` |
| `/architecture-review` | Reading ADR Decision sections | `adr-summary.sh`, `adr-lookup.sh` |
| `/create-epics`, `/create-stories` | Reading multiple ADRs per epic | `adr-summary.sh --layer <layer>` |
| `/dev-story` | Reading the story's referenced ADR section | `adr-lookup.sh <NNNN> <section>` |
| `/story-readiness` | Trigger-condition scan over OPEN-NNN entries | `dedupe-deferred.sh --grep` |
| `/code-review` | Minting OPEN-NNN entries from review findings | `dedupe-deferred.sh` (NEXT_ID + dupe check) |
| `/code-review` | Reading large source files | `partial-read-helper.sh` |
| `/story-done` | Verifying OPEN-NNN closures | `dedupe-deferred.sh --grep "<STORY-ID>"` |
| `/story-done` | Writing close-out Session Extract + rotation | `rotate-active.sh` |
| `/sprint-plan` | Existing-debt scan over OPEN-NNN | `dedupe-deferred.sh` |
| `/retrospective` | TODO-count trend | `count-todos.sh` |
| `/scope-check`, `/tech-debt` | Register state | `dedupe-deferred.sh` |
| Session-start hook | Preview active state | `rotate-active.sh` (read mode), `dedupe-deferred.sh` |
| Session-stop hook | Rotate active.md | `rotate-active.sh` |
| PostToolUse: GDD edit | Rebuild GDD summary | `gdd-summary.sh <slug> --rebuild` |
| PostToolUse: ADR edit | Rebuild ADR summary | `adr-summary.sh <NNNN> --rebuild` |
| PostToolUse: register edit | Re-validate cap pressure | `dedupe-deferred.sh` (and warn) |
| PostToolUse: active.md edit | Validate schema | `validate-active-md.sh` (project-specific) |

---

## Adoption order recommendation

If you're starting fresh, in priority order:

1. **`partial-read-helper.sh` + the Remediation Trigger backstop.** Zero state changes, immediate ~50× token reduction on partial reads.
2. **`dedupe-deferred.sh` + write protocol** (only if you use the register).
3. **`rotate-active.sh` + Session Extract schema** (when `active.md` first crosses ~150 lines).
4. **`adr-summary.sh` / `gdd-summary.sh`** (when your corpus crosses ~10 items / ~100k tokens).
5. **`registry-summary.sh`** (when you have a registry past ~5k tokens).
6. **`count-todos.sh`** (whenever you want sprint-over-sprint trend data).

Don't try to adopt everything at once. A typical adoption sequence is sprint 1 (`partial-read-helper`) → sprint 3 (`dedupe-deferred` + `rotate-active`) → sprint 5 (`gdd-summary`) → sprint 6 (`adr-summary`) → ongoing. Each adoption is triggered by a measurable pain point, not pre-built.

---

## Common pitfalls

- **Adopting summary helpers without freshness hooks.** Summaries drift silently when items are edited. The `--check` flag detects staleness; the PostToolUse hook prevents it. Adopt them as a pair.
- **Half-adopting the active.md schema.** Writers that emit `## Notes` or `## Findings` instead of `## Session Extract` are invisible to the rotator. Either enforce the schema via PostToolUse warnings or accept periodic bulk rotation.
- **Treating helpers as universally correct.** The dedupe-deferred cap of 50 is a project-specific tuning choice from the source deployment. Your project's threshold may differ. Read the script, understand the assumption, tune to your project.
- **Pre-building helpers for corpora that haven't grown yet.** Wait for the second recurrence of the pain point. Pre-built helpers for files you haven't accumulated are overhead.
- **Stacking helpers without retiring complexity.** Every new helper should let you delete an existing step or simpler helper. If it doesn't, ask whether the data model is the actual problem (`PRINCIPLES.md` §4).
