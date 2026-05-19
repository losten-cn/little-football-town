# Asset Specs — entity: Resource Icon Set

> **Source**: `design/assets/entity-inventory.md` (#39), `design/gdd/economy-management-system.md`, `design/gdd/balance-system.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 4 assets specced / 4 approved / 0 in production / 0 done

## ASSET-004 — Resource Icon Core Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 单图分别交付 `16×16` / `24×24` / `32×32` 三档；`Funds` 与 `AP` 共 2 枚图标，合计 6 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_funds_core_16.png`、`ui_funds_core_24.png`、`ui_ap_core_32.png` |
| Polycount | N/A |
| Texture Res | 使用 UI 图标标准阶梯 `16 / 24 / 32 px`（Art Bible §8） |

**Visual Description:**  
这是资源组中最基础的一对图标：`Funds` 表示可存储与可支配的经营价值，建议使用厚实、闭合感强的硬币/代币轮廓；`AP` 表示每日行动容量与球队精力，建议使用短小、圆角化的能量符号，而不是尖锐闪电。  
两枚图标必须与现有 `Stat Icon Set` 属于同一家族：相同的描边厚度、相同的光向、相同的视觉中心控制，但语义上更偏“资源/记账”而不是“球员属性”。

**Art Bible Anchors:**
- §3.3 UI Shape Grammar：UI 使用宽大、平静、易读的形体
- §3.5 Practical Pixel-Art Rules：轮廓优先，减少微小噪声
- §4 Semantic Usage Rules：Funds 倾向 Gold，AP 倾向 Calm Blue，但颜色不能独立承载语义
- §7 Iconography Style：实用、清晰、适合高频扫描
- §8 Resolution and Size Tiers：严格使用 `16 / 24 / 32 px`

**Generation Prompt:**  
`pixel art UI resource icon set for a warm football town management sim, two icons only: Funds and AP, same family as a clean cozy stat icon set, Funds as a thick civic coin token with one simple inset stamp, AP as a short rounded energy bolt glyph with softened corners, silhouette-first readability, broad calm shapes, minimal ornament, cream #F2E8D5 and slate #4C4A4A base, Funds accented with town gold #D6B35A, AP accented with calm blue #5E7FA3, transparent background, readable at 16x16 24x24 32x32, nearest-neighbor pixel art, Kairosoft micro-scale clarity, Football Manager information discipline, no cold spreadsheet feel, no chrome, no glossy sports branding, no texture noise, no tiny line clutter`

**Technical Constraints:**
- 必须按 `16 / 24 / 32` 原生尺寸分别制作，不能由大图缩小导出
- Godot 导入要求：nearest filtering、mipmaps off、repeat off
- 16px 下 `Funds` 与 `AP` 必须先靠轮廓区分，不能依赖颜色或微小内细节

**Status:** Needed

## ASSET-005 — Resource Icon Badge Variant Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 单图分别交付 `16×16` / `24×24` / `32×32` 三档；`Funds` 与 `AP` 共 2 枚图标，合计 6 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_funds_badge_16.png`、`ui_ap_badge_24.png`、`ui_funds_badge_32.png` |
| Polycount | N/A |
| Texture Res | 使用 UI 图标标准阶梯 `16 / 24 / 32 px`（Art Bible §8） |

**Visual Description:**  
这是资源图标的徽章底托版，用于高密度资源行、预算摘要、资源成本 chip。外层容器应沿用与属性徽章相同的圆角方牌/标牌语言，让资源组和属性组并排时显得是同一套系统。  
它不应看起来像奖章、商城按钮或电竞徽标，而应像整洁、可信的小镇经营标牌：奶油底、柔和深灰边、克制强调色。

**Art Bible Anchors:**
- §3.3 UI Shape Grammar：统一容器语言、低装饰度
- §4 UI Palette：温暖底色 + 克制强调色
- §7 Panel, Frame, and Button Style：边角柔和、信息优先
- §7 Maintaining World Identity Without Losing Readability：保持小镇感但比世界更干净
- §8 Outline, Padding, and Detail Rules：统一 padding，保持小尺寸清晰

**Generation Prompt:**  
`pixel art UI badge icon set for a cozy football town management sim, two resource badges: Funds and AP, rounded-square plaque containers, centered simple symbols, Funds coin token icon, AP rounded energy bolt icon, warm civic signboard feeling, cream #F2E8D5 panel, slate #4C4A4A border, restrained town gold #D6B35A and calm blue #5E7FA3 accents, silhouette-first readability, compact high-density UI friendly, transparent background, 16x16 24x24 32x32 pixel art, nearest-neighbor, same family as warm stat badges, no metallic gloss, no esports shield, no bevel-heavy app icon, no ornate crest frame, no texture clutter`

**Technical Constraints:**
- 徽章底托必须 baked 进纹理，不依赖运行时拼装以免像素错位
- 16px 版本若底托过度挤占内部可读面积，应优先简化符号而不是缩放 24/32 版本
- 与 `Stat Icon Badge Variant Set` 并排时，不能显得更重、更亮或更复杂

**Status:** Needed

## ASSET-006 — Resource Icon State Variant Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 单图分别交付 `16×16` / `24×24` / `32×32` 三档；2 枚图标 × 3 状态（`normal / warning_low / disabled_insufficient`），合计 18 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_funds_state_normal_16.png`、`ui_funds_state_warning_low_24.png`、`ui_ap_state_disabled_insufficient_32.png` |
| Polycount | N/A |
| Texture Res | 使用 UI 图标标准阶梯 `16 / 24 / 32 px`（Art Bible §8） |

**Visual Description:**  
这组不是新语义图标，而是资源状态反馈版，服务于资源不足、预警、门禁阻止等界面反馈。三个状态必须保留同一基础轮廓，通过**明度变化、边框处理、极小状态提示结构**来区分，而不是仅靠颜色变化。  
`normal` 保持清洁稳定；`warning_low` 增加轻微的提醒结构与更明确的对比；`disabled_insufficient` 需要显著去饱和、减弱填充，并带一个即使在灰度下也能读成“不可用”的结构提示。

**Art Bible Anchors:**
- §4 Semantic Usage Rules：预警允许使用暖色提醒，但不能失控成强侵略性视觉
- §4 Colorblind Safety：必须通过形状/边框/标签而不仅是颜色传达状态
- §7 Accessibility and Input Clarity：状态区别必须清晰
- §3.5 Practical Pixel-Art Rules：小尺寸状态提示不能变成噪声
- §9 Style Prohibitions：避免过强电竞化警报风或强烈红色支配

**Generation Prompt:**  
`pixel art UI resource state icon set for a warm football town management sim, Funds and AP icons with three states each: normal, warning-low, disabled-insufficient, preserve same base silhouettes across states, communicate status with value shift, border treatment, and tiny state cue not color alone, warning state uses warm gold alert tab or ring cue, disabled state uses muted slate and cream, reduced fill, small unavailable mark, broad calm shapes, minimal ornament, highly readable at 16x16 24x24 32x32, transparent background, nearest-neighbor pixel art, cozy clean UI, no aggressive alarm graphics, no flashing effects, no heavy red dominance, no clutter, no tiny unreadable overlays`

**Technical Constraints:**
- 不允许用模糊、发光、低透明度洗色来伪造状态，必须保持 pixel-crisp
- `warning_low` 与 `disabled_insufficient` 在 16px 下也必须可区分
- 这里与 Art Bible“避免不必要重复纹理”存在轻微张力；若生产决定改用 runtime state derivation，应尽早统一，避免返工

**Status:** Needed

## ASSET-007 — Resource Icon Sprite Sheet Packaging

| Field | Value |
|-------|-------|
| Category | UI / Packaging / Sprite Sheet |
| Dimensions | 建议统一图集 `64×480 px`，`2 列 × 15 行`，每格 `32×32 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_resource_icons_sheet_32grid.png` |
| Polycount | N/A |
| Texture Res | 包装图集使用 32px 网格承载所有原生尺寸与状态变体 |

**Visual Description:**  
这是一张资源图标家族的统一打包规范图，不新增语义，只保证整套资源在 Godot 中按固定网格稳定切分。整张图在视觉上必须延续 `Stat Icon Set` 的系统感：同样的重心、同样的边距、同样的光向与描边逻辑。  
资源组与属性组一起使用时，应该像同一个 HUD 设计系统里的两个子家族，而不是独立拼接的素材来源。

**Art Bible Anchors:**
- §3.4 Hero Shapes vs Supporting Shapes：避免个别资源状态版因布局偏差意外抢视觉
- §7 Maintaining World Identity Without Losing Readability：统一、可信、整洁
- §8 Pixel-Perfect Scaling Rules：固定网格，整像素居中
- §8 Atlas, Material, and Draw-Call Discipline：便于共享 UI atlas 与批处理

**Generation Prompt:**  
`pixel art UI sprite sheet packaging for a cozy football town management sim resource icon family, Funds and AP only, cohesive atlas presentation, core icons, badge variants, and state variants, exact 32x32 carrier grid, equal padding, identical optical centering, same outline weight, same light direction, calm warm UI system, cream and slate led palette with restrained town gold and calm blue accents, transparent background, production-ready nearest-neighbor pixel art, same family as stat icon sheet, no uneven offsets, no inconsistent shadows, no style drift, no decorative frame, no texture noise`

**Technical Constraints:**
- 建议列序：`FUNDS | AP`
- 建议行序：
  1. `core_16`
  2. `core_24`
  3. `core_32`
  4. `badge_16`
  5. `badge_24`
  6. `badge_32`
  7. `state_normal_16`
  8. `state_normal_24`
  9. `state_normal_32`
  10. `state_warning_low_16`
  11. `state_warning_low_24`
  12. `state_warning_low_32`
  13. `state_disabled_insufficient_16`
  14. `state_disabled_insufficient_24`
  15. `state_disabled_insufficient_32`
- 所有 `16 / 24 px` 图标在 `32×32` 单元格中整像素居中
- 如外部工具要求 POT 画布，可仅外扩 padding 到 `64×512`，不得改变内部坐标

**Status:** Needed

## Family Guidance

### Suggested resource silhouettes
- `Funds`：闭合代币 / 硬币轮廓
- `AP`：短小圆角能量符号

### Suggested state treatment
- `warning_low`：偏 Gold 的提醒逻辑
- `disabled_insufficient`：偏 Slate / Cream 的灰化逻辑，并辅以结构性 unavailable cue

> 最终识别必须先靠轮廓与结构成立，颜色只做辅助。