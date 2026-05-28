# Story 003: 实现比赛节点触发与 Match Trigger 状态转换

> **Epic**: 时间与赛季推进系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/time-and-season-progression-system.md`
**Requirement**: `TR-time-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-time-004`: match_trigger_reached = accumulated ≥ match_interval AND no match in progress

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0002: Event/Signal Architecture + TimeManager
**ADR Decision Summary**: TimeManager detects key time nodes and emits `time_match_triggered` through EventBus rather than calling MatchCompetition directly.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Match trigger calculation should be deterministic and idempotent under repeated polling.

**Control Manifest Rules (this layer)**:
- Required: `EventBus` is the sole cross-system communication channel.
- Forbidden: Never mix Core direct calls with EventBus-based UI communication.
- Guardrail: EventBus steady-state memory <50KB.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/time-and-season-progression-system.md`, scoped to this story:*

- [ ] `match_trigger_reached = current_timeline_position >= scheduled_match_position`.
- [ ] Reaching a scheduled match node changes state to `Match Trigger`.
- [ ] Reaching a match node emits `time_match_triggered` with match context.
- [ ] A match node triggers exactly once.
- [ ] If an action lands exactly on a match node, no extra free action window opens before `Match Trigger`.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

TimeManager produces the scheduling event; MatchCompetition consumes it later through EventBus. Do not instantiate or call MatchCompetition from this story.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Match Competition stories: pre-match, live match, halftime, and result flow.
- Story 007: Full EventBus priority queue integration.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 未到比赛节点时不得触发比赛
  - Given: `current_timeline_position < scheduled_match_position`
  - When: 评估 `match_trigger_reached`
  - Then: 结果应为 false，状态保持在当前非比赛触发状态
  - Edge cases: 距离比赛仅差 1 格/1 单位时间时仍不得提前触发

- **AC-2**: 到达比赛节点时进入 Match Trigger 并发事件
  - Given: `current_timeline_position >= scheduled_match_position`
  - When: 执行比赛节点评估
  - Then: `match_trigger_reached` 为 true，状态切换到 `Match Trigger`，并通过 EventBus 发出 `time_match_triggered`
  - Edge cases: `=` 与 `>` 两种情况都必须通过；事件不可漏发

- **AC-3**: 已触发的比赛节点不会重复触发
  - Given: 某场比赛已进入或处理过 `Match Trigger`
  - When: 在同一节点再次执行评估
  - Then: 不应重复发出 `time_match_triggered`，也不应重复创建比赛流程
  - Edge cases: 多次轮询、重复调用 update/evaluate 时必须保持幂等

- **AC-4**: 比赛开始后状态正确流转到 Match In Progress
  - Given: 已完成 `Match Trigger` 且比赛流程开始
  - When: 执行比赛启动切换
  - Then: 状态应进入 `Match In Progress`，并阻止继续执行 Planning/普通行动窗口逻辑
  - Edge cases: 比赛未真正启动时不得提前进入 `Match In Progress`

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/time/match_trigger_test.gd` — must exist and pass

**Status**: [x] Automated unit evidence recorded — `tests/unit/time/match_trigger_test.gd` passed (`MATCH_TRIGGER_TEST_PASS`)

---

## Dependencies

- Depends on:
  - `production/epics/time-and-season-progression-system/story-001-time-manager-state-contract.md` — must be DONE
  - `production/epics/time-and-season-progression-system/story-002-action-window-formula.md` — must be DONE
- Unlocks:
  - `production/epics/time-and-season-progression-system/story-004-stage-settlement-trigger.md`
  - `production/epics/time-and-season-progression-system/story-006-key-node-priority.md`
  - `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md`
