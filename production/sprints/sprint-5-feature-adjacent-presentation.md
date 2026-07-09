# Sprint 5 — Feature-Adjacent Presentation — 2026-07-11 to 2026-07-18

## Sprint Goal

承接 Sprint 4 的 governance 收敛和 next-wave candidate pre-check，启动两个最高优先级的 feature-adjacent Presentation stubs：Skill/Trait Growth Summary（Alpha 最小可见面）和 Town Management UI（最小 grid stub），各作为权威 payload 消费的 presentation-only 入口，不新增 gameplay logic。

## Capacity

- Total days: 6 working days
- Buffer (20%): 1.2 days reserved for unplanned work
- Available: 4.8 days

## Scope Guard

- 本 sprint 只新增 Presentation stubs，不新增 gameplay、route topology 变更、save/event schema 变更或 core authority。
- 所有新 UI 必须只消费已有 authoritative payload（Skill/Trait 消费 ADR-0010 定义的 `pending_skill_trait_feedback` / `feedback_ack`；Town 消费 ADR-0008 定义的 `TownBuilding` read models）。
- 保留 Sprint 3 已完成的 Home / Player / Training / Match visual exemplar baseline 不动。

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S5-01 | Skill/Trait Growth Summary — 最小 Alpha UI stub | UI Programmer | 1.5 | Story 003 (authority contract), ADR-0010 | 新建或扩展 Player Detail / Home summary 以消费 `pending_skill_trait_feedback` 和 `feedback_ack`；只展示 growth summary 占位，不实现 unlock/trigger 逻辑。 |
| S5-02 | Town Management UI — 最小 facility grid stub | UI Programmer | 1.5 | Home visual exemplar (story-002), ADR-0008 | 新建或扩展 Home 小镇摘要区以展示 5×5 grid 布局；消费 `TownBuilding` read model；grid cell 使用占位图标，不实现 construction flow。 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S5-03 | Audio Settings UI — 最小容器 stub | UI Programmer | 0.5 | ADR-0013, Home visual exemplar | 从 Home 可访问的 settings 容器；master/bgm/sfx 音量 slider；消费 `AudioManager` 权威值，写入通过 `AudioManager`。 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S5-04 | Match Live halftime — minimum command stub | UI Programmer | 0.5 | Match visual exemplar (story-002), ADR-0006 | 在 halftime 增加一个合法决策入口（如 "调整为防守战术"）；wire 通过 `MatchStartCoordinator` 或等效 authority 路径。 |

## Carryover from Previous Sprint

None — Sprint 4 全部交付。

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Skill/Trait UI stub 被扩为功能实现 | Medium | High | Scope guard 明确只做 presentation-only stub；不实现 unlock/trigger 逻辑。 |
| Town grid stub 触发 “完整 town building” 期望 | Medium | High | Grid cells 使用占位图标，construction flow 显式 out of scope。 |
| Authority payload readiness 不够 | Medium | Medium | 只消费已有 ADR contract 定义的 payload；若 producer 未提供，UI fallback 为 neutral placeholder。 |
| Sprint 4 governance artifacts 未被实际使用 | Low | Medium | S4-02 决策清单模板建议在 S5-01/S5-02 的 `/story-readiness` 阶段先填。 |

## Dependencies on External Factors

- Skill/Trait payload availability: `pending_skill_trait_feedback` 和 `feedback_ack` 已在 ADR-0010 定义，但 runtime producer 可能尚未完整产出这些字段。UI stub 应在缺失时回退到 neutral placeholder。
- TownBuilding read model: `TownBuilding` 已在 ADR-0008 定义，grid 状态 query interface 需在实现前确认。

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-5.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] Existing route guardrails still pass after new UI stubs
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
