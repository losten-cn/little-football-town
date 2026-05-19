# Asset Specs — entity: Crowd Supporter Silhouette

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/match-competition-system.md`, `design/gdd/game-concept.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 5 assets specced / 5 approved / 0 in production / 0 done

## ASSET-040 — Crowd Supporter Silhouette Base Sheet

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | `16×24` 单帧；`4 列 × 4 行` 图集 `64×96 px`（基础站姿 / 抬手 / 前倾 / 轻摆动） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_crowd_supporter_silhouette_16grid.png` |
| Polycount | N/A |
| Texture Res | Crowd small tier；优先批处理与图集合并 |

**Visual Description:**  
看台支持者应以群体轮廓优先，而不是单人细节优先。角色块面要宽、读感快、细节少，通过头肩起伏、围巾形状和抬手节奏传达“整座小镇都在看球”的氛围，并让看台在远景中保持温暖、整齐、热闹但不杂乱。  

**Art Bible Anchors:**
- §2 Mood & Atmosphere  
- §3.1 Character Silhouette Philosophy  
- §3.5 Practical Pixel-Art Rules  
- §5 Pixel Readability and LOD Philosophy

**Generation Prompt:**  
`pixel art crowd supporter silhouette sheet for a warm football town stadium, group-first readability, simple head and shoulder shapes, scarf and raised-hand variations, minimal detail, warm cream slate and gold value grouping with restrained red accents, rhythmic wholesome crowd energy, readable in the background, clean production-ready pixel art`  
`--no realistic faces --no neon signs --no aggressive ultras vibe --no smoke flares --no chrome detail --no dense visual noise --no dark hostile crowd mood`

**Status:** Needed

## ASSET-041 — Crowd Supporter Prop Variant Set

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | 与 Base 对齐：`16×24` frame box；单张建议不超过 `128×96 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_crowd_supporter_prop-scarf_16grid.png`、`char_crowd_supporter_prop-cap_16grid.png`、`char_crowd_supporter_prop-bunting_16grid.png` |
| Polycount | N/A |
| Texture Res | 优先使用 overlay / palette 复用，避免 full duplicate crowd atlas |

**Visual Description:**  
道具变体用于提升群体层次，但不能破坏远景整合感。围巾、帽子、小彩带、简化手举物应以大轮廓和少像素表达，只负责增加节庆与归属感，不做高频细节噪声。  

**Art Bible Anchors:**
- §3.4 Hero Shapes vs Supporting Shapes  
- §4 Primary Semantic Palette  
- §5 Costume and Accessory Rules  
- §8 Palette and Value Discipline

**Generation Prompt:**  
`pixel art prop variant set for crowd supporter silhouettes, scarves caps bunting and small supporter props, same readable crowd silhouettes, broad calm color blocking, cream and slate structure with warm gold and restrained club red accents, supportive festive mood, minimal ornament, clear at distance, wholesome community stadium feel`  
`--no giant banners full of text --no neon accessories --no flare guns --no chrome objects --no dense clutter --no hostile mob energy`

**Status:** Needed

## ASSET-042 — Crowd Supporter Cheer Pattern Sheet

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | `16×24` 单帧；`4 列 × 4 行` 图集 `64×96 px`（clap / sway / scarf_wave / rise） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_crowd_supporter_cheer_16grid.png` |
| Polycount | N/A |
| Texture Res | Crowd animation small tier；控制循环帧数便于批量复用 |

**Visual Description:**  
这组用于建立看台节奏，不靠复杂单体动画，而靠群体循环模式形成“热血但温暖”的比赛呼吸。动作应短、清晰、易拼接，让不同人群层可以错位组合，形成持续而不混乱的支持感。  

**Art Bible Anchors:**
- §2 Mood & Atmosphere（庆祝语气）  
- §3.5 Practical Pixel-Art Rules  
- §7 Animation Feel  
- §8 Palette and Value Discipline

**Generation Prompt:**  
`pixel art cheer pattern sheet for crowd supporter silhouettes, simple looping motions for clap sway scarf-wave and rise, group rhythm first, broad readable shapes, warm cream-gold with restrained red accents, wholesome small-town stadium atmosphere, easy-to-tile crowd animation, clean production-friendly pixel loops`  
`--no mosh-pit chaos --no taunt gestures --no smoke flare aggression --no neon confetti --no realistic crowd detail --no chrome gloss`

**Status:** Needed

## ASSET-043 — Crowd Supporter Banner / Flag Accent Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | `24×16` / `32×24` / `48×32` 三档；每类旗帜/横幅各一套 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_crowd_banner_small.png`、`ui_crowd_flag_medium.png`、`ui_crowd_banner_large.png` |
| Polycount | N/A |
| Texture Res | Native-authored 多档；避免从单一母版机械缩放 |

**Visual Description:**  
横幅与旗帜应像社区手作支持物，而不是职业联赛广告资产。结构上优先大色块、简化边缘与少量徽记留白，强调“这是居民和球迷共同做出来的支持信号”，服务看台温度与归属感。  

**Art Bible Anchors:**
- §3.3 UI Shape Grammar  
- §4 Semantic Usage Rules  
- §7 Iconography Style  
- §9 Local football club posters / community noticeboards

**Generation Prompt:**  
`pixel art banner and flag accent set for football crowd supporters, handmade community-club feel, large readable color blocks, simple stitched edges, minimal emblem space, cream and gold with restrained red blue green accents, warm supportive noticeboard-and-stadium crossover identity, clean silhouettes, inviting management sim style`  
`--no sponsor-wall graphics --no luxury sports branding --no neon gradients --no chrome trims --no oversized text clutter --no militaristic insignia`

**Status:** Needed

## ASSET-044 — Crowd Supporter Goal-Reaction Burst FX

| Field | Value |
|-------|-------|
| Category | VFX / Particles |
| Dimensions | 默认 `32×32` 单帧；`6–8` 帧，单张建议不超过 `256×128 px`；远景批量场景优先 small tier |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `vfx_crowd_goal-burst_small.png`、`vfx_crowd_goal-burst_medium.png` |
| Polycount | N/A |
| Texture Res | Crowd VFX small tier；alpha 边界保持紧凑，避免 overdraw |

**Visual Description:**  
进球反应特效应表现“整片看台一起亮起来”的喜悦，而不是爆炸式舞台烟火。建议采用轻量上扬纸屑、围巾弧线、简化光点和节奏脉冲，把热血足球的情绪放在社区欢呼里表达，而不是用侵略性特效覆盖画面。  

**Art Bible Anchors:**
- §1 Principle 3: Always Forward  
- §2 Mood & Atmosphere  
- §4 Celebration color guidance  
- §7 Animation Feel

**Generation Prompt:**  
`pixel art goal reaction burst effect for crowd supporters in a warm football town stadium, gentle upward celebratory burst, small scarf arcs, soft sparkle clusters, light confetti hints, cream and town-gold core with restrained club-red accents, readable and joyful, community celebration mood, clean value steps, minimal clutter`  
`--no neon bloom --no pyro explosions --no flare smoke --no anime power-up aura --no chrome particles --no huge shockwaves --no dense particle noise --no hostile crowd energy`

**Status:** Needed
