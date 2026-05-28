# Story 003: 实现属性成长公式与潜力边界

> **Epic**: 数值系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/balance-system.md`
**Requirement**: `TR-balance-003`, `TR-balance-012`, `TR-balance-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-balance-003`: attribute_growth = raw × (1 - current/potential)^decay_factor
- `TR-balance-012`: decay_factor ∈ [0.8, 1.8], default 1.2
- `TR-balance-013`: potential_cap_span ∈ [10, 20], default 15

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0004: Data-Driven Configuration
**ADR Decision Summary**: `decay_factor` and `potential_cap_span` are data-driven `BalanceConfig` fields with validation; growth formula code consumes these values through `ConfigLoader`.

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

- [ ] `attribute_growth = raw_growth_input × max(0, 1 - current_attribute / potential_cap) ^ decay_factor`.
- [ ] `decay_factor` is read from config and validated in range `[0.8, 1.8]`, default `1.2`.
- [ ] `potential_cap_span` is read from config and validated in range `[10, 20]`, default `15`.
- [ ] Lower starting attributes grow more than higher starting attributes under the same inputs.
- [ ] `potential_cap < current_attribute ≤ 100` normalizes `potential_cap` to `current_attribute`, preserves permanent growth, and marks the data for review.
- [ ] At or above potential cap, growth output is `0`.

---

## Implementation Notes

*Derived from ADR-0004 Implementation Guidelines:*

Keep growth formula parameters in `BalanceConfig`; do not duplicate default values in formula code. The shared formula owns only the generic growth curve and boundary normalization, not training project tables or player-development-specific costs.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: Config resource creation and startup validation.
- Player Development stories: concrete training project content and AP costs.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 当前属性较低时，成长结果应接近原始成长输入
  - Given: `raw_growth_input=10`，`current_attribute=20`，`potential_cap=80`，`decay_factor=1.2`
  - When: 计算 `attribute_growth`
  - Then: 返回值大于 0 且明显接近 `raw_growth_input`
  - Edge cases: `current_attribute=0` 时增长应为正；`raw_growth_input=0` 时结果必须为 0

- **AC-2**: 当前属性越接近潜力上限，成长衰减越明显
  - Given: 相同 `raw_growth_input` 与 `potential_cap`，分别取 `current_attribute=40` 与 `79`
  - When: 计算两次 `attribute_growth`
  - Then: `current_attribute=79` 的成长值显著小于 `current_attribute=40`
  - Edge cases: 接近上限时结果可接近 0，但不得出现负增长

- **AC-3**: 当前属性达到或超过潜力上限时，成长必须归零
  - Given: `current_attribute=potential_cap`，以及 `current_attribute > potential_cap`
  - When: 计算 `attribute_growth`
  - Then: 结果均为 0
  - Edge cases: 浮点误差下的 `potential_cap-ε` 仍应得到极小正值；超过上限不得出现 NaN 或负值

- **AC-4**: 潜力边界必须满足配置约束，且不得低于当前属性
  - Given: 使用 `potential_cap_span` 默认值 15，以及边界值 10 和 20
  - When: 初始化或校验属性潜力上限
  - Then: 潜力上限满足配置范围约束，且 `potential_cap >= current_attribute`
  - Edge cases: 当前属性接近 100、span 越界、潜力低于当前值时应校验失败或归一化

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/balance/attribute_growth_test.gd` — must exist and pass

**Status**: [x] Created — `tests/unit/balance/attribute_growth_test.gd`

---

## Dependencies

- Depends on:
  - `production/epics/balance-system/story-001-balance-config-validation.md` — must be DONE
- Unlocks:
  - Downstream work: Player Development growth stories

---

## Completion Notes
**Completed**: 2026-05-27
**Criteria**: 6/6 passing
**Deviations**: None
**Test Evidence**: Logic test passed at `tests/unit/balance/attribute_growth_test.gd`
**Code Review**: Complete
