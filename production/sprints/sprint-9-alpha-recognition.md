# Sprint 9 — Alpha 声望 & 收尾 — 2026-07-11 to 2026-07-18

## Sprint Goal

将 Reputation/Achievement 从 stub 推进到声望计算 + 等级推进，同时清理 Sprint 5–7 遗留的过期 Ready story 状态。

## Capacity

- Total days: 6 working days
- Buffer (20%): 1.2 days reserved for unplanned work
- Available: 4.8 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S9-01 | 声望/成就 — Story 002: 声望计算 + 等级推进 | Gameplay Programmer | 1.0 | ADR-0011, story-001 (recognition summary stub) | `reputation_gain = floor((base + bonus) × source_weight × stage_multiplier)` 公式实现；`reputation_level` / `reputation_progress_ratio` 权威产出；UI 只读消费 `reputation_view_payload`；ser/des 持久化 round-trip |
| S9-02 | 关闭 3 个过期 Ready story (audio-001, rep-001, town-ui-001) | Producer | 0.3 | — | 3 个 story 通过 /story-done 标记 Complete；sprint-status.yaml 更新 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S9-03 | 技能/特性 — Story 002: trait evaluation 最小 stub | Gameplay Programmer | 0.5 | ADR-0010, story-001 (growth summary stub) | `pending_skill_trait_feedback` 消费路径建立；trait candidate evaluation stub；只读 payload 不暴露内部状态 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S9-04 | S8-05 visual-direction-alignment 延期 AC 手动验证 | QA | 0.3 | Story 001-003 Complete | AC-7 (时间冷暖视觉提示) + AC-5 (比赛暗色 5s 渐变) 肉眼确认；截图写入 evidence；关闭对应 tech debt |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| S8-05 visual AC 验证 | Sprint 8 Should Have 未执行 | 0.3d (→ S9-04 Nice to Have) |
| S8-06 QA plan Sprint 8 | Sprint 8 已关闭，不再需要 | — (WON'T DO) |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Reputation-002 无现成 story 文件 | High | Medium | S9-01 前置步骤：先跑 `/create-stories reputation-and-achievement-system` |
| Skill/Trait-002 无现成 story 文件 | High | Low | S9-03 前置步骤：跑 `/create-stories skill-and-trait-system` |
| 过期 Ready story 的 /story-done 可能有文件冲突 | Low | Low | 逐个关闭，先检查 git status |

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed and tested
- [ ] S9-01 实现 + 测试 PASS
- [ ] S9-02 3 个过期 story 全部 Complete
- [ ] QA plan exists for sprint stories (`production/qa/qa-plan-sprint-9.md`)
- [ ] All Logic/Integration stories have passing tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] No S1 or S2 bugs
- [ ] Code reviewed and merged
