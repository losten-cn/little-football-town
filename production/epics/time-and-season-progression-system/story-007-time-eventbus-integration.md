# Story 007: 实现时间事件发布与 EventBus 优先级集成

> **Epic**: 时间与赛季推进系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/time-and-season-progression-system.md`
**Requirement**: `TR-time-004`, `TR-time-005`, `TR-time-006`, `TR-time-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-time-004`: match_trigger_reached = accumulated ≥ match_interval AND no match in progress
- `TR-time-005`: stage_settlement_trigger_reached = matches_played ≥ matches_per_stage
- `TR-time-006`: season_progress_ratio = matches_played / total_matches
- `TR-time-008`: TimeManager exposes get_state() for save snapshots

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0002: Event/Signal Architecture + TimeManager
**ADR Decision Summary**: TimeManager publishes typed `time_*` events through EventBus, and EventBus resolves simultaneous events using the fixed project priority chain.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Use callable-based subscriptions and typed serializable Dictionary payloads.

**Control Manifest Rules (this layer)**:
- Required: Event payloads must be typed Dictionary values containing only serializable primitives or typed Array[Dictionary] data.
- Forbidden: Never consume the generic `event_fired` signal for gameplay or UI business logic.
- Guardrail: EventBus steady-state memory <50KB.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/time-and-season-progression-system.md`, scoped to this story:*

- [ ] TimeManager emits `time_match_triggered` with match context when a match node is reached.
- [ ] TimeManager emits stage and season events when their corresponding nodes settle.
- [ ] Time event payloads are serializable Dictionaries and contain the fields defined in ADR-0002.
- [ ] EventBus dispatches `time_*` events before downstream `match_completed`, `league_*`, `economy_*`, `player_*`, `town_*`, and `save_*` events.
- [ ] Subscribers processing `time_*` events read stable TimeManager state from `get_state()`.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

Business logic consumers subscribe via `EventBus.subscribe(event_name, callable)` and unsubscribe explicitly. `event_fired` is observability-only.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- UI screen lifecycle subscription behavior.
- Downstream content triggered by the time events.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 时间系统状态变化通过 EventBus 发布 `time_*` 事件
  - Given: TimeManager 发生比赛触发、阶段结算、赛季结算等关键变化
  - When: 订阅 EventBus 并执行对应推进
  - Then: 必须收到对应 `time_*` 事件，且事件类型与状态变化一致
  - Edge cases: 连续状态变化时不得漏发；无变化时不得误发

- **AC-2**: EventBus 优先级满足 `time_*` 先于其他业务域事件
  - Given: 同一帧/同一结算链中同时存在 `time_*`、`match_completed`、`league_*`、`economy_*`、`player_*`、`town_*`、`save_*`
  - When: 执行事件派发
  - Then: `time_*` 必须先被处理，之后才是 `match_completed` 与其他业务域事件
  - Edge cases: 多个 time 事件连续出现时，其内部顺序仍需与关键节点优先级一致

- **AC-3**: 事件处理器读取到的是稳定快照
  - Given: 下游系统在处理 `time_*` 事件时会调用 `TimeManager.get_state()`
  - When: 事件被派发到订阅者
  - Then: 订阅者读到的状态必须已经完成当前节点结算，不得出现半完成状态
  - Edge cases: 赛后连续触发、同位置多节点结算时尤其要校验无中间态泄漏

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/time/time_eventbus_integration_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/time-and-season-progression-system/story-006-key-node-priority.md` — must be DONE
- Unlocks:
  - Downstream work: Core systems that consume time events
