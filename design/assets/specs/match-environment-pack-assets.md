# Asset Specs — pack: Match Environment

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/match-competition-system.md`, `design/art/art-bible.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 4 assets specced / 4 approved / 0 in production / 0 done

## ASSET-076 — Match Pitch Tile Set

| Field | Value |
|-------|-------|
| Category | Environment / Terrain / Tile Set |
| Dimensions | 基础网格 `16×16`；建议 48–64 tile（`256×128 px`）；统一 `16×16` 切片 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `tile_match_pitch_core_16grid.png` |
| Polycount | N/A |
| Texture Res | Match terrain tier；独立 pitch tile sheet |

**Visual Description:**  
比赛草坪应比训练场更正式、更整洁，边线、中圈和禁区识别要更强，但仍保留社区主场的轻微使用痕迹。它卖的是“镇上最重要的比赛空间”，不是豪门草坪秀场。  

**Art Bible Anchors:**
- §2
- §3.5
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art football match pitch tileset, clean readable lines, modest wear, community stadium not elite arena, warm natural greens, silhouette-first field grammar, readable center circle and box markings`  
`--no hyperreal turf --no luxury mow stripes --no neon green --no broadcast-sports glam`

**Status:** Needed

## ASSET-077 — Stadium Stand / Terrace Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Structure / Sprite Sheet |
| Dimensions | 基础网格 `16×16`；建议 `512×512 px`；模块以 `1×1`、`2×1`、`2×2`、`4×2 tile` 为主 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_stadium_terrace_core_16grid.png` |
| Polycount | N/A |
| Texture Res | Match shell tier；建议并入 `atlas_match_shell_1024.png` |

**Visual Description:**  
看台与站席应读成“镇民熟悉、会聚集、会呐喊的主场支撑结构”，护栏、楼梯和简易顶棚比豪华座椅更重要。整体要保留社区球场的人尺度，不把比赛氛围推向职业联赛商业包装。  

**Art Bible Anchors:**
- §2
- §3.2
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art small-town football stadium stand and terrace, community-built seating, railings banners modest roof, warm matchday atmosphere, readable silhouette, human-scale structure, low-noise`  
`--no luxury VIP stand --no mega arena --no corporate grandstand --no neon lighting`

**Status:** Needed

## ASSET-078 — Goal Net Prop Set

| Field | Value |
|-------|-------|
| Category | Sprite / Match Prop |
| Dimensions | 单个球门建议 `64×32 px`；推荐 `idle / hit_a / hit_b` 共 3 帧；左右镜像复用 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `prop_goal_net_match_64x32.png` |
| Polycount | N/A |
| Texture Res | Match shell prop tier；建议并入 `atlas_match_shell_1024.png` |

**Visual Description:**  
球门与网面必须在小尺寸下一眼可读，先靠白色门框与整体轮廓成立，网格只做克制暗示。轻微下垂和磨损能让它看起来像被长期使用、被认真维护的主场器材。  

**Art Bible Anchors:**
- §3.5
- §4
- §6
- §8

**Generation Prompt:**  
`pixel art football goal net and frame, crisp readable white posts, subtle sagging net, community club match prop, low-noise, grounded small-town stadium style`  
`--no hyper-detailed mesh --no giant shadow box --no sci-fi goal frame`

**Status:** Needed

## ASSET-079 — Sponsor Signboard Set

| Field | Value |
|-------|-------|
| Category | Sprite / Match Sign Set |
| Dimensions | 模块建议 `32×16` 或 `48×16 px`；8–12 块静态牌面 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `prop_sponsor_signboard_match_32x16.png` |
| Polycount | N/A |
| Texture Res | Match shell sign tier；建议并入 `atlas_match_shell_1024.png` |

**Visual Description:**  
赞助牌应表现为本地商户和社区支持的手绘或简洁牌面，而不是密集 sponsor wall。它们负责强化“大家都在支持这支球队”的社区关系，而不是制造商业噪声。  

**Art Bible Anchors:**
- §4
- §6
- §7
- §8
- §9

**Generation Prompt:**  
`pixel art local sponsor signboards for community football ground, hand-painted small business signage, warm civic style, restrained count, readable shapes, local support atmosphere`  
`--no clutter --no neon --no corporate branding overload --no billboard wall`

**Status:** Needed
