## Retrospective: Sprint 9 — Alpha Recognition & Housekeeping
Period: 2026-07-11 -- 2026-07-18
Generated: 2026-07-10 (同日交付，提前关闭)

### Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Stories (Must Have) | 2 | 2 | 0 |
| Stories (Should Have) | 1 | 0 | −1 |
| Stories (Nice to Have) | 1 | 0 | −1 |
| Completion Rate (Must Have) | -- | 100% | -- |
| Est. Effort Days | 1.3 | ~1 session | −1.3 (提前) |
| Bugs Found (new) | -- | 1 | -- |
| Regression Bugs | -- | 1 (config_loader) | -- |
| Commits | -- | 9 | -- |
| Automated Tests | -- | 86 | +1 (reputation) |

### Velocity Trend

| Sprint | Must Haves | Completed | Rate |
|--------|-----------|-----------|------|
| Sprint 5 | 4 | 4 | 100% |
| Sprint 6 | 3 | 3 | 100% |
| Sprint 7 | 4 | 4 | 100% |
| Sprint 8 | 4 | 4 | 100% |
| Sprint 9 | 2 | 2 | 100% |

**Trend**: 稳定 — 连续 6 个 sprint 100% 完成率。Sprint 9 规模最小（2 Must Haves），但包含了从零搭建新系统 (Reputation) 和跨 3 个 sprint 的清理工作。

### What Went Well

- **Reputation 系统零到一**: S9-01 从 `/create-stories` → `/dev-story` → `/story-done` 全流程打通。ReputationAchievementManager、ReputationConfig、3 个 GDD 公式、86 个测试全部在一次 session 内交付。
- **S9-02 清债成效显著**: 3 个过期 Ready story (S5-03 audio, S6-03 rep, S7-03 town-ui) 正式关闭。这些 story 的代码和测试早已在之前 sprint 中实现并提交，只是 story 文件状态从未更新。S9-02 纠正了 production 记录的偏差。
- **回归修复在同 session 内完成**: ConfigLoader 缺失 `_load_reputation_config` 导致 balance_config_loader 测试崩溃，在 smoke check 中立即发现并修复。Agent 生成代码的验证环节暴露了缺口，但修复在 5 分钟内完成。
- **Sprint 计划质量改善**: Sprint 9 日期未出现 Sprint 8 的笔误问题（S8 标注 8 月实为 7 月）。Sprint 计划更加务实：提前识别 S9-01/S9-03 的 /create-stories 阻塞。

### What Went Poorly

- **Agent 实现引入回归**: gameplay-programmer 在 config_loader.gd 中添加了 `_load_reputation_config()` 调用，但遗漏了对应的 helper 方法和 validator。这是 agent 自主实现时常见的问题——调用点写入成功，但辅助代码不完整。需要通过 smoke check 捕获。
- **Should Haves 连续第 2 个 sprint 未完成**: S9-03 (Skill/Trait) 被 /create-stories 阻塞，S9-04 (visual AC) 再次搁置。Should Have 优先级在执行中持续被忽略。
- **S9-03 阻塞未提前解决**: Sprint 9 计划识别了 S9-03 的 /create-stories 阻塞，但在 sprint 执行中未能提前解除。Should Have 的阻塞应该在 sprint 开始时优先处理，否则必然被推迟。

### Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| S9-03 需 /create-stories skill-and-trait-system | 全 sprint | 未解除 | 在 sprint 计划中将此类阻塞列为 Must Have 的前置任务 |
| ConfigLoader 回归 (missing helper) | ~5 min | 手动追加 3 个 missing methods | 对 agent 生成的文件在提交前强制运行相关测试 |

### Estimation Accuracy

| Story | Estimated | Actual | Variance | Note |
|-------|-----------|--------|----------|------|
| S9-01 Reputation 声望计算 | 1.0d | ~0.5h (+ agent time) | 提前 | Agent 生成主力代码，人工审核修复 |
| S9-02 关闭过期 story | 0.3d | ~0.2h | 提前 | 纯文件状态更新，无代码变更 |

**Overall**: 继续大幅提前。Sprint 8 回顾建议"深化型 story 降至 0.5d"，Sprint 9 验证了这一建议——S9-01 实际工作量远低于 1.0d。

### Carryover Analysis

| Task | Original Sprint | Reason | Action |
|------|---------------|--------|--------|
| S9-03 Skill/Trait story-002 | Sprint 9 | /create-stories 未执行 | 纳入 Sprint 10 Should Have |
| S9-04 visual AC 验证 | Sprint 8→9 | 连续 2 个 sprint 未执行 | 降级为日常 QA 活动，不再追踪为 sprint story |
| training_request_bridge 重写 | Sprint 6→7→8→9 | 连续 4 个 sprint 未处理 | 需明确决策：修复或永久推迟 |

### Technical Debt Status
- Current TODO: 2 (town_grid.gd progress bar + audio_manager.gd EventBus wire) — 上一 sprint: 2
- Current FIXME: 0
- Current HACK: 0
- Pre-existing failures: training_request_bridge_test.gd (Sprint 6 advisory, 连续第 4 个 sprint)
- Trend: 稳定 — 无新增债务

### Previous Action Items Follow-Up

| Action Item (from Sprint 8) | Status | Notes |
|-----------------------------|--------|-------|
| 修正 Sprint 计划日期模板 | ✅ Done | Sprint 9 日期正确 (07-11~07-18) |
| 深化型 story 降至 0.5d | ⚠️ Partial | S9-01 仍估 1.0d 但实际远低于此 |
| 关闭 S8-05/S8-06 | ⚠️ Partial | S8-06→WON'T DO; S8-05→S9-04 (仍未完成) |
| training_request_bridge 重写/推迟 | ❌ Not done | 第 4 个 sprint 未处理 |

### Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | Agent 生成代码后强制运行相关系统测试（非仅新测试），捕获 config/autoload 回归 | Lead Programmer | High | Sprint 10 |
| 2 | 对 training_request_bridge 做明确决策：修复 OR 标记为永久跳过并在 CI 中排除 | Lead Programmer | Med | Sprint 10 |
| 3 | 在 sprint 开始时优先解除 Should Have 阻塞（如 /create-stories），否则 Should Have 100% 被推迟 | Producer | Med | Sprint 10 |
| 4 | 将 S9-04 visual AC 从 sprint tracking 中移除，降级为日常 QA checklist 项 | Producer | Low | Sprint 10 |

### Process Improvements

- **Agent 代码门禁**: Agent 生成的文件在提交前必须运行该系统已有的所有测试（不仅仅是新测试）。S9-01 新增了 `balance_config_loader` 调用但未运行 balance 测试，导致回归。建议：每完成一个 agent，立即运行 `grep -rl "affected_file" tests/` 找到相关测试并执行。
- **Should Have 机制需要重新设计**: 连续 2 个 sprint，Should Haves 100% 被忽略。当前流程中 Must Haves 快速交付后直接进入 /smoke-check → /retrospective，Should Haves 没有执行窗口。建议：在 /sprint-status 中添加 Should Have 提醒，或在 Must Haves 完成后强制 AskUserQuestion 询问是否处理 Should Haves。

### Summary

Sprint 9 高效完成了两个低代码量的 Must Have：从零搭建 Reputation 声望计算系统，以及清理 3 个 sprint 的过期 story 状态。连续 6 个 sprint 100% 完成率。主要教训是 agent 生成代码需要通过已有系统测试进行验证（config_loader 回归），以及 Should Have 追踪机制持续失效。Sprint 10 应继续推进剩余延期系统（Skill/Trait 为当前最高的未覆盖系统），同时解决累积 4 个 sprint 的 training_request_bridge 遗留问题。
