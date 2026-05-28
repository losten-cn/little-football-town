# Story 005: 实现每日 AP 恢复、休息恢复与维护费结算

> **Epic**: 经济管理系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/economy-management-system.md`
**Requirement**: `TR-economy-008`, `TR-economy-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-economy-008`: Daily AP recovery and rest AP recovery formulas
- `TR-economy-009`: daily_maintenance_cost deducted from funds, computed by TownBuilding

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0007: Economy Transaction Framework
**ADR Decision Summary**: Daily resource settlement is handled by EconomyManager through the same transaction pipeline used for all resource changes.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: EventBus-driven settlement and formula arithmetic; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Daily settlement consumes TimeManager and TownBuilding outputs through explicit system contracts.
- Required: Resource changes still route through the economy transaction boundary.
- Guardrail: Settlement ordering must be deterministic.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/economy-management-system.md`, scoped to this story:*

- [ ] Daily settlement applies `daily_ap_recovery = base_ap_recovery + facility_ap_bonus` and clamps AP to `action_points_max`.
- [ ] Rest action days add `rest_ap_recovery` on top of normal daily recovery.
- [ ] Daily settlement deducts `daily_maintenance_cost = base_maintenance_cost + facility_total_maintenance`, where facility maintenance input comes from TownBuilding.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

Handle daily settlement as an economy transaction or fixed sequence of transactions, not as a direct balance write. Pull facility AP bonus and maintenance totals through TownBuilding's public query contract. Keep recovery and maintenance ordering stable so downstream summaries can reconcile the ledger.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: Post-match, stage, and season settlement formulas.
- UI settlement summary.
- TownBuilding formula internals.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Daily AP recovery applies and clamps to max
  - Given: `base_ap_recovery`, `facility_ap_bonus`, and `action_points_max` are configured.
  - When: Daily settlement runs.
  - Then: AP increases by the formula result and never exceeds max.
  - Edge cases: AP already full; recovery exactly reaches max; facility bonus is 0.

- **AC-2**: Rest action adds extra AP recovery
  - Given: The day is marked as a rest action day and `rest_ap_recovery` is configured.
  - When: Daily settlement runs.
  - Then: Rest recovery is added to normal daily recovery before clamping.
  - Edge cases: Rest recovery causes cap; consecutive rest days; rest bonus is 0.

- **AC-3**: Maintenance cost deducts funds from TownBuilding total
  - Given: Base maintenance and TownBuilding facility maintenance totals are available.
  - When: Daily settlement runs.
  - Then: Funds decrease by the combined maintenance cost.
  - Edge cases: No facilities; zero maintenance; deduction creates debt or low-funds warning.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/economy/daily_recovery_maintenance_settlement_test.gd` OR playtest doc

**Status**: [x] Created and verified — `DAILY_RECOVERY_MAINTENANCE_SETTLEMENT_TEST_PASS`

---

## Dependencies

- Depends on:
  - `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md` — must be DONE
- Unlocks:
  - `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`

## Completion Notes
**Completed**: 2026-05-26
**Criteria**: 3/3 passing
**Deviations**: Advisory only — TownBuilding query surface and TownConfig data were expanded to support daily settlement without hardcoded values; remaining QA edge cases are coverage improvements, not blockers.
**Test Evidence**: Integration test at `tests/integration/economy/daily_recovery_maintenance_settlement_test.gd` — PASS (`DAILY_RECOVERY_MAINTENANCE_SETTLEMENT_TEST_PASS`)
**Code Review**: Complete — APPROVED WITH SUGGESTIONS

- Depends on:
  - `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md` — must be DONE
- Unlocks:
  - `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`
