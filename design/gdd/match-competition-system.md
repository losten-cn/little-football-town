# 足球小镇：比赛竞技系统

> **Status**: Designed
> **Author**: 用户 + Claude
> **Last Updated**: 2026-06-02
> **Implements Pillar**: 轻度足球经营、低压力长期成长
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/balance-system.md`
> - `design/gdd/time-and-season-progression-system.md`
> - `design/gdd/save-and-load-system.md`
> - `design/gdd/player-development-system.md`
> - `E:\code\game\game-design\00-足球小镇-策划总览.md`
> - `E:\code\game\game-design\02-足球小镇-数值平衡方案.md`

## Overview

比赛竞技系统是《足球小镇》中负责把球队长期培养成果转化为可验证比赛表现的核心竞技层。它围绕赛前阵容与战术准备、比赛过程演算、关键事件反馈、胜负结果结算以及赛后状态回流展开，把数值系统提供的共享属性与评分规则、培养系统提供的球员能力与状态、时间系统提供的比赛节点和赛季节奏，组织成玩家可理解、可期待、可复盘的比赛体验。它不拥有球员长期成长语义、赛季日历推进或存档恢复边界本身，而是负责回答“这支球队现在踢得怎么样、为什么赢或输、赛后会带来什么变化”，让玩家在低压力节奏中清楚看到训练与经营投入如何在比赛里兑现，并把比赛结果重新送回主循环，形成“培养 → 比赛 → 反馈 → 再培养”的核心闭环。

## Player Fantasy

比赛竞技系统服务的玩家幻想是：“我把亲手培养出来的这支球队，真正带上赛场踢出了属于我们的足球。”玩家期待的不是一串冰冷结算，而是能清楚看到自己长期经营与培养的成果如何在比赛里兑现：那个平时重点训练的前锋终于把握住关键机会，那个原本薄弱的中场因为长期投入而让球队运转更顺，那个愿意坚持培养的普通球员也能在合适体系里打出超出预期的价值。胜利因此不只是运气或单次点击的结果，而是长期判断、阵容取舍、战术安排和球员成长共同积累后的可见回报。

这种幻想的重点不是高压、强操作、强惩罚的竞技刺激，而是“我看得懂、我能预期、输了也知道为什么”的低压力比赛体验。玩家应当在赛前有准备空间，在赛中看到关键反馈，在赛后能复盘“这场比赛为什么会这样”，从而把每一场比赛都视为对培养路线和经营思路的一次验证。比赛竞技系统必须让玩家相信：不同球员值得培养、不同阵容值得尝试、不同战术会带来不同结果，而自己为这支小镇球队做过的每一次长期投入，最终都会在赛场上留下清晰而有说服力的痕迹。

## Detailed Rules

### Core Rules

1. 比赛竞技系统是单场比赛流程的权威来源，负责定义赛前准备、阵容合法性校验、战术选择、比赛演算、关键事件反馈、胜负结果确认以及赛后回流数据的语义。
2. 本系统只拥有"比赛层"的决策与结果，不拥有球员长期成长、赛季时间推进、稳定存档边界、技能/特性状态或共享属性公式本体：
   - 五维属性、`effective_attribute_value`、`positional_overall_rating`、`base_win_probability` 由数值系统拥有；
   - 比赛节点触发、赛后结算所在时间节点、赛季推进节奏由时间与赛季推进系统拥有；
   - `Match In Progress` 不是标准可恢复节点这一规则由存档与读档系统拥有；
   - 球员长期成长、潜力、训练效率与成长语义由运动员培养系统拥有；
   - 技能等级、技能进度、特性状态、候选进度、稳定结算键和技能/特性反馈语义由技能与特性系统拥有。
3. 一场比赛只能在 `match_trigger_reached = true` 的合法比赛节点上进入；比赛系统不得自行生成脱离时间轴的正式比赛。若正式比赛节点到达时 AP 不足，比赛系统不直接处理资源补足，而是等待时间系统与经济系统完成 `match_day_ap_safety_grant` 后再进入赛前流程。
4. MVP 阶段玩家赛前活跃决策必须集中在少数高价值选择上：确认或轻调推荐阵容、选择一个战术方案、确认开赛。系统必须提供可直接采用的推荐阵容与推荐战术；若玩家不主动细调，推荐方案即为合法默认选择，不得把阵容合法性、AP 状态、设施修正、技能/特性快照或联赛上下文拆成多项必须逐个处理的赛前任务。比赛表现 UI 在自由赛前编辑态中可以阻止玩家用非法阵容手动开赛，但一旦正式比赛节点进入不可跳过的强制触发态，UI 不得阻塞本系统继续执行推荐阵容、错位补位或 `forfeit_result_packet` 兜底。
5. 比赛系统消费的是培养系统输出的球员当前能力结果，以及技能与特性系统在赛前锁定的只读效果快照，而不是重建一套独立成长或技能体系。单名球员进入比赛时，至少应带入以下可比赛消费字段：当前属性、有效属性、状态标签、位置适配倾向、可用性状态、`pre_match_skill_trait_snapshot`。比赛系统只读取快照中已聚合的技能比赛标量和特性解释摘要，并由本系统在赛前锁定 `team_skill_trait_summary` wrapper 后唯一推导比赛层 `skill_trait_match_mod`；不得消费技能系统内部 混合后的上下文修正字段、不得把训练倍率复用于比赛、不得逐项重算技能效果、解锁资格、候选进度或特性触发条件。`team_skill_trait_summary` 最小字段为 `summary_id`, `settlement_id`, `snapshot_status`, `lineup_player_ids[]`, `player_effect_rows[]`, `team_modifier_milli`, `applicable_player_count`, `summary_label_key`, `rule_version`；`player_effect_rows[]` 最小字段为 `player_id`, `lineup_slot_id`, `lineup_order`, `context_id`, `player_skill_match_modifier_milli`, `applicable_skill_count`, `applicable_trait_ids[]`, `effect_summary_ids[]`，并按 `lineup_order ASC, player_id ASC` 排序。Match Confirmation 必须先预分配本场 `match_settlement_id`，并要求 `pre_match_skill_trait_snapshot.settlement_id` 与该值一致后才可标记 `applied_locked_snapshot`；`team_skill_trait_summary` 只消费 `context_modifier_summary[]` 中 `context_id = match` 且属于当前锁定首发的浅层记录。若快照缺失、版本不匹配、payload 不满足浅层 typed contract、settlement_id 不一致，或任一首发缺少 match context row，本系统必须使用安全默认摘要：`snapshot_status = missing_safe_default` 或 `version_mismatch_safe_default`，`team_modifier_milli = 0`，且不得从 live player state 回补。
6. 合法阵容判断必须优先服务低压力体验。MVP 阶段允许玩家使用低适配度球员补位，但必须通过 `positional_overall_rating` 明确体现错位上阵的表现折损；系统不应因"没有完美位置人选"而轻易卡死比赛流程。
7. 正式比赛节点遇到非法阵容时，比赛系统必须按固定兜底顺序自动处理：先生成推荐阵容；若缺少特定位置但存在可出场球员，则允许错位补位并施加位置适配折损；若可出场人数仍低于最低比赛人数或完全无可出场球员，则生成 `forfeit_result_packet`（默认 0–3 负场、无关键事件、无球员成长标签、正常交给联赛/经济/时间结算），不得阻塞赛程。UI 可以解释兜底结果，但不得要求玩家逐项解决兜底链中的每个中间状态。
8. 比赛前的球队强度评估必须以共享 `positional_overall_rating` 为单个球员位置适配锚点，并由本系统进一步聚合为队伍比赛强度；数值系统不直接定义"如何从阵容得到最终比赛表现"，该聚合逻辑由本系统拥有。
9. 单场比赛结果不能只由静态队伍评分直接拍板。本系统必须把至少四类来源纳入比赛演算：
   - 阵容强度与位置适配；
   - 球员当前状态与可用性；
   - 战术选择与对位关系；
   - 随机波动与关键事件。
10. `base_win_probability` 只作为赛前基准胜率锚点使用；比赛系统必须在其之上叠加主场、战术匹配、状态、关键事件等比赛内修正，形成本场比赛的实际结果分布。
11. MVP 阶段的比赛流程应以"可观察演算 + 关键反馈"为主，而不是高频手动操作。玩家的主要决策集中在赛前准备与中场调整；系统不追求逐秒微操，也不要求玩家在比赛中持续高压输入。
12. 比赛演算必须至少拆分为多个可解释阶段，使玩家能理解比赛不是一次黑箱掷骰。MVP 默认包含：开场前确认、上半场演算、中场调整、下半场演算、终场结果确认。
13. 比赛过程中必须产生可读关键事件，用于解释比分与过程。MVP 至少应支持以下事件类别：进攻推进、射门/扑救、进球、关键防守、战术调整生效、体能或状态下滑带来的表现变化。
14. 中场调整必须是正式可用的策略窗口。玩家至少可以在中场重新安排阵型或战术倾向，并在可用条件下调整上场球员；这些改动只能影响下半场，不得回溯改写上半场已发生事件。
15. 一旦比赛进入正式演算，`Match In Progress` 期间的过程结果必须被视为未稳定中间态；系统不得把半场中、关键事件进行中或比分未最终确认时写成标准可恢复存档点。
16. 终场一旦确认，比赛结果必须立刻成为权威结果包，至少包括：胜/平/负、比分、关键事件摘要、球员出场摘要、体能/状态变化、士气反馈、供其他系统消费的赛后标签，以及供技能与特性系统幂等消费的稳定 `settlement_id`。
17. 比赛结果包必须为技能与特性系统输出稳定 `skill_trait_settlement_input.confirmed_facts[]`，每名出场球员至少包含：`match_minutes_band`、`position_role_played`、`role_coverage_count`、`low_error_tag_count`、`key_positive_event`（如有）、`key_defensive_event`（如有）、`post_match_growth_tag`、`player_performance_band`，以及 `fact_order` 和稳定 `source_event_id`。低失误事实必须来自比赛系统的事件/评分结果，不得由 UI 复盘文案反推。
18. `skill_trait_snapshot_status` 必须随结果包输出，枚举只允许 `applied_locked_snapshot`, `missing_safe_default`, `version_mismatch_safe_default`。状态为 `missing_safe_default` 或 `version_mismatch_safe_default` 时，比赛可继续以无技能/特性修正执行，但赛后不得回补赛前技能效果解释。
19. 比赛系统可以回传"赛后成长机会"、"比赛负荷"或"技能/特性可消费比赛事实"之类的结构化结果，但不能直接在本系统中静默改写球员长期成长语义、技能进度或特性状态；任何长期属性成长都必须通过培养系统定义的正式接口落地，任何技能/特性变化都必须通过技能与特性系统在稳定结算节点处理。
18. 比赛反馈必须支持复盘。无论输赢，系统都至少应能向玩家解释一组主要原因，例如：阵容强度差距、错位上阵、体能不足、战术被克制、关键事件波动。
19. 比赛系统必须同时支持两类价值兑现：
   - 普通球员的短期可用价值：在合适位置和体系里稳定补强；
   - 明星/高潜力球员的长期兑现价值：在关键比赛中提供更高上限表现。
   这意味着比赛系统不能把所有球员做成同质化输出，否则会削弱培养系统建立的层级差异。
20. 本系统输出的是"单场比赛结果语义"，不是"联赛排名与晋级结构"的最终拥有者。积分、轮次、晋级、淘汰等赛制后果由联赛与赛事结构系统消费本系统结果包后定义。
21. MVP 阶段比赛系统的首要目标不是模拟完整足球世界的一切细节，而是稳定验证"赛前准备真的重要、比赛结果看得懂、赛后反馈能回到培养决策"的核心闭环。

### States and Transitions

| State | Description | Enter condition | Exit condition | Valid next states |
|---|---|---|---|---|
| Match Entry | 时间系统触发正式比赛节点后，玩家进入本场比赛入口 | `match_trigger_reached = true`，且当前节点为正式比赛节点 | 玩家进入赛前准备，或暂时返回 Planning 保持比赛待处理 | Pre-Match Preparation / Planning |
| Pre-Match Preparation | 玩家查看对手摘要、己方推荐阵容、状态与推荐方案，并在有限决策预算内确认阵容和战术 | 从 Match Entry 进入，或从中途取消确认返回 | 玩家确认进入比赛，或返回 Match Entry/Planning | Match Confirmation / Match Entry / Planning |
| Match Confirmation | 系统锁定本场使用的阵容、位置分配和初始战术，并生成开场参数；若兜底后仍非法则生成弃权结果包 | 玩家在赛前准备中点击开始比赛，或不可跳过比赛节点需要自动处理非法阵容 | 锁定成功并正式开赛；或 `forfeit_result_packet` 已生成 | First Half Simulation / Settlement Handoff |
| First Half Simulation | 系统结算上半场关键事件、临时比分与阶段表现 | Match Confirmation 完成 | 上半场结束 | Halftime Adjustment |
| Halftime Adjustment | 玩家查看上半场摘要并进行有限调整 | First Half Simulation 结束 | 玩家确认中场调整，或选择维持不变 | Second Half Simulation |
| Second Half Simulation | 系统结算下半场事件、终场比分与结果倾向 | Halftime Adjustment 完成 | 终场结果已确定 | Result Review |
| Result Review | 向玩家展示比分、关键事件、表现摘要与主要胜负原因 | Second Half Simulation 结束 | 玩家确认终场结果 | Settlement Handoff |
| Settlement Handoff | 把已确认比赛结果包移交给时间系统、培养系统及后续赛事/结算系统 | Result Review 确认 | 赛后状态和结果成功交接 | Post-Match Settlement |

### Interactions with Other Systems

| System | 比赛竞技系统提供 | 该系统提供回比赛竞技系统 | Ownership boundary |
|---|---|---|---|
| 数值系统 | 阵容聚合后的队伍比赛强度需求、比赛中对共享公式的消费场景 | 五维属性定义、`effective_attribute_value`、`positional_overall_rating`、`base_win_probability` | 数值系统拥有共享属性和基准公式；比赛系统拥有"如何把阵容与战术转成单场表现" |
| 时间与赛季推进系统 | 比赛是否已完成、何时可进入赛后结算、比赛结果已锁定的信号 | 比赛触发节点、赛后结算节点、赛季时间轴位置 | 时间系统决定比赛何时发生；比赛系统决定比赛发生后内部如何演算与何时产出最终结果 |
| 存档与读档系统 | 比赛前可恢复节点、终场后已确认结果包、异常退出时的比赛状态语义 | 稳定保存节点定义、`Match In Progress` 非标准恢复节点规则 | 存档系统拥有"什么能存/怎么恢复"；比赛系统拥有"哪一刻结果算最终确认" |
| 运动员培养系统 | 球员出场摘要、比赛负荷、状态变化、赛后成长机会标签 | 球员当前能力、有效属性、状态标签、位置适配倾向、可用性 | 培养系统定义球员长期成长与状态语义；比赛系统定义这些能力在单场里如何兑现并回传什么赛后影响 |
| 技能与特性系统 | 赛后稳定比赛事实、关键事件、位置表现、表现标签、可供幂等消费的 `settlement_id` | 赛前锁定的 `pre_match_skill_trait_snapshot`、聚合技能修正、已拥有特性摘要、适用场景说明 | 技能系统定义技能/特性资格、效果和长期状态；比赛系统只消费赛前只读快照并输出赛后事实，不在比赛中或赛后重算解锁/升级/特性条件 |
| 联赛与赛事结构系统 | 胜/平/负、比分、主客结果、关键事件摘要等标准结果包 | 对手来源、赛制约束、积分/晋级解释规则 | 比赛系统定义单场结果；赛事结构系统定义这些结果如何影响联赛、杯赛和赛季目标 |
| 比赛表现 UI | 赛前阵容字段、战术字段、关键事件流、终场摘要、复盘原因标签 | 实际展示方式、交互节奏、信息层级 | 比赛系统定义显示内容的真实语义；UI 系统定义如何把它做成玩家可读、可操作的界面 |
| 音频系统 | 进球、关键扑救、逆转、终场等高情绪节点事件 | 音效/BGM 呈现与情绪强化方式 | 比赛系统定义何时发生高价值反馈点；音频系统定义这些时刻听起来如何 |
| 新手引导系统 | 玩家需要理解的最小比赛概念：阵容、战术、中场调整、赛后复盘 | 首场比赛引导节奏、提示顺序、教学文案 | 比赛系统定义玩家必须学会什么；引导系统定义如何在首场比赛中教会玩家 |

> **Provisional assumption:** 联赛与赛事结构系统已完成设计（`design/gdd/league-competition-structure-system.md`）。比赛系统向其输出标准化结果包，积分规则、晋级条件、赛程编排逻辑由该 GDD 定义。本节保留向后兼容的 `default_opponent_profile` 作为联赛系统异常时的降级后备。

## Formulas

### 1. 队伍比赛强度

`team_match_strength` 聚合单场比赛所用阵容的总体强度：

`lineup_base_strength = Σ(active_player_i.positional_overall_rating × lineup_weight_i) / Σ(lineup_weight_i) × chemistry_factor`

`team_match_strength = lineup_base_strength + facility_rating_bonus`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 球员位置综合评分 | `positional_overall_rating` | float | 1–100 | 来自数值系统共享公式，按球员本场实际位置计算 |
| 阵容权重 | `lineup_weight_i` | float | 0.1–1.0 | 该位置在阵容贡献中的相对权重；由所选阵型定义 |
| 阵容化学修正 | `chemistry_factor` | float | 0.85–1.15 | 球员间适配度、是否频繁轮换、位置熟悉度的综合修正 |
| 阵容基础强度 | `lineup_base_strength` | float | ~1–115 | 球员评分与化学修正后的阵容强度，允许因化学修正超过 100 |
| 设施评分加成 | `facility_rating_bonus` | float | MVP 0–5；Alpha 预留 0–15 | MVP 最小可见支撑切片中，主场比赛时来自小镇建设系统的 `home_advantage_bonus`；不包含 `adj_stadium_home_bonus`，客场或中立场为 0 |
| 队伍比赛强度 | `team_match_strength` | float | MVP ~1–120；Alpha ~1–130 | 本场比赛己方阵容的有效强度估值，允许设施修正后超过 100 |

**Output Range:** `lineup_base_strength` 接近 1–115，MVP `team_match_strength` 接近 1–120。超过 100 的队伍有效评分是合法的赛前修正结果，不得在进入 `base_win_probability` 前钳制；最终胜率由 `[0.05, 0.95]` clamp 保留爆冷与失手空间。  
**Ownership:** 本系统拥有 `lineup_weight`、`chemistry_factor` 和 `facility_rating_bonus` 接入规则；`positional_overall_rating` 引用数值系统公式，MVP `home_advantage_bonus` 引用小镇建设系统公式。`adj_stadium_home_bonus` 仅为 Alpha 预留，不参与 MVP 强度计算。

### 2. 实际胜率

`actual_win_probability` 在共享基准胜率上叠加比赛内修正：

`actual_win_probability = clamp(base_win_probability + home_advantage_mod + tactical_match_mod + condition_mod + skill_trait_match_mod + event_mod, 0.05, 0.95)`

`snapshot_eligible = pre_match_skill_trait_snapshot exists AND pre_match_skill_trait_snapshot.settlement_id == match_settlement_id AND pre_match_skill_trait_snapshot.schema_contract == shallow_typed_records AND all locked lineup players have one context_modifier_summary row where context_id = match`

`skill_trait_snapshot_status = applied_locked_snapshot when snapshot_eligible = true; else missing_safe_default or version_mismatch_safe_default`

`skill_trait_match_mod = 0 when skill_trait_snapshot_status != applied_locked_snapshot; else clamp(team_skill_trait_summary.team_modifier_milli / 1000, 0.00, skill_trait_match_mod_cap)`

`weighted_skill_match_modifier_milli = floor(Σ(player_skill_match_modifier_milli_i × lineup_weight_milli_i) / max(1, Σ(lineup_weight_milli_i)))`

`team_skill_trait_summary.team_modifier_milli = 0 when skill_trait_snapshot_status != applied_locked_snapshot; else min(skill_trait_match_mod_cap_milli, weighted_skill_match_modifier_milli)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 基准胜率 | `base_win_probability` | float | 0.05–0.95 | 来自数值系统共享公式，基于双方 `team_match_strength` 差与 `rating_win_slope`。`team_match_strength` 包含小镇建设系统 `home_advantage_bonus` 的评分加成 |
| 主场修正 | `home_advantage_mod` | float | 0.00–0.08 | 非设施主场优势（球迷气氛、场地熟悉度等）带来的概率层修正。设施侧主场优势只通过 `facility_rating_bonus` 注入 `team_match_strength`，不得在此项重复计算 |
| 战术匹配修正 | `tactical_match_mod` | float | -0.10–+0.10 | 己方战术克制或被克制时的修正 |
| 状态修正 | `condition_mod` | float | -0.08–+0.08 | 球员集体状态、体能、士气带来的综合修正 |
| 技能/特性快照资格 | `snapshot_eligible` | bool | true/false | 只有快照存在、`settlement_id` 等于本场预分配 `match_settlement_id`、schema 满足浅层 typed records，且所有锁定首发都有 `context_id = match` 的 `context_modifier_summary` row 时为 true |
| 技能/特性比赛修正 | `skill_trait_match_mod` | float | 0.00–+0.08 | Alpha 阶段只能从本系统锁定的 `team_skill_trait_summary.team_modifier_milli` 派生；无快照、安全默认快照或版本不匹配安全默认时为 0，不得复用训练倍率或技能系统内部 混合后的上下文修正字段。特性在 Alpha 只贡献解释摘要，不进入该数值修正 |
| 事件修正 | `event_mod` | float | -0.05–+0.05 | 关键事件（红牌、伤病、逆转势头等）的动态修正 |
| 队伍技能/特性摘要 | `team_skill_trait_summary` | typed dictionary | top-level shallow wrapper | 比赛系统赛前锁定的团队级技能/特性 wrapper，只消费技能系统只读快照中 `context_id = match` 的浅层记录后生成，不持有 live player state；安全默认时 `team_modifier_milli = 0` |
| 本场比赛结算 ID | `match_settlement_id` | string | stable id | Match Confirmation 预分配并写入结果包的稳定比赛结算 ID；用于绑定赛前快照与赛后技能/特性消费事实 |
| 球员技能比赛修正定点值 | `player_skill_match_modifier_milli_i` | int | 0–80 | 单名首发球员在本场上下文中的技能比赛层修正，来自锁定快照摘要中 `context_id = match` 的 `player_skill_match_modifier_milli` |
| 阵容权重定点值 | `lineup_weight_milli_i` | int | 100–1000 | 由 `lineup_weight_i × 1000` 转换并向下取整的千分定点权重，用于避免跨系统 float handoff |
| 加权技能比赛修正 | `weighted_skill_match_modifier_milli` | int | 0–80 | 按 `lineup_weight_milli_i` 加权后向下取整的队伍级技能比赛修正 |
| 技能/特性比赛修正上限 | `skill_trait_match_mod_cap` | float | 0.08 | 技能在胜率公式中的总上限；名称保留为比赛系统 wrapper，便于继续承接特性解释摘要 |
| 技能/特性比赛修正上限定点值 | `skill_trait_match_mod_cap_milli` | int | 80 | 与 `skill_trait_match_mod_cap` 对应的千分定点上限 |
| 技能/特性快照状态 | `skill_trait_snapshot_status` | enum | `applied_locked_snapshot` / `missing_safe_default` / `version_mismatch_safe_default` | 比赛结果包输出的快照消费状态；非 `applied_locked_snapshot` 时技能/特性比赛修正固定为 0 |
| 实际胜率 | `actual_win_probability` | float | 0.05–0.95 | 叠加所有修正后的本场比赛胜率 |

**Output Range:** 0.05–0.95；永远不为 0 或 1，保留爆冷空间。边界对齐数值系统的共享胜率上下限 [0.05, 0.95]。  
**Ownership:** 本系统拥有所有叠加修正项的定义与范围；`base_win_probability` 引用数值系统公式。`team_skill_trait_summary` wrapper 与 `skill_trait_match_mod` 推导由比赛系统拥有，技能与特性系统只提供赛前只读 read model；任何系统不得在比赛中从 live player state 或训练 read model 重算技能比赛修正、特性解释摘要或候选状态。

### 3. 关键事件产量

`key_event_count` 控制一场比赛产生多少可读关键事件：

`key_event_count = clamp(floor(base_event_rate × match_pace_factor × intensity_factor), min_events, max_events)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 基础事件率 | `base_event_rate` | float | 4–10 | 标准比赛预计产生的事件数（调参项） |
| 节奏因子 | `match_pace_factor` | float | 0.7–1.3 | 由战术选择与双方风格决定的比赛节奏 |
| 强度因子 | `intensity_factor` | float | 0.8–1.2 | 由比赛重要性（普通联赛/关键淘汰赛）决定的强度 |
| 最小事件数 | `min_events` | int | 3 | 保证比赛不空泛说明 |
| 最大事件数 | `max_events` | int | 15 | 防止信息过载 |
| 关键事件产量 | `key_event_count` | int | 3–15 | 本场比赛实际产生的关键事件总数 |

**Output Range:** 3–15。  
**Ownership:** 本系统完全拥有。

### 4. 赛后成长机会标签

`post_match_growth_tag` 为每名出场球员输出结构化成长线索：

`post_match_growth_tag = classify_match_exposure(player_match_minutes, player_performance_score, opponent_strength_level)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 出场时间 | `player_match_minutes` | int | 0–90 | 球员本场实际上场时间 |
| 表现评分 | `player_performance_score` | float | 1.0–10.0 | 系统根据位置贡献、关键事件参与等计算的本场表现 |
| 对手强度等级 | `opponent_strength_level` | float | 1–100 | 对手 `team_match_strength` |
| 赛后成长机会标签 | `post_match_growth_tag` | enum | {无, 轻度, 常规, 显著, 突破性} | 供培养系统决定赛后成长或激励 |

**Output Range:** 五个离散标签之一。  
**Ownership:** 本系统拥有标签分类逻辑；标签的实际成长落实由培养系统 `training_actual_gain` 或后续成长接口处理。

### Formula Ownership Notes

- `base_win_probability`、`positional_overall_rating`、`rating_win_slope` 不在本系统中重新定义；本系统只在其上叠加比赛层修正与聚合逻辑。
- `team_match_strength` 是本系统拥有的聚合公式；其他系统如需引用"队伍强度"语义，应引用本系统此公式。
- `post_match_growth_tag` 标签是比赛系统的输出端接口，不是成长系统本身。标签到实际属性成长的映射由培养系统拥有。
- 如果后续联赛系统、事件系统或 UI 系统需要改写比赛修正项范围或关键事件分类，必须先回到本系统修订。

## Edge Cases

- **If 比赛节点触发时无可出场球员（全员伤病/不可用）**: 系统不得进入半场演算；必须生成 `forfeit_result_packet`，默认比分 0–3、结果为负、原因标签为 `forfeit_no_available_players`，并交给联赛、经济和时间系统继续结算。
- **If 赛前阵容无法填满最低合法位置数（例如门将缺失）但仍有可出场球员**: 系统先尝试推荐阵容和错位补位；错位球员按 `positional_overall_rating` 承受位置折损并允许开赛。只有当可出场人数仍低于最低比赛人数时，才生成 `forfeit_result_packet`，不得停留在不可继续的比赛入口。
- **If 玩家未做任何赛前调整直接采用推荐阵容进入比赛**: 系统必须视为合法阵容；推荐阵容的强度可在默认水平，但不得因"玩家没手动调整"而惩罚比赛结果。赛前界面不得把采用推荐阵容包装成低质量或偷懒选择。
- **If `chemistry_factor` 因频繁轮换或多名新球员同时出场而降至极低值**: 比赛仍可正常进行，但系统必须在赛前与赛后反馈中让玩家理解队伍配合度明显影响了表现。
- **If `base_win_probability` 已接近 0.95 或 0.05 但叠加修正后 `actual_win_probability` 超出 clamp 边界**: 由 clamp 强制约束回 0.05–0.95；超出部分不累积也不保留。边界值与数值系统共享胜率上下限一致。
- **If 一场比赛双方 `team_match_strength` 完全相同且战术/状态对等**: `base_win_probability = 0.50`，实际结果分布应接近均等，但关键事件的随机性仍可导致任一方获胜。
- **If 中场调整时玩家替换了一名上半场表现极佳的主力球员**: 下半场必须使用新上球员的能力参与演算；上半场数据不得由于该球员离场而被回退或修改。
- **If 比赛过程中关键事件产量 `key_event_count = min_events`（比赛极为沉闷）**: 系统仍必须输出至少 3 个可读关键事件，并在赛后复盘时明确说明比赛节奏偏慢/双方保守的原因。
- **If `Match In Progress` 期间玩家异常退出（崩溃/强制关闭）**: 系统不得把当前半场中未终了的状态写入标准存档；恢复后应回到 Pre-Match Preparation 或最近可恢复节点，而不是强行从中断处接续。
- **If 比赛结果为平局且后续赛事系统需要分出胜负（如淘汰赛）**: 比赛系统本身不拥有加时/点球规则；这部分由后续联赛与赛事结构系统定义。MVP 阶段平局直接作为合法终场结果产出。
- **If 一名球员本场获得 `post_match_growth_tag = 突破性` 但同时培养系统判定其已触及 `potential_cap`**: 标签作为输入传递至培养系统；培养系统有权将成长量钳制为 0 并反馈"已达到当前上限"；比赛系统不得绕过该约束直接写入属性成长。
- **If 对手数据无法由联赛/赛事系统正常提供（如系统异常或数据不可用时）**: 比赛系统应使用 `default_opponent_profile` 作为降级后备对手模板，该模板参数由本系统 Tuning Knobs 中的对手难度调参项控制，确保比赛演算不阻塞。联赛系统正常运作时，对手数据优先使用联赛系统提供的真实对手数据。
- **If 一场比赛的关键事件产出集中在某几名球员身上（例如所有进球都由一名前锋包揽）**: 系统应允许集中表现存在，但事件类别分布不应全部是同类型事件堆叠；至少应在进攻、防守、战术等类别间有合理占比。
- **If 比赛后球员状态变化与培养系统已有状态冲突（例如比赛系统输出"疲劳"但培养系统当前为"健康"）**: 冲突不得静默覆盖；统一以时间线顺序处理——比赛系统先写回状态标签，培养系统在下一轮结算时消费并合并。
- **If 同一比赛节点被重复触发（例如时间推进异常）**: 比赛系统必须在赛前检查该比赛节点是否已有已确认结果包，若有则直接跳至 Result Review 或 Settlement Handoff，不得重赛。
- **If 玩家在 Pre-Match Preparation 中反复进出而不确认开赛**: 系统应允许无限次退出返回，但不得因为进出重置阵容/战术而产生额外消耗或无成本重试漏洞。
- **If 玩家先在自由赛前编辑态看到"非法阵容不可手动开赛"，随后同一比赛节点进入不可跳过的强制触发态**: 本系统必须继续执行推荐阵容、错位补位或 `forfeit_result_packet` 兜底；不得因 UI 之前的禁用状态而让同一比赛节点进入不可推进状态。
- **If `post_match_growth_tag` 输出为 `无` 且球员出场时间 < 5 分钟**: 视为正常——极短出场时间无需产出成长机会。
- **If `post_match_growth_tag` 输出为 `无` 而球员打满全场且表现评分不低**: 视为异常信号；应将此球员标记为需要复核，但不得阻止比赛结果正常产出。
- **If 赛前技能/特性快照缺失、版本不匹配、`settlement_id` 不等于本场 `match_settlement_id`、payload 不满足浅层 typed contract，或任一锁定首发缺少 `context_id = match` 的 `context_modifier_summary` row**: 正式比赛仍可使用无技能/特性修正的安全快照继续演算，`team_skill_trait_summary.team_modifier_milli = 0`，结果包必须标记 `skill_trait_snapshot_status = missing_safe_default` 或 `version_mismatch_safe_default`，供赛后排查；不得在比赛中读取 live player state、训练 read model 或特性解释摘要临时重算。
- **If 比赛中或赛后发现某球员满足技能解锁/升级或特性新增条件**: 比赛系统只能把相关稳定事实写入结果包，交由技能与特性系统在 `Settlement Handoff` 后消费；不得在比赛系统内直接改写技能/特性状态。
- **If 比赛系统被要求在 MVP 阶段支持友谊赛/训练赛/热身赛等非正式比赛**: 本系统预留非正式比赛模式入口，但 MVP 阶段默认只实现正式联赛/杯赛比赛。非正式比赛可在不修改核心演算逻辑的前提下，通过不同 `intensity_factor` 与事件分布区分行为。
- **If 比赛结算完成但尚未到达时间系统稳定存档节点**: 已确认的比赛结果包视为已锁定；时间系统推迟存档时比赛结果不丢失，也不重复结算。

## Dependencies

比赛竞技系统位于 Core 层，是《足球小镇》MVP 双核循环中的竞技验证轴。它承接 Foundation 层的时间、数值与存档规则，消费运动员培养系统的成长结果，产出可被下游联赛、UI、音频和引导系统消费的单场比赛结果。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 概念文档将"比赛竞技"定义为核心双循环之一，并要求低压力、可读反馈 | 核心幻想、低压力基调、培养→比赛→反馈闭环 |
| `design/gdd/systems-index.md` | Hard | 定义了本系统在 Core/MVP 的位置及依赖方向 | 系统层级、优先级、上下游系统列表 |
| `design/gdd/balance-system.md` | Hard | 定义五维属性、`effective_attribute_value`、`positional_overall_rating`、`base_win_probability`、`rating_win_slope` | 共享属性定义、共享基准公式、合法数值边界 |
| `design/gdd/time-and-season-progression-system.md` | Hard | 定义比赛节点触发 (`match_trigger_reached`)、赛后结算时间点、赛季推进节奏 | 比赛节点触发信号、Post-Match Settlement 节点语义、阶段推进接口 |
| `design/gdd/save-and-load-system.md` | Hard | 定义稳定存档边界和 `Match In Progress` 非标准可恢复节点规则 | 比赛前可恢复节点、终场后落档时机、异常退出恢复策略 |
| `design/gdd/player-development-system.md` | Hard | 提供球员当前能力、状态标签、位置适配倾向和可用性，并接收赛后成长机会标签 | 球员可比赛消费字段、`training_actual_gain` 接口、赛后状态写入接口 |
| `design/gdd/skill-and-trait-system.md` | Hard (Alpha) | 提供赛前只读技能/特性效果快照，并在赛后消费稳定比赛事实形成技能/特性进度、触发解释或身份记录 | `pre_match_skill_trait_snapshot`、聚合技能修正、已拥有特性摘要；比赛系统输出 `settlement_id`、关键事件、位置表现、表现标签和快照状态 |
| `design/gdd/town-building-system.md` | Soft | MVP 最小可见支撑切片提供小幅 `home_advantage_bonus`（作为 `facility_rating_bonus` 注入 `team_match_strength`，上限 5）；`adj_stadium_home_bonus` 和 `stadium_revenue_multiplier` 在 MVP 不作为硬消费合同 | 主场赛前评分计算时接收小幅被动设施评分加成；设施修正只进入强度层，不得在 `home_advantage_mod` 概率层重复计算 |
| 联赛与赛事结构系统 | Hard (packet contract) | 通过 `match_context` 提供对手来源、主客场、轮次、赛事类型、比赛重要性和赛制约束；通过 `match_result_packet` 消费比赛系统产出的已确认单场结果 | `league -> match_context`：对手数据、主客场、轮次、比赛重要性；`match -> match_result_packet`：胜/平/负、比分、主客结果、关键事件摘要、`forfeit_result_packet` |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 比赛竞技系统 | What must be back-referenced later |
|---|---|---|---|
| 联赛与赛事结构系统 | Hard (packet contract) | `match_result_packet`：胜/平/负、比分、主客结果、关键事件摘要、结果类型、弃权结果包 | 必须声明积分、晋级、赛程编排只消费本系统输出的已确认结果包，不直接调用比赛内部演算状态 |
| `design/gdd/economy-management-system.md` | Hard | 比赛结果包、胜/平/负结果、评分/奖励口径、赛后结算标签与其他赛后结算数据 | 必须声明其赛后奖励、经费结算和资源变化如何消费本系统输出的结果包 |
| `design/gdd/player-management-ui.md` | Soft | 球员赛后成长标签、表现评分、出场时间和详情页补充展示数据 | 必须声明其球员详情页和赛后反馈展示如何消费本系统输出的球员级赛后数据 |
| 比赛表现 UI | Hard | 赛前阵容字段、战术字段、关键事件流、终场摘要、复盘原因标签 | 必须声明 UI 展示内容与本系统定义的事件类别、状态表和反馈标签一致，且在正式比赛强制触发态下不得阻塞本系统的非法阵容兜底流程 |
| 音频系统 | Soft | 进球、扑救、逆转、终场等高情绪节点事件 | 必须声明音频触发时机和事件优先级与本系统输出对齐 |
| 新手引导系统 | Hard | 玩家需要理解的最小比赛概念和操作流程 | 必须声明首场比赛引导的目标概念与本系统定义的赛前/赛中/赛后状态一致 |
| 运动员培养系统 | Hard (回传) | 出场摘要、比赛负荷、状态变化、赛后成长机会标签 | 必须声明赛后回传数据如何被消费，而不是由比赛系统直接写入长期属性 |
| 技能与特性系统 | Hard (Alpha) | `settlement_id`、关键事件、位置表现、球员表现标签、出场摘要、`skill_trait_snapshot_status` | 必须声明其只在稳定结算节点消费比赛事实，不要求比赛系统在比赛中重算技能/特性资格 |
| 主循环 UI 框架 | Hard | 比赛状态、关键事件流、结果包、赛后标签——供 Match Center 各阶段（赛前/赛中/赛后）的导航与信息展示 | 必须声明其 Match Pre/Match Live/Match Result 容器消费本系统定义的状态机和事件流 |

### Dependency Rules

1. 比赛竞技系统负责"阵容如何变成比赛表现、比赛结果如何反馈给玩家和下游"，不负责"共享属性是否合法""比赛何时发生""赛后状态如何持久化"或"球员长期属性如何增长"；这些边界必须分别服从上游 Foundation 和培养系统。
2. 任何下游系统若希望新增比赛阶段、改变胜率修正范围、扩展关键事件类别或新增赛后标签，必须先回到本系统修订，而不能在本地 GDD 静默覆盖。
3. UI、音频、引导等系统可以消费比赛状态和事件，但不能各自定义一套独立的比赛规则或状态机。
4. 联赛与赛事结构系统、经济管理系统和主循环 UI 框架的依赖为 Hard——比赛结果包是联赛积分/排名、赛后经济结算和 Match Center 导航展示的核心数据源。球员管理 UI 依赖为 Soft——球员详情页在无比赛数据时仍可用，不阻塞核心功能。技能与特性系统在 Alpha 阶段为 Hard 依赖，因为它提供赛前只读效果快照并消费赛后稳定比赛事实。相关系统均必须在各自 GDD 的 Dependencies 中反向声明对本系统的依赖。
5. 比赛系统不得直接写入技能等级、技能进度、特性状态、候选进度或技能/特性反馈；它只能消费 `pre_match_skill_trait_snapshot`，并在终场结果包中输出带 `settlement_id` 的稳定事实供技能与特性系统后续处理。
6. 如果某个系统只展示比赛结果而不改变比赛状态或规则，则它对本系统属于软依赖；如果某个系统会触发、改变、消费或持久化比赛状态，则属于硬依赖。
7. 比赛系统与联赛系统之间必须实现为 packet contract，而不是具体运行时互相调用：联赛系统在赛前提供 `match_context`，比赛系统在终场后返回 `match_result_packet`；联赛系统不得读取比赛内部半场状态，比赛系统不得直接写入积分榜、排名、晋级或赛程状态。
8. 在 MVP 阶段，比赛表现 UI 和新手引导系统是最关键的承接者；它们必须优先验证玩家能否看懂"为什么这场比赛会这样、赛前我做了什么重要的事"。

## Tuning Knobs

本节仅包含比赛竞技系统拥有的共享调参项。它们控制的是"比赛节奏、胜率修正幅度、事件密度、化学因子边界和阵容强度感"，不包含共享属性范围、赛季长度、球员训练效率或 UI 布局。

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 阵容权重分布 `lineup_weight_profile` | 不同阵型下各位置的贡献权重 | 各位置 0.1–1.0 | 某位置权重过高，阵容选择退化为最优位置堆砌 | 权重过于平均，阵型选择失去策略意义 | 阵型策略感、阵容多样性 |
| 化学修正范围 `chemistry_factor_band` | 球员间适配度对 `team_match_strength` 的影响幅度 | 0.85–1.15 | 化学波动过大，球队强度忽高忽低缺乏可预期性 | 化学因子无感，轮换/适配失去代价 | 阵容搭配深度、可预期性 |
| 主场修正 `home_advantage_mod` | 主场优势对胜率的提升幅度 | 0.00–0.08 | 主场优势压倒战术和阵容差异 | 主场感不足，场地选择失去意义 | 主场价值感、比赛节奏 |
| 战术匹配修正范围 `tactical_match_mod_band` | 战术克制/被克制对胜率的影响幅度 | -0.10–+0.10 | 战术克制幅度过大，赛前选择感被扭曲为一局定胜负 | 战术差异不明显，削弱赛前决策价值 | 战术选择意义、赛前策略深度 |
| 状态修正范围 `condition_mod_band` | 球员集体状态对胜率的影响幅度 | -0.08–+0.08 | 状态波动主导比赛，阵容培养感被掩盖 | 状态管理无意义，赛前体能/士气调整失去反馈 | 状态管理价值、低压力平衡 |
| 事件修正范围 `event_mod_band` | 关键事件对胜率的动态修正幅度 | -0.05–+0.05 | 单次事件足以逆转强弱势差，阵容培养积累感丢失 | 关键事件无感，比赛失去戏剧性 | 爆冷空间、比赛叙事感 |
| 实际胜率 clamp 范围 `actual_win_probability_clamp` | 比赛结果确定性边界 | 下限 0.05 / 上限 0.95 | 上限过高 → 强队基本必赢；下限过低 → 弱队永远无希望 | 上限过低 → 强队太常翻车；下限过高 → 爆冷空间太小 | 对齐数值系统共享胜率上下限 [0.05, 0.95] |
| 基础事件率 `base_event_rate` | 标准比赛关键事件产出数量 | 4–10 | 事件过多，信息过载，比赛阅读负担重 | 事件过少，比赛显得空洞无物 | 比赛阅读节奏、反馈丰富度 |
| 节奏因子范围 `match_pace_factor_band` | 战术风格对事件频率的影响 | 0.7–1.3 | 快节奏战术永远产出最多事件，战术多样性被压缩 | 节奏区分不明显，攻守风格选择失去反馈 | 战术差异化、比赛观感 |
| 强度因子范围 `intensity_factor_band` | 比赛重要性对事件密度的影响 | 0.8–1.2 | 普通比赛太闷，玩家只等关键比赛 | 所有比赛同质化，无重要性区分 | 重要比赛的特殊感 |
| 最小/最大事件数 `min_events` / `max_events` | 单场比赛关键事件的硬边界 | min 3 / max 15 | max 过高 → 信息过载；min 过低 → 比赛太空 | max 过低 → 限制戏剧性；min 过高 → 强行塞事件 | 比赛反馈密度边界 |
| 表现评分范围 `player_performance_score_band` | 球员单场表现评分上限 | 1.0–10.0 | 上限过高 → 评分通胀，区分度下降 | 范围过窄 → 球员差异体现不足 | 赛后反馈精度、球员比较感 |
| 对手模板 `default_opponent_profile` | 联赛系统异常或不可用时的降级后备对手参数 | `team_match_strength` 30–50（对齐最低级联赛 Tier 1 区间） | 对手过强 → 比赛体验挫败；过弱 → 比赛无挑战 | 无对手 → 比赛演算阻塞 | 降级可用性、测试灵活性 |
| 赛后成长标签分布 `post_match_growth_tag_distribution` | 五类成长标签的出现频率分布 | 常规 > 轻度 > 显著 > 突破性 > 无 | 突破性太频繁 → 成长过快失去节奏；无标签太多 → 比赛对成长无反馈 | 标签太保守 → 比赛后成长感不足 | 赛后成长反馈频率、培养节奏衔接 |
| 中场调整上限 `halftime_adjustment_limit` | 中场可调整的人数或幅度上限 | 替换 0–3 人 | 调整过少 → 中场窗口沦为形式 | 调整过多 → 削弱赛前阵容选择的重要性 | 赛前与赛中的策略权重分配 |

## Acceptance Criteria

- **GIVEN** 时间系统触发一场正式比赛节点，**WHEN** QA 检查比赛入口，**THEN** 玩家必须能进入 Pre-Match Preparation 并看到对手摘要、己方可用阵容及推荐方案。
- **GIVEN** 玩家进入 Pre-Match Preparation，**WHEN** QA 统计比赛系统要求玩家主动完成的赛前决策，**THEN** 必须限制为确认或轻调推荐阵容、选择战术方案、确认开赛；AP 补足、设施修正、技能/特性快照和联赛上下文不得成为额外必做决策。
- **GIVEN** 玩家在赛前不做任何手动调整，**WHEN** QA 直接采用推荐阵容和推荐战术开始比赛，**THEN** 系统必须视为合法阵容并正常进入演算，不得因"未手动调整"而阻塞或惩罚。
- **GIVEN** 正式比赛节点到达且首发阵容非法但仍有足够可出场球员，**WHEN** QA 触发开赛，**THEN** 系统必须自动推荐并错位补位，按位置适配折损进入演算；不得因缺少完美位置球员而阻塞。
- **GIVEN** 正式比赛节点到达且可出场人数低于最低比赛人数，**WHEN** QA 触发比赛处理，**THEN** 系统必须生成 `forfeit_result_packet`（默认 0–3 负场）并进入 Settlement Handoff，联赛和经济结算继续推进。
- **GIVEN** 一名球员被安排在非其偏好位置出战，**WHEN** QA 检查该球员的 `positional_overall_rating`，**THEN** 评分必须低于其偏好位置时的评分，且错位影响必须可在赛前预览中看到。
- **GIVEN** 双方阵容锁定并正式开赛，**WHEN** QA 观察上半场演算结果，**THEN** 上半场必须产出至少 1 个可读关键事件并展示临时比分。
- **GIVEN** 上半场结束进入中场调整，**WHEN** QA 替换一名上场球员或调整战术，**THEN** 下半场演算必须使用更新后的阵容和战术，且上半场已发生事件不被回溯修改。
- **GIVEN** 一场比赛完成两个半场演算，**WHEN** QA 检查终场结果，**THEN** 结果包必须包含胜/平/负、比分、关键事件摘要和至少一组胜负原因标签。
- **GIVEN** 双方 `team_match_strength` 存在明显差距（≥15 分），**WHEN** QA 以不同类型阵容反复测试同一场比赛，**THEN** 强队胜率应显著高于弱队，但弱队仍有非零胜率（爆冷空间存在）。
- **GIVEN** 玩家在赛前选择克制对手的战术，**WHEN** QA 与选择被克制战术对照测试，**THEN** 克制方 `actual_win_probability` 必须明显高于被克制方（其他条件不变时）。
- **GIVEN** 比赛进行中玩家异常退出（模拟崩溃），**WHEN** QA 重新进入游戏，**THEN** 终场结果不得已被静默写入存档；玩家应回到最近可恢复节点。
- **GIVEN** 一场比赛终场确认后，**WHEN** QA 检查赛后数据，**THEN** 每名出场球员必须获得 `post_match_growth_tag`（五个标签之一）和出场时间记录。
- **GIVEN** Alpha 阶段技能与特性系统已启用，**WHEN** QA 锁定赛前阵容并进入比赛，**THEN** 比赛系统必须预分配本场 `match_settlement_id`，只在 `pre_match_skill_trait_snapshot.settlement_id` 与该值一致、payload 满足浅层 typed contract、且所有锁定首发都有 `context_id = match` 的 `context_modifier_summary` row 时，消费只读技能比赛修正与特性解释摘要，将 `player_skill_match_modifier_milli` 加权生成的 `team_modifier_milli` 作为 `skill_trait_match_mod` 接入实际胜率公式，不得在比赛中读取 live player state 重算资格或效果；特性摘要只能用于解释，不得改变胜率。
- **GIVEN** 一场比赛终场确认后，**WHEN** QA 检查结果包，**THEN** 结果包必须包含稳定 `settlement_id`、`skill_trait_snapshot_status`、关键事件、位置表现、球员表现标签和给技能与特性系统消费的 `confirmed_facts[]`；每名出场球员的事实至少包含 `match_minutes_band`、`position_role_played`、`role_coverage_count`、`low_error_tag_count`、`post_match_growth_tag`、`player_performance_band`、稳定 `source_event_id` 与 `fact_order`。
- **GIVEN** 赛前技能/特性快照缺失、版本不匹配、payload 非浅层 typed contract、`settlement_id` 不等于本场 `match_settlement_id`，或锁定首发缺少 `context_id = match` 的 row，**WHEN** 正式比赛进入安全默认演算，**THEN** 结果包的 `skill_trait_snapshot_status` 必须为 `missing_safe_default` 或 `version_mismatch_safe_default`，`team_skill_trait_summary.team_modifier_milli = 0` 且 `skill_trait_match_mod = 0`；不得在赛中或赛后回读 live state、训练 read model 或特性解释摘要补算技能效果。
- **GIVEN** 比赛过程中或赛后事实满足某技能/特性条件，**WHEN** QA 检查比赛系统写入行为，**THEN** 比赛系统不得直接写入技能等级、技能进度、特性状态或反馈记录，只能输出稳定事实给技能与特性系统。
- **GIVEN** 一名球员 `potential_cap` 已触及且获得 `post_match_growth_tag = 突破性`，**WHEN** QA 在培养系统中检查该球员成长结算，**THEN** 培养系统应将成长钳制为 0 并反馈"已达上限"；比赛系统不得绕过此约束直接写入属性。
- **GIVEN** 同一比赛节点被重复触发，**WHEN** QA 检查比赛系统响应，**THEN** 若该节点已有已确认结果包，比赛系统应直接展示已有结果，不得重赛。
- **GIVEN** 联赛系统正常运作并提供对手数据，**WHEN** QA 触发一场比赛，**THEN** 系统应使用联赛系统提供的对手数据；**GIVEN** 联赛系统不可用，**WHEN** QA 触发比赛，**THEN** 系统必须降级使用 `default_opponent_profile`（30–50）生成对手，比赛演算不得阻塞。
- **GIVEN** 玩家连续进行多场比赛，**WHEN** QA 检查赛后反馈内容，**THEN** 每场比赛的复盘原因标签必须随阵容、战术和实际表现变化而变化，而非固定输出相同文本。
- **GIVEN** 一场比赛的 `key_event_count = min_events`，**WHEN** QA 检查比赛反馈，**THEN** 系统仍需输出至少 3 个可读事件，且复盘应说明比赛沉闷原因。
- **GIVEN** 明星球员与普通球员在同类位置出战同一场比赛，**WHEN** QA 比较两者本场表现评分与关键事件参与，**THEN** 明星球员应表现出更高的上限可能（不保证每场都更优，但分布上限更高）。
- **GIVEN** 玩家频繁轮换首发阵容导致 `chemistry_factor` 偏低，**WHEN** QA 检查赛前与赛后反馈，**THEN** 系统必须提示队伍配合度影响了表现。
- **GIVEN** MVP 版本未实现加时/点球/淘汰赛规则，**WHEN** QA 检查一场平局比赛的结果，**THEN** 平局直接作为合法终场结果产出，不阻塞后续流程。
- **GIVEN** QA 在新档中连续经历"赛前准备 → 上半场 → 中场调整 → 下半场 → 结果确认 → 赛后反馈"完整流程，**WHEN** 检查体验完整性，**THEN** 玩家必须能在低压力下完成全部流程，并在赛后理解"为什么这场比赛会这样"。
- **GIVEN** 下游系统尝试直接改写本系统定义的胜率修正范围或关键事件分类，**WHEN** QA 检查修改来源，**THEN** 这些变更必须只能通过本系统正式接口生效，绕过比赛系统的改写不得视为有效。
