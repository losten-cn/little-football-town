# 足球小镇：随机事件系统

> **Status**: Designed  
> **Author**: 用户 + Claude  
> **Last Updated**: 2026-06-03  
> **Implements Pillar**: 像素小镇养成、低压力长期成长、轻度足球经营  
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/time-and-season-progression-system.md`
> - `design/gdd/player-development-system.md`
> - `design/gdd/economy-management-system.md`
> - `design/gdd/town-building-system.md`
> - `design/gdd/save-and-load-system.md`

## Overview

随机事件系统是《足球小镇》中负责制造小镇生活变化、赛季插曲和轻量决策点的 Beta 内容系统。它不属于 MVP 必需闭环，不定义时间推进、资源结算、球员成长、设施状态或比赛结果的权威规则；它只在时间与赛季推进系统允许的稳定窗口内生成事件，并把玩家选择或自动结算结果转化为提交给对应权威系统的事件效果请求。随机事件的目标是让小镇和球队经营更有生活感：偶尔出现镇民帮忙、训练小插曲、天气影响、赞助机会、球员心情变化或设施小问题，让玩家感到世界在运转，但不会被高压惩罚、限时焦虑或不可恢复失败打断核心循环。

## Player Fantasy

玩家在随机事件系统中应感受到：“这座足球小镇每天都有小故事发生，而我作为球队经营者，会做一些温和但有意义的选择。”事件不是惩罚机器，也不是效率任务清单，而是让小镇更像一个有人、有天气、有关系、有意外的小地方。

好的随机事件应当像经营日记中的插页：今天镇民来看训练、明天球员帮忙修球场、赛前突然下雨、青训孩子带来惊喜、赞助商提出一个小请求。玩家应该觉得这些事情让世界更真实，也让经营决策更有温度；但即使选择不是最优，也不应造成长期锁死、破产螺旋或关键成长路线断裂。

## Detailed Rules

### Core Rules

1. 随机事件系统是 Beta 内容层系统，MVP 阶段不要求上线完整随机事件闭环。
2. 本系统只负责事件生成、事件条件判定、事件选项组织、事件结果打包和事件历史记录语义，不拥有资源、时间、球员、设施或比赛结果的最终修改权。
3. 所有随机事件必须发生在时间与赛季推进系统声明的合法稳定窗口内，不得在比赛演算中途、训练结算中途、存档写入中途或其他半结算状态插入。
4. 随机事件不得自行推进日期、跳过比赛、强制改变赛季阶段或重排赛程；若事件需要影响时间节奏，必须提交给时间与赛季推进系统处理。
5. 随机事件不得直接修改经费、运动点数、研究点数、维护费或经济预警状态；若事件产生资源变化，必须通过经济管理系统的标准资源结算接口入账。
6. 随机事件不得直接修改球员属性、潜力、状态、技能、特性或训练结果；若事件影响球员，必须提交给运动员培养系统或技能与特性系统的对应接口处理。
7. 随机事件不得直接修改设施等级、设施状态、建设进度、维护费或布局；若事件涉及设施，必须提交给小镇建设系统处理。
8. 随机事件不得直接授予成就、声望等级或长期认可状态；若事件构成里程碑事实，只能把已确认事件事实提交给声望与成就系统消费。
9. 随机事件必须服务低压力长期成长，不得引入排行榜、限时在线、错过即损失、不可恢复惩罚或高压危机链。
10. 单个事件默认提供 1–3 个玩家可理解选项；Beta 首版不允许复杂多阶段事件树。
11. 事件选项必须清楚展示预期影响类型，例如“可能获得少量经费”“提升一名球员心情”“暂缓训练安排”，但不要求暴露全部内部公式。
12. 事件可以有轻微负面或取舍结果，但不得造成核心循环中断、关键资源归零锁死、球员永久废弃或设施永久损坏。
13. 事件出现频率必须受冷却、阶段权重和近期事件历史控制，避免连续触发同类事件造成疲劳。
14. 随机事件必须可被存档与读档系统稳定恢复；待选择事件、已确认结果、事件冷却和近期事件历史不得因读档重复触发。
15. 若事件在读档恢复后已经结算，系统必须恢复 durable outcome，不得重新抽取结果或重复发放效果。
16. 所有一次性事件结果必须具备稳定 `event_settlement_key`，并以 `processed_event_settlement_keys` 作为唯一去重账本，用于防止重复提交、重复入账、重复写历史或重复提示。
17. 随机事件系统的权威实现模块记为 `RandomEventManager`。它独占 `pending_random_event_instance`、`recent_random_event_history`、`event_cooldown_state` 和 `processed_event_settlement_keys` 的 durable truth。
18. 展示层只能消费随机事件系统输出的只读 `random_event_offer_view_payload` 与 `random_event_history_view_payload`，不得本地重新抽取事件、重算事件条件、补造选项，或自行生成事件结果。

### Event Categories

| Category | Description | Example | Main authority touched |
|---|---|---|---|
| 小镇生活事件 | 表现镇民、设施、天气和日常生活变化 | 镇民帮忙整理训练场 | 小镇建设 / 经济 |
| 球员状态事件 | 表现球员心情、关系、训练插曲 | 年轻球员主动加练 | 运动员培养 |
| 经营机会事件 | 提供轻量资源取舍 | 本地商店提出赞助 | 经济管理 |
| 比赛前后事件 | 为赛前赛后增加轻量变化 | 主场观众临时增多 | 比赛竞技 / 声望 |
| 赛季阶段事件 | 绑定月度、阶段或赛季节点 | 赛季中期镇民鼓励 | 时间与赛季 / 声望 |
| 设施相关事件 | 让设施具有生活存在感 | 医疗室收到捐赠器材 | 小镇建设 |

### Event Lifecycle

| State | Description | Enter condition | Exit condition | Valid next states |
|---|---|---|---|---|
| Event Idle | 当前没有待展示或待处理事件 | 稳定操作节点，无合法事件触发 | 时间系统进入可触发窗口并通过事件抽取 | Event Candidate Evaluation |
| Event Candidate Evaluation | 系统评估可触发事件池 | 合法触发窗口开始 | 选出 0 或 1 个事件候选 | Event Offered / Event Idle |
| Event Offered | 事件已生成并等待玩家确认或选择 | 候选事件满足条件且未被冷却拦截 | 玩家选择选项、关闭事件或系统自动确认 | Event Resolution |
| Event Resolution | 系统将选项结果转为效果请求包 | 玩家做出选择或事件自动结算 | 效果请求提交给权威系统并获得结果 | Event Feedback Pending |
| Event Feedback Pending | 等待把结果反馈挂接到主循环 UI | 权威系统返回已确认结果 | 展示轻量反馈并写入历史 | Event History Recorded |
| Event History Recorded | 事件结果、冷却和历史记录已持久化 | 反馈完成或可延后展示 | 回到稳定节点 | Event Idle |
| Event Suppressed | 当前窗口本应可触发事件，但被频率、冷却或优先级压制 | 抽取结果不合法或近期事件过密 | 记录轻量 no-op 或不展示 | Event Idle |

### Trigger Windows

1. 随机事件只能在以下窗口触发：
   - 每日开始后的稳定节点
   - 训练结算完成后的稳定节点
   - 比赛结算完成后的稳定节点
   - 赛季阶段结算后的稳定节点
   - 建设完工确认后的稳定节点
2. 随机事件不得在以下窗口触发：
   - 比赛演算过程中
   - 训练公式计算过程中
   - 经济扣费处理中
   - 存档写入过程中
   - 读档恢复尚未完成时
3. 若同一稳定节点还有比赛结果、训练成长、建设完工、声望升级或成就完成等待展示，随机事件反馈必须后置，不得抢占核心反馈。
4. 若同一天已经触发过高优先级结算反馈，随机事件可以被压制或延后到下一个合法窗口。

### Durable State Contract

随机事件系统在 Beta 首版的最小持久化边界包含：

| Field | Type | Description |
|---|---|---|
| `pending_random_event_instance` | Dictionary[String, Variant] / null | 当前待玩家处理的事件实例；若无待处理事件则为空 |
| `recent_random_event_history` | Array[Dictionary] | 近期已确认事件的稳定历史记录，用于回看、压制频率与恢复一致性 |
| `event_cooldown_state` | Dictionary[String, Variant] | 事件分类、事件 ID 或目标范围的冷却信息 |
| `processed_event_settlement_keys` | Array[String] / set-like contract | 已处理的一次性事件结果去重键集合 |

**Rule:** 这些字段属于随机事件系统 durable truth。读档恢复后只能恢复其已确认状态，不得通过 UI 缓存、本地重抽或其他系统副作用反推重建。

### Event Result Package

随机事件系统向其他系统提交的结果应包含：

| Field | Type | Description |
|---|---|---|
| `event_id` | string | 稳定事件 ID |
| `event_instance_id` | string | 本次事件实例 ID |
| `event_settlement_key` | string | 本次事件结果去重键 |
| `trigger_window` | enum/string | 触发窗口 |
| `selected_option_id` | string | 玩家选择或自动结算选项 |
| `target_scope` | enum/string | player / team / town / facility / economy / match / reputation |
| `target_id` | string/null | 目标对象 ID |
| `effect_request_type` | enum/string | 资源、球员状态、设施、声望事实等请求类型 |
| `effect_magnitude_band` | enum/string | minor / moderate |
| `rule_version` | string/int | 事件规则版本 |
| `display_priority` | int | UI 展示排序 |

## Formulas

### 1. 事件触发概率

`event_trigger_chance = clamp(base_event_chance × stage_multiplier × recent_event_suppression × category_weight, min_event_chance, max_event_chance)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 基础事件概率 | `base_event_chance` | float | 0.00–1.00 | 当前触发窗口的基础随机事件概率 |
| 阶段倍率 | `stage_multiplier` | float | 0.75–1.25 | 根据赛季阶段或系统开放度调整事件概率 |
| 近期事件压制 | `recent_event_suppression` | float | 0.25–1.00 | 近期事件过多时降低触发率 |
| 分类权重 | `category_weight` | float | 0.50–1.50 | 当前事件分类在该窗口的权重 |
| 最小事件概率 | `min_event_chance` | float | 0.00–0.05 | 保底概率，Beta 首版可为 0 |
| 最大事件概率 | `max_event_chance` | float | 0.10–0.35 | 单窗口触发概率上限 |
| 最终触发概率 | `event_trigger_chance` | float | 0.00–0.35 | 本窗口最终抽取概率 |

**Rule:** Beta 首版建议单个稳定窗口触发概率不超过 35%，避免事件压过主循环。

### 2. 近期事件压制

`recent_event_suppression = clamp(1.0 - recent_event_count × suppression_per_recent_event, min_recent_suppression, 1.0)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 近期事件数量 | `recent_event_count` | int | 0–5 | 最近 N 个游戏日或结算窗口内已触发事件数量 |
| 单事件压制量 | `suppression_per_recent_event` | float | 0.10–0.25 | 每个近期事件降低多少触发率 |
| 最低压制倍率 | `min_recent_suppression` | float | 0.25–0.50 | 触发率最低压制到的倍率 |
| 近期事件压制 | `recent_event_suppression` | float | 0.25–1.00 | 最终压制倍率 |

**Rule:** 事件压制只影响新事件触发，不取消已经生成并等待处理的事件。

### 3. 事件权重抽取

`event_selection_score = event_base_weight × category_context_weight × eligibility_weight × cooldown_weight`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 事件基础权重 | `event_base_weight` | int/float | > 0 | 事件内容表中定义的基础出现权重 |
| 分类上下文权重 | `category_context_weight` | float | 0.25–2.00 | 当前阶段、触发窗口与事件分类的匹配程度 |
| 合法性权重 | `eligibility_weight` | float | 0 或 1 | 不满足条件则为 0 |
| 冷却权重 | `cooldown_weight` | float | 0 或 1 | 冷却中则为 0 |
| 事件抽取分 | `event_selection_score` | float | ≥ 0 | 用于加权抽取的最终分值 |

**Rule:** `event_selection_score = 0` 的事件不得被抽中。若所有候选均为 0，本窗口进入 `Event Suppressed` 或回到 `Event Idle`。

### 4. 事件结果去重键

`event_settlement_key = stable_digest(canonical_join([event_instance_id, selected_option_id, target_scope, target_id], "|"))`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 事件实例 ID | `event_instance_id` | string | non-empty | 本次随机事件实例的稳定 ID |
| 选择 ID | `selected_option_id` | string | non-empty | 玩家选择或自动结算选项 |
| 目标作用域 | `target_scope` | enum/string | non-empty | player / team / town / facility / economy / match / reputation |
| 目标 ID | `target_id` | string/null | nullable | 目标对象 ID；无单一目标时使用固定空值语义 |
| 规则版本 | `rule_version` | string/int | non-empty | 事件规则版本；只作为 evaluation / history / migration metadata，不进入 durable settlement identity |
| 事件去重键 | `event_settlement_key` | string | stable digest | 用于防止重复提交事件结果 |

**Rule:** 若 `event_settlement_key` 已存在于 `processed_event_settlement_keys`，本系统必须返回幂等 no-op，不重复提交效果请求、不重复写入历史、不重复展示奖励。仅 `rule_version` 变化时，不得生成新的 `event_settlement_key`，也不得因此重复结算同一事件结果。

## Edge Cases

- **If 当前稳定窗口没有任何合法事件**: 系统不展示事件，不提示“没有事件”，直接保持主循环安静推进。
- **If 近期事件过密**: 使用 `recent_event_suppression` 降低触发率，必要时进入 `Event Suppressed`，避免事件疲劳。
- **If 事件抽中后目标对象失效**: 重新校验目标；若仍无合法目标，则取消该事件并记录 no-op，不从其他系统临时猜测替代目标。
- **If 玩家读档后存在待选择事件**: 必须恢复 `pending_random_event_instance` 中同一个 `event_instance_id`、选项和目标，不重新抽取事件池，也不得补造默认选项。
- **If 玩家读档后事件已经结算**: 必须恢复 `recent_random_event_history`、`event_cooldown_state` 和 `processed_event_settlement_keys` 的已确认结果，不重复提交效果请求。
- **If 同一 `event_settlement_key` 被重复提交**: 返回幂等 no-op，不重复发放资源、不重复修改状态、不重复展示反馈。
- **If 事件结果涉及资源变化但经济系统拒绝结算**: 事件反馈显示温和失败或改为无资源结果，不直接修改资源。
- **If 事件结果涉及球员但球员当前不可用**: 事件结果必须降级为 no-op 或改为队伍级轻量反馈，不修改不存在或非法球员。
- **If 事件涉及设施但设施状态变化中**: 必须等待小镇建设系统判断是否合法；UI 不提前展示设施已变化。
- **If 事件与比赛日核心结算冲突**: 比赛、成长、声望等核心反馈优先；随机事件延后或压制。
- **If 玩家忽略或关闭事件弹窗**: Beta 首版可默认保留在待处理事件入口，或使用无惩罚默认选项；不得因关闭事件造成损失。
- **If 事件文案暗示高压失败**: 必须改为低压力表达，例如“经费偏紧”而不是“危机”或“破产”。
- **If 事件规则版本更新**: 已结算事件历史保持旧版本可解释；未结算事件可按迁移规则重建或取消，但不得重复奖励。
- **If 同一天多个系统都请求事件展示**: 按 `display_priority DESC → event_instance_id ASC` 稳定排序，Beta 首版默认只展示 1 个事件。
- **If 事件结果需要成就或声望识别**: 只提交已确认事实给声望与成就系统，不直接解锁成就或增加声望。

## Dependencies

随机事件系统位于 Feature / Beta 层，是小镇生活感和赛季变化来源。它依赖核心系统提供稳定事实和合法操作边界，但不得反向扩大 MVP 范围。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 定义低压力、小镇生活感和轻度经营支柱 | 低压力事件语气、小镇幻想、反高压约束 |
| `design/gdd/systems-index.md` | Hard | 定义本系统层级、优先级和依赖方向 | Beta 定位、依赖关系、推荐设计顺序 |
| `design/gdd/time-and-season-progression-system.md` | Hard | 提供合法触发窗口、稳定节点和赛季上下文 | 当前日期、阶段、赛季节点、可触发窗口 |
| `design/gdd/economy-management-system.md` | Hard | 资源变化必须由经济系统结算 | 资源变动请求、可结算性、幂等入账 |
| `design/gdd/player-development-system.md` | Hard | 球员相关事件必须由培养系统处理 | 球员状态、训练上下文、成长事件入口 |
| `design/gdd/town-building-system.md` | Hard | 设施相关事件必须由建设系统处理 | 设施状态、设施目标合法性、建设/维护上下文 |
| `design/gdd/save-and-load-system.md` | Hard | 待处理事件、历史和去重账本必须可恢复 | 事件实例、事件历史、冷却、去重键持久化 |
| `design/gdd/match-competition-system.md` | Soft | 比赛日前后事件需要读取比赛上下文 | 比赛结果、主客场、关键比赛标签 |
| `design/gdd/reputation-and-achievement-system.md` | Soft | 事件里程碑可被长期认可系统消费 | 已确认事件事实、里程碑标签 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 随机事件系统 | What must be back-referenced later |
|---|---|---|---|
| 主循环 UI 框架 | Hard | 事件入口、事件弹窗、待处理事件提示、轻量反馈顺序 | 必须声明随机事件展示不抢占核心结算反馈 |
| 新手引导系统 | Soft | 首次事件解释、事件选择说明 | 必须说明事件是低压力插曲，不是任务清单 |
| 教程与提示系统 | Soft | 事件分类说明、效果类型说明 | 必须承接事件选项的低压力解释 |
| 音频系统 | Soft | 事件出现、选择确认、轻量结果反馈 | 音效不得制造危机感或打断主循环节奏 |

### Dependency Rules

1. 本系统不得新增资源类型、时间阶段、球员属性、设施类型或比赛公式。
2. 本系统不得绕过权威系统直接修改资源、球员、设施、时间、声望或成就。
3. 所有事件效果必须先转换为效果请求包，再由对应系统确认并返回结果。
4. 随机事件触发窗口由时间与赛季推进系统拥有；本系统只在合法窗口内抽取事件。
5. 存档与读档系统必须持久化待处理事件、已结算事件历史、事件冷却和事件去重账本。
6. UI 只能消费本系统生成的只读 `random_event_offer_view_payload` 与 `random_event_history_view_payload`，不得自行抽取事件、重算事件条件、补造选项或生成结果。
7. 若后续事件要引入多阶段剧情链，必须先修订本 GDD 的生命周期、持久化和冷却规则。

## Tuning Knobs

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 基础事件概率 `base_event_chance` | 每个合法窗口触发事件的基础概率 | 0.05–0.25 | 事件过密，打断主循环 | 世界变化不足 | 小镇活力、节奏 |
| 单日事件上限 `daily_event_cap` | 每个游戏日最多触发事件数 | 0–1 / Beta 首版 1 | 事件疲劳 | 变化不足 | 信息密度 |
| 近期事件窗口 `recent_event_window_days` | 用于压制频率的历史天数 | 3–7 天 | 压制过久，事件稀少 | 压制不足，事件连发 | 节奏稳定性 |
| 事件选项数量 `event_option_count` | 单个事件可选项数 | 1–3 | 决策压力过强 | 互动感不足 | 低压力决策 |
| 轻量正面结果比例 `positive_event_ratio` | 正面或温和结果占比 | 60–80% | 事件变成福利刷取 | 事件偏惩罚 | 低压力感 |
| 资源事件强度 `event_resource_magnitude_band` | 事件资源变化强度 | minor / moderate | 经济被事件主导 | 事件反馈过弱 | 经济扰动 |
| 球员事件目标数量 `player_event_target_count` | 单个球员事件影响人数 | 1–2 | 影响过广难追踪 | 事件存在感弱 | 球员情感连接 |
| 设施事件冷却 `facility_event_cooldown_days` | 同类设施事件最短间隔 | 7–21 天 | 设施事件太稀少 | 设施事件刷屏 | 小镇生活感 |
| 首屏事件反馈上限 `event_feedback_visible_limit` | 单次结算流展示事件反馈数量 | 1 | 信息过载 | 玩家错过变化 | UI 节奏 |
| 事件历史保留数量 `event_history_limit` | 可回看的近期事件数量 | 20–50 | 存档/界面冗余 | 记忆感不足 | 世界连续性 |

## Acceptance Criteria

- **GIVEN** 时间系统进入合法稳定触发窗口，**WHEN** 随机事件系统执行触发判定，**THEN** 只能在该窗口内抽取事件，不得在比赛、训练、扣费或存档半结算过程中插入事件。
- **GIVEN** 当前窗口没有合法事件候选，**WHEN** 系统完成判定，**THEN** 不展示事件并返回常规主循环，不得生成空事件或错误提示。
- **GIVEN** 一个事件被抽中，**WHEN** QA 检查事件 payload，**THEN** 必须包含 `event_id`、`event_instance_id`、`trigger_window`、合法目标和可展示选项。
- **GIVEN** 玩家选择事件选项，**WHEN** 系统结算结果，**THEN** 随机事件系统必须生成效果请求包并提交给对应权威系统，不得直接修改资源、球员、设施或时间状态。
- **GIVEN** 事件结果涉及经费或运动点数变化，**WHEN** QA 检查调用边界，**THEN** 资源变化必须通过经济管理系统入账。
- **GIVEN** 事件结果涉及球员状态或成长影响，**WHEN** QA 检查调用边界，**THEN** 影响必须通过运动员培养系统或技能与特性系统处理。
- **GIVEN** 事件结果涉及设施状态或设施效果，**WHEN** QA 检查调用边界，**THEN** 影响必须通过小镇建设系统处理。
- **GIVEN** 同一 `event_settlement_key` 被重复提交，**WHEN** 随机事件系统处理该输入，**THEN** 必须返回幂等 no-op，不重复提交效果、不重复写入历史、不重复展示反馈。
- **GIVEN** 玩家在事件待选择状态保存并读档，**WHEN** 游戏恢复，**THEN** 必须从 `pending_random_event_instance` 恢复同一个事件实例、选项、目标和显示状态，不得重新抽取事件。
- **GIVEN** 玩家在事件结算后保存并读档，**WHEN** 游戏恢复，**THEN** 必须恢复 `recent_random_event_history`、`event_cooldown_state` 与 `processed_event_settlement_keys` 的已确认状态，不得重复发放事件结果。
- **GIVEN** 近期事件数量达到压制阈值，**WHEN** 新窗口进行事件触发判定，**THEN** `recent_event_suppression` 必须降低触发概率或压制事件。
- **GIVEN** 同一稳定节点存在比赛结算、成长反馈、声望反馈和随机事件反馈，**WHEN** UI 展示结果，**THEN** 随机事件反馈必须后置，不得抢占核心结算。
- **GIVEN** 玩家关闭事件提示，**WHEN** QA 检查结果，**THEN** 不得造成惩罚式损失；系统必须保留待处理入口或使用无惩罚默认处理。
- **GIVEN** 事件选项包含负面取舍，**WHEN** QA 检查文案和结果，**THEN** 该结果不得造成不可恢复失败、资源锁死、球员永久废弃或设施永久损坏。
- **GIVEN** 随机事件系统已经生成待处理事件，**WHEN** QA 保存并读档恢复，**THEN** `pending_random_event_instance`、`recent_random_event_history`、`event_cooldown_state` 与 `processed_event_settlement_keys` 必须与保存前一致，且不得因恢复重新抽取、重复结算或丢失待处理事件。
- **GIVEN** UI 展示事件列表或事件弹窗，**WHEN** QA 检查数据绑定，**THEN** UI 只能消费随机事件系统提供的只读 `random_event_offer_view_payload` 与 `random_event_history_view_payload`，不得本地抽取事件、重算条件、补造选项或生成结果。
