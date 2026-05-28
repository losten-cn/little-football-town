extends Node

const PlayerScript: Script = preload("res://src/core/player.gd")
const PlayerDevelopmentScript: Script = preload("res://src/core/player_development.gd")
const PlayerRosterScript: Script = preload("res://src/core/player_roster.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_player_state_boundary_match_condition_and_morale_updates_affect_next_training_settlement()
	test_player_state_boundary_no_match_state_changes_preserve_training_baseline()
	test_player_state_boundary_downstream_updates_cannot_modify_long_term_fields()
	test_player_state_boundary_conflicting_updates_are_rejected_or_marked_for_review()
	test_player_state_boundary_stale_updates_are_rejected_or_marked_for_review()
	test_player_state_boundary_identical_duplicate_updates_do_not_trigger_conflict()
	test_player_state_boundary_root_invalid_payload_does_not_apply_state()
	test_player_state_boundary_out_of_range_multiplier_is_rejected()
	if _failures.is_empty():
		print("PLAYER_STATE_BOUNDARY_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("PLAYER_STATE_BOUNDARY_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_player_state_boundary_match_condition_and_morale_updates_affect_next_training_settlement() -> void:
	# Arrange
	var baseline_harness: Dictionary[String, Variant] = _build_training_harness()
	var baseline_gain: float = _run_training_gain_probe(baseline_harness)
	var updated_harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = updated_harness["player_development"]
	var player: Player = updated_harness["player"]
	var apply_result: Dictionary[String, Variant] = player_development.apply_match_result_player_state({
		"match_id": "match-state-1",
		"condition_changes": [
			{"player_id": player.id, "old_condition": 1.0, "new_condition": 0.55},
		],
		"morale_changes": [
			{"player_id": player.id, "old_morale": 1.0, "new_morale": 0.60},
		],
	})

	# Act
	var updated_gain: float = _run_training_gain_probe(updated_harness)

	# Assert
	_expect(apply_result.get("success", false) as bool, "legal match-result state update should succeed")
	_expect(is_equal_approx(player.condition_multiplier, 0.55), "applied match condition should update authoritative player state")
	_expect(is_equal_approx(player.morale_multiplier, 0.60), "applied match morale should update authoritative player state")
	_expect(updated_gain < baseline_gain, "reduced condition and morale should reduce the next training settlement")


func test_player_state_boundary_no_match_state_changes_preserve_training_baseline() -> void:
	# Arrange
	var baseline_harness: Dictionary[String, Variant] = _build_training_harness()
	var baseline_gain: float = _run_training_gain_probe(baseline_harness)
	var unchanged_harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = unchanged_harness["player_development"]
	var apply_result: Dictionary[String, Variant] = player_development.apply_match_result_player_state({
		"match_id": "match-state-no-change",
		"condition_changes": [],
		"morale_changes": [],
	})

	# Act
	var unchanged_gain: float = _run_training_gain_probe(unchanged_harness)

	# Assert
	_expect(apply_result.get("success", false) as bool, "empty match-result state update should succeed")
	_expect(is_equal_approx(unchanged_gain, baseline_gain), "training should match baseline when no state changes are applied")


func test_player_state_boundary_downstream_updates_cannot_modify_long_term_fields() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var player: Player = harness["player"]
	var spd_before: int = player.attributes.spd.current
	var potential_before: int = player.attributes.spd.potential
	var efficiency_before: float = player.training_efficiency

	# Act
	var result: Dictionary[String, Variant] = player_development.apply_match_result_player_state({
		"match_id": "match-state-2",
		"condition_changes": [
			{
				"player_id": player.id,
				"old_condition": 1.0,
				"new_condition": 0.75,
				"training_efficiency": 1.5,
				"potential_cap": 99,
				"attributes": {"SPD": 99},
			},
		],
		"morale_changes": [],
	})

	# Assert
	_expect(not (result.get("success", true) as bool), "illegal long-term field mutation should be rejected")
	_expect(result.get("review_required", false) as bool, "illegal long-term field mutation should require review")
	_expect(is_equal_approx(player.condition_multiplier, 1.0), "rejected update should not mutate condition")
	_expect(player.attributes.spd.current == spd_before, "rejected update should not mutate attributes")
	_expect(player.attributes.spd.potential == potential_before, "rejected update should not mutate potential")
	_expect(is_equal_approx(player.training_efficiency, efficiency_before), "rejected update should not mutate training efficiency")


func test_player_state_boundary_conflicting_updates_are_rejected_or_marked_for_review() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var event_bus: Node = harness["event_bus"]
	var player: Player = harness["player"]
	var observed_events: Array[String] = []
	event_bus.subscribe("player_match_state_applied", _capture_event.bind(observed_events))
	event_bus.subscribe("player_state_update_flagged", _capture_event.bind(observed_events))

	# Act
	var result: Dictionary[String, Variant] = player_development.apply_match_result_player_state({
		"match_id": "match-state-3",
		"condition_changes": [
			{"player_id": player.id, "old_condition": 1.0, "new_condition": 0.70},
			{"player_id": player.id, "old_condition": 0.70, "new_condition": 0.65},
		],
		"morale_changes": [],
	})

	# Assert
	_expect(not (result.get("success", true) as bool), "conflicting duplicate updates should not succeed")
	_expect(result.get("review_required", false) as bool, "conflicting duplicate updates should require review")
	_expect(is_equal_approx(player.condition_multiplier, 1.0), "conflicting duplicate updates should not silently overwrite authoritative state")
	_expect(observed_events.has("player_state_update_flagged"), "conflicting duplicate updates should emit a flagged event")
	_expect(not observed_events.has("player_match_state_applied"), "conflicting duplicate updates should not emit a success event")


func test_player_state_boundary_stale_updates_are_rejected_or_marked_for_review() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var player: Player = harness["player"]

	# Act
	var result: Dictionary[String, Variant] = player_development.apply_match_result_player_state({
		"match_id": "match-state-stale",
		"condition_changes": [
			{"player_id": player.id, "old_condition": 0.88, "new_condition": 0.70},
		],
		"morale_changes": [
			{"player_id": player.id, "old_morale": 0.77, "new_morale": 0.90},
		],
	})

	# Assert
	_expect(not (result.get("success", true) as bool), "stale updates should not succeed")
	_expect(result.get("review_required", false) as bool, "stale updates should require review")
	_expect(is_equal_approx(player.condition_multiplier, 1.0), "stale condition update should not overwrite authoritative state")
	_expect(is_equal_approx(player.morale_multiplier, 1.0), "stale morale update should not overwrite authoritative state")


func test_player_state_boundary_identical_duplicate_updates_do_not_trigger_conflict() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var event_bus: Node = harness["event_bus"]
	var player: Player = harness["player"]
	var observed_events: Array[String] = []
	event_bus.subscribe("player_match_state_applied", _capture_event.bind(observed_events))
	event_bus.subscribe("player_state_update_flagged", _capture_event.bind(observed_events))

	# Act
	var result: Dictionary[String, Variant] = player_development.apply_match_result_player_state({
		"match_id": "match-state-duplicate",
		"condition_changes": [
			{"player_id": player.id, "old_condition": 1.0, "new_condition": 0.70},
			{"player_id": player.id, "old_condition": 1.0, "new_condition": 0.70},
		],
		"morale_changes": [
			{"player_id": player.id, "old_morale": 1.0, "new_morale": 0.85},
			{"player_id": player.id, "old_morale": 1.0, "new_morale": 0.85},
		],
	})

	# Assert
	_expect(result.get("success", false) as bool, "identical duplicate updates should be accepted")
	_expect(not (result.get("review_required", true) as bool), "identical duplicate updates should not require review")
	_expect(is_equal_approx(player.condition_multiplier, 0.70), "identical duplicate condition updates should apply once")
	_expect(is_equal_approx(player.morale_multiplier, 0.85), "identical duplicate morale updates should apply once")
	_expect(observed_events.has("player_match_state_applied"), "identical duplicate updates should emit success event")
	_expect(not observed_events.has("player_state_update_flagged"), "identical duplicate updates should not emit flagged event")


func test_player_state_boundary_root_invalid_payload_does_not_apply_state() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var event_bus: Node = harness["event_bus"]
	var player: Player = harness["player"]
	var observed_events: Array[String] = []
	event_bus.subscribe("player_match_state_applied", _capture_event.bind(observed_events))
	event_bus.subscribe("player_state_update_flagged", _capture_event.bind(observed_events))

	# Act
	var result: Dictionary[String, Variant] = player_development.apply_match_result_player_state({
		"match_id": "match-state-root-invalid",
		"illegal_root_key": true,
		"condition_changes": [
			{"player_id": player.id, "old_condition": 1.0, "new_condition": 0.70},
		],
		"morale_changes": [
			{"player_id": player.id, "old_morale": 1.0, "new_morale": 0.85},
		],
	})

	# Assert
	_expect(not (result.get("success", true) as bool), "root-invalid payload should not succeed")
	_expect(result.get("review_required", false) as bool, "root-invalid payload should require review")
	_expect(is_equal_approx(player.condition_multiplier, 1.0), "root-invalid payload should not apply condition changes")
	_expect(is_equal_approx(player.morale_multiplier, 1.0), "root-invalid payload should not apply morale changes")
	_expect(observed_events.has("player_state_update_flagged"), "root-invalid payload should emit flagged event")
	_expect(not observed_events.has("player_match_state_applied"), "root-invalid payload should not emit success event")


func test_player_state_boundary_out_of_range_multiplier_is_rejected() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var player: Player = harness["player"]

	# Act
	var result: Dictionary[String, Variant] = player_development.apply_match_result_player_state({
		"match_id": "match-state-out-of-range",
		"condition_changes": [
			{"player_id": player.id, "old_condition": 1.0, "new_condition": 1.4},
		],
		"morale_changes": [
			{"player_id": player.id, "old_morale": 1.0, "new_morale": -0.2},
		],
	})

	# Assert
	_expect(not (result.get("success", true) as bool), "out-of-range multipliers should not succeed")
	_expect(result.get("review_required", false) as bool, "out-of-range multipliers should require review")
	_expect(is_equal_approx(player.condition_multiplier, 1.0), "out-of-range condition should not overwrite authoritative state")
	_expect(is_equal_approx(player.morale_multiplier, 1.0), "out-of-range morale should not overwrite authoritative state")


func _run_training_gain_probe(harness: Dictionary[String, Variant]) -> float:
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var player: Player = harness["player"]
	var attribute_before: int = player.attributes.spd.current
	var result: Dictionary[String, Variant] = player_development.train(player.id, _build_training_project(), economy_manager, time_manager)
	_expect(result.get("success", false) as bool, "training probe should succeed")
	return float(player.attributes.spd.current - attribute_before)


func _build_training_project() -> Dictionary[String, Variant]:
	return {
		"project_id": "state-boundary-training",
		"primary_attribute": "SPD",
		"raw_growth_input": 4.0,
		"focus_match_multiplier": 1.0,
		"facility_training_multiplier": 1.0,
		"funds_cost": 20,
		"action_points_cost": 1,
		"time_cost": 1.0,
	}


func _build_training_harness(
	funds: float = 200.0,
	action_points: float = 3.0,
	research_points: float = 0.0,
	phase_budget: int = 4,
	consumed_time: int = 0,
) -> Dictionary[String, Variant]:
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.action_points_floor = 0
	economy_config.research_points_floor = 0
	var economy_manager: EconomyManager = EconomyManagerScript.new()
	economy_manager.set_economy_config_for_testing(economy_config)
	economy_manager.deserialize({
		"funds": funds,
		"action_points": action_points,
		"research_points": research_points,
		"next_tx_id": 1,
		"transactions": [],
	})
	var time_manager: Node = TimeManagerScript.new()
	time_manager.apply_snapshot({
		"current_state": "Planning",
		"timeline_position": 2,
		"season_number": 1,
		"current_stage": 1,
		"current_stage_progress": 0,
		"stage_progress_target": 3,
		"season_progress": {
			"completed_units": 2,
			"total_units": 10,
		},
		"available_action_windows": {
			"current_phase_time_budget": phase_budget,
			"reserved_time": 0,
			"consumed_time": consumed_time,
			"standard_window_size": 1,
		},
		"scheduled_match_position": 8,
		"next_key_node_position": 8,
		"schedule_available": true,
		"schedule_loading": false,
		"schedule_missing": false,
		"match_center_available": true,
	})
	var event_bus: Node = EventBusScript.new()
	economy_manager.set_event_bus_for_testing(event_bus)
	var balance_config: BalanceConfig = BalanceConfigScript.new()
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	player_development.set_balance_config_for_testing(balance_config)
	player_development.set_event_bus_for_testing(event_bus)
	var roster: PlayerRoster = PlayerRosterScript.new()
	var player: Player = _build_player()
	roster.add_player(player)
	player_development.set_roster_for_testing(roster)
	return {
		"player_development": player_development,
		"economy_manager": economy_manager,
		"time_manager": time_manager,
		"event_bus": event_bus,
		"player": player,
	}


func _build_player() -> Player:
	var player: Player = PlayerScript.new()
	player.id = 1
	player.name = "State Boundary Prospect"
	player.position = "MF"
	player.tier = "明星"
	player.training_efficiency = 1.1
	player.condition_multiplier = 1.0
	player.morale_multiplier = 1.0
	player.attributes.spd.current = 40
	player.attributes.spd.potential = 80
	player.attributes.tec.current = 38
	player.attributes.tec.potential = 82
	return player


func _capture_event(event_name: String, _payload: Dictionary, observed_events: Array[String]) -> void:
	observed_events.append(event_name)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
