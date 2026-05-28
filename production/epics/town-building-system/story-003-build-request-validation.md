# Story 003: 实现建造发起校验与 accredited 扣费入口

> **Epic**: 小镇建设系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/town-building-system.md`
**Requirement**: `TR-town-001`, `TR-town-003`, `TR-town-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-town-001`: 5×5 grid, 4-directional adjacency (Manhattan distance = 1)
- `TR-town-003`: Facility state machine: Empty→Constructing→Active↔Upgrading→Demolishing→Empty
- `TR-town-014`: Construction/upgrade costs route through EconomyManager accredited facility-cost entry points exclusively

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0008: Town Grid & Facility System
**ADR Decision Summary**: Facility build requests validate grid and economy constraints before entering constructing state, and all facility costs route through EconomyManager.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Core node integration with EconomyManager API and typed result Dictionaries; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Construction cost requests use `EconomyManager` accredited facility-cost entry points.
- Required: Failed validation must not mutate grid or facility registry.
- Forbidden: Do not write economy balances directly from TownBuilding.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/town-building-system.md`, scoped to this story:*

- [ ] If the target cell is empty and funds are sufficient, starting construction uses `EconomyManager` accredited facility-cost entry points, places a facility in the cell, sets state to `Constructing`, sets level to 0, and stores remaining construction time from Story 002 formulas.
- [ ] Occupied cells, out-of-bounds cells, and insufficient funds all reject construction without writing grid state, creating a facility, or starting a timer.
- [ ] The build path never directly modifies funds/AP/RP; facility cost payment is only legal through `accredit_facility_cost()`.

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

Build requests should return a structured result such as `success`, `error`, and `facility_id`. Only write the grid and facility registry after both town validation and economy payment succeed.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: Upgrade and completion flow.
- Story 005: Demolition.
- Story 007: Adjacency formulas.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Valid construction starts through accredited economy payment
  - Given: An empty cell, legal facility type, and sufficient funds.
  - When: A build request is submitted.
  - Then: Payment uses `accredit_facility_cost()`, the facility enters `Constructing`, level is 0, and remaining time is correct.
  - Edge cases: First facility of each type; level 0 runtime state while target level is 1.

- **AC-2**: Invalid construction does not mutate state
  - Given: Occupied cell, out-of-bounds cell, and insufficient funds cases.
  - When: Build requests are submitted.
  - Then: Each fails and grid/registry/timer state remains unchanged.
  - Edge cases: Retrying after failure at a valid location; no orphan facility id after failure.

- **AC-3**: Economy mutation is not bypassed
  - Given: Instrumented EconomyManager interaction.
  - When: Build requests succeed or fail.
  - Then: Facility costs only go through `accredit_facility_cost()` and never direct balance writes.
  - Edge cases: Accredited call fails; zero-cost debug fixture; duplicate request.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/town/build_request_validation_test.gd` OR playtest doc

**Status**: [x] Created — `tests/integration/town/build_request_validation_test.gd` (passes via Godot headless on 2026-05-26)

---

## Dependencies

- Depends on:
  - `production/epics/town-building-system/story-001-town-grid-facility-contract.md` — must be DONE
  - `production/epics/town-building-system/story-002-facility-cost-time-formulas.md` — must be DONE
- Unlocks:
  - `production/epics/town-building-system/story-004-upgrade-completion-flow.md`
  - `production/epics/town-building-system/story-005-demolish-grid-release.md`
  - `production/epics/town-building-system/story-009-serialization-restore-regression.md`

## Completion Notes
**Completed**: 2026-05-26
**Criteria**: 3/3 passing
**Deviations**: Headless integration evidence passes but exits with resource cleanup warnings (`ObjectDB instances leaked at exit`, `resources still in use at exit`); `_make_transaction()` remains a lightly typed test helper and does not affect Story 003 acceptance.
**Test Evidence**: Integration: test file at `tests/integration/town/build_request_validation_test.gd`
**Code Review**: Complete — re-review after minimal fixes found no remaining blocking issues
