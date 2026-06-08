# MVP Playtest Result — 2026-06-06

> Scope: Current MVP vertical slice only
> Status: AUTOMATED VISUAL WALKTHROUGH PASS WITH WARNINGS
> Timebox: 5 minutes per player
> Note: This records a historical automated route-and-screenshot report. The earlier human-playtest requirement is now covered by the current AI surrogate validation rule.

## Purpose

Record the MVP playtest result for the frozen route:

`Home → Roster → Player Detail → Training → Home → Match Pre → Match Live → Match Result → Home`

Treat this file as automated route-and-screenshot evidence for the historical route check. Under the current policy, follow-up AI surrogate validation closes the prior clarity/readability validation gap without claiming an external-human playtest occurred.

## Automated Visual Walkthrough

Command:

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --path "E:/code/little-football-town" --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd
```

Result marker:

```text
MVP_VISUAL_WALKTHROUGH_PASS
```

Output directory:

`C:/Users/kylin/AppData/Roaming/Godot/app_userdata/Football Town/mvp_visual_walkthrough`

## Screenshots Reviewed

| Step | Screenshot | Expected | Result | Notes |
|---|---|---|---|---|
| 01 | `01_home_initial.png` | Home initial | PASS | Home state, roster/training CTA, and guidance visible. |
| 02 | `02_roster.png` | Roster | PASS | Roster list and return Home action visible. |
| 03 | `03_player_detail.png` | Player Detail | PASS | Player detail, training entry, and return Home action visible. |
| 04 | `04_training.png` | Training | PASS | Training option, confirm action, and route context visible. |
| 05 | `05_training_result.png` | Training Result | PASS | Training completion text and return Home action visible. |
| 06 | `06_home_after_training.png` | Home after training | PASS | Updated team status and next match guidance visible. |
| 07 | `07_home_match_disabled_reason.png` | Home disabled match reason | PASS | Match entry state and disabled/legality reason visible. |
| 08 | `08_match_pre.png` | Match Pre | PASS | Opponent, round, lineup/tactic summary, and start match action visible. |
| 09 | `09_match_live_empty.png` | Match Live initial | PASS | Live match screen, exit warning, and key state visible. |
| 10 | `10_match_live_timeline.png` | Match Live timeline | PASS | Timeline events and halftime placeholder visible. |
| 11 | `11_match_result.png` | Match Result | PASS | Final score, result reason, player performance, league impact, and confirm action visible. |
| 12 | `12_home_final.png` | Home final | PASS | Final Home state is visible and interactive. |


## Evidence Entering Playtest

- `production/qa/evidence/ui-readiness-sprint-1.md` — READY WITH WARNINGS.
- `production/qa/evidence/mvp-playtest-handoff-2026-06-05.md` — READY WITH WARNINGS handoff.
- `production/qa/evidence/mvp-route-sanity-2026-06-05.md` — PASS WITH WARNINGS.
- `production/qa/evidence/mvp-visual-walkthrough-2026-06-05.md` — PASS.
- `L2_PLAYABLE_LOOP_PANELS_TEST_PASS` — Player/Match UI route sanity passed.
- `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS` — Main loop navigation sanity passed.

## Test Script

Observer instruction: do not explain the route unless the player is blocked for more than 30 seconds. Record blockers only; non-blocking friction remains a warning.

### 0:00–2:00 — Player Management Route

Expected route:

`Home → Roster → Player Detail → Training → Home`

Observe:

- Can the player find the roster/player path from Home?
- Can the player reach a player detail view?
- Can the player enter Training and understand that one training resolution occurred?
- Can the player return Home without help?

### 2:00–4:30 — Match Route

Expected route:

`Home → Match Pre → Match Live → Match Result → Home`

Observe:

- Can the player find the match entry from Home?
- If match start is disabled, is the disabled-state reason visible?
- If match start is allowed, can the player reach Match Live?
- Can the player reach Match Result and confirm back to Home?

### 4:30–5:00 — Home Continuation Check

After returning Home, ask the player what they think they would do next.

Observe:

- Is Home still interactive?
- Does the player understand the loop can continue?
- Are they blocked by a modal, blank state, or missing CTA?

## Result

| Field | Value |
|---|---|
| Tester | Automated runner |
| Observer | Claude visual screenshot review |
| Start time | 2026-06-06 automated session |
| End time | 2026-06-06 automated session |
| Completed within 5 minutes | Route completed by runner |
| Developer explanation needed | Not applicable to automation |
| Blockers found | 0 |
| Verdict | PASS WITH WARNINGS for automated visual walkthrough; follow-up AI surrogate validation closes the prior clarity/readability validation gap under current policy |

## Blocker Criteria

Any one of these is a blocker:

- Crash, freeze, black screen, or soft lock.
- Blank page or missing mounted panel.
- Wrong route after a major button/request event.
- Route cannot proceed or cannot return Home.
- Blocking modal prevents route progress.
- Required disabled-state text is missing.
- Authoritative match gate is ignored or incorrectly blocks a valid start.
- Training, match start, result confirmation, or Home return fails due to payload handoff.
- Player needs developer explanation to find the next critical step.

## Observed Notes

- The automated route completed and printed `MVP_VISUAL_WALKTHROUGH_PASS`.
- All 12 screenshots were non-blank and showed the expected route/page content.
- No wrong route, blocking modal, missing mounted panel, missing disabled-state text, or failed Home return was observed.
- Visual layout remains placeholder/minimal and should carry forward as polish warning rather than blocking this topology wave.

## Warnings Carried Forward

Do not fix these during this playtest result pass unless they become blockers:

- Roster sorting/filtering depth.
- Match Live/Halftime command depth.
- League impact polish.
- Final PlayerDevelopment UI read model polish.
- Full localization key coverage.
- Onboarding persistence, cooldowns, replay, analytics, and anchor registry.
- Minor layout, copy, or feedback polish that does not stop route completion.

## Production Decision After Playtest

- If blockers are found: open one smallest possible topology hotfix slice and fix only the route-breaking issue.
- If no blockers are found: freeze the MVP topology wave and move to L5 gate/readiness with warnings carried forward.
