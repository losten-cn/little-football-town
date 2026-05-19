# Asset Specs — entity: Opponent Footballer

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/match-competition-system.md`, `design/gdd/match-performance-ui.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 6 assets specced / 6 approved / 0 in production / 0 done

## ASSET-034 — Opponent Footballer Base Sprite Sheet

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | `32×32` 单帧；动作图集 `256×128 px`（`8 列 × 4 行`，`idle / walk / run / kick`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_opponent_footballer_base_32grid.png` |
| Polycount | N/A |
| Texture Res | 单图集建议不超过 `1024×1024` |

**Visual Description:**  
对手球员应先被读成“具有比赛压力的另一支球队成员”，而不是反派怪物。轮廓与 Club Footballer 保持同层级清晰度，但姿态更紧、更专注，允许在肩线、步幅和配色重心上稍微强调对抗感，同时仍保留温暖世界观下的可读性和克制。  

**Art Bible Anchors:**
- §3.1 Character Silhouette Philosophy  
- §3.5 Practical Pixel-Art Rules  
- §4 Semantic Usage Rules  
- §5 Character Design Direction（Footballers / Readability）

**Generation Prompt:**  
`pixel art sprite sheet of an opponent footballer in a cozy football town management sim, silhouette-first readability, rounded head, compact athletic body, slightly tighter competitive posture, clear shorts socks boots separation, cream and slate structural base with distinct rival color blocking, restrained contrast, broad clean shapes, readable idle walk run kick frames, grounded match-pressure energy without villainy`  
`--no monstrous aggression --no neon --no chrome --no esports rage styling --no hyper-muscular anatomy --no spikes --no photoreal rendering --no texture noise`

**Status:** Needed

## ASSET-035 — Opponent Footballer Portrait Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | `48×48`（roster）与 `96×96`（detail）各 1 套 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `portrait_opponent_footballer_roster_48.png`、`portrait_opponent_footballer_detail_96.png` |
| Polycount | N/A |
| Texture Res | 仅保留两档肖像尺寸，避免冗余导出 |

**Visual Description:**  
肖像应传达“值得重视的对手”，气质可以冷静、坚定、锐利或自信，但不能走向夸张敌意。Roster 版强调快速识别比赛威胁，Detail 版允许略增队服和神情细节，但仍需遵守同一像素语言和管理模拟语气。  

**Art Bible Anchors:**
- §5 Character Design Direction（Expression / Detail Limits）  
- §4 UI Palette  
- §7 UI/HUD Visual Direction（readability first）

**Generation Prompt:**  
`pixel art portrait set for an opponent footballer in a warm football management sim, one roster portrait and one detail portrait, composed competitive expression, readable face shape, simple hair masses, a few memorable traits, rival-club identity through restrained color blocking, clean UI-friendly pixel treatment, grounded and human, pressure without hostility`  
`--no villain sneer --no celebrity glamour --no screaming rage --no neon rim light --no photoreal skin texture --no cluttered background --no esports poster style`

**Status:** Needed

## ASSET-036 — Opponent Footballer Kit Variant Set

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | 与 Base 完全同网格：每套 `256×128 px`，`32×32` cell，对应 `primary / away / derby` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_opponent_footballer_primary_32grid.png`、`char_opponent_footballer_away_32grid.png`、`char_opponent_footballer_derby_32grid.png` |
| Polycount | N/A |
| Texture Res | 与 ASSET-034 对齐；优先复用布局避免内存膨胀 |

**Visual Description:**  
该组用于体现不同对手出场语境，不改轮廓，只改配色与少量衣装分区。Primary 强调俱乐部身份，Away 更强调整洁清晰，Derby 可略增紧张与戏剧感，但不能进入浮夸商业足球视觉；所有版本都必须让玩家一眼认出“这是对手球员同一体系”。  

**Art Bible Anchors:**
- §4 Color System（semantic mapping）  
- §5 Costume and Accessory Rules  
- §8 Palette and Value Discipline

**Generation Prompt:**  
`pixel art opponent football kit variant set for the same rival player sprite, primary away and derby versions, identical silhouette and frame layout, broad calm color blocking, practical well-kept uniforms, readable at gameplay scale, derby version slightly more intense but still grounded, warm management sim world, restrained contrast and minimal ornament`  
`--no neon trim --no chrome shine --no pro-esports jersey style --no oversized logos --no dense striping --no high-frequency fabric noise`

**Status:** Needed

## ASSET-037 — Opponent Footballer Threat / Form Overlay Icons

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | `16×16` / `24×24` / `32×32` 三档；`threat / form / pressure` 共 9 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_opponent_threat_16.png`、`ui_opponent_form_24.png`、`ui_opponent_pressure_32.png` |
| Polycount | N/A |
| Texture Res | 严格使用 UI 图标阶梯 `16 / 24 / 32` |

**Visual Description:**  
这些是赛前/赛中识别对手重点人物的叠加图标，必须一眼完成信息区分。`threat` 用尖一点但仍克制的进攻轮廓，`form` 用稳定上扬结构，`pressure` 用收紧或逼近式图形；差异必须靠形状先成立，颜色只辅助。  

**Art Bible Anchors:**
- §4 Colorblind Safety  
- §7 Iconography Style  
- §7 Accessibility and Input Clarity  
- §3.3 UI Shape Grammar

**Generation Prompt:**  
`pixel art UI overlay icon set for opponent footballer scouting and match presentation, three icons only threat form pressure, silhouette-first readability, broad clean shapes, cream and slate base with restrained rival semantic accents, threat more pointed, form stable and rising, pressure tighter and closing-in, cozy management UI tone, accessible non-color-dependent distinctions`  
`--no skull motifs --no blood symbols --no aggressive sirens --no neon glow --no glossy app-icon bevels --no esports sharpness`

**Status:** Needed

## ASSET-038 — Opponent Footballer Pressure FX

| Field | Value |
|-------|-------|
| Category | VFX / Particles |
| Dimensions | 默认 `32×32` 单帧；`6–8` 帧，单张建议不超过 `256×128 px`；近景 UI 可选 `64×64` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `vfx_opponent_pressure_small.png`、`vfx_opponent_pressure_medium.png` |
| Polycount | N/A |
| Texture Res | Gameplay/UI VFX small tier；alpha 边界保持紧凑 |

**Visual Description:**  
对手压力特效应表现“这个人正在给比赛带来紧张度”，而不是魔法爆发。建议采用收拢式速度弧、轻量压迫脉冲或克制的对抗火花，帮助玩家读到风险上升，但不应夺走球员主体或变成激烈电竞光效。  

**Art Bible Anchors:**
- §1 Principle 3: Always Forward  
- §4 Celebration color guidance  
- §7 Animation Feel  
- §8 Palette and Value Discipline

**Generation Prompt:**  
`pixel art pressure visual effect for an opponent footballer in match presentation, subtle closing-in pulse, compact speed arcs, restrained spark cues, readable and calm, grounded competitive tension, cream and slate structure with controlled rival accent colors, clean value steps, management sim feedback effect, minimal clutter`  
`--no neon bloom --no lightning bursts --no fire explosions --no anime power aura --no chrome particles --no huge shockwaves --no dense particle noise --no horror vibe`

**Status:** Needed

## ASSET-039 — Opponent Footballer Rivalry Reaction Emote Sheet

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | `16×16` 单帧；建议 `6–8` 帧；单张建议不超过 `128×64 px`；特殊强调可选 `24×24` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_opponent_rival_focus_16.png`、`ui_opponent_rival_challenge_16.png`、`ui_opponent_rival_derby_24.png` |
| Polycount | N/A |
| Texture Res | Small icon/emote tier；固定 cell slicing，底部居中对齐 |

**Visual Description:**  
这组用于表达对手对抗、专注、回应和 derby 氛围下的轻量情绪反馈。它们应传达“比赛张力”而不是敌意挑衅，可使用凝视、挑战箭头、短促火花、专注气泡或对位强调等符号。  

**Art Bible Anchors:**
- §3.3 UI Shape Grammar  
- §4 Semantic Usage Rules  
- §7 Iconography Style  
- §7 Animation Feel

**Generation Prompt:**  
`pixel art emote sheet for opponent footballer rivalry reactions, warm football match tension, simple readable cues for focus challenge answer derby heat and pressure, broad calm shapes, cream and slate structure with restrained rival accents, inviting management sim style, competitive but not hostile, clean silhouettes`  
`--no angry comic rage marks --no taunt memes --no neon streamer overlays --no chrome badges --no chaotic particles --no violent symbolism`

**Status:** Needed
