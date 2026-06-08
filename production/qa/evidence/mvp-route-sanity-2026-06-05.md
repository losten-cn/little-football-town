# MVP Route Sanity Gate — 2026-06-05

> Scope: Home → Roster → Player Detail → Training → Home and Home → Match Pre → Match Live → Match Result → Home
> Result: PASS WITH WARNINGS

## Gate Intent

This sanity gate checks only implementation-breaking blockers for the current MVP vertical slice. Polish, feature depth, localization, analytics, and future onboarding depth remain warnings unless they break the route loop.

## A Route — Player Management Loop

Route: `Home → Roster → Player Detail → Training → Home`

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

Pass marker:

```text
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
```

Result: PASS — no route-breaking issue was detected by the current headless coverage for roster/detail/training/home flow.

## B Route — Match Loop

Route: `Home → Match Pre → Match Live → Match Result → Home`

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/main_loop_shell_navigation_test.gd
```

Pass marker:

```text
MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS
```

Result: PASS — no route-breaking issue was detected by the current headless coverage for match pre/live/result/home navigation and disabled gate behavior.

## Blocker Criteria Checked

Fail this gate if any of these appear during manual or automated sanity:

- Blank page or missing mounted panel.
- Wrong route after a button/request event.
- Blocking modal prevents route progress.
- Required disabled-state text is missing.
- Authoritative match gate is ignored or incorrectly blocks a valid start.
- Payload handoff prevents training, match start, result confirmation, or return Home.
- Result confirmation cannot return to Home.

Current blocker count: 0.

## Warnings Carried Forward

- Roster sorting/filtering depth remains deferred.
- Match Live/Halftime command depth remains deferred.
- League impact polish and final PlayerDevelopment UI read model remain deferred.
- Full localization key coverage remains deferred.
- Onboarding persistence, cooldowns, replay, analytics, and anchor registry remain deferred.

## Verdict

PASS WITH WARNINGS — the current topology wave is ready for vertical-slice playtest handoff; the historical recommendation for one short human-observed route sanity pass on the same A/B paths is superseded by the current AI surrogate validation policy.
