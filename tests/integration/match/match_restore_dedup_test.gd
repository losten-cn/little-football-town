extends SceneTree

const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")
const MatchConfigScript: Script = preload("res://src/config/match_config.gd")

var _failures: Array[String] = []
var _captured_match_completed_payloads: Array[Dictionary] = []
var _captured_match_event_payloads: Array[Dictionary] = []


func _initialize() -> void:
	_setup_event_bus()
	_event_bus().subscribe("match_completed", Callable(self, "_on_match_completed"))
	_event_bus().subscribe("match_event_occurred", Callable(self, "_on_match_event_occurred"))

	test_mid_match_serialize_degrades_to_safe_pending_context()
	test_loading_mid_match_snapshot_restores_entry_without_final_result()
	test_confirmed_match_id_retrigger_hands_off_existing_result_without_replay()

	_event_bus().unsubscribe("match_completed", Callable(self, "_on_match_completed"))
	_event_bus().unsubscribe("match_event_occurred", Callable(self, "_on_match_event_occurred"))
	_cleanup_event_bus()
	await process_frame
	if _failures.is_empty():
		print("MATCH_RESTORE_DEDUP_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("MATCH_RESTORE_DEDUP_TEST_FAIL: %s" % failure)
		quit(1)


func test_mid_match_serialize_degrades_to_safe_pending_context() -> void:
	var save_manager: Node = SaveManagerScript.new()
	var time_manager: Node = _build_ready_time_manager()
	var simulation: MatchSimulation = _build_registered_simulation(save_manager)
	var match_context: Dictionary[String, Variant] = _build_match_context({
		"match_id": "restore-dedup-mid-match",
		"opponent": "Mid Match FC",
	})
	_expect(simulation.start_formal_match(match_context, time_manager), "mid-match sample should start formal match")
	for _step: int in range(5):
		simulation.advance()
	_expect(simulation.get_state_name() == "Second Half", "mid-match sample should reach Second Half before serialization")

	var serialized: Dictionary[String, Variant] = save_manager.serialize_registered_system("match")

	_expect(String(serialized.get("state_name", "")) == "Entry", "mid-match serialize should degrade to Entry")
	_expect((serialized.get("formal_state_history", []) as Array[String]).is_empty(), "mid-match serialize should clear live-half history")
	_expect(String((serialized.get("pending_match_context", {}) as Dictionary[String, Variant]).get("match_id", "")) == "restore-dedup-mid-match", "mid-match serialize should retain pending match_id")
	_expect((serialized.get("result_packet", {}) as Dictionary).is_empty(), "mid-match serialize should not write a final result packet")

	_simulation_free(simulation)
	_node_free(time_manager)
	_node_free(save_manager)


func test_loading_mid_match_snapshot_restores_entry_without_final_result() -> void:
	var save_manager: Node = SaveManagerScript.new()
	var invalid_snapshot: SaveSnapshot = load("res://src/autoload/save_snapshot.gd").new()
	invalid_snapshot.save_version = 1
	invalid_snapshot.timestamp = 1
	invalid_snapshot.playtime_seconds = 1.0
	invalid_snapshot.ui_screen_id = "match"
	invalid_snapshot.ui_stack_depth = 1
	invalid_snapshot.snapshot_metadata = {}
	invalid_snapshot.time_state = {}
	invalid_snapshot.player_state = {}
	invalid_snapshot.match_state = {"state_name": "Entry"}
	invalid_snapshot.economy_state = {}
	invalid_snapshot.town_state = {}
	invalid_snapshot.league_state = {}
	var invalid_validation: Dictionary[String, Variant] = save_manager.validate_snapshot(invalid_snapshot)
	_expect(not bool(invalid_validation.get("is_valid", true)), "save validation should reject incomplete match_state schema")
	_expect((invalid_validation.get("missing_fields", []) as Array[String]).has("match_state.state"), "save validation should report missing match_state.state")
	_expect((invalid_validation.get("missing_fields", []) as Array[String]).has("match_state.pending_match_context"), "save validation should report missing match_state.pending_match_context")
	var time_manager: Node = _build_ready_time_manager()
	var simulation: MatchSimulation = _build_registered_simulation(save_manager)
	var match_context: Dictionary[String, Variant] = _build_match_context({
		"match_id": "restore-dedup-load",
		"opponent": "Load FC",
	})
	_expect(simulation.start_formal_match(match_context, time_manager), "load sample should start formal match")
	for _step: int in range(3):
		simulation.advance()
	_expect(simulation.get_state_name() == "First Half", "load sample should reach First Half before serialization")

	var serialized: Dictionary[String, Variant] = save_manager.serialize_registered_system("match")
	var restored: MatchSimulation = MatchSimulationScript.new()
	root.add_child(restored)
	var restored_time_manager: Node = _build_ready_time_manager()
	restored.bind_time_manager(restored_time_manager)
	restored.deserialize_state(serialized)

	_expect(restored.get_state_name() == "Entry", "loading degraded snapshot should restore Entry")
	_expect(restored.get_formal_state_history().is_empty(), "restored degraded snapshot should not keep in-half history")
	_expect(restored.get_result_packet().is_empty(), "restored degraded snapshot should not silently write final result")
	_expect(String(restored.get_pending_match_context().get("opponent", "")) == "Load FC", "restored degraded snapshot should preserve pending context")

	_simulation_free(simulation)
	_simulation_free(restored)
	_node_free(time_manager)
	_node_free(restored_time_manager)
	_node_free(save_manager)


func test_confirmed_match_id_retrigger_hands_off_existing_result_without_replay() -> void:
	_captured_match_completed_payloads.clear()
	var time_manager: Node = _build_ready_time_manager()
	var simulation: MatchSimulation = _build_configured_simulation()
	var match_context: Dictionary[String, Variant] = _build_match_context({
		"match_id": "restore-dedup-confirmed",
		"result": "home_win",
		"event_seed": 9,
	})
	_expect(simulation.start_formal_match(match_context, time_manager), "confirmed-result sample should start first formal match")
	for _step: int in range(7):
		simulation.advance()
	_expect(simulation.get_state_name() == "Settlement", "first confirmed-result run should reach Settlement")
	var confirmed_result: Dictionary[String, Variant] = simulation.get_result_packet()

	var restored_save_manager: Node = SaveManagerScript.new()
	_expect(simulation.register_with_save_manager(restored_save_manager), "confirmed-result sample should register with SaveManager for restore dedup")
	var serialized: Dictionary[String, Variant] = restored_save_manager.serialize_registered_system("match")
	var restored: MatchSimulation = MatchSimulationScript.new()
	root.add_child(restored)
	var restored_time_manager: Node = _build_ready_time_manager()
	restored.set_balance_config_for_testing(_build_balance_config())
	restored.set_match_config_for_testing(_build_match_config())
	restored.bind_time_manager(restored_time_manager)
	restored.deserialize_state(serialized)
	_captured_match_completed_payloads.clear()

	_expect(restored.start_formal_match(match_context, restored_time_manager), "restored confirmed-result sample should accept retrigger by handing off existing result")
	_expect(restored.get_state_name() == "Settlement", "confirmed retrigger should hand off directly to Settlement")
	_expect(restored.get_formal_state_history() == ["Settlement"], "confirmed retrigger should not replay the full formal flow")
	var replayed_result: Dictionary[String, Variant] = restored.get_result_packet()
	_expect(_dictionary_to_text(replayed_result) == _dictionary_to_text(confirmed_result), "confirmed retrigger should hand off the existing confirmed result packet")
	if not _captured_match_completed_payloads.is_empty():
		_expect(_dictionary_to_text(_captured_match_completed_payloads[0]) == _dictionary_to_text(confirmed_result), "confirmed retrigger event payload should match the existing confirmed result packet")

	_simulation_free(simulation)
	_simulation_free(restored)
	_node_free(time_manager)
	_node_free(restored_time_manager)
	_node_free(restored_save_manager)


func _build_registered_simulation(save_manager: Node) -> MatchSimulation:
	var simulation: MatchSimulation = _build_configured_simulation()
	_expect(simulation.register_with_save_manager(save_manager), "simulation should register with SaveManager")
	return simulation


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
		"match_id": "story-008-match",
		"result": "draw",
		"home_strength": 70.0,
		"away_strength": 67.0,
		"home_advantage_mod": 0.06,
		"condition_mod": -0.02,
		"event_mod": 0.03,
		"event_seed": 4,
		"has_out_of_position_player": false,
		"is_reversal": false,
		"player_appearances": [
			{"player_id": 1, "minutes": 90, "performance_score": 8.1, "team_side": "home"},
			{"player_id": 2, "minutes": 90, "performance_score": 7.4, "team_side": "home"},
			{"player_id": 101, "minutes": 90, "performance_score": 6.8, "team_side": "away"},
		],
	}
	for key: String in overrides.keys():
		context[key] = overrides[key]
	return context


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
