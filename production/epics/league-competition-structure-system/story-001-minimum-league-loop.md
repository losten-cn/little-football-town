# Story 001: 建立 Minimum League Loop

> **Epic**: 联赛与赛事结构系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-06-03
> **Last Updated**: 2026-06-03

## Context

**GDD**: `design/gdd/league-competition-structure-system.md`  
**Requirement**: `TR-league-002`, `TR-league-003`, `TR-league-006`, `TR-league-007`, `TR-league-010`, `TR-league-011`, `TR-league-014`  
**ADR Governing Implementation**: ADR-0009: League Competition Structure  
**Cross-ADR Constraints**: ADR-0002, ADR-0003, ADR-0006, ADR-0010

This story is topology L0. It establishes the minimum league authority needed before MainLoopUI and MatchPerfUI can safely show next match, standings, round, and post-match league impact.

## Scope

### In Scope

- Bootstrap one active league season from config using an even `team_count` in the MVP range `8–12`.
- Generate a fixed double round-robin schedule where every team plays `2 × (team_count - 1)` matches.
- Maintain typed runtime state for scheduled matches, standings entries, and league season status.
- Consume existing `match_completed` payloads using `match_id + MatchResultPacket` as read-only input.
- Update both teams' standings from confirmed results.
- Reject duplicate result application for an already completed `match_id`.
- Advance league season state through `PRE_SEASON → IN_PROGRESS → SETTLEMENT → COMPLETED`.
- Finalize season state on `time_season_ended` without adding a league-owned season clock.
- Define league serialize / deserialize data compatible with the existing SaveManager registration and restore order.
- Expose minimum read-only query surface for next match, standings, current round, and season summary.

## Acceptance Criteria

- [ ] Given an even MVP `team_count` from 8 to 12, active season bootstrap creates a fixed double round-robin schedule where every pairing appears twice with reversed home/away sides.
- [ ] League season state transitions follow `PRE_SEASON → IN_PROGRESS → SETTLEMENT → COMPLETED` without bypassing TimeManager season authority.
- [ ] When a confirmed `match_completed` payload arrives, LeagueStructure correlates `match_id` to exactly one scheduled match, marks it completed once, and updates played / wins / draws / losses / goals_for / goals_against / goal_difference / points for both teams.
- [ ] Standings settlement uses `win=3`, `draw=1`, `loss=0` and derives only from the confirmed match result.
- [ ] Re-submitting the same completed `match_id` is an idempotent no-op and cannot double-apply standings, progress, or season side effects.
- [ ] League consumes the existing `MatchResultPacket` as read-only input and does not redefine packet fields, names, or downstream semantics.
- [ ] League-emitted payloads and durable snapshot data are top-level shallow typed dictionaries containing only serializable scalars and shallow record arrays.
- [ ] On `time_season_ended`, the active season finalizes once and exposes final standings, promotion/relegation outcome tags, and `next_tier` intent for downstream consumers.
- [ ] League authority state roundtrips through save/load in the existing restore order without replaying completed matches or duplicate settlement.

## Test Evidence

**Story Type**: Integration  
**Required evidence**:
- Integration: `tests/integration/league/minimum_league_loop_test.gd`

**Status**: [x] Passing — `MINIMUM_LEAGUE_LOOP_TEST_PASS` via Godot 4.6.2 console

Minimum test chain:
- season bootstrap schedule shape
- match result → standings update
- duplicate `match_id` no-op
- `time_season_ended` finalization
- save/load restore with completed match flags and standings preserved

## Dependencies

- Depends on:
  - `production/epics/match-competition-system/story-006-match-result-packet.md` — complete
  - `production/epics/match-competition-system/story-008-match-restore-dedup.md` — complete
  - `production/epics/time-and-season-progression-system/story-005-season-progress-flow.md` — complete
  - `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md` — complete
  - `production/epics/save-and-load-system/story-002-save-registration-snapshot.md` — complete
  - `production/epics/save-and-load-system/story-007-load-restore-order.md` — complete
- Unlocks:
  - `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
  - `production/epics/match-performance-ui/story-001-prematch-result-flow.md`
  - later economy, reputation, and standings UI consumers

## Out of Scope

- Redefining or versioning `MatchResultPacket`.
- Finalizing a full `match_context` contract beyond agreed minimum scalar correlation fields.
- Full standings UI, schedule UI, or Career Review presentation.
- Economy reward amounts or transaction ownership.
- Full promotion/relegation depth, season history retention, and detailed tie-break display.
- Match-owned forfeit generation logic.

## Implementation Notes

- Keep LeagueStructure as the single writer for standings and season state.
- Use scheduled-match completion state as the first duplicate-result barrier.
- Treat `time_season_ended` as the only season-finalization trigger for this story.
- Sort schedule and standings arrays explicitly before emitting them to downstream consumers.
- Normalize all EventBus and save payloads into typed shallow dictionary shapes before crossing system boundaries.
- If a temporary match-launch context is needed before full contract closure, keep it scalar-only and additive; do not freeze richer semantics here.

## Warnings Carried Forward

- **BLOCKER**: League save registration is not closed until serialize / deserialize is verified through SaveManager.
- **BLOCKER**: `match_context` is not finalized; this story must not invent a parallel context schema.
- **BLOCKER**: `MatchResultPacket` must remain upstream truth and read-only input.
- **BLOCKER**: typed shallow payload and duplicate-result/dedup boundaries cannot be weakened.
- Full promotion/relegation depth, season history, standings presentation, and economy season rewards remain later work.
