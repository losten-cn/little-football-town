# Story 007: 实现 KPI 与诊断公式

> **Epic**: 数值系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/balance-system.md`
**Requirement**: `TR-balance-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-balance-009`: 4 KPI formulas: AP use rate, overall win rate, even match win rate, resource efficiency

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0004: Data-Driven Configuration
**ADR Decision Summary**: KPI target ranges are stored in `BalanceConfig`; diagnostic formulas share one implementation and one set of config-backed target bands.

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

- [ ] `action_point_use_rate = action_points_spent / max(1, action_points_available)`.
- [ ] `overall_win_rate = matches_won / max(1, matches_played)`.
- [ ] `even_match_win_rate = even_matches_won / max(1, even_matches_played)` and only includes matches with base probability in `[0.45, 0.55]`.
- [ ] `milestone_completion_time = milestone_timestamp - save_start_timestamp`.
- [ ] Zero-denominator KPI samples return safe values and are marked invalid for balance review.
- [ ] KPI target ranges are read from `BalanceConfig`.

---

## Implementation Notes

*Derived from ADR-0004 Implementation Guidelines:*

Keep these as diagnostic formulas and target bands, not gameplay mutation logic. Downstream systems provide samples; this story defines shared calculation and invalid-sample handling.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Match Competition stories: producing match sample data.
- Reputation/Achievement stories: full Alpha milestone validation for reputation levels.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: `action_point_use_rate` 必须正确反映行动点使用比例
  - Given: 可用行动点 10，已使用行动点 7
  - When: 计算 `action_point_use_rate`
  - Then: 结果为 `0.7`
  - Edge cases: 可用行动点为 0 时返回 0 并标记 `invalid_sample`；已使用值超过上限时应先归一化

- **AC-2**: `overall_win_rate` 必须正确反映总胜率
  - Given: 总比赛 20 场，获胜 11 场
  - When: 计算 `overall_win_rate`
  - Then: 结果为 `0.55`
  - Edge cases: 总比赛为 0 时返回 0 并标记 `invalid_sample`；胜场数为负或大于总场次时应先归一化

- **AC-3**: `even_match_win_rate` 只能统计被判定为势均力敌的样本
  - Given: 势均力敌样本 8 场，其中获胜 4 场；另有非势均力敌样本 12 场
  - When: 计算 `even_match_win_rate`
  - Then: 结果为 `0.5`，且不得混入非势均力敌样本
  - Edge cases: 势均力敌样本为 0 时返回 0 并标记 `invalid_sample`；样本筛选阈值必须与 GDD 定义一致

- **AC-4**: `milestone_completion_time` 必须正确反映里程碑完成耗时
  - Given: 里程碑开始于第 0 分钟，完成于第 24 分钟
  - When: 计算 `milestone_completion_time`
  - Then: 结果为 24 分钟
  - Edge cases: 未完成里程碑应返回未完成态或约定安全值；结束时间早于开始时间时应判为非法输入

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/balance/kpi_formula_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/balance-system/story-001-balance-config-validation.md` — must be DONE
- Unlocks:
  - `production/epics/balance-system/story-009-balance-statistical-validation.md`
