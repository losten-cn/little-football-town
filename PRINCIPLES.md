# Principles — Why these helpers exist

> **Read this before adopting any helper.** The patterns matter more than the scripts. If you adopt the scripts without the patterns, you'll re-create the same context-cost problem two sprints later when your project grows.

---

## 1. The Read-tool tax

Every full Read of a 40k-token file costs 40k tokens against Claude's context window AND ~3-4 seconds wall time on the harness. A 200-line file at 100 tokens per line = ~20k tokens; a 600-line GDD = ~60k tokens. A skill that reads four such files (e.g., `/design-review` reading the target GDD + 2 sibling GDDs + 1 ADR) burns ~240k tokens before doing any work.

A skill that re-reads the same file across the session pays the tax multiple times. A multi-skill chain (`/design-review` → `/architecture-review` → `/code-review` → `/story-done`) that all touch the same corpus pays it once per skill.

**Bash on disk is cheaper.** `grep -n "Acceptance Criteria" big-gdd.md` returns one line in ~50ms. The line number → Read offset/limit emits ~50 tokens of structured output. Total cost: ~50 tokens vs ~60,000.

---

## 2. The 3-tier read budget

For any corpus past the inflection point (~15 files / ~100k total tokens), refit consumer skills to a 3-tier read discipline:

- **Tier 1 — summaries + index.** Every skill that needs corpus-wide awareness reads ≤2k tokens of pre-computed summaries plus a manifest. This is the default tier for plan-time / pre-flight / consistency-check work.
- **Tier 2 — anchor-targeted partial reads.** When a specific section is needed, use the `<domain>-lookup.sh` helper to resolve heading → Read offset/limit, then partial-Read ~50-200 lines. This is the default tier for story-readiness / dev-story / code-review work.
- **Tier 3 — full read.** Only when the structure of the file is the subject of the work (authoring, refactoring, validation against the file's own internal consistency). Requires a one-sentence justification in the user-facing turn so future-you can audit whether the full read was actually necessary.

Skills written before adopting this discipline default to Tier 3. Skills refit afterward should pick Tier 1 by default and escalate only when the task demands it. On a ~100-GDD CCGS deployment, refitting the GDD corpus from Tier 3 → Tier 1 default dropped `/review-all-gdds` invocation spend from ~430k → ~63k tokens (~85% reduction).

---

## 3. The helper-trigger threshold

**Write a helper at the SECOND recurrence of a pain point. Not the first. Not the fifth.**

- First time is reconnaissance. Maybe the workflow only needs the lookup once and the cost is bounded.
- Second time means the workflow's shape needs the lookup. Build the helper now while the cost is fresh — the third+ time will pay for the helper twice over.
- Fifth time means you've been silently absorbing the cost for too long. The user / future-you has to remind us to use helpers that should already exist.

The threshold matters because **pre-built helpers for files that haven't grown yet are the same anti-pattern as premature abstraction**. A helper for a corpus you haven't accumulated is overhead. A helper for a corpus you Read four times last sprint is leverage.

---

## 4. Tool stack discipline (don't patch the blind spot of the previous tool)

When a defect class escapes an existing helper, the default reaction is to write a new helper that catches it. **Stop and ask whether the data model is the actual problem first.**

If three rounds of similar bugs all need new validators, the model is wrong. Fix the model. Don't stack a fifth validator on top of the existing four.

A correct helper that occupies the wrong layer is still wrong. The retirement test: **does this new helper let me delete one or more existing helpers or skill steps?** If no, the answer is probably "fix the data model" not "build the helper."

Concrete example from the source deployment: three GDD-bidirectionality validators detecting drift between a GDD's "Depends on" and "Used by" sections. The fourth recurrence revealed the actual problem: the section should not be free-text prose at all — it should reference the systems-index by ID. A model fix that retired all four validators. Net tool count went DOWN.

---

## 5. The Remediation Trigger (the always-loaded backstop)

Memory entries codify behavioural rules but get ignored under task pressure. The Remediation Trigger lives in `CLAUDE.md` (via `.claude/docs/context-management.md`) so it loads with every session — it's the always-on backstop for systemic context-cost drift.

When you notice ANY of the following, **stop and propose a remediation phase**:

- Repeated full-Reads of the same >500-line file across a session.
- Multiple skills doing the same expensive grep/scan.
- Working-set repeatedly approaches 100k tokens for a focused task.
- Subagent prompts pasting >10k tokens when a summary/anchor lookup would suffice.
- A new corpus reaches ~15+ files / ~100k tokens without a summary layer.
- The user has to remind you to use a helper that exists.
- You catch yourself rationalising "it's only this once" for a large read.

The remediation forms:

- `tools/dev/<domain>-summary.sh` for corpora past the inflection.
- `<domain>-anchors.json` for section-precise lookups (or just script-side anchor parsing — both forms work; pick what matches your CI / hook stack).
- 3-tier read budget refit on offending skills.
- PostToolUse hook to keep the new index fresh on writes.

Save a proposal under `production/proposals/YYYY-MM-DD-<topic>.md` before executing. Ask the user before starting — remediation is a side-quest from whatever they actually asked for, but the cost of NOT remediating is silent context-window erosion.

---

## 6. Append-only session state (rotation, not full overwrites)

`production/session-state/active.md` accumulates across sessions as the file-backed memory between compactions. It WILL grow unboundedly if not rotated.

The pattern:

- Every session writes Session Extract blocks with a fixed schema (`## Session Extract — YYYY-MM-DD — Title` + TL;DR + body).
- The rotator (`rotate-active.sh`) keeps the 5 newest extracts and archives the rest to `production/session-logs/active-archive-YYYY-MM-DD.md`.
- The rotator runs from the session-stop hook and on demand after `/story-done`.

This pattern only works if every writer uses the schema. Stragglers writing top-level H2s that don't match `## Session Extract` are invisible to the rotator and accumulate without bound. A PostToolUse hook (`.claude/hooks/validate-active-md.sh`) warns on drift.

The Session Extract schema is in `docs/active-md-template.md`. The rotator is `scripts/rotate-active.sh`. Adopt them together or not at all — half-adoption produces silent rotation failures.

---

## 7. Single source of truth (the systems-index is canon, memory rots)

The `production/sprint-status.yaml`, `design/gdd/systems-index.md`, `production/deferred-items.md`, and `docs/architecture/tr-registry.yaml` are the project's authoritative state files. Claude memory entries about project state CAN go stale. When in doubt:

- Grep the index files. They are canonical.
- Update memory entries when they go stale; don't trust them silently.
- For state queries, prefer `tools/dev/<domain>-summary.sh` over Claude recall.

This pattern is enforced by skills calling the summary scripts at the start of state-dependent operations — see `INTEGRATION_GUIDE.md`.

---

## TL;DR

1. **Read tax is real.** A 40k-token Read costs 40k tokens. Bash on disk costs ~50 tokens.
2. **3-tier read budget.** Skills default to Tier 1 (summaries + index). Escalate to Tier 2 (anchor lookups). Tier 3 (full read) requires justification.
3. **Write helpers at the 2nd recurrence.** Not the 1st (reconnaissance) and not the 5th (silent absorption).
4. **Don't stack helpers.** When a class of bugs needs a new validator every sprint, the data model is wrong.
5. **Adopt the Remediation Trigger.** The always-loaded backstop for systemic drift.
6. **Append-only files need rotation.** The session-state file is the canonical example.
7. **Index files are canon.** Memory rots; the index files don't.

Read these patterns. THEN adopt the helpers. The helpers without the patterns will give you tactical relief and let the underlying problem grow.
