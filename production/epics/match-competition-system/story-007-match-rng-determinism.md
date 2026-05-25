# Story 007: 实现 seeded RNG 决定性与重复运行一致性

> **Epic**: 比赛竞技系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/match-competition-system.md`
**Requirement**: `TR-match-009`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-match-009`: Seeded RNG per match — same seed + inputs = identical outcome

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0006: Match Simulation Architecture
**ADR Decision Summary**: Each match stores and uses a seed so the same seed plus same inputs produces identical event sequence and result.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state machine and Dictionary math; no post-cutoff APIs used.

**Control Manifest Rules (this layer)**:
- Required: Represent match flow as a deterministic state machine with seeded RNG and an explicit halftime adjustment state.
- Forbidden: Never implement match simulation as a one-shot black-box formula with no event flow.
- Guardrail: Full match simulation <20ms compute time target from ADR.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/match-competition-system.md`, scoped to this story:*

- [ ] Same seed plus same inputs produces the same event sequence and final result.
- [ ] Changing only the seed changes at least part of the event sequence or match result.
- [ ] Determinism covers first half, halftime-adjusted second half, win reasons, and not just final score.

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

Use a per-match RandomNumberGenerator seeded from stored MatchData seed. Re-seed the RNG at match start for deterministic tests. Include match seed in saved match data and ensure all stochastic decisions in event generation and result analysis use this RNG rather than global randomness.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: Event category generation coverage.
- Story 006: Result packet field completeness.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: same seed + same inputs = same event sequence and final result
  - Given: 固定一套完全相同的比赛输入与 seed。
  - When: 连续运行同一场模拟至少两次。
  - Then: 两次输出的事件序列、比分、胜平负、球员摘要、`win_reasons` 完全一致。
  - Edge cases: 包含中场调整输入但两次调整相同；低事件与高事件样本都必须一致；重复运行顺序前后不影响结果。

- **AC-2**: 改变 seed 会改变至少部分事件序列或结果
  - Given: 固定同一套比赛输入，但替换为不同 seed。
  - When: 分别运行模拟并比较结果。
  - Then: 至少有一项发生变化：事件序列、关键事件分钟/分类、比分或胜负结果。
  - Edge cases: 极端强弱差距下比分可能相同，但事件序列仍应可区分；多个不同 seed 不应全部产出完全相同结果。

- **AC-3**: 决定性覆盖上下半场与胜负原因，不只是比分
  - Given: 固定输入与 seed，并保留上下半场拆分输出。
  - When: 重复运行同一场比赛并逐项比对。
  - Then: First Half/Second Half 的事件划分、Halftime 后结果演化、最终 `win_reasons` 都保持一致，而非仅终场比分一致。
  - Edge cases: 中场无调整；中场有固定调整；平局比赛也必须在半场级输出上保持一致。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/match/match_rng_determinism_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/match-competition-system/story-004-key-event-generation.md` — must be DONE
  - `production/epics/match-competition-system/story-005-halftime-adjustment.md` — must be DONE
- Unlocks:
  - `production/epics/match-competition-system/story-008-match-restore-dedup.md`
  - `production/epics/match-competition-system/story-009-match-loop-regression.md`
