# Story 001: 建立赛前到赛后的最小比赛展示流

> **Epic**: 比赛表现 UI
> **Status**: Complete with warnings
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-06-03
> **Last Updated**: 2026-06-03

## Context

**GDD**: `design/gdd/match-performance-ui.md`  
**Requirement**: `TR-matchui-001`, `TR-matchui-002`, `TR-matchui-003`, `TR-matchui-004`, `TR-matchui-007`, `TR-matchui-009`, `TR-matchui-010`, `TR-matchui-011`

This story is a topology L2 page package. It depends on MainLoop Shell route/container freeze and final wiring depends on League next-match / standings / impact contract freeze.

## Scope

### In Scope

- Implement `match_pre`, `match_live`, and `match_result` pages inside MainLoop Shell.
- `match_pre` shows opponent, home/away, round, ranking summary, authoritative lineup summary, tactical summary/minimum choice, and start confirmation.
- `match_live` shows score, match time, half indicator, key event timeline, halftime separator, halftime adjustment entry, and live exit warning.
- `match_result` shows final score, win/loss reason, key event review, player performance summary, league impact, and confirm-return-Home action.
- Expose stable anchors for pre-match confirm, live timeline, exit warning, halftime adjust, and result confirm.

## Acceptance Criteria

- [ ] `match_pre`, `match_live`, and `match_result` all run inside the MainLoop Shell.
- [ ] Pre-match shows opponent, home/away, round, ranking summary, authoritative lineup summary, tactical summary/minimum choice, and start confirmation.
- [ ] Opponent strength is displayed as readable labels derived from authoritative `team_match_strength` without UI recomputation.
- [ ] Start button state is driven by authoritative `match_trigger_reached` and lineup/fallback payloads.
- [ ] Live view shows score, time, half indicator, and key event timeline.
- [ ] Attempting to leave during live match shows a clear warning and does not silently exit.
- [ ] Halftime shows a clear separator and adjustment entry.
- [ ] A 0-0 halftime still shows summary and adjustment entry.
- [ ] Result view appears in fixed order: final score → reason → key events → player performance → league impact → confirm button.
- [ ] Confirming result returns to Home and Home shows updated authoritative summary.
- [ ] UI consumes only authoritative events, result packet, league impact, and lineup/fallback payloads; it does not recompute score, events, player scores, ranking, funds, or AP.
- [ ] A first-time QA player can explain what happened, why, and that the match is complete after one full flow.

## Test Evidence

**Story Type**: UI  
**Required evidence**:
- Manual walkthrough: `production/qa/evidence/match-performance-ui-story-001-prematch-result-flow.md`

**Status**: [x] Created — `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`

Walkthrough covers match_pre, match_live, timeline / halftime adjustment anchor, match_result, league impact summary, and return to Home, with warnings for unresolved upstream lineup/strength/delta payload depth.

## Dependencies

- Depends on:
  - `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
  - `production/epics/league-competition-structure-system/story-001-minimum-league-loop.md` — contract freeze for next match / standings / league impact
  - `production/epics/match-competition-system/story-001-match-state-flow.md`
  - `production/epics/match-competition-system/story-005-halftime-adjustment.md`
  - `production/epics/match-competition-system/story-006-match-result-packet.md`
  - `production/epics/time-and-season-progression-system/story-003-match-trigger.md`
- Parallel with:
  - `production/epics/player-management-ui/story-001-roster-training-entry.md`

## Out of Scope

- Full HUD, animated match scene, deep stats, commentary, audio polish.
- Deep roster editor, full tactical workbench, complete schedule/standings UI.
- Skill/Trait explanation and full post-match analysis.
- UI-local recomputation of lineup legality, match result, player score, ranking, funds, or AP.

## Implementation Notes

- Pre-match should focus on understanding and confirmation, not full tactical depth.
- Live view prioritizes score, phase, and event readability over animation polish.
- Halftime adjustment may be a subview but must not create a new global navigation stack.
- Result view is a closure screen: explain, confirm, return Home.
- If League impact data is not frozen, keep that section behind a planned dependency rather than guessing standings locally.

## Warnings Carried Forward

- Do not expand this story into full match HUD or data dashboard.
- Do not modify `match_context`, `match_result_packet`, or `pre_match_skill_trait_snapshot`.
- All business display must consume authoritative payloads only.
