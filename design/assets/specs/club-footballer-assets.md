# Asset Specs — entity: Club Footballer

> **Source**: `design/assets/entity-inventory.md` (#1), `design/gdd/player-development-system.md`, `design/gdd/match-competition-system.md`, `design/gdd/match-performance-ui.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 6 assets specced / 6 approved / 0 in production / 0 done

## ASSET-012 — Club Footballer Base Sprite Sheet

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | `32×32` 单帧；动作图集 `256×128 px`（`8 列 × 4 行`，`idle / walk / run / kick`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_club_footballer_base_32grid.png` |
| Polycount | N/A |
| Texture Res | 单图集建议不超过 `1024×1024`（当前远低于上限） |

**Visual Description:**  
主力球员应先靠轮廓被识别：圆润头部、紧凑躯干、清晰腿部分离，姿态略前倾，体现“可培养、可信赖”的小镇球队气质。配色以奶油/石板为基础，点缀克制的金色与俱乐部红，避免英雄化、凶猛化与电竞化。四类动作分别传达平稳待机、日常移动、比赛投入、出脚决断，但整体语气仍温暖克制。  

**Art Bible Anchors:**
- §3.1 Character Silhouette Philosophy  
- §3.5 Practical Pixel-Art Rules  
- §4 Semantic Usage Rules  
- §5 Character Design Direction（Footballers / Readability）

**Generation Prompt:**  
`pixel art sprite sheet of a cozy small-town club footballer, silhouette-first readability, rounded head, compact athletic body, clear shorts-socks-boots separation, warm cream and slate base with restrained town-gold and muted club-red accents, approachable coachable player energy, animation keys for idle walk run kick, broad calm shapes, minimal ornament, clean negative space, production-friendly pixel art`  
`--no neon --no chrome --no esports aggression --no hyper-muscular anatomy --no spiky silhouette --no sponsor clutter --no realistic rendering --no texture noise`

**Status:** Needed

## ASSET-013 — Club Footballer Portrait Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | `48×48`（roster）与 `96×96`（detail）各 1 套 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `portrait_club_footballer_roster_48.png`、`portrait_club_footballer_detail_96.png` |
| Polycount | N/A |
| Texture Res | 仅保留两档肖像尺寸，避免冗余导出 |

**Visual Description:**  
肖像应传达“值得长期投入的本地球员”而非明星海报：五官友好、发型块面清楚、一个可记忆特征即可。Roster 版强调快速扫读，Detail 版允许略增织物/表情细节，但必须保持同一像素语法。整体色彩继续沿用奶油、金、克制红与平静蓝/石板中性。  

**Art Bible Anchors:**
- §5 Character Design Direction（Expression / Detail Limits）  
- §4 UI Palette  
- §7 UI/HUD Visual Direction（readability first）

**Generation Prompt:**  
`pixel art portrait set for a football town management sim, one roster portrait and one detail portrait of a warm local club footballer, friendly readable face, simple hair masses, one memorable personal trait, focused/hopeful expression, cream-gold primary palette with restrained red and calm blue accents, clean UI-friendly pixel treatment, inviting community identity`  
`--no anime exaggeration --no celebrity glamour --no angry shouting --no neon rim light --no photoreal skin texture --no cluttered background --no esports poster style`

**Status:** Needed

## ASSET-014 — Club Footballer Kit Variant Set

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | 与 Base 完全同网格：每套 `256×128 px`，`32×32` cell，对应 `home / away / training_bib` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_club_footballer_home_32grid.png`、`char_club_footballer_away_32grid.png`、`char_club_footballer_training_bib_32grid.png` |
| Polycount | N/A |
| Texture Res | 与 ASSET-012 对齐；优先复用布局避免内存膨胀 |

**Visual Description:**  
该组不改轮廓，只改配色与少量衣装分区，确保玩家一眼识别同一球员体系。Home 偏“归属感与热血”：奶油+俱乐部红+金；Away 偏“清晰与纪律”：奶油+平静蓝+石板；Training Bib 偏“成长语义”：绿或金的训练覆盖层。禁止复杂条纹、过强对比和商业化赞助噪声。  

**Art Bible Anchors:**
- §4 Color System（semantic mapping）  
- §5 Costume and Accessory Rules  
- §8 Palette and Value Discipline

**Generation Prompt:**  
`pixel art football kit variant set for the same club player sprite, home away training-bib versions, identical silhouette and frame layout, broad calm color blocking, home in cream with muted red and gold accents, away in cream with calm blue and slate accents, training bib in field-green or warm-gold overlay, practical cared-for small-town uniforms, readable at gameplay scale`  
`--no neon trim --no chrome shine --no pro-esports jersey style --no oversized logos --no dense striping --no high-frequency fabric noise`

**Status:** Needed

## ASSET-015 — Club Footballer Status Overlay Icons

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | `16×16` / `24×24` / `32×32` 三档；`fatigue / injury / morale` 共 9 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_club_footballer_fatigue_16.png`、`ui_club_footballer_injury_24.png`、`ui_club_footballer_morale_32.png` |
| Polycount | N/A |
| Texture Res | 严格使用 UI 图标阶梯 `16 / 24 / 32` |

**Visual Description:**  
这是球员状态叠加标识，必须比世界美术更干净，并在一眼内完成状态识别。`fatigue` 用低能量轮廓，`injury` 用清晰医疗/受伤提示，`morale` 用积极上扬结构；差异必须靠形状先成立，颜色只辅助。语气是“支持性提示”而非惩罚式警报。  

**Art Bible Anchors:**
- §4 Colorblind Safety  
- §7 Iconography Style  
- §7 Accessibility and Input Clarity  
- §3.3 UI Shape Grammar

**Generation Prompt:**  
`pixel art UI status icon set for club footballer, three icons only fatigue injury morale, silhouette-first readability, broad calm shapes, minimal detail, cream and slate base, fatigue with subdued low-energy form, injury with clear red medical warning cue, morale with uplifting green/gold cue, cozy management UI tone, accessible non-color-dependent distinctions`  
`--no tiny clutter --no skull/blood motifs --no aggressive alarm graphics --no neon glow --no glossy app-icon bevels --no esports sharpness`

**Status:** Needed

## ASSET-016 — Club Footballer Selection Ring FX

| Field | Value |
|-------|-------|
| Category | VFX / Particles |
| Dimensions | 单帧 `64×16`；4 帧脉冲循环图集 `256×16 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `vfx_club_footballer_selection_ring_64x16grid.png` |
| Polycount | N/A |
| Texture Res | 小尺寸循环特效，控制 overdraw |

**Visual Description:**  
选中环特效应表现“被关注、可操作”，而不是“被攻击或高能施法”。采用宽缓的环形轮廓，主色奶油+金，必要时少量红色激活点缀；可带轻微脉冲但不应使用强发光。整体必须在草坪背景上稳定可见且不抢主信息。  

**Art Bible Anchors:**
- §3.4 Hero Shapes vs Supporting Shapes  
- §7 Maintaining World Identity Without Losing Readability  
- §4 Semantic Usage Rules  
- §9 Style Prohibitions

**Generation Prompt:**  
`pixel art on-pitch selection ring effect for a cozy football management game, broad calm oval ring under player feet, warm cream and town-gold primary colors with tiny restrained red active accent, subtle pulse loop, crisp pixel edges, readable over green grass, supportive highlight not aggressive`  
`--no neon halo --no electric arcs --no spikes --no flames --no hologram look --no heavy particle clutter --no esports highlight style`

**Status:** Needed

## ASSET-017 — Club Footballer Crowd-Celebration Emote Sheet

| Field | Value |
|-------|-------|
| Category | VFX / Particles |
| Dimensions | `16×16` 单帧；`4 列 × 6 行` 图集 `64×96 px`（6 种表情/符号各 4 帧） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `vfx_club_footballer_crowd_emote_sheet_16grid.png` |
| Polycount | N/A |
| Texture Res | 小图集合并，便于共享 atlas 与批处理 |

**Visual Description:**  
这组用于看台/周边庆祝反馈，语气应是“社区一起开心”，而非挑衅或压迫。可包含围巾挥舞、掌声、小旗、欢呼表情、轻量彩屑等，保持块面清晰与读感轻快。色彩以奶油/金/克制红为节庆核心，蓝绿仅作辅助平衡。  

**Art Bible Anchors:**
- §2 Mood & Atmosphere（庆祝语气）  
- §3.5 Practical Pixel-Art Rules  
- §4 Color System（celebration hierarchy）  
- §9 Reference Direction / Style Prohibitions

**Generation Prompt:**  
`pixel art crowd celebration emote sheet for a football town management sim, six community cheer emotes with 4-frame loops each (scarf wave, clap burst, mini flag, happy cheer face, soft confetti, joy sparkle), chunky readable silhouettes, warm cream-gold with restrained red festive accents, wholesome local-club atmosphere, clean production-ready pixel sheet`  
`--no taunt gestures --no flare/smoke aggression --no neon confetti --no commercial sponsor clutter --no realistic crowd detail --no chrome/gloss`

**Status:** Needed
