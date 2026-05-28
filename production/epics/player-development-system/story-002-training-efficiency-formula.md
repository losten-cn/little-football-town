# Story 002: 实现训练效率与状态修正公式

> **Epic**: 运动员培养系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/player-development-system.md`
**Requirement**: `TR-playerdev-002`, `TR-playerdev-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-playerdev-002`: fatigue_adjusted_training_efficiency = efficiency × condition × morale, clamped [0.5, 1.8]
- `TR-playerdev-010`: Individual training_efficiency ∈ [0.8, 1.5] per player

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0005: Player Data Model
**ADR Decision Summary**: `Player` owns individual training efficiency and persistent condition/morale multipliers; `PlayerDevelopment` computes training results through typed player data.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RefCounted`, `Resource`, and `Dictionary` serialization are stable Godot 4.x APIs; no post-cutoff API verification required.

**Control Manifest Rules (this layer)**:
- Required: Represent `Player` as `RefCounted`; treat `effective` and positional ratings as derived-only values.
- Forbidden: Never model runtime players as individual Resource assets or plain nested Dictionaries.
- Guardrail: Player runtime memory ~25KB target for roster structures.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/player-development-system.md`, scoped to this story:*

- [x] `fatigue_adjusted_training_efficiency = clamp(training_efficiency × condition_multiplier × morale_multiplier, 0.5, 1.8)`.
- [x] Individual `training_efficiency` is constrained to `[0.8, 1.5]` per player.
- [x] High fatigue, low morale, or recovery-state inputs reduce effective training efficiency without dropping below the formula lower bound.

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

Compute fatigue-adjusted efficiency from `Player.training_efficiency`, `condition_multiplier`, and `morale_multiplier` in the PlayerDevelopment formula path. Keep player base `training_efficiency` as authoritative player state and clamp abnormal player data before it participates in training resolution, marking abnormal data for review.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: Applying this efficiency to actual attribute growth.
- Story 008: Consuming post-match condition and morale changes.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: fatigue_adjusted_training_efficiency = clamp(training_efficiency × condition_multiplier × morale_multiplier, 0.5, 1.8)。
  - Given: 已知 training_efficiency、condition_multiplier、morale_multiplier 的固定输入样本，覆盖下界内、正常区间、上界外三类。
  - When: 计算 fatigue_adjusted_training_efficiency。
  - Then: 输出严格等于乘积结果再钳制到 [0.5, 1.8]。
  - Edge cases: 结果恰好为 0.5 或 1.8 时应保留边界值；乘积位于区间内时不得额外偏移。

- **AC-2**: training_efficiency 异常输入会被钳制回 [0.8, 1.5] 并标记复核。
  - Given: 输入 training_efficiency 分别低于 0.8、高于 1.5、以及恰在边界值的样本球员。
  - When: 执行训练效率校验/规范化。
  - Then: 低于下界的值被规范为 0.8，高于上界的值被规范为 1.5，并产生复核标记；边界值保持不变且不误报。
  - Edge cases: 同一异常值重复校验不应重复叠加标记；异常来源为空或缺省时仍需进入复核。

- **AC-3**: 高疲劳/低心情会降低有效训练效率，但不会低于 0.5。
  - Given: 两名基础 training_efficiency 相同的球员，其中一名具有更低 condition 或 morale。
  - When: 分别计算 fatigue_adjusted_training_efficiency。
  - Then: 低 condition / low morale 的样本结果严格低于基准样本，但最终值不低于 0.5。
  - Edge cases: 仅 condition 低或仅 morale 低时也应下降；两者同时极低时结果仍应被钳在 0.5。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player-dev/training_efficiency_formula_test.gd` — must exist and pass

**Status**: [x] Test file created at `tests/unit/player-dev/training_efficiency_formula_test.gd`; runtime verification passed locally via `tests/unit/player-dev/training_efficiency_formula_runner.gd` with Godot 4.6.2 headless result `TRAINING_EFFICIENCY_FORMULA_TEST_PASS` (non-blocking exit warnings remain)

---

## Dependencies

- Depends on:
  - `production/epics/player-development-system/story-001-player-data-serialization-boundary.md` — must be DONE
- Unlocks:
  - `production/epics/player-development-system/story-003-training-gain-cap.md`
  - `production/epics/player-development-system/story-008-player-state-boundary.md`
