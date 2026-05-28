extends SceneTree

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_stable_nodes_are_recoverable_save_points()
	test_match_in_progress_is_not_a_recoverable_save_point()
	test_unknown_or_missing_nodes_are_rejected_by_default()
	test_rejected_save_gate_blocks_commit_before_snapshot_assembly()
	if _failures.is_empty():
		print("STABLE_NODE_SAVE_GATE_TEST_PASS")
		_finish(0)
	else:
		for failure: String in _failures:
			push_error("STABLE_NODE_SAVE_GATE_TEST_FAIL: %s" % failure)
		_finish(1)


func test_stable_nodes_are_recoverable_save_points() -> void:
	# Arrange
	var save_manager: Variant = SaveManagerScript.new()
	var stable_nodes: Array[String] = [
		"Planning",
		"Match Trigger",
		"Post-Match Settlement",
		"Stage Settlement",
		"Season Settlement",
		"Offseason",
	]

	# Act / Assert
	for stable_node: String in stable_nodes:
		var time_state: Dictionary[String, Variant] = _to_typed_dictionary({"current_state": stable_node})
		var gate_result: Dictionary[String, Variant] = save_manager.evaluate_save_gate(time_state)
		_expect(gate_result["success"] as bool, "%s should be allowed by the stable save gate" % stable_node)
		_expect(gate_result["recoverable_stable_node"] as bool, "%s should be marked recoverable" % stable_node)

	_free_if_node(save_manager)


func test_match_in_progress_is_not_a_recoverable_save_point() -> void:
	# Arrange
	var save_manager: Variant = SaveManagerScript.new()

	# Act
	var gate_result: Dictionary[String, Variant] = save_manager.evaluate_save_gate(_to_typed_dictionary({"current_state": "Match In Progress"}))

	# Assert
	_expect(not (gate_result["success"] as bool), "Match In Progress should be rejected by the stable save gate")
	_expect(not (gate_result["recoverable_stable_node"] as bool), "Match In Progress should not be marked recoverable")

	_free_if_node(save_manager)


func test_unknown_or_missing_nodes_are_rejected_by_default() -> void:
	# Arrange
	var save_manager: Variant = SaveManagerScript.new()

	# Act
	var unknown_gate_result: Dictionary[String, Variant] = save_manager.evaluate_save_gate(_to_typed_dictionary({"current_state": "Unknown State"}))
	var missing_gate_result: Dictionary[String, Variant] = save_manager.evaluate_save_gate(_to_typed_dictionary({}))

	# Assert
	_expect(not (unknown_gate_result["success"] as bool), "unknown runtime nodes should be rejected")
	_expect(not (missing_gate_result["success"] as bool), "missing runtime nodes should be rejected")

	_free_if_node(save_manager)


func test_rejected_save_gate_blocks_commit_before_snapshot_assembly() -> void:
	# Arrange
	var save_manager: Variant = SaveManagerScript.new()
	save_manager.register_system("time", _serialize_payload.bind({
		"current_state": "Match In Progress",
		"timeline_position": 5,
		"phase": "match",
	}), _capture_deserialize)
	save_manager.register_system("town", _serialize_payload.bind({"facility_count": 3}), _capture_deserialize)
	save_manager.register_system("player", _serialize_payload.bind({"roster_count": 16}), _capture_deserialize)
	save_manager.register_system("league", _serialize_payload.bind({"rank": 4}), _capture_deserialize)
	save_manager.register_system("economy", _serialize_payload.bind({"funds": 1000}), _capture_deserialize)
	save_manager.register_system("match", _serialize_payload.bind({
		"scheduled_position": 4,
		"in_progress": true,
	}), _capture_deserialize)

	# Act
	var commit_result: Dictionary[String, Variant] = save_manager.commit_registered_snapshot("slot_1", _to_typed_dictionary({
		"ui_screen_id": "home",
		"ui_stack_depth": 1,
	}))

	# Assert
	_expect(not (commit_result["success"] as bool), "commit should be blocked when the save gate rejects the current runtime node")
	_expect(commit_result.get("snapshot", null) == null, "blocked commit should not proceed to snapshot assembly")

	_free_if_node(save_manager)


func _serialize_payload(payload: Dictionary) -> Dictionary:
	return payload.duplicate(true)


func _capture_deserialize(_payload: Dictionary) -> void:
	pass


func _finish(exit_code: int) -> void:
	call_deferred("_quit_with_code", exit_code)


func _quit_with_code(exit_code: int) -> void:
	quit(exit_code)


func _to_typed_dictionary(source: Dictionary) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	for key_variant: Variant in source:
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary


func _free_if_node(value: Variant) -> void:
	if value is Node:
		(value as Node).free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
