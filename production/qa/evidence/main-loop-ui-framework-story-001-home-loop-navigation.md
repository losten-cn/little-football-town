# MainLoop UI Story 001 — Home Loop Navigation Evidence

> Date: 2026-06-03
> Story: `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
> Evidence type: UI interaction smoke + manual walkthrough notes

## Automated Smoke

Command:

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/main_loop_shell_navigation_test.gd
```

Result:

```text
MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS
```

Coverage:

- Frozen route IDs: `home`, `roster`, `player_detail`, `training`, `match_pre`, `match_live`, `match_result`.
- Single `shell_main_content` mount exposed by `MainLoopShell`.
- `screen_requested` routes mount inside the shell.
- Current-wave route depth remains within 3.
- `match_result_confirmed` returns to Home and resets the stack.
- Match CTA uses authoritative `system_state_allows_match` / `navigation_context_allows_match` disable reason payloads.

## Manual Walkthrough Notes

- Home shell starts at `home` with persistent top bar, main content mount, and bottom navigation.
- Roster and Training routes currently mount L1 placeholders into `shell_main_content`; L2 PlayerMgmtUI owns final content.
- Match Pre / Match Live / Match Result routes currently mount L1 placeholders into `shell_main_content`; L2 MatchPerfUI owns final content.
- Match Result confirmation path is represented by `match_result_confirmed` and returns to Home without retaining a parallel stack.
- Full visual polish, screenshots, and content-rich L2 pages remain out of scope for this L1 route/container story.

## Regression

League L0 contract was rerun after L1 shell changes:

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/league/minimum_league_loop_test.gd
```

Result:

```text
MINIMUM_LEAGUE_LOOP_TEST_PASS
```
