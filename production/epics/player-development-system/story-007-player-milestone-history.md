# Story 007: 实现成长里程碑、训练历史与赛季年龄推进

> **Epic**: 运动员培养系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/player-development-system.md`
**Requirement**: `TR-playerdev-001`, `TR-playerdev-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-playerdev-001`: Player must have: id, name, age, position, 5 attrs, train_efficiency, condition, morale, history, milestones
- `TR-playerdev-011`: Milestone check: attribute reaching 10-multiple triggers player_milestone_reached

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0005: Player Data Model
**ADR Decision Summary**: Player history, milestones, and age are authoritative player fields; PlayerDevelopment emits player milestone events and consumes time season-end events for age advancement.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RefCounted`, `Resource`, and `Dictionary` serialization are stable Godot 4.x APIs; no post-cutoff API verification required.

**Control Manifest Rules (this layer)**:
- Required: Event payloads must be typed `Dictionary` values containing only serializable primitives or typed `Array[Dictionary]` data.
- Forbidden: Never consume the generic `event_fired` signal for gameplay or UI business logic.
- Guardrail: EventBus steady-state memory <50KB; player runtime memory ~25KB target for roster structures.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/player-development-system.md`, scoped to this story:*

- [ ] Crossing an attribute multiple of 10 or reaching cumulative training thresholds emits `player_milestone_reached`.
- [ ] Every legal training settlement records training history and supports a recent-growth summary.
- [ ] `time_season_ended` increments player age by 1 exactly once per season boundary.

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

Store `training_history`, `milestones`, and `total_training_sessions` on Player and include them in serialization. Check milestones after successful gain application and emit `player_milestone_reached` with serializable primitive fields. Subscribe to TimeManager's season-end event through EventBus and increment player age without creating a separate independent season progression system.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Presentation UI for milestone popups or growth review screens.
- Story 009: Long-loop regression samples using history and milestones.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 属性跨过 10 的整数倍或累计训练次数达到阈值时触发 player_milestone_reached。
  - Given: 一名球员距离某属性 10 的整数倍只差一次合法训练，且累计训练次数也接近阈值。
  - When: 执行使其跨线的训练。
  - Then: 达到条件时触发 player_milestone_reached，且事件内容可区分“属性里程碑”与“训练次数里程碑”。
  - Edge cases: 恰好落在整数倍/阈值上应触发；同一次结算满足多个里程碑时不得对同一里程碑重复发射。

- **AC-2**: 每次合法训练都会记录 history，并可形成近期成长摘要。
  - Given: 一名球员 history 初始为空，随后执行多次合法训练。
  - When: 检查训练后 history 与近期成长摘要。
  - Then: 每次合法训练对应一条 history，顺序与实际结算顺序一致；近期成长摘要可基于最近若干条 history 正确生成。
  - Edge cases: 非法/失败训练不得写入 history；摘要请求条数超过现有 history 时应只返回已有记录。

- **AC-3**: time_season_ended 后年龄 +1，且不会重复递增。
  - Given: 一名球员在赛季结束前年龄为 X。
  - When: 处理一次 time_season_ended，并在同一赛季结束状态下再次校验/重复触发。
  - Then: 年龄仅从 X 增至 X+1 一次，不会因重复处理、重复加载或重复事件而再次增长。
  - Edge cases: 多名球员应全部只增长一次；赛季结束后立即存档读档也不得再次 +1。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/player-dev/player_milestone_history_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/player-development-system/story-006-training-atomic-integration.md` — must be DONE
  - `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md` — must be DONE
- Unlocks:
  - `production/epics/player-development-system/story-009-player-development-regression.md`
