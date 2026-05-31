# 足球小镇：新手引导系统

> **Status**: Designed
> **Author**: 用户 + Claude
> **Last Updated**: 2026-05-31
> **Implements Pillar**: 轻度足球经营、低压力长期成长
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/main-loop-ui-framework.md`
> - `design/gdd/player-development-system.md`
> - `design/gdd/match-competition-system.md`
> - `design/gdd/player-management-ui.md`
> - `design/gdd/match-performance-ui.md`

## Overview

新手引导系统是《足球小镇》中负责让新玩家在首次进入游戏时不依赖外部说明就能理解核心循环、掌握基础操作并建立"我知道该做什么"信心​的引导层系统。它不拥有任何游戏数据语义——所有引导内容的含义由运动员培养系统、比赛竞技系统、主循环 UI 框架及其下游 UI 系统拥有——而是负责定义首场比赛前后引导的触发时机、步骤顺序、高亮提示、教学文案以及引导完成后的自然退出方式。它把各系统已定义的界面入口、操作流程和关键反馈，组织成一条玩家无需思考"下一步在哪"就能走完的引导路径，使"培养 → 比赛 → 反馈 → 再培养"闭环在第一次体验中就被玩家理解。

> **ADR 引用**: 暂无 ADR 约束本系统。如后续为引导实现方案（如使用 Autoload 引导状态机还是场景内信号驱动）创建 ADR，应在本节补充引用。

## Player Fantasy

新手引导系统服务的玩家幻想是："我第一次打开这个游戏，不需要看任何教程或攻略，就自然地知道该做什么、怎么做、以及为什么这样做有意思。"

好的新手引导让玩家感觉"这个游戏很懂我"——它不急不慢地在我需要知道的时候恰好告诉我需要知道的事，在我可以自己探索的时候安静地退到一边，在我完成一件重要的事后给我一个微小的确认让我知道我做对了。它不把我当傻瓜，也不假设我什么都知道；它让我在第一次游戏会话结束时感觉"我懂了"，而不是"我终于熬过教程了"。

这种幻想的参考是那些让人"拿起来就放不下"的经营游戏的第一小时体验：没有厚厚的教程文本，没有强制点击的箭头指引，而是通过清晰的信息展示、自然的操作引导和适时的反馈，让玩家自己发现"哦，原来训练是这样用的""原来比赛前我需要排阵容""原来赢球后我的球员会变强"。玩家在引导结束后感到的不是"我终于可以开始玩了"，而是"我已经在玩了，而且我知道接下来要做什么"。

## Detailed Rules

### Core Rules

1. 新手引导系统是新玩家首次体验的引导流程权威来源，负责定义引导的触发条件、步骤顺序、每步的教学内容、高亮锚点以及引导完成/跳过的判定规则。它不拥有任何被引导系统的数据语义——所有引导内容指向的操作和数据由运动员培养系统、比赛竞技系统、主循环 UI 框架及其下游 UI 系统拥有。
2. 本系统只拥有"引导流程"层面的规则，不拥有球员属性定义、训练逻辑、比赛演算、界面布局或导航规则：
   - 球员培养操作与反馈由运动员培养系统拥有；
   - 比赛流程与反馈由比赛竞技系统拥有；
   - 界面导航、容器结构和入口可用性由主循环 UI 框架拥有；
   - 球员列表与详情的具体界面呈现由球员管理 UI 拥有；
   - 比赛各阶段界面的具体呈现由比赛表现 UI 拥有。
3. 引导必须在新建存档后玩家首次进入主界面（Home）时自动触发。已有存档的玩家（非首次游戏）不触发引导。
4. MVP 引导必须覆盖以下最小概念集，按顺序引导：
   - 主界面认知：各区域分别是什么（球队概览、赛季进度、下一场比赛、资源摘要、核心入口）；
   - 球员列表认知：如何查看球员、理解评分和状态标签；
   - 首次训练：如何选择训练项目、分配球员、确认训练并查看结果；
   - 首场比赛——赛前：如何查看对手、确认阵容、选择战术、开始比赛；
   - 首场比赛——赛中：如何观看关键事件、理解比分变化、进入中场调整；
   - 首场比赛——赛后：如何阅读比赛结果、理解胜负原因、查看球员表现、确认返回主界面；
   - 循环闭环确认：回到主界面后，确认玩家理解了"培养 → 比赛 → 反馈 → 再培养"的关系。
5. 引导方式必须以"上下文高亮 + 简短文字提示"为主，不得使用全屏模态对话框阻断玩家操作。每次引导提示最多包含：一个高亮目标区域、一句核心说明（不超过 20 字）、一个可选的"了解更多"展开。
6. 引导步骤必须遵循游戏自然操作流，不得要求玩家执行与当前引导目标无关的操作来推进引导。
7. 玩家在引导过程中可以随时偏离引导建议的操作路径（如不按引导点击而自行探索其他区域）。系统不得因玩家偏离而弹出警告、强制拉回或重置引导进度。引导提示应在玩家回到正确路径时自动恢复。
8. 引导不得阻止玩家进行任何合法操作。引导提示出现时，被高亮区域以外的所有界面元素保持正常可交互状态。
9. 玩家可以在任意引导步骤中选择"跳过引导"。跳过确认后，所有引导提示立即消失，引导标记为已完成，玩家自由操作。
10. 玩家也可以跳过当前步骤（如"我知道了"按钮），仅关闭当前提示，引导从下一步继续。
11. 引导完成后，系统写入引导完成标记。该存档后续游戏会话不再触发引导。
12. 引导文案必须使用友好、简洁、鼓励性的语调。不使用"你必须""你应该"等命令式措辞；使用"试试看""可以在这里"等建议式措辞。每句文案不超过 25 字。
13. 引导高亮必须精确指向对应 UI 系统中已定义的稳定锚点标识（如主界面的比赛入口、球员列表中的排序控件、赛前界面的开赛确认按钮等）。如果目标 UI 系统未提供对应锚点标识，引导步骤应降级为仅文本提示而不高亮，而不是指向错误区域。
14. 经济管理系统已完成 MVP 设计；引导中涉及资源摘要的部分应简短说明经费和运动点数的用途，并明确研究点数在 MVP 阶段不展示、不解释。若首场比赛到达不可跳过的 `Match Trigger` 时 AP 不足，引导不得把 `match_day_ap_safety_grant` 解释为普通恢复行动，只能以短提示说明"比赛日最低体力已补足"或等效文案。
15. 首场比赛引导必须兼容比赛系统的非法阵容兜底。若系统自动推荐阵容或错位补位，引导应说明"临时补位也能开赛"；若极端情况下生成 `forfeit_result_packet`，引导不得阻塞流程，应进入赛后结果说明并提示"本场因阵容不足判负，下次可提前调整阵容"。
16. MVP 阶段新手引导系统的首要目标是验证：一个完全不了解《足球小镇》的新玩家，能否在首次游戏会话中不借助外部帮助，完成"看球队 → 练一次 → 踢一场 → 看结果 → 回到主页"的完整闭环，并在结束时能用自己的话说出这个游戏在玩什么。

### States and Transitions

| State | Description | Enter condition | Exit condition | Valid next states |
|---|---|---|---|---|
| Onboarding Idle | 引导未触发，等待触发条件 | 引导完成标记不存在，且玩家首次进入 Home | 新存档首次 Home 加载完成 | Home Orientation |
| Home Orientation | 主界面各区域高亮与说明 | Onboarding Idle 自动触发 | 玩家确认"知道了"或点击其他区域开始探索 | Roster Introduction / 任意自由操作 |
| Roster Introduction | 球员列表认知引导 | 玩家首次进入 Roster 或 Home Orientation 完成后引导指向 Roster | 玩家浏览了至少一名球员或确认"知道了" | First Training / Home Orientation / 任意自由操作 |
| First Training | 首次训练操作引导 | 玩家进入 Training 界面或 Roster Introduction 完成后引导指向 Training | 玩家完成一次训练并查看结果，或跳过 | First Match Pre / Roster Introduction / 任意自由操作 |
| First Match Pre | 首场比赛赛前引导 | `match_trigger_reached = true` 且玩家进入 Match Pre | 玩家确认开赛或跳过 | First Match Live / First Training / 任意自由操作 |
| First Match Live | 首场比赛赛中引导 | 比赛正式开始（进入上半场） | 上半场结束进入中场，或下半场结束 | First Match Halftime / First Match Result / 任意自由操作 |
| First Match Halftime | 中场调整引导 | 上半场结束进入 Halftime Adjustment | 玩家确认进入下半场或跳过 | First Match Live / 任意自由操作 |
| First Match Result | 首场比赛赛后引导 | 比赛结束，进入 Match Result | 玩家确认结果返回 Home | Loop Closure / 任意自由操作 |
| Loop Closure | 循环闭环确认引导 | 从 Match Result 返回 Home | 玩家确认"知道了"或自由操作 | Onboarding Complete |
| Onboarding Complete | 引导完成 | Loop Closure 确认或玩家在任意步骤选择"跳过引导" | 引导完成标记写入 | —（不再触发） |

### Interactions with Other Systems

| System | 新手引导系统提供 | 该系统提供回新手引导系统 | Ownership boundary |
|---|---|---|---|
| 主循环 UI 框架 | 各步骤高亮的目标屏幕和入口标识需求 | 屏幕导航规则、各屏幕的稳定锚点标识、入口可用性状态 | UI 框架定义结构和标识；引导系统定义何时高亮哪个标识、说什么文案 |
| 运动员培养系统 | 训练引导所需的最小操作概念：选择训练项目、分配球员、确认训练 | 训练状态机、训练结果、球员属性数据 | 培养系统定义训练怎么操作；引导系统定义第一步训练怎么教 |
| 比赛竞技系统 | 比赛引导所需的最小比赛概念：赛前阵容/战术、赛中关键事件、中场调整、赛后复盘 | 比赛状态机、关键事件流、比赛结果包、复盘原因标签 | 比赛系统定义比赛流程；引导系统定义第一场比赛怎么教玩家看懂 |
| 球员管理 UI | 球员列表和详情页面的高亮锚点需求 | Roster 和 Player Detail 界面的具体区域标识、排序/筛选控件标识 | 球员管理 UI 定义界面锚点；引导系统定义何时高亮、说什么 |
| 比赛表现 UI | 赛前/赛中/赛后各阶段界面的高亮锚点需求 | Match Pre / Match Live / Match Result 各容器的具体区域标识、关键按钮标识 | 比赛表现 UI 定义界面锚点；引导系统定义何时高亮、说什么 |

## Formulas

新手引导系统是 Polish/UX 层系统，不拥有数学公式。本节定义的是引导流程的结构规则——它们是引导步骤推进、信息密度、完成判定和显示时机必须遵守的约束公式。

### 1. 引导步骤推进条件

`step_advance = player_action_matches_target(step_id) OR player_skips_step OR player_skips_all`

**定义:** 引导从当前步骤推进到下一步的条件：玩家执行了本步目标操作、玩家跳过当前步、或玩家跳过全部引导。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 当前步骤 ID | `step_id` | enum | {home_orientation, roster_intro, first_training, first_match_pre, first_match_live, first_match_halftime, first_match_result, loop_closure} | 引导当前所在的步骤 |
| 玩家操作匹配目标 | `player_action_matches_target` | boolean | {true, false} | 玩家是否执行了本步骤引导提示的目标操作 |
| 玩家跳过当前步 | `player_skips_step` | boolean | {true, false} | 玩家点击当前步骤的"知道了"按钮 |
| 玩家跳过全部 | `player_skips_all` | boolean | {true, false} | 玩家在任意步骤选择"跳过引导" |
| 步骤推进 | `step_advance` | boolean | {true, false} | 是否推进到下一步或结束引导 |

**Output Range:** true 或 false。  
**Example:** 玩家在 Home Orientation 步骤点击了 Roster 入口 → `player_action_matches_target(home_orientation) = true` → `step_advance = true` → 进入 Roster Introduction。  
**Ownership:** 本系统完全拥有。

### 2. 引导提示信息密度

`tip_text_length = char_count(tip_core_text) ≤ 25 AND tip_optional_detail ≤ 80`

**定义:** 每条引导提示的核心说明文字不得超过 25 字，可选的展开详情不得超过 80 字。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 核心说明字数 | `char_count(tip_core_text)` | int | 1–25 | 引导提示的主体文字字数 |
| 可选展开字数 | `tip_optional_detail` | int | 0–80 | "了解更多"展开后的补充说明字数 |
| 密度合规 | — | boolean | {true, false} | 是否符合信息密度约束 |

**Output Range:** true（合规）或 false（不合规——需缩减文案）。  
**Example:** 核心说明"这是你的球员列表"= 8 字（合规）。核心说明"这是你的球员列表，你可以在这里查看所有球员的详细信息包括属性和状态"= 26 字（不合规）。  
**Ownership:** 本系统完全拥有。

### 3. 引导完成判定

`onboarding_done = all_mvp_steps_completed OR player_skipped_all = true`

**定义:** 引导完成的判定：MVP 全部 7 个概念步骤均已完成（玩家在每个步骤至少执行了目标操作或点击了"知道了"），或玩家在任意步骤选择了"跳过引导"。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| MVP 步骤完成集 | `all_mvp_steps_completed` | boolean | {true, false} | 全部 7 个 MVP 引导步骤是否均已标记完成 |
| 引导完成 | `onboarding_done` | boolean | {true, false} | 引导是否已完成 |

**Output Range:** true 或 false。  
**Example:** 玩家完成了 Home Orientation、Roster Introduction、First Training，然后在 First Match Pre 选择"跳过引导" → `onboarding_done = true`。  
**Ownership:** 本系统完全拥有。

### 4. 引导高亮显示时机

`highlight_visible = current_screen_matches(step_target_screen) AND NOT player_interacting_with_other_ui`

**定义:** 引导高亮仅在当前屏幕与引导步骤的目标屏幕一致，且玩家未与其他 UI（如对话框、下拉菜单）交互时显示。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 当前屏幕匹配目标 | `current_screen_matches` | boolean | {true, false} | 玩家当前所在屏幕是否为本步骤引导的目标屏幕 |
| 玩家正与其他 UI 交互 | `player_interacting_with_other_ui` | boolean | {true, false} | 玩家是否正在操作其他 UI 元素（对话框、菜单等） |
| 高亮可见 | `highlight_visible` | boolean | {true, false} | 引导高亮和提示是否应可见 |

**Output Range:** true 或 false。  
**Example:** 引导目标屏幕为 Roster，玩家点击了某球员进入了 Player Detail → `current_screen_matches(roster_intro) = false` → 高亮隐藏；玩家返回 Roster → 高亮恢复。  
**Ownership:** 本系统完全拥有。

### Formula Ownership Notes

- 本节所有规则属于引导流程组织结构层面的约束，不定义具体高亮样式、动画曲线、字体大小或颜色——这些属于视觉设计规范的范畴。
- 引导步骤的目标屏幕与对应锚点标识的映射关系由引导流程配置定义，不在本节重复列出。
- `player_action_matches_target` 的具体判定逻辑依赖各步骤配置的目标操作定义，实现时由引导配置数据驱动。

## Edge Cases

- **If 玩家在 Home Orientation 第一步就选择"跳过引导"**: 引导立即标记为完成，所有提示消失，玩家自由操作；不弹出"确定要跳过吗？"的二次确认——跳过引导本身已是明确选择。
- **If 玩家在引导过程中存档并退出，随后重新加载**: 引导从上次已完成的最后一步之后继续；已完成的步骤不重复触发；引导状态（当前步骤、已完成步骤列表）随存档持久化。
- **If 引导进行中发生游戏崩溃**: 崩溃前的引导进度如未随最近存档落盘，则恢复到最近存档记录的引导状态；不重复已完成步骤，也不跳过来完成步骤。
- **If 引导触发时目标游戏系统尚未就绪（如比赛系统数据延迟加载）**: 引导停留在当前步骤并显示"正在准备..."占位提示，不推进到下一步；目标系统就绪后自动恢复引导提示。
- **If 引导步骤需要高亮的 UI 锚点尚不存在（目标 UI 系统未提供对应标识）**: 该步骤降级为仅文本提示（无高亮），文本中描述目标区域的位置和外观；不指向错误区域或显示空白高亮。
- **If 玩家在 Home Orientation 步骤未按引导建议去 Roster，而是直接点击了比赛入口**: 视为偏离引导路径的正常行为；Home Orientation 标记为完成，当前屏幕切换后引导自动进入对应步骤（如进入 Match Pre 则触发 First Match Pre 引导）；不弹出"请先完成上一步"的阻断提示。
- **If 玩家在引导过程中执行了引导顺序之外的操作（如在 Roster Introduction 时先去训练）**: 引导跟随玩家实际路径——若玩家进入 Training，引导自动切换到 First Training 步骤；之前未完成的步骤在玩家回到对应屏幕时继续；引导不是线性锁链而是随玩家行为切换的上下文提示。
- **If 首场比赛到来时（`match_trigger_reached = true`）玩家尚未完成训练引导**: 比赛入口提升为最高优先级（UI 框架规则），引导自动将 First Match Pre 推为当前步骤；训练引导在赛后玩家回到主界面时继续。
- **If 首场比赛到来时 AP 不足并触发 `match_day_ap_safety_grant`**: 引导显示短提示说明比赛日最低体力已补足，并继续进入 First Match Pre；不得引导玩家把该补足当作可主动选择的普通恢复、训练或建设资源来源。
- **If 首场比赛赛前阵容不完整但仍有可出场球员**: 引导跟随比赛系统的推荐阵容和错位补位结果，提示临时补位可以开赛，并继续进入 First Match Live；不得要求玩家先补齐完美位置或回退到训练引导。
- **If 首场比赛因可出场人数不足生成 `forfeit_result_packet`**: 引导跳过 First Match Live 和 First Match Halftime，直接进入 First Match Result，说明本场因阵容不足判负并提示下次可提前调整阵容；Loop Closure 仍正常触发，不把弃权视为引导失败。
- **If 新存档中没有任何可用球员（初始球队为空）**: 球员列表引导和训练引导跳过；引导直接指向招募入口，并在高亮中说明"你需要先招募球员"。
- **If 玩家在 First Match Live 引导步骤中尝试离开比赛界面**: 离开警告由比赛表现 UI 和主循环 UI 框架协同处理；引导系统不做额外干预——引导提示暂停，玩家处理完警告对话框后恢复。
- **If 玩家快速连续点击"知道了"跳过所有步骤（5 秒内连点 7 次）**: 每次点击正常推进一个步骤；系统不因点击过快而跳过步骤或合并提示；玩家有权快速浏览所有引导内容。
- **If 玩家停留在某引导步骤超过 5 分钟没有任何操作**: 引导提示保持显示不变；不自动消失，不弹出催促提示，不自动推进。
- **If 经济资源数据正在加载或加载失败，引导中需要提及资源摘要区域**: 引导停留在当前步骤并显示"资源正在加载"或等效短提示；不把加载占位解释为正式资源值。
- **If 联赛系统尚未提供对手数据（provisional），首场比赛使用 `default_opponent_profile`**: 引导在赛前步骤正常引导玩家查看对手信息；对手强度标签正常展示；引导不解释对手数据来源。
- **If 玩家设备为小屏幕或窗口模式，引导高亮区域部分被裁剪**: 引导高亮应自动适配可视区域；如目标锚点完全不可见，降级为文本提示并描述目标位置。
- **If 引导完成后，玩家在同一存档中创建了新的游戏模式**: 引导不重新触发——一个存档对应一次引导；后续扩展的新模式引导由对应系统单独定义。
- **If 引导文案因本地化未加载而显示空白或占位符**: 引导仍显示高亮框，文案区显示"..."占位；不因本地化缺失而完全隐藏引导提示或阻塞流程。
- **If 玩家在 Match Live 引导中，关键事件与引导提示同时出现**: 关键事件正常展示（优先级高于引导提示）；引导提示在事件展示间隔期间恢复；两者不争夺同一屏幕区域。
- **If 引导完成后玩家手动删除了引导完成标记（如通过修改存档或调试工具）**: 下次进入 Home 时引导重新触发——这是预期行为，不视为异常。
- **If 下游教程与提示系统（Alpha 阶段未设计）需要区分"首次引导用户"和"回访用户"**: 引导完成标记可被教程系统消费；本系统只负责写入标记，不定义标记的后续消费逻辑。

## Dependencies

新手引导系统位于 Polish/MVP 层，是新玩家首次体验的引导流程层。它承接主循环 UI 框架的导航结构、运动员培养系统和比赛竞技系统的核心操作流，以及球员管理 UI 和比赛表现 UI 的界面锚点，将它们组织成一条玩家无需外部帮助就能走完的首次引导路径，并为下游教程与提示系统提供引导完成标记。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 定义双核循环、低压力基调和 MVP 验证目标 | 核心循环概念、低压力引导基调、"培养→比赛→反馈"闭环 |
| `design/gdd/systems-index.md` | Hard | 定义本系统在 Polish/MVP 的位置及依赖方向 | 系统层级、优先级、上下游系统列表 |
| `design/gdd/main-loop-ui-framework.md` | Hard | 提供引导高亮的屏幕导航规则和各屏幕稳定锚点标识 | 屏幕 ID 体系、导航规则、入口可用性状态、Home/Roster/Training/Match Center/Schedule 各容器标识 |
| `design/gdd/player-development-system.md` | Hard | 提供训练引导的目标操作概念和训练结果反馈 | 训练状态机、训练流程（选择项目→分配球员→确认→查看结果）、球员属性数据 |
| `design/gdd/match-competition-system.md` | Hard | 提供比赛引导的目标操作概念和各阶段反馈 | 比赛状态机、赛前/赛中/赛后流程、关键事件流、比赛结果包、复盘原因标签 |
| `design/gdd/player-management-ui.md` | Hard | 提供球员列表和详情引导的界面锚点 | Roster 界面的列表区域、排序控件、球员条目标识；Player Detail 界面的属性区、训练入口标识 |
| `design/gdd/match-performance-ui.md` | Hard | 提供比赛各阶段引导的界面锚点 | Match Pre 的对手信息区、阵容区、战术选择区、开赛按钮标识；Match Live 的比分区、事件时间线区标识；Match Result 的终场比分区、复盘原因区、确认按钮标识 |
| `design/gdd/save-and-load-system.md` | Hard | 引导完成标记和引导进度必须随存档持久化 | 引导状态（当前步骤、已完成步骤列表、完成标记）的持久化接口 |
| `design/gdd/league-competition-structure-system.md` | Soft | 首场比赛的联赛上下文（对手排名、轮次）在引导中可能被展示 | 双方排名、比赛轮次、主客场标识——引导不解释联赛规则，只确认这些信息在赛前界面可见 |
| `design/gdd/economy-management-system.md` | Hard | 主界面引导需解释资源摘要区中的经费和运动点数 | 经费、运动点数的当前值、变化语义和预警状态；研究点数在 MVP 阶段不展示 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 新手引导系统 | What must be back-referenced later |
|---|---|---|---|
| 教程与提示系统 | Hard | 引导完成标记（区分首次用户和回访用户）、引导步骤的界面锚点列表 | 必须声明其提示深度和频率如何基于引导完成标记区分用户类型 |

### Dependency Rules

1. 新手引导系统负责"玩家第一次玩时先看什么、后看什么、每步该知道什么"，不负责"被引导的操作是否正确""界面锚点是否稳定存在""游戏数据是否合法"；这些边界分别服从上游游戏系统和 UI 系统。
2. 任何下游系统若希望新增引导步骤、改变引导顺序、覆盖引导文案或新增引导触发条件，必须先回到本系统修订，而不能在本地 GDD 静默覆盖。
3. 球员管理 UI 和比赛表现 UI 是本系统在 MVP 阶段最关键的两个锚点提供者；引导高亮必须基于它们定义的稳定界面标识，而不是在引导系统中重新定义界面区域。
4. 经济管理系统是本系统的 Hard 上游；资源摘要引导必须使用正式文案解释经费和运动点数，不得保留临时占位说法。
5. 当教程与提示系统 GDD 完成后，本节教程与提示系统条目应在本节升级，并在其 GDD 的 Dependencies 中反向声明对本系统引导完成标记的依赖。
6. 引导系统不得在 UI 系统未提供锚点标识的界面上强行高亮；如果必需的锚点缺失，引导应降级为文本提示，同时通知对应 UI 系统补充锚点。

## Tuning Knobs

本节仅包含新手引导系统拥有的共享调参项。它们控制"引导节奏、提示密度、高亮视觉和跳过策略"，不包含具体高亮颜色、字体大小或 UI 系统锚点定义。

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 引导提示最小展示时长 `tip_min_display_ms` | 引导提示出现后"知道了"按钮变为可点击的最小等待时间 | 500–2000ms | 过长 → 快读者等待不耐烦 | 过短 → 玩家可能未读完就误点跳过 | 阅读舒适度、误操作防护 |
| 引导高亮淡入时长 `highlight_fade_in_ms` | 高亮框和提示的出现动画时长 | 150–500ms | 过长 → 引导响应迟钝 | 过短 → 高亮突然出现，缺乏过渡 | 引导视觉舒适度 |
| 引导高亮淡出时长 `highlight_fade_out_ms` | 高亮框和提示的消失动画时长 | 100–400ms | 过长 → 残留高亮会遮挡新界面内容 | 过短 → 消失太突然 | 引导过渡流畅度 |
| 高亮区域外围暗化透明度 `highlight_backdrop_opacity` | 高亮区域之外界面的暗化程度 | 30%–60% | 过暗 → 界面不可读，玩家失去上下文 | 过亮 → 高亮区域不够突出 | 引导注意力引导强度 |
| 核心提示最大字数 `tip_core_text_max_chars` | 引导提示主体文字的字数上限 | 15–30 字 | 过多 → 提示冗长，玩家跳过阅读 | 过少 → 信息不足以传达操作目的 | 引导信息传达效率 |
| 展开详情最大字数 `tip_detail_text_max_chars` | "了解更多"展开后补充说明的字数上限 | 50–100 字 | 过多 → 详情变成说明书 | 过少 → 详情无实质补充 | 进阶信息深度 |
| 跳过引导确认方式 `skip_onboarding_confirmation` | 玩家选择"跳过引导"时是否需要二次确认 | 不需要确认 / 需要确认 | 需要确认 → 多一步操作，略微增加摩擦 | 不需要确认 → 可能误触跳过 | 操作安全感、防误触 |
| 引导步骤顺序模式 `step_progression_mode` | 引导步骤是否允许上下文自动切换 | 线性 / 上下文跟随 | 纯线性 → 玩家偏离路径时引导僵化 | 上下文跟随 → 玩家可能跳过某些步骤 | 引导灵活性、覆盖完整性 |
| 引导重新触发规则 `onboarding_retrigger_policy` | 引导完成后在什么条件下重新触发 | 永不 / 手动重置 / 新存档 | 自动重触发 → 回访玩家被重复打扰 | 永不重触发 → 想重看引导的玩家无途径 | 回访体验、可重玩性 |
| 引导步骤无操作超时 `step_idle_timeout_ms` | 引导提示在无操作时是否自动消失 | 永不自动消失 / 5–10 分钟 | 自动消失 → 离开回来的玩家错过引导 | 永不消失 → 长时间停留的引导可能让玩家误以为卡死 | 耐心、容错性 |
| 引导完成标记存储键 `onboarding_flag_storage_key` | 引导完成标记在存档中的存储标识 | 字符串 | 与其他存档键冲突 → 引导状态可能被其他系统覆盖 | — | 存档兼容性、数据隔离 |
| 调试模式引导重置命令 `debug_reset_onboarding` | 开发/测试中是否提供重置引导的命令 | 有 / 无 | — | 无 → 每次测试引导需新建存档 | 开发效率、QA 测试便捷性 |
| 每步引导最大重触发次数 `step_max_retrigger_count` | 玩家回到同一屏幕时该步骤引导重新触发的最大次数 | 1–3 次 | 过多 → 重复提示令人生厌 | 过少 → 玩家可能第一次没注意 | 引导耐心、不打扰 |

## Acceptance Criteria

- **GIVEN** 新存档首次进入主界面（Home），**WHEN** QA 检查界面，**THEN** 引导必须自动触发，主界面各核心区域出现高亮和简短文字说明。
- **GIVEN** 已有引导完成标记的存档，**WHEN** QA 加载存档进入主界面，**THEN** 引导不得再次触发。
- **GIVEN** 引导在 Home Orientation 步骤，**WHEN** QA 阅读引导提示，**THEN** 每句核心说明不超过 25 字，且不使用"你必须""你应该"等命令式措辞。
- **GIVEN** 引导在 Home Orientation 步骤，**WHEN** QA 点击 Roster 入口，**THEN** 界面正常跳转至球员列表，引导自动切换到 Roster Introduction 步骤。
- **GIVEN** 引导在 Roster Introduction 步骤，**WHEN** QA 检查引导高亮，**THEN** 高亮必须指向球员列表区域和关键控件（如排序按钮），且高亮区域外的界面元素保持正常可交互。
- **GIVEN** 引导在 First Training 步骤，**WHEN** QA 完成一次合法训练并查看结果，**THEN** 该步骤标记为完成，引导推进到下一步。
- **GIVEN** 引导在 First Match Pre 步骤且 `match_trigger_reached = true`，**WHEN** QA 检查赛前界面，**THEN** 引导高亮指向对手信息、阵容区和开赛确认按钮。
- **GIVEN** 首场比赛到达不可跳过节点且 AP 不足，**WHEN** QA 检查引导提示，**THEN** 引导说明比赛日最低体力已补足并继续进入赛前流程，不把补足描述为普通恢复行动。
- **GIVEN** 首场比赛赛前阵容不完整但比赛系统已自动推荐或错位补位，**WHEN** QA 检查引导流程，**THEN** 引导提示临时补位可以开赛并继续进入比赛，不阻塞在阵容修正步骤。
- **GIVEN** 首场比赛因可出场人数不足生成 `forfeit_result_packet`，**WHEN** QA 检查引导流程，**THEN** 引导直接进入 First Match Result，说明本场因阵容不足判负，并在返回 Home 后仍进入 Loop Closure。
- **GIVEN** 引导在 First Match Live 步骤且比赛正在进行，**WHEN** QA 观察界面，**THEN** 引导高亮指向实时比分区和关键事件时间线区域。
- **GIVEN** 上半场结束进入中场调整，**WHEN** QA 检查引导状态，**THEN** 引导自动切换到 First Match Halftime 步骤，高亮指向中场调整区域。
- **GIVEN** 比赛结束进入赛后界面，**WHEN** QA 检查引导状态，**THEN** 引导自动切换到 First Match Result 步骤，高亮指向终场比分、胜负原因和确认按钮。
- **GIVEN** 玩家在赛后点击确认返回主界面，**WHEN** QA 检查引导状态，**THEN** 引导进入 Loop Closure 步骤，确认玩家理解了核心循环。
- **GIVEN** 玩家在任意引导步骤点击"知道了"，**WHEN** QA 检查引导状态，**THEN** 当前步骤提示消失，引导推进到下一步骤。
- **GIVEN** 玩家在任意引导步骤点击"跳过引导"，**WHEN** QA 检查界面，**THEN** 所有引导提示立即消失，引导标记为已完成，玩家自由操作。
- **GIVEN** 引导在 Home Orientation 步骤，**WHEN** QA 不按引导建议而直接点击比赛入口，**THEN** 界面正常跳转到 Match Pre，引导自动切换为 First Match Pre 步骤，不弹出阻断提示。
- **GIVEN** 引导进行中，**WHEN** QA 存档并退出游戏后重新加载，**THEN** 引导从上次已完成的最后一步之后继续，不重复已完成步骤。
- **GIVEN** 引导完成（Loop Closure 确认或跳过），**WHEN** QA 检查存档，**THEN** 引导完成标记已写入，后续加载该存档不再触发引导。
- **GIVEN** 引导在任意步骤，**WHEN** QA 尝试执行引导提示目标以外的任意合法操作，**THEN** 操作正常执行，不被引导阻断或弹出警告。
- **GIVEN** 引导步骤的目标 UI 锚点不存在（模拟缺失），**WHEN** QA 检查引导表现，**THEN** 引导降级为仅文本提示而不高亮，不指向错误区域或显示空白高亮。
- **GIVEN** 引导在 Match Live 步骤且比赛系统连续产出关键事件，**WHEN** QA 观察界面，**THEN** 关键事件正常展示，引导提示不争夺事件展示区域或互相遮挡。
- **GIVEN** QA 以完全不了解《足球小镇》的新玩家身份完成完整引导流程（不跳过），**WHEN** 检查体验结果，**THEN** QA 必须能在引导结束后用自己的话描述"这个游戏的核心玩法是培养球员 → 参加比赛 → 获得反馈 → 继续培养"。
