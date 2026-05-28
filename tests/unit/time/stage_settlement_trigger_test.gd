extends SceneTree

const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	await test_stage_settlement_trigger_reached_is_false_before_target()
	await test_reaching_stage_target_enters_stage_settlement_and_emits_event()
	await test_post_match_settlement_continues_directly_into_stage_settlement_when_target_is_met()
	await test_post_match_settlement_returns_to_planning_when_stage_target_is_not_met()
	await test_stage_settlement_does_not_require_manual_time_advance_after_post_match_resolution()
	if _failures.is_empty():
		print("STAGE_SETTLEMENT_TRIGGER_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("STAGE_SETTLEMENT_TRIGGER_TEST_FAIL: %s" % failure)
		quit(1)


func test_stage_settlement_trigger_reached_is_false_before_target() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Post-Match Settlement",
		"current_stage_progress": 2,
		"stage_progress_target": 3,
	})

	# Act
	var trigger_result: Dictionary[String, Variant] = time_manager.evaluate_stage_settlement_trigger()

	# Assert
	_expect(not time_manager.get_stage_settlement_trigger_reached(), "stage settlement trigger should not be reached before target")
	_expect(not (trigger_result["success"] as bool), "evaluate_stage_settlement_trigger should not succeed before target")
	_expect(String(trigger_result["reason"]) == "not_reached", "early stage evaluation should report not_reached")
	_expect(String(time_manager.get_state()["current_state"]) == "Post-Match Settlement", "state should remain Post-Match Settlement before target")


func test_reaching_stage_target_enters_stage_settlement_and_emits_event() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Post-Match Settlement",
		"current_stage_progress": 3,
		"stage_progress_target": 3,
	})
	var stage_events: Array[Dictionary] = []
	var callback := _capture_event.bind(stage_events)
	_event_bus().subscribe("time_stage_settled", callback)
	stage_events.clear()

	# Act
	var trigger_result: Dictionary[String, Variant] = time_manager.evaluate_stage_settlement_trigger()

	# Assert
	_expect(time_manager.get_stage_settlement_trigger_reached(), "stage settlement trigger should be reached at target")
	_expect(trigger_result["success"] as bool, "evaluate_stage_settlement_trigger should succeed at target")
	_expect(String(time_manager.get_state()["current_state"]) == "Stage Settlement", "state should transition to Stage Settlement when target is reached")
	_expect(stage_events.size() == 1, "reaching stage target should emit one time_stage_settled event")
	var stage_payload: Dictionary[String, Variant] = stage_events[0]
	_expect(String(stage_payload["current_state"]) == "Stage Settlement", "stage settlement event should expose Stage Settlement state")
	_expect(int(stage_payload["current_stage"]) == 1, "stage settlement event should expose current stage")

	# Cleanup
	_event_bus().unsubscribe("time_stage_settled", callback)


func test_post_match_settlement_continues_directly_into_stage_settlement_when_target_is_met() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Post-Match Settlement",
		"current_stage_progress": 4,
		"stage_progress_target": 3,
	})
	var phase_events: Array[Dictionary] = []
	var stage_events: Array[Dictionary] = []
	var phase_callback := _capture_event.bind(phase_events)
	var stage_callback := _capture_event.bind(stage_events)
	_event_bus().subscribe("time_phase_changed", phase_callback)
	_event_bus().subscribe("time_stage_settled", stage_callback)
	phase_events.clear()
	stage_events.clear()

	# Act
	var resolution_result: Dictionary[String, Variant] = time_manager.resolve_post_match_settlement()

	# Assert
	_expect(resolution_result["success"] as bool, "post-match resolution should succeed when stage target is met")
	_expect(resolution_result["triggered"] as bool, "post-match resolution should report triggered when stage target is met")
	_expect(String(resolution_result["next_state"]) == "Stage Settlement", "post-match resolution should continue directly into Stage Settlement")
	_expect(String(time_manager.get_state()["current_state"]) == "Stage Settlement", "state should be Stage Settlement after qualifying post-match resolution")
	_expect(phase_events.size() == 1, "post-match resolution should change phase exactly once when entering Stage Settlement")
	var phase_payload: Dictionary[String, Variant] = phase_events[0]
	_expect(String(phase_payload["old_phase"]) == "Post-Match Settlement", "phase change should originate from Post-Match Settlement")
	_expect(String(phase_payload["new_phase"]) == "Stage Settlement", "phase change should land on Stage Settlement")
	_expect(stage_events.size() == 1, "qualifying post-match resolution should emit one time_stage_settled event")

	# Cleanup
	_event_bus().unsubscribe("time_phase_changed", phase_callback)
	_event_bus().unsubscribe("time_stage_settled", stage_callback)


func test_post_match_settlement_returns_to_planning_when_stage_target_is_not_met() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Post-Match Settlement",
		"current_stage_progress": 2,
		"stage_progress_target": 3,
	})
	var stage_events: Array[Dictionary] = []
	var callback := _capture_event.bind(stage_events)
	_event_bus().subscribe("time_stage_settled", callback)
	stage_events.clear()

	# Act
	var resolution_result: Dictionary[String, Variant] = time_manager.resolve_post_match_settlement()

	# Assert
	_expect(resolution_result["success"] as bool, "post-match resolution should still succeed when stage target is not met")
	_expect(not (resolution_result["triggered"] as bool), "post-match resolution should report not triggered when stage target is not met")
	_expect(String(resolution_result["reason"]) == "stage_not_reached", "non-qualifying post-match resolution should report stage_not_reached")
	_expect(String(resolution_result["next_state"]) == "Planning", "post-match resolution should return to Planning when stage target is not met")
	_expect(String(time_manager.get_state()["current_state"]) == "Planning", "state should return to Planning when stage target is not met")
	_expect(stage_events.is_empty(), "non-qualifying post-match resolution should not emit time_stage_settled")

	# Cleanup
	_event_bus().unsubscribe("time_stage_settled", callback)


func test_stage_settlement_does_not_require_manual_time_advance_after_post_match_resolution() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Post-Match Settlement",
		"current_stage_progress": 3,
		"stage_progress_target": 3,
		"timeline_position": 8,
	})

	# Act
	time_manager.resolve_post_match_settlement()
	var state_after_resolution: Dictionary[String, Variant] = time_manager.get_state()

	# Assert
	_expect(String(state_after_resolution["current_state"]) == "Stage Settlement", "stage settlement should be reached immediately after post-match resolution")
	_expect(int(state_after_resolution["timeline_position"]) == 8, "post-match resolution should not require extra manual time advance to reach Stage Settlement")


func _create_time_manager(snapshot: Dictionary[String, Variant]) -> Node:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.call_deferred("add_child", time_manager)
	await process_frame
	time_manager.apply_snapshot(snapshot)
	return time_manager


func _event_bus() -> Node:
	return root.get_node("EventBus")


func _capture_event(_event_name: String, payload: Dictionary, sink: Array[Dictionary]) -> void:
	sink.append(_to_typed_dictionary(payload))


func _to_typed_dictionary(source: Dictionary) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	for key_variant: Variant in source:
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
