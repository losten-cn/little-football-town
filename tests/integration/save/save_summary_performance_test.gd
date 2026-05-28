extends Node

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const SaveSnapshotScript: Script = preload("res://src/autoload/save_snapshot.gd")
const TEST_SAVE_DIRECTORY_PATH: String = "user://test_saves/save_summary_performance"
const LOAD_BUDGET_MSEC: int = 500

var _failures: Array[String] = []


func _ready() -> void:
	test_get_save_metadata_returns_displayable_summary_for_valid_slots()
	test_get_save_metadata_distinguishes_empty_corrupted_and_incomplete_slots()
	test_load_snapshot_from_slot_completes_within_budget_for_representative_full_save()
	test_save_summary_regression_samples_cover_current_migrated_and_corrupted_snapshots()
	_cleanup_save_directory()
	if _failures.is_empty():
		print("SAVE_SUMMARY_PERFORMANCE_TEST_PASS")
		_finish(0)
	else:
		for failure: String in _failures:
			push_error("SAVE_SUMMARY_PERFORMANCE_TEST_FAIL: %s" % failure)
		_finish(1)


func test_get_save_metadata_returns_displayable_summary_for_valid_slots() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Node = _make_save_manager()
	_expect(save_manager.save_snapshot_to_slot("slot_1", _make_valid_snapshot(101, "Alpha Town", 10, 12)), "slot_1 summary setup save should succeed")
	_expect(save_manager.save_snapshot_to_slot("slot_2", _make_valid_snapshot(202, "Beta Town", 6, 12)), "slot_2 summary setup save should succeed")
	_expect(save_manager.save_snapshot_to_slot("slot_3", _make_valid_snapshot(303, "Gamma Town", 12, 12)), "slot_3 summary setup save should succeed")
	_expect(save_manager.save_snapshot_to_slot("autosave", _make_valid_snapshot(404, "Auto Town", 8, 12)), "autosave summary setup save should succeed")

	# Act
	var summaries: Array[Dictionary] = save_manager.list_save_slot_metadata()

	# Assert
	_expect(summaries.size() == 4, "save summary list should include 4 legal slots")
	_expect(String(summaries[0].get("status", "")) == "valid", "slot_1 summary should be valid")
	_expect(String(summaries[0].get("save_label", "")) == "Alpha Town", "slot_1 summary should expose save label")
	_expect(String(summaries[0].get("season_phase", "")) == "Planning", "slot_1 summary should expose season phase")
	_expect(float(summaries[0].get("save_summary_progress_ratio", 0.0)) == 10.0 / 12.0, "slot_1 summary should expose progress ratio")
	_expect(int((summaries[0].get("key_resources", {}) as Dictionary).get("funds", 0)) == 601, "slot_1 summary should expose key resources")
	_expect(String(summaries[3].get("slot_id", "")) == "autosave", "summary list should include autosave slot")
	_free_if_node(save_manager)


func test_get_save_metadata_distinguishes_empty_corrupted_and_incomplete_slots() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Node = _make_save_manager()
	_expect(save_manager.save_snapshot_to_slot("slot_1", _make_valid_snapshot(111, "Valid Town", 3, 12)), "valid slot setup save should succeed")
	var corrupted_snapshot: SaveSnapshot = _make_valid_snapshot(222, "Corrupted Town", 5, 12)
	_expect(save_manager.save_snapshot_to_slot("slot_2", corrupted_snapshot), "corrupted slot setup save should succeed before tamper")
	var corrupted_path: String = save_manager.resolve_slot_path("slot_2")
	var loaded_snapshot: SaveSnapshot = ResourceLoader.load(corrupted_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveSnapshot
	loaded_snapshot.economy_state["funds"] = 9999
	ResourceSaver.save(loaded_snapshot, corrupted_path)
	var incomplete_snapshot: SaveSnapshot = _make_valid_snapshot(333, "Incomplete Town", 2, 12)
	incomplete_snapshot.match_state.erase("state")
	incomplete_snapshot.snapshot_metadata["integrity_hash"] = _compute_integrity_hash(incomplete_snapshot)
	_ensure_parent_directory(save_manager.resolve_slot_path("slot_3"))
	ResourceSaver.save(incomplete_snapshot, save_manager.resolve_slot_path("slot_3"))

	# Act
	var slot_1_summary: Dictionary[String, Variant] = save_manager.get_save_metadata("slot_1")
	var slot_2_summary: Dictionary[String, Variant] = save_manager.get_save_metadata("slot_2")
	var slot_3_summary: Dictionary[String, Variant] = save_manager.get_save_metadata("slot_3")
	var autosave_summary: Dictionary[String, Variant] = save_manager.get_save_metadata("autosave")

	# Assert
	_expect(String(slot_1_summary.get("status", "")) == "valid", "valid slot should remain valid in summary")
	_expect(String(slot_2_summary.get("status", "")) == "corrupted", "corrupted slot should be distinguishable in summary")
	_expect(String(slot_3_summary.get("status", "")) == "invalid", "incomplete slot should be distinguishable in summary")
	_expect(String(autosave_summary.get("status", "")) == "empty", "empty slot should be distinguishable in summary")
	_free_if_node(save_manager)


func test_load_snapshot_from_slot_completes_within_budget_for_representative_full_save() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Node = _make_save_manager()
	var runtime_state: Dictionary[String, Variant] = {}
	_register_restore_tracking(save_manager, runtime_state)
	_expect(save_manager.save_snapshot_to_slot("slot_1", _make_valid_snapshot(444, "Performance Town", 9, 12)), "performance setup save should succeed")

	# Act
	var start_msec: int = Time.get_ticks_msec()
	var load_result: Dictionary[String, Variant] = save_manager.load_snapshot_from_slot("slot_1")
	var elapsed_msec: int = Time.get_ticks_msec() - start_msec

	# Assert
	_expect(load_result.get("success", false) as bool, "representative full save should restore successfully")
	_expect(elapsed_msec < LOAD_BUDGET_MSEC, "full save load should complete within 500ms budget")
	_expect(String((runtime_state.get("time", {}) as Dictionary).get("phase", "")) == "Planning", "performance load should restore runtime state")
	_free_if_node(save_manager)


func test_save_summary_regression_samples_cover_current_migrated_and_corrupted_snapshots() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Node = _make_save_manager()
	var runtime_state: Dictionary[String, Variant] = {}
	_register_restore_tracking(save_manager, runtime_state)
	_expect(save_manager.save_snapshot_to_slot("slot_1", _make_valid_snapshot(555, "Current Town", 12, 12)), "current sample save should succeed")
	var legacy_snapshot: SaveSnapshot = _make_legacy_snapshot(666, "Legacy Town", 4, 12)
	_ensure_parent_directory(save_manager.resolve_slot_path("slot_2"))
	ResourceSaver.save(legacy_snapshot, save_manager.resolve_slot_path("slot_2"))
	var corrupted_snapshot: SaveSnapshot = _make_valid_snapshot(777, "Broken Town", 1, 12)
	_expect(save_manager.save_snapshot_to_slot("slot_3", corrupted_snapshot), "corrupted sample save should succeed before tamper")
	var corrupted_path: String = save_manager.resolve_slot_path("slot_3")
	var broken_loaded_snapshot: SaveSnapshot = ResourceLoader.load(corrupted_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveSnapshot
	broken_loaded_snapshot.match_state["state_name"] = "Broken"
	ResourceSaver.save(broken_loaded_snapshot, corrupted_path)

	# Act
	var slot_1_summary: Dictionary[String, Variant] = save_manager.get_save_metadata("slot_1")
	var slot_2_load: Dictionary[String, Variant] = save_manager.load_snapshot_from_slot("slot_2")
	var slot_2_summary: Dictionary[String, Variant] = save_manager.get_save_metadata("slot_2")
	var slot_3_load: Dictionary[String, Variant] = save_manager.load_snapshot_from_slot("slot_3")

	# Assert
	_expect(String(slot_1_summary.get("status", "")) == "valid", "current sample summary should be valid")
	_expect(slot_2_load.get("success", false) as bool, "legacy sample should remain loadable through migration path")
	_expect(String(slot_2_summary.get("status", "")) == "valid", "legacy sample summary should remain valid after migration-capable load")
	_expect(not (slot_3_load.get("success", true) as bool), "corrupted sample should fail load")
	_expect(String(slot_3_load.get("recovery_reason", "")) == "corrupted", "corrupted sample should return corrupted recovery reason")
	_free_if_node(save_manager)


func _make_save_manager() -> Node:
	var save_manager: Node = SaveManagerScript.new()
	save_manager.set_save_directory_path(TEST_SAVE_DIRECTORY_PATH)
	return save_manager


func _register_restore_tracking(save_manager: Node, runtime_state: Dictionary[String, Variant]) -> void:
	for system_id: String in save_manager.get_required_system_ids():
		save_manager.register_system(system_id, func() -> Dictionary[String, Variant]: return {}, func(data: Dictionary[String, Variant]) -> bool:
			runtime_state[system_id] = data.duplicate(true)
			return true
		)


func _make_valid_snapshot(seed: int, town_name: String, completed_progress_units: int, total_progress_units: int) -> SaveSnapshot:
	var snapshot: SaveSnapshot = SaveSnapshotScript.new()
	snapshot.save_version = 1
	snapshot.timestamp = seed
	snapshot.playtime_seconds = float(seed)
	snapshot.ui_screen_id = "planning"
	snapshot.ui_stack_depth = 1
	snapshot.snapshot_metadata = {
		"save_label": town_name,
		"town_name": town_name,
		"total_progress_units": total_progress_units,
	}
	snapshot.time_state = {
		"phase": "Planning",
		"timeline_position": completed_progress_units,
		"current_state": "Planning",
	}
	snapshot.player_state = {"roster_count": 16}
	snapshot.match_state = {
		"state": 0,
		"state_name": "Planning",
		"pending_match_context": {},
		"result_packet": {},
		"formal_state_history": [],
		"confirmed_results_by_match_id": {},
		"scheduled_position": completed_progress_units,
		"in_progress": false,
	}
	snapshot.economy_state = {"funds": 500 + seed}
	snapshot.town_state = {"facility_count": 1 + (seed % 3)}
	snapshot.league_state = {"rank": 2}
	snapshot.snapshot_metadata["integrity_hash"] = _compute_integrity_hash(snapshot)
	return snapshot


func _make_legacy_snapshot(seed: int, town_name: String, completed_progress_units: int, total_progress_units: int) -> SaveSnapshot:
	var snapshot: SaveSnapshot = SaveSnapshotScript.new()
	snapshot.save_version = 0
	snapshot.timestamp = seed
	snapshot.playtime_seconds = float(seed)
	snapshot.ui_screen_id = "planning"
	snapshot.ui_stack_depth = 1
	snapshot.snapshot_metadata = {
		"save_label": town_name,
		"town_name": town_name,
		"total_progress_units": total_progress_units,
	}
	snapshot.time_state = {
		"phase": "Planning",
		"timeline_position": completed_progress_units,
		"current_state": "Planning",
	}
	snapshot.player_state = {"roster_count": 14}
	snapshot.match_state = {
		"state": 0,
		"state_name": "Planning",
		"pending_match_context": {},
		"result_packet": {},
	}
	snapshot.economy_state = {"funds": 700}
	snapshot.town_state = {"facility_count": 2}
	snapshot.league_state = {"rank": 3}
	snapshot.snapshot_metadata["integrity_hash"] = _compute_integrity_hash(snapshot)
	return snapshot


func _compute_integrity_hash(snapshot: SaveSnapshot) -> int:
	var payload: String = "%s|%s|%s|%s|%s|%s" % [
		_serialize_variant_for_integrity(snapshot.time_state),
		_serialize_variant_for_integrity(snapshot.player_state),
		_serialize_variant_for_integrity(snapshot.match_state),
		_serialize_variant_for_integrity(snapshot.economy_state),
		_serialize_variant_for_integrity(snapshot.town_state),
		_serialize_variant_for_integrity(snapshot.league_state),
	]
	return hash(payload)


func _serialize_variant_for_integrity(value: Variant) -> String:
	if value is Dictionary:
		var dictionary_value: Dictionary = value as Dictionary
		var keys: Array[String] = []
		for key: Variant in dictionary_value.keys():
			keys.append(String(key))
		keys.sort()
		var parts: Array[String] = []
		for key: String in keys:
			parts.append("%s=%s" % [key, _serialize_variant_for_integrity(dictionary_value.get(key))])
		return "{%s}" % ",".join(parts)
	if value is Array:
		var parts: Array[String] = []
		for item: Variant in value as Array:
			parts.append(_serialize_variant_for_integrity(item))
		return "[%s]" % ",".join(parts)
	if value == null:
		return "null"
	return JSON.stringify(value)


func _ensure_parent_directory(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))


func _cleanup_save_directory() -> void:
	var absolute_save_directory_path: String = ProjectSettings.globalize_path(TEST_SAVE_DIRECTORY_PATH)
	if not DirAccess.dir_exists_absolute(absolute_save_directory_path):
		return
	var directory: DirAccess = DirAccess.open(absolute_save_directory_path)
	if directory == null:
		_failures.append("cleanup could not open save directory")
		return
	for file_name: String in directory.get_files():
		var remove_error: int = directory.remove(file_name)
		if remove_error != OK:
			_failures.append("cleanup failed to remove %s (error %d)" % [file_name, remove_error])


func _finish(exit_code: int) -> void:
	call_deferred("_quit_with_code", exit_code)


func _quit_with_code(exit_code: int) -> void:
	get_tree().quit(exit_code)


func _free_if_node(value: Variant) -> void:
	if value is Node:
		(value as Node).free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
