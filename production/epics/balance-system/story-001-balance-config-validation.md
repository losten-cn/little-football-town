# Story 001: 定义 BalanceConfig 数据资源与启动校验

> **Epic**: 数值系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-25

## Context

**GDD**: `design/gdd/balance-system.md`
**Requirement**: `TR-balance-006`, `TR-balance-007`, `TR-balance-008`, `TR-balance-010`, `TR-balance-012`, `TR-balance-013`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-balance-006`: flat_modifier_sum_budget [-10, 15]; percent_modifier_sum_budget [-0.20, 0.30]
- `TR-balance-007`: resource_buffer_multiplier ∈ [2.0, 4.0]
- `TR-balance-008`: 4 player tiers with distinct potential_cap and training_efficiency bands
- `TR-balance-010`: All shared formula parameters must live in data-driven config, not hardcoded in src/
- `TR-balance-012`: decay_factor ∈ [0.8, 1.8], default 1.2
- `TR-balance-013`: potential_cap_span ∈ [10, 20], default 15

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0004: Data-Driven Configuration
**ADR Decision Summary**: All shared tuning values live in typed Godot Custom Resources under `res://config/` and are loaded by `ConfigLoader` at startup. Invalid config fails validation and prevents the game from reaching runtime.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Uses Godot Custom Resources, `@export var`, `ResourceLoader`, and startup validation. ADR notes post-cutoff `@abstract` and `duplicate_deep()` APIs require verification if used.

**Control Manifest Rules (this layer)**:
- Required: All gameplay tuning must load through `ConfigLoader` from typed Custom Resources under `res://config/`; invalid config must block startup.
- Forbidden: Never define gameplay tuning as inline constants in `src/`.
- Guardrail: Config load for all config resources combined must stay under 50ms.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

**Asset / Resource References**:
- `res://config/balance_config.tres` is an implementation output or Godot resource path created/used by this story, not a pre-existing asset dependency unless separately listed.

---

## Acceptance Criteria

*From GDD `design/gdd/balance-system.md`, scoped to this story:*

- [ ] `BalanceConfig` contains shared balance tuning values for modifier budgets, resource buffer, player tier boundaries, decay factor, potential cap span, win probability, and KPI targets.
- [ ] `BalanceConfig.validate()` rejects values outside GDD safe ranges, including `decay_factor`, `potential_cap_span`, `rating_win_slope`, modifier budgets, and `resource_buffer_multiplier`.
- [ ] All shared formula parameters must live in data-driven config, not hardcoded in `src/`.
- [ ] `ConfigLoader` loads `res://config/balance_config.tres` at startup and blocks startup on invalid config.

---

## Implementation Notes

*Derived from ADR-0004 Implementation Guidelines:*

Create `BalanceConfig` as a typed `Resource` with `@export var` fields for every shared balance tuning value. Store the resource at `res://config/balance_config.tres`. Implement `validate() -> Dictionary` returning `{valid = true}` or `{valid = false, errors = [...]}`. `ConfigLoader` must load the resource through `ResourceLoader`, call `validate()`, expose it through a typed `balance_config` property, and quit startup if validation fails.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Attribute model and effective attribute formula.
- Story 003: Attribute growth formula and potential boundary logic.
- Story 008: Cross-system consistency scanning.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 启动时必须通过 `ConfigLoader` 成功加载 `BalanceConfig`，且默认值与 ADR-0004 约定一致
  - Given: 存在有效的 `BalanceConfig` 资源，包含 `decay_factor=1.2`、`potential_cap_span=15`、`rating_win_slope=0.0045`、`resource_buffer_multiplier=3.0`
  - When: 游戏启动并执行 balance smoke check
  - Then: `ConfigLoader` 成功加载该资源，所有 balance 系统读取到的值与资源一致
  - Edge cases: 资源路径错误、资源缺失、加载顺序错误时应启动失败并输出明确校验信息

- **AC-2**: 启动校验必须拒绝超出合法范围的配置
  - Given: `BalanceConfig` 中 `decay_factor=0.79` 或 `1.81`，`potential_cap_span=9` 或 `21`，`rating_win_slope=0.0029` 或 `0.0061`
  - When: 执行启动校验
  - Then: 校验失败，阻止进入游戏，并指出具体字段与越界值
  - Edge cases: 边界值 `0.8/1.8`、`10/20`、`0.003/0.006` 必须通过；仅差 0.001 的越界必须失败

- **AC-3**: 配置结构必须完整，关键 balance 字段缺失时不得部分加载
  - Given: `BalanceConfig` 缺少 modifier budget、`resource_buffer_multiplier`、四档球员 tier 边界或五维属性相关字段
  - When: `ConfigLoader` 解析并校验资源
  - Then: 返回无效配置，拒绝部分加载或静默回退到硬编码值
  - Edge cases: 空资源、字段类型错误、`min > max`、NaN/Inf 值均应失败

- **AC-4**: 调整 `BalanceConfig` 后，公式结果必须随配置变化而变化，无需修改 `src/`
  - Given: 两份配置仅 `rating_win_slope` 不同，其余字段相同
  - When: 分别加载两份配置并执行同一组胜率计算
  - Then: 输出结果随配置变化，证明公式参数来自 `BalanceConfig` 而非 `src/` 硬编码
  - Edge cases: 某个系统仍读取旧缓存值、某个消费者使用本地常量时应在 smoke 中暴露

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Config/Data: smoke check pass (`production/qa/smoke-balance-config.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks:
  - `production/epics/balance-system/story-002-attribute-formula.md`
  - `production/epics/balance-system/story-003-attribute-growth.md`
  - `production/epics/balance-system/story-004-resource-settlement.md`
  - `production/epics/balance-system/story-005-positional-rating.md`
  - `production/epics/balance-system/story-006-win-probability.md`
  - `production/epics/balance-system/story-007-kpi-formulas.md`
