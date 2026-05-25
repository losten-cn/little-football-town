# Story 008: 实现下游只读查询面与维护费汇总

> **Epic**: 小镇建设系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/town-building-system.md`
**Requirement**: `TR-town-018`, `TR-town-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-town-018`: 8 public formula methods for downstream consumption
- `TR-town-019`: Daily maintenance = Σ active facilities × (base + delta × (level-1))

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0008: Town Grid & Facility System
**ADR Decision Summary**: TownBuilding exposes read-only public formula methods and active-facility maintenance totals for downstream systems.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript read APIs and deterministic aggregation; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Downstream systems consume town bonuses through explicit read-only queries.
- Required: Daily maintenance is computed from active facilities only.
- Forbidden: Formula queries must not mutate grid, timers, facility state, or economy balances.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/town-building-system.md`, scoped to this story:*

- [ ] `compute_facility_training_multiplier(age)` equals `training_efficiency × youth_training_bonus × adj_tr_youth_multiplier`.
- [ ] `compute_facility_total_maintenance()` sums only Active facilities using `base + delta × (level-1)`.
- [ ] All public formula methods exposed to downstream systems are read-only; calling them does not change grid, facility state, timers, or balances.

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

This story closes the downstream query surface. Maintenance is a value EconomyManager reads during daily settlement; TownBuilding does not deduct resources itself.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: Serialization and restore regression.
- UI binding.
- EconomyManager daily settlement implementation.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Combined training multiplier equals component product
  - Given: Training ground, youth academy, adjacency state, and player ages inside/outside the youth threshold.
  - When: `compute_facility_training_multiplier(age)` is called.
  - Then: The result equals the product of training efficiency, youth bonus, and training-youth adjacency multiplier.
  - Edge cases: No related facilities returns 1.0; inactive facility ignored; over-age player uses youth factor 1.0.

- **AC-2**: Maintenance sums Active facilities only
  - Given: A town with Active facilities and non-Active facilities at different levels.
  - When: `compute_facility_total_maintenance()` is called.
  - Then: Only Active facilities contribute, using `base + delta × (level-1)`.
  - Edge cases: Empty town returns 0; mixed levels; no duplicate counting.

- **AC-3**: Query methods are read-only
  - Given: A snapshot of town grid, registry, facility states, timers, and economy balances.
  - When: Public formula methods are called repeatedly.
  - Then: The snapshot remains unchanged.
  - Edge cases: Repeated queries; queries after demolition; queries while upgrade is in progress.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/town/downstream_query_maintenance_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/town-building-system/story-006-training-medical-youth-formulas.md` — must be DONE
  - `production/epics/town-building-system/story-007-stadium-adjacency-formulas.md` — must be DONE
- Unlocks:
  - `production/epics/town-building-system/story-009-serialization-restore-regression.md`
