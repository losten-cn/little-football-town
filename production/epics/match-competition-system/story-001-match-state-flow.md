# Story 001: 实现比赛状态机与正式比赛入口边界

> **Epic**: 比赛竞技系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-25

## Context

**GDD**: `design/gdd/match-competition-system.md`
**Requirement**: `TR-match-001`, `TR-match-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-match-001`: 8-state match flow: Entry→Pre-Match→Confirmation→First Half→Halftime→Second Half→Result Review→Settlement
- `TR-match-007`: Match In Progress NOT a stable restore point — save abandons partial state

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0006: Match Simulation Architecture
**ADR Decision Summary**: MatchSimulation uses a deterministic explicit state machine for match flow, and mid-match saves abandon partial in-progress state instead of restoring into half-complete match execution.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state machine and Dictionary math; no post-cutoff APIs used.

**Control Manifest Rules (this layer)**:
- Required: Represent match flow as a deterministic state machine with seeded RNG and an explicit halftime adjustment state.
- Forbidden: Never replace the explicit match state machine with a single generator function that removes halftime/state boundaries.
- Guardrail: Full match simulation <20ms compute time target from ADR; TR registry acceptance requires <100ms.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/match-competition-system.md`, scoped to this story:*

- [ ] Match flow follows Entry → Pre-Match → Confirmation → First Half → Halftime → Second Half → Result Review → Settlement.
- [ ] A formal match can only enter through a legal match node where `match_trigger_reached = true` and `match_center_available = true`.
- [ ] `Match In Progress` is not a stable restore point; interruption during a half does not restore into a half-complete state.

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

Implement MatchSimulation as the authoritative state machine for a single match. Keep Entry, Pre-Match, Confirmation, First Half, Halftime Adjustment, Second Half, Result Review, and Settlement Handoff as explicit states. Register the match system with SaveManager, but when serializing during First Half or Second Half, persist only safe pre-match or pending context instead of partial simulation state.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Team strength and lineup legality calculations.
- Story 006: Final result packet schema and downstream handoff contents.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 8-state flow 按 Entry → Pre-Match → Confirmation → First Half → Halftime → Second Half → Result Review → Settlement 顺序推进
  - Given: 玩家位于 `match_trigger_reached=true` 的正式比赛节点，且存在可合法开赛的默认阵容/战术。
  - When: 玩家从正式比赛入口完整走完一场比赛直到结算。
  - Then: 记录到的状态迁移顺序严格等于 8-state flow；不得跳态、回退、重复进入同一正式状态。
  - Edge cases: 玩家在 Confirmation 返回 Pre-Match 后再次确认；Result Review 停留后再进入 Settlement；平局也必须走完整 8 个状态。

- **AC-2**: 只有 `match_trigger_reached=true` 且 `match_center_available=true` 的正式比赛节点才能进入正式比赛入口
  - Given: 分别准备一个 `match_trigger_reached=true, match_center_available=true` 的比赛节点，以及一个 `match_trigger_reached=true, match_center_available=false` 与一个 `match_trigger_reached=false` 的比赛节点。
  - When: 玩家尝试从这些节点进入正式比赛。
  - Then: 仅同时满足两个条件的节点可进入 Entry/Pre-Match；其余节点必须被拒绝且不会创建进行中的正式比赛上下文。
  - Edge cases: 非正式节点已存在推荐阵容；从 UI/快捷入口重复触发；时间推进前后再次尝试。

- **AC-3**: Match In Progress 不是稳定恢复点，中途中断后不得恢复到半场中间态
  - Given: 比赛分别停留在 First Half 中段、Halftime、Second Half 中段时触发中断并保存/退出。
  - When: 重新加载该存档。
  - Then: 不得恢复到半场中间态；只能回到最近允许恢复的 pre-match/pending 入口上下文，且不会静默生成终场结果。
  - Edge cases: 中断发生在进球事件后立即保存；Halftime 刚进入未做调整；Second Half 接近终场时中断。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/match/match_state_flow_test.gd` OR playtest doc

**Status**: [x] Created — tests/integration/match/match_state_flow_test.gd

---

## Dependencies

- Depends on:
  - `production/epics/time-and-season-progression-system/story-003-match-trigger.md` — must be DONE
  - `production/epics/save-and-load-system/story-002-save-registration-snapshot.md` — must be DONE
  - `production/epics/save-and-load-system/story-003-stable-node-save-gate.md` — must be DONE
- Unlocks:
  - `production/epics/match-competition-system/story-005-halftime-adjustment.md`
  - `production/epics/match-competition-system/story-008-match-restore-dedup.md`

## Completion Notes
**Completed**: 2026-05-25
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Integration: `tests/integration/match/match_state_flow_test.gd`
**Code Review**: Approved
