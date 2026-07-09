# Asset Spec: TileSet 规格

> **Authority**: `STYLE_GUIDE.md` V1.0 §5, §7
> **Status**: Draft — placeholder specs for MVP; final pixel assets TBD by acquisition strategy
> **Created**: 2026-07-10
> **Story**: `production/epics/visual-direction-alignment/story-003-asset-pipeline.md`

## Tile 尺寸

| 参数 | 值 |
|------|-----|
| 原始像素 | 32×32 px |
| 显示缩放 | 2x 整数 → 64×64 px |
| 格式 | PNG, nearest-neighbor 导入 |
| 色板 | 7色绝对闭环 + 季节变体 |

## Tile 类型清单

### 1. 草地 (Grass) — 4 季版本

| 季节 | 色值 | 说明 |
|------|------|------|
| 春 | `#6F8F5B` lightened 0.10 | 提亮 +10% 黄，浅绿点缀 `#8FBC6A` |
| 夏 | `#5A7A4A` | 饱和度 +5%，饱满深绿 |
| 秋 | `#C58A3A` / `#BFA26A` mix | 暖调枯黄混入 |
| 冬 | `#6F8F5B` + 30% white overlay | 明度拉高，透明白雪层 |

Godot 导入: `TileSetAtlasSource`, `texture_region_size = Vector2i(32, 32)`, `filter = false`

### 2. 泥土路 (Dirt Path)

- 色值: `#8A6B4F` (大地棕)
- 可选变体: 边缘轻微暗化，模拟踩踏痕迹
- 季节变体: 春秋基本不变，夏稍干（lightened 0.05），冬覆盖薄雪

### 3. 木板路 (Wood Path)

- 色值: `#8A6B4F` 基调 + `#C58A3A` 条纹
- 用途: 训练场周边、球场入口

### 4. 白色围栏 (White Fence)

- 色值: `#F2E8D5` (奶油色) 基调 + `#4C4A4A` (石板灰) 阴影线
- 用途: 球场边界、训练场边界
- 注意: 围栏为 1-tile 宽的装饰 tile，不是物理碰撞体

## Placeholder 验证

P1 原型 (`prototypes/town-visual-prototype/`) 已验证程序化 32×32 纯色 tile 渲染正确。MVP 阶段可用纯色 placeholder；正式资产生产后替换为像素 tile。

## 检查清单

- [x] 所有色值出自 7 色闭环或批准的季节变体
- [x] 32×32px 尺寸一致，无混入其他 tile 尺寸
- [x] Godot TileSetAtlasSource 导入参数已定义
- [ ] 实际 PNG 资产生产 (P2 — 取决于获取策略)
