# Story 007: 实现球场与三组邻接加成公式

> **Epic**: 小镇建设系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/town-building-system.md`
**Requirement**: `TR-town-007`, `TR-town-008`, `TR-town-012`, `TR-town-013`, `TR-town-017`, `TR-town-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-town-007`: home_advantage_bonus = 2.0 × stadium_level, max 10.0
- `TR-town-008`: stadium_revenue_multiplier = 1.0 + 0.08 × stadium_level, max 1.40
- `TR-town-012`: 3 adjacency pairs: training_ground↔medical_room, training_ground↔youth_academy, stadium↔training_ground
- `TR-town-013`: Maximum adjacency bonus: 15.0 (stadium Lv.5 + training_ground Lv.5 adjacent)
- `TR-town-017`: Adjacency bonuses computed on state change, not polled per-frame
- `TR-town-018`: 8 public formula methods for downstream consumption

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0008: Town Grid & Facility System
**ADR Decision Summary**: TownBuilding computes explicit MVP adjacency pairs and stadium bonuses from active facility levels.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript formula math over flat grid neighbors; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Adjacency is Manhattan distance 1 only.
- Required: Adjacency recomputes on facility state changes, not per-frame polling.
- Guardrail: Only declared MVP adjacency pairs are valid.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/town-building-system.md`, scoped to this story:*

- [ ] Adjacency only counts Manhattan distance 1 and only supports the 3 MVP pairs; diagonal neighbors and undeclared pairs return zero bonus.
- [ ] Training ground ↔ medical room and training ground ↔ youth academy adjacency formulas use `coefficient × min(level_a, level_b)` with required floor/clamp or multiplier rules.
- [ ] `compute_home_advantage_bonus()` and `compute_stadium_revenue_multiplier()` apply stadium base formulas, and stadium ↔ training ground adjacency can raise maximum home advantage to 15.0.

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

Do not build a generic adjacency matrix beyond the GDD-defined MVP pairs. Only Active facilities participate. Keep adjacency update boundaries tied to build completion, upgrade completion, and demolition rather than `_process()` polling.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: Base training/medical/youth formulas.
- Story 008: Combined training multiplier and maintenance query.
- UI visualization of adjacency.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Only valid Manhattan adjacency pairs produce bonuses
  - Given: Facilities placed sharing an edge, diagonally adjacent, and in undeclared pairs.
  - When: Adjacency bonuses are queried.
  - Then: Only declared edge-sharing pairs return non-zero bonuses.
  - Edge cases: Diagonal returns 0; stadium-medical returns 0; medical-youth returns 0.

- **AC-2**: Training-medical and training-youth formulas use min level
  - Given: Different level combinations for training/medical and training/youth pairs.
  - When: Adjacency bonuses are calculated.
  - Then: Results use `min(level_a, level_b)` and obey clamp/multiplier rules.
  - Edge cases: One side level 0; inactive facility; cap reached.

- **AC-3**: Stadium formulas and stadium-training adjacency apply correctly
  - Given: Stadium and training ground levels with and without adjacency.
  - When: Home advantage and revenue multiplier are queried.
  - Then: Base formulas apply and adjacent level 5 stadium/training can reach 15.0 home advantage.
  - Edge cases: No stadium; revenue multiplier cap; non-adjacent training ground.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/town/stadium_adjacency_formula_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/town-building-system/story-001-town-grid-facility-contract.md` — must be DONE
  - `production/epics/town-building-system/story-004-upgrade-completion-flow.md` — must be DONE
  - `production/epics/town-building-system/story-005-demolish-grid-release.md` — must be DONE
- Unlocks:
  - `production/epics/town-building-system/story-008-downstream-query-maintenance.md`
  - `production/epics/town-building-system/story-009-serialization-restore-regression.md`
