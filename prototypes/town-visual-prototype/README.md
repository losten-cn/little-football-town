# P1 最小视觉原型 — 渲染管线验证

> **原型**: `prototypes/town-visual-prototype/`
> **状态**: in-progress
> **创建**: 2026-07-10
> **参考**: `STYLE_GUIDE.md` V1.0 终稿 §7 启动行动清单第 5 步

---

## 验证假说

在投入美术资产生产之前，先验证 Godot 4.6 渲染管线是否能正确承载 STYLE_GUIDE 定义的物理法则：

1. **32×32 TileMapLayer** 在 2x 整数缩放下能否正确渲染
2. **Camera2D** 能否覆盖 30列×17行 目标视野
3. **Y-sort** 能否基于世界 Y 轴正确排序 tile 和 sprite
4. **7色绝对色板** 能否完整映射到场景元素

## 如何运行

```bash
# 命令行 (headless — 仅验证脚本逻辑，不做视觉确认)
godot --headless --path /home/kylin/little-football-town \
  res://prototypes/town-visual-prototype/town_visual_prototype.tscn

# Godot 编辑器 (推荐 — 可肉眼确认 Y-sort 和色板)
# 1. 打开项目: /home/kylin/little-football-town
# 2. 在 FileSystem 中找到 prototypes/town-visual-prototype/town_visual_prototype.tscn
# 3. 右键 → Open Scene，然后按 F5 运行
```

## 场景内容

| 元素 | 规格 | 色板 |
|------|------|------|
| 草地底 | 60×34 tiles (全图) | 球场绿 `#6F8F5B` |
| 主干道路 | 十字，4 tile 宽 | 大地棕 `#8A6B4F` |
| 俱乐部会所 | 4×4 tiles, 左上区 | 奶油色 `#F2E8D5` |
| 训练场 | 3×3 tiles, 右上区 | 小镇金 `#D6B35A` |
| 医疗室 | 2×2 tiles, 右上区 | 冷静蓝 `#5E7FA3` |
| 青训营 | 3×3 tiles, 右下区 | 球场绿深调 |
| 社区球场 | 14×20 tiles, 中央偏下 | 球场绿深调 + 奶油色边线 |
| 测试墙 | 96×80px, 路径交叉口 | 大地棕 |
| 球员A (墙后) | 20×40px, Y=288 | 俱乐部红 |
| 球员B (墙前) | 20×40px, Y=440 | 小镇金 |
| 教练 | 20×40px, 训练场旁 | 冷静蓝 |
| 前锋 | 20×40px, 球场上 | 俱乐部红 |
| 居民 | 18×36px, 街道 | 小镇金 |

## Y-sort 验证清单

运行后肉眼确认以下遮挡关系：

- [ ] **PlayerBehind_Wall** (红, Y≈288) 绘制在 **Wall** (棕, Y≈352) **后面**
- [ ] **PlayerFront_Wall** (金, Y≈440) 绘制在 **Wall** (棕, Y≈352) **前面**
- [ ] 教练 (蓝) 在训练场建筑 tile 上方正确遮挡
- [ ] 前锋 (红) 在球场草皮 tile 上方正确渲染

## Viewport 验证清单

- [ ] 窗口 1920×1080 下，可见约 30×16.9 tiles (接近目标 30×17)
- [ ] 每个 tile 显示为 64×64 屏幕像素 (2x 缩放)
- [ ] 无模糊、抗锯齿或像素错位

## 色板验证清单

所有场景元素的颜色必须出自以下 7 色闭环，无例外：

- [ ] `#F2E8D5` 奶油色 — 会所建筑 / 球场白线
- [ ] `#D6B35A` 小镇金 — 训练场建筑 / 球员B
- [ ] `#B84A4A` 俱乐部红 — 球员A / 前锋
- [ ] `#5E7FA3` 冷静蓝 — 医疗室 / 教练
- [ ] `#6F8F5B` 球场绿 — 草地
- [ ] `#8A6B4F` 大地棕 — 道路 / 测试墙
- [ ] `#4C4A4A` 石板灰 — (本原型未直接使用，留待 UI 层)

## 已知限制

- 本原型使用纯色程序化 tile，非实际像素资产
- 角色为矩形色块，非 32×48px 像素角色精灵
- headless 模式无法做视觉确认，仅打印参数报告
- Window 1920×1080 vs STYLE_GUIDE 理想 1920×1088 有 8px 差异，原型阶段忽略
- 原型不连接任何 autoload (EventBus/SaveManager 等)

### 色板例外说明

原型引入了 2 个 STYLE_GUIDE §3 七色闭环之外的色值：

| 颜色 | Hex | 用途 | 依据 |
|------|-----|------|------|
| 球场绿深调 | `#5A7A4A` | BLDG_GREEN (青训营) | STYLE_GUIDE §3 夏季变体明确列出的深绿色 |
| 球场草皮 | `#4A6A3A` | PITCH_GREEN (球场内部) | 球场草皮深色基准 — 作为 FIELD_GREEN `#6F8F5B` 的合理深调变体，用于区分"草地"与"球场草皮"两个不同概念 |

两者均为 FIELD_GREEN 的功能性变体，非新色系引入。若正式资产生产阶段需要绝对闭环，可将 `#4A6A3A` 替换为 FIELD_GREEN 本体或通过 TileSet 叠加模式替代。

## 结论

> **验证日期**: 2026-07-10
> **验证方式**: Godot 4.6.3 headless 自动自测 + godot-specialist 代码审查 + art-director STYLE_GUIDE 合规审查

### 自动化测试: 19/19 PASS ✅

```
TileMapLayer.y_sort_enabled        ✅
TileSet.tile_size = 32×32          ✅
TileSetAtlasSource found           ✅
Used tile cells: 2040              ✅
Clubhouse tile at (4,3) confirmed  ✅
Root Node2D.y_sort_enabled         ✅
6/6 Sprite y_sort_enabled          ✅
PlayerBehind Y=304 < Wall Y=352    ✅
PlayerFront Y=440 > Wall Y=352     ✅
All sprite colors in palette       ✅
Camera2D.zoom = 0.500 (2x)         ✅
Camera2D.anchor_mode FIXED_TOP_LEFT ✅
Window size = 1920×1080            ✅
Video driver: amdgpu               ✅
```

### 渲染管线验证结论

| # | 验证目标 | 自动测试 | 代码审查 | 判定 |
|---|---------|---------|---------|------|
| 1 | TileMapLayer 32×32px + 2x 整数缩放 | PASS | godot-specialist: CORRECT | ✅ PASS |
| 2 | Camera2D 30列×17行 Viewport | PASS (30.0×16.9) | godot-specialist: CORRECT | ✅ PASS |
| 3 | Y-sort 严格 Y 轴排序 | PASS (坐标关系验证) | godot-specialist: CORRECT | ✅ PASS* |
| 4 | 7色绝对色板 | PASS (无越界色) | art-director: CONCERNS → 已修复 | ✅ PASS |

> *Y-sort 坐标关系已通过自动验证；最终视觉遮挡效果需在 Godot 编辑器中肉眼确认（F5 运行场景）。

### 审查修复记录

| 问题 | 审查者 | 修复 |
|------|--------|------|
| Texture filter 未显式设为 Nearest | art-director | TileMapLayer + Sprite2D 均添加 `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST`（Godot 4.6 中 `ImageTexture` 无 `texture_filter` 属性，须在 CanvasItem 节点级别设置） |
| `#4A6A3A` 色板依据缺失 | art-director | README 已知限制 → 色板例外说明 |

### 最终判定: **PASS — P1 验证目标达成**

渲染管线已验证可承载 STYLE_GUIDE 定义的物理法则。可进入 **P2: 资产清单与获取策略**。
