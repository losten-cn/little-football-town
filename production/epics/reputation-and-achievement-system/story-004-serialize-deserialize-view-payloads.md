# Story 004: 持久化 + UI View Payload

> **Epic**: 声望与成就系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: M (3-4 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/reputation-and-achievement-system.md`
**Requirement**: `TR-reputation-005`, `TR-reputation-006`
**ADR Governing Implementation**: ADR-0011

**Engine**: Godot 4.6 + GDScript | **Risk**: LOW

## Acceptance Criteria

- [ ] **AC-1**: 8 个 durable 字段 (`reputation_total`, `reputation_level`, `reputation_progress_ratio`, `unlocked_achievement_ids`, `pending_reputation_rewards`, `granted_reputation_reward_records`, `evaluated_reputation_settlement_keys`, `processed_reputation_settlement_keys`) 完整 serialize/deserialize round-trip
- [ ] **AC-2**: 读档恢复后所有字段与存档前一致，不重复发放奖励、不丢失 pending rewards、不重算声望进度
- [ ] **AC-3**: `get_reputation_view_payload()` 返回只读 `Dictionary[String, Variant]` — 包含 `reputation_total`, `reputation_level`, `reputation_progress_ratio`
- [ ] **AC-4**: `get_achievement_view_payload()` 返回只读 `Dictionary[String, Variant]` — 包含 `unlocked_achievement_ids`, `pending_reputation_rewards`
- [ ] **AC-5**: 展示层修改 payload 不影响内部 durable state (shallow duplicate 防护)
- [ ] **AC-6**: 注册 `serialize()` / `deserialize()` 契约到 SaveManager

## Implementation Notes

- Payload 使用 `Dictionary[String, Variant]` typed contract
- Shallow duplicate 保证 UI mutation 不穿透到内部 state
- SaveManager 注册: `save_manager.register_system("reputation", Callable(self, "serialize"), Callable(self, "deserialize"))`
- 读档恢复不得停留在"半结算"中间态 — 完整 durable result 恢复或拒绝

## Out of Scope

- Story 002: 声望计算 + 等级推进
- Story 003: 成就判定 + settlement key 去重
- UI 实际渲染 (Presentation 层 story)

## QA Test Cases

- **AC-1**: Serialize/deserialize round-trip
  - Given: 已设置所有 8 个 durable 字段
  - When: serialize → deserialize 到新实例
  - Then: 所有字段值与原始一致

- **AC-3**: View payload 只读
  - Given: reputation_total=150, reputation_level=2
  - When: 获取 `reputation_view_payload`，修改返回值
  - Then: 内部 `reputation_total` 和 `reputation_level` 不变

- **AC-5**: Payload mutation 隔离
  - Given: unlocked_achievement_ids=["ach_1"]
  - When: 获取 payload 后 payload["unlocked_achievement_ids"].append("INJECTED")
  - Then: 内部 `unlocked_achievement_ids` 仍为 ["ach_1"]

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/reputation/save_restore_payload_test.gd`

## Dependencies

- Depends on: Story 003 (成就判定 + settlement 去重 — 双账本字段定义)
- Unlocks: None (epic 最后 story)
