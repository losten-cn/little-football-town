# 足球小镇：声望与成就系统

> **Status**: Designed  
> **Author**: 用户 + Claude  
> **Last Updated**: 2026-06-03  
> **Implements Pillar**: 低压力长期成长、轻度足球经营、像素小镇养成  
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/balance-system.md`
> - `design/gdd/time-and-season-progression-system.md`
> - `design/gdd/economy-management-system.md`
> - `design/gdd/town-building-system.md`
> - `design/gdd/league-competition-structure-system.md`
> - `design/gdd/random-event-system.md`
> - `docs/architecture/adr-0011-reputation-and-achievement-recognition-framework.md`

## Overview

声望与成就系统是《足球小镇》中负责把“持续经营”转化为“被认可的成长轨迹”的长期反馈层。它在系统层面承接比赛成绩、赛季推进、球员培养和小镇建设等关键里程碑，把这些过程统一沉淀为可累积的声望进度、阶段性解锁和可追踪的成就记录，让玩家不仅感到自己在变强，还能明确看到“我已经走了多远、接下来还能达成什么”。本系统在系统优先级上属于 Alpha；MVP 阶段仅要求先定义最小长期反馈契约、结算口径与持久化语义，为后续正式玩家可见闭环预留稳定接口，而不要求完整展示与扩展奖励层全部上线。Alpha 阶段，本系统的重点是为双核循环补上稳定的中长期目标感：提供基础声望累积、少量关键成就和轻量解锁反馈，但不引入排行榜、限时竞争或强迫刷目标的压力；后续阶段再扩展更完整的成就分类、长期奖励树和展示层。

## Player Fantasy

玩家在声望与成就系统中应感受到的，不是“我在刷一张奖励表”，而是“这座小镇和这支球队正在被越来越多人认可，而我留下的每一步努力都有名字、有纪念、也有意义”。当玩家完成一次关键晋级、培养出第一名明星球员、建成更完整的小镇设施，或经历多个赛季后回头看见自己已解锁的阶段节点和成就记录时，应自然地产生一种持续积累的满足感：这不是短期胜负带来的刺激，而是“我真的把这里经营起来了”的长期成就感。

这种幻想必须服务《足球小镇》的低压力长期成长基调。声望与成就不应该把玩家推向排行榜焦虑、限时冲刺或强迫补全，而应像一本不断被写满的成长相册：既能让玩家清楚看到自己已经完成了什么，也能温和地提示“前面还有值得期待的目标”。好的声望与成就反馈应当增强归属感、认可感和中长期方向感，而不是把玩法重心从经营球队与小镇转移到机械地追逐 checklist。

## Detailed Rules

### Core Rules
1. **声望系统是中长期认可层的权威来源。**  
   它负责定义玩家在经营球队与小镇过程中如何获得“被认可的成长进度”，并把这种进度组织为阶段性等级、解锁门槛和长期目标框架。其他系统可以提供声望来源事件，但不得自行定义独立的长期认可等级体系。

2. **成就系统是里程碑记录层的权威来源。**  
   它负责记录玩家已完成的关键事件、风格化目标和阶段性纪念，不直接替代比赛、培养、建设或联赛系统本身的结算逻辑。其他系统只提交“事件是否发生”，成就系统负责判定“是否构成成就完成”。权威实现模块记为 `ReputationAchievementManager`，它独占 `reputation_total`、`reputation_level`、`reputation_progress_ratio`、`unlocked_achievement_ids`、`pending_reputation_rewards`、`granted_reputation_reward_records`、`evaluated_reputation_settlement_keys` 和 `processed_reputation_settlement_keys` 的耐久真值。

3. **声望与成就系统只消费事件，不拥有事件本身。**  
   比赛胜负、赛季排名、球员成长、设施建成、资源结算和阶段推进仍由对应系统拥有；声望与成就系统只定义这些事件如何转化为长期反馈、解锁进度和记录条目。

4. **声望与成就必须服务低压力长期成长，而不是制造额外竞争压力。**  
   本系统不得引入排行榜、限时冲刺、全服比较或“错过即损失”的长期目标结构。玩家应始终感到自己是在稳定积累认可，而不是被系统催促追赶。

5. **本系统在 Alpha 优先级下落地，MVP 只先钉死最小长期反馈契约。**  
   MVP 仅要求先定义并对齐以下最小契约与数据语义：
   - 基础声望累积口径
   - 声望等级阈值
   - 少量关键成就的判定口径
   - 阶段性解锁反馈的挂接语义
   - 与主循环可见但不喧宾夺主的长期目标提示约束  
   这些 MVP 条目用于保证上游事件、存档字段和 UI 挂接边界稳定，不代表 MVP 必须上线完整玩家可见实现。Alpha 阶段再把它们接成正式可见闭环。MVP 不要求完整成就图鉴、隐藏成就体系、复杂奖励树、收藏分页或稀有称号系统。

6. **声望增长必须覆盖多条长期经营来源，但不能压过核心双核循环。**  
   MVP 阶段的主要声望来源应来自：
   - 比赛结果与赛季推进
   - 球员成长里程碑
   - 小镇建设里程碑  
   这些来源必须共同服务“培养 → 比赛 → 反馈 → 再培养”主循环，而不是让玩家脱离主循环专门刷声望。

7. **成就应以纪念与方向感为主，不应成为最优资源循环。**  
   MVP 阶段成就奖励可以提供轻量解锁反馈、阶段确认或少量非破坏性奖励，但不得设计成玩家为了最高效率而反复刷单一成就条件的主收益来源。

8. **声望等级与成就完成都必须是幂等结算。**  
   同一事件在恢复、重进、重复结算或重复读档后，不得重复增加声望、重复触发升级或重复授予同一成就。所有一次性声望/成就奖励必须生成稳定 `reputation_settlement_key`，键源固定为 `settlement_id + reward_scope + reward_id`，`rule_version` 只允许作为元数据保存，不能进入键源；系统同时维护 `evaluated_reputation_settlement_keys` 与 `processed_reputation_settlement_keys` 两类账本：前者记录已被本系统接受并完成判定的稳定键，后者只记录真正产生 durable outcome 的稳定键。重复输入必须返回幂等 no-op，不得重复发奖、重复广播或重复写档。

9. **声望系统必须保留“缓慢但始终向前”的恢复路径。**  
   即使玩家处于低胜率、低资源或阶段推进缓慢状态，也必须仍能通过合法经营行为持续积累少量长期进度，不得让中后期内容因一次阶段失利而长期锁死。

10. **成就与解锁反馈必须从属于主循环节奏。**  
    如果同一结算节点同时触发比赛结果、赛季结算、声望升级和成就完成，声望与成就反馈必须按统一优先级挂接在已有结算流中，不得打断核心结算、重复抢占焦点，或把单次反馈堆叠成高压弹窗链。

11. **展示层只能消费权威只读 payload。**  
    主循环 UI、比赛表现 UI、球员管理 UI、建设与经营 UI 或教程提示不得自行推导成就是否完成、奖励是否已领取、当前等级是否提升或 `reputation_progress_ratio`。本系统必须输出只读 `reputation_view_payload` 与 `achievement_view_payload`，展示层只能绑定这些 payload 字段。

### States and Transitions

| State | Description | Enter condition | Exit condition | Valid next states |
|---|---|---|---|---|
| Reputation Idle | 声望与成就系统处于等待事件输入的常规状态 | 游戏进入稳定可操作节点，且当前没有待处理的声望升级或成就结算 | 任一上游系统提交可计入声望或成就的有效事件 | Reputation Evaluation / Achievement Evaluation |
| Reputation Evaluation | 系统正在结算一次或一批事件带来的声望变化 | 比赛结算、赛季结算、建设完工、球员成长或其他长期事件被提交到声望系统 | 本次事件对应的声望增量被计算并写入累计进度 | Reputation Level Up / Achievement Evaluation / Reputation Idle |
| Reputation Level Up | 系统检测到累计声望跨过至少一个等级阈值，并进入升级处理 | `reputation_total` 达到或超过下一个等级门槛 | 所有升级结果、解锁内容和可见反馈完成登记 | Reward Pending / Achievement Evaluation / Reputation Idle |
| Achievement Evaluation | 系统正在检查当前事件是否满足任一未完成成就条件 | 任一合法事件进入成就判定队列 | 所有可触发成就均完成判定并写入状态 | Achievement Unlocked / Reward Pending / Reputation Idle |
| Achievement Unlocked | 至少一个新成就首次达成，系统进入记录与反馈阶段 | `achievement_completed = true` 且该成就历史状态为未完成 | 成就记录写入完成，相关提示或附属奖励挂接完成 | Reward Pending / Reputation Idle |
| Reward Pending | 当前声望升级或成就完成附带了解锁、提示或奖励，需要等待统一挂接到主结算流 | Reputation Level Up 或 Achievement Unlocked 产生了后续可见反馈或奖励内容 | 奖励、解锁或提示已在当前稳定结算流中按顺序处理完成 | Reputation Idle |
| Deprecated Record | 某成就或阶段记录因版本调整进入弃用或迁移态，仅用于兼容旧存档 | 旧版本成就条件、旧奖励结构或旧记录格式被新版本替换 | 存档迁移完成并映射到新记录结构，或被标记为仅历史保留 | Reputation Idle |

#### State Transition Rules

1. `Reputation Idle` 是默认状态。声望与成就系统在没有新事件输入时不主动推进。
2. 单个上游事件进入后，可以先触发 `Reputation Evaluation`，再触发 `Achievement Evaluation`；也可以按统一批处理顺序在同一稳定节点内串行执行，但不得并发争用同一事件结果。
3. 若一次声望结算跨越多个等级阈值，系统必须在一次 `Reputation Level Up` 流程中顺序处理所有合法升级，不得漏发，也不得因重复进出状态而重复发放。
4. `Achievement Evaluation` 只检查“当前未完成”的成就；已完成成就不得重复进入 `Achievement Unlocked`。
5. `Reward Pending` 不是独立玩法界面，而是一个挂接态：它表示声望升级或成就完成产生的反馈，还需要依附于比赛结算、赛季结算或阶段结算流按顺序展示。
6. 若同一稳定节点同时触发声望升级与成就完成，系统必须使用固定优先级顺序。默认建议：
   - 先完成核心上游结算
   - 再结算声望增长
   - 然后处理声望升级
   - 再判定成就完成
   - 最后统一处理奖励与提示挂接
7. 任何状态在读档恢复后都不得停留在“半结算”中间态。稳定恢复点只能回到：
   - 已结算完成的 `Reputation Idle`
   - 或一个可重新安全执行的统一结算入口
8. `Deprecated Record` 不参与实时玩法循环，只用于旧记录兼容与版本迁移；MVP 阶段可以只保留结构约束，不要求复杂迁移 UI。

### Interactions with Other Systems

| System | 声望与成就系统提供 | 该系统提供回声望与成就系统 | Ownership boundary |
|---|---|---|---|
| 数值系统 | 声望等级阈值、声望增长曲线、成就奖励强度的数值消费需求 | 长期成长节奏目标、奖励安全边界、阶段目标带 | 数值系统定义节奏与边界；声望系统定义这些边界如何组织成长期认可结构 |
| 时间与赛季推进系统 | 声望结算挂接点、阶段性解锁反馈的时序需求 | 稳定结算节点、赛季结算节点、阶段结算节点、恢复安全边界 | 时间系统定义何时结算；声望系统定义这些节点上结算什么长期反馈 |
| 比赛竞技系统 | 比赛相关成就与声望来源的消费规则 | 比赛结果、关键比赛标签、关键事件、赛后成长标签 | 比赛系统定义比赛里发生了什么；声望系统定义哪些结果能转化为长期认可 |
| 联赛与赛事结构系统 | 赛季成绩、晋级/降级、冠军等长期目标的认可规则 | 联赛层级、赛季排名、晋级/降级结果、赛事完成状态 | 联赛系统定义赛季竞争结果；声望系统定义这些结果如何沉淀为阶段认可与成就 |
| 运动员培养系统 | 球员成长里程碑、明星球员成就、长期培养认可规则 | 球员属性成长、潜力突破、里程碑事件、球员状态摘要 | 培养系统定义球员成长事实；声望系统定义哪些成长值得被记录和认可 |
| 技能与特性系统 | 技能/特性里程碑、风格化成长标签、球员身份历史中可被长期认可的确认事件 | 技能解锁、技能升级、特性新增、特性变化、关键特性触发、`player_identity_history_entry`、稳定结算 ID | 技能与特性系统定义球员差异化事实；声望系统只能消费已确认里程碑，不得决定技能/特性解锁、升级、候选或触发 |
| 小镇建设系统 | 建设里程碑、设施发展认可、长期经营成就规则 | 设施建成、升级、布局完成态、小镇发展阶段事件 | 建设系统定义小镇发生了什么变化；声望系统定义这些变化如何成为长期纪念与目标 |
| 随机事件系统 | 随机事件里程碑接收、长期认可映射和可忽略规则 | 已确认事件事实、`event_settlement_key`、`target_scope = reputation`、`effect_request_type`、事件里程碑标签 | 随机事件系统定义事件是否发生和结果是否确认；声望系统只决定该确认事实是否映射为声望或成就，未映射事实必须安全 no-op |
| 经济管理系统 | 轻量奖励或解锁反馈的资源发放请求（若存在） | 标准化奖励结算接口、资源发放幂等边界 | 经济系统定义如何发放资源；声望系统只决定是否有奖励，不直接修改资源值 |
| 主循环 UI 框架 | 声望条、阶段提示、成就弹出、长期目标入口的展示语义 | 实际展示容器、提示优先级、导航入口位置 | UI 框架定义如何展示；声望系统定义展示的内容语义与触发条件 |
| 存档与读档系统 | 需持久化的声望等级、累计进度、成就状态、奖励状态字段 | 稳定节点保存、读档恢复、迁移与兼容结果 | 存档系统定义如何保存恢复；声望系统定义哪些长期记录必须可信持久化 |
| 新手引导 / 教程与提示系统 | 长期目标说明、阶段认可提示、成就解释口径 | 提示时机、引导锚点、说明承载界面 | 引导系统负责教玩家理解；声望系统负责提供准确的长期目标语义 |

#### Interaction Rules

1. 声望与成就系统只消费“已确认发生”的事件，不监听未结算中的临时过程。
2. 声望增长与成就判定必须优先挂接在稳定结算节点上，不得在比赛进行中或训练中途提前发放长期反馈。
3. 若某一事件同时影响多个系统，声望与成就系统只能读取该事件的最终确认结果，不得反向改写上游系统结论。
4. 声望系统可以触发解锁与提示，但不得绕过经济系统、时间系统或存档系统直接写入资源、推进时间或持久化状态。
5. 成就系统必须把“是否完成”的判定权集中在本系统内部；其他系统只能提供条件事实，不能自行把某条成就标记为完成。
6. 所有附带奖励、解锁或提示的长期反馈都必须满足幂等要求，保证恢复、重进和重复结算后结果一致。
7. 随机事件系统提交的已确认事件事实只有在 `target_scope = reputation` 且 `effect_request_type` 映射到本系统声明的来源表时才参与声望或成就判定；未映射、版本不兼容、目标非法或缺少 `event_settlement_key` 的事实必须安全 no-op，并可记录为忽略结果，不得反向要求随机事件重结算。
8. 随机事件事实进入本系统后，`reputation_settlement_key` 必须包含或引用原始 `event_settlement_key`，并通过 `processed_reputation_settlement_keys` 去重；同一随机事件结果重复输入不得重复增加声望、重复解锁成就或重复生成提示。
9. Beta 首版若没有定义随机事件到长期认可的具体映射表，则所有随机事件认可事实默认 no-op 保存或忽略，不阻塞随机事件本体、声望/成就本体或全局 GDD 收敛。
10. MVP 阶段最关键的上游承接者是：比赛竞技系统、联赛与赛事结构系统、运动员培养系统、小镇建设系统、时间与赛季推进系统。
11. MVP 阶段最关键的下游承接者是：主循环 UI 框架与存档与读档系统；没有这两者，长期认可既无法被看见，也无法被可信保留。

## Formulas

### 1. 声望获取

`reputation_gain` 的公式定义如下：

`reputation_gain = floor((base_reputation_source + bonus_reputation_source) × source_weight × stage_multiplier)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 基础声望来源值 | `base_reputation_source` | int | ≥ 0 | 某一事件按类型提供的基础声望值，例如比赛胜利、赛季结算、球员成长或建设里程碑的基础分值 |
| 额外声望来源值 | `bonus_reputation_source` | int | ≥ 0 | 由关键比赛、首次达成、升级、晋级或其他附加条件带来的额外声望值 |
| 来源权重 | `source_weight` | float | 0.5–2.0 | 不同来源类型的统一权重，用于区分普通事件与高纪念性事件的长期认可价值 |
| 阶段倍率 | `stage_multiplier` | float | 1.0–1.5 | 随联赛层级、赛季阶段或系统开放度提升而增加的长期认可倍率 |
| 获得声望值 | `reputation_gain` | int | ≥ 0 | 本次事件最终结算后增加的声望值，统一向下取整 |

**Output Range:**  
普通单场事件建议为 `5–30`；阶段性事件建议为 `20–80`；赛季级事件建议为 `50–150`。MVP 阶段单次来源不应高到让一次事件直接跨越多个大等级区间。

**Example 1 — 普通比赛胜利**  
若一场普通正式比赛胜利提供：
- `base_reputation_source = 12`
- `bonus_reputation_source = 3`（首次击败更高排名对手）
- `source_weight = 1.0`
- `stage_multiplier = 1.0`

则：

`reputation_gain = floor((12 + 3) × 1.0 × 1.0) = 15`

**Example 2 — 赛季晋级结算**  
若赛季晋级事件提供：
- `base_reputation_source = 40`
- `bonus_reputation_source = 20`
- `source_weight = 1.5`
- `stage_multiplier = 1.2`

则：

`reputation_gain = floor((40 + 20) × 1.5 × 1.2) = floor(108) = 108`

**Formula Ownership Notes**
- `reputation_gain` 只定义“长期认可增加多少”，不定义事件本身是否发生。
- 比赛系统、联赛系统、培养系统和建设系统只提供已确认事件与标签。
- 声望系统拥有这些事件如何映射成长期认可值的规则。
- 若某事件同时满足多个声望来源条件，必须先按来源拆分，再按本系统的批量结算顺序汇总，不得由上游系统直接给出最终总声望。

### 2. 声望等级进度

`reputation_progress_ratio` 的公式定义如下：

`reputation_progress_ratio = (reputation_total - current_level_threshold) / max(1, next_level_threshold - current_level_threshold)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 当前累计声望 | `reputation_total` | int | ≥ 0 | 玩家当前已累计的总声望值 |
| 当前等级阈值 | `current_level_threshold` | int | ≥ 0 | 玩家当前所处声望等级的起始阈值 |
| 下一等级阈值 | `next_level_threshold` | int | > `current_level_threshold` | 下一声望等级所需达到的最小累计声望值 |
| 等级进度比例 | `reputation_progress_ratio` | float | 0–1 | 当前等级到下一等级之间的完成比例；达到 1 时必须触发升级处理 |

**Output Range:**  
0–1。若 `reputation_total >= next_level_threshold`，则该值按 `1` 处理，并进入 `Reputation Level Up` 流程。若因异常输入导致 `reputation_total < current_level_threshold`，则结果按 `0` 处理并标记为需复核数据。

**Example 1 — 正常升级进度**  
若：
- `reputation_total = 135`
- `current_level_threshold = 100`
- `next_level_threshold = 180`

则：

`reputation_progress_ratio = (135 - 100) / (180 - 100) = 35 / 80 = 0.4375`

表示当前等级进度为 43.75%。

**Example 2 — 达到升级阈值**  
若：
- `reputation_total = 180`
- `current_level_threshold = 100`
- `next_level_threshold = 180`

则：

`reputation_progress_ratio = (180 - 100) / (180 - 100) = 1.0`

系统必须在本次稳定结算流中进入 `Reputation Level Up`。

**Example 3 — 一次跨越多个等级**  
若：
- `reputation_total = 320`
- 当前玩家原本位于 `Lv.2`
- `Lv.2` 阈值区间为 `100 → 180`
- `Lv.3` 阈值区间为 `180 → 260`
- `Lv.4` 阈值区间为 `260 → 360`

则系统不得只停留在 `Lv.3`。  
它必须顺序完成：
- `Lv.2 -> Lv.3`
- `Lv.3 -> Lv.4`

然后再计算当前停留在 `Lv.4` 区间内的进度：

`reputation_progress_ratio = (320 - 260) / (360 - 260) = 60 / 100 = 0.60`

**Formula Ownership Notes**
- 本公式只定义“当前等级到下一等级之间的进度显示与升级判定口径”。
- 声望等级阈值表由声望系统拥有，不由上游系统定义。
- UI 可直接消费 `reputation_progress_ratio` 作为进度条语义，但不得自行重新推导不同口径。
- 若一次结算跨越多个等级，必须先按等级顺序完成升级结算，再计算最终停留等级的当前进度比例。

### 3. 声望/成就奖励去重键

`reputation_settlement_key = stable_digest(canonical_join([settlement_id, reward_scope, reward_id], "|"))`

**定义：** 一次性声望升级奖励、成就奖励、阶段解锁奖励和待展示奖励都必须使用稳定去重键，避免恢复、重进、重复事件投递或重复结算时再次发放。`rule_version` 只允许作为结果元数据或迁移记录保存，不得进入稳定键源。

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 稳定结算节点 | `settlement_id` | string | non-empty | 时间/比赛/赛季/建设/培养等上游稳定节点提供的唯一结算 ID |
| 奖励作用域 | `reward_scope` | enum/string | reputation_level / achievement / milestone / unlock | 用于区分同一节点下不同类型的长期反馈 |
| 奖励 ID | `reward_id` | string | non-empty | 声望等级、成就、里程碑或解锁项的稳定 ID |
| 规则版本元数据 | `rule_version` | string/int | non-empty | 成就/声望规则版本，用于迁移、审计和解释，不参与稳定键计算 |
| 声望去重键 | `reputation_settlement_key` | string | stable digest | 命中 `evaluated_reputation_settlement_keys` / `processed_reputation_settlement_keys` 的稳定键 |

**Rule:** 若 `reputation_settlement_key` 已存在于 `evaluated_reputation_settlement_keys`，本系统必须把本次输入视为已完成判定的重复投递并返回幂等 no-op；只有当本次判定真正产生 durable outcome 时，对应键才允许写入 `processed_reputation_settlement_keys`。  
**Ownership:** 本系统拥有去重键生成、`evaluated_reputation_settlement_keys` 与 `processed_reputation_settlement_keys`；上游只提供 `settlement_id` 与事实标签。

### 4. 成就完成判定

`achievement_completed` 的公式定义如下：

`achievement_completed = achievement_condition_satisfied AND NOT achievement_already_unlocked`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 成就条件满足 | `achievement_condition_satisfied` | bool | true / false | 当前稳定结算节点中，该成就对应的全部条件是否已经成立 |
| 成就是否已解锁 | `achievement_already_unlocked` | bool | true / false | 该成就是否已在历史记录中被标记为完成 |
| 成就是否本次完成 | `achievement_completed` | bool | true / false | 本次结算中该成就是否应首次进入完成状态 |

**Output Range:**  
布尔值。只有在“当前条件成立”且“历史上尚未解锁”的情况下，系统才允许把该成就写入完成状态并进入 `Achievement Unlocked`。

**Condition Structure Rule**  
成就条件由声望与成就系统统一定义为以下三类基础条件的组合：

- **事件型条件**：某个明确事件是否发生  
  例如：赢得一场正式比赛、完成一次升级、建成第一座球场
- **累计型条件**：某项累计值是否达到阈值  
  例如：累计赢得 10 场比赛、累计培养 3 名明星球员、累计完成 5 次设施升级
- **状态型条件**：某个稳定状态是否成立  
  例如：首次进入更高联赛、首次达成某声望等级、当前拥有满级训练场

MVP 阶段的成就只允许由上述基础条件组合，不引入跨会话隐藏计时、限时窗口或外部竞争条件。

**Example 1 — 首次正式比赛胜利**  
若某成就条件为：
- 事件型条件：`won_first_official_match = true`

且当前：
- `achievement_condition_satisfied = true`
- `achievement_already_unlocked = false`

则：

`achievement_completed = true AND NOT false = true`

系统应把该成就写入完成状态。

**Example 2 — 已解锁成就再次触发**  
若玩家再次满足同一条件，当前：
- `achievement_condition_satisfied = true`
- `achievement_already_unlocked = true`

则：

`achievement_completed = true AND NOT true = false`

系统不得重复授予该成就。

**Example 3 — 累计型条件未达阈值**  
若某成就条件为：
- 累计赢得 10 场正式比赛

当前累计值仅为 8，则：
- `achievement_condition_satisfied = false`
- `achievement_already_unlocked = false`

则：

`achievement_completed = false AND NOT false = false`

系统只更新累计进度，不进入解锁状态。

**Formula Ownership Notes**
- 本公式只定义“该成就是否在本次稳定结算中首次完成”的统一口径。
- 各上游系统只提供事实数据、事件标签或累计值；不直接决定某成就是否完成。
- 成就条件表与条件组合逻辑由声望与成就系统拥有。
- 若一个稳定节点同时满足多个成就条件，必须逐条独立判定，每条成就都应用同一幂等规则。
- 若某成就附带奖励或提示，奖励挂接发生在 `Achievement Unlocked` 之后，不属于本公式本身。

## Edge Cases

- **If 玩家在一个结算节点同时满足多个成就条件**: 必须按 `display_priority DESC → achievement_id ASC → reputation_settlement_key ASC` 稳定排序，批量写入成就状态后再交给主循环 UI 轻量展示；不得为每个成就弹出独立高压弹窗。
- **If 玩家在同一场比赛后同时触发声望升级与赛季结算**: 必须遵循主循环 UI 框架定义的结算顺序：核心上游结算完成后，先展示技能/特性变化，再展示声望增长与升级，再展示成就完成，最后处理奖励与提示挂接；重复投递先以 `evaluated_reputation_settlement_keys` 判定幂等 no-op，真正产生 durable outcome 的奖励结果再以 `processed_reputation_settlement_keys` 记录。
- **If 成就在 MVP 尚未接入完整展示页**: 仍需持久化 `unlocked_achievement_ids`、`pending_reputation_rewards`、`granted_reputation_reward_records`、`evaluated_reputation_settlement_keys` 和 `processed_reputation_settlement_keys`，并能在后续 UI 接入时通过权威 payload 正确回显。
- **If 玩家长期输球或推进缓慢**: 声望系统仍应提供可恢复的长期正反馈，不得把中后期内容完全锁死；低胜率来源可以低收益，但不能让合法赛季推进完全没有长期认可。
- **If 历史成就条件在后续版本被修改**: 必须定义兼容与回溯判定边界，由存档与版本迁移系统承接；`rule_version` 只能作为迁移元数据更新，已存在的 `evaluated_reputation_settlement_keys` 与 `processed_reputation_settlement_keys` 都不得被迁移脚本清空、改写或重算成可再次领奖状态。
- **If 同一 `reputation_settlement_key` 被重复提交**: 本系统返回幂等 no-op，保留既有 durable outcome，不重复增加声望、不重复解锁成就、不重复创建 pending reward。
- **If 读档恢复时存在 `pending_reputation_rewards`**: UI 只展示权威 payload 中的待处理奖励，不重新判定奖励来源；玩家确认后由本系统和经济系统按去重键完成挂接或领取状态更新。
- **If UI payload 缺失或字段版本不匹配**: 展示层必须使用安全空状态或只读占位，不得本地重算声望等级、进度比例、成就完成或奖励状态。
- **If 随机事件系统提交 `target_scope = reputation` 的已确认事实但本系统没有对应映射**: 本系统必须返回 safe no-op 或记录忽略结果，不增加声望、不解锁成就、不要求随机事件重结算，也不阻塞随机事件反馈展示。
- **If 同一 `event_settlement_key` 对应的随机事件事实重复进入声望与成就系统**: 本系统必须通过包含或引用该事件键的 `reputation_settlement_key`、`evaluated_reputation_settlement_keys` 与 `processed_reputation_settlement_keys` 去重，保持既有 durable outcome，不重复发放长期认可。

## Dependencies

声望与成就系统位于 Feature / Alpha 层，用于把培养、比赛、联赛、小镇建设和赛季推进中的关键里程碑沉淀为长期认可、阶段性解锁与可追踪的成就记录。它本身不定义比赛结果、球员成长、资源收支或赛季规则，只消费这些系统已经确认的事件与状态，并把它们转化为长期反馈。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 定义了低压力长期成长、轻度经营与小镇归属感的总体验目标，决定声望与成就系统不能走向排行榜化或 checklist 压迫 | 长期成长目标、阶段认可原则、反高压约束 |
| `design/gdd/systems-index.md` | Hard | 定义本系统的层级、优先级与上下游关系 | 系统定位、依赖方向、阶段范围 |
| `design/gdd/balance-system.md` | Hard | 提供长期成长节奏、奖励强度边界和里程碑时长目标 | 成长节奏目标带、奖励安全范围、阶段目标带 |
| `design/gdd/time-and-season-progression-system.md` | Hard | 提供稳定结算节点、赛季结算、阶段结算与恢复边界 | `Stage Settlement`、`Season Settlement`、稳定恢复节点 |
| `design/gdd/match-competition-system.md` | Hard | 提供比赛胜负、关键比赛结果、赛后事件与成长标签 | 比赛结果包、关键比赛标签、`post_match_growth_tag`、合法结果确认 |
| `design/gdd/league-competition-structure-system.md` | Hard | 提供排名、晋级/降级、冠军与赛季完成等长期竞争结果 | 赛季排名、联赛层级变化、晋级/降级标签、赛季完成状态 |
| `design/gdd/player-development-system.md` | Hard | 提供球员成长、里程碑事件和长期培养事实 | 属性成长结果、潜力里程碑、球员成长度标签 |
| `design/gdd/skill-and-trait-system.md` | Hard | 提供技能/特性里程碑和球员身份历史事实，让声望与成就系统能认可风格化成长但不反向拥有技能逻辑 | 技能解锁、技能升级、特性新增、特性变化、关键特性触发、`player_identity_history_entry`、稳定结算 ID |
| `design/gdd/town-building-system.md` | Hard | 提供设施建成、升级与小镇发展节点 | 设施建成事件、升级事件、小镇发展阶段事件 |
| `design/gdd/random-event-system.md` | Soft (Beta) | 可提交已确认事件事实作为长期认可候选；无映射时必须被本系统安全忽略 | `event_settlement_key`、`target_scope = reputation`、`effect_request_type`、事件里程碑标签、规则版本 |
| `design/gdd/save-and-load-system.md` | Hard | 提供长期记录、待展示奖励和去重账本的持久化与恢复边界 | `reputation_total`、`reputation_level`、`reputation_progress_ratio`、`unlocked_achievement_ids`、`pending_reputation_rewards`、`granted_reputation_reward_records`、`evaluated_reputation_settlement_keys`、`processed_reputation_settlement_keys`、稳定节点保存、迁移恢复规则 |
| `design/gdd/economy-management-system.md` | Soft | 若声望升级或成就完成带来资源奖励，需要依赖其标准发放接口 | 资源奖励入账接口、奖励幂等结算边界 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 声望与成就系统 | What must be back-referenced later |
|---|---|---|---|
| `design/gdd/main-loop-ui-framework.md` | Hard | 声望等级、进度条、阶段性解锁提示、成就完成提示、长期目标入口语义、待展示奖励摘要 | 必须声明这些展示字段直接绑定 `reputation_view_payload` 与 `achievement_view_payload`，不得重算等级、进度、完成状态或奖励领取状态 |
| 球员管理 UI | Soft | 球员相关成就、明星球员里程碑提示、长期培养目标文案 | 必须声明相关提示与记录来自本系统，而不是本地重复定义 |
| 比赛表现 UI | Soft | 关键比赛成就、晋级/冠军相关成就提示、赛后长期反馈入口 | 必须声明赛后长期反馈挂接于本系统结果 |
| 建设与经营 UI | Soft | 小镇建设里程碑、设施阶段成就、长期建设认可展示 | 必须声明建设类长期目标与记录来自本系统 |
| 新手引导系统 | Soft | 声望与成就的首次解释、长期目标提示锚点 | 必须声明其文案与阶段说明遵循本系统定义 |
| 教程与提示系统 | Soft | 长期目标解释、阶段解锁说明、成就提示口径 | 必须声明其提示语义不另造一套目标体系 |
| 音频系统 | Soft | 声望升级、成就完成和长期认可展示节点的短促反馈语义 | 必须声明音频只消费已确认的长期反馈展示节点，不重算等级、奖励或完成条件，也不把长期成长包装成高压奖励链 |
| `design/gdd/save-and-load-system.md` | Hard (回传) | `reputation_total`、`reputation_level`、`reputation_progress_ratio`、`unlocked_achievement_ids`、`pending_reputation_rewards`、`granted_reputation_reward_records`、`evaluated_reputation_settlement_keys`、`processed_reputation_settlement_keys` | 必须声明这些字段属于长期持久化数据；读档恢复后只能恢复 durable outcome，不得重放已确认奖励判定，也不能丢失尚未展示的提示与挂接队列或已完成发放记录 |
| `design/gdd/economy-management-system.md` | Soft (回传) | 若存在奖励，则消费标准化资源发放接口 | 必须声明奖励型资源仍通过经济系统入账，不由本系统直接改值 |

### Dependency Rules

1. 声望与成就系统只消费“已经被上游系统确认”的事实，不接受未完成流程中的临时状态。
2. 任何上游系统都不得自行定义独立的长期认可等级、成就完成口径或长期目标树；这些语义统一由本系统拥有。
3. 若某事件同时影响比赛结算、赛季结算、技能/特性变化、声望升级与成就完成，必须先以时间系统定义的稳定节点为基准，并在技能与特性系统完成其 durable settlement result 后，本系统才能消费其中的里程碑事实。
4. 声望与成就系统不得把任何成就条件、声望等级或长期认可状态反向作为技能/特性解锁、升级、候选转正或触发条件；技能/特性状态始终由技能与特性系统拥有。
5. 若某成就或声望升级附带资源奖励，本系统只能发起奖励请求，不能直接修改资源值；资源入账始终由经济系统拥有。
6. 若某长期反馈需要在 UI 中展示，展示层不得重算等级进度、成就完成口径或奖励条件，只能消费本系统提供的 `reputation_view_payload` 与 `achievement_view_payload`。
7. 当后续 `球员管理 UI`、`比赛表现 UI`、`建设与经营 UI` 完成后，它们必须在各自的 Dependencies 中反向声明对本系统的依赖。
8. MVP/Alpha 过渡阶段，本系统最关键的上游承接者是：比赛竞技系统、联赛与赛事结构系统、运动员培养系统、小镇建设系统、时间与赛季推进系统、技能与特性系统。
9. 随机事件系统是 Beta 阶段的 Soft 上游；它可以提交已确认事件事实作为长期认可候选，但本系统允许无映射 no-op，不因此阻塞随机事件本体实现。
10. 本系统最关键的下游承接者是：主循环 UI 框架与存档与读档系统；如果没有这两个系统，长期认可既无法被玩家感知，也无法被可信保留。

## Tuning Knobs

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 声望等级阈值曲线 `reputation_level_threshold_curve` | 每级所需累计声望 | 早期 80–200 / 中期 200–600 | 升级过慢，长期目标迟滞 | 升级过快，阶段认可贬值 | 长期目标节奏 |
| 单场比赛声望基数 `match_reputation_base` | 普通比赛贡献的基础认可 | 5–30 | 比赛刷声望成为主循环外目标 | 比赛结果缺少长期反馈 | 比赛长期回报感 |
| 赛季结算声望基数 `season_reputation_base` | 排名、晋级、赛季完成贡献 | 50–150 | 赛季一次性跳级过多 | 赛季总结缺少仪式感 | 赛季成就感 |
| 小镇建设里程碑声望奖励 `town_milestone_reputation` | 设施建成/升级的长期认可 | 10–80 | 建设变成刷声望工具 | 小镇支柱反馈不足 | 小镇归属感 |
| 球员成长里程碑声望奖励 `player_milestone_reputation` | 明星球员、潜力突破等认可 | 10–80 | 玩家只追单一明星养成 | 培养成果缺少纪念 | 长期培养反馈 |
| MVP 成就数量上限 `mvp_achievement_count_cap` | Alpha 首版可见成就数量 | 8–20 | 列表压力过强 | 目标过少，长期感不足 | checklist 压力、目标清晰度 |
| 成就奖励强度 `achievement_reward_strength` | 成就附带奖励大小 | 轻量 / 中等 | 最优解变成刷成就 | 成就缺少实际反馈 | 经济扰动、完成满足感 |
| 声望解锁频率目标 `reputation_unlock_frequency_target` | 多久出现一次阶段解锁 | 每 2–5 个比赛周 | 解锁过密打断主循环 | 解锁过稀缺少期待 | 节奏、低压力 |
| 单次会话可见长期反馈密度 `session_long_term_feedback_visible_limit` | 同一结算流首屏长期反馈数量 | 1–3 | 弹窗链/信息过载 | 玩家错过认可反馈 | 反馈密度、主循环节奏 |

## Acceptance Criteria

- **GIVEN** 玩家完成一场合法比赛，**WHEN** 赛后结算完成，**THEN** 若满足声望来源条件，系统必须正确累积声望进度。
- **GIVEN** 玩家声望累计达到等级阈值，**WHEN** 结算完成，**THEN** 系统必须触发一次且仅一次声望升级反馈。
- **GIVEN** 玩家完成一个已定义的 MVP 成就条件，**WHEN** 条件首次成立，**THEN** 系统必须记录该成就为已完成，并保证后续读档可恢复。
- **GIVEN** 技能与特性系统提交已确认的技能解锁、技能升级、特性新增或关键身份历史里程碑，**WHEN** 声望与成就系统执行成就判定，**THEN** 本系统只能消费该里程碑事实来更新声望或成就状态，不得反向修改技能等级、候选进度、特性状态或触发条件。
- **GIVEN** 随机事件系统提交 `target_scope = reputation` 且包含 `event_settlement_key` 的已确认事件事实，**WHEN** 声望与成就系统没有对应 `effect_request_type` 映射，**THEN** 本系统必须返回 safe no-op 或记录忽略结果，不增加声望、不解锁成就、不阻塞随机事件反馈。
- **GIVEN** 同一随机事件确认事实被重复提交，**WHEN** 声望与成就系统处理该输入，**THEN** 由原始 `event_settlement_key` 派生或引用的 `reputation_settlement_key` 必须命中去重账本，不得重复生成长期认可结果。
- **GIVEN** 玩家在一个结算节点同时触发多个成就或声望升级，**WHEN** QA 检查结果，**THEN** 所有奖励与状态变化都必须幂等，不得重复发放，且每个一次性奖励都写入唯一 `reputation_settlement_key`。
- **GIVEN** 同一 `reputation_settlement_key` 被重复提交，**WHEN** 声望与成就系统处理该输入，**THEN** 必须先命中 `evaluated_reputation_settlement_keys` 并返回幂等 no-op，不增加声望、不重复解锁成就、不重复创建 `pending_reputation_rewards`，且 `processed_reputation_settlement_keys` 不出现重复项。
- **GIVEN** 玩家在声望升级或成就完成后立即保存并重新读档，**WHEN** 系统恢复到最近稳定节点，**THEN** `reputation_total`、`reputation_level`、`reputation_progress_ratio`、`unlocked_achievement_ids`、`pending_reputation_rewards`、`granted_reputation_reward_records`、`evaluated_reputation_settlement_keys` 与 `processed_reputation_settlement_keys` 必须与存档前一致，且不得重复发放。
- **GIVEN** 玩家在一个稳定结算节点同时触发声望升级、成就完成与相关提示，**WHEN** UI 挂接这些长期反馈，**THEN** 反馈必须按固定顺序轻量展示，不得打断核心结算或堆叠成高压弹窗链。
- **GIVEN** 主循环 UI、比赛表现 UI 或其他展示层需要显示声望/成就信息，**WHEN** QA 检查数据绑定，**THEN** 展示层必须只消费 `reputation_view_payload` 与 `achievement_view_payload`，不得本地重算等级进度、成就完成状态、奖励领取状态或待展示奖励数量。
- **GIVEN** 玩家长期推进多个赛季，**WHEN** QA 检查长期目标反馈，**THEN** 声望与成就系统必须持续提供中长期目标，而不是在 MVP 中仅作为一次性提示存在。
- **GIVEN** 玩家处于低胜率或低效率推进阶段，**WHEN** QA 检查声望进度，**THEN** 系统仍必须保留可见、可恢复、非排行榜式的长期成长路径。
