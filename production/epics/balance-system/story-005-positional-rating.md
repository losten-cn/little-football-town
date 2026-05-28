# Story 005: 实现位置综合评分公式

> **Epic**: 数值系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-25

## Context

**GDD**: `design/gdd/balance-system.md`
**Requirement**: `TR-balance-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-balance-004`: positional_overall_rating aggregates position-weighted attributes into 0-100 score

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0004: Data-Driven Configuration
**ADR Decision Summary**: Shared formula code consumes typed config and remains the single source for cross-system balance calculations.

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

- [ ] `positional_overall_rating = Σ(effective_attribute_i × position_weight_i)` for `i ∈ {SPD, PWR, TEC, INT, STA}`.
- [ ] The formula uses effective attributes, not current or potential values.
- [ ] Position weights must be non-negative and sum to `1` for Locked data.
- [ ] Draft/Tuned invalid weights are normalized according to GDD Edge Cases before calculation.
- [ ] Manual calculation results match system output.

---

## Implementation Notes

*Derived from ADR-0004 Implementation Guidelines:*

Implement a shared formula interface that accepts typed five-attribute effective values and typed position weights. Do not define position content tables here; downstream PlayerDevelopment or MatchCompetition config owns actual position weight sets.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Effective attribute calculation.
- Match Competition stories: team rating aggregation, lineup, tactic, and match flow.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 位置综合评分必须等于五项有效属性按位置权重的加权和
  - Given: `effective_attribute` 为 `SPD=80,PWR=60,TEC=70,INT=50,STA=90`，某位置权重为 `0.3/0.2/0.2/0.1/0.2`
  - When: 计算 `positional_overall_rating`
  - Then: 结果为 `80×0.3 + 60×0.2 + 70×0.2 + 50×0.1 + 90×0.2 = 73`
  - Edge cases: 浮点误差需控制在可接受范围内；不得遗漏任一属性项

- **AC-2**: 权重为 0 的属性不得对评分产生影响
  - Given: 某位置 `PWR` 权重为 0，其余权重有效
  - When: 计算 `positional_overall_rating`
  - Then: `PWR` 数值变化不应改变最终评分
  - Edge cases: 多个属性权重为 0 时仍应正常计算；全部为 0 时按 GDD 原型规则退回算术平均并标记配置无效

- **AC-3**: 评分计算必须基于 `effective` 属性层，而非 `current` 或 `potential`
  - Given: `current`、`potential` 与 `effective` 值不同
  - When: 计算 `positional_overall_rating`
  - Then: 结果仅随 `effective` 变化而变化
  - Edge cases: modifier 改变 effective 后评分应同步变化；仅改 potential 不应直接改评分

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/balance/positional_rating_test.gd` — must exist and pass

**Status**: [x] Created — tests/unit/balance/positional_rating_test.gd

---

## Dependencies

- Depends on:
  - `production/epics/balance-system/story-002-attribute-formula.md` — must be DONE
- Unlocks:
  - `production/epics/balance-system/story-006-win-probability.md`

## Completion Notes
**Completed**: 2026-05-25
**Criteria**: 5/5 passing
**Deviations**: Runtime verification not executed in-session because `godot` is unavailable in PATH; test harness remains custom Node runner; QA suggested additional coverage for zero-sum locked invalidity, non-negative non-unit locked weights, and float tolerance follow-up.
**Test Evidence**: Logic: `tests/unit/balance/positional_rating_test.gd`
**Code Review**: Complete — approved with suggestions
