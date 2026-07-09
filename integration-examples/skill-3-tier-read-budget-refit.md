# Example — Refitting a skill to the 3-tier read budget

This walks through the pattern with a concrete example: refitting a `/design-review`-shape skill from full-Read to 3-tier.

---

## Before (Tier 3 default — full-Read everything)

```markdown
## Phase 2: Read context

Read the GDD being reviewed in full.
Read all sibling GDDs that are referenced from §F.1 (Dependencies).
Read the entity registry to verify cross-references.
Read the architecture decision register entries that govern this GDD.
```

Cost on a typical mid-project session:
- Target GDD: ~30k tokens
- 3 sibling GDDs: ~90k tokens
- Entity registry: ~96k tokens
- 2 ADRs: ~15k tokens
- **Total: ~231k tokens before any review work**

A single specialist agent spawn then re-pays this cost (passed in the prompt) — total per-skill spend approaches 500k tokens.

---

## After (3-tier default — summaries first, partial reads on demand)

```markdown
## Phase 2: Read context (3-tier read budget)

**Tier 1 — Summaries + manifest (always).**

- Read the target GDD's summary: `tools/dev/gdd-summary.sh <slug>`. ~1.5k tokens.
- Read all sibling GDD summaries: `tools/dev/gdd-summary.sh --all`. ~25k tokens for ~15 GDDs.
- Read the registry summary: `tools/dev/registry-summary.sh`. ~3k tokens.
- Read referenced ADR summaries: `tools/dev/adr-summary.sh <NNNN>` for each. ~1.5k per ADR.

**Total Tier 1 cost: ~35-40k tokens.**

**Tier 2 — Anchor-targeted partial reads (on demand).**

When the review needs a specific section's full text:

- Target GDD section: `tools/dev/gdd-lookup.sh <slug> "<heading>" --emit-read`,
  then partial Read at the emitted offset/limit. ~3-8k tokens per section.
- Sibling GDD section: same shape.
- ADR Decision section: `tools/dev/adr-lookup.sh <NNNN> Decision --emit-read`,
  then partial Read. ~5-10k tokens.

Use Tier 2 when:
- The summary doesn't carry the specific claim being verified.
- A finding references a specific AC by ID; partial Read the AC section.
- A cross-reference between two GDDs needs both sides verified at section-level.

**Tier 3 — Full Read (rare; justified inline).**

Full-Read a GDD or ADR only when:
- The skill is authoring or substantially editing the file (the structure IS the work).
- A consistency check needs every word of two files compared.
- Tier 2 partial reads have surfaced ≥3 sections from the same file (cumulative cost
  exceeds full-read at that point).

When choosing Tier 3, write one sentence in the user-facing turn:
"Full-reading <file> at Tier 3 because <reason>."
```

Cost on the same mid-project session:
- Tier 1: ~40k tokens (always)
- Tier 2: ~10-30k tokens for 2-3 sections (typically)
- **Total: ~50-70k tokens per skill invocation**

That's a ~3-5× reduction on the typical case and ~10× on the worst case (where the original full-Read pattern blew through the context window).

---

## Subagent prompts under the 3-tier discipline

Specialist subagents inherit the same discipline. The orchestrator's job is to pass the **triaged summary** to the subagent, not the raw context:

```diff
- Pass the full GDD text + 3 sibling GDDs + 2 ADRs in the subagent prompt.
+ Pass the GDD's summary + the specific Tier 2 sections relevant to the
+ subagent's review angle. Include a pointer to the helpers so the subagent
+ can request more if needed:
+
+   "If you need a specific section of <sibling GDD>, run
+    `tools/dev/gdd-lookup.sh <slug> <section> --emit-read` and read it
+    partial; full-read is reserved for cases where 3+ sections are needed."
```

The orchestrator-side savings compound when 4-6 specialists are spawned in parallel — each one would otherwise re-pay the full-corpus read.

---

## When NOT to refit to 3-tier

- **First review of an authored corpus.** The first `/design-review` on a new
  GDD doesn't have summaries yet (or the summaries are stubs). Full-Read is
  correct until the summary lands.
- **Authoring skills.** `/design-system`, `/architecture-decision`, and any
  skill whose primary output IS the file structure should default to Tier 3
  for the file being authored.
- **Tiny corpora.** A project with 3 GDDs at ~5k tokens each doesn't benefit
  from summaries. The refit becomes worthwhile around the ~10-item / ~50k-token
  inflection.

The 3-tier pattern is for **read-heavy / corpus-aware** skills. Write-heavy
skills mostly want Tier 3 by default but with their write target in scope.

---

## Verifying the refit worked

After refitting a skill, measure:

1. Total token cost per invocation (the harness reports this in many CCGS deployments).
2. Specialist-agent prompt sizes (should drop by ~5-10× if you triaged before spawning).
3. Subjective time-to-first-finding (the user notices when reviews stop "thinking" for 30+ seconds before starting work).

If the refit dropped token cost by less than 2×, the corpus probably hasn't grown enough to need the 3-tier discipline yet, OR the skill is fundamentally Tier 3 work and the refit shouldn't have been applied.
