# Story 004: 实现阶段结算与赛后连续触发

> **Epic**: 时间与赛季推进系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/time-and-season-progression-system.md`
**Requirement**: `TR-time-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-time-005`: stage_settlement_trigger_reached = matches_played ≥ matches_per_stage

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0002: Event/Signal Architecture + TimeManager
**ADR Decision Summary**: TimeManager owns phase and stage scheduling, and broadcasts time node changes through EventBus.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Stage trigger calculation should be deterministic and unit-testable without downstream settlement content.

**Control Manifest Rules (this layer)**:
- Required: `EventBus` is the sole cross-system communication channel.
- Forbidden: Never let downstream systems silently advance stage state outside TimeManager.
- Guardrail: EventBus dispatch cost per player action should stay below 0.1ms in the ADR estimate.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/time-and-season-progression-system.md`, scoped to this story:*

- [ ] `stage_settlement_trigger_reached = current_stage_progress >= stage_progress_target`.
- [ ] Reaching stage target changes state to `Stage Settlement`.
- [ ] Post-match settlement can immediately continue into `Stage Settlement` when stage target is met.
- [ ] If the stage target is not met, post-match settlement returns to the appropriate non-stage flow.
- [ ] The stage trigger does not require an extra manual time advance after a qualifying post-match settlement.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

This story owns trigger timing, not settlement rewards. Downstream systems subscribe to the stage event and provide their own content.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Economy or League stories: actual stage rewards, standings, or account settlement.
- Story 006: Multiple key node priority when several conditions are true together.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 阶段进度达到目标时触发 Stage Settlement
  - Given: `current_stage_progress >= stage_progress_target`
  - When: 评估 `stage_settlement_trigger_reached`
  - Then: 应进入 `Stage Settlement`
  - Edge cases: `=` 与 `>` 必须覆盖；未达标时不得误触发

- **AC-2**: 比赛结束后若同时满足阶段结算条件，应连续推进
  - Given: 比赛刚结束并进入 `Post-Match Settlement`，且 `current_stage_progress >= stage_progress_target`
  - When: 执行赛后结算链
  - Then: 应按顺序先完成 `Post-Match Settlement`，再进入 `Stage Settlement`，中间不返回 `Planning`
  - Edge cases: 同一 tick 内连续触发时，不得跳过任一步，也不得要求额外手动推进

- **AC-3**: 比赛结束但未达阶段目标时，只执行赛后结算
  - Given: 比赛结束且 `current_stage_progress < stage_progress_target`
  - When: 执行赛后结算链
  - Then: 仅进入/完成 `Post-Match Settlement`，不得误入 `Stage Settlement`
  - Edge cases: 进度差 1 点、赛后奖励尚未写回时，应以稳定写回后的进度判断

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/time/stage_settlement_trigger_test.gd` — must exist and pass

**Status**: [x] Automated unit evidence recorded — `tests/unit/time/stage_settlement_trigger_test.gd` passed (`STAGE_SETTLEMENT_TRIGGER_TEST_PASS`)

---

## Dependencies

- Depends on:
  - `production/epics/time-and-season-progression-system/story-003-match-trigger.md` — must be DONE
- Unlocks:
  - `production/epics/time-and-season-progression-system/story-005-season-progress-flow.md`
  - `production/epics/time-and-season-progression-system/story-006-key-node-priority.md`
  - `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md`
