# Story 006: 实现基准胜率公式与边界

> **Epic**: 数值系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/balance-system.md`
**Requirement**: `TR-balance-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-balance-005`: base_win_probability = 0.5 + rating_win_slope × (home_strength - away_strength), clamped [0.05, 0.95]

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0004: Data-Driven Configuration
**ADR Decision Summary**: `rating_win_slope`, floor, and ceiling are config-backed balance parameters consumed through `BalanceConfig`.

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

- [ ] `base_win_probability = clamp(0.50 + (self_team_rating - opponent_team_rating) × rating_win_slope, 0.05, 0.95)`.
- [ ] `rating_win_slope` is read from config and validated in range `[0.003, 0.006]`, default `0.0045`.
- [ ] Win probability floor and ceiling are enforced at `0.05` and `0.95` for shared base probability.
- [ ] Team ratings above 100 are accepted when passed as effective team ratings from MatchCompetition.
- [ ] Manual calculation results match system output.

---

## Implementation Notes

*Derived from ADR-0004 Implementation Guidelines:*

Implement the shared base win probability anchor only. MatchCompetition owns home advantage, tactic, condition, event simulation, and final result flow, but must consume this shared anchor instead of redefining it.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Match Competition stories: actual match simulation, tactical modifiers, seeded RNG, result packet.
- Story 009: Statistical validation across repeated trials.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 双方评分相同时，基准胜率必须为 0.50
  - Given: `self_team_rating = opponent_team_rating`
  - When: 计算 `base_win_probability`
  - Then: 结果为 `0.50`
  - Edge cases: 微小浮点差异不应导致明显偏离 0.50

- **AC-2**: 胜率变化必须随评分差与 `rating_win_slope` 线性变化
  - Given: `self_team_rating - opponent_team_rating = 20`，`rating_win_slope=0.0045`
  - When: 计算 `base_win_probability`
  - Then: 结果为 `0.50 + 20 × 0.0045 = 0.59`
  - Edge cases: 评分差为 `-20` 时结果应为 `0.41`；斜率必须取自 `BalanceConfig`

- **AC-3**: 胜率必须被钳制在 `[0.05, 0.95]`
  - Given: 极大正评分差与极大负评分差
  - When: 计算 `base_win_probability`
  - Then: 上限返回 `0.95`，下限返回 `0.05`
  - Edge cases: 恰好命中边界时保留边界值；不得返回 `<0.05`、`>0.95`、NaN

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/balance/win_probability_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/balance-system/story-005-positional-rating.md` — must be DONE
- Unlocks:
  - `production/epics/balance-system/story-009-balance-statistical-validation.md`
