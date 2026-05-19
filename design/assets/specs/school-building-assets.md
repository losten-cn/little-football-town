# Asset Specs — entity: School Building

> **Source**: `design/assets/entity-inventory.md`, `design/art/art-bible.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 2 assets specced / 2 approved / 0 in production / 0 done

## ASSET-071 — School Building Facade Variant Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 基础网格 `16×16`；逻辑占地 `96×64`（6×4 tile）；渲染盒 `112×80`；建议 3 个变体（约 `336×80 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_school_building_facade_sheet.png` |
| Polycount | N/A |
| Texture Res | Town civic landmark tier；建议并入 `town_civic_landmarks` atlas |

**Visual Description:**  
学校应读成朴素、可靠、对孩子友好的社区建筑，以整齐窗列、稳重入口、温暖墙面和轻度公共建筑标识来建立识别。它需要让人自然联想到“孩子们从这里走向球场”，而不是联想到制度压迫或大型校园。  

**Art Bible Anchors:**
- §3.2
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art small-town school building facade, modest civic architecture, cream walls, brick base, regular windows, friendly and nurturing, readable low-rise silhouette, community football town, hopeful youth atmosphere`  
`--no cold institution --no hospital vibe --no urban mega campus --no concrete brutalism`

**Status:** Needed

## ASSET-072 — School Entry / Yard / Youth Community Set

| Field | Value |
|-------|-------|
| Category | Sprite / Environment |
| Dimensions | 基础 cell `16×16`；建议 `128×64 px` sheet，可覆盖入口围栏、公告栏、自行车架、迷你球门、场地线和路标 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `prop_school_entry_yard_set_sheet.png` |
| Polycount | N/A |
| Texture Res | Civic props small tier；建议与 training/youth 相关 props 共享 cell family |

**Visual Description:**  
这组资产负责把学校和青训体系连接起来，包括校门、围栏、公告栏、自行车架、迷你球门、青少年海报、长椅和小型运动点缀。它应表达“课后活动空间”和“孩子们向足球靠近”的情绪，而不是独立的大型体育场地。  

**Art Bible Anchors:**
- §3.4
- §4
- §6
- §8
- §9

**Generation Prompt:**  
`pixel art school community props, backpacks, ball bag, mini goal, youth posters, bench, local club noticeboard, bike stand, fence, painted yard lines, hopeful football aspiration, cozy small-town life, low-noise readability`  
`--no commercial sports academy branding --no cluttered playground chaos --no harsh institutional signage`

**Status:** Needed
