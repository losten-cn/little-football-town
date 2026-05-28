extends SceneTree

const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	test_match_trigger_reached_is_false_before_scheduled_position()
	test_reaching_match_node_enters_match_trigger_and_emits_event()
	test_match_node_triggers_exactly_once_under_repeated_polling()
	test_set_match_in_progress_transitions_state_correctly_after_trigger()
	test_exact_match_node_does_not_open_extra_free_window_before_trigger()
	if _failures.is_empty():
		print("MATCH_TRIGGER_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("MATCH_TRIGGER_TEST_FAIL: %s" % failure)
		quit(1)


func test_match_trigger_reached_is_false_before_scheduled_position() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
		"timeline_position": 4,
		"schedule_available": true,
		"match": {
			"scheduled_position": 5,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Northbridge FC",
			"next_match_display": "vs Northbridge FC",
		},
	})

	# Act
	var trigger_result: Dictionary[String, Variant] = time_manager.evaluate_match_trigger()

	# Assert
	_expect(not time_manager.get_match_trigger_reached(), "match trigger should not be reached before scheduled position")
	_expect(not (trigger_result["success"] as bool), "evaluate_match_trigger should not succeed before scheduled position")
	_expect(String(trigger_result["reason"]) == "not_reached", "early evaluation should report not_reached")
	_expect(String(time_manager.get_state()["current_state"]) == "Planning", "state should remain Planning before scheduled position")


func test_reaching_match_node_enters_match_trigger_and_emits_event() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
		"timeline_position": 5,
		"schedule_available": true,
		"match": {
			"scheduled_position": 5,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "River City",
			"next_match_display": "vs River City",
		},
	})
	var match_events: Array[Dictionary] = []
	var callback := _capture_event.bind(match_events)
	_event_bus().subscribe("time_match_triggered", callback)
	match_events.clear()

	# Act
	var trigger_result: Dictionary[String, Variant] = time_manager.evaluate_match_trigger()

	# Assert
	_expect(time_manager.get_match_trigger_reached(), "match trigger should be reached at the scheduled position")
	_expect(trigger_result["success"] as bool, "evaluate_match_trigger should succeed at the scheduled position")
	_expect(String(time_manager.get_state()["current_state"]) == "Match Trigger", "state should transition to Match Trigger when the node is reached")
	_expect(match_events.size() == 1, "reaching the match node should emit one time_match_triggered event")
	var match_payload: Dictionary[String, Variant] = match_events[0]
	_expect(String(match_payload["current_state"]) == "Match Trigger", "match trigger event should expose Match Trigger state")
	_expect(int(match_payload["scheduled_match_position"]) == 5, "match trigger event should expose scheduled match position")
	var match_context: Dictionary[String, Variant] = _to_typed_dictionary(match_payload["match_context"] as Dictionary)
	_expect(String(match_context["opponent_name"]) == "River City", "match trigger event should include opponent name in match_context")
	_expect(String(match_context["next_match_display"]) == "vs River City", "match trigger event should include display text in match_context")

	# Cleanup
	_event_bus().unsubscribe("time_match_triggered", callback)


func test_match_node_triggers_exactly_once_under_repeated_polling() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
		"timeline_position": 6,
		"schedule_available": true,
		"match": {
			"scheduled_position": 5,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Harbor Athletic",
			"next_match_display": "vs Harbor Athletic",
		},
	})
	var match_events: Array[Dictionary] = []
	var callback := _capture_event.bind(match_events)
	_event_bus().subscribe("time_match_triggered", callback)
	match_events.clear()

	# Act
	var first_result: Dictionary[String, Variant] = time_manager.evaluate_match_trigger()
	var second_result: Dictionary[String, Variant] = time_manager.evaluate_match_trigger()

	# Assert
	_expect(first_result["success"] as bool, "first evaluation should trigger the scheduled match node")
	_expect(not (second_result["success"] as bool), "second evaluation should not re-trigger an already consumed match node")
	_expect(String(second_result["reason"]) == "already_triggered", "second evaluation should report already_triggered")
	_expect(match_events.size() == 1, "match node should emit time_match_triggered exactly once")

	# Cleanup
	_event_bus().unsubscribe("time_match_triggered", callback)


func test_set_match_in_progress_transitions_state_correctly_after_trigger() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
		"timeline_position": 5,
		"schedule_available": true,
		"match": {
			"scheduled_position": 5,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "East Side",
			"next_match_display": "vs East Side",
		},
	})
	time_manager.evaluate_match_trigger()

	# Act
	time_manager.set_match_in_progress(true)

	# Assert
	_expect(String(time_manager.get_state()["current_state"]) == "Match In Progress", "set_match_in_progress(true) should transition to Match In Progress after trigger")
	_expect(time_manager.is_match_in_progress(), "match in progress flag should be true after transition")


func test_exact_match_node_does_not_open_extra_free_window_before_trigger() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
		"timeline_position": 4,
		"schedule_available": true,
		"available_action_windows": {
			"current_phase_time_budget": 5,
			"reserved_time": 0,
			"consumed_time": 4,
			"standard_window_size": 1,
		},
		"match": {
			"scheduled_position": 5,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Southport",
			"next_match_display": "vs Southport",
		},
	})

	# Act
	time_manager.advance_timeline(1)
	var state: Dictionary[String, Variant] = time_manager.get_state()
	var windows_after_trigger: int = time_manager.get_available_action_windows()

	# Assert
	_expect(String(state["current_state"]) == "Match Trigger", "landing exactly on the match node should transition immediately to Match Trigger")
	_expect(windows_after_trigger == 0, "no extra free action window should open once Match Trigger is reached")


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
