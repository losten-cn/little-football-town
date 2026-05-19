# Asset Specs — entity: Stadium

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/town-building-system.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 4 assets specced / 4 approved / 0 in production / 0 done

## ASSET-061 — Stadium Core Structure Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 基础网格 `16×16`；逻辑占地 `128×96`（8×6 tile）；渲染盒 `192×128`；`Lv1–Lv5` 共 5 帧（建议 `960×128 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_stadium_core_sheet.png` |
| Polycount | N/A |
| Texture Res | Landmark tier；独立 sheet；nearest / filter off / mipmap off / repeat off |

**Visual Description:**  
球场主结构应读成“小镇主场地标”，有清晰的看台、入口和记分牌轮廓，但仍然保持低层、亲切、有人情味的社区尺度。它要比其他建筑更有英雄形体和主场归属感，但绝不能走豪门职业球场或商业综合体路线。  

**Art Bible Anchors:**
- §3.2
- §3.4
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art hometown football stadium, small-town main ground, low-rise stand, ticket gate, simple scoreboard, warm cream and town-gold structure, club-red accents, heroic but human-scale, silhouette-first readability, community pride landmark`  
`--no mega arena --no neon flood spectacle --no corporate exterior --no luxury VIP architecture --no esports stadium`

**Status:** Needed

## ASSET-062 — Stadium Matchday / Upgrade Overlay Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 单帧 `192×128`；`Lv2–Lv5` 增量 overlay 共 4 帧（建议 `768×128 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_stadium_upgrade_overlay_sheet.png` |
| Polycount | N/A |
| Texture Res | 与 ASSET-061 同级；同 pivot 对齐；控制常驻叠层数 |

**Visual Description:**  
这组覆盖层应同时承担“设施升级”和“比赛日主场感增强”的职责，例如更完整的看台结构、暖光入口、旗帜、门楣、灯架与更整洁的外立面。视觉重点是“主场感越来越强”，而不是“商业包装越来越重”。  

**Art Bible Anchors:**
- §3.4
- §4
- §6
- §7
- §8
- §9

**Generation Prompt:**  
`pixel art stadium upgrade and matchday overlays, fuller seating, banners, warm lamps, cleaner facade, stronger home-ground identity, community pride, readable modular layers, warm small-town football atmosphere`  
`--no sponsor wall overload --no esports arena style --no luxury VIP gloss --no neon strips`

**Status:** Needed

## ASSET-063 — Stadium Construction State Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 单帧 `192×128`；4 状态（`foundation / constructing_a / constructing_b / upgrading`）建议 `768×128 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_stadium_construction_sheet.png` |
| Polycount | N/A |
| Texture Res | 与 ASSET-061 同级；固定 frame box 切片 |

**Visual Description:**  
球场建造状态应像“镇上一起扩建自己的主场”，而不是工业化施工秀。通过半成型看台、整洁木料、简化脚手和布旗，表现一座社区主场逐步成形的过程，保持积极、清晰、可读。  

**Art Bible Anchors:**
- §3.2
- §4
- §6
- §8

**Generation Prompt:**  
`pixel art stadium construction states, half-built stand, tidy scaffolding, lumber stacks, civic expansion mood, optimistic small-town football project, low-stress readable progression, warm restrained palette`  
`--no industrial chaos --no sparks --no grim realism --no giant cranes dominating the frame`

**Status:** Needed

## ASSET-064 — Stadium Frontage / Gate Prop Set

| Field | Value |
|-------|-------|
| Category | Sprite / Environment |
| Dimensions | 基础 cell `16×16`；建议 `128×80 px` sheet |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `prop_stadium_frontage_set_sheet.png` |
| Polycount | N/A |
| Texture Res | Landmark props tier；建议独立或并入 matchday / landmark props atlas |

**Visual Description:**  
包含售票亭、入口栏杆、自行车架、旗杆、围巾摊、导视牌和手绘比赛海报等前场元素。它们应让球场在比赛日显得热闹而有秩序，并让“主场优势”和“比赛收入”有直观的社区文化锚点。  

**Art Bible Anchors:**
- §3.4
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art stadium frontage props, ticket booth, scarf stall, bike rack, flagpole, queue rails, hand-painted match posters, cozy local football event, clear silhouettes, controlled density, community pride`  
`--no aggressive ads --no clutter spam --no glossy corporate event setup`

**Status:** Needed
