extends Node

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const SaveSnapshotScript: Script = preload("res://src/autoload/save_snapshot.gd")
const TEST_SAVE_DIRECTORY_PATH: String = "user://saves"

var _failures: Array[String] = []


func _ready() -> void:
	test_save_manager_resolves_only_legal_slot_paths()
	test_save_manager_writes_valid_snapshots_only_to_approved_slot_paths()
	test_save_manager_rejects_wrong_resource_type_without_writing_slot()
	test_save_manager_rejects_incomplete_snapshot_without_replacing_existing_slot()
	test_save_manager_inspect_slot_reports_empty_valid_and_invalid_statuses()
	test_save_manager_inspect_slot_reports_corrupted_for_wrong_type_and_unparseable_files()
	_cleanup_save_directory()
	if _failures.is_empty():
		print("SAVE_SNAPSHOT_SLOTS_TEST_PASS")
		_finish(0)
	else:
		for failure: String in _failures:
			push_error("SAVE_SNAPSHOT_SLOTS_TEST_FAIL: %s" % failure)
		_finish(1)


func test_save_manager_resolves_only_legal_slot_paths() -> void:
	_cleanup_save_directory()
	var save_manager: Variant = SaveManagerScript.new()
	_expect(save_manager.resolve_slot_path("slot_1") == "user://saves/slot_1.tres", "slot_1 should resolve to canonical path")
	_expect(save_manager.resolve_slot_path("slot_2") == "user://saves/slot_2.tres", "slot_2 should resolve to canonical path")
	_expect(save_manager.resolve_slot_path("slot_3") == "user://saves/slot_3.tres", "slot_3 should resolve to canonical path")
	_expect(save_manager.resolve_slot_path("autosave") == "user://saves/autosave.tres", "autosave should resolve to canonical path")
	_expect(save_manager.resolve_slot_path("slot_4").is_empty(), "unknown manual slot should be rejected")
	_expect(save_manager.resolve_slot_path("../slot_1").is_empty(), "path traversal slot id should be rejected")
	_free_if_node(save_manager)


func test_save_manager_writes_valid_snapshots_only_to_approved_slot_paths() -> void:
	_cleanup_save_directory()
	var save_manager: Variant = SaveManagerScript.new()
	var legal_slots: Array[String] = ["slot_1", "slot_2", "slot_3", "autosave"]
	for slot_id: String in legal_slots:
		var snapshot: Variant = _build_valid_snapshot(slot_id)
		_expect(save_manager.save_snapshot_to_slot(slot_id, snapshot), "valid snapshot should save successfully for %s" % slot_id)
		var path: String = save_manager.resolve_slot_path(slot_id)
		_expect(FileAccess.file_exists(path), "save file should exist for %s" % slot_id)
		var loaded_resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		_expect(loaded_resource != null and loaded_resource.get_script() == SaveSnapshotScript, "saved resource should reload as SaveSnapshot for %s" % slot_id)
	_expect(not save_manager.save_snapshot_to_slot("bad_slot", _build_valid_snapshot("illegal")), "illegal slot should be rejected")
	_free_if_node(save_manager)


func test_save_manager_rejects_wrong_resource_type_without_writing_slot() -> void:
	_cleanup_save_directory()
	var save_manager: Variant = SaveManagerScript.new()
	var slot_path: String = save_manager.resolve_slot_path("slot_1")
	var wrong_type_resource: Resource = Resource.new()
	_expect(not save_manager.save_snapshot_to_slot("slot_1", wrong_type_resource), "wrong resource type should be rejected")
	_expect(not FileAccess.file_exists(slot_path), "wrong resource type should not create a slot file")
	_free_if_node(save_manager)


func test_save_manager_rejects_incomplete_snapshot_without_replacing_existing_slot() -> void:
	_cleanup_save_directory()
	var save_manager: Variant = SaveManagerScript.new()
	var original_snapshot: Variant = _build_valid_snapshot("baseline")
	_expect(save_manager.save_snapshot_to_slot("slot_1", original_snapshot), "baseline snapshot should save successfully")
	var incomplete_snapshot: Variant = _build_valid_snapshot("broken")
	incomplete_snapshot.ui_screen_id = ""
	var validation: Dictionary[String, Variant] = save_manager.validate_snapshot(incomplete_snapshot)
	_expect(not (validation["is_valid"] as bool), "incomplete snapshot should fail validation")
	_expect((validation["save_snapshot_completeness"] as float) < 1.0, "incomplete snapshot completeness should be less than 1")
	_expect(not save_manager.save_snapshot_to_slot("slot_1", incomplete_snapshot), "incomplete snapshot should not overwrite an existing slot")
	var loaded_snapshot := ResourceLoader.load(save_manager.resolve_slot_path("slot_1"), "", ResourceLoader.CACHE_MODE_IGNORE)
	_expect(loaded_snapshot != null, "baseline slot should remain loadable after rejected overwrite")
	_expect(String(loaded_snapshot.snapshot_metadata.get("town_name", "")) == "Town baseline", "rejected overwrite must preserve original slot contents")
	_free_if_node(save_manager)


func test_save_manager_inspect_slot_reports_empty_valid_and_invalid_statuses() -> void:
	_cleanup_save_directory()
	var save_manager: Variant = SaveManagerScript.new()
	var empty_result: Dictionary[String, Variant] = save_manager.inspect_slot("slot_1")
	_expect(String(empty_result["status"]) == "empty", "missing slot should report empty")
	var valid_snapshot: Variant = _build_valid_snapshot("valid")
	_expect(save_manager.save_snapshot_to_slot("slot_1", valid_snapshot), "valid snapshot should save for inspect test")
	var valid_result: Dictionary[String, Variant] = save_manager.inspect_slot("slot_1")
	_expect(String(valid_result["status"]) == "valid", "complete snapshot should report valid")
	_expect(is_equal_approx(valid_result["save_snapshot_completeness"] as float, 1.0), "valid slot completeness should equal 1")
	var invalid_snapshot: Variant = _build_valid_snapshot("invalid")
	invalid_snapshot.ui_screen_id = ""
	_expect(_write_resource_directly(invalid_snapshot, save_manager.resolve_slot_path("slot_2")) == OK, "test setup should write invalid snapshot directly")
	var invalid_result: Dictionary[String, Variant] = save_manager.inspect_slot("slot_2")
	_expect(String(invalid_result["status"]) == "invalid", "incomplete SaveSnapshot should report invalid")
	_expect((invalid_result["save_snapshot_completeness"] as float) < 1.0, "invalid slot completeness should be less than 1")
	_free_if_node(save_manager)


func test_save_manager_inspect_slot_reports_corrupted_for_wrong_type_and_unparseable_files() -> void:
	_cleanup_save_directory()
	var save_manager: Variant = SaveManagerScript.new()
	var wrong_type_path: String = save_manager.resolve_slot_path("slot_3")
	var generic_resource: Resource = Resource.new()
	_expect(_write_resource_directly(generic_resource, wrong_type_path) == OK, "test setup should write wrong-type resource")
	var wrong_type_result: Dictionary[String, Variant] = save_manager.inspect_slot("slot_3")
	_expect(String(wrong_type_result["status"]) == "corrupted", "non-SaveSnapshot resource should report corrupted")
	var unparseable_path: String = save_manager.resolve_slot_path("autosave")
	_expect(_write_text_file(unparseable_path, "") == OK, "test setup should write zero-byte file contents")
	var unparseable_result: Dictionary[String, Variant] = save_manager.inspect_slot("autosave")
	_expect(String(unparseable_result["status"]) == "corrupted", "zero-byte file should report corrupted")
	_free_if_node(save_manager)


func _build_valid_snapshot(label: String) -> Variant:
	var snapshot: Variant = SaveSnapshotScript.new()
	snapshot.save_version = 1
	snapshot.timestamp = 123456 + label.length()
	snapshot.playtime_seconds = 42.5
	snapshot.ui_screen_id = "home_%s" % label
	snapshot.ui_stack_depth = 2
	snapshot.snapshot_metadata["town_name"] = "Town %s" % label
	snapshot.snapshot_metadata["season"] = 1
	snapshot.snapshot_metadata["league_tier"] = 2
	snapshot.time_state["phase"] = "planning"
	snapshot.player_state["roster_count"] = 16
	snapshot.match_state["last_match_id"] = "match_%s" % label
	snapshot.match_state["state"] = 0
	snapshot.match_state["state_name"] = "idle"
	snapshot.match_state["pending_match_context"] = {}
	snapshot.match_state["result_packet"] = {}
	snapshot.match_state["formal_state_history"] = []
	snapshot.match_state["confirmed_results_by_match_id"] = {}
	snapshot.economy_state["funds"] = 1000
	snapshot.town_state["facility_count"] = 3
	snapshot.league_state["rank"] = 4
	return snapshot


func _write_resource_directly(resource: Resource, path: String) -> int:
	var ensure_error: int = _ensure_save_directory_exists()
	if ensure_error != OK:
		return ensure_error
	return ResourceSaver.save(resource, path)


func _finish(exit_code: int) -> void:
	call_deferred("_quit_with_code", exit_code)


func _quit_with_code(exit_code: int) -> void:
	get_tree().quit(exit_code)


func _free_if_node(value: Variant) -> void:
	if value is Node:
		(value as Node).free()


func _write_text_file(path: String, content: String) -> int:
	var ensure_error: int = _ensure_save_directory_exists()
	if ensure_error != OK:
		return ensure_error
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	if not file.store_string(content):
		return ERR_FILE_CANT_WRITE

	file.flush()
	return OK


func _ensure_save_directory_exists() -> int:
	var absolute_save_directory_path: String = ProjectSettings.globalize_path(TEST_SAVE_DIRECTORY_PATH)
	if DirAccess.dir_exists_absolute(absolute_save_directory_path):
		return OK
	return DirAccess.make_dir_recursive_absolute(absolute_save_directory_path)


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
