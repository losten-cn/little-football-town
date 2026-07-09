# Sprint 3 — Production Visual Follow-through — 2026-07-05 to 2026-07-12

## Sprint Goal

将 Production gate 的视觉与展示层 follow-through 从“READY WITH WARNINGS”推进到可执行 story/readiness/QA 证据链：完成 Home visual exemplar story readiness、实施最小 Home/shell visual boundary pass、产出截图/ walkthrough 证据，并为后续 Player/Match visual exemplar stories 建立不扩 scope 的模板。

## Capacity

- Total days: 6 working days
- Buffer (20%): 1.2 days reserved for unplanned work
- Available: 4.8 days

## Scope Guard

- 本 sprint 只处理 Presentation follow-through，不新增 gameplay、route、save/event schema 或 core authority。
- Home visual exemplar 是唯一 Must Have implementation slice。
- Player/Match/Town/Tutorial/Audio/Random Event 等系统只允许作为后续 story/readiness/defer 链出现，不进入本 sprint implementation scope。
- 当前 Production gate 可继续在 CONCERNS / READY WITH WARNINGS posture 下推进；本 sprint 的目标是减少视觉/展示 follow-through 风险，不承诺 clean READY。

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S3-01 | 验证 Home visual exemplar story readiness | Producer / UX Designer | 0.5 | `production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md` | `/story-readiness` 通过或输出明确 blocker list；未通过则不启动 implementation。 |
| S3-02 | 为 Home visual exemplar 建立 QA evidence expectations | QA Lead | 0.5 | S3-01 | Sprint QA plan 或 story evidence checklist 覆盖 Home initial、after training、match disabled reason、final Home、focus/hover/disabled 状态与 route guardrails。 |
| S3-03 | 实施 Home/shell 最小 visual exemplar boundary pass | UI Programmer | 1.5 | S3-01, S3-02 | Home 保持既有 route IDs 与 shell；暖色小镇视觉方向更清晰；placeholder 不暴露 debug/internal labels、不造成路线歧义；不改 gameplay authority。 |
| S3-04 | 跑 Home route guardrails 与 MVP visual walkthrough | QA Lead / UI Programmer | 1.0 | S3-03 | `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`、`L2_PLAYABLE_LOOP_PANELS_TEST_PASS`、`MVP_VISUAL_WALKTHROUGH_PASS` 或等效更新证据通过；失败项记录为 blocker 或 allowed warning。 |
| S3-05 | 写入 Home visual exemplar evidence pack | QA Lead | 0.5 | S3-04 | `production/qa/evidence/home-visual-exemplar-placeholder-boundary-2026-07-05.md` 或日期等效文件存在，包含截图/route/warning verdict 与 acceptance criteria 映射。 |
| S3-06 | 更新 Sprint 状态与 story completion verdict | Producer | 0.5 | S3-05 | Story 002 根据证据进入 review/done 流程；sprint status 与 story file 状态同步；未完成项明确 carry forward。 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S3-07 | 起草 Player/Training visual exemplar follow-up story | UX Designer / Producer | 0.5 | S3-05 | 新 story 草案只覆盖 Player/Training visual boundary，不改变 roster/training authority 或 training depth。 |
| S3-08 | 起草 Match visual exemplar follow-up story | UX Designer / Producer | 0.5 | S3-05 | 新 story 草案只覆盖 Match Pre/Live/Result visual boundary，不增加 halftime/live command depth。 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S3-09 | 记录非本 sprint 系统的 explicit deferral notes | Producer | 0.5 | None | Random Event、Audio、Skill/Trait、Reputation/Achievement、Town UI、Tutorial/Hint 保持 defer 状态，并各自指向未来 story chain 需求。 |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| Production gate visual readiness follow-through | Sprint 2 recovery 已完成，但 2026-07-05 gate follow-up 仍显示 clean READY 需要视觉 exemplar / screenshot follow-through | 3.5d Must Have implementation + evidence |
| Concrete near-term story/readiness chain | `production/session-state/active.md` 已选择 Presentation boundary / visual exemplar stabilization slice；Story 002 已 authored 但尚未 story-readiness / dev-story | 0.5d readiness + follow-up tracking |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Visual polish 扩张为 full art pass | Medium | High | 只做 Home/shell exemplar boundary；final production art replacement 留到 future art pass。 |
| Home UI 改动误触 route topology 或 authority boundary | Medium | High | S3-03 明确禁止 ScreenManager、route IDs、save/event schema、gameplay authority 变更；S3-04 跑 route guardrails。 |
| Placeholder cleanup 变成新功能入口 | Medium | Medium | Placeholder 只允许改善可读性和歧义，不新增 interaction depth。 |
| 无 QA plan 导致实现标准不清 | High before QA plan | High | 本 sprint 写入后立即运行 `/qa-plan sprint`，先定义 QA cases 再实现。 |
| Clean READY 被误报 | Low | High | Sprint 目标只声明 warning reduction；不声明 clean READY、remote CI green 或 final art readiness。 |

## Dependencies on External Factors

- Godot headless / visual walkthrough runner availability in the local environment.
- Screenshot capture path must remain reviewable; known dummy-renderer screenshot warnings may be carried only if route/walkthrough markers pass.
- No external-human validation is required under current project policy; AI-agent surrogate / local evidence remains accepted for this gate.

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-3.md` or sprint-specific equivalent)
- [ ] UI / interaction evidence exists for Home visual exemplar story
- [ ] Existing route guardrails pass after Home visual pass
- [ ] Smoke check passed (`/smoke-check sprint`) or documented equivalent route/walkthrough evidence exists
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`) or sprint evidence explicitly states remaining warnings
- [ ] No S1 or S2 bugs in delivered Home/shell surfaces
- [ ] Design documents updated for any deviations, or no deviations recorded
- [ ] Code reviewed and merged only after `/dev-story` and story completion flow authorize it

## QA Plan

> ⚠️ **QA Plan Pending**: No Sprint 3 QA plan existed when this sprint was created. Run `/qa-plan sprint` before implementation begins. The user selected “先建 QA Plan”, so implementation should wait until QA cases are defined.

## Review Mode

- Review mode: `lean`
- PR-SPRINT skipped — Lean mode.

## Scope Check

If this sprint includes stories added beyond the original Main Loop UI Framework scope, run `/scope-check production/epics/main-loop-ui-framework/EPIC.md` before implementation begins.

## Next Steps

1. Run `/qa-plan sprint` before starting implementation.
2. Run `/story-readiness production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md`.
3. If readiness passes, run `/dev-story production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md`.
4. After implementation, run visual walkthrough / route guardrails and write evidence.
