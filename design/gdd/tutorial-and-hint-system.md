# 足球小镇：教程与提示系统

> **Status**: Designed  
> **Author**: 用户 + Claude  
> **Last Updated**: 2026-06-03  
> **Implements Pillar**: 低压力长期成长、轻度足球经营、像素小镇养成  
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/onboarding-system.md`
> - `design/gdd/main-loop-ui-framework.md`
> - `design/gdd/player-development-system.md`
> - `design/gdd/player-management-ui.md`
> - `design/gdd/match-performance-ui.md`
> - `design/gdd/town-management-ui.md`
> - `design/gdd/reputation-and-achievement-system.md`
> - `design/gdd/skill-and-trait-system.md`
> - `design/gdd/random-event-system.md`

## Overview

教程与提示系统是《足球小镇》中负责承接规则说明、上下文帮助和中长期理解支持的 Alpha Polish 层系统。它不拥有训练、比赛、建设、经济、声望、技能、随机事件、时间推进或存档规则，也不新增任务链、奖励循环、效率清单或第二套目标体系；它只消费新手引导完成标记、主循环 UI 锚点、各系统的权威只读 payload 与解释口径，在合适的界面位置提供低压力、可忽略、可回看的说明。该系统的目标是在不打断主循环、不制造焦虑的前提下，让玩家逐步理解“为什么这里有提示”“这个数值大概代表什么”“我可以从哪里查看更多说明”。

## Player Fantasy

玩家在教程与提示系统中应感受到：“游戏在我需要时温和解释，而不是催我照着清单优化。”提示应该像小镇教练或熟悉的队务提醒玩家注意信息：训练效率变低时解释影响来源，第一次看到声望解锁时说明长期目标，遇到随机事件时提醒这是生活插曲而非限时任务，看到技能候选时说明它代表球员成长痕迹而不是必须追逐的 build 路线。

好的教程与提示不应让玩家觉得被考试、被催促或被评价操作好坏。它应该帮助玩家建立长期心智模型：哪些界面是核心操作，哪些反馈只是说明，哪些变化来自其他权威系统。玩家可以阅读、展开、忽略或稍后回看这些提示，而不会因此错过奖励、受到惩罚或破坏当前流程。

## Detailed Rules

### Core Rules

1. 教程与提示系统是 Alpha Polish / UX Support 层系统，不属于 MVP 首次闭环的必需权威系统。
2. 本系统只负责提示触发判定、提示内容选择、提示显示频率、帮助入口组织、提示历史语义和说明文本承接，不拥有任何玩法结果的修改权。
3. 本系统不得直接修改时间、资源、球员、训练、比赛、设施、声望、成就、技能、特性、随机事件或存档状态。
4. 本系统不得新增任务链、每日目标、奖励循环、成就条件、训练推荐、build 路线、效率待办或限时提示。
5. 本系统不得把提示关闭、忽略或稍后查看解释为玩家失败；关闭提示不得造成资源损失、成长损失、事件损失或解锁延迟。
6. 本系统必须基于新手引导系统提供的引导完成标记区分首次用户和回访用户；首次引导流程由新手引导系统负责，本系统不得重写首日教学闭环。
7. 本系统必须使用主循环 UI 框架、球员管理 UI、比赛表现 UI、建设与经营 UI 等系统定义的界面锚点、屏幕标识和信息层级，不得自行重排界面流程。
8. 本系统解释任何系统规则时，必须引用该权威系统的口径或只读 payload，不得另写一套训练效率、比赛结果、经济压力、建设收益、声望目标、技能候选或随机事件规则。
9. 提示内容必须以低压力语气表达，优先使用“可以查看”“这里说明”“当前影响来自”这类解释性措辞，不得使用“必须”“立刻”“错过”“失败”“惩罚”等高压措辞。
10. 单次自动出现的提示默认只包含一个界面锚点、一句核心说明和一个可选展开入口；长说明必须放入可主动打开的帮助面板或词条中。
11. 自动提示必须受冷却、频率上限、用户偏好和同屏信息密度控制，避免连续弹出造成教程疲劳。
12. 同一稳定结算流中，比赛结果、训练成长、建设完工、资源变化、声望/成就、随机事件等核心反馈优先；教程与提示只能后置或以非抢焦点方式显示。
13. 本系统可以记录提示是否已看过、是否被关闭、是否被禁用、是否进入帮助索引，但这些记录只能影响提示显示，不得影响玩法结算。
14. 本系统可以提供上下文“了解更多”入口，将玩家带到说明面板或词条，但不得自动跳转到训练、建设、阵容调整或其他操作界面。
15. 本系统必须允许玩家在设置或帮助入口中降低提示频率、隐藏自动提示或重新查看基础说明。
16. 本系统必须兼容存档恢复；已显示提示、关闭状态、提示冷却和帮助索引解锁状态不得因读档重复刷屏或丢失。
17. 本系统不得在存档写入、读档恢复、比赛演算、训练结算、经济扣费或其他半结算状态中插入自动提示。
18. 若权威系统 payload 不存在、缺失或版本不兼容，本系统必须静默不显示对应提示或显示通用帮助入口，不得猜测规则内容。

### Hint Categories

| Category | Description | Example | Main source of truth |
|---|---|---|---|
| 首次回访提示 | 玩家完成新手引导后再次进入系统时的轻量提醒 | “训练效果会受体力和设施影响。” | 新手引导 / 主循环 UI |
| 上下文解释提示 | 对当前界面中已有信息做低压力解释 | “这个标记表示近期成长方向。” | 对应界面与权威系统 payload |
| 规则词条提示 | 帮助面板中的可回看规则说明 | “维护费会在日常结算中处理。” | 经济 / 建设 / 时间系统 |
| 状态变化提示 | 对已发生变化做解释，不提前预测结果 | “这次变化来自赛后结算。” | 比赛 / 培养 / 经济系统 |
| 长期目标提示 | 解释声望、成就和阶段目标的含义 | “声望等级代表小镇认可度。” | 声望与成就系统 |
| 内容插曲提示 | 解释随机事件、技能候选等非核心压力内容 | “随机事件是小镇生活插曲。” | 随机事件 / 技能与特性系统 |

### Hint Lifecycle

| State | Description | Enter condition | Exit condition | Valid next states |
|---|---|---|---|---|
| Hint Idle | 当前没有待展示自动提示 | 稳定 UI 状态，无合法提示触发 | 进入合法提示检查窗口 | Hint Eligibility Check |
| Hint Eligibility Check | 检查用户状态、界面锚点、频率与 payload | 合法 UI 稳定节点出现 | 选出 0 或 1 条提示候选 | Hint Offered / Hint Suppressed / Hint Idle |
| Hint Offered | 提示以非抢焦点方式展示 | 候选满足条件且未被频率压制 | 玩家关闭、展开、忽略或切换界面 | Hint Acknowledged / Hint Expanded / Hint Suppressed |
| Hint Expanded | 玩家主动打开更多说明 | 玩家选择“了解更多”或帮助入口 | 玩家关闭帮助面板或返回原界面 | Hint Acknowledged |
| Hint Acknowledged | 提示显示记录、冷却和偏好状态已更新 | 玩家关闭、读完或系统记录已展示 | 回到稳定 UI 状态 | Hint Idle |
| Hint Suppressed | 合法提示被频率、优先级、用户偏好或缺失 payload 压制 | 检查失败或更高优先反馈存在 | 可选择记录 no-op 或不记录 | Hint Idle |

### Display Principles

1. 自动提示默认使用轻量角标、侧边短提示、信息图标或非模态浮层，不使用全屏阻断式弹窗。
2. 提示必须附着在已有 UI 锚点或帮助入口上，不得凭空覆盖主要操作区域。
3. 若同屏已有比赛、训练、建设、资源、声望、随机事件等反馈，提示必须降低优先级或延后。
4. 帮助词条可以提供更完整说明，但仍必须引用权威系统语义，不允许新增隐藏公式或设计师建议路线。
5. 提示可说明“影响类型”和“信息来源”，但不应把玩家导向唯一最优解。

## Formulas

### 1. 提示合法性评分

`hint_eligibility_score = anchor_available × payload_available × onboarding_weight × context_relevance × novelty_weight × user_preference_weight × cooldown_weight`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 界面锚点可用 | `anchor_available` | int | 0 or 1 | 当前屏幕是否存在提示可附着的合法 UI 锚点 |
| 权威 payload 可用 | `payload_available` | int | 0 or 1 | 对应系统是否提供可解释的只读状态或说明口径 |
| 引导状态权重 | `onboarding_weight` | float | 0.50–1.25 | 根据玩家是否完成新手引导调整提示资格 |
| 上下文相关度 | `context_relevance` | float | 0.00–1.00 | 当前界面、系统状态和提示主题的匹配程度 |
| 新鲜度权重 | `novelty_weight` | float | 0.25–1.00 | 基于 `seen_hint_records`、近期同类提示记录和 `hint_version` 判断该提示是否仍有说明价值 |
| 用户偏好权重 | `user_preference_weight` | float | 0.00–1.00 | 玩家设置中的提示频率偏好；关闭自动提示时为 0 |
| 冷却权重 | `cooldown_weight` | int | 0 or 1 | 同类提示是否仍在冷却中 |
| 提示合法性评分 | `hint_eligibility_score` | float | 0.00–1.25 | 用于判断提示是否可进入候选池 |

**Rule:** 若 `anchor_available = 0`、`payload_available = 0`、`user_preference_weight = 0` 或 `cooldown_weight = 0`，该提示不得自动展示。`hint_eligibility_score` 只决定说明展示资格，不影响任何玩法结算。

**Example:** 一个已完成新手引导的玩家在训练界面第一次看到训练效率说明：`1 × 1 × 1.0 × 0.9 × 1.0 × 1.0 × 1 = 0.9`，若阈值为 `0.50`，则可进入提示候选池。

### 2. 提示展示优先级

`hint_display_priority = clamp(base_hint_priority + context_priority_bonus - core_feedback_penalty - recent_hint_penalty, 0, max_hint_priority)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 基础提示优先级 | `base_hint_priority` | int | 0–100 | 提示内容表中定义的基础优先级 |
| 上下文优先级加成 | `context_priority_bonus` | int | 0–30 | 当前界面首次访问、首次遇到系统状态等带来的加成 |
| 核心反馈占用惩罚 | `core_feedback_penalty` | int | 0–100 | 比赛、训练、建设、资源、声望、随机事件等核心反馈存在时降低提示优先级 |
| 近期提示惩罚 | `recent_hint_penalty` | int | 0–50 | 同屏或近期已展示提示时降低优先级 |
| 最大提示优先级 | `max_hint_priority` | int | 100 | 提示排序上限 |
| 提示展示优先级 | `hint_display_priority` | int | 0–100 | 多个候选提示之间的稳定排序依据 |

**Rule:** 自动提示只能在没有更高优先核心反馈抢占焦点时展示。若 `core_feedback_penalty` 将结果压到 0，则该提示应延后或压制。

**Example:** 一个基础优先级 60 的声望说明在声望升级反馈同屏出现时：`clamp(60 + 10 - 80 - 0, 0, 100) = 0`，系统不自动弹出说明，改为在反馈完成后提供帮助入口。

### 3. 近期提示压制

`recent_hint_penalty = min(recent_hint_count × penalty_per_recent_hint, max_recent_hint_penalty)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 近期提示数量 | `recent_hint_count` | int | 0–10 | 最近 N 分钟、N 个界面切换或 N 个游戏日内已自动展示的提示数量 |
| 单条提示惩罚 | `penalty_per_recent_hint` | int | 5–15 | 每条近期提示降低多少展示优先级 |
| 最大近期提示惩罚 | `max_recent_hint_penalty` | int | 30–50 | 近期提示对优先级的最大压制值 |
| 近期提示惩罚 | `recent_hint_penalty` | int | 0–50 | 用于减少连续提示刷屏 |

**Rule:** 近期提示压制只影响自动提示展示，不影响玩家主动打开帮助面板或词条。

**Example:** 最近已自动展示 3 条提示、单条惩罚为 10、最大惩罚为 40，则 `recent_hint_penalty = min(3 × 10, 40) = 30`。

### 4. 提示冷却结束窗口

`hint_cooldown_until = current_stable_window_index + base_hint_cooldown_windows × category_cooldown_multiplier`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 当前稳定窗口序号 | `current_stable_window_index` | int | ≥ 0 | UI 或主循环稳定节点的递增序号 |
| 基础提示冷却窗口 | `base_hint_cooldown_windows` | int | 1–20 | 同一提示再次自动出现前需要经过的稳定窗口数 |
| 分类冷却倍率 | `category_cooldown_multiplier` | float | 0.50–3.00 | 不同提示分类的冷却倍率 |
| 冷却结束窗口 | `hint_cooldown_until` | int | ≥ current | 自动提示可再次展示的最早稳定窗口 |

**Rule:** 冷却只限制自动提示重复出现，不限制帮助索引中的主动查看。若计算结果不是整数稳定窗口，必须向上取整，避免冷却提前结束。

**Example:** 当前稳定窗口为 40，基础冷却为 6，分类倍率为 1.5，则 `hint_cooldown_until = ceil(40 + 6 × 1.5) = 49`，第 49 个稳定窗口前不再自动展示同类提示。

### 5. 提示记录去重键

`hint_record_key = stable_digest(canonical_join([hint_id, anchor_id, payload_source_id, hint_version], "|"))`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 提示 ID | `hint_id` | string | non-empty | 内容表中稳定的提示标识 |
| 锚点 ID | `anchor_id` | string | non-empty | UI 系统定义的稳定界面锚点 |
| payload 来源 ID | `payload_source_id` | string | non-empty | 权威系统或 view payload 的稳定来源标识 |
| 提示版本 | `hint_version` | string/int | non-empty | 提示文案或触发规则版本 |
| 提示记录去重键 | `hint_record_key` | string | stable digest | 防止同一提示在读档、切屏或重复刷新时刷屏 |

**Rule:** 若 `hint_record_key` 已处于当前冷却或已被用户永久隐藏，本系统不得重复自动展示该提示；但帮助索引仍可显示对应说明。

## Edge Cases

- **If 玩家尚未完成新手引导**: 本系统只允许显示由新手引导系统显式授权的辅助说明，不抢占或重排首次引导步骤。
- **If 玩家已完成新手引导并回访某界面**: 可显示一次低压力回访提示，但必须受冷却和频率上限限制。
- **If 当前界面缺少合法 UI 锚点**: 不展示自动提示，不创建悬空浮层，不猜测提示位置。
- **If 对应权威 payload 缺失或版本不兼容**: 静默压制该提示或显示通用帮助入口，不自行推导规则含义。
- **If 同一稳定节点存在比赛、训练、建设、资源、声望、成就或随机事件反馈**: 核心反馈优先，提示延后、压制或以非抢焦点信息图标出现。
- **If 玩家连续切换界面触发多个提示候选**: 只展示最高优先级且合法的一条，其余进入冷却、压制或等待下一个稳定窗口重新判定。
- **If 玩家关闭单条提示**: 记录该提示的关闭状态和冷却，不重复刷屏；不得影响玩法状态或奖励。
- **If 玩家关闭全部自动提示**: `user_preference_weight` 变为 0，自动提示停止；帮助索引和主动查看入口仍保留。
- **If 玩家读档后恢复到曾经展示提示的界面**: 必须恢复 `seen_hint_records`、`hint_cooldown_state` 和用户偏好，不因读档重复自动弹出同一提示。
- **If 玩家读档后恢复到新系统首次可见状态**: 若提示从未展示且满足冷却、锚点、payload 与偏好条件，可在稳定窗口展示一次。
- **If 提示文案版本更新**: 已看过旧版本的记录保持可解释；新版本是否可再次展示必须由 `hint_version` 和冷却规则决定，不得无条件刷屏。
- **If 某提示可能被理解为唯一最优解**: 文案必须改为解释影响来源或信息含义，不给出强制路线。
- **If 提示涉及资源不足、训练效率下降或比赛失利**: 必须使用低压力说明，避免“失败”“惩罚”“必须修正”等措辞。
- **If 帮助索引中存在尚未开放系统的词条**: 默认隐藏或显示为未开放说明，不提前暴露未解锁规则细节。
- **If UI 缩放、文本长度或本地化导致提示遮挡操作**: 提示应改为帮助入口或非自动展示，不覆盖主要按钮。
- **If 玩家在提示显示时进入存档写入、读档恢复或结算流程**: 自动提示立即关闭或延后，不在半结算态继续展示。
- **If 多个系统提供同一概念的解释口径**: 本系统必须选择权威来源，不合并出新的混合规则。
- **If 提示记录去重键重复提交**: 返回幂等 no-op，不重复记录、不刷新冷却、不再次展示。

## Dependencies

教程与提示系统是 Polish 层说明与支持系统。它依赖已经设计完成的规则系统、UI 系统和新手引导系统提供稳定语义、界面锚点与用户状态；它不得反向改变任何上游系统的规则边界。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 定义低压力长期成长、小镇语气和反高压体验 | 低压力文案原则、核心支柱、禁止焦虑化表达 |
| `design/gdd/systems-index.md` | Hard | 定义本系统层级、优先级和依赖方向 | Alpha Polish 定位、设计顺序、系统边界 |
| `design/gdd/onboarding-system.md` | Hard | 区分首次引导和回访提示 | 引导完成标记、步骤锚点、首次体验边界 |
| `design/gdd/main-loop-ui-framework.md` | Hard | 提供主界面锚点、信息层级和反馈排序 | screen_id、anchor_id、反馈优先级、非抢焦点容器 |
| `design/gdd/player-management-ui.md` | Hard | 提供球员信息区说明锚点 | 球员列表、详情区、状态区、技能/特性展示锚点 |
| `design/gdd/match-performance-ui.md` | Hard | 提供比赛界面说明锚点和操作顺序 | 赛前、赛中、赛后界面分区与提示位置 |
| `design/gdd/town-management-ui.md` | Hard | 提供建设界面说明锚点 | 设施效果、维护费、资源不足提示位置 |
| `design/gdd/player-development-system.md` | Hard | 提供训练、潜力、状态和 ROI 解释口径 | 训练效率、成长反馈、状态影响、资源取舍说明 |
| `design/gdd/balance-system.md` | Hard | 提供共享数值概念和边界口径 | 资源意义、成长边界、公式说明来源 |
| `design/gdd/time-and-season-progression-system.md` | Hard | 提供时间推进和赛季节点解释口径 | 日期、阶段、稳定窗口、关键节点说明 |
| `design/gdd/save-and-load-system.md` | Hard | 提供提示偏好和历史恢复约束 | 已看提示、冷却、用户偏好、帮助索引状态持久化 |
| `design/gdd/reputation-and-achievement-system.md` | Soft | 提供长期目标、声望和成就说明口径 | `reputation_view_payload`、`achievement_view_payload`、阶段目标语义 |
| `design/gdd/skill-and-trait-system.md` | Soft | 提供技能/特性候选与身份痕迹说明口径 | 技能/特性展示 payload、候选说明、低压力身份标签 |
| `design/gdd/random-event-system.md` | Soft | 提供随机事件分类和低压力插曲说明口径 | `random_event_offer_view_payload`、`random_event_history_view_payload`、事件效果类型说明 |
| `design/gdd/economy-management-system.md` | Soft | 提供资源不足、维护费和经营压力说明口径 | 资源状态、费用来源、软压力说明 |
| `design/gdd/match-competition-system.md` | Soft | 提供比赛结果和战术影响说明口径 | 比赛摘要、结果来源、战术标签语义 |
| `design/gdd/town-building-system.md` | Soft | 提供设施效果和建设状态说明口径 | 设施状态、设施效果、建设/维护语义 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 教程与提示系统 | What must be back-referenced later |
|---|---|---|---|
| 主循环 UI 框架 | Hard | 提示入口、帮助索引入口、非抢焦点提示容器、提示反馈排序 | 必须声明其 UI 容器是本系统唯一展示承载层 |
| 新手引导系统 | Hard | 引导结束后的回访提示策略和帮助入口承接 | 必须声明首次引导完成后由本系统接管中长期说明 |
| 球员管理 UI | Soft | 球员详情、状态、技能/特性的说明入口 | 必须声明提示不新增球员操作按钮或训练推荐 |
| 比赛表现 UI | Soft | 比赛界面、赛后摘要和战术结果的说明入口 | 必须声明提示不重排比赛流程或遮挡赛后核心反馈 |
| 建设与经营 UI | Soft | 设施、维护费、资源不足和建设效果说明入口 | 必须声明提示不改变低压力文案和建设操作顺序 |
| 存档与读档系统 | Hard | 已看提示、提示冷却、用户偏好和帮助索引状态 | 必须声明这些字段只影响说明展示，不影响玩法状态 |
| 本地化系统 / 文本管线 | Future | 可翻译提示文本、词条标题和展开说明 | 未提供专用系统前，提示文本必须先使用普通文本 key 管理，并保留低压力语气检查 |
| 可访问性设置 | Future | 提示频率、文本大小、自动提示开关和可回看帮助入口 | 未提供专用系统前，必须至少支持自动提示关闭和通过帮助入口主动回看 |

### Durable State Contract

教程与提示系统在 Alpha 首版的最小持久化边界包含：

| Field | Type | Description |
|---|---|---|
| `seen_hint_records` | Array[String] / set-like contract | 已展示或已确认的提示记录去重键集合 |
| `hint_cooldown_state` | Dictionary[String, Variant] | 提示 ID、分类或锚点范围的冷却状态 |
| `hint_user_preferences` | Dictionary[String, Variant] | 自动提示开关、频率等级、隐藏分类等玩家偏好 |
| `help_index_unlock_state` | Dictionary[String, Variant] | 帮助索引中已可见或已查看词条状态 |

**Rule:** 这些字段只影响提示显示、帮助入口和说明可回看状态，不得被其他系统用于判断资源、成长、比赛、建设、声望、技能或事件结果。

### Dependency Rules

1. 本系统不得新增或重写任何上游系统的规则、公式、状态或结算边界。
2. 本系统必须从 UI 系统取得合法锚点后才能展示上下文提示。
3. 本系统必须从权威系统或其 view payload 取得解释口径后才能展示系统说明。
4. 新手引导系统负责首次闭环教学；本系统负责引导完成后的回访说明、帮助索引和上下文解释。
5. 存档与读档系统必须持久化已看提示、提示冷却、玩家提示偏好和帮助索引状态，防止读档后重复刷屏。
6. 若某上游系统尚未提供稳定 payload 或锚点，本系统只能提供通用帮助入口，不得猜测该系统细节。
7. 所有自动提示展示必须服从主循环 UI 框架的信息优先级和非抢焦点容器规则。
8. 若后续要引入互动式教程挑战、奖励化教学任务或智能推荐路线，必须先修订本 GDD，并重新评审其是否破坏低压力边界。

## Tuning Knobs

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 自动提示总开关 `auto_hint_enabled` | 是否允许系统主动显示提示 | true / false | 不适用 | 玩家可能错过上下文帮助 | 玩家控制权、干扰度 |
| 提示频率等级 `hint_frequency_level` | 自动提示整体频率 | off / low / normal | 提示疲劳、打断感 | 帮助不足 | 新手理解、回访体验 |
| 单屏自动提示上限 `auto_hint_per_screen_cap` | 每次进入同一屏幕最多自动提示数 | 0–1 | 同屏信息过载 | 说明不足 | UI 清爽度 |
| 单日自动提示上限 `daily_auto_hint_cap` | 每个游戏日最多自动提示数 | 0–3 | 教程感过强 | 长期系统理解慢 | 节奏与耐心 |
| 近期提示窗口 `recent_hint_window` | 近期提示压制统计窗口 | 3–10 稳定窗口 / 1–5 分钟 | 压制过久 | 连续刷屏 | 提示节奏 |
| 单条近期提示惩罚 `penalty_per_recent_hint` | 每条近期提示降低多少优先级 | 5–15 | 重要说明被压制 | 提示连发 | 信息密度 |
| 最大近期提示惩罚 `max_recent_hint_penalty` | 近期提示压制上限 | 30–50 | 提示系统过安静 | 压制不足 | 自动提示稳定性 |
| 基础提示冷却 `base_hint_cooldown_windows` | 同类提示再次出现间隔 | 3–12 稳定窗口 | 重复提示过少，玩家遗忘 | 重复刷屏 | 记忆强化、干扰度 |
| 提示核心说明字数 `hint_short_text_limit` | 自动提示一句话长度 | 12–24 中文字 | 遮挡 UI、阅读压力 | 信息不足 | 可读性 |
| 展开说明字数 `hint_expanded_text_limit` | “了解更多”展开说明长度 | 60–180 中文字 | 帮助面板过重 | 解释不充分 | 学习深度 |
| 帮助词条默认可见数 `help_index_initial_visible_count` | 首次打开帮助索引显示词条数 | 5–12 | 信息过载 | 找不到帮助 | 帮助入口可用性 |
| 上下文相关阈值 `context_relevance_threshold` | 提示进入候选池的最低相关度 | 0.40–0.70 | 提示过少 | 提示不贴场景 | 准确性 |
| 核心反馈惩罚 `core_feedback_penalty` | 核心反馈存在时压制提示力度 | 60–100 | 提示过度后置 | 抢占结算反馈 | 反馈优先级 |
| 回访提示权重 `returning_player_hint_weight` | 引导完成后回访提示强度 | 0.50–1.25 | 老玩家被打扰 | 回访说明不足 | 长期理解支持 |
| 低压力词语检查 `low_pressure_copy_check` | 是否启用高压词语拦截 | true / false | 文案审核成本增加 | 文案可能焦虑化 | 语气一致性 |

## Acceptance Criteria

- **GIVEN** 玩家尚未完成新手引导，**WHEN** 教程与提示系统检查自动提示，**THEN** 只能显示新手引导系统显式授权的辅助说明，不得重排首次引导步骤。
- **GIVEN** 玩家已完成新手引导，**WHEN** 玩家首次回访训练、比赛、建设或球员界面，**THEN** 系统可以在合法 UI 锚点上显示最多一条低压力回访提示。
- **GIVEN** 当前屏幕没有合法 `anchor_id`，**WHEN** 提示系统进行合法性检查，**THEN** `anchor_available` 必须为 0 且不得展示悬空提示。
- **GIVEN** 对应权威系统没有提供 payload 或解释口径，**WHEN** 提示系统尝试展示系统说明，**THEN** 必须压制该提示或显示通用帮助入口，不得猜测规则内容。
- **GIVEN** 玩家关闭自动提示，**WHEN** 任意界面进入提示检查窗口，**THEN** `user_preference_weight` 必须为 0，系统不得自动展示提示。
- **GIVEN** 玩家关闭单条提示，**WHEN** 玩家读档回到同一界面，**THEN** 系统必须恢复该提示的记录和冷却，不得重复自动弹出同一提示。
- **GIVEN** 玩家主动打开帮助索引，**WHEN** 自动提示已关闭，**THEN** 玩家仍能查看已开放帮助词条。
- **GIVEN** 同一屏幕存在多个提示候选，**WHEN** 系统排序候选，**THEN** 只能展示 `hint_display_priority` 最高且合法的一条自动提示。
- **GIVEN** 同一稳定节点存在比赛结果、训练成长、建设完工、资源变化、声望/成就或随机事件反馈，**WHEN** UI 组织反馈顺序，**THEN** 教程与提示必须后置、压制或以非抢焦点入口显示。
- **GIVEN** 最近提示数量达到频率上限，**WHEN** 新提示候选出现，**THEN** `recent_hint_penalty` 必须降低其展示优先级或压制自动展示。
- **GIVEN** 同类提示仍处于 `hint_cooldown_state`，**WHEN** 玩家再次进入相同上下文，**THEN** 系统不得自动重复展示该提示。
- **GIVEN** 玩家主动点击“了解更多”，**WHEN** 系统打开展开说明，**THEN** 只能展示说明面板或帮助词条，不得自动跳转到训练、建设、阵容调整或其他操作界面。
- **GIVEN** 提示说明训练效率、资源不足、比赛失利或设施维护费，**WHEN** QA 检查文案，**THEN** 文案不得使用“必须”“立刻”“错过”“失败”“惩罚”等高压措辞。
- **GIVEN** 提示解释技能候选或特性倾向，**WHEN** QA 检查界面行为，**THEN** 提示不得生成 build 路线、训练跳转、行动按钮或效率待办。
- **GIVEN** 提示解释随机事件，**WHEN** QA 检查文案和入口，**THEN** 必须把随机事件表达为低压力生活插曲，不得包装成限时任务或奖励清单。
- **GIVEN** 提示解释声望、成就或长期目标，**WHEN** QA 检查说明来源，**THEN** 说明必须引用声望与成就系统的权威语义，不得另造目标体系。
- **GIVEN** 提示记录生成 `hint_record_key`，**WHEN** 同一 key 被重复提交，**THEN** 系统必须返回幂等 no-op，不重复记录、不刷新冷却、不再次展示。
- **GIVEN** 玩家保存并读档，**WHEN** 游戏恢复，**THEN** `seen_hint_records`、`hint_cooldown_state`、`hint_user_preferences` 与 `help_index_unlock_state` 必须与保存前一致。
- **GIVEN** 存档写入、读档恢复、比赛演算、训练结算或经济扣费正在进行，**WHEN** 提示系统收到自动展示请求，**THEN** 必须延后或压制提示，不得在半结算态插入自动提示。
- **GIVEN** UI 文本缩放或本地化导致提示遮挡主要操作，**WHEN** QA 检查可用性，**THEN** 自动提示必须改为非抢焦点入口或帮助索引，不得覆盖主要按钮。
