# Story 009: 实现时间状态展示字段与节奏回归样本

> **Epic**: 时间与赛季推进系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/time-and-season-progression-system.md`
**Requirement**: `TR-time-003`, `TR-time-006`, `TR-time-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-time-003`: available_action_windows: remaining actions before forced time advance
- `TR-time-006`: season_progress_ratio = matches_played / total_matches
- `TR-time-008`: TimeManager exposes get_state() for save snapshots

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0002: Event/Signal Architecture + TimeManager
**ADR Decision Summary**: TimeManager provides pull state for UI and save/load, and pushes updates via EventBus so display surfaces remain consistent without polling independent time state.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Integration regression should verify state data rather than visual presentation fidelity.

**Control Manifest Rules (this layer)**:
- Required: `TimeManager` must provide both synchronous pull access (`get_state`) and runtime push updates.
- Forbidden: Never poll Core state from `_process()` for routine UI refresh when an EventBus update exists.
- Guardrail: TimeManager startup work must stay under 1ms in `_ready()`.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/time-and-season-progression-system.md`, scoped to this story:*

- [ ] Time state exposes current date/phase, next key node, remaining windows, and season position for UI consumption.
- [ ] `remaining_time_to_next_key_node = max(0, next_key_node_position - current_timeline_position)`.
- [ ] A standard MVP session can complete the minimum loop: arrange action → match node → post-match settlement → stage or season node.
- [ ] Time status fields are consistent across display consumers and internal TimeManager state.
- [ ] Season progression samples, match frequency, and stage settlement frequency fall inside GDD tuning target bands or are marked as tuning failures.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

Expose structured read-only state for UI. This story creates state regression evidence, not final UI layouts or animations.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Presentation UI stories: visual rendering of time widgets, warnings, or navigation.
- Balance tuning changes if regression samples fall outside target bands.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 时间状态展示字段完整且与公式一致
  - Given: TimeManager 处于任一可展示状态
  - When: 读取时间状态展示数据
  - Then: 至少应正确提供 `current_state`、`available_action_windows`、`season_progress_ratio`、`remaining_time_to_next_key_node`
  - Edge cases: `remaining_time_to_next_key_node` 必须满足 `max(0, next_key_node_position - current_timeline_position)`，不得为负数

- **AC-2**: 节奏回归样本在关键检查点保持稳定
  - Given: 预设一条代表性时间推进样本，覆盖 `Planning → Action Resolution → Match Trigger → Match In Progress → Post-Match Settlement → Stage Settlement → Season Settlement / Offseason / SeasonStart`
  - When: 按样本逐步推进并在每个检查点记录状态字段
  - Then: 各检查点的状态、窗口数、赛季比值、到下个关键节点剩余时间必须与基线一致
  - Edge cases: 同位置连续触发、赛后连续结算、赛季结束边界都应纳入样本

- **AC-3**: 展示层按 GDD 的 9 状态枚举，不按过期 7 状态假设渲染
  - Given: 展示层/调试面板读取 TimeManager 的状态字段
  - When: 遍历并展示全部可达状态
  - Then: 必须能正确展示 9 个 GDD 状态，不得遗漏 `Post-Match Settlement`、`Offseason`、`SeasonStart` 等状态
  - Edge cases: 若上层仍按 7 状态做映射，应测试失败并标明为文档/实现未同步

- **AC-4**: 展示字段在边界值下仍稳定可读
  - Given: 可用窗口为 0、赛季比值达到 1、下个关键节点剩余时间为 0
  - When: 刷新状态展示
  - Then: 展示结果应与内部状态一致，且不会出现负值、空值或延后一拍更新
  - Edge cases: 比值刚好 1 时应同步反映即将/已经进入 `Season Settlement`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/time/time_status_regression_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/time-and-season-progression-system/story-001-time-manager-state-contract.md` — must be DONE
  - `production/epics/time-and-season-progression-system/story-002-action-window-formula.md` — must be DONE
  - `production/epics/time-and-season-progression-system/story-005-season-progress-flow.md` — must be DONE
  - `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md` — must be DONE
- Unlocks:
  - Downstream work: Main Loop UI time display and MVP loop validation
