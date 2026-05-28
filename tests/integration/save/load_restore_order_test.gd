extends Node

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const SaveSnapshotScript: Script = preload("res://src/autoload/save_snapshot.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_restore_snapshot_deserializes_systems_in_fixed_dependency_order()
	test_restore_snapshot_exposes_upstream_restored_state_to_downstream_systems()
	test_restore_snapshot_aborts_on_system_failure_without_continuing_remaining_systems()
	test_restore_snapshot_rejects_match_in_progress_snapshot()
	if _failures.is_empty():
		print("LOAD_RESTORE_ORDER_TEST_PASS")
		_finish(0)
	else:
		for failure: String in _failures:
			push_error("LOAD_RESTORE_ORDER_TEST_FAIL: %s" % failure)
		_finish(1)


func test_restore_snapshot_deserializes_systems_in_fixed_dependency_order() -> void:
	# Arrange
	var save_manager: Node = SaveManagerScript.new()
	var restore_order: Array[String] = []
	var runtime_state: Dictionary[String, Variant] = {}
	_register_restore_doubles(save_manager, restore_order, runtime_state)
	var snapshot: SaveSnapshot = _make_restore_snapshot()

	# Act
	var restore_result: Dictionary[String, Variant] = save_manager.restore_snapshot(snapshot)

	# Assert
	_expect(restore_result.get("success", false) as bool, "restore should succeed when all systems deserialize")
	_expect(restore_order == save_manager.get_required_system_ids(), "restore should follow required dependency order")
	_expect((restore_result.get("restored_systems", []) as Array[String]) == save_manager.get_required_system_ids(), "restore result should report the full dependency order")
	_free_if_node(save_manager)


func test_restore_snapshot_exposes_upstream_restored_state_to_downstream_systems() -> void:
	# Arrange
	var save_manager: Node = SaveManagerScript.new()
	var restore_order: Array[String] = []
	var runtime_state: Dictionary[String, Variant] = {}
	var observed_dependencies: Dictionary[String, Variant] = {}
	_register_restore_doubles(save_manager, restore_order, runtime_state, "", observed_dependencies)
	var snapshot: SaveSnapshot = _make_restore_snapshot()

	# Act
	var restore_result: Dictionary[String, Variant] = save_manager.restore_snapshot(snapshot)

	# Assert
	_expect(restore_result.get("success", false) as bool, "restore should succeed for dependency visibility check")
	_expect(int(observed_dependencies.get("town_timeline_position", -1)) == 7, "town restore should observe restored time state")
	_expect(int(observed_dependencies.get("player_facility_count", -1)) == 3, "player restore should observe restored town state")
	_expect(int(observed_dependencies.get("league_roster_count", -1)) == 18, "league restore should observe restored player state")
	_expect(int(observed_dependencies.get("economy_rank", -1)) == 2, "economy restore should observe restored league state")
	_expect(int(observed_dependencies.get("match_funds", -1)) == 900, "match restore should observe restored economy state")
	_free_if_node(save_manager)


func test_restore_snapshot_aborts_on_system_failure_without_continuing_remaining_systems() -> void:
	# Arrange
	var save_manager: Node = SaveManagerScript.new()
	var restore_order: Array[String] = []
	var runtime_state: Dictionary[String, Variant] = {}
	_register_restore_doubles(save_manager, restore_order, runtime_state, "economy")
	var snapshot: SaveSnapshot = _make_restore_snapshot()

	# Act
	var restore_result: Dictionary[String, Variant] = save_manager.restore_snapshot(snapshot)

	# Assert
	_expect(not (restore_result.get("success", true) as bool), "restore should fail when a system deserialize fails")
	_expect(String(restore_result.get("failed_system", "")) == "economy", "restore should report the failing system")
	_expect(restore_order == ["time", "town", "player", "league", "economy"], "restore should stop after the failing system")
	_expect(not runtime_state.has("match"), "restore should not apply downstream systems after failure")
	_free_if_node(save_manager)


func test_restore_snapshot_rejects_match_in_progress_snapshot() -> void:
	# Arrange
	var save_manager: Node = SaveManagerScript.new()
	var restore_order: Array[String] = []
	var runtime_state: Dictionary[String, Variant] = {}
	_register_restore_doubles(save_manager, restore_order, runtime_state)
	var snapshot: SaveSnapshot = _make_restore_snapshot()
	snapshot.match_state["in_progress"] = true
	snapshot.time_state["current_state"] = "Match In Progress"
	snapshot.snapshot_metadata["integrity_hash"] = _compute_integrity_hash(snapshot)

	# Act
	var restore_result: Dictionary[String, Variant] = save_manager.restore_snapshot(snapshot)

	# Assert
	_expect(not (restore_result.get("success", true) as bool), "match-in-progress snapshot should be rejected")
	_expect(String(restore_result.get("failed_system", "")) == "match", "match-in-progress rejection should attribute failure to match")
	_expect(restore_order.is_empty(), "match-in-progress rejection should abort before deserializing any system")
	_free_if_node(save_manager)


func _register_restore_doubles(save_manager: Node, restore_order: Array[String], runtime_state: Dictionary[String, Variant], failing_system_id: String = "", observed_dependencies: Dictionary[String, Variant] = {}) -> void:
	save_manager.register_system("time", func() -> Dictionary[String, Variant]: return {}, _make_deserialize_callable("time", restore_order, runtime_state, failing_system_id, observed_dependencies))
	save_manager.register_system("town", func() -> Dictionary[String, Variant]: return {}, _make_deserialize_callable("town", restore_order, runtime_state, failing_system_id, observed_dependencies))
	save_manager.register_system("player", func() -> Dictionary[String, Variant]: return {}, _make_deserialize_callable("player", restore_order, runtime_state, failing_system_id, observed_dependencies))
	save_manager.register_system("league", func() -> Dictionary[String, Variant]: return {}, _make_deserialize_callable("league", restore_order, runtime_state, failing_system_id, observed_dependencies))
	save_manager.register_system("economy", func() -> Dictionary[String, Variant]: return {}, _make_deserialize_callable("economy", restore_order, runtime_state, failing_system_id, observed_dependencies))
	save_manager.register_system("match", func() -> Dictionary[String, Variant]: return {}, _make_deserialize_callable("match", restore_order, runtime_state, failing_system_id, observed_dependencies))


func _make_deserialize_callable(system_id: String, restore_order: Array[String], runtime_state: Dictionary[String, Variant], failing_system_id: String, observed_dependencies: Dictionary[String, Variant]) -> Callable:
	return func(data: Dictionary[String, Variant]) -> bool:
		restore_order.append(system_id)
		match system_id:
			"town":
				observed_dependencies["town_timeline_position"] = int((runtime_state.get("time", {}) as Dictionary).get("timeline_position", -1))
			"player":
				observed_dependencies["player_facility_count"] = int((runtime_state.get("town", {}) as Dictionary).get("facility_count", -1))
			"league":
				observed_dependencies["league_roster_count"] = int((runtime_state.get("player", {}) as Dictionary).get("roster_count", -1))
			"economy":
				observed_dependencies["economy_rank"] = int((runtime_state.get("league", {}) as Dictionary).get("rank", -1))
			"match":
				observed_dependencies["match_funds"] = int((runtime_state.get("economy", {}) as Dictionary).get("funds", -1))
		if system_id == failing_system_id:
			return false
		runtime_state[system_id] = data.duplicate(true)
		return true


func _make_restore_snapshot() -> SaveSnapshot:
	var snapshot: SaveSnapshot = SaveSnapshotScript.new()
	snapshot.save_version = 1
	snapshot.timestamp = 120
	snapshot.playtime_seconds = 12.0
	snapshot.ui_screen_id = "planning"
	snapshot.ui_stack_depth = 1
	snapshot.snapshot_metadata = {"seed": 77}
	snapshot.time_state = {
		"phase": "Planning",
		"timeline_position": 7,
		"current_state": "Planning",
	}
	snapshot.town_state = {"facility_count": 3}
	snapshot.player_state = {"roster_count": 18}
	snapshot.league_state = {"rank": 2}
	snapshot.economy_state = {"funds": 900}
	snapshot.match_state = {
		"state": 0,
		"state_name": "Planning",
		"pending_match_context": {},
		"result_packet": {},
		"formal_state_history": [],
		"confirmed_results_by_match_id": {},
		"scheduled_position": 7,
		"in_progress": false,
	}
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
