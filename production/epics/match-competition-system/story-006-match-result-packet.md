# Story 006: 实现 MatchResultPacket、胜负原因与赛后标签

> **Epic**: 比赛竞技系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/match-competition-system.md`
**Requirement**: `TR-match-008`, `TR-match-010`, `TR-match-011`, `TR-match-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-match-008`: Standardized MatchResultPacket consumed by LeagueStructure, EconomyManager, TimeManager, MatchPerfUI
- `TR-match-010`: 5 win_reason categories for post-match analysis
- `TR-match-011`: post_match_growth_tag: 5 discrete labels
- `TR-match-012`: match_id in match_completed event for LeagueStructure correlation

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0006: Match Simulation Architecture
**ADR Decision Summary**: MatchSimulation finalizes a standardized MatchResultPacket consumed by LeagueStructure, EconomyManager, TimeManager, and Match Performance UI.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state machine and Dictionary math; no post-cutoff APIs used.

**Control Manifest Rules (this layer)**:
- Required: Produce a standardized `MatchResultPacket` consumed by League, Economy, UI, and Time systems.
- Required: Event payloads must be typed `Dictionary` values containing only serializable primitives or typed `Array[Dictionary]` data.
- Guardrail: Stored match result history ~400KB target for ~200 matches.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/match-competition-system.md`, scoped to this story:*

- [ ] Final result packet contains result, score, key event summary, player appearances, condition/morale changes, win reasons, post-match growth tags, and `match_id`.
- [ ] Win reasons cover the defined post-match analysis categories where reachable.
- [ ] Every appearing player receives minutes played and a legal `post_match_growth_tag`; very short appearances may receive `无`.

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

Create a serializable MatchResultPacket with score, result, event list or summary, player performance entries, condition/morale changes, top win reasons, match stats, post-match tags, and `match_id`. Emit `match_completed` with the packet as a typed Dictionary once settlement handoff is reached. Keep all payload data primitive/Dictionary/Array-based for downstream systems and save/load compatibility.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: Full downstream consumption smoke and performance regression.
- League, Economy, or PlayerDevelopment internals that consume this packet.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 终场结果包至少包含胜平负、比分、关键事件摘要、球员出场摘要、`condition/morale changes`、`win_reasons`、`post_match_growth_tag`、`match_id`
  - Given: 一场完整比赛已结束并生成 `MatchResultPacket`。
  - When: 检查结果包结构与字段内容。
  - Then: 上述字段全部存在且可解析；`match_id` 唯一；比分与胜平负一致；关键事件与球员摘要非空且对应本场比赛。
  - Edge cases: 平局；无换人；低事件密度比赛；短时间出场球员也必须出现在球员摘要中。

- **AC-2**: `win_reasons` 至少能覆盖 5 类复盘原因中的可达集合
  - Given: 准备能触发不同胜负叙事的样本比赛集合。
  - When: 汇总各场比赛的 `win_reasons`。
  - Then: 可达的复盘原因类型在集合层面至少覆盖 5 类，且每场只输出与该场过程一致的原因。
  - Edge cases: 平局应输出平局语义下的原因集合；多原因并存时不得互相矛盾；沉闷比赛也应有可解释原因。

- **AC-3**: 每名出场球员都获得 `post_match_growth_tag` 和上场时间；短出场允许 `tag=无`
  - Given: 一场包含首发、替补、极短时间替补出场的比赛结果。
  - When: 检查球员出场摘要。
  - Then: 每名实际出场球员都有合法上场时间与 `post_match_growth_tag`；极短出场球员允许 `tag=无`，未出场球员不得被标记为已出场。
  - Edge cases: 90+ 分钟补时登场；整场未换人；伤停前后出场时间汇总必须正确。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/match/match_result_packet_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/match-competition-system/story-002-team-strength-aggregation.md` — must be DONE
  - `production/epics/match-competition-system/story-004-key-event-generation.md` — must be DONE
  - `production/epics/match-competition-system/story-005-halftime-adjustment.md` — must be DONE
- Unlocks:
  - `production/epics/match-competition-system/story-008-match-restore-dedup.md`
  - `production/epics/match-competition-system/story-009-match-loop-regression.md`
