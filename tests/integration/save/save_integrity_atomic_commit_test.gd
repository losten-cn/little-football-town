extends Node

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const SaveSnapshotScript: Script = preload("res://src/autoload/save_snapshot.gd")
const TEST_SAVE_DIRECTORY_PATH: String = "user://test_saves/save_integrity_atomic_commit"

class SaveManagerDouble:
	extends "res://src/autoload/save_manager.gd"

	var fail_save_to_temp: bool = false
	var fail_replace_atomic: bool = false

	func _save_resource_to_path(snapshot: Resource, path: String) -> int:
		if fail_save_to_temp and path.contains(".tmp"):
			return ERR_FILE_CANT_WRITE
		return super._save_resource_to_path(snapshot, path)

	func _replace_file_atomic(source_path: String, target_path: String) -> int:
		if fail_replace_atomic:
			return ERR_FILE_CANT_WRITE
		return super._replace_file_atomic(source_path, target_path)

var _failures: Array[String] = []


func _ready() -> void:
	test_save_snapshot_to_slot_writes_integrity_hash_and_valid_slot()
	test_inspect_slot_reports_corrupted_when_saved_file_is_tampered()
	test_save_snapshot_to_slot_keeps_previous_valid_snapshot_when_temp_write_fails()
	test_save_snapshot_to_slot_keeps_previous_valid_snapshot_when_replace_fails()
	_cleanup_save_directory()
	if _failures.is_empty():
		print("SAVE_INTEGRITY_ATOMIC_COMMIT_TEST_PASS")
		_finish(0)
	else:
		for failure: String in _failures:
			push_error("SAVE_INTEGRITY_ATOMIC_COMMIT_TEST_FAIL: %s" % failure)
		_finish(1)


func test_save_snapshot_to_slot_writes_integrity_hash_and_valid_slot() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Node = _make_save_manager()
	var snapshot: Resource = _make_valid_snapshot(101)

	# Act
	var save_success: bool = save_manager.save_snapshot_to_slot("slot_1", snapshot)
	var slot_result: Dictionary[String, Variant] = save_manager.inspect_slot("slot_1")

	# Assert
	_expect(save_success, "valid snapshot save should succeed")
	_expect(int(snapshot.snapshot_metadata.get("integrity_hash", 0)) != 0, "saved snapshot should include integrity hash")
	_expect(String(slot_result.get("status", "")) == "valid", "saved slot should inspect as valid")
	_expect(int((slot_result.get("snapshot_metadata", {}) as Dictionary).get("integrity_hash", 0)) != 0, "slot metadata should expose integrity hash")
	_free_if_node(save_manager)


func test_inspect_slot_reports_corrupted_when_saved_file_is_tampered() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Node = _make_save_manager()
	var snapshot: Resource = _make_valid_snapshot(202)
	var slot_path: String = save_manager.resolve_slot_path("slot_1")
	var save_success: bool = save_manager.save_snapshot_to_slot("slot_1", snapshot)
	if not save_success:
		_expect(false, "tamper test setup save should succeed")
		_free_if_node(save_manager)
		return
	var loaded_snapshot: SaveSnapshot = ResourceLoader.load(slot_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveSnapshot
	loaded_snapshot.economy_state["funds"] = 9999
	ResourceSaver.save(loaded_snapshot, slot_path)

	# Act
	var slot_result: Dictionary[String, Variant] = save_manager.inspect_slot("slot_1")

	# Assert
	_expect(save_success, "tamper test setup save should succeed")
	_expect(String(slot_result.get("status", "")) == "corrupted", "tampered snapshot should inspect as corrupted")
	_free_if_node(save_manager)


func test_save_snapshot_to_slot_keeps_previous_valid_snapshot_when_temp_write_fails() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: SaveManagerDouble = _make_save_manager_double()
	var original_snapshot: Resource = _make_valid_snapshot(303)
	var replacement_snapshot: Resource = _make_valid_snapshot(404)
	var initial_save_success: bool = save_manager.save_snapshot_to_slot("slot_1", original_snapshot)
	var initial_slot_result: Dictionary[String, Variant] = save_manager.inspect_slot("slot_1")
	save_manager.fail_save_to_temp = true

	# Act
	var replacement_save_success: bool = save_manager.save_snapshot_to_slot("slot_1", replacement_snapshot)
	var final_slot_result: Dictionary[String, Variant] = save_manager.inspect_slot("slot_1")

	# Assert
	_expect(initial_save_success, "temp-write failure setup save should succeed")
	_expect(String(initial_slot_result.get("status", "")) == "valid", "setup slot should start valid")
	_expect(not replacement_save_success, "temp write failure should report save failure")
	_expect(String(final_slot_result.get("status", "")) == "valid", "temp write failure should keep previous slot valid")
	_expect(int((final_slot_result.get("snapshot_metadata", {}) as Dictionary).get("seed", 0)) == 303, "temp write failure should keep previous snapshot metadata")
	_free_if_node(save_manager)


func test_save_snapshot_to_slot_keeps_previous_valid_snapshot_when_replace_fails() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: SaveManagerDouble = _make_save_manager_double()
	var original_snapshot: Resource = _make_valid_snapshot(505)
	var replacement_snapshot: Resource = _make_valid_snapshot(606)
	var initial_save_success: bool = save_manager.save_snapshot_to_slot("slot_1", original_snapshot)
	var initial_slot_result: Dictionary[String, Variant] = save_manager.inspect_slot("slot_1")
	save_manager.fail_replace_atomic = true

	# Act
	var replacement_save_success: bool = save_manager.save_snapshot_to_slot("slot_1", replacement_snapshot)
	var final_slot_result: Dictionary[String, Variant] = save_manager.inspect_slot("slot_1")

	# Assert
	_expect(initial_save_success, "replace failure setup save should succeed")
	_expect(String(initial_slot_result.get("status", "")) == "valid", "setup slot should start valid before replace failure")
	_expect(not replacement_save_success, "replace failure should report save failure")
	_expect(String(final_slot_result.get("status", "")) == "valid", "replace failure should keep previous slot valid")
	_expect(int((final_slot_result.get("snapshot_metadata", {}) as Dictionary).get("seed", 0)) == 505, "replace failure should keep previous snapshot metadata")
	_free_if_node(save_manager)


func _make_save_manager() -> Node:
	var save_manager: Node = SaveManagerScript.new()
	save_manager.set_save_directory_path(TEST_SAVE_DIRECTORY_PATH)
	return save_manager


func _make_save_manager_double() -> SaveManagerDouble:
	var save_manager := SaveManagerDouble.new()
	save_manager.set_save_directory_path(TEST_SAVE_DIRECTORY_PATH)
	return save_manager


func _make_valid_snapshot(seed: int) -> SaveSnapshot:
	var snapshot: SaveSnapshot = SaveSnapshotScript.new()
	snapshot.timestamp = seed
	snapshot.playtime_seconds = float(seed)
	snapshot.ui_screen_id = "planning"
	snapshot.ui_stack_depth = 1
	snapshot.snapshot_metadata = {"seed": seed}
	snapshot.time_state = {
		"phase": "Planning",
		"timeline_position": 3,
		"current_state": "Planning",
	}
	snapshot.player_state = {"roster_count": 16, "seed": seed}
	snapshot.match_state = {
		"state": 0,
		"state_name": "Planning",
		"pending_match_context": {},
		"result_packet": {},
		"formal_state_history": [],
		"confirmed_results_by_match_id": {},
		"scheduled_position": 4,
		"in_progress": false,
	}
	snapshot.economy_state = {"funds": 500 + seed}
	snapshot.town_state = {"facility_count": 1}
	snapshot.league_state = {"rank": 2}
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
		var array_value: Array = value as Array
		var parts: Array[String] = []
		for item: Variant in array_value:
			parts.append(_serialize_variant_for_integrity(item))
		return "[%s]" % ",".join(parts)
	return JSON.stringify(value)


func _finish(exit_code: int) -> void:
	call_deferred("_quit_with_code", exit_code)


func _quit_with_code(exit_code: int) -> void:
	get_tree().quit(exit_code)


func _free_if_node(value: Variant) -> void:
	if value is Node:
		(value as Node).free()


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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
