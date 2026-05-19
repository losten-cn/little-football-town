# Asset Specs — pack: Match UI Components

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/match-performance-ui.md`, `design/gdd/match-competition-system.md`, `design/art/art-bible.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 2 assets specced / 2 approved / 0 in production / 0 done

## ASSET-100 — Match Scoreboard Skin

| Field | Value |
|-------|-------|
| Category | UI / Composite Scoreboard Kit |
| Dimensions | 建议组件化：`outer_frame_live 32h`、`outer_frame_result 48h`、`team_slot 24h`、`score_core 24h`、可选 `divider` 小件 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `match_scoreboard_frame_live_32h.png`、`match_scoreboard_frame_result_48h.png`、`match_scoreboard_slot_team_24h.png`、`match_scoreboard_core_score_24h.png`、`match_scoreboard_divider_center_24h.png` |
| Polycount | N/A |
| Texture Res | Match UI composite tier；建议做成复用 Control 组件，而非单张死图 |

**Visual Description:**  
比分牌是少数需要“中心英雄形”的 HUD 部件，比分数字优先级必须压过 crest 和修饰。它应像球场公告牌或主场公示牌，清楚、可信、温暖，比电视转播图层更像这个小镇自己的比赛界面。  

**Art Bible Anchors:**
- §3.4
- §4
- §7
- §8

**Generation Prompt:**  
`pixel art football match scoreboard skin for a warm small-town management sim, symmetrical home-away plaque with bold central score area, civic stadium noticeboard feeling, cream and slate structure, restrained gold and club red emphasis, clear crest slots, high readability`  
`--no TV broadcast chrome --no neon HUD --no metallic gloss --no esports overlay`

**Status:** Needed

## ASSET-101 — Result Cause Tag Shell Set

| Field | Value |
|-------|-------|
| Category | UI / 9-slice / Tag Shell Set |
| Dimensions | 建议 4 个语义壳体：`positive / neutral / warning / negative`；统一 `24h`；按 9-slice authoring |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `match_tag_cause_positive_24h.png`、`match_tag_cause_neutral_24h.png`、`match_tag_cause_warning_24h.png`、`match_tag_cause_negative_24h.png` |
| Polycount | N/A |
| Texture Res | Match UI stylebox tier；文本运行时填充，左侧预留 icon socket |

**Visual Description:**  
赛果原因标签应像赛后分析里的一组温和标签壳，而不是新的徽章系统。它们服务“为什么赢、为什么平、为什么输”的解释层，通过统一外壳和语义层次让分析更整洁、更容易扫读。  

**Art Bible Anchors:**
- §3.3
- §4
- §7
- §8

**Generation Prompt:**  
`pixel art UI cause tag shell set for post-match summary, compact rounded chips with left icon socket and right text space, cream slate base with restrained semantic trims, cozy analytic football UI, clean reusable stylebox family`  
`--no mobile candy gloss --no spreadsheet coldness --no neon labels`

**Status:** Needed
