# Story 003: 资产管线

> **Epic**: 视觉方向对齐 (visual-direction-alignment)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Config/Data + Visual/Feel
> **Estimate**: S (2-4 hours for spec doc; asset production timeline TBD by strategy)
> **Manifest Version**: 2026-07-05
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**Authority**: `STYLE_GUIDE.md` §5 (实体与空间), §7 (启动行动清单)
**ADR Governing Implementation**: N/A — 资产管线属于生产决策层，不直接涉及代码架构 ADR。获取策略决策应通过 `/architecture-decision` 记录

**Current State**: 项目美术资产几乎为零 — 仅 14 个 20px HUD 功能图标 + 1 个 Zpix 像素字体。P1 原型使用程序化纯色 tile 验证了渲染管线。本 story 产出的是规格文档和策略决策，不包含实际像素资产的绘制。

**Engine**: Godot 4.6 + GDScript | **Risk**: LOW
**Engine Notes**:
- PNG 导入使用 nearest-neighbor 采样，禁止过滤/模糊缩放
- `snap_2d_transforms_to_pixel = true` 确保像素资产不产生亚像素偏移
- TileSet 通过 `TileSetAtlasSource` 管理，支持 `texture_region_size = Vector2i(32, 32)`

**Control Manifest Rules (Presentation Layer)**:
- Forbidden: 不得将 `TileMapLayer` 作为权威 gameplay state 的来源 — 渲染和游戏逻辑分离 (ADR-0008)
- Guardrail: 512 MB 总内存上限 — 像素艺术资产内存占用极低，但需关注 atlas 和 sprite sheet 总量

## Acceptance Criteria

*From STYLE_GUIDE.md §5 + §7:*

- [ ] **AC-1**: TileSet 规格文档落地 — 定义以下 tile 类型的精确像素规格（32×32px 原始尺寸）：草地 4 季版本（春/夏/秋/冬色板）、泥土路、木板路、白色围栏。每个类型包含色板值、视觉描述、Godot TileSetAtlasSource 导入参数
- [ ] **AC-2**: 建筑精灵规格文档落地 — 俱乐部会所 (4×4 Tile, 128×128px 原始)、训练场 (3×3 Tile)、医疗室 (2×2 Tile)、青训营 (3×3 Tile)、社区球场 (14×20 Tile 白线底纹)。规格包含：斜屋顶占比、正面门廊、升级表现差异、周围道具密度指南
- [ ] **AC-3**: 角色精灵规格文档落地 — 1 名前锋球员 32×48px（头 12/身体 24/腿 12）+ 1 名 NPC 教练 + 三要素规则（1 剪影特征 + 1 颜色强调 + 1 个人配件）。动画规格：待机 2 帧 / 走路 4 帧 / 跑动 6 帧。比赛跑动 8 方向（上下左右+斜向）
- [ ] **AC-4**: 资产获取策略决策完成 — 对每类资产（TileSet / 建筑 / 角色 / 比赛画面 / 音频）明确决定：自制 / 购买 asset pack / 先用纯色 placeholder，并记录决策理由
- [ ] **AC-5**: 至少 1 个 placeholder TileSet 可在 Godot 中导入验证 — 使用纯色块（7 色闭环）创建最小 TileSet（草地 + 泥土路 + 木板路 + 围栏），导入 Godot 并通过 TileMapLayer 渲染验证
- [ ] **AC-6**: 所有规格文档引用 STYLE_GUIDE.md 为唯一权威来源，不得出现与 STYLE_GUIDE 冲突的尺寸、色板或比例值

## Implementation Notes

*Derived from STYLE_GUIDE.md and project standards:*

1. **规格文档位置**: `design/art/asset-spec-tileset.md`, `design/art/asset-spec-buildings.md`, `design/art/asset-spec-characters.md`。每个文档必须标注 "Authority: STYLE_GUIDE.md V1.0"。
2. **获取策略决策**: 通过 `/architecture-decision asset-acquisition-strategy` 创建 ADR，记录每类资产的选择和理由。选项：(a) 自制像素图 — 成本最高但完全自控；(b) 购买 asset pack — 需验证与 STYLE_GUIDE 色板/尺寸兼容性；(c) 先用纯色 placeholder — 零成本，功能先行。
3. **Placeholder TileSet**: 参考 P1 原型的程序化纹理生成方法（`_make_tile_image()`），生成符合 7 色闭环的纯色 tile。导出为 PNG 以便 Godot TileSet 编辑器导入。
4. **8 方向跑动**: 角色动画使用 sprite sheet 组织。每行一个方向（8 行），每列一帧（6 列）。帧尺寸保持 32×48px 一致。
5. **球场规格**: 14×20 tiles 白线底纹，草皮纹理包含磨损斑秃（深绿/浅绿交替），白线 2px 粗。一侧木质小看台 100×64px。

## Out of Scope

*Handled by neighbouring stories or future work — do not implement here:*

- **Story 001**: 实际 TileMapLayer 实现 — 本 story 仅产出规格和 placeholder 验证
- **Story 002**: HUD 图标 (ico_calendar, ico_funds 等) — 属于 HUD 迁移的一部分
- 未来 story: 实际像素资产的绘制/购买/导入（P2 生产阶段）
- 未来 story: 音频资产 (BGM/SFX) — 属于 audio-system epic

## QA Test Cases

*For Config/Data criteria — manual verification:*

- **AC-1**: TileSet 规格文档
  - Setup: 阅读 `design/art/asset-spec-tileset.md`
  - Verify: 包含草地四季/泥土路/木板路/围栏的 32×32px 规格、色板值、Godot 导入参数
  - Pass condition: 所有 tile 类型有完整规格，色板值出自 7 色闭环或批准的季节变体

- **AC-2**: 建筑精灵规格文档
  - Setup: 阅读 `design/art/asset-spec-buildings.md`
  - Verify: 包含会所/训练场/医疗室/青训营/球场的 tile 尺寸、视觉描述、升级差异、道具密度指南
  - Pass condition: 所有建筑类型有完整规格，无与 STYLE_GUIDE 冲突的尺寸

- **AC-3**: 角色精灵规格文档
  - Setup: 阅读 `design/art/asset-spec-characters.md`
  - Verify: 包含球员 32×48px 头身比、三要素、动画帧数、8 方向说明
  - Pass condition: 角色规格明确到可直接交付美术生产

- **AC-4**: 获取策略决策
  - Setup: 检查 `docs/architecture/adr-XXXX-asset-acquisition-strategy.md`
  - Verify: 对每类资产有明确决策（自制/购买/占位）+ 理由
  - Pass condition: ADR 状态为 Accepted，策略覆盖全部 5 类资产

- **AC-5**: Placeholder TileSet 导入验证
  - Setup: 在 Godot 编辑器中导入 placeholder TileSet PNG
  - Verify: TileMapLayer 使用该 TileSet 渲染，32×32 tile 以 2x 整数缩放显示，无模糊
  - Pass condition: Placeholder TileSet 在 Godot 中正常工作

- **AC-6**: STYLE_GUIDE 一致性
  - Setup: 逐条比对规格文档中的尺寸/色板/比例值与 STYLE_GUIDE.md
  - Verify: 无冲突项
  - Pass condition: 零冲突

## Test Evidence

**Story Type**: Config/Data + Visual/Feel
**Required evidence**:
- Config/Data: smoke check pass (`production/qa/smoke-*.md` — 规格文档完整性检查)
- Visual/Feel: `production/qa/evidence/asset-pipeline-evidence.md` — Placeholder TileSet 截图 + 获取策略 ADR 引用

**Status**: [ ] Not yet created

## Dependencies

- Depends on: None — 可与 Story 001 并行进行（Story 001 实现渲染管线，Story 003 定义资产规格）
- Unlocks: 后续 P2 资产生产阶段（实际像素资产绘制/购买/导入）
