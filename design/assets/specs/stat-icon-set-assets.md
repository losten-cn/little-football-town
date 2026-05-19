# Asset Specs — entity: Stat Icon Set

> **Source**: `design/assets/entity-inventory.md` (#38), `design/gdd/balance-system.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 3 assets specced / 3 approved / 0 in production / 0 done

## ASSET-001 — Stat Icon Core Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 单图分别交付 `16×16` / `24×24` / `32×32` 三档；5 枚图标，共 15 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_spd_core_16.png`、`ui_pwr_core_24.png`、`ui_tec_core_32.png` 等 |
| Polycount | N/A |
| Texture Res | 使用 UI 图标标准阶梯 `16 / 24 / 32 px`（Art Bible §8） |

**Visual Description:**  
这是一组用于 `SPD / PWR / TEC / INT / STA` 的五维属性基础图标，必须先通过轮廓而不是颜色被识别。整体风格要温暖、克制、可读，带有小镇足球经营的亲和感，但比世界内美术更干净、更高对比。  
建议的轮廓方向为：`SPD` 用前倾鞋/速度刻线，`PWR` 用厚实手臂，`TEC` 用控球感足球，`INT` 用侧头轮廓+节点，`STA` 用耐力感心形/环形符号；每个图标控制在“一个主形 + 一个辅助提示”以内。

**Art Bible Anchors:**
- §3.3 Shape Language: UI 使用宽大、平静、易点读的形体，不使用尖锐或花哨装饰
- §3.5 Practical Pixel-Art Rules: silhouette first，big readable masses over micro-texture
- §4 Color System: 颜色只做助记，不可单独承载语义
- §7 Iconography Style: 简洁、轮廓优先、实用型 icon，而非激进体育转播风
- §8 Asset Standards: UI icon 严格使用 `16 / 24 / 32 px` 阶梯，PNG，pixel-clean

**Generation Prompt:**  
`pixel art UI icon set for a cozy football town management game, five attribute icons SPD PWR TEC INT STA, silhouette-first readability, broad calm shapes, minimal ornament, warm and friendly but clean UI, cream #F2E8D5, slate neutral #4C4A4A outlines, restrained accents from town gold #D6B35A, calm blue #5E7FA3, field green #6F8F5B, centered icons on transparent background, nearest-neighbor pixel art, high readability at 16x16 24x24 32x32, Kairosoft-inspired micro readability, softer than pro sports branding --no neon, no chrome, no glossy esports badge, no dense texture, no tiny line clutter, no cold corporate UI`

**Technical Constraints:**
- 禁止从大图缩小导出，必须按原生尺寸分别制作
- Godot 导入要求：nearest filtering、mipmaps off、repeat off
- UI 使用时避免 fractional scaling，优先直接使用对应尺寸资源

**Status:** Needed

## ASSET-002 — Stat Icon Badge Variant Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 单图分别交付 `16×16` / `24×24` / `32×32` 三档；5 枚图标，共 15 张 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_spd_badge_16.png`、`ui_int_badge_24.png`、`ui_sta_badge_32.png` 等 |
| Polycount | N/A |
| Texture Res | 使用 UI 图标标准阶梯 `16 / 24 / 32 px`（Art Bible §8） |

**Visual Description:**  
这是同一组五维图标的“徽章底托版”，用于高密度列表、摘要 chip、紧凑型属性行。每个图标放在统一的圆角方形或柔和徽章容器内，外轮廓一致，仅通过内部符号和少量强调色区分属性。  
徽章不应做成金属奖章或电竞按钮，而应更像整洁的俱乐部标识牌：奶油色/柔和深灰底，轻边框，弱材质感，核心目标仍是密集界面中的一眼可读。

**Art Bible Anchors:**
- §3.3 UI Shape Grammar: 面板/按钮使用稳定、宽大、低装饰的容器语言
- §4 UI Palette + Colorblind Safety: 用形状、边框、明度共同区分，不依赖颜色单独识别
- §7 Panel, Frame, and Button Style: 轻柔边角、克制边框、读数优先
- §8 Outline, Padding, and Detail Rules: 统一 padding，减少微小纹理噪声

**Generation Prompt:**  
`pixel art UI badge icon set for football management sim, five stat badges SPD PWR TEC INT STA, rounded-square compact containers, centered simple icons, warm civic enamel-plaque feeling, cream #F2E8D5 panel, slate neutral #4C4A4A border, restrained accent colors, clean readable 16x16 24x24 32x32 pixel art, high-density UI row friendly, soft corners, minimal ornament, transparent background, nearest-neighbor style --no metallic gloss, no bevel-heavy app icon, no esports shield, no heavy shadows, no ornate crest frame, no cold spreadsheet UI`

**Technical Constraints:**
- 徽章容器必须 baked 进纹理，不依赖运行时缩放组合来保证像素稳定性
- 16 px 版本若容器+符号过密，应优先简化内部图标，而不是缩小 24/32 px 版本

**Status:** Needed

## ASSET-003 — Stat Icon Sprite Sheet Packaging

| Field | Value |
|-------|-------|
| Category | UI / Packaging / Sprite Sheet |
| Dimensions | 建议统一图集 `160×192 px`，`5 列 × 6 行`，每格 `32×32 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_stat_icons_sheet_32grid.png` |
| Polycount | N/A |
| Texture Res | 包装图集使用 32px 网格承载 16/24/32 三档资产 |

**Visual Description:**  
这不是新图标，而是整组资源的统一打包规范。图集中所有图标必须共享一致的视觉中心、描边粗细、阴影逻辑和内边距，这样整组放在同一行里时会读成一个平静、可信的系统，而不是五种互不相关的小图。  
当整张 sheet 被查看时，最重要的是“家族一致性”：同样的容器逻辑、同样的高光方向、同样的体块复杂度，只在属性轮廓上做区分。

**Art Bible Anchors:**
- §3.4 Hero vs Supporting Shapes: 不让任何单一属性因包装偏移而意外抢视觉
- §7 Maintain World Identity Without Losing Readability: UI 统一、整洁、可信
- §8 Pixel-Perfect Scaling + Atlas Discipline: 固定网格、统一 padding、便于 Godot slicing

**Generation Prompt:**  
`pixel art UI sprite sheet layout for five football management stat icons, cohesive icon family packaging, exact 32x32 grid, equal padding, identical optical centering, same outline weight, same highlight direction, calm readable warm UI system, cream and slate-led palette with restrained accent colors, transparent background, production-ready atlas presentation, nearest-neighbor pixel art --no uneven offsets, no inconsistent shadows, no style drift, no decorative frame, no texture noise`

**Technical Constraints:**
- 建议行序：`core_16`、`core_24`、`core_32`、`badge_16`、`badge_24`、`badge_32`
- 建议列序：`SPD | PWR | TEC | INT | STA`
- 16/24 px 图标在 `32×32` 格内做整像素居中
- Godot 中按固定 `32×32` region slicing；关闭 filtering 和 mipmaps
- 当前内存占用极小，无性能冲突

**Status:** Needed

## Family Guidance

### Suggested silhouette mapping
- `SPD`：前倾鞋 / 速度刻线
- `PWR`：厚实手臂
- `TEC`：控球足球 / 精准触球符号
- `INT`：侧头 + 战术节点
- `STA`：心形 + 耐力环

### Suggested accent mapping
- `SPD`：Calm Blue
- `PWR`：Town Gold
- `TEC`：Field Green 或 Calm Blue
- `INT`：Calm Blue
- `STA`：Field Green

> 这些颜色只作为辅助记忆；最终识别必须先靠轮廓成立。