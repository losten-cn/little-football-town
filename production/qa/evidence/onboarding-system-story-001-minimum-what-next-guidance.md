# Onboarding System Story 001 — Minimum What-to-Do-Next Guidance Evidence

> Date: 2026-06-04
> Story: `production/epics/onboarding-system/story-001-minimum-what-next-guidance.md`
> Evidence type: UI interaction smoke + manual walkthrough notes

## Automated Smoke

Command:

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/what_next_guidance_test.gd
```

Result:

```text
WHAT_NEXT_GUIDANCE_TEST_PASS
```

Coverage:

- `WhatNextGuidance` mounts inside `MainLoopShell` as a non-modal banner.
- Home first cue is `先看看球员` and stays under 25 characters.
- Roster route advances to a single current cue pointing toward selecting a player.
- Direct Training route works without requiring a Roster visit first.
- `training_completed` advances guidance toward Pre-Match.
- `time_advanced.match_trigger_reached` / `match_center_available` drive the Pre-Match copy.
- `match_completed` advances guidance to Result.
- `match_result_confirmed` ends and hides the current-wave guidance.
- Missing anchors fall back to text-only copy instead of blank or blocking UI.

## Regression Chain

```text
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS
MINIMUM_LEAGUE_LOOP_TEST_PASS
```

## Manual Walkthrough Notes

- Home: player sees one friendly next-step cue, not a full tutorial.
- Roster / Player Detail / Training: guidance only points toward one minimum training action.
- Training completion: guidance advances toward the match entry path.
- Pre-Match: guidance points to starting the match when the authoritative match trigger is available, otherwise it says to wait.
- Result: guidance points to reading the result and returning Home.
- Return Home after result confirmation hides current-wave guidance.
- Text-only fallback sample is covered by `set_anchor_available(false)`.

## Warnings Carried

- `TR-onboard-001` remains partial: Match Live and Halftime guidance are deferred.
- No persistence, hint cooldown, replay, analytics, or anchor registry is included in this wave.
- UI text is currently script fallback copy; full localization key coverage remains a later localization pass.
