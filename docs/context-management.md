# Context Management

Context is the most critical resource in a Claude Code session. Manage it actively.

## File-Backed State (Primary Strategy)

**The file is the memory, not the conversation.** Conversations are ephemeral and
will be compacted or lost. Files on disk persist across compactions and session crashes.

### Session State File

Maintain `production/session-state/active.md` as a living checkpoint. Update it
after each significant milestone:

- Design section approved and written to file
- Architecture decision made
- Implementation milestone reached
- Test results obtained

The state file should contain: current task, progress checklist, key decisions
made, files being worked on, and open questions.

### Status Line Block (Production+ only)

When the project is in Production, Polish, or Release stage, include a structured
status block in `active.md` that the status line script can parse:

```markdown
<!-- STATUS -->
Epic: Combat System
Feature: Melee Combat
Task: Implement hitbox detection
<!-- /STATUS -->
```

- All three fields (Epic, Feature, Task) are optional — include only what applies
- Update this block when switching focus areas
- The status line displays it as a breadcrumb: `Combat System > Melee Combat > Hitboxes`
- Remove or empty the block when no active work focus exists

After any disruption (compaction, crash, `/clear`), read the state file first.

### Incremental File Writing

When creating multi-section documents (design docs, architecture docs, lore entries):

1. Create the file immediately with a skeleton (all section headers, empty bodies)
2. Discuss and draft one section at a time in conversation
3. Write each section to the file as soon as it's approved
4. Update the session state file after each section
5. After writing a section, previous discussion about that section can be safely
   compacted — the decisions are in the file

This keeps the context window holding only the *current* section's discussion
(~3-5k tokens) instead of the entire document's conversation history (~30-50k tokens).

## Proactive Compaction

- **Compact proactively** at ~60-70% context usage, not reactively at the limit
- **Use `/clear`** between unrelated tasks, or after 2+ failed correction attempts
- **Natural compaction points:** after writing a section to file, after committing,
  after completing a task, before starting a new topic
- **Focused compaction:** `/compact Focus on [current task] — sections 1-3 are
  written to file, working on section 4`

## Context Budgets by Task Type

- Light (read/review): ~3k tokens startup
- Medium (implement feature): ~8k tokens
- Heavy (multi-system refactor): ~15k tokens

## Remediation Trigger — flag context-cost issues, don't just live with them

A typical CCGS project's GDD/ADR corpus benefits from a corpus-compression
workstream (summaries + anchor lookups + registry self-checks) that drops
review-class skill token spend by 5-10×. The same problem class will
re-emerge in **other corpora** — sprints, epics, stories, dev logs, test
evidence, deferred-items, audit trails — as they accumulate.

**Do not silently absorb the cost.** When you notice ANY of the following,
stop and propose a remediation phase, even if the user did not ask for it:

- **Repeated full-Reads of the same large file across a session** (>2 full
  reads of a >500-line file ≈ wasted tokens; the file should be summarised
  or partial-read-helper'd)
- **Multiple skills doing the same expensive grep/scan** (e.g. every QA
  skill walks every story file) — a shared index or summary corpus is
  cheaper
- **Working-set repeatedly approaches 100k tokens** for a single task that
  should be focused (e.g. one story implementation, one ADR review) — the
  task surface is wrong-shape, not the task itself
- **Subagent prompts paste >10k tokens of context** when a summary or
  anchor lookup would carry the same signal
- **A new domain reaches the GDD-corpus inflection** (~15+ files, ~100k+
  total tokens) without a summary/anchor layer
- **The user has to remind you** to use `partial-read-helper.sh`,
  `gdd-lookup.sh`, `gdd-summary.sh`, or `dedupe-deferred.sh` — that's a
  process-failure signal: the helpers exist but the discipline didn't fire
- **You catch yourself rationalising** "it's only this once" for a large
  read — that's the moment to flag, because it usually isn't once

**What "flagging" looks like.**

1. **Surface the symptom in the user-facing turn**: name the file(s) /
   skill(s) / pattern, give a rough token estimate of the waste.
2. **Recommend a remediation form**: usually one of —
   - Build a `tools/dev/<domain>-summary.sh` for a corpus that's grown
     past the inflection
   - Add an anchor index (`<domain>-anchors.json`) for section-precise
     lookups
   - Refit the offending skill(s) to a 3-tier read budget (Tier 1 =
     summaries + index; Tier 2 = anchor lookups; Tier 3 = full read with
     justification)
   - Add a PostToolUse hook to keep the new index fresh on writes
3. **Save a proposal under `production/proposals/YYYY-MM-DD-<topic>.md`**
   before starting the remediation. A useful proposal template covers:
   §0 baseline measurement, §N artifacts/helpers to build, §M skill refit
   plan, §X build sequence with effort estimates, §V risk table,
   §Z versioning.
4. **Ask the user before executing.** Remediation is a side-quest from
   whatever they actually asked for; they may want to defer or scope it
   down.

**Why this matters.** Memory entries codifying "use the helpers" get
ignored under task pressure when the cheap path is "just Read the file."
This section is the always-loaded backstop: if you read CLAUDE.md you
read this; the trigger should fire without needing to remember the
memory entries.

**Out of scope.** Don't flag normal one-shot full Reads, intentional
deep-dives, or first-time reads of a new file. The trigger is for
*systemic* token-cost patterns, not single transactions.

## Subagent Delegation

Use subagents for research and exploration to keep the main session clean.
Subagents run in their own context window and return only summaries:

- **Use subagents** when investigating across multiple files, exploring unfamiliar code,
  or doing research that would consume >5k tokens of file reads
- **Use direct reads** when you know exactly which 1-2 files to check
- Subagents do not inherit conversation history — provide full context in the prompt

## Compaction Instructions

When context is compacted, preserve the following in the summary:

- Reference to `production/session-state/active.md` (read it to recover state)
- List of files modified in this session and their purpose
- Any architectural decisions made and their rationale
- Active sprint tasks and their current status
- Agent invocations and their outcomes (success/failure/blocked)
- Test results (pass/fail counts, specific failures)
- Unresolved blockers or questions awaiting user input
- The current task and what step we are on
- Which sections of the current document are written to file vs. still in progress

**After compaction:** Read `production/session-state/active.md` and any files being
actively worked on to recover full context. The files contain the decisions; the
conversation history is secondary.

## Recovery After Session Crash

If a session dies ("prompt too long") or you start a new session to continue work:

1. The `session-start.sh` hook will detect and preview `active.md` automatically
2. Read the full state file for context
3. Read the partially-completed file(s) listed in the state
4. Continue from the next incomplete section or task
