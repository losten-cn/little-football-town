## Retrospective: Sprint 8 — Backend Deepening
Period: 2026-07-04 -- 2026-07-11 (计划标注 08-04~08-11 为笔误)
Generated: 2026-07-10 (同日交付，提前关闭)

### Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Stories (Must Have) | 4 | 4 | 0 |
| Stories (Should Have) | 2 | 0 | −2 |
| Completion Rate (Must Have) | -- | 100% | -- |
| Est. Effort Days | 4.8 | ~1 session | −4.8 (大幅提前) |
| Bugs Found (new) | -- | 0 | -- |
| Unplanned Tasks | -- | 0 | -- |
| Commits | -- | 10 | -- |
| Automated Tests | -- | 85 | -- |

### Velocity Trend

| Sprint | Must Haves | Completed | Rate |
|--------|-----------|-----------|------|
| Sprint 4 | 7 | 7 | 100% |
| Sprint 5 | 4 | 4 | 100% |
| Sprint 6 | 3 | 3 | 100% |
| Sprint 7 | 4 | 4 | 100% |
| Sprint 8 | 4 | 4 | 100% |

**Trend**: 稳定 — 连续 5 个 sprint 100% 完成率。单 session 交付能力持续增强。

### What Went Well

- **4 系统同日交付**: RandomEvent (S8-01)、AudioServer (S8-02)、TownBuildConfirm (S8-03)、TutorialHint (S8-04) 在单个 session 内全部实现 + 测试 + /story-done 关闭。每个 story 的 AC 5/5 PASS。
- **全量回归 0 失败**: 85 自动化测试 (42 SceneTree + 43 Node) 全部 PASS，无回归。14 个系统覆盖。
- **延期系统治理收尾**: Sprint 8 实际关闭了 `deferred-systems-governance-2026-07-09.md` 中 6 个延期系统中的 4 个（Random Event、Audio、Town UI、Tutorial/Hint）。仅余 Skill/Trait 和 Reputation/Achievement。
- **Story 管道流畅**: /dev-story → /story-done → /smoke-check 全流程无阻塞。3 个 story 在提交代码后通过 /story-done 正式关闭，流程纪律良好。
- **ADR 合规 0 偏差**: 4 个 story 均严格遵循各自 ADR (ADR-0012、ADR-0013、ADR-0007/0008)，Manifest Version 全部匹配。

### What Went Poorly

- **Should Haves 未执行**: S8-05 (visual-direction-alignment deferred AC 手动验证) 和 S8-06 (Sprint 8 QA plan) 未启动。Sprint 计划中的 Should Have 优先级在实际执行中被 Must Haves 的快速交付所忽视。
- **Sprint 计划日期笔误**: 计划标注 `2026-08-04 to 2026-08-11`，实际工作在 07-10 完成。日期错误导致燃尽计算无法正常进行。
- **Sprint 7/8 边界模糊**: Sprint 8 的 4 个 story 实际是 Sprint 7 建立的 4 个后端 authority stub 的"追加功能 story"。Sprint 7 和 8 更像一个连续的技术深化阶段，而非独立 sprint。

### Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| 无 | — | — | — |

### Estimation Accuracy

| Story | Estimated | Actual | Variance | Note |
|-------|-----------|--------|----------|------|
| S8-01 RandomEvent 窗口 | 1.0d | ~0.5h | 大幅提前 | 基于 S7-02 stub，增量开发 |
| S8-02 AudioServer BGM | 1.0d | ~0.5h | 大幅提前 | AudioManager stub 已建立 |
| S8-03 建造确认流 | 1.0d | ~0.5h | 大幅提前 | TownBuilding API 已稳定 |
| S8-04 TutorialHint | 0.5d | ~0.3h | 提前 | 独立 stub，依赖少 |

**整体估算准确度**: 4/4 大幅提前。趋势延续 Sprint 6 的观察：当基础 stub 和 ADR 已建立时，追加功能的实现速度远超估计。考虑对"深化型" story 应用 0.5d 默认估计（而非 1.0d）。

### Carryover Analysis

| Task | Original Sprint | Reason | Action |
|------|---------------|--------|--------|
| S8-05 visual AC 验证 | Sprint 8 | Should Have，Must Have 交付后未跟进 | 纳入下个 sprint 或标记为日常 QA 活动 |
| S8-06 QA plan Sprint 8 | Sprint 8 | Should Have，未生成 | 如 Sprint 8 已关闭则不再需要（Sprint 9 QA plan 取代） |

### Technical Debt Status
- Current TODO: 2 (town_grid.gd progress bar + audio_manager.gd EventBus wire) — 上一 sprint: 1
- Current FIXME: 0
- Current HACK: 0
- Trend: 小幅增长 (+1 TODO) — audio_manager.gd 的 EventBus TODO 是预期的后续 story 占位，非债务堆积

### Previous Action Items Follow-Up

| Action Item (from Sprint 6) | Status | Notes |
|-----------------------------|--------|-------|
| 减少模板驱动 story 的估算倍数 | ⚠️ 部分 | Sprint 8 估计仍偏保守，但已有 0.5d 估计出现 |
| 创建 training_request_bridge 完整重写 story | ❌ 未做 | 仍在待办，优先级低 |
| 轻量 story 格式 (Config/Data) | ❌ 未做 | 本次无 Config/Data story |

### Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | 修正 Sprint 计划日期模板，增加日期校验步骤 | Producer | Med | Sprint 9 |
| 2 | 对"深化型" story 应用 0.5d 默认估计（非 1.0d） | Producer | Med | Sprint 9 |
| 3 | 关闭 S8-05/S8-06 或标记为 WON'T DO | Producer | Low | Sprint 9 |
| 4 | 处理 training_request_bridge 重写或标记为永久推迟 | Lead Programmer | Low | Sprint 9 |

### Process Improvements

- **增量故事模式**: Sprint 7 stub → Sprint 8 追加功能的模式验证有效。单个系统分两个 sprint 推进（先建 authority stub，再加功能深度）可以作为一个可复用的推进策略。
- **Should Have 跟进机制**: Should Haves 在 Must Haves 快速交付后容易丢失。建议在 /sprint-status 中增加 Should Have 提醒，或在 sprint 中段强制检查。

### Summary

Sprint 8 是高效的技术深化 sprint：4 个 Must Have 在单个 session 内全部交付，85 测试 0 回归，关闭了延期系统治理中的 4/6 系统。估算持续偏保守，连续 5 个 sprint 100% 完成率。主要不足是 Should Haves 被忽视，以及 Sprint 7/8 的边界不够清晰。建议 Sprint 9 转向新的系统领域（Skill/Trait、Reputation/Achievement 等 Alpha 系统），同时将深化型 story 的估计标准下调至 0.5d。
