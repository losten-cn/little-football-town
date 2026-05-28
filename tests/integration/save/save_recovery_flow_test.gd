extends Node

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const SaveSnapshotScript: Script = preload("res://src/autoload/save_snapshot.gd")
const TEST_SAVE_DIRECTORY_PATH: String = "user://test_saves/save_recovery_flow"

var _failures: Array[String] = []


func _ready() -> void:
	test_load_snapshot_from_slot_routes_invalid_snapshot_to_recovery_without_restoring_runtime_state()
	test_evaluate_overwrite_risk_returns_structured_confirmation_semantics()
	test_delete_slot_without_confirmation_leaves_disk_state_unchanged()
	test_recovery_flow_never_silently_restores_corrupted_snapshot()
	_cleanup_save_directory()
	if _failures.is_empty():
		print("SAVE_RECOVERY_FLOW_TEST_PASS")
		_finish(0)
	else:
		for failure: String in _failures:
			push_error("SAVE_RECOVERY_FLOW_TEST_FAIL: %s" % failure)
		_finish(1)


func test_load_snapshot_from_slot_routes_invalid_snapshot_to_recovery_without_restoring_runtime_state() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Node = _make_save_manager()
	var restore_order: Array[String] = []
	var runtime_state: Dictionary[String, Variant] = {
		"baseline": "keep_me",
	}
	_register_restore_tracking(save_manager, restore_order, runtime_state)
	var snapshot: SaveSnapshot = _make_valid_snapshot(101)
	snapshot.match_state.erase("state")
	snapshot.snapshot_metadata["integrity_hash"] = _compute_integrity_hash(snapshot)
	var save_path: String = save_manager.resolve_slot_path("slot_1")
	_ensure_parent_directory(save_path)
	ResourceSaver.save(snapshot, save_path)

	# Act
	var load_result: Dictionary[String, Variant] = save_manager.load_snapshot_from_slot("slot_1")

	# Assert
	_expect(not (load_result.get("success", true) as bool), "invalid snapshot should not restore successfully")
	_expect(String(load_result.get("recovery_reason", "")) == "corrupted", "invalid snapshot should route to corrupted recovery")
	_expect(String(load_result.get("recovery_action", "")) == "show_recovery", "invalid snapshot should expose recovery action")
	_expect(restore_order.is_empty(), "invalid snapshot should not deserialize any system")
	_expect(String(runtime_state.get("baseline", "")) == "keep_me", "load failure should leave current runtime state unchanged")
	_free_if_node(save_manager)


func test_evaluate_overwrite_risk_returns_structured_confirmation_semantics() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Node = _make_save_manager()
	var snapshot: SaveSnapshot = _make_valid_snapshot(202)
	_expect(save_manager.save_snapshot_to_slot("slot_1", snapshot), "overwrite risk setup save should succeed")

	# Act
	var overwrite_result: Dictionary[String, Variant] = save_manager.evaluate_overwrite_risk("slot_1")

	# Assert
	_expect(not (overwrite_result.get("success", true) as bool), "occupied slot should require overwrite confirmation")
	_expect(overwrite_result.get("requires_confirmation", false) as bool, "overwrite risk should require confirmation")
	_expect(String(overwrite_result.get("recovery_reason", "")) == "overwrite_requires_confirmation", "overwrite risk should expose overwrite confirmation reason")
	_expect(String(overwrite_result.get("recovery_action", "")) == "confirm_overwrite", "overwrite risk should expose confirm_overwrite action")
	_free_if_node(save_manager)


func test_delete_slot_without_confirmation_leaves_disk_state_unchanged() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Node = _make_save_manager()
	var snapshot: SaveSnapshot = _make_valid_snapshot(303)
	var slot_path: String = save_manager.resolve_slot_path("slot_1")
	_expect(save_manager.save_snapshot_to_slot("slot_1", snapshot), "delete cancel setup save should succeed")
	_expect(FileAccess.file_exists(slot_path), "delete cancel setup should create slot file")

	# Act
	var delete_result: Dictionary[String, Variant] = save_manager.delete_slot("slot_1", false)

	# Assert
	_expect(not (delete_result.get("success", true) as bool), "unconfirmed delete should not succeed")
	_expect(delete_result.get("requires_confirmation", false) as bool, "unconfirmed delete should require confirmation")
	_expect(FileAccess.file_exists(slot_path), "unconfirmed delete should leave disk state unchanged")
	_free_if_node(save_manager)


func test_recovery_flow_never_silently_restores_corrupted_snapshot() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Node = _make_save_manager()
	var restore_order: Array[String] = []
	var runtime_state: Dictionary[String, Variant] = {}
	_register_restore_tracking(save_manager, restore_order, runtime_state)
	var snapshot: SaveSnapshot = _make_valid_snapshot(404)
	_expect(save_manager.save_snapshot_to_slot("slot_1", snapshot), "corruption setup save should succeed")
	var slot_path: String = save_manager.resolve_slot_path("slot_1")
	var loaded_snapshot: SaveSnapshot = ResourceLoader.load(slot_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveSnapshot
	loaded_snapshot.economy_state["funds"] = 9999
	ResourceSaver.save(loaded_snapshot, slot_path)

	# Act
	var load_result: Dictionary[String, Variant] = save_manager.load_snapshot_from_slot("slot_1")
	var delete_result: Dictionary[String, Variant] = save_manager.delete_slot("slot_1", true)

	# Assert
	_expect(not (load_result.get("success", true) as bool), "corrupted snapshot should not restore successfully")
	_expect(String(load_result.get("recovery_reason", "")) == "corrupted", "corrupted snapshot should route to corrupted recovery")
	_expect(restore_order.is_empty(), "corrupted snapshot should never deserialize into authority state")
	_expect(delete_result.get("success", false) as bool, "confirmed delete should succeed for corrupted slot")
	_expect(delete_result.get("deleted", false) as bool, "confirmed delete should remove corrupted slot")
	_expect(not FileAccess.file_exists(slot_path), "confirmed delete should remove slot file from disk")
	_free_if_node(save_manager)


func _make_save_manager() -> Node:
	var save_manager: Node = SaveManagerScript.new()
	save_manager.set_save_directory_path(TEST_SAVE_DIRECTORY_PATH)
	return save_manager


func _register_restore_tracking(save_manager: Node, restore_order: Array[String], runtime_state: Dictionary[String, Variant]) -> void:
	for system_id: String in save_manager.get_required_system_ids():
		save_manager.register_system(system_id, func() -> Dictionary[String, Variant]: return {}, func(data: Dictionary[String, Variant]) -> bool:
			restore_order.append(system_id)
			runtime_state[system_id] = data.duplicate(true)
			return true
		)


func _make_valid_snapshot(seed: int) -> SaveSnapshot:
	var snapshot: SaveSnapshot = SaveSnapshotScript.new()
	snapshot.save_version = 1
	snapshot.timestamp = seed
	snapshot.playtime_seconds = float(seed)
	snapshot.ui_screen_id = "planning"
	snapshot.ui_stack_depth = 1
	snapshot.snapshot_metadata = {"seed": seed}
	snapshot.time_state = {
		"phase": "Planning",
		"timeline_position": 5,
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
		"scheduled_position": 5,
		"in_progress": false,
	}
	snapshot.economy_state = {"funds": 600}
	snapshot.town_state = {"facility_count": 2}
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
