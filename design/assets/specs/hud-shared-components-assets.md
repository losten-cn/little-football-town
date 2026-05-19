# Asset Specs — pack: HUD Shared Components

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/main-loop-ui-framework.md`, `design/gdd/league-competition-structure-system.md`, `design/gdd/time-and-season-progression-system.md`, `design/art/art-bible.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 4 assets specced / 4 approved / 0 in production / 0 done

## ASSET-096 — Shared Soft Panel Skin Kit

| Field | Value |
|-------|-------|
| Category | UI / 9-slice / Panel Skin Kit |
| Dimensions | 4 个基础壳体：`compact 24h`、`standard 32h`、`emphasis 32h`、`inset 24h`；统一按 9-slice authoring |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `hud_panel_soft_compact_24h.png`、`hud_panel_soft_standard_32h.png`、`hud_panel_soft_emphasis_32h.png`、`hud_panel_soft_inset_24h.png` |
| Polycount | N/A |
| Texture Res | HUD stylebox tier；建议通过 Theme / StyleBoxTexture 统一复用 |

**Visual Description:**  
这组共享面板壳体应像“小镇公告牌”和“温暖搪瓷标牌”的折中版：奶油底、石板灰边、极轻内外层次，圆角稳定、留白宽松。它服务跨 screen 的信息容器一致性，让 HUD 和管理界面看起来像同一个世界的整洁管理层。  

**Art Bible Anchors:**
- §3.3
- §4
- §7
- §8

**Generation Prompt:**  
`pixel art UI panel skin kit for a cozy football town management sim, warm cream enamel-noticeboard hybrid, rounded rectangle, calm slate border, minimal ornament, clean 9-slice-ready corners and edges, subtle gold emphasis variant, bright trustworthy management UI`  
`--no glossy mobile bevels --no dark dashboard --no sci-fi HUD --no metallic chrome`

**Status:** Needed

## ASSET-097 — Phase Label Chip Set

| Field | Value |
|-------|-------|
| Category | UI / 9-slice / Label Chip Set |
| Dimensions | 建议 4 个语义壳体：`neutral / scheduled / active / settled`；统一 `24h`；按 9-slice authoring |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `hud_chip_phase_neutral_24h.png`、`hud_chip_phase_scheduled_24h.png`、`hud_chip_phase_active_24h.png`、`hud_chip_phase_settled_24h.png` |
| Polycount | N/A |
| Texture Res | HUD stylebox tier；运行时文本填充，不烘焙文字 |

**Visual Description:**  
阶段标签应比 banner 更轻、比按钮更静，像贴在面板上的小型分类签。它们用于日期、赛季阶段与比赛阶段的共享视觉语法，靠轮廓、边框与轻度色彩重心区分状态，而不是靠大块高饱和度色条。  

**Art Bible Anchors:**
- §3.3
- §3.4
- §4
- §7

**Generation Prompt:**  
`pixel art UI label chip set for season phase and match phase labels, soft rounded capsule and plaque hybrids, cream and slate base with restrained blue gold red semantic trims, tiny HUD readability, cozy management sim, 9-slice-friendly`  
`--no neon tags --no hard-edged esports tabs --no glossy candy UI`

**Status:** Needed

## ASSET-098 — State / Warning Banner Set

| Field | Value |
|-------|-------|
| Category | UI / Banner Kit |
| Dimensions | base shell 建议 `compact 24h`、`standard 32h`；accent strip 4 态：`info / success / warning / blocking` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `hud_banner_base_compact_24h.png`、`hud_banner_base_standard_32h.png`、`hud_banner_accent_info_24h.png`、`hud_banner_accent_success_24h.png`、`hud_banner_accent_warning_24h.png`、`hud_banner_accent_blocking_24h.png` |
| Polycount | N/A |
| Texture Res | HUD component tier；base shell 走 9-slice，accent strip 作为独立组件叠加 |

**Visual Description:**  
状态条幅应表现为“温和但明确的提醒”，而不是惩罚式警报。通过底壳稳定结构加上语义 accent 条来区分信息、成功、警示和阻断状态，让提醒既清楚又符合小镇管理界面的整体温度。  

**Art Bible Anchors:**
- §1
- §4
- §7
- §8
- §9

**Generation Prompt:**  
`pixel art UI state banner set for a warm football town management HUD, horizontal notice strips with info success caution blocked variants, shape cues and border treatment not color alone, cream slate base with restrained blue green gold red accents, calm civic readability`  
`--no alarm siren graphics --no hazard stripes dominance --no neon warning UI`

**Status:** Needed

## ASSET-099 — Season Progress Indicator Skin

| Field | Value |
|-------|-------|
| Category | UI / Progress Skin Kit |
| Dimensions | 组件式：`track 16h`、`fill 16h`、`marker_current 16`、`marker_matchday 16`、`marker_season_end 16` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `hud_progress_track_neutral_16h.png`、`hud_progress_fill_gold_16h.png`、`hud_progress_marker_current_16.png`、`hud_progress_marker_matchday_16.png`、`hud_progress_marker_season_end_16.png` |
| Polycount | N/A |
| Texture Res | HUD progress tier；track/fill 可 theme 复用，marker 由数据驱动摆位 |

**Visual Description:**  
赛季进度皮肤不应是通用 RPG 血条，而更像一条带节奏节点的赛季时间轴。底轨稳定、已推进部分温暖、关键节点清楚，让玩家感到“赛季正在向前”，而不是“资源在被消耗”。  

**Art Bible Anchors:**
- §1
- §4
- §7
- §8

**Generation Prompt:**  
`pixel art season progress indicator skin for a cozy football management sim, horizontal schedule-like progress track with milestone sockets, cream base, slate structure, restrained town gold fill, calm blue neutral markers, warm readable HUD`  
`--no futuristic segmented bar --no glossy meter --no cold corporate dashboard`

**Status:** Needed
