# Asset Specs — entity: Corner Shop

> **Source**: `design/assets/entity-inventory.md`, `design/art/art-bible.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 2 assets specced / 2 approved / 0 in production / 0 done

## ASSET-067 — Corner Shop Facade Variant Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 基础网格 `16×16`；逻辑占地 `64×48`（4×3 tile）；渲染盒 `80×64`；建议 4 个变体（约 `320×64 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_corner_shop_facade_sheet.png` |
| Polycount | N/A |
| Texture Res | Town commerce facade tier；建议与 Café 共用 commerce atlas |

**Visual Description:**  
街角商铺应读成社区日常补给点，有清晰的转角门脸、橱窗和简洁雨棚。它比住宅更有展示性，但仍然要保持小镇尺度和手工气息，避免连锁商业或高压零售感。  

**Art Bible Anchors:**
- §3.2
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art corner shop facade, small-town storefront, corner awning, display window, warm cream and town-gold palette, community retail, readable silhouette, low-noise, local football-town identity`  
`--no chain-store gloss --no neon signage --no harsh modern retail facade`

**Status:** Needed

## ASSET-068 — Corner Shop Signage / Streetfront Set

| Field | Value |
|-------|-------|
| Category | Sprite / Environment |
| Dimensions | façade overlay 单帧 `80×64`；建议 4 帧内状态变化；另含 `16×16` 街前 props，可合并为 `128×64 px` 级别 sheet |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_corner_shop_signage_overlay_sheet.png`、`prop_corner_shop_frontage_set_sheet.png` |
| Polycount | N/A |
| Texture Res | Commerce props tier；控制 overlay 仅在必要时启用 |

**Visual Description:**  
这一组负责门头招牌、价格黑板、货箱、报刊架、海报框等街前要素，让商铺既能做变体也能自然融入足球文化。视觉上应强调“邻里商业”而不是“广告密度”，让足球元素像社区生活的一部分而不是硬贴主题。  

**Art Bible Anchors:**
- §3.4
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art corner shop street props, hanging sign, chalk price board, crates, news rack, drinks box, local club poster, cozy civic football culture, clear clustered shapes, small-town retail warmth`  
`--no ad clutter --no harsh commercial branding --no sponsor wall overload`

**Status:** Needed
