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

## 结论

_运行验证后填写。若全部 PASS，则进入 P2: 资产清单与获取策略。_
