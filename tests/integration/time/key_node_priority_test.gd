extends SceneTree

const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	await test_same_position_key_nodes_resolve_in_fixed_priority_order()
	await test_qualifying_chain_processes_all_eligible_nodes_without_skipping()
	await test_repeating_same_input_produces_same_state_sequence_event_sequence_and_final_state()
	await test_each_eligible_key_node_is_processed_exactly_once()
	await test_next_node_is_re_evaluated_from_newly_committed_stable_state_without_replaying_processed_nodes()
	if _failures.is_empty():
		print("KEY_NODE_PRIORITY_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("KEY_NODE_PRIORITY_TEST_FAIL: %s" % failure)
		quit(1)


func test_same_position_key_nodes_resolve_in_fixed_priority_order() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager(_priority_snapshot())

	# Act
	var resolution: Dictionary[String, Variant] = time_manager.resolve_current_key_nodes()
	var processed_sequence: Array[String] = resolution["processed_sequence"]

	# Assert
	_expect(processed_sequence == ["Match Trigger", "Post-Match Settlement", "Stage Settlement", "Season Settlement"], "same-position key nodes should resolve in fixed priority order")
	_expect(String(resolution["final_state"]) == "Season Settlement", "priority resolution should end at Season Settlement when all key nodes qualify")


func test_qualifying_chain_processes_all_eligible_nodes_without_skipping() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager(_priority_snapshot())

	# Act
	var resolution: Dictionary[String, Variant] = time_manager.resolve_current_key_nodes()
	var state_sequence: Array[String] = resolution["state_sequence"]

	# Assert
	_expect(state_sequence == ["Planning", "Match Trigger", "Post-Match Settlement", "Stage Settlement", "Season Settlement"], "qualifying chain should include every eligible stable state in order")


func test_repeating_same_input_produces_same_state_sequence_event_sequence_and_final_state() -> void:
	# Arrange
	var first_time_manager: Node = await _create_time_manager(_priority_snapshot())
	var second_time_manager: Node = await _create_time_manager(_priority_snapshot())

	# Act
	var first_resolution: Dictionary[String, Variant] = first_time_manager.resolve_current_key_nodes()
	var second_resolution: Dictionary[String, Variant] = second_time_manager.resolve_current_key_nodes()

	# Assert
	_expect((first_resolution["processed_sequence"] as Array[String]) == (second_resolution["processed_sequence"] as Array[String]), "repeating the same input should produce the same processed node sequence")
	_expect((first_resolution["state_sequence"] as Array[String]) == (second_resolution["state_sequence"] as Array[String]), "repeating the same input should produce the same state sequence")
	_expect(String(first_resolution["final_state"]) == String(second_resolution["final_state"]), "repeating the same input should produce the same final state")


func test_each_eligible_key_node_is_processed_exactly_once() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager(_priority_snapshot())

	# Act
	var resolution: Dictionary[String, Variant] = time_manager.resolve_current_key_nodes()
	var processed_sequence: Array[String] = resolution["processed_sequence"]

	# Assert
	_expect(_occurrence_count(processed_sequence, "Match Trigger") == 1, "Match Trigger should be processed exactly once")
	_expect(_occurrence_count(processed_sequence, "Post-Match Settlement") == 1, "Post-Match Settlement should be processed exactly once")
	_expect(_occurrence_count(processed_sequence, "Stage Settlement") == 1, "Stage Settlement should be processed exactly once")
	_expect(_occurrence_count(processed_sequence, "Season Settlement") == 1, "Season Settlement should be processed exactly once")


func test_next_node_is_re_evaluated_from_newly_committed_stable_state_without_replaying_processed_nodes() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager(_priority_snapshot())

	# Act
	var first_resolution: Dictionary[String, Variant] = time_manager.resolve_current_key_nodes()
	var second_resolution: Dictionary[String, Variant] = time_manager.resolve_current_key_nodes()

	# Assert
	_expect((first_resolution["processed_sequence"] as Array[String]) == ["Match Trigger", "Post-Match Settlement", "Stage Settlement", "Season Settlement"], "first resolution should process all newly eligible nodes in order")
	_expect((second_resolution["processed_sequence"] as Array[String]).is_empty(), "already processed nodes should not replay on the same committed state")
	_expect(String(second_resolution["final_state"]) == "Season Settlement", "re-evaluation should keep the committed stable state")


func _priority_snapshot() -> Dictionary[String, Variant]:
	return {
		"current_state": "Planning",
		"timeline_position": 5,
		"schedule_available": true,
		"match": {
			"scheduled_position": 5,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Priority FC",
			"next_match_display": "vs Priority FC",
		},
		"current_stage_progress": 3,
		"stage_progress_target": 3,
		"season_progress": {
			"completed_units": 10,
			"total_units": 10,
		},
	}


func _create_time_manager(snapshot: Dictionary[String, Variant]) -> Node:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.call_deferred("add_child", time_manager)
	await process_frame
	time_manager.apply_snapshot(snapshot)
	return time_manager


func _occurrence_count(values: Array[String], expected: String) -> int:
	var count: int = 0
	for value: String in values:
		if value == expected:
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
