# Asset Specs — entity: Town Resident NPC

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/town-building-system.md`, `design/gdd/game-concept.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 5 assets specced / 5 approved / 0 in production / 0 done

## ASSET-029 — Town Resident Base Sprite Sheet

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | `24×32` 单帧；按动作族拆分图集；单张建议不超过 `256×256 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_town_resident_base_idle_small.png`、`char_town_resident_base_walk_small.png`、`char_town_resident_base_wave_small.png` |
| Polycount | N/A |
| Texture Res | Character small tier；每帧保留约 `2 px` 透明 padding |

**Visual Description:**  
小镇居民应先读成“生活在这里的人”，而不是任务发布器或背景纸片。轮廓保持温和、实在、轻微职业差异，姿态可有散步、招呼、驻足观看等日常动作，让城镇显得被真实社区 inhabiting，而不是只有球队存在。  

**Art Bible Anchors:**
- §1 Visual Identity Statement  
- §3.1 Character Silhouette Philosophy  
- §3.5 Practical Pixel-Art Rules  
- §5 Archetype Direction

**Generation Prompt:**  
`pixel art sprite sheet of warm small-town residents for a football management sim, everyday community NPCs, readable silhouettes, rounded heads, practical modest clothing, walking waving and standing poses, cream and slate base with soft town-gold, calm blue, field green and restrained red accents, broad calm shapes, lived-in inviting neighborhood feel, charming management sim pixel art`  
`--no fantasy costumes --no cyberpunk styling --no celebrity fashion --no neon colors --no chrome details --no exaggerated caricature --no gritty realism`

**Status:** Needed

## ASSET-030 — Town Resident Portrait Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 主档 `64×64`；仅在详情页需要时新增 `128×128` detail 版 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `portrait_town_resident_neutral_standard.png`、`portrait_town_resident_neutral_detail.png` |
| Polycount | N/A |
| Texture Res | Portrait standard tier；保持统一裁切与视线高度 |

**Visual Description:**  
居民肖像应强调“你认识这些人，他们也在看着俱乐部成长”。表情可温和、关切、骄傲、好奇或轻松，允许少量职业和年龄差异，但所有人都应服务于社区归属感，而不是突出单一个体戏剧。  

**Art Bible Anchors:**
- §1 Visual Identity Statement  
- §4 Semantic Usage Rules  
- §5 Expression and Pose Style  
- §5 Character Detail Limits

**Generation Prompt:**  
`pixel art portrait set of town residents in a warm football town, approachable community faces, modest everyday styling, expressions like kind curious proud supportive relaxed, broad readable face shapes, cream and warm gold base with restrained red blue green accents, inviting management sim portrait style, human neighborhood identity, gentle variety without dramatic hero framing`  
`--no glamorous fashion portraits --no angry hostility --no photoreal skin detail --no neon rim light --no exaggerated comedy faces --no gritty urban mood`

**Status:** Needed

## ASSET-031 — Town Resident Occupation Variant Set

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | 与 Base 完全同布局：`24×32` frame box；各动作族单张建议不超过 `256×256 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_town_resident_shopkeeper_small.png`、`char_town_resident_teacher_small.png`、`char_town_resident_vendor_small.png`、`char_town_resident_parent_small.png` |
| Polycount | N/A |
| Texture Res | 优先使用 overlay / palette 复用，不建议整套 full duplicate atlas |

**Visual Description:**  
职业变体用于强调“小镇生态真的围绕俱乐部和生活运转”。通过围裙、背包、围巾、书本、提袋等少量识别物建立 shopkeeper、teacher、vendor、parent 等身份，但所有变体都必须保持朴素、可信和同一像素语法。  

**Art Bible Anchors:**
- §3.1 Character Silhouette Philosophy  
- §4 Primary Semantic Palette  
- §4 Semantic Usage Rules  
- §5 Costume and Accessory Rules

**Generation Prompt:**  
`pixel art occupation variant set for small-town residents, same readable base silhouette with subtle shopkeeper teacher vendor and parent variants, practical clothes and small props only, cream and slate base with warm gold, calm blue, field green and restrained red accents, wholesome community identity, broad calm shapes, minimal ornament, readable at gameplay scale`  
`--no costume-party exaggeration --no luxury fashion --no neon accessories --no dense handheld clutter --no fantasy uniforms --no corporate branding`

**Status:** Needed

## ASSET-032 — Town Resident Mood / Support Icon Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 严格使用 `16×16` / `24×24` / `32×32` 三档；`support / concern / excitement` 共 9 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_town_resident_support_16.png`、`ui_town_resident_concern_24.png`、`ui_town_resident_excitement_32.png` |
| Polycount | N/A |
| Texture Res | 严格使用 UI 图标阶梯 `16 / 24 / 32` |

**Visual Description:**  
居民情绪图标应像社区反馈，而不是 KPI 警报。`support` 用上扬与拥抱式轮廓，`concern` 用收拢、思考或轻提醒结构，`excitement` 用开放、节庆但克制的形状；差异必须依赖结构而不是只靠颜色。  

**Art Bible Anchors:**
- §4 Colorblind Safety  
- §7 Iconography Style  
- §7 Accessibility and Input Clarity  
- §3.3 UI Shape Grammar

**Generation Prompt:**  
`pixel art UI mood icon set for town residents, three icons only support concern excitement, silhouette-first readability, broad calm shapes, cream and slate base, support with warm uplifting form, concern with thoughtful contained shape, excitement with open celebratory cue, cozy management sim UI tone, accessible non-color-dependent distinctions`  
`--no aggressive alarms --no angry protest symbols --no tiny clutter --no neon glow --no glossy mobile-app bevels --no esports sharpness`

**Status:** Needed

## ASSET-033 — Town Resident Street-Life Emote Sheet

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | `16×16` 单帧；建议 `6–8` 帧；单张建议不超过 `128×64 px`；特殊强调可选 `24×24` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_town_resident_wave_16.png`、`ui_town_resident_chat_16.png`、`ui_town_resident_pride_24.png` |
| Polycount | N/A |
| Texture Res | Small icon/emote tier；固定 cell slicing，底部居中对齐 |

**Visual Description:**  
这组用于街道和城镇场景中的轻量反馈，应表现聊天、招手、认同、惊喜、围观和社区自豪，而不是喧闹表演。它们的作用是让玩家感到俱乐部影响正在镇上被讨论、被感受、被回应。  

**Art Bible Anchors:**
- §1 Visual Identity Statement  
- §3.3 UI Shape Grammar  
- §4 Semantic Usage Rules  
- §7 Animation Feel

**Generation Prompt:**  
`pixel art emote sheet for town resident street-life reactions, warm small-town football community mood, simple readable cues for wave chat notice pride surprise and gather, broad calm shapes, cream and gold primary colors with restrained red green blue accents, inviting management sim style, community presence, clean silhouettes and honest emotion`  
`--no meme emotes --no angry comic bursts --no neon streamer graphics --no confetti overload --no chrome badges --no chaotic particles`

**Status:** Needed
