# Story 009: 实现建设状态序列化与读档恢复回归

> **Epic**: 小镇建设系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/town-building-system.md`
**Requirement**: `TR-town-003`, `TR-town-016`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time; construction-state save/restore is a GDD acceptance criterion without a dedicated town TR-ID)*

**GDD Rule / Acceptance Mapping**:
- `TR-town-003`: Facility state machine: Empty→Constructing→Active↔Upgrading→Demolishing→Empty
- `TR-town-016`: Construction timers decrement on time_phase_changed

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0008: Town Grid & Facility System
**ADR Decision Summary**: TownBuilding serializes authoritative grid and facility runtime state so construction and upgrade timers resume correctly after load.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Dictionary-based SaveManager serialization and EventBus time progression; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Core systems register serialization contracts with SaveManager.
- Required: Save payloads contain only primitives, typed Arrays, and Dictionaries.
- Guardrail: Construction timers must not duplicate completion events after restore.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/town-building-system.md`, scoped to this story:*

- [ ] `serialize()` includes `grid_width`, `grid_height`, `next_facility_id`, facility list, and each facility's position, level, state, and remaining construction units.
- [ ] `deserialize()` restores cell occupancy, facility ids, states, levels, and remaining construction units exactly; in-progress construction is not reset to initial time.
- [ ] After load, advancing `time_phase_changed` completes construction after the expected number of ticks exactly once.

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

Register TownBuilding with SaveManager and serialize authoritative gameplay state only. Do not persist visual nodes or UI state. This story is the town epic regression closeout and depends on prior state, formula, and query boundaries.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Save slot UI.
- Save integrity/hash/migration behavior.
- Other systems' deserialize order tests.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Serialization captures full town state
  - Given: A town with Active, Constructing, and Upgrading facilities.
  - When: `serialize()` is called.
  - Then: The payload includes grid dimensions, next id, and each facility's position, level, state, and remaining units.
  - Edge cases: Empty town; facility under construction; multiple facilities with different states.

- **AC-2**: Deserialization restores construction state exactly
  - Given: A serialized town payload.
  - When: A new TownBuilding deserializes it.
  - Then: Occupancy, facility ids, states, levels, and remaining construction units match the original state.
  - Edge cases: Upgrading facility not restored as Active; next id does not repeat; empty grid.

- **AC-3**: Loaded construction completes on expected tick once
  - Given: A facility had D remaining construction units at save time.
  - When: The game loads and `time_phase_changed` advances D times.
  - Then: The facility completes on the Dth event and emits completion once.
  - Edge cases: D=1; multiple projects; no early or duplicate completion.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/town/serialization_restore_regression_test.gd` OR playtest doc

**Status**: [x] Created and passing — `tests/integration/town/serialization_restore_regression_test.gd`

---

## Dependencies

- Depends on:
  - `production/epics/town-building-system/story-001-town-grid-facility-contract.md` — must be DONE
  - `production/epics/town-building-system/story-002-facility-cost-time-formulas.md` — must be DONE
  - `production/epics/town-building-system/story-003-build-request-validation.md` — must be DONE
  - `production/epics/town-building-system/story-004-upgrade-completion-flow.md` — must be DONE
  - `production/epics/town-building-system/story-005-demolish-grid-release.md` — must be DONE
  - `production/epics/town-building-system/story-006-training-medical-youth-formulas.md` — must be DONE
  - `production/epics/town-building-system/story-007-stadium-adjacency-formulas.md` — must be DONE
  - `production/epics/town-building-system/story-008-downstream-query-maintenance.md` — must be DONE
- Unlocks:
  - Downstream work: Town epic completion gate

---

## Completion Notes
**Completed**: 2026-05-27
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Integration: `tests/integration/town/serialization_restore_regression_test.gd`
**Code Review**: Complete — approved after adding SaveManager restore-path coverage plus D=1 and multi-project restore regression assertions
