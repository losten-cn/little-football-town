# Story 003: 实现训练成长结算与潜力上限裁剪

> **Epic**: 运动员培养系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/player-development-system.md`
**Requirement**: `TR-playerdev-003`, `TR-playerdev-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-playerdev-003`: training_actual_gain = attribute_growth × fatigue × focus_match × facility_multiplier
- `TR-playerdev-004`: facility_training_multiplier ∈ [1.0, 1.75] — consumed from TownBuilding

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0005: Player Data Model
**ADR Decision Summary**: PlayerDevelopment computes training gains from shared growth formulas, player state, focus matching, and external facility multiplier, then applies growth only to authoritative current attributes.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RefCounted`, `Resource`, and `Dictionary` serialization are stable Godot 4.x APIs; no post-cutoff API verification required.

**Control Manifest Rules (this layer)**:
- Required: Core systems must access config through typed `ConfigLoader` properties, not string-keyed lookups.
- Forbidden: Never serialize or persist derived player values such as `effective` or positional overall ratings.
- Guardrail: Player runtime memory ~25KB target for roster structures.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/player-development-system.md`, scoped to this story:*

- [ ] `training_actual_gain = min(potential_cap - current_attribute, attribute_growth(...) × fatigue_adjusted_training_efficiency × training_focus_match_multiplier × facility_training_multiplier)`.
- [ ] `facility_training_multiplier` is consumed from TownBuilding and constrained to `[1.0, 1.75]`.
- [ ] If `current_attribute = potential_cap`, growth is `0`; if `potential_cap < current_attribute`, normalize potential to current and mark the player for review.

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

Use the shared `attribute_growth` formula as the base growth term and multiply by fatigue-adjusted efficiency, training focus matching, and TownBuilding's facility multiplier. Apply gains only to `attributes.current`, clamp to `attributes.potential`, and do not modify derived values.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: ROI calculation and multi-attribute training project analysis.
- Story 006: Economy cost deduction and time advancement around the training operation.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: training_actual_gain = min(potential_cap - current_attribute, attribute_growth(...) × fatigue_adjusted_training_efficiency × training_focus_match_multiplier × facility_training_multiplier)。
  - Given: 已知 current_attribute、potential_cap、基础成长与全部乘数的固定样本，且剩余成长空间可精确计算。
  - When: 执行一次训练成长结算。
  - Then: training_actual_gain 等于“公式结果”和“剩余成长空间”中的较小者，且结算后属性不超过 potential_cap。
  - Edge cases: 公式结果恰等于剩余空间时应精确贴边；剩余空间为正但很小时仍只增长到 cap。

- **AC-2**: facility_training_multiplier 消费自 TownBuilding，范围 [1.0, 1.75]。
  - Given: TownBuilding 提供 1.0、区间中值、1.75 三组设施倍率样本。
  - When: 在其余输入完全相同的前提下执行训练结算。
  - Then: 成长结果随 TownBuilding 提供的设施倍率变化而变化，且仅接受 [1.0, 1.75] 区间内的倍率。
  - Edge cases: 无设施加成时倍率视为 1.0；超出区间的设施数据不得静默生效，至少进入复核。

- **AC-3**: current_attribute = potential_cap 时成长为 0；potential_cap < current_attribute 时规范化到 current_attribute 并标记复核。
  - Given: 一名球员 current_attribute 恰等于 potential_cap，另一名球员出现 potential_cap 小于 current_attribute 的异常数据。
  - When: 执行训练成长结算。
  - Then: 前者 training_actual_gain 为 0；后者先把 potential_cap 规范化到 current_attribute，再得到 0 成长并生成复核标记。
  - Edge cases: 仅异常属性被规范化，不影响该球员其他属性；异常数据在读档后再次结算也不得产生负成长。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player-dev/training_gain_cap_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/player-development-system/story-001-player-data-serialization-boundary.md` — must be DONE
  - `production/epics/player-development-system/story-002-training-efficiency-formula.md` — must be DONE
- Unlocks:
  - `production/epics/player-development-system/story-005-training-roi.md`
  - `production/epics/player-development-system/story-006-training-atomic-integration.md`
