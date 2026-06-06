# Player Management UI Story 001 — Roster / Training Entry Evidence

> Date: 2026-06-04
> Story: `production/epics/player-management-ui/story-001-roster-training-entry.md`
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

- `PlayerMgmtPanel` mounts inside `MainLoopShell.shell_main_content`.
- `roster` route exposes `RosterList` and roster row stable IDs.
- Roster rows sort by authoritative `rating` descending in the smoke payload.
- Clicking a roster row requests `player_detail` without mutating player state.
- `player_detail` exposes `PlayerDetailSummary` and a training entry button.
- Training entry requests `training` and exposes `TrainingOptionList` / `TrainingConfirmButton`.
- Panel consumes `roster_updated` and `training_options_updated` payloads and emits request events only.

## Manual Walkthrough Notes

- The current slice proves the navigation handoff: Home / bottom roster button → roster → player detail → training.
- The panel displays concise roster rows and selected player detail from authoritative payload snapshots.
- Empty roster state displays `无匹配球员`.
- Training completion/result display is wired to `training_completed` / `player_action_completed` payloads, but full training resolution remains owned by PlayerDevelopment stories.

## Warnings Carried

- Full name/position sort controls and position filter UI are not fully expanded in this convergence pass; the smoke locks the route, mount, row ID, and handoff contract first.
- Final roster/training payload field names may need one small adapter pass once PlayerDevelopment emits production UI read models.
