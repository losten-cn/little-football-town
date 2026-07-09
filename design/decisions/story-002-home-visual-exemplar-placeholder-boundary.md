# Change Log: Home visual exemplar and placeholder boundary

## 基础信息
- **Story ID**: Story 002
- **Epic**: 主循环 UI 框架
- **负责代理**: gameplay-programmer (执行), lead-programmer / godot-specialist / qa-tester (审查)
- **完成日期**: 2026-07-08

## 变更摘要
- 将 Home 从长摘要块收敛为六张只读信息卡与简短摘要，保留主循环 shell 与既有 route IDs。
- 将比赛入口 authority 收敛为 `MatchStartCoordinator` 统一生产的 `match_entry_state_changed` payload，`MainLoopShell` 与 `ZoneC1` 只消费该结果。
- 增加导航与 authority 回归测试，覆盖 schedule_missing、authoritative disable reason、refresh 不覆盖 lock、match_entry_state 单一 authority。
- 运行 headless + visible-window walkthrough，生成 12 张 PNG，并完成 Home visual exemplar evidence pack。

## 设计决策
| 决策点 | 选择方案 | 理由 | 替代方案 (已否决) |
|--------|----------|------|--------------------|
| Home exemplar 布局 | 短摘要 + 六张信息卡 | 保持 warm-town 可读性，同时满足 `home_info_density` 约束并减少 placeholder 模糊感 | 继续使用单段长摘要；拆成更多可交互模块（超出 story scope） |
| 比赛入口 authority | 由 `MatchStartCoordinator` 统一聚合并发布 `match_entry_state_changed` | 满足 story-002 与 ADR-0010 的“UI 只消费权威 payload，不重算 truth”边界 | 继续让 `MainLoopShell` / `ZoneC1` 本地组合 time/system gate；让 walkthrough 直接注入最终态 |
| 视觉证据链 | 保留 headless 结构验证，并补 visible-window walkthrough 截图 | headless 适合 guardrail，visible-window 才能闭合 screenshot review evidence | 只保留 headless no-image 结构验证；只做人工口头审查而不留 PNG |

## 影响范围
- **修改/新增的文件**:
  - `src/ui/hud/main_loop_shell.gd`
  - `src/ui/hud/zone_c1.gd`
  - `src/core/match_start_coordinator.gd`
  - `tests/integration/ui/main_loop_shell_navigation_test.gd`
  - `tests/integration/ui/mvp_visual_walkthrough_runner.gd`
  - `production/qa/evidence/home-visual-exemplar-placeholder-boundary-2026-07-05.md`
  - `production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md`
- **影响的其他系统**: Main Loop UI, Match Entry authority, QA evidence pipeline, visual walkthrough tooling
- **数据/配置变更**: 无新的 save/event schema；新增运行时 `match_entry_state_changed` authority payload 消费路径

## 质量保证
- **通过的测试**:
  - `tests/integration/ui/main_loop_shell_navigation_test.gd` → `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`
  - `tests/integration/ui/l2_playable_loop_panels_test.gd` → `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
  - `tests/integration/ui/mvp_visual_walkthrough_runner.gd` → `MVP_VISUAL_WALKTHROUGH_STRUCTURE_PASS`, `MVP_VISUAL_WALKTHROUGH_PASS`
- **Agent 审查摘要**: 最终 `/code-review` 结论为 APPROVED WITH SUGGESTIONS；剩余项为非阻塞建议（next-match summary 展示收口、final art 非本 story 范围）。

## 依赖关系
- **前置 Story**: `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
- **后置 Story**: `production/sprints/sprint-3-production-visual-follow-through.md#s3-07`, `production/sprints/sprint-3-production-visual-follow-through.md#s3-08`
