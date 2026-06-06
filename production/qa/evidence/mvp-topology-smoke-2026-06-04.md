# MVP Topology Smoke — 2026-06-04

> Scope: L0 LeagueStructure → L1 MainLoopShell → L2 PlayerMgmtUI / MatchPerfUI → L3 WhatNextGuidance
> Result: PASS WITH WARNINGS

## Automated Smoke Commands

All commands used Godot 4.6.2 console:

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/what_next_guidance_test.gd
```

```text
WHAT_NEXT_GUIDANCE_TEST_PASS
```

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

```text
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
```

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/main_loop_shell_navigation_test.gd
```

```text
MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS
```

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/league/minimum_league_loop_test.gd
```

```text
MINIMUM_LEAGUE_LOOP_TEST_PASS
```

## Review Inputs

- QA smoke review: no new blockers; current hard gate is the four-test smoke sweep passing on the candidate build.
- GDScript static review: no parse/type blockers; one implementation-risk warning was fixed before final smoke rerun.

## Fix Applied During Smoke

- `src/ui/match/match_perf_panel.gd` now consumes system/navigation affordance payloads through `set_system_payload()` before enabling `PreMatchStartButton`.
- `src/ui/hud/main_loop_shell.gd` forwards `system_state_changed` payloads to MatchPerfPanel.
- `tests/integration/ui/l2_playable_loop_panels_test.gd` now asserts system-disabled pre-match start stays on `match_pre`.

## Remaining Warnings

- Roster full sort/filter depth remains deferred.
- Match Live/Halftime guidance and command depth remain deferred.
- `team_match_strength` labels, league impact delta, final PlayerDevelopment UI read model, onboarding persistence/cooldowns/replay/analytics, full localization key coverage, and anchor registry remain deferred.

## Manual Smoke Recommendation

Before playtest handoff, run one 5-minute manual route sanity check:

`Home → Roster → Player Detail → Training → Home → Match Pre → Match Live → Match Result → Home`

Pass if there are no blank pages, wrong routes, blocking modals, or missing disabled-state text.
