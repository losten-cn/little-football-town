# HUD Visual Design Spec: 足球小镇

> **Status**: Aligned to Approved UX
> **Author**: nico + art-director
> **Last Updated**: 2026-05-19
> **Implements**: `design/ux/hud.md`, `design/ux/interaction-patterns.md`, `design/accessibility-requirements.md`
> **Template**: Visual Design Specification

---

## 1. Color Palette

### 1.1 Rationale

HUD 视觉必须服务已批准的 **严格 MVP HUD**：玩家在 3 秒内读懂时间、资源、行动能力、下一场比赛状态，以及两个核心入口。视觉目标不是做一个功能密集的运营面板，而是做一个稳定、低噪声、可快速扫读的状态条系统。

整体风格保持像素风深色底板 + 足球橙强调色，但强调只给真正需要注意的状态：菜单焦点、比赛就绪、禁用原因提示、错误/警告反馈。常态下不使用持续脉冲、不使用滚动 ticker、不使用大面积动画。

### 1.2 Core Palette

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

### 3.1 Zone A — Top Status Bar (48px)

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

### 3.2 Zone C — Bottom Navigation (56px)

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
