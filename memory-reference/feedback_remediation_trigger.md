---
name: Token-cost remediation trigger — flag, don't absorb
description: When you notice systemic token-cost patterns (repeated full-Reads of large files, skill-side grep duplication, new corpus past the inflection without a summary layer), STOP and propose a remediation phase. Don't quietly absorb the cost.
type: feedback
---

A CCGS deployment that runs more than a few sprints will accumulate large
corpora (GDDs, ADRs, entity registries, deferred-items, session-state,
audit trails). Without active remediation, the cost of reading these
corpora through Read crowds out actual work — review-class skills
routinely burn 300k+ tokens before producing any output. A summary-layer
+ anchor-lookup refit (the same shape this helper bundle ships) typically
drops review-class skill token spend by 5-10×.

**Why:** memory entries about helpers and patterns get ignored under task
pressure when the cheap path is "just Read the file." The right answer
to token bloat is remediate-now, not live-with-it. The trigger should
fire before the user has to remind us.

**How to apply:** when ANY of these symptoms appear, surface them in the
user-facing turn and propose a remediation, even if the user didn't ask:

- repeated full-Reads of the same >500-line file across a session
- multiple skills doing the same expensive grep/scan
- working-set repeatedly approaches 100k tokens for a focused task
- subagent prompts paste >10k tokens when a summary/anchor would suffice
- new domain reaches ~15+ files / ~100k tokens without summary layer
- user has to remind us to use `partial-read-helper.sh` / `gdd-lookup.sh`
  / `gdd-summary.sh` / `dedupe-deferred.sh` — that's a process-failure
  signal
- you catch yourself rationalising "it's only this once" for a large read

Remediation forms (pick one or combine):

- `tools/dev/<domain>-summary.sh` for corpora past the inflection
- `<domain>-anchors.json` for section-precise lookups
- 3-tier read budget refit on offending skills (Tier 1 summaries + index;
  Tier 2 anchor lookups; Tier 3 full read with justification)
- PostToolUse hook to keep the new index fresh on writes

Save a proposal under `production/proposals/YYYY-MM-DD-<topic>.md` before
executing. Ask the user before starting — remediation is a side-quest
from whatever they actually asked for.

Out of scope: one-shot full Reads, intentional deep-dives, first-time
reads of a new file. The trigger is for *systemic* patterns, not single
transactions.

The always-loaded backstop for this lives at
`.claude/docs/context-management.md` § Remediation Trigger, surfaced
from `CLAUDE.md` § Context Management.
