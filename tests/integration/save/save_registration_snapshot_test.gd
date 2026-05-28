extends Node

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const SaveSnapshotScript: Script = preload("res://src/autoload/save_snapshot.gd")
const TEST_SAVE_DIRECTORY_PATH: String = "user://test_saves/save_registration_snapshot"

var _failures: Array[String] = []


func _ready() -> void:
	test_save_manager_registers_required_system_pairs()
	test_save_manager_returns_empty_state_when_serializer_does_not_return_dictionary()
	test_save_manager_assembles_registered_systems_into_one_snapshot()
	test_save_manager_fails_snapshot_assembly_when_required_system_missing()
	test_save_manager_blocks_commit_when_cross_system_consistency_ratio_is_below_one()
	_cleanup_save_directory()
	if _failures.is_empty():
		print("SAVE_REGISTRATION_SNAPSHOT_TEST_PASS")
		_finish(0)
	else:
		for failure: String in _failures:
			push_error("SAVE_REGISTRATION_SNAPSHOT_TEST_FAIL: %s" % failure)
		_finish(1)


func test_save_manager_registers_required_system_pairs() -> void:
	# Arrange
	var save_manager: Variant = SaveManagerScript.new()
	save_manager.set_save_directory_path(TEST_SAVE_DIRECTORY_PATH)
	var deserialize_callable := _capture_deserialize.bind("time")

	# Act
	var valid_registration: bool = save_manager.register_system("time", _serialize_payload.bind({"phase": "planning"}), deserialize_callable)
	var empty_id_registration: bool = save_manager.register_system("", _serialize_payload.bind({}), deserialize_callable)
	var missing_serialize_registration: bool = save_manager.register_system("town", Callable(), deserialize_callable)
	var replacement_registration: bool = save_manager.register_system("time", _serialize_payload.bind({"phase": "match"}), deserialize_callable)
	var serialized_time_state: Dictionary[String, Variant] = save_manager.serialize_registered_system("time")

	# Assert
	_expect(valid_registration, "paired callables should register successfully")
	_expect(not empty_id_registration, "empty system id should be rejected")
	_expect(not missing_serialize_registration, "missing serialize callable should be rejected")
	_expect(replacement_registration, "duplicate registration should replace an existing system contract")
	_expect(save_manager.has_registered_system("time"), "time should be marked as registered")
	_expect(String(serialized_time_state.get("phase", "")) == "match", "latest registration should win for duplicate system ids")
	_free_if_node(save_manager)


func test_save_manager_returns_empty_state_when_serializer_does_not_return_dictionary() -> void:
	# Arrange
	var save_manager: Variant = SaveManagerScript.new()
	save_manager.set_save_directory_path(TEST_SAVE_DIRECTORY_PATH)
	var deserialize_callable := _capture_deserialize.bind("time")
	save_manager.register_system("time", _serialize_invalid_payload, deserialize_callable)

	# Act
	var serialized_time_state: Dictionary[String, Variant] = save_manager.serialize_registered_system("time")

	# Assert
	_expect(serialized_time_state.is_empty(), "serializer returning non-dictionary should produce an empty serialized state")
	_free_if_node(save_manager)


func test_save_manager_assembles_registered_systems_into_one_snapshot() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Variant = SaveManagerScript.new()
	save_manager.set_save_directory_path(TEST_SAVE_DIRECTORY_PATH)
	_register_required_systems(save_manager, false)
	var ui_state: Dictionary[String, Variant] = {
		"ui_screen_id": "home",
		"ui_stack_depth": 2,
		"playtime_seconds": 88.5,
		"timestamp": 4242,
		"town_name": "Town Alpha",
	}
	var slot_metadata: Dictionary[String, Variant] = {
		"town_name": "Town Alpha",
		"season": 1,
	}

	# Act
	var assembly: Dictionary[String, Variant] = save_manager.assemble_snapshot(ui_state, slot_metadata, 88.5, 4242)
	var snapshot: Variant = assembly["snapshot"]
	var commit_result: Dictionary[String, Variant] = save_manager.commit_registered_snapshot("slot_1", ui_state, slot_metadata, 88.5, 4242)
	var saved_snapshot: Resource = ResourceLoader.load(save_manager.resolve_slot_path("slot_1"), "", ResourceLoader.CACHE_MODE_IGNORE)

	# Assert
	_expect(assembly["success"] as bool, "assembly should succeed when all required systems are registered")
	_expect(snapshot != null and snapshot.get_script() == SaveSnapshotScript, "assembly should return a SaveSnapshot resource")
	_expect(is_equal_approx(assembly["save_snapshot_completeness"] as float, 1.0), "assembled snapshot completeness should equal 1")
	_expect(is_equal_approx(assembly["cross_system_consistency_ratio"] as float, 1.0), "assembled snapshot consistency should equal 1")
	_expect(String(snapshot.ui_screen_id) == "home", "assembled snapshot should preserve ui_screen_id")
	_expect(int(snapshot.ui_stack_depth) == 2, "assembled snapshot should preserve ui_stack_depth")
	_expect(String(snapshot.time_state.get("phase", "")) == "planning", "assembled snapshot should include time state")
	_expect(int(snapshot.player_state.get("roster_count", 0)) == 16, "assembled snapshot should include player state")
	_expect(commit_result["success"] as bool, "commit should succeed when assembly is complete and consistent")
	_expect(saved_snapshot != null and saved_snapshot.get_script() == SaveSnapshotScript, "commit should write the assembled snapshot through SaveManager")
	_free_if_node(save_manager)


func test_save_manager_fails_snapshot_assembly_when_required_system_missing() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Variant = SaveManagerScript.new()
	save_manager.set_save_directory_path(TEST_SAVE_DIRECTORY_PATH)
	_register_required_systems(save_manager, false, "match")
	var ui_state: Dictionary[String, Variant] = {
		"ui_screen_id": "home",
		"ui_stack_depth": 1,
	}

	# Act
	var assembly: Dictionary[String, Variant] = save_manager.assemble_snapshot(ui_state)
	var commit_result: Dictionary[String, Variant] = save_manager.commit_registered_snapshot("slot_1", ui_state)
	var slot_path: String = save_manager.resolve_slot_path("slot_1")

	# Assert
	_expect(not (assembly["success"] as bool), "assembly should fail when a required system is missing")
	_expect((assembly["missing_systems"] as Array[String]).has("match"), "assembly should report the missing required system")
	_expect(is_equal_approx(assembly["save_snapshot_completeness"] as float, 0.0), "failed assembly should report zero completeness")
	_expect(is_equal_approx(assembly["cross_system_consistency_ratio"] as float, 0.0), "failed assembly should report zero consistency")
	_expect(not (commit_result["success"] as bool), "commit should fail when a required system is missing")
	_expect(not FileAccess.file_exists(slot_path), "failed commit should not write a slot file")
	_free_if_node(save_manager)


func test_save_manager_blocks_commit_when_cross_system_consistency_ratio_is_below_one() -> void:
	# Arrange
	_cleanup_save_directory()
	var save_manager: Variant = SaveManagerScript.new()
	save_manager.set_save_directory_path(TEST_SAVE_DIRECTORY_PATH)
	_register_required_systems(save_manager, true)
	var ui_state: Dictionary[String, Variant] = {
		"ui_screen_id": "home",
		"ui_stack_depth": 1,
	}

	# Act
	var assembly: Dictionary[String, Variant] = save_manager.assemble_snapshot(ui_state)
	var commit_result: Dictionary[String, Variant] = save_manager.commit_registered_snapshot("slot_2", ui_state)
	var slot_path: String = save_manager.resolve_slot_path("slot_2")

	# Assert
	_expect(not (assembly["success"] as bool), "assembly should fail when consistency checks do not all pass")
	_expect((assembly["cross_system_consistency_ratio"] as float) < 1.0, "consistency ratio should be below 1 when cross-system state is inconsistent")
	_expect(not (commit_result["success"] as bool), "commit should fail when consistency ratio is below 1")
	_expect(not FileAccess.file_exists(slot_path), "consistency failure should not write a slot file")
	_free_if_node(save_manager)


func _register_required_systems(save_manager: Variant, make_match_inconsistent: bool, excluded_system_id: String = "") -> void:
	var required_states: Dictionary[String, Variant] = {
		"time": {
			"phase": "planning",
			"timeline_position": 5 if make_match_inconsistent else 3,
			"current_state": "Planning" if make_match_inconsistent else "Match Trigger",
		},
		"town": {"facility_count": 3},
		"player": {"roster_count": 16},
		"league": {"rank": 4},
		"economy": {"funds": 1000},
		"match": {
			"last_match_id": "match_001",
			"scheduled_position": 4,
			"in_progress": make_match_inconsistent,
			"state": 0,
			"state_name": "idle",
			"pending_match_context": {},
			"result_packet": {},
			"formal_state_history": [],
			"confirmed_results_by_match_id": {},
		},
	}
	for system_id: String in required_states.keys():
		if system_id == excluded_system_id:
			continue
		save_manager.register_system(system_id, _serialize_payload.bind(required_states[system_id]), _capture_deserialize.bind(system_id))


func _serialize_payload(payload: Dictionary) -> Dictionary:
	return payload.duplicate(true)


func _serialize_invalid_payload() -> Variant:
	return "invalid"


func _capture_deserialize(_system_id: String, _payload: Dictionary) -> void:
	pass


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
