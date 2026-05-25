# Story 009: 实现完整比赛闭环回归样本与性能验证

> **Epic**: 比赛竞技系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/match-competition-system.md`
**Requirement**: `TR-match-013`, `TR-match-015`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-match-013`: Full match simulation < 100ms
- `TR-match-015`: Stadium revenue multiplier consumed from TownBuilding

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0006: Match Simulation Architecture
**ADR Decision Summary**: MatchSimulation provides a full deterministic match loop and result handoff fast enough for MVP play, with standardized output consumed by downstream systems.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state machine and Dictionary math; no post-cutoff APIs used.

**Control Manifest Rules (this layer)**:
- Required: Produce a standardized `MatchResultPacket` consumed by League, Economy, UI, and Time systems.
- Required: Represent match flow as a deterministic state machine with seeded RNG and an explicit halftime adjustment state.
- Guardrail: Full match simulation <20ms compute time target from ADR; TR registry acceptance requires <100ms.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/match-competition-system.md`, scoped to this story:*

- [ ] A representative MVP session completes: pre-match preparation → first half → halftime → second half → result confirmation → post-match feedback.
- [ ] Match result can be consumed by downstream systems, including stadium revenue multiplier needs and post-match feedback back to player/time systems.
- [ ] Full match simulation completes under 100ms, and draws are legal MVP final results without extra-time or penalty requirements.

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

This story creates integration regression evidence for the complete match loop. Use the official state machine, seeded simulation, halftime handling, MatchResultPacket output, and downstream handoff surfaces. Do not introduce extra-time, penalties, or physics simulation for MVP.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Balance tuning if sample outcomes fall outside target distribution.
- Presentation UI animation, event timeline rendering, or audio feedback.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 一个 MVP 会话能跑完整闭环：赛前准备→上半场→中场→下半场→结果确认→赛后反馈
  - Given: 一个最小可玩 MVP 会话，包含正式比赛入口与下游反馈展示。
  - When: 从赛前准备开始完整游玩一场正式比赛直到赛后反馈结束。
  - Then: 全流程无阻塞、无缺失状态、无必现报错，且按既定顺序完成闭环。
  - Edge cases: 平局；中场不做调整；使用推荐阵容直接开赛；低事件密度比赛也必须闭环完成。

- **AC-2**: 比赛结果能被下游消费：至少包含 `stadium revenue multiplier` 所需信息，且赛后反馈可回培养/时间系统
  - Given: 一场比赛已产出确认过的 `MatchResultPacket`。
  - When: League/Economy/Time/UI 等下游系统消费该结果。
  - Then: Economy 可读取 `stadium revenue multiplier` 所需信息；赛后反馈中的 condition/morale/growth/time 变更能正确回写到培养/时间相关系统。
  - Edge cases: 平局消费路径；主客场差异；无成长标签球员不应导致下游失败。

- **AC-3**: Full match simulation < 100ms；平局在 MVP 阶段直接作为合法终场结果
  - Given: 使用代表性 MVP 样本数据与固定 seed，在目标运行环境下执行整场模拟。
  - When: 记录从确认开赛到生成 `MatchResultPacket` 的模拟耗时，并包含一场平局样本。
  - Then: 单场 full match simulation 耗时小于 100ms；平局无需额外加赛或异常分支，可直接进入 Result Review/Settlement 作为合法终场结果。
  - Edge cases: 高事件密度样本仍需 <100ms；连续批量运行时单次结果不应显著退化；0:0 与高比分平局都应合法结束。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/match/match_loop_regression_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/match-competition-system/story-001-match-state-flow.md` — must be DONE
  - `production/epics/match-competition-system/story-002-team-strength-aggregation.md` — must be DONE
  - `production/epics/match-competition-system/story-003-actual-win-probability.md` — must be DONE
  - `production/epics/match-competition-system/story-004-key-event-generation.md` — must be DONE
  - `production/epics/match-competition-system/story-005-halftime-adjustment.md` — must be DONE
  - `production/epics/match-competition-system/story-006-match-result-packet.md` — must be DONE
  - `production/epics/match-competition-system/story-007-match-rng-determinism.md` — must be DONE
  - `production/epics/match-competition-system/story-008-match-restore-dedup.md` — must be DONE
- Unlocks:
  - Downstream work: Economy post-match settlement, League standings integration, Match Performance UI implementation
