# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Can a player complete one clear training-to-match-to-feedback loop in under 5 minutes without guidance?
# Date: 2026-05-30

extends Node

const VerticalSliceScenarioScript: Script = preload("res://prototypes/little-football-town-vertical-slice/vertical_slice_scenario.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const PlayerDevelopmentScript: Script = preload("res://src/core/player_development.gd")
const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")

signal state_changed
signal training_resolved
signal match_state_changed
signal match_finished

var _event_bus: Node
var _time_manager: Node
var _economy_manager: Node
var _player_development: Node
var _match_simulation: Node
var _roster: Resource
var _training_projects: Array = []
var _last_training_result: Dictionary[String, Variant] = {}
var _latest_match_result: Dictionary[String, Variant] = {}
var _recommended_setup: Dictionary[String, Variant] = {}
var _match_context: Dictionary[String, Variant] = {}
var _did_training_this_loop: bool = false
var _match_started: bool = false
var _match_result_confirmed: bool = false
var _last_state_summary: Dictionary[String, Variant] = {}


func _ready() -> void:
	_bootstrap_runtime()
	_emit_state_changed()


func get_state_summary() -> Dictionary[String, Variant]:
	var time_state: Dictionary[String, Variant] = _time_manager.get_state()
	var balance_snapshot: Dictionary[String, float] = _economy_manager.get_balance_snapshot()
	var roster_summary: Array = []
	for player_variant: Variant in _roster.players:
		roster_summary.append(_build_player_summary(player_variant))
	_last_state_summary = {
		"phase": String(time_state.get("current_phase", "Planning")),
		"date_display": String(time_state.get("current_date_display", "")),
		"next_match_display": String(time_state.get("match", {}).get("next_match_display", "")),
		"opponent_name": String(time_state.get("match", {}).get("opponent_name", "")),
		"available_action_windows": int(time_state.get("available_action_windows", {}).get("count", 0)),
		"funds": int(round(balance_snapshot.get("funds", 0.0))),
		"action_points": int(round(balance_snapshot.get("action_points", 0.0))),
		"research_points": int(round(balance_snapshot.get("research_points", 0.0))),
		"match_trigger_reached": bool(time_state.get("match", {}).get("trigger_reached", false)),
		"can_advance_to_match_day": not _did_training_this_loop,
		"can_open_match_center": bool(time_state.get("match", {}).get("trigger_reached", false)),
		"did_training_this_loop": _did_training_this_loop,
		"match_started": _match_started,
		"match_result_confirmed": _match_result_confirmed,
		"players": roster_summary,
		"training_projects": _to_dictionary_array(_training_projects),
		"last_training_result": _last_training_result.duplicate(true),
		"latest_match_result": _latest_match_result.duplicate(true),
	}
	return _last_state_summary.duplicate(true)


func get_team_view_model() -> Dictionary[String, Variant]:
	var state_summary: Dictionary[String, Variant] = get_state_summary()
	return {
		"players": (state_summary.get("players", []) as Array).duplicate(true),
		"training_projects": _to_dictionary_array(_training_projects),
		"last_training_result": _last_training_result.duplicate(true),
		"available_action_windows": state_summary.get("available_action_windows", 0),
		"funds": state_summary.get("funds", 0),
		"action_points": state_summary.get("action_points", 0),
	}


func get_match_view_model() -> Dictionary[String, Variant]:
	var state_summary: Dictionary[String, Variant] = get_state_summary()
	return {
		"phase": state_summary.get("phase", "Planning"),
		"opponent_name": state_summary.get("opponent_name", ""),
		"next_match_display": state_summary.get("next_match_display", ""),
		"match_started": _match_started,
		"match_result_confirmed": _match_result_confirmed,
		"recommended_setup": _recommended_setup.duplicate(true),
		"formal_state_history": _match_simulation.get_formal_state_history(),
		"match_state_name": _match_simulation.get_state_name(),
		"latest_match_result": _latest_match_result.duplicate(true),
	}


func run_training(player_id: int, project_id: String) -> Dictionary[String, Variant]:
	var training_project: Dictionary[String, Variant] = _find_training_project(project_id)
	if training_project.is_empty():
		return {"success": false, "error": "training_project_missing"}
	var result: Dictionary[String, Variant] = _player_development.train(player_id, training_project, _economy_manager, _time_manager)
	if not bool(result.get("success", false)):
		_last_training_result = result.duplicate(true)
		emit_signal("training_resolved", _last_training_result)
		emit_signal("state_changed")
		return result
	_did_training_this_loop = true
	var player: Variant = _roster.get_player(player_id)
	_last_training_result = {
		"success": true,
		"player_id": player_id,
		"player_name": player.name if player != null else "",
		"project_id": project_id,
		"project_label": String(training_project.get("label", project_id)),
		"primary_attribute": String(result.get("primary_attribute", "")),
		"applied_gain": float(result.get("applied_gain", 0.0)),
		"remaining_action_windows": _time_manager.get_available_action_windows(),
	}
	var timeline_result: Dictionary[String, Variant] = _advance_to_match_day_if_ready()
	_last_training_result["timeline_result"] = timeline_result.duplicate(true)
	emit_signal("training_resolved", _last_training_result.duplicate(true))
	_emit_state_changed()
	return _last_training_result.duplicate(true)


func open_match_center() -> Dictionary[String, Variant]:
	if not _time_manager.can_enter_formal_match():
		return {"success": false, "error": "match_not_available"}
	if not _match_started:
		_match_started = _match_simulation.start_formal_match(_match_context.duplicate(true), _time_manager)
	if not _match_started:
		return {"success": false, "error": "match_start_failed"}
	_emit_match_state_changed()
	_emit_state_changed()
	return {"success": true, "state": _match_simulation.get_state_name()}


func advance_match_step() -> Dictionary[String, Variant]:
	if not _match_started:
		return {"success": false, "error": "match_not_started"}
	_match_simulation.advance()
	var state_name: String = _match_simulation.get_state_name()
	if state_name == "Settlement":
		_finalize_match_loop()
	_emit_match_state_changed()
	_emit_state_changed()
	return {
		"success": true,
		"state": state_name,
		"formal_state_history": _match_simulation.get_formal_state_history(),
	}


func confirm_match_result_and_return_home() -> Dictionary[String, Variant]:
	if _latest_match_result.is_empty():
		return {"success": false, "error": "match_result_missing"}
	_match_result_confirmed = true
	if _time_manager.get_state().get("current_phase", "") == "Post-Match Settlement":
		_time_manager.resolve_post_match_settlement()
	_emit_state_changed()
	return {"success": true, "next_phase": _time_manager.get_state().get("current_phase", "Planning")}


func _bootstrap_runtime() -> void:
	_event_bus = EventBusScript.new()
	add_child(_event_bus)

	_time_manager = TimeManagerScript.new()
	_time_manager.set_event_bus_for_testing(_event_bus)
	add_child(_time_manager)

	_economy_manager = EconomyManagerScript.new()
	_economy_manager.set_event_bus_for_testing(_event_bus)
	_economy_manager.set_economy_config_for_testing(VerticalSliceScenarioScript.create_economy_config())
	add_child(_economy_manager)

	_player_development = PlayerDevelopmentScript.new()
	_player_development.set_event_bus_for_testing(_event_bus)
	_player_development.set_balance_config_for_testing(VerticalSliceScenarioScript.create_balance_config())
	add_child(_player_development)

	_match_simulation = MatchSimulationScript.new()
	_match_simulation.set_event_bus_for_testing(_event_bus)
	_match_simulation.set_balance_config_for_testing(VerticalSliceScenarioScript.create_balance_config())
	_match_simulation.set_match_config_for_testing(VerticalSliceScenarioScript.create_match_config())
	add_child(_match_simulation)

	_roster = VerticalSliceScenarioScript.create_roster()
	_training_projects = VerticalSliceScenarioScript.create_training_projects()
	_player_development.set_roster_for_testing(_roster)
	_time_manager.apply_snapshot(VerticalSliceScenarioScript.create_initial_time_snapshot())
	var economy_snapshot: Dictionary[String, Variant] = {
		"funds": 160.0,
		"action_points": 8.0,
		"research_points": 0.0,
		"next_tx_id": 1,
		"transactions": [],
	}
	_economy_manager.deserialize(economy_snapshot)
	_recommended_setup = _match_simulation.build_recommended_pre_match_setup(_roster.players)
	_match_context = VerticalSliceScenarioScript.create_match_context(_roster, _recommended_setup.get("lineup_slots", []))
	_match_simulation.bind_time_manager(_time_manager)
	_event_bus.subscribe("match_completed", Callable(self, "_on_match_completed"))


func _find_training_project(project_id: String) -> Dictionary[String, Variant]:
	for training_project_variant: Variant in _training_projects:
		var training_project: Dictionary[String, Variant] = _to_string_variant_dictionary(training_project_variant)
		if String(training_project.get("project_id", "")) == project_id:
			return training_project.duplicate(true)
	return _to_string_variant_dictionary({})


func _advance_to_match_day_if_ready() -> Dictionary[String, Variant]:
	if _time_manager.get_match_trigger_reached():
		return {"success": true, "already_at_match_day": true, "state": _time_manager.get_state().get("current_phase", "Planning")}
	_time_manager.advance_timeline(2)
	return {
		"success": true,
		"state": _time_manager.get_state().get("current_phase", "Planning"),
		"match_trigger_reached": _time_manager.get_match_trigger_reached(),
	}


func _finalize_match_loop() -> void:
	if _latest_match_result.is_empty():
		_latest_match_result = _match_simulation.get_result_packet()
		_latest_match_result = _to_string_variant_dictionary(_latest_match_result)
	var match_player_result: Dictionary[String, Variant] = _player_development.apply_match_result_player_state(_latest_match_result)
	var settlement_context: Dictionary[String, Variant] = VerticalSliceScenarioScript.create_post_match_settlement_context()
	var settlement_result: Dictionary[String, Variant] = _economy_manager.settle_post_match(_latest_match_result, settlement_context)
	var time_result: Dictionary[String, Variant] = _time_manager.enter_post_match_settlement()
	_latest_match_result["player_state_result"] = match_player_result
	_latest_match_result["economy_settlement_result"] = settlement_result
	_latest_match_result["time_transition_result"] = time_result
	if _latest_match_result.has("win_reasons"):
		_latest_match_result["summary_text"] = _build_match_summary_text(_latest_match_result)
		emit_signal("match_finished", _latest_match_result.duplicate(true))


func _build_player_summary(player: Variant) -> Dictionary[String, Variant]:
	return {
		"id": player.id,
		"name": player.name,
		"position": player.position,
		"tier": player.tier,
		"training_efficiency": snappedf(player.training_efficiency, 0.01),
		"condition_multiplier": snappedf(player.condition_multiplier, 0.01),
		"morale_multiplier": snappedf(player.morale_multiplier, 0.01),
		"spd": player.attributes.spd.current,
		"pwr": player.attributes.pwr.current,
		"tec": player.attributes.tec.current,
		"intelligence": player.attributes.intelligence.current,
		"sta": player.attributes.sta.current,
	}


func _build_match_summary_text(result_packet: Dictionary[String, Variant]) -> String:
	var score: Dictionary[String, Variant] = _to_string_variant_dictionary(result_packet.get("score", {}))
	var home_score: int = int(score.get("home", 0))
	var away_score: int = int(score.get("away", 0))
	var reasons: Array = result_packet.get("win_reasons", [])
	var reason_text: String = ""
	if not reasons.is_empty():
		reason_text = String(reasons[0])
	return "本场以 %d:%d 结束，关键原因：%s" % [home_score, away_score, reason_text]


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary


func _to_dictionary_array(value: Variant) -> Array[Dictionary]:
	var dictionaries: Array[Dictionary] = []
	if value is Array:
		for entry: Variant in value:
			if entry is Dictionary:
				dictionaries.append((entry as Dictionary).duplicate(true))
	return dictionaries


func _emit_state_changed() -> void:
	get_state_summary()
	emit_signal("state_changed")


func _emit_match_state_changed() -> void:
	emit_signal("match_state_changed")


func _on_match_completed(_event_name: String, payload: Dictionary) -> void:
	_latest_match_result = _to_string_variant_dictionary(payload)
