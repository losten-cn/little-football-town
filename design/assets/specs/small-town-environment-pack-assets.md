# Asset Specs — pack: Small-Town Environment

> **Source**: `design/assets/entity-inventory.md`, `design/art/art-bible.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 3 assets specced / 3 approved / 0 in production / 0 done

## ASSET-073 — Street Block Core Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Terrain / Tile Set |
| Dimensions | 基础网格 `16×16`；建议约 64 tile（`256×128 px`）；统一 `16×16` 切片 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_street_block_core_16grid.png` |
| Polycount | N/A |
| Texture Res | Town exterior tile tier；建议并入 `atlas_world_town_exterior_core_1024.png` |

**Visual Description:**  
街区核心地表应先读出“可以散步、可以回家、也有足球生活痕迹的小镇日常”，而不是复杂装饰场景。重点放在道路、路缘、转角、铺装节奏和留白，让街道成为温暖稳定的管理主背景。  

**Art Bible Anchors:**
- §1
- §3.2
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art cozy small-town street block tileset, low-rise neighborhood roads and sidewalks, football culture lightly woven into daily life, warm cream brown green palette, silhouette-first, low-noise, inviting community street, readable intersections and edges`  
`--no neon --no sci-fi --no luxury sports district --no clutter overload --no harsh modern city paving`

**Status:** Needed

## ASSET-074 — Civic Plaza Landmark Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Landmark / Sprite Sheet |
| Dimensions | 基础网格 `16×16`；建议 `512×256 px`；模块以 `2×2`、`3×3`、`4×4 tile` 为主 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_civic_plaza_landmark_16grid.png` |
| Polycount | N/A |
| Texture Res | Town exterior landmark tier；建议并入 `atlas_world_town_exterior_core_1024.png` |

**Visual Description:**  
社区广场应像镇民会停留、集合、贴公告、庆祝胜利的公共核心，而不是商业购物广场。铺地、树池、旗串和公告区要形成开阔但不空旷的焦点结构，读感偏“社区自豪感”而非“市政权威感”。  

**Art Bible Anchors:**
- §1
- §3.4
- §4
- §6
- §8

**Generation Prompt:**  
`pixel art civic plaza in a football town, warm open gathering square, modest paving trees benches notice area, community pride not commercial spectacle, clean focal composition, low-noise, welcoming public space`  
`--no shopping mall plaza --no corporate event square --no neon banners --no dense clutter`

**Status:** Needed

## ASSET-075 — Residential Backdrop Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Backdrop / Sprite Sheet |
| Dimensions | 基础网格 `16×16`；建议 `512×256 px`；模块以 `2×2`、`3×2`、`4×3 tile` 为主 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_residential_backdrop_16grid.png` |
| Polycount | N/A |
| Texture Res | Background tier；建议并入 `atlas_world_town_exterior_core_1024.png` |

**Visual Description:**  
住宅背景层负责卖出“小镇延展感”和“有人正在这里生活”的熟悉氛围，但视觉优先级必须低于前景可交互层。屋顶、后墙、树冠和后院轮廓应柔和、低对比，不把玩家注意力从主要管理信息上抢走。  

**Art Bible Anchors:**
- §3.2
- §3.5
- §4
- §6
- §8

**Generation Prompt:**  
`pixel art residential block backdrop, layered rooftops balconies laundry trees, warm lived-in football town neighborhood, soft contrast, background readability, low-noise, familiar daily-life atmosphere`  
`--no street-facing hero facades --no dense micro detail --no high-rise skyline --no neon`

**Status:** Needed
