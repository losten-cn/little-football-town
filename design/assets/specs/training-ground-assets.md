# Asset Specs — entity: Training Ground

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/town-building-system.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 6 assets specced / 6 approved / 0 in production / 0 done

## ASSET-045 — Training Ground Core Structure Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 基础网格 `16×16`；逻辑占地 `64×64`（4×4 tile）；渲染盒 `96×96`；`Lv1–Lv5` 共 5 帧（建议 `480×96 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_training_ground_core_sheet.png` |
| Polycount | N/A |
| Texture Res | World facility small tier；nearest / filter off / mipmap off / repeat off |

**Visual Description:**  
训练场主结构应读成“社区俱乐部认真维护的日常训练空间”，而非豪门高科技基地。以稳定轮廓与温暖材质为主，允许轻微使用痕迹，保证小尺寸下一眼可读。  

**Art Bible Anchors:**
- §3.2  
- §4  
- §6  
- §8

**Generation Prompt:**  
`pixel art cozy small-town football training ground core structure, silhouette-first readability, warm cream and field-green base, restrained town-gold and slate shadows, community-maintained facility, clear 2D modular footprint, low-noise texture, production-friendly`  
`--no neon --no chrome --no luxury pro campus --no dense micro detail --no esports arena style`

**Status:** Needed

## ASSET-046 — Training Ground Upgrade Overlay Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 单帧 `96×96`；`Lv2–Lv5` 增量 overlay 共 4 帧（建议 `384×96 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_training_ground_upgrade_overlay_sheet.png` |
| Polycount | N/A |
| Texture Res | 与 ASSET-045 同级；同 pivot 对齐 |

**Visual Description:**  
该组只承载升级“增量件”，例如围栏强化、器材棚、照明与边线整理，不重画整场地。通过模块叠加表达成长，保持同一训练场视觉身份。  

**Art Bible Anchors:**
- §3.4  
- §4  
- §8

**Generation Prompt:**  
`pixel art modular upgrade overlays for football training ground, fence improvements, equipment shelter, tidy boundary accents, warm small-town club identity, broad calm shapes, low-noise readable layers`  
`--no full-scene repaint --no neon lighting --no chrome structural shine --no cluttered add-ons`

**Status:** Needed

## ASSET-047 — Training Pitch Tile Set

| Field | Value |
|-------|-------|
| Category | Environment / Terrain |
| Dimensions | `16×16` tile；建议 16 tile（`64×64 px` sheet） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `tile_training_pitch_16.png` |
| Polycount | N/A |
| Texture Res | Tile small tier；Godot TileSet 按 `16×16` 切片 |

**Visual Description:**  
训练草坪以低噪声草面与清晰边线为核心，区分可训练区域与边界。允许轻微磨损、泥边与线条补刷，体现长期使用但被照料。  

**Art Bible Anchors:**
- §3.5  
- §4  
- §8  
- §9

**Generation Prompt:**  
`pixel art training pitch tileset, low-noise grass values, soft chalk lines, subtle worn patches, warm community football town mood, readable 2D tile grammar`  
`--no photoreal turf --no harsh contrast striping --no neon green --no texture noise overload`

**Status:** Needed

## ASSET-048 — Training Fence / Gate & Prop Set

| Field | Value |
|-------|-------|
| Category | Sprite / Environment |
| Dimensions | 基础 cell `16×16`；围栏门片建议 `64×64 px`；器材合集建议 `128×64 px`（可同 atlas） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_training_ground_fence_gate_sheet.png`、`prop_training_ground_set_sheet.png` |
| Polycount | N/A |
| Texture Res | World props small tier；建议共用 world props atlas，减少切换 |

**Visual Description:**  
包含围栏、门、长椅、cone、ball rack、agility ladder、小告示牌等训练周边。目标是“有生活感的功能区”，强调秩序与可读，不走花哨陈列。  

**Art Bible Anchors:**
- §3.4  
- §4  
- §6  
- §8

**Generation Prompt:**  
`pixel art football training props and sideline set, cones ball rack bench ladder fence gate noticeboard, cozy community club practice zone, broad readable silhouettes, warm restrained palette`  
`--no sponsor wall clutter --no chrome metal glam --no neon accents --no dense accessory spam`

**Status:** Needed

## ASSET-049 — Training Construction State Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 单帧 `96×96`；4 状态（foundation / constructing_a / constructing_b / upgrading）建议 `384×96 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_training_ground_construction_sheet.png` |
| Polycount | N/A |
| Texture Res | 与 ASSET-045 同级；优先状态切换，不做长动画 |

**Visual Description:**  
用于建造与升级中的可视状态表达，重点是“正在被建设”而非施工秀。通过简化脚手、材料堆与半完成轮廓提示进度。  

**Art Bible Anchors:**
- §3.1  
- §4  
- §7  
- §8

**Generation Prompt:**  
`pixel art construction state sheet for small-town football training ground, foundation to upgrading stages, clear progression silhouettes, restrained warm palette, practical community build vibe`  
`--no heavy industrial machinery --no sparks explosion --no gritty realism --no neon warning style`

**Status:** Needed

## ASSET-050 — Training Efficiency & Session Icon Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 原生 `16×16` / `24×24` / `32×32` 三档 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_training_efficiency_16.png`、`ui_training_efficiency_24.png`、`ui_training_efficiency_32.png` |
| Polycount | N/A |
| Texture Res | UI icon tier；三档原生绘制，禁止单母版缩放 |

**Visual Description:**  
仅覆盖训练专属语义，例如 high / normal / low efficiency、focus、at cap，避免重复现有通用状态图标。图形差异依赖轮廓与结构，不依赖单纯颜色。  

**Art Bible Anchors:**
- §3.3  
- §4  
- §7  
- §8

**Generation Prompt:**  
`pixel art UI icon set for training efficiency states, silhouette-first small icons, calm readable forms, cream/slate base with restrained gold green blue accents, accessible non-color-dependent distinctions`  
`--no glossy bevel icons --no neon glow --no chrome badge style --no tiny clutter`

**Status:** Needed
