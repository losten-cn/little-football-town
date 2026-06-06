# 足球小镇：经济管理系统

> **Status**: Designed
> **Author**: 用户 + Claude + systems-designer + economy-designer
> **Last Updated**: 2026-05-31
> **Implements Pillar**: 轻度足球经营、低压力长期成长
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/balance-system.md`
> - `design/gdd/time-and-season-progression-system.md`
> - `design/gdd/save-and-load-system.md`
> - `E:\code\game\game-design\00-足球小镇-策划总览.md`
> - `E:\code\game\game-design\02-足球小镇-数值平衡方案.md`

## Overview

经济管理系统是《足球小镇》中负责定义三大核心资源（经费、研究点数、运动点数）的来源、消耗、周期结算与经营压力的资源控制层。它在数据层面承接数值系统定义的 `resource_settlement` 共享结算接口，把所有资源变化统一为"获得 → 积累 → 消耗 → 结算"的标准化流水；在设计层面，它把资源获取的渠道（比赛奖励、周期收入、阶段性解锁收益）和消耗出口（训练消耗、建设支出、维护成本、特殊行动费用）组织成玩家可理解、可规划的收支结构，使"钱从哪来、花在哪、值不值"成为每一轮经营决策的核心。

经济管理系统不拥有具体训练内容的收益定义（培养系统）、比赛奖励的数值口径（数值系统/比赛系统）、建设项目的具体效果（建设系统）或赛季推进的节奏（时间系统）——它拥有的是"这些行为消耗多少资源、这些行为产生多少收入、在什么时机结算、以及收支差值如何转化为玩家的经营压力或自由度"。在 MVP 阶段，本系统的目标是让玩家明确感受到：有限的经费、研究点数和运动点数迫使自己在培养、建设和比赛之间做有意义的取舍，而这种取舍正是经营乐趣的核心来源。

## Player Fantasy

经济管理系统服务的玩家幻想是："我亲手经营这座足球小镇的每一笔账，知道钱从哪来、花在哪、值不值，并因为我的精明规划让小镇一步步变得更好。"

这种幻想包含两个层面。在直接的决策面上，玩家每次面对训练投入、建设支出或比赛策略选择时，都会感受到"有限的资源必须做出取舍"的经营实感——不是让玩家为钱焦虑，而是让每一次花钱都有清晰的回报预期，每一次省钱都有明确的机会成本。在间接的基础设施面上，玩家不需要管理复杂的财务报表——系统在后台把周期收入、维护支出、结算奖励静默处理成可读的余额变化，让玩家在回到主界面时自然看到"这一轮我赚了多少、花了多少、还剩多少"，从而对自己的经营节奏建立信任。

参考那些让人感到"经营有方"而非"财务焦虑"的游戏：Football Manager 中在预算内签下合适球员的满足感，Stardew Valley 中第一季精打细算后在第二季看到农场扩张的成就感。经济管理系统必须让"钱"成为玩家规划和成长的工具，而不是惩罚和压力的来源。

## Detailed Rules

### Core Rules

**规则 1 — 资源控制权**: 经济管理系统是所有三种资源（经费、研究点数、运动点数）的唯一 faucet（来源）和 sink（消耗）授权方。其他系统可以请求资源变化（如"比赛胜利奖励 X 经费"），但必须通过经济系统定义的标准化变更接口执行，不得直接修改资源值。经济系统记录每一笔流水，保证"收入 − 支出 = 余额变化"恒成立。

**规则 2 — 资源语义边界**: 三种资源各自有明确的用途范围，不可互相转换（MVP 阶段不做兑换）:
- **经费**: 通用货币，用于建设、维护、部分训练消耗。是经营决策的主要约束。
- **研究点数**: 解锁型货币，用于解锁高级训练方法、特殊设施、战术研究。获取速度慢于经费，保证解锁节奏可控。
- **运动点数**: 行动许可型资源，代表球队/球员的体力与行动配额。每次训练、每场比赛消耗一定运动点数。运动点数每日自然恢复，是"每天能做多少事"的自然上限。

**规则 3 — 资源上下限**: 每种资源有统一的下限 `0`（不可为负）和各自的上限。上限由游戏阶段决定（可通过建设升级提升）。资源达到上限时，超出部分不累积（或触发溢出转换——非 MVP）。达到下限 `0` 时，所有需要消耗该资源的行动被锁定，直到资源恢复为正。

**规则 4 — 经费来源**: 经费通过以下途径获得:
- 比赛奖励（联赛排名奖金、单场胜负奖金——由比赛竞技系统提供奖励口径，数值系统定义公式）
- 周期收入（赛季末结算、阶段结算——由时间与赛季推进系统触发结算时机）
- 成就/声望奖励（阶段性解锁——由声望与成就系统在 Alpha 阶段接入；MVP 阶段以固定里程碑奖励代替）

**规则 5 — 研究点数来源**: 研究点数通过以下途径获得:
- 比赛中的"战术执行评分"转换（由比赛竞技系统提供评分，经济系统按转换率公式计算）
- 赛季研究基金（赛季末固定发放，由联赛与赛事结构系统提供层级系数）
- 特殊事件/成就奖励（Alpha/Beta 阶段接入）

**规则 6 — 运动点数来源**: 运动点数通过以下途径获得:
- 每日自然恢复（MVP 固定基础值，由时间与赛季推进系统触发每日结算；设施 AP 加成为 Alpha 预留）
- 休息/恢复行动（玩家主动选择跳过训练日换取额外恢复——这是"取舍"设计的关键体现）
- 赛季间歇期全恢复（赛季结束后自动回满）

**规则 7 — 运动点数作为行动约束**: 运动点数是玩家每日决策的自然节奏器。每次训练消耗 N 点，每场比赛消耗 M 点。玩家必须在"多训练几个球员"和"留够点数打比赛"之间做取舍。这是经济系统最直接、最高频的"经营实感"来源。为防止正式赛程死锁，若时间系统已进入不可跳过的 `Match Trigger` 且 AP 低于 `match_ap_cost`，经济系统允许一次 `match_day_ap_safety_grant` 把 AP 补足到本场最低开赛成本；该补足不是玩家可主动选择的恢复行动，不可用于训练或建设。同一 `match_id` 的 grant 必须具备唯一流水标识和审计字段，只允许成功执行一次。该补足只能补到差额，不得超发。该比赛若后续按 `forfeit_result_packet` 结算，资源结算仍按该正式比赛节点的一次已处理赛后结算处理，不得重复补 AP 或重复结算。 
**规则 8 — 具体数值由 Tuning Knobs 定义**: 经济系统本身不硬编码"训练花费多少经费""一场比赛奖励多少奖金"。它只定义资源的语义、来源类型和消耗类型。所有具体数值（单价、奖励量、恢复速率、上限）在 Tuning Knobs 中定义为可调参数，由数值系统提供初始值和平衡范围。

**规则 9 — 结算时机**: 资源变化只在以下稳定节点执行批量结算，不在比赛/训练过程中实时修改:
- 每日结算（运动点数自然恢复、日常维护费扣除）
- 赛后结算（比赛奖励、消耗确认）
- 阶段结算（阶段性奖金、成就奖励）
- 赛季结算（赛季末排名奖金、研究基金发放、下赛季资源重置规则）

**规则 10 — MVP 目标**: MVP 阶段的经济系统目标是验证"有限的经费和运动点数迫使玩家在培养、最小建设和比赛之间做有意义的取舍"这一核心假设。MVP 包含小镇建设系统的最小可见支撑切片，经济系统必须支持建造/升级扣费、每日维护费和设施维护费结算；设施 AP 恢复加成与球场收入倍率在 MVP 固定为 0/1.00，只作为 Alpha 预留。MVP 不需要实现研究点数的完整解锁树。经费和运动点数在界面可见并在结算中变化；研究点数在后台正常累积（接口预留），但不显示在 MVP UI 中（研究点数消费出口在 Alpha 阶段接入解锁树后开放，届时再加入 UI 展示）。

**规则 11 — 软停滞保护**: 维护费和低胜率可以让玩家进入低现金压力状态，但不得把玩家推进到需要重开档才能恢复的长期停滞。MVP 阶段的最低恢复路径由正式比赛节点和赛季结算共同承担：`match_day_ap_safety_grant` 保证不可跳过的正式比赛不会因 AP 不足死锁，负场 `post_match_funds` 至少覆盖一次最低训练经费，赛季垫底仍产生 `season_bonus_funds`，若赛季结算后经费仍低于最低常规经费操作成本，则 `season_recovery_floor_grant` 只补足到该最低操作成本。该保护不等于免成本经营，也不抵消维护费；它只禁止“无破产提示但实际已不可恢复”的隐性失败状态。

### States and Transitions

经济管理系统有五个资源聚合状态，在每次结算时评估:

| 状态 | 触发条件 | 系统行为 | 玩家感知 |
|---|---|---|---|
| **Settlement Idle** (结算空闲) | 无结算进行中 | 正常接受资源变化请求，排队等待下次结算 | 正常经营，资源值在 UI 上显示为"当前值" |
| **Resource Settlement** (资源结算中) | 时间系统发出结算信号 | 批量执行所有排队的资源变化，逐笔验证余额≥0，生成结算摘要 | UI 显示结算动画/摘要："本回合收入 X，支出 Y，净变化 Z" |
| **Warning State** (预警状态) | 任一资源低于预警阈值（如 ≤20% 上限） | 正常结算，但在结算摘要中附加预警标记 | UI 显示黄色警告色，提示"经费紧张""运动点数不足"等 |
| **Budget Preview** (预算预览) | 玩家打开训练/建设界面时 | 不修改实际资源，计算"如果执行此操作，剩余资源将变为 X" | 界面显示"当前余额 → 操作后余额"，经费不足时按钮灰化 |
| **Resource Cap Reached** (资源达上限) | 结算后任一资源 = 上限 | 该资源不再接受增加，超出部分在结算摘要中标注"已达上限" | UI 显示"已满"标记，提示玩家消耗该资源以释放获取空间 |

**状态转换规则**:
- Settlement Idle 是默认状态。每次结算信号触发 → 进入 Resource Settlement → 结算完成后评估是否进入 Warning State 或 Resource Cap Reached → 回到 Settlement Idle。
- Budget Preview 不参与状态流转——它是一个瞬时计算状态，在玩家关闭界面后立即消失。
- Resource Settlement 期间锁定所有消耗操作（防止并发修改）。

### Interactions with Other Systems

| 系统 | 数据流入经济系统 | 数据流出经济系统 | 交互时机 |
|---|---|---|---|
| **数值系统** (Hard 上游) | `resource_settlement` 结算接口定义、资源类型定义、公式参数 | 实际资源变化量（反馈给数值系统验证公式正确性） | 每次结算 |
| **时间与赛季推进系统** (Hard 上游) | 结算信号（每日/赛后/阶段/赛季）、赛季阶段标识 | 资源状态（正常/预警/达上限——影响赛季推进是否允许继续） | 每个结算节点 |
| **存档与读档系统** (Hard 上游) | 存档/读档指令 | 三种资源的当前值、流水记录、预警状态 | 存档时全量保存；读档时全量恢复 |
| **运动员培养系统** (Hard 上游·消费方) | 训练资源消耗请求（训练类型 → 消耗 X 经费 + Y 运动点数） | 资源是否充足（允许/拒绝训练）、实际扣除量 | 玩家发起训练时（Budget Preview） + 每日结算时（批量确认） |
| **比赛竞技系统** (Hard 上游·产出方) | 比赛结果 → 奖励口径（胜负/排名/评分 → 奖金基数、研究点数转换率） | 资源是否充足；不可跳过正式比赛节点可通过 `match_day_ap_safety_grant` 补足最低开赛 AP；实际奖励入账 | 赛后结算 |
| **联赛与赛事结构系统** (Hard 上游·产出方) | 联赛层级系数、赛季排名奖金表、赛季研究基金额度 | 赛季末资源入账确认 | 赛季结算 |
| **小镇建设系统** (Hard 双向) | 经济→建设: 资源充足性检查、经费扣除；建设→经济: `facility_total_maintenance`（注入 `daily_maintenance_cost`）；`facility_ap_bonus` 与 `stadium_revenue_multiplier` 在 MVP 固定为 0/1.00 或只读预留 | 经济系统在 MVP 只硬消费建设系统产出的维护费；建设系统消费经济系统的资源验证和结算 | 每日结算（维护费）、建造/升级确认（资源扣除）；AP 恢复和收入倍率若在 Alpha 启用需先修订双方 GDD |
| **主循环 UI 框架** (Hard 下游·展示方) | 资源显示请求、结算摘要展示请求 | 经费和运动点数的当前值、变化量、预警状态、结算摘要（研究点数在 MVP 阶段不在 UI 展示，Alpha 阶段接入） | 主界面渲染、结算动画触发 |
| **声望与成就系统** (Soft 下游·Alpha 阶段) | 里程碑达成信号 → 资源奖励请求 | 奖励入账确认 | Alpha 阶段接入（MVP 以固定里程碑代替） |

> **双向性说明**: 培养系统和比赛系统同时是经济系统的消费方和产出方——培养消耗资源但提升球员能力（间接提升比赛胜率和奖励），比赛消耗运动点数但产出经费和研究点数。这种"消耗 → 提升 → 更多产出 → 更多消耗"的循环是经营乐趣的核心引擎。经济系统负责让这个循环在数值上可持续——不出现"消耗殆尽无法继续"或"资源溢出失去意义"。

## Formulas

### 1. 运动点数每日恢复

The `daily_ap_recovery` formula is defined as:

`daily_ap_recovery = base_ap_recovery + facility_ap_bonus`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 基础恢复量 | `base_ap_recovery` | int | 4–6 | 每日自然恢复的运动点数，Tier 1 默认=5 |
| 设施加成 | `facility_ap_bonus` | int | MVP 固定 0；Alpha 预留 0–3 | 建设系统 AP 恢复加成；MVP 阶段不得作为正式恢复来源，Alpha 启用前必须修订小镇建设系统硬消费合同 |
| 运动点数上限 | `action_points_max` | int | 100 | 硬上限，由 Tuning Knobs 定义 |

Recovery with cap:

`action_points_new = min(action_points_max, action_points_current + daily_ap_recovery)`

**Output Range:** MVP 恢复增量 4–6 点/日；Alpha 若启用设施 AP 加成则为 4–9 点/日。结算后总值 0–100。
**Example:** 若 `action_points_current = 2`, `base_ap_recovery = 5`, `facility_ap_bonus = 0`, `action_points_max = 100`, 则 `action_points_new = min(100, 2+5) = 7`。

**Design rationale:** R=5 + 训练消耗=1AP + 比赛消耗=3AP → 玩家每天可做"3次训练+留够比赛"或"5次训练+跳过比赛"。AP 使用率自然落在 70-80%，对齐数值系统的 `action_point_use_rate_target`（0.70-0.90）。

### 2. 赛后资源奖励

Three sub-formulas converting match results into the three resources:

`post_match_funds = base_match_funds × league_tier_multiplier × match_result_multiplier × stadium_revenue_multiplier`

`post_match_research = base_match_research × tactical_rating_ratio × league_tier_multiplier`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 基础比赛经费 | `base_match_funds` | int | 200–300 | Tier 1 单场经费基数，默认=250 |
| 基础研究点数 | `base_match_research` | int | 10–20 | Tier 1 单场研究基数，默认=15 |
| 比赛结果倍率 | `match_result_multiplier` | float | 0.4–1.0 | 胜=1.0, 平=0.6, 负=0.4 |
| 联赛层级倍率 | `league_tier_multiplier` | float | 1.0–1.5 | Tier 1=1.0, Tier 2=1.3（收入增长部分被成本增长抵消） |
| 球场收入倍率 | `stadium_revenue_multiplier` | float | MVP 固定 1.00；Alpha 预留 1.00–1.40 | 小镇建设系统球场收入倍率；MVP 阶段不得放大赛后经费，Alpha 启用前必须修订双方 GDD |
| 战术评分比 | `tactical_rating_ratio` | float | 0.3–1.0 | 比赛系统输出的战术执行评分 / 满分 |
| 比赛AP消耗 | `match_ap_cost` | int | 3 | 每场比赛固定消耗（由 Tuning Knobs 定义） |

**Output Range:** MVP 经费 100–450/场；Alpha 若启用球场收入倍率则为 100–630/场。研究点数 3–30/场。
**Example:** Tier 1 联赛，胜场，MVP 球场收入倍率固定为 `stadium_revenue_multiplier = 1.00`：`post_match_funds = 250 × 1.0 × 1.0 × 1.00 = 250`；`post_match_research = 15 × 0.8 × 1.0 = 12`。负场：`post_match_funds = 250 × 1.0 × 0.4 × 1.00 = 100`（覆盖最低训练成本，防止贫困螺旋）。

### 3. 赛季结算奖励

`season_bonus_funds = base_season_bonus × ranking_multiplier × tier_multiplier`

`season_bonus_research = base_season_research × tier_multiplier`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 基础赛季奖金 | `base_season_bonus` | int | 800–1200 | Tier 1 赛季末奖金基数，默认=1000 |
| 排名倍率 | `ranking_multiplier` | float | 0.5–1.5 | 冠军=1.5, 中游=1.0, 垫底=0.5 |
| 基础研究基金 | `base_season_research` | int | 80–120 | 赛季末研究基金基数，默认=100 |
| 层级倍率 | `tier_multiplier` | float | 1.0–1.5 | 联赛层级系数 |

**Output Range:** 经费 400–2700/赛季；研究点数 80–180/赛季。
**Example:** Tier 1 中游排名：`season_bonus_funds = 1000 × 1.0 × 1.0 = 1000`；`season_bonus_research = 100 × 1.0 = 100`。

**Design rationale:** 赛季奖金占年收入 25-35%，日常比赛收入占 65-75%。研究基金固定发放（不与排名挂钩），保证即使赛季表现差，研究进度也不停滞——对齐"低压力"支柱。

### 4. 赛季软停滞恢复地板

The `season_recovery_floor_grant` formula is defined as:

`season_recovery_floor_grant = max(0, minimum_regular_funds_action_cost - funds_after_season_bonus)`

It is evaluated once per season settlement after `season_bonus_funds` has been applied.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 赛季奖金后经费 | `funds_after_season_bonus` | int | ≥0 | 应用赛季奖金和同节点支出后的经费余额 |
| 最低常规经费操作成本 | `minimum_regular_funds_action_cost` | int | 80–120 | MVP 中至少一种常规经费消耗操作的最低成本，默认=100；通常对应最低训练经费成本 |

**Output Range:** 0–120 经费/赛季结算。该值不是收入奖励，只是恢复地板补差。

**Example:** 玩家因全 Lv.5 设施维护与全负场进入赛季末 `funds_after_season_bonus = 40`，`minimum_regular_funds_action_cost = 100`，则 `season_recovery_floor_grant = max(0, 100 - 40) = 60`，赛季结算后经费为 100，玩家至少能执行一次最低常规经费操作。若 `funds_after_season_bonus = 500`，则 grant = 0。

**Worst-case MVP recovery sample:** 以 Tier 1、比赛间隔 3 天、四设施全 Lv.5 为压力样本：`daily_maintenance_cost = 25 + 31 = 56`，三天维护费为 168；负场收入为 `250 × 1.0 × 0.4 × 1.00 = 100`，因此全负场周期净额为 `100 - 168 = -68`。单靠负场无法维持正现金流，但正式比赛节点不会因 AP 死锁而中断，赛季垫底奖金至少为 `1000 × 0.5 × 1.0 = 500`；若赛季结算后余额仍低于 100，`season_recovery_floor_grant` 补足到 100。该样本证明玩家在最差低胜率维护压力下最多等待到下一次赛季结算即可恢复到至少一次常规经费操作，而不是进入不可恢复状态。

**Design rationale:** 恢复地板只在赛季结算后检查，且只补到最低操作成本，不创造可囤积收入。它保留连续维护费和低胜率造成的经营压力，同时为低压力长期成长支柱提供硬安全网。

### 5. 资源预警阈值

`warning_active = (action_points_current / max(1, action_points_max) ≤ warning_ratio) OR (funds_current ≤ funds_warning_absolute)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 预警比例 | `warning_ratio` | float | 0.15–0.25 | AP 低于此比例触发预警，默认=0.20 |
| 经费绝对预警值 | `funds_warning_absolute` | int | 80–150 | 经费低于此值触发预警，默认=100 |

**Output Range:** 布尔值 — true 进入 Warning State，UI 显示黄色警告。
**Example:** 若 `action_points_current = 15`, `action_points_max = 100`, `warning_ratio = 0.20`, 则 `15/100 = 0.15 ≤ 0.20 → warning_active = true`。

**Design note:** 经费无硬上限，不能用比率判定预警，改用绝对阈值。MVP 阶段研究点数暂不纳入预警（Alpha 阶段接入解锁树后再加）。

### 6. 预算预览

`action_affordable = (funds_current ≥ proposed_funds_cost) AND (action_points_current ≥ proposed_ap_cost) AND (research_points_current ≥ proposed_rp_cost)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 当前经费 | `funds_current` | int | ≥0 | |
| 当前运动点数 | `action_points_current` | int | ≥0 | |
| 当前研究点数 | `research_points_current` | int | ≥0 | |
| 拟消耗经费 | `proposed_funds_cost` | int | ≥0 | 来自培养/建设系统的消耗请求 |
| 拟消耗AP | `proposed_ap_cost` | int | ≥0 | |
| 拟消耗RP | `proposed_rp_cost` | int | ≥0 | |

**Output Range:** `action_affordable` 布尔值。
**Example:** 训练请求消耗 100经费 + 1AP。若 `funds_current = 250`, `action_points_current = 6`，则 `action_affordable = true`。UI 显示"当前 250 → 操作后 150"。若经费不足，按钮灰化并标明"经费不足（需 100，当前 80）"。

### 7. 标准化训练成本

Consumed by the player development system's `player_development_roi` formula.

`standardized_training_cost = funds_cost + (ap_cost × ap_to_funds_weight)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 训练经费消耗 | `funds_cost` | int | ≥0 | |
| 训练AP消耗 | `ap_cost` | int | ≥0 | |
| AP→经费权重 | `ap_to_funds_weight` | float | 40–60 | 1 AP 折合多少经费的机会成本，默认=50 |

**Output Range:** ≥0。
**Example:** 训练消耗 100经费 + 1AP，`ap_to_funds_weight = 50`，则 `standardized_training_cost = 100 + (1 × 50) = 150`。

### 8. 流水完整性（QA专用）

`settlement_valid = (resource_post == clamp(resource_pre + Σincome - Σexpense, resource_min, resource_max))`

非 gameplay 公式，QA 自动化测试使用。验证每次结算后 `收入 − 支出 = 余额变化`（含钳制修正）。

### 9. 休息行动 AP 恢复

The `rest_ap_recovery` formula is defined as:

`rest_ap_recovery = base_rest_ap_recovery`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 基础休息恢复量 | `base_rest_ap_recovery` | int | 2–5 | 跳过训练日额外恢复的 AP，默认=3 |

**Output Range:** 2–5 AP。
**Example:** 玩家选择跳过当日训练休息，`base_rest_ap_recovery = 3`，则额外恢复 3 AP（在每日恢复基础上叠加）。

**Design rationale:** 休息行动是"取舍"设计的关键体现——玩家放弃训练收益换取额外 AP。调参范围为 2-5：低于 2 则取舍无意义，高于 5 则休息成为主导策略。

### 10. 每日维护费

The `daily_maintenance_cost` formula is defined as:

`daily_maintenance_cost = base_maintenance_cost + facility_total_maintenance`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 基础维护费 | `base_maintenance_cost` | int | 20–30 | 每日固定经费扣除，默认=25 |
| 设施总维护费 | `facility_total_maintenance` | int | 0–31 | 由小镇建设系统提供，所有已建造设施的维护费之和；无设施时 = 0 |

**Output Range:** 20–61 经费/日。
**Example:** `base_maintenance_cost = 25`，小镇四设施全 Lv.5（见小镇建设系统 Formula 9 示例，`facility_total_maintenance = 31`），则 `daily_maintenance_cost = 25 + 31 = 56` 经费/日。

**Design rationale:** 每日维护费是经济系统在 MVP 阶段的唯一被动经费出口，确保经费不会无限累积（取消硬上限后，维护费成为主要囤积防护机制）。金额约等于一次训练的 1/4，低到不会造成焦虑，但持续存在是玩家规划时需要考虑的因素。

### Float-to-Int 舍入规则

所有涉及资源值的浮点计算结果统一使用 `floor()` 向下取整。此规则适用于 `post_match_funds`、`post_match_research`、`season_bonus_funds`、`season_bonus_research`、`standardized_training_cost` 等所有可能产生非整数值的公式。QA 手工计算验证时亦使用 `floor()` 确保一致性。

### Formula Ownership Notes

- `resource_settlement` 本体由数值系统拥有（balance-system.md 公式 3），经济系统在其上叠加结算时机和流水语义。
- `standardized_training_cost` 由经济系统拥有（因为经济系统定义资源相对价值）；培养系统的 `player_development_roi` 消费此值。
- 比赛奖励的具体金额由经济系统拥有；比赛系统只输出胜负/评分/战术评分等"口径"数据，不定义金额。
- 赛季奖金公式由经济系统拥有；联赛系统只输出排名/晋级/降级标签。

## Edge Cases

- **If 任一资源在结算后归零**: 该资源相关的所有消耗操作被锁定（按钮灰化），UI 显示红色"资源耗尽"标记。系统不会自动从其他资源转换，也不会弹出催促消费的提示。玩家必须等待下一个恢复节点（每日恢复/赛后/赛季末）。
- **If 任一有硬上限资源（运动点数/研究点数）达到上限且仍有增加**: `resource_settlement` 钳制到上限，超出部分丢弃。结算摘要中标注"已达上限，超出部分未计入"。系统不自动将溢出转换为其他资源（MVP 不实现溢出转换）。经费在 MVP 阶段无硬上限，不受此条约束。
- **If 两个结算信号同时到达（如每日结算与赛后结算重叠）**: 按优先级顺序串行处理——赛后结算 > 每日结算 > 阶段结算 > 赛季结算。每个结算完整执行完毕后才开始下一个。不允许两个结算交叉修改同一资源。
- **If 下游系统提交的资源消耗量超过当前余额**: Budget Preview 阶段应已拦截此请求（按钮灰化）。若因异常绕过了 Preview 直接提交，结算时拒绝该笔消耗并记录异常日志，不产生负余额。
- **If 普通界面状态下运动点数不足 `match_ap_cost`**: 比赛入口预览显示"运动点数不足（需 X，当前 Y）"并提示玩家可休息或等待恢复。若时间系统尚未进入不可跳过的 `Match Trigger`，系统不允许提前欠费开赛。
- **If 不可跳过的 `Match Trigger` 已到达且运动点数不足 `match_ap_cost`**: 经济系统执行一次 `match_day_ap_safety_grant`，补足 `match_ap_cost - action_points_current` 的差额，然后再扣除本场比赛 AP。该补足记录为系统流水，不触发资源预警解除提示，不可超过本场最低开赛所需差额。
- **If 同一 `match_id` 的 `match_day_ap_safety_grant` 因恢复、重进或重复结算请求再次到达**: 经济系统必须识别其唯一流水标识并拒绝重复发放；该比赛节点最多只能存在一笔有效 grant 流水。
- **If 同一 `match_id` 的赛后结算结果包被重复提交（包括 `forfeit_result_packet`）**: 经费、研究点数、AP 扣除与任何比赛相关资源流水都只能生效一次；重复提交不得重复入账、重复扣除或重复记录正式比赛奖励。
- **If 玩家在 Budget Preview 打开期间收到结算信号**: Preview 显示的"操作后余额"立即失效，UI 刷新为结算后最新值。Preview 是瞬时计算状态（Section C），不缓存也不阻止结算。
- **If 读档后资源值与存档时不一致**: 存档与读档系统保证资源值完整恢复。若发生版本迁移导致资源语义变化（如新增资源类型），新资源以初始默认值填充，已有资源值保持不变。迁移规则由存档系统拥有。
- **If 训练消耗请求的资源量为 0 或负数**: 视为无效请求，拒绝执行。不产生流水记录。负数消耗不得被解释为"反向增加资源"。
- **If MVP 阶段研究点数持续累积但无可消费出口**: 这是预期行为——研究点数在 Alpha 阶段接入解锁树后才成为完整经济循环。MVP 阶段研究点数在后台正常累积（接口和存储逻辑完整），但不显示在 MVP UI 中。不对"无法消费"做额外提示或惩罚。Alpha 阶段接入解锁树后，历史累积的 RP 可正常使用。
- **If 玩家因维护费与低胜率组合进入连续多日经费归零状态**: 正式比赛节点仍按时间系统推进；不可跳过比赛若 AP 不足，由 `match_day_ap_safety_grant` 补足最低开赛 AP；负场仍按 `post_match_funds` 入账。若赛季结算应用 `season_bonus_funds` 后经费仍低于 `minimum_regular_funds_action_cost`，经济系统执行一次 `season_recovery_floor_grant` 补足差额。该 grant 只在赛季结算后生效，不在每日或赛后结算中补差。
- **If 赛季末结算时玩家经费大量累积（超过 3x 月净收入）**: 系统正常入账，但结算摘要中附带提示"当前经费充足，可考虑投资训练或建设"。MVP 阶段经费无硬上限，不强制消费或丢弃溢出——提示仅为软引导。
- **If 玩家连续多日不消耗任何运动点数**: 运动点数停留在上限，每日恢复全部丢弃。系统不提示"你浪费了恢复"——低压力设计不应催促玩家行动。但连续多日不活动可能触发时间系统的闲置提示（由时间系统拥有）。
- **If 训练消耗的 AP 同时被多个球员的并行训练请求占用**: 经济系统按请求提交顺序串行检查。第一笔训练消耗后余额更新，第二笔训练基于新余额重新检查。若第二笔余额不足则拒绝，并提示"运动点数不足"。
- **If 比赛系统产出异常高的战术评分比（如 >1.0）**: `tactical_rating_ratio` 钳制到 `[0.3, 1.0]`，超出范围的值视同边界值。研究点数结算不受异常输入阻塞。
- **If 设施加成 `facility_ap_bonus` 在 MVP 阶段被非零值调用**: 视为配置错误或 Alpha 预留误接入；经济系统不得把该值作为正式每日 AP 恢复来源。只有在本 GDD 与小镇建设系统 GDD 均升级 Alpha 合同后，才可按 0–3 范围消费该字段。
- **If 赛季最后一轮比赛获胜后触发晋级（升级或降级）**: 该场比赛的 `post_match_funds` 使用球队**赛前所在层级**的 `league_tier_multiplier`（即比赛发生时的层级），而非晋级后的新层级。例如：Tier 2 球队在最后一轮获胜并升入 Tier 1，该场收入仍按 Tier 2 的 `league_tier_multiplier = 1.3` 结算。新层级倍率从下赛季首场比赛开始生效。赛季末奖金（`season_bonus_funds`）同理使用结算赛季的层级。

## Dependencies

### Upstream Dependencies

| System | Type | What this system needs | Key interface |
|---|---|---|---|
| `design/gdd/balance-system.md` | Hard | `resource_settlement` 结算接口、资源类型定义、公式参数边界 | 每次结算调用 `resource_settlement = clamp(current + gained - spent, min, max)` |
| `design/gdd/time-and-season-progression-system.md` | Hard | 结算信号（每日/赛后/阶段/赛季）、赛季阶段标识 | 时间系统在每个结算节点触发经济系统结算 |
| `design/gdd/save-and-load-system.md` | Hard | 存档/读档指令、权威持久化边界 | 三种资源当前值、流水记录、预警状态在稳定节点全量保存 |
| `design/gdd/player-development-system.md` | Hard | 训练资源消耗请求（训练类型 → 经费 + AP 消耗量） | 培养系统发起消耗，经济系统验证余额并确认扣除 |
| `design/gdd/match-competition-system.md` | Hard | 比赛结果 → 奖励口径（胜负/评分/战术评分） | 比赛系统输出奖励口径，经济系统据此计算金额并入账 |
| `design/gdd/league-competition-structure-system.md` | Hard | 联赛层级系数、赛季排名/晋级/降级标签 | 联赛系统输出结算标签，经济系统据此计算赛季奖金 |

### Downstream Dependencies

| System | Type | What this system provides | Key interface |
|---|---|---|---|
| `design/gdd/main-loop-ui-framework.md` | Hard | 经费和运动点数的当前值、变化量、预警状态、结算摘要；研究点数在 Alpha 阶段接入 UI | 主界面渲染资源条和结算动画 |
| 小镇建设系统 | Hard (双向) | 经济→建设: 资源充足性检查、经费扣除、维护费扣缴；建设→经济: `facility_total_maintenance`（叠加 `daily_maintenance_cost`）；`facility_ap_bonus` 与 `stadium_revenue_multiplier` 在 MVP 固定为 0/1.00 或只读预留 | 双向接口: 经济系统在 MVP 只硬消费建设维护费；建设系统依赖经济系统的资源验证与结算 |
| 声望与成就系统 | Soft (Alpha) | 里程碑达成 → 资源奖励入账 | Alpha 阶段接入（MVP 以固定里程碑代替） |
| 随机事件系统 | Soft (Beta) | 事件驱动的资源变化请求入口 | Beta 阶段接入 |
| `design/gdd/onboarding-system.md` | Soft | 引导需解释资源摘要区中经费和运动点数的真实含义与用途 | 引导系统消费经济系统的资源查询接口用于引导文案 |
| 建设与经营 UI | Hard (Alpha) | 资源余额展示、预算预览 | 建设界面消费经济系统的资源查询接口 |
| `design/gdd/player-development-system.md` | Hard (回传) | 资源充足性确认、标准化训练成本 `standardized_training_cost` | 培养系统消费此值计算 `player_development_roi` |
| `design/gdd/league-competition-structure-system.md` | Hard (回传) | 赛季奖金结算确认 | 联赛系统输出标签后，经济系统返回奖励入账确认 |

### Dependency Rules

1. 经济管理系统对上游系统的依赖体现在"消费它们的输出但不在本系统内重新定义它们的语义"——比赛系统定义什么是"赢"，经济系统定义赢了值多少钱。
2. 任何下游系统不得直接修改三种资源的当前值——所有资源变化必须通过经济系统定义的标准化变更接口（Budget Preview → Settlement）。
3. 小镇建设系统在 MVP 阶段对经济系统的硬回传仅包含建造/升级扣费与 `facility_total_maintenance`；`facility_ap_bonus` 和 `stadium_revenue_multiplier` 若在 Alpha 启用，必须先同步修订本 GDD 与小镇建设系统 GDD。声望与成就系统、随机事件系统 GDD 完成后，本节对应的 Soft 条目应升级为 Hard，并在其 GDD 的 Dependencies 中反向声明对本系统的依赖。
4. 如果某个系统只展示资源余额而不发起消耗或收入请求，则它属于软依赖；如果会改变资源值，则属于硬依赖。
5. MVP 阶段，主循环 UI 框架是经济系统最关键的展示消费方——它必须正确展示经费和运动点数的当前值、结算摘要和预警状态。研究点数在后台累积但不在 MVP UI 中显示（Alpha 阶段接入解锁树后开放），否则玩家无法感知经济系统的存在。

## Tuning Knobs

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| `base_ap_recovery` | 每日运动点数自然恢复量 | 4–6 | AP 过于充裕，取舍意义减弱 | AP 长期不足，玩家感到行动受限 | 每日行动节奏、AP 使用率 |
| `facility_ap_bonus` | 建设系统提供的额外 AP 恢复 | MVP 固定 0；Alpha 0–3 | 后期 AP 压力消失过早 | 设施升级反馈不足 | Alpha 建设回报感（MVP 不启用） |
| `base_match_funds` | Tier 1 单场比赛经费基数 | 200–300 | 经费通胀，训练/建设支出变得无感 | 经费压力过大，负场无法维持运营 | 比赛回报感、经营压力 |
| `match_result_multiplier` | 胜/平/负的奖励倍率 | 胜 0.8–1.2, 平 0.5–0.7, 负 0.2–0.4 | 胜场奖励过高，平/负无意义 | 胜负差异过小，比赛结果不痛不痒 | 比赛重要性、风险回报平衡 |
| `base_season_bonus` | Tier 1 赛季末奖金基数 | 800–1200 | 赛季末突然暴富，日常收入贬值 | 赛季结算无满足感 | 赛季成就感、长期规划动力 |
| `minimum_regular_funds_action_cost` | 赛季软停滞恢复地板的目标余额 | 80–120 | 低胜率惩罚过轻，玩家可依赖地板反复消费 | 恢复后仍无法执行任何常规经费操作 | 软停滞恢复、安全网强度 |
| `base_season_research` | 赛季末研究基金基数 | 80–120 | 研究解锁过快 | 研究进度通胀，解锁树瞬间耗尽 | 研究节奏、解锁期待感 |
| `base_match_research` | 单场研究点数基数 | 10–20 | 研究点数短期爆仓 | 研究点数几乎不增长 | 研究获取节奏 |
| `tactical_rating_ratio` 范围 | 战术评分比钳制范围 | 0.3–1.0 | 战术差也能获取高研究点（反直觉） | 好战术与差战术无区分度 | 研究点数获取与战术表现关联 |
| `warning_ratio` | AP 预警触发比例阈值 | 0.15–0.25 | 过早预警频繁触发，麻木 | 预警触发过迟，来不及补救 | 预警感知、经营安全感 |
| `funds_warning_absolute` | 经费绝对值预警线 | 80–150 | 经费尚充裕就频发预警 | 经费已见底仍未警告 | 低经费感知 |
| `ap_to_funds_weight` | AP→经费标准化转换权重 | 40–60 | AP 在 ROI 计算中过度放大 | AP 机会成本被低估 | 培养 ROI 计算、跨资源比较 |
| `action_points_max` | 运动点数硬上限 | 80–120 | 可囤积大量 AP，每日限制形同虚设 | AP 上限过低，每日恢复大量溢出 | AP 节奏、囤积自由度 |
| `rest_ap_recovery` | 跳过训练日额外恢复的 AP | 2–5 | 休息成为主导策略 | 取舍无意义 | 休息行动的吸引力、取舍平衡 |
| `daily_maintenance_fee` | 每日固定经费扣除 | 20–30 | 经费压力过大 | 经费无自然出口，堆积无感 | 日常经营压力、囤积防护 |

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

- **GIVEN** 一名玩家从新档开始游戏，**WHEN** 打开主界面，**THEN** 经费和运动点数的当前值均可见，且初始值符合 Tuning Knobs 定义的默认值。研究点数不在 MVP UI 中显示（Alpha 阶段接入解锁树后开放）。
- **GIVEN** 玩家拥有足够资源，**WHEN** 发起一次训练并确认，**THEN** Budget Preview 正确显示操作前后余额变化，确认后经费和运动点数被正确扣除，扣除量符合训练消耗配置。
- **GIVEN** 玩家经费不足（当前 < 训练所需），**WHEN** 在训练界面选择训练项目，**THEN** Budget Preview 显示操作后经费将不足（需X，当前Y），训练确认按钮灰化，并明确提示"经费不足"。
- **GIVEN** 玩家运动点数不足（当前 < `match_ap_cost`）且尚未到达不可跳过的正式比赛节点，**WHEN** 在比赛入口预览比赛，**THEN** UI 提示"运动点数不足（需 X，当前 Y）"，并引导休息或等待恢复。
- **GIVEN** 不可跳过的 `Match Trigger` 已到达且玩家 AP < `match_ap_cost`，**WHEN** QA 进入比赛入口，**THEN** 经济系统执行 `match_day_ap_safety_grant` 补足差额后再扣除本场比赛 AP；流水中必须能区分该补足与普通 AP 恢复。
- **GIVEN** 同一 `match_id` 在恢复、重进或重复求值后再次请求 `match_day_ap_safety_grant`，**WHEN** QA 检查 AP 余额与流水，**THEN** 经济系统只允许第一笔有效 grant 生效，后续重复请求不得再次增加 AP。
- **GIVEN** 同一 `match_id` 的赛后结果包被重复提交给经济系统，**WHEN** QA 检查比赛奖励、AP 扣除和流水记录，**THEN** 该比赛相关资源结算只能生效一次；重复提交不得重复入账或重复扣除。
- **GIVEN** 时间系统发出每日结算信号，**WHEN** 结算完成，**THEN** 运动点数按 `daily_ap_recovery` 公式恢复，恢复量正确计入，不超过 `action_points_max`；结算摘要显示"今日恢复 X 运动点数"。
- **GIVEN** 一场比赛终场确认且比赛系统输出奖励口径，**WHEN** 赛后结算完成，**THEN** 经费按 `post_match_funds` 公式正确入账；结算摘要显示胜负结果和对应奖励金额。研究点数在后台按 `post_match_research` 公式累积（不在 MVP 结算摘要中显示）。
- **GIVEN** 比赛结果为负场，**WHEN** 赛后结算完成，**THEN** 入账经费 ≥ 最低训练成本（防止贫困螺旋）；AP 消耗被正确扣除。
- **GIVEN** 时间系统发出赛季结算信号且联赛系统输出排名/晋级标签，**WHEN** 赛季结算完成，**THEN** 经费按 `season_bonus_funds` 公式正确入账；若赛季奖金后经费仍低于 `minimum_regular_funds_action_cost`，则按 `season_recovery_floor_grant` 补足到该成本；结算摘要显示赛季成绩、奖金明细和恢复地板补差。研究点数在后台按 `season_bonus_research` 公式累积（固定发放，与排名无关；不在 MVP 结算摘要中显示）。
- **GIVEN** 任一资源在结算后 ≤ 预警阈值，**WHEN** 结算完成，**THEN** UI 对该资源显示黄色警告；**GIVEN** 该资源在后续结算中恢复到阈值以上，**WHEN** 结算完成，**THEN** 黄色警告移除。
- **GIVEN** 任一资源达到上限且结算产生额外增加，**WHEN** 结算完成，**THEN** 该资源停留在上限值，超出部分丢弃，结算摘要中标注"已达上限"。
- **GIVEN** 资源归零（如经费=0），**WHEN** 玩家尝试任何需要消耗该资源的行动，**THEN** 该行动被阻止，UI 显示"资源耗尽"标记。
- **GIVEN** QA 使用一组已知输入手工计算 `resource_settlement` 结果，**WHEN** 对比系统结算输出，**THEN** 系统结果必须与手工计算结果一致，越界结果正确钳制到 `resource_min` 或 `resource_max`。
- **GIVEN** QA 采集一个完整赛季的资源流水数据，**WHEN** 核算赛季总收入与总支出，**THEN** 期末余额 = 期初余额 + 总收入 − 总支出（含钳制修正），`settlement_valid` 对每次结算返回 true。
- **GIVEN** 玩家在 Budget Preview 打开期间收到结算信号，**WHEN** 结算完成，**THEN** UI 刷新为结算后最新值，Preview 不缓存旧数据也不阻止结算。
- **GIVEN** 玩家读档恢复到一个稳定保存节点，**WHEN** 检查三种资源值，**THEN** 资源值与存档时完全一致，流水记录完整恢复。
- **GIVEN** 每日结算与赛后结算信号同时到达，**WHEN** 结算系统处理，**THEN** 赛后结算先完整执行，每日结算在其后完整执行，两次结算的结果不交叉修改同一资源。
- **GIVEN** 多个球员的训练请求同时提交（同一帧），**WHEN** 经济系统处理，**THEN** 按提交顺序串行检查，前一请求消耗后的新余额作为后一请求的检查基准；余额不足的后续请求被拒绝并提示"资源不足"。
- **GIVEN** 比赛系统输出的 `tactical_rating_ratio` 值 > 1.0 或 < 0.3，**WHEN** 赛后结算处理研究点数，**THEN** `tactical_rating_ratio` 被钳制到 [0.3, 1.0] 范围，结算不因异常输入而阻塞。
- **GIVEN** 下游系统提交的资源消耗量为 0 或负数，**WHEN** 结算系统验证，**THEN** 该请求被拒绝执行，不产生流水记录，不改变任何资源值。
- **GIVEN** 下游系统绕过 Budget Preview 直接提交超过余额的消耗请求，**WHEN** 结算系统验证，**THEN** 该笔消耗被拒绝，记录异常日志，资源值不变，不产生负余额。
- **GIVEN** MVP 版本仅实现本 GDD 定义的最小经济闭环，**WHEN** QA 从新档连续游玩一个标准会话（至少 3 个比赛日），**THEN** 必须验证以下全部条件成立：(a) 三种资源在每次结算后数值变化正确；(b) 每次结算产生可见的结算摘要；(c) 至少一次因资源不足导致操作被阻止；(d) 运动点数每日恢复量正确；(e) 休息行动使运动点数按 `rest_ap_recovery` 增长。
- **GIVEN** Tier 1 玩家处于四设施全 Lv.5、`base_maintenance_cost = 25`、`facility_total_maintenance = 31`、比赛间隔 3 天、连续负场且经费被维护费扣至 0，**WHEN** QA 继续按 MVP 合法流程推进到赛季结算，**THEN** 每个负场周期可按 `100 - (56 × 3) = -68` 手工核算为亏损；赛季垫底奖金至少按 `1000 × 0.5 × 1.0 = 500` 入账；若赛季奖金后经费仍低于 `minimum_regular_funds_action_cost = 100`，`season_recovery_floor_grant` 必须补足到 100，使玩家无需重开档或外部注入即可再次执行至少一种常规经费消耗操作。

## Open Questions

[To be designed]
