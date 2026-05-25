# Story 005: 实现拆除限制、空地释放与邻接重算触发

> **Epic**: 小镇建设系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/town-building-system.md`
**Requirement**: `TR-town-003`, `TR-town-015`, `TR-town-017`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-town-003`: Facility state machine: Empty→Constructing→Active↔Upgrading→Demolishing→Empty
- `TR-town-015`: Demolish under-construction facility returns error
- `TR-town-017`: Adjacency bonuses computed on state change, not polled per-frame

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0008: Town Grid & Facility System
**ADR Decision Summary**: Demolition is a controlled town-state transition that releases grid occupancy and triggers adjacency recomputation without per-frame polling.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state transition and EventBus notification; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Facility state changes trigger adjacency recomputation.
- Required: Under-construction demolition requests return explicit errors.
- Forbidden: Do not implement adjacency updates as `_process()` polling.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/town-building-system.md`, scoped to this story:*

- [ ] Active facilities can be demolished immediately; the grid cell becomes Empty, the facility is removed from registry, and no resources are refunded.
- [ ] `Constructing` and `Upgrading` facilities reject demolition requests and preserve their previous state.
- [ ] After demolition, affected neighboring adjacency bonuses are invalidated within the same settlement boundary without per-frame polling.

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

The GDD/EPIC state path names `Demolishing`, while ADR-0008 treats MVP demolition as immediate rather than a persistent `DEMOLISHING` state. Implement it as an instantaneous controlled transition and keep this mismatch visible during readiness review.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: Full adjacency formula values.
- Story 009: Save/load restoration.
- UI confirmation prompts.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Active facility demolition releases grid
  - Given: An Active facility on the grid.
  - When: Demolition is requested.
  - Then: The facility is removed, its cell becomes Empty, and no refund transaction is created.
  - Edge cases: Demolishing the same id twice; demolition next to multiple facilities; no economy change.

- **AC-2**: In-progress facilities cannot be demolished
  - Given: A `Constructing` or `Upgrading` facility.
  - When: Demolition is requested.
  - Then: A clear error is returned and facility state/timer remain unchanged.
  - Edge cases: Request immediately before completion; retry after completion; invalid id.

- **AC-3**: Demolition invalidates affected adjacency bonuses
  - Given: Facilities with active adjacency bonuses.
  - When: One facility in an adjacency pair is demolished.
  - Then: Bonuses involving that facility are removed in the same boundary, while unrelated bonuses remain.
  - Edge cases: Multiple adjacent pairs; diagonal facilities; no polling in `_process()`.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/town/demolish_grid_release_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/town-building-system/story-001-town-grid-facility-contract.md` — must be DONE
  - `production/epics/town-building-system/story-003-build-request-validation.md` — must be DONE
  - `production/epics/town-building-system/story-004-upgrade-completion-flow.md` — must be DONE
- Unlocks:
  - `production/epics/town-building-system/story-007-stadium-adjacency-formulas.md`
  - `production/epics/town-building-system/story-008-downstream-query-maintenance.md`
  - `production/epics/town-building-system/story-009-serialization-restore-regression.md`
