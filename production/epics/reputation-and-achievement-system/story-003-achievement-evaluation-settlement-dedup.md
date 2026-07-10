# Story 003: 成就判定 + 结算去重

> **Epic**: 声望与成就系统
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M (3-4 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/reputation-and-achievement-system.md`
**Requirement**: `TR-reputation-003`, `TR-reputation-004`
**ADR Governing Implementation**: ADR-0011

**Engine**: Godot 4.6 + GDScript | **Risk**: LOW

## Acceptance Criteria

- [ ] **AC-1**: `achievement_completed = achievement_condition_satisfied AND NOT achievement_already_unlocked` — 只在条件满足且历史上未解锁时返回 true
- [ ] **AC-2**: `reputation_settlement_key = stable_digest(canonical_join([settlement_id, reward_scope, reward_id], "|"))` — `rule_version` 不进入键源
- [ ] **AC-3**: 双账本: `evaluated_reputation_settlement_keys` (已判定) + `processed_reputation_settlement_keys` (已产出 durable outcome)
- [ ] **AC-4**: 同一 `reputation_settlement_key` 重复提交 → 命中 `evaluated` 账本 → 幂等 no-op，不重复增加声望/解锁成就/创建 pending reward
- [ ] **AC-5**: 同一稳定节点触发多个成就时，按 `display_priority DESC → achievement_id ASC` 稳定排序，逐条独立判定

## Implementation Notes

- 成就条件类型: 事件型 (event occurred)、累计型 (counter ≥ threshold)、状态型 (state == value)
- MVP 成就只允许上述三种基础条件组合，不引入限时窗口或外部竞争条件
- 已解锁成就 (`unlocked_achievement_ids`) 永久记录，同一成就不可重复解锁
- `evaluated` 账本记录"已被本系统接受并完成判定"，`processed` 账本只记录"真正产生 durable outcome"

## Out of Scope

- Story 001: recognition summary stub
- Story 002: 声望计算 + 等级推进
- Story 004: serialize/deserialize + view payloads
- 完整成就条件表定义 (config 层后续 story)
- 成就奖励挂接与发放

## QA Test Cases

- **AC-1**: 成就完成判定
  - Given: achievement_condition_satisfied=true, achievement_already_unlocked=false
  - When: 调用 `evaluate_achievement()`
  - Then: 返回 `achievement_completed=true`，`unlocked_achievement_ids` 新增该成就 ID

- **AC-2**: Settlement key 确定性
  - Given: settlement_id="s_001", reward_scope="achievement", reward_id="ach_first_win"
  - When: 两次调用生成 key
  - Then: 两次结果完全相同，rule_version 变更不影响 key

- **AC-4**: 重复提交幂等
  - Given: key 已在 `evaluated_reputation_settlement_keys` 中
  - When: 再次提交同一 key
  - Then: 返回 no-op，`processed_reputation_settlement_keys` 不新增重复项

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/reputation/achievement_settlement_test.gd`

## Dependencies

- Depends on: Story 002 (声望计算 + 等级推进 — `reputation_settlement_key` 生成器)
- Unlocks: Story 004 (持久化 + view payloads)
