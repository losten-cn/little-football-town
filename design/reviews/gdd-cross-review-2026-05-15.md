# Cross-GDD Review Report

> **Date**: 2026-05-15
> **Reviewed**: 12 documents (10 MVP system GDDs + game-concept + systems-index)
> **Verdict**: FAIL

---

## Phase 2: Cross-GDD Consistency — 5 Blocking / 6 Warnings

### 2a — Dependency Bidirectionality

#### Blocking

🔴 **2a.1 — 数值系统与联赛系统 Hard/Soft 类型不匹配**

- **涉及文档**: `balance-system.md`, `league-competition-structure-system.md`
- **具体矛盾**: `balance-system.md` 将联赛与赛事结构系统列为 Hard 下游依赖（"难度区间、奖励倍率边界、阶段目标时长"），但 `league-competition-structure-system.md` Dependencies 章节将数值系统列为 Soft 上游（"不直接消费共享公式"）。
- **分析**: 联赛系统确实引用了数值系统的共享边界——对手难度区间与 `opponent_strength_band` 直接受数值系统约束，奖励倍率边界也需与数值系统的 `overall_win_rate_target` 一致。联赛系统在定义对手强度区间时消费了数值系统的输出范围。
- **建议**: 联赛系统将此依赖从 Soft 升级为 Hard，保持一致。

🔴 **2a.3 — 存档系统声明的下游依赖在联赛系统中无反向声明**

- **涉及文档**: `save-and-load-system.md`, `league-competition-structure-system.md`
- **具体矛盾**: `save-and-load-system.md` 将联赛与赛事结构系统列为 Hard 下游（"赛季容器、赛程状态、积分与排名的长期持久化框架"），但 `league-competition-structure-system.md` 的 Upstream Dependencies 完全未列出存档与读档系统。
- **分析**: 联赛系统的积分榜、赛程、晋级/降级名单属于长期状态，必须随存档一起持久化。联赛系统必须在每次保存时提供权威赛季状态。
- **建议**: 联赛系统在其 Dependencies 中新增存档与读档系统为 Hard 上游依赖。

🔴 **2a.4 — 联赛系统声明的下游依赖在主循环 UI 框架中无反向声明**

- **涉及文档**: `league-competition-structure-system.md`, `main-loop-ui-framework.md`
- **具体矛盾**: `league-competition-structure-system.md` 将主循环 UI 框架列为 Hard 下游（"赛季信息入口的导航数据、积分榜摘要、赛季进度指示"），但 `main-loop-ui-framework.md` 的 Upstream Dependencies 完全未列出联赛与赛事结构系统。
- **分析**: 主循环 UI 框架的 Schedule 视图、赛季进度指示和积分榜摘要均依赖联赛系统数据。主界面侧边栏的赛季位置和积分榜摘要必须消费联赛系统输出。
- **建议**: 主循环 UI 框架在其 Dependencies 中新增联赛系统为 Hard 上游依赖。

#### Warnings

⚠️ **2a.2 — 时间系统声明的 UI 下游依赖缺少反向声明**

- **涉及文档**: `time-and-season-progression-system.md`, `player-management-ui.md`, `match-performance-ui.md`
- **具体问题**: 时间系统将球员管理 UI 和比赛表现 UI 列为 Soft 下游，但这两个 UI GDD 均未将时间系统列为上游依赖。它们通过主循环 UI 框架间接消费时间信息，但时间系统的依赖规则明确要求下游反向声明。
- **建议**: 在 UI GDD 中补上对时间系统的 Soft 依赖声明（注明通过 UI 框架间接消费），或时间系统移除对这些 UI 的直接下游声明。

---

### 2b — Rule Contradictions

#### Blocking

🔴 **2b.1 — 联赛系统公式 5 的描述与公式不一致**

- **涉及文档**: `league-competition-structure-system.md`
- **具体矛盾**: 公式 5 的描述写的是"双循环赛制下**每队**的总比赛场次"，但公式 `matches_per_season = team_count × (team_count − 1)` 计算的是**全联赛**总对阵数。以 12 队为例：公式输出 132，但每队实际场次为 (12−1)×2 = 22 场。
- **建议**: 修正公式为 `2 × (team_count − 1)` 以匹配"每队场次"语义——每队场次对赛季长度和调参更有意义。

🔴 **2b.3 — 联赛系统引用错误的赛季结算触发信号**

- **涉及文档**: `league-competition-structure-system.md`, `time-and-season-progression-system.md`
- **具体矛盾**: 联赛系统 Rule 13 写道赛季结束条件由时间系统发出 `stage_settlement_trigger_reached`（赛季结算节点），但时间系统中 `stage_settlement_trigger_reached` 用于触阶段结算（Stage Settlement），赛季结算由 `season_progress_ratio >= 1` 触发。
- **建议**: 联赛系统引用 `season_progress_ratio >= 1` 或时间系统定义的赛季结算触发条件。

#### Warnings

⚠️ **2b.2 — Offseason 状态所有权不明确**

- **涉及文档**: `time-and-season-progression-system.md`, `league-competition-structure-system.md`
- **具体问题**: 时间系统定义了 `Offseason` 状态及其转换规则，但联赛系统的状态机从 `Season Settlement` 直接转换到 `Pre-Season`，不存在 `Offseason`。休赛期管理权归属不明确。
- **建议**: 明确 Offseason 由时间系统拥有（定义时间窗口），联赛系统在 Pre-Season 中包含 offseason 过渡逻辑。

---

### 2c — Stale References

#### Warnings

⚠️ **2c.1 — 比赛系统对联赛系统的 provisional 标记已过期**

- **涉及文档**: `match-competition-system.md`
- **具体问题**: 比赛系统将联赛系统标记为 "Soft (provisional)" 并说明"尚未设计完成"。联赛系统已设计完成（Status: Designed）。比赛系统自己的 Dependency Rules 要求当联赛系统完成后从 Soft (provisional) 升级为 Hard。
- **建议**: 将比赛系统中对联赛系统的依赖从 Soft (provisional) 升级为 Hard，移除 provisional 注释。

⚠️ **2c.2 — 比赛系统 Edge Case 中"联赛未完成"假设过时**

- **涉及文档**: `match-competition-system.md`
- **具体问题**: Edge Case 写"对手数据尚未由联赛/赛事系统提供（该系统未完成时）"，但联赛系统已完成。`default_opponent_profile` 作为降级方案保留但措辞应更新。
- **建议**: 更新为"联赛系统正常运作时使用联赛对手数据，联赛系统异常/不可用时降级到 default_opponent_profile"。

---

### 2d — Data and Tuning Knob Ownership Conflicts

#### Blocking

🔴 **2d.1 — `default_roster_sort_field` 同时出现在两个 GDD 中**

- **涉及文档**: `main-loop-ui-framework.md`, `player-management-ui.md`
- **具体矛盾**: 两个 GDD 都定义了同名同描述的 `default_roster_sort_field`（"列表默认排序字段——球员列表首次加载时的默认排序依据"）。
- **建议**: 球员管理 UI 是球员列表的具体实现者，应拥有此调节项。主循环 UI 框架移除该条目。

#### Warnings

⚠️ **2d.2 — 比赛系统 `default_opponent_profile` 与联赛系统 `opponent_strength_band` 范围不匹配**

- **涉及文档**: `match-competition-system.md`, `league-competition-structure-system.md`
- **具体问题**: 比赛系统的 `default_opponent_profile` 的 `team_match_strength` 为 40-60，但联赛系统的 `opponent_strength_band` 按层级分段：低级 30-50、中级 45-65、高级 60-85。默认后备值（40-60）横跨低级和中级的重叠区，不与任何单一层级对齐。
- **建议**: 将 default_opponent_profile 范围对齐最低级联赛（30-50），模拟"玩家从最低级起步"的 MVP 体验。

---

### 2e — Formula Compatibility

**零问题**。全部跨系统公式链（`attribute_growth → training_actual_gain → positional_overall_rating → team_match_strength → base_win_probability → actual_win_probability`）输入-输出范围兼容。边界值测试（最大值、最小值、零值、钳制行为）均通过。

---

### 2f — Acceptance Criteria Cross-Check

**零问题**。所有 AC 可同时为真，无逻辑互斥。

---

## Phase 3: Game Design Holism — 2 Blocking / 3 Warnings

### 3a — Progression Loop Competition

**通过**。核心循环定义唯一且一致传递到所有 12 份文档。球员属性成长的唯一权威来源是培养系统，无多系统竞争同一成长资源。

### 3b — Player Attention Budget

⚠️ **经济系统缺失导致注意力预算评估不完整**。当前 MVP 阶段同时活跃系统约 2-3 个（训练 + 赛前），低于 3-4 预警线。但经济系统加入后将新增一个持续 Active 决策维度，可能使峰值升至 3-4。建议设计经济系统时将其决策频率与训练/比赛自然交错。

### 3c — Dominant Strategy Detection

⚠️ **"明星球员始终最优"的风险未完全排除**。培养系统定义了"普通球员短期 ROI 更高、明星球员长期更强"的目标，但短期 ROI 差（10%-30%）和长期上限差（10-25 属性点）的具体平衡未经数值验证。经济系统的缺失使训练成本无法量化，"性价比"比较不可证伪。

### 3d — Economic Loop Analysis

🔴 **经济管理系统未设计 — 三大核心资源的来源与消耗规则缺失**。game-concept.md Rule 3 将经费、研究点数、运动点数定义为玩家必须取舍的核心约束，balance-system.md 定义了资源结算的通用公式，但具体的 faucets 和 sinks 在任何已完成的 MVP GDD 中都没有定义。

- 影响：无法验证资源是否会无限积累、是否存在资源死锁、正反馈循环是否受控
- 5+ 份 GDD 含对经济系统的 provisional 依赖，当经济系统完成时需回溯修改

### 3e — Difficulty Curve Consistency

⚠️ **成长曲线与难度曲线由不同系统独立定义，交叉点未验证**。玩家成长曲线（对数型衰减）与比赛难度曲线（阶梯状上升）从未被联合分析。需做一次"培养-联赛"交叉模拟来确保 `overall_win_rate` 落在 0.55–0.65 目标区间。

### 3f — Pillar Alignment

🔴 **"像素小镇养成"支柱在 MVP 中无系统支撑**。小镇建设系统标记为 Alpha / Not Started。10 个 MVP 系统全部标注了 "Implements Pillar: 像素小镇养成"，但实际上没有任何系统实现该支柱。Player Fantasy 段落承诺的"从无到有建设足球小镇的掌控感"在 MVP 可操作系统中无体验出口。

- 建议 A：将小镇建设系统降级为 MVP 后半段，至少引入一个简化版本（如单一训练设施等级）
- 建议 B：重新审视 MVP 定义，将 Pillar 2 调整为中期扩展方向

### 3g — Player Fantasy Coherence

**通过**。所有系统的 Player Fantasy 高度一致——"玩家 = 长期经营者 + 教练/培养者 + 球队领导者"。无身份冲突。情感词汇一致："温馨""投入""持续变强""低压力""掌控感"。

---

## Phase 4: Cross-System Scenario Walkthrough

### Scenario 1: 训练 → 比赛日 → 赛后成长

**Trigger**: 玩家完成训练，时间推进至比赛节点

| Step | Systems | Action | Issue |
|------|---------|--------|-------|
| Training Resolution | player-dev, time | 训练结算，消耗时间单位 | — |
| Growth Review | player-dev | 展示训练成长结果 | — |
| Planning → Match Trigger | time | `match_trigger_reached = true` | — |
| Pre-Match → Match Confirmation | match | 阵容/战术确认 | — |
| First Half → Halftime → Second Half | match | 比赛演算 | — |
| Result Review → Post-Match | match, time | 赛后结算 | — |
| Standings Update | league | 积分榜更新 | — |
| Growth Opportunities | player-dev | 赛后成长标签回流 | — |

ℹ️ **INFO**: Action Resolution → Match Trigger 的合法跳转可能跳过 Planning 中间态中的 Growth Review 展示。时间系统 Rule 6 要求"推进后发生了什么"必须在推进前清晰说明——实现时应确保 Planning 作为必经过渡。

### Scenario 2: 赛季结束级联

**Trigger**: 赛季最后一场比赛完成

| Step | Systems | Action | Issue |
|------|---------|--------|-------|
| Last Match → Post-Match | match, time | 最后一场确认 | — |
| Standings Final Update | league | 最终积分榜锁定 | — |
| Season Settlement Trigger | time | `season_progress_ratio >= 1` | — |
| Season Settlement | league | 晋级/降级确定 | 🔴 2b.3: 联赛系统引用错误信号 |
| Offseason | time | 赛季间隙 | ⚠️ 2b.2: 联赛系统无 Offseason 状态 |
| New Season | time, league | 新赛季初始化 | — |

⚠️ **WARNING**: Post-Match Settlement 同时触发培养系统（赛后成长）和联赛系统（积分榜更新），两个同步操作的执行顺序未在任何 GDD 中指定。如果一方操作失败，无明确定义的回滚/重试机制。

### Scenario 3: 新手引导 + 比赛触发重叠

**Trigger**: 新存档引导中，`match_trigger_reached = true`

| Step | Systems | Action | Issue |
|------|---------|--------|-------|
| First Training step | onboarding, player-dev | 引导训练完成 | — |
| Match Trigger fires | time | 比赛节点到达 | — |
| Onboarding → First Match Pre | onboarding | 引导跟随玩家进入赛前 | — |

ℹ️ **INFO**: 引导的"首场比赛——赛中"提示在 Halftime Adjustment 中出现，期间玩家需要做战术决策。当前设计通过 Rule 8（非阻断、可跳过）正确覆盖，但中场提示的展示位置应避免遮挡战术选项。

### Scenario 4: 赛后保存 → 重载 → 赛季结算恢复

**Trigger**: 赛后保存，赛季结算前重载

| Step | Systems | Action | Issue |
|------|---------|--------|-------|
| Post-Match Settlement | match, time | 赛后，稳定节点 | — |
| Manual Save | save-and-load | 快照写入 | — |
| Reload | save-and-load | 恢复到 Post-Match | — |
| Season Settlement | time, league | `season_progress_ratio >= 1` 再次触发 | — |

**通过**。Post-Match Settlement 是稳定保存节点，重载后赛季结算正确重新触发。

---

## Summary — GDDs Flagged for Revision

| # | GDD | Issues | Priority |
|---|-----|--------|----------|
| 1 | `league-competition-structure-system.md` | 2b.1 (公式错误), 2b.3 (信号引用), 2a.3+2a.4 (缺少反向依赖), 2a.1 (Hard/Soft 不匹配) | **Blocking** |
| 2 | `main-loop-ui-framework.md` | 2a.4 (缺少联赛依赖), 2d.1 (Tuning Knob 冲突) | **Blocking** |
| 3 | `match-competition-system.md` | 2c.1 (过期 provisional), 2c.2 (过期假设), 2d.2 (范围不匹配) | Warning |
| 4 | `player-management-ui.md` | 2a.2 (缺少时间系统反向依赖) | Warning |

---

## Verdict: FAIL

**Blocking issues (7)**: 5 个一致性 Blocking + 2 个设计整体性 Blocking

**关键路径**: 联赛系统有 4 个 Blocking 项（公式错误、信号引用错误、2 个反向依赖缺失），必须在进入架构设计前修复。经济管理系统和小镇建设系统的缺失属于设计层面 Blocking，解决方式取决于用户决策（立即设计 vs 调整 MVP 范围声明）。

### Required actions before re-running /review-all-gdds

1. 修复 `league-competition-structure-system.md`: 公式 5 修正、赛季结算信号引用修正、补上存档系统和主循环 UI 框架的双向依赖
2. 修复 `main-loop-ui-framework.md`: 补上联赛系统依赖、移除重复的 `default_roster_sort_field`
3. 修复 `match-competition-system.md`: 升级过期 provisional 引用、更新 Edge Case 措辞
4. 设计 `经济管理系统` GDD 或将资源规则临时内嵌到现有 MVP GDD 中
5. 决定"像素小镇养成"支柱的 MVP 策略（简化版建设 vs 调整 MVP 范围声明）
