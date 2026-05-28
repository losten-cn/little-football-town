extends Node

const TIME_MANAGER_SCRIPT: Script = preload("res://src/autoload/time_manager.gd")

var _failures: Array[String] = []


func _time_manager() -> Node:
	return get_node("/root/TimeManager")


func _event_bus() -> Node:
	return get_node("/root/EventBus")


func _save_manager() -> Node:
	return get_node("/root/SaveManager")


func _ready() -> void:
	test_time_manager_autoload_order_matches_manifest_contract()
	test_time_manager_get_state_returns_serializable_complete_snapshot()
	test_time_manager_state_model_supports_all_nine_gdd_states()
	test_time_manager_state_transition_updates_pull_state_and_push_events_consistently()
	if _failures.is_empty():
		print("TIME_MANAGER_STATE_CONTRACT_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("TIME_MANAGER_STATE_CONTRACT_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_time_manager_autoload_order_matches_manifest_contract() -> void:
	# Arrange
	var autoload_order: Array[String] = _read_autoload_order_from_project_file()

	# Assert
	_expect(autoload_order.size() == 5, "autoload order should contain the five foundation singletons")
	_expect(_index_of(autoload_order, "ConfigLoader") == 0, "ConfigLoader should load first")
	_expect(_index_of(autoload_order, "EventBus") == 1, "EventBus should load second")
	_expect(_index_of(autoload_order, "TimeManager") == 2, "TimeManager should load after EventBus")
	_expect(_index_of(autoload_order, "SaveManager") == 3, "SaveManager should load after TimeManager")
	_expect(_index_of(autoload_order, "ScreenManager") == 4, "ScreenManager should load last in the foundation chain")
	_expect(_time_manager() != null, "TimeManager singleton should be available")
	_expect(_event_bus() != null, "EventBus singleton should be available")
	_expect(_save_manager() != null, "SaveManager singleton should be available")


func test_time_manager_get_state_returns_serializable_complete_snapshot() -> void:
	# Arrange
	var snapshot: Dictionary[String, Variant] = {
		"current_state": "Planning",
		"timeline_position": 7,
		"season_number": 3,
		"season_label": "Season 3",
		"current_stage": 2,
		"current_stage_display": "Stage 2",
		"current_date_display": "Week 7",
		"season_progress": {
			"completed_units": 7,
			"total_units": 14,
		},
		"available_action_windows": {
			"current_phase_time_budget": 10,
			"reserved_time": 2,
			"consumed_time": 5,
			"standard_window_size": 1,
		},
		"next_key_node": {
			"type": "match",
			"state": "Match Trigger",
			"position": 9,
			"display_name": "Matchday 4",
		},
		"match": {
			"scheduled_position": 8,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Northbridge FC",
			"next_match_display": "vs Northbridge FC",
		},
		"schedule_available": true,
		"schedule_loading": false,
		"schedule_missing": false,
	}
	_time_manager().apply_snapshot(snapshot)

	# Act
	var state: Dictionary[String, Variant] = _time_manager().get_state()
	var season_progress: Dictionary[String, Variant] = state["season_progress"]
	var available_action_windows: Dictionary[String, Variant] = state["available_action_windows"]
	var next_key_node: Dictionary[String, Variant] = state["next_key_node"]
	var match_data: Dictionary[String, Variant] = state["match"]

	# Assert
	_expect(int(state["timeline_position"]) == 7, "get_state should expose timeline_position")
	_expect(String(state["current_phase"]) == "Planning", "get_state should expose the current phase name")
	_expect(String(state["current_state"]) == "Planning", "get_state should expose the current state name")
	_expect(int(state["season_number"]) == 3, "get_state should expose season_number")
	_expect(int(state["current_stage"]) == 2, "get_state should expose current_stage")
	_expect(String(state["current_stage_display"]) == "Stage 2", "get_state should preserve current_stage_display")
	_expect(String(state["current_date_display"]) == "Week 7", "get_state should preserve current_date_display")
	_expect(int(available_action_windows["count"]) == 3, "available_action_windows should expose calculated count")
	_expect(int(available_action_windows["current_phase_time_budget"]) == 10, "available_action_windows should expose current_phase_time_budget")
	_expect(int(available_action_windows["reserved_time"]) == 2, "available_action_windows should expose reserved_time")
	_expect(int(available_action_windows["consumed_time"]) == 5, "available_action_windows should expose consumed_time")
	_expect(int(available_action_windows["standard_window_size"]) == 1, "available_action_windows should expose standard_window_size")
	_expect(int(season_progress["completed_units"]) == 7, "season_progress should expose completed_units")
	_expect(int(season_progress["total_units"]) == 14, "season_progress should expose total_units")
	_expect(is_equal_approx(float(season_progress["progress_ratio"]), 0.5), "season_progress should expose progress_ratio")
	_expect(String(next_key_node["type"]) == "match", "next_key_node should expose type")
	_expect(String(next_key_node["state"]) == "Match Trigger", "next_key_node should expose state")
	_expect(int(next_key_node["position"]) == 9, "next_key_node should expose position")
	_expect(int(next_key_node["remaining_time"]) == 2, "next_key_node should expose remaining_time")
	_expect(String(next_key_node["display_name"]) == "Matchday 4", "next_key_node should expose display_name")
	_expect(int(match_data["scheduled_position"]) == 8, "match should expose scheduled_position")
	_expect(match_data["center_available"] as bool, "match should expose center_available")
	_expect(not (match_data["in_progress"] as bool), "match should expose in_progress")
	_expect(String(match_data["opponent_name"]) == "Northbridge FC", "match should expose opponent_name")
	_expect(String(match_data["next_match_display"]) == "vs Northbridge FC", "match should expose next_match_display")
	_expect(_dictionary_is_serializable(state), "get_state should return a serializable dictionary payload")


func test_time_manager_state_model_supports_all_nine_gdd_states() -> void:
	# Arrange
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

	# Act
	var supported_state_names: Array[String] = _time_manager().get_supported_state_names()

	# Assert
	_expect(supported_state_names.size() == 9, "supported state list should contain exactly 9 states")
	for state_name: String in expected_state_names:
		_expect(supported_state_names.has(state_name), "supported state list should include %s" % state_name)
		_expect(_time_manager().has_state_name(state_name), "_time_manager() should recognize state %s" % state_name)
		var transitioned: bool = _time_manager().set_state_by_name(state_name)
		if state_name == String(_time_manager().get_state()["current_state"]):
			_expect(transitioned or state_name == "Planning", "set_state_by_name should allow transition into %s" % state_name)
		_expect(String(_time_manager().get_state()["current_state"]) == state_name, "get_state should report %s after transition" % state_name)


func test_time_manager_state_transition_updates_pull_state_and_push_events_consistently() -> void:
	# Arrange
	var phase_events: Array[Dictionary] = []
	var match_events: Array[Dictionary] = []
	var time_events: Array[Dictionary] = []
	var phase_callback := _capture_event.bind(phase_events)
	var match_callback := _capture_event.bind(match_events)
	var time_callback := _capture_event.bind(time_events)
	_event_bus().subscribe("time_phase_changed", phase_callback)
	_event_bus().subscribe("time_match_triggered", match_callback)
	_event_bus().subscribe("time_advanced", time_callback)

	var snapshot: Dictionary[String, Variant] = {
		"current_state": "Planning",
		"timeline_position": 5,
		"season_number": 1,
		"current_stage": 1,
		"current_stage_display": "Stage 1",
		"available_action_windows": {
			"current_phase_time_budget": 8,
			"reserved_time": 1,
			"consumed_time": 1,
			"standard_window_size": 1,
		},
		"season_progress": {
			"completed_units": 5,
			"total_units": 10,
		},
		"next_key_node": {
			"type": "match",
			"state": "Match Trigger",
			"position": 6,
			"display_name": "League Match",
		},
		"match": {
			"scheduled_position": 6,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "River City",
			"next_match_display": "vs River City",
		},
		"schedule_available": true,
		"schedule_loading": false,
		"schedule_missing": false,
	}
	_time_manager().apply_snapshot(snapshot)
	phase_events.clear()
	match_events.clear()
	time_events.clear()

	# Act
	_time_manager().advance_timeline(1)

	# Assert
	_expect(phase_events.size() == 1, "advancing into a match trigger should emit one time_phase_changed event")
	_expect(match_events.size() == 1, "advancing into a match trigger should emit one time_match_triggered event")
	_expect(time_events.size() == 1, "advancing into a match trigger should emit one HUD-facing time_advanced event")
	var pull_state: Dictionary[String, Variant] = _time_manager().get_state()
	_expect(String(pull_state["current_state"]) == "Match Trigger", "get_state should expose the transitioned Match Trigger state")
	_expect(String(pull_state["current_phase"]) == "Match Trigger", "get_state phase should match the transitioned state")
	_expect(int(pull_state["timeline_position"]) == 6, "get_state should expose the post-transition timeline position")
	var phase_payload: Dictionary[String, Variant] = phase_events[0]
	_expect(String(phase_payload["old_phase"]) == "Planning", "time_phase_changed should expose the previous phase")
	_expect(String(phase_payload["new_phase"]) == "Match Trigger", "time_phase_changed should expose the new phase")
	_expect(int(phase_payload["timeline_position"]) == 6, "time_phase_changed should expose the updated timeline position")
	_expect(String(_time_manager().get_state()["current_phase"]) == String(phase_payload["new_phase"]), "pull state should match phase_changed payload")
	var match_payload: Dictionary[String, Variant] = match_events[0]
	_expect(String(match_payload["current_state"]) == "Match Trigger", "time_match_triggered should expose Match Trigger state")
	_expect(int(match_payload["timeline_position"]) == 6, "time_match_triggered should expose the updated timeline position")
	_expect(int(match_payload["scheduled_match_position"]) == 6, "time_match_triggered should expose scheduled match position")
	_expect(String(match_payload["opponent_name"]) == "River City", "time_match_triggered should expose opponent name")
	_expect(String(match_payload["next_match_display"]) == "vs River City", "time_match_triggered should expose next_match_display")
	_expect(String(_time_manager().get_state()["current_phase"]) == String(match_payload["current_phase"]), "pull state should match match_trigger payload")
	var hud_payload: Dictionary[String, Variant] = time_events[0]
	_expect(String(hud_payload["state"]) == "Match Trigger", "time_advanced should expose the transitioned state")
	_expect(int(hud_payload["current_timeline_position"]) == 6, "time_advanced should expose the updated timeline position")
	_expect(hud_payload["match_trigger_reached"] as bool, "time_advanced should expose match_trigger_reached")

	# Cleanup
	_event_bus().unsubscribe("time_phase_changed", phase_callback)
	_event_bus().unsubscribe("time_match_triggered", match_callback)
	_event_bus().unsubscribe("time_advanced", time_callback)


func _capture_event(_event_name: String, payload: Dictionary, sink: Array[Dictionary]) -> void:
	sink.append(_to_typed_dictionary(payload))


func _to_typed_dictionary(source: Dictionary) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	for key_variant: Variant in source:
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary


func _dictionary_is_serializable(value: Dictionary[String, Variant]) -> bool:
	for key: String in value.keys():
		if not _value_is_serializable(value[key]):
			return false
	return true


func _value_is_serializable(value: Variant) -> bool:
	if value is String or value is StringName:
		return true
	if value is bool or value is int or value is float:
		return true
	if value == null:
		return true
	if value is Dictionary:
		for nested_key: Variant in value:
			if not (nested_key is String or nested_key is StringName):
				return false
			if not _value_is_serializable(value[nested_key]):
				return false
		return true
	if value is Array:
		for entry: Variant in value:
			if not _value_is_serializable(entry):
				return false
		return true
	return false


func _read_autoload_order_from_project_file() -> Array[String]:
	var autoload_order: Array[String] = []
	var project_file: FileAccess = FileAccess.open("res://project.godot", FileAccess.READ)
	if project_file == null:
		_failures.append("project.godot should be readable for autoload verification")
		return autoload_order

	var in_autoload_section: bool = false
	while not project_file.eof_reached():
		var line: String = project_file.get_line().strip_edges()
		if line.begins_with("["):
			in_autoload_section = line == "[autoload]"
			continue
		if not in_autoload_section or line.is_empty() or line.begins_with(";"):
			continue
		var separator_index: int = line.find("=")
		if separator_index <= 0:
			continue
		autoload_order.append(line.substr(0, separator_index))
	return autoload_order


func _index_of(values: Array[String], expected: String) -> int:
	for index: int in range(values.size()):
		if values[index] == expected:
			return index
	return -1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
