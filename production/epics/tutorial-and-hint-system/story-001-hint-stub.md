# Story 001: TutorialHintManager 最小 Stub

> **Epic**: 教程与提示系统
> **Status**: Ready
> **Layer**: Polish
> **Type**: Logic + Integration
> **Estimate**: S (2-3 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/tutorial-and-hint-system.md`
**Requirement**: `TR-tutorial-001`, `TR-tutorial-002`, `TR-tutorial-003`, `TR-tutorial-006`, `TR-tutorial-007`
**ADR**: N/A — Presentation Support 层，消费已有系统权威 payload，无独立架构决策

**Engine**: Godot 4.6 + GDScript | **Risk**: LOW

## Acceptance Criteria

- [ ] **AC-1**: `TutorialHintManager` 为场景实例化节点，不是 Autoload。独占 `seen_hints: Array[String]`, `disabled_hints: Array[String]`, `hint_cooldowns: Dictionary[String, float]`, `help_index_visible: bool`
- [ ] **AC-2**: 消费 `OnboardingSystem` 引导完成标记——区分首次用户（显示引导提示）和回访用户（仅显示上下文帮助）
- [ ] **AC-3**: 提示冷却检查——同一 hint_id 在 cooldown 期间不重复显示；`disabled_hints` 中的 hint 永久抑制
- [ ] **AC-4**: `serialize() / deserialize()` 持久化所有 hint 状态；读档恢复不重复刷屏
- [ ] **AC-5**: `get_hint_view_payload(hint_id: String) → Dictionary[String, Variant]` 返回只读提示 payload；关闭提示不得造成资源损失

## Implementation Notes

- 提示措辞使用低压语气("可以查看" / "这里说明")，不使用"必须"/"立刻"/"错过"等高压词
- 冷却默认 300s (5分钟)，可通过 `hint_cooldowns` 配置
- 不包含自动弹出逻辑——只提供 payload 查询接口，展示由 UI 层控制
- 不新增任务链/奖励循环/每日目标

## Out of Scope

- 自动弹出提示 UI
- 帮助面板/词条系统
- 中长篇规则说明
- 多语言支持

## QA Test Cases

- **AC-1**: 字段初始化
  - Given: TutorialHintManager.new()
  - Then: seen_hints=[], disabled_hints=[], cooldowns={}, help_index=false

- **AC-2**: 引导完成标记消费
  - Given: OnboardingSystem.is_guided()==true
  - When: request_hint("first_training")
  - Then: 提示内容映射到"引导用户"版本

- **AC-3**: 冷却抑制
  - Given: hint "first_training" 刚刚显示过（在 cooldown 内）
  - When: request_hint("first_training")
  - Then: 返回空 payload

- **AC-4**: serialize/deserialize
  - Given: 已设置 seen_hints=["a","b"], disabled_hints=["c"]
  - When: serialize → deserialize
  - Then: 所有状态精确恢复

- **AC-5**: 关闭不造成资源损失
  - Given: hint 已显示
  - When: disable_hint("first_training")
  - Then: 仅更新 disabled_hints，不影响任何 gameplay 状态

## Test Evidence

**Story Type**: Logic + Integration
**Required evidence**: `tests/unit/tutorial/hint_stub_test.gd`

## Dependencies

- Depends on: OnboardingSystem (existing, ADR-defined)
- Unlocks: Story 002 (自动弹出提示 + 帮助面板)
