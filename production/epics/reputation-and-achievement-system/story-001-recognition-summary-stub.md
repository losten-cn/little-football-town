# Story 001: Reputation/Achievement — 最小 recognition summary stub

> **Epic**: 声望与成就系统
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/reputation-and-achievement-system.md`
**Requirement**: `TR-reputation-006`
**ADR**: ADR-0011 — Reputation and Achievement Recognition Framework

This story is a minimum Alpha presentation stub for the Reputation/Achievement recognition summary. It does not implement reputation calculation, achievement unlock logic, milestone evaluation, or reward settlement. Its only goal is to establish a read-only UI consumption path for `reputation_state_changed` and `achievement_unlocked` payloads — so that when the Core reputation authority begins producing these fields, the presentation layer is already wired.

This follows the Presentation-stub pattern documented in `docs/architecture/presentation-stub-pattern.md`.

**ADR Decision Summary**:

- ADR-0011 defines `reputation_state_changed` and `achievement_unlocked` as durable read-only UI payloads. UI must consume these without recomputing reputation progress, achievement eligibility, or milestone thresholds.
- ADR-0002 requires EventBus-based subscription.
- ADR-0001 requires the new surface to remain inside the existing shell route/container lifecycle.

**Engine**: Godot 4.6 | **Risk**: Low

---

## Acceptance Criteria

- [ ] A Recognition Summary surface exists inside the MainLoop Shell, visible from Home, without new route IDs.
- [ ] The surface consumes `reputation_state_changed` EventBus events as read-only snapshots and renders reputation level + progress ratio.
- [ ] The surface consumes `achievement_unlocked` EventBus events and renders recent achievement entries.
- [ ] The surface does not compute reputation growth, achievement eligibility, milestone thresholds, or reward settlement.
- [ ] If reputation/achievement payloads are absent or empty, the surface degrades to a neutral placeholder ("暂无声望记录") without exposing internal IDs or debug labels.
- [ ] Existing Home cards are not degraded by this addition.
- [ ] Automated regression coverage proves the surface consumes authoritative payloads and degrades safely.
- [ ] Existing route and handoff guardrails still pass.

## Scope

### In Scope
- Read-only recognition summary PanelContainer in MainLoopShell Home area.
- Subscription to `reputation_state_changed` and `achievement_unlocked` EventBus events.
- Reputation level + progress ratio display.
- Recent achievements list (up to 3 entries).
- Neutral placeholder on missing payload.
- Integration test + walkthrough evidence.

### Out of Scope
- Reputation calculation formulas.
- Achievement unlock logic / condition evaluation.
- Milestone thresholds / reward settlement.
- Full achievement browser or history.
- Any new Core authority or save/event schema changes.

## Dependencies
- ADR-0011 (Accepted)
- Home visual exemplar (Complete)
- Presentation-stub pattern doc (`docs/architecture/presentation-stub-pattern.md`)

## Test Evidence
**Story Type**: UI
**Required evidence**: `tests/integration/ui/recognition_summary_authoritative_payload_test.gd`; `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`; `MVP_VISUAL_WALKTHROUGH_STRUCTURE_PASS`

## Definition of Done
- [ ] Recognition Summary panel exists and is visible from Home.
- [ ] Integration test passes.
- [ ] Existing route/handoff guardrails pass.
- [ ] No new route IDs, gameplay formulas, or schema contracts.
- [ ] Code review confirms presentation-only scope.

## Completion Notes
**Completed**: 2026-07-10
**Criteria**: All passing (S6-03 implementation, auto-verified)
**Deviations**: None
**Test Evidence**: UI — `tests/integration/ui/recognition_summary_authoritative_payload_test.gd` (PASS)
**Code Review**: Complete (Sprint 6)
**Implementation**: S6-03 — recognition summary stub panel on Home (Presentation-stub pattern)
