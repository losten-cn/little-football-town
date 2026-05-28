# Story 004: 实现预算预览与可负担性查询合同

> **Epic**: 经济管理系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/economy-management-system.md`
**Requirement**: `TR-economy-003`, `TR-economy-011`, `TR-economy-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-economy-003`: Pre-validation rejects transactions violating resource floors
- `TR-economy-011`: Accredited entry points: accredit_match_reward, accredit_facility_cost, accredit_training_cost
- `TR-economy-013`: Budget preview and affordability queries are read-only and return projected balances plus reason codes without mutating authoritative resources

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0007: Economy Transaction Framework
**ADR Decision Summary**: EconomyManager provides read-only forecast and affordability contracts while preserving `execute_transaction()` as the only write path.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript query methods returning Dictionary payloads; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Downstream systems query affordability through EconomyManager.
- Required: Preview operations must not mutate authoritative state.
- Forbidden: Do not create temporary committed transactions for previews.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/economy-management-system.md`, scoped to this story:*

- [ ] EconomyManager provides a read-only budget preview query that returns current balances and projected balances for proposed `funds`, `AP`, and `RP` costs.
- [ ] EconomyManager provides affordability result and reason codes so training, match, and construction entry points can display insufficient-resource causes.
- [ ] If real settlement changes balances while Budget Preview is open, the next preview recalculates from the latest authoritative balances rather than stale cached values.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

Implement preview as a pure read/query contract. It may reuse validation logic but must not write balances, allocate transaction ids, or append to the transaction log. This story is governed by `TR-economy-013` for read-only budget preview and affordability query behavior.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- UI button grey-out and tooltip presentation.
- Actual transaction execution.
- Settlement handlers.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Preview returns projected balances without mutation
  - Given: Current balances and proposed resource costs.
  - When: The budget preview query is called.
  - Then: It returns current and projected balances while real balances remain unchanged.
  - Edge cases: Zero cost; all three resources change; projected funds become negative.

- **AC-2**: Affordability query reports reason codes
  - Given: One affordable request and one request that violates resource policy.
  - When: Affordability is checked.
  - Then: The affordable request succeeds and the failed request includes a stable reason code.
  - Edge cases: AP exactly equals cost; RP exactly 0; multiple shortages at once.

- **AC-3**: Preview uses fresh authoritative balances
  - Given: A preview was previously shown and then a real transaction or settlement changes resources.
  - When: The preview is requested again.
  - Then: Projection is based on the updated balances.
  - Edge cases: Multiple settlements in one frame; preview and settlement interleaving; cached UI state.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/economy/budget_preview_affordability_query_test.gd` OR playtest doc

**Status**: [x] Created and locally verified (`BUDGET_PREVIEW_AFFORDABILITY_QUERY_TEST_PASS`)

---

## Completion Notes
**Completed**: 2026-05-26
**Criteria**: 3/3 passing
**Deviations**: `EconomyManager` preview logic now shares the same debt-capable funds policy as real facility-cost execution by removing the stale `funds_insufficient` branch from `accredit_facility_cost()`; integration evidence also verifies preview does not mutate balances, advance `tx_id`, append to transaction log, or emit warning events.
**Test Evidence**: Integration: `tests/integration/economy/budget_preview_affordability_query_test.gd` present and locally verified with `D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe` (PASS). Local runs still emit the existing economy test exit resource warnings.
**Code Review**: Complete — initial affordability/reality mismatch was corrected and the final implementation passed review with no remaining blockers.

---

## Dependencies

- Depends on:
  - `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md` — must be DONE
  - `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md` — must be DONE
- Unlocks:
  - Downstream work: Player, Town, and Match UI affordability integration
