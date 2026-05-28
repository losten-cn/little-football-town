extends Node

const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_halftime_adjustment_accepts_up_to_three_substitutions()
	test_halftime_adjustment_preserves_first_half_snapshot_and_updates_second_half_plan()
	test_halftime_adjustment_allows_no_changes_and_advances_to_second_half()
	if _failures.is_empty():
		print("HALFTIME_ADJUSTMENT_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("HALFTIME_ADJUSTMENT_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_halftime_adjustment_accepts_up_to_three_substitutions() -> void:
	var simulation: MatchSimulation = _build_simulation_at_halftime()
	_expect(simulation.apply_halftime_changes({"shape": "4-4-2"}, []), "halftime should allow zero substitutions")
	_expect(simulation.apply_halftime_changes({"shape": "4-3-3"}, [_build_substitution(1, 12)]), "halftime should allow one substitution")
	_expect(simulation.apply_halftime_changes({"shape": "3-5-2"}, [_build_substitution(1, 12), _build_substitution(2, 13), _build_substitution(3, 14)]), "halftime should allow up to three substitutions")
	_expect(not simulation.apply_halftime_changes({"shape": "3-4-3"}, [_build_substitution(1, 12), _build_substitution(2, 13), _build_substitution(3, 14), _build_substitution(4, 15)]), "halftime should reject a fourth substitution")


func test_halftime_adjustment_preserves_first_half_snapshot_and_updates_second_half_plan() -> void:
	var simulation: MatchSimulation = _build_simulation_at_halftime()
	var frozen_snapshot: Dictionary[String, Variant] = simulation.get_first_half_snapshot()
	_expect(simulation.apply_halftime_changes({"pressing": "high"}, [_build_substitution(7, 17), _build_substitution(8, 18)]), "halftime changes should apply during halftime")
	_expect(simulation.get_first_half_snapshot() == frozen_snapshot, "halftime changes should not rewrite the first-half snapshot")
	var second_half_plan: Dictionary[String, Variant] = simulation.get_second_half_plan()
	_expect((second_half_plan.get("tactics", {}) as Dictionary[String, Variant]).get("pressing", "") == "high", "second-half plan should record updated tactics")
	_expect((second_half_plan.get("substitutions", []) as Array[Dictionary]).size() == 2, "second-half plan should record halftime substitutions")


func test_halftime_adjustment_allows_no_changes_and_advances_to_second_half() -> void:
	var simulation: MatchSimulation = _build_simulation_at_halftime()
	_expect(simulation.apply_halftime_changes({}, []), "halftime should allow continuing without changes")
	simulation.advance()
	_expect(simulation.get_state_name() == "Second Half", "match should continue into Second Half after halftime without changes")
	_expect((simulation.get_second_half_plan().get("substitutions", []) as Array[Dictionary]).is_empty(), "no-change halftime should preserve an empty substitution plan")


func _build_simulation_at_halftime() -> MatchSimulation:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.apply_snapshot({
		"schedule_available": true,
		"scheduled_match_position": 5,
		"current_timeline_position": 5,
		"match_center_available": true,
	})
	var simulation: MatchSimulation = MatchSimulationScript.new()
	_expect(simulation.start_formal_match({"match_id": "halftime-story-005"}, time_manager), "formal match should start for halftime adjustment test")
	for _step: int in range(4):
		simulation.advance()
	_expect(simulation.get_state_name() == "Halftime", "simulation should reach Halftime before halftime adjustment assertions")
	return simulation


func _build_substitution(out_player_id: int, in_player_id: int) -> Dictionary[String, Variant]:
	return {
		"out_player_id": out_player_id,
		"in_player_id": in_player_id,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
