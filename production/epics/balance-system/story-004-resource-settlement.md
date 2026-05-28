# Story 004: 实现资源结算共享公式

> **Epic**: 数值系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/balance-system.md`
**Requirement**: `TR-balance-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-balance-007`: resource_buffer_multiplier ∈ [2.0, 4.0]

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0004: Data-Driven Configuration
**ADR Decision Summary**: Resource capacity tuning is data-driven through `BalanceConfig`; shared formulas must use config-backed boundaries and remain consistent across downstream consumers.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Formula implementation should be deterministic, typed GDScript and unit-testable without scene runtime dependencies.

**Control Manifest Rules (this layer)**:
- Required: All gameplay tuning must load through `ConfigLoader` from typed Custom Resources under `res://config/`; invalid config must block startup.
- Forbidden: Never define gameplay tuning as inline constants in `src/`.
- Guardrail: Config load for all config resources combined must stay under 50ms.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/balance-system.md`, scoped to this story:*

- [ ] `resource_settlement = clamp(current_resource + gained_resource - spent_resource, resource_min, resource_max)`.
- [ ] Only `funds`, `research`, and `action points` participate in shared resource settlement.
- [ ] Final resource result lands inside the legal GDD boundary.
- [ ] Resource lower and upper boundary violations are clamped according to GDD Edge Cases.
- [ ] `resource_buffer_multiplier` is read from config and validated in range `[2.0, 4.0]`, default `3.0`.

---

## Implementation Notes

*Derived from ADR-0004 Implementation Guidelines:*

Implement the shared settlement formula as a reusable balance formula. Economy-specific accounts, income sources, expense categories, and transaction authorization are owned by EconomyManager stories, not this story.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Economy Management stories: transaction execution, warning thresholds, settlement stages.
- Story 008: Cross-system scan for downstream duplicate resource formulas.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 资源结算必须按 `current + gained - spent` 执行
  - Given: `current_resource=100`，`gained_resource=30`，`spent_resource=20`，范围足够大
  - When: 计算 `resource_settlement`
  - Then: 结果为 110
  - Edge cases: `gained_resource=0` 或 `spent_resource=0` 时仍应按同一公式计算

- **AC-2**: 结算结果低于最小值时必须钳制到 `resource_min`
  - Given: `current_resource=10`，`gained_resource=0`，`spent_resource=50`，`resource_min=0`
  - When: 计算 `resource_settlement`
  - Then: 结果为 0
  - Edge cases: 恰好等于最小值时保留该值；负资源输入应被归一化或在上层校验中拦截

- **AC-3**: 结算结果高于最大值时必须钳制到 `resource_max`
  - Given: `current_resource=190`，`gained_resource=30`，`spent_resource=0`，`resource_max=200`
  - When: 计算 `resource_settlement`
  - Then: 结果为 200
  - Edge cases: `resource_min/resource_max` 来自 `BalanceConfig`；若范围配置非法应拒绝计算

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/balance/resource_settlement_test.gd` — must exist and pass

**Status**: [x] Created — `tests/unit/balance/resource_settlement_test.gd`

---

## Dependencies

- Depends on:
  - `production/epics/balance-system/story-001-balance-config-validation.md` — must be DONE
- Unlocks:
  - Downstream work: Economy Management resource settlement stories

---

## Completion Notes
**Completed**: 2026-05-27
**Criteria**: 5/5 passing
**Deviations**: None
**Test Evidence**: Logic test passed at `tests/unit/balance/resource_settlement_test.gd`
**Code Review**: Complete
