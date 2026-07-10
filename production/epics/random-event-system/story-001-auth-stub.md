# Story 001: RandomEventManager 最小 Authority Stub

> **Epic**: 随机事件系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic + Integration
> **Estimate**: M (3-4 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/random-event-system.md`
**Requirement**: `TR-randomevent-001`, `TR-randomevent-004`, `TR-randomevent-005`
**ADR Governing Implementation**: ADR-0012 (Random Event Settlement Contracts)

**Engine**: Godot 4.6 + GDScript | **Risk**: LOW

**Control Manifest Rules (Feature Layer)**:
- Required: settlement work at stable event boundaries, not per-frame
- Forbidden: 不得直接写入 resource/player/facility/match/reputation durable truth

## Acceptance Criteria

- [ ] **AC-1**: `RandomEventManager` 为场景实例化节点 (class_name)，不是 Autoload
- [ ] **AC-2**: 独占 durable truth 字段: `pending_random_event_instance`, `recent_random_event_history`, `event_cooldown_state`, `processed_event_settlement_keys`
- [ ] **AC-3**: `event_settlement_key = stable_digest([event_instance_id, selected_option_id, target_scope, target_id])`, `rule_version` 不进入 key 源
- [ ] **AC-4**: `processed_event_settlement_keys` 用于幂等去重——相同 key 不重复写 history/发奖励/展示
- [ ] **AC-5**: 提供 `serialize()` / `deserialize()` 契约注册到 SaveManager

## Implementation Notes

- 参考 ADR-0012 Implementation Guidelines: settlement key 从 canonical scalar fields 生成
- `stable_digest()` 使用 `String.md5_text()` 或等效确定性摘要
- Payload 使用 `Dictionary[String, Variant]` typed contract
- 禁止在 settlement key 中包含 `rule_version`、display labels、runtime container hash

## Out of Scope

- Story 002: 事件触发窗口监听 (`time_phase_changed`) 和 offer 骨架

## QA Test Cases

- **AC-1**: RandomEventManager 为场景实例化节点
  - Given: 场景实例化 RandomEventManager
  - When: 检查 `is_instance_of(RandomEventManager)`
  - Then: true AND node 不是 Autoload

- **AC-2**: durable truth 字段存在且初始化为空
  - Given: RandomEventManager 新实例
  - When: 读取 4 个 durable truth 字段
  - Then: pending = null, history = [], cooldown = {}, processed_keys = []

- **AC-3**: event_settlement_key 确定性
  - Given: 相同输入 (event_id, option_id, scope, target_id)
  - When: 两次调用 key 生成
  - Then: 两次结果完全相等 AND rule_version 变更不影响 key

- **AC-4**: 幂等去重
  - Given: key 已在 processed_event_settlement_keys 中
  - When: 尝试以相同 key 提交
  - Then: 返回 false (不重复处理)

- **AC-5**: serialize/deserialize round-trip
  - Given: 已设置 durable fields
  - When: serialize → deserialize
  - Then: 所有字段值与原始一致

## Test Evidence

**Story Type**: Logic + Integration
**Required evidence**: `tests/unit/random_event/auth_stub_test.gd`

## Dependencies

- Depends on: None
- Unlocks: Story 002 (事件触发窗口与 offer 骨架)

## Completion Notes
**Completed**: 2026-07-10
**Criteria**: 5/5 passing (all auto-verified)
**Deviations**: None
**Test Evidence**: Logic + Integration — `tests/unit/random_event/auth_stub_test.gd` (5 test functions, PASS)
**Code Review**: Complete
**Implementation**: `src/core/random_event_manager.gd` (Story 001 baseline — 4 durable fields + settlement key + serialize/deserialize + idempotency guard)
