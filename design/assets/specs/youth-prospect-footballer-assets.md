# Asset Specs — entity: Youth Prospect Footballer

> **Source**: `design/assets/entity-inventory.md` (#2), `design/gdd/player-development-system.md`, `design/gdd/town-building-system.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 6 assets specced / 6 approved / 0 in production / 0 done

## ASSET-018 — Youth Prospect Base Sprite Sheet

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | `24×32` 单帧；按动作族拆分图集，单张建议不超过 `256×256 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_youth_prospect_base_idle_small.png`、`char_youth_prospect_base_walk_small.png` |
| Polycount | N/A |
| Texture Res | Character small tier；每帧保留约 `2 px` 透明 padding |

**Visual Description:**  
青训候选球员首先应被读成“本地学院苗子”而不是成熟明星：圆润头部、紧凑比例、清晰袜子与短裤分离、姿态略前倾但不张扬。整体造型应显得健康、可塑、有希望，但仍保留“尚未定型”的青涩感。配色以奶油、柔和红、平静蓝、成长绿与石板阴影组织，避免过度装饰。  

**Art Bible Anchors:**
- §3.1 Character Silhouette Philosophy  
- §3.5 Practical Pixel-Art Rules  
- §4 Primary Semantic Palette  
- §5 Archetype Direction  
- §5 Pixel Readability and LOD Philosophy

**Generation Prompt:**  
`pixel art character sprite sheet, youth football prospect from a warm small-town academy, local talent not a superstar, readable silhouette first, rounded head, compact athletic body, broad calm shapes, minimal ornament, slightly forward hopeful posture, simple shorts socks boots training wear, inviting football town style, warm cream and town gold foundation with restrained club red, calm blue, field green accents, slate outlines, clean value grouping, soft sturdy proportions, charming management sim aesthetic, lived-in and human, coherent frame-to-frame pose clarity`  
`--no neon colors --no chrome --no esports styling --no celebrity swagger --no spiky anime hair --no oversized muscles --no dense accessory clutter --no photoreal rendering --no glossy lighting`

**Status:** Needed

## ASSET-019 — Youth Prospect Portrait Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 主档 `64×64`；仅在详情页需要新增像素细节时再交付 `128×128` detail 版 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `portrait_youth_prospect_neutral_standard.png`、`portrait_youth_prospect_neutral_detail.png` |
| Polycount | N/A |
| Texture Res | Portrait standard tier；保持统一裁切与视线高度 |

**Visual Description:**  
肖像应强调“潜力可期的年轻人”：略带紧张、期待、专注或羞涩自豪的神情，比成年主力更青涩。脸部块面保持温和易读，只允许少量发型与个性特征来区分候选人，避免把每个角色都画成高戏剧性主角。整体气质应服务“值得培养”的长期投入感。  

**Art Bible Anchors:**
- §1 Visual Identity Statement  
- §4 Semantic Usage Rules  
- §5 Expression and Pose Style  
- §5 Character Detail Limits

**Generation Prompt:**  
`pixel art portrait set of youth football prospects, warm approachable small-town academy candidates, local talent with future potential, soft face shapes, readable expressions like hopeful focused shy-proud determined, modest athletic styling, minimal ornament, broad clean color blocks, cream and warm gold base, restrained red blue green accents, slate shadow control, inviting management sim portrait style, grounded and human, consistent roster identity`  
`--no celebrity fashion --no heavy makeup --no hyper-dramatic rage --no smug superstar confidence --no neon rim light --no gritty realism --no excessive facial detail --no esports broadcast energy`

**Status:** Needed

## ASSET-020 — Youth Prospect Kit Variant Set

| Field | Value |
|-------|-------|
| Category | Sprite / 2D Art |
| Dimensions | 与 Base 完全同布局：`24×32` frame box；各动作族单张建议不超过 `256×256 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `char_youth_prospect_kit-home_small.png`、`char_youth_prospect_kit-away_small.png`、`char_youth_prospect_kit-training_small.png` |
| Polycount | N/A |
| Texture Res | 优先使用 overlay / palette 复用，不建议整套 full duplicate atlas |

**Visual Description:**  
青训球员的服装变体应传达“学院成长路径”而不是“商业化球星包装”。保持同一轮廓与帧布局，只通过练习背心、训练服、清爽比赛服与少量色块区分使用场景。奶油是呼吸空间，金色代表期望，红色代表足球归属，绿色代表成长，蓝色代表纪律与结构。  

**Art Bible Anchors:**
- §3.1 Character Silhouette Philosophy  
- §4 Primary Semantic Palette  
- §4 Semantic Usage Rules  
- §5 Costume and Accessory Rules  
- §9 Style Prohibitions

**Generation Prompt:**  
`pixel art youth football kit variant set, academy candidate uniforms for a warm football town, simple readable sportswear, broad calm shapes, minimal ornament, cream base with restrained town gold, club red, calm blue, and field green variant accents, practical shorts socks boots training bibs light warmup layers, cared-for and aspirational not elite or flashy, inviting management sim style, silhouette-first design, gentle local club identity`  
`--no sponsor-wall clutter --no luxury fashion sportswear --no sharp esports jersey graphics --no flame or lightning motifs --no chrome trims --no oversized logos --no neon gradients`

**Status:** Needed

## ASSET-021 — Youth Prospect Potential Tier Badge Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 严格使用 `16×16` / `24×24` / `32×32` 三档；每个潜力层级各一套 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_youth_prospect_potential-a_16.png`、`ui_youth_prospect_potential-a_24.png`、`ui_youth_prospect_potential-a_32.png` |
| Polycount | N/A |
| Texture Res | Native-authored 三档，不允许从单一母版缩放导出 |

**Visual Description:**  
潜力徽章应像“社区学院认可标”而不是残酷竞技排位勋章。可使用平静的圆牌、丝带、星点、嫩芽或足球生长意象来区分层级，越高阶越明亮清晰，但重点始终是“值得培育的未来”，而不是“碾压别人”。层级差异必须依赖轮廓与结构，而不是仅靠颜色。  

**Art Bible Anchors:**
- §3.3 UI Shape Grammar  
- §3.4 Hero Shapes vs Supporting Shapes  
- §4 Semantic Usage Rules  
- §7 Iconography Style  
- §9 Local football club posters / community noticeboards

**Generation Prompt:**  
`pixel art badge set for youth prospect potential tiers, warm football town academy identity, simple silhouette-first icons, calm shield circle ribbon and star motifs, optional sprout or football-growth symbolism, cream and gold progression with restrained red blue green semantic accents, slate outlines, broad readable shapes, minimal ornament, optimistic and inviting, community sports noticeboard feel, clear tier distinction through value and shape simplicity`  
`--no sharp metallic rank crests --no chrome --no flaming wings --no skull motifs --no neon glow --no militaristic insignia --no hyper-ornate heraldry --no dark prestige visuals`

**Status:** Needed

## ASSET-022 — Youth Prospect Growth Pulse FX

| Field | Value |
|-------|-------|
| Category | VFX / Particles |
| Dimensions | 默认 `32×32` 单帧；`6–8` 帧，单张建议不超过 `256×128 px`；仅在近景 UI 需要时增补 `64×64` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `vfx_youth_prospect_growth-pulse_small.png`、`vfx_youth_prospect_growth-pulse_medium.png` |
| Polycount | N/A |
| Texture Res | Gameplay/UI VFX small tier；alpha 边界保持紧凑，避免 overdraw |

**Visual Description:**  
成长脉冲特效应表现“进步正在发生”，而不是“爆发式升级压制”。建议采用温暖向外扩散的微脉冲、轻金色火花或带一点足球/嫩芽意象的成长闪烁，让玩家感到被鼓励、被看见。它应传达长期成长的安静喜悦，而非夸张的 power-up。  

**Art Bible Anchors:**
- §1 Principle 3: Always Forward  
- §4 Celebration color guidance  
- §7 Animation Feel  
- §8 Palette and Value Discipline

**Generation Prompt:**  
`pixel art growth pulse visual effect for youth football prospect improvement, warm inviting academy progression effect, gentle outward pulse, soft glow rings, small spark clusters, subtle football and growth symbolism, cream and town gold core, field green support, restrained blue-slate shadow balance, readable and calm, optimistic long-term development mood, minimal clutter, clean value steps, management sim feedback effect`  
`--no neon bloom --no lightning bursts --no fire explosions --no anime power-up aura --no chrome particles --no huge shockwaves --no dense particle noise --no aggressive red dominance`

**Status:** Needed

## ASSET-023 — Youth Prospect Recruitment Reveal Emote Sheet

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | `16×16` 单帧；建议 `6–8` 帧；单张建议不超过 `128×64 px`；特殊强调场景可选 `24×24` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_youth_prospect_reveal-interest_16.png`、`ui_youth_prospect_reveal-surprise_16.png`、`ui_youth_prospect_reveal-rare_24.png` |
| Polycount | N/A |
| Texture Res | Small icon/emote tier；固定 cell slicing，底部居中对齐便于头顶挂载 |

**Visual Description:**  
招募揭示表情应表达“发现好苗子”的小镇喜悦：轻微惊喜、希望、公告板弹出、握手、小型足球符号或成长提示都可以。它不是大张旗鼓的抽卡演出，而是社区在悄悄地为一个未来可塑的人才感到高兴。应保持真诚、轻快、易读。  

**Art Bible Anchors:**
- §1 Visual Identity Statement  
- §3.3 UI Shape Grammar  
- §4 Semantic Usage Rules  
- §7 Iconography Style  
- §7 Animation Feel

**Generation Prompt:**  
`pixel art emote sheet for youth football prospect recruitment reveal, warm small-town academy mood, simple readable icons and reactions, hopeful surprise and discovery, subtle football ball motif, noticeboard pop, handshake, spark, growth cue, broad calm shapes, minimal ornament, cream and gold primary colors with restrained red and green accents, slate outlines, inviting management sim style, community pride, long-term growth fantasy, clean silhouettes`  
`--no angry comic emotes --no meme exaggeration --no neon streamer graphics --no confetti overload --no sharp explosive symbols --no dark-background esports UI --no chrome badges --no chaotic particles`

**Status:** Needed
