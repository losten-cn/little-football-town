# Story 001: 实现 Minimum What-to-Do-Next Guidance

> **Epic**: 新手引导系统
> **Status**: Complete with warnings
> **Layer**: Polish
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-06-03
> **Last Updated**: 2026-06-03

## Context

**GDD**: `design/gdd/onboarding-system.md`  
**Requirement**: `TR-onboard-001`, `TR-onboard-002`, `TR-onboard-003`, `TR-onboard-005`, `TR-onboard-009`, `TR-onboard-010`

This story is topology L3. It starts only after MainLoopUI, PlayerMgmtUI, and MatchPerfUI expose stable anchors for Home, Roster/Training, Pre-Match, and Result.

`TR-onboard-001` is only partially covered here: this story covers `Home → Roster/Training → Pre-Match → Result → Home`, not Match Live or Halftime guidance.

## Scope

### In Scope

- Provide one current checkpoint hint at a time.
- Add minimum guidance for:
  - Home
  - Roster
  - Training
  - Pre-Match
  - Result
  - Return Home closure
- Allow both `Home → Roster → Training` and `Home → Training` paths.
- Use non-modal highlight or short text-only fallback.
- Let players dismiss or ignore guidance without blocking legal actions.
- End current-wave guidance after player returns Home from Match Result.

## Acceptance Criteria

- [ ] First visible Home checkpoint shows a non-modal next-step cue with core copy ≤ 25 characters.
- [ ] Home guidance only answers where to go next and does not teach the full HUD or future systems.
- [ ] If the player enters Roster first, guidance follows to Roster and points toward Training.
- [ ] If the player goes directly to Training, guidance does not require visiting Roster first.
- [ ] Roster/Training guidance covers one minimum training loop only and does not explain sorting, formulas, ROI, or full player details.
- [ ] After one legal training completion, guidance advances toward Pre-Match.
- [ ] Pre-Match guidance points to starting the match without expanding into tactics, skill snapshots, or league stakes.
- [ ] Result guidance points to reading the result and returning Home.
- [ ] Completing or dismissing a checkpoint advances or exits guidance without modal blocking or forced navigation.
- [ ] Missing anchors fall back to text-only guidance without bad highlights, blank boxes, or flow blocking.
- [ ] All highlight references use stable IDs exported by UI owners; this story does not create a separate anchor registry.
- [ ] A first-time QA player can complete `Home → Roster/Training → Match → Result → Home` in 5 minutes without external explanation.

## Test Evidence

**Story Type**: UI  
**Required evidence**:
- Manual walkthrough: `production/qa/evidence/onboarding-system-story-001-minimum-what-next-guidance.md`

**Status**: [x] Created — `WHAT_NEXT_GUIDANCE_TEST_PASS`

Walkthrough covers Home cue, Home→Roster→Training, Home→Training direct path, Pre-Match cue, Result cue, return Home, and a text-only fallback sample.

## Dependencies

- Depends on:
  - `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
  - `production/epics/player-management-ui/story-001-roster-training-entry.md`
  - `production/epics/match-performance-ui/story-001-prematch-result-flow.md`

Stable anchors required:
- Home anchor — MainLoopUI
- Roster/Training anchors — PlayerMgmtUI
- Pre-Match anchor — MatchPerfUI
- Result anchor — MatchPerfUI

## Out of Scope

- Full Tutorial/Hint system.
- hint eligibility, `hint_record_key`, cooldown, shared anchor registry.
- seen/preferences/onboarding_done persistence.
- Match Live / Halftime guidance.
- Help index, tutorial replay, analytics, personalized hint frequency.
- Rules teaching for training, tactics, facilities, skill/trait, or league stakes.

## Implementation Notes

- Use a single-current-hint model.
- Guidance follows player context rather than forcing one route.
- Suggested copy style: friendly, action-oriented, 12–18 Chinese characters when possible.
- Text-only fallback should be placed in a safe non-blocking area.
- Do not introduce new rule authority, recommendation algorithms, or hint dedup systems.

## Warnings Carried Forward

- `TR-onboard-001` remains partial; Match Live and Halftime guidance are deferred.
- No onboarding persistence is included in this wave.
- Anchor stability depends on upstream UI owners.
- Full Tutorial/Hint, `hint_record_key`, cooldown, and seen/preferences persistence remain explicitly deferred.
