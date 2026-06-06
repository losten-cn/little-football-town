# 足球小镇：建设与经营 UI

> **Status**: Designed
> **Author**: 用户 + Claude
> **Last Updated**: 2026-06-03
> **Implements Pillar**: 像素小镇养成、轻度足球经营、低压力长期成长
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/town-building-system.md`
> - `design/gdd/economy-management-system.md`
> - `design/gdd/main-loop-ui-framework.md`
> - `design/gdd/save-and-load-system.md`
> - `E:\code\game\game-design\00-足球小镇-策划总览.md`
> - `E:\code\game\ui-design\足球小镇-UI交互设计文档.md`

## Overview

建设与经营 UI 是《足球小镇》中把小镇建设系统与经济管理系统的数据转化为玩家可浏览、可规划、可确认的完整建设界面的 Presentation 层系统。它不定义设施有哪些、设施效果如何计算、建造/升级成本是多少、资源如何结算或时间如何推进；这些语义分别由小镇建设系统、经济管理系统和时间与赛季推进系统拥有。本系统负责回答“我的小镇现在长什么样、哪些设施正在建设或可升级、这次建设会花多少钱和多久、它会带来什么低强度长期支持”。在 Alpha 阶段，本系统的目标是把 MVP 的主界面小镇摘要扩展成完整但低压力的建设与经营界面，让玩家感到自己正在照顾一座足球小镇，而不是被迫研究最优网格布局或复杂财务报表。

## Player Fantasy

建设与经营 UI 服务的玩家幻想是：“我打开小镇界面，就能看到这座足球小镇是我一步步建起来的；我知道下一座设施要不要建、升级值不值，但不会被复杂布局和财务压力压垮。”玩家进入这个界面时，首先应感受到空间归属感：训练场、医疗室、青训营和球场清晰地占据小镇格子，正在建设的设施有可见进度，已升级的设施有明确变化。其次才是经营判断：当前经费够不够、维护费是否紧张、升级后大致会改善什么。

这种幻想不是“城市建造优化器”，而是“球队之家在成长”。界面应鼓励玩家做少量有意义的长期选择：先补训练能力、还是先升级球场身份感；先维持低维护费，还是投资青训愿景。它必须避免把建设变成高压 spreadsheet：不展示复杂邻接收益矩阵，不要求玩家频繁重排布局，不把每个设施效果拆成需要逐项比较的最优解。好的体验是玩家能在 30 秒内理解当前小镇状态，并自然做出一个建设/升级决定，或安心关闭界面回到训练与比赛主循环。

## Detailed Rules

### Core Rules

1. 建设与经营 UI 是 Presentation 层系统，只拥有建设信息如何展示、玩家如何进入建造/升级确认流、以及小镇经营摘要如何组织的规则；不拥有设施数据、资源结算、时间推进、维护费公式或设施加成公式。
2. 本系统必须嵌入主循环 UI 框架定义的导航与容器体系，从 Home 的小镇摘要或建设入口进入，不得创建绕过 Home/主循环框架的独立入口。
3. 本系统在 Alpha 阶段承接完整建设界面；MVP 仍只要求主循环 UI 提供小镇摘要与最小建设入口。若实现顺序需要先做 MVP 入口，本 GDD 的完整网格界面不得反向扩大 MVP 范围。
4. 建设界面首屏必须展示以下信息：小镇网格、当前经费、运动点数摘要（只读）、每日维护费摘要、正在建设/升级的项目、可执行的建造或升级入口、当前设施加成摘要。
5. 研究点数在 MVP 阶段不显示；Alpha 若研究树尚未接入，本界面也不得把研究点数作为可操作资源展示。只有当经济系统和对应解锁系统正式开放研究点数消费出口后，才能在本界面加入研究点数展示与消费说明。
6. 单次建造/升级确认流程必须保持低压力，默认只包含 3 个活跃决策：选择目标格/设施、查看预算预览、确认或取消。设施加成、维护费变化、工期和邻接关系默认作为只读摘要，不得变成额外必须逐项确认的任务。
7. 设施网格在 Alpha 首版只服务空间可读性、设施状态展示和小镇归属感。邻接关系可以被高亮说明，但不得展示数值邻接收益表、最优布局评分、布局效率百分比或任何“推荐最佳摆法”的压力提示。
8. 本系统不得提供常规拆迁重排优化入口。若小镇建设系统仅在 Alpha/Debug 支持拆除，本界面不得在普通玩家流程中暴露拆除作为优化工具；若后续版本正式开放拆除，必须先修订小镇建设系统和本 GDD。
9. 建造/升级按钮的可用性必须由小镇建设系统与经济管理系统共同决定：小镇建设系统提供设施状态、格子可用性和目标等级合法性；经济系统提供资源充足性与预算预览；时间系统提供工期登记可行性。
10. 当资源不足时，本系统必须禁用确认按钮并显示具体原因，例如“经费不足：还差 120”，而不是静默灰掉按钮或展示通用失败提示。资源不足提示必须低压力，不得使用破产、危机、失败等高压措辞。
11. 预算预览必须展示“当前经费 → 确认后经费”和“当前每日维护费 → 完成后每日维护费”。若建设或升级尚未完工，必须清楚区分“立即扣除的建造/升级成本”和“完工后才变化的设施加成或维护费”。
12. 设施加成摘要必须使用玩家可读文案，而不是裸露全部内部公式。示例：训练场 Lv.3 显示为“训练收益小幅提升”，球场 Lv.2 显示为“主场氛围略有提升”。详细数值可以在展开说明中显示，但默认不压到首屏。
13. 本系统必须展示设施状态：未建造、建设中、运作中、升级中。建设中/升级中必须展示剩余时间或预计完工节点，数据由时间系统和小镇建设系统提供。
14. 本系统必须支持查看单个设施详情。设施详情至少包含：设施名称、等级、状态、当前效果摘要、下一等级预览（若可升级）、建造/升级成本、工期、维护费变化和来源系统说明。
15. 本系统必须支持建设队列或进行中项目摘要，但 Alpha 首版不要求多项目并行优化。若小镇建设系统只允许单项目或有限项目并行，UI 必须直接反映该限制，不得提供超出系统能力的排队界面。
16. 维护费摘要只用于经营理解，不得变成高压财务报表。默认展示每日维护费总额、主要来源和低压力预警；不展示逐日长期现金流预测、破产倒计时或复杂盈亏曲线。
17. 若经济系统进入资源预警状态，本系统可以在经费区域和维护费摘要中显示温和预警，例如“经费偏紧，建议先完成比赛或等待赛季结算”，但不得阻止玩家浏览小镇或查看未来升级。
18. 本系统的返回路径遵循主循环 UI 框架：“完成确认后返回建设界面并刷新状态；取消局部操作返回来源页；从建设界面返回 Home”。不得在确认建造后强制跳转到不相关系统。
19. 本系统必须为新手引导和教程系统提供稳定 UI 锚点，至少包括：小镇入口、网格区域、设施详情、建造按钮、升级按钮、预算预览、维护费摘要和加成摘要。
20. 本系统不得把小镇建设包装成核心胜负条件。界面文案必须强调设施是长期支持和身份表达，而不是“不升级就落后”的必做清单。

### States and Transitions

| State | Description | Parent container | Valid interactions |
|---|---|---|---|
| Town Overview | 建设与经营主界面，展示小镇网格、资源摘要、维护费和设施加成摘要 | Main Loop → Town Management | 选择格子/设施、打开建造菜单、查看进行中项目、返回 Home |
| Facility Detail | 单设施详情页，展示等级、状态、效果、维护费和下一等级预览 | Town Management | 查看说明、发起升级预览、返回 Town Overview |
| Build Picker | 空格建造选择页，展示可建设施列表与简短定位 | Town Management | 选择设施、查看预算预览、返回 Town Overview |
| Upgrade Preview | 建造/升级预算预览页，展示成本、工期、维护费变化和效果摘要 | Town Management | 确认、取消、返回设施详情或建造选择 |
| Construction Confirmed | 建造/升级确认反馈状态 | Town Management | 查看确认反馈、返回 Town Overview |
| Maintenance Summary | 维护费与资源压力说明页 | Town Management | 查看维护费来源、返回 Town Overview |

### Interactions with Other Systems

| System | 建设与经营 UI 提供 | 该系统提供回建设与经营 UI | Ownership boundary |
|---|---|---|---|
| 主循环 UI 框架 | 建设入口承接、返回路径、容器嵌入需求、稳定 UI 锚点 | Home 入口、导航规则、顶部状态栏/主内容/底部操作区规范 | 主循环 UI 定义入口和导航；本系统定义建设界面内部组织 |
| 小镇建设系统 | 建设/升级操作请求、目标格/目标设施选择、详情展示需求 | 设施列表、网格状态、设施等级、设施状态、可建造/可升级判断、成本与工期、加成摘要、邻接关系 | 建设系统定义设施语义和合法性；本系统只展示并发起确认 |
| 经济管理系统 | 预算预览请求、资源不足提示需求、维护费展示需求、低压力维护费文案分类需求 | 经费当前值、资源预警状态、建造/升级可支付性、确认扣费结果、`daily_maintenance_cost`、每日维护费摘要 | 经济系统定义资源与扣费；本系统只展示预算、确认结果，并基于权威字段派生 UI-only 维护费压力文案 |
| 时间与赛季推进系统 | 工期展示和完工节点提示需求 | 当前日期/阶段、建设剩余时间、完工节点、时间推进后的状态变化 | 时间系统定义工期推进；本系统只展示进度 |
| 存档与读档系统 | 恢复后界面刷新需求 | 已保存设施状态、进行中建设/升级、最近稳定节点语义 | 存档系统定义恢复边界；本系统按恢复后的权威状态重建界面 |
| 运动员培养系统 | 训练设施效果的玩家可读说明位置 | 训练收益消费结果或训练效果说明需求 | 培养系统消费设施加成；本系统不得重算训练收益 |
| 比赛竞技系统 | 球场主场身份加成的说明位置 | 主场评分消费语义或比赛日说明需求 | 比赛系统消费主场加成；本系统只展示“可能影响主场氛围”的解释 |
| 新手引导系统 | 小镇建设关键 UI 锚点 | 引导高亮、提示文案、教学节奏 | 本系统提供稳定锚点；引导系统定义教学内容 |

## Formulas

建设与经营 UI 是 Presentation 层系统，不拥有小镇建设、经济扣费或维护费的数学公式。本节定义 UI 展示、决策预算和信息密度约束。

### 1. 建设确认决策预算

`construction_active_decision_count = count(active_controls_in_build_or_upgrade_flow)`

**定义：** 单次建造或升级确认流程中，需要玩家主动处理的决策数量。

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 活跃决策数 | `construction_active_decision_count` | int | 1–3 | 选择目标、查看预算并确认/取消 |
| 最大活跃决策数 | `construction_decision_budget_max` | int | 3 | Alpha 首版硬上限 |

**Rule:** `construction_active_decision_count ≤ construction_decision_budget_max`。  
**Ownership:** 本系统拥有。

### 2. 建设首屏信息密度

`town_overview_info_density = visible_town_key_fields / town_overview_key_field_limit`

**定义：** Town Overview 首屏同时展示的关键字段不得超过上限，避免建设界面变成信息表格。

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 可见关键字段 | `visible_town_key_fields` | int | 5–9 | 网格、经费、维护费、进行中项目、加成摘要等 |
| 首屏字段上限 | `town_overview_key_field_limit` | int | 9 | Alpha 首版建议上限 |

**Rule:** `town_overview_info_density ≤ 1.0`。  
**Ownership:** 本系统拥有。

### 3. 预算预览可读性

`budget_preview_complete = shows_current_funds AND shows_after_funds AND shows_cost AND shows_build_time AND shows_maintenance_delta`

**定义：** 建造/升级确认前，预算预览必须包含足够信息让玩家知道“现在花什么、未来变什么”。

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 当前经费可见 | `shows_current_funds` | bool | true/false | 当前经费是否显示 |
| 确认后经费可见 | `shows_after_funds` | bool | true/false | 扣费后经费是否显示 |
| 成本可见 | `shows_cost` | bool | true/false | 建造/升级经费成本是否显示 |
| 工期可见 | `shows_build_time` | bool | true/false | 工期或预计完工节点是否显示 |
| 维护费变化可见 | `shows_maintenance_delta` | bool | true/false | 完工后维护费变化是否显示 |

**Rule:** `budget_preview_complete = true` 才能启用确认按钮。  
**Ownership:** 本系统拥有展示完整性规则；具体数值来自经济、小镇建设和时间系统。

### 4. 建设压力提示强度

`maintenance_pressure_state = classify_maintenance_pressure(daily_maintenance_cost, facility_total_maintenance, funds_current)`

`town_warning_intensity = classify_resource_warning(resource_warning_state, maintenance_pressure_state)`

**定义：** 将经济系统提供的资源预警状态、每日维护费、设施维护费和当前经费转成低压力 UI 文案等级。`maintenance_pressure_state` 不是经济系统新状态，而是本系统用于展示的 UI-only 分类；其输入字段仍以经济系统和小镇建设系统的权威输出为准。

| Input condition | maintenance_pressure_state | town_warning_intensity label | Presentation rule |
|---|---|---|---|
| `resource_warning_state = false` 且维护费无明显增长 | normal | 正常 | 常规资源显示 |
| `resource_warning_state = true` 且维护费无明显增长 | normal | 经费偏紧 | 黄色轻提示，不阻止浏览 |
| `daily_maintenance_cost` 高于近期默认说明阈值，或 `facility_total_maintenance > 0` 且玩家查看维护费来源 | maintenance_increased | 维护费增加 | 在维护费摘要中说明来源，不暗示危机 |
| `resource_warning_state = true` 且 `maintenance_pressure_state = maintenance_increased` | maintenance_increased | 建议暂缓升级 | 禁用不可支付操作，仍允许查看和规划 |

**Ownership:** 本系统拥有 `maintenance_pressure_state` 的 UI-only 分类、文案强度与展示方式；`resource_warning_state`、`funds_current`、`daily_maintenance_cost` 由经济系统拥有，`facility_total_maintenance` 由小镇建设系统产出并经经济系统结算消费。

## Edge Cases

- **If 小镇建设系统尚未初始化完成**: Town Overview 显示“正在加载小镇”占位，建造/升级按钮禁用；不得显示空白网格并允许点击。
- **If 经济数据尚未加载或加载失败**: 预算预览不可确认，资源区显示加载/错误状态；玩家仍可浏览已建设施详情。
- **If 玩家选择空格但当前无可建设施**: Build Picker 显示“当前没有可建造设施”，并说明可能原因来自解锁或资源状态；不得展示空列表。
- **If 玩家选择已满级设施**: Facility Detail 显示“已达到当前最高等级”，不显示升级按钮。
- **If 玩家经费不足以建造/升级**: 确认按钮禁用并显示缺口；允许玩家返回浏览或关闭界面，不弹出惩罚式警告。
- **If 建造/升级确认时资源状态被其他结算改变**: 确认请求必须重新向经济系统校验预算；若失败，停留在预览页并刷新原因。
- **If 玩家在 Upgrade Preview 修改主意并返回**: 不保留任何未确认扣费或工期登记；返回来源设施详情或 Build Picker。
- **If 玩家确认建造/升级后立即关闭界面**: 已确认结果由小镇建设、经济和时间系统持久化；下次进入 Town Overview 时显示进行中项目。
- **If 设施升级中**: 设施详情显示当前生效等级和目标等级；当前加成仍按小镇建设系统定义的升级期间规则展示，不提前显示新效果已生效。
- **If 多个设施同时处于进行中状态**: Town Overview 以简短列表展示所有进行中项目；若超过可见上限，折叠为“更多建设项目”入口，不挤压网格区域。
- **If 维护费导致资源预警**: Maintenance Summary 显示维护费来源和温和建议；不得展示破产倒计时或要求玩家拆除设施。
- **If 玩家在较小窗口尺寸下打开界面**: 网格区域优先保持可点击，资源摘要和加成摘要可折叠；确认按钮不得被裁切。
- **If 邻接关系存在但 Alpha 首版未启用数值邻接**: UI 只展示“相邻设施”视觉高亮或生活感说明，不显示额外收益数值。
- **If 后续版本启用数值邻接**: 必须先修订小镇建设系统中的邻接硬消费合同，再修订本系统展示对应收益；不得由 UI 先行展示未授权数值。
- **If 存档读档后进行中项目已到达完工时间但尚未结算**: 时间系统和小镇建设系统先完成权威状态更新；本系统只展示更新后的设施状态，不自行判定完工。
- **If 玩家快速重复点击确认按钮**: UI 必须防重复提交，同一确认请求只发送一次；后续点击显示处理中或忽略。
- **If 小镇网格已满**: Build Picker 禁用新建入口并说明“当前小镇空间已满”；升级既有设施仍可用。
- **If 当前设施效果对训练或比赛没有立即可见变化**: Facility Detail 必须说明“这是长期支持设施”或等效文案，避免玩家误以为操作失败。
- **If 新手引导正在高亮建设入口**: 本系统必须保持锚点稳定，不因资源不足或正在建设中改变锚点 ID。

## Dependencies

建设与经营 UI 位于 Presentation/Alpha 层，是主循环 UI 框架、小镇建设系统和经济管理系统之间的具体建设界面承接者。它让玩家能完整查看和操作小镇建设，但不改变建设系统作为支持性长期成长系统的范围。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 定义像素小镇养成、低压力长期成长和反复杂 UI 密度支柱 | 小镇归属感、低压力、清晰先于密度 |
| `design/gdd/systems-index.md` | Hard | 定义本系统在 Presentation/Alpha 的设计顺序和依赖方向 | 系统层级、优先级、推荐设计顺序 |
| `design/gdd/main-loop-ui-framework.md` | Hard | 定义 Home 入口、Town Management 容器、导航深度、容器规范和返回路径 | 建设入口、Town Management 容器、导航规则、UI 锚点要求 |
| `design/gdd/town-building-system.md` | Hard | 提供设施、网格、状态、建造/升级合法性、工期和加成摘要 | 设施列表、格子状态、设施等级、成本、工期、维护费、加成摘要 |
| `design/gdd/economy-management-system.md` | Hard | 提供经费、预算预览、资源预警和维护费结算 | 当前经费、可支付性、预算预览、资源预警、`daily_maintenance_cost`、维护费摘要 |
| `design/gdd/time-and-season-progression-system.md` | Hard | 建造/升级工期和完工节点需要时间系统驱动 | 当前日期、剩余工期、完工节点、时间推进事件 |
| `design/gdd/save-and-load-system.md` | Hard | 设施状态、进行中项目和 UI 恢复必须可持久化 | 稳定节点恢复、设施状态快照、进行中建设恢复 |
| `design/gdd/player-development-system.md` | Soft | 训练设施效果说明需要与训练结果口径一致 | 训练结果消费设施加成后的解释需求 |
| `design/gdd/match-competition-system.md` | Soft | 球场主场身份加成说明需要与比赛赛前评分一致 | 主场加成消费语义 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 建设与经营 UI | What must be back-referenced later |
|---|---|---|---|
| 新手引导系统 | Soft | 小镇入口、建造按钮、预算预览、设施详情等稳定锚点 | 必须声明其建设教学基于本系统锚点，不临时修改界面结构 |
| 教程与提示系统 | Soft | 维护费说明、设施效果说明、资源不足提示位置 | 必须声明其提示不覆盖本系统低压力文案原则 |
| 音频系统 | Soft | 建造确认、升级确认、完工查看等 UI 事件 | 必须声明音效触发不改变 UI 操作节奏 |

### Dependency Rules

1. 本系统不得新增设施类型、设施效果、成本、工期或维护费公式；这些必须先回到小镇建设系统或经济管理系统修订。
2. 本系统不得绕过经济系统直接扣费或判断资源合法性；所有确认操作必须通过经济系统预算与结算接口。
3. 本系统不得绕过时间系统直接推进工期或判定完工；完工状态必须来自时间系统与小镇建设系统。
4. `maintenance_pressure_state` 仅是本系统的展示分类，不得被经济系统、存档系统或小镇建设系统当作权威资源状态持久化或消费。
4. 本系统不得把 Alpha 预留字段（AP 恢复、球场收入倍率、潜力下限提升、数值邻接收益）展示成已经生效的正式收益。
5. 如果后续要加入拆除、重排、布局评分或数值邻接优化，必须先升级小镇建设系统 GDD 的硬消费合同，再修订本系统。
6. 主循环 UI 框架拥有导航与容器规则；本系统只能在其容器内完成建设界面，不自建全局导航。

## Tuning Knobs

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 建设流程活跃决策上限 `construction_decision_budget_max` | 单次建造/升级流程需要玩家主动处理的步骤数 | 2–4 | 步骤过多 → 建设像任务清单 | 步骤过少 → 预算信息不足 | 操作压力、确认清晰度 |
| Town Overview 首屏字段上限 `town_overview_key_field_limit` | 首屏关键字段数量 | 6–10 | 信息过载 | 信息不足，需要频繁展开 | 清晰度、经营掌控感 |
| 网格默认缩放 `town_grid_default_zoom` | 小镇网格初始显示范围 | 显示 5×5 全图 / 局部放大 | 全图太小 → 设施辨识弱 | 局部太窄 → 小镇整体感弱 | 空间归属感 |
| 预算预览详情层级 `budget_preview_detail_level` | 预算默认显示多少细节 | 简洁 / 标准 / 详细 | 过详细 → 财务报表压力 | 过简洁 → 玩家不知成本来源 | 经营可理解性 |
| 维护费预警文案强度 `maintenance_warning_tone` | 维护费紧张时的提示语气 | 温和建议 / 中性提醒 | 过强 → 破产焦虑 | 过弱 → 玩家忽略风险 | 低压力、资源规划 |
| 进行中项目可见上限 `active_construction_visible_limit` | 首屏显示的进行中项目数量 | 1–4 | 过多挤压网格 | 过少隐藏进度 | 建设进度感 |
| 加成摘要默认条目数 `facility_bonus_summary_visible_limit` | 首屏默认显示的设施加成摘要数量 | 2–5 | 过多像数值面板 | 过少看不到回报 | 成长反馈、信息密度 |
| 邻接高亮强度 `adjacency_visual_emphasis` | 相邻设施视觉提示强度 | 低 / 中 | 过强暗示优化压力 | 过弱失去空间关系感 | 小镇生活感、布局焦虑 |
| 确认反馈停留时长 `construction_confirm_feedback_ms` | 建造/升级确认后的反馈可见时间 | 800–2000ms | 过长拖慢操作 | 过短缺少仪式感 | 操作反馈、节奏 |
| 资源不足提示详略 `insufficient_resource_hint_detail` | 资源不足时显示缺口和建议的程度 | 缺口值 / 缺口值+温和建议 | 建议过多像指导清单 | 信息不足不知为何禁用 | 可理解性、低压力 |

## Acceptance Criteria

- **GIVEN** 玩家从 Home 点击小镇/建设入口，**WHEN** 建设与经营 UI 打开，**THEN** 必须进入主循环 UI 框架内的 Town Management 容器，不得打开独立导航栈。
- **GIVEN** Town Overview 首次显示，**WHEN** QA 检查首屏内容，**THEN** 必须展示小镇网格、当前经费、每日维护费摘要、进行中项目摘要、设施加成摘要和返回 Home 入口。
- **GIVEN** MVP/Alpha 研究树尚未接入，**WHEN** QA 检查资源摘要，**THEN** 研究点数不得作为可消费资源显示或参与建造确认。
- **GIVEN** 玩家选择一个空格，**WHEN** Build Picker 打开，**THEN** 只能展示小镇建设系统声明可建的设施，不得显示未解锁或未定义设施。
- **GIVEN** 玩家选择可建设施，**WHEN** Upgrade Preview 展示，**THEN** 必须显示当前经费、建造成本、确认后经费、工期、预计完工节点和完工后维护费变化。
- **GIVEN** 玩家经费不足，**WHEN** QA 检查确认按钮，**THEN** 确认按钮必须禁用并显示具体缺口，不得发送扣费或工期登记请求。
- **GIVEN** 玩家经费充足并确认建造，**WHEN** QA 检查系统调用顺序，**THEN** UI 必须先通过经济系统确认扣费，再由小镇建设系统登记建设状态，并由时间系统登记工期；UI 不得自行修改设施状态。
- **GIVEN** 玩家选择一个可升级设施，**WHEN** Facility Detail 打开，**THEN** 必须展示当前等级、当前状态、当前效果摘要、下一等级预览、升级成本、工期和维护费变化。
- **GIVEN** 玩家选择已满级设施，**WHEN** Facility Detail 打开，**THEN** 显示“已达到当前最高等级”或等效提示，升级按钮不可见或禁用。
- **GIVEN** 设施处于升级中，**WHEN** QA 检查 Facility Detail，**THEN** 必须同时展示当前生效等级和目标等级，不得提前把目标等级效果标为已生效。
- **GIVEN** Town Overview 中存在邻接设施，**WHEN** QA 检查邻接展示，**THEN** UI 可以高亮相邻关系，但不得展示数值邻接收益、布局评分或推荐最佳摆法。
- **GIVEN** 玩家打开 Maintenance Summary，**WHEN** QA 检查维护费信息，**THEN** 必须展示每日维护费总额和主要来源，并能说明 `maintenance_pressure_state` 是基于 `daily_maintenance_cost`、`facility_total_maintenance` 和 `funds_current` 的 UI-only 分类；不得展示破产倒计时或要求拆除设施的高压提示。
- **GIVEN** 经济系统返回资源预警状态，**WHEN** QA 检查建设界面，**THEN** 资源区显示温和预警，浏览、返回和查看详情仍可用。
- **GIVEN** 玩家在预算预览页取消操作，**WHEN** QA 检查资源和设施状态，**THEN** 不得扣费、不得登记工期、不得改变设施状态。
- **GIVEN** 玩家快速重复点击建造确认，**WHEN** QA 检查请求日志，**THEN** 只允许发送一次确认请求，不得重复扣费或重复创建建设项目。
- **GIVEN** 玩家确认建造后返回 Town Overview，**WHEN** QA 检查界面刷新，**THEN** 对应格子必须显示建设中状态和剩余工期。
- **GIVEN** 存档读档后存在进行中建设项目，**WHEN** QA 打开 Town Overview，**THEN** UI 必须按存档恢复后的权威状态显示项目进度，不得重置为空地或直接判定完工。
- **GIVEN** 时间系统触发建设完工，**WHEN** QA 回到 Town Overview，**THEN** 对应设施必须显示为运作中并展示新等级/效果摘要。
- **GIVEN** 小镇网格已满，**WHEN** QA 尝试新建设施，**THEN** Build Picker 必须显示空间已满提示；升级既有设施仍可正常进入预览。
- **GIVEN** 玩家在较小窗口尺寸下打开界面，**WHEN** QA 检查可用性，**THEN** 小镇网格、返回入口和确认/取消按钮不得被裁切到不可操作。
- **GIVEN** 新手引导系统请求小镇入口、建造按钮或预算预览锚点，**WHEN** QA 检查 UI 标识，**THEN** 这些锚点必须稳定存在并可被引用。
- **GIVEN** 玩家完成一次“打开建设界面 → 选择设施 → 查看预算 → 确认建造 → 返回 Home”的流程，**WHEN** QA 检查整体体验，**THEN** 玩家必须能理解这次建设花费了什么、何时完成、未来会支持什么，同时不需要理解数值邻接或最优布局。
