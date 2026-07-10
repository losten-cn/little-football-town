# Epic: 建设与经营 UI

> **Layer**: Presentation (Alpha)
> **GDD**: `design/gdd/town-management-ui.md`
> **Architecture Module**: `TownManagementUI` (Presentation [Alpha])
> **Status**: Ready
> **Stories**: 1 story

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Grid Stub](story-001-grid-stub.md) | UI | Ready | ADR-0008 |

## Overview

建设与经营 UI 是把 TownBuilding 数据转化为玩家可浏览、可规划、可确认的完整建设界面的 Presentation 层系统。它不定义设施规则/成本/效果——这些分别由 TownBuilding、EconomyManager 和 TimeManager 拥有。Alpha 阶段将 MVP 的主界面小镇摘要扩展为完整的建设与经营界面：5×5 设施网格、建造/升级确认流、预算预览和维护费摘要。界面必须嵌入主循环 UI 框架导航体系，保持低压力、低财务焦虑。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: Town Grid & Facility System | TileMapLayer 仅 presentation；TownBuilding 为权威 gameplay state owner；渲染节点不得作为权威数据源 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-town-management-ui-001 | 必须运行在 Main Loop UI 容器内，不创建独立导航栈 | ADR-0001 ✅ |
| TR-town-management-ui-002 | Town Overview 必须展示 grid/funds/AP/维护费/建设中项目/建造入口/加成摘要 | ADR-0008 ✅ |
| TR-town-management-ui-003 | 建造/升级按钮可用性由 TownBuilding + EconomyManager + TimeManager 共同决定 | ADR-0008 ✅ |
| TR-town-management-ui-004 | 预算预览展示"当前→确认后"经费和维护费变化 | ADR-0007 ✅ |
| TR-town-management-ui-005 | 设施状态展示：未建造/建设中/运作中/升级中 | ADR-0008 ✅ |
| TR-town-management-ui-006 | 不得把小镇建设包装为核心胜负条件 | ADR-0008 ✅ |
| TR-town-management-ui-007 | 返回路径遵循主循环 UI 框架 | ADR-0001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/town-management-ui.md` are verified
- Facility grid 正确消费 TownBuilding read model
- 建造/升级确认流通过 ScreenManager 导航

## Next Step

Run `/create-stories town-management-ui` to break this epic into implementable stories.
