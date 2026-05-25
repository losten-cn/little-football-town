# Story 004: 实现关键事件产量与事件分类生成

> **Epic**: 比赛竞技系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/match-competition-system.md`
**Requirement**: `TR-match-004`, `TR-match-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-match-004`: Key event count per match: 3 ≤ count ≤ 15
- `TR-match-005`: 6 event categories: offensive_push, shot_on_goal, goal_scored, key_defense, tactical_adaptation, stamina_decline

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0006: Match Simulation Architecture
**ADR Decision Summary**: MatchSimulation generates readable categorized match events through a deterministic event pipeline using match inputs and seeded RNG.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state machine and Dictionary math; no post-cutoff APIs used.

**Control Manifest Rules (this layer)**:
- Required: Match event generation must emit readable categorized events with minute, side, and narrative metadata.
- Forbidden: Never build a physics-based real-time football simulation for MVP.
- Guardrail: Full match simulation <20ms compute time target from ADR.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/match-competition-system.md`, scoped to this story:*

- [ ] `key_event_count` stays within `3..15` for every completed match.
- [ ] Six event categories are reachable: `offensive_push`, `shot_on_goal`, `goal_scored`, `key_defense`, `tactical_adaptation`, `stamina_decline`.
- [ ] Every event has category, minute, side, and narrative tags; low-event matches still provide at least 3 readable events and a slow-pace explanation.

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

Generate match events as typed serializable Dictionaries or typed event objects convertible to Dictionaries. Each event must contain category, minute, half/side identity, involved player ids where available, narrative tags, and modifier flags. The event pipeline should be deterministic under seeded RNG and should not depend on rendering or physics simulation.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: Result packet aggregation and win-reason analysis.
- Presentation UI rendering of the event timeline.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: `key_event_count` 始终在 3..15
  - Given: 覆盖低、中、高事件密度的多组固定比赛输入与种子。
  - When: 生成关键事件列表。
  - Then: 每场比赛的 `key_event_count` 都满足 `3 <= count <= 15`。
  - Edge cases: 极低节奏比赛；极高攻势比赛；平局与大比分比赛都不得越界。

- **AC-2**: 六类事件都可达且结构完整（`category/minute/side/tags`）
  - Given: 一组足以覆盖六类事件的测试样本集合。
  - When: 汇总所有样本输出的关键事件。
  - Then: 六类事件都至少出现一次，且每条事件都包含非空 `category`、合法 `minute`、合法 `side`、可解析 `tags`。
  - Edge cases: 补时分钟；同分钟多事件；`side` 必须仅归属合法参赛方。

- **AC-3**: 即使低事件密度比赛也至少输出 3 个可读事件并能解释沉闷原因
  - Given: 一场低事件密度、低攻防波动的沉闷比赛输入。
  - When: 生成关键事件摘要。
  - Then: 输出至少 3 个可读事件，且其中包含可解释沉闷原因的标签或描述线索。
  - Edge cases: 0:0 平局；仅少量射门/犯规；沉闷原因不可用空事件或占位文本代替。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/match/key_event_generation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/match-competition-system/story-003-actual-win-probability.md` — must be DONE
- Unlocks:
  - `production/epics/match-competition-system/story-005-halftime-adjustment.md`
  - `production/epics/match-competition-system/story-006-match-result-packet.md`
  - `production/epics/match-competition-system/story-007-match-rng-determinism.md`
