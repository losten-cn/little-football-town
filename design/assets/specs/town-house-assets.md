# Asset Specs — entity: Town House

> **Source**: `design/assets/entity-inventory.md`, `design/art/art-bible.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 2 assets specced / 2 approved / 0 in production / 0 done

## ASSET-065 — Town House Facade Variant Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 基础网格 `16×16`；逻辑占地 `48×48`（3×3 tile）；渲染盒 `64×64`；建议 5 个变体（约 `320×64 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_town_house_facade_sheet.png` |
| Polycount | N/A |
| Texture Res | Town residential facade tier；建议并入 `town_residential_facades` atlas |

**Visual Description:**  
住宅立面应表现“住得起、住得久、有人打理”的小镇日常，靠屋顶轮廓、窗户节奏、门廊比例和暖窗变化建立差异。它们要像社区足球文化的背景锚点，而不是豪华住宅或冷冰冰的标准化街区。  

**Art Bible Anchors:**
- §3.2
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art small-town house facades, low-rise homes, cream plaster, earth-brown roofs, flower boxes, curtains, warm windows, lived-in and welcoming, silhouette-first, low-noise, football-town background identity`  
`--no luxury villas --no cold suburban uniformity --no neon windows --no high-rise apartment blocks`

**Status:** Needed

## ASSET-066 — Town House Frontage Prop Set

| Field | Value |
|-------|-------|
| Category | Sprite / Environment |
| Dimensions | 基础 cell `16×16`；建议 `128×64 px` sheet |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `prop_town_house_frontage_set_sheet.png` |
| Polycount | N/A |
| Texture Res | Residential props small tier；建议并入 `town_residential_props` atlas |

**Visual Description:**  
门前道具负责给住宅补上生活感，包括邮箱、自行车、盆栽、晾衣、门垫、小长椅和轻度俱乐部文化痕迹。它们应支持“可复用街区拼装”，但不能因为细节过多而误导玩家把住宅误读为主要交互点。  

**Art Bible Anchors:**
- §3.4
- §4
- §6
- §8

**Generation Prompt:**  
`pixel art residential frontage props, mailbox, bicycle, potted plants, laundry line, doormat, small bench, subtle football scarf accents, cozy neighborhood life, clustered detail, calm readability`  
`--no clutter overload --no heavy signage --no luxury decoration`

**Status:** Needed
