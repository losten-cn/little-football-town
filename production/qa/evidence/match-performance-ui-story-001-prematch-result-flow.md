# Match Performance UI Story 001 — Pre-Match / Result Flow Evidence

> Date: 2026-06-04
> Story: `production/epics/match-performance-ui/story-001-prematch-result-flow.md`
> Evidence type: UI interaction smoke + manual walkthrough notes

## Automated Smoke

Command:

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

Result:

```text
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
```

Coverage:

- `MatchPerfPanel` mounts inside `MainLoopShell.shell_main_content`.
- `match_pre` exposes `PreMatchStartButton` and starts only from authoritative `match_trigger_reached` + `match_center_available` payload flags.
- Start requests `match_live` without changing match state directly.
- `match_live` exposes `LiveTimeline`, `LiveExitWarning`, and `HalftimeAdjustButton`.
- `match_event_occurred` appends authoritative timeline text.
- `match_completed` routes to `match_result` and displays the authoritative result packet.
- `league_standings_updated` feeds `LeagueImpactSummary`.
- `ResultConfirmButton` emits `match_result_confirmed`, and the shell returns to Home.

## Manual Walkthrough Notes

- The current slice proves the page chain: Home / match CTA → match_pre → match_live → match_result → Home.
- Pre-match shows opponent, round, home/away, ranking, lineup, and tactical summaries when supplied by payload.
- Live view prioritizes score/time/half/timeline readability and keeps a visible exit warning.
- Result view displays final score, result, reason, player performance summary, league impact, and confirmation.

## Warnings Carried

- Complete lineup/fallback package, `team_match_strength` display labels, and player performance read model are not fully frozen; the panel shows supplied authoritative fields and otherwise uses low-noise `待同步` placeholders.
- League impact delta is not locally derived; only the authoritative `league_standings_updated` summary is displayed.
- Halftime adjustment remains an exposed disabled placeholder until the MatchCompetition halftime adjustment story provides the command contract.
