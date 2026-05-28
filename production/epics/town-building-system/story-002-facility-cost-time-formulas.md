# Story 002: 实现设施建造/升级成本与工期公式

> **Epic**: 小镇建设系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/town-building-system.md`
**Requirement**: `TR-town-004`, `TR-town-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-town-004`: Construction cost: ceil(base × 1.8^(level-1))
- `TR-town-005`: Construction time: ceil(base × 1.3^(level-1))

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0008: Town Grid & Facility System
**ADR Decision Summary**: TownBuilding computes construction and upgrade costs/timers from data-driven facility config using explicit formulas.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript formula math; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Facility values come from data-driven config.
- Required: Formula outputs use the exact rounding rules from GDD/TR.
- Forbidden: Do not hardcode gameplay tuning values in source code.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/town-building-system.md`, scoped to this story:*

- [ ] Construction and upgrade funds cost equals `ceil(base_cost × 1.8^(level-1))`.
- [ ] Construction time and upgrade time read their respective base values and equal `ceil(base_time × 1.3^(level-1))`.
- [ ] Illegal target levels below 1 or above 5 are explicitly rejected and not converted into executable costs or timers.

---

## Implementation Notes

*Derived from ADR-0008 Implementation Guidelines:*

Keep this story to pure formula interfaces and validation. All base costs, base times, and multipliers must be loaded from TownConfig/ConfigLoader. Do not include EconomyManager payment, grid occupancy, or construction timer progression here.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: Build request validation and facility-cost payment.
- Story 004: Upgrade flow and completion ticking.
- Story 008: Maintenance fee aggregation.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Cost formula uses ceil and level exponent
  - Given: Base costs for each MVP facility type and target levels 1–5.
  - When: Construction or upgrade cost is calculated.
  - Then: The result equals `ceil(base_cost × 1.8^(level-1))`.
  - Edge cases: Level 1 returns base cost; level 5 high value; different facility base costs.

- **AC-2**: Time formula uses correct base table
  - Given: Separate construction and upgrade base times.
  - When: New construction and upgrade time are calculated.
  - Then: Each uses the correct base time and `ceil(base_time × 1.3^(level-1))`.
  - Edge cases: Level 1 construction vs upgrade; level 5; non-integer result requiring ceil.

- **AC-3**: Illegal levels are rejected
  - Given: Target levels 0, 6, and negative values.
  - When: Formula methods are called.
  - Then: A failure result is returned and no executable cost/time value is accepted.
  - Edge cases: Legal boundary levels 1 and 5 remain valid.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/town/facility_cost_time_formula_test.gd` — must exist and pass

**Status**: [x] Created — `tests/unit/town/facility_cost_time_formula_test.gd` (passes via Godot headless on 2026-05-26)

---

## Dependencies

- Depends on:
  - `production/epics/town-building-system/story-001-town-grid-facility-contract.md` — must be DONE
- Unlocks:
  - `production/epics/town-building-system/story-003-build-request-validation.md`
  - `production/epics/town-building-system/story-004-upgrade-completion-flow.md`

---

## Completion Notes
**Completed**: 2026-05-26
**Criteria**: 3/3 passing
**Deviations**: QA review suggested follow-up coverage for `unsupported_facility_type` and direct production-path config resolution; no blocking issues remain for Story 002 completion.
**Test Evidence**: Logic: test file at `tests/unit/town/facility_cost_time_formula_test.gd`
**Code Review**: Complete — `/code-review` approved with suggestions in lean mode
