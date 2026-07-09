# Story 002: HUD 暖亮化迁移

> **Epic**: 视觉方向对齐 (visual-direction-alignment)
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI + Integration
> **Estimate**: M (4-6 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**Authority**: `STYLE_GUIDE.md` §4 (界面交互铁律), §6 (绝对禁止清单)
**ADR Governing Implementation**: ADR-0001 (ScreenManager — HUD 导航必须通过 Screen Stack 模式，不得绕过)
**ADR Referenced**: ADR-0002 (EventBus — UI 订阅/取消订阅生命周期)

**Existing Implementation**: `src/ui/hud/main_loop_shell.gd`, `src/ui/hud/Hud.tscn`, `src/ui/hud/zone_c1.gd` — 当前使用暗色面板体系 (#1A1A2E, #252540, #FF9800)。`design/art/hud-visual-design.md` 中 8 处条款已于 2026-07-10 标记 [已废弃，见 STYLE_GUIDE.md]。

**Engine**: Godot 4.6 + GDScript | **Risk**: MEDIUM
**Engine Notes**:
- Godot 4.6 双焦点系统 — 鼠标和键盘焦点需分别测试
- `snap_2d_transforms_to_pixel = true` — 确保 Zpix 字体 4px 网格对齐时不产生亚像素偏移

**Control Manifest Rules (Presentation Layer)**:
- Required: UI screens 必须遵守 Screen 生命周期，在 `on_enter()` 中订阅事件，`on_leave()` 中取消订阅 (ADR-0001, ADR-0002)
- Forbidden: 不得在 `_process()` 中轮询 Core state 做常规 UI 刷新 (ADR-0002)
- Forbidden: 不得设计新的 gamepad/touch/mobile 交互模式 (technical-preferences)
- Guardrail: 60fps / 16ms 帧预算 / 500 draw calls

## Acceptance Criteria

*From STYLE_GUIDE.md §4:*

- [ ] **AC-1**: 顶部状态栏 (Zone A) — Y=0~72，高度 72px。底色 #FFF2D2。底部 2px #C58A3A 木质边框。布局：左区（赛季/日期 Zpix 16px #3A2A1A + 天气图标 24×24）、中区（经费💰 #D6B35A / 运动点数⚡ #5E7FA3 / 行动窗口 72×28 #6F8F5B 背景白字）、右区（比赛倒计时 #B84A4A + 汉堡菜单 32×32）
- [ ] **AC-2**: 底部导航栏 (Zone C) — Y=1016~1080，高度 64px。底色 #8A6B4F + 奶油细条纹。顶部 2px #C58A3A 边框。仅两个按钮：左侧「👥 球员入口」+ 右侧「⚽ 比赛入口」+ 中间 32×32 队徽。悬停填充 #FFF2D2 + 金边。激活文字变 #B84A4A + 左侧 4px 红块指示器
- [ ] **AC-3**: 通用面板（弹窗）— 边框 2px #3A2A1A + 内框 1px #C58A3A。背景 #FFF2D2。标题栏 #D6B35A。圆角 = 0（绝对直角）。关闭按钮 16×16，悬停变红。尺寸三档：小 640×480 / 中 800×560 / 大 960×640
- [ ] **AC-4**: Zpix 字体 — 唯一字体。关闭抗锯齿。强制 4px 网格对齐。最大字号 24px（仅比赛横幅），常规 16px/18px/20px。禁用状态：原色 + 50% 白色蒙层
- [ ] **AC-5**: 比赛直播 UI（唯一暗色例外）— 顶部栏切换为 #2A1F1A（深木炭），文字反白。比分牌 #B84A4A 底板 + #FFF2D5 大字，置顶中央。计时器 #5E7FA3。终场哨响后 5 秒渐变动画恢复暖色
- [ ] **AC-6**: 禁止全局暗色 UI — 除比赛直播 5 分钟外，Home / Roster / Training / Result / Town 等所有界面必须使用暖亮基线（#FFF2D2 / #F2E8D5 系列），不得出现旧暗色面板 (#1A1A2E, #252540, #12122A)
- [ ] **AC-7**: 现有功能测试不回归 — `tests/integration/ui/main_loop_shell_navigation_test.gd` 和 `tests/integration/ui/mvp_visual_walkthrough_runner.gd` 保持 PASS

## Implementation Notes

*Derived from ADR-0001 and control manifest:*

1. **ScreenManager 边界**: HUD 导航变更不得绕过 ScreenManager。底部「球员入口」和「比赛入口」的导航必须通过 `push_screen`/`replace_screen` 实现，禁止直接 `change_scene_to_file()`。
2. **色板迁移路径**: 在现有 `main_loop_shell.gd` 和 `zone_c1.gd` 中替换全部硬编码颜色常量。提取 7 色闭环到共享常量文件或主题资源中。旧的暗色 token (#1A1A2E, #252540, #FF9800, #3D3D5C 等) 全部移除。
3. **Zone A 高度变更**: 48px → 72px。需同步调整 Zone B (中央世界区域) 的 margin/anchor，确保世界渲染区域不被 HUD 遮挡。顶部栏内容布局需重新适配 72px 高度。
4. **Zone C 高度变更**: 56px → 64px。底部导航栏从等宽双按钮改为左-中-右三区布局（球员入口 / 队徽 / 比赛入口）。禁用态按钮显示具体原因文案，不得仅灰掉。
5. **面板系统**: 创建通用 Panel 主题/组件。所有弹窗（暂停菜单、确认对话框、Toast 通知）统一使用新的暖亮面板样式。圆角必须为 0。
6. **ZPix 字体**: 所有 UI 文字节点须使用 Zpix 字体，关闭 `font_antialiased`。字号严格限制：常规正文 16px/18px/20px，最大 24px 仅用于比赛横幅。旧 12px/14px 字号全部升级。
7. **比赛暗色过渡**: 从暖亮切换到比赛暗色时使用 200ms 渐变动画。终场哨响后 5 秒内从暗色渐变回暖色。过渡期间不阻塞 UI 交互。

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **Story 001**: 世界渲染层 — TileMapLayer/Camera2D/Y-sort 实现。HUD 坐标依赖 Story 001 确认后的 viewport 参数
- **Story 003**: 资产管线 — HUD 图标 (ico_calendar, ico_funds, ico_ap 等) 的实际像素资产生产，本 story 使用现有占位图标
- 后续 story: 从世界建筑点击进入功能（STYLE_GUIDE 要求的导航模式变更，超出 HUD 暖亮化范围）

## QA Test Cases

*For Integration criteria — automated test specs:*

- **AC-6**: 全局暗色 UI 禁止
  - Given: HUD shell 启动，遍历 Home / Roster / Training / Result / Town 各界面
  - When: 检查各界面根面板/容器的 modulate/self_modulate 和 StyleBox 颜色
  - Then: 禁止出现 #1A1A2E, #252540, #12122A 等旧暗色 token。所有界面背景为 #FFF2D2 或 #F2E8D5 系列
  - Edge cases: 比赛直播界面允许 #2A1F1A（暗色例外），但赛后面板必须恢复暖色

- **AC-7**: 现有测试回归
  - Given: UI 集成测试套件已存在
  - When: `godot --headless --path ... --script tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/main_loop_shell_navigation_test.gd`
  - Then: 所有测试 PASS，无新增失败
  - Edge cases: Zone A/C 高度变更可能导致旧坐标断言失败——这些是预期变更，需更新测试期望值而非视为回归

*For UI criteria — manual verification steps:*

- **AC-1**: Zone A 顶部状态栏
  - Setup: 运行游戏，观察主界面顶部栏
  - Verify: 高度 72px，底色 #FFF2D2（暖奶油色，非旧暗色 #1A1A2E），底部有 2px #C58A3A 木质色边框；赛季/日期/经费/AP/倒计时/菜单各元素正确排列
  - Pass condition: 顶部栏暖亮、可读、72px 高度，所有信息项可见

- **AC-2**: Zone C 底部导航栏
  - Setup: 运行游戏，观察主界面底部栏
  - Verify: 高度 64px，底色 #8A6B4F（大地棕）+ 奶油条纹，左侧球员入口 + 中间 32×32 队徽 + 右侧比赛入口
  - Pass condition: 底部栏暖色、64px 高度，三区布局正确，悬停有金边反馈

- **AC-3**: 通用面板
  - Setup: 打开任意弹窗（暂停菜单/确认对话框）
  - Verify: 边框直角（无圆角），外层 2px 深棕 + 内层 1px 金色。标题栏 #D6B35A。关闭按钮悬停变红
  - Pass condition: 面板样式与 STYLE_GUIDE 描述一致，绝对直角

- **AC-4**: Zpix 字体
  - Setup: 观察 UI 各区域的文字（顶部栏/底部栏/面板/Toast）
  - Verify: 所有文字使用 Zpix 像素字体，无抗锯齿模糊，正文 16-20px，无 12px 小字
  - Pass condition: 所有文字清晰像素风格，无模糊，字号合规

- **AC-5**: 比赛暗色例外
  - Setup: 进入比赛直播界面
  - Verify: 顶部栏切换为深木炭 #2A1F1A（非旧 #1A1A2E），比分牌红底 + 大字，计时器蓝色
  - Pass condition: 比赛界面使用批准暗色，赛后 5 秒内渐变恢复暖色

## Test Evidence

**Story Type**: UI + Integration
**Required evidence**:
- Integration: `tests/integration/ui/hud_warm_migration_test.gd` — 7 色板合规断言 + 暗色 token 不存在断言 + 现有测试回归
- UI: `production/qa/evidence/hud-warm-migration-evidence.md` — Zone A/C 截图 + 面板截图 + 比赛暗色切换截图

**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001 (世界渲染层) — HUD 坐标 (Y=0~72, Y=1016~1080) 依赖 viewport 参数确认
- Unlocks: 后续 story — 从世界建筑点击进入功能面板（P3 重校准项）
