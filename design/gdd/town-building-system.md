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

小镇建设系统是《足球小镇》中负责设施建造、升级、布局规划与长期加成的世界管理层，也是"像素小镇养成"支柱在 MVP 阶段的核心承载系统。它在数据层面承接数值系统定义的设施系数边界、升级倍率边界和邻接加成上限，把建设行为统一映射为可计算、可验证的属性或资源修正；在体验层面，它让玩家亲手从一片空地开始，逐步建造训练场、医疗室、青训营等足球主题设施，在视觉上看到小镇从简朴走向繁荣，并持续感受到"我的投入正在让这个地方变得更好"。

本系统不拥有训练内容（培养系统）、比赛规则（比赛系统）、资源账目（经济系统）或时间推进节奏（时间系统）——它拥有的是"哪些设施可以建造、建造和升级需要什么条件、建成后对球员培养和比赛表现产生什么加成、以及设施之间的布局关系如何影响效率"。在 MVP 阶段，本系统的目标是控制范围：提供有限但可感知的设施集合，让玩家通过建设行为看到小镇外观变化并感受到长期的属性/资源回报，从而验证"建设投入 → 长期加成 → 更强的培养和比赛表现"这一核心经营假设。

## Player Fantasy

小镇建设系统服务的玩家幻想是："从一片空地开始，亲手把我的足球小镇建成一座充满活力的足球之城。"

这种幻想包含两个层面。在直接的建造面上，玩家面对一块可规划的小镇地图，决定先建训练场还是先修医疗室、把青训营放在球场旁边还是办公区附近、攒够钱后是先升级现有设施还是解锁新建筑——每一次建造和升级都是玩家亲手留下的"经营痕迹"，当小镇从寥寥几座简朴建筑逐渐扩展为拥有训练基地、医疗中心、青训学院和球迷广场的繁荣社区时，玩家会感到自己是这座小镇真正的创建者和主人。在间接的回报面上，玩家不需要每次训练前重新检查设施加成——系统将设施效果静默注入训练收益、比赛表现和资源恢复中，让玩家在培养出更强球员、赢得更关键比赛、看到更多资源流入时，自然地感受到"这些回报的来源之一是我当初选择建设的那座训练场"。

参考那些让人感到"亲手建设成就"而非"最优布局焦虑"的游戏：Stardew Valley 中第一年精打细算后在第二年看到农场扩展的满足感，Football Manager 中升级训练设施后看到球员发展加速的回报感。小镇建设系统必须让"建设"成为玩家长期经营中的稳定成长投资——每一次建造都有可见的回报、每一次升级都有可感知的增益、每一个布局选择都体现玩家的个人风格，而不是强迫玩家为了数值最优解而放弃对小镇面貌的自主权。

## Detailed Design

### Core Rules

**规则 1 — 建设系统控制权**: 小镇建设系统是所有设施建造、升级、布局和加成的权威来源。其他系统可以消费设施加成（如培养系统使用训练效率倍率），但不得直接修改设施状态、等级或布局。

**规则 2 — MVP 设施集合**: MVP 阶段提供最小建设切片，包含 4 种核心设施、建造/升级/拆除状态、维护费、基础邻接和下游只读加成查询。完整建设与经营 UI、扩展设施、深层布局优化和设施皮肤留到 Alpha。MVP 阶段提供 4 种核心设施：

| 设施 | 功能定位 | 基础效果 |
|---|---|---|
| 训练场 | 提升日常训练效率 | 训练获得的 `attribute_growth` 乘以 `training_efficiency_multiplier` |
| 医疗室 | 加速疲劳恢复与伤病康复 | 每日 AP 恢复量增加 `medical_ap_bonus`；伤病恢复回合数减少 |
| 青训营 | 提升新球员初始质量 | 新招募球员的潜力下限提升；年轻球员（≤22 岁）训练成长额外加成 |
| 球场 | 增强主场优势与比赛收入 | 主场比赛时 `self_team_rating` 获得 `home_advantage_bonus`；比赛经费收入乘以 `stadium_revenue_multiplier` |

**规则 3 — 设施等级**: 每种设施有 5 个等级（Lv.1–Lv.5）。初始均为未建造状态。建造 = 解锁 Lv.1。升级 = Lv.N → Lv.N+1。每升一级：基础效果数值递增（非倍率叠加）、建造/升级的经费和时间成本递增、设施外观变化。

**规则 4 — 建造与升级成本**: 每项建造/升级消耗两类资源：经费 + 时间单位。成本由 Tuning Knobs 定义，遵循公式：
`construction_cost_funds(level) = base_cost × level_cost_multiplier ^ (level - 1)`
`construction_time(level) = base_time × level_time_multiplier ^ (level - 1)`

**规则 5 — 布局与邻接**: 小镇使用 `M × N` 网格地图（MVP 建议 5×5，由 Tuning Knobs 定义）。每座设施占地 1 格。设施只能放在空格上。邻接定义为共享边（四方向）。邻接加成规则：
- 训练场 ↔ 医疗室相邻：训练场获得 `adj_tr_med_bonus`（降低训练受伤概率）；医疗室获得 `adj_med_tr_bonus`（AP 恢复再增加）
- 训练场 ↔ 青训营相邻：训练场获得 `adj_tr_youth_bonus`（年轻球员额外成长乘区）；青训营获得 `adj_youth_tr_bonus`（新球员潜力下限再提升）
- 球场 ↔ 训练场相邻：球场获得 `adj_stad_tr_bonus`（主场评分加成再增加）
- 球场 ↔ 医疗室相邻：无特殊加成
- 球场 ↔ 青训营相邻：无特殊加成
- 医疗室 ↔ 青训营相邻：无特殊加成

设施可被拆除并重建到其他位置，拆除不返还资源，新位置需重新从 Lv.1 开始建造。

**规则 6 — 加成生效时机**: 设施加成在设施建成（完工节点到达）后立即生效。升级在完工后立即应用新等级的加成。拆除后加成立即移除。加成变化不影响已经结算完成的历史结果。

**规则 7 — MVP 范围控制**:
- 实现 4 类设施的建造、升级、拆除、维护费、存档恢复和只读加成查询；主循环 UI 只展示小镇摘要与最小建设入口
- 实现被 MVP 下游消费的输出：`facility_training_multiplier`、`facility_ap_bonus`、`facility_total_maintenance`、`home_advantage_bonus + adj_stadium_home_bonus`、`stadium_revenue_multiplier`
- `potential_floor_boost`、`adj_youth_potential_boost`、`injury_recovery_reduction`、`training_injury_prob_multiplier` 在 MVP 中保留为公式和数据字段，但不作为 MVP 下游硬消费合同；招募质量、伤病概率、伤病恢复系统在 Alpha 接入后再把这些输出升级为硬依赖
- 不实现设施之间的组合加成（如"训练场+医疗室+青训营三件套"额外奖励）
- 不实现设施皮肤/外观选择
- 不实现设施出租/共享/多球队共用
- 邻接规则仅限上述 3 对，不做通用邻接矩阵

### States and Transitions

| 状态 | 描述 | 进入条件 | 退出条件 | 有效下一状态 |
|---|---|---|---|---|
| **Empty** (空地) | 网格槽位为空，可建造 | 初始状态 / 拆除完成 | 玩家确认建造 | Constructing |
| **Constructing** (建造中) | 设施正在首次建造，尚未生效 | 玩家确认建造并支付成本 | 时间系统触发完工节点 | Active(Lv.1) |
| **Active(Lv.N)** (运作中) | 设施在等级 N 正常运行，提供对应加成 | 建造完工 / 升级完工 | 玩家发起升级 / 玩家发起拆除 | Upgrading / Demolishing |
| **Upgrading** (升级中) | 设施正在从 Lv.N 升级到 Lv.N+1 | 玩家确认升级并支付成本 | 时间系统触发完工节点 | Active(Lv.N+1) |
| **Demolishing** (拆除中) | 设施正在被拆除（MVP 设为即时，不占时间） | 玩家确认拆除 | 拆除完成 | Empty |

**状态转换规则**:
- Empty → Constructing: 仅当玩家经费 ≥ 建造成本、且目标格子为空
- Constructing → Active(Lv.1): 时间系统发出该建设项目的完工信号
- Active(Lv.N) → Upgrading: 仅当 N < 5、经费 ≥ 升级成本、且完工前该格不被拆除
- Upgrading → Active(Lv.N+1): 时间系统发出该升级项目的完工信号。升级期间设施维持 Lv.N 的加成（不中断服务）
- Active(Lv.N) → Demolishing: 玩家确认拆除，即时完成，加成立即移除，格子恢复 Empty
- 建造/升级中不允许拆除同一设施，必须等待完工后方可拆除

### Interactions with Other Systems

| 系统 | 数据流入建设系统 | 数据流出建设系统 | 交互时机 |
|---|---|---|---|
| **数值系统** (Hard 上游) | 设施系数边界（`flat_modifier_sum_budget`、`percent_modifier_sum_budget`）、升级倍率安全范围 | 训练效率倍率（`training_efficiency_multiplier`）、AP 恢复加成（`facility_ap_bonus`）、主场评分加成（`home_advantage_bonus`）等实际加成值 | 加成值变更时（建造完工/升级完工/拆除）→ 通知数值系统验证是否在边界内 |
| **经济管理系统** (Hard 上游·消费方) | 资源充足性确认、实际经费扣除、每日维护费扣除 | 建造/升级经费消耗请求、每日维护费基准（`facility_maintenance_cost` = 各设施维护费之和） | 建造/升级发起时（Budget Preview + 确认扣除）；每日结算时（维护费） |
| **时间与赛季推进系统** (Hard 上游) | 完工节点信号、建设占用时段确认 | 建造/升级时间消耗请求（`construction_time`） | 建造/升级发起时（时间系统登记工期）；工期到达时（时间系统触发完工） |
| **存档与读档系统** (Hard 上游) | 存档/读档指令 | 设施列表（类型、位置、等级、当前状态）、建造/升级剩余工期、已确认完工结果 | 稳定节点保存时全量写入；读档时全量恢复 |
| **运动员培养系统** (Hard 下游·消费方) | 球员年龄（用于年轻球员训练倍率判定） | `facility_training_multiplier`（训练场、青训营自身年轻球员加成、训练场↔青训营邻接加成的组合倍率） | 每次训练结算时，培养系统读取当前设施加成；招募潜力下限输出在 Alpha 接入 |
| **比赛竞技系统** (Hard 下游·消费方) | — | `home_advantage_bonus`（球场提供，加入 `self_team_rating` 修正）、`stadium_revenue_multiplier`（球场提供，乘入赛后经费计算） | 赛前评分计算时；赛后奖励结算时 |
| **主循环 UI 框架** (Hard 下游·展示方) | — | 设施列表（类型、位置、等级、状态）、建造/升级进度、邻接关系、加成摘要 | MVP 主界面渲染小镇摘要与最小建设入口；完整建设界面由 Alpha 的建设与经营 UI 承接 |
| **建设与经营 UI** (Hard 下游·展示方·Alpha) | — | 网格状态（每格为空/设施类型/等级）、可建造/可升级/可拆除判断、成本预览 | Alpha 阶段接入；MVP 阶段建设交互内嵌于主循环 UI |

> **邻接双向性**: 训练场 ↔ 医疗室、训练场 ↔ 青训营、训练场 ↔ 球场的三种邻接关系中，双方各自获得不同的邻接加成（见规则 5）。这些加成在设施完工或拆除时立刻重新计算并通知下游系统。

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
| `training_ground_bonus_delta` | float | 0.03–0.07 | 每级增加的训练效率百分比，默认 0.05 |

**输出范围:** 1.00（未建造）至 1.25（Lv.5）。

**等级-倍率对照表（默认 delta = 0.05）:**

| Lv.0 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|
| 1.00 | 1.05 | 1.10 | 1.15 | 1.20 | 1.25 |

**计算示例:**

训练场 Lv.3: `1.0 + 0.05 × 3 = 1.15`
本系统将训练类倍率组合为 `facility_training_multiplier`，作为新因子接入 `training_actual_gain`（玩家培养系统第 4 因子）:
`facility_training_multiplier = training_efficiency_multiplier × youth_training_bonus × adj_tr_youth_multiplier`
计算示例: 若 `attribute_growth = 0.8`，`fatigue_adjusted_training_efficiency = 0.9`，`training_focus_match_multiplier = 1.0`，`facility_training_multiplier = 1.15`，则:
`training_actual_gain = min(potential_cap - current, 0.8 × 0.9 × 1.0 × 1.15) = min(potential_cap - current, 0.828)`
对比无训练场时的 `0.8 × 0.9 × 1.0 = 0.72`，Lv.3 训练场使单次训练收益提升约 15%。

**退化防护:** `level = 0` 时结果为 1.0，不产生退化。倍率始终 >= 1.0，不会反向削减训练收益。

---

### 4. AP 恢复加成与伤病恢复（医疗室）

医疗室提供两项独立加成: (a) AP 恢复加成、(b) 伤病恢复回合减免。

#### 4a. AP 恢复加成

**表达式:**

`medical_ap_bonus(level) = clamp( floor( level × medical_ap_bonus_per_level ), (level > 0 ? 1 : 0), 3 )`

其中 `level` 为医疗室当前等级，未建造时为 0。clamp 下限在 `level > 0` 时为 1（Lv.1 保底），上限 3 由经济管理系统 `facility_ap_bonus` 范围 [0, 3] 约束。

> **设计注**: `facility_ap_bonus` 输出范围 [0, 3] 只有 4 个离散值，而设施有 5 个等级，因此必然存在相邻等级输出相同的情况。默认系数 0.7 确保最多连续 2 个等级共享同一输出值，避免 Lv.1–Lv.3 三级无增量的"死区"。

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `level` | int | 0–5 | 医疗室当前等级（0 = 未建造） |
| `medical_ap_bonus_per_level` | float | 0.5–0.9 | 每级 AP 增量系数，默认 0.7 |

**输出范围:** 0–3（整数）。上限 3 由经济管理系统 `facility_ap_bonus` 范围 [0, 3] 约束。

**等级-AP对照表（默认 0.7）:**

| Lv.0 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|
| 0 | 1 | 1 | 2 | 2 | 3 |

**计算示例:**

医疗室 Lv.1: `clamp(floor(1 × 0.7), 1, 3) = clamp(0, 1, 3) = 1`（Lv.1 保底）
医疗室 Lv.2: `clamp(floor(2 × 0.7), 1, 3) = clamp(1, 1, 3) = 1`
医疗室 Lv.3: `clamp(floor(3 × 0.7), 1, 3) = clamp(2, 1, 3) = 2`（Lv.2→Lv.3 首次出现 AP 增量）
结合经济系统: `daily_ap_recovery = base_ap_recovery + facility_ap_bonus = 5 + 1 = 6` AP/日。

**对接经济系统:** 实际输出通过 `facility_ap_bonus = clamp(medical_ap_bonus + adj_med_ap_bonus, 0, 3)` 汇总后传入 `daily_ap_recovery`。

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
| `home_advantage_per_level` | float | 1.0–2.5 | 每级增加的球队评分点数，默认 2.0 |

**输出范围:** 0–10（Lv.5 时 +10）。

**等级-加成对照表:**

| Lv.0 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|
| 0.0 | 2.0 | 4.0 | 6.0 | 8.0 | 10.0 |

**计算示例:**

球场 Lv.4，`team_match_strength = 65`，`opponent_team_match_strength = 62`，`rating_win_slope = 0.0045`:
`team_match_strength_effective = 65 + 8.0 = 73.0`
`base_win_probability = clamp(0.50 + (73.0 - 62.0) × 0.0045, 0.05, 0.95) = clamp(0.5495, 0.05, 0.95) = 0.5495`

对比无球场时的 `base_win_prob = clamp(0.50 + 3 × 0.0045, ...) = 0.5135`，Lv.4 球场带来约 +3.6% 胜率提升。

**退化防护:** `level = 0` 时结果为 0，客场比赛不受影响。

---

### 6. 比赛收入倍率（球场）

**表达式:**

`stadium_revenue_multiplier(level) = 1.0 + stadium_revenue_per_level × level`

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `level` | int | 0–5 | 球场当前等级 |
| `stadium_revenue_per_level` | float | 0.05–0.12 | 每级增加的收入百分比，默认 0.08 |

**输出范围:** 1.00–1.40（Lv.5 时 +40% 比赛收入）。

**等级-倍率对照表:**

| Lv.0 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|
| 1.00 | 1.08 | 1.16 | 1.24 | 1.32 | 1.40 |

**计算示例:**

球场 Lv.3，Tier 1 联赛，胜场。`stadium_revenue_multiplier` 作为第 4 因子接入经济系统 `post_match_funds` 公式:
`post_match_funds = base_match_funds × league_tier_multiplier × match_result_multiplier × stadium_revenue_multiplier`
`= 250 × 1.0 × 1.0 × 1.24 = 310`（经济系统 `floor()` 取整后）
对比无球场时的 250，增收 60 经费/场。

**退化防护:** `level = 0` 时倍率为 1.0，不改变收入。

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

`youth_training_bonus(level) = clamp( 1.0 + youth_growth_per_level × level, 1.00, 1.20 )`

触发条件: 球员年龄 `≤ youth_age_threshold`（默认 22 岁）。clamp 上限 1.20 确保即使调参提高 `youth_growth_per_level`，输出也不会突破声明范围。

**变量表:**

| 符号 | 类型 | 范围 | 描述 |
|------|------|------|------|
| `level` | int | 0–5 | 青训营当前等级 |
| `youth_growth_per_level` | float | 0.02–0.06 | 每级增加的年轻球员成长百分比，默认 0.04 |
| `youth_age_threshold` | int | 20–24 | 年轻球员年龄判定上限，默认 22 |

**输出范围:** 1.00–1.20（Lv.5 时 +20% 训练成长）。

| Lv.0 | Lv.1 | Lv.2 | Lv.3 | Lv.4 | Lv.5 |
|---|---|---|---|---|---|
| 1.00 | 1.04 | 1.08 | 1.12 | 1.16 | 1.20 |

**计算示例:**

青训营 Lv.4，训练一名 20 岁球员:
`training_actual_gain_with_youth = training_actual_gain × youth_training_bonus(4) = training_actual_gain × 1.16`
若同时有训练场 Lv.3（`training_efficiency_multiplier = 1.15`），则:
`total_effective_multiplier = 1.15 × 1.16 = 1.334`
年轻球员在双设施加持下获得 +33.4% 训练效率。

**退化防护:** `level = 0` 时倍率为 1.0。球员年龄超过阈值时不适用此加成。

---

### 8. 邻接加成体系

#### 8.1 邻接判定规则

在 5×5 网格上，两个设施**邻接**当且仅当它们共享一条边（四方向: 上/下/左/右）。对角相邻不算邻接。

每个设施可同时与多个邻接设施形成加成对，各类加成独立叠加。

#### 8.2 三组邻接关系

| 邻接对 | 受益方 | 加成类型 | 系数变量 | 默认值 |
|---|---|---|---|---|
| 训练场 ↔ 医疗室 | 训练场 | 降低训练受伤概率 | `adj_tr_med_coeff` | 0.05 |
| 训练场 ↔ 医疗室 | 医疗室 | 额外 AP 恢复 | `adj_med_tr_coeff` | 0.50 |
| 训练场 ↔ 青训营 | 训练场 | 年轻球员额外成长乘区 | `adj_tr_youth_coeff` | 0.03 |
| 训练场 ↔ 青训营 | 青训营 | 额外潜力下限提升 | `adj_youth_tr_coeff` | 0.50 |
| 球场 ↔ 训练场 | 球场 | 额外主场评分加成 | `adj_stad_tr_coeff` | 1.00 |

#### 8.3 通用邻接加成公式

对所有邻接加成对 (A, B)，其中受益方为目标设施 `fac`，另一侧为来源设施 `src`:

`adjacency_bonus = coefficient × min(level_fac, level_src)`

使用 `min()` 确保较弱一方限制协同效果，鼓励玩家均衡升级双方设施而非单独拉高一方。

当任一设施未建造（level = 0）时，`min = 0`，加成自动为 0。

---

#### 8.3a 训练场 ← 医疗室: 训练受伤概率降低

**表达式:**

`training_injury_prob_multiplier = max( 0.40, 1.0 - adj_tr_med_coeff × min(tg_level, med_level) )`

**输出范围:** 1.00（无加成）至 0.75（Lv.5+5 时 -25%），硬底限 0.40。

**计算示例:**

训练场 Lv.3 与医疗室 Lv.2 邻接:
`training_injury_prob_multiplier = max(0.40, 1.0 - 0.05 × min(3, 2)) = max(0.40, 1.0 - 0.10) = 0.90`

训练受伤概率降至原来的 90%。

**退化防护:** `max(0.40, ...)` 确保受伤概率降幅不超过 60%，防止邻接完全消除伤病风险。

---

#### 8.3b 医疗室 ← 训练场: 额外 AP 恢复

**表达式:**

`adj_med_ap_bonus = clamp( floor( adj_med_tr_coeff × min(tg_level, med_level) ), (min(tg_level, med_level) ≥ 1 ? 1 : 0), 2 )`

**输出范围:** 0–2（整数 AP）。clamp 下限在双方均已建造（min ≥ 1）时为 1，确保第一对邻接即有可见回报。默认系数 0.60 避免 min=2 与 min=3 输出相同。

| min(tg, med) | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| `adj_med_ap_bonus` | 1 | 1 | 2 | 2 | 2 |

**计算示例:**

医疗室 Lv.4 与训练场 Lv.5 邻接:
`adj_med_ap_bonus = clamp(floor(0.60 × min(5, 4)), 0, 2) = clamp(floor(2.4), 0, 2) = 2`

汇总 AP（含经济系统上限）:
`facility_ap_bonus = clamp(medical_ap_bonus(4) + 2, 0, 3) = clamp(2 + 2, 0, 3) = 3`

Lv.4 医疗室 + Lv.5 训练场邻接可提前达到 AP 上限 3。

---

#### 8.3c 训练场 ← 青训营: 年轻球员额外成长乘区

**表达式:**

`adj_tr_youth_multiplier = 1.0 + adj_tr_youth_coeff × min(tg_level, ya_level)`

**输出范围:** 1.00–1.15（Lv.5+5 时 +15%）。

| min(tg, ya) | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| `adj_tr_youth_multiplier` | 1.03 | 1.06 | 1.09 | 1.12 | 1.15 |

**计算示例:**

训练场 Lv.5 与青训营 Lv.3 邻接，训练 19 岁球员:
`adj_tr_youth_multiplier = 1.0 + 0.03 × min(5, 3) = 1.09`
该球员的总成长倍率:
`total = training_efficiency_multiplier(5) × youth_training_bonus(3) × adj_tr_youth_multiplier = 1.25 × 1.12 × 1.09 = 1.526`

---

#### 8.3d 青训营 ← 训练场: 额外潜力下限提升

**表达式:**

`adj_youth_potential_boost = clamp( floor( adj_youth_tr_coeff × min(tg_level, ya_level) ), (min(tg_level, ya_level) ≥ 1 ? 1 : 0), 2 )`

**输出范围:** 0–2（整数）。clamp 上限 2 确保调参上限不突破声明范围；下限在双方均已建造时保底 1。默认系数 0.60 避免 min=2 与 min=3 输出相同。

| min(tg, ya) | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| `adj_youth_potential_boost` | 1 | 1 | 2 | 2 | 2 |

**计算示例:**

青训营 Lv.5 与训练场 Lv.5 邻接:
`adj_youth_potential_boost = floor(0.60 × min(5, 5)) = floor(3.0) = 3 → clamp(3, 1, 2) = 2`
总潜力下限提升 = 青训营自身 `potential_floor_boost(5) = 5` + 邻接 `2 = 7` 点。

---

#### 8.3e 球场 ← 训练场: 额外主场评分加成

**表达式:**

`adj_stadium_home_bonus = clamp( adj_stad_tr_coeff × min(stad_level, tg_level), 0, 5 )`

**输出范围:** 0–5（浮点评分）。clamp 上限 5 确保调参上限不突破声明范围。

| min(stad, tg) | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| `adj_stadium_home_bonus` | 1.0 | 2.0 | 3.0 | 4.0 | 5.0 |

**计算示例:**

球场 Lv.3 与训练场 Lv.5 邻接:
`adj_stadium_home_bonus = 1.0 × min(3, 5) = 3.0`
主场总评分加成:
`effective_home_advantage = home_advantage_bonus(3) + 3.0 = 6.0 + 3.0 = 9.0`

对比无邻接时的 6.0 分加成，邻接使球场效果提升 50%。

**边界验证:** 最大情况（球场 Lv.5 + 训练场 Lv.5 邻接）: `10.0 + 5.0 = 15.0`。此值作为 `facility_rating_bonus` 注入比赛系统的 `team_match_strength`，允许主场有效队伍评分超过 100；进入 `base_win_probability` 前不按属性上限钳制，最终由胜率公式的 0.05–0.95 clamp 兜底。`flat_modifier_sum_budget` 只约束 per-player 属性修正，不约束队伍级设施评分加成。

---

#### 8.4 邻接叠加规则

设施可同时享受多对邻接关系的加成，各对独立计算后叠加:

**示例 — 完全体训练场:**

训练场 Lv.5，同时邻接医疗室 Lv.5 和青训营 Lv.5:
- 自身: `training_efficiency_multiplier = 1.25`
- 来自医疗室: `training_injury_prob_multiplier = max(0.40, 1.0 - 0.05 × 5) = 0.75`
- 来自青训营: `adj_tr_youth_multiplier = 1.0 + 0.03 × 5 = 1.15`
- 三项加成互不覆盖，同时生效。

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

**对接经济系统:** 经济系统的 `daily_maintenance_cost` 由 `base_maintenance_cost`（20–30）扩展为 `base_maintenance_cost + facility_total_maintenance`。

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
- 建议最低可持续门槛：50%+ 胜率 + Tier 2 及以上联赛，或搭配阶段/赛季奖金

**设计含义:**
1. 过度建设而比赛成绩不佳将导致结构性赤字——建设系统本身就是风险/回报权衡
2. 玩家必须在"建设更多 → 维护费更高"与"维持胜率 → 覆盖维护费"之间取得平衡
3. 若 playtest 显示此压力过大，优先调低 `facility_maintenance_delta`（每级增量），而非调高比赛收入
4. 建议在 Tuning Knobs 维护费表中增加"匹配比赛间隔"作为调参约束因子

---

### 舍入规则总结

| 公式 | 舍入方式 | 理由 |
|---|---|---|
| 经费成本 (1) | `ceil()` | 消耗取整，确保玩家无法利用小数取整漏洞 |
| 时间成本 (2) | `ceil()` | 工期取整，完工发生在最后一天结束时 |
| 训练效率倍率 (3) | 保留浮点 | 乘法因子，在 `training_actual_gain` 计算时自然参与 |
| AP 加成 (4a) | `floor()` | 对齐经济系统 `facility_ap_bonus` int 类型约定 |
| 伤病减免 (4b) | `floor()` | 回合数取整，保守偏向不超额减免 |
| 主场评分 (5) | 保留浮点 | 参与 `base_win_probability` 浮点运算 |
| 收入倍率 (6) | 保留浮点 | 乘入 `post_match_funds` 后统一 `floor()`（经济系统约定） |
| 青训营加成 (7a, 7b) | 7a: `floor()` / 7b: 保留浮点 | 潜力值为 int；倍率为乘法因子 |
| 邻接加成 (8) | AP: `floor()`；分数: 保留浮点 | 各依目标类型 |
| 维护费 (9) | 整数（无需舍入） | 所有输入均为 int |

## Edge Cases

- **If 玩家在已被占用的格子上尝试建造**: 建造按钮灰化，提示"此位置已被[设施名称]占用"。系统不得自动拆除或替换已有设施。
- **If 玩家尝试升级已达 Lv.5 的设施**: 升级按钮灰化，显示"已满级"。系统不得接受升级请求或扣除资源。
- **If 玩家建造/升级时经费不足**: Budget Preview 阶段即灰化确认按钮，显示"经费不足（需 X，当前 Y）"。不得进入 Constructing 或 Upgrading 状态。
- **If 所有 25 格（5×5）均已被设施占满且无设施可升级**: 建设菜单显示"小镇已无空地"，建造按钮全局灰化。玩家必须先拆除某设施腾出空间，或升级现有设施。
- **If 玩家在设施正在建造/升级期间尝试拆除同一设施**: 拆除按钮灰化，提示"设施正在施工中，无法拆除"。必须等待 Construction/Upgrading → Active 状态转移完成后才可拆除。
- **If 建造或升级的完工节点与比赛日或赛季结算同时到达**: 时间系统按固定优先级顺序处理：赛后结算 > 建造完工 > 每日结算 > 阶段结算。建造完工不因与其他节点重合而被跳过或重复触发。
- **If 设施加成在训练或比赛中途改变（如相邻设施刚完工）**: 已开始的训练或比赛使用发起时的加成快照，不受中途完工影响。加成仅在下次行动发起时才以新值生效。
- **If 邻接加成汇总后超出上游系统边界**: `facility_ap_bonus` 经 `clamp(0, 3)` 确保不突破经济系统上限；`home_advantage_bonus + adj_stadium_home_bonus` 的最大 MVP 输出为 15 点（球场 Lv.5 + 训练场 Lv.5 邻接），作为队伍级 `facility_rating_bonus` 注入比赛系统 `team_match_strength`。该队伍级主场评分加成不直接受 `flat_modifier_sum_budget`（per-player 属性修正约束）限制；若未来 Tuning Knobs 调高系数导致综合优势过大，由数值系统评估是否新增上限。
- **If 玩家拆除设施导致邻接加成链断裂**: 被拆设施自身加成立即移除；与它邻接的其他设施重新计算邻接加成（可能因失去邻接伙伴而降低）。重算在拆除瞬间完成，不等待下一个结算节点。
- **If 玩家拆除一座 Lv.5 设施后在新位置重建**: 新建设施从 Lv.1 开始，已投入的升级成本不返还，新位置可能形成不同的邻接关系。系统不追踪"设施迁移历史"。
- **If 每日维护费扣除时经费余额不足**: 维护费按 `resource_settlement` 规则结算，经费 `clamp` 到 0（不可为负）。若触发经费归零，经济系统进入 Warning State，所有消耗经费的行动被锁定。系统不因维护费欠缴而自动降低设施等级或拆除设施。
- **If 存档时某设施正处于 Constructing 或 Upgrading 状态**: 存档完整保存当前状态、目标等级和剩余工期。读档后时间系统恢复剩余工期计数，到期正常触发完工。不会因读档而重置工期或丢失进度。
- **If 青训营的 `youth_age_threshold` 边界与球员生日重叠**: 球员年龄以赛季结算或招募时的"足球年龄"为准。若球员在赛季中途年满 23 岁，该赛季内仍享受年轻球员加成，下赛季开始时重新判定。
- **If 球场 Lv.0（未建造）时触发主场比赛**: `home_advantage_bonus = 0`，`stadium_revenue_multiplier = 1.0`。主场比赛仍然正常进行（默认中立主场），玩家不会因未建造球场而失去主场比赛资格。
- **If 训练场提供的 `training_efficiency_multiplier` 叠加医疗室邻接和青训营邻接后的总效率超过 2.0**: 这是预期内的后期数值（Lv.5 训练场 1.25 × 青训营邻接 1.15 × 青训营自身 youth 1.20 = 1.725，仍在安全范围）。若未来内容扩展导致超 3.0，应由数值系统评估是否需要新增全局培养倍率上限。MVP 阶段不做硬钳制。

## Dependencies

### Upstream Dependencies

| System | Type | What this system needs | Key interface |
|---|---|---|---|
| `design/gdd/balance-system.md` | Hard | 设施系数边界（`flat_modifier_sum_budget`、`percent_modifier_sum_budget`）、升级倍率安全范围、共享属性与资源定义 | 加成值变更后验证是否在数值系统定义的边界内 |
| `design/gdd/economy-management-system.md` | Hard | 资源充足性检查、经费扣除、每日维护费结算、`facility_ap_bonus` 上限约束 | 建造/升级时 Budget Preview + 确认扣除；每日结算时维护费扣缴 |
| `design/gdd/time-and-season-progression-system.md` | Hard | 建设占用时段登记、完工节点触发、稳定节点保存时机 | 建造/升级发起时登记工期；工期到达时触发完工信号 |
| `design/gdd/save-and-load-system.md` | Hard | 设施列表、等级、布局、建造/升级剩余工期、已确认完工结果的持久化与恢复 | 稳定节点全量保存；读档时全量恢复 |
| `design/gdd/game-concept.md` | Hard | "像素小镇养成"支柱定义、MVP 范围约束、建设在核心循环中的定位 | 建设系统的体验目标和范围边界 |
| `design/gdd/systems-index.md` | Hard | 系统层级（Core）、优先级（MVP 最小建设切片；Alpha 扩展完整建设 UI 与深度建设）、依赖关系 | 系统定位、MVP 边界和设计顺序 |

### Downstream Dependencies

| System | Type | What this system provides | Key interface |
|---|---|---|---|
| `design/gdd/player-development-system.md` | Hard | 组合后的 `facility_training_multiplier`（= `training_efficiency_multiplier × youth_training_bonus × adj_tr_youth_multiplier`），作为 `training_actual_gain` 第 4 因子接入 | 培养系统每次训练结算时读取 `facility_training_multiplier`；`potential_floor_boost` 与 `adj_youth_potential_boost` 在 Alpha 招募系统接入前不是 MVP 硬消费合同 |
| `design/gdd/match-competition-system.md` | Hard | `home_advantage_bonus` + `adj_stadium_home_bonus`（作为 `facility_rating_bonus` 注入 `team_match_strength`）、`stadium_revenue_multiplier`（接入 `post_match_funds` 第 4 因子） | 赛前评分计算时通过 `team_match_strength` 接收主场加成；设施修正后的有效队伍评分可超过 100，并由胜率 clamp 兜底；赛后经费计算时通过 `post_match_funds` 公式消费收入倍率 |
| `design/gdd/main-loop-ui-framework.md` | Hard | 设施列表（类型、位置、等级、状态）、建造/升级进度、邻接关系图、加成摘要 | MVP 主界面渲染小镇摘要、设施状态与最小建设入口；Alpha 的建设与经营 UI 承接完整网格交互 |
| 声望与成就系统 | Soft (Alpha) | 设施建造/升级里程碑（如"建成第一座 Lv.5 设施"） | Alpha 阶段接入成就条件 |
| 建设与经营 UI | Hard (Alpha) | 网格状态、可建造/可升级/可拆除判断、成本预览 | Alpha 阶段独立建设界面；MVP 内嵌于主循环 UI |
| 随机事件系统 | Soft (Beta) | 设施相关事件入口（如"暴风雨损坏训练场"） | Beta 阶段接入 |
| `design/gdd/economy-management-system.md` | Hard (回传) | `facility_total_maintenance`（叠加 `daily_maintenance_cost`）、`facility_ap_bonus` 汇总值（医疗室 + 邻接） | 每日结算时经济系统读取维护费总和；AP 恢复时读取 `facility_ap_bonus` |
| `design/gdd/time-and-season-progression-system.md` | Hard (回传) | 建造/升级时间消耗请求（`construction_time`） | 建设发起时向时间系统登记工期 |

### Dependency Rules

1. 小镇建设系统提供的是设施建造、升级、布局和加成的权威规则，不是下游系统业务内容的定义；下游系统可以消费设施加成，但不能直接修改设施状态、等级或布局。
2. 任何下游系统若需要新增设施类型、改变邻接规则、或修改加成计算方式，必须先回到本系统修订，而不能在本地 GDD 中静默覆盖。
3. 当声望与成就系统、随机事件系统 GDD 完成后，本节对应的 Soft 条目应升级为 Hard，并在其 GDD 的 Dependencies 中反向声明对本系统的依赖。
4. 如果某个系统只展示设施信息而不改动建设状态，则它对本系统属于软依赖；如果某个系统消费设施加成、发起建造/升级/拆除请求、或持久化建设状态，则属于硬依赖。
5. 本系统对经济系统和时间系统的回传依赖（维护费、AP 加成、建设工期）必须在两者的 Dependencies 中被列为 Hard 下游依赖。

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
| `training_ground_bonus_delta` | 每级训练效率增量 | 0.03–0.07 | 0.05 | 训练收益过高 | 训练场投资回报不足 |
| `adj_tr_med_coeff` | 邻接医疗室→受伤概率降幅/级 | 0.03–0.08 | 0.05 | 邻接完全消除伤病风险 | 邻接加成不可感知 |
| `adj_tr_youth_coeff` | 邻接青训营→年轻球员成长乘区/级 | 0.02–0.05 | 0.03 | 年轻球员成长过快 | 邻接回报不足 |

### 医疗室

| 调参项 | 控制内容 | 安全范围 | 默认值 | 调高风险 | 调低风险 |
|---|---|---|---|---|---|
| `medical_ap_bonus_per_level` | 每级 AP 增量系数 | 0.5–0.9 | 0.7 | AP 过于充裕 | AP 恢复感不足 |
| `injury_recovery_per_level` | 每级伤病恢复减免增量 | 0.5–0.8 | 0.7 | 伤病几乎无影响 | 伤病惩罚过重 |
| `adj_med_tr_coeff` | 邻接训练场→额外 AP/级 | 0.40–0.80 | 0.60 | 轻易触及 AP 上限 3 | 邻接回报不可感知 |

### 青训营

| 调参项 | 控制内容 | 安全范围 | 默认值 | 调高风险 | 调低风险 |
|---|---|---|---|---|---|
| `youth_potential_floor_per_level` | 每级新球员潜力下限提升 | 0.5–1.5 | 1.0 | 招募池整体过强 | 青训营投资回报不足 |
| `youth_growth_per_level` | 每级年轻球员训练乘区 | 0.02–0.06 | 0.04 | 年轻球员成长过快 | 回报不足 |
| `youth_age_threshold` | 年轻球员年龄上限 | 20–24 | 22 | 覆盖球员过多 | 覆盖球员过少 |
| `adj_youth_tr_coeff` | 邻接训练场→额外潜力下限/级 | 0.40–0.80 | 0.60 | 潜力膨胀 | 邻接回报不足 |

### 球场

| 调参项 | 控制内容 | 安全范围 | 默认值 | 调高风险 | 调低风险 |
|---|---|---|---|---|---|
| `home_advantage_per_level` | 每级主场评分加成 | 1.0–2.5 | 2.0 | 主场优势过大 | 主场优势不可感知 |
| `stadium_revenue_per_level` | 每级比赛收入倍率增量 | 0.05–0.12 | 0.08 | 经费通胀 | 球场投资回报不足 |
| `adj_stad_tr_coeff` | 邻接训练场→额外主场评分/级 | 0.50–1.50 | 1.00 | 主场评分突破 flat 上限 | 邻接回报不足 |

### 维护费

| 调参项 | 控制内容 | 安全范围 | 默认值 | 调高风险 | 调低风险 |
|---|---|---|---|---|---|
| `facility_maintenance_base[*]` | 各设施 Lv.1 每日维护费 | 1–5 | 2/2/3/4 | 日常经营压力过大 | 维护费无存在感 |
| `facility_maintenance_delta[*]` | 各设施每级维护费增量 | 1–3 | 1/1/1/2 | 高级设施维护负担过重 | 升级不产生额外成本 |

### 调参顺序建议

1. 先调成本与节奏组——确认建设投入的绝对难度
2. 再调各设施核心加成——确认回报感知
3. 然后调邻接系数——确认布局策略深度
4. 最后调维护费——确认长期经营可持续性

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
- **GIVEN** 一座设施处于 Constructing 或 Upgrading 状态，**WHEN** 玩家尝试拆除该设施，**THEN** 拆除按钮灰化并提示"设施正在施工中，无法拆除"；**WHEN** 通过 API 直接调用 `demolish()`，**THEN** 状态机拒绝操作，返回错误，设施状态不变。
- **GIVEN** 一座设施处于 Active 状态，**WHEN** 玩家确认拆除，**THEN** 加成立即移除，格子恢复 Empty，与被拆设施邻接的所有设施在同一帧内重新计算邻接加成。

### 训练场加成

- **GIVEN** 训练场处于 Lv.N，**WHEN** 查询 `training_efficiency_multiplier`，**THEN** 返回 `1.0 + training_ground_bonus_delta × N`。验证：Lv.0=1.00, Lv.3=1.15, Lv.5=1.25（默认 delta=0.05）。

### 医疗室加成

- **GIVEN** 医疗室处于 Lv.N（N>0），**WHEN** 查询 `medical_ap_bonus`（不含邻接），**THEN** 返回 `clamp(floor(N × 0.7), 1, 3)`。验证：Lv.1=1, Lv.2=1, Lv.3=2, Lv.4=2, Lv.5=3。
- **GIVEN** 医疗室处于 Lv.N 且邻接额外 AP = A，**WHEN** 查询 `facility_ap_bonus`，**THEN** 返回 `clamp(medical_ap_bonus(N) + A, 0, 3)`。验证：Lv.4 + 邻接 A=2 → clamp(2+2, 0, 3) = 3；Lv.5 + 邻接 A=2 → clamp(3+2, 0, 3) = 3（触及上限）。
- **GIVEN** 医疗室处于 Lv.N，**WHEN** 查询 `injury_recovery_reduction`，**THEN** 返回 `clamp(floor(N × 0.7), (N>0?1:0), 2)`。验证：Lv.0=0, Lv.1=1, Lv.2=1, Lv.3=2, Lv.4=2, Lv.5=2。

### 球场加成

- **GIVEN** 球场处于 Lv.N，**WHEN** 查询 `home_advantage_bonus`，**THEN** 返回 `home_advantage_per_level × N`。验证：Lv.0=0, Lv.3=6.0, Lv.5=10.0（默认 2.0/级）。
- **GIVEN** 球场处于 Lv.N，**WHEN** 查询 `stadium_revenue_multiplier`，**THEN** 返回 `1.0 + stadium_revenue_per_level × N`。验证：Lv.0=1.00, Lv.3=1.24, Lv.5=1.40（默认 0.08/级）。

### 青训营加成

- **GIVEN** 青训营处于 Lv.N，**WHEN** 查询 `potential_floor_boost`，**THEN** 返回 `clamp(floor(youth_potential_floor_per_level × N), 0, 5)`。验证：Lv.0=0, Lv.3=3, Lv.5=5（默认 1.0/级）。
- **GIVEN** 青训营处于 Lv.N 且球员年龄 = A，**WHEN** 查询 `youth_training_bonus`，**THEN**：若 A ≤ `youth_age_threshold`，返回 `clamp(1.0 + youth_growth_per_level × N, 1.00, 1.20)`；若 A > `youth_age_threshold`，返回 1.0。验证：Lv.3 + 年龄 20 → 1.12；Lv.5 + 年龄 23（超过默认 22）→ 1.0；Lv.0 始终返回 1.0。

### 邻接加成

- **GIVEN** 训练场 Lv.T 与医疗室 Lv.M 邻接，**WHEN** 查询邻接加成，**THEN**：
  - `training_injury_prob_multiplier = max(0.40, 1.0 - 0.05 × min(T, M))`。验证：T=3, M=2 → max(0.40, 1.0 - 0.10) = 0.90；T=5, M=5 → max(0.40, 0.75) = 0.75；T=0 或 M=0 → max(0.40, 1.0) = 1.00。
  - `adj_med_ap_bonus = clamp(floor(0.60 × min(T, M)), (min(T,M)≥1?1:0), 2)`。验证：min=2 → clamp(1, 1, 2) = 1；min=3 → clamp(1, 1, 2) = 2（min=2→3 首次出现增量）；min=5 → clamp(3, 1, 2) = 2（触及上限）。

- **GIVEN** 训练场 Lv.T 与青训营 Lv.Y 邻接，**WHEN** 查询邻接加成，**THEN**：
  - `adj_tr_youth_multiplier = 1.0 + 0.03 × min(T, Y)`。验证：T=5, Y=3 → 1.0 + 0.09 = 1.09；T=0 或 Y=0 → 1.00。
  - `adj_youth_potential_boost = clamp(floor(0.60 × min(T, Y)), (min(T,Y)≥1?1:0), 2)`。验证：min=2 → clamp(1, 1, 2) = 1；min=3 → clamp(1, 1, 2) = 2；min=5 → clamp(3, 1, 2) = 2（触及上限）。

- **GIVEN** 球场 Lv.S 与训练场 Lv.T 邻接，**WHEN** 查询邻接加成，**THEN** `adj_stadium_home_bonus = clamp(1.0 × min(S, T), 0, 5)`。验证：S=3, T=5 → clamp(3.0, 0, 5) = 3.0；S=5, T=5 → clamp(5.0, 0, 5) = 5.0；S=5, T=5 时主场总加成 = 10.0 + 5.0 = 15.0。

### 维护费

- **GIVEN** 所有已建成的设施及其等级，**WHEN** 查询 `facility_total_maintenance`，**THEN** 返回 `SUM 对所有已建造设施: (facility_maintenance_base[fac] + facility_maintenance_delta[fac] × (level − 1))`。验证：无设施 → 0；训练场 Lv.3 + 医疗室 Lv.2 → (2+1×2) + (2+1×1) = 4+3 = 7。

### 拆除与邻接更新

- **GIVEN** 设施布局包含多种邻接关系，**WHEN** QA 拆除其中一座设施，**THEN** 被拆设施加成立即移除；与被拆设施邻接的所有设施在同一帧内重新计算邻接加成；重算后的加成值不含已不存在的邻接关系。

### 存档读档

- **GIVEN** 存档时某设施正在建造/升级中（状态=Constructing 或 Upgrading，剩余工期 = D），**WHEN** 读档恢复，**THEN** 设施状态、目标等级和剩余工期 D 完整恢复；工期继续从读档点倒计时（不会重置为初始工期）；完工触发时机与存档前一致。

### 集成验证

- **[Integration AC 1 — 成本]** **GIVEN** MVP 完整实现，**WHEN** QA 从新档开始依次建造每类设施 Lv.1，**THEN** 每次建造扣款 = `ceil(base_funds_cost[fac] × cost_multiplier^0)`，工期 = `ceil(base_construction_time[fac] × time_multiplier^0)`。
- **[Integration AC 2 — 加成递增]** **GIVEN** 一座设施从 Lv.1 逐级升至 Lv.5，**WHEN** 每级完工后查询该设施的加成输出，**THEN** 每级加成值 ≥ 上一级加成值；至少 3 个等级的输出严格大于前一级（确保升级有可感知回报）。
- **[Integration AC 3 — 邻接判定]** **GIVEN** 训练场与医疗室在 5×5 网格上相邻（共享边）、训练场与青训营对角相邻（仅共享角），**WHEN** 查询两对邻接加成，**THEN** 训练场↔医疗室返回非零加成值；训练场↔青训营（对角）加成值为 0（对角不算邻接）。
- **[Integration AC 4 — 拆除级联]** **GIVEN** 训练场同时与医疗室和青训营邻接，**WHEN** 拆除训练场，**THEN** 医疗室和青训营的邻接加成在同一帧内归零；拆除后 `facility_ap_bonus` 仅含医疗室自身加成。
- **[Integration AC 5 — 存档恢复]** **GIVEN** 设施建造中（剩余工期 3 天），**WHEN** 存档 → 推进 1 天 → 读档，**THEN** 剩余工期恢复为 3 天（而非 2 天）；继续推进 3 天后正确触发完工。

## Open Questions

[To be designed]
