# GDScript Typed Dictionary Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove runtime typed dictionary assignment errors across GDScript prototype, runtime, and test boundaries while preserving core typed payload contracts.

**Architecture:** Keep `Dictionary[String, Variant]` at stable API boundaries and normalize untyped/`Variant` data before it enters those boundaries. Use plain `Dictionary` for volatile UI display locals that only read data. Add focused regression coverage for the reported vertical slice team screen path and run the existing headless test suite slices that touch corrected code.

**Tech Stack:** Godot 4.6.2 stable, GDScript, custom `tests/test_script_runner.gd` headless runner, PowerShell on Windows.

---

## File Structure

- Modify `prototypes/little-football-town-vertical-slice/screens/team_screen.gd`: weaken local view dictionaries to plain `Dictionary` and avoid typed assignment from `Variant` array elements.
- Modify `prototypes/little-football-town-vertical-slice/screens/home_screen.gd`: weaken local view dictionaries that are read-only UI data.
- Modify `prototypes/little-football-town-vertical-slice/screens/match_screen.gd`: weaken local view dictionaries that are read-only UI data.
- Modify `prototypes/little-football-town-vertical-slice/vertical_slice_session.gd`: normalize arrays and nested dictionaries at session/runtime boundaries.
- Review `prototypes/little-football-town-vertical-slice/vertical_slice_scenario.gd`: change only if typed return literals fail compile/runtime after session fixes.
- Optionally mirror equivalent edits in `prototypes/training-match-loop-vertical-slice/` if that untracked directory remains in the workspace. Do not stage or commit this untracked directory without explicit user approval.
- Modify `src/core/transaction.gd`: normalize serialized metadata in `from_dict()`.
- Modify `src/core/match_simulation.gd`: normalize typed dictionary loops over `Array[Dictionary]`, `.get(..., {})` nested dictionaries, duplicate assignments, and confirmed result lookup.
- Modify `src/core/economy_manager.gd`: normalize duplicated context and transaction metadata before assignment to typed dictionaries.
- Modify `src/autoload/save_manager.gd`: normalize duplicated autosave and snapshot metadata before assignment.
- Add `tests/integration/prototype/vertical_slice_team_screen_boundary_test.gd`: automated regression for the reported team screen bind/refresh path.
- Modify specific existing tests only where unsafe typed loops or `.get(...,{})` assignments fail after runtime fixes.

Use this Godot executable on this Windows machine unless a newer confirmed path is available:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --version
```

Expected: prints a Godot 4.6.2 version string and exits 0.

---

### Task 1: Add Prototype Team Screen Regression Test

**Files:**
- Create: `tests/integration/prototype/vertical_slice_team_screen_boundary_test.gd`

- [ ] **Step 1: Write the failing regression test**

Create `tests/integration/prototype/vertical_slice_team_screen_boundary_test.gd` with:

```gdscript
extends Node

const SessionScript: Script = preload("res://prototypes/little-football-town-vertical-slice/vertical_slice_session.gd")
const TeamScreenScene: PackedScene = preload("res://prototypes/little-football-town-vertical-slice/screens/team_screen.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	test_team_screen_binds_session_and_refreshes_view_model()
	if _failures.is_empty():
		print("VERTICAL_SLICE_TEAM_SCREEN_BOUNDARY_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func test_team_screen_binds_session_and_refreshes_view_model() -> void:
	var session: Node = SessionScript.new()
	add_child(session)
	await get_tree().process_frame

	var team_screen: Control = TeamScreenScene.instantiate()
	add_child(team_screen)
	team_screen.call("bind_session", session, Callable(self, "_noop_show_home_screen"))
	await get_tree().process_frame

	var player_list: ItemList = team_screen.get_node("Players/PlayerList") as ItemList
	var project_list: ItemList = team_screen.get_node("Training/ProjectList") as ItemList
	var result_label: RichTextLabel = team_screen.get_node("Result") as RichTextLabel

	_expect(player_list.item_count == 11, "team screen should render all scenario players")
	_expect(project_list.item_count == 2, "team screen should render all scenario training projects")
	_expect(result_label.text.contains("训练反馈"), "team screen should render training feedback header")

	team_screen.queue_free()
	session.queue_free()


func _noop_show_home_screen() -> void:
	pass


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
```

- [ ] **Step 2: Run the regression test and confirm it fails before implementation**

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/prototype/vertical_slice_team_screen_boundary_test.gd"
```

Expected before implementation: non-zero exit with the reported typed dictionary assignment error in `team_screen.gd`, or another typed dictionary assignment error on the same path.

- [ ] **Step 3: Commit the failing test**

```powershell
git add -- tests/integration/prototype/vertical_slice_team_screen_boundary_test.gd
git commit -m "test: cover vertical slice team screen dictionary boundary"
```

---

### Task 2: Fix Reported Prototype Screen Boundary

**Files:**
- Modify: `prototypes/little-football-town-vertical-slice/screens/team_screen.gd`
- Modify: `prototypes/little-football-town-vertical-slice/screens/home_screen.gd`
- Modify: `prototypes/little-football-town-vertical-slice/screens/match_screen.gd`

- [ ] **Step 1: Change `team_screen.gd` local dictionaries to plain dictionaries**

In `prototypes/little-football-town-vertical-slice/screens/team_screen.gd`, change these local declarations:

```gdscript
var team_view: Dictionary[String, Variant] = _session.get_team_view_model()
```

to:

```gdscript
var team_view: Dictionary = _session.get_team_view_model()
```

Change:

```gdscript
var player_summary: Dictionary[String, Variant] = player_summary_variant
```

to:

```gdscript
var player_summary: Dictionary = player_summary_variant as Dictionary
```

Change:

```gdscript
var project: Dictionary[String, Variant] = project_variant
```

to:

```gdscript
var project: Dictionary = project_variant as Dictionary
```

Change:

```gdscript
var last_training_result: Dictionary[String, Variant] = team_view.get("last_training_result", {})
```

to:

```gdscript
var last_training_result: Dictionary = team_view.get("last_training_result", {}) as Dictionary
```

- [ ] **Step 2: Change `home_screen.gd` local dictionaries to plain dictionaries**

In `prototypes/little-football-town-vertical-slice/screens/home_screen.gd`, change:

```gdscript
var summary: Dictionary[String, Variant] = _session.get_state_summary()
```

to:

```gdscript
var summary: Dictionary = _session.get_state_summary()
```

Change:

```gdscript
var latest_match_result: Dictionary[String, Variant] = summary.get("latest_match_result", {})
```

to:

```gdscript
var latest_match_result: Dictionary = summary.get("latest_match_result", {}) as Dictionary
```

- [ ] **Step 3: Change `match_screen.gd` local dictionaries to plain dictionaries**

In `prototypes/little-football-town-vertical-slice/screens/match_screen.gd`, change all local UI-only declarations that assign from `_session` or `.get(...,{})`:

```gdscript
var open_result: Dictionary[String, Variant] = _session.open_match_center()
var match_view: Dictionary[String, Variant] = _session.get_match_view_model()
var latest_match_result: Dictionary[String, Variant] = match_view.get("latest_match_result", {})
var result: Dictionary[String, Variant] = _session.confirm_match_result_and_return_home()
```

to:

```gdscript
var open_result: Dictionary = _session.open_match_center()
var match_view: Dictionary = _session.get_match_view_model()
var latest_match_result: Dictionary = match_view.get("latest_match_result", {}) as Dictionary
var result: Dictionary = _session.confirm_match_result_and_return_home()
```

- [ ] **Step 4: Run the prototype regression test**

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/prototype/vertical_slice_team_screen_boundary_test.gd"
```

Expected: `VERTICAL_SLICE_TEAM_SCREEN_BOUNDARY_TEST_PASS`.

- [ ] **Step 5: Commit the prototype screen fix**

```powershell
git add -- prototypes/little-football-town-vertical-slice/screens/team_screen.gd prototypes/little-football-town-vertical-slice/screens/home_screen.gd prototypes/little-football-town-vertical-slice/screens/match_screen.gd tests/integration/prototype/vertical_slice_team_screen_boundary_test.gd
git commit -m "fix: relax prototype screen dictionary locals"
```

---

### Task 3: Normalize Prototype Session Dictionaries

**Files:**
- Modify: `prototypes/little-football-town-vertical-slice/vertical_slice_session.gd`

- [ ] **Step 1: Add local conversion helpers**

Near the bottom of `prototypes/little-football-town-vertical-slice/vertical_slice_session.gd`, before `_emit_state_changed()`, add:

```gdscript
func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary


func _to_dictionary_array(value: Variant) -> Array[Dictionary]:
	var dictionaries: Array[Dictionary] = []
	if value is Array:
		for entry: Variant in value:
			if entry is Dictionary:
				dictionaries.append((entry as Dictionary).duplicate(true))
	return dictionaries
```

- [ ] **Step 2: Normalize untyped return and lookup boundaries**

In `_find_training_project()`, change:

```gdscript
for training_project: Dictionary[String, Variant] in _training_projects:
	if String(training_project.get("project_id", "")) == project_id:
		return training_project.duplicate(true)
return {}
```

to:

```gdscript
for training_project_variant: Variant in _training_projects:
	var training_project: Dictionary[String, Variant] = _to_string_variant_dictionary(training_project_variant)
	if String(training_project.get("project_id", "")) == project_id:
		return training_project.duplicate(true)
return _to_string_variant_dictionary({})
```

In `_build_match_summary_text()`, change:

```gdscript
var score: Dictionary[String, Variant] = result_packet.get("score", {})
```

to:

```gdscript
var score: Dictionary[String, Variant] = _to_string_variant_dictionary(result_packet.get("score", {}))
```

In `_finalize_match_loop()`, immediately after `_latest_match_result = _match_simulation.get_result_packet()`, add:

```gdscript
_latest_match_result = _to_string_variant_dictionary(_latest_match_result)
```

- [ ] **Step 3: Normalize arrays returned in view models**

In `get_state_summary()`, leave `roster_summary` as an untyped `Array`, but ensure dictionary fields assigned from typed state remain duplicated only after conversion:

```gdscript
"training_projects": _to_dictionary_array(_training_projects),
"last_training_result": _last_training_result.duplicate(true),
"latest_match_result": _latest_match_result.duplicate(true),
```

In `get_team_view_model()`, change:

```gdscript
"players": state_summary.get("players", []).duplicate(true),
"training_projects": _training_projects.duplicate(true),
```

to:

```gdscript
"players": (state_summary.get("players", []) as Array).duplicate(true),
"training_projects": _to_dictionary_array(_training_projects),
```

- [ ] **Step 4: Run prototype and match-related tests**

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/prototype/vertical_slice_team_screen_boundary_test.gd"
```

Expected: pass marker.

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" "res://prototypes/little-football-town-vertical-slice/vertical_slice_main.tscn" --quit-after 2
```

Expected: no typed dictionary assignment errors in stderr. If `--quit-after` is unsupported, use MCP `run_project` and `get_debug_output`, then stop the project.

- [ ] **Step 5: Commit prototype session normalization**

```powershell
git add -- prototypes/little-football-town-vertical-slice/vertical_slice_session.gd
git commit -m "fix: normalize prototype session dictionaries"
```

---

### Task 4: Normalize Core Runtime Dictionary Boundaries

**Files:**
- Modify: `src/core/transaction.gd`
- Modify: `src/core/economy_manager.gd`
- Modify: `src/core/match_simulation.gd`

- [ ] **Step 1: Fix transaction metadata restore**

In `src/core/transaction.gd`, add this static helper inside the class:

```gdscript
static func _to_typed_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary
```

Change `from_dict()` from:

```gdscript
var serialized_metadata: Dictionary[String, Variant] = data.get("metadata", {}) as Dictionary[String, Variant]
transaction.metadata = serialized_metadata.duplicate(true)
```

to:

```gdscript
transaction.metadata = _to_typed_dictionary(data.get("metadata", {}))
```

- [ ] **Step 2: Fix economy duplicated typed assignments**

In `src/core/economy_manager.gd`, add or reuse a private helper:

```gdscript
func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary
```

Change:

```gdscript
var resolved_context: Dictionary[String, Variant] = season_context.duplicate(true)
```

to:

```gdscript
var resolved_context: Dictionary[String, Variant] = _to_string_variant_dictionary(season_context)
```

Change:

```gdscript
var authorized_metadata: Dictionary[String, Variant] = transaction.metadata.duplicate(true)
```

to:

```gdscript
var authorized_metadata: Dictionary[String, Variant] = _to_string_variant_dictionary(transaction.metadata)
```

- [ ] **Step 3: Fix match simulation typed lookup and loop boundaries**

In `src/core/match_simulation.gd`, add private helpers near other private helpers:

```gdscript
func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary


func _to_dictionary_array(value: Variant) -> Array[Dictionary]:
	var dictionaries: Array[Dictionary] = []
	if value is Array:
		for entry: Variant in value:
			if entry is Dictionary:
				dictionaries.append((entry as Dictionary).duplicate(true))
	return dictionaries
```

Change:

```gdscript
var requested_match_context: Dictionary[String, Variant] = match_context.duplicate(true)
```

to:

```gdscript
var requested_match_context: Dictionary[String, Variant] = _to_string_variant_dictionary(match_context)
```

Change:

```gdscript
_result_packet = (_confirmed_results_by_match_id.get(match_id, {}) as Dictionary[String, Variant]).duplicate(true)
```

to:

```gdscript
_result_packet = _to_string_variant_dictionary(_confirmed_results_by_match_id.get(match_id, {}))
```

Change typed loops over `Array[Dictionary]` to plain dictionary loop variables in these functions:

```gdscript
is_lineup_legal()
compute_team_match_strength()
_finalize_result_packet()
_build_key_event_summary()
_build_player_appearances()
_build_condition_changes()
_build_morale_changes()
_build_post_match_tags()
_events_include_category()
```

For each loop, use this shape:

```gdscript
for entry_variant: Variant in events:
	var event_entry: Dictionary = entry_variant as Dictionary
```

For lineup slots:

```gdscript
for lineup_slot_variant: Variant in lineup_slots:
	var lineup_slot: Dictionary = lineup_slot_variant as Dictionary
```

Change nested `.get(...,{})` chains:

```gdscript
float(_second_half_plan.get("tactics", {}).get("tactical_match_mod", 0.0))
```

to:

```gdscript
var second_half_tactics: Dictionary[String, Variant] = _to_string_variant_dictionary(_second_half_plan.get("tactics", {}))
float(second_half_tactics.get("tactical_match_mod", 0.0))
```

Apply the same pattern in `_finalize_result_packet()`, `_build_win_reasons()`, and any other place where a nested `.get("tactics", {})` result is immediately treated as a dictionary.

- [ ] **Step 4: Run core match and economy tests**

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/unit/economy/economy_authority_transaction_model_test.gd"
```

Expected: pass marker.

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/unit/economy/execute_transaction_atomic_validation_test.gd"
```

Expected: pass marker.

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/unit/match/match_rng_determinism_test.gd"
```

Expected: pass marker.

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/match/match_loop_regression_test.gd"
```

Expected: pass marker.

- [ ] **Step 5: Commit core runtime normalization**

```powershell
git add -- src/core/transaction.gd src/core/economy_manager.gd src/core/match_simulation.gd
git commit -m "fix: normalize core dictionary boundaries"
```

---

### Task 5: Normalize Save Manager Boundary Assignments

**Files:**
- Modify: `src/autoload/save_manager.gd`

- [ ] **Step 1: Add save manager conversion helper**

In `src/autoload/save_manager.gd`, add a private helper near other helper functions:

```gdscript
func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary
```

- [ ] **Step 2: Replace unsafe duplicate/cast assignments**

Change:

```gdscript
var resolved_ui_state: Dictionary[String, Variant] = ui_state.duplicate(true)
```

to:

```gdscript
var resolved_ui_state: Dictionary[String, Variant] = _to_string_variant_dictionary(ui_state)
```

Change:

```gdscript
var pending_ui_state: Dictionary[String, Variant] = _pending_autosave_ui_state.duplicate(true)
var pending_slot_metadata: Dictionary[String, Variant] = _pending_autosave_slot_metadata.duplicate(true)
```

to:

```gdscript
var pending_ui_state: Dictionary[String, Variant] = _to_string_variant_dictionary(_pending_autosave_ui_state)
var pending_slot_metadata: Dictionary[String, Variant] = _to_string_variant_dictionary(_pending_autosave_slot_metadata)
```

Change:

```gdscript
var snapshot_metadata: Dictionary[String, Variant] = (migrated_snapshot.snapshot_metadata as Dictionary[String, Variant]).duplicate(true)
```

to:

```gdscript
var snapshot_metadata: Dictionary[String, Variant] = _to_string_variant_dictionary(migrated_snapshot.snapshot_metadata)
```

- [ ] **Step 3: Run save tests**

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/save/autosave_triggers_test.gd"
```

Expected: pass marker.

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/save/save_snapshot_slots_test.gd"
```

Expected: pass marker.

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/save/save_recovery_flow_test.gd"
```

Expected: pass marker.

- [ ] **Step 4: Commit save manager normalization**

```powershell
git add -- src/autoload/save_manager.gd
git commit -m "fix: normalize save manager dictionaries"
```

---

### Task 6: Audit and Fix Remaining Typed Dictionary Hotspots

**Files:**
- Modify: `tests/unit/town/facility_cost_time_formula_test.gd`
- Modify: `tests/unit/match/key_event_generation_test.gd`
- Modify: `tests/unit/match/match_rng_determinism_test.gd`
- Modify: `tests/unit/match/team_strength_aggregation_test.gd`
- Modify: `tests/integration/balance/balance_consistency_test.gd`
- Modify: `tests/integration/match/match_loop_regression_test.gd`
- Modify: `tests/integration/economy/settlement_order_concurrency_regression_test.gd`
- Modify: `tests/integration/town/downstream_query_maintenance_test.gd`
- Modify: `tests/integration/town/serialization_restore_regression_test.gd`

- [ ] **Step 1: Re-run high-risk search**

Run:

```powershell
rg -n "Dictionary\[String, Variant\].*=.*\.get\([^\n]*\{\}|var .*: Dictionary\[String, Variant\] = .*_session\.|for .*: Dictionary\[String, Variant\] in|Dictionary\[String, Variant\] = .*\.duplicate\(" --glob "*.gd" src prototypes tests
```

Expected: remaining results are in the files listed for this task, already normalized through helper calls, local typed literals known to be safe, or stable API assignments that do not cross an untyped boundary.

- [ ] **Step 2: Fix unsafe typed loops in tests**

For test loops over inline arrays, replace typed loop variables with plain dictionaries. In `tests/unit/town/facility_cost_time_formula_test.gd`, change the illegal-level loop to:

```gdscript
for result_variant: Variant in [
	town_building.compute_construction_funds_cost(Facility.FacilityType.TRAINING_GROUND, illegal_level),
	town_building.compute_upgrade_funds_cost(Facility.FacilityType.TRAINING_GROUND, illegal_level),
	town_building.compute_construction_time_cost(Facility.FacilityType.TRAINING_GROUND, illegal_level),
	town_building.compute_upgrade_time_cost(Facility.FacilityType.TRAINING_GROUND, illegal_level),
]:
	var result: Dictionary = result_variant as Dictionary
	_expect(not (result["success"] as bool), "illegal level %s should fail" % str(illegal_level))
	_expect(result["error"] as String == "invalid_target_level", "illegal level %s should report invalid_target_level" % str(illegal_level))
	_expect(result["value"] == null, "illegal level %s should not return executable value" % str(illegal_level))
```

In `tests/unit/match/key_event_generation_test.gd`, change event loops from:

```gdscript
for event: Dictionary[String, Variant] in events:
```

to:

```gdscript
for event_variant: Variant in events:
	var event: Dictionary = event_variant as Dictionary
```

In `tests/unit/match/team_strength_aggregation_test.gd`, change lineup loops from:

```gdscript
for lineup_slot: Dictionary[String, Variant] in lineup_slots:
```

to:

```gdscript
for lineup_slot_variant: Variant in lineup_slots:
	var lineup_slot: Dictionary = lineup_slot_variant as Dictionary
```

In `tests/integration/balance/balance_consistency_test.gd`, `tests/integration/match/match_loop_regression_test.gd`, and `tests/integration/economy/settlement_order_concurrency_regression_test.gd`, apply the same `Variant` loop variable plus `as Dictionary` local pattern to any loop reported by Step 1.

- [ ] **Step 3: Fix unsafe `.get(...,{})` assignments in tests**

For code such as:

```gdscript
var first_result_packet: Dictionary[String, Variant] = first_output.get("result_packet", {})
```

use an existing local helper if present:

```gdscript
var first_result_packet: Dictionary[String, Variant] = _to_typed_dictionary(first_output.get("result_packet", {}))
```

In `tests/unit/match/match_rng_determinism_test.gd`, use the file's existing typed helper if present. If the file lacks a helper, add:

```gdscript
func _to_typed_dictionary(source: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if source is Dictionary:
		for key: Variant in (source as Dictionary).keys():
			typed_dictionary[String(key)] = (source as Dictionary)[key]
	return typed_dictionary
```

In `tests/integration/town/downstream_query_maintenance_test.gd` and `tests/integration/town/serialization_restore_regression_test.gd`, change direct `serialize().duplicate(true)` typed assignments to use an existing local conversion helper. If the file lacks one, add the same `_to_typed_dictionary(source: Variant)` helper shown above and call:

```gdscript
var payload: Dictionary[String, Variant] = _to_typed_dictionary(source_town.serialize())
```

- [ ] **Step 4: Keep untracked prototype separate**

Do not modify, stage, or commit `prototypes/training-match-loop-vertical-slice/` in this plan because it is currently untracked. Check:

```powershell
git status --short prototypes/training-match-loop-vertical-slice
```

Expected: every path remains `??`. If the user later approves bringing this prototype into version control, create a separate plan or task for that directory.

- [ ] **Step 5: Run representative tests for changed files**

Run these tests after applying any changes in this task:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/unit/town/facility_cost_time_formula_test.gd"
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/unit/match/key_event_generation_test.gd"
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/unit/match/match_rng_determinism_test.gd"
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/unit/match/team_strength_aggregation_test.gd"
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/balance/balance_consistency_test.gd"
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/match/match_loop_regression_test.gd"
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/economy/settlement_order_concurrency_regression_test.gd"
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/town/downstream_query_maintenance_test.gd"
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/town/serialization_restore_regression_test.gd"
```

Expected: each test prints its pass marker and exits 0.

- [ ] **Step 6: Commit remaining tracked hotspot fixes**

Only add tracked files and approved new tests:

```powershell
git status --short
git add -- tests/unit/town/facility_cost_time_formula_test.gd tests/unit/match/key_event_generation_test.gd tests/unit/match/match_rng_determinism_test.gd tests/unit/match/team_strength_aggregation_test.gd tests/integration/balance/balance_consistency_test.gd tests/integration/match/match_loop_regression_test.gd tests/integration/economy/settlement_order_concurrency_regression_test.gd tests/integration/town/downstream_query_maintenance_test.gd tests/integration/town/serialization_restore_regression_test.gd
git commit -m "fix: normalize remaining typed dictionary hotspots"
```

---

### Task 7: Full Verification and Final Audit

**Files:**
- No required code files.
- Optional: update implementation notes only if verification limitations must be recorded.

- [ ] **Step 1: Run the reported vertical slice scene**

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" "res://prototypes/little-football-town-vertical-slice/vertical_slice_main.tscn" --quit-after 2
```

Expected: no typed dictionary assignment error. If this command does not exit because the flag is unsupported, use MCP `run_project` with scene `res://prototypes/little-football-town-vertical-slice/vertical_slice_main.tscn`, then `get_debug_output`, then `stop_project`.

- [ ] **Step 2: Run prototype regression**

Run:

```powershell
& "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- --test-script="res://tests/integration/prototype/vertical_slice_team_screen_boundary_test.gd"
```

Expected: `VERTICAL_SLICE_TEAM_SCREEN_BOUNDARY_TEST_PASS`.

- [ ] **Step 3: Run all automated unit and integration tests**

Run in PowerShell:

```powershell
$godot = "D:\Program Files\godot\Godot_v4.6.2-stable_win64_console.exe"
$failures = @()
Get-ChildItem -Path tests\unit, tests\integration -Recurse -Filter *_test.gd | Sort-Object FullName | ForEach-Object {
	$resPath = "res://" + ($_.FullName.Substring((Get-Location).Path.Length + 1) -replace "\\", "/")
	Write-Host "Running $resPath"
	& $godot --headless --path "E:\code\little-football-town" --script "res://tests/test_script_runner.gd" -- "--test-script=$resPath"
	if ($LASTEXITCODE -ne 0) {
		$failures += $resPath
	}
}
if ($failures.Count -gt 0) {
	Write-Host "FAILED TESTS:"
	$failures | ForEach-Object { Write-Host $_ }
	exit 1
}
Write-Host "ALL_TESTS_PASS"
```

Expected: `ALL_TESTS_PASS`.

- [ ] **Step 4: Re-run high-risk search and classify remaining results**

Run:

```powershell
rg -n "Dictionary\[String, Variant\].*=.*\.get\([^\n]*\{\}|var .*: Dictionary\[String, Variant\] = .*_session\.|for .*: Dictionary\[String, Variant\] in|Dictionary\[String, Variant\] = .*\.duplicate\(" --glob "*.gd" src prototypes tests
```

Expected: no remaining unreviewed unsafe boundaries. Remaining results must be local typed literals, helper-normalized assignments, or intentionally typed stable API assignments.

- [ ] **Step 5: Check working tree and untracked prototype status**

Run:

```powershell
git status --short
```

Expected:

- No unstaged tracked changes from this implementation.
- Existing unrelated user changes may remain:
  - `M design/gdd/game-concept.md`
  - `M production/session-state/active.md`
- `?? prototypes/training-match-loop-vertical-slice/` may remain untracked if not explicitly approved for version control.

- [ ] **Step 6: Do not create a verification-only commit**

Task 7 is verification-only. If it changes no files, do not create an empty commit. If verification exposes a new code issue, return to the relevant earlier task, fix the code there, run that task's tests, and commit under that task's commit message pattern.

Expected: no additional commit is created by Task 7 unless a real code fix was required.
