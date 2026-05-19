# Asset Specs — entity: Medical Room

> **Source**: `design/assets/entity-inventory.md`, `design/gdd/town-building-system.md`
> **Art Bible**: `design/art/art-bible.md`
> **Generated**: 2026-05-19
> **Status**: 6 assets specced / 6 approved / 0 in production / 0 done

## ASSET-051 — Medical Room Core Structure Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 基础网格 `16×16`；逻辑占地 `64×64`（4×4 tile）；渲染盒 `96×96`；`Lv1–Lv5` 共 5 帧（建议 `480×96 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_medical_room_core_sheet.png` |
| Polycount | N/A |
| Texture Res | World facility small tier；nearest / filter off / mipmap off / repeat off |

**Visual Description:**  
Medical Room 主建筑应读成“俱乐部里被认真照顾的一间恢复小屋”，而不是城市医院科室。它在材质与体量上与 Training Ground 同宗，但通过更柔和的遮阳篷、窗帘、长椅、盆栽与暖色入口灯，把“训练推进成长”对照成“医疗保障恢复”。  

**Art Bible Anchors:**
- §1  
- §3.2  
- §4  
- §6  
- §8  
- §9

**Generation Prompt:**  
`pixel art environment sheet, 3/4 top-down view, cozy football club medical room core structure, small-town recovery annex beside training facilities, warm cream plaster walls, earth-brown wood trim, calm blue awning, small town-gold accents, tiny club-red signage accents, soft curtains, warm windows, bench, planter boxes, notice board, clean silhouette, outline-first, low visual noise, inviting community care, restorative atmosphere, handcrafted and lived-in, readable at small scale, paired visually with a friendly training ground`  
`--no cold hospital --no fluorescent blue lighting --no emergency room --no chrome lab equipment --no sci-fi sports lab --no neon --no blood --no photorealism --no excessive detail noise`

**Status:** Needed

## ASSET-052 — Medical Room Upgrade Overlay Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 单帧 `96×96`；`Lv2–Lv5` 增量 overlay 共 4 帧（建议 `384×96 px`） |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_medical_room_upgrade_overlay_sheet.png` |
| Polycount | N/A |
| Texture Res | 与 ASSET-051 同级；同 pivot 对齐 |

**Visual Description:**  
升级覆盖层不表现为“机器越来越贵”，而表现为“照护越来越周到”。通过更好的遮阴、更多布艺与木作收纳、更整洁的恢复角、更温暖的识别标识与植物，把恢复质量提升表达成支持系统逐步成熟。  

**Art Bible Anchors:**
- §1  
- §3.2  
- §4  
- §6.4  
- §7  
- §8

**Generation Prompt:**  
`pixel art overlay sheet for medical room upgrades, modular environment add-ons, cozy football club recovery room improvements, upgraded awning, extra planter boxes, hydration station, folded towel shelves, privacy screen, better signage, soft lamp, recovery porch, warm trim upgrades, cleaner entry path, supportive care details, calm and readable, same material family as training ground but softer and more nurturing, community football atmosphere, low-noise pixel clusters, clear upgrade readability`  
`--no MRI machine --no operating theater --no laboratory monitors --no futuristic rehab chamber --no chrome treadmill lab --no neon strips --no harsh warning signs --no clutter overload`

**Status:** Needed

## ASSET-053 — Medical Room Construction State Sheet

| Field | Value |
|-------|-------|
| Category | Environment / Sprite / 2D Art |
| Dimensions | 单帧 `96×96`；4 状态（`foundation / constructing_a / constructing_b / upgrading`）建议 `384×96 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `env_medical_room_construction_sheet.png` |
| Polycount | N/A |
| Texture Res | 与 ASSET-051 同级；状态切换优先，不做长动画 |

**Visual Description:**  
施工阶段应传达“俱乐部在为球员补上一处更好的照护空间”，而不是事故现场或废墟改造。脚手架、木板、布篷、材料箱与临时告示都应保持整洁友好，让建造本身读起来也是温和向前的成长过程。  

**Art Bible Anchors:**
- §1  
- §3.2  
- §4  
- §6.1  
- §6.4  
- §8  
- §9

**Generation Prompt:**  
`pixel art construction state sheet, 3/4 top-down view, cozy football club medical room under construction, tidy scaffolding, wooden planks, canvas tarps, stacked crates, friendly construction signage, community renovation feeling, warm cream and brown materials already visible, clear silhouette at every stage, low-stress building progression, small-town football facility expansion, optimistic and readable`  
`--no disaster debris --no dark hazard zone --no industrial demolition --no sparks --no post-apocalyptic ruin --no grim construction site --no neon work lights`

**Status:** Needed

## ASSET-054 — Medical Room Recovery Prop Set

| Field | Value |
|-------|-------|
| Category | Sprite / Environment |
| Dimensions | 基础 cell `16×16`；建议 `128×64 px` sheet（`8×4` cells）；默认静态 props |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `prop_medical_room_recovery_set_sheet.png` |
| Polycount | N/A |
| Texture Res | World props small tier；建议并入医疗/恢复类 world props atlas |

**Visual Description:**  
这组道具负责把 Medical Room 的“被照顾、慢慢恢复”情绪落到细节上：毛巾、热水袋、冰敷包、补水杯、小推车、记录板、靠枕、药柜、弹力带等都应优先表现恢复与支持，而不是临床压迫感。材质更偏布料、木材、搪瓷与温和塑料，而非不锈钢与实验室器械。  

**Art Bible Anchors:**
- §3.2  
- §4  
- §5  
- §6.2  
- §6.3  
- §8

**Generation Prompt:**  
`pixel art prop set, football club medical room recovery props, folded towels, hot water bottle, cold pack bucket, hydration cups, tea thermos, clipboard, recovery mat, stool, cushion, privacy screen, medicine cabinet, rehab bands, supportive care objects, cozy community clinic feel, warm cream green blue brown palette, clean silhouettes, low-noise pixel art, readable small sprites, nurturing and restorative, practical and friendly`  
`--no syringes --no scalpels --no surgical tray --no body horror --no cold stainless steel everywhere --no cyber rehab device --no neon monitor glow --no gore --no punishment imagery`

**Status:** Needed

## ASSET-055 — Medical Room Recovery Status Icon Set

| Field | Value |
|-------|-------|
| Category | UI / Sprite / 2D Art |
| Dimensions | 原生 `16×16` / `24×24` / `32×32` 三档；baseline 按 4 个语义位估算 |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `ui_medical_room_recovering_16.png`、`ui_medical_room_capacity_full_24.png`、`ui_medical_room_ready_32.png` |
| Polycount | N/A |
| Texture Res | UI icon tier；三档原生绘制，禁止单母版缩放 |

**Visual Description:**  
这套图标应延续现有 Club Footballer Status Overlay Icons 的语言，但进一步收窄为“支持性提醒”。形状圆润、轮廓优先、内部细节极简，用奶油、平静蓝、成长绿、镇金构成主要语义，小剂量俱乐部红只用于“需要关注”，而不是危险警报。  

**Art Bible Anchors:**
- §3.3  
- §4  
- §7  
- §8

**Generation Prompt:**  
`pixel art UI icon set for football club recovery statuses, 16px 24px 32px readable icons, rounded silhouette-first symbols, supportive recovery reminder language, rest, treatment, improving, care attention, hydration, light rehab, calm and optimistic tone, cream, calm blue, growth green, town gold, small red only for attention states, low detail, clean contrast, friendly management sim interface, not punitive`  
`--no skull icon --no biohazard --no ECG spikes --no emergency siren --no aggressive warning triangle dominance --no horror medical symbols --no sci-fi HUD --no neon glow --no glossy mobile-game UI`

**Status:** Needed

## ASSET-056 — Medical Room Recovery Pulse FX

| Field | Value |
|-------|-------|
| Category | VFX / Particles |
| Dimensions | 建议 `32×32` 单帧；6 帧轻循环；sheet `192×32 px` |
| Format | PNG，8-bit RGBA，透明背景 |
| Naming | `vfx_medical_room_recovery_pulse_32grid.png` |
| Polycount | N/A |
| Texture Res | VFX small tier；alpha 覆盖尽量紧；避免大面积 overdraw |

**Visual Description:**  
Recovery Pulse FX 应像“稳定呼吸”或“温和护理节拍”，而不是警报灯或扫描波。它用于恢复完成、康复进展或状态改善的轻微反馈，以柔和奶油金光为主、少量蓝绿辅助，表现安静而持续的恢复感。  

**Art Bible Anchors:**
- §1  
- §4  
- §7.5  
- §8  
- §9

**Generation Prompt:**  
`pixel art VFX sheet, gentle recovery pulse effect for a cozy football club medical room, soft rhythmic glow, subtle expanding rings, tiny warm spark motes, breathing-like pulse, restorative not urgent, cream-gold light with hints of calm blue and growth green, low-intensity, readable at small scale, supportive reminder effect, management sim friendly, quiet and warm, complements training-ground growth feedback`  
`--no alarm beacon --no siren flash --no sci-fi scanner sweep --no hologram interface --no shockwave explosion --no electric discharge --no aggressive red pulse --no neon aura --no chaotic particle storm`

**Status:** Needed
