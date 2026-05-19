# HUD Design: 足球小镇

> **Status**: In Design
> **Author**: nico + ux-designer
> **Last Updated**: 2026-05-18
> **Implements GDD**: `design/gdd/main-loop-ui-framework.md`
> **Template**: HUD Design

---

## 1. HUD Philosophy

《足球小镇》的 HUD 在 MVP 阶段只服务一个目标：让玩家在 3 秒内回答四个问题——

1. 现在是哪个时间节点？
2. 我还有多少经费和运动点数？
3. 我还能做几次行动？
4. 下一场比赛什么时候来，是否已经可以进入？

因此本规格采用 **严格 MVP HUD**：
- 只保留上游 GDD 已明确拥有、且主循环真实需要的常驻信息。
- 把“详细解释”“二级统计”“日志中心”“未来系统入口”全部从常驻 HUD 中移除。
- 让 HUD 负责“定向”和“提醒”，不负责承载完整子系统内容。
- 在比赛流程全屏接管时隐藏 HUD，避免与比赛表现 UI 争抢注意力。

**MVP 原则**：
- **少而稳**：少数元素始终可信，比大量半成品入口更重要。
- **优先级清晰**：比赛提醒高于一般状态，但不靠持续噪声打断玩家。
- **故障可解释**：缺数据时显示加载/缺失原因，不显示空白或占位乱码。
- **键盘可达**：所有交互元素可通过键盘访问；只读元素不进入 Tab 顺序。

---

## 2. MVP Scope and Ownership

### 2.1 常驻 HUD：MVP 保留项

| HUD 元素 | MVP 状态 | 上游依据 | 备注 |
|---|---|---|---|
| 日期/赛季阶段 | 保留 | `main-loop-ui-framework.md` | 主循环最小信息集之一 |
| 经费 | 保留 | `economy-management-system.md` | MVP 明确显示 |
| 运动点数 | 保留 | `economy-management-system.md` | MVP 明确显示 |
| 可用行动窗口 | 保留 | `main-loop-ui-framework.md` | 主循环最小信息集之一 |
| 下一场比赛状态/提醒 | 保留 | `main-loop-ui-framework.md`, `systems-index.md` | 主循环最小信息集之一 |
| 球员入口 | 保留 | `main-loop-ui-framework.md`, `player-management-ui` ownership implied | MVP 核心循环入口 |
| 比赛入口 | 保留 | `main-loop-ui-framework.md`, `match-performance-ui` ownership implied | 仅在条件允许时可用 |
| 菜单入口 | 保留 | 存档/暂停属于基础框架 | 全局系统入口 |

### 2.2 从常驻 HUD 移除或降级的项目

以下项目**不得作为 MVP 常驻 HUD 承诺**出现：

| 项目 | 处理方式 | 原因 |
|---|---|---|
| 声望等级 | 移除常驻承诺 | `声望与成就系统` 为 Alpha，未有正式 GDD ownership |
| 任务 | 移除 | `tutorial/quest` 类系统未正式拥有 HUD 常驻位 |
| 商店 | 移除 | 无上游 GDD ownership |
| 统计总览 | 移除 | 无 MVP HUD ownership；若未来需要应做独立界面 |
| 通知中心 | 移除 | 模式库仅有 Toast，无 Notification Center 模式 |
| 信息滚动条 / Ticker | 移除 | 高噪声、弱可测试、非 MVP 核心信息 |
| 研究点数 | 隐藏 | 经济系统明确：MVP 后台累积，不在 UI 显示 |
| 建设常驻入口 | 未来占位，仅可 hidden | `town-building-system.md` 为 Alpha，且 UI Requirements 未设计 |

**约束**：如果原型里存在上述入口，MVP 构建中必须满足以下全部条件才允许保留占位：
- 默认隐藏，不占据常驻 HUD 空间。
- 不出现在教程/引导中。
- 无默认快捷键。
- 文档中明确标注为 `Non-MVP future placeholder`，不承诺实现。

---

## 3. Layout Zones

### 3.1 严格 MVP 布局

MVP HUD 只保留两个固定区：顶部状态栏 + 底部导航条。

```text
┌─ Zone A: Top Status Bar (48px fixed) ─────────────────────────────────────┐
│ 日期/赛季 │ 经费 │ 运动点数 │ 行动窗口 │ 下一场比赛 │ 菜单 │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│                         Zone B: Main Content Area                         │
│      Home / Roster / Training / Schedule / Match full-screen takeover     │
│                                                                           │
├─ Zone C: Bottom Navigation (56px fixed) ──────────────────────────────────┤
│ 球员入口 │ 比赛入口 │
└───────────────────────────────────────────────────────────────────────────┘
```

### 3.2 不再采用的旧布局

以下区域不是 MVP HUD 的一部分：
- 左侧快捷栏
- 底部任务/商店/建设五标签条
- 信息通知滚动条
- 常驻统计或通知面板入口

### 3.3 分辨率与安全区

| 分辨率 | HUD 规则 |
|---|---|
| 1280×720（最低） | Zone A 与 Zone C 固定高度；文字不得重叠；主内容区保持可用 |
| 1920×1080（推荐） | 标准布局 |
| 超宽屏 (>16:9) | HUD 横向拉伸；交互元素仍保持在 16:9 主要阅读区内 |
| UI Scale 125% | 允许高度放大，但不允许文字裁切、按钮重叠或焦点环溢出屏幕 |

引用模式：`#19 Resolution Adaptation`, `#20 Font Readability`。

---

## 4. Persistent HUD Element Specifications

### 4.1 Zone A — 顶部状态栏

| ID | 元素 | 数据源 | 可见性 | 交互 | 加载态 | 无数据态 | 上游未实现/禁用态 | 键盘与焦点 | 模式引用 |
|---|---|---|---|---|---|---|---|---|---|
| A1 | 日期/赛季阶段 | 时间与赛季推进系统 | Home / Roster / Training / Schedule 可见；Match Pre/Live/Result 隐藏 | 若 `Schedule` 已接入：点击进入日程；若未接入：只读 | 显示骨架宽度与最终文本一致；超过 500ms 显示“时间加载中” | 不适用；时间是必需状态，如缺失视为错误 | 显示“时间未连接”，不可点击 | 已接入 Schedule 时进入 Tab 顺序；未接入时不进 Tab；焦点顺序位于首位 | `#1 Navigation Hierarchy`, `#30 Loading State` |
| A2 | 经费 | 经济管理系统 | 同 A1 | 默认只读；可选 hover tooltip 仅解释“经费用于训练与建设”，不承诺收支明细面板 | 显示“经费加载中”占位 | 不适用；如缺失视为错误 | 显示“经费不可用”；不允许显示空白或 `0` 冒充真实值 | 只读，不进入 Tab 顺序；若实现 tooltip，不要求键盘聚焦 | `#29 Tooltip`, `#30 Loading State`, `#21 Color-Blind Friendly` |
| A3 | 运动点数 | 经济管理系统 | 同 A1 | 默认只读；可选 hover tooltip 仅解释“运动点数决定可执行行动” | 显示“点数加载中”占位 | 不适用；如缺失视为错误 | 显示“点数不可用” | 只读，不进入 Tab 顺序 | `#29 Tooltip`, `#30 Loading State`, `#24 Progress Bar`, `#21 Color-Blind Friendly` |
| A4 | 可用行动窗口 | 时间与赛季推进系统 | 同 A1 | 只读；不承诺点击展开明细 | 显示“窗口加载中” | 若系统合法返回 0，则显示“0 可用”而不是空白 | 显示“窗口未连接” | 只读，不进入 Tab 顺序 | `#30 Loading State` |
| A5 | 下一场比赛状态 | 联赛/时间系统 | 同 A1 | 当 `match_trigger_reached = true` 且比赛中心可进入时，可点击进入比赛；否则只读状态文本 | 显示“赛程加载中” | 若赛程未生成，显示“赛程待公布” | 若比赛中心未接入，显示状态文本但不可点击 | 仅在可点击时进入 Tab 顺序；位于菜单按钮之前 | `#1 Navigation Hierarchy`, `#30 Loading State`, `#31 Empty State`, `#17 Micro-interaction` |
| A6 | 菜单按钮 | 基础框架 | 同 A1 | 打开暂停菜单 | 无特殊加载态 | 不适用 | 若暂停菜单未接入，按钮禁用并显示“暂未开放” | 始终在 Tab 顺序中；可由 Enter/Space 激活；关闭菜单后焦点返回此按钮 | `#4 Icon Button Feedback`, `#13 Keyboard Shortcuts` |

#### A2 经费显示规则
- 文本格式：`经费 {current_value}`
- 预警状态：使用颜色 + 图标/文字双通道，不可仅靠颜色。
- 不承诺 MVP 内显示“日变化”“完整收支明细”“统计总览入口”。

#### A3 运动点数显示规则
- 文本格式：`运动点数 {current}/{max}`
- 可配一条简短填充条，但必须服从 `#24 Progress Bar` 的阈值与 reduced-motion 规则。
- 不承诺显示训练消耗明细面板。

#### A5 下一场比赛显示规则
- 默认格式：`下一场：{opponent_or_status}`
- 当 `match_trigger_reached = true` 时：
  - 文本切换为 `比赛已可开始` 或 `对阵 {opponent}`。
  - 可使用单一轻量强调动画。
  - reduced-motion 下改为静态高亮，不使用脉冲。
- 不承诺常驻倒计时秒表、滚动赛事播报或通知中心联动。

### 4.2 Zone C — 底部导航条

| ID | 元素 | 上游 ownership | 可见性 | 交互 | 加载态 | 无数据态 | 上游未实现/禁用态 | 键盘与焦点 | 模式引用 |
|---|---|---|---|---|---|---|---|---|---|
| C1 | 球员入口 | `player-management-ui` | 非比赛全屏时可见 | 进入球员界面；若已在球员相关界面则显示选中态 | 首次加载时按钮可见但禁用，标签显示“球员加载中” | 若球员数 = 0，按钮仍可用，进入空状态球员界面 | 若球员界面未接入，则按钮禁用并标注“暂未开放” | 始终在 Tab 顺序中（除禁用时）；可由快捷键 `R` 或用户最终映射键触发；如果项目不提供字母键，则至少支持 Tab + Enter | `#1 Navigation Hierarchy`, `#3 Button Feedback`, `#31 Empty State` |
| C2 | 比赛入口 | `match-performance-ui` + 时间系统 | 非比赛全屏时可见 | 当 `match_trigger_reached = true` 时进入比赛中心；未到比赛节点时保持禁用并给出原因 | 首次加载时按钮可见但禁用，标签显示“比赛加载中” | 若赛程未生成，显示“赛程待公布”且禁用 | 若比赛界面未接入，则按钮禁用并标注“暂未开放” | 在 Tab 顺序中（禁用时跳过）；若获得焦点且可用，Enter/Space 激活 | `#1 Navigation Hierarchy`, `#3 Button Feedback`, `#17 Micro-interaction`, `#30 Loading State` |

**不保留的底部入口**：任务、建设、商店、统计。

**建设入口说明**：
- 当前不占据常驻 HUD 槽位。
- 仅当 `town-building-system.md` 与建设 UI 拥有正式入口、禁用态、空态和键盘规范后，才可回到 HUD 规格讨论。
- 当前如需记录，标记为 `Non-MVP future placeholder`。

---

## 5. Non-Persistent HUD Behaviors

### 5.1 暂停菜单 Overlay

| 属性 | 规格 |
|---|---|
| 触发 | `Esc`（L1/Home 等允许场景）或点击菜单按钮 |
| 内容 | 继续游戏 / 存档 / 读档 / 设置 / 返回主菜单 / 退出 |
| 焦点 | 打开时焦点移到首个按钮；关闭后回到菜单按钮 |
| 键盘 | `Tab/Shift+Tab` 循环；`Enter` 确认；`Esc` 关闭 |
| 模式引用 | `#1 Navigation Hierarchy`, `#13 Keyboard Shortcuts` |

### 5.2 Toast 通知

Toast 仅作为轻量反馈，不构成“通知中心”。

| 属性 | 规格 |
|---|---|
| 用途 | 存档成功、错误提示、训练完成、关键结算完成 |
| 位置 | 右上角 |
| 上限 | 同屏最多 3 条 |
| 键盘 | 不抢占焦点，不打断 Tab 顺序 |
| MVP 限制 | 不承诺“历史消息查看”“未读计数”“通知归档” |
| 模式引用 | `#28 Toast Notification` |

### 5.3 Tooltip

Tooltip 只用于补充简短解释，不承担关键规则说明。

| 属性 | 规格 |
|---|---|
| 适用 | 经费、运动点数、只读状态说明 |
| 时机 | 鼠标悬停 300ms |
| 限制 | 关键操作原因必须内联可见，不能只藏在 tooltip 中 |
| 模式引用 | `#29 Tooltip` |

---

## 6. HUD States by Gameplay Context

| 上下文 | Zone A | Zone C | 说明 |
|---|---|---|---|
| Home | 显示 | 显示 | 默认状态 |
| Home（新档，无球员） | 显示 | 显示 | 球员入口可用；比赛入口禁用 |
| Roster | 显示 | 显示 | 球员入口选中 |
| Training | 显示 | 显示 | 比赛入口仍遵循比赛节点可用性 |
| Schedule | 显示 | 显示 | 日期元素可显示选中态，但不新增常驻字段 |
| Match Pre | 隐藏 | 隐藏 | 比赛表现 UI 全屏接管 |
| Match Live | 隐藏 | 隐藏 | 比赛表现 UI 全屏接管 |
| Match Result | 隐藏 | 隐藏 | 比赛表现 UI 全屏接管 |
| Pause Menu | 变暗 | 变暗 | 后方 HUD 不可交互 |
| 全局加载 | 显示可用元素；缺失元素独立进入加载态 | 显示可用元素；缺失入口独立禁用 | 不允许整条 HUD 因单一数据源缺失而整体消失 |
| 全局错误 | 未受影响元素保持正常 | 未受影响元素保持正常 | 只在受影响元素局部显示错误态 |

---

## 7. Pattern References and Gaps

### 7.1 本文允许引用的现有模式

| 场景 | 模式 |
|---|---|
| 跨屏导航 | `#1 Navigation Hierarchy` |
| 文字按钮反馈 | `#3 Button Feedback` |
| 图标按钮反馈 | `#4 Icon Button Feedback` |
| 键盘快捷操作 | `#13 Keyboard Shortcuts` |
| 轻量强调动画 | `#17 Micro-interaction` |
| 分辨率适配 | `#19 Resolution Adaptation` |
| 字体与对比度 | `#20 Font Readability` |
| 色盲友好 | `#21 Color-Blind Friendly` |
| 点数条 | `#24 Progress Bar` |
| Toast | `#28 Toast Notification` |
| Tooltip | `#29 Tooltip` |
| 加载态 | `#30 Loading State` |
| 空状态 | `#31 Empty State` |

### 7.2 明确不再引用的旧说法

以下不是有效模式引用，不应再出现在 HUD 文档中：
- “任务面板模式”
- “通知中心模式”
- 任意未在 `interaction-patterns.md` 中登记的自定义模式编号

### 7.3 New pattern needed

以下交互若未来要复用，应先补进模式库；本次 HUD 文档只做局部定义，不视为模式库已拥有：

| 交互 | 状态 |
|---|---|
| 持久化“比赛已可开始”状态胶囊（静态/强调双态） | `New pattern needed` |
| Alpha 阶段建设入口的常驻/隐藏切换规则 | `New pattern needed` |

---

## 8. Accessibility

无障碍层级保持 **WCAG-AA**，并服从 `design/accessibility-requirements.md`。

### 8.1 HUD 最低执行要求

- 所有交互元素支持键盘访问。
- 所有禁用态必须说明原因，且不能只靠颜色表达。
- 正文最小字号 12px；HUD 关键标签在 720p 下仍可读。
- 所有强调动画提供 reduced-motion 静态替代。
- Match Ready、资源预警等状态使用颜色 + 图标/文字双通道。

### 8.2 焦点顺序

默认 Tab 顺序：
1. 日期（仅当可进入 Schedule 时）
2. 下一场比赛状态（仅当可点击时）
3. 菜单按钮
4. 球员入口
5. 比赛入口

只读文本（经费、运动点数、行动窗口）默认**不进入 Tab 顺序**。

### 8.3 屏幕阅读器：MVP 最低可执行要求

屏幕阅读器相关写法收紧为以下最低要求：

**若 AccessKit 路径已在 Godot 4.6 项目中验证可用，则 HUD 最少实现：**
1. 菜单、球员、比赛三个交互按钮具有稳定可播报名称。
2. 日期、经费、运动点数、行动窗口、下一场比赛以纯文本形式可被读取。
3. 打开暂停菜单时播报菜单标题。
4. 当比赛入口从禁用变为可用时，发送一次非侵入式状态播报。

**若 MVP 时 AccessKit 仍未验证或未接入，则：**
- 不得把“完整屏幕阅读器支持”写成既成事实。
- 必须在 QA/发布说明中记录为风险：`HUD-A11Y-R1 Screen reader support not yet verified in engine build`。
- 仍需满足键盘、对比度、颜色冗余、reduced-motion 等 AA 基线。

### 8.4 Reduced-motion

- 比赛已可开始：动态强调改为静态高亮。
- 资源预警：静态警示样式，不闪烁。
- Toast：50ms 淡入淡出或即时显示。
- HUD 不使用滚动 ticker，因此无需为 ticker 提供替代。

---

## 9. Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 影响 |
|---|---|---|---|
| 顶部状态栏高度 | 48px | 44–56px | 文本可读性与主内容高度 |
| 底部导航高度 | 56px | 48–64px | 按钮点击性与主内容高度 |
| 比赛可用强调强度 | 中 | 低–中 | 紧迫感 vs 低压力体验 |
| HUD 文本缩写阈值 | 1280px | 1280–1600px | 小分辨率下的截断策略 |
| 资源预警显示方式 | 图标+文字 | 不可降为纯颜色 | 色盲可用性 |
| 单元素加载占位超时 | 500ms | 300–1000ms | 是否切换为“加载中”文案 |
| 单元素错误重试提示延迟 | 5s | 3–8s | 错误态显著性 |

---

## 10. Acceptance Criteria

- [ ] 非比赛全屏场景中，HUD 常驻元素仅包含：日期/赛季、经费、运动点数、可用行动窗口、下一场比赛状态、菜单、球员入口、比赛入口。
- [ ] MVP HUD 中不出现常驻声望、任务、商店、统计总览、通知中心、建设入口、研究点数显示。
- [ ] `match_trigger_reached = true` 后，下一场比赛状态和比赛入口在 **250ms 内或下一次渲染周期内** 更新为可进入状态；reduced-motion 下只使用静态高亮。
- [ ] 当赛程尚未生成时，HUD 显示“赛程待公布”，比赛入口禁用，并给出可读原因；不得显示空白、错误日期或无语义占位。
- [ ] 当球员数为 0 时，球员入口仍可用，并能进入球员界面的空状态；比赛入口保持禁用直到满足上游条件。
- [ ] 当经济数据未就绪超过 500ms 时，经费/运动点数元素进入局部加载态；其他 HUD 元素继续正常显示和交互，HUD 不得整体消失。
- [ ] 当任一单独上游数据源失败时，仅对应元素显示“未连接/不可用”错误态；未受影响的 HUD 元素继续可用，且界面不崩溃。
- [ ] 在 1280×720、1920×1080 和 125% UI Scale 下，顶部栏与底部导航不得发生文字裁切、元素重叠、焦点环越界或主内容区完全不可见。
- [ ] 键盘 Tab 遍历只能停在可交互元素上；只读统计项不进入 Tab 顺序；禁用按钮跳过焦点。
- [ ] 暂停菜单打开后形成焦点陷阱；关闭后焦点返回菜单按钮。
- [ ] Match Pre / Match Live / Match Result 三个比赛阶段由比赛表现 UI 全屏接管，HUD 完整隐藏；离开比赛流程后恢复 HUD。
- [ ] 屏幕阅读器支持若未在 MVP 构建中完成 AccessKit 验证，则必须作为 `HUD-A11Y-R1` 风险记录，而不是在文档或 QA 结论中宣称“已完成”。

---

## 11. Open Questions / Risks

| ID | 项目 | 类型 | 当前处理 |
|---|---|---|---|
| HUD-RISK-01 | Godot 4.6 AccessKit 在项目实际构建中的可用性 | Risk | 未验证前仅承诺最低可执行要求，不宣称完整屏幕阅读器支持 |
| HUD-QQ-02 | `Schedule` 是否在 MVP 首版即可从日期元素进入 | Open Question | 若未接入，日期元素保持只读，不阻塞 HUD MVP |
| HUD-QQ-03 | 未来建设入口是否需要常驻 HUD 位 | Open Question | 等 `town-building-system.md` 与建设 UI ownership 明确后再讨论 |
| HUD-QQ-04 | “比赛已可开始”状态胶囊是否应沉淀为通用模式 | Open Question | 目前标记为 `New pattern needed`，不修改模式库 |
