# Memory Reference

> Copies of the Claude memory entries that codify the behavioural rules behind the helpers. These are the "why" entries that catch when the patterns drift.

---

## What's in here

| File | Purpose | When it fires |
|---|---|---|
| `feedback_remediation_trigger.md` | The behavioural rule that says "STOP and propose a remediation phase when systemic context-cost drift appears." | When repeated full-Reads, expensive grep duplication, or a new corpus past the inflection appear in a session. |
| `feedback_partial_read_helpers.md` | The trigger-threshold rule for writing new helpers. | When a workflow needs the same large-file lookup for the second time. |
| `feedback_large_file_reads.md` | The "cap initial Read at ~200 lines" defensive rule. | When opening a known-large file for the first time in a session. |
| `feedback_tool_stack_discipline.md` | The "don't patch the blind spot of the previous tool" rule. | When considering a new validator after a related class of bug recurs. |

---

## How to install

Copy these files into your Claude memory directory:

```bash
cp ccgs-context-helpers-2026-05-30/memory-reference/feedback_*.md \
   ~/.claude/projects/<your-project-path>/memory/
```

Then add entries to your `MEMORY.md` index file (one line per entry — Claude reads the index on every session start):

```markdown
- [Token-cost remediation trigger — flag, don't absorb](feedback_remediation_trigger.md) — When you notice systemic token-cost patterns, STOP and propose a remediation phase. Don't quietly absorb the cost.
- [Write bash helpers for repeated large-file lookups](feedback_partial_read_helpers.md) — At the SECOND recurrence, write a tools/dev/ helper that processes on disk and emits ~200 tokens.
- [Large file reads — cap initial Read at ~200 lines](feedback_large_file_reads.md) — Read tool fails opaquely past ~25k tokens; default to limit ≤200 on first read of large files.
- [Tool stack discipline — fix the data model, don't patch the previous tool](feedback_tool_stack_discipline.md) — Before proposing a new validator, run the retirement test: does it let me delete existing tools? If no, the data model is probably wrong.
```

---

## Adapting to your project

These memory entries are written in a project-agnostic voice. You can:

1. **Use them as-is** — the rules are generic and ready to drop into any CCGS project's memory directory.
2. **Add a project-specific anecdote** under each entry's "Why" section if you want to anchor the rule to a concrete incident from your own workflow. (Optional — the rules work without it.)
3. **Adjust the `description:` field** if your memory-index has a different summary-line style.

The structure (frontmatter + Why + How to apply + Out of scope) is the load-bearing pattern — copy that wholesale.

---

## Why these specifically

These four entries are the load-bearing ones for context-cost discipline. Most CCGS memory sets grow into the dozens of entries (engine choices, gameplay decisions, agent-routing notes), most of which are project-specific. These four are the ones every CCGS project will benefit from.
