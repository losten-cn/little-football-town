# Story 001: 建立 Facility 数据模型与网格索引契约

> **Epic**: 小镇建设系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-25

## Context

**GDD**: `design/gdd/town-building-system.md`
**Requirement**: `TR-town-001`, `TR-town-002`, `TR-town-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-town-001`: 5×5 grid, 4-directional adjacency (Manhattan distance = 1)
- `TR-town-002`: 4 MVP facility types, 5 levels each
- `TR-town-003`: Facility state machine: Empty→Constructing→Active↔Upgrading→Demolishing→Empty

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0008: Town Grid & Facility System
**ADR Decision Summary**: TownBuilding owns a flat typed grid and Facility runtime model as the authoritative gameplay state for town facilities.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript RefCounted model and typed Array grid; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: TownBuilding owns authoritative facility and grid state.
- Required: Downstream systems consume facilities through explicit read APIs.
- Forbidden: Do not make TileMapLayer or UI nodes the gameplay authority for facility state.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/town-building-system.md`, scoped to this story:*

- [ ] `TownBuilding` initializes a flat typed grid, defaulting to 5×5, with index rule `x + y * width`.
- [ ] `Facility` runtime model contains `id`, `facility_type`, `level`, `state`, `grid_x`, `grid_y`, and `remaining_construction_units`, and supports 4 MVP facility types with levels 0–5.
- [ ] `get_facility_at()` and `get_facility()` return empty results for empty cells, out-of-bounds coordinates, and unknown ids without mutating state.

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

Create `Facility` as a `RefCounted` runtime object and keep the flat typed array grid inside the scene-instantiated `TownBuilding` Core node. The grid is gameplay authority; visual tilemaps or UI views must only mirror it.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Cost and time formulas.
- Story 003: Build request validation.
- Story 009: Save/load serialization.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Grid initializes with stable flat index mapping
  - Given: Town config provides a 5×5 grid.
  - When: `TownBuilding` initializes.
  - Then: The grid has 25 cells and `(x, y)` maps to `x + y * width`.
  - Edge cases: `(0,0)`, `(4,4)`, `(-1,0)`, and `(5,4)`.

- **AC-2**: Facility model stores required MVP fields
  - Given: Facility samples for training ground, medical room, youth academy, and stadium.
  - When: Facilities are created with different levels and states.
  - Then: All required fields are retained and legal levels/states are represented.
  - Edge cases: Level 0 unbuilt/constructing representation; level 5 max; unsupported facility type.

- **AC-3**: Read queries do not mutate state
  - Given: An empty grid, an out-of-bounds coordinate, and an unknown facility id.
  - When: `get_facility_at()` or `get_facility()` is called.
  - Then: Empty results are returned and grid/registry remain unchanged.
  - Edge cases: Repeated invalid queries; empty cell after demolition; unknown id after load.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/town/town_grid_contract_test.gd` OR playtest doc

**Status**: [x] Created — `tests/integration/town/town_grid_contract_test.gd` (passes via Godot headless on 2026-05-25)

## Completion Notes
**Completed**: 2026-05-25
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Integration test at `tests/integration/town/town_grid_contract_test.gd`
**Code Review**: Complete — `/code-review` passed in lean mode

---

## Dependencies

- Depends on: None
- Unlocks:
  - `production/epics/town-building-system/story-002-facility-cost-time-formulas.md`
  - `production/epics/town-building-system/story-003-build-request-validation.md`
  - `production/epics/town-building-system/story-006-training-medical-youth-formulas.md`
  - `production/epics/town-building-system/story-007-stadium-adjacency-formulas.md`
  - `production/epics/town-building-system/story-009-serialization-restore-regression.md`
