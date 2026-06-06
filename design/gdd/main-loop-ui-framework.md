# 足球小镇：主循环 UI 框架

> **Status**: Designed
> **Author**: 用户 + Claude
> **Last Updated**: 2026-06-02
> **Implements Pillar**: 轻度足球经营、低压力长期成长
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/balance-system.md`
> - `design/gdd/time-and-season-progression-system.md`
> - `design/gdd/player-development-system.md`
> - `design/gdd/match-competition-system.md`
> - `E:\code\game\game-design\00-足球小镇-策划总览.md`
> - `E:\code\game\ui-design\足球小镇-UI交互设计文档.md`

## Overview

主循环 UI 框架是《足球小镇》中把底层系统规则组织成玩家可理解、可导航、可操作的界面骨架的 Presentation 层基础系统。它不定义球员如何成长、比赛如何演算或时间如何推进，而是负责回答"玩家从哪里看到球队、从哪里进入训练、从哪里迎接比赛、从哪里理解当前处于赛季的什么位置"。它把运动员培养系统、比赛竞技系统、时间与赛季推进系统以及经济管理系统的信息与入口，收敛为一套统一的主界面导航结构、屏幕流转规则和关键信息展示层级，确保玩家在任何时候都能快速回答三个问题：我现在该做什么、我的球队怎么样了、下一场比赛是什么时候。在 MVP 阶段，主循环 UI 框架的首要目标是验证"培养→比赛→反馈→再培养"闭环在界面层是否连贯、低压力且不需要外部说明就能被新玩家理解。

## Player Fantasy

主循环 UI 框架服务的玩家幻想不是"我喜欢这个界面"，而是"我始终知道我的球队在做什么、接下来会发生什么、我应该去哪里"。它追求的是经营类游戏最珍贵的那种"掌控感"——不是通过复杂操作实现的掌控，而是通过清晰的信息呈现和自然的导航路径，让玩家在打开游戏后的几秒内就能读懂自己球队的状态，并自然地走向下一个有意义的决策。

这种幻想的参考体验来自那些让人不知不觉玩下去的模拟经营游戏：玩家不会意识到"这个 UI 设计得很好"，但会感觉到"我好像总是知道该干什么"。主循环 UI 框架必须让《足球小镇》成为"玩家不需要教程就能开始玩的游戏"——主界面上球队近况一目了然，训练入口触手可及，下一场比赛的时间和信息清晰可见，所有关键系统入口都在玩家最需要它们的时候恰好出现。它不追求视觉炫技，而是把信息层级、导航节奏和操作流做得足够自然，让玩家把注意力留给培养谁、怎么布阵、如何经营——而不是花在"这个按钮在哪儿"上。

## Detailed Rules

### Core Rules

1. 主循环 UI 框架是玩家与游戏系统之间的导航和组织层，负责定义主界面结构、屏幕流转规则、关键信息展示层级和系统入口的触发时机。它不拥有任何游戏数据的定义权——所有展示内容的数据语义由对应游戏系统拥有。
2. 本框架只拥有"界面组织"层面的规则，不拥有培养逻辑、比赛演算、时间推进、资源结算或任何游戏系统内部规则：
   - 球员属性、训练效率、成长状态的语义由运动员培养系统拥有；
   - 比赛流程、阵容、战术、胜负结果的语义由比赛竞技系统拥有；
   - 时间节点、赛季进度、行动窗口的语义由时间与赛季推进系统拥有；
   - 资源数值与结算语义由数值系统及后续经济管理系统拥有。
3. MVP 阶段的主循环 UI 框架必须至少包含以下核心屏幕：
   - **主界面（Home）**：球队概览、赛季进度、下一场比赛倒计时、关键系统快捷入口、小镇摘要与最小建设入口；
   - **球队/球员总览（Roster）**：球员列表、基础状态、培养入口；
   - **训练安排（Training）**：训练项目选择、球员分配、训练预览与确认；
   - **比赛中心（Match Center）**：赛前准备、比赛进行中反馈、赛后结果与复盘；
   - **日程/日历（Schedule）**：赛季赛程视图、近期比赛节点、关键事件标记。
4. 主界面必须是玩家每次进入游戏、完成关键操作后自然回归的中心枢纽。所有核心子系统入口必须能在主界面上不经过深层菜单直接触达。
5. 屏幕流转默认遵循"从哪里来回哪里去"的自然返回原则。跨系统闭环完成后的默认落点是主界面；同系统内的局部操作取消或完成，应优先返回来源页，而不是强制跳回主界面或跳转到不相关屏幕。
6. 时间推进是驱动 UI 状态变化的核心信号。当时间系统推进一个行动窗口或到达关键节点时，主界面必须立即反映以下变化：
   - 赛季进度条的推进；
   - 下一场比赛倒计时的更新；
   - 新可用行动窗口的出现；
   - 关键节点（比赛日、阶段结算）的高亮提示。
7. 比赛节点的 UI 处理必须优先于其他常规操作入口。当 `match_trigger_reached = true` 时，主界面必须将比赛入口提升为最高优先级展示，并在玩家完成本场比赛，或在时间系统明确允许取消返回的情况下离开赛前流程前保持醒目提示。不可跳过的正式比赛节点不得以“推迟比赛”的方式绕过。若正式比赛节点到达时 AP 不足，UI 不显示死锁式禁用入口，而是展示"比赛日最低 AP 已补足"或等效结算提示后允许进入赛前流程。
8. MVP 阶段 Match Pre 的活跃决策预算必须限制在最多 4 个需要玩家主动处理的控件或选择。默认赛前流程只允许以下活跃决策：确认或轻调推荐阵容、选择一个战术方案、确认开赛；中场调整不计入赛前预算。AP 补足、非法阵容兜底、设施加成、技能/特性快照、联赛 stakes 和赛后成长预期必须默认作为自动处理结果、只读摘要或赛后解释呈现，不得同时变成玩家必须逐项优化的赛前任务。
9. 若同一稳定结算节点同时产生比赛/赛季结果、技能/特性变化、声望增长、声望升级、成就完成和相关提示，主循环 UI 必须按固定顺序挂接：先完成核心上游结算，再展示技能/特性变化与触发解释，再展示声望增长与升级，再展示成就完成，最后处理奖励与提示挂接；不得打断核心结算，也不得堆叠成高压弹窗链。技能/特性新提示只允许在 `first_surface_id = main_loop` 或 `match_result` 的首次归属面展示；`match_result` 只指 Match Result 容器中的赛后结果流，`main_loop` 只指可路由的轻量 Growth Summary 容器，`first_surface_route_id` 必须具体指向 `training_growth_summary:<settlement_id>`、`phase_growth_summary:<settlement_id>` 或 `season_growth_summary:<season_id>`，不是独立弹窗链或任意主界面 toast。Growth Summary 必须按 `settlement_id/season_id → player_id ASC → change_type_order → display_priority DESC → display_order ASC → feedback_key ASC` 分组和排序；单个 Growth Summary 首屏最多展示 3 条技能/特性反馈，超出部分折叠为“还有成长记录可查看”入口，不显示内部数量、点数或候选排行。反馈卡片实际渲染后，预算内记录转为 `attention_state = awaiting_ack` 且 `surface_state = shown_on_first_surface`；玩家确认整屏摘要时，预算内已展示记录逐条请求 `feedback_ack`。玩家选择稍后查看时，未确认记录保持原 `feedback_key`，并将不可恢复或预算外记录转为 `attention_state = needs_followup`、`surface_state = deferred_to_followup_notice` 或继续保留在队列中，由 Home/Roster/Growth Summary 未读摘要入口承接。`Player Detail` 仅作为回看和补读入口。单次结算的技能/特性反馈按 `display_priority DESC → display_order ASC → feedback_key ASC` 稳定排序，超出展示预算的记录继续保留在 `pending_skill_trait_feedback`，并可在 Home/Roster 显示低压力未读摘要入口，但不得丢弃或抢在核心结果前展示。
10. 主界面必须始终可见以下关键信息（MVP 最小集）：
   - 当前日期/赛季阶段；
   - 下一场比赛的时间与对手名称；
   - 球队整体实力摘要（基于 `team_match_strength` 的简化呈现）；
   - 可用行动窗口数量；
   - 核心资源摘要（经费、运动点数——数据由经济系统拥有，本框架只定义展示位置）。
11. 所有列表类界面（球员列表、赛程列表等）在 MVP 阶段必须支持基础排序和简单筛选，不要求复杂多条件筛选，但不能让玩家在 20+ 条目中只能线性翻页查找。
12. 信息展示必须区分"即时可操作的当前状态"与"只读的历史/未来信息"：前者需要交互控件，后者只需要清晰的可读格式；两者不得在视觉上混淆。
13. 当玩家处于某个子系统内部且时间推进条件满足时，系统必须决定是否允许时间推进触发：在训练安排、赛前准备等关键决策界面中，时间推进应等待玩家确认后执行，不得在玩家半完成操作时静默推进。
14. 本框架必须为下游 UI 系统定义统一的视觉容器规范，至少包括：顶部导航/状态栏区域、主内容区域、底部操作/标签栏区域。MVP 不要求复杂主题系统，但必须预留后续 UI 系统统一嵌入的接口。
15. 所有系统入口的可用性必须由对应游戏系统的状态决定。例如：
   - 比赛入口仅在 `match_trigger_reached = true` 且比赛状态为 Pre-Match Preparation 或 Match Entry 时可用；
   - 训练入口仅在时间系统处于 Planning 阶段且有可用行动窗口时可用；
   - 如果某个入口被禁用，UI 必须给出可读原因而不是静默灰掉按钮。
16. 经济管理系统已完成 MVP 设计；主界面资源摘要区必须显示经费和运动点数的真实当前值、变化量和预警状态。研究点数在 MVP 阶段后台累积但不在 UI 中显示，Alpha 阶段接入解锁树后再加入展示。
17. MVP 阶段主循环 UI 框架的首要目标是验证：从主界面出发，玩家能否在不借助外部说明的情况下，完成一次完整的"查看球队 → 安排训练 → 进入比赛 → 查看结果 → 回到主界面"闭环。

### States and Transitions

| State | Description | Enter condition | Exit condition | Valid next states |
|---|---|---|---|---|
| Home | 主界面，展示球队概览、赛季进度、下一场比赛倒计时和关键入口 | 游戏启动、完成操作后返回、取消操作返回 | 玩家选择任意子系统入口 | Roster / Training / Match Center / Schedule / Town Management |
| Town Management | 建设与经营容器，承接 Home 的小镇摘要/建设入口，并为完整建设界面提供主循环内嵌容器 | 从 Home 选择小镇摘要或建设入口；MVP 可仅进入最小建设入口，Alpha 承接完整建设界面 | 玩家返回 Home，或完成/取消容器内局部建设操作 | Home |
| Roster | 球员列表视图，展示所有球员的基础信息和状态 | 从 Home 选择球队/球员入口 | 玩家选择球员详情、返回 Home、或进入训练 | Player Detail / Training / Home |
| Player Detail | 单名球员详情视图，展示属性、潜力、训练效率、状态和成长轨迹 | 从 Roster 选择特定球员 | 玩家返回列表、或进入该球员的训练安排 | Roster / Training |
| Training | 训练安排视图，选择训练项目、分配球员、预览消耗与预期收益 | 从 Home 或 Roster 进入训练入口 | 玩家确认训练或取消 | Training Resolution / Home |
| Training Resolution | 训练结算视图，展示训练结果、属性变化与成长反馈 | 玩家确认一次合法训练 | 结算完成 | Growth Summary / Home / Roster |
| Growth Summary | 轻量成长摘要容器，用于 `first_surface_id = main_loop` 的技能/特性首次提示；按结算节点、球员和变化类型分组展示，不显示候选点数或 build 任务 | 训练结算、阶段结算或赛季收口产生 `first_surface_route_id = training_growth_summary:*` / `phase_growth_summary:*` / `season_growth_summary:*` | 玩家确认整屏摘要并写入已展示记录的 `feedback_ack`，或选择稍后查看并将未确认记录转入低压力未读入口 | Home / Roster / Player Detail |
| Match Center | 比赛中心，根据比赛状态展示赛前准备、赛中反馈或赛后结果 | 从 Home 进入比赛入口（`match_trigger_reached = true`） | 比赛流程完成，或玩家在规则允许的非强制场景中取消返回 | Match Pre / Match Live / Match Result / Home |
| Match Pre | 赛前准备视图，展示对手、己方阵容、战术选项 | Match Center 且比赛状态为 Pre-Match Preparation | 玩家确认开赛或取消 | Match Live / Home |
| Match Live | 比赛进行中视图，展示上半场/下半场关键事件和实时比分 | 比赛正式开始 | 比赛结束 | Match Result |
| Match Result | 赛后结果与复盘视图 | 比赛结束 | 玩家确认结果 | Home |
| Schedule | 赛程日历视图，展示赛季比赛安排与关键节点 | 从 Home 选择日程/日历入口 | 玩家返回 Home | Home |

### Interactions with Other Systems

| System | 主循环 UI 框架提供 | 该系统提供回主循环 UI 框架 | Ownership boundary |
|---|---|---|---|
| 数值系统 | 属性、评分、公式的展示位置与格式需求 | 五维属性定义、`positional_overall_rating`、资源语义 | 数值系统定义数据含义；UI 框架定义数据如何呈现给玩家 |
| 时间与赛季推进系统 | 赛季进度条、比赛倒计时、行动窗口指示的展示位置 | 当前时间位置、`match_trigger_reached`、`available_action_windows`、`season_progress_ratio` | 时间系统定义时间状态；UI 框架定义如何让玩家感知时间流动 |
| 运动员培养系统 | 球员列表、球员详情、训练入口、成长反馈的展示框架 | 球员属性、状态标签、训练效率、`training_actual_gain`、培养里程碑 | 培养系统定义球员数据；UI 框架定义如何让玩家浏览、比较和操作 |
| 比赛竞技系统 | 赛前准备、赛中反馈、赛后复盘、阵容/战术展示的界面框架 | 比赛状态、`team_match_strength`、关键事件流、比赛结果包、`post_match_growth_tag` | 比赛系统定义比赛数据与阶段；UI 框架定义每个阶段的界面布局与交互节奏 |
| 经济管理系统 | 核心资源摘要展示位置、资源入口预留 | 经费、运动点数的当前值；研究点数在 MVP 阶段不在 UI 中显示（Alpha 阶段接入） | 经济系统定义资源数据；UI 框架定义主界面上资源摘要的展示位置 |
| 建设与经营 UI | Town Management 容器、Home 小镇摘要/建设入口承接、返回 Home 的导航规则 | 完整建设界面内部页面、预算预览展示、维护费摘要和设施详情交互 | 主循环 UI 定义容器与跨系统导航；建设与经营 UI 定义容器内部组织 |
| 声望与成就系统 | 长期反馈的展示顺序、挂接位置与轻量提示容器 | 声望等级、进度、成就完成状态、待展示奖励状态、待挂接提示状态 | 声望系统定义长期反馈内容与触发条件；UI 框架定义它们如何按固定顺序挂接在主结算流中 |
| 技能与特性系统 | 技能/特性反馈在核心结果之后、声望/成就之前的挂接位置、轻量提示容器、首次展示归属面和稳定展示排序 | `pending_skill_trait_feedback`、技能/特性变化 payload、触发解释、`feedback_key`、`first_surface_id`、`feedback_ack` 状态 | 技能系统定义反馈语义、领域主键和确认状态；UI 框架定义展示顺序、容器和确认回写时机，不按界面拆分确认语义 |
| 随机事件系统 | 事件入口、待处理事件提示、事件弹窗容器、以及在核心结算反馈之后的轻量展示顺序 | `pending_random_event_instance`、`random_event_offer_view_payload`、`random_event_history_view_payload`、`display_priority`、事件已确认结果 | 随机事件系统定义事件内容、选项和结果；UI 框架定义事件如何进入主循环、何时后置展示，以及如何避免抢占核心结算反馈 |
| 球员管理 UI | 球员列表与详情的基础展示框架和导航规则 | 详细列表页设计、详情页布局、筛选排序交互的完整实现 | UI 框架定义导航与信息层级；球员管理 UI 在框架内完成具体页面设计 |
| 比赛表现 UI | 比赛各阶段的基础展示框架和导航规则 | 赛前/赛中/赛后的详细视觉呈现、事件动画、数据可视化 | UI 框架定义比赛界面的阶段流与信息分区；比赛表现 UI 在框架内完成具体呈现 |
| 新手引导系统 | 核心导航路径、关键入口位置、操作流的 UI 锚点 | 首次引导的高亮顺序、提示文案、教学节奏 | UI 框架定义界面结构；引导系统定义如何在界面上教玩家使用 |

> **MVP 资源显示:** 经济管理系统已设计完成。MVP 阶段主界面资源摘要区显示经费和运动点数两种资源。研究点数在后台累积但不显示（消费出口在 Alpha 阶段接入解锁树后开放）。

## Formulas

主循环 UI 框架是 Presentation 层系统，不拥有数学公式。本节定义的是 UI 结构层面的规则——它们是后续 UI 系统（球员管理 UI、比赛表现 UI 等）在布局和交互设计时必须遵守的约束公式。

### 1. 导航深度约束

`max_navigation_depth_from_home ≤ 3`

**定义：** 从主界面（Home）出发，到达任意可操作内容的最大屏幕跳转次数不得超过 3 层。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 导航深度 | `navigation_depth` | int | 1–3 | 从 Home 到目标屏幕的跳转次数（Home = 深度 0） |
| 最大深度 | `max_navigation_depth_from_home` | int | 3 | MVP 硬上限 |

**Output Range:** 1–3。  
**Example:** Home → Roster → Player Detail = 深度 2（合法）。Home → Roster → Player Detail → 某深层子页面 = 深度 3（合法但已达上限）。  
**Ownership:** 本框架完全拥有。

### 2. 主界面信息密度

`home_info_density = visible_key_fields / max_key_fields ≤ 1.0`

**定义：** 主界面同时可见的关键信息字段数不得超过预设上限，避免信息过载。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 可见关键字段数 | `visible_key_fields` | int | 5–8 | 主界面首屏同时可见的关键信息字段实际数量 |
| 最大关键字段数 | `max_key_fields` | int | 8 | MVP 主界面信息密度上限 |

**Output Range:** 5–8 个关键字段。  
**Example:** 当前日期、赛季阶段、下一场比赛信息（对手+时间=2 字段）、球队实力摘要、可用行动窗口、资源摘要（经费+运动点数=2 字段）→ 7 字段（合法）。  
**Ownership:** 本框架完全拥有。

### 3. 入口可用性判定

`entry_available = system_state_allows(system_id) AND navigation_context_allows(current_screen, target_screen)`

**定义：** 任意系统入口的可用性由两个条件共同决定：目标游戏系统的当前状态是否允许进入，以及当前屏幕的导航上下文是否允许跳转。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 目标系统 | `system_id` | enum | {training, match, roster, schedule, economy} | 入口指向的游戏系统 |
| 系统状态允许 | `system_state_allows` | boolean | {true, false} | 由目标系统根据自身状态机判定 |
| 导航上下文允许 | `navigation_context_allows` | boolean | {true, false} | 由本框架根据当前屏幕和跳转规则判定 |
| 入口可用 | `entry_available` | boolean | {true, false} | 入口是否对玩家可交互 |

**Output Range:** true 或 false。  
**Example:** 当玩家在 Training 确认界面时，`navigation_context_allows(Home → Match) = false`（不允许在训练结算中途跳去比赛）。  
**Ownership:** `system_state_allows` 由对应游戏系统拥有；`navigation_context_allows` 由本框架拥有。

### 4. 信息刷新规则

`ui_refresh_trigger = time_advanced OR system_state_changed OR player_action_completed`

**定义：** UI 必须在三类事件发生时立即刷新相关展示区域：时间推进、任意关联系统状态变化、玩家完成一次操作。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 时间推进 | `time_advanced` | boolean | {true, false} | 行动窗口消耗或关键节点到达 |
| 系统状态变化 | `system_state_changed` | boolean | {true, false} | 任意本框架关联的游戏系统状态发生变化 |
| 玩家操作完成 | `player_action_completed` | boolean | {true, false} | 玩家确认了一次训练、比赛、招募等操作 |

**Output Range:** 触发刷新或不触发。  
**Ownership:** 本框架拥有刷新触发规则；各系统的状态变化信号由对应系统发出。

### Formula Ownership Notes

- 本节所有规则属于 UI 组织结构层面的约束，不定义具体像素、颜色、字体或动画参数——这些属于下游 UI 系统（球员管理 UI、比赛表现 UI 等）和视觉设计规范的范畴。
- `system_state_allows` 的判定逻辑不在这里重复定义；本框架只负责消费各系统提供的状态信号。
- 导航深度和信息密度的具体数值可在 Tuning Knobs 中调整。

## Edge Cases

- **If 游戏启动时关联系统（培养、比赛、时间）尚未完成初始化**: 主界面必须以安全默认状态展示，所有依赖未就绪系统的入口标记为"加载中"并禁止交互，不得以半填充数据或错误状态直接暴露给玩家。
- **If 当前球队没有任何球员（新档首次进入）**: 主界面不得显示空崩溃状态；Roster 入口可用但列表为空，系统应给出引导性提示（如"前往招募你的第一名球员"），训练和比赛入口在无可用球员时自然禁用。
- **If 赛季尚未开始或赛程尚未生成**: 下一场比赛区域应显示"赛程待公布"或等效占位信息，比赛入口暂时不可用，而不是展示空倒计时或错误日期。
- **If `match_trigger_reached = true` 但同时有其他高优先级 UI 事件（如阶段结算）**: 比赛入口和阶段结算提示应按照本框架定义的优先级排序展示，不得互相遮挡或静默覆盖。
- **If 玩家在 Training 确认界面按下返回/取消但训练尚未结算**: 系统必须弹出确认对话框询问"放弃本次训练安排？"，而不是直接返回 Home 导致已填写的训练安排静默丢失。
- **If 玩家在 Match Pre 界面准备开赛时，阵容不满足最低合法条件**: 自由赛前编辑态下"开始比赛"按钮必须禁用并显示具体缺失原因（如"缺少门将"）；正式比赛强制触发态下，界面必须展示比赛系统将自动处理推荐阵容、错位补位或 `forfeit_result_packet`，不得要求玩家先手动修复所有阵容问题。
- **If 一场比赛正在进行中（Match Live）且玩家尝试通过某种路径离开比赛界面**: 系统必须阻止离开或给出明确警告"比赛进行中，离开将视为放弃本场比赛"，具体策略由比赛系统定义；本框架负责提供阻止跳转的导航层机制。
- **If 多个系统同时发出状态变化信号（例如时间推进同时触发了比赛节点和阶段结算）**: UI 刷新不得产生竞态闪烁或多重弹出；必须以统一优先级队列依次展示，一次只显示一个需要玩家确认的高优先级事件。
- **If 玩家在 Schedule 视图中查看的赛程超出当前赛季范围**: 系统应允许滚动查看但明确标记"当前赛季"与"后续赛季"的边界；不得把未生成的比赛节点展示为可交互入口。
- **If 球员列表超过 50 人（MVP 阶段预期不会出现但需预留处理）**: 列表必须支持分页或虚拟滚动，不得因条目过多导致 UI 卡顿或渲染崩溃。
- **If 所有行动窗口已耗尽且无比赛节点待处理**: 主界面必须明确指示"当前无可执行操作"，并引导玩家推进时间到下一个可用窗口或比赛节点。
- **If 经济资源数据正在加载或加载失败但主界面已进入 Home**: 资源摘要区可短暂使用加载或错误占位（如 `经费: 加载中`、`运动点数: 加载中`），不得展示无语义占位；数据恢复后必须刷新为真实经费和运动点数当前值。
- **If 玩家在较窄的屏幕/窗口尺寸下运行游戏（如 Steam Deck 或窗口模式）**: MVP 不要求完全响应式布局，但主界面核心信息区和主要入口不得因分辨率低于设计基准而裁剪到不可用状态。
- **If 一场比赛的赛后结果包含多个高情绪事件（如逆转+绝杀+球员里程碑）**: 结果展示应以结构化方式依次呈现，不得把所有信息堆在同一屏导致玩家无法消化。
- **If 玩家在 Player Detail 中查看的球员恰好被另一系统的事件修改了状态（如比赛系统回传疲劳）**: 详情页应在返回或刷新时反映最新状态；已在当前屏幕展示的旧数据不需要实时推送覆盖，但玩家再次进入时必须看到最新值。
- **If 玩家快速连续点击多个入口按钮**: 系统必须防止重复跳转或多次创建同一屏幕实例；导航请求在处理中时应忽略重复点击。
- **If 存档加载完成后 UI 状态与加载前的默认状态不一致**: 主界面必须以加载后的存档数据为准刷新所有展示区，不得残留加载前的临时占位或默认值。
- **If 存档加载后存在 `pending_skill_trait_feedback.attention_state = needs_first_surface` 且 `surface_state = queued_for_first_surface`，但原首次容器不再能直接恢复**: 主界面或 Roster 必须显示低压力未读成长摘要入口，并将该反馈转为 `attention_state = needs_followup`、`surface_state = deferred_to_followup_notice`；玩家从该入口进入 Player Detail 或 Growth Summary 时只能作为补读展示，不得生成第二条新提示或改变原 `feedback_key`。
- **If Growth Summary 中单次结算待展示技能/特性反馈超过首屏预算**: 只展示稳定排序后的前 3 条，其余记录保留原 `attention_state`、`surface_state` 和 `feedback_key` 并折叠到低压力未读入口；折叠入口不得显示“还差多少”“即将解锁数量”或任何 build tracker 式指标。
- **If 玩家退出游戏时正处于某个子系统内部（非 Home）**: 系统应允许在任何屏幕退出，下次启动时根据存档状态恢复到 Home（不得直接恢复到退出时的子系统内部，因为该中间状态可能不是稳定可恢复节点）。
- **If 后续 UI 系统（球员管理 UI、比赛表现 UI）覆盖了本框架定义的导航或容器规则**: 视为设计冲突；应以本框架的导航与容器规则为权威基线，下游 UI 系统在框架内完成具体呈现，而不是绕过框架另建一套导航逻辑。
- **If MVP 阶段未实现新手引导系统但主界面已预留引导锚点**: 各关键入口和操作区域必须具有稳定可引用的标识，使后续引导系统可以精确指向它们，而不是在引导系统完成后回头修改 UI 结构来适配引导。

## Dependencies

主循环 UI 框架位于 Presentation 层，是《足球小镇》从 Core 系统规则走向玩家可操作界面的第一层组织层。它承接所有已设计 Core 系统（培养、比赛、时间）的信息与状态，把它们组织成统一的导航结构，并为下游 UI 系统（球员管理 UI、比赛表现 UI 等）提供界面骨架和导航规则。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 概念文档定义了双核循环、低压力基调和核心玩法节奏 | 核心幻想、操作节奏预期、MVP 闭环目标 |
| `design/gdd/systems-index.md` | Hard | 定义了本系统在 Presentation/MVP 的位置及依赖方向 | 系统层级、优先级、上下游系统列表 |
| `design/gdd/balance-system.md` | Hard | 定义五维属性、共享公式与资源语义，UI 需要展示这些数值 | 属性定义、`positional_overall_rating`、资源字段语义 |
| `design/gdd/time-and-season-progression-system.md` | Hard | 提供赛季进度、比赛倒计时、行动窗口等驱动 UI 更新的核心信号 | `match_trigger_reached`、`available_action_windows`、`season_progress_ratio`、`remaining_time_to_next_key_node` |
| `design/gdd/player-development-system.md` | Hard | 提供球员列表、属性、训练效率、成长状态的数据源 | 球员字段、`training_actual_gain`、`player_tier_potential_band`、训练状态机 |
| `design/gdd/match-competition-system.md` | Hard | 提供比赛状态、关键事件、结果包和赛后标签的数据源 | 比赛状态机、`team_match_strength`、关键事件流、`post_match_growth_tag`、结果包 |
| `design/gdd/league-competition-structure-system.md` | Hard | 提供积分榜、赛程表、赛季进度和晋级/降级状态的数据源，主界面赛季信息区域、Schedule 视图和积分榜摘要均消费其数据 | 积分榜数据、赛程数据、赛季进度、晋级/降级标记 |
| `design/gdd/town-building-system.md` | Hard | MVP 最小建设切片提供设施列表、状态、建造进度、邻接关系和加成摘要，主界面消费其小镇触点数据 | 设施列表（类型、位置、等级、状态）、建造/升级进度、邻接关系、加成摘要；完整网格建设交互由 Alpha 建设与经营 UI 承接 |
| `design/gdd/save-and-load-system.md` | Hard | 存档/读档时的 UI 状态恢复策略；主界面需展示存档槽摘要元数据 | 稳定存档节点语义、存档槽元数据（时间戳、赛季、进度摘要）、恢复后默认屏幕规则 |
| `design/gdd/economy-management-system.md` | Hard | 主界面需要展示核心资源摘要（经费、运动点数）和资源预警状态 | 经费、运动点数的当前值、预警状态；研究点数在 Alpha 阶段接入 |
| `design/gdd/skill-and-trait-system.md` | Hard (Alpha) | 统一结算流需要在核心结果之后、声望/成就之前展示技能/特性反馈，并遵守首次展示归属与全局确认语义 | `pending_skill_trait_feedback`、技能/特性变化 payload、触发解释、`feedback_key`、`first_surface_id`、`feedback_ack` |
| `E:\code\game\ui-design\足球小镇-UI交互设计文档.md` | Soft | 外部 UI 设计文档提供视觉方向和交互参考 | 视觉风格方向、交互模式参考——本框架定义结构，不定义视觉 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 主循环 UI 框架 | What must be back-referenced later |
|---|---|---|---|
| 球员管理 UI | Hard | 球员列表与详情的基础展示框架、导航规则、视觉容器规范 | 必须声明其列表页与详情页嵌入本框架的 Roster/Player Detail 容器，而不是另建独立导航 |
| 比赛表现 UI | Hard | 比赛各阶段（赛前/赛中/赛后）的界面框架、导航规则、视觉容器规范 | 必须声明其各阶段视图嵌入本框架的 Match Pre/Match Live/Match Result 容器 |
| 建设与经营 UI | Hard (Alpha) | Town Management 容器、Home 小镇摘要/建设入口、返回 Home 的导航规则和统一视觉容器规范 | 必须声明其建设与经营视图接入本框架的 Town Management 容器，并在容器内部完成 Town Overview、Facility Detail、Build Picker、Upgrade Preview 等页面 |
| 新手引导系统 | Hard | 核心导航路径、关键入口的 UI 锚点标识、屏幕流转规则 | 必须声明其引导高亮和提示基于本框架定义的屏幕 ID 与入口标识 |
| 教程与提示系统 | Hard (Alpha) | 各屏幕的标识体系、信息层级规则、提示入口、帮助索引入口、非抢焦点提示容器和提示反馈排序 | 必须声明其提示内容、帮助索引和自动提示展示都绑定本框架定义的锚点、容器和反馈优先级，不得自建覆盖式提示层 |
| 音频系统 | Soft | 屏幕切换事件、关键 UI 交互事件（按钮点击、页面进入/退出），以及最小音频设置入口的 UI 容器归属 | 必须声明其 UI 音效触发时机与本框架定义的屏幕流转事件对齐；主循环 UI 框架临时拥有 Settings/Options 中主音量、BGM、SFX、Ambience 和分类静音的最小入口容器，具体音量字段和混音语义仍由音频系统与存档系统拥有 |
| 随机事件系统 | Hard (Beta) | 事件入口、待处理事件提示、事件弹窗容器、以及在核心结算反馈之后的后置展示顺序 | 必须声明其事件展示绑定本框架容器与排序规则，且不得抢占比赛、成长、声望/成就等核心结算反馈 |

### Dependency Rules

1. 主循环 UI 框架负责"玩家如何在不同系统之间导航、如何看到关键信息"，不负责"数据是否正确""状态是否合法"或"视觉是否美观"；这些边界分别服从上游游戏系统和下游 UI 系统。
2. 任何下游 UI 系统若希望新增屏幕、改变导航规则或覆盖主界面信息层级，必须先回到本框架修订，而不能在本地 GDD 中静默自建一套导航逻辑。
3. 球员管理 UI 和比赛表现 UI 是本框架在 MVP 阶段最关键的两个下游承接者；它们必须在本框架定义的容器和导航规则内完成具体设计。
4. 技能与特性反馈必须在核心训练/比赛结果之后、声望/成就之前展示；下游 UI 不得把技能反馈拆成独立高压弹窗链，也不得晚于声望里程碑导致因果顺序倒置。`feedback_key` 的确认范围是全局领域事实，`first_surface_id` 只决定首次展示面；任何下游 UI 都不得按界面生成第二套新提示或第二条确认事实。
5. 建设与经营 UI 已作为 Alpha 下游接入 Town Management 容器；它必须在本框架定义的 Home 入口、容器分区和返回路径内完成内部页面，不得自建独立全局导航。经济管理系统和 town-building-system 已完成设计，已列为 Hard 上游。
6. 随机事件系统在 Beta 阶段接入后，必须通过本框架定义的事件入口、待处理提示和事件弹窗容器展示；其反馈顺序默认后置于比赛/训练/成长/声望等核心结算，且不得在半结算态抢占焦点。
7. 主循环 UI 框架临时拥有最小 Settings/Options 容器归属，用于让玩家编辑音频系统声明的 `audio_master_volume`、`audio_bgm_volume`、`audio_sfx_volume`、`audio_ambience_volume` 和 `audio_muted_categories`。该入口只负责导航、控件承载和保存请求转发，不拥有混音公式、默认值、音效触发规则或持久化字段语义。
8. 教程与提示系统在 Alpha 阶段接入后，必须通过本框架定义的提示入口、帮助索引入口和非抢焦点提示容器展示；自动提示默认后置于比赛/训练/建设/资源/声望/随机事件等核心反馈，并使用本框架的 `screen_id`、`anchor_id` 与反馈优先级排序。
9. 外部 UI 设计文档（`足球小镇-UI交互设计文档.md`）提供视觉参考，但不拥有本框架中的导航规则、屏幕结构或信息层级定义权。

## Tuning Knobs

本节仅包含主循环 UI 框架拥有的共享调参项。它们控制的是"导航深度、信息密度、刷新节奏和入口优先级"，不包含具体像素尺寸、颜色、字体或动画曲线——这些属于下游 UI 系统和视觉设计规范的范畴。

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 最大导航深度 `max_navigation_depth_from_home` | 从 Home 到任意可操作内容的最大屏幕跳转次数 | 2–4 | 深度过大 → 玩家迷失在深层菜单中 | 深度过小 → 信息过度挤压在主界面，单屏信息过载 | 导航清晰度、操作效率 |
| 主界面最大关键字段数 `max_key_fields` | 主界面首屏同时可见的信息字段上限 | 5–10 | 字段过多 → 主界面杂乱，玩家找不到重点 | 字段过少 → 关键信息被隐藏，需要额外点击才能获取 | 主界面信息密度、一目了然感 |
| 事件优先级队列 `ui_event_priority_order` | 多个系统事件同时触发时的展示顺序 | 比赛节点 > 阶段结算 > 成长里程碑 > 一般状态变化 | 排序不当 → 关键事件被次要信息遮挡 | 排序过于僵化 → 可能错过特定场景下的重要反馈 | 信息触达效率、关键事件不遗漏 |
| UI 刷新防抖间隔 `ui_refresh_debounce_ms` | 连续状态变化信号的最低合并刷新间隔 | 100–500ms | 间隔过大 → UI 响应迟钝，玩家感知延迟 | 间隔过小 → 频繁重绘导致闪烁和性能浪费 | UI 流畅度、性能 |
| 入口禁用透明度/灰度 `disabled_entry_visual_opacity` | 禁用入口的视觉降级程度 | 30%–60% 不透明度 | 降级过度 → 禁用入口几乎不可见，玩家不知道功能存在 | 降级不足 → 禁用入口与可用入口混淆 | 可发现性与可用性区分 |
| 训练确认对话框超时 `training_abandon_confirm_timeout` | 放弃训练安排时的确认对话框是否需要手动确认 | 始终需要确认 / 5 秒超时自动取消 | 无确认 → 误操作导致训练安排静默丢失 | 每次都要确认 → 频繁取消时体验繁琐 | 操作安全感、流程顺畅度 |
| 比赛入口高亮强度 `match_entry_highlight_level` | `match_trigger_reached = true` 时比赛入口的视觉突出程度 | 中等高亮 / 强高亮（脉冲/闪烁） | 过强 → 给玩家制造不必要的紧迫感 | 过弱 → 玩家可能错过比赛节点 | 比赛节点触达、低压力体验 |
| 列表每页条目数 `list_page_size` | 球员列表、赛程列表等每页显示条目数 | 10–25 | 过大 → 滚动负担增加 | 过小 → 翻页操作频繁 | 列表浏览效率 |
| 资源加载占位格式 `resource_loading_placeholder_format` | 资源数据加载中或加载失败时主界面资源区的临时状态样式 | `加载中` / `重试` / 灰化图标 / 错误标记 | 占位太显眼 → 看起来像 bug | 隐藏整行 → 玩家误以为资源系统不存在 | 加载反馈清晰度、布局稳定性 |
| 屏幕切换动画时长 `screen_transition_duration_ms` | 主屏幕之间切换过渡动画时长 | 150–400ms | 过长 → 操作节奏拖沓 | 过短 → 切换感觉生硬无反馈 | 操作流畅感、节奏 |
| 赛季进度条更新粒度 `season_progress_update_granularity` | 主界面赛季进度条的更新步长 | 按比赛周 / 按行动窗口 | 太粗 → 进度条长时间不动，感觉赛季停滞 | 太细 → 进度条每步微不可察，失去参考意义 | 赛季节奏感知 |

## Acceptance Criteria

- **GIVEN** 玩家首次启动游戏进入主界面且经济数据加载完成，**WHEN** QA 检查屏幕内容，**THEN** 主界面必须展示赛季进度、下一场比赛信息、球队实力摘要、可用行动窗口、核心资源摘要和小镇摘要六个区域，且核心资源摘要显示真实经费和运动点数当前值；小镇摘要显示设施状态或最小建设入口。
- **GIVEN** 玩家在主界面，**WHEN** QA 检查导航入口，**THEN** 球队、训练、比赛、日程四个核心入口必须可直接触达（不超过 1 次点击），且每个入口的可用/禁用状态与其对应游戏系统状态一致。
- **GIVEN** 玩家从主界面进入 Roster → Player Detail，**WHEN** QA 计算导航深度，**THEN** 从 Home 到 Player Detail 的跳转次数不得超过 2 次。
- **GIVEN** 玩家在 Training 界面填写了训练安排但尚未确认，**WHEN** QA 按下返回按钮，**THEN** 系统必须弹出确认对话框，不得直接返回 Home 并静默丢失已填内容。
- **GIVEN** 时间系统触发 `match_trigger_reached = true`，**WHEN** QA 检查主界面，**THEN** 比赛入口必须提升为最高视觉优先级，且在玩家完成比赛，或在时间系统允许取消返回前保持醒目；不可跳过比赛节点不得被“推迟”规避。
- **GIVEN** 时间系统触发 `match_trigger_reached = true` 且玩家进入 Match Pre，**WHEN** QA 统计赛前界面中需要主动处理的控件或选择，**THEN** 活跃决策不得超过 4 个；AP 补足、设施加成、技能/特性快照、联赛 stakes 和成长预期不得作为必须逐项确认的额外赛前任务。
- **GIVEN** 一场比赛正在进行中（Match Live），**WHEN** QA 尝试通过任意导航方式离开比赛界面，**THEN** 系统必须阻止离开或给出明确警告。
- **GIVEN** 所有行动窗口已耗尽且无待处理比赛，**WHEN** QA 检查主界面，**THEN** 系统必须明确指示"当前无可执行操作"并引导推进时间。
- **GIVEN** 赛季尚未开始或赛程未生成，**WHEN** QA 查看主界面下一场比赛区域，**THEN** 显示合理的占位信息而不是空倒计时或错误日期。
- **GIVEN** 一场比赛完成后，**WHEN** QA 在赛后结果界面确认并返回，**THEN** 必须回到主界面且主界面展示的数据已反映赛后最新状态。
- **GIVEN** 多个系统事件同时触发（如时间推进同时触发比赛节点和阶段结算），**WHEN** QA 观察 UI 响应，**THEN** 事件必须以优先级队列依次展示，不得出现弹窗重叠或竞态闪烁。
- **GIVEN** 单次结算产生多条技能/特性反馈且超过展示预算，**WHEN** 主循环 UI 挂接反馈，**THEN** 必须按 `display_priority DESC → display_order ASC → feedback_key ASC` 展示预算内记录，剩余记录继续保存在 `pending_skill_trait_feedback`，且 Player Detail 不得把剩余记录渲染为首次新提示。
- **GIVEN** `pending_skill_trait_feedback.first_surface_id = main_loop`，**WHEN** 主循环 UI 路由首次展示，**THEN** `first_surface_route_id` 必须指向 `training_growth_summary:<settlement_id>`、`phase_growth_summary:<settlement_id>` 或 `season_growth_summary:<season_id>`，并进入 Growth Summary 容器；不得使用不可恢复的通用 toast。Growth Summary 必须按 `settlement_id/season_id → player_id ASC → change_type_order → display_priority DESC → display_order ASC → feedback_key ASC` 分组排序，首屏最多展示 3 条技能/特性反馈。
- **GIVEN** 读档后存在未确认技能/特性反馈且原首次容器不可恢复，**WHEN** QA 检查 Home 或 Roster，**THEN** 必须出现低压力未读成长摘要入口，反馈状态转为 `attention_state = needs_followup`、`surface_state = deferred_to_followup_notice`，且进入 Player Detail 后只作为补读展示。
- **GIVEN** 玩家在 Growth Summary 选择确认整屏摘要，**WHEN** UI 写入确认请求，**THEN** 已展示的每条技能/特性反馈必须逐条请求 `feedback_ack` 并最终进入 `attention_state = acknowledged`；未展示的预算外记录不得被隐式确认。
- **GIVEN** 球员列表有 20+ 名球员，**WHEN** QA 浏览列表，**THEN** 必须支持基础排序（至少按综合评分或位置）和翻页/滚动，不得只有线性翻页。
- **GIVEN** 经济数据加载失败或暂不可用，**WHEN** QA 检查主界面资源摘要区，**THEN** 资源区显示明确的加载或错误状态且布局不崩溃；数据恢复后刷新为真实经费和运动点数当前值。
- **GIVEN** 玩家在非 Home 屏幕退出游戏，**WHEN** QA 重新启动并加载存档，**THEN** UI 必须恢复到 Home 界面，不得直接恢复到退出时的子系统内部。
- **GIVEN** 当前球队没有任何球员，**WHEN** QA 进入 Roster，**THEN** 显示空列表并提供引导性提示，训练和比赛入口自然禁用。
- **GIVEN** 玩家快速连续点击多个入口按钮，**WHEN** QA 观察屏幕跳转行为，**THEN** 系统不得重复跳转或多次创建同一屏幕实例。
- **GIVEN** 训练结算完成后，**WHEN** QA 检查返回路径，**THEN** 返回 Home 后球员列表和相关属性展示必须反映训练后的最新值。
- **GIVEN** 一场比赛结果包含多个高情绪事件，**WHEN** QA 检查赛后结果界面，**THEN** 事件以结构化方式依次呈现，不在一屏堆叠所有信息。
- **GIVEN** 玩家从 Home 的小镇摘要或建设入口进入建设界面，**WHEN** QA 检查屏幕状态，**THEN** 必须进入本框架定义的 Town Management 容器，并可从该容器返回 Home；建设与经营 UI 不得打开独立于主循环框架之外的全局导航栈。
- **GIVEN** 主界面定义了统一的视觉容器（顶部状态栏、主内容区、底部标签栏），**WHEN** QA 在不同屏幕间切换，**THEN** 各屏幕均遵守该容器分区，不出现布局跳跃或区域缺失。
- **GIVEN** MVP 阶段未实现新手引导系统，**WHEN** QA 检查各关键入口和操作区域，**THEN** 每个区域必须有稳定可引用的标识，可供后续引导系统精确指向。
- **GIVEN** 下游 UI 系统尝试绕过本框架自建导航逻辑，**WHEN** QA 检查屏幕流转路径，**THEN** 所有跨系统屏幕跳转必须经过本框架定义的导航规则，绕过框架的独立导航视为设计违规。
