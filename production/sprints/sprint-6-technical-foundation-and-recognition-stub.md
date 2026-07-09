# Sprint 6 — Technical Foundation & Recognition Stub — 2026-07-19 to 2026-07-26

## Sprint Goal

关闭 Sprint 5 遗留技术债（training_request_bridge 测试修复、Presentation-stub 模式文档化、visual evidence 补齐），同时启动 Feature-layer Presentation stub：声望与成就系统的最小 recognition summary。

## Capacity

- Total days: 6 working days
- Buffer (20%): 1.2 days reserved
- Available: 4.8 days

## Scope Guard

- 本 sprint 聚焦技术基础 + 1 个新 Presentation stub
- 新 UI 只消费已有 authoritative payload（ADR-0011 Reputation/Achievement）
- 不新增 gameplay logic、route topology 变更、save/event schema 变更
- 保留 Sprint 3–5 的 Home / Player / Training / Match / Growth Summary / Town Grid / Audio Settings / Halftime baseline

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S6-01 | 文档化 Presentation-stub 模式 | UI Programmer | 0.5 | Sprint 5 stories | 产出 `docs/architecture/presentation-stub-pattern.md`，包含 PanelContainer + EventBus + authority payload + neutral fallback 模板，含代码示例和 checklist。 |
| S6-02 | 修复 `training_request_bridge_test.gd` 3 个 pre-existing 失败 | Lead Programmer | 0.5 | Story 003 training refactor | 所有 3 个失败断言修复；`TRAINING_REQUEST_BRIDGE_TEST_PASS`。 |
| S6-03 | Reputation/Achievement — 最小 recognition summary stub | UI Programmer | 1.0 | ADR-0011, Home visual exemplar | Home 新增 recognition summary 卡片；消费 `reputation_state_changed` / `achievement_unlocked` EventBus 事件；缺失 payload → neutral placeholder；不实现声望计算或成就解锁逻辑。 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S6-04 | 补齐 S5 visual evidence 文件 | UI Programmer | 0.5 | S5 stories | `production/qa/evidence/` 下创建 S5-01/02/03/04 的 evidence markdown；接受 headless limitation 或手动截图。 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S6-05 | Onboarding/Tutorial — 首次 hint stub | UI Programmer | 0.5 | WhatNextGuidance stub | Home 首次加载时展示欢迎提示；不实现教程步骤或进度追踪。 |

## Carryover from Previous Sprint

None — Sprint 5 全部交付。

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| training_request_bridge 根因深追超出 0.5d | Medium | Medium | 时间盒 0.5d；超出则记录 findings 并 accept advisory |
| Reputation payload producer 未产出 | High | Low | Stub 模式 — 缺失 payload 时 neutral placeholder；不阻塞 |

## Retro Action Items Incorporated

| Retro Action | Sprint 6 Mapping |
|-------------|-----------------|
| 文档化 Presentation-stub 模式 | S6-01 |
| 创建 manual visual evidence 文件 | S6-04 |
| 修复 training_request_bridge_test | S6-02 |
| 文档化 autoload headless 测试模式 | 纳入 S6-01 文档范围 |

## Dependencies on External Factors

- Reputation/Achievement payload: ADR-0011 已定义 `reputation_state_changed` / `achievement_unlocked`，但 runtime producer 可能未产出 — UI stub 在缺失时回退 neutral placeholder
- Training request bridge 修复可能需要深入 Story 003 training refactor logic

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-6.md`)
- [ ] All Logic/Integration stories have passing tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] Existing route guardrails still pass
- [ ] Code reviewed and merged
