extends SceneTree

const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	await test_season_progress_ratio_uses_safe_formula_and_marks_abnormal_data()
	await test_reaching_full_progress_enters_season_settlement_and_emits_event()
	await test_exceeding_total_progress_enters_season_settlement_and_marks_abnormal_data()
	await test_season_settlement_transitions_into_offseason_and_season_start()
	await test_start_new_season_resets_season_local_counters_without_losing_long_term_state()
	if _failures.is_empty():
		print("SEASON_PROGRESS_FLOW_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("SEASON_PROGRESS_FLOW_TEST_FAIL: %s" % failure)
		quit(1)


func test_season_progress_ratio_uses_safe_formula_and_marks_abnormal_data() -> void:
	# Arrange
	var zero_total_time_manager: Node = await _create_time_manager({
		"season_progress": {
			"completed_units": 0,
			"total_units": 0,
		}
	})
	var abnormal_time_manager: Node = await _create_time_manager({
		"season_progress": {
			"completed_units": 8,
			"total_units": 5,
		}
	})

	# Act
	var zero_total_ratio: float = zero_total_time_manager.get_season_progress_ratio()
	var abnormal_state: Dictionary[String, Variant] = abnormal_time_manager.get_state()
	var abnormal_progress: Dictionary[String, Variant] = abnormal_state["season_progress"]

	# Assert
	_expect(is_equal_approx(zero_total_ratio, 0.0), "season progress ratio should use max(1, total_season_units) when total is zero")
	_expect(is_equal_approx(float(abnormal_progress["progress_ratio"]), 1.0), "season progress ratio should clamp effective progress to complete when completed units exceed total")
	_expect(abnormal_progress["abnormal_for_review"] as bool, "abnormal season progress data should be marked for review")
	_expect(abnormal_state["season_progress_abnormal"] as bool, "top-level state should expose abnormal season progress flag")


func test_reaching_full_progress_enters_season_settlement_and_emits_event() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
		"season_progress": {
			"completed_units": 6,
			"total_units": 6,
		}
	})
	var season_events: Array[Dictionary] = []
	var callback := _capture_event.bind(season_events)
	_event_bus().subscribe("time_season_ended", callback)
	season_events.clear()

	# Act
	var trigger_result: Dictionary[String, Variant] = time_manager.evaluate_season_settlement_trigger()

	# Assert
	_expect(time_manager.get_season_settlement_trigger_reached(), "season settlement trigger should be reached at ratio 1")
	_expect(trigger_result["success"] as bool, "evaluate_season_settlement_trigger should succeed at ratio 1")
	_expect(String(time_manager.get_state()["current_state"]) == "Season Settlement", "state should transition to Season Settlement at full progress")
	_expect(season_events.size() == 1, "reaching season settlement should emit one time_season_ended event")
	var season_payload: Dictionary[String, Variant] = season_events[0]
	_expect(String(season_payload["current_state"]) == "Season Settlement", "season event should expose Season Settlement state")
	_expect(int(season_payload["season_number"]) == 1, "season event should expose current season number")

	# Cleanup
	_event_bus().unsubscribe("time_season_ended", callback)


func test_exceeding_total_progress_enters_season_settlement_and_marks_abnormal_data() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
		"season_progress": {
			"completed_units": 7,
			"total_units": 5,
		}
	})

	# Act
	var trigger_result: Dictionary[String, Variant] = time_manager.evaluate_season_settlement_trigger()
	var state: Dictionary[String, Variant] = time_manager.get_state()

	# Assert
	_expect(trigger_result["success"] as bool, "evaluate_season_settlement_trigger should succeed when ratio exceeds 1")
	_expect(String(state["current_state"]) == "Season Settlement", "ratio above 1 should still enter Season Settlement")
	_expect(state["season_progress_abnormal"] as bool, "ratio above 1 should preserve abnormal review flag")


func test_season_settlement_transitions_into_offseason_and_season_start() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Season Settlement",
		"season_number": 2,
		"season_progress": {
			"completed_units": 6,
			"total_units": 6,
		}
	})
	var phase_events: Array[Dictionary] = []
	var callback := _capture_event.bind(phase_events)
	_event_bus().subscribe("time_phase_changed", callback)
	phase_events.clear()

	# Act
	var offseason_result: Dictionary[String, Variant] = time_manager.resolve_season_settlement()
	var season_start_result: Dictionary[String, Variant] = time_manager.start_new_season()

	# Assert
	_expect(offseason_result["success"] as bool, "season settlement should resolve into Offseason")
	_expect(String(offseason_result["next_state"]) == "Offseason", "season settlement should enter Offseason")
	_expect(season_start_result["success"] as bool, "Offseason should transition into SeasonStart")
	_expect(String(season_start_result["next_state"]) == "SeasonStart", "new season start should enter SeasonStart")
	_expect(phase_events.size() == 2, "season-end flow should emit two phase changes: Offseason then SeasonStart")
	_expect(String(phase_events[0]["old_phase"]) == "Season Settlement", "first phase change should originate from Season Settlement")
	_expect(String(phase_events[0]["new_phase"]) == "Offseason", "first phase change should land on Offseason")
	_expect(String(phase_events[1]["old_phase"]) == "Offseason", "second phase change should originate from Offseason")
	_expect(String(phase_events[1]["new_phase"]) == "SeasonStart", "second phase change should land on SeasonStart")

	# Cleanup
	_event_bus().unsubscribe("time_phase_changed", callback)


func test_start_new_season_resets_season_local_counters_without_losing_long_term_state() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Offseason",
		"season_number": 3,
		"current_stage": 4,
		"current_stage_progress": 3,
		"stage_progress_target": 5,
		"timeline_position": 12,
		"season_label": "Season 3",
		"current_stage_display": "Stage 4",
		"season_progress": {
			"completed_units": 12,
			"total_units": 12,
		},
		"match": {
			"scheduled_position": 10,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Old Rival",
			"next_match_display": "vs Old Rival",
		}
	})

	# Act
	var start_result: Dictionary[String, Variant] = time_manager.start_new_season()
	var state: Dictionary[String, Variant] = time_manager.get_state()
	var season_progress: Dictionary[String, Variant] = state["season_progress"]

	# Assert
	_expect(start_result["success"] as bool, "start_new_season should succeed from Offseason")
	_expect(int(state["season_number"]) == 4, "new season start should increment the season number")
	_expect(int(state["timeline_position"]) == 0, "new season start should reset the timeline position")
	_expect(int(state["current_stage"]) == 1, "new season start should reset the current stage")
	_expect(int(state["current_stage_progress"]) == 0, "new season start should reset stage progress")
	_expect(int(season_progress["completed_units"]) == 0, "new season start should reset completed season units")
	_expect(int(season_progress["total_units"]) == 12, "new season start should preserve the configured total season units")
	_expect(not (state["season_progress_abnormal"] as bool), "new season start should clear abnormal season progress review flags")
	_expect(String(state["current_state"]) == "SeasonStart", "new season start should enter SeasonStart")
	_expect(String(state["season_label"]) == "Season 3", "new season start should preserve long-term season label state")
	var match_state: Dictionary[String, Variant] = state["match"]
	_expect(not (match_state["trigger_reached"] as bool), "new season start should clear consumed match trigger state")
	_expect(String(match_state["opponent_name"]) == "Old Rival", "new season start should preserve long-term match context fields")


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
