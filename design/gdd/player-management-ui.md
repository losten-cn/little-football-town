# 足球小镇：球员管理 UI

> **Status**: Designed
> **Author**: 用户 + Claude
> **Last Updated**: 2026-06-02
> **Implements Pillar**: 轻度足球经营、低压力长期成长
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/player-development-system.md`
> - `design/gdd/main-loop-ui-framework.md`
> - `E:\code\game\game-design\00-足球小镇-策划总览.md`
> - `E:\code\game\ui-design\足球小镇-UI交互设计文档.md`

## Overview

球员管理 UI 是《足球小镇》中把运动员培养系统定义的球员数据转化为玩家可浏览、可比较、可决策的可视化界面的 Presentation 层系统。它不定义球员属性是什么、训练如何生效、成长如何计算——这些由运动员培养系统拥有——而是负责回答"我有哪些球员、每个人强在哪里弱在哪里、谁值得我投入培养资源、培养之后变化了多少"。它承接主循环 UI 框架定义的 Roster 和 Player Detail 容器与导航规则，在框架内完成球员列表页的排序筛选交互、球员详情页的信息布局、成长轨迹的可视化呈现以及培养入口的衔接，确保玩家在浏览球队时能快速建立对每个球员的判断，并自然地被引导到有意义的培养决策上。在 MVP 阶段，球员管理 UI 的首要目标是验证玩家能否在 30 秒内从球员列表中找到值得关注的球员、看懂他的强弱项和培养价值、并知道下一步该去哪里培养他。

## Player Fantasy

球员管理 UI 服务的玩家幻想不是"这个界面很漂亮"，而是"我了解我球队里的每一个人"。当玩家打开球员列表时，他看到的不只是一排名字和数字，而是一群他亲手培养、看着成长的球员——那个训练刻苦但天赋平平的边后卫、那个天赋异禀但还欠打磨的年轻前锋、那个已经为球队效力三个赛季的老队长——每个人在他的记忆里都有一段属于自己的成长故事。

球员管理 UI 必须让这种"了解"变得容易。一个好的球员列表让玩家一眼就能判断：谁正在变强、谁已经触顶、谁今天状态不好需要休息、谁值得在下一场比赛中首发。球员详情页则应该让玩家在翻阅时产生"这个人我懂他"的亲近感——他的长短板一目了然，他的成长轨迹有迹可循，他的培养方向清晰可辨。这种幻想的核心不是数据密度，而是信息可读性：不需要玩家成为数值分析专家，就能对每个球员产生判断，并基于这些判断做出自己满意的培养和阵容决策。

## Detailed Rules

### Core Rules

1. 球员管理 UI 是球员数据的可视化层，负责定义球员列表页和球员详情页的布局、交互和视觉呈现规则。它不拥有任何球员数据语义——所有展示内容的含义由运动员培养系统拥有。
2. 本系统只拥有"球员信息如何呈现"层面的规则，不拥有球员属性定义、成长计算、训练逻辑、技能/特性判定或状态判定：
   - 球员五维属性、`current / potential / effective` 值语义、训练效率、状态标签、培养层级由运动员培养系统拥有；
   - 技能等级、技能进度、特性标签、解锁原因和适用场景由技能与特性系统拥有；
   - 共享属性边界和评分公式由数值系统拥有；
   - 导航规则、屏幕容器结构、信息刷新触发由主循环 UI 框架拥有。
3. 本系统必须嵌入主循环 UI 框架定义的 Roster 和 Player Detail 两个容器内，不创建独立于框架之外的球员查看入口或导航路径。
4. 球员列表页（Roster 容器内）MVP 必须至少展示以下字段：
   - 球员姓名；
   - 主位置；
   - 综合实力摘要（基于 `positional_overall_rating` 的简化呈现）；
   - 培养层级（普通/优秀/明星/传奇胚子）；
   - 当前状态标签（健康/疲劳/低谷等）；
   - 近期成长指示（最近一次训练或比赛后的成长方向标识）。
5. 球员列表必须支持按以下维度排序：综合评分、主位置、姓名。MVP 默认排序为综合评分降序。排序切换必须即时生效，不触发加载或转场。
6. 球员列表必须支持简单筛选：至少支持按主位置筛选。MVP 不要求多条件组合筛选，但筛选结果为空时必须给出"无匹配球员"的合理提示，而不是空白列表。
7. 球员列表每页条目数默认应遵循主循环 UI 框架的 `list_page_size` 参数。列表翻页操作不触发深层跳转。
8. 从球员列表点击任意球员，必须进入该球员的详情页（Player Detail 容器内）。导航深度为 Home(0) → Roster(1) → Player Detail(2)，符合框架导航深度约束。
9. 球员详情页 MVP 必须至少展示以下信息区：
   - **基础身份区**：姓名、主位置/偏好位置、培养层级；
   - **五维属性区**：速度/力量/技术/智力/体能的当前值与潜力上限，以可读的视觉格式呈现（如条形图或雷达图骨架）；
   - **成长信息区**：训练效率、最近训练收益摘要、距离潜力上限的剩余空间；
   - **技能与特性区**：已拥有技能、技能等级/进度、特性标签、适用场景、候选倾向、只读身份摘要、最近解锁/升级/触发原因；
   - **身份历史区**：来自 `player_identity_history` 的技能解锁、技能升级、特性新增/变化和关键触发记录；
   - **状态区**：当前状态标签、疲劳/心情指示；
   - **培养操作入口**：从详情页可直接进入该球员的训练安排。
10. 五维属性展示必须同时呈现"当前值"和"潜力上限"，使玩家能直观看到每项属性的成长空间。不得只展示当前值而让玩家去猜测上限。
11. 球员详情页中，已被训练触及上限的属性（`current_attribute = potential_cap`）必须给出明确的"已达上限"视觉标记，不得与仍有成长空间的属性使用相同样式。
12. 成长轨迹展示 MVP 至少应支持：最近几次训练或比赛后的属性变化摘要（哪个属性涨了多少、什么时候），不要求完整历史图表，但必须让玩家感知到"这个球员正在变强"或"最近没什么变化"。
13. 训练入口从球员详情页点击后，应携带当前球员上下文进入训练安排界面；玩家不需要在训练界面中重新选择刚看过的球员。
14. 球员状态标签的视觉呈现必须服务于低压力体验：疲劳、低谷等不利状态应清晰标记但不引起恐慌，不得使用红色闪烁或警告弹窗等高压暗示。
15. 从球员详情页或列表页返回，必须回到上一个屏幕（列表或主界面），遵循主循环 UI 框架的返回原则。
16. 所有球员数据的更新触发必须遵循主循环 UI 框架的 `ui_refresh_trigger` 规则：时间推进后、关联系统状态变化后、玩家操作完成后立即刷新。
17. 球员管理 UI 中所有可交互元素（按钮、排序控件、筛选控件）必须有清晰的视觉区分：可交互与只读信息不得在视觉上混淆。
18. MVP 阶段球员管理 UI 不拥有"球员对比"功能（两两或多人并排比较），但列表页的信息密度和排序筛选应让玩家能通过快速浏览完成基础比较。
19. MVP 阶段不要求复杂动画或过渡效果，但列表加载、翻页和详情切换的响应时间不应让玩家感知到明显卡顿。
20. 技能与特性区只消费技能与特性系统提供的权威 payload，不得读取训练 UI、比赛 UI 或 live player state 重新判断技能资格、特性触发或家族上限。该区域必须分成四层 read model：已拥有技能/特性、只读候选身份摘要、待确认补读、身份历史。已拥有技能必须显示等级、适用场景和最近原因；已拥有特性必须显示标签、触发语义和最近关键触发。
21. 候选倾向展示只允许使用 `candidate_visibility_stage` 的身份痕迹阶段标签（`trace_emerging` = 初现痕迹 / `trace_consistent` = 稳定倾向 / `trace_distinct` = 鲜明风格）、`blocked_reason` 映射出的玩家可读说明，以及 `context_hint_label_key` / `context_hint_label_args` 提供的只读身份摘要，不得显示 `candidate_progress_points`、`candidate_unlock_threshold`、内部比例、候选排行、候选数量或“还差多少点”。Player Detail 默认每名球员最多直接展示 2 条候选摘要，必须按技能与特性系统提供的 `candidate_display_priority DESC → display_order ASC → subject_id ASC` 稳定顺序消费；其余候选只能折叠到“更多成长倾向”分组，折叠入口不得显示候选数量、排行或接近程度。候选说明必须像成长线索而不是 build 任务；UI 不得为候选记录展示行动按钮、训练跳转、隐藏规则页、任务清单或“下一步该做什么”的优化提示，也不得暗示玩家应读档、保护槽位、清槽、重铸或等待不存在的槽位变化。`trait_reliable_rotation` 因核心身份槽位占用而保留为候选时，若该球员没有其他直接展示记录说明普通/可靠身份路径，UI 必须把它纳入直接展示预算或作为折叠分组首条摘要。
22. `pending_skill_trait_feedback` 在 Player Detail 中必须挂接到对应球员的技能与特性区或身份历史区，但只允许展示 `attention_state = needs_followup` 或 `awaiting_ack`，且 `surface_state` 为 `shown_on_first_surface`、`deferred_to_followup_notice` 或 `seen_as_detail_followup` 的补读记录；`attention_state = acknowledged` 的记录只通过身份历史回看，不再显示为待处理提示。玩家确认补读记录后，UI 写入或请求写入 `feedback_ack`；已确认反馈不得再次作为新提示弹出，但仍可在 `player_identity_history` 中回看。Player Detail 不得把 `attention_state = needs_first_surface` 或 `surface_state = queued_for_first_surface` 的反馈抢先渲染为首次提示，也不得把 Growth Summary 或 Match Result 尚未首曝的记录改成详情页首曝。
23. 身份历史区以 `player_identity_history_entry` 为唯一来源，按时间倒序展示技能解锁、技能升级、特性新增、特性变化和关键触发。UI 可以折叠历史列表，但不得删除、合并或改写历史语义。
24. MVP 阶段球员管理 UI 的首要目标是验证：玩家在 Roster 和 Player Detail 两个屏幕内能否完整回答"我有哪些球员、谁值得培养、谁已经到顶、下一步该练谁"。

### States and Transitions

球员管理 UI 的状态在主循环 UI 框架的 Roster 和 Player Detail 容器之内。以下状态转换由本系统定义具体交互行为：

| State | Description | Parent container | Valid interactions |
|---|---|---|---|
| Roster View | 球员列表展示，支持排序、筛选和翻页 | Roster | 切换排序、切换筛选、翻页、点击球员进入 Detail View、点击训练入口进入 Training |
| Detail View | 单名球员详情展示 | Player Detail | 查看五维属性、查看成长轨迹、查看技能/特性、查看身份历史、查看状态、点击训练入口（携带球员上下文）、返回 Roster View |
| Detail - Growth Tab | 球员详情中的成长轨迹子视图 | Player Detail | 查看近期属性变化摘要、返回 Detail View |
| Detail - Skill Trait Tab | 球员详情中的技能与特性子视图 | Player Detail | 查看已拥有技能/特性、只读候选身份摘要、最近原因；确认补读反馈 |
| Detail - Identity History | 球员详情中的身份历史子视图 | Player Detail | 查看 `player_identity_history` 条目，按时间倒序浏览；返回 Detail View |
| Detail - Training Action | 从详情页点击训练入口，携带球员上下文跳转到训练界面 | Player Detail → Training | 进入 Training，球员已预选 |

### Interactions with Other Systems

| System | 球员管理 UI 提供 | 该系统提供回球员管理 UI | Ownership boundary |
|---|---|---|---|
| 运动员培养系统 | 属性、潜力、训练效率、状态、成长轨迹的可视化呈现 | 球员所有字段的数据定义、`training_actual_gain`、`player_tier_potential_band`、`fatigue_adjusted_training_efficiency`、状态机 | 培养系统定义数据是什么；球员管理 UI 定义数据长什么样 |
| 主循环 UI 框架 | Roster 和 Player Detail 容器内的完整页面实现 | Roster 和 Player Detail 的容器规范、导航规则、`ui_refresh_trigger`、`list_page_size`、`max_navigation_depth_from_home` | UI 框架定义在哪里展示和怎么导航；球员管理 UI 定义展示什么内容 |
| 数值系统 | 五维属性和评分的视觉呈现格式 | 属性定义、`positional_overall_rating`、`effective_attribute_value` | 数值系统定义数值含义；球员管理 UI 定义如何让玩家看懂这些数值 |
| 比赛竞技系统 | 球员出场信息、比赛表现评分的详情页补充展示 | `post_match_growth_tag`、`player_performance_score` | 比赛系统定义赛后标签；球员管理 UI 决定在详情页中如何呈现 |
| 技能与特性系统 | 技能/特性权威状态的详情页展示、解锁原因、适用场景、只读候选身份摘要、待确认反馈和身份历史 | 技能列表、技能等级/进度、特性标签、最近解锁/触发原因、适用场景、`candidate_progress_record`、`pending_skill_trait_feedback`、`player_identity_history_entry` | 技能与特性系统定义状态和语义；球员管理 UI 只展示，不重算资格、效果、候选点数或家族上限 |
| 新手引导系统 | 球员列表和详情页中可被引导锚定的关键交互点 | 首次浏览球队、首次查看球员详情的引导节奏 | 引导系统定义教学顺序；球员管理 UI 提供稳定的界面锚点 |

> **Alpha integration note:** 技能与特性系统进入 Alpha 后，Player Detail 必须展示已拥有技能/特性、等级/进度、适用场景和最近原因；MVP 若尚未启用该系统，可显示“技能与特性将在后续阶段解锁”的占位。

## Formulas

球员管理 UI 是 Presentation 层系统，不拥有数学公式。本节定义的是球员信息可视化层面的结构规则——它们是球员列表和详情页在布局与交互设计时必须遵守的约束公式。

### 1. 列表行信息密度

`roster_row_fields ≤ max_roster_row_fields`

**定义：** 球员列表每行同时展示的信息字段数不得超过预设上限。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 列表行字段数 | `roster_row_fields` | int | 4–7 | 列表每行实际展示的信息字段数 |
| 最大行字段数 | `max_roster_row_fields` | int | 7 | MVP 硬上限，对应 Core Rule 4 的 6 个必展字段 |

**Output Range:** 4–7。  
**Example:** 姓名 + 位置 + 综合评分 + 层级 + 状态 + 成长方向 = 6 字段（合法）。  
**Ownership:** 本系统完全拥有。

### 2. 属性可视化编码

`attribute_visual = encode(current_value, potential_cap, is_at_cap)`

**定义：** 五维属性的可视化编码规则——当前值、潜力上限和是否触顶三项信息必须在同一个视觉元素中同时传达。

**Encoding Rules:**

| Condition | Visual encoding |
|---|---|
| `current_value < potential_cap` | 填充条显示当前值占比，空白段显示剩余成长空间 |
| `current_value = potential_cap` | 填充条满格 + "已达上限"标记，颜色或样式与未触顶属性区分 |
| 属性值在所有属性中的相对高低 | 填充条长度一致（基于统一 scale 1–100），不因属性类型改变 scale |

**Output Range:** 视觉编码（填充条 + 标记），非数值输出。  
**Ownership:** 本系统完全拥有。

### 3. 成长变化可见性

`growth_visible = has_recent_growth(player_id, lookback_window) AND growth_amount ≥ min_growth_display_threshold`

**定义：** 球员的成长变化是否在当前视图中产生可见指示。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 回顾窗口 | `lookback_window` | int | 1–5 次最近训练/比赛 | 多近的成长记录被视为"近期" |
| 成长量 | `growth_amount` | float | ≥ 0 | 单属性或综合成长量 |
| 最小展示阈值 | `min_growth_display_threshold` | float | 0.1 | 低于此值的成长变化在列表中折叠为"无显著变化" |
| 成长可见 | `growth_visible` | boolean | {true, false} | 列表或详情中是否展示成长变化指示 |

**Output Range:** true/false。  
**Example:** 球员最近一次训练后 SPD +0.05 → `growth_amount < 0.1` → 列表中 `growth_visible = false`，详情页中仍可查到精确数值。  
**Ownership:** 本系统完全拥有。

### 4. 详情页信息区优先级

`detail_section_order = [identity, attributes, growth, skills_and_traits, status, actions]`

**定义：** 球员详情页各信息区的固定展示顺序。顺序固定不变——不同球员之间不因数据差异而改变信息区排列。

**Section order (从上到下):**

| Order | Section | Content |
|---|---|---|
| 1 | 基础身份区 | 姓名、位置、层级 |
| 2 | 五维属性区 | 当前值 + 潜力上限，可视化编码 |
| 3 | 成长信息区 | 训练效率、近期收益、剩余空间 |
| 4 | 技能与特性区 | 已拥有技能、等级/进度、适用场景、特性标签、只读候选身份摘要、最近原因 |
| 5 | 身份历史区 | `player_identity_history` 的关键成长记录，可折叠回看 |
| 6 | 状态区 | 状态标签、疲劳/心情 |
| 7 | 操作入口区 | 训练入口按钮（携带球员上下文） |

**Ownership:** 本系统完全拥有。

### Formula Ownership Notes

- 本节所有规则属于球员信息可视化层面的约束，不定义具体像素、颜色、字体或动画参数——这些属于视觉设计规范的范畴。
- 属性可视化编码规则定义了"必须同时展示当前值和潜力上限"的结构要求，但填充条的具体颜色、形状、动画由视觉实现决定。
- 成长变化可见性的 `min_growth_display_threshold` 可在 Tuning Knobs 中调整。

## Edge Cases

- **If 球队没有任何球员（新档首次进入、或所有球员已离队）**: Roster 列表页不得展示空崩溃状态；应显示清晰的引导提示（如"还没有球员——前往招募你的第一名球员"），所有交互控件（排序、筛选）可保留但操作后结果仍为空。
- **If 筛选后的球员列表为空（如按"门将"筛选但无门将）**: 必须显示"无匹配球员——尝试调整筛选条件"，不得展示空白表格或上一次筛选的残留数据。
- **If 球员的五维属性全部达到潜力上限**: 详情页必须正常展示，但五维属性区每个属性均标记"已达上限"；成长信息区应显示"该球员已全面达到当前潜力上限"。
- **If 球员当前状态同时存在多个标签（如"疲劳"+"士气低落"）**: 详情页状态区必须同时展示所有活跃标签，不得只显示优先级最高的一项而隐藏其余。
- **If 训练系统返回的 `training_actual_gain` 极小（如 0.01）但累计多次后跨过了可视化阈值**: 详情页的成长轨迹应反映累积变化；单次微小变化在列表中可折叠，但累计跨阈值的变化必须在详情中可见。
- **If 球员详情页中某属性的 `potential_cap` 高于该球员所属层级的默认区间上限**: 该球员应标记为"特殊个体"，但详情页正常展示其实际潜力上限；不得因超出层级区间而裁剪显示值。
- **If 球员经历了比赛但尚未经历训练，成长轨迹区域缺少数据**: 成长轨迹区域应显示"最近暂无训练记录"，并在有赛后成长标签 (`post_match_growth_tag`) 时展示比赛带来的成长信息。
- **If 球员列表条目超过一页且玩家翻到第 N 页后执行了排序切换**: 排序后应重置回第一页，不得停留在可能已不存在的第 N 页位置。
- **If 玩家在球员详情页点击训练入口时，训练系统因行动窗口不足而不可用**: 训练入口按钮应显示为禁用状态并给出原因（如"当前无可用的训练行动窗口"），而不是允许点击后进入训练界面再报错。
- **If 球员姓名过长（超过常规显示宽度）**: 列表中的姓名必须截断并附省略号，详情页中显示完整姓名。不得因长姓名破坏列表列宽布局。
- **If 主循环 UI 框架定义的容器尺寸在窄屏下不足以展示所有列表字段**: MVP 允许列表字段按优先级缩减——姓名、综合评分、状态优先保留；次要字段可在窄屏下折叠到详情页中展示。
- **If 球员的属性值在两次查看之间被外部系统修改（如比赛回传了状态变化）且变化微小**: UI 刷新时应更新数值但不触发高亮动画。只有跨过成长阈值的变化才需要视觉提示。
- **If 详情页中技能/特性展示区域预留但 MVP 未实现**: 预留区域显示"技能系统尚未解锁"或等效占位，不得显示空白区域或错误提示。
- **If 技能与特性系统提供 `candidate_progress_record`**: 详情页只显示 `candidate_visibility_stage` 对应的初现痕迹/稳定倾向/鲜明风格标签、`blocked_reason` 的玩家可读说明和真实可执行或低压力方向建议；每名球员默认最多直接展示 2 条候选摘要，其余折叠到“更多成长倾向”分组；不得显示内部点数、阈值、百分比、候选排行、候选数量或还差多少点，也不得显示清槽、重铸、读档或等待不可执行槽位变化的伪行动。
- **If 同家族主技能位阻塞候选解锁**: 技能与特性区必须显示“已留下稳定倾向，但主技能位已被占用”或等效说明，不得把候选隐藏成无进度状态。
- **If 存在未确认 `pending_skill_trait_feedback`**: 详情页必须在对应球员的技能与特性区或身份历史区显示轻量提示；玩家确认后写入 `feedback_ack`，该反馈不得再次作为新提示出现。
- **If 技能/特性反馈已确认但玩家仍想回看原因**: 身份历史区必须能从 `player_identity_history` 展示对应历史条目；确认反馈不得删除历史。
- **If 技能与特性 payload 缺少某个可选展示字段**: UI 使用“暂无记录”或折叠该子项，不得自行重算技能资格、候选进度、触发条件或家族上限。
- **If 多语言环境下球员培养层级名称长度差异较大（如"传奇胚子"vs"Legendary Prospect"）**: 层级标签应使用固定宽度的标签组件，文字过长时截断。MVP 只要求中文版本的正常展示。
- **If 玩家在列表中快速切换排序方式多次**: 每次切换即时生效，不累积请求或出现排序闪烁。UI 防抖由主循环 UI 框架的 `ui_refresh_debounce_ms` 统一控制。
- **If 球员详情页从列表进入后玩家连续翻看多名球员（返回→点击下一名→返回→点击再下一名）**: 每次进入详情页应展示当前最新数据；不得因缓存而显示上一名球员的旧数据。
- **If 球队球员数量超出预期（如通过 MOD 或后续扩展达到 50+）**: 列表分页和筛选排序必须仍然可用；性能不得因列表条目增加而显著下降。
- **If 新手引导系统尚未实现但需要锚定球员管理 UI 的关键交互点**: 所有可交互元素（排序按钮、筛选下拉、列表行、训练入口按钮）必须有稳定的可标识 ID，供后续引导系统引用。
- **If 训练入口携带球员上下文跳转后，玩家在训练界面取消了训练**: 返回时应回到球员详情页，而不是直接跳回主界面。详情页数据应与离开前一致。
- **If 球员的 `player_tier_potential_band` 因平衡性调整而改变，但已有球员的层级未重新分配**: 详情页展示该球员当前实际层级和潜力上限，层级区间变更不应导致已有球员的数据展示异常。

## Dependencies

球员管理 UI 位于 Presentation/MVP 层，是运动员培养系统数据面向玩家的可视化承接者。它在主循环 UI 框架定义的 Roster 和 Player Detail 容器内完成球员列表和详情页的具体实现，并为下游新手引导系统提供可锚定的交互点。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 概念文档定义"玩家了解并培养球员"为双核循环的关键环节 | 核心幻想、低压力基调 |
| `design/gdd/systems-index.md` | Hard | 定义本系统在 Presentation/MVP 的位置及依赖方向 | 系统层级、优先级 |
| `design/gdd/save-and-load-system.md` | Hard | 球员列表和详情页展示的球员数据必须来自存档恢复的权威快照，而非瞬时缓存 | 稳定存档节点语义、读档后数据完整性验证 |
| `design/gdd/player-development-system.md` | Hard | 定义球员所有展示字段的数据语义——本系统的唯一数据源 | 球员属性、训练效率、`training_actual_gain`、`player_tier_potential_band`、状态机、成长里程碑 |
| `design/gdd/main-loop-ui-framework.md` | Hard | 定义 Roster 和 Player Detail 容器规范、导航规则、信息刷新规则 | 容器规范、`ui_refresh_trigger`、`list_page_size`、`max_navigation_depth_from_home`、视觉容器分区 |
| `design/gdd/balance-system.md` | Soft | 提供 `positional_overall_rating` 和 `effective_attribute_value` 的展示格式参考 | 共享评分公式输出——本系统只定义呈现，不定义数值语义 |
| `design/gdd/time-and-season-progression-system.md` | Soft | 训练窗口、成长里程碑时机和状态推进节奏通过主循环 UI 框架间接影响球员列表的刷新和状态反馈 | `available_action_windows`、`match_trigger_reached`（通过主循环 UI 框架传递）——本系统通过 UI 框架间接消费时间信息 |
| `design/gdd/match-competition-system.md` | Soft | 提供赛后标签和表现评分在详情页中的补充展示数据 | `post_match_growth_tag`、`player_performance_score` |
| `design/gdd/skill-and-trait-system.md` | Hard (Alpha) | 提供详情页技能/特性区、候选倾向、待确认反馈和身份历史的权威状态 | 技能列表、特性标签、`candidate_progress_record`、`pending_skill_trait_feedback`、`feedback_ack`、`player_identity_history_entry`、解锁原因、触发解释——本系统只展示，不重算 |
| `E:\code\game\ui-design\足球小镇-UI交互设计文档.md` | Soft | 外部 UI 设计文档提供视觉风格参考 | 视觉风格方向、交互模式参考——本系统定义信息结构，不定义视觉 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 球员管理 UI | What must be back-referenced later |
|---|---|---|---|
| 新手引导系统 | Hard | 球员列表和详情页中可被引导锚定的关键交互点（排序按钮、筛选控件、列表行、训练入口） | 必须声明其引导步骤如何精确定位本系统定义的界面锚点 |
| 教程与提示系统 | Soft | 球员信息区的布局结构和信息层级 | 必须声明其提示内容与本系统定义的信息区结构一致 |
| 主循环 UI 框架 | Hard (回传) | Roster 和 Player Detail 容器的完整实现，验证导航与容器规则的可实现性 | 不适用——UI 框架定义容器；本系统在容器内实现内容 |

### Dependency Rules

1. 球员管理 UI 负责"球员数据如何让玩家看懂和操作"，不负责"数据是什么意思"或"屏幕之间怎么跳转"；这些边界分别服从运动员培养系统和主循环 UI 框架。
2. 任何下游系统若希望新增球员列表字段、改变详情页布局或修改属性可视化规则，必须先回到本系统修订，而不能在本地 GDD 静默覆盖。
3. 技能与特性系统拥有技能/特性状态、进度、解锁原因、适用场景、候选进度、反馈确认和身份历史语义；本系统只负责在 Player Detail 中清晰展示这些内容，不得重算资格、效果、候选阶段或家族上限。
4. `feedback_ack` 的最终持久化由技能与特性系统和存档系统闭合；本系统只发起确认动作并刷新展示状态，不直接改写技能/特性领域数据。
5. 运动员培养系统拥有球员基础成长数据的完整语义；如果培养系统新增或修改了球员字段，本系统必须同步更新对应的可视化规则。

## Tuning Knobs

本节仅包含球员管理 UI 拥有的共享调参项。它们控制的是"列表密度、排序默认行为、属性可视化阈值和交互响应"，不包含球员数据含义、具体像素尺寸或视觉风格。

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 列表默认排序字段 `default_roster_sort_field` | 球员列表首次加载时的排序依据 | 综合评分 / 姓名 / 位置 | 按姓名 → 新玩家难快速识别强将 | 按综合评分 → 低分球员可能被完全忽略 | 球队判断效率 |
| 列表默认排序方向 `default_roster_sort_direction` | 首次加载时的排序方向 | 降序 / 升序 | 升序 → 最弱球员排在最前 | 降序 → 最强球员最显眼（推荐 MVP） | 注意力分配 |
| 最小成长展示阈值 `min_growth_display_threshold` | 列表中折叠微成长的临界值 | 0.05–0.5 | 阈值过大 → 真实成长被折叠，球员"看起来没变" | 阈值过小 → 列表频繁显示微成长指示，噪音过多 | 成长感知频率 |
| 成长回顾窗口 `growth_lookback_window` | 列表中"近期成长"的计算范围 | 1–5 次最近训练/比赛 | 窗口过大 → 很早以前的成长混入"近期"，稀释反馈精准度 | 窗口过小 → 只有最近一次记录，间歇性训练看不到变化 | 成长反馈的及时性与连续性 |
| 属性条 scale 范围 `attribute_bar_scale` | 五维属性可视化填充条的 scale 基准 | 1–100（统一）/ 按属性差异化 | 差异化 scale → 不同属性间难以直观比较 | 统一 scale → 低值属性在视觉上永远"很弱" | 属性间可比性 |
| 已触顶属性视觉样式 `at_cap_attribute_style` | 已达潜力上限属性的视觉区分方式 | 颜色变化 / 图标标记 / 填充样式变化 | 过于低调 → 触顶不易被注意到，玩家仍尝试训练 | 过于醒目 → 触顶呈现为"负面"状态，不符合低压力基调 | 触顶识别、训练决策效率 |
| 列表截断阈值 `roster_name_truncate_length` | 球员姓名在列表中的最大显示字符数 | 4–8 个中文字符 | 过短 → 长姓名被过度截断，辨识困难 | 过长 → 可能挤压其他字段空间 | 列表可读性 |
| 成长动画触发阈值 `growth_animation_threshold` | 触发"属性变化高亮动画"的最小变化量 | 0.2–1.0 | 阈值过大 → 只有大成长才被注意到 | 阈值过小 → 每次微变都闪动画，视觉噪音 | 成长反馈的满足感 |
| 空状态引导文案 `empty_roster_guide_text` | 无球员时列表展示的引导提示内容 | 自定义文本 | — | — | 新玩家引导 |

## Acceptance Criteria

- **GIVEN** 玩家从主界面进入 Roster（球员列表），**WHEN** QA 检查列表内容，**THEN** 每名球员行至少展示姓名、主位置、综合评分、培养层级和当前状态标签，且默认按综合评分降序排列。
- **GIVEN** 球员列表有多页数据，**WHEN** QA 使用翻页控件，**THEN** 翻页不触发屏幕跳转，且页码指示器准确反映当前位置。
- **GIVEN** 玩家切换列表排序方式（综合评分 → 姓名 → 位置），**WHEN** QA 观察列表响应，**THEN** 排序即时生效，不触发加载转场，且排序后重置回第一页。
- **GIVEN** 玩家按位置筛选球员列表，**WHEN** QA 选择"前锋"筛选，**THEN** 列表仅展示前锋球员，其他位置球员被过滤；筛选结果为空时显示"无匹配球员"提示。
- **GIVEN** 玩家从列表点击一名球员，**WHEN** QA 检查屏幕跳转，**THEN** 进入该球员的详情页，且导航深度为 Home(0) → Roster(1) → Player Detail(2)。
- **GIVEN** 球员详情页已加载，**WHEN** QA 检查信息区域，**THEN** 必须按顺序展示：基础身份区 → 五维属性区 → 成长信息区 → 技能与特性区 → 身份历史区 → 状态区 → 操作入口区。
- **GIVEN** 球员五维属性中某一项已达潜力上限，**WHEN** QA 检查该属性的可视化呈现，**THEN** 该属性必须以与未触顶属性不同的视觉样式展示，并有明确的"已达上限"标记。
- **GIVEN** 球员详情页可查看五维属性，**WHEN** QA 检查每个属性，**THEN** 每个属性同时展示当前值和潜力上限，且使用统一 scale（1–100）的填充条编码。
- **GIVEN** 球员最近经历了训练且成长量超过展示阈值，**WHEN** QA 检查列表和详情页，**THEN** 成长变化必须在列表中产生可见指示，并在详情页中显示变化详情。
- **GIVEN** 球员详情页状态区，**WHEN** QA 检查存在多个活跃状态标签的球员，**THEN** 所有活跃标签同时可见，不因数量而被隐藏。
- **GIVEN** 玩家在球员详情页点击训练入口，**WHEN** QA 检查训练界面，**THEN** 该球员已在训练界面中预选，玩家无需重新选择。
- **GIVEN** 训练入口点击时训练系统因行动窗口不足而不可用，**WHEN** QA 检查训练按钮状态，**THEN** 按钮显示为禁用并提供不可用原因。
- **GIVEN** 球队没有任何球员，**WHEN** QA 进入 Roster，**THEN** 显示清晰的引导提示而不是空列表崩溃，排序和筛选控件保留但不产生结果。
- **GIVEN** 球员姓名长度超过列表显示宽度，**WHEN** QA 检查列表渲染，**THEN** 姓名被截断并附省略号，不破坏列宽布局；详情页中显示完整姓名。
- **GIVEN** 球员数据在外部被更新（如训练结算后返回），**WHEN** QA 返回球员列表或详情页，**THEN** UI 展示最新数据，且超过动画阈值的属性变化有视觉高亮。
- **GIVEN** 玩家在详情页之间连续翻看多名球员，**WHEN** QA 每次进入新球员详情，**THEN** 展示的数据属于当前选中球员，不残留上一名球员的缓存数据。
- **GIVEN** 球队球员数量达到 30+，**WHEN** QA 浏览列表、翻页、排序和筛选，**THEN** 列表操作无明显卡顿，响应时间在可接受范围内。
- **GIVEN** 技能与特性系统尚未实现，**WHEN** QA 检查详情页中的技能/特性预留区域，**THEN** 显示合理的占位状态而不是空白或错误信息。
- **GIVEN** 技能与特性系统返回已拥有技能和特性，**WHEN** QA 检查 Player Detail 的技能与特性区，**THEN** UI 必须按“已拥有技能/特性 → 只读候选身份摘要 → 待确认补读 → 身份历史”四层展示，已拥有层展示技能名称/等级/适用场景/最近原因、特性标签/触发语义/最近关键触发，并且不得调用技能判定或特性触发规则重新计算结果。
- **GIVEN** `candidate_progress_record` 的 `candidate_visibility_stage = trace_consistent` 且 `blocked_reason = family_slot_occupied`，**WHEN** QA 检查 Player Detail，**THEN** UI 必须显示“稳定倾向”和同家族主技能位已占用的玩家可读说明与只读身份摘要，不得显示 `candidate_progress_points`、`candidate_unlock_threshold`、百分比、候选排行、候选数量、还差多少点、行动按钮或训练跳转；若同一球员候选超过 2 条，只有技能与特性系统排序后的前 2 条直接展示，其余进入折叠分组。
- **GIVEN** `candidate_progress_record.context_hint_label_key` 已配置，**WHEN** QA 检查 Player Detail 的候选摘要，**THEN** UI 只能把该内容显示为不可点击的低压力说明文本，不得渲染为按钮、训练跳转、隐藏规则页入口或待办清单。
- **GIVEN** 某球员存在未确认 `pending_skill_trait_feedback` 且 `attention_state = needs_followup` 或 `awaiting_ack`，`surface_state` 为 `shown_on_first_surface`、`deferred_to_followup_notice` 或 `seen_as_detail_followup`，**WHEN** 玩家在 Player Detail 确认该补读提示，**THEN** UI 必须发起 `feedback_ack` 确认并刷新为 `attention_state = acknowledged`；同一反馈不得在后续进入详情页时再次作为新提示出现。若 `attention_state = needs_first_surface` 或 `surface_state = queued_for_first_surface`，Player Detail 不得抢先渲染为首次提示。
- **GIVEN** 技能解锁、技能升级、特性新增、特性变化或关键触发已经写入 `player_identity_history`，**WHEN** QA 打开身份历史区，**THEN** 对应条目必须可按时间倒序回看，且确认反馈不会删除该历史条目。
- **GIVEN** 新手引导系统尚未实现，**WHEN** QA 检查球员列表和详情页中的可交互元素，**THEN** 每个可交互元素（排序按钮、筛选控件、列表行、训练按钮）有稳定可引用的标识。
- **GIVEN** 玩家首次打开球员列表并浏览一轮后，**WHEN** QA 采访体验，**THEN** 玩家能在 30 秒内说出谁是球队最强球员、谁最值得培养、谁已经触顶、以及下一步该去训练谁。
