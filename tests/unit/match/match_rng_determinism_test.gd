extends SceneTree

const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")
const MatchConfigScript: Script = preload("res://src/config/match_config.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	test_same_seed_and_inputs_produce_same_event_sequence_and_result()
	test_different_seed_changes_event_sequence_or_result()
	test_same_seed_preserves_halftime_adjusted_second_half_and_win_reasons()
	test_restore_to_entry_rebuilds_rng_for_deterministic_replay()
	await process_frame
	if _failures.is_empty():
		print("MATCH_RNG_DETERMINISM_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("MATCH_RNG_DETERMINISM_TEST_FAIL: %s" % failure)
		quit(1)


func test_same_seed_and_inputs_produce_same_event_sequence_and_result() -> void:
	var first_result: Dictionary[String, Variant] = _simulate_match_result(_build_match_context({}), 17, true)
	var second_result: Dictionary[String, Variant] = _simulate_match_result(_build_match_context({}), 17, true)
	_expect(first_result.get("result", "") == second_result.get("result", ""), "same seed should preserve final result")
	_expect(_dictionary_to_text(first_result.get("score", {})) == _dictionary_to_text(second_result.get("score", {})), "same seed should preserve score summary")
	_expect(_dictionary_to_text(first_result.get("key_event_summary", {})) == _dictionary_to_text(second_result.get("key_event_summary", {})), "same seed should preserve event summary")
	_expect(_array_to_text(first_result.get("player_appearances", [])) == _array_to_text(second_result.get("player_appearances", [])), "same seed should preserve player appearances")
	_expect(_array_to_text(first_result.get("win_reasons", [])) == _array_to_text(second_result.get("win_reasons", [])), "same seed should preserve win reasons")


func test_different_seed_changes_event_sequence_or_result() -> void:
	var first_result: Dictionary[String, Variant] = _simulate_match_result(_build_match_context({}), 17, true)
	var second_result: Dictionary[String, Variant] = _simulate_match_result(_build_match_context({}), 18, true)
	var event_summary_changed: bool = _dictionary_to_text(first_result.get("key_event_summary", {})) != _dictionary_to_text(second_result.get("key_event_summary", {}))
	var score_changed: bool = _dictionary_to_text(first_result.get("score", {})) != _dictionary_to_text(second_result.get("score", {}))
	var result_changed: bool = String(first_result.get("result", "")) != String(second_result.get("result", ""))
	_expect(event_summary_changed or score_changed or result_changed, "different seed should change event sequence or final outcome")


func test_same_seed_preserves_halftime_adjusted_second_half_and_win_reasons() -> void:
	var context: Dictionary[String, Variant] = _build_match_context({
		"match_id": "determinism-halftime",
		"result": "draw",
		"home_strength": 64.0,
		"away_strength": 63.0,
		"has_out_of_position_player": false,
		"is_reversal": false,
	})
	var first_output: Dictionary[String, Variant] = _simulate_match_output(context, 31, true)
	var second_output: Dictionary[String, Variant] = _simulate_match_output(context, 31, true)
	var first_result_packet: Dictionary[String, Variant] = _to_typed_dictionary(first_output.get("result_packet", {}))
	var second_result_packet: Dictionary[String, Variant] = _to_typed_dictionary(second_output.get("result_packet", {}))
	_expect(_dictionary_to_text(first_output.get("first_half_snapshot", {})) == _dictionary_to_text(second_output.get("first_half_snapshot", {})), "same seed should preserve first-half output")
	_expect(_dictionary_to_text(first_result_packet.get("key_event_summary", {})) == _dictionary_to_text(second_result_packet.get("key_event_summary", {})), "same seed should preserve halftime-adjusted second-half evolution")
	_expect(_array_to_text(first_result_packet.get("win_reasons", [])) == _array_to_text(second_result_packet.get("win_reasons", [])), "same seed should preserve halftime-adjusted win reasons")
	_expect(_array_to_text(first_result_packet.get("post_match_tags", [])) == _array_to_text(second_result_packet.get("post_match_tags", [])), "same seed should preserve halftime-adjusted post-match tags")


func test_restore_to_entry_rebuilds_rng_for_deterministic_replay() -> void:
	var context: Dictionary[String, Variant] = _build_match_context({
		"match_id": "determinism-restore",
		"event_seed": 27,
	})
	var baseline_output: Dictionary[String, Variant] = _simulate_match_output(context, 27, true)
	var baseline_result_packet: Dictionary[String, Variant] = _to_typed_dictionary(baseline_output.get("result_packet", {}))
	var save_manager: Node = SaveManagerScript.new()
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
	simulation.set_balance_config_for_testing(_build_balance_config())
	simulation.set_match_config_for_testing(_build_match_config())
	simulation.set_match_seed_for_testing(27)
	_expect(simulation.register_with_save_manager(save_manager), "restore determinism sample should register with SaveManager")
	_expect(simulation.start_formal_match(context, time_manager), "restore determinism sample should start formal match")
	for _step: int in range(3):
		simulation.advance()
	var degraded_snapshot: Dictionary[String, Variant] = save_manager.serialize_registered_system("match")
	root.remove_child(simulation)
	simulation.free()
	var restored: MatchSimulation = MatchSimulationScript.new()
	root.add_child(restored)
	restored.set_balance_config_for_testing(_build_balance_config())
	restored.set_match_config_for_testing(_build_match_config())
	restored.bind_time_manager(time_manager)
	restored.deserialize_state(degraded_snapshot)
	_expect(restored.get_state_name() == "Entry", "restored determinism sample should restart from degraded Entry")
	for _step: int in range(4):
		restored.advance()
	_expect(restored.get_state_name() == "Halftime", "restored determinism sample should reach Halftime before second-half replay")
	_expect(restored.apply_halftime_changes({"tactical_match_mod": 0.04}, [_build_substitution(7, 12), _build_substitution(8, 18)]), "restored determinism sample should apply halftime changes")
	for _step: int in range(3):
		restored.advance()
	var restored_result_packet: Dictionary[String, Variant] = restored.get_result_packet()
	var baseline_first_half_snapshot: Dictionary[String, Variant] = _to_typed_dictionary(baseline_output.get("first_half_snapshot", {}))
	var restored_first_half_snapshot: Dictionary[String, Variant] = restored.get_first_half_snapshot()
	_expect(_dictionary_to_text(baseline_first_half_snapshot.get("events", [])) == _dictionary_to_text(restored_first_half_snapshot.get("events", [])), "restore to Entry should preserve deterministic first-half replay")
	_expect(_dictionary_to_text(baseline_result_packet.get("key_event_summary", {})) == _dictionary_to_text(restored_result_packet.get("key_event_summary", {})), "restore to Entry should preserve deterministic event summary")
	_expect(_dictionary_to_text(baseline_result_packet.get("score", {})) == _dictionary_to_text(restored_result_packet.get("score", {})), "restore to Entry should preserve deterministic score")
	root.remove_child(restored)
	restored.free()
	root.remove_child(time_manager)
	time_manager.free()


func _simulate_match_result(match_context: Dictionary[String, Variant], match_seed: int, apply_halftime_changes: bool) -> Dictionary[String, Variant]:
	return _to_typed_dictionary(_simulate_match_output(match_context, match_seed, apply_halftime_changes).get("result_packet", {}))


func _simulate_match_output(match_context: Dictionary[String, Variant], match_seed: int, apply_halftime_changes: bool) -> Dictionary[String, Variant]:
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
	simulation.set_balance_config_for_testing(_build_balance_config())
	simulation.set_match_config_for_testing(_build_match_config())
	simulation.set_match_seed_for_testing(match_seed)
	_expect(simulation.start_formal_match(match_context, time_manager), "determinism sample should start formal match")
	for _step: int in range(4):
		simulation.advance()
	_expect(simulation.get_state_name() == "Halftime", "determinism sample should reach Halftime")
	if apply_halftime_changes:
		_expect(simulation.apply_halftime_changes({"tactical_match_mod": 0.04}, [_build_substitution(7, 12), _build_substitution(8, 18)]), "determinism sample should apply halftime changes")
	var first_half_snapshot: Dictionary[String, Variant] = simulation.get_first_half_snapshot()
	for _step: int in range(3):
		simulation.advance()
	_expect(simulation.get_state_name() == "Settlement", "determinism sample should reach Settlement")
	var output: Dictionary[String, Variant] = {
		"first_half_snapshot": first_half_snapshot,
		"result_packet": simulation.get_result_packet(),
	}
	root.remove_child(simulation)
	simulation.free()
	root.remove_child(time_manager)
	time_manager.free()
	return output


func _build_match_context(overrides: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var context: Dictionary[String, Variant] = {
		"match_id": "story-007-match",
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


func _dictionary_to_text(value: Variant) -> String:
	return JSON.stringify(value)


func _array_to_text(value: Variant) -> String:
	return JSON.stringify(value)


func _to_typed_dictionary(source: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if source is Dictionary:
		var source_dictionary: Dictionary = source as Dictionary
		for key: Variant in source_dictionary.keys():
			typed_dictionary[String(key)] = source_dictionary[key]
	return typed_dictionary


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
