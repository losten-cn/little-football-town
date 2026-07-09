## Retrospective: Sprint 3 — Production Visual Follow-through
Period: 2026-07-05 -- 2026-07-09
Generated: 2026-07-09

### Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Tasks | 9 | 8 | -1 |
| Completion Rate | -- | 89% | -- |
| Effort Days (Must Have) | 4.5 | ~6 | +1.5 |
| Stories Delivered | 4 | 4 | 0 |
| Integration Tests Added | 0 | 1 | +1 |
| Commits | -- | 2 | -- |

### Velocity Trend

| Sprint | Stories | Completed | Rate |
|--------|---------|-----------|------|
| Sprint 1 | 8 | 8 | 100% |
| Sprint 2 | 3 | 3 | 100% |
| Sprint 3 (current) | 4 | 4 | 100% |

**Trend**: Stable — 100% story completion across all three sprints. Sprint 3 delivered fewer stories but each involved deeper architecture convergence work.

### What Went Well
- **Visual exemplar contract pattern established**: Home → Player/Training → Match 三连 visual boundary pass 形成可复用的 story 模板（Scope/Out of Scope/ADR/AC/evidence 结构一致），后续类似 polish 任务可快速复制。
- **Authority contract 收敛彻底**: PlayerMgmt explanatory payload authority contract (Story 003) 虽然是最折腾的一条，但最终把 "UI 本地推导" 和 "authoritative payload 消费" 的边界真正画清楚了，为后续 stories 提供了更强的架构基线。
- **TDD 节奏坚持到了最后**: Story 003 经历多轮 RED→GREEN→REFACTOR，最终通过专用 integration test 闭环，没有因为疲劳跳过 TDD。
- **Sprint scope 边界控制好**: 没有 scope creep——每个 visual exemplar pass 都守住了不改 route/schema/authority 的底线。
- **Commit 干净**: Sprint 3 所有交付一次性汇入单条 commit，变更范围清晰可追溯。

### What Went Poorly
- **PlayerMgmt authority contract 的正式 code-review 阻塞反复出现**: Story 003 至少经历了 3 轮 `/code-review` 才收敛到可接受状态。根因是 story scope 和 reviewer 预期之间的 gap——reviewer 要求的是 "authority purity"，但 story scope 定义的是 "visual exemplar boundary"。
- **walkthrough runner 维护成本偏高**: Story 003 改了 authority contract 之后，walkthrough runner 因为内嵌旧的行为假设，被迫大规模同步。这说明 walkthrough runner 和 authority contract 之间的耦合太紧。
- **S3-09（Deferral notes）未完成**: 非阻塞，但让 Random Event / Audio / Skill/Trait / Tutorial 等系统的显式 deferral governance 仍然缺位。
- **部分架构讨论消耗了过多实现时间**: Story 003 的 explanatory contract 设计决策如果能在实现前先定好（producer 是否自己生成 explanations？refresh 语义用 latest producer wins？），可以省掉多轮修订。

### Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| Story 003 authority contract 设计与 reviewer 预期不一致 | ~1 天反复迭代 | 最终按 authority purity first + latest producer wins 决策组合收口 | 实现前先写最小决策清单，让 reviewer 先确认语义再动手 |
| walkthrough runner 与 Story 003 contract 冲突 | ~2 小时 | walkthrough 降级为 smoke/visibility verifier | 区分 "authority 主证明"（integration test）和 "可见行为 smoke"（walkthrough）两层证据 |

### Estimation Accuracy

| Task | Estimated | Actual | Variance | Likely Cause |
|------|-----------|--------|----------|--------------|
| Home visual exemplar (S) | 1.5d | ~1d | -0.5d | story scope 定义清晰，实现路径直接 |
| Player/Training visual exemplar (S) | 1.5d | ~1d | -0.5d | 复制 Home pattern，执行顺畅 |
| PlayerMgmt authority contract (S) | 0.5d 估计 | ~3d 实际 | +2.5d | story scope 低估了架构收敛的复杂度 |
| Match visual exemplar (S) | 0.5d 估计 | ~0.5d | 0 | 前三个 story 已经形成了模板和经验 |

**Overall estimation accuracy**: ~50% (2/4 within ±20%)

Analysis: visual-boundary-only stories (Home, Match) 估计准确；authority-contract-convergence story (Story 003) 严重低估。以后再遇到 "convergence" / "contract" / "authority" 类 story 时，estimate 应该至少调高 1-2 个 tier。

### Carryover Analysis

| Task | Original Sprint | Reason | Action |
|------|----------------|--------|--------|
| S3-09 (Deferral notes) | Sprint 3 | 被 Story 003 消耗了过多的 focus | 纳入 Sprint 4 Must Have 或直接由 producer 单开 |

### Technical Debt Status
- Current TODO count: 0 (previous: unknown)
- Current FIXME count: 0
- Current HACK count: 0
- ponytail: comments: ~6 (all intentional simplification markers with upgrade paths)
- Trend: N/A — first measurement

### Previous Action Items Follow-Up

| Action Item (from previous sprints) | Status | Notes |
|-------------------------------|--------|-------|
| 无明确 carry-forward action items | — | 前两 sprint 的 retrospective 未记录或未找到 |

### Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | 补 S3-09 Deferral notes：为 Random Event / Audio / Skill/Trait / Tutorial 等非本 sprint 系统写显式 deferral | Producer | High | Sprint 4 Week 1 |
| 2 | 为 authority-contract 类 story 先写 "最小决策清单" 再动手实现 | UI Programmer | High | Ongoing |
| 3 | 区分 walkthrough 的两类职责：authority proof（归 integration test）和 smoke/visibility（归 walkthrough），写入 story 模板 | Producer / QA Lead | Medium | Sprint 4 |
| 4 | Story 003 遗留：training summary `回报/时机` slot mapping 优化 | UI Programmer | Low | 后续 UI copy 精修 |
| 5 | 清理 sprint-status.yaml 中 S3-09 的 backlog 状态 | Producer | Low | Sprint 4 |

### Process Improvements
- **对付 authority-contract 类 story 时，先定决策、再写代码**: Story 003 的教训——如果在开始前就把 "authority purity first / latest producer wins / disable_reason≠risk_summary" 这几个关键决策定好，实现会快很多。
- **walkthrough 不再做 authority contract 的主证明器**: walkthrough 应该专注于 "route 通不通、界面空不空、key controls 在不在"——authority semantics 交给 dedicated integration test。

### Summary
Sprint 3 交付了 4 条 stories，完成了 Home → Player/Training → Match 三个 Presentation 面的 visual exemplar boundary pass，以及一条关键的 authority contract convergence story。整体 story completion 100%，自动化测试绿。最大的教训是：authority contract 类 story 需要在动手前先定语义决策，否则会被反复的 code-review 往返消耗。下个 sprint 应补掉 S3-09 deferral notes，并为 authority-heavy stories 引入 "先决策、后实现" 的前置步骤。
