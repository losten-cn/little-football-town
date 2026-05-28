extends Node

const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_match_state_flow_advances_through_exact_eight_states()
	test_formal_match_entry_requires_match_trigger_reached()
	test_formal_match_entry_requires_match_center_availability()
	test_formal_match_entry_rejects_duplicate_trigger_during_active_flow()
	test_live_match_save_restores_to_pending_entry_instead_of_live_half_state()
	test_halftime_save_restores_to_pending_entry_instead_of_live_half_state()
	test_second_half_save_restores_to_pending_entry_instead_of_live_half_state()
	test_restored_entry_can_replay_clean_eight_state_flow()
	if _failures.is_empty():
		print("MATCH_STATE_FLOW_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("MATCH_STATE_FLOW_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_match_state_flow_advances_through_exact_eight_states() -> void:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.apply_snapshot({
		"schedule_available": true,
		"scheduled_match_position": 5,
		"current_timeline_position": 5,
		"match_center_available": true,
	})
	var simulation: MatchSimulation = MatchSimulationScript.new()
	_expect(simulation.start_formal_match({"match_id": "ac1"}, time_manager), "formal match should start when trigger is reached")
	for _step: int in range(7):
		simulation.advance()
	_expect(simulation.get_formal_state_history() == MatchSimulation.FORMAL_STATE_NAMES, "formal state history should match the exact 8-state flow")
	_expect(simulation.get_state_name() == "Settlement", "seventh advance should land on Settlement")


func test_formal_match_entry_requires_match_trigger_reached() -> void:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.apply_snapshot({
		"schedule_available": true,
		"scheduled_match_position": 6,
		"current_timeline_position": 5,
		"match_center_available": true,
	})
	var simulation: MatchSimulation = MatchSimulationScript.new()
	_expect(not simulation.start_formal_match({"match_id": "blocked"}, time_manager), "formal match should not start before trigger is reached")
	_expect(simulation.get_formal_state_history().is_empty(), "blocked entry should not record formal states")
	time_manager.advance_timeline(1)
	_expect(simulation.start_formal_match({"match_id": "allowed"}, time_manager), "formal match should start once trigger is reached")
	_expect(simulation.get_state_name() == "Entry", "legal entry should begin at Entry state")


func test_formal_match_entry_requires_match_center_availability() -> void:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.apply_snapshot({
		"schedule_available": true,
		"scheduled_match_position": 5,
		"current_timeline_position": 5,
		"match_center_available": false,
	})
	var simulation: MatchSimulation = MatchSimulationScript.new()
	_expect(not simulation.start_formal_match({"match_id": "center-blocked"}, time_manager), "formal match should not start when match center is unavailable")
	_expect(simulation.get_formal_state_history().is_empty(), "center-unavailable entry should not record formal states")


func test_formal_match_entry_rejects_duplicate_trigger_during_active_flow() -> void:
	var time_manager: Node = _build_ready_time_manager(4)
	var simulation: MatchSimulation = MatchSimulationScript.new()
	_expect(simulation.start_formal_match({"match_id": "duplicate-guard"}, time_manager), "initial formal match entry should succeed")
	_expect(not simulation.start_formal_match({"match_id": "duplicate-guard-2"}, time_manager), "active formal flow should reject duplicate entry")
	_expect(simulation.get_pending_match_context().get("match_id", "") == "duplicate-guard", "duplicate entry should not overwrite active pending context")


func test_live_match_save_restores_to_pending_entry_instead_of_live_half_state() -> void:
	var save_manager: SaveManager = SaveManagerScript.new()
	var time_manager: Node = _build_ready_time_manager(3)
	var simulation: MatchSimulation = MatchSimulationScript.new()
	_expect(simulation.register_with_save_manager(save_manager), "match system should register with SaveManager")
	_expect(save_manager.has_registered_system("match"), "SaveManager should retain match registration")
	_expect(simulation.start_formal_match({"match_id": "ac3", "opponent": "Rivals"}, time_manager), "formal match should start for save degradation test")
	simulation.advance()
	simulation.advance()
	simulation.advance()
	_expect(simulation.get_state_name() == "First Half", "simulation should enter First Half before serialization")
	var serialized: Dictionary[String, Variant] = save_manager.serialize_registered_system("match")
	_assert_entry_restore(serialized, "ac3", "Rivals", "first-half save should degrade to Entry")


func test_halftime_save_restores_to_pending_entry_instead_of_live_half_state() -> void:
	var save_manager: SaveManager = SaveManagerScript.new()
	var time_manager: Node = _build_ready_time_manager(7)
	var simulation: MatchSimulation = MatchSimulationScript.new()
	_expect(simulation.register_with_save_manager(save_manager), "match system should register with SaveManager for halftime save")
	_expect(simulation.start_formal_match({"match_id": "ac3-halftime", "opponent": "Halftime Rivals"}, time_manager), "formal match should start for halftime save degradation test")
	for _step: int in range(4):
		simulation.advance()
	_expect(simulation.get_state_name() == "Halftime", "simulation should enter Halftime before serialization")
	var serialized: Dictionary[String, Variant] = save_manager.serialize_registered_system("match")
	_assert_entry_restore(serialized, "ac3-halftime", "Halftime Rivals", "halftime save should degrade to Entry")


func test_second_half_save_restores_to_pending_entry_instead_of_live_half_state() -> void:
	var save_manager: SaveManager = SaveManagerScript.new()
	var time_manager: Node = _build_ready_time_manager(9)
	var simulation: MatchSimulation = MatchSimulationScript.new()
	_expect(simulation.register_with_save_manager(save_manager), "match system should register with SaveManager for second-half save")
	_expect(simulation.start_formal_match({"match_id": "ac3-second-half", "opponent": "Second Half Rivals"}, time_manager), "formal match should start for second-half save degradation test")
	for _step: int in range(5):
		simulation.advance()
	_expect(simulation.get_state_name() == "Second Half", "simulation should enter Second Half before serialization")
	var serialized: Dictionary[String, Variant] = save_manager.serialize_registered_system("match")
	_assert_entry_restore(serialized, "ac3-second-half", "Second Half Rivals", "second-half save should degrade to Entry")


func test_restored_entry_can_replay_clean_eight_state_flow() -> void:
	var save_manager: SaveManager = SaveManagerScript.new()
	var time_manager: Node = _build_ready_time_manager(11)
	var simulation: MatchSimulation = MatchSimulationScript.new()
	_expect(simulation.register_with_save_manager(save_manager), "match system should register with SaveManager for replay test")
	_expect(simulation.start_formal_match({"match_id": "replay-clean", "opponent": "Replay Rivals"}, time_manager), "formal match should start for replay cleanliness test")
	simulation.advance()
	simulation.advance()
	simulation.advance()
	var serialized: Dictionary[String, Variant] = save_manager.serialize_registered_system("match")
	var restored: MatchSimulation = MatchSimulationScript.new()
	restored.bind_time_manager(time_manager)
	restored.deserialize_state(serialized)
	_expect(restored.get_formal_state_history().is_empty(), "restored entry should not retain in-half state history")
	for _step: int in range(7):
		restored.advance()
	_expect(restored.get_formal_state_history() == MatchSimulation.FORMAL_STATE_NAMES, "restored entry should replay a clean single 8-state flow")


func _build_ready_time_manager(trigger_position: int) -> Node:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.apply_snapshot({
		"schedule_available": true,
		"scheduled_match_position": trigger_position,
		"current_timeline_position": trigger_position,
		"match_center_available": true,
	})
	return time_manager


func _assert_entry_restore(serialized: Dictionary[String, Variant], expected_match_id: String, expected_opponent: String, failure_prefix: String) -> void:
	_expect(String(serialized.get("state_name", "")) == "Entry", "%s" % failure_prefix)
	_expect((serialized.get("pending_match_context", {}) as Dictionary[String, Variant]).get("match_id", "") == expected_match_id, "%s should retain match identity" % failure_prefix)
	_expect((serialized.get("formal_state_history", []) as Array[String]).is_empty(), "%s should clear in-progress state history" % failure_prefix)
	var restored: MatchSimulation = MatchSimulationScript.new()
	restored.deserialize_state(serialized)
	_expect(restored.get_state_name() == "Entry", "%s should restore to Entry" % failure_prefix)
	_expect(restored.get_pending_match_context().get("opponent", "") == expected_opponent, "%s should preserve pending context metadata" % failure_prefix)
	_expect(restored.get_formal_state_history().is_empty(), "%s should restore without residual state history" % failure_prefix)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
