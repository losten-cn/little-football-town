# Asset Acquisition Strategy

> **Status**: Decision
> **Date**: 2026-07-10
> **Authority**: STYLE_GUIDE.md V1.0 §7
> **Story**: `production/epics/visual-direction-alignment/story-003-asset-pipeline.md`

## Decision

采用**分阶段混合策略**：MVP 阶段全部使用程序化纯色 placeholder；Alpha 阶段按优先级逐步替换为实际像素资产。

## 资产分类决策

| 资产类别 | 决策 | 理由 |
|---------|------|------|
| **TileSet** (草地/道路/围栏) | MVP: 程序化纯色 → Alpha: 购买或自制 | 32×32 tile 市场供应充足，购买可大幅加速；7色色板可作为筛选条件 |
| **建筑精灵** (会所/训练场/医疗室/青训营) | MVP: 程序化纯色色块 → Alpha: 定制自制 | 建筑风格与 STYLE_GUIDE 紧密绑定，购买难以精确匹配斜屋顶/门廊/升级系统 |
| **角色精灵** (球员/教练/NPC) | MVP: 程序化矩形色块 → Alpha: 购买基础包 + 调色板调整 | 32×48px 运动比例角色在生产市场上找到精确匹配难度高，但可购买基础 sprite 后调整色板 |
| **球场** (14×20 tile) | MVP: 程序化纯色 + 白线 → Alpha: 自制 | 社区球场风格特定，白线/磨损纹理需要精确控制 |
| **音频** (BGM/SFX) | Beta: 购买 royalty-free 包 | 音频不属于 MVP 核心闭环 (ADR-0013)，延至 Beta；温暖/低压力方向为筛选条件 |

## 被拒绝的替代方案

- **全部自制**: 人力成本过高，MVP 进度不可接受
- **全部购买**: STYLE_GUIDE 的精确色板/比例/建筑规范难以通过现成 asset pack 完全满足
- **AI 生成**: 像素艺术的一致性（32×32 tile + 色板闭环 + 升级视觉差异）超出当前 AI 工具的可靠输出范围

## 下一步

- P2 阶段启动时，按优先级逐类执行：TileSet 购买调研 → 建筑定制 → 角色购买+调色 → 球场自制 → 音频采购
- 每类资产采购前，确认与 STYLE_GUIDE 色板/尺寸/比例的兼容性
- 采购决策记录在 `design/art/acquisition-log.md`
