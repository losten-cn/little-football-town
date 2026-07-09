# Sprint 4 — Governance and Technical Foundation — 2026-07-10 to 2026-07-17

## Sprint Goal

承接 Sprint 3 的 Production visual follow-through 交付成果，完成显式系统 deferral governance 并收敛关键流程改进项（authority-contract 前置决策清单、walkthrough 职责分离、process improvement adoption）。

## Capacity

- Total days: 6 working days
- Buffer (20%): 1.2 days reserved for unplanned work
- Available: 4.8 days

## Scope Guard

- 本 sprint 以 governance / process improvement / preparation 为主，不新增 gameplay、route、save/event schema 或 core authority。
- 新 story 只允许进入 presentation / polish / QA 面。
- 保留 Sprint 3 已完成的 Home / Player / Training / Match visual exemplar baseline 不动。

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S4-01 | 记录非 Sprint 3 系统的 explicit deferral notes (S3-09 carryover) | Producer | 0.5 | None | Random Event、Audio、Skill/Trait、Reputation/Achievement、Town UI、Tutorial/Hint 保持 defer 状态，并各自指向未来 story chain 需求。 |
| S4-02 | 建立 authority-contract 类 story 的 "最小决策清单" 前置模板 | Lead Programmer / Producer | 0.5 | Sprint 3 retro action items | 模板包含：authority purity 优先级、refresh 语义、explanatory field 归属规则；可用于下一条 authority contract story 的 /story-readiness 前自检。 |
| S4-03 | 规范 walkthrough 与 integration test 的验证职责边界 | QA Lead | 0.5 | Sprint 3 retro action items | walkthrough 只做 route/visibility/smoke；authority semantics 归 integration test。文档或 story 模板更新完成。 |
| S4-04 | 清理 sprint-status.yaml 中 Sprint 3 遗留项 | Producer | 0.5 | None | S3-09 状态反映实际 deferral；Sprint 狀態一致。 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S4-05 | Training summary `回报/时机` slot mapping 修正 | UI Programmer | 0.5 | Story 003 complete | `回报` 改为显示 `payoff`；`时机` 改为显示 `impact`。UI copy 精修。 |
| S4-06 | 扫描当前 TODO / ponytail / 技术债注释并记录 | Lead Programmer | 0.5 | None | `src/` 中所有 ponytail/FIXME/TODO 项有对应 debt 追踪或关闭决策。 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S4-07 | 为下一个 Presentation wave 做 readiness pre-check | Producer | 0.5 | S4-01 | 输出至少 2 条可进入 /story-readiness 的候选 story。 |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| S3-09 — Deferral notes | Story 003 authority contract 收敛超出预期工作量，S3-09 推迟 | 0.5d — 变为 S4-01 |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Governance sprint 被认为 "无产出" | Medium | Low | 所有 Must Have 输出具体 deliverable（模板文件、文档、yaml 清理），不是纯讨论。 |
| Story 003 剩余 UI copy fix 被遗忘 | Low | Low | S4-05 作为 Should Have 显式追踪。 |
| Sprint 惯性期望 "继续写新功能" | Medium | Medium | Sprint goal 明确写清本 sprint 定位：governance + process improvement + preparation。 |

## Dependencies on External Factors

- 无。本 sprint 全部为内部文档/process/模板工作，不依赖外部系统或环境。
- Godot / walkthrough runner 无需在本 sprint 运行（若 S4-05 需要验证，可能需要 walkthrough 支持）。

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed
- [ ] S3-09 carryover resolved (S4-01)
- [ ] Process improvement deliverables exist as reusable artifacts
- [ ] sprint-status.yaml is consistent with actual story status
- [ ] Next wave candidate stories identified (S4-07 or equivalent)
- [ ] Smoke check passed (`/smoke-check sprint`) — relevant if any code changes are made
- [ ] Design documents updated for any deviations
