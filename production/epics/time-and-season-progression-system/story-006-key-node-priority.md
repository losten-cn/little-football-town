# Story 006: 实现关键节点优先级与同位置确定性结算

> **Epic**: 时间与赛季推进系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/time-and-season-progression-system.md`
**Requirement**: `TR-time-004`, `TR-time-005`, `TR-time-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-time-004`: match_trigger_reached = accumulated ≥ match_interval AND no match in progress
- `TR-time-005`: stage_settlement_trigger_reached = matches_played ≥ matches_per_stage
- `TR-time-006`: season_progress_ratio = matches_played / total_matches

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0002: Event/Signal Architecture + TimeManager
**ADR Decision Summary**: EventBus and TimeManager resolve simultaneous key nodes deterministically, with time events processed before downstream match, league, economy, player, town, and save events.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Use deterministic queues/orderings and avoid relying on Dictionary iteration order for gameplay outcomes.

**Control Manifest Rules (this layer)**:
- Required: Event dispatch order follows the fixed priority chain: `time_*` → `match_completed` → `league_*` → `economy_*` → `player_*` → `town_*` → `save_*`.
- Forbidden: Never let implementation traversal order decide gameplay node order.
- Guardrail: EventBus steady-state memory <50KB.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/time-and-season-progression-system.md`, scoped to this story:*

- [ ] Multiple key nodes at the same timeline position resolve in this fixed order:
      `Match Trigger → Post-Match Settlement → Stage Settlement → Season Settlement`.
- [ ] A qualifying chain handles `Match Trigger → Post-Match Settlement → Stage Settlement → Season Settlement` without skipping eligible nodes.
- [ ] Repeating the same input produces the same state sequence, event sequence, and final state.
- [ ] Each eligible key node is processed exactly once.
- [ ] If processing one node changes the next node's eligibility, the next node is re-evaluated from the newly committed stable state, but no already-processed node may be replayed.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

Use TimeManager-owned key-node scheduling and EventBus priority rules. This story validates deterministic ordering, not downstream reward details.

This story defines key-node order inside the time domain. EventBus domain priority still applies after node resolution: `time_*` events dispatch before downstream `match_completed`, `league_*`, `economy_*`, `player_*`, `town_*`, and `save_*` events.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: Payload schema and EventBus integration details.
- Downstream stories: actual match/league/economy settlement contents.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 同一 timeline 位置的多个关键节点按已定义优先级结算
  - Given: 同一位置同时满足多个关键节点条件（如 Match Trigger / Stage Settlement / Season Settlement）
  - When: 执行该位置的统一结算
  - Then: 处理顺序必须严格符合 story/ADR 定义的关键节点优先级，且最终状态唯一确定
  - Edge cases: 任意两个节点并发、三个节点并发都要覆盖；不得因容器遍历顺序产生随机结果

- **AC-2**: 同输入重复运行得到完全一致的结算顺序与结果
  - Given: 相同初始状态、相同关键节点集合、相同 timeline 位置
  - When: 重复执行多次同位置结算
  - Then: 每次产生的状态序列、事件序列、最终快照必须一致
  - Edge cases: 测试应覆盖重复运行与不同执行轮次，防止隐式随机性

- **AC-3**: 同位置连续结算不会跳过节点或重复结算
  - Given: 某位置需要按优先级串行处理多个节点
  - When: 执行完整结算链
  - Then: 每个应处理节点恰好处理一次，既不遗漏也不重复
  - Edge cases: 上一节点会改变下一节点条件时，仍须保证结果与定义一致

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/time/key_node_priority_test.gd` OR playtest doc

**Status**: [x] Automated integration evidence recorded — `tests/integration/time/key_node_priority_test.gd` passed (`KEY_NODE_PRIORITY_TEST_PASS`)

---

## Dependencies

- Depends on:
  - `production/epics/time-and-season-progression-system/story-003-match-trigger.md` — must be DONE
  - `production/epics/time-and-season-progression-system/story-004-stage-settlement-trigger.md` — must be DONE
  - `production/epics/time-and-season-progression-system/story-005-season-progress-flow.md` — must be DONE
- Unlocks:
  - `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md`
