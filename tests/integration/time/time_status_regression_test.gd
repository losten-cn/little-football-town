extends SceneTree

const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	await test_time_status_fields_expose_required_display_contract()
	await test_remaining_time_to_next_key_node_uses_non_negative_formula()
	await test_time_status_regression_sample_covers_all_nine_states()
	await test_time_status_regression_sample_completes_minimum_mvp_loop()
	await test_time_status_regression_sample_marks_tuning_target_band_result()
	if _failures.is_empty():
		print("TIME_STATUS_REGRESSION_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("TIME_STATUS_REGRESSION_TEST_FAIL: %s" % failure)
		quit(1)


func test_time_status_fields_expose_required_display_contract() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
		"timeline_position": 2,
		"season_number": 1,
		"current_stage": 1,
		"current_stage_progress": 1,
		"stage_progress_target": 4,
		"current_stage_display": "Stage 1",
		"current_date_display": "Week 2",
		"season_progress": {
			"completed_units": 2,
			"total_units": 20,
		},
		"available_action_windows": {
			"current_phase_time_budget": 5,
			"reserved_time": 1,
			"consumed_time": 1,
			"standard_window_size": 1,
		},
		"next_key_node": {
			"type": "match",
			"state": "Match Trigger",
			"position": 4,
			"display_name": "Matchday 1",
		},
		"match": {
			"scheduled_position": 4,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Display FC",
			"next_match_display": "vs Display FC",
		},
		"schedule_available": true,
		"schedule_loading": false,
		"schedule_missing": false,
	})

	# Act
	var state: Dictionary[String, Variant] = time_manager.get_state()
	var hud_payload: Dictionary[String, Variant] = time_manager.get_hud_payload()
	var season_position: Dictionary[String, Variant] = state["season_position"]
	var available_action_windows: Dictionary[String, Variant] = state["available_action_windows"]

	# Assert
	_expect(String(state["current_state"]) == "Planning", "display contract should expose current_state")
	_expect(String(state["current_date_or_position"]) == "Week 2", "display contract should expose current_date_or_position")
	_expect(int(available_action_windows["count"]) == 3, "display contract should expose remaining action windows")
	_expect(is_equal_approx(float(state["season_progress"]["progress_ratio"]), 0.1), "display contract should expose season_progress_ratio through get_state")
	_expect(int(state["remaining_time_to_next_key_node"]) == 2, "display contract should expose remaining_time_to_next_key_node")
	_expect(int(state["next_key_node_position"]) == 4, "display contract should expose next_key_node_position")
	_expect(String(state["next_key_node_display"]) == "Matchday 1", "display contract should expose next_key_node_display")
	_expect(int(season_position["season_number"]) == 1, "display contract should expose season position season_number")
	_expect(int(season_position["current_stage"]) == 1, "display contract should expose season position current_stage")
	_expect(int(season_position["current_stage_progress"]) == 1, "display contract should expose season position current_stage_progress")
	_expect(int(season_position["stage_progress_target"]) == 4, "display contract should expose season position stage_progress_target")
	_expect(int(season_position["timeline_position"]) == 2, "display contract should expose season position timeline_position")
	_expect(String(hud_payload["state"]) == String(state["current_state"]), "hud payload state should match get_state")
	_expect(int(hud_payload["available_action_windows"]) == int(available_action_windows["count"]), "hud payload action windows should match get_state")
	_expect(is_equal_approx(float(hud_payload["season_progress_ratio"]), float(state["season_progress"]["progress_ratio"])), "hud payload season progress ratio should match get_state")
	_expect(int(hud_payload["remaining_time_to_next_key_node"]) == int(state["remaining_time_to_next_key_node"]), "hud payload remaining time should match get_state")


func test_remaining_time_to_next_key_node_uses_non_negative_formula() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Action Resolution",
		"timeline_position": 8,
		"next_key_node": {
			"type": "stage",
			"state": "Stage Settlement",
			"position": 6,
			"display_name": "Stage Checkpoint",
		},
	})

	# Act
	var state: Dictionary[String, Variant] = time_manager.get_state()
	var remaining_time: int = int(state["remaining_time_to_next_key_node"])

	# Assert
	_expect(remaining_time == 0, "remaining time should clamp to zero when next key node is behind current position")
	_expect(remaining_time == maxi(int(state["next_key_node_position"]) - int(state["timeline_position"]), 0), "remaining time should follow the max(0, next - current) formula")


func test_time_status_regression_sample_covers_all_nine_states() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
	})
	var expected_state_names: Array[String] = [
		"Planning",
		"Action Resolution",
		"Match Trigger",
		"Match In Progress",
		"Post-Match Settlement",
		"Stage Settlement",
		"Season Settlement",
		"Offseason",
		"SeasonStart",
	]

	# Act / Assert
	for state_name: String in expected_state_names:
		var transitioned: bool = time_manager.set_state_by_name(state_name)
		var current_state: String = String(time_manager.get_state()["current_state"])
		_expect(current_state == state_name, "regression coverage should expose %s" % state_name)
		_expect(transitioned or state_name == "Planning", "state %s should be reachable for regression coverage" % state_name)


func test_time_status_regression_sample_completes_minimum_mvp_loop() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager(_season_boundary_loop_snapshot())

	# Act
	var visited_states: Array[String] = []
	visited_states.append(String(time_manager.get_state()["current_state"]))

	time_manager.set_state_by_name("Action Resolution")
	visited_states.append(String(time_manager.get_state()["current_state"]))

	time_manager.advance_timeline(1)
	visited_states.append(String(time_manager.get_state()["current_state"]))

	time_manager.set_match_in_progress(true)
	visited_states.append(String(time_manager.get_state()["current_state"]))

	time_manager.set_match_in_progress(false)
	visited_states.append(String(time_manager.get_state()["current_state"]))

	var post_match_result: Dictionary[String, Variant] = time_manager.resolve_post_match_settlement()
	visited_states.append(String(time_manager.get_state()["current_state"]))

	var season_trigger_result: Dictionary[String, Variant] = time_manager.evaluate_season_settlement_trigger()
	visited_states.append(String(time_manager.get_state()["current_state"]))

	var season_result: Dictionary[String, Variant] = time_manager.resolve_season_settlement()
	visited_states.append(String(time_manager.get_state()["current_state"]))

	var new_season_result: Dictionary[String, Variant] = time_manager.start_new_season()
	visited_states.append(String(time_manager.get_state()["current_state"]))

	# Assert
	_expect(visited_states == [
		"Planning",
		"Action Resolution",
		"Match Trigger",
		"Match In Progress",
		"Post-Match Settlement",
		"Stage Settlement",
		"Season Settlement",
		"Offseason",
		"SeasonStart",
	], "mvp regression sample should complete the required loop in order")
	_expect(post_match_result["success"] as bool, "post-match settlement should resolve successfully in the regression sample")
	_expect(post_match_result["triggered"] as bool, "post-match settlement should transition into the stage settlement boundary in the sample")
	_expect(season_trigger_result["success"] as bool, "season settlement should trigger successfully in the regression sample")
	_expect(season_result["success"] as bool, "season settlement should resolve successfully in the regression sample")
	_expect(String(season_result["next_state"]) == "Offseason", "season settlement should transition into Offseason")
	_expect(new_season_result["success"] as bool, "new season should start successfully in the regression sample")
	_expect(String(new_season_result["next_state"]) == "SeasonStart", "new season should enter SeasonStart")


func test_time_status_regression_sample_marks_tuning_target_band_result() -> void:
	# Arrange
	var time_manager: Node = await _create_time_manager(_normal_ui_snapshot())

	# Act
	var state: Dictionary[String, Variant] = time_manager.get_state()
	var available_action_windows: int = int((state["available_action_windows"] as Dictionary[String, Variant])["count"])
	var remaining_time: int = int(state["remaining_time_to_next_key_node"])
	var season_progress_ratio: float = float((state["season_progress"] as Dictionary[String, Variant])["progress_ratio"])
	var tuning_band_result: Dictionary[String, bool] = {
		"match_interval_target": available_action_windows >= 2 and available_action_windows <= 5,
		"stage_settlement_frequency_target": available_action_windows >= 3 and available_action_windows <= 7,
		"remaining_time_to_next_key_node_target": remaining_time >= 1 and remaining_time <= 4,
		"session_season_progress_target": season_progress_ratio >= 0.05 and season_progress_ratio <= 0.15,
	}

	# Assert
	_expect(tuning_band_result["match_interval_target"], "regression sample should stay within the match interval target band")
	_expect(tuning_band_result["stage_settlement_frequency_target"], "regression sample should stay within the stage settlement frequency target band")
	_expect(tuning_band_result["remaining_time_to_next_key_node_target"], "regression sample should stay within the next key node remaining time target band")
	_expect(tuning_band_result["session_season_progress_target"], "regression sample should stay within the representative session season progress target band")


func _normal_ui_snapshot() -> Dictionary[String, Variant]:
	return {
		"current_state": "Planning",
		"timeline_position": 2,
		"season_number": 1,
		"current_stage": 1,
		"current_stage_progress": 2,
		"stage_progress_target": 6,
		"current_stage_display": "Stage 1",
		"current_date_display": "Week 2",
		"season_progress": {
			"completed_units": 2,
			"total_units": 20,
		},
		"available_action_windows": {
			"current_phase_time_budget": 5,
			"reserved_time": 0,
			"consumed_time": 1,
			"standard_window_size": 1,
		},
		"next_key_node": {
			"type": "match",
			"state": "Match Trigger",
			"position": 3,
			"display_name": "Matchday 1",
		},
		"match": {
			"scheduled_position": 3,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Regression FC",
			"next_match_display": "vs Regression FC",
		},
		"schedule_available": true,
		"schedule_loading": false,
		"schedule_missing": false,
	}


func _season_boundary_loop_snapshot() -> Dictionary[String, Variant]:
	return {
		"current_state": "Planning",
		"timeline_position": 2,
		"season_number": 1,
		"current_stage": 1,
		"current_stage_progress": 3,
		"stage_progress_target": 3,
		"current_stage_display": "Stage 1",
		"current_date_display": "Week 2",
		"season_progress": {
			"completed_units": 20,
			"total_units": 20,
		},
		"available_action_windows": {
			"current_phase_time_budget": 5,
			"reserved_time": 0,
			"consumed_time": 1,
			"standard_window_size": 1,
		},
		"next_key_node": {
			"type": "match",
			"state": "Match Trigger",
			"position": 3,
			"display_name": "Matchday 1",
		},
		"match": {
			"scheduled_position": 3,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Regression FC",
			"next_match_display": "vs Regression FC",
		},
		"schedule_available": true,
		"schedule_loading": false,
		"schedule_missing": false,
	}


func _create_time_manager(snapshot: Dictionary[String, Variant]) -> Node:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.call_deferred("add_child", time_manager)
	await process_frame
	time_manager.apply_snapshot(snapshot)
	return time_manager


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
