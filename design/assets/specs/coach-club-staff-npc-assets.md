# Asset Specs — entity: Coach / Club Staff NPC

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/player-development-system.md`, `design/gdd/match-competition-system.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 5 assets specced / 5 approved / 0 in production / 0 done

## ASSET-024 — Coach / Staff Base Sprite Sheet

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | `24×32` 单帧；按动作族拆分图集；单张建议不超过 `256×256 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_staff_base_idle_small.png`、`char_staff_base_walk_small.png`、`char_staff_base_point_small.png` |
| Polycount | N/A |
| Texture Res | Character small tier；每帧保留约 `2 px` 透明 padding |

**Visual Description:**  
教练与俱乐部职员应先被读成“可靠的大人”和“运营中枢”，而不是比赛主角。轮廓比球员更稳定，站姿更直，允许加入外套、夹克、哨子挂绳、简化记事板等小道具，但仍保持宽大色块、少装饰和一眼可读的像素管理模拟语法。  

**Art Bible Anchors:**
- §3.1 Character Silhouette Philosophy  
- §3.5 Practical Pixel-Art Rules  
- §4 Primary Semantic Palette  
- §5 Archetype Direction

**Generation Prompt:**  
`pixel art sprite sheet of a cozy football town coach and club staff NPC, silhouette-first readability, reliable adult proportions, upright posture, rounded head, calm practical clothing, whistle lanyard, clipboard or jacket variations, warm cream and slate base with restrained town-gold, muted club-red and calm blue accents, broad clean shapes, approachable management sim style, human and grounded, readable idle walk and pointing poses`  
`--no neon --no chrome --no celebrity swagger --no esports coach styling --no tactical sci-fi UI gear --no dense accessories --no photoreal rendering --no harsh contrast`

**Status:** Needed

## ASSET-025 — Coach / Staff Portrait Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 主档 `64×64`；详情页可选 `128×128` detail 版 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `portrait_staff_neutral_standard.png`、`portrait_staff_neutral_detail.png` |
| Polycount | N/A |
| Texture Res | Portrait standard tier；统一裁切与视线高度 |

**Visual Description:**  
肖像需要传达“你愿意信任其带队或协助俱乐部成长”的气质：沉稳、温和、专注、略带疲惫但可靠。允许通过发型、眼镜、胡茬、围巾或职业化服装轮廓制造区分，但必须避免把他们画成权威压迫型或浮夸明星经理。  

**Art Bible Anchors:**
- §1 Visual Identity Statement  
- §4 Semantic Usage Rules  
- §5 Expression and Pose Style  
- §5 Character Detail Limits

**Generation Prompt:**  
`pixel art portrait set of club coach and staff NPCs for a warm football town management sim, trustworthy adult faces, focused calm expressions, subtle tiredness and care, practical clothing, optional glasses or scarf, cream and warm gold base with restrained red and blue accents, broad readable face shapes, inviting and grounded roster identity, community-club professionalism without harsh authority`  
`--no corporate glamour --no esports analyst desk vibe --no angry shouting --no neon rim light --no photoreal wrinkles --no heavy makeup --no villainous expression`

**Status:** Needed

## ASSET-026 — Coach / Staff Role Variant Set

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | 与 Base 完全同布局：`24×32` frame box；各动作族单张建议不超过 `256×256 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_staff_role-headcoach_small.png`、`char_staff_role-assistant_small.png`、`char_staff_role-scout_small.png`、`char_staff_role-physio_small.png` |
| Polycount | N/A |
| Texture Res | 优先使用 overlay / palette 复用，不建议 full duplicate atlas |

**Visual Description:**  
该组用于区分不同 staff 职能，不改核心轮廓，只通过外套长度、肩部色块、小型工具和配色重心区分角色。Head Coach 更偏金/红的领导感，Assistant 更平衡中性，Scout 更偏旅行与观察语义，Physio 则带少量医疗/恢复提示，但都必须保留同一俱乐部世界观。  

**Art Bible Anchors:**
- §3.1 Character Silhouette Philosophy  
- §4 Primary Semantic Palette  
- §4 Semantic Usage Rules  
- §5 Costume and Accessory Rules

**Generation Prompt:**  
`pixel art role variant set for football club staff NPCs, same base silhouette with subtle role differentiation for head coach assistant scout and physio, practical jackets and modest tools, broad calm color blocking, cream and slate base with gold red blue green semantic accents by role, warm small-town club identity, readable at gameplay scale, minimal ornament`  
`--no uniforms with military command tone --no luxury fashion tailoring --no neon insignia --no dense medical equipment --no sharp esports styling --no cluttered sponsor marks`

**Status:** Needed

## ASSET-027 — Coach / Staff Instruction Emote Sheet

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | `16×16` 单帧；建议 `6–8` 帧；单张建议不超过 `128×64 px`；特殊强调可选 `24×24` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_staff_instruction_encourage_16.png`、`ui_staff_instruction_plan_16.png`、`ui_staff_instruction_alert_24.png` |
| Polycount | N/A |
| Texture Res | Small icon/emote tier；固定 cell slicing，底部居中对齐 |

**Visual Description:**  
教练/职员表情应表现“在指导、提醒、组织”，而不是暴躁怒吼。可使用鼓励手势、战术箭头、小哨声、简化灯泡、注意提示或笔记弹出等视觉语义，让玩家感到团队正在被照看和协调。  

**Art Bible Anchors:**
- §3.3 UI Shape Grammar  
- §4 Semantic Usage Rules  
- §7 Iconography Style  
- §7 Animation Feel

**Generation Prompt:**  
`pixel art emote sheet for coach and club staff instructions, warm football town management mood, simple readable cues for encourage plan remind alert and organize, whistle chirp, tactic arrow, note pop, supportive hand gesture, broad calm shapes, cream and gold primary colors with restrained red blue green accents, inviting management sim UI style, clean silhouettes`  
`--no angry comic rage marks --no meme exaggeration --no neon streamer overlays --no military command icons --no chrome badges --no chaotic particles`

**Status:** Needed

## ASSET-028 — Coach / Staff Clipboard / Tactics Overlay Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 严格使用 `16×16` / `24×24` / `32×32` 三档；每个战术提示元素各一套 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_staff_tactics_clipboard_16.png`、`ui_staff_tactics_marker_24.png`、`ui_staff_tactics_plan_32.png` |
| Polycount | N/A |
| Texture Res | Native-authored 三档，不允许单一母版缩放导出 |

**Visual Description:**  
这组是 staff 语义的辅助叠加图标，应该像比赛日白板和训练记事，而不是高科技战术 HUD。可包含简化夹板、磁贴、箭头、站位点、安排勾选等元素，强调温暖、有组织、支持成长的俱乐部运营感。  

**Art Bible Anchors:**
- §3.3 UI Shape Grammar  
- §3.4 Hero Shapes vs Supporting Shapes  
- §4 Semantic Usage Rules  
- §7 Iconography Style

**Generation Prompt:**  
`pixel art tactics overlay icon set for coach and club staff UI, clipboard board markers formation arrows and check cues, silhouette-first readability, broad clean shapes, cream and slate base with town-gold and restrained red blue green accents, community club training board feel, supportive and organized, minimal ornament, readable at small sizes`  
`--no hologram tactics display --no chrome UI plating --no military command room feel --no neon grids --no excessive micro-detail --no aggressive warning design`

**Status:** Needed
