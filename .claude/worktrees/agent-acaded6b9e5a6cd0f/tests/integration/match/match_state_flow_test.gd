extends Node

const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const PASS_MARKER: String = "MATCH_STATE_FLOW_TEST_PASS"
const FAIL_MARKER: String = "MATCH_STATE_FLOW_TEST_FAIL"

var _failures: Array[String] = []


func _ready() -> void:
	test_match_state_flow_canonical_sequence_reaches_settlement()
	test_match_state_flow_confirmation_return_remains_legal()
	test_match_entry_requires_match_trigger_reached_true()
	test_match_save_restore_drops_first_half_to_entry_context()
	test_match_save_restore_drops_halftime_to_entry_context()
	test_match_save_restore_drops_second_half_to_entry_context()
	if _failures.is_empty():
		print(PASS_MARKER)
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("%s: %s" % [FAIL_MARKER, failure])
		get_tree().quit(1)


func test_match_state_flow_canonical_sequence_reaches_settlement() -> void:
	# Arrange
	var simulation: MatchSimulation = _create_simulation()
	var legal_context: Dictionary[String, Variant] = _build_match_context(true)

	# Act
	var started: bool = simulation.start_formal_match(legal_context)
	simulation.advance()
	simulation.advance()
	simulation.advance()
	simulation.advance()
	simulation.advance()
	simulation.advance()
	simulation.advance()

	# Assert
	_expect(started, "formal match should start from a legal node")
	_expect(simulation.get_state_name() == "Settlement", "canonical flow should stop at Settlement before reset")
	_expect(
		simulation.get_transition_history() == [
			"Entry",
			"Pre-Match",
			"Confirmation",
			"First Half",
			"Halftime",
			"Second Half",
			"Result Review",
			"Settlement",
		],
		"canonical flow should follow the exact 8-state sequence"
	)
	_cleanup_simulation(simulation)


func test_match_state_flow_confirmation_return_remains_legal() -> void:
	# Arrange
	var simulation: MatchSimulation = _create_simulation()
	var legal_context: Dictionary[String, Variant] = _build_match_context(true)
	simulation.start_formal_match(legal_context)
	simulation.advance()
	simulation.advance()

	# Act
	simulation.return_to_pre_match()
	var state_after_return: String = simulation.get_state_name()
	simulation.advance()
	var state_after_reconfirm: String = simulation.get_state_name()

	# Assert
	_expect(state_after_return == "Pre-Match", "confirmation should be able to return to Pre-Match")
	_expect(state_after_reconfirm == "Confirmation", "pre-match should be able to re-enter Confirmation")
	_cleanup_simulation(simulation)


func test_match_entry_requires_match_trigger_reached_true() -> void:
	# Arrange
	var legal_simulation: MatchSimulation = _create_simulation()
	var illegal_simulation: MatchSimulation = _create_simulation()
	var legal_context: Dictionary[String, Variant] = _build_match_context(true)
	var illegal_context: Dictionary[String, Variant] = _build_match_context(false)

	# Act
	var legal_started: bool = legal_simulation.start_formal_match(legal_context)
	var illegal_started: bool = illegal_simulation.start_formal_match(illegal_context)

	# Assert
	_expect(legal_started, "legal match node should enter the formal match flow")
	_expect(legal_simulation.get_state_name() == "Entry", "legal match node should begin at Entry")
	_expect(not illegal_started, "illegal match node should be rejected")
	_expect(illegal_simulation.get_state_name() == "Idle", "illegal match node should not create in-progress state")
	_expect(illegal_simulation.get_transition_history().is_empty(), "illegal match node should not record formal state history")
	_cleanup_simulation(legal_simulation)
	_cleanup_simulation(illegal_simulation)


func test_match_save_restore_drops_first_half_to_entry_context() -> void:
	# Arrange
	var simulation: MatchSimulation = _create_simulation()
	simulation.start_formal_match(_build_match_context(true))
	simulation.advance()
	simulation.advance()
	simulation.advance()
	var serialized_state: Dictionary[String, Variant] = simulation.serialize_state()
	var restored_simulation: MatchSimulation = _create_simulation()

	# Act
	restored_simulation.deserialize_state(serialized_state)

	# Assert
	_expect(simulation.get_state_name() == "First Half", "arrange should place the match in First Half")
	_expect(serialized_state["state"] as int == MatchSimulation.State.ENTRY, "first-half save should serialize back to Entry")
	_expect(serialized_state["abandoned_in_progress_state"] as bool, "first-half save should mark the unstable state as abandoned")
	_expect(restored_simulation.get_state_name() == "Entry", "first-half load should restore to Entry")
	_cleanup_simulation(simulation)
	_cleanup_simulation(restored_simulation)


func test_match_save_restore_drops_halftime_to_entry_context() -> void:
	# Arrange
	var simulation: MatchSimulation = _create_simulation()
	simulation.start_formal_match(_build_match_context(true))
	simulation.advance()
	simulation.advance()
	simulation.advance()
	simulation.advance()
	var serialized_state: Dictionary[String, Variant] = simulation.serialize_state()
	var restored_simulation: MatchSimulation = _create_simulation()

	# Act
	restored_simulation.deserialize_state(serialized_state)

	# Assert
	_expect(simulation.get_state_name() == "Halftime", "arrange should place the match in Halftime")
	_expect(serialized_state["state"] as int == MatchSimulation.State.ENTRY, "halftime save should serialize back to Entry")
	_expect(restored_simulation.get_state_name() == "Entry", "halftime load should restore to Entry")
	_cleanup_simulation(simulation)
	_cleanup_simulation(restored_simulation)


func test_match_save_restore_drops_second_half_to_entry_context() -> void:
	# Arrange
	var simulation: MatchSimulation = _create_simulation()
	simulation.start_formal_match(_build_match_context(true))
	simulation.advance()
	simulation.advance()
	simulation.advance()
	simulation.advance()
	simulation.advance()
	var serialized_state: Dictionary[String, Variant] = simulation.serialize_state()
	var restored_simulation: MatchSimulation = _create_simulation()

	# Act
	restored_simulation.deserialize_state(serialized_state)

	# Assert
	_expect(simulation.get_state_name() == "Second Half", "arrange should place the match in Second Half")
	_expect(serialized_state["state"] as int == MatchSimulation.State.ENTRY, "second-half save should serialize back to Entry")
	_expect(restored_simulation.get_state_name() == "Entry", "second-half load should restore to Entry")
	_cleanup_simulation(simulation)
	_cleanup_simulation(restored_simulation)


func _create_simulation() -> MatchSimulation:
	var simulation: MatchSimulation = MatchSimulationScript.new()
	add_child(simulation)
	return simulation


func _cleanup_simulation(simulation: MatchSimulation) -> void:
	if is_instance_valid(simulation):
		simulation.queue_free()


func _build_match_context(match_trigger_reached: bool) -> Dictionary[String, Variant]:
	return {
		"match_trigger_reached": match_trigger_reached,
		"match_id": "story-001-fixture",
		"opponent_name": "Test United",
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
