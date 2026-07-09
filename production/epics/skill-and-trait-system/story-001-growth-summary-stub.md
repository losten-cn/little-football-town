# Story 001: Skill/Trait Growth Summary — 最小 Alpha UI stub

> **Epic**: 技能与特性系统
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S–M
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/skill-and-trait-system.md`, `design/gdd/player-management-ui.md`
**Requirement**: `TR-skill-006`, `TR-skill-007`, `TR-playerui-011`

This story is a minimum Alpha presentation stub for the Skill/Trait Growth Summary. It does not implement skill unlock logic, trait trigger conditions, candidate threshold evaluation, or settlement deduplication. Its only goal is to establish a read-only UI consumption path for `pending_skill_trait_feedback` and `feedback_ack` payloads — so that when the skill/trait Core authority begins producing these fields, the presentation layer is already wired.

This is the first Skill/Trait story. It follows the same Presentation-stub pattern as the Home/Player/Training/Match visual exemplar stories, and it applies the authority-contract decision checklist from Sprint 4 governance.

**ADR Governing Implementation**:

- Primary: ADR-0010 — Cross-System Payload and Settlement Contracts
- Secondary: ADR-0002 — Event/Signal Architecture + TimeManager
- Secondary: ADR-0001 — Scene Management & Autoload Architecture

**ADR Decision Summary**:

- ADR-0010 defines `pending_skill_trait_feedback` and `feedback_ack` as durable read-only UI payloads owned by PlayerDevelopment / skill-trait authority. UI must consume these without recomputing unlock, trigger, or settlement truth.
- ADR-0002 requires EventBus-based subscription and forbids ad hoc direct coupling.
- ADR-0001 requires the new surface to remain inside the existing shell route/container lifecycle.

**Engine**: Godot 4.6 | **Risk**: Medium

**Engine Notes**:

- No new Godot 4.6 feature adoption is required.
- This is a presentation-only story over existing Control-node patterns.
- Focus ambiguity between existing Player Detail sections and the new Growth Summary section must be avoided.

**Control Manifest Rules (Presentation / Foundation)**:

- Required: UI modules must consume snapshots, explanations, labels, acknowledgement flags, and visibility stages as read-only payloads.
- Required: If a UI screen needs a new display field, add it to the authoritative payload by the owning Core system before presenting it.
- Forbidden: Never recompute whether a skill unlocks, a trait triggers, a candidate threshold is crossed, or a settlement should be deduplicated in UI.
- Forbidden: Never resolve authority nodes through hardcoded `NodePath`, arbitrary scene-tree search, or implicit pseudo-singletons.
- Guardrail: UI implementations must stay within the global 60fps / 16ms frame budget and 500 draw-call ceiling.

**Pre-Implementation Decisions (S4-02 checklist applied)**:

- [x] Authority purity first — missing payload → neutral placeholder only
- [x] Latest producer wins — refresh meaning per ADR-0010 settlement contract
- [x] Explanatory fields from producer, UI read-only
- [x] Selection context from authority only
- [x] `disable_reason` ≠ `risk_summary` — N/A for this story (no disable/risk fields)
- [x] Test contract: new integration test file; existing L2/walkthrough should not be broken by a new read-only surface

---

## Acceptance Criteria

- [ ] A Growth Summary surface exists inside the existing MainLoop Shell, reachable from Player Detail or as a Home summary section, without new route IDs.
- [ ] The surface consumes `pending_skill_trait_feedback` payload as a read-only snapshot and renders feedback entries grouped by `feedback_key` or equivalent stable identity.
- [ ] The surface does not compute: whether a skill unlocks, whether a trait triggers, whether a candidate has crossed a hidden threshold, what action a player should take, or whether a settlement event should be deduplicated.
- [ ] If `pending_skill_trait_feedback` is absent or empty, the surface degrades to a neutral placeholder without exposing internal IDs, debug labels, or false interaction.
- [ ] `feedback_ack` state is consumed from authoritative payload and is not silently deduced from local UI cache.
- [ ] Focus, hover, selected, and disabled states remain understandable without color alone on the new surface.
- [ ] This stub does not add new skill/trait gameplay logic, new route IDs, new save/event schema, or new persistence fields.
- [ ] Existing Player Detail and Home visual exemplar behavior is not degraded by the addition of this stub.
- [ ] Automated regression coverage proves the surface consumes authoritative feedback payload and degrades safely when payload is missing.
- [ ] Existing route and handoff guardrails still pass.

---

## Scope

### In Scope

- A read-only Growth Summary container inside the existing shell.
- Subscription to `pending_skill_trait_feedback` and `feedback_ack` payloads.
- Neutral placeholder rendering when payload is missing or empty.
- Warm-town visual treatment consistent with the approved Home/Player/Training exemplar direction.
- Integration test for feedback payload consumption and safe degradation.
- Walkthrough/screenshot evidence.

### Out of Scope

- Skill unlock logic.
- Trait trigger evaluation.
- Candidate progress threshold computation.
- Settlement deduplication.
- `feedback_ack` write-back — UI only reads `feedback_ack` state; writing is owned by the skill/trait authority.
- Any new Core authority, gameplay formula, save/event schema change, or persistence contract.
- Full Growth Summary interaction depth (acknowledgement, follow-up, history browsing).
- Production art replacement.

---

## Dependencies

- Depends on:
  - `production/epics/player-management-ui/story-002-player-training-visual-exemplar-boundary.md`
  - `production/epics/player-management-ui/story-003-authoritative-explanatory-payload-contract.md`
  - `production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md`
  - `docs/architecture/control-manifest.md` Manifest Version `2026-07-05`
- Parallel with:
  - `production/sprints/sprint-5-feature-adjacent-presentation.md#s5-02`
- Unlocks:
  - future Skill/Trait feedback interaction depth stories
  - future Player Detail skill/trait history integration
- Story dependencies: None beyond the items listed above.

---

## Implementation Notes

This is a presentation-stub story, not a feature-growth story.

Preserve:

- existing route IDs
- existing Home → Roster → Player Detail flow
- existing save/event schema
- existing MainLoop Shell mounting and return paths

Allowed changes:

- add a new read-only Growth Summary container;
- subscribe to `pending_skill_trait_feedback` EventBus events;
- render feedback entries as grouped, labeled, non-interactive text;
- show neutral placeholder when payload is absent;
- add screenshot or walkthrough evidence.

Not allowed:

- adding skill unlock or trait trigger logic;
- recomputing gameplay truth locally;
- writing `feedback_ack` state from UI;
- adding new route IDs;
- changing `ScreenManager`;
- expanding into full Skill/Trait interaction depth.

---

## Test Evidence

**Story Type**: UI

**Required evidence**:

- Manual visual evidence:
  - `production/qa/evidence/skill-trait-growth-summary-stub-2026-07-10.md`
- Automated guardrails:
  - `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
  - `MVP_VISUAL_WALKTHROUGH_PASS` or updated walkthrough evidence
- Authority contract evidence:
  - `tests/integration/ui/skill_trait_growth_summary_authoritative_payload_test.gd`

**Status**: [ ] Not yet created

---

## Definition of Done

- [ ] Growth Summary surface exists and is reachable from existing routes.
- [ ] Integration test for authoritative feedback payload consumption passes.
- [ ] Existing route/handoff guardrails still pass.
- [ ] No new route IDs, gameplay formulas, or schema contracts were introduced.
- [ ] Code review confirms presentation-only scope was preserved.
- [ ] Any advisory deviations are documented.
