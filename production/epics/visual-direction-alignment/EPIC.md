# Epic: 视觉方向对齐 (Visual Direction Alignment)

> **Layer**: Presentation (跨系统视觉重构)
> **Authority**: `STYLE_GUIDE.md` V1.0 终稿 (2026-07-10)
> **Ref**: `production/session-state/visual-direction-recalibration-2026-07-09.md`
> **Status**: Ready
> **Stories**: 3 stories — work through in dependency order

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [世界渲染层](story-001-world-rendering-layer.md) | Logic + Visual/Feel | Complete | N/A (STYLE_GUIDE §1-§3) |
| 002 | [HUD 暖亮化迁移](story-002-hud-warm-migration.md) | UI + Integration | Complete | ADR-0001 |
| 003 | [资产管线](story-003-asset-pipeline.md) | Config/Data + Visual/Feel | Complete | N/A (STYLE_GUIDE §5, §7) |

## Overview

本 epic 将游戏视觉层从当前暗色管理仪表盘范式完整迁移到 STYLE_GUIDE.md 定义的暖亮 3/4 俯视 2D 像素足球小镇范式。它不是一个新系统的 GDD 实现，而是一次跨模块的视觉宪法执行——覆盖三个维度：(1) 世界渲染层 (TileMapLayer + Camera2D + Y-sort + 季节系统)，(2) HUD 暖亮化迁移 (Zone A/C 颜色/高度/字号对齐)，(3) 资产管线 (TileSet/精灵规格/获取策略)。P1 原型已通过 Godot 4.6 + Compatibility Renderer 的 19 项自动化验证 (19/19 PASS)，核心渲染管线成立。

## Governing Authority

| 文档 | 角色 | 版本 |
|------|------|------|
| `STYLE_GUIDE.md` | 像素宪法 — 所有视觉/渲染/HUD 参数的唯一权威来源 | V1.0 终稿 |
| `production/session-state/visual-direction-recalibration-2026-07-09.md` | 断层分析与 P0-P3 优先级路线图 | 2026-07-09 |
| `prototypes/town-visual-prototype/` | P1 渲染管线验证原型 (19/19 PASS) | 2026-07-10 |

### 相关 ADR

| ADR | 关联点 | 风险 |
|-----|--------|------|
| ADR-0001: ScreenManager | HUD 导航边界 — Story 002 从世界建筑点击入口不可绕过 ScreenManager | LOW |

## Story Dimensions

| # | Story | 覆盖 | 类型 | 依赖 |
|---|-------|------|------|------|
| 001 | **世界渲染层** | TileMapLayer 30×17 viewport + Camera2D 2x 整数缩放 + Y-sort + 季节调色偏移 (春夏秋冬) + 时间冷暖 (黄昏/夜晚) | Logic + Visual | P1 原型 |
| 002 | **HUD 暖亮化迁移** | Zone A (48→72px, #1A1A2E→#FFF2D2) + Zone C (56→64px, #1A1A2E→#8A6B4F) + 通用面板 (圆角→0) + Zpix 字号对齐 + 比赛直播暗色例外 | UI + Integration | Story 001 |
| 003 | **资产管线** | TileSet 规格 (草地四季/泥土路/木板路/围栏) + 建筑精灵规格 (会所 4×4/训练场 3×3/球场 14×20) + 角色精灵规格 (32×48px, 三要素) + 获取策略决策 | Config/Data + Visual | 可并行 001 |

## Key Technical Parameters (from STYLE_GUIDE.md)

| 参数 | 锁定值 |
|------|--------|
| Tile 尺寸 | 32×32px 原始, 2x 整数缩放 → 64×64px 显示 |
| Viewport | 30列×17行 (960×544 原始像素) |
| 绝对色板 | 7色闭环: #F2E8D5 / #D6B35A / #B84A4A / #5E7FA3 / #6F8F5B / #8A6B4F / #4C4A4A |
| Z-Order | 严格 Y 轴排序 |
| 字体 | Zpix 唯一, 关闭抗锯齿, 4px 网格对齐 |
| HUD 顶部 | 72px, #FFF2D2, 底部 2px #C58A3A |
| HUD 底部 | 64px, #8A6B4F, 顶部 2px #C58A3A |
| 面板圆角 | 0 (绝对直角) |
| 比赛暗色 | #2A1F1A (仅比赛直播 5 分钟) |

## Definition of Done

This epic is complete when:
- **Story 001**: TileMap 世界场景可运行，Y-sort 遮挡正确，季节参数可通过切换验证，P1 原型的 19 项自测保持 PASS
- **Story 002**: Zone A/C 颜色/高度/字号/边框全部对齐 STYLE_GUIDE §4，`hud-visual-design.md` 中已标记废弃的 8 处不再被引用；现有 UI 集成测试不回归
- **Story 003**: TileSet/建筑/角色精灵规格文档落地于 `design/art/`；资产获取方式有明确决策记录（自制/购买/占位）；至少 1 个 placeholder TileSet 可在 Godot 中导入验证
- P3 的重校准项 (从世界建筑点击进入功能 + 比赛画面替代文字结果) 由后续 story 承接

## P1 Prototype Verification (Completed)

```
prototypes/town-visual-prototype/
  19/19 automated tests PASS — Godot 4.6 + Compatibility Renderer + AMD GPU
  ✅ TileMapLayer 32×32 + 2x zoom + Y-sort + 7-color palette + 60×34 map
  Zero errors, zero warnings
```

## Next Step

Run `/create-stories visual-direction-alignment` to break this epic into 3 implementable stories.
