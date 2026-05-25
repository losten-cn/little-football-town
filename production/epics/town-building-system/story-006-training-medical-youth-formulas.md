# Story 006: 实现训练/医疗/青训基础公式接口

> **Epic**: 小镇建设系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/town-building-system.md`
**Requirement**: `TR-town-006`, `TR-town-009`, `TR-town-010`, `TR-town-011`, `TR-town-018`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-town-006`: training_efficiency_multiplier = 1.0 + 0.05 × training_ground_level
- `TR-town-009`: medical_ap_bonus: clamp(floor(level × bonus_per_level), 1, 3) + adjacency, total [0, 3]
- `TR-town-010`: injury_recovery_reduction: clamp(floor(level × recovery_per_level), 1, 2)
- `TR-town-011`: youth_potential_floor_boost: base + adjacency, clamp [0, 5]
- `TR-town-018`: 8 public formula methods for downstream consumption

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0008: Town Grid & Facility System
**ADR Decision Summary**: TownBuilding exposes read-only facility formula methods consumed by player development, time, and other systems.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript formula queries against active facility state; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Public formula methods are read-only and deterministic.
- Required: Formula constants come from data-driven config.
- Forbidden: Do not mutate town state during formula queries.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/town-building-system.md`, scoped to this story:*

- [ ] `compute_training_efficiency_multiplier()` returns the training ground base multiplier, with no facility returning 1.0 and configured levels matching the GDD table.
- [ ] `compute_facility_ap_bonus()` and `compute_injury_recovery_reduction()` follow their `floor()`/`clamp()` rules and maximum limits, with no facility returning neutral values.
- [ ] `compute_potential_floor_boost()` and `compute_youth_training_bonus(age)` follow level and age gates, with over-age players receiving a youth bonus of 1.0.

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

Implement only the base training, medical, and youth formula query methods here. They should consider Active facilities only and return neutral values when facilities are absent or inactive.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: Stadium and adjacency formulas.
- Story 008: Combined downstream multiplier and maintenance aggregation.
- Facility construction or upgrade state transitions.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Training efficiency returns configured base multiplier
  - Given: Training ground levels 0, 1, 3, and 5.
  - When: `compute_training_efficiency_multiplier()` is called.
  - Then: Values match the GDD table, and no facility returns exactly 1.0.
  - Edge cases: Inactive training ground; multiple training grounds if unsupported; level 5 cap.

- **AC-2**: Medical formulas apply floor and clamp
  - Given: Medical room levels 0–5.
  - When: AP bonus and injury recovery reduction are queried.
  - Then: Results match GDD floor/clamp rules and never exceed their max limits.
  - Edge cases: Level 1 minimum; level high enough to hit cap; no medical room.

- **AC-3**: Youth formulas respect level and age gates
  - Given: Youth academy levels 0–5 and player ages below, at, and above the youth threshold.
  - When: Potential floor boost and youth training bonus are queried.
  - Then: Level values match GDD and over-age youth bonus returns 1.0.
  - Edge cases: No youth academy; age exactly at threshold; inactive academy.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/town/training_medical_youth_formula_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/town-building-system/story-001-town-grid-facility-contract.md` — must be DONE
  - `production/epics/town-building-system/story-004-upgrade-completion-flow.md` — must be DONE
- Unlocks:
  - `production/epics/town-building-system/story-008-downstream-query-maintenance.md`
