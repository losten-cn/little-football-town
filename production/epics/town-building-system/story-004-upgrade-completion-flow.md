# Story 004: 实现升级流转与 time_phase_changed 完工结算

> **Epic**: 小镇建设系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/town-building-system.md`
**Requirement**: `TR-town-003`, `TR-town-014`, `TR-town-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-town-003`: Facility state machine: Empty→Constructing→Active↔Upgrading→Demolishing→Empty
- `TR-town-014`: Construction/upgrade costs via EconomyManager.accredit_facility_cost() exclusively
- `TR-town-016`: Construction timers decrement on time_phase_changed

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0008: Town Grid & Facility System
**ADR Decision Summary**: Facility upgrade and construction timers progress on TimeManager phase events, with completion updating facility state at deterministic boundaries.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: EventBus integration with deterministic state transitions; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Construction timers decrement on `time_phase_changed`.
- Required: Upgrade costs use `EconomyManager.accredit_facility_cost()`.
- Guardrail: Facility completion events must be emitted once per completed facility.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/town-building-system.md`, scoped to this story:*

- [ ] Active facilities below level 5 can start upgrading; upgrade cost uses `accredit_facility_cost()`, state becomes `Upgrading`, and old-level bonuses remain active until completion.
- [ ] Each `time_phase_changed` decrements `remaining_construction_units` exactly once for constructing/upgrading facilities; when it reaches 0, the facility becomes Active at the new level in the same tick.
- [ ] Completion emits a facility completion event and new-level formula query results are readable in the same settlement boundary.

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

Subscribe to `time_phase_changed` through EventBus. Reject upgrades for non-Active facilities and level 5 facilities. Preserve old-level service during upgrade until the completion transition applies.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: Demolition.
- Story 007: Detailed adjacency formulas.
- Story 009: Save/load recovery.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Upgrade starts from valid Active facility only
  - Given: An Active level N facility where N < 5 and funds are sufficient.
  - When: Upgrade is requested.
  - Then: Cost is paid through `accredit_facility_cost()`, state becomes `Upgrading`, and old-level bonus remains readable.
  - Edge cases: Level 5 rejects; non-Active rejects; accredited payment fails.

- **AC-2**: Time phase decrements construction once per tick
  - Given: Constructing and Upgrading facilities with known remaining units.
  - When: `time_phase_changed` fires repeatedly.
  - Then: Each active timer decrements once per event and completes exactly when it reaches 0.
  - Edge cases: Same event emitted twice; multiple facilities; remaining units start at 1.

- **AC-3**: Completion event and new-level queries happen at same boundary
  - Given: A facility is one tick from completion.
  - When: The final `time_phase_changed` is processed.
  - Then: The facility becomes Active, emits completion once, and formula queries see the new level.
  - Edge cases: Multiple facilities complete in one tick; construction and upgrade complete together.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/town/upgrade_completion_flow_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/town-building-system/story-001-town-grid-facility-contract.md` — must be DONE
  - `production/epics/town-building-system/story-002-facility-cost-time-formulas.md` — must be DONE
  - `production/epics/town-building-system/story-003-build-request-validation.md` — must be DONE
- Unlocks:
  - `production/epics/town-building-system/story-005-demolish-grid-release.md`
  - `production/epics/town-building-system/story-006-training-medical-youth-formulas.md`
  - `production/epics/town-building-system/story-007-stadium-adjacency-formulas.md`
  - `production/epics/town-building-system/story-008-downstream-query-maintenance.md`
  - `production/epics/town-building-system/story-009-serialization-restore-regression.md`
