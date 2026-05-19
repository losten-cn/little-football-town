# Asset Specs — entity: Team Crest / Club Badge

> **Source**: `design/assets/entity-inventory.md` (#37), `design/gdd/league-competition-structure-system.md`, `design/gdd/main-loop-ui-framework.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 4 assets specced / 4 approved / 0 in production / 0 done

## ASSET-008 — Team Crest Core Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 单图分别交付 `16×16` / `24×24` / `32×32` 三档；基础主徽章 1 套（主队）共 3 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_crest_core_16.png`、`ui_crest_core_24.png`、`ui_crest_core_32.png` |
| Polycount | N/A |
| Texture Res | 使用 UI 图标标准阶梯 `16 / 24 / 32 px`（Art Bible §8） |

**Visual Description:**  
主徽章用于俱乐部身份锚定，需在小尺寸下先靠轮廓识别“盾形/牌形+内部单一主符号”，再由颜色辅助记忆。风格应与 Stat/Resource 图标家族一致：温暖、克制、信息优先，避免金属高光与电竞锋利感。  
该资产作为 HUD 与菜单中的“身份核心件”，必须在高频视线切换中稳定可读，不抢比分与资源信息焦点。

**Art Bible Anchors:**
- §3.3 UI Shape Grammar：宽大、平静、低装饰轮廓
- §4 Semantic Usage Rules：颜色辅助识别，不单独承载语义
- §7 Iconography Style：实用型高频扫描图标
- §8 Resolution and Size Tiers：严格 `16 / 24 / 32 px`

**Generation Prompt:**  
`pixel art football club crest icon for a cozy small-town management sim, single primary crest silhouette with one simple internal civic symbol, warm and trustworthy identity mark, silhouette-first readability at 16x16 24x24 32x32, cream #F2E8D5 and slate #4C4A4A base with restrained town gold #D6B35A accent, transparent background, nearest-neighbor pixel art, same family as calm stat/resource icons, no metallic shine, no esports aggression, no sharp spikes, no ornate heraldic clutter, no tiny unreadable details`

**Status:** Needed

## ASSET-009 — Team Crest Result Variant Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 单图分别交付 `16×16` / `24×24` / `32×32`；3 状态（`neutral / win_highlight / loss_subdued`），共 9 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_crest_state_neutral_16.png`、`ui_crest_state_win_highlight_24.png`、`ui_crest_state_loss_subdued_32.png` |
| Polycount | N/A |
| Texture Res | 使用 `16 / 24 / 32 px` 阶梯（Art Bible §8） |

**Visual Description:**  
该组用于赛果与赛程节点中的“同一徽章状态反馈”，不是新徽章设计。三状态保持同一主轮廓，仅通过明度、边框强调和极简结构提示区分：`win_highlight` 稍增强可见性，`loss_subdued` 去饱和并弱化填充。  
状态差异必须在灰度下仍可区分，避免仅靠红绿变化。

**Art Bible Anchors:**
- §4 Colorblind Safety：状态不可仅靠颜色
- §7 Accessibility and Input Clarity：反馈状态清晰可读
- §3.5 Practical Pixel-Art Rules：小尺寸避免噪声化提示
- §9 Style Prohibitions：避免侵略性警报视觉

**Generation Prompt:**  
`pixel art club crest state variants for cozy football management UI, same crest silhouette across neutral win-highlight loss-subdued states, communicate state via value shift border treatment and tiny structural cue, not color alone, warm restrained palette, transparent background, readable at 16x16 24x24 32x32, nearest-neighbor crisp pixels, no flashing, no heavy red-green dependency, no clutter, no style drift`

**Status:** Needed

## ASSET-010 — Team Crest Badge Plate Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | `16×16` / `24×24` / `32×32` 三档；徽章底托版 1 套，共 3 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_crest_badge_16.png`、`ui_crest_badge_24.png`、`ui_crest_badge_32.png` |
| Polycount | N/A |
| Texture Res | 使用 `16 / 24 / 32 px` 阶梯（Art Bible §8） |

**Visual Description:**  
用于高密度列表（积分榜、赛程条目、对阵行）的“容器化俱乐部徽章”。底托需延续属性/资源徽章语言，形成统一 HUD 系统感；整体不应像商店按钮或奖章。  
16px 下优先保留轮廓与中轴结构，必要时简化内部符号而非缩放复制。

**Art Bible Anchors:**
- §3.3 UI Shape Grammar：统一容器语言
- §7 Panel, Frame, and Button Style：柔和边角、读数优先
- §8 Outline, Padding, and Detail Rules：统一 padding 与描边
- §7 Maintaining World Identity Without Losing Readability：小镇感 + UI 清洁度

**Generation Prompt:**  
`pixel art club crest badge for compact football management UI rows, rounded-square plaque container with centered crest symbol, warm civic signboard mood, cream panel #F2E8D5, slate border #4C4A4A, restrained town gold accents #D6B35A, highly readable at 16x16 24x24 32x32, transparent background, nearest-neighbor pixel art, no glossy app-icon bevels, no esports shield exaggeration, no ornate frame, no texture noise`

**Status:** Needed

## ASSET-011 — Team Crest Sprite Sheet Packaging

| Field | Value |
|-------|-------|
| Category | UI / Packaging / Sprite Sheet |
| Dimensions | 建议图集 `96×288 px`，`3 列 × 9 行`，每格 `32×32 px`（列：core/state/badge；行：尺寸与状态序） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_crest_icons_sheet_32grid.png` |
| Polycount | N/A |
| Texture Res | 统一 `32 px` 网格承载全部变体 |

**Visual Description:**  
该图集用于 Godot 固定网格切分，不新增视觉语义。目标是保证 Team Crest 家族在 HUD、积分榜、赛程、赛果界面中的偏移、重心、描边逻辑完全一致。  
与 `ui_stat_icons_sheet_32grid.png`、`ui_resource_icons_sheet_32grid.png` 并排查看时，应读成同一 UI 体系内的第三个子家族。

**Art Bible Anchors:**
- §8 Pixel-Perfect Scaling Rules：整像素居中、固定网格
- §8 Atlas, Material, and Draw-Call Discipline：便于共享 atlas 批处理
- §3.4 Hero vs Supporting Shapes：包装不导致意外抢视觉
- §7 Consistency Rules：跨界面一致性优先

**Generation Prompt:**  
`pixel art UI sprite sheet packaging for football club crest family, includes core crest, state variants, and badge variant, exact 32x32 carrier grid, equal padding, identical optical centering, consistent outline weight and light direction, warm calm management UI style, transparent background, production-ready nearest-neighbor atlas, same family as stat/resource sheets, no uneven offsets, no mismatched shadows, no decorative framing, no noise`

**Status:** Needed
