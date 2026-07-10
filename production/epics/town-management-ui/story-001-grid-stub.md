# Story 001: 设施网格最小容器

> **Epic**: 建设与经营 UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S (2-3 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/town-management-ui.md`
**Requirement**: `TR-town-management-ui-001`, `TR-town-management-ui-002`
**ADR Referenced**: ADR-0008 (TownBuilding authority), ADR-0001 (ScreenManager)

**Engine**: Godot 4.6 + GDScript | **Risk**: LOW

## Acceptance Criteria

- [ ] **AC-1**: 从 Home 可访问的 Town Overview 容器，通过 ScreenManager.push_screen("town_overview") 进入
- [ ] **AC-2**: 容器内展示 5×5 facility grid（使用占位图标/色块），grid cell 可被点击（不触发实际建造）
- [ ] **AC-3**: 消费 `TownBuilding` read model（只读，不写入），展示设施名称/等级/状态
- [ ] **AC-4**: 展示只读经济摘要：当前经费、每日维护费总额
- [ ] **AC-5**: 返回按钮通过 ScreenManager.pop_screen() 回到 Home

## Implementation Notes

- 通过 ADR-0001 Screen Stack: push_screen("town_overview"), pop_screen()
- Grid 数据源: TownBuilding.get_facility_grid() read model (只读)
- 占位图标使用 WarmPalette 7色闭环色块
- 不实现建造/升级确认流 (后续 story)

## Out of Scope

- 建造/升级确认流程
- 预算预览
- 设施详情面板
- 建设队列/进行中项目摘要

## QA Test Cases

- **AC-1**: Town Overview 导航
  - Setup: 运行游戏，Home 界面点击小镇入口
  - Verify: push_screen("town_overview") 被调用，town overview 容器可见
  - Pass condition: ScreenManager.get_active_screen_id() == "town_overview"

- **AC-2**: 5×5 grid 渲染
  - Setup: town_overview screen 已打开
  - Verify: 25 个 grid cell 可见，每个 cell 可被点击（至少触发 debug 输出）
  - Pass condition: 所有 25 cell 存在且可交互

- **AC-3**: TownBuilding read model
  - Setup: mock TownBuilding 提供测试数据
  - Verify: grid 展示 mock 数据中的设施名称/等级
  - Pass condition: 渲染的数据与 mock TownBuilding 一致

- **AC-4**: 经济摘要
  - Setup: town_overview screen 已打开
  - Verify: 经费和每日维护费数值可见
  - Pass condition: 显示值与 EconomyManager 数据一致

- **AC-5**: 返回导航
  - Setup: town_overview screen 已打开
  - When: 点击返回按钮
  - Then: get_active_screen_id() == "home"

## Test Evidence

**Story Type**: UI
**Required evidence**: `tests/integration/ui/town_mgmt_grid_stub_test.gd`

## Dependencies

- Depends on: None（可独立创建容器；grid 数据从 mock TownBuilding 获取）
- Unlocks: Story 002 (建造/升级确认流)
