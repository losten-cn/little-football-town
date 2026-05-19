# Asset Specs — entity: Café

> **Source**: `design/assets/entity-inventory.md`, `design/art/art-bible.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 2 assets specced / 2 approved / 0 in production / 0 done

## ASSET-069 — Café Facade Variant Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 基础网格 `16×16`；逻辑占地 `64×48`（4×3 tile）；渲染盒 `80×64`；建议 3 个变体（约 `240×64 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_cafe_facade_sheet.png` |
| Polycount | N/A |
| Texture Res | Town commerce facade tier；建议与 Corner Shop 共用 commerce atlas |

**Visual Description:**  
咖啡馆应读成“比赛前后会停留的地方”，靠暖窗、布篷、门前小桌和柔和色调形成停留感。它比商铺更柔和、更有休息氛围，但仍然要保持小镇社区的亲切、简洁和可读。  

**Art Bible Anchors:**
- §3.2
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art cozy small-town cafe facade, warm windows, cream walls, calm blue awning, town-gold trim, friendly football-town gathering spot, inviting and readable, low-noise pixel art, relaxed civic atmosphere`  
`--no trendy city cafe --no neon --no luxury branding --no upscale restaurant facade`

**Status:** Needed

## ASSET-070 — Café Seating / Frontage Set

| Field | Value |
|-------|-------|
| Category | Sprite / Environment |
| Dimensions | façade overlay 单帧 `80×64`；建议 3–4 帧；另含 `16×16` 门前道具，整体建议 `128×64 px` 级别 sheet |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_cafe_seating_overlay_sheet.png`、`prop_cafe_frontage_set_sheet.png` |
| Polycount | N/A |
| Texture Res | Commerce props small tier；避免常驻多层 overdraw |

**Visual Description:**  
这组负责小桌椅、黑板菜单、盆栽、伞篷、杯盘和轻度俱乐部围巾挂饰，把“社区停留感”落到建筑前景。重点是门前氛围与休息节奏，而不是复杂餐饮细节或高密度摆设。  

**Art Bible Anchors:**
- §3.4
- §4
- §6
- §8

**Generation Prompt:**  
`pixel art cafe terrace props, small tables, chairs, chalkboard menu, planters, cups, subtle football scarf accents, warm community hangout, broad silhouettes, controlled detail, cozy small-town rhythm`  
`--no clutter overload --no upscale restaurant feel --no glossy lifestyle branding`

**Status:** Needed
