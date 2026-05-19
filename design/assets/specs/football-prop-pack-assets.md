# Asset Specs — pack: Football Props

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/match-competition-system.md`, `design/art/art-bible.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 3 assets specced / 3 approved / 0 in production / 0 done

## ASSET-089 — Football Core

| Field | Value |
|-------|-------|
| Category | Sprite / Hero Prop |
| Dimensions | 基础 cell `16×16`；球体主体建议 `8–10 px`；推荐 `rest + roll_1 + roll_2 + roll_3 + roll_4` 共 5 帧（约 `80×16 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `prop_football_core_16grid.png` |
| Polycount | N/A |
| Texture Res | Shared prop tier；可独立保存以供比赛/训练/UI 共用 |

**Visual Description:**  
足球必须在小尺寸下保持极高识别度，优先靠明暗分块和整体球形成立，而不是靠真实缝线细节。它是比赛视线里的关键英雄物，应当清晰、干净、可信赖。  

**Art Bible Anchors:**
- §3.4
- §4
- §8

**Generation Prompt:**  
`pixel art football, highly readable at small scale, simple panel contrast, warm grounded style, clean silhouette, management sim friendly, reusable across training and match scenes`  
`--no photoreal stitching --no giant shadow --no glowing ball --no sci-fi sports ball`

**Status:** Needed

## ASSET-090 — Practice Cone Set

| Field | Value |
|-------|-------|
| Category | Sprite / Training Prop Set |
| Dimensions | 基础网格 `16×16`；建议 6–8 格；single / stack_2 / knocked / paired-lane 变体 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `prop_practice_cone_set_16grid.png` |
| Polycount | N/A |
| Texture Res | Shared training prop tier；建议作为训练场唯一锥桶来源复用 |

**Visual Description:**  
训练锥桶应当像社区训练区的通用器材，体块简洁、颜色温暖可见，但绝不能走荧光体育商城路线。它服务训练秩序感与路径感，而不是成为视觉噪点。  

**Art Bible Anchors:**
- §3.5
- §4
- §6
- §8

**Generation Prompt:**  
`pixel art football practice cones, rounded simple shapes, warm orange-gold not neon, community training feel, clear silhouette, modest sports equipment`  
`--no fluorescent orange --no plastic showroom gloss --no cluttered kit pile`

**Status:** Needed

## ASSET-091 — Trophy Sheet

| Field | Value |
|-------|-------|
| Category | Sprite / Reward Prop Sheet |
| Dimensions | 建议 `32×32` cell；6–8 个静态 trophy silhouette（约 `128×64 px` 或 `256×32 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `prop_trophy_sheet_32grid.png` |
| Polycount | N/A |
| Texture Res | Reward prop tier；可独立小图保存 |

**Visual Description:**  
奖杯应读成“镇里会珍惜、会陈列、会记住”的荣誉，而不是奢华国际赛事奖具。金色高光要克制，轮廓和重量感优先，让它既有成就感又不脱离小镇尺度。  

**Art Bible Anchors:**
- §2
- §3.4
- §4
- §8
- §9

**Generation Prompt:**  
`pixel art football trophy, civic pride cup, warm gold highlight, modest prestigious shape, readable silhouette, small-town honor and memory`  
`--no luxury elite trophy --no jewel-encrusted cup --no exaggerated fireworks baked in`

**Status:** Needed
