# Asset Specs — pack: Celebration and Feedback

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/match-competition-system.md`, `design/gdd/league-competition-structure-system.md`, `design/art/art-bible.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 4 assets specced / 4 approved / 0 in production / 0 done

## ASSET-092 — Confetti Burst VFX Sheet

| Field | Value |
|-------|-------|
| Category | VFX / Sheet |
| Dimensions | 建议 `64×64` cell；8 帧 one-shot；总图约 `512×64 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `vfx_confetti_burst_64grid.png` |
| Polycount | N/A |
| Texture Res | Celebration VFX tier；建议并入 `atlas_vfx_celebration_core_512.png` |

**Visual Description:**  
彩带爆发应像温暖、明确、值得庆祝的胜利反馈，用奶油、金和少量红形成清楚的块状喷发，而不是碎纸噪声风暴。它承担的是“高兴、被认可、向前推进”的瞬时情绪，而不是炫技特效。  

**Art Bible Anchors:**
- §2
- §4
- §7
- §8
- §9

**Generation Prompt:**  
`pixel art confetti burst, warm cream gold red, joyful readable chunks, championship celebration, cozy football town reward feedback, low-noise one-shot effect`  
`--no neon chaos --no glitter storm --no smoke cloud --no explosive violence`

**Status:** Needed

## ASSET-093 — Fireworks Burst VFX Sheet

| Field | Value |
|-------|-------|
| Category | VFX / Sheet |
| Dimensions | 建议 `96×96` cell；6 帧 one-shot；总图约 `576×96 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `vfx_fireworks_burst_96grid.png` |
| Polycount | N/A |
| Texture Res | Celebration VFX tier；建议并入 `atlas_vfx_celebration_core_512.png` 或独立不超过 `1024 px` |

**Visual Description:**  
烟花应只用于高峰庆祝场景，形状更偏花束、圆弧和绽放，而不是战争爆炸或夜店灯光。它需要让庆祝显得盛大，但仍然属于这个温暖像素小镇的情绪上限。  

**Art Bible Anchors:**
- §2
- §4
- §7
- §8
- §9

**Generation Prompt:**  
`pixel art fireworks burst for cozy football celebration, warm gold and soft red arcs, festive not violent, readable night sky effect, small-town championship joy`  
`--no war explosion --no neon rave effect --no giant smoke plume`

**Status:** Needed

## ASSET-094 — Result Outcome Badge Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / Badge Set |
| Dimensions | 建议 `48×48` cell；6 格预留；总图约 `288×48 px` 或 `144×96 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_result_outcome_badge_48grid.png` |
| Polycount | N/A |
| Texture Res | Match feedback UI tier；建议并入 `atlas_ui_match_feedback_512.png` |

**Visual Description:**  
胜/平/负徽章应和现有 crest / icon 系统一脉相承，用轮廓、边框重量和内部结构区分结果，而不是只靠红绿切换。它的语气应该偏复盘与定格，而不是手机成就徽章式的夸张炫耀或惩罚。  

**Art Bible Anchors:**
- §1
- §3.3
- §4
- §7
- §8

**Generation Prompt:**  
`pixel art result outcome badge set, win draw loss, warm readable UI badges, shape-first differentiation, cream slate gold red-brown restrained palette, reflective football management tone`  
`--no mobile achievement shine --no neon victory flame --no punitive failure iconography`

**Status:** Needed

## ASSET-095 — Formation Position Marker Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / Marker Set |
| Dimensions | 建议 `24×24` cell；7–8 格（base_default / selected / locked + role pips）；总图约 `192×24 px` 或 `96×48 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_formation_position_marker_24grid.png` |
| Polycount | N/A |
| Texture Res | Match feedback UI tier；建议并入 `atlas_ui_match_feedback_512.png` |

**Visual Description:**  
阵型位置标记应像战术板上的安静标记件，而不是电竞 HUD reticle。轮廓要厚实、稳定，留出头像/号码/文本叠加空间，让位置识别来自结构和轻量角色 pip，而不是复杂符号堆叠。  

**Art Bible Anchors:**
- §3.3
- §3.4
- §4
- §7
- §8

**Generation Prompt:**  
`pixel art formation position markers for football management UI, calm readable pitch overlays, rounded stable base markers, role pips, warm clean interface style, tactic-board feeling, no sci-fi HUD`  
`--no neon rings --no radar reticles --no broadcast sports chrome`

**Status:** Needed
