# Story 002: 建造/升级确认流

> **Epic**: 建设与经营 UI
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI + Integration
> **Estimate**: M (3-4 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/town-management-ui.md`
**Requirement**: `TR-town-management-ui-003`, `TR-town-management-ui-004`, `TR-town-management-ui-005`
**ADR Referenced**: ADR-0008 (TownBuilding), ADR-0007 (EconomyManager accredited entry)

**Engine**: Godot 4.6 + GDScript | **Risk**: LOW

## Acceptance Criteria

- [ ] **AC-1**: 点击 grid cell → 预算预览面板弹出，展示"当前经费 → 确认后经费"和"当前维护费 → 完成后维护费"
- [ ] **AC-2**: 确认按钮调用 `EconomyManager.accredit_facility_cost()` —— 不直接扣除经费
- [ ] **AC-3**: 资源不足时禁用确认按钮，显示具体原因（"经费不足：还差 120"）
- [ ] **AC-4**: 取消按钮关闭面板，返回 grid 视图（不触发建造）
- [ ] **AC-5**: 设施状态展示: 未建造/建设中/运作中/升级中 —— 建设中显示剩余工期

## Implementation Notes

- 预算预览通过 `TownBuilding.get_facility_at()` + `EconomyManager.get_funds()` + `get_daily_maintenance()` 组装
- Accredited economy path: `EconomyManager.accredit_facility_cost()` per ADR-0007
- 低压文案: 资源不足显示温和提示，不使用破产/危机措辞
- Panel 使用 WarmPalette 样式

## Out of Scope

- 实际建造执行 (construction timer 启动)
- 多项目并行
- 设施拆除/重排
- 邻接收益展示

## QA Test Cases

- **AC-1**: Budget preview
  - Given: grid cell clicked, funds=500, build_cost=200
  - When: panel opens
  - Then: "当前经费: 500 → 确认后: 300"

- **AC-2**: Accredited economy path
  - Given: confirm clicked
  - When: EconomyManager.accredit_facility_cost() called
  - Then: funds NOT directly deducted by UI

- **AC-3**: Insufficient funds
  - Given: funds=100, build_cost=200
  - When: cell clicked
  - Then: confirm button disabled, "经费不足：还差 100"

- **AC-4**: Cancel
  - Given: panel open
  - When: cancel clicked
  - Then: panel closed, no funds deducted, grid visible

- **AC-5**: Facility status
  - Given: facility under construction (3 days remaining)
  - When: grid renders
  - Then: cell shows "建设中 - 剩余3天"

## Test Evidence

**Story Type**: UI + Integration
**Required evidence**: `tests/integration/ui/town_build_confirm_test.gd`

## Dependencies

- Depends on: Story 001 (grid stub — TownOverview screen exists)
- Unlocks: Story 003 (建设队列 + 并行项目)

## Completion Notes
**Completed**: 2026-07-10
**Criteria**: 5/5 passing (all auto-verified)
**Deviations**: None
**Test Evidence**: UI + Integration — `tests/integration/ui/town_build_confirm_test.gd` (PASS)
**Code Review**: Complete
**Implementation**: `src/ui/town/town_overview_screen.gd` (budget preview + confirm flow + facility status labels)
