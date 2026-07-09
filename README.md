# CCGS Context-Cost Helpers — Distribution Bundle

> **Bundle date:** 2026-05-30.
> **Bundle author:** sharing freely with the CCGS community.
> **Issue this addresses:** [Donchitos/Claude-Code-Game-Studios#64](https://github.com/Donchitos/claude-code-Game-Studios/issues/64) — context-cost / large-project context drift.
> **Status:** Generic / project-agnostic. Battle-tested across a multi-sprint CCGS deployment with ~100 GDDs, ~25 ADRs, and dozens of stories.

---

## What this is

A drop-in bundle of bash helpers + skill-integration patterns + memory-feedback entries that solve **the load-bearing context-cost problem in large CCGS projects**.

When a CCGS project grows past the first few sprints:

- GDDs cross 15+ files / 100k+ tokens — `/design-review`, `/review-all-gdds`, `/consistency-check` burn entire context windows on full Reads.
- ADRs cross 10+ files — `/architecture-review`, `/dev-story`, `/story-readiness` repeatedly Read ADRs that haven't changed.
- The deferred-items register grows to 40+ items — every skill that touches it re-reads the whole file.
- `production/session-state/active.md` accumulates append-only and crashes on compaction.
- The entity / TR registry grows past 5k tokens — every cross-reference burns Read budget.

The fix is consistent across all of these: **summary corpus + anchor-based partial reads + on-disk helpers that emit ~200 tokens of structured stdout instead of forcing Claude to Read 40k+ tokens of raw file**.

This bundle ships everything we built to make that work — generic, dependency-light, and project-agnostic.

---

## What's in the box

```
ccgs-context-helpers-2026-05-30/
├── README.md                                  # this file — start here
├── INTEGRATION_GUIDE.md                       # how to wire these into your CCGS project (skills, hooks, CLAUDE.md)
├── PER_HELPER_NOTES.md                        # what each helper does, when it pays off, what to adapt
├── PRINCIPLES.md                              # the underlying patterns (3-tier read budget, summary corpora, helper-trigger threshold)
├── scripts/                                   # the bash helpers themselves
│   ├── partial-read-helper.sh                 # anchor → Read offset/limit; the universal foundation
│   ├── rotate-active.sh                       # incremental archival of append-only session state
│   ├── dedupe-deferred.sh                     # deferred-items register summary + cap-pressure
│   ├── adr-summary.sh                         # ADR corpus summary layer (~1.5k tokens vs ~5-10k full)
│   ├── adr-lookup.sh                          # ADR section → Read offset/limit
│   ├── gdd-summary.sh                         # GDD corpus summary layer (~1.5k tokens vs ~30k full)
│   ├── gdd-lookup.sh                          # GDD section → Read offset/limit
│   ├── registry-summary.sh                    # entity registry summary layer
│   ├── registry-lookup.sh                     # entity registry lookup
│   └── count-todos.sh                         # tech-debt indicator (TODO/FIXME counts)
├── docs/
│   ├── context-management.md                  # the "Remediation Trigger" section — the always-loaded backstop
│   └── active-md-template.md                  # Session Extract schema for rotation-friendly append-only logs
├── memory-reference/                          # Claude memory entries that codify the behaviour
│   ├── feedback_remediation_trigger.md
│   ├── feedback_partial_read_helpers.md
│   ├── feedback_large_file_reads.md
│   └── feedback_tool_stack_discipline.md
└── integration-examples/                      # CLAUDE.md snippets + skill-update diffs
    ├── CLAUDE-md-snippet.md
    ├── skill-3-tier-read-budget-refit.md
    └── hook-keep-index-fresh.md
```

---

## Quick start (5 minutes)

If you're hitting context-cost issues right now, the highest-ROI moves in order:

1. **Install `partial-read-helper.sh`** at `tools/dev/` in your project and run a smoke test:
   ```bash
   chmod +x tools/dev/partial-read-helper.sh
   tools/dev/partial-read-helper.sh design/gdd/your-largest-gdd.md "Acceptance Criteria"
   ```
   It emits: `Read("design/gdd/your-largest-gdd.md", offset=N, limit=M)`. That's the Read call Claude should issue instead of full-Read.

2. **Install `dedupe-deferred.sh`** if you have a `production/deferred-items.md` register. Run it and confirm output shape:
   ```bash
   chmod +x tools/dev/dedupe-deferred.sh
   tools/dev/dedupe-deferred.sh
   # OPEN=24
   # RESOLVED=28
   # TOTAL=52
   # NEXT_ID=OPEN-054
   # CAP=50
   # CAP_PRESSURE=ok
   ```
   Wire this into every skill that mints OPEN-NNN entries — see `INTEGRATION_GUIDE.md` § Deferred Register.

3. **Install `rotate-active.sh`** + adopt the Session Extract schema from `docs/active-md-template.md`. Hook it into your session-stop hook (see `integration-examples/hook-keep-index-fresh.md`).

4. **Add the Remediation Trigger section to your `CLAUDE.md`** — copy `docs/context-management.md` content into `.claude/docs/` and reference it from `CLAUDE.md`. See `integration-examples/CLAUDE-md-snippet.md`.

5. When you hit your first "this GDD/ADR corpus is too big" pain point, install the matching `<domain>-summary.sh` + `<domain>-lookup.sh` pair and refit the offending skills. The summary scripts ARE templated to project-specific paths — adapt them, don't copy verbatim. See `PER_HELPER_NOTES.md`.

---

## What this is NOT

- **It is not a fork of CCGS.** These are project-level scripts + skill amendments you drop into your existing CCGS project.
- **It does not require you to change your engine, agent, or skill set.** It composes with whatever CCGS skills you already use.
- **It does not auto-install.** Adopt one helper at a time, measure the impact, then adopt the next. The trigger-threshold-discipline (write the helper at the *second* recurrence of a pain point) matters.
- **It is not a substitute for project-specific drift checkers.** The source deployment had ~13 additional project-specific validators (design-pillar discipline, GDD bidirectionality checks, locked-constant citations, etc.) that are intentionally excluded — they encode that project's specific design rules. Adapt the *patterns* shown here to your own project's rules, but don't copy any project-specific validators directly.

---

## The principle (one paragraph)

**Bash on disk is cheaper than Claude reading through Read.** When a workflow has Claude grep a 5k+ token state file more than once, write a `tools/dev/<verb>-<noun>.sh` helper that processes the file on disk and emits ≤30 lines of structured stdout. The Read-tool budget for a 40k-token register is 40k tokens; a partial Read after anchor lookup is ~200 tokens. The savings compound across the dozens of skill invocations in a sprint. The threshold for writing a new helper is the **second** time you need the lookup — first time is reconnaissance, second time means the workflow needs it.

See `PRINCIPLES.md` for the full theory + the "tool stack discipline" failure mode you want to avoid.

---

## Licensing

Public domain / CC0. Distribute freely, modify freely, no attribution required. If it helps your project, that's the point.

---

## Contact / Issues

This bundle was extracted from a multi-sprint CCGS deployment 2026-05-30. If you find a bug, want to suggest improvements, or have a CCGS context-cost pattern you've solved that should be in here, open an issue against the original CCGS issue #64 thread — the conversation lives there.
