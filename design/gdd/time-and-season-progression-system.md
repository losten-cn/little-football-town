# 足球小镇：时间与赛季推进系统

> **Status**: Designed
> **Author**: 用户 + Claude
> **Last Updated**: 2026-05-31
> **Implements Pillar**: 轻度足球经营、像素小镇养成、低压力长期成长
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/balance-system.md`
> - `E:\code\game\game-design\00-足球小镇-策划总览.md`

## Overview

时间与赛季推进系统是《足球小镇》的底层节奏控制层，负责定义游戏内时间如何流动、日常行动如何占用时段、比赛节点何时触发、阶段结算如何发生，以及一个赛季从开始到结束的推进框架。它不直接拥有训练内容、比赛规则、建设项目或经济账目本身，而是为这些系统提供统一的时间单位、日历结构、阶段边界和推进接口，让培养、比赛、经营与解锁能够被组织成清晰、低压力、可预期的长期循环。玩家会通过“今天还能做什么”“下一场比赛什么时候开始”“本赛季还剩多少推进空间”这些具体感受体验到它的存在；本系统的核心目标，是把短期行动、中期赛季和长期成长稳定串联起来，同时避免用冗长等待破坏轻度经营节奏。

## Player Fantasy

时间与赛季推进系统服务的玩家幻想是：“我的足球小镇正在按我规划的节奏稳步前进。”玩家不只是被动等待时间流逝，而是持续感到自己在安排今天做什么、这周推进什么、这个赛季冲击什么。每一次训练、每一场比赛、每一次阶段结算，都应当让玩家感到时间是在为自己的经营计划服务，而不是反过来逼迫自己追赶系统。

这种幻想的重点不是紧张倒计时带来的压迫感，而是有节奏、有目标、有空间做选择的掌控感。玩家应该相信：即使资源有限、赛程存在阶段压力，自己仍然可以通过安排优先级来稳定推进球队和小镇的发展。时间与赛季推进系统必须让“下一步做什么”始终清晰，让短期计划与长期目标自然衔接，并把赛季推进塑造成一种持续展开的成长旅程，而不是单纯的时间消耗过程。

## Detailed Rules

### Core Rules

1. 时间与赛季推进系统是全局节奏的权威来源，负责定义游戏内时间单位、日历结构、阶段边界、赛程节点和结算触发条件。
2. 本系统只拥有“推进框架”，不拥有下游系统的具体内容表：
   - 训练项目和训练收益由运动员培养系统拥有；
   - 比赛对阵、战术和胜负演算由比赛竞技系统拥有；
   - 建设项目、升级内容和布局效果由小镇建设系统拥有；
   - 收支项目和资源公式由经济管理系统拥有；
   - 联赛层级和赛事规则细节由联赛与赛事结构系统拥有。
3. 游戏内时间必须使用统一口径，让所有会消耗推进机会的行为都能映射到同一套时间单位中；下游系统不得各自定义互相冲突的独立时钟。
4. 时间推进必须优先服务“低压力长期成长”目标：常规操作不依赖长时间现实等待，玩家的节奏压力主要来自资源取舍、赛程安排、阶段目标和机会成本。
5. 本系统必须同时支撑三层循环：
   - 短期循环：单日或单个行动窗口内的训练、经营、准备与局部安排；
   - 中期循环：一周、一个阶段或一个赛季中的比赛安排、阶段结算与解锁推进；
   - 长期循环：跨多个赛季的球队成长、联赛晋级、长期目标与终局推进。
6. 玩家每次主动推进时间时，系统都必须明确说明“推进了多少时间”“推进后发生了什么”“距离下一关键节点还有多远”。
7. 任何会消耗主要行动机会的行为，都必须同时声明其时间消耗、资源消耗、是否可取消、以及会不会直接推进到下一个关键节点。
8. 比赛、阶段结算、赛季结算、解锁结算等关键节点必须由本系统统一调度；下游系统只能在这些节点被触发时提供自己的结算内容。
9. 本系统必须允许“计划性推进”，即玩家能够在进入关键比赛或阶段结算前，清楚知道自己还有哪些常规行动窗口可用。
10. 时间推进必须避免隐藏惩罚：如果某个选择会跳过训练机会、提前触发比赛、结束当周或结束赛季，系统必须在玩家确认前给出清晰提示。
11. 日历推进必须保持稳定、可预测；同一类行动在正常情况下应消耗一致的时间单位，除非下游系统明确声明并展示特殊修正来源。
12. 赛季必须是一个可识别的中期框架，至少包含：赛季开始、赛程推进、阶段性比赛节点、赛季结束结算、进入下一赛季或下一阶段。
13. 如果某些内容在 MVP 阶段尚未实现，例如复杂事件链或多赛区联动，本系统仍必须能独立支撑“训练 → 比赛 → 结算 → 下一阶段”的最小推进闭环。
14. 本系统必须为 UI 提供明确的可显示信息：当前日期/阶段、下一比赛节点、下一结算节点、剩余可安排窗口、当前赛季所处位置。
15. 当下游系统需要基于时间推进触发效果时，必须接入本系统的统一节点，而不是自行在别处静默推进时间。
16. 正式比赛节点不可因运动点数不足而造成推进死锁。当 `match_trigger_reached = true` 且当前 AP < 经济系统 `match_ap_cost` 时，本系统先请求经济系统执行一次 `match_day_ap_safety_grant`，把 AP 补足到本场比赛最低开赛成本；该补足只可在正式比赛触发节点执行，不能被训练、建设或手动休息调用。同一 `match_id` 在同一正式比赛节点上最多只能成功发放一次补足；恢复、重进或重复求值不得重复发放。`match_day_ap_safety_grant` 是进入赛前前的自动节点处理，只能作为短提示、结算摘要或审计流水展示，不得成为玩家需要主动选择、确认或优化的赛前决策。

### States and Transitions

| State | Description | Enter condition | Exit condition | Valid next states |
|---|---|---|---|---|
| Planning | 玩家停留在当前可操作窗口内，尚未确认推进下一步 | 进入主循环、赛后返回、阶段结算后返回 | 玩家选择执行行动或直接推进时间 | Action Resolution / Match Trigger / Stage Settlement |
| Action Resolution | 正在结算一次会占用时间的日常行动 | 玩家确认训练、建设、管理或其他推进性行动 | 行动结算完成 | Planning / Match Trigger / Stage Settlement |
| Match Trigger | 到达比赛节点，系统要求进入赛前或开赛流程 | 时间推进触发预定比赛节点 | 玩家完成比赛入口确认或取消返回允许状态 | Match In Progress / Planning |
| Match In Progress | 比赛系统接管一次比赛流程 | 比赛正式开始 | 比赛结束 | Post-Match Settlement |
| Post-Match Settlement | 处理比赛后的奖励、状态变化和赛程后续推进 | 比赛结束 | 结算展示完成 | Planning / Stage Settlement / Season Settlement |
| Stage Settlement | 处理阶段目标、周结、阶段奖励或阶段解锁 | 达成阶段边界或阶段目标 | 阶段结算完成 | Planning / Match Trigger / Season Settlement |
| Season Settlement | 处理赛季结束、排名结果、赛季奖励与下一赛季入口 | 到达赛季终点 | 玩家确认进入下一赛季或下一阶段 | Offseason / Planning |
| Offseason | 赛季间的短暂调整窗口，用于准备下一赛季或承接阶段解锁 | 一个赛季完成并进入赛季间隙 | 玩家确认开始新赛季或完成必要准备 | Planning / SeasonStart |
| SeasonStart | 新赛季初始化节点，生成新赛程和新阶段目标 | 玩家开始下一赛季 | 初始化完成 | Planning |

### Interactions with Other Systems

| System | 时间与赛季推进系统提供 | 该系统提供回时间与赛季推进系统 | Ownership boundary |
|---|---|---|---|
| 数值系统 | 统一时间口径、阶段目标节点、与时间相关的共享节奏边界 | 行动点、资源压力目标、里程碑目标时长 | 时间系统定义何时推进；数值系统定义推进后的共享节奏目标 |
| 运动员培养系统 | 训练窗口、训练时段消耗规则、阶段切换节点 | 训练项目、训练收益、训练结果事件 | 时间系统定义什么时候能练、练完推进到哪里；培养系统定义练什么、涨什么 |
| 比赛竞技系统 | 比赛触发节点、赛前/赛后流程入口、赛程时间位 | 比赛结果、赛后奖励、状态变化 | 时间系统定义何时比赛；比赛系统定义比赛内部发生什么 |
| 经济管理系统 | 周期结算节点、维护费/收益触发时机、阶段账期边界 | 收支明细、周期资源变化、经营事件 | 时间系统定义什么时候结账；经济系统定义结什么账 |
| 小镇建设系统 | 建设占用时段、完工节点、阶段推进接口 | 建设项目、升级内容、完工收益 | 时间系统定义什么时候开工/完工；建设系统定义建什么、提供什么效果 |
| 联赛与赛事结构系统 | 赛季开始/结束节点、赛程容器、阶段边界接口 | 赛事层级、赛程编排规则、晋级条件 | 时间系统定义赛季怎么走；赛事系统定义赛季里有哪些比赛与规则 |
| 随机事件系统 | 可触发事件的时间窗口、阶段节点、赛季上下文 | 事件内容、事件结果、临时分支 | 时间系统定义何时允许事件发生；事件系统定义发生什么 |
| 主循环 UI 框架 | 当前日期/阶段、下一节点、剩余窗口、赛季位置 | 实际展示方式、提醒优先级、交互入口 | 时间系统定义信息语义；UI 系统定义如何展示和提醒 |
| 存档与读档系统 | 当前时间状态、赛季进度、待触发节点、阶段状态 | 保存、读取、迁移和恢复结果 | 时间系统定义哪些推进状态必须持久化；存档系统定义如何持久化 |

## Formulas

### 1. 行动时间消耗

`action_time_cost` 的公式定义如下：

`action_time_cost = base_time_cost × time_cost_modifier`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 基础时间消耗 | `base_time_cost` | float | > 0 | 某行动在标准情况下占用的基础时间单位 |
| 时间消耗修正 | `time_cost_modifier` | float | 0.5–2.0 | 由设施、阶段状态、特殊事件或系统规则带来的时间修正倍率 |
| 实际时间消耗 | `action_time_cost` | float | > 0 | 该行动最终占用的时间单位 |

**Output Range:** 大于 0；常规日常行动的目标区间应保持短且统一，避免单次操作拖得过长。
**Example:** 若一次训练的 `base_time_cost = 1.0`，设施使 `time_cost_modifier = 0.8`，则 `action_time_cost = 1.0 × 0.8 = 0.8`。

### 2. 可用行动窗口

`available_action_windows` 的公式定义如下：

`available_action_windows = floor((current_phase_time_budget - reserved_time - consumed_time) / standard_window_size)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 当前阶段时间预算 | `current_phase_time_budget` | float | ≥ 0 | 当前日、周或阶段中可分配的总时间单位 |
| 预留时间 | `reserved_time` | float | ≥ 0 | 已被固定比赛、强制结算或不可跳过节点占用的时间 |
| 已消耗时间 | `consumed_time` | float | ≥ 0 | 当前阶段已被玩家行动消耗的时间 |
| 标准窗口大小 | `standard_window_size` | float | > 0 | 一个常规可操作窗口对应的标准时间单位 |
| 可用行动窗口数 | `available_action_windows` | int | ≥ 0 | 玩家在当前阶段还可自由安排的窗口数量 |

**Output Range:** ≥ 0；若结果小于 0，则按 0 处理。
**Example:** 若 `current_phase_time_budget = 10`、`reserved_time = 2`、`consumed_time = 5`、`standard_window_size = 1`，则 `available_action_windows = floor((10 - 2 - 5) / 1) = 3`。

### 3. 比赛节点触发判定

`match_trigger_reached` 的公式定义如下：

`match_trigger_reached = current_timeline_position >= scheduled_match_position`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 当前时间轴位置 | `current_timeline_position` | float | ≥ 0 | 玩家当前推进到的时间轴位置 |
| 预定比赛位置 | `scheduled_match_position` | float | ≥ 0 | 某场比赛在当前周或当前赛季时间轴上的预定触发点 |
| 是否触发比赛节点 | `match_trigger_reached` | bool | true / false | 是否已经进入比赛节点 |

**Output Range:** 布尔值；为 `true` 时必须进入比赛入口或明确处理其分支。
**Example:** 若 `current_timeline_position = 6.0`、`scheduled_match_position = 6.0`，则 `match_trigger_reached = true`。

### 4. 阶段结算触发判定

`stage_settlement_trigger_reached` 的公式定义如下：

`stage_settlement_trigger_reached = current_stage_progress >= stage_progress_target`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 当前阶段进度 | `current_stage_progress` | float | ≥ 0 | 玩家在本阶段累计推进的进度值 |
| 阶段目标进度 | `stage_progress_target` | float | > 0 | 触发本阶段结算所需达到的目标值 |
| 是否触发阶段结算 | `stage_settlement_trigger_reached` | bool | true / false | 是否进入阶段结算节点 |

**Output Range:** 布尔值；为 `true` 时必须触发阶段结算或进入结算入口。
**Example:** 若 `current_stage_progress = 12`、`stage_progress_target = 12`，则 `stage_settlement_trigger_reached = true`。

### 5. 赛季进度比例

`season_progress_ratio` 的公式定义如下：

`season_progress_ratio = completed_season_units / max(1, total_season_units)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 已完成赛季单位 | `completed_season_units` | float | 0–`total_season_units` | 当前赛季已经完成的赛程单位、周单位或阶段单位 |
| 赛季总单位 | `total_season_units` | float | > 0 | 当前赛季的总推进单位数 |
| 赛季进度比例 | `season_progress_ratio` | float | 0–1 | 当前赛季推进完成度 |

**Output Range:** 0–1；达到 1 时表示赛季已到达终点，必须进入赛季结算流程。
**Example:** 若 `completed_season_units = 9`、`total_season_units = 18`，则 `season_progress_ratio = 0.5`。

### 6. 关键节点剩余时间

`remaining_time_to_next_key_node` 的公式定义如下：

`remaining_time_to_next_key_node = max(0, next_key_node_position - current_timeline_position)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 下一关键节点位置 | `next_key_node_position` | float | ≥ `current_timeline_position` | 下一场比赛、阶段结算或赛季结算所在的时间轴位置 |
| 当前时间轴位置 | `current_timeline_position` | float | ≥ 0 | 玩家当前推进到的时间轴位置 |
| 距下一关键节点剩余时间 | `remaining_time_to_next_key_node` | float | ≥ 0 | 玩家距离下一关键节点还有多少时间单位 |

**Output Range:** ≥ 0；该值必须可被 UI 用于向玩家展示剩余安排空间。
**Example:** 若 `next_key_node_position = 10`、`current_timeline_position = 7.5`，则 `remaining_time_to_next_key_node = 2.5`。

### Formula Ownership Notes

- `training_actual_gain`、`training_queue_result` 不在本系统中定义；运动员培养系统负责训练收益本身。
- `match_result`、`team_rating`、`match_rewards` 不在本系统中定义；比赛竞技系统负责比赛内部演算和结果。
- `weekly_income`、`maintenance_cost`、`resource_income_tick` 不在本系统中定义；经济管理系统负责周期收支细节。
- `league_schedule_generation` 不在本系统中定义；联赛与赛事结构系统负责具体赛程生成规则。
- 本系统只定义“何时触发”与“还剩多少推进空间”，不定义下游系统在该节点具体结算什么内容。

## Edge Cases

- **If `action_time_cost <= 0`**: 该行动时间配置视为无效；系统必须把该行动阻止在结算前，并将其标记为错误配置，而不是允许“零时间”或“负时间”推进。
- **If `time_cost_modifier` 把一个常规行动压到极小值**: 系统仍必须保证该行动至少占用一个可感知的最小时间单位；不得通过倍率叠加把常规行动压缩成可无限刷取的伪免费操作。
- **If `available_action_windows` 计算结果小于 0**: 结果按 `0` 处理；系统必须直接进入下一个关键节点或要求玩家结束当前阶段，而不是允许继续安排额外行动。
- **If 玩家当前阶段剩余时间不足以执行所选行动**: 该行动不得开始；系统必须明确提示该行动会超出当前阶段剩余时间，并要求玩家改选、提前推进，或进入关键节点。
- **If 某个行动会刚好把时间推进到比赛节点**: 行动结算完成后必须立即进入 `Match Trigger`，不得再额外开放一个自由行动窗口。
- **If 某个行动同时跨过比赛节点和阶段结算节点**: 系统必须按统一优先级顺序依次结算，不能跳过其中任一节点；推荐顺序为：比赛节点 → 赛后结算 → 阶段结算。
- **If 多个关键节点落在同一时间轴位置**: 系统必须使用固定节点优先级处理，且该优先级必须对玩家可解释；不得因实现顺序不同导致不同结果。
- **If 玩家在 `Match Trigger` 时 AP 不足以支付 `match_ap_cost`**: 本系统请求经济系统执行 `match_day_ap_safety_grant`，将 AP 补足到本场比赛最低成本后继续进入比赛入口。该补足必须写入结算摘要或审计流水，且不得增加到超过 `match_ap_cost` 所需的最低值；UI 只能把它展示为自动补足提示，不得让玩家把它当成赛前可选行动。
- **If 同一 `match_id` 的 `Match Trigger` 在恢复、重复进入或同一稳定节点内被再次求值**: 已成功记录的 `match_day_ap_safety_grant` 不得再次发放；系统必须读取已有 grant 状态并继续原比赛节点处理，而不是重复补足 AP。
- **If 玩家在 `Match Trigger` 时取消进入比赛**: 只有在规则允许取消的情况下，系统才能返回 `Planning`；若该比赛属于不可跳过节点，则必须继续停留在比赛入口，直到玩家处理该节点。
- **If 不可跳过比赛节点因非法阵容无法正常开赛**: 时间系统不得延迟、跳过或反复触发同一比赛节点；比赛系统必须按其兜底规则生成推荐阵容、错位补位或 `forfeit_result_packet`，随后时间系统继续进入 `Post-Match Settlement`。
- **If 一个赛季的 `total_season_units = 0` 或非法**: 赛季配置视为无效；系统不得开始该赛季，并必须标记为配置错误，而不是生成可立即结束的空赛季。
- **If `completed_season_units > total_season_units`**: `season_progress_ratio` 按 `1` 处理，并立即转入 `Season Settlement`；同时将该赛季进度标记为需复核的异常数据。
- **If 玩家在赛季末仍有未处理的普通行动窗口**: 普通窗口必须在赛季结束前失效；系统不得允许玩家绕过赛季结算继续在旧赛季中刷取额外收益。
- **If 赛后结算直接导致阶段目标完成或赛季结束**: 系统必须在 `Post-Match Settlement` 后连续触发对应的 `Stage Settlement` 或 `Season Settlement`，不得要求玩家手动重复推进一次时间。
- **If 联赛系统配置的一个 `matchweek` 对应多于一轮正式联赛窗口或完全没有正式比赛窗口**: 该赛季配置视为无效；MVP 阶段必须保持 `1 matchweek = 1 轮正式联赛比赛窗口`，否则时间预算、比赛频率与赛季节奏口径不可信。
- **If 随机事件、建筑完工或周期结算与比赛日冲突**: 本系统必须使用统一节点优先级，并保证同一事件不会在不同入口被重复结算。
- **If 存档读取时当前状态停在关键节点中途**: 系统必须恢复到最近一个可验证的节点状态，例如 `Planning`、`Match Trigger`、`Post-Match Settlement` 或 `Season Settlement`，不得恢复到既已消耗时间又未挂接结算的半完成状态。
- **If 玩家在 Offseason 未完成必要准备就尝试开新赛季**: 系统必须先检查赛季开始条件；若条件未满足，应阻止进入 `SeasonStart` 并明确说明缺少的前置项。
- **If 下游系统试图自行推进时间轴位置、赛季进度或关键节点状态**: 该推进无效；所有时间推进必须回到本系统统一登记并触发。
- **If MVP 阶段尚未实现复杂赛程、分区联赛或多层阶段结构**: 系统必须退回到最小可运行结构，至少保证“可安排行动窗口 → 比赛节点 → 赛后结算 → 赛季结算”这条主链可闭环运行。

## Dependencies

时间与赛季推进系统位于 Foundation 层，是多个后续系统共享的节奏底座。它本身不决定训练收益、比赛结果或经济公式，但负责把这些系统组织到统一的时间轴、阶段边界和赛季框架中。对上，它依赖游戏概念、系统索引与数值系统来确定体验目标和共享节奏边界；对下，它为培养、比赛、经济、建设、赛事和表现层提供统一的推进节点。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 定义了三层循环、低压力长期成长、资源驱动而非等待驱动的节奏目标 | 核心循环层级、阶段目标类型、低压力节奏原则 |
| `design/gdd/systems-index.md` | Hard | 定义了本系统在 Foundation/MVP 的位置，以及哪些系统会依赖它 | 系统层级、优先级、依赖方向 |
| `design/gdd/balance-system.md` | Hard | 定义了时间民主化原则、行动点节奏目标、里程碑目标时长等共享边界 | 时间相关共享口径、KPI 目标带、关键里程碑时长 |
| 平衡验证 / 内部测试结果 | Soft | 用于验证行动窗口、比赛频率和赛季长度是否符合体验目标 | 单次会话时长、赛季推进样本、节点触发统计 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 时间与赛季推进系统 | What must be back-referenced later |
|---|---|---|---|
| 运动员培养系统 | Hard | 训练窗口、行动时段消耗、阶段切换节点 | 必须声明训练何时可执行、一次训练占用哪种时间口径 |
| 比赛竞技系统 | Hard | 比赛触发节点、赛前入口、赛后返回节点 | 必须声明比赛由时间系统触发，而不是自行独立推进 |
| 经济管理系统 | Hard | 周期结算节点、维护费结算时机、阶段账期边界 | 必须声明资源周期结算挂接在哪些时间节点 |
| 小镇建设系统 | Hard | 开工时点、完工节点、建设占用时段 | 必须声明建设项目何时开始、何时完工、是否跨阶段 |
| 联赛与赛事结构系统 | Hard | 赛季容器、赛程时间位、赛季开始/结束节点 | 必须声明赛事结构如何装配到统一赛季框架中 |
| 随机事件系统 | Soft | 可触发事件的时间窗口、阶段上下文、赛季上下文 | 必须声明事件在什么节点可触发、是否会打断常规推进 |
| 声望与成就系统 | Soft | 阶段结算节点、赛季完成节点、长期推进边界 | 必须声明声望或成就在哪些时间节点校验和发放 |
| 主循环 UI 框架 | Hard | 当前日期/阶段、下一关键节点、剩余窗口、赛季位置 | 必须声明这些展示字段直接引用本系统定义的时间语义 |
| 球员管理 UI | Soft | 可安排训练窗口、阶段剩余行动空间 | 必须声明训练安排入口与剩余时间显示口径一致 |
| 比赛表现 UI | Soft | 下一比赛节点、比赛日入口、赛后返回节点 | 必须声明比赛入口和比赛日信息与本系统同步 |
| 建设与经营 UI | Soft | 建设占用时段、完工倒计节点、周期结算位置 | 必须声明建设和经营的时间显示口径与本系统一致 |
| 存档与读档系统 | Hard | 当前时间轴位置、当前阶段、赛季进度、待触发节点状态 | 必须声明哪些时间状态会被持久化，以及如何恢复关键节点 |
| 教程与提示系统 | Soft | 时间推进规则、赛季说明、关键节点提示口径 | 必须声明提示文案引用本系统规则，而不是另写一套时间逻辑 |

### Dependency Rules

1. 时间与赛季推进系统提供的是统一推进框架，不是下游系统的具体内容实现；下游系统可以填充内容，但不能改写统一时间轴、赛季边界或关键节点定义。
2. 任何下游系统若需要改变行动窗口口径、比赛触发方式、阶段结算顺序或赛季结束条件，必须先回到本系统修订，而不能在本地文档中静默覆盖。
3. 下游系统可以定义自己的内容节奏，例如训练项目列表、比赛类型、账期明细或建设工期表，但这些内容必须明确标注自己引用了本系统的哪个时间节点、哪个推进阶段或哪种窗口结构。
4. 当后续 GDD 完成时，依赖关系必须双向成立：本节列出的下游系统，需要在它们各自的 Dependencies 或 Interactions 章节中反向声明“依赖时间与赛季推进系统”。
5. 如果某个系统只展示时间信息而不改动推进结果，则它对本系统属于软依赖；如果某个系统会消耗时间、触发节点、生成赛程、跨越阶段或持久化推进状态，则属于硬依赖。
6. 在 MVP 阶段，运动员培养系统、比赛竞技系统、联赛与赛事结构系统和主循环 UI 框架是最关键的下游承接者；它们的设计必须优先验证是否和本系统的统一节奏框架兼容。

## Tuning Knobs

本节仅包含时间与赛季推进系统拥有的共享调参项与节奏目标，不包含训练收益表、比赛奖励表、建设工期表、联赛奖金表等下游系统内容。

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 常规行动基础时耗 `base_time_cost_standard` | 单次常规训练、管理或建设操作默认占用的时间单位 | `0.5` 至 `1.5` 窗口 | 单次操作过重，玩家每轮可做的事太少 | 时间像不存在，节奏过松，规划价值下降 | 日常节奏密度、操作手感 |
| 时间消耗修正上限 `time_cost_modifier_cap` | 设施、事件或状态对时间消耗倍率修正的最大幅度 | `0.75` 至 `1.50` | 特殊加速或拖慢过强，破坏统一时间口径 | 系统联动感不足，时间修正存在感太弱 | 系统联动感、可读性 |
| 单阶段时间预算 `current_phase_time_budget_target` | 单日 / 单周 / 单阶段内可自由安排的总时间单位目标 | `6` 至 `12` 标准窗口 | 玩家每阶段要做的事过多，循环拖沓 | 玩家很快被推到关键节点，准备空间不足 | 计划空间、节奏宽松度 |
| 预留节点占比 `reserved_time_ratio_target` | 比赛、强制结算等关键节点在阶段预算中的保留占比 | `15%` 至 `35%` | 固定节点挤压自由安排空间，压迫感上升 | 关键节点过 sparse，赛程推进感不足 | 自由度、赛程存在感 |
| 阶段结算频率 `stage_settlement_frequency_target` | 阶段性结算出现的频率 | 每 `3` 至 `7` 个可操作窗口一次 | 结算过密，流程被频繁打断 | 反馈过稀，玩家不易感知中期推进 | 中期反馈密度、节奏分段感 |
| 比赛节点间隔 `match_interval_target` | 相邻两场常规比赛之间的目标时间间隔 | `2` 至 `5` 个可操作窗口 | 比赛过密，训练和经营空间被压缩 | 比赛过稀，核心循环反馈变慢 | 培养/比赛平衡、推进爽感 |
| 单赛季长度 `total_season_units_target` | 一个赛季包含的总推进单位数 | `12` 至 `24` 单位 | 赛季过长，中期目标拖沓 | 赛季过短，阶段成长和赛程层次不足 | 中期目标长度、赛季感 |
| 休赛期长度 `offseason_window_target` | 赛季结束到下一赛季开始之间的准备窗口大小 | `1` 至 `4` 窗口 | 休赛期过长，赛季连续性被打断 | 休赛期过短，调整空间不足 | 过渡感、准备感 |
| 下一关键节点剩余时间目标 `remaining_time_to_next_key_node_target` | UI 常态下应向玩家呈现的剩余可安排空间目标 | `1` 至 `4` 窗口 | 总是剩很多，关键节点紧张感不足 | 经常逼近 0，玩家持续感到被赶进度 | 可规划感、紧迫感 |
| 赛季进度可感知阈值 `season_progress_visibility_threshold` | UI 或阶段反馈开始强调“赛季推进”存在感的最低比例 | `0.20` 至 `0.40` | 赛季压力出现太早，轻松感下降 | 玩家前中段不易感知赛季结构 | 赛季存在感、心理节奏 |
| 关键节点提示提前量 `key_node_warning_lead` | 比赛、阶段结算、赛季结算前多久开始提醒玩家 | `1` 至 `3` 窗口 | 提醒过早，造成冗余噪音 | 提醒过晚，玩家容易误推进 | 可预期性、误操作风险 |
| 单次会话赛季推进目标 `session_season_progress_target` | 一次典型会话内玩家应推进的赛季比例 | `5%` 至 `15%` | 一次会话推进过多，内容消耗过快 | 一次会话推进过少，成长感不足 | 留存节奏、单次会话满足感 |

### 调参顺序建议

1. 先调 `base_time_cost_standard`、`current_phase_time_budget_target`、`match_interval_target`，确认最基础的短期循环密度。
2. 再调 `stage_settlement_frequency_target`、`reserved_time_ratio_target`、`key_node_warning_lead`，确认关键节点出现频率和可预期性。
3. 然后调 `total_season_units_target`、`offseason_window_target`、`session_season_progress_target`，确认中期赛季长度与单次会话推进感。
4. 最后调 `time_cost_modifier_cap`、`season_progress_visibility_threshold`、`remaining_time_to_next_key_node_target`，修正系统联动表现和 UI 层节奏感知。

如果需要改动统一时间口径、关键节点体系、赛季必须包含的结构，或允许下游系统自行推进独立时钟，应视为系统级改版，而不是常规调参。

## Acceptance Criteria

- **GIVEN** 玩家处于任一可操作阶段，**WHEN** QA 执行一次常规训练、建设或管理行动，**THEN** 系统必须按照 `action_time_cost` 规则扣除时间，并明确显示该行动推进了多少时间。
- **GIVEN** 多个不同类型的日常行动被配置为常规操作，**WHEN** QA 检查其时间消耗定义，**THEN** 它们必须全部映射到本系统统一的时间口径中，不得存在下游系统自定义且未登记的独立时间单位。
- **GIVEN** 当前阶段具有固定时间预算、预留节点时间和已消耗时间，**WHEN** QA 手工计算 `available_action_windows`，**THEN** 系统返回结果必须与手工结果一致，且结果不得为负数。
- **GIVEN** 玩家当前剩余时间不足以执行所选行动，**WHEN** QA 尝试开始该行动，**THEN** 系统必须阻止行动开始，并明确提示该行动会超出当前阶段剩余时间。
- **GIVEN** 一次行动会把时间推进到预定比赛节点，**WHEN** QA 完成该行动结算，**THEN** 系统必须立即进入 `Match Trigger`，不得再额外开放自由行动窗口。
- **GIVEN** `Match Trigger` 到达时玩家 AP 低于 `match_ap_cost`，**WHEN** QA 检查进入比赛入口前的资源状态，**THEN** 时间系统必须请求经济系统补足本场最低开赛 AP，并继续进入比赛入口；不得停留在无可执行操作且比赛又不可开始的死锁状态。
- **GIVEN** `match_day_ap_safety_grant` 已在比赛节点自动执行，**WHEN** QA 检查 Match Pre 界面，**THEN** 该补足只能作为短提示、结算摘要或审计流水出现，不得作为玩家需要主动点击确认或选择的额外赛前决策。
- **GIVEN** 同一 `match_id` 的 `Match Trigger` 在恢复、重进或重复求值后再次到达，且该比赛已成功执行过 `match_day_ap_safety_grant`，**WHEN** QA 检查 AP 与审计流水，**THEN** 时间系统不得再次请求发放补足；同一比赛只允许一次有效 grant。
- **GIVEN** MVP 联赛赛程与时间系统共同定义一个标准赛季，**WHEN** QA 检查时间单位与联赛轮次映射，**THEN** `1 matchweek` 必须恰好对应 `1` 轮正式联赛比赛窗口；若不满足，该配置不得视为合法 MVP 节奏配置。
- **GIVEN** `current_timeline_position` 与 `scheduled_match_position` 已知，**WHEN** QA 手工计算 `match_trigger_reached`，**THEN** 系统返回结果必须与手工判断一致，并在结果为 `true` 时进入比赛入口流程。
- **GIVEN** `current_stage_progress` 与 `stage_progress_target` 已知，**WHEN** QA 手工计算 `stage_settlement_trigger_reached`，**THEN** 系统返回结果必须与手工判断一致，并在结果为 `true` 时进入阶段结算流程。
- **GIVEN** 一个赛季的 `completed_season_units` 与 `total_season_units` 已知，**WHEN** QA 手工计算 `season_progress_ratio`，**THEN** 系统返回值必须与手工结果一致；当结果达到 `1` 时，系统必须进入 `Season Settlement`。
- **GIVEN** 当前时间轴位置与下一关键节点位置已知，**WHEN** QA 手工计算 `remaining_time_to_next_key_node`，**THEN** 系统返回值必须与手工结果一致，且该值必须能被 UI 正确展示。
- **GIVEN** 玩家完成一场比赛，且赛后结果同时满足阶段完成或赛季结束条件，**WHEN** QA 完成赛后结算，**THEN** 系统必须继续触发对应的 `Stage Settlement` 或 `Season Settlement`，不得要求玩家额外手动推进一次时间。
- **GIVEN** 多个关键节点位于同一时间轴位置，**WHEN** QA 多次重放同一输入场景，**THEN** 系统必须始终按同一固定优先级顺序结算，结果不得因执行顺序波动。
- **GIVEN** 玩家在赛季末仍保留未使用的普通行动窗口，**WHEN** QA 触发赛季结束，**THEN** 系统必须使这些窗口失效，并直接进入赛季结算，不得允许继续在旧赛季执行常规收益行动。
- **GIVEN** 存档保存在 `Planning`、`Match Trigger`、`Post-Match Settlement` 或 `Season Settlement` 任一节点，**WHEN** QA 读档恢复，**THEN** 系统必须回到同一可验证节点，而不是落在时间已推进但结算未挂接的中间态。
- **GIVEN** 下游系统尝试直接修改时间轴位置、赛季进度或关键节点状态，**WHEN** QA 检查推进来源，**THEN** 所有有效推进都必须经过本系统登记和触发；绕过本系统的推进不得生效。
- **GIVEN** MVP 版本仅实现最小节奏闭环，**WHEN** QA 从新档连续游玩一个标准会话，**THEN** 玩家必须能够完整经历“安排常规行动 → 进入比赛节点 → 完成赛后结算 → 推进到阶段或赛季节点”的闭环。
- **GIVEN** UI 正在展示时间推进相关信息，**WHEN** QA 检查当前日期/阶段、下一关键节点、剩余窗口和赛季位置，**THEN** 这些字段必须与本系统内部状态一致，不得出现不同页面口径不一致的情况。
- **GIVEN** 一次典型会话按照目标节奏推进，**WHEN** QA 采集赛季推进样本，**THEN** 单次会话的赛季推进量、比赛频率和阶段结算频率必须落在本 GDD 的调参目标带内，或明确标记为调优未通过。
