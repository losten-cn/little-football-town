extends SceneTree

const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")
const MatchConfigScript: Script = preload("res://src/config/match_config.gd")
const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")
const FacilityScript: Script = preload("res://src/core/facility.gd")

var _failures: Array[String] = []
var _captured_match_completed_payloads: Array[Dictionary] = []
var _captured_match_event_payloads: Array[Dictionary] = []


func _initialize() -> void:
	_setup_event_bus()
	_event_bus().subscribe("match_completed", Callable(self, "_on_match_completed"))
	_event_bus().subscribe("match_event_occurred", Callable(self, "_on_match_event_occurred"))
	_expect(_event_bus().subscriber_count("match_completed") == 1, "match_completed subscription should be registered before assertions")
	_expect(_event_bus().subscriber_count("match_event_occurred") == 1, "match_event_occurred subscription should be registered before assertions")
	_captured_match_completed_payloads.clear()
	_captured_match_event_payloads.clear()
	_event_bus().emit("match_completed", {"match_id": "probe"})
	_event_bus().emit("match_event_occurred", {"match_minute": 11, "event_data": {"minute": 11}})
	_expect(String(_captured_match_completed_payloads[0].get("match_id", "")) == "probe", "match_completed probe should reach test callback before assertions")
	_expect(int(_captured_match_event_payloads[0].get("match_minute", 0)) == 11, "match_event_occurred probe should reach test callback before assertions")

	test_representative_mvp_session_completes_full_loop()
	test_match_result_handoff_supports_downstream_feedback_and_stadium_revenue_inputs()
	test_full_match_simulation_stays_under_100ms_and_allows_draw_results()

	_event_bus().unsubscribe("match_completed", Callable(self, "_on_match_completed"))
	_event_bus().unsubscribe("match_event_occurred", Callable(self, "_on_match_event_occurred"))
	_cleanup_event_bus()
	await process_frame
	if _failures.is_empty():
		print("MATCH_LOOP_REGRESSION_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("MATCH_LOOP_REGRESSION_TEST_FAIL: %s" % failure)
		quit(1)


func test_representative_mvp_session_completes_full_loop() -> void:
	_captured_match_completed_payloads.clear()
	_captured_match_event_payloads.clear()
	var draw_session: Dictionary[String, Variant] = _run_match_session(_build_match_context({
		"match_id": "loop-draw",
		"result": "draw",
		"home_strength": 64.0,
		"away_strength": 64.0,
		"has_out_of_position_player": false,
		"is_reversal": false,
	}), false)
	_expect(draw_session["history"] == MatchSimulation.FORMAL_STATE_NAMES, "draw MVP session should complete the full formal loop in order")
	_expect(String(draw_session["final_state"]) == "Settlement", "draw MVP session should finish at Settlement")
	_expect(String(draw_session["result_packet"].get("result", "")) == "draw", "draw MVP session should preserve draw as a legal final result")
	_simulation_free(draw_session["simulation"] as MatchSimulation)
	_node_free(draw_session["time_manager"] as Node)
	_captured_match_event_payloads.clear()

	var low_event_session: Dictionary[String, Variant] = _run_match_session(_build_match_context({
		"match_id": "loop-low-density",
		"result": "home_win",
		"event_mod": -0.90,
		"event_seed": 5,
		"has_out_of_position_player": false,
		"is_reversal": false,
	}), false)
	var low_event_summary: Dictionary = low_event_session["result_packet"].get("key_event_summary", {}) as Dictionary
	var low_event_debug: Dictionary[String, Variant] = (low_event_session["simulation"] as MatchSimulation).get_event_emit_debug()
	_expect(int(low_event_summary.get("event_count", 0)) == 3, "low event density MVP session should still close the loop with three legal events")
	_expect(String(low_event_session["final_state"]) == "Settlement", "low event density MVP session should finish at Settlement")
	_expect(bool(low_event_debug.get("event_bus_found", false)), "match_event debug should confirm EventBus was available during emission")
	_expect(bool(low_event_debug.get("has_subscribers", false)), "match_event debug should confirm subscribers were present during emission")
	_expect(_captured_match_event_payloads.size() >= 3 and _captured_match_event_payloads.size() <= 15, "full loop should emit a legal number of match_event_occurred payloads")
	var event_summary_events: Array = (low_event_session["result_packet"].get("key_event_summary", {}) as Dictionary).get("events", []) as Array
	_expect(_captured_match_event_payloads.size() == event_summary_events.size(), "event stream size should match result packet event list")
	if not _captured_match_event_payloads.is_empty() and not event_summary_events.is_empty():
		_expect(int(_captured_match_event_payloads[0].get("match_minute", -1)) == int((event_summary_events[0] as Dictionary[String, Variant]).get("minute", -2)), "event stream should preserve event minute ordering")
	_simulation_free(low_event_session["simulation"] as MatchSimulation)
	_node_free(low_event_session["time_manager"] as Node)


func test_match_result_handoff_supports_downstream_feedback_and_stadium_revenue_inputs() -> void:
	_captured_match_completed_payloads.clear()
	var session: Dictionary[String, Variant] = _run_match_session(_build_match_context({
		"match_id": "loop-downstream",
		"result": "home_win",
		"event_seed": 12,
	}), true)
	var result_packet: Dictionary[String, Variant] = session["result_packet"]
	_expect(String(result_packet.get("match_id", "")) == "loop-downstream", "downstream handoff should preserve match_id")
	_expect(result_packet.has("score"), "downstream handoff should include score")
	_expect(result_packet.has("condition_changes"), "downstream handoff should include condition feedback")
	_expect(result_packet.has("morale_changes"), "downstream handoff should include morale feedback")
	_expect(result_packet.has("player_appearances"), "downstream handoff should include player appearances for growth feedback")
	_expect(result_packet.has("post_match_tags"), "downstream handoff should include post-match feedback tags")
	if not _captured_match_completed_payloads.is_empty():
		_expect(_dictionary_to_text(_captured_match_completed_payloads[_captured_match_completed_payloads.size() - 1]) == _dictionary_to_text(result_packet), "match_completed payload should match the finalized result packet")

	var town_config: TownConfig = TownConfigScript.new()
	var town_building: TownBuilding = TownBuildingScript.new(town_config)
	town_building.initialize_grid(5, 5)
	var stadium: Facility = _active_facility(1, Facility.FacilityType.STADIUM, 3, 2, 2)
	_expect(town_building.register_facility(stadium), "stadium should register for downstream revenue sample")
	var stadium_revenue_multiplier: float = town_building.compute_stadium_revenue_multiplier()
	_expect(is_equal_approx(stadium_revenue_multiplier, 1.24), "downstream economy sample should be able to read stadium revenue multiplier from TownBuilding")
	_expect(not (result_packet.get("condition_changes", []) as Array).is_empty(), "downstream feedback sample should contain condition changes")
	_expect(not (result_packet.get("morale_changes", []) as Array).is_empty(), "downstream feedback sample should contain morale changes")
	_expect(not (result_packet.get("player_appearances", []) as Array).is_empty(), "downstream feedback sample should contain player appearances")

	_simulation_free(session["simulation"] as MatchSimulation)
	_node_free(session["time_manager"] as Node)
	_node_free(town_building)
	stadium = null
	town_config = null


func test_full_match_simulation_stays_under_100ms_and_allows_draw_results() -> void:
	var durations_usec: Array[int] = []
	var draw_verified: bool = false
	for sample: Dictionary[String, Variant] in [
		_build_match_context({
			"match_id": "perf-draw",
			"result": "draw",
			"home_strength": 68.0,
			"away_strength": 68.0,
			"event_seed": 3,
			"event_mod": 0.01,
			"has_out_of_position_player": false,
			"is_reversal": false,
		}),
		_build_match_context({
			"match_id": "perf-high-density",
			"result": "home_win",
			"home_strength": 83.0,
			"away_strength": 59.0,
			"event_seed": 14,
			"event_mod": 0.90,
			"has_out_of_position_player": true,
			"is_reversal": true,
		}),
	]:
		var started_at_usec: int = Time.get_ticks_usec()
		var session: Dictionary[String, Variant] = _run_match_session(sample, true)
		var elapsed_usec: int = Time.get_ticks_usec() - started_at_usec
		durations_usec.append(elapsed_usec)
		_expect(elapsed_usec < 100000, "single full match simulation should finish under 100ms")
		var result_packet: Dictionary[String, Variant] = session["result_packet"]
		if String(sample.get("result", "")) == "draw":
			draw_verified = true
			_expect(String(result_packet.get("result", "")) == "draw", "draw performance sample should end as a legal draw")
			_expect(String(session["final_state"]) == "Settlement", "draw performance sample should reach Settlement without extra-time or penalties")
		_simulation_free(session["simulation"] as MatchSimulation)
		_node_free(session["time_manager"] as Node)
	_expect(draw_verified, "performance regression sample set should include a legal draw case")


func _run_match_session(match_context: Dictionary[String, Variant], apply_halftime_changes: bool) -> Dictionary[String, Variant]:
	var time_manager: Node = _build_ready_time_manager()
	var simulation: MatchSimulation = _build_configured_simulation()
	_expect(simulation.start_formal_match(match_context, time_manager), "match session should start from legal formal entry")
	for _step: int in range(4):
		simulation.advance()
	_expect(simulation.get_state_name() == "Halftime", "match session should reach Halftime before second-half resolution")
	if apply_halftime_changes:
		_expect(simulation.apply_halftime_changes({"tactical_match_mod": 0.04}, [_build_substitution(7, 12), _build_substitution(8, 18)]), "match session should accept legal halftime changes")
	for _step: int in range(3):
		simulation.advance()
	_expect(simulation.get_state_name() == "Settlement", "match session should reach Settlement by the end of the loop")
	return {
		"simulation": simulation,
		"time_manager": time_manager,
		"history": simulation.get_formal_state_history(),
		"final_state": simulation.get_state_name(),
		"result_packet": simulation.get_result_packet(),
	}


func _build_configured_simulation() -> MatchSimulation:
	var simulation: MatchSimulation = MatchSimulationScript.new()
	root.add_child(simulation)
	simulation.set_event_bus_for_testing(_event_bus())
	simulation.set_balance_config_for_testing(_build_balance_config())
	simulation.set_match_config_for_testing(_build_match_config())
	return simulation


func _build_ready_time_manager() -> Node:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.add_child(time_manager)
	time_manager.apply_snapshot({
		"schedule_available": true,
		"scheduled_match_position": 5,
		"current_timeline_position": 5,
		"match_center_available": true,
	})
	return time_manager


func _build_match_context(overrides: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var context: Dictionary[String, Variant] = {
		"match_id": "story-009-match",
		"result": "home_win",
		"home_strength": 78.0,
		"away_strength": 66.0,
		"home_advantage_mod": 0.06,
		"condition_mod": -0.02,
		"event_mod": 0.03,
		"event_seed": 2,
		"has_out_of_position_player": true,
		"is_reversal": true,
		"player_appearances": [
			{"player_id": 1, "minutes": 90, "performance_score": 8.8, "team_side": "home"},
			{"player_id": 2, "minutes": 90, "performance_score": 7.5, "team_side": "home"},
			{"player_id": 3, "minutes": 72, "performance_score": 8.0, "team_side": "home"},
			{"player_id": 12, "minutes": 18, "performance_score": 6.6, "team_side": "home"},
			{"player_id": 18, "minutes": 3, "performance_score": 5.8, "team_side": "home"},
			{"player_id": 101, "minutes": 90, "performance_score": 6.4, "team_side": "away"},
		],
	}
	for key: String in overrides.keys():
		context[key] = overrides[key]
	return context


func _build_substitution(out_player_id: int, in_player_id: int) -> Dictionary[String, Variant]:
	return {
		"out_player_id": out_player_id,
		"in_player_id": in_player_id,
	}


func _build_balance_config() -> BalanceConfig:
	var balance_config: BalanceConfig = BalanceConfigScript.new()
	return balance_config


func _build_match_config() -> MatchConfig:
	var match_config: MatchConfig = MatchConfigScript.new()
	return match_config


func _active_facility(id: int, facility_type: int, level: int, grid_x: int, grid_y: int) -> Facility:
	return FacilityScript.new(id, facility_type, level, Facility.FacilityState.ACTIVE, grid_x, grid_y, 0)


func _setup_event_bus() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)


func _cleanup_event_bus() -> void:
	var event_bus: Node = root.get_node_or_null("EventBus")
	if event_bus != null:
		event_bus.queue_free()


func _event_bus() -> Node:
	return root.get_node("EventBus")


func _on_match_completed(_event_name: String, payload: Dictionary) -> void:
	_captured_match_completed_payloads.append(payload.duplicate(true))


func _on_match_event_occurred(_event_name: String, payload: Dictionary) -> void:
	_captured_match_event_payloads.append(payload.duplicate(true))


func _simulation_free(simulation: MatchSimulation) -> void:
	if simulation == null:
		return
	if simulation.get_parent() != null:
		simulation.get_parent().remove_child(simulation)
	simulation.free()


func _node_free(node: Node) -> void:
	if node == null:
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.free()


func _dictionary_to_text(value: Variant) -> String:
	return JSON.stringify(value)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
