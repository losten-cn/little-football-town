extends SceneTree

const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")
const MatchConfigScript: Script = preload("res://src/config/match_config.gd")

var _failures: Array[String] = []
var _captured_match_completed_payloads: Array[Dictionary] = []


func _initialize() -> void:
	_setup_event_bus()
	_event_bus().subscribe("match_completed", Callable(self, "_on_match_completed"))
	_expect(_event_bus().subscriber_count("match_completed") == 1, "match_completed subscription should be registered before assertions")
	_captured_match_completed_payloads.clear()
	_event_bus().emit("match_completed", {"match_id": "probe"})
	_expect(String(_captured_match_completed_payloads[0].get("match_id", "")) == "probe", "match_completed probe should reach test callback before assertions")
	test_result_packet_contains_required_fields_and_match_completed_payload()
	test_win_reasons_limit_to_top_three_and_preserve_priority_order()
	test_each_appearing_player_receives_minutes_and_legal_growth_tag()
	test_draw_and_low_event_density_produce_consistent_reasonable_packet()
	test_no_substitutions_still_produce_complete_result_packet()
	_event_bus().unsubscribe("match_completed", Callable(self, "_on_match_completed"))
	_cleanup_event_bus()
	await process_frame
	if _failures.is_empty():
		print("MATCH_RESULT_PACKET_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("MATCH_RESULT_PACKET_TEST_FAIL: %s" % failure)
		quit(1)


func test_result_packet_contains_required_fields_and_match_completed_payload() -> void:
	_captured_match_completed_payloads.clear()
	var session: Dictionary[String, Variant] = _build_completed_session(_build_match_context({}), true)
	var simulation: MatchSimulation = session["simulation"] as MatchSimulation
	var time_manager: Node = session["time_manager"] as Node
	var result_packet: Dictionary[String, Variant] = simulation.get_result_packet()
	var event_emit_debug: Dictionary[String, Variant] = simulation.get_event_emit_debug()
	_expect(result_packet.has("match_id"), "result packet should include match_id")
	_expect(result_packet.has("result"), "result packet should include result")
	_expect(result_packet.has("score"), "result packet should include score")
	_expect(result_packet.has("key_event_summary"), "result packet should include key_event_summary")
	_expect(result_packet.has("player_appearances"), "result packet should include player_appearances")
	_expect(result_packet.has("condition_changes"), "result packet should include condition_changes")
	_expect(result_packet.has("morale_changes"), "result packet should include morale_changes")
	_expect(result_packet.has("win_reasons"), "result packet should include win_reasons")
	_expect(result_packet.has("post_match_tags"), "result packet should include post_match_tags")
	_expect(String(result_packet.get("match_id", "")) == "story-006-match", "result packet should preserve match_id")
	_expect(bool(event_emit_debug.get("event_bus_found", false)), "match_completed debug should confirm EventBus was available during emission")
	_expect(bool(event_emit_debug.get("has_subscribers", false)), "match_completed debug should confirm subscribers were present during emission")
	_expect(not _captured_match_completed_payloads.is_empty(), "match_completed should emit a payload")
	if not _captured_match_completed_payloads.is_empty():
		_expect(String(_captured_match_completed_payloads[_captured_match_completed_payloads.size() - 1].get("match_id", "")) == "story-006-match", "match_completed payload should include match_id")
	var score: Dictionary = result_packet.get("score", {}) as Dictionary
	_expect(int(score.get("home", -1)) == 2 and int(score.get("away", -1)) == 1, "home_win should produce a consistent 2-1 score summary")
	var event_summary: Dictionary = result_packet.get("key_event_summary", {}) as Dictionary
	_expect(int(event_summary.get("event_count", 0)) >= 3, "key_event_summary should contain at least three events")
	_expect(not (result_packet.get("player_appearances", []) as Array).is_empty(), "player appearances should not be empty")
	var morale_changes: Array = result_packet.get("morale_changes", []) as Array
	var away_morale_change: Dictionary[String, Variant] = _find_player_entry(morale_changes, 101)
	_expect(float(away_morale_change.get("new_morale", 1.0)) < float(away_morale_change.get("old_morale", 0.0)), "away player morale should decrease after a home win")
	_simulation_free(simulation)
	_node_free(time_manager)


func test_win_reasons_limit_to_top_three_and_preserve_priority_order() -> void:
	var session: Dictionary[String, Variant] = _build_completed_session(_build_match_context({
		"match_id": "reasons-top-three",
		"home_strength": 82.0,
		"away_strength": 60.0,
		"has_out_of_position_player": true,
		"is_reversal": true,
	}), true)
	var simulation: MatchSimulation = session["simulation"] as MatchSimulation
	var time_manager: Node = session["time_manager"] as Node
	var win_reasons: Array = simulation.get_result_packet().get("win_reasons", []) as Array
	_expect(win_reasons.size() <= 3, "win reasons should cap at the ADR top-three contract")
	_expect(win_reasons == ["阵容强度差距", "错位球员表现不足", "体能不足影响下半场"], "win reasons should preserve existing priority order before truncation")
	_simulation_free(simulation)
	_node_free(time_manager)


func test_each_appearing_player_receives_minutes_and_legal_growth_tag() -> void:
	var session: Dictionary[String, Variant] = _build_completed_session(_build_match_context({
		"player_appearances": [
			{"player_id": 1, "minutes": 90, "performance_score": 8.8, "team_side": "home"},
			{"player_id": 2, "minutes": 90, "performance_score": 7.5, "team_side": "home"},
			{"player_id": 3, "minutes": 72, "performance_score": 8.0, "team_side": "home"},
			{"player_id": 12, "minutes": 18, "performance_score": 6.6, "team_side": "home"},
			{"player_id": 18, "minutes": 3, "performance_score": 5.8, "team_side": "home"},
			{"player_id": 19, "minutes": 0, "performance_score": 6.1, "team_side": "home"},
		],
	}), true)
	var simulation: MatchSimulation = session["simulation"] as MatchSimulation
	var time_manager: Node = session["time_manager"] as Node
	var appearances: Array = simulation.get_result_packet().get("player_appearances", []) as Array
	_expect(appearances.size() == 5, "zero-minute players should not be marked as appearing players")
	for player_entry_variant: Variant in appearances:
		var player_entry: Dictionary = player_entry_variant as Dictionary
		_expect(int(player_entry.get("minutes", -1)) > 0, "appearing player should include positive minutes")
		var growth_tag: String = String(player_entry.get("post_match_growth_tag", ""))
		_expect(growth_tag in ["无", "轻度", "常规", "显著", "突破性"], "appearing player should receive a legal growth tag")
		if int(player_entry.get("minutes", 0)) < 5:
			_expect(growth_tag == "无", "very short appearances should be allowed to receive 无")
	_simulation_free(simulation)
	_node_free(time_manager)


func test_draw_and_low_event_density_produce_consistent_reasonable_packet() -> void:
	var session: Dictionary[String, Variant] = _build_completed_session(_build_match_context({
		"match_id": "draw-low-density",
		"result": "draw",
		"home_strength": 61.0,
		"away_strength": 61.0,
		"has_out_of_position_player": false,
		"is_reversal": false,
		"event_mod": -0.90,
		"event_seed": 1,
	}), true)
	var simulation: MatchSimulation = session["simulation"] as MatchSimulation
	var time_manager: Node = session["time_manager"] as Node
	var result_packet: Dictionary[String, Variant] = simulation.get_result_packet()
	var score: Dictionary = result_packet.get("score", {}) as Dictionary
	_expect(int(score.get("home", -1)) == 1 and int(score.get("away", -1)) == 1, "draw packet should keep a draw score summary")
	var win_reasons: Array = result_packet.get("win_reasons", []) as Array
	_expect(not win_reasons.is_empty(), "draw should still produce explainable win reasons")
	var event_summary: Dictionary = result_packet.get("key_event_summary", {}) as Dictionary
	_expect(int(event_summary.get("event_count", 0)) == 3, "low event density sample should clamp to three events")
	_simulation_free(simulation)
	_node_free(time_manager)


func test_no_substitutions_still_produce_complete_result_packet() -> void:
	_captured_match_completed_payloads.clear()
	var session: Dictionary[String, Variant] = _build_completed_session(_build_match_context({
		"match_id": "no-substitutions",
		"result": "home_win",
		"has_out_of_position_player": false,
		"is_reversal": false,
	}), false)
	var simulation: MatchSimulation = session["simulation"] as MatchSimulation
	var time_manager: Node = session["time_manager"] as Node
	var result_packet: Dictionary[String, Variant] = simulation.get_result_packet()
	_expect(simulation.get_state_name() == "Settlement", "no-substitutions sample should still reach Settlement")
	_expect(String(result_packet.get("match_id", "")) == "no-substitutions", "result packet should preserve match_id without halftime changes")
	_expect(not _captured_match_completed_payloads.is_empty(), "match_completed should emit without halftime changes")
	if not _captured_match_completed_payloads.is_empty():
		_expect(String(_captured_match_completed_payloads[_captured_match_completed_payloads.size() - 1].get("match_id", "")) == "no-substitutions", "match_completed payload should preserve match_id without halftime changes")
	_expect(result_packet.has("score"), "result packet without substitutions should include score")
	_expect(result_packet.has("key_event_summary"), "result packet without substitutions should include key_event_summary")
	_expect(result_packet.has("player_appearances"), "result packet without substitutions should include player_appearances")
	_expect(not (result_packet.get("player_appearances", []) as Array).is_empty(), "player appearances should remain non-empty without substitutions")
	_expect(not (result_packet.get("win_reasons", []) as Array).is_empty(), "win reasons should remain non-empty without substitutions")
	_simulation_free(simulation)
	_node_free(time_manager)


func _build_completed_session(match_context: Dictionary[String, Variant], apply_halftime_changes: bool) -> Dictionary[String, Variant]:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.add_child(time_manager)
	time_manager.apply_snapshot({
		"schedule_available": true,
		"scheduled_match_position": 5,
		"current_timeline_position": 5,
		"match_center_available": true,
	})
	var simulation: MatchSimulation = MatchSimulationScript.new()
	root.add_child(simulation)
	simulation.set_event_bus_for_testing(_event_bus())
	simulation.set_balance_config_for_testing(_build_balance_config())
	simulation.set_match_config_for_testing(_build_match_config())
	_expect(simulation.start_formal_match(match_context, time_manager), "formal match should start for match result packet test")
	for _step: int in range(4):
		simulation.advance()
	_expect(simulation.get_state_name() == "Halftime", "simulation should reach Halftime before result packet assertions")
	if apply_halftime_changes:
		_expect(simulation.apply_halftime_changes({"tactical_match_mod": 0.04}, [_build_substitution(7, 12), _build_substitution(8, 18)]), "halftime changes should apply before second half")
	for _step: int in range(3):
		simulation.advance()
	_expect(simulation.get_state_name() == "Settlement", "simulation should emit match_completed before packet assertions")
	return {
		"simulation": simulation,
		"time_manager": time_manager,
	}


func _build_match_context(overrides: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var context: Dictionary[String, Variant] = {
		"match_id": "story-006-match",
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


func _find_player_entry(entries: Array, player_id: int) -> Dictionary[String, Variant]:
	for entry_variant: Variant in entries:
		var entry: Dictionary = entry_variant as Dictionary
		if int(entry.get("player_id", 0)) == player_id:
			var typed_entry: Dictionary[String, Variant] = {}
			for key: Variant in entry.keys():
				typed_entry[String(key)] = entry[key]
			return typed_entry
	return {}


func _build_balance_config() -> BalanceConfig:
	var balance_config: BalanceConfig = BalanceConfigScript.new()
	return balance_config


func _build_match_config() -> MatchConfig:
	var match_config: MatchConfig = MatchConfigScript.new()
	return match_config


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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
