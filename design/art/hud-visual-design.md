# HUD Visual Design Spec: 足球小镇

> **Status**: ⚠️ 部分条款已被 `STYLE_GUIDE.md` (V1.0 终稿, 2026-07-10) 取代
> **Author**: nico + art-director
> **Last Updated**: 2026-05-19 (冲突标记: 2026-07-10)
> **Implements**: `design/ux/hud.md`, `design/ux/interaction-patterns.md`, `design/accessibility-requirements.md`
> **Template**: Visual Design Specification
>
> **⚠️ 重要提示**: 本文在 2026-07-10 经过与 `STYLE_GUIDE.md` 的逐条对比。标记 `[已废弃，见 STYLE_GUIDE.md]` 的条款以 STYLE_GUIDE 为准。未标记的 HUD layout 框架（Zone 分区逻辑、focus order、toast/tooltip/dialog 行为规范、accessibility 规则）仍然有效。

---

## 1. Color Palette

### 1.1 Rationale

HUD 视觉必须服务已批准的 **严格 MVP HUD**：玩家在 3 秒内读懂时间、资源、行动能力、下一场比赛状态，以及两个核心入口。视觉目标不是做一个功能密集的运营面板，而是做一个稳定、低噪声、可快速扫读的状态条系统。

Production 全局基线采用暖亮 town UI：浅暖面板、木质/琥珀边框、深棕正文与足球橙强调色，优先服务“像素小镇养成”的亲和感。深色底板只保留给 Match Live、警告遮罩或局部高紧张状态，不能作为 Home / Roster / Training 的全局基调。强调只给真正需要注意的状态：菜单焦点、比赛就绪、禁用原因提示、错误/警告反馈。常态下不使用持续脉冲、不使用滚动 ticker、不使用大面积动画。

### 1.2 Production Town-Light Delta Palette

[已废弃，见 STYLE_GUIDE.md §3 绝对色板 + §4 界面交互铁律]

以下 token 定义保留作为历史参考。STYLE_GUIDE 已锁定 7 色绝对闭环（奶油 `#F2E8D5` / 小镇金 `#D6B35A` / 俱乐部红 `#B84A4A` / 冷静蓝 `#5E7FA3` / 球场绿 `#6F8F5B` / 大地棕 `#8A6B4F` / 石板灰 `#4C4A4A`），任何未出现在该闭环中的色值均为无效。

| Token | Hex | Usage | STYLE_GUIDE 判定 |
|-------|-----|-------|-----------------|
| `town-surface` | `#FFF2D2` | Home / Roster / Training / Result 的默认暖亮面板 | ⚠️ 近似兼容。STYLE_GUIDE 奶油色为 `#F2E8D5`，顶部栏底色 `#FFF2D2` 为具体使用变体 |
| `town-border` | `#C58A3A` | 像素木质边框、卡片分隔、暖色焦点外框 | ❌ 不在 7 色闭环中。STYLE_GUIDE 木质边框为 `#C58A3A`（秋调变体），但主边框应为 `#3A2A1A`（深棕） |
| `town-text` | `#3A2A1A` | 暖亮面板上的正文 | ❌ 不在 7 色闭环中。STYLE_GUIDE 正文使用石板灰 `#4C4A4A` |
| `town-muted` | `#6D5A3A` | 次级说明、训练结果辅助文案 | ❌ 不在 7 色闭环中 |
| `town-accent` | `#C76A00` | 主行动、比赛就绪、标题与关键提醒 | ❌ 不在 7 色闭环中。STYLE_GUIDE 强调色为小镇金 `#D6B35A` 或俱乐部红 `#B84A4A` |
| `match-dark-local` | `#1A1A2E` | Match Live 局部紧张态背景 | ❌ 不在 7 色闭环中。STYLE_GUIDE 比赛暗色为深木炭 `#2A1F1A` |

### 1.3 Core Palette

[已废弃，见 STYLE_GUIDE.md §4 界面交互铁律]

本表格为暗色面板系统的完整色板定义。STYLE_GUIDE §6 体验红线第 2 条明确规定「禁止全局暗色 UI（仅比赛直播 5 分钟内可用）」，因此以下全部 token 仅可在 Match Live 场景中作为历史参考，不得用于 Home / Roster / Training / Result 等日常界面。

| Token | Hex | Usage | Contrast (on `#1A1A2E`) |
|-------|-----|-------|-------------------------|
| `bg-deep` | `#12122A` | 最深背景，弹窗后层、进度条轨道 | -- |
| `bg-base` | `#1A1A2E` | Zone A / Zone C 主背景 | -- |
| `bg-surface` | `#252540` | 按钮、可交互状态块、提示面板 | -- |
| `bg-surface-hover` | `#303058` | Hover 背景 | -- |
| `border-default` | `#3D3D5C` | 主边框 / 分隔线 | 3.2:1 |
| `border-subtle` | `#2E2E4A` | 次级分隔 | -- |
| `text-primary` | `#EAEAEA` | 主文字 | 13.1:1 |
| `text-secondary` | `#9E9EB8` | 次级文字 | 5.2:1 |
| `text-disabled` | `#5C5C7A` | 禁用态文字 | 2.8:1 |
| `accent-primary` | `#FF9800` | 主要强调色、比赛可进入状态、选中态 | 4.8:1 |
| `accent-primary-hover` | `#FFB74D` | Hover 亮化 | 7.2:1 |
| `accent-primary-dim` | `rgba(255,152,0,0.20)` | 轻量高亮背景 | -- |
| `semantic-success` | `#4CAF50` | 资源增长、成功反馈 | 5.2:1 |
| `semantic-warning` | `#FFC107` | 警告、AP 中低阈值 | 6.8:1 |
| `semantic-danger` | `#E53935` | 错误、AP 低阈值、危险反馈 | 5.1:1 |
| `focus-ring` | `#FFD700` | 键盘焦点环 | 8.4:1 |

### 1.3 Overlay Palette

[已废弃，见 STYLE_GUIDE.md §4 通用面板]

以下 Toast 色板均使用暗色背景，与 STYLE_GUIDE 暖亮面板方向不一致。Toast/Dialog 实现时请使用 7 色闭环中的奶油 `#F2E8D5` 面板 + 石板灰 `#4C4A4A` 文字 + 小镇金 `#D6B35A` 标题栏作为基线。

| Token | Hex | Usage |
|-------|-----|-------|
| `overlay-backdrop` | `rgba(0,0,0,0.50)` | 暂停菜单与确认对话框背景遮罩 |
| `overlay-backdrop-danger` | `rgba(180,15,15,0.25)` | 重要确认的危险遮罩 |
| `toast-bg-info` | `#1E283A` | Info Toast |
| `toast-bg-success` | `#1A2E1E` | Success Toast |
| `toast-bg-warning` | `#2E2A18` | Warning Toast |
| `toast-bg-error` | `#2E1A1C` | Error Toast |
| `tooltip-bg` | `#212121` at 92% opacity | Tooltip 背景 |

### 1.4 Color Safety

- 所有状态信息遵守 `#21 Color-Blind Friendly`：颜色 + 图标/符号 + 文字。
- 经费/AP 变化不能只靠红绿；必须同时显示 `▲` / `▼` 或明确文案。
- “比赛已可开始”使用橙色高亮 + 文本，不使用纯色块闪烁。
- 禁用入口必须配合可读原因，不得只有灰掉按钮。

---

## 2. Typography

### 2.1 Font Selection

**Primary Pixel Font**: Zpix (最像素)

- 用于 HUD 全部文字、Tooltip、Toast、暂停菜单。
- 关闭抗锯齿，保持像素对齐。
- 中文与拉丁文统一使用同一套像素风呈现。

### 2.2 Font Sizes

[已废弃，见 STYLE_GUIDE.md §4 Zpix 字体排版]

STYLE_GUIDE 锁定字号为：最大 24px（仅比赛横幅），常规 16px/18px/20px。以下 12px/14px 字号低于 STYLE_GUIDE 常规下限，不再使用。

| Element | Pixel Size | Notes |
|---------|------------|-------|
| Zone A 主数值 / 状态文本 | 14px | 日期、经费、运动点数、行动窗口、下一场比赛 |
| Zone A 次级标签 / 增减量 | 12px | 变化量、说明性补充 |
| Zone C 按钮标签 | 14px | 球员 / 比赛 |
| Tooltip / Toast 正文 | 12px | 辅助说明 |
| 暂停菜单按钮 | 16px | 高可读、低误触 |
| 对话框正文 | 14px | 确认信息 |

### 2.3 Rendering Rules

- 所有文字坐标对齐到整数像素。
- 不使用平滑渐变；只使用纯色或少量抖动高亮。
- 720p 下正文不得小于 12px。
- 125% UI Scale 下不允许裁切、重叠或焦点环越界。

---

## 3. Zone Visual Treatment

### 3.1 Zone A — Top Status Bar (48px → 已废弃为 72px)

[已废弃，见 STYLE_GUIDE.md §4 顶部状态栏]

| 属性 | 本稿值 | STYLE_GUIDE 值 |
|------|--------|---------------|
| 高度 | 48px | **72px** (Y=0~72) |
| 背景色 | `bg-base` (#1A1A2E) | **#FFF2D2** (暖亮奶油) |
| 底部边框 | 1px `border-default` (#3D3D5C) | **2px #C58A3A** (木质边框) |

以下 Zone A 原始规格全部以 STYLE_GUIDE 为准：

```text
┌ 日期/赛季 │ 经费 │ 运动点数 │ 行动窗口 │ 下一场比赛 │ 菜单 ┐
```

| Attribute | Spec |
|-----------|------|
| Background | `bg-base` |
| Border | 底部 1px `border-default` |
| Padding | 左右 8px，垂直居中 |
| Group gap | 16px |
| Divider | 1px `border-subtle` 竖线 |

#### Zone A visual rules

- 日期/赛季：默认普通文本；当可进入 `Schedule` 时，外层容器转为按钮态。
- 经费：显示当前值；如果本次变动非零，右侧显示 12px 增减量。
- 运动点数：图标 + 120×12px progress bar + `current/max` 文本。
- 行动窗口：简短文本，例如 `2 可用`、`0 可用`。
- 下一场比赛：
  - 常态：普通文本，不抢注意力。
  - 比赛就绪：转为按钮态，文字/边框改为 `accent-primary`，允许轻量静态高亮。
- 菜单：右对齐图标按钮，热区不小于 32×32px。

#### Zone A removed from MVP

以下内容 **不得** 出现在 Zone A：
- 声望等级
- 球队整体实力摘要的常驻字段
- 研究点数
- 通知角标
- 滚动信息条

### 3.2 Zone C — Bottom Navigation (56px → 已废弃为 64px)

[已废弃，见 STYLE_GUIDE.md §4 底部导航栏]

| 属性 | 本稿值 | STYLE_GUIDE 值 |
|------|--------|---------------|
| 高度 | 56px | **64px** (Y=1016~1080) |
| 背景色 | `bg-base` (#1A1A2E) | **#8A6B4F** (大地棕) + 奶油细条纹 |
| 顶部边框 | 1px `border-default` (#3D3D5C) | **2px #C58A3A** (木质边框) |
| 按钮布局 | 两个等宽主按钮 | **左侧球员入口 + 右侧比赛入口 + 中间 32×32 队徽** |
| 按钮悬停 | `bg-surface-hover` + 橙色边框 | **#FFF2D2 + 金边** |
| 按钮激活 | 橙色边框/下划线/文字高亮 | **文字 #B84A4A + 左侧 4px 红块指示器** |

以下 Zone C 原始规格全部以 STYLE_GUIDE 为准：

```text
┌ 球员入口 │ 比赛入口 ┐
```

| Attribute | Spec |
|-----------|------|
| Background | `bg-base` |
| Border | 顶部 1px `border-default` |
| Layout | 两个等宽主按钮，居中，左右安全边距 16px |
| Button height | 40px–44px 视觉高度，保证热区可点 |
| Gap | 12px |

#### Zone C visual rules

- **球员入口**：默认可用；当玩家处于 Roster / Player Detail / Training 相关界面时可显示选中态。
- **比赛入口**：
  - 未到比赛节点：禁用态，保留标签，但显式呈现不可用。
  - 比赛就绪：转为主要强调按钮（橙色边框或填充），与顶部“下一场比赛”同步高亮。
- 不允许在底部再加入任务、建设、商店、统计等入口。

### 3.3 Non-MVP zones

以下旧区域在严格 MVP 中不存在：
- 左侧侧栏（Zone B）
- 底部五标签条
- Info Ticker / Zone C2
- 常驻通知入口

---

## 4. Control Styling

[已废弃，见 STYLE_GUIDE.md §4 界面交互铁律]

本节省略全部原始状态表。所有按钮/进度条/图标按钮的状态颜色均引用暗色面板 token（`bg-surface`, `bg-surface-hover`, `accent-primary` #FF9800, `semantic-warning` #FFC107 等），与 STYLE_GUIDE 暖亮基线不兼容。重新实现时请直接参照 STYLE_GUIDE 7 色闭环定义 hover/active/disabled 状态。

### 4.1 Status Button

适用于：可点击的日期区域、可点击的“下一场比赛”状态。

| State | Treatment |
|-------|-----------|
| Default | 透明背景 + 主文字 |
| Hover | `bg-surface-hover` 轻量底板 + 1px `accent-primary` 边框 |
| Focus | 2px `focus-ring` |
| Disabled | 文字 `text-secondary` / `text-disabled`，无 hover/focus |
| Match Ready | 文字和边框切换为 `accent-primary`，不闪烁 |

### 4.2 Primary Navigation Button

适用于：底部 `球员`、`比赛` 两个主入口。

| State | Treatment |
|-------|-----------|
| Default | `bg-surface` + 1px `border-default` |
| Hover | `bg-surface-hover` + 橙色边框 |
| Pressed | 95% 轻微缩放，`bg-deep` |
| Selected | 橙色边框 / 橙色下划线 / 文字高亮 |
| Disabled | 50% 透明度 + `text-disabled` |
| Match Ready | 比赛按钮进入 Primary Variant，高优先级但不脉冲 |

### 4.3 Icon Button

适用于：菜单按钮。

| State | Treatment |
|-------|-----------|
| Default | 20×20px 图标，透明背景 |
| Hover | `accent-primary-dim` 圆/方形高亮底 |
| Pressed | 100 → 90 → 105 → 100% 的轻量反馈 |
| Focus | 2px `focus-ring` |
| Disabled | 50% 透明度 |

### 4.4 Progress Bar

适用于：运动点数条。

| Attribute | Spec |
|-----------|------|
| Track | `bg-deep`，1px `border-default` |
| Fill >50% | `accent-primary` |
| Fill 25–50% | `semantic-warning` |
| Fill <25% | `semantic-danger` |
| Label | 右侧 `current/max` |
| Motion | 默认 200ms 平滑过渡；reduced-motion 下静态更新 |

---

## 5. Overlay Styling

### 5.1 Pause Menu

| Attribute | Spec |
|-----------|------|
| Backdrop | `overlay-backdrop` |
| Panel | 居中，宽 280px–320px，2px `border-default` |
| Options | Continue / Save / Load / Settings / Main Menu / Quit |
| Focus | 打开后落到 Continue，关闭后返回 HUD 触发按钮 |
| Motion | 150ms 淡入；reduced-motion 下 50ms |

### 5.2 Toast Notification

| Attribute | Spec |
|-----------|------|
| Position | 右上角，距边缘 16px |
| Width | 300px |
| Stack limit | 同屏最多 3 条 |
| Motion | 200ms 滑入 / 淡出；reduced-motion 下 50ms 淡入淡出 |

### 5.3 Tooltip

| Attribute | Spec |
|-----------|------|
| Trigger | Hover 300ms 或键盘聚焦 |
| Width | 最大 200px |
| Background | `tooltip-bg` + 1px 边框 |
| Content | 12px 像素字，简短解释，不承担关键说明 |

### 5.4 Confirmation Dialog

- 继续使用已定义的 `Light Confirmation` / `Important Confirmation` 模式。
- HUD 本身不扩展新的确认视觉模式。

---

## 6. Focus Indicator

| Rule | Spec |
|------|------|
| Color | `focus-ring` (`#FFD700`) |
| Width | 2px |
| Visibility | 仅键盘导航时显示 |
| Order | 服从已批准 UX：日期（仅可用时）→ 下一场比赛（仅可用时）→ 菜单 → 球员 → 比赛 |

- 只读统计项（经费、运动点数、行动窗口）不进入 Tab 顺序。
- 禁用按钮与隐藏按钮不进入 Tab 顺序。

---

## 7. Asset Manifest

所有资源使用 PNG，nearest-neighbor，禁止抗锯齿。

### 7.1 Zone A Icons

| Asset ID | Name | Size |
|----------|------|------|
| `ico_calendar_20px` | 日期 / 赛季 | 20×20 |
| `ico_funds_20px` | 经费 | 20×20 |
| `ico_ap_20px` | 运动点数 | 20×20 |
| `ico_action_window_20px` | 行动窗口 | 20×20 |
| `ico_menu_hamburger_20px` | 菜单 | 20×20 |

### 7.2 Zone C Buttons

| Asset ID | Name | Size |
|----------|------|------|
| `ico_roster_20px` | 球员入口 | 20×20 或 24×24 |
| `ico_match_20px` | 比赛入口 | 20×20 或 24×24 |

### 7.3 Toast / Dialog / Utility

| Asset ID | Name | Size |
|----------|------|------|
| `ico_toast_info` | Info | 16×16 |
| `ico_toast_success` | Success | 16×16 |
| `ico_toast_warning` | Warning | 16×16 |
| `ico_toast_error` | Error | 16×16 |
| `ico_warning_dialog` | Warning | 24×24 |

### 7.4 Explicitly not required for MVP HUD

以下资产不属于严格 MVP HUD：
- 侧栏导航图标集
- 任务/建设/商店/统计五标签图标集
- 通知中心角标图标
- 信息滚动条装饰资产
- 声望星级显示资产

---

## 8. Resolution & Scaling

[已废弃，见 STYLE_GUIDE.md §1 核心基石]

STYLE_GUIDE 锁定：
- 原生分辨率 1920×1080，兼容 1280×720
- 2x 整数缩放（32px→64px），禁止非整数缩放
- Viewport 30列×17行 (960×544 原始像素)
- HUD 顶部 72px + 底部 64px，中央 944px 留给世界

以下原始 Godot 设置仅供参考，实际实现以 STYLE_GUIDE 为准：

| Resolution | Behavior |
|-----------|----------|
| 1280×720 | Zone A / Zone C 固定高度，内容不裁切 |
| 1920×1080 | 设计基准 |
| >16:9 | HUD 延展，但交互主体保持在主要阅读区 |
| 125% UI Scale | 允许高度增加，但不允许按钮重叠、文字裁切、焦点环越界 |

Godot 建议设置：

```text
display/window/stretch/mode = viewport
display/window/stretch/aspect = keep
rendering/2d/snap/snap_2d_transforms_to_pixel = true
rendering/2d/snap/snap_2d_vertices_to_pixel = true
```

---

## Appendix A: WCAG-AA Checks

| Foreground | Background | Ratio | Pass |
|-----------|------------|-------|------|
| `text-primary` | `bg-base` | 13.1:1 | Yes |
| `text-secondary` | `bg-base` | 5.2:1 | Yes |
| `accent-primary` | `bg-base` | 4.8:1 | Yes |
| `semantic-warning` | `bg-base` | 6.8:1 | Yes |
| `semantic-danger` | `bg-base` | 5.1:1 | Yes |
| `focus-ring` | `bg-base` | 8.4:1 | Yes |

## Appendix B: Alignment Notes

- 本文以 `design/ux/hud.md` 为唯一 HUD 范围基线。
- 如果后续要恢复侧栏、ticker 或 5 标签结构，必须先修订 UX Spec，而不是在视觉规格中单独扩展。
- 本文不声明 `.tscn` 结构已实现；它只定义实现时应遵守的视觉标准。
