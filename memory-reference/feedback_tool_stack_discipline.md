---
name: Tool stack discipline — fix the data model, don't stack validators
description: Don't propose tools that patch the blind spot of a previous tool. Each new tool must retire complexity or solve a structural problem — not stack onto the existing tool chain. If a class of bug keeps needing a new validator, the underlying data model is wrong; fix the model, not the symptom.
type: feedback
---

When a defect class escapes an existing tool, the default reaction is
to propose a new tool that catches it. **Stop and ask whether the data
model is the actual problem first.** If the answer is yes, propose the
model change; don't propose another validator stacked on top.

**Why:** the failure shape is consistent — a CCGS project accumulates
validators at the GDD / ADR / registry / consistency-check layers, and
each new defect class triggers a request for "one more checker." Each
checker addresses the prior checker's blind spot. The stack grows; the
project becomes unmaintainable when each layer needs another layer to
police it. The recurrence pattern is the diagnostic: three rounds of
the same drift surfacing before someone notices the model is wrong.

A concrete example: cross-GDD dependency tracking implemented as
free-text prose in a "Depends on" section. The first validator checks
that "Depends on" entries reference valid GDDs. The second checks
bidirectionality (every "Depends on" has a matching "Used by"). The
third checks ID-vs-name drift (entries reference the right thing by
the wrong name). The fourth recurrence reveals the real problem:
free-text shouldn't be the schema. Move the dependency declarations
to a single systems-index that GDDs reference by ID, and all three
validators retire. Net tool count goes DOWN.

**How to apply:**

- **Before proposing a new tool, run the retirement test.** Does this
  tool let me delete one or more existing tools or skill steps? If no,
  the answer is probably "fix the data model" not "build the tool."
- **A class of bug recurring across multiple sessions is a model
  problem, not a validator problem.** The recurrence is the diagnostic.
- **"Get it right the first time" applies to tooling architecture, not
  individual tools.** A correct tool that occupies the wrong layer is
  still wrong. Slower decisions about whether to build at all beat
  faster decisions about what to build.
- **When the user asks for a tool that fits this pattern, surface the
  stacking risk before writing it.** Don't write the tool and then add
  a meta-comment later. The pushback happens at the proposal step.
- **Existing stacked tools stay where they are** unless their removal
  is part of the structural fix. Pre-emptive removal under this
  principle alone is its own anti-pattern. The trigger for the
  structural fix is recurrence + a viable model change, not pure
  taste.

**Related:** [[feedback-remediation-trigger]] (flag context-cost bloat
proactively — same family; that one says "don't silently absorb the
cost," this one says "don't silently stack the fix").
