# Interaction Pattern Library

> **Status**: In Design
> **Author**: nico + ux-designer
> **Last Updated**: 2026-05-18
> **Template**: Interaction Pattern Library

---

## Overview

本交互模式库定义《足球小镇》所有界面中可复用的交互模式。它是 UI/UX 设计的权威参考——每个界面 UX Spec 引用这里的模式而非重新定义。

### 覆盖范围

导航、输入反馈、拖拽、确认对话、信息层次、键盘快捷操作、动画过渡、响应式适配。所有模式基于 Keyboard/Mouse 输入，目标平台为 PC（Windows 为主，Linux 为辅），采用 2D 像素艺术风格。

### 使用方式

- 界面 UX Spec 的 **Component Inventory** 和 **Interaction Map** 段直接引用模式名
- 新增模式必须在此库中登记后才能被界面 Spec 引用
- 违反已有模式的设计在 `/ux-review` 中视为冲突
- 无障碍基线：WCAG-AA（详见 `design/accessibility-requirements.md`）——所有模式须遵守该文档的色彩、焦点、动效要求

### 输入环境

- **输入方式**: Keyboard/Mouse
- **主输入**: 鼠标驱动 UI，键盘快捷键辅助
- **Gamepad**: 不支持
- **触屏**: 不支持

---

## Pattern Catalog

| # | Pattern | Category | Description |
|---|---------|----------|-------------|
| 1 | Navigation Hierarchy | Navigation | 4-layer depth limit, unified back, breadcrumbs, shortcuts |
| 2 | Tab-Based Section Switching | Navigation | Content tabs with active indicator and count badges |
| 3 | Button Feedback | Feedback | Hover glow → click shrink 95% → release bounce + sfx |
| 4 | Icon Button Feedback | Feedback | Hover circle highlight → click bounce 100→90→105→100% |
| 5 | List Item Selection | Feedback | Hover background deepen → click sink → selected highlight |
| 6 | Map Pan & Zoom | Drag / Future | Future-only map browsing pattern; not used by MVP town main view |
| 7 | Building Placement Drag | Drag / Future | Future-only building placement pattern; not used by MVP town main view |
| 8 | Player Roster Drag | Drag / Future | Future-only roster/lineup drag pattern; not required by MVP match flow |
| 9 | Light Confirmation | Dialog | Simple confirm/cancel with resource cost summary |
| 10 | Important Confirmation | Dialog | Warning icon + detail info + type-to-confirm text input |
| 11 | Information Hierarchy | Information | 4-layer depth: instant glance → active browse → explore → reference |
| 12 | Data Card Display | Information | Title + 2-3 key stats + status indicator in card layout |
| 13 | Keyboard Shortcuts | Efficiency | MVP keyboard access: Esc, Tab, Enter/Space, R, M; local 1-N only for in-screen tabs |
| 14 | Right-Click Context Menu | Efficiency | Context-sensitive dropdown anchored to right-click target |
| 15 | Batch Operations | Efficiency | Ctrl+click multi-select + bulk action toolbar |
| 16 | Screen Transition | Animation | Fade in/out, slide in/out between screen levels |
| 17 | Micro-interaction | Animation | Button bounce, number count-up, notification pulse |
| 18 | Pixel Animation Frames | Animation | 6-frame cycle, 2-second period for looping pixel art |
| 19 | Resolution Adaptation | Adaptation | Min 1280×720, proportional scaling with safe zones |
| 20 | Font Readability | Adaptation | Min 14px body text, 18px headers, pixel font fallback |
| 21 | Color-Blind Friendly | Adaptation | Color + icon + text triple encoding for all status indicators |
| 22 | Toggle Switch | Control | On/off toggle with animated slider and immediate state feedback |
| 23 | Dropdown Menu | Control | Click-triggered floating option list with keyboard navigation |
| 24 | Progress Bar | Information | Fill-bar showing current/max ratio with label and color thresholds |
| 25 | Input Field | Control | Text input with placeholder, focus, validation, and character limit |
| 26 | Scroll Behavior | Navigation | Scrollbar style, momentum, and keyboard scrolling (arrows/PgUp/PgDn) |
| 27 | Grid Layout | Information | Responsive card grid with auto column count and consistent spacing |
| 28 | Toast Notification | Feedback | Auto-dismiss floating message with icon, priority queue, and stacking |
| 29 | Tooltip | Information | Hover-triggered contextual popup with position-aware flip |
| 30 | Loading State | State | Skeleton screen, spinner, and progress bar patterns for async loads |
| 31 | Empty State | State | Guided placeholder with illustration, explanation, and call-to-action |
| 32 | Radar Chart | Information | Five-axis attribute visualization with current/potential dual-line, per-axis tooltip, and keyboard navigation |

### Pattern Naming Rule

所有 UX spec 在引用本模式库时，必须使用 **Pattern Catalog** 中登记的正式模式名，不得自行缩写、改写或替换编号对应的标题。

示例：
- 使用 `#4 Icon Button Feedback`，不要写成 `#4 Icon Button`
- 使用 `#12 Data Card Display`，不要写成 `#12 Data Card`

若某个界面只想引用模式编号，也必须保证编号与正式模式名一一对应，且在首次出现时写出完整名称。

若发现现有 UX spec 中存在缩写或别名，视为文档一致性问题，应在下次修订时统一回正式模式名。

---

## Patterns

### 1. Navigation Hierarchy

**Category**: Navigation
**Used In**: All screens

**Description**: 游戏所有界面遵循统一的层级导航结构——主菜单 (L0) → 小镇主视图 / Home (L1) → 核心子界面 (L2) → 详情或子操作 (L3)。MVP 默认不超过 L3；超过时必须重新评估信息架构，而不是继续堆叠导航深度。所有子界面左上角统一返回按钮，详情层可显示面包屑路径。

**Specification**:
- 返回按钮：所有子界面左上角固定位置，点击返回上一级
- 面包屑：L3 详情或子操作层可在标题下方显示路径（如 `球员管理 > 王五 > 培养`）
- 深度限制：MVP 默认不超过 L3；不得用侧栏或五标签底栏规避层级问题
- 状态保持：返回上一级时恢复列表滚动位置和筛选条件
- 键盘：ESC = 返回上级 / 关闭弹窗

**When to Use**: 任何需要从父界面进入子界面的层级推进场景。
**When NOT to Use**: 非层级关系的临时弹窗——使用 Light Confirmation 或 Important Confirmation 模式。

---

### 2. Tab-Based Section Switching

**Category**: Navigation
**Used In**: 球员列表、训练中心、比赛中心

**Description**: 单界面内多个子视图的局部切换方式。水平标签栏位于内容区上方，当前选中标签有底部指示条和颜色高亮。它只能表达同一 L2/L3 界面内部的平级内容，不得替代全局 HUD 底部导航。

**Specification**:
- 标签排列：水平方向，间距 8px
- 选中态：背景高亮 + 图标放大 + 下方 3px 强调色指示条
- 未读角标：仅在该界面规格明确允许时显示；MVP 不默认承诺通知式角标
- 切换动画：内容区横向滑入（200ms ease-out）
- 键盘：数字键 1-N 仅在当前界面聚焦范围内切换对应局部标签

**When to Use**: 同一界面有 2-6 个平级子视图需要切换。
**When NOT to Use**: 层级推进关系——使用 Navigation Hierarchy。

---

### 3. Button Feedback

**Category**: Feedback
**Used In**: All screens

**Description**: 所有可点击按钮的统一交互反馈。三级视觉强度：普通按钮（中性色）、主要按钮（强调色 足球橙 #FF9800）、危险按钮（警示红 #E53935）。

**Specification**:
- 默认态：扁平像素风格，1-2px 深色描边
- 悬停态：像素发光边框 + 轻微放大 102%
- 按下态：缩小至 95%，颜色加深
- 释放：弹回 100% + 触发音效
- 禁用态：50% 透明度，无交互，光标 `not-allowed`
- 键盘：Tab 切换焦点，Enter/Space 触发点击

**When to Use**: 所有带文字标签的可点击交互元素。
**When NOT to Use**: 纯图标的工具栏按钮——使用 Icon Button Feedback。

---

### 4. Icon Button Feedback

**Category**: Feedback
**Used In**: 菜单按钮、底部导航按钮、球员列表操作图标

**Description**: 纯图标无文字按钮的交互反馈。48×48px 触控区域，悬停显示圆形高亮背景，点击触发弹跳动画。

**Specification**:
- 尺寸：48×48px 触控区，图标 32×32px
- 悬停态：圆形背景高亮（主色 20% 透明度）
- 点击动画：scale 100% → 90% → 105% → 100%（300ms）
- 禁用态：50% 透明度，无交互
- Tooltip：悬停 500ms 后显示功能名称（12px 像素字体）

**When to Use**: 工具栏、操作栏中的纯图标按钮。
**When NOT to Use**: 需要文字说明的主要操作——使用 Button Feedback。

---

### 5. List Item Selection

**Category**: Feedback
**Used In**: 球员列表、比赛列表、经济明细

**Description**: 可点击列表项的统一交互行为。每行显示一个实体的摘要信息，悬停时背景加深并出现左侧指示条，点击进入详情。

**Specification**:
- 行高：64px（单行数据项）
- 悬停态：背景色加深（暖灰色 #8D6E63 10% 透明度），左侧 3px 强调色指示条滑入
- 点击：整体轻微下沉（translate Y +2px，100ms），然后导航至详情
- 选中态：持续高亮背景 + 左侧强调色指示条常驻
- 键盘：↑↓ 切换选中行，Enter 进入详情
- 数据限制：单行最多 6 列核心数据

**When to Use**: 实体列表（球员、比赛、建筑等）需要点击查看详情。
**When NOT to Use**: 纯展示的非交互列表。

---

### 6. Map Pan & Zoom

**Category**: Drag
**Used In**: Future map screens only（MVP 小镇主视图不使用）

**Description**: Future-only 的大地图视角控制模式。MVP 小镇主视图的中央地图主体是固定 Home 内容区，不支持拖拽平移、滚轮缩放、WASD 移动或 Q/E 缩放。

**Specification**:
- 平移：鼠标左键拖拽，释放后惯性滑动（衰减系数 0.92）
- 缩放：鼠标滚轮，5 级缩放 (50%/75%/100%/150%/200%)，以鼠标位置为中心
- 边界：弹性回弹动画（超出边界 20px 后弹回，300ms ease-out）
- 光标：拖拽时变为 `grabbing`，悬停可拖拽区域时 `grab`
- 键盘：future screen 必须提供方向键平移与等效缩放控件；MVP 不启用地图快捷键

**When to Use**: Future 版本中，确实存在超出视口的大地图/画布且已提供键盘等效路径时。
**When NOT to Use**: MVP 小镇主视图、固定 Home 背景、或任何不承诺地图热点/缩放/拖拽的界面。

---

### 7. Building Placement Drag

**Category**: Drag
**Used In**: Future 建设模式 only（MVP 不使用）

**Description**: Future-only 的建设拖放模式。MVP 小镇主视图不提供建设入口、模式开关、网格覆盖或建筑拖放；任何使用此模式的 future screen 必须先有独立 UX spec。

**Specification**:
- 拾取：建筑变为半透明 60%，原位置显示虚线框
- 拖拽中：建筑跟随光标，网格高亮占地范围（如 4×4 格 = 128×128px）
- 可放置：网格边框变为绿色 (#43A047)
- 不可放置：网格边框变为红色 (#E53935) + 禁止图标叠加
- 放下：轻微下落动画（scale 105%→100%，200ms）+ 像素尘土粒子
- 键盘：Enter 确认放置，ESC 取消

**When to Use**: Future 建设系统正式进入 UX 范围，且该界面明确提供拖拽与键盘替代路径时。
**When NOT to Use**: MVP 小镇主视图、非建设界面、或尚未正式接入建设系统的占位入口。

---

### 8. Player Roster Drag

**Category**: Drag
**Used In**: Future 赛前阵容安排 only（MVP 不要求）

**Description**: Future-only 的阵容拖拽模式。MVP 比赛流程是自动演算与观看优先，不要求通过拖拽调整球员位置；若 future 阵容系统接入，必须提供非拖拽键盘替代路径。

**Specification**:
- 拾取：球员卡片放大至 110% + 阴影加深
- 拖拽中：卡片跟随光标，有效目标位置高亮（虚线边框 + 浅色填充）
- 交换：两张卡片动画交换位置（300ms ease-in-out）
- 无效放下：卡片弹回原位（300ms ease-out）
- 键盘：Tab 切换选中球员，方向键移动位置，Enter 确认

**When to Use**: Future 阵容或排序系统正式进入 UX 范围，且需要空间化调整顺序时。
**When NOT to Use**: MVP 球员管理列表、MVP 比赛观看流程、或任何没有非拖拽替代路径的关键操作。当前 MVP 中任何赛前阵容、换人或排序交互，都必须先以键盘/点击主路径成立后，才可追加此模式作为增强交互。

---

### Future-only Drag Pattern Boundary

本模式库中的拖拽类模式（`#6 Map Pan & Zoom`、`#7 Building Placement Drag`、`#8 Player Roster Drag`）在当前项目阶段统一遵守以下边界：

- 它们属于 **future-only pattern**，不是当前 MVP 的默认交互承诺。
- 任何当前 MVP 界面若需要实现同类功能，必须先提供**键盘/点击式主路径**，拖拽只能作为可选增强交互。
- 不允许把拖拽写成唯一完成关键操作的方式。
- 不允许在尚未补齐焦点顺序、替代输入路径、错误/取消路径之前，把 future-only 拖拽模式升级为当前正式模式。
- 若后续某个界面要把拖拽提升为正式交互，必须先在对应 UX spec 中明确：
  - 该拖拽行为服务什么玩家目标
  - 非拖拽替代路径是什么
  - 焦点与取消规则是什么
  - reduced-motion 与无障碍要求如何满足
- 在这些条件未满足前，所有拖拽类模式默认视为“可引用作 future 方向”，不可作为当前 `/ux-review` 的 MVP 主路径依据。

---

### 9. Light Confirmation

**Category**: Dialog
**Used In**: 开始训练、安排比赛、招募球员等中等操作

**Description**: 中等重要度操作的确认弹窗。显示操作名称和资源消耗，两个按钮（取消/确认）。背景为半透明黑色遮罩，弹窗居中。

**Specification**:
- 遮罩：半透明黑色 (rgba(0,0,0,0.5))，覆盖全屏
- 弹窗：居中，像素边框，宽度 320px 自适应内容
- 内容：标题 + 资源消耗列表（图标 + 数量）+ 取消/确认按钮
- 确认按钮：主色（足球橙 #FF9800），位于右侧
- 取消：点击遮罩或取消按钮或 ESC 关闭
- 键盘：Enter = 确认，ESC = 取消

**When to Use**: 消耗资源的中等操作（训练、比赛安排、招募）。
**When NOT to Use**: 不可逆的重要操作——用 Important Confirmation。

---

### 10. Important Confirmation

**Category**: Dialog
**Used In**: 解雇球员、拆除建筑、大额消费

**Description**: 不可逆操作的危险确认弹窗。显示警告图标、操作详情、后果说明，要求玩家输入确认文字后才能点击确认按钮。

**Specification**:
- 遮罩：半透明红色调 (rgba(200,0,0,0.3))
- 弹窗：居中，警示红边框 (#E53935)，宽度 360px
- 内容：⚠️ 警告图标 + 操作标题 + 受影响实体详情 + "此操作不可撤销" 文案
- 输入框：提示 "请输入 '确认' 以继续"
- 确认按钮：默认禁用（灰色），输入正确文字后变为危险红色
- 键盘：Tab 在输入框和按钮间切换，ESC 关闭

**When to Use**: 不可逆或高代价操作（解雇、拆除、大额消费）。
**When NOT to Use**: 可逆的中等操作——用 Light Confirmation。

---

### 11. Information Hierarchy

**Category**: Information
**Used In**: All screens

**Description**: 所有界面信息按 4 层深度组织——一眼可见（核心数值、关键状态、主要操作）、主动浏览（列表概览、进度）、主动探索（详情、完整属性）、按需查阅（帮助、日志）。信息密度控制在单屏 5-7 个主要信息组，卡片内容不超过标题 + 2-3 个关键数据 + 状态指示。

**Specification**:
- L1 一眼可见：大字号（18-24px）、高对比度、屏幕顶部/中央位置
- L2 主动浏览：卡片布局（14-16px）、图标辅助、内容区上部
- L3 主动探索：可展开面板或详情页、需一次点击进入
- L4 按需查阅：独立入口（帮助按钮、设置菜单）、弹窗展示
- 单屏上限：5-7 个主要信息组，超出时使用折叠或分页

**When to Use**: 任何界面设计前——先确定信息层次再布局。
**When NOT to Use**: 极简界面（纯操作无数据）可以只有 L1。

---

### 12. Data Card Display

**Category**: Information
**Used In**: 球员列表、比赛记录、future-only 建筑/成就面板

**Description**: 实体摘要信息的卡片化展示。每张卡片包含实体图标/头像、标题、2-3 个关键属性值、稀有度/状态指示。卡片排列为网格或列表，响应式切换列数。

**Specification**:
- 卡片尺寸：宽度自适应网格列数，高度 80-120px
- 内容布局：左侧图标/头像 (48-64px) + 右侧文字信息（标题 + 属性行 + 状态标签）
- 稀有度边框：普通=无边框，良好=绿色 1px 发光，稀有=蓝色 2px 发光，传奇=金色 3px 发光+粒子
- 状态指示：右上角彩色圆点（绿=良好，黄=疲劳，红=伤病）
- 悬停：卡片轻微上浮（translate Y -2px）+ 阴影加深

**When to Use**: 需要展示多个同类实体的摘要信息。
**When NOT to Use**: 单个实体的完整详情——用详情视图（非卡片模式）。

---

### 13. Keyboard Shortcuts

**Category**: Efficiency
**Used In**: 全局

**Description**: 为高频操作提供键盘路径，面向 Keyboard/Mouse PC 玩家。快捷键不替代鼠标操作，而是保证核心流程可键盘完成。MVP 不提供全局五标签切换、地图移动/缩放快捷键或未接入系统的默认快捷键。

**Specification**:
| Key | Function |
|-----|----------|
| ESC | 返回上级 / 关闭弹窗 / 打开或关闭暂停菜单（按当前界面规则） |
| Tab / Shift+Tab | 按显式焦点顺序前进 / 后退 |
| Enter | 确认当前聚焦操作 |
| Space | 触发当前聚焦按钮；在暂停/播放控件上按界面规则切换 |
| R | 从小镇主视图进入球员管理 |
| M | 从小镇主视图进入比赛中心（仅可进入时） |
| 1-N | 仅在当前界面规格明确声明的局部标签栏中切换标签 |

- 所有快捷键必须有鼠标等效操作
- 快捷键不可与文本输入冲突（输入框中禁用全局快捷键）
- 禁用状态的目标不响应快捷键，并必须显示原因
- Future 系统不得预占默认快捷键；接入时需在对应 UX spec 中声明

**When to Use**: 全局生效，所有界面通用。
**When NOT to Use**: 文本输入框获得焦点时——禁用全部快捷键。

---

### 14. Right-Click Context Menu

**Category**: Efficiency
**Used In**: 球员列表、小镇建筑

**Description**: 右键点击实体弹出上下文菜单，列出该实体的可用操作。菜单定位在点击位置，超出视口时自动翻转方向。

**Specification**:
- 菜单宽 180px，像素边框 1px 深色
- 菜单项高 32px，左侧图标 16×16px + 右侧文字
- 悬停菜单项：背景高亮
- 分隔线：1px 暖灰色
- 危险操作（如解雇）：红色文字，置于分隔线下方
- 点击菜单外或 ESC 关闭菜单
- 最多 8 个菜单项，超出时使用子菜单

**When to Use**: 实体有 3+ 个可用操作且频繁切换。
**When NOT to Use**: 仅 1-2 个操作——用内联按钮。

---

### 15. Batch Operations

**Category**: Efficiency
**Used In**: 球员管理、比赛安排

**Description**: 多选实体后进行批量操作。Ctrl+点击添加/移除选择，顶部出现批量操作工具栏显示选中数量和可用操作。

**Specification**:
- 选择：Ctrl+点击 = 添加/移除单个，Shift+点击 = 范围选择
- 选中态：行背景高亮 + 左侧勾选标记
- 工具栏：选中 ≥1 项时从顶部滑入，显示 "已选 N 项" + 批量操作按钮
- 批量操作按钮：训练、调整阵容、释放等
- 取消选择：点击空白区域或 ESC
- 操作完成后自动清除选择

**When to Use**: 列表中有 3+ 项且需要重复相同操作。
**When NOT to Use**: 每项操作都不同——逐项处理。

---

### 16. Screen Transition

**Category**: Animation
**Used In**: All screen transitions

**Description**: 界面之间的过渡动画。不同导航层级使用不同转场效果：深入（L1→L2）从右滑入，返回（L2→L1）向右滑出，弹窗（L2→dialog）从下方弹出，主菜单进入游戏用淡入淡出。

**Specification**:
| Transition | Animation | Duration |
|------------|-----------|----------|
| L1 → L2 (push) | Slide in from right | 250ms ease-out |
| L2 → L1 (pop) | Slide out to right | 200ms ease-in |
| Dialog open | Pop up from bottom + overlay fade in | 200ms ease-out |
| Dialog close | Shrink down + overlay fade out | 150ms ease-in |
| Main menu → Game | Full black fade in → fade out to game | 500ms |

- 所有过渡动画需在 reduced-motion 模式下缩短为 50ms 淡入淡出

**When to Use**: 任何界面切换。
**When NOT to Use**: 同层级标签切换——用 Tab-Based Section Switching 的滑入。

---

### 17. Micro-interaction

**Category**: Animation
**Used In**: 全局

**Description**: 小尺度即时反馈动画，增强操作响应感。MVP 中只用于按钮响应、数值变化、状态强调和已确认结算项反馈；不默认承诺通知中心脉冲、成就粒子或未接入系统的演出。

**Specification**:
- 按钮弹跳：scale 100→90→105→100%，300ms
- 数字变化：从旧值滚动到新值（逐帧递增），200ms 持续
- 状态强调：单次轻量高亮，不使用循环脉冲
- 成功反馈：绿色勾选图标 + 文字说明 + 轻微弹跳
- 错误反馈：界面轻微水平抖动 (±3px, 3 次)，200ms，并附文字原因
- 已确认结算项反馈：数值飞向对应 HUD 资源栏，500ms

**When to Use**: 任何需要即时操作响应的场景。
**When NOT to Use**: 大尺度布局变化——用 Screen Transition。

---

### 18. Pixel Animation Frames

**Category**: Animation
**Used In**: 背景动画、角色动画、环境循环

**Description**: 像素艺术的标准帧动画规范。循环动画使用 6 帧、2 秒周期，确保动作清晰可读。一次性动画（如进球庆祝）使用 8-12 帧、4 秒周期。

**Specification**:
- 循环动画：6 帧，333ms/帧，2 秒完整周期
- 一次性动画：8-12 帧，300-500ms/帧
- 帧尺寸：32×32px（角色）、64×64px（大型元素）
- 播放方式：sprite sheet 帧序列，无补间
- 暂停状态下冻结全部帧动画

**When to Use**: 所有像素艺术动画元素。
**When NOT to Use**: UI 控件动画——用 Micro-interaction。

---

### 19. Resolution Adaptation

**Category**: Adaptation
**Used In**: All screens

**Description**: 界面响应不同分辨率窗口。最低支持 1280×720，推荐 1920×1080。使用等比缩放，保持 16:9 安全区。超出 16:9 的区域用背景色或像素装饰填充。

**Specification**:
- 最低分辨率：1280×720
- 推荐分辨率：1920×1080
- 缩放策略：等比缩放，保持宽高比
- 安全区：界面全部元素保持在 16:9 区域内
- 超宽屏 (>16:9)：左右填充背景色或像素装饰边框
- UI 元素使用 anchor 定位（顶部栏固定顶部，底部栏固定底部）

**When to Use**: 全局生效。
**When NOT to Use**: N/A —— 所有界面必须遵守。

---

### 20. Font Readability

**Category**: Adaptation
**Used In**: All screens

**Description**: 像素游戏中的字体可读性标准。正文最小 14px，标题 18-24px。所有文本需在 4px 像素网格上对齐。使用像素字体（自定义像素字），避免抗锯齿渲染。

**Specification**:
- 正文：最小 12px（像素字体等价），推荐 14-16px
- 标题：18-24px
- 小标签/tooltip：12px
- 行高：1.5× font-size
- 渲染：关闭抗锯齿，保持像素锐利
- 对比度：文字与背景比至少 4.5:1（正文）、3:1（大号标题）
- 中文字体：使用像素艺术风格中文字体或位图字

**When to Use**: 所有显示文字的元素。
**When NOT to Use**: N/A —— 全局标准。

---

### 21. Color-Blind Friendly

**Category**: Adaptation
**Used In**: All screens

**Description**: 所有用颜色传达信息的元素必须同时使用图标和文字作为冗余编码。红/绿状态不可仅靠颜色区分——需要附加图标（如 ✅/❌）或文字标签。

**Specification**:
- 状态指示：颜色 + 图标 + 文字标签三重编码
- 稀有度：颜色边框 + 星级 + 文字标签（"稀有"、"传奇"等）
- 正/负面反馈：绿色/红色 + ✅/❌ 图标 + 文字说明
- 可放置/不可放置：绿色/红色边框 + ✓/✗ 图标
- 避免依赖的颜色对：红-绿、蓝-紫、绿-黄

**When to Use**: 任何用颜色传递信息的 UI 元素。
**When NOT to Use**: 纯装饰性颜色（背景色、氛围色）无需冗余编码。

---

### 22. Toggle Switch

**Category**: Control
**Used In**: 设置面板、future-only 可逆系统开关

**Description**: 双态即时切换控件。点击或按 Space 在开/关之间切换，无确认步骤。滑块动画提供即时的状态变化反馈。

**Specification**:
- 尺寸：轨道 40×22px，圆形滑块 18×18px
- 开启态：轨道填充主色（足球橙 #FF9800），滑块居右
- 关闭态：轨道填充灰色 (#757575)，滑块居左
- 悬停：轨道亮度 +10%
- 点击：滑块滑动至对侧（150ms ease-out）+ #3 Button click sfx
- 禁用态：50% 透明度，无交互
- 键盘：Tab 聚焦 → Space 切换
- 标签：点击关联文字标签也可切换状态

**When to Use**: 即时生效且可逆的双态设置（选项开关、过滤器、future-only 系统开关）。
**When NOT to Use**: 有资源消耗或不可逆的状态变更——使用 Light Confirmation 或 Important Confirmation。

---

### 23. Dropdown Menu

**Category**: Control
**Used In**: 排序控件、阵型选择、筛选条件

**Description**: 点击触发按钮后，在其下方弹出浮动选项列表。选中项高亮，点击选项或点击外部区域关闭菜单。最多展示 8 项，超出时菜单内部滚动。

**Specification**:
- 触发按钮：显示当前选中值 + ▼ 箭头图标，使用 #3 Button Feedback
- 菜单宽：180px 最小宽度，自适应内容
- 菜单项高：32px，左侧可选勾选标记 + 右侧文字
- 悬停菜单项：背景高亮（暖灰色 10% 透明度）
- 选中项：勾选标记 + 文字加粗
- 分隔线：1px 暖灰色，用于分组相关选项
- 关闭：点击菜单外区域 / 点击选项 / ESC
- 键盘：↑↓ 在菜单项间移动，Enter 选中，ESC 关闭
- 超出视口：自动向上翻转（底部空间不足时）

**When to Use**: 3-8 个互斥选项需要选择其一时。
**When NOT to Use**: 2 个选项——用 Toggle Switch；8+ 选项——考虑带搜索的列表。

---

### 24. Progress Bar

**Category**: Information
**Used In**: 运动点数条、经验条、赛季进度、future-only 建造进度

**Description**: 横向填充条展示当前值相对于最大值的比例。配合标签显示具体数值或百分比。颜色根据阈值变化（正常/警告/危险）。

**Specification**:
- 轨道：全宽，高 12-16px，圆角 2px，深色背景
- 填充：从左侧开始填充，宽度 = (current / max) × 100%
- 颜色阈值：>50% 主色 → 25-50% 黄色 (#FFC107) → <25% 红色 (#E53935)
- 标签：填充条右侧或内部显示 `180/200` 或百分比
- 动画：数值变化时填充条平滑过渡（200ms ease-out）
- 不确定态：填充条来回扫动动画（数据加载中但总量未知时）

**When to Use**: 任何需要展示完成度、余量或进度的数值比率。
**When NOT to Use**: 绝对值不重要、仅为装饰的度量——用 Stat Display。

---

### 25. Input Field

**Category**: Control
**Used In**: 搜索框、确认文字输入、球员名编辑

**Description**: 单行文本输入区域。包含 placeholder 提示、focus 高亮边框、字符计数、以及格式校验的即时反馈。

**Specification**:
- 尺寸：高度 32-40px，宽度自适应容器
- 默认态：1px 暖灰色边框 + 白色/浅色填充
- Placeholder：灰色文字，斜体，输入内容后消失
- Focus 态：边框变为足球橙 (#FF9800) 2px + 外发光
- Error 态：边框变为红色 (#E53935) + 错误提示文字
- 字符计数：右下角显示 `N/MAX`，超出上限时数字变红
- 清除按钮：右侧 ✕ 图标，有内容时出现
- 键盘：Tab 切换焦点，Enter 提交（若有关联操作）
- 文本输入框中禁用全局快捷键

**When to Use**: 需要玩家输入文字的场景（搜索、命名、确认文本）。
**When NOT to Use**: 从预设选项中选择——用 Dropdown Menu。

---

### 26. Scroll Behavior

**Category**: Navigation
**Used In**: 球员列表、事件时间线、帮助面板、训练/比赛结果列表

**Description**: 内容超出容器的统一滚动交互。鼠标滚轮、键盘方向键和拖拽滚动条均可操作。滚动条在非操作时自动隐藏，保持界面简洁。

**Specification**:
- 滚动条宽：6px，圆角 3px，半透明暖灰色
- 悬停滚动条：不透明度从 40% → 70%
- 非操作时：滚动条 1.5s 后淡出（不透明度 → 0%）
- 鼠标滚轮：逐行滚动（每格 24px）
- 键盘：↑↓ 逐行滚动，PgUp/PgDn 逐页滚动，Home/End 跳至首尾
- 动量滚动：快速滚轮后惯性衰减（衰减系数 0.90，200ms 停止）
- 边界：到达顶部/底部时无弹性效果（与 Map Pan 不同）

**When to Use**: 任何内容高度超出容器的列表或文本区域。
**When NOT to Use**: 地图级缩放平移——用 #6 Map Pan & Zoom。

---

### 27. Grid Layout

**Category**: Information
**Used In**: 可选卡片集合、future-only 技能/建筑/成就/商店界面

**Description**: 等宽卡片/图标按网格排列，列数根据容器宽度自动调整。卡片间距一致，每张卡片使用 #12 Data Card Display 模式。

**Specification**:
- 最小列宽：160px（低于此宽度减列）
- 列间距：12px，行间距：12px
- 响应式列数：容器宽 / (160 + 12) → 向下取整
- 最小列数：1（窄屏），最大列数：6（超宽屏）
- 卡片：等宽不等高，顶部对齐
- 空网格：居中显示 Empty State 占位
- 加载态：骨架卡片（灰色占位 × 列数）

**When to Use**: 展示 4+ 个同类实体的摘要卡片。
**When NOT to Use**: 列表项需要跨列详细对比——用 #5 List Item Selection 的列表视图。

---

### 28. Toast Notification

**Category**: Feedback
**Used In**: 训练完成、资源不足警告、赛后/赛季轻量反馈、自动保存提示

**Description**: 从屏幕顶部或底部滑入的轻量非阻塞反馈。Toast 不是通知中心，不提供常驻入口、未读角标或历史列表。它自动在短时间后消失，不打断当前操作，携带图标、标题和简短描述。多个 Toast 时按优先级排队，同时最多显示 3 条。

**Specification**:
- 位置：屏幕右上角（默认）或顶部居中
- 尺寸：300px 宽，高度自适应内容（最大 80px）
- 滑入动画：从顶部滑入（200ms ease-out）
- 消失动画：淡出 + 上滑（200ms ease-in）
- 显示时长：3s（信息型）/ 5s（警告型）/ 手动关闭（错误型）
- 类型样式：
  - 信息 (Info)：中性色边框 + ℹ️ 图标
  - 成功 (Success)：绿色边框 (#43A047) + ✅ 图标
  - 警告 (Warning)：黄色边框 (#FFC107) + ⚠️ 图标
  - 错误 (Error)：红色边框 (#E53935) + ❌ 图标
- 优先级队列：Error > Warning > Success > Info
- 同时显示上限：3 条，超出时最早的信息型通知被顶出
- 操作：悬停可暂停自动消失计时；MVP 默认不点击跳转，除非对应界面规格明确声明
- 键盘：无焦点——纯展示，不打断 Tab 序

**When to Use**: 非关键操作的结果反馈（训练完成、资源不足、自动保存）。
**When NOT to Use**: 需要玩家确认的关键结果——用 Light/Important Confirmation；比赛进球——用赛中事件流；需要历史列表或未读管理——future Notification Center。

---

### 29. Tooltip

**Category**: Information
**Used In**: 图标按钮悬停、属性标签说明、资源消耗明细、雷达图数值

**Description**: 悬停或长按可交互元素后出现的上下文信息浮层。无交互元素——纯展示补充信息。智能检测视口边缘并自动翻转方向。

**Specification**:
- 触发：鼠标悬停 300ms 后显示（无延迟累积）
- 消失：鼠标移出立即消失 / 3s 后自动消失
- 字体：12px 像素字体
- 最大宽度：200px，文字自动换行
- 背景：深色 (#212121) 80% 不透明度 + 1px 暖灰色边框
- 内边距：6px 水平 + 4px 垂直
- 位置：默认出现在触发元素下方 4px；下方空间不足时翻转到上方；左右同理
- 箭头：三角指示器指向触发元素中心

**When to Use**: 需要为可交互元素补充简短说明但不需要永久占屏空间。
**When NOT to Use**: 关键操作说明——应内联显示而非隐藏在 tooltip 中；长段落内容——用帮助面板。

---

### 30. Loading State

**Category**: State
**Used In**: 任何有异步数据加载的界面（存档读取、比赛模拟、数据查询）

**Description**: 界面数据尚未就绪时的过渡展示。使用骨架屏（skeleton screen）而非空白屏幕或单一旋转图标，让玩家对即将出现的内容结构有预期。

**Specification**:
- **骨架屏**：用灰色占位块模拟实际内容的形状和位置——标题区（长条 60% × 20px）、卡片区（矩形 × N）、列表行（横条 × N）
- **闪烁动画**：占位块亮度在 40% ↔ 60% 之间呼吸渐变（1.5s 周期）
- **加载文字**：内容区顶部居中显示「加载中...」，12px 灰色像素字体
- **超时处理**：5s 后仍未完成 → 骨架屏保留 + 显示「加载时间较长，请稍候...」+ `[重试]` 按钮
- 加载期间：所有交互控件禁用（50% 透明度），导航按钮可用（允许取消等待）
- 数据就绪后：骨架屏淡出（150ms）→ 真实内容淡入（150ms）

**When to Use**: 任何内容区需要等待异步数据才能渲染时。
**When NOT to Use**: 即时同步渲染的界面——直接展示内容。

---

### 31. Empty State

**Category**: State
**Used In**: 球员列表为空、比赛记录为空、搜索无结果、future-only 建设列表为空

**Description**: 当列表或内容区无数据可展示时的引导性占位。不展示空白崩溃——始终提供解释说明和下一步操作的入口。

**Specification**:
- 布局：内容区垂直居中，元素自上而下排列
- 插图：像素艺术占位图（64×64px），根据不同上下文选用不同图标
  - 球员空：⚽+👤 组合图标
  - 比赛空：🏟️ 空心图标
  - 搜索无结果：🔍+✕ 图标
  - 通用空：📭 图标
- 标题：14px 像素字体，描述当前状态（如「还没有球员」）
- 说明：12px 灰色文字，解释原因并引导下一步（如「前往招募你的第一名球员」）
- CTA 按钮：引导操作的快捷入口（如 `[招募新球员]`），使用 #3 Button Feedback 主按钮样式
- 首次空状态（新档）vs 常态空状态（过滤无结果）：前者包含教学性引导，后者只提供清除筛选

**When to Use**: 任何列表、网格或内容区在合法状态下可能为空时。
**When NOT to Use**: 数据正在加载中——用 #30 Loading State；数据错误——用 Error State。

---

### 32. Radar Chart

**Category**: Information
**Used In**: 球员详情、训练中心

**Description**: 五维属性雷达图，以五边形可视化球员的五项核心属性。实线表示当前值，虚线表示潜力上限。每个轴支持悬停查看精确值和距上限差距，键盘 Tab 逐轴访问。

**Specification**:
- 轴数：5 轴（SPD/PWR/TEC/INT/STA），轴间距 72°
- 当前值：实线填充，主色（足球橙 #FF9800）40% 透明度
- 潜力上限：虚线边框，灰色（#757575）60% 透明度
- 数值范围：每轴 0-100，刻度间隔 20
- 轴标签：每轴外侧显示属性缩写（12px 像素字体）
- 悬停轴：高亮当前值标记点 + tooltip 显示「{属性名} {当前值}/{潜力上限} — 潜力剩余 {差距}」
- 已达上限：该轴标记 🔒 锁图标（12×12px），tooltip 显示「已达上限」
- 键盘：Tab 逐轴访问，每轴 Enter 展开 tooltip 精确值
- 更新动画：值变化时填充区域平滑过渡（200ms ease-out）
- 空状态：数据未加载时显示灰色五边形骨架（#424242 30% 透明度）
- 屏幕阅读器：逐轴播报「{属性名} {当前值}/{潜力上限} — 潜力剩余 {差距}」；已达上限播报「{属性名} 已达上限」

**Reduced-motion**：禁用填充过渡动画，值变化时静态更新形状。

**When to Use**: 需要在 3+ 维度上同时展示当前能力和成长空间。
**When NOT to Use**: 单维度进度——用 Progress Bar（#24）；少于 3 维度的比较——用 Stat Display。

---

## Animation Standards

所有 UI 动画首先服务于**状态确认、注意力引导与层级切换**，而不是装饰表演。
本节是全局动画基线；各个具体模式（如 `#16 Screen Transition`、`#17 Micro-interaction`、`#18 Pixel Animation Frames`）必须在此范围内细化，不得冲突。

### Timing Table

| 类别 | 默认时长 | 最大时长 | Reduced-motion | 用途 |
|---|---:|---:|---:|---|
| Screen Transition | 200–250ms | 400ms | 50ms fade | L1/L2/L3 界面切换、返回、主流程跳转 |
| Dialog / Overlay | 150–200ms | 250ms | 50ms fade | 确认框、暂停菜单、中场覆盖层、模态层 |
| Micro-interaction | 150–300ms | 300ms | 50ms 或静态高亮 | 按钮反馈、数值变化、轻量状态切换 |
| Emphasis Animation | 200–500ms | 500ms | 静态高亮 | 比分变化、成长结果、关键可进入状态 |
| Auto-dismiss Feedback | 200ms 进入 / 200ms 退出 | 250ms | 50ms fade | Toast、轻量提示 |
| Looping Ambient Motion | 2s 周期 | 2s 周期 | 停止或静态帧 | 环境像素循环、背景装饰演出 |

### Usage Rules

- **Screen Transition** 只用于屏幕级或容器级切换，不用于局部组件反馈。
- **Dialog / Overlay** 动画必须比主屏切换更轻，避免模态层显得“比主流程更重”。
- **Micro-interaction** 只用于局部反馈：点击、选中、数值更新、状态确认。
- **Emphasis Animation** 只用于单次关键事件强调，不得作为持续噪声常驻存在。
- **Looping Ambient Motion** 只服务气氛和世界活性，不得承载关键状态信息。

### Priority Rules

当多个动画可能同时触发时，按以下优先级保留最高层级，避免视觉冲突：

1. Blocking modal / critical overlay
2. Screen transition
3. Emphasis animation
4. Micro-interaction
5. Ambient looping motion

若高优先级动画触发，低优先级动画应暂停、延后或直接静态结算，不得叠加成视觉噪音。

### Reduced-Motion Rules

当系统或游戏设置启用 reduced-motion 时：

- 所有 Screen Transition 与 Dialog / Overlay 降级为 **50ms 淡入淡出**
- 所有 Micro-interaction 降级为 **50ms 亮度变化** 或 **静态高亮**
- 所有 Emphasis Animation 降级为 **静态高亮 / 边框变化 / 图标提示**
- 所有粒子、脉冲、抖动、数字滚动、连续缩放一律禁用
- 所有循环环境动画停止，或停留在可读静态帧
- 不允许 reduced-motion 模式下保留“轻微震动也没关系”的例外写法

### Forbidden

以下动画做法在项目中一律视为不合规：

- **≥ 3Hz 的快速频闪**
- **无限循环的强调脉冲**（尤其是按钮、提醒入口、状态警告）
- **把动画作为唯一状态表达方式**
- **需要玩家等待动画播完才能继续关键操作**
- **多个同级强调动画同时争抢注意力**
- **reduced-motion 开启后仍保留粒子、抖动、连续缩放或数字滚动**

### Implementation Notes

- 若某个具体界面需要更慢或更重的动画，必须在对应 UX spec 中说明理由，且不得突破本表最大时长。
- 若某个界面引入新的动画类别，应先在本模式库补充，而不是只在单一 UX spec 中私有定义。
- `#16 Screen Transition`、`#17 Micro-interaction`、`#18 Pixel Animation Frames` 是本标准的下游细化模式；若细节冲突，以本节为准并回修对应模式。

---

## Sound Standards

所有 UI 音效的统一规范。音效由音频系统提供，本表定义交互层的触发时机和优先级。

| Event | Category | Trigger | Priority | Duration | Description |
|-------|----------|---------|----------|----------|-------------|
| Button Click | UI Feedback | 任何按钮按下（#3, #4） | High | 50ms | 短促像素风点击音，确认操作已被接收 |
| Toggle Switch | UI Feedback | Toggle 状态切换（#22） | High | 50ms | 与 Button Click 同音效 |
| Dialog Open | UI Feedback | 弹窗出现（#9, #10） | High | 80ms | 轻微上滑音，提示模态切换 |
| Dialog Close | UI Feedback | 弹窗关闭 | Medium | 60ms | 下滑收回音，低于 Open 音量 |
| Notification Arrive | UI Feedback | Toast 滑入（#28） | Medium | 100ms | 轻柔提示音，不打断当前操作 |
| Success Feedback | UI Feedback | 操作成功（训练完成、future-only 建造完成） | High | 120ms | 上行音阶，3 个音符递增 |
| Error Feedback | UI Feedback | 操作失败、校验不通过 | High | 150ms | 下行短音，2 个音符 + 轻微 buzz |
| Resource Change | UI Feedback | 经费/AP 数值变化 | Low | 60ms | 轻微硬币/点数音（仅在变化 ≥ 阈值时播放） |
| Building Place | Game Event | 建筑成功放置（#7） | High | 200ms | 下落重音 + 尘土粒子配合音 |
| Building Invalid | Game Event | 建筑放置位置不合法 | Medium | 80ms | 短促拒绝音 |
| Drag Pickup | UI Feedback | 拖拽拾取（#7, #8） | Low | 40ms | 轻微拾取音 |
| Drag Drop | UI Feedback | 拖拽放下成功（#7, #8） | Medium | 60ms | 放置确认音 |
| Screen Transition | Navigation | 界面切换（#16） | Low | 100ms | 轻微滑音，方向与转场方向一致 |
| Match Whistle | Game Event | 比赛开球/结束 | High | 300ms | 裁判哨声——比赛叙事锚点 |
| Match Goal | Game Event | 进球事件 | Highest | 400ms | 哨声 + 短促欢呼——最高优先级音效 |
| Achievement Unlock | Game Event / Future | future-only 里程碑/成就触发 | High | 250ms | 上行音阶 5 音符 + 粒子配合 |

**音量层级**：
- UI Feedback: 基准音量 60%（不压倒游戏音效）
- Game Event: 基准音量 80%
- Navigation: 基准音量 40%（频繁触发，需低调）
- Match 事件: 基准音量 100%

**Reduced-motion 联动**：系统 reduced-motion 开启时，UI Feedback 类音效音量降至 30%；Game Event 类保持不变。

**实现备注**：音效文件的具体格式和存储路径由音频系统（`design/gdd/audio-system.md`）定义。本表仅声明交互触发时机和优先级——UI 实现时在对应交互点预留音效调用锚点。

---

## Non-MVP Future Patterns

以下模式不是 MVP 当前缺口，不得被解释为当前屏幕实现承诺。只有当对应系统进入正式 UX 范围并通过独立 spec 后，才可从 future-only 状态提升为 MVP/Alpha 模式。

| # | Future Pattern | When Needed | Priority |
|---|----------------|-------------|----------|
| F1 | Notification Center | Future 通知历史、未读管理、通知详情入口 | Low |
| F2 | Tutorial Overlay | 新手引导的遮罩高亮 + 指示箭头 + 步骤流程 | Low |
| F3 | Save/Load UI | 存档槽选择、确认覆盖、删除存档 | Low |
| F4 | Slider | 设置面板（音量调节等）、比赛速度细调 | Low |
| F5 | Interactive Town Map | Future 地图拖拽、缩放、建筑/角色热点 | Low |
| F6 | Building Placement | Future 建设模式网格与建筑拖放 | Low |

新增或提升模式流程：先在对应界面 UX Spec 中定义行为与无障碍要求 → 经 `/ux-review` 验证 → 再追加或更新 Pattern Catalog。

---

## Open Questions

| ID | Question | Priority | Resolution Path |
|----|----------|----------|-----------------|
| QQ-01 | 无障碍层级已确认为 WCAG-AA（见 `design/accessibility-requirements.md`） | High | RESOLVED — 所有 UX spec 须引用该文档 |
| QQ-02 | 玩家旅程地图未创建 —— 界面设计缺乏玩家情绪和上下文锚点 | Medium | 创建 `design/player-journey.md` |
| QQ-03 | 像素中文字体尚未选定 —— 影响 Font Readability 模式的具体数值 | Medium | 技术选型阶段确定 |
| QQ-04 | 通知中心不属于 MVP 小镇主视图；若 future 版本接入，需独立 UX spec | Low | Future-only，当前不阻塞 MVP |
