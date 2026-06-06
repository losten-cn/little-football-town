# 足球小镇：技能与特性系统

> **Status**: Approved  
> **Author**: 用户 + Claude  
> **Last Updated**: 2026-06-03  
> **Implements Pillar**: 低压力长期成长、轻度足球经营、球员养成差异化  
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/balance-system.md`
> - `design/gdd/player-development-system.md`
> - `design/gdd/match-competition-system.md`
> - `design/gdd/reputation-and-achievement-system.md`
> - `design/gdd/save-and-load-system.md`

## Overview

技能与特性系统是《足球小镇》中负责把“球员成长”转化为“球员风格”的长期差异化层。它建立在运动员培养系统已经确认的属性成长、潜力阶段、训练结果和比赛经历之上，将部分长期成长事实沉淀为可识别、可持久化、可展示的技能、特性和风格标签，让玩家不仅看到球员数值提升，也能逐渐记住“这个人擅长什么、倾向怎样、为什么值得继续培养”。

本系统位于 Alpha 层，用于扩展 MVP 已验证的培养 → 比赛 → 反馈 → 再培养循环。它不取代运动员培养系统的基础成长，不拥有比赛竞技系统的胜负演算，也不直接修改经济或声望奖励；它只定义哪些长期成长结果可以成为技能或特性，以及这些技能/特性如何以轻量、可解释、低压力的方式影响训练反馈、比赛表现和球员身份感。Alpha 首版采用小池验证：6 个技能、5 个特性、明确家族上限、稳定结算键和统一反馈顺序，目标是验证“球员是否更有记忆点”，而不是建立复杂 RPG build 或最优解路线。

## Player Fantasy

玩家在技能与特性系统中应感受到的，不是“我给球员装了一套最优 build”，而是“这些球员正在因为训练、比赛和经历逐渐变得不一样”。当玩家回看一名培养了多个赛季的球员时，应能自然说出类似这样的判断：他是关键时刻靠得住的人、他很适合控球组织、他虽然成长慢但很稳定、他总能在主场比赛里表现更好。技能与特性应让球员从一组属性数字，变成玩家愿意记住、偏爱和继续投入的个体。

这种幻想必须保持轻松、温和和可解释。玩家不应该为了追逐完美特性组合而焦虑，也不应该觉得某个随机负面特性毁掉了一个球员。好的技能与特性反馈应像“成长痕迹”而不是“强制配装”：它让玩家更容易理解球员风格，更愿意讲述球队故事，也更容易接受不同球员有不同价值；但它不应取代基础属性、阵容位置、战术选择或比赛结果成为唯一正确答案。

本系统的反模式是：把技能做成必须查表优化的 build 树、把特性做成随机惩罚词条、让玩家为了刷完美组合而重复读档，或让技能/特性强到压过属性、阵容和战术。Alpha 首版必须优先证明“成长痕迹能被理解和记住”，而不是证明“玩家可以优化出最强组合”。

## Detailed Rules

### Core Rules

1. **技能与特性系统是球员长期差异化表达的权威来源。**  
   它负责定义哪些技能、特性和风格标签存在，如何解锁、升级、触发、持久化和展示。其他系统可以提供训练、比赛或成长事实，但不得自行定义另一套球员技能/特性体系。

2. **技能是可成长能力，特性是稳定倾向。**  
   - **技能（Skill）**：偏向可训练、可解锁、可升级的能力模块，例如稳定传球、防守站位、门前嗅觉。  
   - **特性（Trait）**：偏向球员个性、风格或长期倾向，例如大场面球员、慢热型、团队核心。  
   两者都用于增强球员身份感，但不得混成无边界的通用加成标签。

3. **本系统只消费已确认成长事实，不拥有基础成长事实。**  
   基础属性成长、潜力阶段、训练结果、比赛表现和赛后标签仍由运动员培养系统与比赛竞技系统拥有；本系统只判断这些事实是否足以形成技能、特性或相关进度。

4. **技能/特性不得替代基础属性、阵容位置和战术选择。**  
   技能/特性可以提供轻量修正、触发标签或表现解释，但不得成为比赛胜负的单一主因，也不得让低属性但堆叠正确技能的球员稳定压过基础培养和合理阵容。

5. **Alpha 首版采用小池验证。**  
   首版内容池固定为 6 个技能和 5 个特性。它不要求大型技能树、复杂 build 路线、主动技能释放、随机词条刷取、特性重铸或高压最优组合追求。首版成功标准是玩家能记住少数球员的风格差异。

6. **技能/特性必须使用家族上限控制组合压力。**  
   每名球员最多拥有 3 个技能，其中同一技能家族最多 1 个主技能；每名球员最多拥有 2 个特性，其中最多 1 个核心身份特性和 1 个情境标签特性。超过上限时，新进度仍可记录为候选进度，但不得自动挤掉已拥有内容。

7. **技能/特性解锁与升级必须发生在稳定结算节点。**  
   训练中途、比赛进行中或未确认事件不得即时改变技能/特性状态。合法结算点包括训练结算、赛后结算、阶段结算或其他由时间/存档系统认可的稳定节点。

8. **所有技能/特性变化必须幂等且排序确定。**  
   同一稳定结算事实必须通过稳定结算键去重。稳定结算键由 `settlement_id + player_id + consumer_scope + rule_id` 组成，其中 `consumer_scope` 区分 `skill_progress`、`skill_unlock`、`skill_upgrade`、`candidate_progress`、`trait_add`、`trait_trigger_effect`、`trait_trigger_visible`、`trait_changed` 和 `feedback_ack`。`rule_version` 是随结果保存的规则元数据，不参与幂等键源，避免旧结算在规则迁移或恢复重放后被当作新事实重复消费。同一键重复进入系统时，不得重复解锁、重复升级、重复添加特性、重复改写特性、重复记录特性效果生效，或重复展示一次性反馈。稳定结算键必须由固定字段顺序的 canonical string 生成，不得直接对运行时 Dictionary、Resource 或 Variant 做引擎默认 hash。所有解锁裁决、候选裁决、反馈展示、身份历史回显和快照数组排序都必须使用本系统声明的全序比较器；所有用于排序或阶段分类的“比例”都必须先转换为定点整数（`*_rank_milli` 或 `*_progress_milli`），不得用二进制浮点值直接比较。若主要比较字段完全相同，必须继续比较稳定 ID，不得回退到资源表顺序、数组原始顺序、Godot Dictionary 遍历顺序或 signal 到达顺序。

9. **技能效果必须有明确适用场景。**  
   每个技能必须声明适用位置、训练类型、比赛上下文或战术条件。若当前场景不匹配，技能效果应降低或不生效，而不是无条件提供全局收益。

10. **特性应少变、可信、可解释。**  
    特性代表球员长期倾向，不应频繁随机变化。若后续允许特性新增、变化或移除，必须基于明确的长期成长原因，例如持续比赛表现、训练路线、关键比赛经历或阶段性成长节点。

11. **负面或限制性特性必须避免惩罚感。**  
    Alpha 首版不引入强负面特性。限制性特性只能表现为有取舍的中性倾向，例如“慢热型”在上半场解释为进入状态较慢、在长期培养中解释为后程稳定，而不是随机削弱球员价值。

12. **技能/特性反馈必须从属于主结算流。**  
    如果训练结果、比赛结果、声望成就和技能/特性变化同时发生，展示顺序固定为：核心训练/比赛结果 → 技能/特性变化与触发解释 → 声望增长/成就完成 → 其他奖励与提示。技能/特性反馈不得先于核心结果，也不得形成连续高压弹窗。

13. **技能/特性反馈是持久化领域数据，且确认语义必须全局唯一。**  
    待展示反馈必须保存为 `pending_skill_trait_feedback` 记录，包含稳定反馈键、球员 ID、变化类型、显示原因、来源结算、展示优先级、展示顺序、唯一首次展示归属面和确认状态。`feedback_key` 是领域事实主键，只能由 `settlement_id + player_id + change_type + subject_id` canonical 生成；`first_surface_id` 是展示路由字段，不得参与主键生成。UI 确认后写入 `feedback_ack`，读档后只展示未确认记录。`feedback_ack` 一旦写入即成为长期确认事实，不得因读档、回看比赛结果、首次展示面变更或迁移而重新弹出。`feedback_ack` 的确认范围是全局反馈键，不按界面拆分；`ack_surface_id` 只记录本次确认来自哪个展示面。Alpha 首版的首次展示归属面必须唯一且只允许两个新提示入口：赛后触发解释挂在 `Match Result`，训练/阶段成长变化挂在 `Main Loop`；`Player Detail` 永远只负责回看、补读和身份历史浏览，不拥有首次新提示权。

14. **技能/特性必须写入长期球员记忆。**  
    任何技能解锁、技能升级、特性新增、特性变化和被展示的关键触发，都必须写入球员详情可回看的 `player_identity_history`。历史记录至少包含发生时间/赛季、来源结算、触发原因、变化前后状态和玩家可读解释。普通球员也必须能通过可靠出勤、位置适配、训练稳定性、团队配合等事实形成身份记录，而不只依赖进球、关键比赛或高评分。

15. **技能/特性候选采用“身份痕迹”可见性，不得变成隐藏 build tracker。**  
    候选进度表示球员已经留下某种成长痕迹，不表示玩家正在推进一条可优化的解锁任务。玩家不直接看到精确阈值、内部点数、百分比、候选数量、候选排行或还差多少点，也不看到“接近解锁”这类任务化标签。球员详情默认只展示少量只读身份线索：`初现痕迹`、`稳定倾向`、`鲜明风格`、最近原因，以及“他正在表现出哪种风格”的短句说明。`candidate_progress_record`、`feedback_ack`、`attention_state`、`surface_state` 等实现字段不得直接暴露给玩家。Player Detail 默认每名球员最多展示 2 条候选摘要，按 `candidate_display_priority DESC → display_order ASC → subject_id ASC` 稳定筛选；其余候选只能折叠到“更多成长倾向”分组，折叠入口不得显示候选数量、排行或接近程度。若同家族槽位、总技能槽位或特性槽位阻止自动转正，UI 必须展示稳定的 `blocked_reason` 与低压力说明：该痕迹已被记录为另一条成长方向，而不是“快解锁但被卡住”。候选摘要默认不得显示可点击推荐操作、训练跳转、清单式下一步或任何行动按钮；如需解释方向，只能使用不可点击的 `context_hint_label_key` / `context_hint_label_args` 只读文案，不得建议玩家等待槽位、保护槽位、清槽、重铸、读档或停止培养。普通/弱势球员的 `trait_reliable_rotation` 若因核心身份槽位被占用而保留为候选，必须在展示预算内至少保留一条低压力提醒或折叠分组首条摘要，说明“稳定完成任务的身份倾向仍被记录”，但不得暗示玩家应清槽或追求最优组合。

16. **技能/特性必须可持久化、可迁移、可回显。**  
    已解锁技能、技能等级、技能进度、候选进度、特性状态、稳定结算键、解锁记录、`player_identity_history`、待展示反馈和迁移历史都属于长期球员状态。读档恢复后必须与保存前一致；旧版本技能/特性调整时必须使用稳定 ID 映射，而不是显示名、资源路径或数组顺序。

17. **技能/特性的最小持久化状态集合由本系统拥有语义。**  
    存档系统负责保存和恢复结构，但不得解释或重算技能/特性状态。Alpha 起，每名球员的最小持久化集合必须包含：已拥有技能 ID、技能等级、当前等级剩余进度、累计进度、技能规则版本、来源稳定结算键；`candidate_progress_record`；已拥有特性 ID、特性类型、来源稳定结算键、特性规则版本；特性可见触发冷却状态（`last_visible_feedback_settlement_id`、`settlements_since_last_visible_trigger`、`trait_visible_cooldown_window`）；`evaluated_settlement_keys`（所有已评估消费键，含 no-op，按字典序排序持久化的 `Array[String]`）；`processed_settlement_keys`（已产生 durable outcome 的消费键，按字典序排序持久化的 `Array[String]`）；`pending_skill_trait_feedback`；`feedback_ack`；`player_identity_history_entry`；技能/特性 ID 迁移历史和废弃 ID 映射记录。

18. **实现语义是确定性结算事务，不是常驻运行态。**  
    本系统的状态表描述结算阶段和持久化状态，不要求引擎中存在跨帧运行的技能状态机。实现时应由单一结算编排入口接收稳定事件，并在同一次事务内完成四个固定子阶段：`Collect Confirmed Facts` → `Evaluate Skill/Trait Outcomes` → `Build Durable Settlement Result` → `Atomic Commit Durable Result`。`Collect` 与 `Evaluate` 只存在于内存中的本次结算上下文，永不作为存档恢复点；每个被合法评估的消费键无论是否产生变化，都必须进入 `evaluated_settlement_keys`，用于读档重放、旧事实晚到和 no-op 防重；只有产生 durable outcome 的消费键才进入 `processed_settlement_keys`。技能/特性状态变化、`evaluated_settlement_keys`、`processed_settlement_keys`、`pending_skill_trait_feedback`、`feedback_ack` 种子、`player_identity_history_entry`、候选进度与特性冷却变化必须先组装成同一个 durable settlement result，再一次性提交。读档恢复只能看到整个 durable result 已完成，或完全看不到该 result；不得出现状态已生效但反馈、身份历史或处理键缺失的半提交状态。实现不得依赖 Godot signal 调用顺序。

### Alpha Initial Content Pool

Alpha 首版内容池用于验证风格记忆点，不作为最终完整名单。所有名称、数值和阈值都可在 Alpha 后调整，但家族、适用场景、触发解释和上限规则必须保持稳定。首版特性池为 5 个特性，其中 `trait_reliable_rotation` 专门服务普通/弱势球员的可靠性身份路径。

#### Skill Families and Skills

| Skill ID | Skill name | Family | Primary fantasy | Applicable contexts | Unlock source | Effect expression |
|---|---|---|---|---|---|---|
| `skill_stable_pass` | 稳定传球 | 组织家族 | 这个球员传球不花哨，但很少把节奏弄乱 | 中场/后场、控球或均衡战术、传球训练 | 多次传球相关训练或比赛中稳定组织表现 | 提供轻量控球/组织表现修正，并在赛后解释为“减少失误” |
| `skill_field_vision` | 开阔视野 | 组织家族 | 他能看到更好的传球线路 | 中场、控球战术、助攻或关键传球表现 | 组织训练与比赛关键传球标签 | 提供轻量机会创造修正，并生成“找到空当”解释 |
| `skill_defensive_positioning` | 防守站位 | 防守家族 | 他不一定抢眼，但总在正确位置 | 后卫/防守型中场、防守或均衡战术 | 防守训练、拦截/封堵表现 | 提供轻量防守稳定修正，并减少负面表现解释频率 |
| `skill_recovery_run` | 回追补位 | 防守家族 | 失位后愿意追回来补上 | 边路/后卫、体能充足、被反击或落后场景 | 体能训练、逆风防守表现 | 提供轻量防守补救解释，不直接抵消重大失误 |
| `skill_goal_instinct` | 门前嗅觉 | 终结家族 | 他总能在禁区里出现在有威胁的位置 | 前锋/进攻型中场、进攻战术、射门场景 | 射门训练、进球或高质量射门表现 | 提供轻量射门机会修正，并在进球/射门事件中显示解释 |
| `skill_composed_finish` | 冷静终结 | 终结家族 | 关键机会来临时不慌 | 前锋/进攻型中场、关键射门、比分接近场景 | 关键比赛射门表现、阶段性射门成长 | 提供轻量终结稳定修正，并用于赛后原因标签 |

#### Traits

| Trait ID | Trait name | Type | Player-facing meaning | Add condition | Trigger / display rule |
|---|---|---|---|---|---|
| `trait_big_moment` | 大场面球员 | 核心身份 | 关键比赛里更容易让人放心 | 多次关键比赛表现稳定，且没有同类核心身份特性 | 只在关键比赛结算或赛前预览中轻量提示 |
| `trait_slow_starter` | 慢热型 | 核心身份 | 前期不一定抢眼，但长期表现趋于稳定 | 多次训练/比赛前段表现一般、后段或长期成长稳定 | 不作为强负面；所有文案必须强调后程稳定和成长耐心 |
| `trait_reliable_rotation` | 可靠轮换 | 核心身份 | 他也许不是明星，但经常能稳稳完成任务 | 赛季级持续出勤、低失误、多个位置可用或训练态度稳定；不要求进球、助攻或高评分事件 | 给普通/弱势球员的身份路径，只提供稳定性解释与轻量下限支撑，不提高表现上限 |
| `trait_home_comfort` | 主场安心感 | 情境标签 | 在熟悉的小镇氛围中表现更自然 | 多次主场比赛表现稳定或情绪状态较好 | 只在主场或小镇相关反馈中触发 |
| `trait_team_anchor` | 团队支点 | 情境标签 | 他让队友和阵容更稳定 | 长期出勤稳定、队伍低波动、训练配合良好 | 用于赛前阵容说明和赛后团队稳定解释 |

#### Family Limit Rules

1. 同一球员不能同时自动解锁两个同家族主技能；若两个同家族技能同结算满足条件，系统先比较 `unlock_rank_milli`，再比较 `candidate_priority`，最后比较 `skill_id` 字典序，只解锁最终优先者，其他候选记录为候选进度。
2. 同一球员不能同时拥有两个核心身份特性；若新核心身份条件成立，系统只记录候选原因、阻塞说明与只读方向说明，不自动替换。
3. 情境标签特性最多 1 个；后续新增必须由玩家管理 UI 或阶段结算规则显式确认，Alpha 首版不实现替换操作。
4. 家族上限与总槽位上限都是防 build 压力的硬规则；不得通过 UI、声望、设施或比赛系统绕过。
5. 若两个不同家族技能在同一稳定结算中同时达到解锁条件，但总技能槽位只剩 1 个，系统必须按全局稳定顺序 `unlock_rank_milli DESC → candidate_priority DESC → skill_id ASC` 只解锁 1 个技能，其他技能转为候选进度并保留来源稳定结算键；结果不得依赖资源表顺序或遍历顺序。

### States and Transitions

技能与特性系统的状态表示确定性结算事务中的阶段，以及已持久化的球员长期状态。

| State | Description | Enter condition | Exit condition | Valid next states |
|---|---|---|---|---|
| Skill Idle | 技能与特性系统处于等待稳定事件输入的常规状态 | 游戏进入稳定可操作节点，且当前没有待评估的技能/特性事件 | 上游系统提交合法训练、成长、比赛表现或阶段成长事件 | Settlement Transaction / Skill Idle |
| Settlement Transaction | 单一结算编排入口正在处理一个稳定事件的完整事务 | 收到包含 `settlement_id` 的训练、比赛或阶段结算 payload | 本次事务已完成事实收集、技能/特性评估、durable settlement result 组装与原子提交 | Skill Idle |
| Skill Evaluation | 系统正在检查某球员是否满足技能进度、解锁或升级条件；只存在于当前事务上下文 | `Settlement Transaction` 已完成 `Collect Confirmed Facts`，且本次事实包含训练、成长、比赛表现或阶段成长事实 | 所有关联技能的进度、解锁和升级判定完成，并生成待提交的 result delta | Skill Progress Updated / Skill Unlocked / Skill Upgraded / Trait Evaluation |
| Skill Progress Updated | 某球员的技能进度发生变化，但尚未达到解锁或升级阈值；表示待提交结果而非已持久化状态 | `accumulated_skill_points` 增加，且未达到下一个阈值 | 该结果已写入本次事务的待提交 result delta | Trait Evaluation / Settlement Transaction |
| Skill Unlocked | 至少一个技能首次解锁；表示待提交结果而非已持久化状态 | `skill_unlocked = true`，该球员此前未拥有该技能，且未违反家族上限 | 技能状态、初始等级和来源结算键已加入本次事务的待提交 result delta | Skill Upgraded / Trait Evaluation / Settlement Transaction |
| Skill Upgraded | 已拥有技能满足升级条件；表示待提交结果而非已持久化状态 | 该技能累计进度达到下一等级阈值，且未超过等级上限 | 技能等级、剩余进度和来源结算键已加入本次事务的待提交 result delta | Trait Evaluation / Settlement Transaction |
| Trait Evaluation | 系统正在检查某球员是否满足新增、确认或变化特性条件；只存在于当前事务上下文 | 技能判定已完成，且稳定训练结果、比赛表现标签、长期成长状态或关键经历进入特性判定队列 | 所有关联特性的新增、变化和触发判定完成，并生成待提交的 result delta | Trait Triggered / Trait Added / Trait Changed / Feedback Pending |
| Trait Triggered | 某个已有特性在当前场景中生效或进入表现解释；表示待提交结果而非已持久化状态 | `trait_triggered = true`，且该特性已存在于球员状态中 | 本次触发结果和对应稳定结算键已加入待提交 result delta | Feedback Pending / Settlement Transaction |
| Trait Added | 某球员首次获得一个新特性；表示待提交结果而非已持久化状态 | 特性新增条件成立，球员此前未拥有该特性，且未违反特性上限 | 特性状态和来源结算键已加入待提交 result delta | Trait Changed / Feedback Pending / Settlement Transaction |
| Trait Changed | 某球员已有特性因长期成长原因发生变化；表示待提交结果而非已持久化状态 | 已满足明确的特性变化条件，且该变化被规则允许 | 旧特性迁移、替换或标记方案与新特性状态已加入待提交 result delta | Feedback Pending / Settlement Transaction |
| Feedback Pending | 当前技能/特性变化或触发结果需要注册为待展示反馈；表示待提交结果而非独立玩法界面 | Skill Unlocked、Skill Upgraded、Trait Triggered、Trait Added 或 Trait Changed 产生可见反馈 | 反馈、展示顺序和唯一首次展示归属面已加入本次 durable settlement result | Settlement Transaction |
| Deprecated Skill/Trait | 某技能或特性因版本调整进入弃用、合并或迁移状态 | 旧版本技能/特性被新版本替换、合并或移除 | 存档迁移完成，并映射到新状态或标记为历史保留 | Skill Idle |

#### State Transition Rules

1. `Skill Idle` 是默认状态。系统不主动推进，只响应已确认的稳定事件。
2. 所有技能/特性判定必须从 `Settlement Transaction` 进入，不能由训练 UI、比赛 UI 或单个 Godot signal 直接改写球员技能状态。
3. 单个稳定事件可以同时触发技能判定与特性判定，但事务顺序必须固定为：`Collect Confirmed Facts` → `Evaluate Skill/Trait Outcomes` → `Build Durable Settlement Result` → `Atomic Commit Durable Result`。`Atomic Commit Durable Result` 之前不得写入任何长期球员状态、稳定结算键、反馈确认事实、身份历史、候选进度或特性冷却变化。
4. `Skill Evaluation` 只能消费已经确认的训练、成长或比赛事实，不得读取未完成训练安排、比赛进行中事件或临时 UI 预览。
5. 若同一事件同时让多个技能满足条件，系统必须先按家族分组；同家族候选按 `unlock_rank_milli DESC → candidate_priority DESC → skill_id ASC` 的固定顺序裁决。不同家族且总槽位足够时可在同一结算中分别解锁，且每个技能使用独立稳定结算键；若不同家族同时满足条件但总槽位只剩 1 个，则必须按同一全局稳定顺序只解锁 1 个，其余转为候选进度，且不得依赖遍历顺序。
6. 首次解锁时若 `accumulated_skill_points` 超过解锁阈值，溢出点必须立即转入该技能的等级进度，不得丢失；若某技能一次结算跨越多个等级阈值，系统必须按等级顺序处理升级，直到达到当前累计进度允许的最高合法等级或技能等级上限。
7. `Skill Progress Updated` 可以不产生可见反馈；只有解锁、升级或设计上明确需要提示的进度节点才进入 `Feedback Pending`。
8. `Trait Evaluation` 不应频繁改写球员身份。特性新增或变化必须来自长期、稳定、可解释的条件，而不是单次随机事件。
9. `Trait Triggered` 只表示已有特性在当前场景中进入规则生效层；是否生成玩家可见反馈必须再经过独立的可见冷却、反馈预算和去重检查。首次实际生效若会明显影响当前结果解释，则本次事务必须至少生成一次可读原因记录，不能长期停留在“只生效不解释”。
10. `Trait Changed` 必须保留来源事件和迁移语义，避免玩家读档后无法理解球员特性为什么变化。
11. `Feedback Pending` 不是独立玩法界面，只表示技能/特性反馈需要挂接到训练结果、赛后结果或长期反馈流中。允许存在“已生效未展示”的状态，但不得绕过唯一首次展示归属面，也不得让同一 `feedback_key` 在多个界面分别作为新提示出现；Player Detail 只负责历史和补读，不拥有首次新提示权。
12. 读档恢复后不得停留在 `Collect Confirmed Facts`、`Evaluate Skill/Trait Outcomes`、`Build Durable Settlement Result` 或 `Settlement Transaction` 的半结算状态。稳定恢复点只能是 `Atomic Commit Durable Result` 完成后的 `Skill Idle`，或完全看不到该 durable result。
13. `Deprecated Skill/Trait` 不参与实时玩法循环，只用于版本迁移、旧存档兼容和历史记录保留。

### Interactions with Other Systems

| System | 技能与特性系统提供 | 该系统提供回技能与特性系统 | Ownership boundary |
|---|---|---|---|
| 数值系统 | 技能效果强度、叠加上限、触发频率和等级倍率的数值需求 | 效果强度边界、成长节奏、安全倍率范围、叠加上限 | 数值系统定义全局安全边界；技能系统定义具体技能/特性语义，并服从数值系统上限 |
| 运动员培养系统 | 技能解锁/升级需求、特性成长反馈语义、训练结算后的反馈 payload | 已确认训练结果、属性成长、潜力阶段、球员状态、稳定结算 ID | 培养系统定义基础成长事实；技能系统独占技能进度、解锁、升级和特性写入，不由培养系统直接改写技能/特性状态 |
| 比赛竞技系统 | 赛前可消费的不可变技能/特性效果快照、赛后表现解释标签 | 出场位置、比赛结果、关键事件、位置表现、赛后表现标签、稳定结算 ID | 比赛系统定义比赛事实并消费赛前快照；技能系统定义哪些技能/特性生效，不在比赛进行中解锁或升级 |
| 存档与读档系统 | 技能等级、技能进度、候选进度、特性状态、可见触发冷却、稳定结算键、解锁记录、身份历史、待展示反馈状态、反馈确认状态、弃用/迁移状态 | 稳定节点保存、读档恢复、版本迁移结果、快照复检结果 | 存档系统定义持久化结构与恢复时机；技能系统定义状态语义、迁移含义、反馈确认和幂等规则 |
| 声望与成就系统 | 技能/特性里程碑事实、风格化成长标签、可被长期认可消费的确认事件 | 成就或长期认可消费需求、长期反馈挂接结果 | 声望系统定义长期认可；技能系统只提供球员差异化事实，声望系统不得反向决定技能/特性解锁 |
| 主循环 UI 框架 | 技能/特性反馈 payload、挂接语义、展示优先级需求 | 统一提示容器、反馈队列、导航入口、结算展示顺序 | UI 框架定义如何挂接和展示；技能系统定义展示内容语义，不开启独立高压弹窗流 |
| 球员管理 UI | 技能列表、特性标签、等级/进度、候选阶段、阻塞原因、待确认反馈和身份历史 | 展示容器、筛选/排序需求、详情页入口、反馈确认入口 | 球员管理 UI 展示技能/特性权威状态；不重算条件、效果、候选阶段或家族上限 |
| 比赛表现 UI | 赛前技能/特性快照摘要、已触发技能/特性解释、赛后表现中的轻量影响标签和反馈确认入口 | 赛前只读系统摘要、赛后结果流、表现摘要展示位置、比赛事件上下文 | 比赛表现 UI 只解释已确认影响；不拥有技能/特性判定，也不在赛前或赛后重算解锁、升级、候选或触发条件 |

## Formulas

### 1. 稳定结算键

`canonical_fields = [normalize_scalar(settlement_id), normalize_scalar(player_id), normalize_scalar(consumer_scope), normalize_scalar(rule_id)]`

`settlement_key_source = canonical_join(canonical_fields, "|")`

`settlement_key = sha256_utf8_hex(settlement_key_source)`

**定义：** 技能/特性系统用于幂等处理的持久键。相同键重复进入系统时，视为同一条规则消费同一稳定结算事实，不得重复写入结果。`rule_version` 必须随技能、特性、反馈或历史结果保存，但不得进入 `settlement_key_source`；规则迁移只能通过显式迁移记录改变旧结果含义，不能通过改变 key 让旧结算再次消费。`normalize_scalar` 必须把输入规范化为 UTF-8 文本标量：整数与布尔值使用无本地化格式，枚举使用稳定代码名，`null` 非法且不得静默替换；字段前后空白必须裁剪。`canonical_join` 必须按公式中的固定字段顺序拼接，若字段文本本身包含分隔符 `|` 或转义符 `\`，必须先执行反斜杠转义。摘要算法固定为 `SHA-256`，输出小写十六进制字符串。实现不得直接 hash Dictionary、Array、Resource、Variant 或未排序运行时对象。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 结算 ID | `settlement_id` | string | 非空稳定 ID | 由训练、比赛或阶段结算生成的稳定结算标识 |
| 球员 ID | `player_id` | string | 非空稳定 ID | 被判定的球员稳定标识 |
| 消费作用域 | `consumer_scope` | enum | `skill_progress` / `skill_unlock` / `skill_upgrade` / `candidate_progress` / `trait_add` / `trait_reliable_rotation_season_score` / `trait_trigger_effect` / `trait_trigger_visible` / `trait_changed` / `feedback_ack` | 本次结算事实被哪类规则消费；可靠轮换赛季计分也必须走同一 canonical key pipeline |
| 规则 ID | `rule_id` | string | 非空稳定 ID | 技能、特性或反馈规则的稳定 ID |
| 规则版本 | `rule_version` | int | ≥ 1 | 该规则的持久化版本号；保存到结果元数据中，但不参与稳定结算键生成 |
| 结算键源文本 | `settlement_key_source` | string | 非空 canonical string | 固定字段顺序拼接后的稳定源文本，不包含 `rule_version` |
| 稳定结算键 | `settlement_key` | string | 非空 stable digest | 幂等去重使用的持久键 |

**Example:** `match_03_round_05 + player_12 + skill_unlock + skill_goal_instinct` 生成一个技能解锁键。该键已经存在时，同一比赛结果即使在规则版本迁移后重放，也不得再次解锁 `skill_goal_instinct`；迁移只更新该结果的版本元数据或迁移记录。

### 2. 稳定排序与全序比较器

`stable_order(items, order_spec) = sort(items by declared fields, then stable_tiebreak_id ASC)`

**定义：** 本系统所有跨系统可持久化结果、候选裁决、反馈展示和历史回显都必须使用全序比较器。任何排序规则都必须声明完整的比较字段，并以稳定 ID 作为最终 tie-breaker；若比较字段全部相同，结果仍必须唯一且可复现。实现不得使用资源表插入顺序、数组原始顺序、Godot `Dictionary.keys()` 遍历顺序、Object instance id、Node 路径、Resource 路径、signal 到达顺序或本地化显示名作为隐式排序依据。

**Required order specs:**

| Use case | Order spec | Stable tiebreak id |
|---|---|---|
| 家族内技能解锁裁决 | `unlock_rank_milli DESC → candidate_priority DESC → skill_id ASC` | `skill_id` |
| 全局技能槽位裁决 | `unlock_rank_milli DESC → candidate_priority DESC → skill_id ASC` | `skill_id` |
| 同类型特性新增裁决 | `trait_candidate_rank_milli DESC → trait_priority DESC → trait_id ASC` | `trait_id` |
| 单次结算反馈展示 | `display_priority DESC → display_order ASC → feedback_key ASC` | `feedback_key` |
| 身份历史回显 | `season_or_date DESC → display_order ASC → history_id ASC` | `history_id` |
| 赛前快照效果摘要 | `display_order ASC → effect_summary_id ASC` | `effect_summary_id` |
| 候选记录展示 | `candidate_display_priority DESC → display_order ASC → subject_id ASC` | `subject_id` |
| 已评估结算键持久化 | `settlement_key ASC` | `settlement_key` |
| 已处理结算键持久化 | `settlement_key ASC` | `settlement_key` |

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 待排序项目集合 | `items` | Array[typed shallow record] | 0–N entries | 仅包含稳定标量字段的数组 |
| 排序规则 | `order_spec` | ordered field list | 非空 | 明确字段名、升降序和比较类型的排序声明 |
| 稳定最终比较 ID | `stable_tiebreak_id` | string | 非空稳定 ID | 同一 use case 下唯一且不依赖显示名或资源路径的稳定 ID |
| 稳定排序结果 | `stable_order` | Array | same length as `items` | 全序排序后的确定性数组 |

**Example:** 两条反馈 `display_priority` 和 `display_order` 完全相同，则必须继续按 `feedback_key ASC` 排序。读档、迁移、不同平台或不同 Godot 运行时容器顺序下，展示顺序必须一致。

### 3. 主技能解锁裁决

`unlock_threshold_milli = skill_unlock_threshold × 1000`

`unlock_rank_milli = floor((accumulated_skill_points × 1000) / unlock_threshold_milli)`

`skill_unlock_candidate = accumulated_skill_points >= unlock_threshold_milli AND skill_not_already_owned AND settlement_key_not_processed`

`family_unlock_eligible = skill_unlock_candidate AND family_slot_available`

`family_unlock_order = sort(family_unlock_eligible in same family by unlock_rank_milli DESC, candidate_priority DESC, skill_id ASC)`

`family_unlock_winner = skill_id = first(family_unlock_order)`

`family_filtered_unlock_candidates = [skill_id where family_unlock_eligible AND family_unlock_winner]`

`global_unlock_order = sort(family_filtered_unlock_candidates by unlock_rank_milli DESC, candidate_priority DESC, skill_id ASC)`

`global_unlock_selected = total_skill_slots_remaining > 0 AND skill_id ∈ first_n(global_unlock_order, total_skill_slots_remaining)`

`skill_unlocked = skill_unlock_candidate AND family_slot_available AND family_unlock_winner AND global_unlock_selected`

`skill_candidate_trace_recorded = accumulated_skill_points > 0 AND skill_not_already_owned`

`skill_candidate_retained = skill_candidate_trace_recorded AND NOT skill_unlocked`

**定义：** 同一家族多个技能在同一稳定结算中同时达到解锁条件时，必须先生成不被槽位短路的 `skill_unlock_candidate`，再由 `family_unlock_eligible` 进入家族内裁决，最后把所有家族胜者放入全局槽位裁决。只有 `skill_unlocked = true` 的候选可写入已拥有技能；任何尚未拥有但已有成长事实的技能都可通过 `skill_candidate_trace_recorded` 写入或更新 `candidate_progress_record`，用于表达“身份痕迹”而非可优化任务。`skill_candidate_retained = true` 的记录必须保留来源稳定结算键、累计痕迹、阻塞原因和低压力说明。家族槽位或总槽位不足只能阻止写入已拥有技能，不得阻止候选痕迹持久化。该最终布尔裁决是唯一写入已拥有技能列表的条件，任何 UI、培养系统或比赛系统不得绕过。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 累计技能点 | `accumulated_skill_points` | int | ≥ 0 milli-points | 某球员在某技能上的累计定点成长点数 |
| 技能解锁阈值 | `skill_unlock_threshold` | int | 8–30 points | 解锁该技能所需的普通点数阈值；比较时必须乘以 1000；配置为 0 或负数是非法配置，不得用 `max(1, threshold)` 吞掉 |
| 解锁阈值定点数 | `unlock_threshold_milli` | int | 8000–30000 milli-points | `skill_unlock_threshold × 1000` 后的定点阈值 |
| 解锁排序定点比 | `unlock_rank_milli` | int | ≥ 0 | `accumulated_skill_points / unlock_threshold_milli` 的千分定点排序值；可超过 1000，达到 1000 时进入候选判定，不得用 float 排序 |
| 技能解锁候选 | `skill_unlock_candidate` | bool | true / false | 该技能是否满足阈值、尚未拥有且结算键未处理；不包含槽位检查，因此槽位不足时仍可保留候选进度 |
| 家族解锁资格 | `family_unlock_eligible` | bool | true / false | 该技能是否既满足候选条件又具备同家族写入槽位，可进入家族胜者裁决 |
| 家族解锁顺序 | `family_unlock_order` | Array[String] | 0–2 entries per family | 同一家族可写入候选按 `unlock_rank_milli DESC → candidate_priority DESC → skill_id ASC` 排序后的稳定顺序 |
| 家族胜者 | `family_unlock_winner` | bool | true / false | 该技能是否为本家族本次唯一胜者 |
| 家族过滤后候选 | `family_filtered_unlock_candidates` | Array[String] | 0–3 entries | 各家族胜者组成的全局槽位候选集合 |
| 全局解锁顺序 | `global_unlock_order` | Array[String] | 0–3 entries | 家族胜者按 `unlock_rank_milli DESC → candidate_priority DESC → skill_id ASC` 排序后的稳定顺序 |
| 进入全局解锁名单 | `global_unlock_selected` | bool | true / false | 该技能是否落在按剩余总槽位数量截断后的全局解锁名单内 |
| 技能已解锁 | `skill_unlocked` | bool | true / false | 该技能是否在本次结算中最终写入已拥有技能列表 |
| 候选痕迹已记录 | `skill_candidate_trace_recorded` | bool | true / false | 该技能尚未拥有但已有至少一条稳定成长事实，可写入或更新身份痕迹候选记录；不要求达到解锁阈值 |
| 候选保留 | `skill_candidate_retained` | bool | true / false | 技能尚未写入已拥有状态，但已有身份痕迹需要持久化；可能是未达阈值、家族槽位占用或总槽位不足 |
| 技能尚未拥有 | `skill_not_already_owned` | bool | true / false | 该球员当前是否尚未拥有该技能 |
| 家族槽位可用 | `family_slot_available` | bool | true / false | 该球员是否未超过同家族主技能上限 |
| 总剩余技能槽位 | `total_skill_slots_remaining` | int | 0–3 | 当前球员本次裁决前仍可写入的总技能槽位数量 |
| 候选优先级 | `candidate_priority` | int | 0–99 | 设计配置的稳定裁决优先级；数值越高越优先 |
| 结算键未评估 | `settlement_key_not_evaluated` | bool | true / false | 本次稳定结算键是否尚未进入 `evaluated_settlement_keys`；为 false 时本次消费直接返回 idempotent no-op |
| 结算键未处理 | `settlement_key_not_processed` | bool | true / false | 本次稳定结算键是否尚未进入 `processed_settlement_keys`；只用于会产生 durable outcome 的写入判定 |

**Example:** 同一家族两个候选技能分别为 18000/20000 和 20000/20000 milli-points，且总技能槽位、家族槽位都可用，则 `unlock_rank_milli` 更高的 20000/20000 技能成为 `family_unlock_winner`。若两者 `unlock_rank_milli` 都为 1000，则继续比较 `candidate_priority`，再比较 `skill_id` 字典序。若三个家族胜者同时满足条件但总技能槽位只剩 2 个，则只写入全局排序前 2 个技能，剩余胜者以 `skill_candidate_retained = true` 写入候选进度。

### 4. 首次解锁溢出与技能升级进度

`unlock_overflow_points = max(0, accumulated_skill_points - (skill_unlock_threshold × 1000)) when skill_unlocked = true AND skill_level_before = 0; else 0`

`available_upgrade_progress = current_level_progress + incoming_skill_points + unlock_overflow_points`

`while skill_level_after < skill_level_cap AND available_upgrade_progress >= level_thresholds[skill_level_after + 1] × 1000:`

`    available_upgrade_progress -= level_thresholds[skill_level_after + 1] × 1000`

`    skill_level_after += 1`

`remaining_skill_progress = available_upgrade_progress`

**定义：** 首次解锁时，超过解锁阈值的定点点数不得丢失，而是直接转入该技能的等级进度；该溢出只允许在本次从未拥有状态写入 `skill_unlocked = true` 时计算一次。已拥有技能继续按每级阈值表逐级升级，且 `unlock_overflow_points = 0`，不得把历史累计点数重复计入升级进度；`level_thresholds[level]` 表示升到该等级所需的普通点数阈值，例如 `level_thresholds[2] = 12`、`level_thresholds[3] = 18`，比较和扣减时必须乘以 1000。循环必须按等级顺序执行，不得一次跳过中间等级。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 升级前等级 | `skill_level_before` | int | 0–3 | 该技能当前等级；0 表示本次结算前尚未拥有，用于首次解锁溢出计算；已拥有技能范围为 1–3 |
| 升级后等级 | `skill_level_after` | int | 1–3 | 本次结算后的技能等级；初始值等于 `skill_level_before` |
| 技能等级上限 | `skill_level_cap` | int | 3 | Alpha 首版技能等级上限 |
| 当前等级进度 | `current_level_progress` | int | ≥ 0 milli-points | 当前等级内已保留定点进度；首次解锁时初始为 0 |
| 新增技能点 | `incoming_skill_points` | int | ≥ 0 milli-points | 本次稳定结算新增的定点技能进度；对首次解锁场景记为 0 |
| 解锁溢出点 | `unlock_overflow_points` | int | ≥ 0 milli-points | 首次解锁时超出解锁阈值并转入等级进度的定点点数 |
| 可用升级进度 | `available_upgrade_progress` | int | ≥ 0 milli-points | 当前等级进度、结算新增进度和首次解锁溢出之和 |
| 等级阈值表 | `level_thresholds[level]` | Dictionary[int, int] | level 2–3, value 12–45 points | 升到指定等级所需普通点数阈值；比较和扣减时必须乘以 1000 |
| 剩余技能进度 | `remaining_skill_progress` | int | ≥ 0 milli-points | 完成本次升级后保留到当前等级的定点进度；满级后仍作为历史进度保留但不继续升级 |

**Example:** 某技能解锁阈值为 15 points，球员本次累计到 22000 milli-points 并首次解锁，则 `unlock_overflow_points = 7000`，该 7000 milli-points 直接成为解锁后的等级进度。若另一已拥有技能等级 1、`current_level_progress = 5000`，本次新增 30000 milli-points；升到 2 需要 12000 milli-points，升到 3 需要 18000 milli-points，则 `available_upgrade_progress = 35000`，先扣 12000 升到 2，剩 23000；再扣 18000 升到 3，剩 5000；`skill_level_after = 3`，`remaining_skill_progress = 5000`。

### 5. 技能效果修正

`raw_skill_effect_modifier = base_skill_effect × skill_level_multiplier × context_match_ratio`

`skill_effect_modifier = clamp(raw_skill_effect_modifier, 0, skill_effect_cap)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 基础技能效果 | `base_skill_effect` | float | 0–0.08 | 该技能在完全适用场景下的基础效果值 |
| 技能等级倍率 | `skill_level_multiplier` | float | 1.0–1.5 | 技能等级带来的效果倍率 |
| 场景匹配比例 | `context_match_ratio` | float | 0–1 | 当前训练、位置、战术或比赛场景与技能适用场景的匹配程度 |
| 技能效果上限 | `skill_effect_cap` | float | 0.01–0.12 | 数值系统允许本技能在单次消费中的最大轻量修正值；0 是非法配置，禁用技能应使用显式 disabled 状态 |
| 原始技能效果修正 | `raw_skill_effect_modifier` | float | ≥ 0 | clamp 前的技能效果值 |
| 技能效果修正 | `skill_effect_modifier` | float | 0–0.12 | 输出给训练或比赛系统消费的最终轻量修正值 |

**Example:** 某技能基础效果为 0.04，等级倍率为 1.25，当前场景匹配比例为 0.8，效果上限为 0.12，则 `skill_effect_modifier = clamp(0.04 × 1.25 × 0.8, 0, 0.12) = 0.04`。

### 6. 多技能聚合

`applicable_skill_modifiers = [skill_effect_modifier_i where context_match_ratio_i > 0 AND skill_snapshot_enabled_i = true]`

`raw_aggregated_skill_modifier = Σ(applicable_skill_modifiers)`

`aggregated_skill_modifier = clamp(raw_aggregated_skill_modifier, 0, aggregated_skill_effect_cap)`

**定义：** 当同一训练、比赛或结算场景中多个已拥有技能同时适用时，先分别按单技能公式计算每个技能的轻量修正，再在本系统内聚合并封顶。下游系统只能消费聚合后的只读结果，不能逐个技能再次叠加，避免双重应用。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 可适用技能修正集合 | `applicable_skill_modifiers` | Array[float] | 0–3 entries | 当前场景可生效的技能修正集合，受球员技能上限约束 |
| 技能快照启用状态 | `skill_snapshot_enabled_i` | bool | true / false | 赛前或训练结算快照中该技能是否允许被消费 |
| 原始聚合技能修正 | `raw_aggregated_skill_modifier` | float | ≥ 0 | 所有适用技能修正相加后的未封顶值 |
| 聚合技能效果上限 | `aggregated_skill_effect_cap` | float | 0.04–0.18 | 同一上下文中所有技能合计允许贡献的最大修正 |
| 聚合技能修正 | `aggregated_skill_modifier` | float | 0–0.18 | 输出给修正叠加公式的技能总修正 |

**Example:** 三个技能分别产出 0.06、0.04、0.03，聚合上限为 0.10，则 `raw_aggregated_skill_modifier = 0.13`，`aggregated_skill_modifier = 0.10`。

### 7. 技能数值 read model 与特性解释 read model 输出

`skill_training_modifier_milli = floor(clamp(aggregated_skill_modifier where context_type = training, 0, skill_training_modifier_cap) × 1000)`

`skill_training_multiplier_milli = clamp(1000 + skill_training_modifier_milli, 1000, skill_training_multiplier_cap_milli)`

`player_skill_match_modifier_milli = floor(clamp(aggregated_skill_modifier where context_type = match, 0, player_skill_match_modifier_cap) × 1000)`

`trait_effect_summary_ids = stable_order(effect_summary_id where owned trait context applies and trait is explanation-only, display_order ASC → effect_summary_id ASC)`

**定义：** Alpha 首版中，技能拥有训练/比赛数值 read model；特性默认是解释、身份历史和轻量下限语义，不进入训练或比赛数值修正。培养系统只能消费 `skill_training_modifier_milli` 或由其派生的 `skill_training_multiplier_milli`；比赛系统只能消费赛前锁定快照中的 `player_skill_match_modifier_milli`，并由比赛系统生成 `team_skill_trait_summary` 和 `skill_trait_match_mod`。`skill_training_multiplier_cap_milli` 必须满足 `skill_training_multiplier_cap_milli >= 1000 + floor(skill_training_modifier_cap × 1000)`；若配置不满足该不变量，规则加载必须失败而不是静默截断技能训练修正。`trait_effect_summary_ids` 只用于解释、身份历史、赛前/赛后说明和可靠轮换等普通球员身份路径，不得被下游当作数值加成重新叠加。本系统不得输出或要求下游消费混入属性、战术、设施、状态或 trait 数值的 混合后的上下文修正字段，下游也不得把训练倍率复用于比赛。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 聚合技能修正 | `aggregated_skill_modifier` | float | 0–0.18 | 本系统输出的技能总修正，已在多技能聚合公式中封顶，且按上下文分别生成训练或比赛摘要 |
| 技能训练修正定点值 | `skill_training_modifier_milli` | int | 0–180 | 仅包含技能系统拥有的训练场景数值效果，不含 trait、属性、战术、设施、状态或比赛层修正 |
| 技能训练修正上限 | `skill_training_modifier_cap` | float | 0.04–0.18 | 技能在训练收益前允许贡献的最大纯修正 |
| 技能训练倍率定点值 | `skill_training_multiplier_milli` | int | 1000–1350 | 培养系统消费的定点倍率；由 `1000 + skill_training_modifier_milli` 派生并按安全上限 clamp，显示时可换算为 1.00–1.35 |
| 技能训练倍率上限定点值 | `skill_training_multiplier_cap_milli` | int | 1100–1350 | 训练收益中技能倍率的安全上限 |
| 球员技能比赛修正定点值 | `player_skill_match_modifier_milli` | int | 0–80 | 赛前快照中单名球员的比赛层纯技能修正摘要；比赛系统按阵容权重聚合为 `team_skill_trait_summary` |
| 球员比赛修正上限 | `player_skill_match_modifier_cap` | float | 0.00–0.08 | 单名球员贡献给比赛 wrapper 前的技能修正安全上限 |
| 特性效果摘要 ID 集合 | `trait_effect_summary_ids` | Array[String] | 0–2 entries | 当前上下文中适用的解释型特性摘要；只用于说明和身份历史，不进入训练或比赛数值公式 |

**Example:** 某球员在训练上下文有两个适用技能，聚合后 `aggregated_skill_modifier = 0.06`，训练上限为 0.18，则 `skill_training_modifier_milli = floor(0.06 × 1000) = 60`，`skill_training_multiplier_milli = 1060`。同一球员在比赛上下文的聚合技能修正为 0.09，比赛单人上限为 0.08，则 `player_skill_match_modifier_milli = floor(0.08 × 1000) = 80`；最终队伍级 `skill_trait_match_mod` 仍由比赛系统根据阵容权重和 `team_skill_trait_summary` 唯一推导。若该球员拥有 `trait_reliable_rotation`，快照只输出对应 `trait_effect_summary_ids` 供解释和身份历史使用，不增加 `player_skill_match_modifier_milli`。

### 8. 特性效果与可见反馈分离

`trait_effect_applied = trait_condition_satisfied AND context_allows_trait AND trait_is_owned AND trait_effect_key_not_processed`

`visible_cooldown_available = true when last_visible_feedback_settlement_id = null; else current_settlement_id != last_visible_feedback_settlement_id AND settlements_since_last_visible_trigger >= trait_visible_cooldown_window`

`trait_feedback_visible = trait_effect_applied AND visible_cooldown_available AND feedback_budget_available AND trait_visible_key_not_processed`

`trait_add_precheck = add_condition_satisfied AND trait_not_already_owned AND trait_slot_available AND add_settlement_key_not_processed`

`trait_changed = change_condition_satisfied AND trait_change_allowed AND old_trait_owned AND change_settlement_key_not_processed`

**定义：** 特性在规则层的“效果生效”与展示层的“可见反馈”必须分离。特性可以在当前稳定结算中正常生效，但只有通过可见冷却、展示预算和去重检查后，才能生成玩家可见反馈。`trait_add_precheck` 只表示特性新增进入候选裁决前的资格检查，最终是否写入新特性必须使用“特性候选、转正与可靠轮换裁决”中的 `trait_added`。新增、变化、效果生效和可见反馈都必须使用独立作用域和独立结算键，不与 `trait_effect_applied` 混用。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 特性条件满足 | `trait_condition_satisfied` | bool | true / false | 当前稳定节点中，该特性效果条件是否成立 |
| 场景允许特性生效 | `context_allows_trait` | bool | true / false | 当前训练、比赛或结算场景是否允许该特性生效 |
| 球员拥有特性 | `trait_is_owned` | bool | true / false | 该球员是否已经拥有该特性 |
| 特性效果键未处理 | `trait_effect_key_not_processed` | bool | true / false | 本次 `trait_trigger_effect` 作用域稳定结算键是否尚未处理 |
| 当前结算 ID | `current_settlement_id` | string | 非空稳定 ID | 当前判定所在稳定结算 |
| 上次可见反馈结算 ID | `last_visible_feedback_settlement_id` | string / null | 稳定 ID 或 null | 该特性上次生成可见反馈的结算 ID；首次触发为 null |
| 距上次可见触发结算数 | `settlements_since_last_visible_trigger` | int | ≥ 0 | 自上次可见触发提交后、当前可见性检查前已经完成的相关训练/比赛/阶段结算次数；生成可见反馈的同次结算不计入该值，提交后重置为 0 |
| 特性可见冷却窗口 | `trait_visible_cooldown_window` | int | 1–5 | 同一特性两次可见反馈之间至少需要完成的相关稳定结算数；例如窗口为 2 时，上次可见后的第 1 次相关结算不可见，第 2 次相关结算才可再次可见 |
| 展示预算可用 | `feedback_budget_available` | bool | true / false | 当前结算结果是否仍有可见反馈预算 |
| 特性可见键未处理 | `trait_visible_key_not_processed` | bool | true / false | 本次 `trait_trigger_visible` 作用域稳定结算键是否尚未处理 |
| 特性效果生效 | `trait_effect_applied` | bool | true / false | 该特性是否在当前结算中进入规则生效层 |
| 特性反馈可见 | `trait_feedback_visible` | bool | true / false | 该特性是否在当前结算中生成可见反馈 |
| 新增条件满足 | `add_condition_satisfied` | bool | true / false | 当前稳定节点中，该特性新增所需的候选事实和阈值是否已成立 |
| 特性尚未拥有 | `trait_not_already_owned` | bool | true / false | 该球员是否尚未拥有该特性 |
| 特性槽位可用 | `trait_slot_available` | bool | true / false | 对应特性类型槽位是否仍可写入；核心身份和情境标签分别计算 |
| 特性新增键未处理 | `add_settlement_key_not_processed` | bool | true / false | 本次 `trait_add` 作用域稳定结算键是否尚未处理 |
| 特性新增预检成立 | `trait_add_precheck` | bool | true / false | 是否具备进入特性候选裁决前的资格；不是最终写入条件 |
| 变化条件满足 | `change_condition_satisfied` | bool | true / false | 当前稳定节点中，已拥有特性发生长期变化的条件是否成立 |
| 特性变化被允许 | `trait_change_allowed` | bool | true / false | 当前版本规则是否允许该特性变化；Alpha 首版默认只允许显式配置的变化 |
| 旧特性已拥有 | `old_trait_owned` | bool | true / false | 该球员是否拥有待变化或迁移的旧特性 |
| 特性变化键未处理 | `change_settlement_key_not_processed` | bool | true / false | 本次 `trait_changed` 作用域稳定结算键是否尚未处理 |
| 特性变化成立 | `trait_changed` | bool | true / false | 是否写入一次特性变化 |

**Example:** 一名球员已拥有 `trait_big_moment`，关键比赛赛后满足特性条件，则 `trait_effect_applied = true`。若该特性此前从未生成可见反馈（`last_visible_feedback_settlement_id = null`），首次可见检查直接通过；若 `trait_visible_cooldown_window = 2`，上次可见后的第 1 次相关结算使 `settlements_since_last_visible_trigger = 1` 且不可见，第 2 次相关结算检查前该值为 2，且当前结算仍有反馈预算，则 `trait_feedback_visible = true`；若冷却未结束，则效果仍生效，但不生成新反馈。

### 9. 特性候选、转正与可靠轮换裁决

`trait_point_delta_milli = trait_fact_point_value × trait_fact_weight_milli`

`trait_candidate_points_after = trait_candidate_points_before + Σ(trait_point_delta_milli_i for accepted trait facts)`

`trait_candidate_threshold_milli = trait_candidate_threshold × 1000`

`trait_candidate_rank_milli = floor((trait_candidate_points_after × 1000) / trait_candidate_threshold_milli)`

`trait_add_candidate = trait_candidate_points_after >= trait_candidate_threshold_milli AND trait_not_already_owned AND trait_slot_available AND add_settlement_key_not_processed`

`trait_type_order = stable_order(trait_id where trait_add_candidate in same trait_type, trait_candidate_rank_milli DESC → trait_priority DESC → trait_id ASC)`

`trait_type_winner = trait_id = first(trait_type_order)`

`trait_added = trait_add_candidate AND trait_type_winner`

`trait_candidate_retained = trait_candidate_points_after > 0 AND NOT trait_added`

`reliable_rotation_season_score_milli = attendance_score_milli + low_error_score_milli + role_coverage_score_milli + training_stability_score_milli`

`reliable_rotation_season_settlement_id = season_closeout_settlement_id where settlement_type = season_closeout AND season_id = scored_season_id`

`reliable_rotation_season_settlement_key = settlement_key where consumer_scope = trait_reliable_rotation_season_score AND rule_id = trait_reliable_rotation AND settlement_id = reliable_rotation_season_settlement_id`

`reliable_rotation_season_evaluated = reliable_rotation_season_settlement_key ∈ evaluated_settlement_keys`

`reliable_rotation_season_scored = reliable_rotation_season_settlement_key ∈ processed_settlement_keys`

`reliable_rotation_accumulator_after = reliable_rotation_accumulator_before when reliable_rotation_season_evaluated = true; else min(reliable_rotation_accumulator_before + reliable_rotation_season_score_milli, reliable_rotation_accumulator_cap_milli)`

`reliable_rotation_threshold_met = reliable_rotation_accumulator_after >= reliable_rotation_threshold_milli AND highlight_event_required = false`

`reliable_rotation_candidate_points_after = max(trait_candidate_points_after, reliable_rotation_accumulator_after)`

`reliable_rotation_add_candidate = reliable_rotation_threshold_met AND trait_not_already_owned AND core_identity_slot_available AND add_settlement_key_not_processed`

`trait_add_candidate for trait_reliable_rotation = reliable_rotation_add_candidate`

`trait_candidate_retained for trait_reliable_rotation = reliable_rotation_candidate_points_after > 0 AND NOT trait_added`

**定义：** 特性新增必须先经过候选计点，再按特性类型槽位裁决。`trait_added = true` 是唯一可写入新特性的最终条件；所有 `trait_candidate_retained = true` 的特性必须写入或更新 `candidate_progress_record`。核心身份与情境标签分别独立裁决：核心身份最多写入 1 个，情境标签最多写入 1 个；同一类型多个特性同结算满足条件时，按 `trait_candidate_rank_milli DESC → trait_priority DESC → trait_id ASC` 只选 1 个。Alpha 首版不允许特性替换，因此槽位被占用时只能保留候选与行动建议，不得自动挤掉旧特性。

`trait_reliable_rotation` 使用专属跨赛季可靠性 accumulator。它不要求进球、助攻、高评分或关键比赛事件；只消费赛季级可靠事实，并且效果只能用于稳定性解释、轻量失误解释抑制或候选身份记录，不得提高射门、组织、防守等表现上限。该 accumulator 必须持久化，并且同一 `player_id + season_id` 只能通过 `reliable_rotation_season_settlement_key` 评估一次：阶段结算可以生成只读预览或候选说明，但不得把同一赛季的中期分数多次累加入跨赛季 accumulator；赛季结算或等价的唯一赛季收口节点才允许写入 `reliable_rotation_accumulator_state` 和处理键。读档后若该赛季 key 已存在于 `evaluated_settlement_keys`，再次收到同一赛季可靠性结算只能返回 idempotent no-op，不得双计分。若核心身份槽位为空，`reliable_rotation_add_candidate` 进入同一 `trait_added` canonical path；若核心身份槽位已被占用，系统仍必须用 `reliable_rotation_candidate_points_after` 写入或更新 `candidate_progress_record`，并给出只读低压力说明，不得让普通球员身份路径消失。无论最终是 `trait_added`、`candidate_updated` 还是无变化 no-op，该赛季 key 都必须进入 `evaluated_settlement_keys`；只有写入 trait 或候选 durable outcome 时才进入 `processed_settlement_keys`。若该特性最终写入，`pending_skill_trait_feedback` 和 `player_identity_history_entry` 的文案必须强调“稳定完成任务”，不得暗示该球员成为明星或最优解。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 特性事实基础点数 | `trait_fact_point_value` | int | 0–3 | 由特性计点表赋予某条稳定事实的基础点数 |
| 特性事实权重 | `trait_fact_weight_milli` | int | 400 / 700 / 1000 | 同类低价值事实在连续窗口内的定点权重；高价值长期事实固定为 1000 |
| 特性候选点数 | `trait_candidate_points_after` | int | ≥ 0 milli-points | 本次结算后的特性候选累计定点点数 |
| 特性候选阈值 | `trait_candidate_threshold` | int | 10–36 points | 特性从候选转为可新增所需普通点数阈值；比较时乘以 1000；配置为 0 或负数是非法配置，不得用 `max(1, threshold)` 吞掉 |
| 特性候选排序定点比 | `trait_candidate_rank_milli` | int | ≥ 0 | 特性候选点数相对阈值的千分定点排序值，可超过 1000；不得用 float 排序 |
| 特性 ID | `trait_id` | string | 非空稳定 ID | 被裁决的特性稳定标识 |
| 特性类型 | `trait_type` | enum | `core_identity` / `context_tag` | 特性槽位类型；核心身份和情境标签分别裁决 |
| 特性新增候选 | `trait_add_candidate` | bool | true / false | 该特性是否具备进入同类型槽位裁决的资格 |
| 特性类型裁决顺序 | `trait_type_order` | Array[String] | 0–2 entries per type | 同类型可新增候选按 `trait_candidate_rank_milli DESC → trait_priority DESC → trait_id ASC` 排序后的稳定顺序 |
| 特性类型胜者 | `trait_type_winner` | bool | true / false | 该特性是否为同类型本次唯一胜者 |
| 特性已新增 | `trait_added` | bool | true / false | 该特性是否在本次结算中最终写入球员特性状态 |
| 特性候选保留 | `trait_candidate_retained` | bool | true / false | 特性已有候选进度但未在本次写入正式状态 |
| 特性优先级 | `trait_priority` | int | 0–99 | 设计配置的稳定裁决优先级；数值越高越优先 |
| 可靠出勤分 | `attendance_score_milli` | int | 0–3000 per season | 赛季出勤率达到 60% / 70% / 80% 时分别提供 1000 / 2000 / 3000 milli-points |
| 低失误分 | `low_error_score_milli` | int | 0–3000 per season | 每 2 个低失误标签提供 1000 milli-points，单赛季最多 3000 |
| 位置覆盖分 | `role_coverage_score_milli` | int | 0–2000 per season | 可胜任第 2 个位置提供 1000，第 3 个及以上合计最多 2000 |
| 训练稳定分 | `training_stability_score_milli` | int | 0–2000 per season | 训练完成率达到 70% / 85% 时分别提供 1000 / 2000 milli-points |
| 单赛季可靠轮换分 | `reliable_rotation_season_score_milli` | int | 0–10000 per season | 四项可靠性事实在单赛季内的合计分 |
| 被计分赛季 ID | `scored_season_id` | string | 非空稳定 ID | 本次可靠轮换赛季分所属赛季；同一球员同一 `scored_season_id` 只能入账一次 |
| 可靠轮换赛季结算 ID | `reliable_rotation_season_settlement_id` | string | 非空稳定 ID | 由时间/赛季系统唯一赛季收口结算提供的 `season_closeout_settlement_id`；不得由阶段预览、UI 或数组顺序拼接生成 |
| 累计前可靠轮换分 | `reliable_rotation_accumulator_before` | int | 0–30000 milli-points | 本次阶段/赛季结算前已持久化的跨赛季可靠性累计分 |
| 累计后可靠轮换分 | `reliable_rotation_accumulator_after` | int | 0–30000 milli-points | 本次结算后持久化的跨赛季可靠性累计分 |
| 可靠轮换累计上限 | `reliable_rotation_accumulator_cap_milli` | int | 20000–30000 milli-points | 防止长期闲置累计无限膨胀的安全上限；Alpha 建议 24000 |
| 可靠轮换赛季计分键 | `reliable_rotation_season_settlement_key` | string | 非空 stable digest | 使用“稳定结算键”公式生成的一次性计分键；`consumer_scope = trait_reliable_rotation_season_score`，`rule_id = trait_reliable_rotation`，`settlement_id = reliable_rotation_season_settlement_id`，同一球员同一赛季只能入账一次 |
| 可靠轮换赛季已评估 | `reliable_rotation_season_evaluated` | bool | true / false | 该球员该赛季可靠轮换分是否已经进入 `evaluated_settlement_keys`；为 true 时本次结算直接 no-op |
| 可靠轮换赛季已计分 | `reliable_rotation_season_scored` | bool | true / false | 该球员该赛季可靠轮换分是否已经产生 durable outcome；为 true 时本次结算不得再次累加 |
| 可靠轮换阈值 | `reliable_rotation_threshold_milli` | int | 12000–18000 milli-points | `trait_reliable_rotation` 可转正所需跨赛季累计可靠性分；Alpha 建议 14000；配置为 0 或负数非法 |
| 可靠轮换阈值满足 | `reliable_rotation_threshold_met` | bool | true / false | 跨赛季可靠性累计是否达到转正门槛，且不要求高光事件 |
| 可靠轮换候选点 | `reliable_rotation_candidate_points_after` | int | ≥ 0 milli-points | 槽位被占用或未转正时写入候选记录的可靠轮换候选点 |
| 高光事件是否必需 | `highlight_event_required` | bool | false | `trait_reliable_rotation` 固定为 false，用于保证普通球员身份路径不依赖高光事件 |

**Example 1 — 特性同类型裁决:** 某球员在同一阶段结算中 `trait_big_moment` 与 `trait_reliable_rotation` 都达到核心身份特性新增条件，且核心身份槽位为空。若两者 `trait_candidate_rank_milli` 分别为 1100 和 1300，则只写入 `trait_reliable_rotation`，`trait_big_moment` 以候选保留。

**Example 2 — 普通球员可靠轮换:** 一名普通球员第一赛季出勤率 82%、低失误标签 6 次、可胜任 2 个位置、训练完成率 75%，获得 `3000 + 3000 + 1000 + 1000 = 8000` milli-points，并写入 `reliable_rotation_accumulator_after = 8000`。第二赛季再次获得 8000，累计达到 16000，高于 Alpha 建议阈值 14000；即使没有进球、助攻或高评分事件，也满足 `reliable_rotation_threshold_met = true`。若核心身份槽位为空，该特性进入 `trait_added` 裁决；若槽位已被占用，则用 16000 milli-points 更新 `candidate_progress_record`，而不是静默丢弃普通球员的身份成长。

### 10. 固定计点表与反刷衰减

`skill_point_delta_milli = fact_point_value × repeated_fact_weight_milli`

`accumulated_skill_points_after = accumulated_skill_points_before + Σ(skill_point_delta_milli_i for accepted facts)`

`candidate_progress_points_after = candidate_progress_points_before + Σ(skill_point_delta_milli_i for accepted facts while blocked)`

`repeated_fact_weight_milli = 1000 when repeated_low_value_fact_count_in_window = 0; 700 when = 1; 400 when >= 2`

**定义：** 技能与候选进度点不允许在实现阶段自由解释；`confirmed_facts[]` 必须先被映射为稳定点数事实，再进入技能/候选进度累计。为避免浮点边界漂移，Alpha 首版在持久化和裁决中使用千分定点计数：所有进度存为 milli-points，展示和示例可以换算为普通点数；阈值比较统一使用 `progress_milli >= threshold × 1000`，不得用二进制浮点近似结果直接判断解锁、升级或候选阶段。Alpha 首版采用固定计点表：同一条事实只能映射到一个主技能家族。训练事实使用 `training_focus_hit = 3`、`training_focus_partial = 2`、`training_focus_miss = 1`；比赛曝光事实使用 `match_role_exposure_strong = 3`、`match_role_exposure_ok = 2`、`match_role_exposure_light = 1`；关键事件事实使用 `key_positive_event = 2`、`key_negative_or_misaligned_event = 0`；长期稳定标签事实使用 `season_stability_tag = 2`、`reliable_rotation_tag = 2`。当同一球员对同一技能家族在连续相关结算窗口内重复命中“低价值同类事实”（`training_focus_partial`、`training_focus_miss`、`match_role_exposure_light`）时，必须按 `repeated_fact_weight_milli` 递减记点，避免低风险重复刷法成为最优成长路径。高价值事实（`training_focus_hit`、`match_role_exposure_strong`、`key_positive_event`、长期稳定标签）不受该衰减影响。连续相关结算窗口固定为同一球员、同一技能家族最近 3 次相关训练/比赛/阶段结算；任一高价值事实命中或切换到不同技能家族时，该家族低价值连续计数重置。该窗口状态不是运行时临时缓存，必须持久化为 `anti_grind_window_state`，至少包含 `player_id`、`family_id`、`recent_low_value_fact_types[]`、`recent_settlement_ids[]`、`repeated_low_value_fact_count_in_window`、`last_reset_reason` 和 `rule_version`。读档、迁移或重复结算后不得因为窗口状态丢失而把下一条低价值事实重新按 1000 milli-points 记分。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 单条事实基础点数 | `fact_point_value` | int | 0–3 | 由固定计点表赋予某条稳定事实的基础点数 |
| 重复事实权重（千分） | `repeated_fact_weight_milli` | int | 400 / 700 / 1000 | 同一球员、同一技能家族、连续窗口内重复低价值同类事实的衰减权重 |
| 技能点增量（千分） | `skill_point_delta_milli` | int | ≥ 0 | 单条事实最终贡献给技能或候选进度的定点点数 |
| 累计技能点（前） | `accumulated_skill_points_before` | int | ≥ 0 milli-points | 本次结算前该技能的累计定点点数 |
| 累计技能点（后） | `accumulated_skill_points_after` | int | ≥ 0 milli-points | 本次结算后该技能的累计定点点数 |
| 候选进度点（前） | `candidate_progress_points_before` | int | ≥ 0 milli-points | 本次结算前该候选记录的累计定点点数 |
| 候选进度点（后） | `candidate_progress_points_after` | int | ≥ 0 milli-points | 本次结算后该候选记录的累计定点点数 |
| 连续窗口内重复低价值事实次数 | `repeated_low_value_fact_count_in_window` | int | 0–2+ | 同一球员对同一家族在最近 3 次相关稳定结算窗口内已发生的低价值同类事实次数 |

**Example:** 某球员连续三次通过同家族的轻度比赛曝光获得成长，三次事实都映射为 `match_role_exposure_light = 1`。若这是连续窗口内第 1、2、3 次同类低价值事实，则三次分别记为 `1 × 1000 = 1000`、`1 × 700 = 700`、`1 × 400 = 400` milli-points，也就是展示口径的 1、0.7、0.4 点，避免安全重复刷分且不引入浮点比较漂移。

### 11. 候选身份痕迹可见阶段

`candidate_threshold_milli = candidate_unlock_threshold × 1000`

`candidate_progress_milli = floor((candidate_progress_points × 1000) / candidate_threshold_milli)`

`candidate_visibility_stage = classify_candidate_progress(candidate_progress_milli)`

`candidate_display_order = stable_order(candidate_progress_record by candidate_display_priority DESC → display_order ASC → subject_id ASC)`

`candidate_summary_visible = candidate_visibility_stage != none AND record ∈ first_n(candidate_display_order, per_player_candidate_summary_budget)`

**Classification Table:**

| Candidate progress milli | Stage | Player-facing label |
|---|---|---|
| 0 | `none` | 不展示候选 |
| 1–349 | `trace_emerging` | 初现痕迹 |
| 350–749 | `trace_consistent` | 稳定倾向 |
| ≥ 750 | `trace_distinct` | 鲜明风格 |

**定义：** 当技能或特性尚未达到最终写入条件，或因家族上限、总槽位上限、特性类型槽位上限而不能立即写入已拥有状态时，本系统仍记录候选身份痕迹并提供模糊阶段。技能候选的 `candidate_progress_points` 来自技能计点表与 `skill_candidate_retained`；特性候选的 `candidate_progress_points` 来自特性计点表、`trait_candidate_points_after` 与 `trait_candidate_retained`。这些阶段只表示“这名球员正在留下怎样的成长痕迹”，不表示任务进度、解锁承诺或最优路线。玩家只能看到阶段标签、阻塞说明、真实可执行或不可点击的低压力方向建议和玩家词汇层解释，不看到精确点数或阈值。Player Detail 默认每名球员最多展示 2 条候选摘要；达到 `trace_emerging` 但未进入预算的候选必须折叠到统一的“更多成长倾向”分组，折叠入口不得显示数量、排行、百分比或“还差多少”。`trait_reliable_rotation` 因槽位阻塞而保留为候选时，若该球员没有其他已展示候选解释其普通/可靠身份路径，UI 必须把它提升到预算内或作为折叠分组首条摘要。
**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 候选进度点 | `candidate_progress_points` | int | ≥ 0 milli-points | 因未解锁、家族冲突或槽位冲突而保留的候选定点成长点 |
| 候选解锁阈值 | `candidate_unlock_threshold` | int | 8–36 points | 技能候选使用 8–30，特性候选使用 10–36；比较时必须乘以 1000；不得为 0 或负数 |
| 候选进度定点比 | `candidate_progress_milli` | int | ≥ 0 | 候选点数相对阈值的千分定点阶段值，可超过 1000；不得用 float 分类 |
| 候选可见阶段 | `candidate_visibility_stage` | enum | `none` / `trace_emerging` / `trace_consistent` / `trace_distinct` | 球员详情页展示的身份痕迹阶段；`none` 不展示为候选 |
| 每球员候选摘要预算 | `per_player_candidate_summary_budget` | int | 1–2 | Player Detail 默认可直接展示的候选摘要数量；Alpha 推荐 2 |
| 候选展示优先级 | `candidate_display_priority` | int | 0–99 | 用于候选摘要预算裁决的稳定优先级；不得暴露给玩家 |
| 阻塞原因 | `blocked_reason` | enum | `family_slot_occupied` / `total_skill_slots_full` / `trait_slot_occupied` / `below_threshold` | 当前候选未转正的主要原因；`below_threshold` 只表示痕迹尚浅，不表示失败或任务未完成 |
| 只读方向说明 | `context_hint_label_key` | string / null | 稳定本地化 key 或 null | 可选的低压力说明文案，只用于解释这条痕迹来自什么情境，不得渲染为按钮或任务清单 |
| 只读方向参数 | `context_hint_label_args` | Dictionary[String, String] | 0–N scalar pairs | `context_hint_label_key` 的字符串参数；不得包含对象、数组或嵌套字典 |

**Example:** 某同家族候选技能已积累 12000 milli-points，阈值为 20 points，`candidate_progress_milli = 600`，球员详情展示为“稳定倾向”。若该家族主技能槽位已被占用，详情页只展示槽位阻塞说明与只读身份痕迹文案（如“他在这一方向上留下了稳定表现”），不得显示行动按钮、精确点数、百分比、等待槽位空出或清槽建议。

### 12. 最小数据契约

技能与特性系统的实现必须以稳定标量字段为边界，避免直接传递可变运行时对象。所有跨系统 payload 字段只能使用 string、int、float、bool、enum code、稳定 ID、按明确定义排序的数组，或由上述标量组成的浅层 typed dictionary；不得把 Godot `Resource`、Node、Callable、运行时 `Dictionary` 默认 hash、未排序数组、任意 Variant blob 或 UI 本地状态写入稳定契约。所有 `*_label_args` 只允许 `Dictionary[String, String]`，键和值都必须是已规范化文本标量。所有 `*_state_delta` 必须是按 `change_type` 判别的浅层 typed dictionary，只允许对应矩阵声明的字段；不得用一个宽泛稀疏 union 同时承载所有变化类型。以下字段是 Alpha 首版最小契约。

| Payload | Required fields | Producer / consumer | Rule |
|---|---|---|---|
| `skill_trait_settlement_input` | `settlement_id`, `settlement_type`, `settlement_time`, `season_or_date`, `player_id`, `source_system`, `confirmed_facts[]`, `rule_version` | 培养/比赛/阶段结算 → 技能与特性系统 | 只包含已确认事实，不包含 UI 预览或比赛中临时事件；`settlement_type` 只允许 `training_resolution`, `match_result`, `phase_settlement`, `season_closeout`；`confirmed_facts[]` 的每个元素都必须是稳定字段字典，最小字段为 `fact_type`, `fact_context`, `fact_point_class`, `fact_point_value`, `family_id`, `source_event_id`, `fact_order`，并按 `fact_order ASC, source_event_id ASC` 升序提供。`fact_context` 只允许 `training`, `match`, `phase`, `season`；`fact_point_value` 必须来自本 GDD 的固定计点表，不得由实现期临时估算 |
| `pre_match_skill_trait_snapshot` | `snapshot_id`, `settlement_id`, `player_id`, `context_modifier_summary[]`, `owned_trait_ids[]`, `effect_summary[]`, `summary_label_key`, `summary_label_args`, `snapshot_locked_at`, `skill_trait_snapshot_status`, `snapshot_schema_version`, `rule_version` | 技能与特性系统提供浅层 read model；比赛系统拥有赛前 wrapper 并输出给比赛表现 UI | 赛前锁定后只读；生成时必须 copy-on-build 为顶层浅层 typed dictionary + 明确排序的浅层 record arrays。顶层字段只能是 string、int、float、bool、enum code、稳定 ID、`Dictionary[String, String]` label args 或 record array；record array 的元素也只能包含标量字段、`Dictionary[String, String]` label args、稳定 ID 数组，不得再嵌套任意 Dictionary/Array。禁止保留 live player state、Resource、Node、Callable、Object、Variant blob 或运行时容器引用。`owned_trait_ids[]` 按 `trait_id ASC` 排序，只用于解释和身份历史。`context_modifier_summary[]` 的最小元素字段为 `context_id`, `aggregated_skill_modifier`, `skill_training_modifier_milli`, `skill_training_multiplier_milli`, `player_skill_match_modifier_milli`, `applicable_skill_count`, `applicable_trait_ids[]`, `effect_summary_ids[]`，数组按 `context_id ASC` 排序；其中 `applicable_trait_ids[]` 与 `effect_summary_ids[]` 分别按 `trait_id ASC`、`effect_summary_id ASC` 排序，且 trait 只提供解释摘要，不进入数值修正。`effect_summary[]` 的最小元素字段为 `effect_summary_id`, `subject_id`, `subject_type`, `context_id`, `summary_label_key`, `summary_label_args`, `display_order`，并按 `display_order ASC, effect_summary_id ASC` 排序。比赛系统和 UI 只能消费按上下文锁定后的聚合结果与摘要，不再逐项叠加原始技能效果；比赛系统必须把该 read model 包装为 `team_skill_trait_summary` 后再推导 `skill_trait_match_mod`。任何读侧不得 mutation 快照字段，若实现语言无法强制只读，消费方必须先复制到本地 view model |
| `pending_skill_trait_feedback` | `feedback_key`, `settlement_id`, `player_id`, `change_type`, `subject_id`, `subject_rule_version`, `before_state_delta`, `after_state_delta`, `display_reason_key`, `display_reason_args`, `display_priority`, `display_order`, `attention_state`, `surface_state`, `first_surface_id`, `first_surface_route_id`, `last_surface_id` | 技能与特性系统 → 主循环 UI/球员管理 UI/比赛表现 UI | 未确认前必须持久化；`feedback_key` 是全局唯一领域主键，由 `settlement_id + player_id + change_type + subject_id` canonical 生成，不包含 `first_surface_id`；`before_state_delta` / `after_state_delta` 必须符合 `change_type` state delta matrix；UI 确认后请求写入 `feedback_ack`。`attention_state` 是是否仍需要玩家注意的唯一真相，只允许 `needs_first_surface`, `awaiting_ack`, `needs_followup`, `acknowledged`；`surface_state` 只记录路由/展示阶段，只允许 `not_routed`, `queued_for_first_surface`, `shown_on_first_surface`, `deferred_to_followup_notice`, `seen_as_detail_followup`。`first_surface_id` 在 Alpha 只能是 `match_result` 或 `main_loop`，`first_surface_route_id` 必须指向可恢复容器（如 `match_result:<settlement_id>`、`training_growth_summary:<settlement_id>`、`phase_growth_summary:<settlement_id>`、`season_growth_summary:<season_id>`）。合法持久化组合只有：`needs_first_surface/not_routed`、`needs_first_surface/queued_for_first_surface`、`awaiting_ack/shown_on_first_surface`、`needs_followup/deferred_to_followup_notice`、`needs_followup/seen_as_detail_followup`、`acknowledged/shown_on_first_surface`、`acknowledged/seen_as_detail_followup`。合法迁移链为：创建时 `needs_first_surface/not_routed`；挂入可恢复首曝容器时 `needs_first_surface/queued_for_first_surface`；首曝容器中的具体反馈卡片进入展示预算并实际渲染时转为 `awaiting_ack/shown_on_first_surface`；玩家确认已展示记录时同次写入 `feedback_ack` 并把 `attention_state = acknowledged`，保留最后合法 `surface_state`。若首曝容器因读档、导航或展示预算不可恢复而改由 Home/Roster/Growth Summary 未读入口承接，则转为 `needs_followup/deferred_to_followup_notice`；玩家从该入口进入 Player Detail 或 Growth Summary 补读并实际看到该记录时可转为 `needs_followup/seen_as_detail_followup`。任一可确认状态写入 `feedback_ack` 后必须同次原子更新为 `attention_state = acknowledged`。Player Detail 只能把 `attention_state = needs_followup` 或 `awaiting_ack` 且 `surface_state = shown_on_first_surface`、`deferred_to_followup_notice` 或 `seen_as_detail_followup` 的记录作为补读/历史条目展示，确认后写入全局 `feedback_ack`，不得把 `not_routed` 或 `queued_for_first_surface` 记录渲染为首次新提示；任何 UI 不得仅因打开容器或进入详情页就把记录视为已看见。任一未列出的 state pair 必须被拒绝并返回 `skill_trait_invalid_feedback_state_pair` |
| `candidate_progress_record` | `candidate_record_id`, `last_source_settlement_key`, `player_id`, `subject_id`, `subject_type`, `subject_rule_version`, `family_id`, `candidate_progress_points`, `candidate_progress_milli`, `candidate_visibility_stage`, `candidate_display_priority`, `blocked_reason`, `blocked_reason_label_key`, `blocked_reason_label_args`, `context_hint_label_key`, `context_hint_label_args`, `display_order` | 技能与特性系统 → 球员管理 UI/存档系统 | `candidate_record_id` 是稳定 upsert 主键，生成规则为 `sha256_utf8_hex(canonical_join([normalize_scalar(player_id), normalize_scalar(subject_type), normalize_scalar(subject_id)], "|"))`；字段裁剪、转义和小写十六进制输出规则与稳定结算键相同，`last_source_settlement_key` 只记录最近一次更新来源，不得作为记录身份。候选表示身份痕迹，不自动挤掉已拥有技能/特性；UI 只展示模糊身份阶段、阻塞说明、最近原因和只读身份说明，不展示点数、阈值、百分比、候选数量或候选排行；`candidate_progress_milli` 只供阶段分类和排序校验，不得暴露给玩家。`context_hint_label_key` / `context_hint_label_args` 只能提供不可点击的低压力说明，UI 不得把候选记录渲染为行动按钮、任务清单、隐藏规则页或训练跳转。Alpha 禁止写入 `wait_for_slot`、`clear_slot`、`reroll_trait`、`save_scum` 或任何当前版本不可执行的伪建议 |
| `trait_trigger_effect_record` | `settlement_key`, `settlement_id`, `player_id`, `trait_id`, `trigger_context`, `trigger_reason_key`, `trigger_reason_args`, `effect_applied`, `effect_summary_ids[]`, `visible_feedback_generated`, `cooldown_counter_after`, `rule_version` | 技能与特性系统 → 存档系统/比赛表现 UI | 记录幕后特性效果生效事实；不等同于可见反馈，不创建新提示；同一 `trait_trigger_effect` 作用域结算键只能存在一条，`visible_feedback_generated` 标记本次是否另有 `trait_trigger_visible`。`effect_summary_ids[]` 只能包含稳定摘要 ID，按 `effect_summary_id ASC` 排序，不得包含嵌套字典、数值 modifier blob 或运行时对象 |
| `trait_cooldown_state` | `player_id`, `trait_id`, `last_visible_feedback_settlement_id`, `settlements_since_last_visible_trigger`, `trait_visible_cooldown_window`, `rule_version` | 技能与特性系统 → 存档系统 | 仅限制重复可见反馈；读档后必须继续沿用，不因恢复而重置冷却；每条相关 `trait_trigger_effect` 结算都必须更新或确认 `settlements_since_last_visible_trigger`，生成 `trait_trigger_visible` 时写入 `last_visible_feedback_settlement_id = current_settlement_id` 并把计数重置为 0 |
| `anti_grind_window_state` | `player_id`, `family_id`, `recent_low_value_fact_types[]`, `recent_settlement_ids[]`, `repeated_low_value_fact_count_in_window`, `last_reset_reason`, `rule_version` | 技能与特性系统 → 存档系统 | 持久化低价值重复事实窗口；数组按发生顺序保存，最多 3 条；读档后继续用于 `repeated_fact_weight_milli`，不得重置为首次命中 |
| `reliable_rotation_accumulator_state` | `player_id`, `trait_id`, `reliable_rotation_accumulator_milli`, `last_scored_season_id`, `last_scored_settlement_id`, `reliable_rotation_season_settlement_id`, `reliable_rotation_season_settlement_key`, `season_score_milli`, `rule_version` | 技能与特性系统 → 存档系统 | 持久化普通球员可靠性身份路径；`reliable_rotation_season_settlement_id` 必须来自唯一赛季收口结算，同一球员同一赛季只允许通过 `reliable_rotation_season_settlement_key` 入账一次，槽位被占用时仍驱动 `candidate_progress_record` |
| `feedback_ack` | `feedback_key`, `settlement_id`, `player_id`, `ack_surface_id`, `ack_timestamp`, `settlement_key`, `ack_rule_id`, `feedback_key_aliases[]` | UI → 技能与特性系统/存档系统 | 已确认反馈的长期确认事实；`feedback_key` 是唯一确认主键，`settlement_key` 使用通用稳定结算键公式生成，其中 `consumer_scope = feedback_ack`，`rule_id = feedback_key`，`ack_rule_id = feedback_key`，`settlement_id` 保持原反馈所属结算 ID；不得用固定字符串 `feedback_ack` 作为 `rule_id`。同一 `feedback_key` 已存在确认时，后续确认请求必须返回 existing-ack 结果，不得新增第二条确认、不得覆盖原 `ack_surface_id`、不得改变技能/特性领域状态。若迁移导致 `subject_id` 改名并产生新 `feedback_key`，迁移必须把旧键写入 `feedback_key_aliases[]` 或 `skill_trait_migration_record` 的 alias 字段；读档、回看或迁移重放时任一 alias 已确认都视为该领域反馈已确认，不得再次作为新提示展示。若两个 alias 指向不同领域事实或同一 alias 被两个新反馈声明，迁移必须失败并返回 `skill_trait_feedback_alias_collision` |
| `player_identity_history_entry` | `history_id`, `settlement_id`, `player_id`, `event_type`, `subject_id`, `subject_rule_version`, `before_state_delta`, `after_state_delta`, `season_or_date`, `display_reason_key`, `display_reason_args`, `display_priority`, `history_surface_state`, `display_order` | 技能与特性系统 → 球员管理 UI/存档系统 | 解锁、升级、新增、变化和关键触发都必须写入；`history_surface_state` 只记录历史条目是否可在身份历史中展示，不参与反馈确认生命周期；`Player Detail` 身份历史以此为唯一来源，默认按 `season_or_date DESC, display_order ASC, history_id ASC` 排序 |
| `skill_trait_migration_record` | `migration_id`, `from_rule_version`, `to_rule_version`, `old_subject_id`, `new_subject_id`, `migration_type`, `preserved_level`, `preserved_progress`, `history_policy`, `old_feedback_key_aliases[]`, `processed_key_aliases[]` | 技能与特性系统 → 存档系统 | 旧 ID 映射、合并、废弃、反馈确认 alias、已处理结算键 alias 和历史保留的持久记录；不得用显示名或数组顺序推断迁移。迁移后旧 `feedback_key`、旧 `processed_settlement_keys`、候选记录、反刷窗口、特性冷却和可靠轮换累计都必须按 alias 或显式映射保真，避免旧结果重放成新提示或新成长 |

#### State Delta Matrix

| `change_type` | Required before fields | Required after fields | Forbidden fields | Notes |
|---|---|---|---|---|
| `skill_unlocked` | `state_code_before = locked`, `progress_milli_before` | `state_code_after = unlocked`, `level_after`, `progress_milli_after`, `subject_id_after` | `trait_id`, `old_trait_id` | `level_after` 必须为 1；溢出进度写入 `progress_milli_after` |
| `skill_upgraded` | `state_code_before = unlocked`, `level_before`, `progress_milli_before` | `state_code_after = unlocked`, `level_after`, `progress_milli_after`, `subject_id_after` | `trait_id`, `old_trait_id` | `level_after > level_before`，不得超过上限 |
| `skill_progress_updated` | `state_code_before = unlocked`, `level_before`, `progress_milli_before` | `state_code_after = unlocked`, `level_after = level_before`, `progress_milli_after`, `subject_id_after` | `trait_id`, `old_trait_id` | 已拥有技能获得普通进度但未跨升级阈值时使用；仍必须写入来源结算键，不能只更新内存进度 |
| `trait_added` | `state_code_before = not_owned` | `state_code_after = owned`, `subject_id_after`, `trait_type_after` | `level_before`, `level_after` | 只能由 `trait_added = true` 写入 |
| `trait_changed` | `state_code_before = owned`, `subject_id_before`, `trait_type_before`, `change_reason_key` | `state_code_after = owned`, `subject_id_after`, `trait_type_after`, `change_policy`, `old_trait_history_policy` | `level_before`, `level_after` | Alpha 首版仅允许显式配置的变化；旧特性去向必须明确为 `deprecated_history_only`、`replaced_by_new_trait` 或 `merged_into_new_trait` |
| `trait_trigger_effect` | `state_code_before = owned`, `subject_id_before`, `cooldown_before` | `state_code_after = owned`, `subject_id_after`, `effect_applied = true`, `trigger_context`, `cooldown_after` | `level_before`, `level_after` | 只表示规则层效果生效，不代表新增特性或可见反馈 |
| `trait_trigger_visible` | `state_code_before = owned`, `subject_id_before`, `cooldown_before` | `state_code_after = owned`, `subject_id_after`, `cooldown_after`, `visible_feedback_generated = true` | `level_before`, `level_after` | 只表示可见解释，不代表新增特性 |
| `candidate_updated` | `progress_milli_before`, `candidate_visibility_stage_before` | `progress_milli_after`, `candidate_visibility_stage_after`, `blocked_reason`, `context_hint_label_key` | `level_before`, `level_after` | 可用于技能候选与特性候选；UI 仍不显示精确点数、行动按钮或训练跳转 |

#### Durable Result Companion Matrix

| Outcome in durable settlement result | Required companion records in same atomic commit | If missing on save/load validation |
|---|---|---|
| `skill_unlocked` | owned skill state, source `settlement_key`, `evaluated_settlement_keys`, `processed_settlement_keys`, `pending_skill_trait_feedback`, `player_identity_history_entry` | `skill_trait_snapshot_invalid_partial_commit` |
| `skill_upgraded` | updated skill level/progress, source `settlement_key`, `evaluated_settlement_keys`, `processed_settlement_keys`, `pending_skill_trait_feedback`, `player_identity_history_entry` | `skill_trait_snapshot_invalid_partial_commit` |
| `skill_progress_updated` | updated skill progress, source `settlement_key`, `evaluated_settlement_keys`, `processed_settlement_keys`; `player_identity_history_entry` only when the progress crosses a visible milestone | `skill_trait_snapshot_invalid_partial_commit` |
| `candidate_updated` | `candidate_progress_record` upserted by `candidate_record_id`, `last_source_settlement_key`, `evaluated_settlement_keys`, `processed_settlement_keys`, `anti_grind_window_state` when caused by low-value repeated facts; `reliable_rotation_accumulator_state`, `reliable_rotation_season_settlement_key`, insertion of that season key into `evaluated_settlement_keys`, and insertion into `processed_settlement_keys` only when a candidate durable outcome was written | `skill_trait_snapshot_invalid_partial_commit` |
| `trait_added` | owned trait state, source `settlement_key`, `evaluated_settlement_keys`, `processed_settlement_keys`, `pending_skill_trait_feedback`, `player_identity_history_entry`, `reliable_rotation_accumulator_state` and `reliable_rotation_season_settlement_key` when subject is `trait_reliable_rotation` | `skill_trait_snapshot_invalid_partial_commit` |
| `trait_changed` | updated owned trait state, old trait history policy, source `settlement_key`, `evaluated_settlement_keys`, `processed_settlement_keys`, `pending_skill_trait_feedback`, `player_identity_history_entry`, `skill_trait_migration_record` when change uses migration/merge semantics | `skill_trait_snapshot_invalid_partial_commit` |
| `trait_trigger_effect` | `trait_trigger_effect_record`, source `settlement_key`, `evaluated_settlement_keys`, `processed_settlement_keys`, updated `trait_cooldown_state` with `settlements_since_last_visible_trigger` advanced or reset according to visibility result | `skill_trait_snapshot_invalid_partial_commit` |
| `trait_trigger_visible` | visible feedback record, source `settlement_key`, `evaluated_settlement_keys`, `processed_settlement_keys`, `pending_skill_trait_feedback`, `player_identity_history_entry`, updated `trait_cooldown_state` with `last_visible_feedback_settlement_id = current_settlement_id` | `skill_trait_snapshot_invalid_partial_commit` |
| `feedback_ack` | `feedback_ack`, `feedback_key`, ack `settlement_key`, `evaluated_settlement_keys`, `processed_settlement_keys`, updated `pending_skill_trait_feedback.attention_state = acknowledged` with preserved legal `surface_state` | `skill_trait_snapshot_invalid_partial_commit` |
| `settlement_noop` | source `settlement_key`, `evaluated_settlement_keys`; no mutation to owned skill/trait state, candidates, feedback or history | `skill_trait_snapshot_invalid_partial_commit` |
| `migration_applied` | `skill_trait_migration_record`, migrated state, migrated history policy, processed migration key, `evaluated_settlement_keys` / `processed_settlement_keys` aliases as declared | `skill_trait_snapshot_invalid_partial_commit` |

### Formula Ownership Notes

- 本系统拥有技能/特性的解锁、升级、触发、家族上限和反馈挂接公式。
- 数值系统拥有全局安全边界和上下文修正总上限；若 `context_modifier_cap` 与数值系统冲突，以数值系统为准并回修本 GDD。
- 比赛系统和培养系统消费本系统输出的不可变 read model，不重算技能/特性资格。
- 球员管理 UI 和比赛表现 UI 只消费本系统输出的展示 payload；候选阶段、阻塞原因、只读方向说明、反馈确认状态和身份历史语义均由本系统拥有。
- `candidate_progress_record`、`pending_skill_trait_feedback`、`feedback_ack` 和技能/特性状态结果的权威写入者为技能与特性系统；`pre_match_skill_trait_snapshot` 的技能/特性 read model 由本系统提供，但赛前锁定 wrapper 的权威写入者是比赛系统；`skill_trait_migration_record` 的迁移边界由存档系统拥有。
## Edge Cases

- **If 技能解锁阈值配置为 0 或负数**: 这是非法配置，技能判定必须拒绝该规则并记录配置错误；不得用 `max(1, threshold)` 自动吞掉错误并继续解锁。
- **If 特性候选阈值或可靠轮换阈值配置为 0 或负数**: 这是非法配置，特性判定必须拒绝该规则并记录配置错误；不得用 `max(1, threshold)` 自动吞掉错误并继续新增特性或候选。
- **If 同一结算节点满足多个技能解锁条件**: 系统必须先按家族分组裁决。若技能属于不同家族且总技能槽位足够，可同时解锁；若不同家族同时满足条件但总技能槽位不足，则按 `unlock_rank_milli DESC → candidate_priority DESC → skill_id ASC` 的全局稳定顺序只解锁剩余槽位允许的前 N 个，其余记录为候选进度。若属于同一家族，只解锁 `unlock_rank_milli` 最高者；若进度比相同，再按 `candidate_priority`，最后按 `skill_id` 字典序裁决。
- **If 同一技能一次结算跨越多个升级阈值**: 系统必须按等级顺序逐级升级，直到达到等级上限或进度不足；首次解锁溢出点和后续升级溢出进度都按 `remaining_skill_progress` 保留。
- **If 已满级技能继续获得进度**: 进度可记录为历史成长统计，但不得继续提升等级或突破 `skill_level_cap`。
- **If 技能升级和特性新增同时发生**: 反馈必须挂接到统一结算流中，按技能变化 → 特性变化的顺序写入 `pending_skill_trait_feedback`，不得形成高压弹窗链。
- **If 读档后重复收到同一训练或比赛结果**: 已存在相同稳定结算键于 `evaluated_settlement_keys` 时，系统必须直接返回 idempotent no-op；技能/特性变化不得重复授予、重复升级、重复添加或重复展示。若 key 只存在于 `processed_settlement_keys` 但缺少 `evaluated_settlement_keys` companion，快照复检必须返回 `skill_trait_snapshot_invalid_partial_commit`。
- **If 球员位置变化导致原技能适用性下降**: 技能保留，但 `context_match_ratio` 可以降低；不得静默删除技能，也不得自动替换成新位置技能。
- **If 技能效果与战术、设施或属性加成叠加过强**: 本系统只输出已封顶的纯技能/特性 read model；培养系统和比赛系统必须分别在自己的公式中组合训练、比赛、属性、战术、设施与状态修正，不得要求本系统输出混合后的上下文修正字段，也不得绕过各自系统的最终上限。
- **If 同一特性在同一结算中多次满足触发条件**: 只写入一条 `trait_trigger_effect` 记录；若本次也满足可见条件，再额外写入一条 `trait_trigger_visible` 记录，其余命中合并为同一解释，不重复展示。
- **If 同一特性连续多场都满足触发条件但未过冷却窗口**: 特性效果仍可继续生效并记录为内部命中，但不得重复创建可见触发反馈；达到 `trait_visible_cooldown_window` 后才允许再次进入可见解释。
- **If 同家族技能槽位已满但另一技能持续获得成长事实**: 系统必须写入或更新 `candidate_progress_record`，球员详情默认显示模糊阶段和槽位阻塞原因，不自动替换已拥有技能。
- **If 同一球员对同一技能家族连续命中低价值同类事实**: 系统必须按固定计点表中的 `repeated_fact_weight_milli` 递减记点，高价值事实与长期稳定标签不受该衰减影响；不得让低风险重复刷法成为最优成长路径。连续窗口固定为最近 3 次同球员、同家族相关结算，且该计数必须随候选/技能进度一起持久化，读档后不得重置。
- **If 普通或低评分球员没有高光事件但长期可靠出勤、低失误或位置适配稳定**: 系统必须在赛季收口节点按 `reliable_rotation_season_settlement_key` 更新一次 `reliable_rotation_accumulator_state`，允许其累积 `trait_reliable_rotation` 或相关候选进度；阶段结算只能展示预览或候选说明，不得多次累加入跨赛季 accumulator，不得只让进球、助攻、高评分球员获得身份记录。
- **If `trait_reliable_rotation` 达到阈值但核心身份槽位已被占用**: 系统不得自动替换旧核心身份，也不得丢弃可靠轮换成长；必须更新 `candidate_progress_record`，展示低压力方向建议，并在 `player_identity_history_entry` 中保留普通球员可靠性成长事实。
- **If 技能/特性变化写入反馈但未写入 `player_identity_history`**: 视为设计违规；可见变化和关键触发都必须能在球员详情历史中回看。
- **If durable settlement result 中任一 outcome 已写入但 Durable Result Companion Matrix 声明的同次 companion records 缺失**: 该快照视为非法半提交状态，存档复检必须返回 `skill_trait_snapshot_invalid_partial_commit`，并拒绝作为标准成功读档结果恢复；实现必须通过同一个 durable settlement result 原子提交状态、反馈、身份历史、候选/冷却变化、反刷窗口、可靠轮换累计和处理键。`skill_progress_updated` 不得只修改技能进度字段而遗漏来源 `settlement_key` 与 `processed_settlement_keys`；`trait_reliable_rotation` 的候选更新不得遗漏 `reliable_rotation_accumulator_state` 与通用 canonical 生成的 `reliable_rotation_season_settlement_key`。
- **If 赛前快照已生成后球员 live state 又发生技能/特性变化**: 当前比赛仍使用已 copy-on-build 锁定的 `pre_match_skill_trait_snapshot`；比赛表现 UI 也只能展示该快照的 `summary_label_key`、`summary_label_args`、`context_modifier_summary[]` 和 `effect_summary[]` 摘要；新变化只能影响后续稳定结算或下一场比赛。实现不得让快照持有可变 player dictionary、Resource、Node、Object、Callable、Variant blob、未排序数组或嵌套运行时 Dictionary/Array 引用；快照只能由顶层浅层 typed dictionary 与已声明的浅层 record arrays 组成。若输入包含未声明的嵌套集合或运行时引用，系统必须拒绝构建该快照并返回 `skill_trait_invalid_snapshot_contract`，再由比赛系统使用安全默认摘要；不得递归修复后继续展示。
- **If 比赛系统在合法 fallback 场景下缺少 `pre_match_skill_trait_snapshot` 或快照版本不匹配**: 比赛仍可按比赛系统定义的安全默认值执行，但必须输出 `skill_trait_snapshot_status = missing_safe_default` 或 `version_mismatch_safe_default`，本系统不得在赛后回补赛前效果、不得生成技能/特性触发解释，只能在后续稳定节点继续处理新的训练、比赛或阶段事实。
- **If 负面特性造成玩家厌恶或惩罚感**: Alpha 首版不得引入强惩罚型负面特性；已出现惩罚感的特性必须改为中性解释或从池中移除。
- **If Alpha 初期 UI 尚未完整展示技能图鉴**: 球员详情页仍必须展示已拥有技能/特性、等级、适用场景、候选倾向、阻塞原因和最近解锁原因；不得只显示无解释标签。
- **If `candidate_progress_record.blocked_reason` 存在但缺少 `blocked_reason_label_key`**: UI 可以回退到稳定原因码映射的通用说明；若稳定原因码也缺失，该候选记录视为不完整，不得在 UI 中显示为正常候选。
- **If 技能/特性反馈在展示前保存并读档**: 未确认反馈必须继续待展示；已确认反馈不得再次弹出，但可在球员详情历史中查看。
- **If `feedback_ack` 已持久化但 UI 回看同一比赛结果或球员详情**: UI 可以展示历史解释入口，但不得重新创建 `pending_skill_trait_feedback` 或把该反馈放回新提示队列。
- **If 后续版本调整 `first_surface_id` 或同一反馈从不同界面被确认**: `feedback_key` 仍必须保持不变，因为它不包含展示面；已确认反馈不得因首次展示路由变化而重新作为新提示出现。
- **If 候选进度、特性冷却或 `processed_settlement_keys` 在存档中缺失**: 该技能/特性状态快照视为不完整，不得通过重新读取培养、比赛或 UI 缓存来猜测补齐。
- **If 读档后恢复到技能/特性半结算节点**: 这是非法恢复点；存档复检必须返回 `skill_trait_snapshot_invalid_partial_commit`，系统必须只恢复到 `Atomic Commit Durable Result` 完成后的 `Skill Idle`，或完全看不到该 durable result；不得恢复事实收集、评估或组装中的中间状态。
- **If 旧版本迁移后 `skill_trait_migration_record` 缺失**: 迁移结果不得视为可追溯；存档系统必须判定复检失败或要求补齐迁移记录。
- **If UI 确认 `pending_skill_trait_feedback`**: UI 只能发起 `feedback_ack`，不得直接修改技能等级、候选进度、特性状态或身份历史；同一 `feedback_key` 的确认必须对所有界面同时生效。
- **If 技能/特性反馈与声望增长、成就完成同时触发**: 主循环 UI 必须先展示核心训练/比赛结果，再展示技能/特性变化，再展示声望/成就；不得反向排序。
- **If 旧版本技能或特性被重命名、合并或废弃**: 存档迁移必须使用稳定 ID 映射，保留玩家已确认的长期成长记录，避免丢失球员身份感。
- **If 两个旧技能合并为一个新技能**: 新技能等级取较高旧等级，进度取两者剩余进度中较高值，历史记录保留两个旧 ID 的来源。
- **If 技能被删除且无新技能可映射**: 该技能进入 `Deprecated Skill/Trait`，不参与效果计算，但在历史成长记录中保留名称、等级和来源。

## Dependencies

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 定义低压力长期成长和球员养成幻想 | 长期成长支柱、反高压约束 |
| `design/gdd/systems-index.md` | Hard | 定义本系统在 Alpha 层的位置和依赖方向 | 系统优先级、上下游关系 |
| `design/gdd/balance-system.md` | Hard | 提供技能效果、安全倍率和成长节奏边界 | 效果强度范围、叠加上限、成长目标带 |
| `design/gdd/player-development-system.md` | Hard | 提供训练、成长、潜力与球员状态事实 | 训练结果、属性成长、潜力阶段、球员状态标签、稳定结算 ID |
| `design/gdd/match-competition-system.md` | Hard | 提供比赛表现、关键事件和赛后表现事实，并消费赛前不可变技能快照 | 比赛结果包、关键事件、位置表现、赛后标签、稳定结算 ID、赛前技能效果快照入口 |
| `design/gdd/save-and-load-system.md` | Hard | 保存技能等级、技能进度、候选进度、特性状态、可见触发冷却、身份历史、稳定结算键、反馈确认状态和迁移历史 | 稳定节点保存、恢复、迁移边界、快照复检结果 |
| `design/gdd/main-loop-ui-framework.md` | Hard | 定义技能/特性反馈在统一结算流中的展示位置 | 核心结果 → 技能/特性 → 声望/成就 → 其他奖励的反馈顺序 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 技能与特性系统 | What must be back-referenced later |
|---|---|---|---|
| `design/gdd/reputation-and-achievement-system.md` | Soft | 技能/特性里程碑、风格化成长标签 | 必须声明其只消费里程碑事实，不决定技能/特性解锁 |
| `design/gdd/player-management-ui.md` | Hard | 技能列表、特性标签、等级/进度、候选阶段、阻塞原因、解锁原因、待确认反馈、身份历史 | 必须声明其展示来自本系统的权威状态，不再作为未设计占位 |
| `design/gdd/match-performance-ui.md` | Soft | 赛前快照摘要、技能/特性对赛后表现的轻量解释、反馈确认入口 | 必须声明其只展示影响，不重算效果、条件或候选状态 |
| 教程与提示系统 | Soft | 技能/特性的解释文案和首次提示锚点 | 必须声明其提示口径不把技能系统包装成高压 build 系统 |

### Dependency Rules

1. 技能与特性系统拥有技能/特性的定义、状态、进度、解锁、升级、触发、迁移和反馈 payload；其他系统只能提供事实或消费结果。
2. 培养系统不得直接写入技能/特性状态；比赛系统不得在比赛进行中解锁或升级技能/特性；声望系统不得反向决定技能/特性条件。
3. 存档系统保存本系统状态，但不定义技能/特性含义、候选阶段、反馈确认语义或迁移结果含义。
4. 主循环 UI 框架负责展示顺序和容器，不拥有技能/特性判定。
5. 球员管理 UI 和比赛表现 UI 可以确认反馈，但确认动作必须回写为 `feedback_ack`；UI 不拥有 `attention_state` 或 `surface_state` 的领域语义。
6. 若任何下游系统需要新增技能/特性字段、改变反馈顺序或绕过家族上限，必须先回到本系统修订。

## Tuning Knobs

| Knob | Linked formula / rule | Safe range | 调高影响 | 调高风险 | 调低影响 | 调低风险 | QA observation |
|---|---|---|---|---|---|---|---|
| 技能数量上限 | Alpha scope | 6 个首批技能 | 球员差异化更丰富 | 学习成本升高，接近 build 压力 | 系统更易理解 | 球员风格不足 | 玩家能否在列表中记住技能含义 |
| 特性数量上限 | Alpha scope | 5 个首批特性 | 球员故事感更强 | 特性解释变稀释 | 特性更有记忆点 | 球员长期差异不足 | 玩家是否能用特性描述球员 |
| 单名球员可拥有技能数量 | Family Limit Rules | 2–3 个 | 培养空间更大 | 最优组合压力增加 | 更容易形成清晰定位 | 成长深度不足 | 多赛季球员是否仍有成长目标 |
| 同一家族主技能上限 | Family Limit Rules | 1 个 | 可防止同类堆叠 | 限制过硬时玩家可能想不通 | 组合更自由 | build 压力升高 | 同家族技能是否被同时自动解锁 |
| 单名球员可拥有特性数量 | Family Limit Rules | 1–2 个 | 身份标签更丰富 | 标签堆叠难读 | 身份更聚焦 | 差异表达不足 | 详情页标签是否可一眼读懂 |
| 核心身份特性上限 | Family Limit Rules | 1 个 | 身份更聚焦 | 后续新身份难展示 | 身份变化更自由 | 玩家难以记住主身份 | 是否出现互相冲突的身份标签 |
| 技能解锁阈值 `skill_unlock_threshold` | `unlock_rank_milli` | 8–30 点 | 解锁更稀有、更长期 | 玩家感知成长变慢 | 更快看到差异化 | 技能泛滥、身份稀释 | 首赛季是否至少出现少量可见解锁 |
| 技能升级阈值表 `level_thresholds[level]` | `available_upgrade_progress` | level 2–3, value 12–45 点 | 高级技能更稀有 | 成长停滞感 | 升级反馈更频繁 | 强度堆叠过快 | 同一球员是否过早满级 |
| 技能等级上限 `skill_level_cap` | `skill_level_after` | 3 | 长期成长空间更大 | 数值与 UI 复杂度上升 | 更易控制强度 | 成长目标不足 | 是否清楚看到等级含义 |
| 基础技能效果 `base_skill_effect` | `skill_effect_modifier` | 0–0.08 | 技能影响更明显 | 替代基础属性/阵容 | 效果更轻量 | 玩家感知不到技能 | 同场景有无技能差异是否可解释 |
| 技能效果上限 `skill_effect_cap` | `skill_effect_modifier` | 0.01–0.12 | 允许强风格表达 | 与战术/设施叠加过强 | 更安全 | 技能存在感不足 | 叠加后是否仍服从数值系统上限 |
| 聚合技能效果上限 `aggregated_skill_effect_cap` | `aggregated_skill_modifier` | 0.04–0.18 | 多技能组合更有存在感 | 技能堆叠压过阵容/战术 | 更安全 | 多技能同场无感 | 多技能同时适用时是否先聚合再封顶 |
| 技能训练倍率上限 `skill_training_multiplier_cap_milli` | `skill_training_multiplier_milli` | 1100–1350 | 技能训练影响更明显 | 训练收益压过基础培养与设施 | 更安全 | 技能训练反馈偏弱 | 训练 read model 是否仍只包含技能修正，且 trait 只进入解释摘要 |
| 候选进度阶段阈值 `candidate_visibility_stage` | `candidate_progress_milli` | 350 / 750 milli | 更早展示成长倾向 | 玩家误以为即将解锁 | 更保守 | 普通成长不易被看见 | 候选倾向是否能被理解且不过度精确 |
| 可靠轮换阈值 `reliable_rotation_threshold_milli` | `reliable_rotation_threshold_met` | 12000–18000 milli-points | 普通球员更早形成可靠身份 | 可靠身份过于常见 | 身份更稀有 | 普通球员路径不够可见 | 无高光普通球员是否能在 1–2 赛季内形成记忆点 |
| 可靠轮换累计上限 `reliable_rotation_accumulator_cap_milli` | `reliable_rotation_accumulator_after` | 20000–30000 milli-points | 长期可靠性更容易保留 | 历史累计过度压过近期事实 | 更强调近期表现 | 长期可靠球员被低估 | 长期普通球员身份是否稳定但不过强 |
| 低价值反刷窗口长度 `anti_grind_window_size` | `repeated_fact_weight_milli` | 3 次相关结算 | 更强抑制重复刷法 | 正常稳定培养也被压低 | 更宽松 | 安全重复刷法收益过高 | 读档后连续低价值事实是否继续衰减 |
| 特性可见冷却窗口 `trait_visible_cooldown_window` | `trait_cooldown_available` | 1–5 次相关结算 | 特性反馈更克制 | 特性像不存在 | 特性更常被玩家记住 | 反馈噪音增加 | 赛后反馈是否过于频繁或稀薄 |
| 同结算特性触发条数 | Trait Triggered | 1–2 条 | 解释更完整 | 信息过载 | 反馈更轻 | 触发原因被隐藏 | 同场比赛是否刷出多条同类解释 |
| 正向/负向/中性特性比例 | Trait pool | Alpha 首版以正向/中性为主，强负面为 0 | 风格对比更强 | 负面惩罚感 | 压力更低 | 取舍不足 | 是否出现“毁掉球员”的感受 |
| 单次结算可展示技能/特性反馈数量 | Feedback Pending | 1–3 条 | 玩家看到更多变化 | 弹窗链和信息负担 | 结算更轻 | 重要变化被延后 | 核心训练/比赛结果是否先被理解 |
| 待展示反馈保留期限 | Feedback Pending | 直到确认或赛季归档 | 防止反馈丢失 | 历史队列变长 | 存档更轻 | 读档后反馈丢失 | 未确认反馈读档后是否仍可见 |
| 已评估结算键保留策略 | `evaluated_settlement_keys` | 长期保留所有已评估消费键，含 no-op | 防旧事实重放更稳 | 存档体积上升 | 存档更轻 | 无变化消费可能被旧事件晚到重复评估 | 重复提交同一事件是否只返回 no-op |
| 已处理结算键保留策略 | `processed_settlement_keys` | 长期保留已产生 durable outcome 的键 | outcome companion 校验更清晰 | 需要与 evaluated 账本保持一致 | 存档更轻 | outcome 重放风险 | 已产生结果是否只处理一次 |

## Acceptance Criteria

- **GIVEN** `skill_unlock_threshold`、`trait_candidate_threshold` 或 `reliable_rotation_threshold_milli` 为 0 或负数，**WHEN** 系统加载或评估对应规则，**THEN** 必须拒绝该规则并记录配置错误，不得自动把阈值改为 1 或继续解锁技能/新增特性。
- **GIVEN** 球员某技能累计点数从 9000 增至 10000 milli-points，且 `skill_unlock_threshold = 10`、`skill_not_already_owned = true`、`family_slot_available = true`、`settlement_key_not_processed = true`，**WHEN** 训练结算事件进入技能判定，**THEN** 该技能必须从未解锁变为已解锁，初始等级写入为 1，并写入对应稳定结算键。
- **GIVEN** 球员已拥有某技能，当前等级为 1，`current_level_progress = 5000`、`incoming_skill_points = 30000`、等级 2 阈值为 12、等级 3 阈值为 18，等级上限为 3，**WHEN** 后续成长事件进入技能升级判定，**THEN** 该技能必须升至等级 3，剩余进度为 5000 milli-points，并记录来源稳定结算键。
- **[Unit] GIVEN** 某技能首次解锁阈值为 15 points，且球员在同一次结算中累计到 22000 milli-points，**WHEN** 系统完成首次解锁，**THEN** 该技能必须解锁为等级 1，且 7000 milli-points 溢出进度必须立即写入该技能的当前等级剩余进度，不得丢失。
- **[Unit] GIVEN** 球员已经拥有某技能，且后续结算再次进入升级判定，**WHEN** 系统计算 `available_upgrade_progress`，**THEN** `unlock_overflow_points` 必须为 0，只能使用 `current_level_progress + incoming_skill_points`，不得把历史累计点数再次计入升级进度。
- **GIVEN** 两份 `settlement_id`、`player_id`、`consumer_scope`、`rule_id` 完全相同但来源容器顺序不同的输入，且 `rule_version` 分别为 1 与 2，**WHEN** 系统生成 `settlement_key`，**THEN** 输出键必须一致；若 `settlement_id`、`player_id`、`consumer_scope` 或 `rule_id` 任一字段值不同，**THEN** 输出键必须不同。
- **GIVEN** 任一结算键源字段包含前后空白、分隔符 `|` 或转义符 `\`，**WHEN** 系统生成 `settlement_key_source`，**THEN** 字段必须先裁剪空白并执行反斜杠转义；**GIVEN** 任一结算键源字段为 `null`，**WHEN** 系统生成 `settlement_key`，**THEN** 必须拒绝该输入并记录配置或数据错误。
- **GIVEN** 两组候选、反馈或快照元素包含相同数据但输入数组顺序、资源表顺序或 Dictionary 遍历顺序不同，**WHEN** 系统执行裁决、展示排序或持久化排序，**THEN** 输出顺序必须完全一致，并以对应稳定 ID 作为最终 tie-breaker。
- **GIVEN** 同一 `settlement_key` 的训练或比赛结果被重复提交两次，**WHEN** 系统重新评估技能/特性，**THEN** 第一次评估无论是否产生 outcome 都必须写入 `evaluated_settlement_keys`；第二次提交必须返回 idempotent no-op，不得重复授予技能、重复升级、重复添加特性、重复记录 `trait_trigger_effect`、重复记录 `trait_trigger_visible` 或重复创建反馈记录。
- **GIVEN** 两个同家族技能在同一结算中同时满足解锁条件，且该球员同家族主技能槽位只剩 1 个，**WHEN** 系统执行技能解锁判定，**THEN** 必须只解锁 `unlock_rank_milli` 更高者；若进度比相同，则按 `candidate_priority`，再按 `skill_id` 字典序裁决，未被选中的技能保留候选进度但不写入已拥有技能列表。
- **GIVEN** 两个不同家族技能在同一结算中同时满足解锁条件，但该球员总技能槽位只剩 1 个，**WHEN** 系统执行技能解锁判定，**THEN** 必须按 `unlock_rank_milli DESC → candidate_priority DESC → skill_id ASC` 的全局稳定顺序只解锁 1 个技能，另一个写入候选进度且不得丢失其来源结算键。
- **GIVEN** 两个不同家族技能在同一结算中同时满足解锁条件，且该球员总技能槽位足够，**WHEN** 系统执行技能解锁判定，**THEN** 两个技能都必须解锁，各自写入独立稳定结算键和反馈记录。
- **GIVEN** 某未拥有技能达到解锁阈值但 `family_slot_available = false`，**WHEN** 系统执行技能解锁判定，**THEN** `skill_unlock_candidate` 仍为 true、`skill_unlocked` 为 false，并写入或更新 `candidate_progress_record`，其 `blocked_reason = family_slot_occupied`；不得因家族槽位占用而丢失候选进度。
- **GIVEN** 已拥有技能获得 4000 milli-points 但未跨越下一等级阈值，**WHEN** 系统完成结算，**THEN** 必须写入 `skill_progress_updated` outcome、更新技能当前等级进度、记录来源 `settlement_key` 并加入 `processed_settlement_keys`；读档复检缺少任一 companion 时返回 `skill_trait_snapshot_invalid_partial_commit`。
- **GIVEN** 某技能当前场景 `context_match_ratio = 0`，**WHEN** 比赛或训练系统请求该技能效果快照，**THEN** 技能必须保留在球员状态中，但本次 `skill_effect_modifier = 0`。
- **GIVEN** 球员位置变化导致已拥有技能不再匹配当前场景，**WHEN** 生成效果快照，**THEN** 技能仍保留在球员状态与历史记录中，只通过 `context_match_ratio` 降低或取消本次效果。
- **GIVEN** 同一球员对同一技能家族连续三次命中 `match_role_exposure_light = 1` 的低价值事实，且三次都在最近 3 次相关结算窗口内，**WHEN** 系统累计技能或候选进度，**THEN** 三次必须分别写入 1000、700、400 milli-points；保存并读档后继续相关结算不得重置该连续计数。
- **GIVEN** 同一球员在低价值连续窗口后命中 `training_focus_hit` 或 `key_positive_event` 等高价值事实，**WHEN** 系统累计技能或候选进度，**THEN** 该高价值事实不得套用低价值衰减，并必须重置该技能家族的低价值连续计数。
- **GIVEN** 三个适用技能分别产出 0.06、0.04、0.03，且 `aggregated_skill_effect_cap = 0.10`，**WHEN** 系统计算多技能聚合，**THEN** `aggregated_skill_modifier` 必须为 0.10，下游系统不得再次逐个叠加技能效果。
- **[Unit] GIVEN** 训练上下文中 `aggregated_skill_modifier = 0.06` 且 `skill_training_modifier_cap = 0.18`，**WHEN** 技能与特性系统生成训练 read model，**THEN** `skill_training_modifier_milli = 60` 且 `skill_training_multiplier_milli = 1060`；该输出不得包含 trait、属性、战术、设施、状态或比赛层修正。
- **[Unit] GIVEN** 比赛上下文中 `aggregated_skill_modifier = 0.09` 且 `player_skill_match_modifier_cap = 0.08`，**WHEN** 技能与特性系统生成赛前快照，**THEN** `player_skill_match_modifier_milli = 80`；最终 `skill_trait_match_mod` 必须由比赛系统从 `team_skill_trait_summary` 推导，本系统不得输出混合后的上下文修正字段。
- **[Integration] GIVEN** 球员拥有 `trait_reliable_rotation` 或其他 Alpha 特性，**WHEN** 系统生成训练或比赛 read model，**THEN** 这些 trait 只能输出 `trait_effect_summary_ids` / `effect_summary[]` 解释摘要，不得增加 `skill_training_modifier_milli`、`skill_training_multiplier_milli` 或 `player_skill_match_modifier_milli`。
- **GIVEN** 球员拥有 `trait_big_moment`，且 `trait_condition_satisfied = true`、`context_allows_trait = true`、`trait_effect_key_not_processed = true`、`visible_cooldown_available = true`、`feedback_budget_available = true`、`trait_visible_key_not_processed = true`，**WHEN** 比赛结算完成，**THEN** 系统必须写入一条 `trait_trigger_effect_record`，字段至少包含 `settlement_key`、`settlement_id`、`player_id`、`trait_id`、`trigger_context`、`trigger_reason_key`、`effect_applied = true`、`visible_feedback_generated = true`、`cooldown_counter_after` 和 `rule_version`，并额外写入一条 `trait_trigger_visible` 反馈。
- **GIVEN** 球员拥有某特性且连续两场相关比赛都满足触发条件，但第二场未达到 `trait_visible_cooldown_window`，**WHEN** 第二场赛后结算完成，**THEN** 系统必须继续记录 `trait_trigger_effect_record`，将 `visible_feedback_generated` 写为 false，并更新 `trait_cooldown_state.settlements_since_last_visible_trigger`；不得创建第二条可见 `trait_trigger_visible` 反馈。
- **GIVEN** 球员尚未拥有某特性，即使当前满足该特性的触发条件，**WHEN** 系统执行特性判定，**THEN** 不得写入 `trait_trigger_effect` 或 `trait_trigger_visible` 记录；只有满足新增条件且特性槽位可用时，才能写入 `trait_add` 记录。
- **GIVEN** 两个同类型特性在同一稳定结算中同时满足新增条件，且该类型槽位只剩 1 个，**WHEN** 系统执行特性新增判定，**THEN** 必须按 `trait_candidate_rank_milli DESC → trait_priority DESC → trait_id ASC` 只写入 1 个 `trait_added`，另一个写入或更新 `candidate_progress_record`，不得依赖资源表顺序。
- **GIVEN** 一名普通球员连续 2 个赛季出勤率 ≥ 80%、每赛季低失误标签 ≥ 6 次、可胜任位置 ≥ 2 个且训练完成率 ≥ 70%，但没有进球、助攻或高评分事件，**WHEN** 每个赛季的唯一赛季收口结算进入特性判定，**THEN** `reliable_rotation_accumulator_after` 必须达到 16000，若核心身份槽位为空则进入 `trait_added` canonical path，若核心身份槽位被占用则更新其 `candidate_progress_record` 和身份历史，且该特性不得提高任何射门、组织、防守或上下文表现上限字段。
- **[Integration] GIVEN** 同一球员同一赛季的 `reliable_rotation_season_settlement_key` 已存在于 `evaluated_settlement_keys`，**WHEN** 阶段结算、读档重放或赛季结算再次提交同一赛季可靠轮换分，**THEN** `reliable_rotation_accumulator_after` 必须保持等于提交前值，系统只返回 idempotent no-op，不得再次累加 `season_score_milli`，也不得重复写入候选记录、身份历史或反馈。
- **[Integration] GIVEN** `trait_reliable_rotation` 因核心身份槽位占用只更新候选而未转正，**WHEN** 系统提交 `candidate_updated` outcome，**THEN** 同次原子提交必须把 `reliable_rotation_season_settlement_key` 插入 `evaluated_settlement_keys`，并在确实写入候选 durable outcome 时插入 `processed_settlement_keys`；缺失对应 companion key 时存档复检必须返回 `skill_trait_snapshot_invalid_partial_commit`。
- **[Unit] GIVEN** 系统生成 `reliable_rotation_season_settlement_key`，**WHEN** QA 检查其源字段，**THEN** 该键必须使用通用 `settlement_key` 公式且 `settlement_id = reliable_rotation_season_settlement_id`、`consumer_scope = trait_reliable_rotation_season_score`、`rule_id = trait_reliable_rotation`；`reliable_rotation_season_settlement_id` 必须来自该 `scored_season_id` 的唯一 `season_closeout_settlement_id`，不得使用阶段预览 ID、临时字符串拼接或第二套 hash 规则。
- **[Manual] GIVEN** Alpha 内部测试至少推进 1 个完整赛季，且存在普通/低高光球员获得稳定出勤、低失误或位置覆盖事实，**WHEN** 测试者回看 Player Detail 和 Growth Summary，**THEN** 至少 1 名非明星球员应能通过 `trait_reliable_rotation` 候选痕迹、身份历史或补读摘要被测试者描述为“稳定完成任务的人”；测试记录中不得出现“需要清槽/刷词条/保护槽位才不浪费成长”的主观反馈作为通过结果。
- **GIVEN** 单次结算同时产生技能升级和特性新增，**WHEN** 系统写入 `pending_skill_trait_feedback`，**THEN** 反馈顺序必须为技能变化先于特性变化，且两者都位于核心训练/比赛结果之后、声望/成就之前。
- **[Integration] GIVEN** 单次结算同时产生 4 条技能/特性反馈，且单次展示上限为 3，**WHEN** 主循环 UI 展示结算结果，**THEN** 核心训练或比赛结果必须先显示，随后仅展示按 `display_priority DESC → display_order ASC → feedback_key ASC` 稳定排序后的前 3 条技能/特性反馈；前 3 条在具体反馈卡片实际渲染后写为 `attention_state = awaiting_ack` 且 `surface_state = shown_on_first_surface`，剩余 1 条必须继续保存在 `pending_skill_trait_feedback` 中，保留原 `feedback_key` 和 `display_order`，并保持 `attention_state = needs_first_surface` 且 `surface_state = queued_for_first_surface`，直到原 route 可恢复展示或转入 `deferred_to_followup_notice`。
- **[Integration] GIVEN** 新的 `pending_skill_trait_feedback` 写入，**WHEN** Alpha 首版任一 UI 消费该记录，**THEN** `first_surface_id` 只能是 `match_result` 或 `main_loop`，且 `first_surface_route_id` 必须指向可恢复容器；若玩家在首曝前打开 Player Detail，**THEN** 该界面不得把 `surface_state = not_routed` 或 `queued_for_first_surface` 的记录渲染为首次新提示、补读提示或可确认条目。
- **[Integration] GIVEN** `pending_skill_trait_feedback.attention_state` 和 `surface_state` 沿合法链路迁移，**WHEN** 玩家保存并读档，**THEN** 两个状态必须恢复一致，并且 Home/Roster/Player Detail 不得生成第二条新提示或改变原 `feedback_key`。
- **[Integration] GIVEN** 某反馈记录的 `attention_state = awaiting_ack` 或 `needs_followup`，且 `surface_state = shown_on_first_surface`、`deferred_to_followup_notice` 或 `seen_as_detail_followup`，**WHEN** 任一 UI 或恢复流程尝试把它迁回 `queued_for_first_surface` 或 `not_routed`，**THEN** 系统必须拒绝该迁移并返回 `skill_trait_invalid_feedback_state_transition`，且不得创建第二条反馈记录。
- **[Integration] GIVEN** 某反馈记录的 `attention_state = acknowledged`，**WHEN** 任一 UI 重复提交确认或尝试重新挂入首曝队列，**THEN** 系统必须返回 existing-ack / idempotent no-op，不得改变原 `ack_surface_id`、不得重建新提示。
- **GIVEN** 技能/特性反馈与声望增长、成就完成同时触发，**WHEN** 主循环 UI 挂接反馈，**THEN** 展示顺序必须是核心训练/比赛结果 → 技能/特性反馈 → 声望增长/成就完成 → 其他奖励与提示。
- **[Manual] GIVEN** 某同家族候选技能已积累 12000 milli-points、阈值为 20 points 且主技能槽位已被占用，**WHEN** QA 查看球员详情，**THEN** 必须显示候选身份阶段“稳定倾向”、身份痕迹说明和只读低压力说明，不显示精确点数、阈值、百分比、行动按钮或“快解锁但被卡住”的表述；若该记录未进入每球员 2 条候选摘要预算，必须出现在“更多成长倾向”折叠分组中，且不得显示清槽、重铸、读档或等待不可执行槽位变化的伪行动。
- **GIVEN** 同一球员存在 4 条 `candidate_progress_record`，且 `per_player_candidate_summary_budget = 2`，**WHEN** 球员管理 UI 消费这些记录，**THEN** 只能直接展示按 `candidate_display_priority DESC → display_order ASC → subject_id ASC` 排序后的前 2 条，其余进入折叠分组；界面不得显示候选排行、内部数量、百分比或“还差多少点”。
- **GIVEN** `trait_reliable_rotation` 因核心身份槽位占用而保留为候选，且该球员没有其他直接展示记录说明普通/可靠身份路径，**WHEN** Player Detail 应用候选摘要预算，**THEN** UI 必须把该记录纳入直接展示预算或作为折叠分组首条摘要，并展示低压力说明，不得建议清槽、重铸或读档。
- **GIVEN** `candidate_progress_record.blocked_reason = family_slot_occupied`、`blocked_reason_label_key` 已配置且 `context_hint_label_key` 已配置，**WHEN** 球员管理 UI 消费该记录，**THEN** 玩家必须能直接看到阻塞说明与只读身份痕迹说明，且该记录在未打开任何额外规则说明的情况下仍可被理解为“同家族槽位已被占用，这条成长方向已被记录”；UI 不得把该说明渲染为行动按钮或训练跳转。
- **GIVEN** `trait_changed = true` 写入 durable settlement result，**WHEN** QA 检查同次原子提交内容，**THEN** 必须同时存在更新后的 owned trait state、旧特性的 `old_trait_history_policy`、来源 `settlement_key`、`processed_settlement_keys`、`pending_skill_trait_feedback`、`player_identity_history_entry`，且在变化使用迁移或合并语义时存在 `skill_trait_migration_record`；缺少任一项时复检返回 `skill_trait_snapshot_invalid_partial_commit`。
- **GIVEN** 技能解锁、技能升级、特性新增、特性变化或关键触发成功写入，**WHEN** QA 查看 `player_identity_history`，**THEN** 必须存在对应历史条目，包含发生时间/赛季、来源结算、变化前后状态和玩家可读解释。
- **GIVEN** 玩家保存并读档，**WHEN** 检查球员已确认技能状态，**THEN** 已拥有技能 ID、技能等级、当前等级剩余进度、累计进度和来源稳定结算键必须恢复一致。
- **[Integration] GIVEN** 玩家保存并读档，**WHEN** 检查候选进度状态，**THEN** `candidate_progress_record` 的 `candidate_record_id`、候选阶段、阻塞原因、只读方向说明、`display_order` 和 `last_source_settlement_key` 必须恢复一致；同一 `player_id + subject_type + subject_id` 经 canonical hash 后的后续候选更新必须 upsert 同一记录，不得因新 `settlement_key` 产生重复候选行。
- **GIVEN** 玩家保存并读档，**WHEN** 检查特性可见触发冷却，**THEN** `last_visible_feedback_settlement_id`、`settlements_since_last_visible_trigger` 和 `trait_visible_cooldown_window` 必须恢复一致，且不得重置冷却。
- **GIVEN** 玩家保存并读档，**WHEN** 检查反馈确认状态，**THEN** `pending_skill_trait_feedback`、`feedback_ack`、对应 `feedback_key`、`attention_state` 和完整 `surface_state` 生命周期必须恢复一致；恢复后的组合必须属于合法持久化组合矩阵，且已确认反馈不得再次作为新提示弹出。
- **GIVEN** 玩家保存并读档，**WHEN** 检查身份历史，**THEN** `player_identity_history_entry` 必须按原有 `season_or_date` 与 `display_order` 顺序恢复，不得丢失或重排。
- **[Integration] GIVEN** 同一 `feedback_key` 被同一界面重复确认两次、被两个不同界面先后确认，或后续版本改变该反馈的 `first_surface_id`，**WHEN** 系统写入或读取 `feedback_ack`，**THEN** 最终只允许存在一条有效全局确认事实，且不得重新创建提示、覆盖原确认来源或改变技能/特性领域状态；其 `settlement_key` 必须使用 `consumer_scope = feedback_ack` 且 `rule_id = feedback_key` 生成。
- **[Integration] GIVEN** 旧版本迁移导致 `subject_id` 变化并生成新的 `feedback_key`，且旧 `feedback_key` 已确认，**WHEN** 迁移完成后读取或重放该反馈，**THEN** `feedback_key_aliases[]` 或 `skill_trait_migration_record.old_feedback_key_aliases[]` 必须让旧确认继续生效，不得把同一领域事实重新放入新提示队列。
- **GIVEN** 某候选技能或候选特性因槽位阻塞只写入 `candidate_progress_record`，**WHEN** 玩家保存、读档并打开 Player Detail，**THEN** 候选阶段、阻塞原因和来源稳定结算键必须恢复一致，UI 不需要重算家族上限即可展示。
- **GIVEN** 某特性可见触发写入后仍在 `trait_visible_cooldown_window` 内，**WHEN** 玩家保存、读档并推进下一次相关结算，**THEN** `trait_cooldown_state` 必须阻止重复可见触发反馈，且不得清空该特性状态。
- **GIVEN** 读档恢复的快照包含某 durable settlement result 的任一 outcome，**WHEN** 存档系统按 Durable Result Companion Matrix 复检该快照，**THEN** 该 outcome 对应的 companion records 必须同时存在；若任一必需 companion 缺失，复检必须返回 `skill_trait_snapshot_invalid_partial_commit`，且该快照不得作为标准成功读档结果恢复。
- **GIVEN** 读档恢复的快照记录技能/特性处于 `Collect Confirmed Facts`、`Evaluate Skill/Trait Outcomes` 或 `Build Durable Settlement Result`，**WHEN** 存档系统复检该快照，**THEN** 复检必须返回 `skill_trait_snapshot_invalid_partial_commit`；只能恢复到 `Atomic Commit Durable Result` 完成后的持久状态，或完全看不到该 result。
- **GIVEN** `pre_match_skill_trait_snapshot` 已生成且随后球员技能状态发生变化，**WHEN** 比赛表现 UI 展示当前 Match Pre 或 Match Result，**THEN** UI 必须继续展示 copy-on-build 锁定快照中的 `context_modifier_summary[]`、`effect_summary[]` 与 `summary_label_key`/`summary_label_args`，不得读取 live player state、Resource、Node、Object、Callable、Variant blob 或运行时 Dictionary 生成新的赛前摘要，也不得逐项重算原始技能效果。
- **[Integration] GIVEN** `pre_match_skill_trait_snapshot` 的 `context_modifier_summary[]` 或 `effect_summary[]` 输入包含嵌套 Dictionary/Array、不同输入顺序或可变运行时容器，**WHEN** 系统构建快照，**THEN** 合法输入必须输出为顶层浅层 typed dictionary + 明确排序的浅层 record arrays，数组顺序分别符合 `context_id ASC` 和 `display_order ASC → effect_summary_id ASC`，且后续修改源容器不得改变已生成快照；若任一 record 字段包含未声明的嵌套 Dictionary/Array、Resource、Node、Callable、Object 或 Variant blob，系统必须拒绝构建该快照、返回 `skill_trait_invalid_snapshot_contract`，并交由比赛系统使用 safe default，不得尝试递归修复后继续展示。
- **GIVEN** 比赛系统以 `skill_trait_snapshot_status = missing_safe_default` 或 `version_mismatch_safe_default` 完成一场合法 fallback 比赛，**WHEN** 赛后结算进入技能与特性系统，**THEN** 本系统不得回补该场比赛的赛前技能效果或特性触发解释，只能消费比赛系统提供的已确认赛后事实。
- **[Integration] GIVEN** 旧存档中存在未确认反馈、已确认反馈、`evaluated_settlement_keys`、`processed_settlement_keys`、`candidate_progress_record`、`anti_grind_window_state`、`trait_cooldown_state` 和 `reliable_rotation_accumulator_state`，**WHEN** 存档从旧规则版本迁移到新规则版本，**THEN** 这些状态必须被保留或按显式 alias 映射迁移；迁移后重新提交旧 `settlement_id` 只能得到 idempotent no-op，不得重复解锁、重复触发可见反馈、重置低价值衰减窗口或重复累计可靠轮换分。
- **[Integration] GIVEN** 旧版本 `skill_stable_pass_v1` 被迁移为 `skill_stable_pass`，**WHEN** 旧存档完成迁移，**THEN** 玩家已拥有等级、剩余进度、来源记录必须映射到新稳定 ID，旧 ID 写入迁移历史，不得静默丢失。
- **GIVEN** 旧版本两个技能被合并为一个新技能，**WHEN** 旧存档完成迁移，**THEN** 新技能等级必须取两个旧技能中的较高等级，剩余进度取较高剩余进度，两个旧技能 ID 均保留在历史记录中。
- **GIVEN** 某旧技能被删除且无任何新技能可映射，**WHEN** 旧存档完成迁移，**THEN** 该技能必须进入 `Deprecated Skill/Trait`，不参与效果计算，但名称、等级、来源和迁移记录必须仍可在历史中追溯。
