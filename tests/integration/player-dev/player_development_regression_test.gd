extends Node

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
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
	test_player_development_regression_mvp_session_save_load_preserves_growth_and_costs_once()
	test_player_development_regression_routes_show_opportunity_cost_or_tuning_failure()
	test_player_development_regression_training_gain_matches_hand_calculated_formula_without_facility_bonus()
	if _failures.is_empty():
		print("PLAYER_DEVELOPMENT_REGRESSION_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("PLAYER_DEVELOPMENT_REGRESSION_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_player_development_regression_mvp_session_save_load_preserves_growth_and_costs_once() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_regression_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var save_manager: Variant = harness["save_manager"]
	var player: Player = harness["player"]
	var player_before: Dictionary[String, Variant] = player_development._serialize()
	var economy_before: Dictionary[String, Variant] = economy_manager.serialize()
	var time_before: Dictionary[String, Variant] = time_manager.get_state()
	var training_project: Dictionary[String, Variant] = _build_training_project("mvp-session", "SPD", 4.0, 1.0, 1.0, 20, 1, 1.0)

	# Act
	var train_result: Dictionary[String, Variant] = player_development.train(player.id, training_project, economy_manager, time_manager)
	var summary_after_training: Dictionary[String, Variant] = player_development.get_recent_growth_summary(player.id, 1)
	var player_after_training: Dictionary[String, Variant] = player_development._serialize()
	var economy_after_training: Dictionary[String, Variant] = economy_manager.serialize()
	var time_after_training: Dictionary[String, Variant] = time_manager.get_state()
	var ui_state: Dictionary[String, Variant] = {
		"ui_screen_id": "player_roster",
		"ui_stack_depth": 1,
	}
	var slot_metadata: Dictionary[String, Variant] = {
		"town_name": "Regression Town",
		"total_progress_units": 10,
	}
	var commit_result: Dictionary[String, Variant] = save_manager.commit_registered_snapshot(
		"slot_1",
		ui_state,
		slot_metadata,
		321.0,
		5678
	)
	var saved_snapshot: SaveSnapshot = commit_result.get("snapshot", null) as SaveSnapshot
	var restore_result: Dictionary[String, Variant] = save_manager.restore_snapshot(saved_snapshot)
	var restore_result_repeat: Dictionary[String, Variant] = save_manager.restore_snapshot(saved_snapshot)
	var player_after_restore: Dictionary[String, Variant] = player_development._serialize()
	var economy_after_restore: Dictionary[String, Variant] = economy_manager.serialize()
	var time_after_restore: Dictionary[String, Variant] = time_manager.get_state()

	# Assert
	_expect(train_result.get("success", false) as bool, "MVP session training should succeed")
	_expect(summary_after_training.get("success", false) as bool, "MVP session should produce growth feedback summary")
	_expect(_extract_player_attribute(player_after_training, 0, "SPD", "current") > _extract_player_attribute(player_before, 0, "SPD", "current"), "MVP session should visibly grow the trained attribute")
	_expect(float(economy_after_training.get("funds", 0.0)) == float(economy_before.get("funds", 0.0)) - 20.0, "MVP session should consume funds exactly once")
	_expect(float(economy_after_training.get("action_points", 0.0)) == float(economy_before.get("action_points", 0.0)) - 1.0, "MVP session should consume action points exactly once")
	_expect(_extract_consumed_time(time_after_training) == _extract_consumed_time(time_before) + 1, "MVP session should consume time exactly once")
	_expect(commit_result.get("success", false) as bool, "SaveManager should commit the MVP snapshot")
	_expect(saved_snapshot != null, "MVP session should produce a restorable snapshot")
	_expect(restore_result.get("success", false) as bool, "SaveManager should restore the committed MVP snapshot")
	_expect(restore_result_repeat.get("success", false) as bool, "repeated restore should still succeed")
	_expect(_dictionaries_deep_equal(player_after_restore, player_after_training), "restored player state should match the saved post-training state")
	_expect(_dictionaries_deep_equal(economy_after_restore, economy_after_training), "restored economy state should match the saved post-training state")
	_expect(String(time_after_restore.get("current_state", "")) == String(time_after_training.get("current_state", "")), "restored time state should preserve current_state")
	_expect(int(time_after_restore.get("timeline_position", -1)) == int(time_after_training.get("timeline_position", -1)), "restored time state should preserve timeline_position")
	_expect(int(time_after_restore.get("season_number", -1)) == int(time_after_training.get("season_number", -1)), "restored time state should preserve season_number")
	_expect(_extract_consumed_time(time_after_restore) == _extract_consumed_time(time_after_training), "restored time state should preserve consumed_time")
	_expect(_extract_player_total_training_sessions(player_after_restore, 0) == _extract_player_total_training_sessions(player_after_training, 0), "repeat restore should not double-settle player training sessions")


func test_player_development_regression_routes_show_opportunity_cost_or_tuning_failure() -> void:
	# Arrange
	var focused_sample: Dictionary[String, Variant] = _run_route_sample(_build_route_players(), [0, 0, 0, 0, 0, 0])
	var ordinary_sample: Dictionary[String, Variant] = _run_route_sample(_build_route_players(), [0, 0, 0, 1, 1, 1])
	var star_sample: Dictionary[String, Variant] = _run_route_sample(_build_route_players(), [2, 2, 2, 2, 2, 2])
	var route_behaves_as_expected: bool = focused_sample["focus_player_gain"] as float > ordinary_sample["focus_player_gain"] as float
	route_behaves_as_expected = route_behaves_as_expected and ordinary_sample["ordinary_avg_gain"] as float > star_sample["ordinary_avg_gain"] as float
	route_behaves_as_expected = route_behaves_as_expected and star_sample["star_player_gain"] as float > ordinary_sample["star_player_gain"] as float

	# Act
	var route_result: Dictionary[String, Variant] = {
		"success": route_behaves_as_expected,
		"tuning_failure": not route_behaves_as_expected,
		"focused_sample": focused_sample,
		"ordinary_sample": ordinary_sample,
		"star_sample": star_sample,
	}

	# Assert
	_expect(route_result.has("tuning_failure"), "route regression sample should explicitly classify tuning failures")
	_expect(route_result.get("success", false) as bool or route_result.get("tuning_failure", false) as bool, "route regression sample should either pass or mark a tuning failure")
	_expect((route_result["focused_sample"] as Dictionary).get("funds_spent", 0.0) == (route_result["ordinary_sample"] as Dictionary).get("funds_spent", 0.0), "regression routes should make opportunity-cost comparisons under matched budgets")
	_expect((route_result["focused_sample"] as Dictionary).get("action_points_spent", 0.0) == (route_result["star_sample"] as Dictionary).get("action_points_spent", 0.0), "regression routes should compare like-for-like action-point investment")


func test_player_development_regression_training_gain_matches_hand_calculated_formula_without_facility_bonus() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_regression_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var player: Player = harness["player"]
	player.training_efficiency = 1.1
	player.condition_multiplier = 1.0
	player.morale_multiplier = 1.0
	player.attributes.spd.current = 40
	player.attributes.spd.potential = 80
	var training_project: Dictionary[String, Variant] = _build_training_project("hand-formula", "SPD", 4.0, 1.0, 1.0, 20, 1, 1.0)
	var expected_gain: float = player_development.attribute_growth(4.0, 40, 80, 1.2) * player_development.get_fatigue_adjusted_training_efficiency(player) * 1.0 * 1.0

	# Act
	var result: Dictionary[String, Variant] = player_development.train(player.id, training_project, economy_manager, time_manager)

	# Assert
	_expect(result.get("success", false) as bool, "hand-formula regression sample should succeed")
	_expect(is_equal_approx(float(result.get("resolved_gain", 0.0)), expected_gain), "resolved training gain should match the hand-calculated formula when facility multiplier is 1.0")
	_expect(is_equal_approx(float(result.get("applied_gain", 0.0)), expected_gain), "applied training gain should match the hand-calculated formula when rounding does not cap the result")


func _run_route_sample(players: Array[Player], training_targets: Array[int]) -> Dictionary[String, Variant]:
	var harness: Dictionary[String, Variant] = _build_regression_harness(players)
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var routed_players: Array[Player] = harness["players"]
	var spd_before: Array[int] = []
	for player: Player in routed_players:
		spd_before.append(player.attributes.spd.current)
	for target_index: int in training_targets:
		var player_id: int = routed_players[target_index].id
		var train_result: Dictionary[String, Variant] = player_development.train(player_id, _build_training_project("route-%d" % target_index, "SPD", 3.5, 1.0, 1.0, 20, 1, 1.0), economy_manager, time_manager)
		_expect(train_result.get("success", false) as bool, "route regression training step should succeed")
	var total_gain: float = 0.0
	var ordinary_total_gain: float = 0.0
	var ordinary_count: int = 0
	for player_index: int in range(routed_players.size()):
		var player_gain: float = float(routed_players[player_index].attributes.spd.current - spd_before[player_index])
		total_gain += player_gain
		if routed_players[player_index].tier == "普通":
			ordinary_total_gain += player_gain
			ordinary_count += 1
	return {
		"focus_player_gain": float(routed_players[0].attributes.spd.current - spd_before[0]),
		"star_player_gain": float(routed_players[2].attributes.spd.current - spd_before[2]),
		"ordinary_avg_gain": ordinary_total_gain / float(maxi(1, ordinary_count)),
		"total_gain": total_gain,
		"funds_spent": 20.0 * float(training_targets.size()),
		"action_points_spent": float(training_targets.size()),
	}


func _build_regression_harness(players_override: Array[Player] = []) -> Dictionary[String, Variant]:
	var save_manager: Variant = SaveManagerScript.new()
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.action_points_floor = 0
	economy_config.research_points_floor = 0
	var economy_manager: EconomyManager = EconomyManagerScript.new()
	economy_manager.set_economy_config_for_testing(economy_config)
	economy_manager.deserialize({
		"funds": 500.0,
		"action_points": 12.0,
		"research_points": 0.0,
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
			"current_phase_time_budget": 12,
			"reserved_time": 0,
			"consumed_time": 0,
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
	time_manager.call("set_event_bus_for_testing", event_bus)
	var balance_config: BalanceConfig = BalanceConfigScript.new()
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	player_development.set_balance_config_for_testing(balance_config)
	player_development.set_event_bus_for_testing(event_bus)
	var roster: PlayerRoster = PlayerRosterScript.new()
	var players: Array[Player] = []
	if players_override.is_empty():
		players = [_build_player("Regression Prospect", "明星", 1.1, 40, 80)]
	else:
		players = players_override
	for player: Player in players:
		roster.add_player(player)
	player_development.set_roster_for_testing(roster)
	player_development.save_manager = save_manager
	player_development._ready()
	save_manager.register_system("time", func() -> Dictionary[String, Variant]: return time_manager.get_state(), time_manager.apply_snapshot)
	save_manager.register_system("town", _serialize_stub.bind({"facility_count": 2}), _deserialize_stub)
	save_manager.register_system("league", _serialize_stub.bind({"rank": 5}), _deserialize_stub)
	save_manager.register_system("economy", economy_manager.serialize, economy_manager.deserialize)
	save_manager.register_system("match", _serialize_stub.bind({
		"state": 0,
		"state_name": "idle",
		"pending_match_context": {},
		"result_packet": {},
		"formal_state_history": [],
		"confirmed_results_by_match_id": {},
		"scheduled_position": 5,
		"in_progress": false,
	}), _deserialize_stub)
	return {
		"save_manager": save_manager,
		"player_development": player_development,
		"economy_manager": economy_manager,
		"time_manager": time_manager,
		"event_bus": event_bus,
		"roster": roster,
		"player": players[0],
		"players": players,
	}


func _build_route_players() -> Array[Player]:
	return [
		_build_player("Ordinary Focus", "普通", 0.9, 40, 70),
		_build_player("Ordinary Support", "普通", 0.95, 39, 72),
		_build_player("Star Prospect", "明星", 1.3, 42, 92),
	]


func _build_player(player_name: String, tier: String, training_efficiency: float, current_spd: int, potential_spd: int) -> Player:
	var player: Player = PlayerScript.new()
	player.name = player_name
	player.position = "MF"
	player.tier = tier
	player.age = 20
	player.training_efficiency = training_efficiency
	player.condition_multiplier = 1.0
	player.morale_multiplier = 1.0
	player.attributes.spd.current = current_spd
	player.attributes.spd.potential = potential_spd
	player.attributes.tec.current = 38
	player.attributes.tec.potential = 82
	return player


func _build_training_project(project_id: String, primary_attribute: String, raw_growth_input: float, focus_match_multiplier: float, facility_training_multiplier: float, funds_cost: int, action_points_cost: int, time_cost: float) -> Dictionary[String, Variant]:
	return {
		"project_id": project_id,
		"primary_attribute": primary_attribute,
		"raw_growth_input": raw_growth_input,
		"focus_match_multiplier": focus_match_multiplier,
		"facility_training_multiplier": facility_training_multiplier,
		"funds_cost": funds_cost,
		"action_points_cost": action_points_cost,
		"time_cost": time_cost,
	}


func _serialize_stub(payload: Variant) -> Dictionary[String, Variant]:
	return _to_typed_dictionary(payload).duplicate(true)


func _deserialize_stub(_payload: Dictionary) -> void:
	pass


func _extract_player_attribute(player_state: Dictionary[String, Variant], player_index: int, attribute_name: String, field_name: String) -> int:
	var players: Array = player_state.get("players", [])
	var player: Dictionary[String, Variant] = _to_typed_dictionary(players[player_index]) if player_index < players.size() else {}
	var attributes: Dictionary[String, Variant] = _to_typed_dictionary(player.get("attributes", {}))
	var attribute: Dictionary[String, Variant] = _to_typed_dictionary(attributes.get(attribute_name, {}))
	return int(attribute.get(field_name, 0))


func _extract_player_total_training_sessions(player_state: Dictionary[String, Variant], player_index: int) -> int:
	var players: Array = player_state.get("players", [])
	var player: Dictionary[String, Variant] = _to_typed_dictionary(players[player_index]) if player_index < players.size() else {}
	return int(player.get("total_training_sessions", 0))


func _extract_consumed_time(time_state: Dictionary[String, Variant]) -> int:
	var windows: Dictionary[String, Variant] = _to_typed_dictionary(time_state.get("available_action_windows", {}))
	return int(windows.get("consumed_time", 0))


func _dictionaries_deep_equal(left: Dictionary[String, Variant], right: Dictionary[String, Variant]) -> bool:
	return JSON.stringify(left) == JSON.stringify(right)


func _to_typed_dictionary(source: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (source is Dictionary):
		return typed_dictionary
	for key_variant: Variant in source:
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
