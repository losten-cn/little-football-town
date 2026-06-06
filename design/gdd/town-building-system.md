# 足球小镇：小镇建设系统

> **Status**: Designed
> **Author**: 用户 + Claude
> **Last Updated**: 2026-05-31
> **Implements Pillar**: 像素小镇养成、轻度足球经营
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/balance-system.md`
> - `design/gdd/economy-management-system.md`
> - `design/gdd/time-and-season-progression-system.md`
> - `design/gdd/save-and-load-system.md`

## Overview

小镇建设系统是《足球小镇》中负责设施建造、升级、布局呈现与小镇长期身份感的世界管理层，也是"像素小镇养成"支柱在 MVP 阶段的可见承载系统。它在数据层面承接数值系统定义的设施系数边界、升级倍率边界和维护费边界，把建设行为映射为少量、可验证、低强度的支持性修正；在体验层面，它让玩家逐步看到训练场、医疗室、青训营和球场等足球主题设施出现在小镇里，形成"这里是我的球队之家"的归属感。

本系统不拥有训练内容（培养系统）、比赛规则（比赛系统）、资源账目（经济系统）或时间推进节奏（时间系统）——它拥有的是"哪些设施可以建造、建造和升级需要什么条件、设施在小镇中如何可见、以及少量设施状态如何作为被动支持信息被下游消费"。在 MVP 阶段，本系统的目标是严格控制范围：提供最小可见建设切片，让玩家感受到小镇正在成长，但不把建设变成与培养和比赛并列竞争的第二主循环，也不要求玩家通过网格最优布局来获得核心进度。

## Player Fantasy

小镇建设系统服务的玩家幻想是："从一片空地开始，亲手把我的足球小镇建成一座充满活力的足球之城。"

这种幻想包含两个层面。在直接的建造面上，玩家面对一个可逐步填充的小镇空间，决定先把哪座足球设施带进小镇、何时升级现有设施、怎样让小镇看起来更像自己的球队之家——每一次建造和升级都是玩家亲手留下的"生活痕迹"。在间接的回报面上，玩家不需要每次训练前重新检查设施加成；系统只把少量设施状态作为被动支持注入训练、主场氛围或收支摘要，让玩家自然感到"小镇正在帮球队变好"，而不是被迫为每次行动重新计算设施最优解。

参考那些让人感到"亲手建设成就"而非"最优布局焦虑"的游戏：Stardew Valley 中第一年精打细算后在第二年看到农场扩展的满足感，Football Manager 中升级训练设施后看到球员发展加速的回报感。小镇建设系统必须让"建设"成为玩家长期经营中的温暖支撑和身份表达——每一次建造都有可见回报、每一次升级都有轻量增益、每一个布局选择都优先体现个人风格，而不是强迫玩家为了数值最优解而放弃对小镇面貌的自主权。

## Detailed Rules

### Core Rules

**规则 1 — 建设系统控制权**: 小镇建设系统是所有设施建造、升级、布局和加成的权威来源。其他系统可以消费设施加成（如培养系统使用训练效率倍率），但不得直接修改设施状态、等级或布局。

**规则 2 — MVP 设施集合**: MVP 阶段提供最小可见建设切片，包含 4 种核心设施、建造/升级状态、轻量维护费、主界面小镇摘要和下游只读加成查询。完整建设与经营 UI、扩展设施、深层布局优化、拆迁重排玩法、强邻接收益和设施皮肤留到 Alpha。MVP 阶段提供 4 种核心设施：

| 设施 | 功能定位 | MVP 基础效果 |
|---|---|---|
| 训练场 | 支持日常训练效率 | 训练获得的 `attribute_growth` 乘以低强度 `training_efficiency_multiplier` |
| 医疗室 | 展示恢复与健康基础设施 | MVP 只提供状态摘要和伤病恢复字段预留；不作为 AP 恢复硬来源 |
| 青训营 | 展示年轻球员培养愿景 | MVP 只提供年轻球员训练轻量加成；招募潜力下限提升为 Alpha 输出 |
| 球场 | 展示主场身份与比赛日氛围 | MVP 只提供小幅 `home_advantage_bonus`；比赛收入倍率为 Alpha 输出或只读预留 |

**规则 3 — 设施等级**: 每种设施有 5 个等级（Lv.1–Lv.5）。初始均为未建造状态。建造 = 解锁 Lv.1。升级 = Lv.N → Lv.N+1。每升一级：基础效果数值递增（非倍率叠加）、建造/升级的经费和时间成本递增、设施外观变化。

**规则 4 — 建造与升级成本**: 每项建造/升级消耗两类资源：经费 + 时间单位。成本由 Tuning Knobs 定义，遵循公式：
`construction_cost_funds(level) = base_cost × level_cost_multiplier ^ (level - 1)`
`construction_time(level) = base_time × level_time_multiplier ^ (level - 1)`

**规则 5 — 布局与邻接**: 小镇使用 `M × N` 网格地图（MVP 建议 5×5，由 Tuning Knobs 定义），每座设施占地 1 格。MVP 阶段网格主要服务可见小镇布局和空间归属感，不承担核心数值最优解。邻接定义为共享边（四方向），MVP 只展示邻接关系和小幅摘要提示，不把邻接作为训练、AP、收入或胜率的必做优化来源。Alpha 阶段如需恢复数值邻接，可从本 GDD 的邻接公式预留项升级为正式硬消费合同。

MVP 阶段设施不支持拆迁重排优化。若调试或后续版本允许拆除，拆除不返还资源，新位置需重新从 Lv.1 开始建造；该能力不得作为 MVP 玩家常规优化路径。

**规则 6 — 加成生效时机**: 设施加成在设施建成（完工节点到达）后立即生效。升级在完工后立即应用新等级的加成。拆除后加成立即移除。加成变化不影响已经结算完成的历史结果。

**规则 7 — MVP 范围控制**:
- 实现 4 类设施的建造、升级、轻量维护费、存档恢复和只读加成查询；主循环 UI 只展示小镇摘要与最小建设入口
- MVP 正式硬消费输出只包含：`facility_training_multiplier`（训练场 + 青训营年轻球员轻量加成，MVP 上限 1.35）、`facility_total_maintenance`（轻量维护费）、`home_advantage_bonus`（球场小幅主场评分加成，MVP 上限 5）
- `facility_ap_bonus`、`stadium_revenue_multiplier`、`potential_floor_boost`、`adj_youth_potential_boost`、`injury_recovery_reduction`、`training_injury_prob_multiplier` 和所有数值邻接输出在 MVP 中只作为公式/数据字段或摘要预留，不作为下游硬消费合同
- 不实现设施之间的组合加成（如"训练场+医疗室+青训营三件套"额外奖励）
- 不实现设施皮肤/外观选择
- 不实现设施出租/共享/多球队共用
- 不实现拆迁重排优化和通用邻接矩阵；MVP 邻接只用于可见布局说明，不提供额外硬数值收益
- MVP 建设不得要求玩家在每次训练、比赛或赛前准备前重新优化设施布局；设施收益应作为低强度长期背景支持

### States and Transitions

| 状态 | 描述 | 进入条件 | 退出条件 | 有效下一状态 |
|---|---|---|---|---|
| **Empty** (空地) | 网格槽位为空，可建造 | 初始状态 / 拆除完成 | 玩家确认建造 | Constructing |
| **Constructing** (建造中) | 设施正在首次建造，尚未生效 | 玩家确认建造并支付成本 | 时间系统触发完工节点 | Active(Lv.1) |
| **Active(Lv.N)** (运作中) | 设施在等级 N 正常运行，提供对应加成 | 建造完工 / 升级完工 | 玩家发起升级；Alpha/调试模式可发起拆除 | Upgrading / Demolishing(Alpha/Debug) |
| **Upgrading** (升级中) | 设施正在从 Lv.N 升级到 Lv.N+1 | 玩家确认升级并支付成本 | 时间系统触发完工节点 | Active(Lv.N+1) |
| **Demolishing** (拆除中，Alpha/Debug) | 设施正在被拆除；MVP 玩家流程不暴露常规入口 | Alpha/调试模式中玩家确认拆除 | 拆除完成 | Empty |

**状态转换规则**:
- Empty → Constructing: 仅当玩家经费 ≥ 建造成本、且目标格子为空
- Constructing → Active(Lv.1): 时间系统发出该建设项目的完工信号
- Active(Lv.N) → Upgrading: 仅当 N < 5、经费 ≥ 升级成本、且完工前该格不被拆除
- Upgrading → Active(Lv.N+1): 时间系统发出该升级项目的完工信号。升级期间设施维持 Lv.N 的加成（不中断服务）
- Active(Lv.N) → Demolishing: 仅 Alpha/调试模式允许；确认拆除后即时完成，加成立即移除，格子恢复 Empty
- MVP 玩家流程不提供常规拆除入口；Alpha/调试模式中，建造/升级中也不允许拆除同一设施，必须等待完工后方可拆除

### Interactions with Other Systems

| 系统 | 数据流入建设系统 | 数据流出建设系统 | 交互时机 |
|---|---|---|---|
| **数值系统** (Hard 上游) | 设施系数边界（`flat_modifier_sum_budget`、`percent_modifier_sum_budget`）、升级倍率安全范围 | 训练效率倍率（`training_efficiency_multiplier`）、主场评分加成（`home_advantage_bonus`）等实际加成值 | 加成值变更时（建造完工/升级完工）→ 通知数值系统验证是否在边界内 |
| **经济管理系统** (Hard 上游·消费方) | 资源充足性确认、实际经费扣除、每日维护费扣除 | 建造/升级经费消耗请求、每日维护费基准（`facility_total_maintenance` = 各设施维护费之和） | 建造/升级发起时（Budget Preview + 确认扣除）；每日结算时（维护费） |
| **时间与赛季推进系统** (Hard 上游) | 完工节点信号、建设占用时段确认 | 建造/升级时间消耗请求（`construction_time`） | 建造/升级发起时（时间系统登记工期）；工期到达时（时间系统触发完工） |
| **存档与读档系统** (Hard 上游) | 存档/读档指令 | 设施列表（类型、位置、等级、当前状态）、建造/升级剩余工期、已确认完工结果 | 稳定节点保存时全量写入；读档时全量恢复 |
| **运动员培养系统** (Hard 下游·消费方) | 球员年龄（用于年轻球员训练倍率判定） | `facility_training_multiplier`（训练场与青训营年轻球员轻量加成的组合倍率；MVP 不含邻接乘区） | 每次训练结算时，培养系统读取当前设施加成；招募潜力下限输出在 Alpha 接入 |
| **比赛竞技系统** (Soft 下游·消费方) | — | `home_advantage_bonus`（球场提供的小幅主场身份加成，加入 `team_match_strength`） | 主场比赛赛前评分计算时；客场或中立场不消费 |
| **主循环 UI 框架** (Hard 下游·展示方) | — | 设施列表（类型、位置、等级、状态）、建造/升级进度、邻接关系展示、加成摘要 | MVP 主界面渲染小镇摘要与最小建设入口；完整建设界面由 Alpha 的建设与经营 UI 承接 |
| **建设与经营 UI** (Hard 下游·展示方·Alpha) | — | 网格状态（每格为空/设施类型/等级）、可建造/可升级/可拆除判断、成本预览 | Alpha 阶段接入；MVP 阶段建设交互内嵌于主循环 UI |

> **邻接说明**: MVP 阶段邻接只作为布局可读性和小镇外观关系展示，不向培养、比赛或经济输出额外硬数值。Alpha 若启用数值邻接，必须先在本系统中把对应公式从预留项升级为正式合同，再让下游消费。

## Formulas

### 1. 建造/升级经费成本

**表达式:**

`construction_cost_funds(facility, target_level) = ceil( base_funds_cost[facility] × cost_multiplier ^ (target_level - 1) )`

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `facility` | enum | {training_ground, medical_room, youth_academy, stadium} | 设施类型 |
| `target_level` | int | 1–5 | 建造/升级的目标等级 |
| `base_funds_cost[facility]` | int | 见下表 | 每种设施的 Lv.1 建造经费基数 |
| `cost_multiplier` | float | 1.5–2.0 | 全局经费指数增长倍率，默认 1.8 |

`base_funds_cost` 表:

| facility | base_funds_cost | 设计理由 |
|---|---|---|
| training_ground | 200 | 基础训练设施，约 1 场 Tier 1 胜场收入 |
| medical_room | 150 | 辅助设施，略低于训练场 |
| youth_academy | 300 | 长期投资型设施，初始成本较高 |
| stadium | 500 | 核心基础设施，初始成本最高 |

**输出范围:** `base_funds_cost[facility]` 至 `base_funds_cost[facility] × cost_multiplier^4`（Lv.5 时为基数 × 1.8^4 ≈ 基数 × 10.5）。

**计算示例:**

建造训练场 Lv.1: `ceil(200 × 1.8^0) = 200`
训练场 Lv.1 → Lv.2: `ceil(200 × 1.8^1) = 360`
训练场 Lv.4 → Lv.5: `ceil(200 × 1.8^4) = ceil(200 × 10.498) = 2100`
建造球场 Lv.1: `ceil(500 × 1.8^0) = 500`
球场 Lv.4 → Lv.5: `ceil(500 × 1.8^4) = ceil(5248.8) = 5249`

**退化防护:** 当 `target_level = 1` 时指数为 0，结果为 `base_funds_cost`，不会出现乘零或除零。

---

### 2. 建造/升级时间成本

**表达式:**

`construction_time(facility, target_level) = ceil( base_time_type[facility] × time_multiplier ^ (target_level - 1) )`

其中 `base_time_type` 根据操作类型选择:
- 新建（target_level = 1）: 使用 `base_construction_time[facility]`
- 升级（target_level >= 2）: 使用 `base_upgrade_time[facility]`

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `facility` | enum | {training_ground, medical_room, youth_academy, stadium} | 设施类型 |
| `target_level` | int | 1–5 | 建造/升级的目标等级 |
| `base_construction_time[facility]` | int | 见下表 | 新建（Lv.1）所需的基础天数 |
| `base_upgrade_time[facility]` | int | 见下表 | 升级（Lv.N→Lv.N+1）所需的基础天数 |
| `time_multiplier` | float | 1.2–1.5 | 全局时间指数增长倍率，默认 1.3 |

`base_construction_time` / `base_upgrade_time` 表（单位：天）:

| facility | 新建基础天数 | 升级基础天数 | 设计理由 |
|---|---|---|---|
| training_ground | 4 | 3 | 训练设施中等规模，升级比新建快 |
| medical_room | 3 | 2 | 小型辅助设施，建造/升级均较快 |
| youth_academy | 6 | 4 | 大型长期设施，建造和升级周期较长 |
| stadium | 8 | 5 | 核心大型设施，工期最长 |

**输出范围:** 新建: 3–8 天（Lv.1）；升级: `base_upgrade_time` 至 `base_upgrade_time × time_multiplier^4` 天（Lv.5）。

**计算示例:**

新建训练场 Lv.1: `ceil(4 × 1.3^0) = 4` 天
训练场 Lv.1 → Lv.2: `ceil(3 × 1.3^1) = ceil(3.9) = 4` 天
训练场 Lv.2 → Lv.3: `ceil(3 × 1.3^2) = ceil(5.07) = 6` 天
训练场 Lv.4 → Lv.5: `ceil(3 × 1.3^4) = ceil(3 × 2.856) = ceil(8.568) = 9` 天
新建球场 Lv.1: `ceil(8 × 1.3^0) = 8` 天
球场 Lv.4 → Lv.5: `ceil(5 × 1.3^4) = ceil(14.28) = 15` 天

**总工期参考（从空地到 Lv.5，以训练场为例）:** 4 + 4 + 6 + 7 + 9 = 30 天。

**退化防护:** 时间结果经 `ceil()` 保证至少为 1 天。`target_level = 1` 时指数为 0，结果为 `base_construction_time`。

---

### 3. 训练效率倍率（训练场）

**表达式:**

`training_efficiency_multiplier(level) = 1.0 + training_ground_bonus_delta × level`

其中 `level` 为训练场当前等级，若未建造则 `level = 0`，倍率为 1.0（无加成）。

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `level` | int | 0–5 | 训练场当前等级（0 = 未建造） |
| `training_ground_bonus_delta` | float | 0.02–0.03（MVP）/ 0.03–0.07（Alpha） | 每级增加的训练效率百分比，MVP 默认 0.03 |

**输出范围:** 1.00（未建造）至 1.15（Lv.5，MVP 硬上限）。Alpha 若需要更强设施成长感，可通过调参把上限扩展回 1.25。

**等级-倍率对照表（MVP 默认 delta = 0.03）:**

| Lv.0 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|
| 1.00 | 1.03 | 1.06 | 1.09 | 1.12 | 1.15 |

**计算示例:**

训练场 Lv.3: `1.0 + 0.03 × 3 = 1.09`
本系统将 MVP 训练类倍率组合为 `facility_training_multiplier`，作为新因子接入 `training_actual_gain`（玩家培养系统第 4 因子）:
`facility_training_multiplier = training_efficiency_multiplier × youth_training_bonus`
计算示例: 若 `attribute_growth = 0.8`，`fatigue_adjusted_training_efficiency = 0.9`，`training_focus_match_multiplier = 1.0`，`facility_training_multiplier = 1.09`，则:
`training_actual_gain = min(potential_cap - current, 0.8 × 0.9 × 1.0 × 1.09) = min(potential_cap - current, 0.785)`
对比无训练场时的 `0.8 × 0.9 × 1.0 = 0.72`，Lv.3 训练场使单次训练收益提升约 9%。

**退化防护:** `level = 0` 时结果为 1.0，不产生退化。倍率始终 >= 1.0，不会反向削减训练收益。

---

### 4. AP 恢复加成与伤病恢复（医疗室）

医疗室提供两项独立加成: (a) AP 恢复加成、(b) 伤病恢复回合减免。

#### 4a. AP 恢复加成（Alpha 预留）

**表达式:**

`medical_ap_bonus(level) = 0`（MVP）

MVP 阶段医疗室不作为正式 AP 恢复硬来源，避免建设系统提前消解运动点数取舍。医疗室可以在主界面和小镇摘要中展示"恢复设施"身份，但经济系统 `daily_ap_recovery` 的正式计算只使用基础恢复、休息行动和比赛日安全补足。

Alpha 阶段若需要启用设施 AP 恢复，可恢复以下预留口径：`medical_ap_bonus(level) = clamp( floor( level × medical_ap_bonus_per_level ), (level > 0 ? 1 : 0), 3 )`，并同步升级经济系统对 `facility_ap_bonus` 的硬消费合同。

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `level` | int | 0–5 | 医疗室当前等级（0 = 未建造） |
| `medical_ap_bonus_per_level` | float | 0.5–0.9 | Alpha 预留的每级 AP 增量系数，默认 0.7 |

**输出范围:** MVP 固定为 0。Alpha 预留范围为 0–3（整数）。

**计算示例:**

医疗室 Lv.3（MVP）: `medical_ap_bonus = 0`，`daily_ap_recovery = base_ap_recovery + facility_ap_bonus = 5 + 0 = 5` AP/日。

**对接经济系统:** MVP 阶段 `facility_ap_bonus = 0`，不得作为经济系统正式 AP 恢复来源。

#### 4b. 伤病恢复回合减免

**表达式:**

`injury_recovery_reduction(level) = clamp( floor( level × injury_recovery_per_level ), (level > 0 ? 1 : 0), 2 )`

其中 `level` 为医疗室当前等级。clamp 下限在 `level > 0` 时为 1（Lv.1 保底），上限 2 确保伤病恢复回合数至少为 1。

> **设计注**: 输出范围 [0, 2] 只有 3 个离散值，而设施有 5 个等级。默认系数 0.7 确保最多连续 2 个等级共享同一输出值，避免 Lv.1–Lv.3 三级无增量的"死区"。

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `level` | int | 0–5 | 医疗室当前等级 |
| `injury_recovery_per_level` | float | 0.5–0.8 | 每级减免回合增量，默认 0.7 |

**输出范围:** 0–2（整数回合）。上限由 clamp 强制，即使调参值更高的 `injury_recovery_per_level` 也不会突破。

| Lv.0 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|
| 0 | 1 | 1 | 2 | 2 | 2 |

**计算示例:**

医疗室 Lv.1: `clamp(floor(1 × 0.7), 1, 2) = clamp(0, 1, 2) = 1`（Lv.1 保底）
医疗室 Lv.3: `clamp(floor(3 × 0.7), 1, 2) = clamp(2, 1, 2) = 2`（Lv.2→Lv.3 首次出现减免增量）

医疗室 Lv.5: `floor(5 × 0.7) = 3 → clamp(3, 1, 2) = 2`。若基础伤病恢复需 5 回合，则实际为 `max(1, 5 - 2) = 3` 回合。

**退化防护:** 减免后恢复回合数 `clamp` 至最少 1 回合（伤病不可被完全消除）。当 `level = 0` 时减免为 0。

---

### 5. 主场评分加成（球场）

**表达式:**

`home_advantage_bonus(level) = home_advantage_per_level × level`

其中 `level` 为球场当前等级，未建造时为 0。此值作为主场比赛的 `facility_rating_bonus` 加分项，通过比赛系统的 `team_match_strength` 进入评级→概率转换链；该链允许设施修正后的有效队伍评分超过 100，最终由胜率公式的 0.05–0.95 clamp 保留爆冷与失手空间。

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `level` | int | 0–5 | 球场当前等级 |
| `home_advantage_per_level` | float | 0.5–1.0（MVP）/ 1.0–2.5（Alpha） | 每级增加的球队评分点数，MVP 默认 1.0 |

**输出范围:** 0–5（Lv.5 时 +5，MVP 硬上限）。Alpha 若需要更强主场身份，可扩展回 0–10。

**等级-加成对照表:**

| Lv.0 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|
| 0.0 | 1.0 | 2.0 | 3.0 | 4.0 | 5.0 |

**计算示例:**

球场 Lv.4，`team_match_strength = 65`，`opponent_team_match_strength = 62`，`rating_win_slope = 0.0045`:
`team_match_strength_effective = 65 + 4.0 = 69.0`
`base_win_probability = clamp(0.50 + (69.0 - 62.0) × 0.0045, 0.05, 0.95) = clamp(0.5315, 0.05, 0.95) = 0.5315`

对比无球场时的 `base_win_prob = clamp(0.50 + 3 × 0.0045, ...) = 0.5135`，Lv.4 球场带来约 +1.8% 胜率提升。

**退化防护:** `level = 0` 时结果为 0，客场比赛不受影响。

---

### 6. 比赛收入倍率（球场，Alpha 预留）

**表达式:**

`stadium_revenue_multiplier(level) = 1.0`（MVP）

MVP 阶段球场不作为正式比赛收入倍率来源，避免小镇建设同时放大比赛胜率和经费收入，形成自强化建设路线。球场在 MVP 中主要提供可见主场身份和小幅 `home_advantage_bonus`。

Alpha 阶段若需要启用球场收入成长，可恢复以下预留口径：`stadium_revenue_multiplier(level) = 1.0 + stadium_revenue_per_level × level`，并同步升级经济系统对该字段的硬消费合同。

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `level` | int | 0–5 | 球场当前等级 |
| `stadium_revenue_per_level` | float | 0.05–0.12 | Alpha 预留的每级收入百分比，默认 0.08 |

**输出范围:** MVP 固定为 1.00。Alpha 预留范围为 1.00–1.40。

**计算示例:**

球场 Lv.3，Tier 1 联赛，胜场。MVP 阶段 `stadium_revenue_multiplier = 1.00`:
`post_match_funds = base_match_funds × league_tier_multiplier × match_result_multiplier × stadium_revenue_multiplier`
`= 250 × 1.0 × 1.0 × 1.00 = 250`（经济系统 `floor()` 取整后）。

**退化防护:** MVP 与 Lv.0 均为 1.0，不改变收入。

---

### 7. 青训营加成

青训营提供两项独立加成: (a) 新球员潜力下限提升、(b) 年轻球员额外训练成长乘区。

#### 7a. 新球员潜力下限提升

**表达式:**

`potential_floor_boost(level) = clamp( floor( youth_potential_floor_per_level × level ), 0, 5 )`

其中 `level` 为青训营当前等级。clamp 上限 5 确保即使调参提高 `youth_potential_floor_per_level`，输出也不会突破声明范围。

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `level` | int | 0–5 | 青训营当前等级 |
| `youth_potential_floor_per_level` | float | 0.5–1.5 | 每级提升的潜力下限点数，默认 1.0 |

**输出范围:** 0–5（整数潜力点数）。

| Lv.0 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|
| 0 | 1 | 2 | 3 | 4 | 5 |

**计算示例:**

青训营 Lv.3: `floor(3 × 1.0) = 3`。若某球员层级基础潜力区间为 [65, 80]，则新招募该层级球员的潜力下限提升为 `65 + 3 = 68`，区间变为 [68, 80]（上限不变）。

#### 7b. 年轻球员训练成长加成

**表达式:**

`youth_training_bonus(level) = clamp( 1.0 + youth_growth_per_level × level, 1.00, 1.15 )`（MVP）

触发条件: 球员年龄 `≤ youth_age_threshold`（默认 22 岁）。MVP clamp 上限 1.15，确保与 Lv.5 训练场组合后 `facility_training_multiplier` 不超过 1.35；Alpha 若需要更强青训成长感，可扩展回 1.20。

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `level` | int | 0–5 | 青训营当前等级 |
| `youth_growth_per_level` | float | 0.02–0.03（MVP）/ 0.02–0.06（Alpha） | 每级增加的年轻球员成长百分比，MVP 默认 0.03 |
| `youth_age_threshold` | int | 20–24 | 年轻球员年龄判定上限，默认 22 |

**输出范围:** MVP 为 1.00–1.15（Lv.5 时 +15% 训练成长）；Alpha 预留范围为 1.00–1.20。

| Lv.0 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|
| 1.00 | 1.03 | 1.06 | 1.09 | 1.12 | 1.15 |

**计算示例:**

青训营 Lv.4，训练一名 20 岁球员:
`training_actual_gain_with_youth = training_actual_gain × youth_training_bonus(4) = training_actual_gain × 1.12`
若同时有训练场 Lv.3（`training_efficiency_multiplier = 1.09`），则:
`total_effective_multiplier = 1.09 × 1.12 = 1.221`
年轻球员在双设施加持下获得约 +22.1% 训练效率；最大组合为训练场 Lv.5 × 青训营 Lv.5 = `1.15 × 1.15 = 1.3225`，低于 MVP `facility_training_multiplier` 上限 1.35。

**退化防护:** `level = 0` 时倍率为 1.0。球员年龄超过阈值时不适用此加成。

---

### 8. 邻接加成体系（Alpha 预留）

MVP 阶段只实现邻接判定和可视化摘要，不把邻接输出接入训练、比赛、AP 或经济公式。以下公式为 Alpha 预留，除非本节被修订并在下游 GDD 中升级为硬消费合同，否则不得在 MVP 实现中生效。

#### 8.1 邻接判定规则

在 5×5 网格上，两个设施**邻接**当且仅当它们共享一条边（四方向: 上/下/左/右）。对角相邻不算邻接。

MVP 阶段只展示邻接关系。Alpha 可允许每个设施同时与多个邻接设施形成加成对，各类加成独立叠加。

#### 8.2 Alpha 数值邻接预留项

| 邻接对 | Alpha 受益方 | Alpha 加成类型 | 系数变量 | MVP 默认 |
|---|---|---|---|---|
| 训练场 ↔ 医疗室 | 训练场 | 降低训练受伤概率 | `adj_tr_med_coeff` | 不生效 |
| 训练场 ↔ 医疗室 | 医疗室 | 额外 AP 恢复 | `adj_med_tr_coeff` | 不生效 |
| 训练场 ↔ 青训营 | 训练场 | 年轻球员额外成长乘区 | `adj_tr_youth_coeff` | 不生效 |
| 训练场 ↔ 青训营 | 青训营 | 额外潜力下限提升 | `adj_youth_tr_coeff` | 不生效 |
| 球场 ↔ 训练场 | 球场 | 额外主场评分加成 | `adj_stad_tr_coeff` | 不生效 |

MVP 中，上表只用于说明未来可扩展方向；实际查询这些输出时必须返回中性值：伤病概率倍率 = 1.0、额外 AP = 0、额外成长乘区 = 1.0、额外潜力下限 = 0、额外主场评分 = 0。

#### 8.3 Alpha 通用邻接加成公式（未启用）

若 Alpha 阶段启用数值邻接，对所有邻接加成对 (A, B)，其中受益方为目标设施 `fac`，另一侧为来源设施 `src`:

`adjacency_bonus = coefficient × min(level_fac, level_src)`

使用 `min()` 确保较弱一方限制协同效果。启用前必须先修订本 GDD、对应下游 GDD、Tuning Knobs 和 Acceptance Criteria；不得只在实现中打开系数。

#### 8.4 MVP 邻接叠加规则

MVP 阶段不存在数值邻接叠加。设施可以同时与多座设施共享边，但这些关系只影响小镇摘要的可视化说明，不改变 `facility_training_multiplier`、`facility_ap_bonus`、`home_advantage_bonus`、`stadium_revenue_multiplier`、潜力下限或伤病相关输出。

---

### 9. 设施总维护费

**表达式:**

`facility_total_maintenance = Σ maintenance_per_facility(facility, level)` （对所有已建造的设施求和）

其中:

`maintenance_per_facility(facility, level) = facility_maintenance_base[facility] + facility_maintenance_delta[facility] × (level - 1)`

当 `level = 0`（未建造）时，该设施不产生维护费。

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `facility` | enum | 见下表 | 设施类型 |
| `level` | int | 0–5 | 设施当前等级 |
| `facility_maintenance_base[facility]` | int | 见下表 | Lv.1 每日基础维护费 |
| `facility_maintenance_delta[facility]` | int | 见下表 | 每升一级增加的每日维护费 |

维护费表（单位: 经费/日）:

| facility | Lv.1 基础 | 每级增量 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|---|---|
| training_ground | 2 | 1 | 2 | 3 | 4 | 5 | 6 |
| medical_room | 2 | 1 | 2 | 3 | 4 | 5 | 6 |
| youth_academy | 3 | 1 | 3 | 4 | 5 | 6 | 7 |
| stadium | 4 | 2 | 4 | 6 | 8 | 10 | 12 |

**输出范围:** 0（无设施）至 31（四设施全 Lv.5）。

**计算示例:**

场景: 训练场 Lv.3、医疗室 Lv.2、青训营 Lv.1、球场 Lv.4（均已建造）:
- 训练场: `2 + 1 × (3-1) = 4`
- 医疗室: `2 + 1 × (2-1) = 3`
- 青训营: `3 + 1 × (1-1) = 3`
- 球场: `4 + 2 × (4-1) = 10`
- `facility_total_maintenance = 4 + 3 + 3 + 10 = 20` 经费/日

**对接经济系统:** 经济系统的 `daily_maintenance_cost` 由 `base_maintenance_cost`（20–30）扩展为 `base_maintenance_cost + facility_total_maintenance`。MVP 维护费是轻量囤积防护，不得把设施推入停机、降级或破产惩罚链；若低胜率与维护费把经费压到最低操作成本以下，恢复责任由经济系统的赛季结算恢复地板承担，建设系统不自行发放经费、停机减免或拆除补偿。

**经济可持续性验证（按比赛间隔修正）:**

GDD 初版可持续性验证假设"每日有比赛"，该假设与实际比赛节奏不符。以下按实际比赛间隔重新验证：

基础假设：时间系统 `match_interval_target` = 2–5 个窗口，取中位数 3 天间隔。

| 建设阶段 | 维护费/日 | 3天维护费 | Tier 1 负场(100) | Tier 1 胜场(250) | 净额/周期(负场) | 净额/周期(胜场) |
|---|---|---|---|---|---|---|
| 无设施 | 25 | 75 | +100 | +250 | +25 | +175 |
| 初期（四设施 Lv.1） | 25+11=36 | 108 | +100 | +250 | −8 | +142 |
| 中期（四设施 Lv.3） | 25+20=45 | 135 | +100 | +250 | −35 | +115 |
| 终局（四设施 Lv.5） | 25+31=56 | 168 | +100 | +250 | −68 | +82 |

**关键发现:**
- 全 Lv.5 + 全负场 = 每周期净亏 68 经费——不可持续
- 全 Lv.5 + 全胜场 = 净余 82/周期——可持续但收窄
- 50% 胜率下（平均收入 175）：175 − 168 = +7/周期——勉强持平
- 建议最低可持续门槛：50%+ 胜率 + Tier 2 及以上联赛，或搭配阶段/赛季奖金；若赛季结算后仍低于最低常规操作成本，由经济系统 `season_recovery_floor_grant` 补足到恢复地板

**设计含义:**
1. MVP 维护费只提供轻量经营取舍和囤积防护，不应成为硬核经营失败条件
2. 玩家可以感知"建设更多 → 维护费更高"，但不需要通过拆迁或停建设施来维持基础可玩性
3. 若 playtest 显示低胜率队伍长期归零，优先调低 `facility_maintenance_delta`（每级增量），而非调高建设收益
4. 维护费调参必须匹配比赛间隔和经济系统软停滞恢复路径；建设系统不得单独制造不可恢复赤字

---

### 舍入规则总结

| 公式 | 舍入方式 | 理由 |
|---|---|---|
| 经费成本 (1) | `ceil()` | 消耗取整，确保玩家无法利用小数取整漏洞 |
| 时间成本 (2) | `ceil()` | 工期取整，完工发生在最后一天结束时 |
| 训练效率倍率 (3) | 保留浮点 | 乘法因子，在 `training_actual_gain` 计算时自然参与 |
| AP 加成 (4a) | MVP 固定 0；Alpha 使用 `floor()` | MVP 对齐经济系统 `facility_ap_bonus = 0`；Alpha 启用时保持 int 类型 |
| 伤病减免 (4b) | `floor()` | 回合数取整，保守偏向不超额减免 |
| 主场评分 (5) | 保留浮点 | 参与 `base_win_probability` 浮点运算 |
| 收入倍率 (6) | 保留浮点 | 乘入 `post_match_funds` 后统一 `floor()`（经济系统约定） |
| 青训营加成 (7a, 7b) | 7a: `floor()` / 7b: 保留浮点 | 潜力值为 int；倍率为乘法因子 |
| 邻接加成 (8) | MVP 不进入正式数值结算 | Alpha 启用前只返回中性值 |
| 维护费 (9) | 整数（无需舍入） | 所有输入均为 int |

## Edge Cases

- **If 玩家在已被占用的格子上尝试建造**: 建造按钮灰化，提示"此位置已被[设施名称]占用"。系统不得自动拆除或替换已有设施。
- **If 玩家尝试升级已达 Lv.5 的设施**: 升级按钮灰化，显示"已满级"。系统不得接受升级请求或扣除资源。
- **If 玩家建造/升级时经费不足**: Budget Preview 阶段即灰化确认按钮，显示"经费不足（需 X，当前 Y）"。不得进入 Constructing 或 Upgrading 状态。
- **If 所有 25 格（5×5）均已被设施占满且无设施可升级**: MVP 建设菜单显示"小镇已无空地"，建造按钮全局灰化；系统不要求玩家通过拆迁重排继续优化。Alpha 若开放拆除，可通过拆除腾出空间，但该能力不属于 MVP 常规玩家流程。
- **If 玩家在设施正在建造/升级期间尝试拆除同一设施**: MVP 玩家流程不显示拆除入口；Alpha/调试模式下拆除按钮灰化，提示"设施正在施工中，无法拆除"。必须等待 Construction/Upgrading → Active 状态转移完成后才可拆除。
- **If 建造或升级的完工节点与比赛日或赛季结算同时到达**: 时间系统按固定优先级顺序处理：赛后结算 > 建造完工 > 每日结算 > 阶段结算。建造完工不因与其他节点重合而被跳过或重复触发。
- **If 设施加成在训练或比赛中途改变（如相邻设施刚完工）**: 已开始的训练或比赛使用发起时的加成快照，不受中途完工影响。加成仅在下次行动发起时才以新值生效。
- **If 邻接关系存在但 MVP 未启用数值邻接**: 系统只在小镇摘要中展示邻接关系，不向训练、比赛、AP 或经济输出额外数值。`facility_training_multiplier`、`facility_ap_bonus`、`home_advantage_bonus` 和 `stadium_revenue_multiplier` 必须按 MVP 正式合同计算，不得暗中读取 Alpha 邻接预留公式。
- **If Alpha/调试模式中玩家拆除设施导致邻接关系变化**: 被拆设施自身加成立即移除；与它相邻的其他设施重新计算邻接展示关系。MVP 因未启用数值邻接，拆除不得导致训练、AP、主场、收入或潜力数值变化。
- **If 玩家尝试把拆除当作 MVP 布局优化手段**: MVP 玩家流程不提供常规拆迁重排入口；若调试或后续版本允许拆除，重建设施从 Lv.1 开始且不返还投入。系统不得把拆迁包装成推荐优化策略。
- **If 每日维护费扣除时经费余额不足**: 维护费按 `resource_settlement` 规则结算，经费 `clamp` 到 0（不可为负）。若触发经费归零，经济系统进入 Warning State，所有消耗经费的行动被锁定。系统不因维护费欠缴而自动降低设施等级或拆除设施。
- **If 玩家因维护费与低胜率组合进入连续多日经费归零状态**: MVP 设计必须提供“可恢复但不无成本”的软保护，不允许形成必须重开档才能脱困的长期停滞。最低保护形式可为：基础设施不停机、正式比赛节点保持可继续、且至少保留一条无需新增经费投入即可逐步恢复正现金流的经营路径。具体恢复手段由经济系统拥有。
- **If 存档时某设施正处于 Constructing 或 Upgrading 状态**: 存档完整保存当前状态、目标等级和剩余工期。读档后时间系统恢复剩余工期计数，到期正常触发完工。不会因读档而重置工期或丢失进度。
- **If 青训营的 `youth_age_threshold` 边界与球员生日重叠**: 球员年龄以赛季结算或招募时的"足球年龄"为准。若球员在赛季中途年满 23 岁，该赛季内仍享受年轻球员加成，下赛季开始时重新判定。
- **If 球场 Lv.0（未建造）时触发主场比赛**: `home_advantage_bonus = 0`，`stadium_revenue_multiplier = 1.0`。主场比赛仍然正常进行（默认中立主场），玩家不会因未建造球场而失去主场比赛资格。
- **If MVP `facility_training_multiplier` 超过 1.35**: 视为配置错误。MVP 正式训练设施倍率只允许训练场与青训营年轻球员轻量加成相乘，不含邻接乘区；超过上限说明 Alpha 预留公式被错误接入或调参越界。

## Dependencies

### Upstream Dependencies

| System | Type | What this system needs | Key interface |
|---|---|---|---|
| `design/gdd/balance-system.md` | Hard | 设施系数边界（`flat_modifier_sum_budget`、`percent_modifier_sum_budget`）、升级倍率安全范围、共享属性与资源定义 | 加成值变更后验证是否在数值系统定义的边界内 |
| `design/gdd/economy-management-system.md` | Hard | 资源充足性检查、经费扣除、每日维护费结算；`facility_ap_bonus` 在 MVP 固定为 0 | 建造/升级时 Budget Preview + 确认扣除；每日结算时维护费扣缴 |
| `design/gdd/time-and-season-progression-system.md` | Hard | 建设占用时段登记、完工节点触发、稳定节点保存时机 | 建造/升级发起时登记工期；工期到达时触发完工信号 |
| `design/gdd/save-and-load-system.md` | Hard | 设施列表、等级、布局、建造/升级剩余工期、已确认完工结果的持久化与恢复 | 稳定节点全量保存；读档时全量恢复 |
| `design/gdd/game-concept.md` | Hard | "像素小镇养成"支柱定义、MVP 范围约束、建设在核心循环中的定位 | 建设系统的体验目标和范围边界 |
| `design/gdd/systems-index.md` | Hard | 系统层级（Core）、优先级（MVP 最小建设切片；Alpha 扩展完整建设 UI 与深度建设）、依赖关系 | 系统定位、MVP 边界和设计顺序 |

### Downstream Dependencies

| System | Type | What this system provides | Key interface |
|---|---|---|---|
| `design/gdd/player-development-system.md` | Hard | MVP `facility_training_multiplier`（= `training_efficiency_multiplier × youth_training_bonus`，不含邻接乘区，硬上限 1.35），作为 `training_actual_gain` 第 4 因子接入 | 培养系统每次训练结算时读取 `facility_training_multiplier`；`potential_floor_boost` 与 `adj_youth_potential_boost` 在 Alpha 招募系统接入前不是 MVP 硬消费合同 |
| `design/gdd/match-competition-system.md` | Soft | MVP `home_advantage_bonus`（作为小幅 `facility_rating_bonus` 注入 `team_match_strength`，硬上限 5） | 主场赛前评分计算时通过 `team_match_strength` 接收小幅被动加成；`adj_stadium_home_bonus` 在 Alpha 前不是硬消费合同 |
| `design/gdd/main-loop-ui-framework.md` | Hard | 设施列表（类型、位置、等级、状态）、建造/升级进度、邻接关系图、加成摘要 | MVP 主界面渲染小镇摘要、设施状态与最小建设入口；Alpha 的建设与经营 UI 承接完整网格交互 |
| `design/gdd/audio-system.md` | Soft (Beta) | 建造开始、升级确认、建造/升级完工、维护费结算可视反馈的稳定事件语义 | 音频系统只消费建设反馈事件用于 SFX/氛围响应，不修改设施状态、建设时间、经济扣款或加成结果 |
| 声望与成就系统 | Soft (Alpha) | 设施建造/升级里程碑（如"建成第一座 Lv.5 设施"） | Alpha 阶段接入成就条件 |
| 建设与经营 UI | Hard (Alpha) | 网格状态、可建造/可升级/可拆除判断、成本预览 | Alpha 阶段独立建设界面；MVP 内嵌于主循环 UI |
| 随机事件系统 | Soft (Beta) | 设施相关事件入口（如"暴风雨损坏训练场"） | Beta 阶段接入 |
| `design/gdd/economy-management-system.md` | Hard (回传) | `facility_total_maintenance`（叠加 `daily_maintenance_cost`）；`facility_ap_bonus` 和 `stadium_revenue_multiplier` 在 MVP 固定为 0/1.0 或只读预留 | 每日结算时经济系统读取维护费总和；MVP 不通过设施增加 AP 恢复或比赛收入倍率 |
| `design/gdd/time-and-season-progression-system.md` | Hard (回传) | 建造/升级时间消耗请求（`construction_time`） | 建设发起时向时间系统登记工期 |

### Dependency Rules

1. 小镇建设系统提供的是设施建造、升级、布局和加成的权威规则，不是下游系统业务内容的定义；下游系统可以消费设施加成，但不能直接修改设施状态、等级或布局。
2. 任何下游系统若需要新增设施类型、改变邻接规则、或修改加成计算方式，必须先回到本系统修订，而不能在本地 GDD 中静默覆盖。
3. 当声望与成就系统、随机事件系统 GDD 完成后，本节对应的 Soft 条目应升级为 Hard，并在其 GDD 的 Dependencies 中反向声明对本系统的依赖。
4. 如果某个系统只展示设施信息而不改动建设状态，则它对本系统属于软依赖；如果某个系统消费设施加成、发起建造/升级/拆除请求、或持久化建设状态，则属于硬依赖。
5. 本系统对经济系统和时间系统的回传依赖（维护费、建设工期）必须在两者的 Dependencies 中被列为 Hard 下游依赖；AP 加成和收入倍率在 MVP 阶段不得列为硬消费合同。

## Tuning Knobs

### 成本与节奏

| 调参项 | 控制内容 | 安全范围 | 默认值 | 调高风险 | 调低风险 |
|---|---|---|---|---|---|
| `base_funds_cost[training_ground]` | 训练场 Lv.1 建造经费 | 150–250 | 200 | 早期建设门槛过高 | 建设决策无分量 |
| `base_funds_cost[medical_room]` | 医疗室 Lv.1 建造经费 | 100–200 | 150 | 同上 | 同上 |
| `base_funds_cost[youth_academy]` | 青训营 Lv.1 建造经费 | 200–400 | 300 | 同上 | 同上 |
| `base_funds_cost[stadium]` | 球场 Lv.1 建造经费 | 350–650 | 500 | 同上 | 同上 |
| `cost_multiplier` | 经费指数增长倍率 | 1.5–2.0 | 1.8 | 后期升级成本过高 | 后期成本无感 |
| `base_construction_time[*]` | 各设施新建工期（天） | 2–10 | 3/4/6/8 | 工期过长，建设反馈延迟 | 工期过短，建设无节奏感 |
| `base_upgrade_time[*]` | 各设施升级工期（天） | 1–6 | 2/3/4/5 | 同上 | 同上 |
| `time_multiplier` | 工期指数增长倍率 | 1.2–1.5 | 1.3 | 后期工期过长 | 后期工期递增感不足 |
| 网格尺寸 `M × N` | 小镇可用建造格数 | 4×4 至 6×6 | 5×5 | 空间过多，邻接布局无挑战 | 空间过少，设施摆不下 |

### 训练场

| 调参项 | 控制内容 | 安全范围 | 默认值 | 调高风险 | 调低风险 |
|---|---|---|---|---|---|
| `training_ground_bonus_delta` | 每级训练效率增量 | 0.02–0.03（MVP）/ 0.03–0.07（Alpha） | 0.03 | 训练收益过高，建设成为必点路线 | 训练场投资回报不足 |
| `adj_tr_med_coeff` | 邻接医疗室→受伤概率降幅/级 | 0.03–0.08 | 0.05 | 邻接完全消除伤病风险 | 邻接加成不可感知 |
| `adj_tr_youth_coeff` | 邻接青训营→年轻球员成长乘区/级 | 0.02–0.05 | 0.03 | 年轻球员成长过快 | 邻接回报不足 |

### 医疗室

| 调参项 | 控制内容 | 安全范围 | 默认值 | 调高风险 | 调低风险 |
|---|---|---|---|---|---|
| `medical_ap_bonus_per_level` | 每级 AP 增量系数 | MVP 固定 0；Alpha 0.5–0.9 | 0（MVP） | AP 过于充裕，行动点取舍消失 | 医疗室升级反馈不足 |
| `injury_recovery_per_level` | 每级伤病恢复减免增量 | 0.5–0.8 | 0.7 | 伤病几乎无影响 | 伤病惩罚过重 |
| `adj_med_tr_coeff` | 邻接训练场→额外 AP/级 | Alpha 预留 0.40–0.80 | 0（MVP） | 轻易触及 AP 上限 3 | 邻接回报不可感知 |

### 青训营

| 调参项 | 控制内容 | 安全范围 | 默认值 | 调高风险 | 调低风险 |
|---|---|---|---|---|---|
| `youth_potential_floor_per_level` | 每级新球员潜力下限提升 | 0.5–1.5 | 1.0 | 招募池整体过强 | 青训营投资回报不足 |
| `youth_growth_per_level` | 每级年轻球员训练乘区 | 0.02–0.03（MVP）/ 0.02–0.06（Alpha） | 0.03 | 年轻球员成长过快，青训营成为必点路线 | 回报不足 |
| `youth_age_threshold` | 年轻球员年龄上限 | 20–24 | 22 | 覆盖球员过多 | 覆盖球员过少 |
| `adj_youth_tr_coeff` | 邻接训练场→额外潜力下限/级 | 0.40–0.80 | 0.60 | 潜力膨胀 | 邻接回报不足 |

### 球场

| 调参项 | 控制内容 | 安全范围 | 默认值 | 调高风险 | 调低风险 |
|---|---|---|---|---|---|
| `home_advantage_per_level` | 每级主场评分加成 | 0.5–1.0（MVP）/ 1.0–2.5（Alpha） | 1.0 | 主场优势过大，建设影响压过阵容 | 主场身份不可感知 |
| `stadium_revenue_per_level` | 每级比赛收入倍率增量 | MVP 固定 0；Alpha 0.05–0.12 | 0（MVP） | 经费通胀并强化建设滚雪球 | 球场投资回报不足 |
| `adj_stad_tr_coeff` | 邻接训练场→额外主场评分/级 | Alpha 预留 0.50–1.50 | 0（MVP） | 主场评分过强 | 邻接回报不足 |

### 维护费

| 调参项 | 控制内容 | 安全范围 | 默认值 | 调高风险 | 调低风险 |
|---|---|---|---|---|---|
| `facility_maintenance_base[*]` | 各设施 Lv.1 每日维护费 | 1–5 | 2/2/3/4 | 日常经营压力过大 | 维护费无存在感 |
| `facility_maintenance_delta[*]` | 各设施每级维护费增量 | 1–3 | 1/1/1/2 | 高级设施维护负担过重 | 升级不产生额外成本 |

### 调参顺序建议

1. 先调成本与节奏组——确认建设投入的绝对难度
2. 再调训练场和球场的 MVP 轻量加成——确认回报可感知但不主导培养/比赛
3. Alpha 才调邻接系数——确认布局策略深度
4. 最后调维护费——确认长期经营可持续性且不制造不可恢复赤字

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

### 建造/升级流程

- **GIVEN** 玩家拥有足够经费且小镇有空地，**WHEN** 选择一个设施类型并确认建造，**THEN** 经费被扣除 `construction_cost_funds(facility, 1)` 的精确值，设施进入 Constructing 状态，UI 显示剩余工期 = `construction_time(facility, 1)`。
- **GIVEN** 一座设施处于 Active(Lv.N) 状态且 N < 5，玩家经费足够，**WHEN** 玩家发起升级并确认，**THEN** 经费被扣除 `construction_cost_funds(facility, N+1)`，设施进入 Upgrading 状态，升级期间设施维持 Lv.N 的加成不变。
- **GIVEN** 一座设施处于 Constructing 或 Upgrading 状态，**WHEN** 时间系统发出该设施的完工信号，**THEN** 在同一帧内：设施状态转移至 Active(Lv.N+1)（建造完工为 Lv.1），新等级加成立即生效，加成查询返回新等级对应值。
- **GIVEN** 玩家经费不足（当前 < 建造成本），**WHEN** 尝试建造或升级，**THEN** Budget Preview 显示"经费不足（需 X，当前 Y）"，确认按钮灰化，不扣除任何资源，设施状态不变。
- **GIVEN** 玩家经费足够、发起建造/升级扣款，**WHEN** 扣款过程中经费因其他并发操作变得不足，**THEN** 扣款失败，设施保持原状态（Empty 或 Active(Lv.N)），不创建施工计时器，经费余额不变。
- **GIVEN** 一座设施处于 Lv.5，**WHEN** 玩家查看该设施，**THEN** 升级按钮灰化并显示"已满级"。
- **GIVEN** MVP 玩家流程中一座设施处于 Constructing、Upgrading 或 Active 状态，**WHEN** QA 检查建设入口，**THEN** 不得出现常规拆除/重排入口；拆除能力只允许在 Alpha 或调试模式中暴露。
- **GIVEN** Alpha/调试模式中一座设施处于 Active 状态，**WHEN** 玩家确认拆除，**THEN** 加成立即移除，格子恢复 Empty，与被拆设施相邻的所有设施在同一帧内重新计算邻接展示关系；MVP 正式数值输出不得因邻接关系变化而改变。

### 训练场加成

- **GIVEN** 训练场处于 Lv.N，**WHEN** 查询 MVP `training_efficiency_multiplier`，**THEN** 返回 `1.0 + training_ground_bonus_delta × N`。验证：Lv.0=1.00, Lv.3=1.09, Lv.5=1.15（MVP 默认 delta=0.03）。

### 医疗室加成

- **GIVEN** 医疗室处于 Lv.N（N>0），**WHEN** 查询 MVP `medical_ap_bonus`，**THEN** 返回 0；医疗室不得在 MVP 中增加 `daily_ap_recovery`。
- **GIVEN** 医疗室处于 Lv.N 且与训练场邻接，**WHEN** 查询 MVP `facility_ap_bonus`，**THEN** 返回 0；邻接 AP 公式只作为 Alpha 预留，不参与 MVP 经济结算。
- **GIVEN** 医疗室处于 Lv.N，**WHEN** 查询 `injury_recovery_reduction`，**THEN** 返回 `clamp(floor(N × 0.7), (N>0?1:0), 2)`。验证：Lv.0=0, Lv.1=1, Lv.2=1, Lv.3=2, Lv.4=2, Lv.5=2。

### 球场加成

- **GIVEN** 球场处于 Lv.N，**WHEN** 查询 MVP `home_advantage_bonus`，**THEN** 返回 `home_advantage_per_level × N`。验证：Lv.0=0, Lv.3=3.0, Lv.5=5.0（MVP 默认 1.0/级）。
- **GIVEN** 球场处于 Lv.N，**WHEN** 查询 MVP `stadium_revenue_multiplier`，**THEN** 返回 1.00；球场收入倍率只作为 Alpha 预留，不参与 MVP 赛后经费公式。

### 青训营加成

- **GIVEN** 青训营处于 Lv.N，**WHEN** 查询 `potential_floor_boost`，**THEN** 返回 `clamp(floor(youth_potential_floor_per_level × N), 0, 5)`。验证：Lv.0=0, Lv.3=3, Lv.5=5（默认 1.0/级）。
- **GIVEN** 青训营处于 Lv.N 且球员年龄 = A，**WHEN** 查询 MVP `youth_training_bonus`，**THEN**：若 A ≤ `youth_age_threshold`，返回 `clamp(1.0 + youth_growth_per_level × N, 1.00, 1.15)`；若 A > `youth_age_threshold`，返回 1.0。验证：Lv.3 + 年龄 20 → 1.09；Lv.5 + 年龄 23（超过默认 22）→ 1.0；Lv.0 始终返回 1.0。

### 邻接加成

- **GIVEN** 两座设施在 MVP 网格中共享边，**WHEN** 查询邻接状态，**THEN** 系统返回它们相邻并可在小镇摘要中展示关系；**WHEN** 查询训练、AP、主场或收入正式加成，**THEN** 不得因该邻接额外增加数值。
- **GIVEN** 两座设施仅对角接触，**WHEN** 查询邻接状态，**THEN** 系统返回不相邻；小镇摘要不得把对角关系展示为邻接收益。

### 维护费

- **GIVEN** 所有已建成的设施及其等级，**WHEN** 查询 `facility_total_maintenance`，**THEN** 返回 `SUM 对所有已建造设施: (facility_maintenance_base[fac] + facility_maintenance_delta[fac] × (level − 1))`。验证：无设施 → 0；训练场 Lv.3 + 医疗室 Lv.2 → (2+1×2) + (2+1×1) = 4+3 = 7。

### Alpha/调试拆除与邻接更新

- **GIVEN** Alpha/调试模式的设施布局包含多种邻接关系，**WHEN** QA 拆除其中一座设施，**THEN** 被拆设施加成立即移除；与被拆设施相邻的所有设施在同一帧内重新计算邻接展示关系；MVP 正式训练、AP、主场、收入和潜力数值输出不因该邻接变化而改变。

### 存档读档

- **GIVEN** 存档时某设施正在建造/升级中（状态=Constructing 或 Upgrading，剩余工期 = D），**WHEN** 读档恢复，**THEN** 设施状态、目标等级和剩余工期 D 完整恢复；工期继续从读档点倒计时（不会重置为初始工期）；完工触发时机与存档前一致。

### 集成验证

- **[Integration AC 1 — 成本]** **GIVEN** MVP 完整实现，**WHEN** QA 从新档开始依次建造每类设施 Lv.1，**THEN** 每次建造扣款 = `ceil(base_funds_cost[fac] × cost_multiplier^0)`，工期 = `ceil(base_construction_time[fac] × time_multiplier^0)`。
- **[Integration AC 2 — 加成递增]** **GIVEN** 一座设施从 Lv.1 逐级升至 Lv.5，**WHEN** 每级完工后查询该设施的加成输出，**THEN** 每级加成值 ≥ 上一级加成值；至少 3 个等级的输出严格大于前一级（确保升级有可感知回报）。
- **[Integration AC 3 — 邻接判定]** **GIVEN** 训练场与医疗室在 5×5 网格上相邻（共享边）、训练场与青训营对角相邻（仅共享角），**WHEN** 查询两对邻接状态，**THEN** 训练场↔医疗室返回相邻并可展示；训练场↔青训营（对角）返回不相邻；两者的 MVP 正式训练、AP、主场、收入和潜力数值输出均保持中性值。
- **[Integration AC 4 — Alpha/调试拆除级联]** **GIVEN** Alpha/调试模式中训练场同时与医疗室和青训营邻接，**WHEN** 拆除训练场，**THEN** 医疗室和青训营的邻接展示关系在同一帧内更新；MVP `facility_ap_bonus` 仍为 0，且拆除不得产生任何额外训练、AP、主场、收入或潜力数值变化。
- **[Integration AC 5 — 存档恢复]** **GIVEN** 设施建造中（剩余工期 3 天），**WHEN** 存档 → 推进 1 天 → 读档，**THEN** 剩余工期恢复为 3 天（而非 2 天）；继续推进 3 天后正确触发完工。

## Open Questions

[To be designed]
