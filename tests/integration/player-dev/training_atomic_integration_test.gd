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
	test_training_atomic_flow_executes_validate_deduct_grow_apply_emit_once()
	test_training_costs_use_accredited_training_entry_point_only()
	test_failed_training_requests_do_not_partially_apply_resources_growth_history_or_events()
	test_post_deduct_failure_rolls_back_resources_growth_history_and_events()
	if _failures.is_empty():
		print("TRAINING_ATOMIC_INTEGRATION_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("TRAINING_ATOMIC_INTEGRATION_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_training_atomic_flow_executes_validate_deduct_grow_apply_emit_once() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var event_bus: Node = harness["event_bus"]
	var player: Player = harness["player"]
	var observed_events: Array[String] = []
	event_bus.subscribe("economy_balance_changed", _capture_event.bind(observed_events))
	event_bus.subscribe("time_advanced", _capture_event.bind(observed_events))
	event_bus.subscribe("player_training_completed", _capture_event.bind(observed_events))
	var training_project: Dictionary[String, Variant] = {
		"project_id": "spd_focus",
		"primary_attribute": "SPD",
		"raw_growth_input": 4.0,
		"focus_match_multiplier": 1.1,
		"facility_training_multiplier": 1.0,
		"funds_cost": 30,
		"action_points_cost": 1,
		"time_cost": 1.0,
	}
	var funds_before: float = economy_manager.get_funds()
	var action_points_before: float = economy_manager.get_action_points()
	var attribute_before: int = player.attributes.spd.current
	var history_before: int = player.training_history.size()

	# Act
	var result: Dictionary[String, Variant] = player_development.train(player.id, training_project, economy_manager, time_manager)

	# Assert
	_expect(result["success"] as bool, "valid training should succeed")
	_expect(String(result.get("stage", "")) == "emit", "successful training should finish at emit stage")
	_expect(result.get("stage_sequence", []) == ["validate", "deduct", "grow", "apply", "emit"], "successful training should report validate→deduct→grow→apply→emit once each")
	_expect(economy_manager.get_funds() == funds_before - 30.0, "funds should be deducted before completion")
	_expect(economy_manager.get_action_points() == action_points_before - 1.0, "action points should be deducted before completion")
	_expect(player.attributes.spd.current > attribute_before, "training should apply growth to the selected attribute")
	_expect(player.training_history.size() == history_before + 1, "successful training should append one history record")
	_expect(player.total_training_sessions == 1, "successful training should increment total training sessions")
	_expect(observed_events.size() == 3, "successful training should emit economy, time, and player events once each")
	_expect(observed_events.count("time_advanced") == 1, "successful training should emit time_advanced exactly once")
	_expect(observed_events[0] == "economy_balance_changed", "economy mutation should emit first")
	_expect(observed_events[1] == "time_advanced", "time advancement should emit after deduction")
	_expect(observed_events[2] == "player_training_completed", "player completion should emit after growth is applied")


func test_training_costs_use_accredited_training_entry_point_only() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var player: Player = harness["player"]
	var training_project: Dictionary[String, Variant] = {
		"project_id": "tec_focus",
		"primary_attribute": "TEC",
		"raw_growth_input": 3.0,
		"focus_match_multiplier": 1.0,
		"facility_training_multiplier": 1.0,
		"funds_cost": 12,
		"action_points_cost": 0,
		"time_cost": 1.0,
	}

	# Act
	var result: Dictionary[String, Variant] = player_development.train(player.id, training_project, economy_manager, time_manager)
	var transaction_log: Array[Transaction] = economy_manager.get_transaction_log()
	var committed_transaction: Transaction = transaction_log[0] if not transaction_log.is_empty() else null

	# Assert
	_expect(result["success"] as bool, "training through the official entry point should succeed")
	_expect(transaction_log.size() == 1, "training should commit exactly one economy transaction")
	_expect(committed_transaction != null, "training should create a committed transaction entry")
	_expect(String(committed_transaction.reason) == "training_cost", "training should deduct costs only through accredit_training_cost")
	_expect(String(committed_transaction.source_system) == "player", "training cost transaction should be attributed to the player system")
	_expect(int(committed_transaction.metadata.get("player_id", 0)) == player.id, "training cost transaction should carry the trained player id")


func test_failed_training_requests_do_not_partially_apply_resources_growth_history_or_events() -> void:
	# Arrange
	var insufficient_funds_harness: Dictionary[String, Variant] = _build_training_harness(20.0, 2.0, 0.0, 2, 0)
	var insufficient_ap_harness: Dictionary[String, Variant] = _build_training_harness(200.0, 1.0, 0.0, 2, 0)
	var insufficient_time_harness: Dictionary[String, Variant] = _build_training_harness(200.0, 2.0, 0.0, 0, 0)
	var insufficient_funds_project: Dictionary[String, Variant] = {
		"project_id": "funds_blocked",
		"primary_attribute": "SPD",
		"raw_growth_input": 4.0,
		"focus_match_multiplier": 1.0,
		"facility_training_multiplier": 1.0,
		"funds_cost": 30,
		"action_points_cost": 1,
		"time_cost": 1.0,
	}
	var insufficient_ap_project: Dictionary[String, Variant] = {
		"project_id": "ap_blocked",
		"primary_attribute": "SPD",
		"raw_growth_input": 4.0,
		"focus_match_multiplier": 1.0,
		"facility_training_multiplier": 1.0,
		"funds_cost": 10,
		"action_points_cost": 2,
		"time_cost": 1.0,
	}
	var insufficient_time_project: Dictionary[String, Variant] = {
		"project_id": "time_blocked",
		"primary_attribute": "SPD",
		"raw_growth_input": 4.0,
		"focus_match_multiplier": 1.0,
		"facility_training_multiplier": 1.0,
		"funds_cost": 10,
		"action_points_cost": 1,
		"time_cost": 1.0,
	}

	# Act
	var insufficient_funds_result: Dictionary[String, Variant] = _run_failed_training_probe(insufficient_funds_harness, insufficient_funds_project)
	var insufficient_ap_result: Dictionary[String, Variant] = _run_failed_training_probe(insufficient_ap_harness, insufficient_ap_project)
	var insufficient_time_result: Dictionary[String, Variant] = _run_failed_training_probe(insufficient_time_harness, insufficient_time_project)

	# Assert
	_expect(not (insufficient_funds_result["result"].get("success", false) as bool), "insufficient funds training should fail")
	_expect(String(insufficient_funds_result["result"].get("stage", "")) == "deduct", "economy rejection should fail during deduct stage")
	_expect(is_equal_approx(insufficient_funds_result["funds_after"], insufficient_funds_result["funds_before"]), "failed funds check should not mutate funds")
	_expect(is_equal_approx(insufficient_funds_result["ap_after"], insufficient_funds_result["ap_before"]), "failed funds check should not mutate action points")
	_expect(int(insufficient_funds_result["attribute_after"]) == int(insufficient_funds_result["attribute_before"]), "failed funds check should not apply growth")
	_expect(int(insufficient_funds_result["history_after"]) == int(insufficient_funds_result["history_before"]), "failed funds check should not append history")
	_expect(int(insufficient_funds_result["event_count"]) == 0, "failed funds check should not emit events")
	_expect(int(insufficient_funds_result["transaction_count"]) == 0, "failed funds check should not commit transactions")
	_expect(int(insufficient_funds_result["consumed_time_after"]) == int(insufficient_funds_result["consumed_time_before"]), "failed funds check should not consume time")

	_expect(not (insufficient_ap_result["result"].get("success", false) as bool), "insufficient AP training should fail")
	_expect(String(insufficient_ap_result["result"].get("stage", "")) == "deduct", "AP rejection should fail during deduct stage")
	_expect(is_equal_approx(insufficient_ap_result["funds_after"], insufficient_ap_result["funds_before"]), "failed AP check should not mutate funds")
	_expect(is_equal_approx(insufficient_ap_result["ap_after"], insufficient_ap_result["ap_before"]), "failed AP check should not mutate action points")
	_expect(int(insufficient_ap_result["attribute_after"]) == int(insufficient_ap_result["attribute_before"]), "failed AP check should not apply growth")
	_expect(int(insufficient_ap_result["history_after"]) == int(insufficient_ap_result["history_before"]), "failed AP check should not append history")
	_expect(int(insufficient_ap_result["event_count"]) == 0, "failed AP check should not emit events")
	_expect(int(insufficient_ap_result["transaction_count"]) == 0, "failed AP check should not commit transactions")
	_expect(int(insufficient_ap_result["consumed_time_after"]) == int(insufficient_ap_result["consumed_time_before"]), "failed AP check should not consume time")

	_expect(not (insufficient_time_result["result"].get("success", false) as bool), "insufficient time training should fail")
	_expect(String(insufficient_time_result["result"].get("stage", "")) == "validate", "time-window rejection should fail during validate stage")
	_expect(is_equal_approx(insufficient_time_result["funds_after"], insufficient_time_result["funds_before"]), "failed time check should not mutate funds")
	_expect(is_equal_approx(insufficient_time_result["ap_after"], insufficient_time_result["ap_before"]), "failed time check should not mutate action points")
	_expect(int(insufficient_time_result["attribute_after"]) == int(insufficient_time_result["attribute_before"]), "failed time check should not apply growth")
	_expect(int(insufficient_time_result["history_after"]) == int(insufficient_time_result["history_before"]), "failed time check should not append history")
	_expect(int(insufficient_time_result["event_count"]) == 0, "failed time check should not emit events")
	_expect(int(insufficient_time_result["transaction_count"]) == 0, "failed time check should not commit transactions")
	_expect(int(insufficient_time_result["consumed_time_after"]) == int(insufficient_time_result["consumed_time_before"]), "failed time check should not consume time")


func test_post_deduct_failure_rolls_back_resources_growth_history_and_events() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var event_bus: Node = harness["event_bus"]
	var player: Player = harness["player"]
	var observed_events: Array[String] = []
	event_bus.subscribe("economy_balance_changed", _capture_event.bind(observed_events))
	event_bus.subscribe("time_advanced", _capture_event.bind(observed_events))
	event_bus.subscribe("player_training_completed", _capture_event.bind(observed_events))
	player_development.set_training_failure_stage_for_testing("apply")
	var training_project: Dictionary[String, Variant] = {
		"project_id": "forced_rollback",
		"primary_attribute": "SPD",
		"raw_growth_input": 4.0,
		"focus_match_multiplier": 1.0,
		"facility_training_multiplier": 1.0,
		"funds_cost": 20,
		"action_points_cost": 1,
		"time_cost": 1.0,
	}
	var funds_before: float = economy_manager.get_funds()
	var action_points_before: float = economy_manager.get_action_points()
	var attribute_before: int = player.attributes.spd.current
	var history_before: int = player.training_history.size()
	var consumed_time_before: int = int(time_manager.get_state()["available_action_windows"]["consumed_time"])

	# Act
	var result: Dictionary[String, Variant] = player_development.train(player.id, training_project, economy_manager, time_manager)
	player_development.set_training_failure_stage_for_testing("")

	# Assert
	_expect(not (result.get("success", false) as bool), "forced post-deduct failure should fail")
	_expect(String(result.get("stage", "")) == "apply", "forced failure should report the injected post-deduct stage")
	_expect(is_equal_approx(economy_manager.get_funds(), funds_before), "post-deduct failure should roll back funds")
	_expect(is_equal_approx(economy_manager.get_action_points(), action_points_before), "post-deduct failure should roll back action points")
	_expect(player.attributes.spd.current == attribute_before, "post-deduct failure should roll back attribute growth")
	_expect(player.training_history.size() == history_before, "post-deduct failure should roll back history")
	_expect(player.total_training_sessions == 0, "post-deduct failure should roll back total training sessions")
	_expect(economy_manager.get_transaction_log().is_empty(), "post-deduct failure should roll back committed transactions")
	_expect(int(time_manager.get_state()["available_action_windows"]["consumed_time"]) == consumed_time_before, "post-deduct failure should roll back consumed time")
	_expect(observed_events.is_empty(), "post-deduct failure should not emit success-path events")


func _run_failed_training_probe(harness: Dictionary[String, Variant], training_project: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var event_bus: Node = harness["event_bus"]
	var player: Player = harness["player"]
	var observed_events: Array[String] = []
	event_bus.subscribe("economy_balance_changed", _capture_event.bind(observed_events))
	event_bus.subscribe("time_advanced", _capture_event.bind(observed_events))
	event_bus.subscribe("player_training_completed", _capture_event.bind(observed_events))
	var funds_before: float = economy_manager.get_funds()
	var action_points_before: float = economy_manager.get_action_points()
	var attribute_before: int = player.attributes.spd.current
	var history_before: int = player.training_history.size()
	var consumed_time_before: int = int(time_manager.get_state()["available_action_windows"]["consumed_time"])
	var result: Dictionary[String, Variant] = player_development.train(player.id, training_project, economy_manager, time_manager)
	var state_after: Dictionary[String, Variant] = time_manager.get_state()
	var windows_after: Dictionary[String, Variant] = state_after["available_action_windows"]
	return {
		"result": result,
		"funds_before": funds_before,
		"funds_after": economy_manager.get_funds(),
		"ap_before": action_points_before,
		"ap_after": economy_manager.get_action_points(),
		"attribute_before": attribute_before,
		"attribute_after": player.attributes.spd.current,
		"history_before": history_before,
		"history_after": player.training_history.size(),
		"event_count": observed_events.size(),
		"transaction_count": economy_manager.get_transaction_log().size(),
		"consumed_time_before": consumed_time_before,
		"consumed_time_after": int(windows_after["consumed_time"]),
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
	player.name = "Training Prospect"
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
