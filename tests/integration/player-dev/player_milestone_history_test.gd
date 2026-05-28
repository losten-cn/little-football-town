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
	test_player_milestone_history_training_crosses_attribute_and_session_threshold_emits_distinct_milestones()
	test_player_milestone_history_legal_training_records_history_and_recent_growth_summary()
	test_player_milestone_history_failed_training_does_not_record_history()
	test_player_milestone_history_time_season_ended_advances_age_once_per_season()
	if _failures.is_empty():
		print("PLAYER_MILESTONE_HISTORY_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("PLAYER_MILESTONE_HISTORY_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_player_milestone_history_training_crosses_attribute_and_session_threshold_emits_distinct_milestones() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var event_bus: Node = harness["event_bus"]
	var player: Player = harness["player"]
	var observed_events: Array[Dictionary] = []
	player.attributes.spd.current = 39
	player.attributes.spd.potential = 90
	player.total_training_sessions = 9
	player.milestones.clear()
	event_bus.subscribe("player_milestone_reached", _capture_milestone_event.bind(observed_events))

	# Act
	var result: Dictionary[String, Variant] = player_development.train(player.id, _build_training_project(4.0), economy_manager, time_manager)

	# Assert
	_expect(result.get("success", false) as bool, "training that crosses a milestone should succeed")
	_expect(observed_events.size() == 2, "one training should emit attribute and training-session milestones when both thresholds are crossed")
	var attribute_event: Dictionary[String, Variant] = _find_milestone_event(observed_events, "attribute")
	var training_event: Dictionary[String, Variant] = _find_milestone_event(observed_events, "training_sessions")
	_expect(String(attribute_event.get("milestone_key", "")) == "SPD_40", "attribute milestone should identify the crossed 10-multiple")
	_expect(int(attribute_event.get("milestone_value", 0)) == 40, "attribute milestone should report the crossed attribute value")
	_expect(String(training_event.get("milestone_key", "")) == "TRAINING_10", "training milestone should identify the crossed session threshold")
	_expect(int(training_event.get("milestone_value", 0)) == 10, "training milestone should report the crossed session threshold")
	_expect(player.milestones.count("SPD_40") == 1, "attribute milestone should not be duplicated in player state")
	_expect(player.milestones.count("TRAINING_10") == 1, "training-session milestone should not be duplicated in player state")


func test_player_milestone_history_legal_training_records_history_and_recent_growth_summary() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var player: Player = harness["player"]
	player.training_history.clear()
	player.total_training_sessions = 0
	var project_a: Dictionary[String, Variant] = _build_training_project(2.6, "growth-a")
	var project_b: Dictionary[String, Variant] = _build_training_project(2.3, "growth-b")
	var project_c: Dictionary[String, Variant] = _build_training_project(2.0, "growth-c")

	# Act
	var result_a: Dictionary[String, Variant] = player_development.train(player.id, project_a, economy_manager, time_manager)
	var result_b: Dictionary[String, Variant] = player_development.train(player.id, project_b, economy_manager, time_manager)
	var result_c: Dictionary[String, Variant] = player_development.train(player.id, project_c, economy_manager, time_manager)
	var summary: Dictionary[String, Variant] = player_development.get_recent_growth_summary(player.id, 5)

	# Assert
	_expect(result_a.get("success", false) as bool, "first legal training should succeed")
	_expect(result_b.get("success", false) as bool, "second legal training should succeed")
	_expect(result_c.get("success", false) as bool, "third legal training should succeed")
	_expect(player.training_history.size() == 3, "every legal training should append one history entry")
	var summary_entries: Array = summary.get("entries", [])
	_expect(summary.get("success", false) as bool, "recent growth summary should succeed for an existing player")
	_expect(summary_entries.size() == 3, "summary should return all available history when the requested limit exceeds stored entries")
	_expect(String(_to_typed_dictionary(summary_entries[0]).get("project_id", "")) == "growth-a", "summary should preserve training order")
	_expect(String(_to_typed_dictionary(summary_entries[2]).get("project_id", "")) == "growth-c", "summary should preserve the most recent entry at the end")
	_expect(float(summary.get("total_applied_gain", 0.0)) > 0.0, "summary should accumulate applied gain from recent history")


func test_player_milestone_history_failed_training_does_not_record_history() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness()
	var player_development: PlayerDevelopment = harness["player_development"]
	var economy_manager: EconomyManager = harness["economy_manager"]
	var time_manager: Node = harness["time_manager"]
	var player: Player = harness["player"]
	player.training_history.clear()
	player.total_training_sessions = 0
	player_development.set_training_failure_stage_for_testing("emit")

	# Act
	var result: Dictionary[String, Variant] = player_development.train(player.id, _build_training_project(2.8, "failed-growth"), economy_manager, time_manager)

	# Assert
	_expect(not (result.get("success", true) as bool), "forced emit failure should fail training")
	_expect(player.training_history.is_empty(), "failed training should not persist training history")
	_expect(player.total_training_sessions == 0, "failed training should not persist the session counter")
	_expect(player.milestones.is_empty(), "failed training should not persist milestone state")


func test_player_milestone_history_time_season_ended_advances_age_once_per_season() -> void:
	# Arrange
	var harness: Dictionary[String, Variant] = _build_training_harness(2)
	var player_development: PlayerDevelopment = harness["player_development"]
	var event_bus: Node = harness["event_bus"]
	var roster: PlayerRoster = harness["roster"]
	var player_a: Player = harness["player"]
	var player_b: Player = _build_player("Season Teammate")
	player_b.id = 2
	player_b.age = 22
	roster.players.append(player_b)
	player_development._ready()
	var age_a_before: int = player_a.age
	var age_b_before: int = player_b.age

	# Act
	event_bus.emit("time_season_ended", {"season_number": 3})
	event_bus.emit("time_season_ended", {"season_number": 3})
	event_bus.emit("time_season_ended", {"season_number": 4})

	# Assert
	_expect(player_a.age == age_a_before + 2, "player age should increase once per distinct season")
	_expect(player_b.age == age_b_before + 2, "all roster players should age once per distinct season")
	_expect(player_a.last_age_advanced_season == 4, "player should track the last advanced season for save/load idempotence")
	_expect(player_b.last_age_advanced_season == 4, "every player should track the last advanced season")


func _build_training_project(raw_growth_input: float, project_id: String = "milestone-history-training") -> Dictionary[String, Variant]:
	return {
		"project_id": project_id,
		"primary_attribute": "SPD",
		"raw_growth_input": raw_growth_input,
		"focus_match_multiplier": 1.0,
		"facility_training_multiplier": 1.0,
		"funds_cost": 20,
		"action_points_cost": 1,
		"time_cost": 1.0,
	}


func _build_training_harness(player_count: int = 1) -> Dictionary[String, Variant]:
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.action_points_floor = 0
	economy_config.research_points_floor = 0
	var economy_manager: EconomyManager = EconomyManagerScript.new()
	economy_manager.set_economy_config_for_testing(economy_config)
	economy_manager.deserialize({
		"funds": 200.0,
		"action_points": 6.0,
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
			"current_phase_time_budget": 8,
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
	balance_config.player_training_session_milestones = [10, 25, 50]
	balance_config.recent_growth_summary_limit = 5
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	player_development.set_balance_config_for_testing(balance_config)
	player_development.set_event_bus_for_testing(event_bus)
	var roster: PlayerRoster = PlayerRosterScript.new()
	var player: Player = _build_player("Milestone Prospect")
	roster.add_player(player)
	player_development.set_roster_for_testing(roster)
	return {
		"player_development": player_development,
		"economy_manager": economy_manager,
		"time_manager": time_manager,
		"event_bus": event_bus,
		"roster": roster,
		"player": player,
	}


func _build_player(player_name: String) -> Player:
	var player: Player = PlayerScript.new()
	player.id = 1
	player.name = player_name
	player.position = "MF"
	player.tier = "明星"
	player.age = 20
	player.training_efficiency = 1.1
	player.condition_multiplier = 1.0
	player.morale_multiplier = 1.0
	player.attributes.spd.current = 36
	player.attributes.spd.potential = 80
	player.attributes.tec.current = 38
	player.attributes.tec.potential = 82
	return player


func _capture_milestone_event(_event_name: String, payload: Dictionary, observed_events: Array[Dictionary]) -> void:
	observed_events.append(_to_typed_dictionary(payload))


func _find_milestone_event(events: Array[Dictionary], milestone_type: String) -> Dictionary[String, Variant]:
	for event: Dictionary in events:
		var typed_event: Dictionary[String, Variant] = _to_typed_dictionary(event)
		if String(typed_event.get("milestone_type", "")) == milestone_type:
			return typed_event
	return {}


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
