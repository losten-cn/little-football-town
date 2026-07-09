---
name: Write bash helpers for repeated large-file lookups
description: When a CCGS workflow has Claude grep a 5k+ token state file (registry, deferred-items, session-state) repeatedly, write a tools/dev/ bash helper that processes on disk and returns ~200 tokens.
type: feedback
---

Any time a CCGS workflow requires Claude to grep, parse, or summarise a
large state file (registry, deferred-items, session-state, status yaml,
change log) more than once per session, **write a bash helper under
`tools/dev/`** that does the work on disk and emits only the summary
lines the workflow needs. The Read tool's context tax is the actual
problem; bash on disk is the solution.

**Why:** the math is one-sided. Loading a 40k-token register through
Read consumes 40k of context budget; a 50-line bash script that emits
counts + top-N rows costs ~200 tokens of output. The savings compound
across the dozens of skill invocations in a sprint. Rediscovering the
pattern from scratch each session wastes the early sprints' worth of
context-heavy CCGS work.

**The trigger threshold:** the *second time* I find myself reaching for
a large state file through Read or Grep in a workflow, write the helper.
First time is reconnaissance; second time means the workflow needs it,
and the third+ time will pay for the helper twice over.

**How to apply:**

1. Helper lives at `tools/dev/<verb>-<noun>.sh` — short, single-purpose,
   structured stdout.
2. Print a usage block in the script header (`# Usage: tools/dev/...`).
3. Output is a summary in ≤30 lines, grep-friendly, no decoration.
   Counts, top-N rows, matching lines with `--grep` flag, next-ID style
   — whatever the workflow actually consumes.
4. Process the file on disk (`grep`, `awk`, `python3 -c "..."` if
   YAML/JSON, `wc`, `sort -u`). Never re-emit the full file.
5. Add a one-line note about the helper in the project's CLAUDE.md or
   `tools/dev/README.md` so future sessions know it exists.

**Candidate triggers to anticipate (don't pre-build):**

- A `design/registry/entities.yaml` lookup that grows past 5k tokens →
  helper that emits entities by source-GDD, by status, by referenced_by.
- A `production/session-state/` file CCGS appends to → helper that emits
  the head N entries, head/tail rotation, archive-eligible rows.
- A consistency-check output dump that's noisy → helper that filters to
  actionable rows.
- Architecture decision register (`docs/architecture/tr-registry.yaml`)
  past 5k tokens → helper that emits decisions by status, by component.

**Don't pre-build.** Write a helper when the second use lands.
Pre-building helpers for files that haven't grown yet is the same
anti-pattern as pre-building abstractions.
