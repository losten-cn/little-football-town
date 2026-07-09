# Story 001: 世界渲染层

> **Epic**: 视觉方向对齐 (visual-direction-alignment)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic + Visual/Feel
> **Estimate**: M (4-6 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**Authority**: `STYLE_GUIDE.md` §1 (核心基石), §2 (世界架构), §3 (色彩与光)
**ADR Governing Implementation**: N/A — STYLE_GUIDE.md 为权威技术规范；P1 原型 (`prototypes/town-visual-prototype/`) 已验证核心管线 19/19 PASS
**ADR Referenced**: ADR-0001 (ScreenManager — 世界场景须通过 ScreenManager 管理，不可绕过)

**Engine**: Godot 4.6 + GDScript | **Risk**: MEDIUM
**Engine Notes**:
- 使用 `TileMapLayer` (4.3+)，严禁使用已废弃的 `TileMap`
- 使用 `Node2D.y_sort_enabled`，严禁使用已废弃的 `YSort` 节点
- Compatibility renderer 必须显式设置（像素艺术 2D，避免 D3D12 默认值）
- `snap_2d_transforms_to_pixel = true` / `snap_2d_vertices_to_pixel = true`

**Control Manifest Rules (Presentation Layer)**:
- Required: 若渲染 town grid，渲染节点仅作 presentation；gameplay authority 保持在 `TownBuilding` (ADR-0008)
- Required: Windows 构建必须显式使用 2D Compatibility renderer
- Forbidden: 不得将 `TileMapLayer` 作为权威 town/facility gameplay state 的来源
- Guardrail: 60fps / 16ms 帧预算 / 500 draw calls

## Acceptance Criteria

*From STYLE_GUIDE.md §1-§3:*

- [ ] **AC-1**: TileMapLayer 使用 32×32px cell_size，Camera2D zoom = 0.5 实现 2x 整数缩放（32px→64px 屏幕像素），禁止非整数缩放值
- [ ] **AC-2**: Viewport 覆盖 30列×17行（960×544 原始像素），窗口 1920×1080 下可见约 30×16.9 tiles（纵向 8px 差异由 HUD 裁切处理）
- [ ] **AC-3**: 根节点 `y_sort_enabled = true`，所有 TileMapLayer 和 Sprite2D 节点 `y_sort_enabled = true`。Y 值越大（越靠近屏幕底部）的节点绘制在越前面
- [ ] **AC-4**: 地图总尺寸 60列×34行（视角窗口滚动面积 2 倍），俱乐部会所、训练场、医疗室、青训营、球场入口永不超出边界
- [ ] **AC-5**: 所有场景元素颜色必须出自 7 色绝对闭环（#F2E8D5 / #D6B35A / #B84A4A / #5E7FA3 / #6F8F5B / #8A6B4F / #4C4A4A），无任何例外。季节变体颜色需在对应季节调色规则内
- [ ] **AC-6**: 季节调色偏移功能可用——通过参数切换春（地面提亮+10%黄，#8FBC6A 点缀）、夏（饱和度+5%，#5A7A4A 草皮）、秋（#C58A3A 草地混入 + #BFA26A 枯黄）、冬（30% 透明白雪层 + 建筑窗户暖黄 #F2E8D5）
- [ ] **AC-7**: 时间冷暖视觉提示可用——日常经营暖白光照 + 极小 2px 投影；比赛黄昏橙色高光层 + 4px 泛光灯投影；夺冠夜晚星空粒子 + 冷蓝背光 + 烟花红金炸点
- [ ] **AC-8**: P1 原型 (`prototypes/town-visual-prototype/`) 的 19 项自动化自测保持全部 PASS

## Implementation Notes

*Derived from STYLE_GUIDE.md and control manifest:*

1. **TileMapLayer 架构**: 使用单个 TileMapLayer 节点承载地面层。如需多层（地面/建筑/装饰），使用多个 TileMapLayer 节点，每个节点为一个独立渲染层。每层 `y_sort_enabled = true`。
2. **Camera2D 设置**: `anchor_mode = ANCHOR_MODE_FIXED_TOP_LEFT`，`zoom = Vector2(0.5, 0.5)`。地图中心对齐：`position = Vector2(MAP_COLS * TILE_SIZE / 2.0, MAP_ROWS * TILE_SIZE / 2.0)`。
3. **Y-sort 验证**: 在测试场景中放置 3 个不同 Y 值的 sprite（玩家在墙后 / 墙 / 玩家在墙前），程序化断言 Y 关系，并确认 Godot 引擎的 Y-sort 正确渲染遮挡。
4. **季节系统**: 使用 `season` 枚举参数驱动全局 shader 参数或 TileSet 替换。MVP 阶段可用纯色 TileSet 切换验证逻辑，Alpha 阶段接入真实季节资产。季节变化必须通过时间系统事件触发，不得自行推进。
5. **渲染器锁定**: 在 `project.godot` 中确认 `rendering/renderer/rendering_method = "gl_compatibility"`，禁止 D3D12 默认值。
6. **TileMap 使用 `TileMapLayer`**，不使用已废弃的 `TileMap` 节点。
7. **Y-sort 使用 `Node2D.y_sort_enabled`**，不使用已废弃的 `YSort` 节点。

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **Story 002**: HUD 暖亮化迁移 — 顶部栏/底部导航的颜色、高度、字体变化
- **Story 003**: 资产管线 — 实际像素 TileSet 资产、建筑/角色精灵的生产

## QA Test Cases

*For Logic criteria — automated test specs:*

- **AC-1**: TileMapLayer 32×32 + Camera2D 2x 整数缩放
  - Given: 场景启动，TileMapLayer 已创建，Camera2D 已配置
  - When: 读取 `tile_set.tile_size` 和 `camera.zoom`
  - Then: `tile_size == Vector2i(32, 32)` AND `camera.zoom == Vector2(0.5, 0.5)`
  - Edge cases: 验证 camera.zoom 不为 0.75、1.33 等非整数缩放值

- **AC-2**: Viewport 30×17 可见范围
  - Given: 窗口 1920×1080, camera zoom = 0.5
  - When: 计算 `visible_cols = viewport_width * zoom / TILE_SIZE`
  - Then: `visible_cols >= 30.0` AND `visible_rows >= 16.8`（允许纵向 8px HUD 差异）
  - Edge cases: 1280×720 窗口下缩小适配，UI 锚点保持整数

- **AC-3**: Y-sort 前提条件
  - Given: 3 个 Sprite2D 节点 (behind/Wall/front) 已创建，父节点 y_sort_enabled=true
  - When: 检查各节点 Y 坐标和 y_sort_enabled 标志
  - Then: `behind.position.y < wall.position.y < front.position.y` AND 所有节点 `y_sort_enabled == true`
  - Edge cases: 等 Y 值情况按节点创建顺序渲染

- **AC-5**: 7色板合规
  - Given: 所有 tile 和 sprite 已创建
  - When: 抽样检查各节点中心像素颜色
  - Then: 所有颜色均出自 7 色闭环或允许的季节变体
  - Edge cases: 边界像素可能有 1px 深色边线（darkened 0.15 以内）

*For Visual/Feel criteria — manual verification steps:*

- **AC-4**: 地图边界
  - Setup: 运行场景，拖动摄像机到地图四角边缘
  - Verify: 所有建筑（会所/训练场/医疗室/青训营/球场）完整可见，不被地图边界裁切
  - Pass condition: 地图四个角落可到达，无建筑被边界截断

- **AC-6**: 季节调色
  - Setup: 运行场景，通过调试参数切换 season = SPRING / SUMMER / AUTUMN / WINTER
  - Verify: 草地色温按季节规则变化，冬季有透明雪层，建筑窗户保持暖黄
  - Pass condition: 四个季节各显示明显差异，且不越出 7 色板允许的变体范围

- **AC-7**: 时间冷暖
  - Setup: 通过调试参数切换 day_mode = DAILY / MATCH_DUSK / CHAMPIONSHIP_NIGHT
  - Verify: 黄昏有橙色高光层，夜晚有星空粒子+冷蓝背光
  - Pass condition: 三种模式有明显视觉差异，日常模式保持暖白基调

- **AC-8**: P1 原型回归
  - Setup: 跑 `godot --headless --path ... res://prototypes/town-visual-prototype/town_visual_prototype.tscn`
  - Verify: 输出中 `总计: N PASS / 0 FAIL → ALL PASS ✅`
  - Pass condition: 零失败，零错误

## Test Evidence

**Story Type**: Logic + Visual/Feel
**Required evidence**:
- Logic: `tests/unit/visual/world_rendering_layer_test.gd` — TileMapLayer 参数、Camera2D 参数、Y-sort 前提条件、色板合规
- Visual/Feel: `production/qa/evidence/world-rendering-layer-evidence.md` + 季节切换截图 + 时间冷暖截图

**Status**: [ ] Not yet created

## Dependencies

- Depends on: None（P1 原型已验证核心管线，此 story 直接基于已验证参数实现）
- Unlocks: Story 002 (HUD 暖亮化迁移 — 需要确认 viewport 参数后调整 HUD 坐标)
