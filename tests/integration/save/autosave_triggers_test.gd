extends Node

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const SaveSnapshotScript: Script = preload("res://src/autoload/save_snapshot.gd")
const TEST_SAVE_DIRECTORY_PATH: String = "user://test_saves/autosave_triggers"

class ScreenManagerStub:
	extends Node

	var active_screen_id: String = "home"
	var stack_depth: int = 1

	func get_active_screen_id() -> String:
		return active_screen_id

	func get_screen_stack_depth() -> int:
		return stack_depth

var _failures: Array[String] = []


func _ready() -> void:
	test_autosave_triggers_write_to_autosave_slot_at_stable_nodes()
	test_autosave_requests_defer_at_unstable_nodes_until_next_stable_phase()
	test_repeated_deferred_autosave_requests_coalesce_into_one_latest_snapshot()
	test_close_request_obeys_same_stable_node_rule()
	_cleanup_save_directory()
	if _failures.is_empty():
		print("AUTOSAVE_TRIGGERS_TEST_PASS")
		_finish(0)
	else:
		for failure: String in _failures:
			push_error("AUTOSAVE_TRIGGERS_TEST_FAIL: %s" % failure)
		_finish(1)


func test_autosave_triggers_write_to_autosave_slot_at_stable_nodes() -> void:
	# Arrange
	_cleanup_save_directory()
	var event_bus: Node = EventBusScript.new()
	var save_manager: Node = _make_save_manager(event_bus)
	var autosave_path: String = save_manager.resolve_slot_path("autosave")

	# Act / Assert
	for event_name: String in ["match_completed", "time_season_ended", "town_facility_completed"]:
		_cleanup_save_directory()
		event_bus.call("emit", event_name, {"event_name": event_name})
		_expect(FileAccess.file_exists(autosave_path), "%s should trigger autosave file creation at stable nodes" % event_name)
		var saved_snapshot: Resource = ResourceLoader.load(autosave_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		_expect(saved_snapshot != null and saved_snapshot.get_script() == SaveSnapshotScript, "%s should write a SaveSnapshot to autosave slot" % event_name)
		_expect(String(saved_snapshot.ui_screen_id) == "home", "%s autosave should use resolved UI screen id" % event_name)

	_cleanup_save_directory()
	var close_result: Dictionary[String, Variant] = save_manager.handle_close_request_autosave()
	var close_snapshot: Resource = ResourceLoader.load(autosave_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	_expect(close_result.get("success", false) as bool, "close request should autosave immediately at stable nodes")
	_expect(FileAccess.file_exists(autosave_path), "close request should target autosave slot")
	_expect(close_snapshot != null and close_snapshot.get_script() == SaveSnapshotScript, "close request should write a SaveSnapshot")
	_free_if_node(save_manager)
	_free_if_node(event_bus)


func test_autosave_requests_defer_at_unstable_nodes_until_next_stable_phase() -> void:
	# Arrange
	_cleanup_save_directory()
	var event_bus: Node = EventBusScript.new()
	var save_manager: Node = _make_save_manager(event_bus, "Match In Progress")
	var autosave_path: String = save_manager.resolve_slot_path("autosave")

	# Act
	event_bus.call("emit", "match_completed", {"event_name": "match_completed"})
	var deferred_before_flush: bool = bool(save_manager.get("_pending_autosave_requested"))
	var file_exists_before_flush: bool = FileAccess.file_exists(autosave_path)
	event_bus.call("emit", "time_phase_changed", {"old_phase": "Match In Progress", "new_phase": "Planning"})
	var deferred_after_flush: bool = bool(save_manager.get("_pending_autosave_requested"))
	var file_exists_after_flush: bool = FileAccess.file_exists(autosave_path)

	# Assert
	_expect(deferred_before_flush, "unstable-node autosave should enter deferred state")
	_expect(not file_exists_before_flush, "unstable-node autosave should not write immediately")
	_expect(not deferred_after_flush, "pending autosave should flush after next stable phase")
	_expect(file_exists_after_flush, "pending autosave should write once stable phase arrives")
	_free_if_node(save_manager)
	_free_if_node(event_bus)


func test_repeated_deferred_autosave_requests_coalesce_into_one_latest_snapshot() -> void:
	# Arrange
	_cleanup_save_directory()
	var event_bus: Node = EventBusScript.new()
	var save_manager: Node = _make_save_manager(event_bus, "Match In Progress")
	var screen_manager: ScreenManagerStub = save_manager.get("_screen_manager_override") as ScreenManagerStub
	var autosave_path: String = save_manager.resolve_slot_path("autosave")

	# Act
	screen_manager.active_screen_id = "match_live"
	var first_ui_state: Dictionary[String, Variant] = {"ui_screen_id": "match_live", "ui_stack_depth": 2}
	var first_metadata: Dictionary[String, Variant] = {"request": 1}
	var first_request: Dictionary[String, Variant] = save_manager.request_autosave("event_a", first_ui_state, first_metadata, 10.0, 100)
	screen_manager.active_screen_id = "post_match"
	var second_ui_state: Dictionary[String, Variant] = {"ui_screen_id": "post_match", "ui_stack_depth": 3}
	var second_metadata: Dictionary[String, Variant] = {"request": 2}
	var second_request: Dictionary[String, Variant] = save_manager.request_autosave("event_b", second_ui_state, second_metadata, 20.0, 200)
	event_bus.call("emit", "time_phase_changed", {"old_phase": "Match In Progress", "new_phase": "Post-Match Settlement"})
	var saved_snapshot: Resource = ResourceLoader.load(autosave_path, "", ResourceLoader.CACHE_MODE_IGNORE)

	# Assert
	_expect(not (first_request.get("success", false) as bool) and (first_request.get("deferred", false) as bool), "first unstable autosave request should defer")
	_expect(not (second_request.get("success", false) as bool) and (second_request.get("deferred", false) as bool), "repeated unstable autosave request should also defer")
	_expect(FileAccess.file_exists(autosave_path), "coalesced deferred autosave should eventually write one snapshot")
	_expect(saved_snapshot != null and saved_snapshot.get_script() == SaveSnapshotScript, "coalesced autosave should write a SaveSnapshot")
	_expect(String(saved_snapshot.ui_screen_id) == "post_match", "coalesced autosave should keep the latest ui state")
	_expect(int(saved_snapshot.ui_stack_depth) == 3, "coalesced autosave should keep the latest stack depth")
	_expect(int(saved_snapshot.timestamp) == 200, "coalesced autosave should keep the latest timestamp")
	_expect(int(saved_snapshot.snapshot_metadata.get("request", 0)) == 2, "coalesced autosave should keep the latest metadata")
	_free_if_node(save_manager)
	_free_if_node(event_bus)


func test_close_request_obeys_same_stable_node_rule() -> void:
	# Arrange
	_cleanup_save_directory()
	var stable_event_bus: Node = EventBusScript.new()
	var stable_save_manager: Node = _make_save_manager(stable_event_bus, "Planning")
	var unstable_event_bus: Node = EventBusScript.new()
	var unstable_save_manager: Node = _make_save_manager(unstable_event_bus, "Match In Progress")
	var autosave_path: String = stable_save_manager.resolve_slot_path("autosave")

	# Act
	var stable_result: Dictionary[String, Variant] = stable_save_manager.handle_close_request_autosave()
	_cleanup_save_directory()
	var unstable_result: Dictionary[String, Variant] = unstable_save_manager.handle_close_request_autosave()
	var unstable_pending: bool = bool(unstable_save_manager.get("_pending_autosave_requested"))

	# Assert
	_expect(stable_result.get("success", false) as bool, "close request should autosave immediately at stable nodes")
	_expect(not (unstable_result.get("success", false) as bool) and (unstable_result.get("deferred", false) as bool), "close request should defer at unstable nodes")
	_expect(unstable_pending, "unstable close request should leave one pending autosave")
	_expect(not FileAccess.file_exists(autosave_path), "unstable close request should not write immediately")
	_free_if_node(stable_save_manager)
	_free_if_node(stable_event_bus)
	_free_if_node(unstable_save_manager)
	_free_if_node(unstable_event_bus)


func _make_save_manager(event_bus: Node, current_state: String = "Planning") -> Node:
	var save_manager: Node = SaveManagerScript.new()
	save_manager.set_save_directory_path(TEST_SAVE_DIRECTORY_PATH)
	save_manager.set_event_bus_for_testing(event_bus)
	var screen_manager := ScreenManagerStub.new()
	save_manager.set_screen_manager_for_testing(screen_manager)
	_register_required_systems(save_manager, event_bus, current_state)
	save_manager._ready()
	return save_manager


func _register_required_systems(save_manager: Node, event_bus: Node, current_state: String) -> void:
	var runtime_state: Dictionary[String, Variant] = {
		"current_state": current_state,
	}
	var runtime_state_callback: Callable = Callable(self, "_update_runtime_state").bind(runtime_state)
	event_bus.call("subscribe", "time_phase_changed", runtime_state_callback)
	save_manager.set_meta("test_event_bus", event_bus)
	save_manager.set_meta("test_runtime_state_callback", runtime_state_callback)
	save_manager.register_system("time", _serialize_time_state.bind(runtime_state), _capture_deserialize.bind("time"))
	save_manager.register_system("town", _serialize_payload.bind({"facility_count": 1}), _capture_deserialize.bind("town"))
	save_manager.register_system("player", _serialize_payload.bind({"roster_count": 16}), _capture_deserialize.bind("player"))
	save_manager.register_system("league", _serialize_payload.bind({"rank": 2}), _capture_deserialize.bind("league"))
	save_manager.register_system("economy", _serialize_payload.bind({"funds": 500}), _capture_deserialize.bind("economy"))
	save_manager.register_system("match", _serialize_match_state.bind(runtime_state), _capture_deserialize.bind("match"))


func _serialize_payload(payload: Dictionary) -> Dictionary:
	return payload.duplicate(true)


func _serialize_time_state(runtime_state: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var current_state: String = String(runtime_state.get("current_state", "Planning"))
	return {
		"phase": current_state,
		"timeline_position": 3,
		"current_state": current_state,
	}


func _serialize_match_state(runtime_state: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var current_state: String = String(runtime_state.get("current_state", "Planning"))
	return {
		"state": 0,
		"state_name": current_state,
		"pending_match_context": {},
		"result_packet": {},
		"formal_state_history": [],
		"confirmed_results_by_match_id": {},
		"scheduled_position": 4,
		"in_progress": current_state == "Match In Progress",
	}


func _update_runtime_state(_event_name: String, payload: Dictionary, runtime_state: Dictionary[String, Variant]) -> void:
	runtime_state["current_state"] = String(payload.get("new_phase", runtime_state.get("current_state", "Planning")))


func _capture_deserialize(_system_id: String, _payload: Dictionary) -> void:
	pass


func _finish(exit_code: int) -> void:
	call_deferred("_quit_with_code", exit_code)


func _quit_with_code(exit_code: int) -> void:
	get_tree().quit(exit_code)


func _free_if_node(value: Variant) -> void:
	if value is Node:
		var node: Node = value as Node
		if node.has_meta("test_event_bus") and node.has_meta("test_runtime_state_callback"):
			var event_bus: Node = node.get_meta("test_event_bus") as Node
			var runtime_state_callback: Callable = node.get_meta("test_runtime_state_callback") as Callable
			if event_bus != null:
				event_bus.call("unsubscribe", "time_phase_changed", runtime_state_callback)
		node.free()


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
