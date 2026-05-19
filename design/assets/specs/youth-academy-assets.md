# Asset Specs — entity: Youth Academy

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/town-building-system.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 4 assets specced / 4 approved / 0 in production / 0 done

## ASSET-057 — Youth Academy Core Structure Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 基础网格 `16×16`；逻辑占地 `64×64`（4×4 tile）；渲染盒 `96×96`；`Lv1–Lv5` 共 5 帧（建议 `480×96 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_youth_academy_core_sheet.png` |
| Polycount | N/A |
| Texture Res | World facility small tier；nearest / filter off / mipmap off / repeat off |

**Visual Description:**  
青训营主建筑应读成“社区认真培养下一代球员的小型学院”，而不是职业豪门的封闭基地。整体以低层、温暖、可亲近的建筑轮廓为主，通过奶油色墙面、木质或砖质边框、俱乐部红小点缀与安静的院落感，传达“希望、成长、被照顾”的核心气质。  

**Art Bible Anchors:**
- §3.2
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art cozy small-town football youth academy, low-rise community training school, cream walls, earth-brown trim, calm blue awning, small club-red accents, open courtyard feeling, silhouette-first readability, low-noise texture, warm and inviting, modest and aspirational, community-grown football culture`  
`--no elite pro campus --no neon --no sci-fi --no sponsor clutter --no luxury sports complex --no cold institutional building`

**Status:** Needed

## ASSET-058 — Youth Academy Upgrade Overlay Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 单帧 `96×96`；`Lv2–Lv5` 增量 overlay 共 4 帧（建议 `384×96 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_youth_academy_upgrade_overlay_sheet.png` |
| Polycount | N/A |
| Texture Res | 与 ASSET-057 同级；同 pivot 对齐 |

**Visual Description:**  
升级覆盖层应表现“培养条件越来越完善”，而不是“设备越来越昂贵”。通过围栏整理、院落优化、阅览角、报名告示、旗帜与墙面装饰等增量件，让同一栋青训营持续成长，同时保持稳定的社区建筑身份。  

**Art Bible Anchors:**
- §3.4
- §4
- §6
- §8

**Generation Prompt:**  
`pixel art modular upgrade overlays for youth football academy, better fencing, study corner, shade canopy, cleaner path, youth posters, community growth not luxury, readable layered silhouettes, restrained warm palette, same building identity across levels`  
`--no chrome lab --no premium academy gloss --no neon signage --no dense detail noise`

**Status:** Needed

## ASSET-059 — Youth Academy Construction State Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 单帧 `96×96`；4 状态（`foundation / constructing_a / constructing_b / upgrading`）建议 `384×96 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_youth_academy_construction_sheet.png` |
| Polycount | N/A |
| Texture Res | 与 ASSET-057 同级；状态切换优先，不做长动画 |

**Visual Description:**  
施工状态应传达“镇上正在为年轻球员建设未来”，而不是大工地景观。用整洁的木料、简化脚手、布篷、半完成轮廓和友好的施工告示来表达进度，让建造本身也带有温和向前的成长感。  

**Art Bible Anchors:**
- §3.2
- §4
- §6
- §8

**Generation Prompt:**  
`pixel art youth academy construction states, tidy scaffolding, wooden planks, canvas shade, partial community sports school silhouette, optimistic small-town football project, low-stress readable progression, warm restrained palette`  
`--no industrial chaos --no sparks --no grim realism --no demolition debris --no hazard-zone aesthetic`

**Status:** Needed

## ASSET-060 — Youth Academy Courtyard / Frontage Prop Set

| Field | Value |
|-------|-------|
| Category | Sprite / Environment |
| Dimensions | 基础 cell `16×16`；建议 `128×64 px` sheet（静态 props 为主） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `prop_youth_academy_courtyard_set_sheet.png` |
| Polycount | N/A |
| Texture Res | World props small tier；建议并入 club facility props atlas |

**Visual Description:**  
这组道具负责把青训营的“学习 + 成长 + 社区支持”落到细节上，包括长椅、自行车、书包、迷你球门、训练锥、公告板、校队旗和通往训练场的共享路径语义。重点是让青训营看起来像年轻球员每天会来、会停留、会进步的地方。  

**Art Bible Anchors:**
- §3.4
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art youth academy courtyard props, benches, bikes, school bags, mini goal, cones, noticeboard, youth team flags, shared path to training ground, warm community football life, broad readable silhouettes, low-noise pixel art`  
`--no commercial branding --no overcrowding --no sponsor wall --no aggressive sports merch clutter`

**Status:** Needed
