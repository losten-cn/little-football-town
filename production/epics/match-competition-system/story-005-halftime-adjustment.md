# Story 005: 实现中场调整与下半场独立生效

> **Epic**: 比赛竞技系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/match-competition-system.md`
**Requirement**: `TR-match-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-match-006`: Half-time adjustment: change tactics + up to 3 substitutions, second half only

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0006: Match Simulation Architecture
**ADR Decision Summary**: The explicit Halftime Adjustment state allows tactics and substitutions to be applied only to the second half while preserving first-half results.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state machine and Dictionary math; no post-cutoff APIs used.

**Control Manifest Rules (this layer)**:
- Required: Represent match flow as a deterministic state machine with seeded RNG and an explicit halftime adjustment state.
- Required: Half-time tactical changes and substitutions must affect only the second half.
- Forbidden: Never replace the explicit match state machine with a single generator function that removes halftime/state boundaries.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/match-competition-system.md`, scoped to this story:*

- [ ] Halftime Adjustment allows tactic changes and up to 3 substitutions.
- [ ] Halftime changes affect the second half only and do not rewrite first-half events, score, or summaries.
- [ ] Choosing no halftime changes remains legal and proceeds to second-half simulation.

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

Expose a halftime adjustment operation that is valid only while the state machine is in Halftime Adjustment. Store second-half tactics and substitutions separately from first-half data. Reject substitutions beyond the configured limit and keep first-half event data immutable after it has been generated.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Presentation UI for halftime controls.
- Story 006: Final player performance and result packet summarization.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Halftime Adjustment 允许战术改变与最多 3 次换人
  - Given: 比赛已进入 Halftime，且队伍有可用替补。
  - When: 玩家在中场界面修改战术并尝试换人 0、1、3、4 次。
  - Then: 0~3 次换人均可合法提交；第 4 次必须被拒绝；已提交战术变更被记录用于下半场。
  - Edge cases: 无可用替补时仍可只改战术；重复选择同一球员；换人后阵容仍需保持合法。

- **AC-2**: 调整只影响 second half，不回溯 first half
  - Given: 记录上半场结束时的比分、事件、出场摘要与上半场战术状态。
  - When: 在 Halftime 做出战术/换人调整并完成下半场。
  - Then: First Half 已生成的数据保持不变；调整仅影响 Second Half 的事件与结果演化。
  - Edge cases: 中场大幅改战术后，已记录的上半场 win_reasons/事件不得被重写；Halftime 后立即保存再加载仍不可回溯。

- **AC-3**: 不做调整时仍可合法继续下半场
  - Given: 比赛处于 Halftime，玩家不修改任何战术且不换人。
  - When: 玩家选择直接继续比赛。
  - Then: 比赛可正常进入 Second Half，且沿用中场前有效配置继续模拟。
  - Edge cases: 推荐调整存在但玩家忽略；无替补与有替补两种情况；平局/领先/落后都可直接继续。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/match/halftime_adjustment_test.gd` OR playtest doc

**Status**: [x] Created — tests/integration/match/halftime_adjustment_test.gd

---

## Dependencies

- Depends on:
  - `production/epics/match-competition-system/story-001-match-state-flow.md` — must be DONE
  - `production/epics/match-competition-system/story-004-key-event-generation.md` — must be DONE
- Unlocks:
  - `production/epics/match-competition-system/story-006-match-result-packet.md`
  - `production/epics/match-competition-system/story-007-match-rng-determinism.md`

---

## Completion Notes

**Completed**: 2026-05-26  
**Criteria**: 3/3 passing  
**Deviations**: None  
**Test Evidence**: Integration: `tests/integration/match/halftime_adjustment_test.gd`  
**Code Review**: Approved
