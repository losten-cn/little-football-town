# 足球小镇：全局 GDD 复查报告（技能与特性补丁后）

> **Date**: 2026-05-31  
> **Mode**: `/review-all-gdds full`  
> **Scope**: Cross-GDD consistency, holistic design review, and multi-system scenario walkthrough after the skill-and-trait targeted patch  
> **Verdict**: **FAIL** — Systems Design should not advance to Technical Setup until blockers are resolved or explicitly accepted.

## Summary

本次复查验证了技能与特性系统定点补丁后的全局一致性。结论是：上一轮最危险的推进硬死锁、非法比赛状态阻塞和技能系统边界混乱已有明显改善；`match_day_ap_safety_grant`、推荐阵容/错位补位/`forfeit_result_packet` 兜底链、`pre_match_skill_trait_snapshot` 只读快照、技能聚合封顶和候选进度模糊可见性都属于有效修补。

但整体仍未达到 Technical Setup 的安全门槛。当前阻塞集中在四类问题：小镇建设仍可能争夺主 progression 地位；赛前注意力预算仍超载；低胜率 + 维护费 + 建设失误下的经济软停滞恢复路径仍未被证明足够温和；技能系统新增的长期状态尚未被存档和 UI 文档完整承接。

## Documents Reviewed

- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/gdd/balance-system.md`
- `design/gdd/save-and-load-system.md`
- `design/gdd/time-and-season-progression-system.md`
- `design/gdd/player-development-system.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/league-competition-structure-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/reputation-and-achievement-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/match-performance-ui.md`
- `design/gdd/onboarding-system.md`
- `design/gdd/skill-and-trait-system.md`

Historical report excluded from system scope:

- `design/gdd/gdd-cross-review-2026-05-31.md`

Registry baseline:

- `design/registry/entities.yaml` exists.
- Entities/items/constants are empty.
- Registered formulas include `effective_attribute_value`, `attribute_growth`, `resource_settlement`, `positional_overall_rating`, `base_win_probability`, `action_time_cost`, `available_action_windows`, `match_trigger_reached`, `stage_settlement_trigger_reached`, `season_progress_ratio`, `remaining_time_to_next_key_node`, `training_actual_gain`, and `player_tier_potential_band`.
- New skill-system formulas such as `settlement_key`, `aggregated_skill_modifier`, and `candidate_progress_ratio` are not yet registered.

## Blocking Issues

### 1. Town building still competes for primary progression

**Severity**: BLOCKER  
**Source**: Holistic design review  
**Files / systems**:

- `design/gdd/town-building-system.md`
- `design/gdd/player-development-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/match-competition-system.md`

**Issue**: 小镇建设文档虽然把范围描述为 “MVP 最小切片”，但实际规则仍同时输出训练倍率、AP 恢复、维护费压力、主场优势、比赛收入倍率，并保留 5×5 网格、邻接和拆建损失。这让 town building 不再只是温暖背景层或长期承托层，而是可能成为玩家最优路径的主导优化棋盘。

**Why it blocks**: 技术架构无法确定 town 是轻量状态层，还是需要独立网格模拟、邻接求值、长期经济结算、跨系统事件广播和复杂 UI 的核心子系统。这个选择会直接影响存档模型、刷新时序、UI 信息架构和系统边界。

**Required before Technical Setup**:

- 明确 MVP town building 的活跃决策上限。
- 削弱或后置部分跨系统硬输出，尤其是同时影响训练、比赛、经济和 AP 的输出组合。
- 明确哪些建设数据 MVP 只做展示/摘要，哪些必须进入正式计算。

### 2. Pre-match attention budget remains overloaded

**Severity**: BLOCKER  
**Source**: Holistic design review + scenario walkthrough  
**Files / systems**:

- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/match-performance-ui.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/time-and-season-progression-system.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/skill-and-trait-system.md`

**Issue**: 典型正式比赛前，玩家可能同时处理 AP 合法性、阵容合法性、战术选择、技能/特性快照结果、设施加成、对手与联赛 stakes、赛后成长预期。这已经逼近职业经理式多面板决策，而不是低压力的 “培养 → 比赛 → 反馈” 循环。

**Why it blocks**: MVP 中哪些信息必须同屏、哪些自动化、哪些只做后置反馈尚未定死。技术团队无法稳定定义主循环状态机、赛前界面拆分、提示优先级、UI 锚点和事件顺序。

**Required before Technical Setup**:

- 明确赛前最多 3–4 个活跃决策。
- 将设施、技能快照和成长预期中至少一部分降级为只读摘要或赛后解释。
- 让阵容合法性兜底和 AP 安全补足默认自动化，避免成为玩家必须主动优化的赛前任务。

### 3. Economic soft-stall recovery is not proven

**Severity**: BLOCKER  
**Source**: Holistic design review + scenario walkthrough  
**Files / systems**:

- `design/gdd/economy-management-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/league-competition-structure-system.md`
- `design/gdd/balance-system.md`

**Issue**: 经济设计已经解决硬死锁：AP 安全补足可以保证正式比赛继续开赛。但 “低胜率 + 维护费 + 建设失误” 下的中期恢复路径仍未被证明足够温和。AP 补足保证比赛能发生，不保证玩家不会陷入长期低收益、无法建设、无法有效提升胜率的软停滞。

**Why it blocks**: 技术实现需要知道经济失败状态是可恢复低谷、系统性救济的一部分，还是玩家承担的硬经营后果。否则结算、提示、AI 建议、经济日志、新手保护和测试用例都没有稳定契约。

**Required before Technical Setup**:

- 给出低胜率 + 高维护费样本下的恢复路径 AC。
- 明确哪些系统负责提示玩家脱困：经济、主循环 UI、新手引导或声望/成就。
- 明确维护费压力在 MVP 中是轻量约束还是核心风险/回报玩法。

### 4. Skill-system long-term state is not fully carried by save/load

**Severity**: BLOCKER  
**Source**: Cross-GDD consistency review  
**Files / systems**:

- `design/gdd/skill-and-trait-system.md`
- `design/gdd/save-and-load-system.md`

**Issue**: 技能与特性系统已把 `candidate_progress_record`、`candidate_visibility_stage`、`player_identity_history`、`pending_skill_trait_feedback` 和 `feedback_ack` 作为长期状态与反馈来源。但存档文档仍主要停留在泛化的 skill/trait 持久化表述，未明确这些新增字段的保存、读取、版本迁移与缺失回退。

**Why it blocks**: 程序无法据此建立稳定序列化契约和迁移测试。一旦实现先行，容易出现旧档丢历史、候选进度重置、读档后 UI/结算解释失真。

**Required before Technical Setup**:

- 在 save/load GDD 明确列出 `candidate_progress_record`、`player_identity_history`、trait visible cooldown 状态、feedback ack 状态和相关迁移规则。
- 增加读档后一致性 AC：候选进度、身份历史、反馈确认状态必须恢复一致且不重复展示。

### 5. Skill-system UI consumption contract is incomplete

**Severity**: BLOCKER  
**Source**: Cross-GDD consistency review  
**Files / systems**:

- `design/gdd/skill-and-trait-system.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/match-performance-ui.md`

**Issue**: 技能文档要求玩家可见候选进度、模糊阶段、身份历史与赛后反馈来源；但球员管理 UI 未把 `player_identity_history`、模糊阶段展示和阻塞原因展示写成明确界面规则。比赛表现 UI 也没有把 snapshot 驱动的赛前/赛后技能解释升级为明确消费契约。

**Why it blocks**: 上游已定义输出，下游未定义消费方式。程序和 UX 无法决定哪些字段必须实现、何时展示、如何 ack，容易导致接口存在但没有合法入口，或 UI 自行做出与 GDD 不一致的解释逻辑。

**Required before Technical Setup**:

- 在 player-management UI 增加 `player_identity_history`、候选阶段、阻塞原因和最近触发解释的显示规则。
- 在 match-performance UI 明确只展示 `pre_match_skill_trait_snapshot` 与已确认触发解释，不重算资格。
- 为反馈确认与历史回看增加可测试 AC。

## Warnings

### 1. Skill and trait design could still drift into build pressure

**Severity**: WARNING  
**Files / systems**:

- `design/gdd/skill-and-trait-system.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/match-performance-ui.md`

技能与特性文档本身已经明显降压：小池、家族上限、聚合封顶、模糊候选进度、可见冷却都能降低 RPG build 压力。但一旦技能信息固定进入球员详情、赛前快照和赛后反馈三处入口，玩家仍可能追逐隐藏最优组合。后续 UI 必须把技能当作身份解释，而不是优化面板。

### 2. Reputation and achievements can become checklist pressure

**Severity**: WARNING  
**Files / systems**:

- `design/gdd/reputation-and-achievement-system.md`
- `design/gdd/main-loop-ui-framework.md`

声望/成就文案目标是 “相册式认可”，方向正确。但已有多处 UI 预留位，未来若与资源、解锁或赛季目标绑定过深，容易滑向 checklist pressure。需要持续保持轻量、纪念性、非限时、非错过惩罚。

### 3. Difficulty curve may become sawtoothed

**Severity**: WARNING  
**Files / systems**:

- `design/gdd/player-development-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/balance-system.md`
- `design/gdd/league-competition-structure-system.md`

训练成长、设施增益、联赛晋级压力和比赛胜率目标各自合理，但组合后可能形成前期平缓、中期设施/训练滚雪球、后期被维护费重新拉住的锯齿曲线。需要用样本赛季验证而不是只看单系统公式。

### 4. Player fantasy still has light identity tension

**Severity**: WARNING  
**Files / systems**:

- `design/gdd/game-concept.md`
- `design/gdd/town-building-system.md`
- `design/gdd/match-competition-system.md`

总概念强调温暖小镇教练/经理，但 town 的网格优化与赛前多层决策仍会把部分玩家拉向 “求最优解的系统经理”。这不一定错误，但必须有意识地用 UI 默认、自动化和低压文案把体验拉回 cozy management。

### 5. Systems index and document headers have status drift

**Severity**: WARNING  
**Files / systems**:

- `design/gdd/systems-index.md`
- `design/gdd/player-development-system.md`
- `design/gdd/skill-and-trait-system.md`

`player-development-system.md` 在索引中是 Approved，但正文文件头仍是 Designed；`skill-and-trait-system.md` 在索引中是 In Review，但文件头仍是 In Design。这不会直接破坏设计，但会误导排期、评审门禁和下一步状态判断。

### 6. Formula registry lags behind new skill formulas

**Severity**: WARNING  
**Files / systems**:

- `design/registry/entities.yaml`
- `design/gdd/skill-and-trait-system.md`

`settlement_key`、`aggregated_skill_modifier`、`candidate_progress_ratio` 尚未进入 registry。若 registry 继续作为跨文档公式基线，自动一致性扫描和测试映射会漏掉这些新公式。

### 7. Minor document-structure drift remains

**Severity**: WARNING  
**Files / systems**:

- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/town-building-system.md`

`main-loop-ui-framework.md` 和 `match-competition-system.md` 存在 Dependency Rules 编号重复。`economy-management-system.md` 和 `town-building-system.md` 使用 `Detailed Design` 而不是标准 `Detailed Rules`，且仍保留额外占位段落。这些主要是标准合规噪音，但会影响后续自动化审查准确性。

## Resolved Since Previous Cross-Review

### 1. Match-day AP deadlock is structurally reduced

`time-and-season-progression-system.md` 与 `economy-management-system.md` 的 `match_day_ap_safety_grant` 基本解决了正式比赛节点 AP 不足导致时间推进卡死的问题。这次看起来是结构性修复，不只是文字转移。

### 2. Illegal lineup fallback is now coherent

`match-competition-system.md` 与 `time-and-season-progression-system.md` 通过推荐阵容 → 错位补位 → `forfeit_result_packet` 的兜底链，明显降低了非法阵容阻塞赛程的旧风险。

### 3. Skill/trait system no longer behaves like an independent RPG build layer

`skill-and-trait-system.md` 与 `match-competition-system.md` 的边界更清晰：比赛消费赛前只读快照，技能系统拥有解锁/升级/触发语义。聚合封顶、模糊候选进度、可见冷却和小池内容都在降低优化压力。

### 4. MVP boundary is clearer than the previous review

`systems-index.md` 与 `game-concept.md` 中，研究点数退到后台累积，town building 被明确写成 MVP 最小切片。方向上比上一轮更收敛。

### 5. Main-loop feedback order is more stable

`main-loop-ui-framework.md` 已明确核心训练/比赛结果 → 技能/特性变化 → 声望/成就 → 其他奖励/提示的展示顺序，减少了多个长期反馈系统争夺 UI 焦点的风险。

## Cross-System Scenario Walkthroughs

### Scenario 1 — Official match day with low AP and imperfect lineup

**Trigger**: 时间系统到达不可跳过的正式比赛节点。

**Activation order**:

1. 时间系统检测 `match_trigger_reached = true`。
2. 若 AP 不足，经济系统提供一次性 `match_day_ap_safety_grant`。
3. 主循环 UI 将比赛入口提升为最高优先级。
4. 比赛系统检查阵容合法性。
5. 若阵容不合法，按推荐阵容 → 错位补位 → `forfeit_result_packet` 兜底。
6. 新手引导和比赛表现 UI 解释兜底结果。

**Finding**: 硬死锁已解决。剩余风险是注意力超载：玩家可能同时看到 AP 补足、阵容兜底、战术、对手、联赛影响和技能快照。此场景支持 Blocker 2。

### Scenario 2 — Post-match settlement with skill changes and reputation events

**Trigger**: 比赛终场确认。

**Activation order**:

1. 比赛系统输出权威结果包和稳定 `settlement_id`。
2. 技能与特性系统消费赛后稳定事实，更新技能进度/候选进度/特性触发。
3. 技能系统写入 `pending_skill_trait_feedback` 与 `player_identity_history`。
4. 声望与成就系统消费长期里程碑事实。
5. 主循环 UI 按固定顺序展示核心结果、技能/特性、声望/成就、其他奖励。

**Finding**: 展示顺序已清楚；但 save/load 与 UI 尚未完整承接 `candidate_progress_record` 和 `player_identity_history`。此场景支持 Blocker 4 和 Blocker 5。

### Scenario 3 — Low win-rate team with upgraded facilities and growing maintenance

**Trigger**: 玩家中期建设多个设施，但比赛胜率偏低。

**Activation order**:

1. Town building 提供训练、AP、主场、收入等加成。
2. Economy 每日扣除基础维护费 + `facility_total_maintenance`。
3. 低胜率降低比赛收入与联赛推进收益。
4. AP 安全补足保证比赛继续，但不直接修复现金流。
5. 玩家可能难以继续建设或升级，训练/比赛改善变慢。

**Finding**: 不会形成硬死锁，但可能形成软停滞。恢复路径尚未用 AC 或样本证明。此场景支持 Blocker 3。

### Scenario 4 — Player detail review after skill candidate progress is blocked by family limit

**Trigger**: 球员同家族候选技能持续获得进度，但主技能位已占用。

**Activation order**:

1. 技能系统记录 `candidate_progress_record`。
2. 技能系统计算 `candidate_visibility_stage`。
3. 球员管理 UI 应展示模糊阶段和阻塞原因。
4. 存档系统必须持久化候选进度和历史。

**Finding**: 技能系统定义完整，但 UI 和 save/load 反向承接不足。此场景支持 Blocker 4 和 Blocker 5。

## Final Verdict

**FAIL**

这套 GDD 已经修掉了最危险的 “推进硬死锁” 与 “非法状态卡死” 问题，但整体设计仍未完全回答一个更根本的问题：本游戏的主体验到底是低压力的培养 + 比赛循环，town 负责温暖承托；还是带网格优化和多重赛前决策的综合管理模拟。当前 progression loop 竞争尚未收束，赛前 attention budget 也还没有压回 cozy 管理游戏应有的负荷。再加上技能系统新增长期状态尚未被存档和 UI 文档完整闭环，技术团队现在开始 Technical Setup 会被迫同时为两种不同复杂度的游戏搭骨架。

建议不是推翻现有方向，而是在进入 Technical Setup 前再收一次 MVP：削弱 town 的跨系统硬输出，明确赛前最多 3–4 个活跃决策，其余自动化或后置反馈；同时补齐技能新增状态在 save/load、player-management UI 和 match-performance UI 中的消费契约。完成这些后，整体有机会转为 **PASS WITH WARNINGS**。
