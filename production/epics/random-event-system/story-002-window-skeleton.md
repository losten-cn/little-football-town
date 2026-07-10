# Story 002: 事件触发窗口与 Offer 骨架

> **Epic**: 随机事件系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M (3-4 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: [set by /dev-story]

## Context

**GDD**: `design/gdd/random-event-system.md`
**Requirement**: `TR-randomevent-002`, `TR-randomevent-003`, `TR-randomevent-006`
**ADR Governing Implementation**: ADR-0012

**Engine**: Godot 4.6 + GDScript | **Risk**: LOW

## Acceptance Criteria

- [ ] **AC-1**: 通过 EventBus 订阅 `time_phase_changed`，只在 TimeManager 声明的稳定窗口内触发事件检查
- [ ] **AC-2**: `_evaluate_event_trigger()` 检查冷却 (`event_cooldown_state`) 和近期历史 (`recent_random_event_history`)，满足条件时生成 `pending_random_event_instance`
- [ ] **AC-3**: 提供 `random_event_offer_view_payload` (只读 Dictionary[String, Variant]) 供 UI 消费——不暴露内部 mutable state
- [ ] **AC-4**: `random_event_history_view_payload` 提供近期事件历史只读视图
- [ ] **AC-5**: 展示层不得通过 payload 重抽/重算/补造——所有 event 逻辑在 RandomEventManager 内闭包

## Implementation Notes

- EventBus 订阅在 `_ready()` 中执行，取消订阅在 `_exit_tree()` 中
- `time_phase_changed` 事件是最优先调度事件 (ADR-0002 event dispatch order)
- 冷却检查: 读取 `event_cooldown_state[event_category]`，与当前 game_time 比较
- Payload 组装为 shallow typed dictionary，禁止 live object references

## Out of Scope

- Story 001: durable truth 字段和 settlement key 生成
- 实际事件分类/选项/效果实现 (Beta 后续 story)
- UI 渲染 (Presentation 层 story)
- 效果提交到 Economy/Player/Town 系统 (Beta 后续 story)

## QA Test Cases

- **AC-1**: time_phase_changed 事件触发检查
  - Given: RandomEventManager 已订阅 EventBus
  - When: EventBus 分发 `time_phase_changed` (phase=STABLE)
  - Then: `_evaluate_event_trigger()` 被调用

- **AC-2**: 冷却检查阻止重复触发
  - Given: event_cooldown_state[category] 在未来
  - When: 触发检查
  - Then: pending_random_event_instance 保持 null

- **AC-3**: offer_view_payload 为只读
  - Given: pending_random_event_instance 已设置
  - When: 获取 `random_event_offer_view_payload`
  - Then: payload 是 Dictionary[String, Variant]，修改 payload 不影响内部 state

- **AC-4**: history_view_payload
  - Given: recent_random_event_history 包含 3 个条目
  - When: 获取 view payload
  - Then: payload 包含 3 个条目且按时间倒序

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/random_event/window_skeleton_test.gd`

## Dependencies

- Depends on: Story 001 (RandomEventManager auth stub — durable truth 字段)
- Unlocks: 后续 Beta story (实际事件分类/选项/效果)
