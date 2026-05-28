# Story 008: 实现存档降级恢复与重复触发防重赛

> **Epic**: 比赛竞技系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/match-competition-system.md`
**Requirement**: `TR-match-007`, `TR-match-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-match-007`: Match In Progress NOT a stable restore point — save abandons partial state
- `TR-match-012`: match_id in match_completed event for LeagueStructure correlation

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0006: Match Simulation Architecture
**ADR Decision Summary**: MatchCompetition registers SaveManager contracts, but saves during active simulation abandon partial in-progress state and restore to pre-match entry; completed match nodes are deduplicated by confirmed result packet and match id.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state machine and Dictionary math; no post-cutoff APIs used.

**Control Manifest Rules (this layer)**:
- Required: If a save occurs mid-match, abandon partial in-progress match state and restore to pre-match Entry state on load.
- Required: Every Core system must register its serialization contract with `SaveManager` and restore only through the centralized load pipeline.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/match-competition-system.md`, scoped to this story:*

- [ ] Serializing mid-match does not preserve half-complete simulation state and retains only safe pre-match or pending context.
- [ ] Loading a mid-match snapshot returns to the nearest recoverable node and does not silently write a final result.
- [ ] Re-triggering a match node that already has a confirmed result shows or hands off the existing result instead of replaying the match.

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

Implement `_serialize()` and `_deserialize()` for MatchCompetition/MatchSimulation according to SaveManager registration. During First Half or Second Half, return inactive or pending context data only. Track confirmed result packets by `match_id` so repeated triggers can detect completed nodes and avoid creating a second result for the same scheduled match.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- SaveManager file persistence details and checksum handling.
- LeagueStructure's duplicate match submission behavior after consuming `match_id`.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: mid-match serialize 不保留半场中间态，只保留 pre-match context / pending context
  - Given: 比赛在 First Half 中段、Halftime、Second Half 中段分别触发 serialize。
  - When: 检查保存后的持久化上下文。
  - Then: 不存在可直接恢复到半场中间态的数据；仅保留允许恢复的 pre-match/pending 比赛上下文。
  - Edge cases: 刚发生关键事件后立刻保存；Halftime 已做调整但未继续；多次连续保存结果应一致。

- **AC-2**: load 后回到最近可恢复节点，不静默写入终场结果
  - Given: 使用上述 mid-match 存档重新加载游戏。
  - When: 进入与该比赛相关的流程。
  - Then: 系统回到最近可恢复节点，并要求玩家重新进入合法比赛入口；不会在加载时自动生成或写入终场结果。
  - Edge cases: 加载后立即查看联赛/经济/时间系统；Result Review 前中断；接近终场中断也不得自动结算。

- **AC-3**: 同一比赛节点若已有确认结果包，则展示已有结果/直接交接，不得重赛
  - Given: 某比赛节点已存在确认完成的 `MatchResultPacket`。
  - When: 玩家再次触发同一比赛节点或从加载后再次进入该节点。
  - Then: 系统展示已有结果或直接进入下游交接，不允许重新开赛生成第二份结果。
  - Edge cases: 重复点击入口；加载旧存档后再次触发同节点；下游消费未完成时也不得重赛覆盖已确认结果。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/match/match_restore_dedup_test.gd` OR playtest doc

**Status**: [x] Created — tests/integration/match/match_restore_dedup_test.gd

---

## Completion Notes

**Completed**: 2026-05-27  
**Criteria**: 3/3 passing  
**Deviations**: None  
**Test Evidence**: Integration: `tests/integration/match/match_restore_dedup_test.gd`  
**Code Review**: Approved with suggestions  
**Review Notes**: Restore-boundary behavior, mid-match degradation, and confirmed-result dedup all passed review. Remaining feedback is advisory only around making the retrigger event-contract assertion more explicit if that contract is later frozen.

---

## Dependencies

- Depends on:
  - `production/epics/match-competition-system/story-001-match-state-flow.md` — must be DONE
  - `production/epics/match-competition-system/story-006-match-result-packet.md` — must be DONE
  - `production/epics/match-competition-system/story-007-match-rng-determinism.md` — must be DONE
- Unlocks:
  - `production/epics/match-competition-system/story-009-match-loop-regression.md`
