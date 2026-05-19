# 足球小镇：数值系统

> **Status**: Designed
> **Author**: 用户 + Claude
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 轻度足球经营、像素小镇养成、低压力长期成长
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `E:\code\game\game-design\02-足球小镇-数值平衡方案.md`

## Overview

数值系统是《足球小镇》的底层平衡规则层，负责统一定义属性、资源、成长、奖励、难度和经济压力的基础量纲、公式边界与调参接口。它不直接规定每一个训练项目、比赛类型或设施等级的完整内容表，而是为运动员培养、比赛竞技、经济管理、小镇建设、声望解锁等系统提供可引用、可测试、可调优的共同数值语言。玩家不会直接“操作”数值系统，但会通过球员稳定成长、比赛结果可信、资源取舍清晰、长期目标可预期等体验感受到它的存在；本系统的核心目标是支撑“轻度足球经营 + 低压力长期成长”的节奏，让玩家既能持续变强，又必须在有限资源下做出有意义的培养与经营选择。

## Player Fantasy

数值系统服务的玩家幻想是：“我经营的小镇和球队正在因为我的选择稳定变强。”玩家不需要直接理解每一个公式，也不应该被复杂表格压住节奏；他们应当通过训练后的属性提升、比赛前后的实力变化、资源投入带来的明确收益，以及长期目标逐步接近的过程，持续感到自己的经营判断正在产生效果。

这种幻想的重点不是高压竞技中的精确算计，而是低压力经营中的可靠成长感。玩家应该相信：普通球员经过培养可以变得可靠，弱势阶段通过训练和资源分配可以逐步追赶，关键投入会在后续比赛和小镇发展中得到反馈。数值系统必须让“稳定变强”可见、可预测、可验证，同时保留足够的取舍空间，让玩家在有限资源下做出选择时感到自己是在规划未来，而不是被随机结果牵着走。

## Detailed Rules

### Core Rules

1. 数值系统是跨系统共享规则的权威来源，负责定义所有后续系统必须引用的基础量纲、范围、公式接口和调参边界。
2. 数值系统只拥有“共享底座”，不拥有每个下游系统的完整内容表：
   - 训练项目列表、训练消耗和训练解锁由运动员培养系统拥有；
   - 比赛类型、赛程结构和赛后事件由比赛竞技系统与联赛与赛事结构系统拥有；
   - 建筑列表、布局规则和升级内容由小镇建设系统拥有；
   - 资源来源、支出项和经营事件由经济管理系统拥有。
3. 所有球员必须使用同一套五维属性：速度 `SPD`、力量 `PWR`、技巧 `TEC`、智力 `INT`、体能 `STA`。

> **守门员属性映射（MVP 设计注）**: 五维属性体系主要为外场球员设计。若 MVP 包含守门员位置，GK 通过位置权重映射使用现有五维——例如 `TEC` 映射为扑救手控球、`INT` 映射为阅读比赛/站位判断、`SPD` 映射为反应/出击速度。此映射方案由运动员培养系统在位置权重表中定义。若 playtest 显示 GK 表现与预期偏差显著（外场球员五维无法通过权重映射产生有区分度的 GK 行为），则 post-MVP 考虑新增 `REF`（反应/Reflexes）第六属性。此扩展需先回到本 GDD 修订属性体系，不可在下游系统中静默添加。
4. 每个属性必须区分三个值：
   - 当前值：球员当前真实成长水平；
   - 潜力上限：常规培养可达到的上限；
   - 有效值：当前值经过状态、心情、稀有度、设施或比赛修正后的临时结果。
5. 常规属性当前值范围为 1–100。当前值不得低于 1，不得高于潜力上限；潜力上限不得高于 100，除非后续“突破”类系统另行定义并在本系统中登记。
6. 有效值可以因临时修正高于当前值或低于当前值，但不得永久改变当前值。任何有效值修正必须说明来源、持续时间和是否可叠加。
7. 所有球员必须拥有稀有度。稀有度只定义初始属性范围、潜力区间、技能槽位和成长效率倍率的边界；具体招募渠道、球探成本和候选池刷新由运动员培养系统拥有。
8. 游戏必须使用三大核心资源：经费、研究点数、运动点数。
9. 经费用于招募、建设、薪资、维护和经营支出；研究点数用于解锁、技能、战术和设施升级；运动点数用于训练、比赛、探索和高价值行动。
10. 数值节奏必须遵循“时间民主化”原则：常规操作的基础执行时间保持短而统一，主要通过资源消耗、日程限制、解锁条件和机会成本控制节奏，而不是通过长时间等待制造压力。
11. 所有成长与收益必须满足“可感知进步”原则：一次成功训练、比赛或建设投入至少应在属性、资源、解锁进度、评分预期或长期目标之一上产生可见反馈。
12. 所有成长公式必须具备递减机制，使低属性球员更容易追赶，高属性球员需要更多投入才能接近上限。
13. 所有随机波动必须服务轻度不确定性，不得覆盖玩家长期投入的主导作用。随机结果可以制造惊喜，但不能让同等投入长期表现为不可解释的失败。
14. 所有跨系统数值输出必须保留可测试边界：最小值、最大值、正常区间、异常输入处理方式和示例计算必须在 Formulas 或下游系统文档中明确。
15. 玩家不直接操作数值系统，但玩家的训练、比赛、招募、建设和资源分配决策必须通过数值系统形成可理解的收益差异。

### States and Transitions

数值系统本身没有玩家可见的运行时状态，但每一组跨系统数值必须处于一个明确的数据生命周期状态，避免未经验证的数值被误认为已锁定。

| State | Description | Enter condition | Exit condition | Valid next states |
|---|---|---|---|---|
| Draft | 初始设计值，仅用于讨论和原型验证 | 新公式、新范围或新表格被提出 | 设计者确认可以进入小规模测试 | Tuned / Deprecated |
| Tuned | 已经过内部推演或小规模测试，适合进入系统 GDD 或原型 | Draft 数值完成至少一次示例计算或测试推演 | 核心循环验证通过，或发现问题需要修改 | Locked / Revised |
| Locked | 当前版本的权威数值，其他系统可以引用 | 数值通过设计审查，并被写入对应 GDD 或注册表 | 新测试数据、系统变更或体验目标改变 | Revised |
| Revised | 已锁定数值被重新调整，必须记录原因与影响范围 | Locked 数值需要变更 | 新版本通过测试并重新确认 | Tuned / Locked |
| Deprecated | 数值、公式或范围不再使用，只保留历史记录 | Draft、Tuned、Locked 或 Revised 数值被替代 | 不再恢复使用 | - |

### Interactions with Other Systems

| System | 数值系统提供 | 该系统提供回数值系统 | Ownership boundary |
|---|---|---|---|
| 运动员培养系统 | 属性范围、潜力规则、成长递减规则、训练效率接口、稀有度成长倍率边界 | 训练项目、训练消耗、球员成长事件、技能学习需求 | 数值系统定义公式和范围；培养系统定义具体训练内容 |
| 比赛竞技系统 | 综合评分接口、有效属性修正接口、胜率边界、随机波动安全范围、奖励倍率边界 | 阵型、战术、对手、比赛结果、赛后表现数据 | 数值系统定义可计算接口；比赛系统定义比赛流程和事件含义 |
| 经济管理系统 | 三大资源定义、资源上限规则、净收入框架、收入/支出平衡目标 | 收入来源、支出项目、周期结算、经营事件 | 数值系统定义资源语言和目标区间；经济系统定义具体账目 |
| 小镇建设系统 | 设施系数边界、升级倍率边界、邻接加成上限、建设成本调参接口 | 建筑列表、设施等级、布局关系、实际邻接组合 | 数值系统定义加成如何约束；建设系统定义哪些设施产生加成 |
| 声望与成就系统 | 声望经验曲线接口、解锁节奏目标、奖励区间 | 声望等级、成就条件、解锁内容 | 数值系统定义成长速度和奖励边界；声望系统定义目标内容 |
| 联赛与赛事结构系统 | 对手难度区间、赛事奖励倍率边界、阶段节奏目标 | 赛季结构、赛事层级、晋级条件 | 数值系统定义难度/奖励范围；赛事系统定义何时使用这些范围 |
| 主循环 UI 框架 | 需要展示的核心数值类别、范围和变化方向 | 实际展示层级、提醒方式、可视化优先级 | 数值系统定义信息含义；UI 系统定义呈现方式 |
| 存档与读档系统 | 需要持久化的数值类别和版本状态 | 保存、读取、迁移和校验结果 | 数值系统定义哪些值具有长期意义；存档系统定义持久化实现 |

如果下游系统需要改变已锁定的共享范围、公式或资源定义，必须回到数值系统修改并记录为 Revised，而不是在下游文档中单独覆盖。

## Formulas

### 1. 有效属性值

`effective_attribute_value` 的公式定义如下：

`effective_attribute_value = clamp((current_attribute + flat_modifier_sum) × (1 + percent_modifier_sum), 1, 100)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 当前属性值 | `current_attribute` | int | 1–100 | 球员在该属性上的永久成长值 |
| 平面修正合计 | `flat_modifier_sum` | float | -99–99 | 所有直接加减该属性点数的临时修正总和 |
| 百分比修正合计 | `percent_modifier_sum` | float | -1.0–1.0 | 所有百分比属性修正的加总结果 |
| 有效属性值 | `effective_attribute_value` | float | 1–100 | 用于训练、比赛或 UI 预估的临时结算属性 |

**Output Range:** 1–100；低于 1 时钳制为 1，高于 100 时钳制为 100。未来如果加入突破上限系统，必须先修改本公式或新增 over-cap 规则。
**Example:** 若 `current_attribute = 72`、`flat_modifier_sum = 8`、`percent_modifier_sum = 0.10`，则 `effective_attribute_value = clamp((72 + 8) × 1.10, 1, 100) = 88`。

### 2. 属性成长结算

`attribute_growth` 的公式定义如下：

`attribute_growth = raw_growth_input × max(0, 1 - current_attribute / potential_cap) ^ decay_factor`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 未衰减成长值 | `raw_growth_input` | float | ≥ 0 | 下游系统计算出的基础成长值，例如训练、比赛经验或特殊奖励带来的成长 |
| 当前属性值 | `current_attribute` | int | 1–100 | 球员在该属性上的永久成长值 |
| 潜力上限 | `potential_cap` | int | 1–100，且 ≥ `current_attribute` | 常规培养可达到的属性上限 |
| 衰减因子 | `decay_factor` | float | 0.8–1.8 | 控制成长递减强度，默认 1.2。越高表示越接近上限时衰减越明显。0.8 以下减速过弱（中期几无递减感），1.8 以上撞墙过快（70% 上限时即衰减 90%+） |
| 实际成长值 | `attribute_growth` | float | 0–`raw_growth_input` | 经过递减后的最终成长量 |

**Output Range:** 0–`raw_growth_input`；当当前属性等于潜力上限时，输出为 0。
**Example:** 若 `raw_growth_input = 3.0`、`current_attribute = 40`、`potential_cap = 80`、`decay_factor = 1.5`，则 `attribute_growth = 3.0 × (1 - 40 / 80) ^ 1.5 ≈ 1.06`。

### 3. 资源结算

`resource_settlement` 的公式定义如下：

`resource_settlement = clamp(current_resource + gained_resource - spent_resource, resource_min, resource_max)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 当前资源量 | `current_resource` | float | ≥ 0 | 结算前拥有的资源量 |
| 获得资源量 | `gained_resource` | float | ≥ 0 | 本结算窗口内获得的资源总量 |
| 消耗资源量 | `spent_resource` | float | ≥ 0 | 本结算窗口内消耗的资源总量 |
| 资源下限 | `resource_min` | float | ≥ 0 | 通常为 0 |
| 资源上限 | `resource_max` | float / ∞ | ≥ `resource_min` | 有上限资源使用固定值；经费可使用 ∞ |
| 结算后资源量 | `resource_settlement` | float | `resource_min`–`resource_max` | 结算后的资源量 |

**Output Range:** `resource_min`–`resource_max`；经费无硬上限时，`resource_max = ∞`。
**Example:** 若运动点数 `current_resource = 80`、`gained_resource = 30`、`spent_resource = 20`、`resource_min = 0`、`resource_max = 100`，则 `resource_settlement = clamp(80 + 30 - 20, 0, 100) = 90`。

### 4. 位置综合评分

`positional_overall_rating` 的公式定义如下：

`positional_overall_rating = Σ(effective_attribute_i × position_weight_i), where i ∈ {SPD, PWR, TEC, INT, STA} and Σ(position_weight_i) = 1`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 单项有效属性 | `effective_attribute_i` | float | 1–100 | 某一项五维属性的有效值 |
| 位置权重 | `position_weight_i` | float | 0–1 | 该位置对该属性的依赖权重 |
| 属性集合 | `i` | enum | SPD / PWR / TEC / INT / STA | 五维属性枚举 |
| 位置综合评分 | `positional_overall_rating` | float | 1–100 | 球员在指定位置上的综合评分 |

**Output Range:** 1–100；所有权重必须非负且总和必须等于 1。
**Example:** 若前锋权重为 `SPD 0.20`、`PWR 0.25`、`TEC 0.25`、`INT 0.15`、`STA 0.15`，球员有效属性为 `SPD 75`、`PWR 70`、`TEC 80`、`INT 65`、`STA 72`，则 `positional_overall_rating = 75×0.20 + 70×0.25 + 80×0.25 + 65×0.15 + 72×0.15 = 73.05`。

### 5. 基准胜率锚点

`base_win_probability` 的公式定义如下：

`base_win_probability = clamp(0.50 + (self_team_rating - opponent_team_rating) × rating_win_slope, 0.05, 0.95)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 我方队伍评分 | `self_team_rating` | float | 1–130 | 比赛系统传入的我方队伍有效评分；基础阵容评分来自 1–100 属性体系，但设施修正后可超过 100 |
| 对手队伍评分 | `opponent_team_rating` | float | 1–130 | 比赛系统传入的对手队伍有效评分；基础阵容评分来自 1–100 属性体系，但设施修正后可超过 100 |
| 评分胜率斜率 | `rating_win_slope` | float | 0.003–0.006 | 每 1 点评分差转换为胜率变化的幅度，默认 0.0045（每 10 分差 ≈ +4.5% 胜率） |
| 基准胜率 | `base_win_probability` | float | 0.05–0.95 | 不含主场、战术、阵型、士气等修正的基准胜率 |

**Output Range:** 0.05–0.95；保留最低爆冷概率和最高失手概率，避免必胜或必败。
**Example:** 若 `self_team_rating = 75`、`opponent_team_rating = 60`、`rating_win_slope = 0.0045`，则 `base_win_probability = clamp(0.50 + (75 - 60) × 0.0045, 0.05, 0.95) = clamp(0.5675, 0.05, 0.95) = 0.5675`。

> **设计注**: 15 点评分差仅产生约 7% 的胜率偏移——这确保"小差距不过度锁定结果"。基础球员属性与位置综合评分仍以 1–100 为常规边界；比赛系统传入的 `self_team_rating` / `opponent_team_rating` 是赛前有效队伍评分，允许小镇设施等赛前修正使其超过 100。最终 `base_win_probability` 仍由 0.05/0.95 clamp 兜底，避免必胜或必败。

### 6. 运动点数使用率

`action_point_use_rate` 的公式定义如下：

`action_point_use_rate = action_points_spent / max(1, action_points_available)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 已消耗运动点数 | `action_points_spent` | float | ≥ 0 | 统计窗口内玩家实际消耗的运动点数 |
| 可用运动点数 | `action_points_available` | float | ≥ 0 | 统计窗口内初始运动点数、自然恢复、奖励补充等可用总量 |
| 运动点数使用率 | `action_point_use_rate` | float | 0–1+ | 衡量运动点数是否形成有效节奏压力 |

**Output Range:** 正常目标区间为 0.70–0.90；若超过 1，表示统计口径或外部补充来源需要复查。
**Example:** 若 30 分钟测试窗口内 `action_points_spent = 160`、`action_points_available = 200`，则 `action_point_use_rate = 160 / 200 = 0.80`。

### 7. 总体胜率

`overall_win_rate` 的公式定义如下：

`overall_win_rate = matches_won / max(1, matches_played)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 获胜场次 | `matches_won` | int | 0–`matches_played` | 统计窗口内玩家获胜的比赛数量 |
| 总比赛场次 | `matches_played` | int | ≥ 0 | 统计窗口内玩家完成的比赛数量 |
| 总体胜率 | `overall_win_rate` | float | 0–1 | 衡量玩家长期比赛体验是否符合轻度成长目标 |

**Output Range:** 正常目标区间为 0.55–0.65；低于区间说明挫败压力偏高，高于区间说明比赛可能缺乏挑战。
**Example:** 若 `matches_won = 26`、`matches_played = 44`，则 `overall_win_rate = 26 / 44 ≈ 0.591`。

### 8. 均势对局胜率

`even_match_win_rate` 的公式定义如下：

`even_match_win_rate = even_matches_won / max(1, even_matches_played)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 均势对局获胜场次 | `even_matches_won` | int | 0–`even_matches_played` | 基准胜率在 0.45–0.55 之间的比赛中，玩家获胜的数量 |
| 均势对局总场次 | `even_matches_played` | int | ≥ 0 | 基准胜率在 0.45–0.55 之间的比赛总数 |
| 均势对局胜率 | `even_match_win_rate` | float | 0–1 | 衡量接近五五开的比赛是否真的接近均衡 |

**Output Range:** 正常目标区间为 0.45–0.55；低于区间说明隐藏惩罚过重，高于区间说明玩家优势被放大。
**Example:** 若 `even_matches_won = 11`、`even_matches_played = 22`，则 `even_match_win_rate = 11 / 22 = 0.50`。

### 9. 里程碑达成时间

`milestone_completion_time` 的公式定义如下：

`milestone_completion_time = milestone_timestamp - save_start_timestamp`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| 存档开始时间 | `save_start_timestamp` | float | ≥ 0 | 新存档开始时的游戏内或测试计时时间戳，单位为分钟 |
| 里程碑达成时间 | `milestone_timestamp` | float | ≥ `save_start_timestamp` | 指定里程碑首次达成的时间戳，单位为分钟 |
| 里程碑耗时 | `milestone_completion_time` | float | ≥ 0 | 玩家从开档到达成该里程碑所需时间 |

**Output Range:** ≥ 0；不同里程碑使用不同目标区间。MVP 校准目标包括：首次比赛胜利 `< 30` 分钟，声望 Lv.3 为 `120–180` 分钟，声望 Lv.10 为 `1800–2400` 分钟。
**Example:** 若新档从 `0` 分钟开始，首次胜利发生在第 `24` 分钟，则 `milestone_completion_time = 24 - 0 = 24` 分钟，满足首次胜利 `< 30` 分钟目标。

### Formula Ownership Notes

- `training_actual_gain` 不在本系统中定义；运动员培养系统可以基于 `attribute_growth` 公式定义训练专用收益。
- `team_rating` 不在本系统中定义；比赛竞技系统负责决定首发、替补、阵型、战术、疲劳等因素如何聚合成队伍评分。
- `net_income` 的分项不在本系统中定义；经济管理系统负责收入来源、固定支出、可变支出和结算周期。
- 招募概率、设施成本、建筑邻接组合、赛事奖励表不在本系统中定义；这些表格由对应下游系统拥有。
- 如果后续系统需要改变本节中的公式名、变量范围、目标区间或输出边界，必须回到数值系统修订，而不是在下游 GDD 中静默覆盖。

## Edge Cases

- **If `current_attribute < 1` or `current_attribute > 100`**: 在进入任何共享公式前先钳制到 `1–100`；钳制后的值作为规范化当前值，并将原始数据标记为无效输入。
- **If `potential_cap < current_attribute` and `current_attribute ≤ 100`**: 将 `potential_cap` 规范化提升到 `current_attribute`，优先保留玩家已经获得的永久成长值，并标记该球员数值需要复核。
- **If `potential_cap > 100`**: 将 `potential_cap` 钳制为 `100`；如果 `current_attribute` 也高于 `100`，则两者同时钳制为 `100`。
- **If 多个 flat modifier 和多个 percent modifier 同时作用于同一属性**: 先合并所有平面修正，再合并所有百分比修正，只执行一次 `effective_attribute_value` 结算；不允许按来源分别结算后重复放大。
- **If `effective_attribute_value` 的结算结果低于 1 或高于 100**: 只钳制临时有效值；不得把该临时结果回写成永久 `current_attribute`。
- **If `base_win_probability` 的 `self_team_rating` 或 `opponent_team_rating` 超过 100**: 该输入若来自比赛系统的赛前有效队伍评分（如设施主场加成、化学修正）则为合法输入，不按属性上限钳制；胜率公式直接消费该差值，并由 0.05–0.95 输出 clamp 兜底。
- **If `raw_growth_input < 0`**: `attribute_growth` 的输出强制为 `0`；共享成长公式不承担负成长，任何永久降属性规则必须由下游系统单独定义。
- **If `potential_cap < 1` or `potential_cap = 0`**: 在计算成长前将 `potential_cap` 规范化为 `max(1, current_attribute)`；如果发生这种修正，该条数据不能直接视为 Locked。
- **If `current_resource + gained_resource - spent_resource < resource_min`**: `resource_settlement` 返回 `resource_min`；资源不得变成负数，超额消耗必须被下游行动系统阻止或截断。
- **If `resource_max` 为有限值且结算结果超过上限**: `resource_settlement` 返回 `resource_max`；超出的部分直接丢弃，除非下游系统显式定义了溢出转化规则。
- **If 某个行动的资源成本高于当前可用资源**: 该行动不得开始；系统必须给出“资源不足”的明确反馈，而不是先执行再回滚。
- **If 任一位置权重小于 0**: 该权重配置视为无效；Draft/Tuned 演算中先把负权重视为 `0` 再归一化其余权重，Locked 配置不得带有负权重发布。
- **If 某位置的全部权重之和等于 0**: `positional_overall_rating` 在原型演算中临时退回五维有效属性的算术平均值；该配置同时标记为无效，不能进入 Locked。
- **If 位置权重之和不等于 1 但大于 0**: Draft/Tuned 阶段按比例归一化后再计算评分；Locked 阶段必须修正到精确和为 `1`。
- **If `action_points_available = 0`、`matches_played = 0` 或 `even_matches_played = 0`**: 对应 KPI 按公式保护返回 `0`，但该样本不能用于通过平衡性审查，也不能据此宣告调优成功。
- **If 下游比赛修正把最终胜率推到 `0.05–0.95` 之外**: 在全部修正完成后再次钳制到 `0.05–0.95`；任何下游系统都不得绕过共享胜率上下限。
- **If 两个下游系统试图为同一个共享公式名、变量范围、属性上限或目标区间定义不同口径**: 下游覆盖无效；必须回到本 GDD 修订共享规则，并把该规则的生命周期状态切换为 `Revised`。
- **If 某条 Locked 数值规则被修改，而其他系统已经在引用它**: 该规则立即失去 Locked 身份并转入 `Revised`；所有依赖它的系统在复核完成前都不得把新值视为最终版本。
- **If 长样本测试持续偏离本 GDD 的目标带**: 先调整 tuning knob 或下游内容表；若问题无法通过调参解决，则本系统对应规则进入 `Revised`，而不是直接放宽共享边界。

## Dependencies

数值系统位于 Foundation 层，作为多个后续系统共享的规则底座。它本身没有必须先完成的上游玩法系统，但它依赖游戏概念、系统索引和后续平衡验证流程来确认边界是否成立。对其他系统而言，数值系统提供的是共享公式、范围、资源定义和目标带，而不是具体内容表。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 定义了三大资源、双核循环、低压力长期成长和 MVP 目标，决定本系统的体验边界 | 核心资源集合、核心循环目标、长期节奏目标 |
| `design/gdd/systems-index.md` | Hard | 定义了本系统在 Foundation/MVP 的位置，以及它被哪些系统依赖 | 系统层级、优先级、依赖方向 |
| 平衡验证 / 内部测试结果 | Soft | 用于判断目标带是否成立，决定某条规则是否从 Tuned 进入 Locked | KPI 样本、里程碑耗时、胜率与资源使用率统计 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 数值系统 | What must be back-referenced later |
|---|---|---|---|
| 运动员培养系统 | Hard | 五维属性定义、潜力规则、成长递减公式、稀有度边界 | 必须声明属性成长和训练收益引用 `attribute_growth` 等共享规则 |
| 比赛竞技系统 | Hard | 位置综合评分接口、有效属性接口、基准胜率锚点、胜率上下限 | 必须声明比赛评分与胜率修正建立在共享属性和胜率边界之上 |
| 经济管理系统 | Hard | 三大资源定义、资源结算接口、资源目标带 | 必须声明具体收支表是对共享资源规则的实现，而不是替代 |
| 小镇建设系统 | Hard | 设施系数边界、升级倍率边界、资源消耗语言 | 必须声明建设加成和成本表如何接入共享资源与属性系统 |
| 声望与成就系统 | Hard | 里程碑节奏目标、奖励区间、长期成长目标 | 必须声明声望经验曲线和解锁节奏遵守共享进度目标 |
| 联赛与赛事结构系统 | Hard | 难度区间、奖励倍率边界、阶段目标时长 | 必须声明赛事层级如何引用共享难度和奖励边界 |
| 主循环 UI 框架 | Soft | 需要展示的属性、资源、评分、目标带和反馈方向 | 必须声明 UI 展示的是共享数值含义，而不是另行定义口径 |
| 球员管理 UI | Soft | 属性、潜力、稀有度、成长反馈的显示语义 | 必须声明展示字段与本系统定义一致 |
| 比赛表现 UI | Soft | 比赛评分、胜率反馈、奖励结果的显示语义 | 必须声明展示字段与本系统和比赛系统定义一致 |
| 建设与经营 UI | Soft | 经费、研究点数、运动点数和建设收益反馈 | 必须声明展示字段与本系统和经济/建设系统定义一致 |
| 存档与读档系统 | Hard | 需要持久化的共享数值类别、版本状态、Locked/Revised 生命周期 | 必须声明共享数值版本如何保存、读取和迁移 |
| 教程与提示系统 | Soft | 资源意义、成长反馈、边界规则的解释口径 | 必须声明提示文本引用共享规则，而不是独立描述另一套数值逻辑 |

### Dependency Rules

1. 数值系统对下游系统的依赖主要体现在“被引用”，不是“被实现”；下游系统可以扩展内容，但不能改写共享公式、属性上限、资源定义或目标区间。
2. 任何下游系统若需要改变 `effective_attribute_value`、`attribute_growth`、`resource_settlement`、`positional_overall_rating`、`base_win_probability` 或本 GDD 中定义的 KPI 目标带，必须先回到数值系统修改并记录为 `Revised`。
3. 下游系统可以拥有自己的内容表、倍率表、事件表和奖励表，但这些表必须明确标注它们引用了本系统的哪一个共享变量、公式或边界。
4. 当后续 GDD 完成时，依赖关系必须双向成立：本节列为下游依赖的系统，需要在它们各自的 Dependencies 或 Interactions 章节中反向声明“依赖数值系统”。
5. 如果某个 Presentation 或 Polish 系统只展示共享数值而不改变数值结果，则它对数值系统属于软依赖；如果某个系统要生成、消耗、结算或持久化共享数值，则属于硬依赖。
6. 在 MVP 阶段，运动员培养系统、比赛竞技系统和经济管理系统是最关键的下游承接者；它们的任何边界变更都应优先检查是否会破坏本 GDD 的共享公式和目标带。

## Tuning Knobs

本节仅包含数值系统拥有的共享调参项与校准目标，不包含训练项目收益、球员模板、赛事奖励表、设施成本表、招募概率表等下游系统内容。

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 平面修正总预算 `flat_modifier_sum_budget` | 单名球员在常规流程内可同时生效的平面属性修正总量 | `-10` 至 `+15` | 原始属性被修正值淹没，叠加后容易出现断层增长 | 系统联动存在感过弱，属性加成不明显 | 构筑感、属性可读性 |
| 百分比修正总预算 `percent_modifier_sum_budget` | 单名球员在常规流程内可同时生效的百分比属性修正总量 | `-20%` 至 `+30%` | 乘区放大过快，频繁撞到属性上限 | 高阶成长不够兴奋，后期反馈偏弱 | 成长爽感、爆发感 |
| 成长衰减系数 `decay_factor` | 属性接近潜力上限时的成长减速强度 | `0.8` 至 `1.8` | 中后期成长撞墙，培养挫败感强 | 成长过直线，容易批量堆满上限 | 培养节奏、长期目标感 |
| 潜力上限跨度 `potential_cap_span` | 常规球员池内潜力上限的全局离散度 | `10` 至 `20` 点 | 上限差距过大，招募结果过度决定长期强度 | 球员同质化，培养惊喜不足 | 招募期待、阵容差异化 |
| 资源容量缓冲倍数 `resource_buffer_multiplier` | 资源上限相对单周期净收支的容纳空间 | `2` 至 `4` 倍 | 玩家容易长期囤积资源，资源压力不足 | 经常溢出或被迫消费，挫败感上升 | 资源张力、节奏自由度 |
| 胜率斜率 `rating_win_slope` | 评分差转化为基准胜率的敏感度 | per-point `0.003`–`0.006`（每 10 分差 +3%–6% 胜率），默认 `0.0045` | 小差距就过度锁定结果，比赛悬念不足 | 阵容强弱反馈不明显，投入回报模糊 | 比赛确定性、养成回报 |
| 胜率下限 `win_probability_floor` | 弱势方的最低基础胜率 | `0.05` 至 `0.10` | 爆冷过于频繁，实力差被稀释 | 弱队几乎“没得打”，恢复空间不足 | 希望感、公平感 |
| 胜率上限 `win_probability_ceiling` | 强势方的最高基础胜率 | `0.90` 至 `0.95` | 强队过稳，比赛脚本感强 | 强队优势不值钱，随机性偏高 | 支配感、悬念平衡 |
| 运动点数使用率目标 `action_point_use_rate_target` | 校准行动点供给与消耗是否形成有效选择压力 | `0.70` 至 `0.90` | 玩家常年见底，被迫保守或固化最优解 | 行动点形同虚设，规划价值低 | 回合压力、决策密度 |
| 总体胜率目标 `overall_win_rate_target` | 校准主线推进的整体顺畅度 | `0.55` 至 `0.65` | 推进过顺，挑战感不足 | 挫败累积，成长反馈偏弱 | 成就感、留存 |
| 均势对局胜率目标 `even_match_win_rate_target` | 校准实力接近时的公平性 | `0.45` 至 `0.55` | 隐性修正偏袒一方，公平感下降 | 另一侧长期吃亏，结果失真 | 公平感、可预期性 |
| 里程碑时长偏差容忍度 `milestone_completion_time_tolerance` | 校准成长、资源、比赛循环的推进速度 | 相对目标值 `±10%` | 节奏拖沓，刷感上升 | 内容消耗过快，阶段感变弱 | 节奏感、阶段推进满足 |

### 调参顺序建议

1. 先调 `rating_win_slope`、`win_probability_floor`、`win_probability_ceiling`，修正比赛结果的确定性。
2. 再调 `resource_buffer_multiplier` 和 `action_point_use_rate_target`，修正主循环的资源压力。
3. 然后调 `decay_factor` 与 `potential_cap_span`，修正长期培养节奏。
4. 最后调 `flat_modifier_sum_budget` 与 `percent_modifier_sum_budget`，修正系统联动的表现强度。

如果需要改动属性上限 `1–100`、共享资源种类、共享公式结构或基准胜率上下限的存在方式，应视为系统级改版，而不是常规调参。

## Acceptance Criteria

### 跨系统一致性

- **GIVEN** 下游系统代码库，**WHEN** CI 扫描所有数值边界、乘区、上下限的常量引用，**THEN** 每个引用必须指向本 GDD 声明的常量或公式；未声明的额外边界、额外乘区或额外上下限视为构建失败。
- **GIVEN** 同一组输入同时被共享数值系统和任一下游系统用于属性、资源、评分或胜率计算，**WHEN** QA 在两侧分别执行同一计算，**THEN** 输出结果必须一致。

### 属性体系

- **GIVEN** 一个球员或单位进入共享属性结算，**WHEN** QA 检查其属性结构，**THEN** 系统必须只使用 `SPD`、`PWR`、`TEC`、`INT`、`STA` 五项属性，并且每项属性都必须能区分 `current`、`potential`、`effective` 三类值。
- **GIVEN** 任一属性输入小于 `1`、大于 `100`，或 `potential_cap` 非法，**WHEN** 该输入进入共享公式，**THEN** 系统必须先按本 GDD 的 Edge Cases 规则完成钳制或规范化，再继续结算，不得直接把非法值传入后续公式。

### 资源结算

- **GIVEN** 三类资源之一发生结算，**WHEN** QA 检查输入和输出，**THEN** 只有 `funds`、`research`、`action points` 可以参与本系统的共享资源结算，且最终结果必须落在本 GDD 定义的合法边界内。

### 幂等性与操作顺序

- **GIVEN** 两个测试场景的初始状态完全一致（球员属性值 + 三类资源量 + 游戏时间戳三者均相等）、具有相同总时长和相同总资源投入，只是"一次训练结算"等原子操作的执行顺序不同，**WHEN** QA 完成同一时间窗口的全部结算，**THEN** 两个场景的属性成长、资源结果、评分结果与 KPI 结果必须一致，不得因操作先后额外获得收益。

### 成长反馈

- **GIVEN** 某属性未达到潜力上限且满足最小成长条件，**WHEN** QA 执行一次完整成长结算，**THEN** 至少一项被培养属性的 `current` 或 `effective` 值必须发生可量化变化；若没有变化，原因必须完全符合本 GDD 已声明的上限或无效输入规则。
- **GIVEN** 两个测试对象除起始属性值不同外，其余成长输入完全一致，且都未达到各自上限，**WHEN** QA 对两者执行一次相同的成长结算，**THEN** 起始值较低的一方获得的 `attribute_growth` 必须大于起始值较高的一方。
- **GIVEN** `potential_cap < current_attribute ≤ 100`（逆输入边界），**WHEN** 执行成长结算，**THEN** 系统将 `potential_cap` 规范化为 `current_attribute`，保留已获得的永久成长值，并标记该球员数据需复核——该数据不得直接视为 Locked。

### 随机性与统计

- **GIVEN** 一组固定输入的确定性部分已经判定对象 A 强于对象 B，**WHEN** QA 在仅随机项可变的前提下重复执行 1000 次独立试验，**THEN** 每次试验的随机项必须落在本 GDD 定义的区间内；A 胜出的比例不得低于 0.95（允许 ≤5% 的偶然反转）。

### 公式手工验证

- **GIVEN** 一组合法输入用于 `effective_attribute_value`，**WHEN** QA 依据本 GDD 手工计算结果，**THEN** 系统返回值必须与手工结果一致，并在触发上下界时正确钳制到 `1–100`。附加验证：(a) `current=100, flat=+15, percent=+30%` → 系统返回 100（溢出静默钳制），并产生溢出日志；(b) 多个 `flat_modifier` 以任意顺序求和 `flat_modifier_sum`，结果一致（加法交换律）。
- **GIVEN** 一组常规、接近上限和已达上限的输入用于 `attribute_growth`，**WHEN** QA 分别手工计算结果，**THEN** 系统返回值必须与手工结果一致；已达上限时输出必须为 `0`。附加验证：`decay_factor=0.8`（最弱衰减）下，`current/potential=0.80` 时 `attribute_growth > 0` 且 `> decay_factor=1.8` 同条件下的输出；`decay_factor=1.8`（最强衰减）下，低属性（`current/potential=0.20`）的 `attribute_growth` 仍显著大于高属性（0.80）。
- **GIVEN** 一组资源输入用于 `resource_settlement`，**WHEN** QA 依据本 GDD 手工计算结果，**THEN** 系统返回值必须与手工结果一致；越界结果必须按规则钳制到 `resource_min` 或 `resource_max`。
- **GIVEN** 一组五维属性值和某位置的权重集合用于 `positional_overall_rating`，**WHEN** QA 手工计算评分，**THEN** 系统返回值必须与手工结果一致；若权重总和不满足要求，则必须先按本 GDD 规则归一化后再计算。
- **GIVEN** 两支队伍的综合评分输入用于 `base_win_probability`，**WHEN** QA 手工计算基准胜率，**THEN** 系统返回值必须与手工结果一致，且结果必须落在 `0.05–0.95` 之间。

### KPI 与诊断公式

- **GIVEN** 一个统计窗口内存在 action points 的可用量与消耗量，**WHEN** QA 计算 `action_point_use_rate`，**THEN** 系统结果必须与手工值一致；当可用量为 `0` 时，结果返回 `0` 且标记为 invalid_sample，该样本不得作为有效样本通过审查。
- **GIVEN** 一个统计窗口内存在总比赛数和获胜场次，**WHEN** QA 计算 `overall_win_rate`，**THEN** 系统结果必须与手工值一致；当总比赛数为 `0` 时，该样本标记为 invalid_sample。
- **GIVEN** 一个统计窗口内存在符合 even match 定义的比赛集合，**WHEN** QA 计算 `even_match_win_rate`，**THEN** 系统结果必须与手工值一致；只有基准胜率位于 `0.45–0.55` 的比赛可以被纳入该统计。

### 里程碑时长

- **GIVEN** 一个里程碑具有明确的起始时间戳与完成时间戳，**WHEN** QA 计算 `milestone_completion_time`，**THEN** 系统结果必须与手工值一致。
- **[MVP 可验证]** **GIVEN** MVP 完整实现，**WHEN** QA 从新档开始推进至首次比赛胜利，**THEN** `milestone_completion_time < 30` 分钟。
- **[Alpha 回归验证]** **GIVEN** 声望系统完整实现，**WHEN** QA 从新档开始推进，**THEN** 声望 Lv.3 达成时间在 `120–180` 分钟区间内；声望 Lv.10 达成时间在 `1800–2400` 分钟区间内。此两项在声望系统 GDD 完成后回归验证。

### 数值生命周期

- **[CI 元数据]** **GIVEN** 所有数值常量/公式/范围的注册表，**WHEN** CI 扫描元数据标签，**THEN** 每条规则的状态标签为五种合法状态之一（Draft/Tuned/Locked/Revised/Deprecated），且 `Deprecated` 规则未被任何有效结算引用。
- **[设计审查清单]** **GIVEN** 一条 Locked 规则被修改，**WHEN** 执行设计审查，**THEN** 人工确认：(a) 规则状态已从 Locked 迁移至 Revised；(b) 所有硬依赖此规则的下游系统负责人已被通知；(c) 下游系统相关状态已更新为 Draft/Tuned 等待复核。

