# Story 002: 实现属性模型与有效属性公式

> **Epic**: 数值系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/balance-system.md`
**Requirement**: `TR-balance-001`, `TR-balance-002`, `TR-balance-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-balance-001`: Five core attributes (SPD/PWR/TEC/INT/STA) with three-layer semantics (current/potential/effective)
- `TR-balance-002`: effective_attribute_value = (current + flat_modifiers) × (1 + percent_modifiers), clamped [1, 100]
- `TR-balance-011`: Modifier application order: flat first, then percent

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0004: Data-Driven Configuration
**ADR Decision Summary**: Shared balance parameters are exposed through `BalanceConfig` and loaded by `ConfigLoader`; formula code must consume those parameters instead of local hardcoded tuning values.

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

- [ ] Shared attribute settlement uses only `SPD`, `PWR`, `TEC`, `INT`, `STA`.
- [ ] Each attribute can distinguish `current`, `potential`, and `effective` values.
- [ ] `effective_attribute_value = clamp((current_attribute + flat_modifier_sum) × (1 + percent_modifier_sum), 1, 100)`.
- [ ] Flat modifiers are summed and applied before percent modifiers.
- [ ] Illegal current/effective inputs are normalized according to GDD Edge Cases before formula use.

---

## Implementation Notes

*Derived from ADR-0004 Implementation Guidelines:*

Keep formula code independent from downstream systems and feed it typed config values from `BalanceConfig`. Do not create downstream-specific variants of the formula. Effective values are temporary outputs and must never overwrite permanent `current` attributes.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: Growth and potential cap formula.
- Story 005: Position-weighted overall rating.
- Story 008: CI consistency scanning for duplicate constants.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 有效属性计算必须遵循“先 flat，后 percent”的顺序
  - Given: `current_attribute=50`，`flat_modifier_sum=10`，`percent_modifier_sum=0.20`
  - When: 计算 `effective_attribute_value`
  - Then: 结果为 `clamp((50 + 10) × 1.20, 1, 100) = 72`
  - Edge cases: 若错误按先 percent 后 flat，结果会变成 70，应明确判定失败

- **AC-2**: 有效属性必须按公式上下限钳制到 `[1,100]`
  - Given: 一组输入使结果低于 1，另一组输入使结果高于 100
  - When: 计算 `effective_attribute_value`
  - Then: 低于下限时返回 1，高于上限时返回 100
  - Edge cases: 恰好等于 1 或 100 时必须保留边界值，不得继续偏移

- **AC-3**: `current`、`potential`、`effective` 三层属性必须语义分离
  - Given: 五项属性 `SPD/PWR/TEC/INT/STA` 的 current 与 potential 已初始化
  - When: 对任一属性执行 effective 计算
  - Then: 仅 `effective` 输出变化，`current` 与 `potential` 原值不被修改
  - Edge cases: 多次重复计算、负向 modifier、0 modifier 时结果必须稳定且不串层

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/balance/attribute_formula_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/balance-system/story-001-balance-config-validation.md` — must be DONE
- Unlocks:
  - `production/epics/balance-system/story-005-positional-rating.md`
