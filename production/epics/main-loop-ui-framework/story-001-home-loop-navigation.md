# Story 001: 建立 Home Shell 与主循环导航骨架

> **Epic**: 主循环 UI 框架
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-06-03
> **Last Updated**: 2026-06-03

## Context

**GDD**: `design/gdd/main-loop-ui-framework.md`  
**Requirement**: `TR-mainui-001`, `TR-mainui-004`, `TR-mainui-005`, `TR-mainui-006`, `TR-mainui-007`

This story is topology L1. It freezes the shell, route, and return-path contract that PlayerMgmtUI and MatchPerfUI use in parallel.

## Scope

### In Scope

- Implement a unified shell container: `shell_top_bar`, `shell_main_content`, `shell_bottom_bar`.
- Freeze route IDs: `home`, `roster`, `player_detail`, `training`, `match_pre`, `match_live`, `match_result`.
- Implement Home summaries for date/phase, next match, team overview, available action windows, funds, and AP.
- Implement Home entry points for roster, training, and match.
- Show disable reasons when an entry is unavailable.
- Return to Home after roster/training cancel and match result confirmation.
- Refresh Home after `time_advanced`, `system_state_changed`, or `player_action_completed`.
- Keep major screen transitions within 150–400ms.

## Acceptance Criteria

- [ ] `home`, `roster`, `training`, `match_pre`, `match_live`, and `match_result` all run inside one consistent top/main/bottom shell.
- [ ] From Home, the deepest current-wave path does not exceed depth 3.
- [ ] Training and match entries use authoritative `system_state_allows + navigation_context_allows` and show explicit disable reasons.
- [ ] When `match_trigger_reached = true`, match entry becomes the primary CTA until the match is completed.
- [ ] Home refreshes date/phase, next match, team overview, action windows, funds, and AP after time advancement, system state change, or player action completion.
- [ ] Roster/training cancel returns to Home without creating a parallel navigation stack.
- [ ] Match Result confirmation returns to Home and shows updated post-match authoritative summaries.
- [ ] Screen transitions stay within 150–400ms and avoid blank/black loading screens.
- [ ] PlayerMgmtUI and MatchPerfUI mount only into the frozen shell/route contract.
- [ ] Shell and Home consume authoritative payloads only and do not recompute roster, training, economy, league, or match truth.

## Test Evidence

**Story Type**: UI  
**Required evidence**:
- Manual walkthrough: `production/qa/evidence/main-loop-ui-framework-story-001-home-loop-navigation.md`

**Status**: [x] Created and backed by `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`

Walkthrough covers Home shell, Roster/Training placeholders, Match Pre/Live/Result placeholders, Match Result confirmation returning Home, disable reason behavior, and L0 League regression evidence.

## Dependencies

- Depends on:
  - `production/epics/league-competition-structure-system/story-001-minimum-league-loop.md` — contract freeze required
  - `production/epics/time-and-season-progression-system/story-003-match-trigger.md`
  - `production/epics/time-and-season-progression-system/story-009-time-status-regression.md`
  - `production/epics/match-competition-system/story-006-match-result-packet.md`
- Unlocks:
  - `production/epics/player-management-ui/story-001-roster-training-entry.md`
  - `production/epics/match-performance-ui/story-001-prematch-result-flow.md`
  - `production/epics/onboarding-system/story-001-minimum-what-next-guidance.md`

## Out of Scope

- Full HUD, deep schedule, complete settings, audio polish, full tutorial/help stack.
- Player detail content, match live/result content, training formula displays.
- New gameplay payloads or business-rule recomputation.

## Implementation Notes

- Freeze route and anchor contracts before L2 page work starts.
- `shell_main_content` is the only L2 page mount area.
- If League next-match data is not frozen, keep this story queued rather than guessing standings or round truth in UI.
- Placeholder art is acceptable; prioritize hierarchy, route clarity, and return-path reliability.

## Warnings Carried Forward

- Do not expand this story into full HUD or deep schedule.
- Do not recompute authoritative payloads in the shell.
- L2 UI packages may proceed in parallel only after this route/container contract is stable.
