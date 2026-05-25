# Story 002: 实现行动时间消耗与可用窗口公式

> **Epic**: 时间与赛季推进系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/time-and-season-progression-system.md`
**Requirement**: `TR-time-002`, `TR-time-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-time-002`: action_time_cost defines action window consumption
- `TR-time-003`: available_action_windows: remaining actions before forced time advance

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0002: Event/Signal Architecture + TimeManager
**ADR Decision Summary**: TimeManager owns time progression and exposes action-window state through its authoritative timeline model.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Formula implementation should be deterministic, typed GDScript and unit-testable without scene runtime dependencies.

**Control Manifest Rules (this layer)**:
- Required: `TimeManager` must provide synchronous pull access (`get_state`) and runtime push updates.
- Forbidden: Never let downstream systems define independent time units or directly mutate timeline state.
- Guardrail: TimeManager startup work must stay under 1ms in `_ready()`.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/time-and-season-progression-system.md`, scoped to this story:*

- [ ] `action_time_cost = base_time_cost × time_cost_modifier`.
- [ ] Invalid `action_time_cost <= 0` is blocked before time progression.
- [ ] `available_action_windows = floor((current_phase_time_budget - reserved_time - consumed_time) / standard_window_size)`.
- [ ] Available action windows never return negative values.
- [ ] Remaining time insufficient for an action blocks the action and reports failure semantics.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

Keep time cost and window calculations under TimeManager authority. Downstream systems may request time consumption, but cannot own their own independent clock.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: Match node trigger logic.
- Story 009: UI-facing status regression samples.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 行动时间消耗按 GDD 公式计算
  - Given: `base_time_cost > 0` 且 `time_cost_modifier` 在 `[0.5, 2.0]` 内
  - When: 计算 `action_time_cost = base_time_cost × time_cost_modifier`
  - Then: 结果应与公式完全一致
  - Edge cases: 边界值 `modifier = 0.5` 与 `2.0` 必须通过；浮点精度误差需在约定容差内

- **AC-2**: 非法时间消耗输入被阻止
  - Given: `base_time_cost <= 0` 或 `time_cost_modifier <= 0`
  - When: 请求计算行动时间消耗
  - Then: 系统必须阻止结算并返回明确失败结果，而不是生成 0、负数或继续推进时间
  - Edge cases: `base_time_cost = 0`、`modifier = 0`、负数输入都必须覆盖；若实现对越界正数做规范化，需与 story/GDD 保持一致

- **AC-3**: 可用行动窗口按 floor 公式结算
  - Given: 已知 `current_phase_time_budget`、`reserved_time`、`consumed_time`、`standard_window_size`
  - When: 计算 `available_action_windows = floor((budget - reserved - consumed) / standard_window_size)`
  - Then: 结果必须等于公式的向下取整值
  - Edge cases: 恰好整除、余数不足 1 个窗口、`reserved + consumed = budget` 都要覆盖

- **AC-4**: 可用行动窗口不会出现负值
  - Given: `reserved_time + consumed_time >= current_phase_time_budget`
  - When: 计算 `available_action_windows`
  - Then: 输出必须钳制为 `0`
  - Edge cases: 超支 1 点、超支很多、`standard_window_size` 边界值均不应导致负数或异常

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/time/action_window_formula_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/time-and-season-progression-system/story-001-time-manager-state-contract.md` — must be DONE
- Unlocks:
  - `production/epics/time-and-season-progression-system/story-003-match-trigger.md`
  - `production/epics/time-and-season-progression-system/story-009-time-status-regression.md`
