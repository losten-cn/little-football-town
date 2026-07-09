# Change Log: Player / Training visual exemplar boundary

## 基础信息
- **Story ID**: Story 002
- **Epic**: 球员管理 UI
- **负责代理**: ui-programmer / gameplay-programmer (执行), godot-specialist / godot-gdscript-specialist / qa-tester (审查)
- **完成日期**: 2026-07-09

## 变更摘要
- 对 Player / Training 现有挂载页做最小 visual-boundary 收敛，不改变 route、authority topology、save/event schema。
- 强化 roster 行的扫读结构，重排为更清晰的状态/成长/关注/用途/下一步分层。
- 强化 Player Detail 与 Training 结果区的段落结构、按钮状态可读性和玩家-facing disabled reason。
- 更新 `l2_playable_loop_panels_test.gd` 与 walkthrough runner，并补写 Player / Training evidence 文档。

## 设计决策
| 决策点 | 选择方案 | 理由 | 替代方案 (已否决) |
|--------|----------|------|--------------------|
| Player / Training 视觉收敛范围 | 只做 visual-boundary pass，不改 route、authority、schema | 保持 story S3-07 的 Presentation follow-through 边界，避免 scope 扩张 | 同时收敛 explanatory authority contract（已拆到 Story 003） |
| roster/detail/training 信息层级 | 用更明确的多段分组与标题锚点替代单段长文案 | 提升扫读性、截图可审性和 disabled-state 可理解性 | 继续保持旧的长段摘要；引入更深 player-management 功能 |
| authority 漂移处理 | 当前 story 按 advisory 关闭，并新建 Story 003 跟踪 explanatory payload authority contract | 当前 visual exemplar 目标已达成，但严格 authority 纯度仍需单独收敛 | 把 authority contract 收敛继续塞回本 story，扩大范围继续开发 |

## 影响范围
- **修改/新增的文件**:
  - `src/ui/player/player_mgmt_panel.gd`
  - `tests/integration/ui/l2_playable_loop_panels_test.gd`
  - `tests/integration/ui/mvp_visual_walkthrough_runner.gd`
  - `production/qa/evidence/player-training-visual-exemplar-boundary-2026-07-08.md`
  - `production/epics/player-management-ui/story-002-player-training-visual-exemplar-boundary.md`
  - `production/epics/player-management-ui/story-003-authoritative-explanatory-payload-contract.md`
- **影响的其他系统**: Player Management UI, walkthrough evidence pipeline, follow-up explanatory payload authority planning
- **数据/配置变更**: 无新的 save/event schema；无新的 gameplay formula；新增 follow-up authority-contract story 作为追踪工件

## 质量保证
- **通过的测试**:
  - `tests/integration/ui/l2_playable_loop_panels_test.gd` → `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
  - `tests/integration/ui/mvp_visual_walkthrough_runner.gd` → `MVP_VISUAL_WALKTHROUGH_STRUCTURE_PASS`, `MVP_VISUAL_WALKTHROUGH_PASS`
- **Agent 审查摘要**: `/code-review` 结果以 `COMPLETE WITH NOTES` 方式接受关闭；唯一剩余分歧是 explanatory fallback authority 纯度，已拆分到 Story 003。

## 依赖关系
- **前置 Story**: `production/epics/player-management-ui/story-001-roster-training-entry.md`, `production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md`
- **后置 Story**: `production/epics/player-management-ui/story-003-authoritative-explanatory-payload-contract.md`
