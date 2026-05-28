# Story 009: 实现培养闭环回归样本与持久化一致性验证

> **Epic**: 运动员培养系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/player-development-system.md`
**Requirement**: `TR-playerdev-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-playerdev-008`: Training gains survive save/load without loss or double-settlement

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0005: Player Data Model
**ADR Decision Summary**: PlayerDevelopment owns the roster and training operations, registers save/load contracts, and provides structured player growth state to downstream systems without duplicating derived values.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RefCounted`, `Resource`, and `Dictionary` serialization are stable Godot 4.x APIs; no post-cutoff API verification required.

**Control Manifest Rules (this layer)**:
- Required: Every Core system must register its serialization contract with `SaveManager` and restore only through the centralized load pipeline.
- Forbidden: Never serialize or persist derived player values such as `effective` or positional overall ratings.
- Guardrail: Roster serialization <50ms for a full roster; save/load total time load <500ms for a full save.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/player-development-system.md`, scoped to this story:*

- [x] A representative MVP session completes: view player differences → choose training → consume resources and time → receive growth feedback → save/load with consistent player state.
- [x] Regression samples for focused training, ordinary-player priority, and star-player priority show opportunity cost and long-term ceiling differences or are marked as tuning failures.
- [x] With `facility_training_multiplier = 1.0`, training result matches the hand-calculated formula result.

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

This story creates regression evidence for the complete player-development loop. Use PlayerDevelopment's authoritative training path and SaveManager serialization, not UI-only state. Treat balance sample failures as tuning failures rather than changing formula ownership inside this story.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Presentation UI for final player management screens.
- Balance tuning changes if route samples fall outside target bands.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 一个 MVP 会话可完成：查看差异→选择训练→消耗资源与时间→获得成长反馈→读档恢复后保持一致。
  - Given: 一个可训练的 MVP 存档状态，且已记录训练前的球员差异、资源与时间状态。
  - When: 完成一次完整训练闭环，再保存并读档恢复。
  - Then: 训练前后差异可见；资源与时间已正确消耗；成长反馈已产生；读档后球员与资源状态与保存时一致。
  - Edge cases: 训练在提交前中断时不得留下部分结果；同一存档重复读取不应重复扣费或重复成长。

- **AC-2**: 集中培养/普通优先/明星优先等路线样本能体现机会成本和长期上限差异，越界时标记调优失败。
  - Given: 至少三组固定回归样本路线：集中培养、普通优先、明星优先，且各自有预期目标区间。
  - When: 跑完定义好的样本周期并比较资源消耗、阶段收益与长期上限。
  - Then: 各路线应体现可区分的机会成本与长期上限差异；结果超出目标区间时标记调优失败。
  - Edge cases: 若两条路线结果几乎无差异而抹平策略区别，应判为失败；被潜力上限裁剪的样本仍需按既定目标解释结果。

- **AC-3**: 无设施倍率=1.0 时，训练结果与手工公式一致。
  - Given: 一个无设施加成的固定输入样本，facility_training_multiplier = 1.0，且手工公式结果可预先计算。
  - When: 执行训练结算。
  - Then: 系统输出的 training_actual_gain 与手工公式结果一致，不引入额外隐含倍率。
  - Edge cases: 处于效率钳制边界时仍应一致；若存在数值精度处理，应在约定容差内完全匹配。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/player-dev/player_development_regression_test.gd` OR playtest doc

**Status**: [x] Created — `tests/integration/player-dev/player_development_regression_test.gd` + `tests/integration/player-dev/player_development_regression_test.tscn`; Godot 4.6.2 headless result: `PLAYER_DEVELOPMENT_REGRESSION_TEST_PASS` (non-blocking exit warnings remain)

---

## Dependencies

- Depends on:
  - `production/epics/player-development-system/story-001-player-data-serialization-boundary.md` — must be DONE
  - `production/epics/player-development-system/story-002-training-efficiency-formula.md` — must be DONE
  - `production/epics/player-development-system/story-003-training-gain-cap.md` — must be DONE
  - `production/epics/player-development-system/story-004-player-tier-band.md` — must be DONE
  - `production/epics/player-development-system/story-005-training-roi.md` — must be DONE
  - `production/epics/player-development-system/story-006-training-atomic-integration.md` — must be DONE
  - `production/epics/player-development-system/story-007-player-milestone-history.md` — must be DONE
  - `production/epics/player-development-system/story-008-player-state-boundary.md` — must be DONE
- Unlocks:
  - Downstream work: Match competition integration, Player Management UI implementation, MVP loop validation
