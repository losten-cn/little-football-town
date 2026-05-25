# Sprint 1 — 2026-05-19 to 2026-06-02

## Sprint Goal
完成 HUD Framework 的收尾、验证与后续 MVP UI 屏幕落地准备，使主循环 UI 框架能进入可实现的 story 管理状态。

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S1-1 | 完成 HUD Framework 实现收尾 | ui-programmer / godot-specialist | 1.5 | `production/epics/time-and-season-progression-system/story-009-time-status-regression.md`, `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md` | HUD scene/scripts/components/overlays are complete enough for review; no obvious script parse errors; HUD follows layer/layout decisions from session state. |
| S1-2 | HUD 手动 walkthrough + 截图证据 | qa-tester / ui-programmer | 1 | `production/epics/time-and-season-progression-system/story-009-time-status-regression.md`, `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md` | Evidence captures Home HUD zones, overlay behavior, focus/navigation, resource/date/action displays, and any known visual issues. |
| S1-3 | 修复 HUD Review/QA 发现的问题 | ui-programmer / godot-gdscript-specialist | 1 | `production/epics/time-and-season-progression-system/story-009-time-status-regression.md`, `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md` | Blocking HUD walkthrough findings resolved or explicitly deferred with rationale; no S1/S2 issues remain in HUD Framework. |
| S1-4 | 创建 QA plan for Sprint 1 | qa-lead | 1 | `production/epics/time-and-season-progression-system/story-009-time-status-regression.md`, `production/epics/player-development-system/story-009-player-development-regression.md`, `production/epics/match-competition-system/story-009-match-loop-regression.md` | `production/qa/qa-plan-sprint-1.md` exists and defines required checks for HUD, Player Management UI readiness, and Match Performance UI readiness. |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S1-5 | 准备 Player Management UI story/readiness | producer / ui-programmer | 1 | `production/epics/time-and-season-progression-system/story-009-time-status-regression.md`, `production/epics/player-development-system/story-008-player-state-boundary.md`, `production/epics/player-development-system/story-009-player-development-regression.md` | Story/readiness notes identify scope, dependencies, acceptance criteria, UI anchors, and required QA checks for Player Management UI implementation. |
| S1-6 | 准备 Match Performance UI story/readiness | producer / ui-programmer | 1 | `production/epics/time-and-season-progression-system/story-009-time-status-regression.md`, `production/epics/match-competition-system/story-006-match-result-packet.md`, `production/epics/match-competition-system/story-009-match-loop-regression.md` | Story/readiness notes identify scope, dependencies, acceptance criteria, UI anchors, and required QA checks for Match Performance UI implementation. |

## Story Mapping Notes

- Dedicated Presentation UI story files for HUD Framework, Player Management UI, and Match Performance UI are not present under `production/epics/`.
- HUD Framework references are mapped to `production/epics/time-and-season-progression-system/story-009-time-status-regression.md` and `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md` because those stories provide the UI-facing time/status and resource query surfaces used by the HUD.
- Player Management UI readiness is mapped to `production/epics/player-development-system/story-008-player-state-boundary.md` and `production/epics/player-development-system/story-009-player-development-regression.md` because those stories define player state consumption boundaries and explicitly identify Player Management UI as downstream work.
- Match Performance UI readiness is mapped to `production/epics/match-competition-system/story-006-match-result-packet.md` and `production/epics/match-competition-system/story-009-match-loop-regression.md` because those stories define the MatchResultPacket consumed by Match Performance UI and explicitly identify Match Performance UI as downstream work.

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S1-7 | 清理 adoption 剩余中优先级基础设施 | producer | 0.5 | `docs/adoption-plan-2026-05-19.md` | `production/stage.txt` status is resolved through `/gate-check Production` or explicitly deferred; adoption plan is updated/checkable after sprint-status creation. |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| `production/epics/time-and-season-progression-system/story-009-time-status-regression.md`, `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md` | Active session state shows HUD Framework Phase 3 implementation in progress from prior work. | 1.5 days |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| HUD implementation may have unverified Godot scene/script issues | Medium | High | Run manual walkthrough and targeted Godot/GDScript checks before treating HUD as complete. |
| No QA plan exists at sprint start | High | Medium | Run `/qa-plan sprint` immediately after writing this sprint plan. |
| Player Management UI and Match Performance UI depend on HUD stability | Medium | Medium | Keep both as Should Have until HUD review and fixes complete. |
| No Accepted ADR corpus exists yet | Medium | Medium | Use current Control Manifest global rules; create ADRs before major architecture decisions. |

## Dependencies on External Factors

- Godot editor/runtime availability for UI walkthrough and screenshot evidence.
- Existing HUD implementation files under `src/ui/` remaining stable enough for review.
- QA plan creation before implementation work expands beyond HUD.

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-1.md`)
- [ ] All Logic/Integration stories have passing unit/integration tests where applicable
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS (`/team-qa sprint`)
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged

> ⚠️ **No QA Plan**: This sprint was started without a QA plan. Run `/qa-plan sprint`
> before the last story is implemented. The Production → Polish gate requires a QA
> sign-off report, which requires a QA plan.

## Gate Notes

- Producer feasibility gate PR-SPRINT skipped — Lean mode.
- QA plan not found at sprint creation time.

## Scope Check

If this sprint includes stories added beyond the original epic scope, run `/scope-check [epic]` to detect scope creep before implementation begins.
