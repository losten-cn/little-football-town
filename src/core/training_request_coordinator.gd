class_name TrainingRequestCoordinator
extends Node
## Bridges UI training requests to the authoritative PlayerDevelopment operation.

const PlayerScript: Script = preload("res://src/core/player.gd")
const PlayerRosterScript: Script = preload("res://src/core/player_roster.gd")
const PlayerDevelopmentScript: Script = preload("res://src/core/player_development.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")

@export var starting_funds: float = 1200.0
@export var starting_action_points: float = 2.0

var _player_development: PlayerDevelopment = null
var _economy_manager: EconomyManager = null
var _training_catalog: Resource = null
var _event_bus_override: Node = null
var _time_manager_override: Node = null


func _ready() -> void:
	if _player_development == null or _economy_manager == null or _training_catalog == null:
		_bootstrap_runtime_systems()
	else:
		_get_event_bus().subscribe("player_training_completed", _on_player_training_completed)
	_get_event_bus().subscribe("screen_requested", _on_screen_requested)
	_get_event_bus().subscribe("training_requested", _on_training_requested)
	_publish_training_read_models()


func _exit_tree() -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus != null:
		event_bus.unsubscribe("screen_requested", _on_screen_requested)
		event_bus.unsubscribe("training_requested", _on_training_requested)
		event_bus.unsubscribe("player_training_completed", _on_player_training_completed)


## Overrides runtime dependencies for isolated integration tests.
func configure_for_testing(player_development: PlayerDevelopment, economy_manager: EconomyManager, training_catalog: Resource, event_bus: Node, time_manager: Node) -> void:
	_player_development = player_development
	_economy_manager = economy_manager
	_training_catalog = training_catalog
	_event_bus_override = event_bus
	_time_manager_override = time_manager
	if _player_development != null:
		_player_development.set_event_bus_for_testing(event_bus)
	if _economy_manager != null:
		_economy_manager.set_event_bus_for_testing(event_bus)


## Publishes authoritative roster/training read models for UI display.
func publish_training_read_models() -> void:
	_publish_training_read_models()


func _bootstrap_runtime_systems() -> void:
	var event_bus: Node = _get_event_bus()
	_player_development = PlayerDevelopmentScript.new() as PlayerDevelopment
	_player_development.name = "PlayerDevelopment"
	_player_development.save_manager = SaveManager
	_player_development.set_event_bus_for_testing(event_bus)
	if ConfigLoader.balance_config != null:
		_player_development.set_balance_config_for_testing(ConfigLoader.balance_config)
	var roster: PlayerRoster = PlayerRosterScript.new() as PlayerRoster
	roster.add_player(_build_runtime_player("Low", "DF", "normal", 45, 48, 42, 40, 55))
	roster.add_player(_build_runtime_player("High", "FW", "star", 68, 62, 77, 60, 65))
	_player_development.set_roster_for_testing(roster)
	add_child(_player_development)

	_economy_manager = EconomyManagerScript.new() as EconomyManager
	_economy_manager.name = "EconomyManager"
	_economy_manager.set_event_bus_for_testing(event_bus)
	if ConfigLoader.economy_config != null:
		_economy_manager.set_economy_config_for_testing(ConfigLoader.economy_config)
	_economy_manager.deserialize({
		"funds": starting_funds,
		"action_points": starting_action_points,
		"research_points": 0.0,
		"next_tx_id": 1,
		"transactions": [],
	})
	add_child(_economy_manager)

	_training_catalog = ConfigLoader.training_catalog_config
	event_bus.subscribe("player_training_completed", _on_player_training_completed)


func _on_screen_requested(_event_name: String, payload: Dictionary) -> void:
	var typed_payload: Dictionary[String, Variant] = _to_string_variant_dictionary(payload)
	var screen_id: String = String(typed_payload.get("screen_id", ""))
	if ["roster", "player_detail", "training"].has(screen_id):
		call_deferred("_publish_training_read_models")


func _on_training_requested(_event_name: String, payload: Dictionary) -> void:
	var typed_payload: Dictionary[String, Variant] = _to_string_variant_dictionary(payload)
	var player_id: int = int(typed_payload.get("player_id", 0))
	var training_id: String = String(typed_payload.get("training_id", typed_payload.get("project_id", ""))).strip_edges()
	var training_project: Dictionary[String, Variant] = _get_training_project(training_id)
	if player_id <= 0 or training_project.is_empty():
		_get_event_bus().emit("training_failed", {
			"player_id": player_id,
			"training_id": training_id,
			"reason": "training_request_invalid",
		})
		return
	var result: Dictionary[String, Variant] = _player_development.train(player_id, training_project, _economy_manager, _get_time_manager())
	if not bool(result.get("success", false)):
		_get_event_bus().emit("training_failed", {
			"player_id": player_id,
			"training_id": training_id,
			"reason": String(result.get("error", "training_failed")),
		})
		return


func _on_player_training_completed(_event_name: String, payload: Dictionary) -> void:
	var typed_payload: Dictionary[String, Variant] = _to_string_variant_dictionary(payload)
	var completion_payload: Dictionary[String, Variant] = typed_payload.duplicate(true)
	completion_payload["training_id"] = String(typed_payload.get("project_id", typed_payload.get("training_id", "")))
	completion_payload["summary"] = _training_summary(completion_payload)
	_get_event_bus().emit("training_completed", completion_payload)
	_get_event_bus().emit("player_action_completed", completion_payload)
	_publish_training_read_models()


func _publish_training_read_models() -> void:
	var event_bus: Node = _get_event_bus()
	if _player_development != null:
		event_bus.emit("roster_updated", {"players": _build_roster_view()})
	if _training_catalog != null and _training_catalog.has_method("get_training_options"):
		event_bus.emit("training_options_updated", {
			"training_available": true,
			"options": _training_catalog.call("get_training_options"),
		})
	if _economy_manager != null:
		var balances: Dictionary[String, float] = _economy_manager.get_balance_snapshot()
		event_bus.emit("system_state_changed", {
			"funds": int(balances.get("funds", 0.0)),
			"ap": int(balances.get("action_points", 0.0)),
			"team_overview": "训练系统已接入，球员成长可结算",
			"system_state_allows_match": true,
			"navigation_context_allows_match": true,
		})


func _build_roster_view() -> Array[Dictionary]:
	var roster_snapshot: Dictionary[String, Variant] = _to_string_variant_dictionary(_player_development.call("_serialize"))
	var players: Array[Dictionary] = []
	for player_variant: Variant in roster_snapshot.get("players", []):
		var player_data: Dictionary[String, Variant] = _to_string_variant_dictionary(player_variant)
		var attributes: Dictionary[String, Variant] = _to_string_variant_dictionary(player_data.get("attributes", {}))
		var tec: Dictionary[String, Variant] = _to_string_variant_dictionary(attributes.get("TEC", {}))
		players.append({
			"id": int(player_data.get("id", 0)),
			"name": String(player_data.get("name", "球员")),
			"position": String(player_data.get("position", "MF")),
			"rating": int(tec.get("current", 50)),
			"development_tier": String(player_data.get("tier", "普通")),
			"status_tag": "可训练",
			"recent_growth": _recent_growth_text(player_data),
		})
	return players


func _build_runtime_player(player_name: String, position: String, tier: String, spd: int, pwr: int, tec: int, intelligence: int, sta: int) -> Player:
	var player: Player = PlayerScript.new() as Player
	player.name = player_name
	player.position = position
	player.tier = tier
	player.training_efficiency = 1.1 if tier == "star" else 1.0
	player.condition_multiplier = 1.0
	player.morale_multiplier = 1.0
	player.attributes.spd.current = spd
	player.attributes.spd.potential = mini(spd + 20, 99)
	player.attributes.pwr.current = pwr
	player.attributes.pwr.potential = mini(pwr + 20, 99)
	player.attributes.tec.current = tec
	player.attributes.tec.potential = mini(tec + 20, 99)
	player.attributes.intelligence.current = intelligence
	player.attributes.intelligence.potential = mini(intelligence + 20, 99)
	player.attributes.sta.current = sta
	player.attributes.sta.potential = mini(sta + 20, 99)
	return player


func _get_training_project(training_id: String) -> Dictionary[String, Variant]:
	if _training_catalog == null or not _training_catalog.has_method("get_project"):
		return {}
	return _to_string_variant_dictionary(_training_catalog.call("get_project", training_id))


func _training_summary(payload: Dictionary[String, Variant]) -> String:
	return "%s 完成训练，%s +%s" % [
		String(payload.get("player_name", "球员")),
		String(payload.get("primary_attribute", "属性")),
		str(int(round(float(payload.get("applied_gain", 0.0))))),
	]


func _recent_growth_text(player_data: Dictionary[String, Variant]) -> String:
	var history: Array = player_data.get("training_history", []) as Array
	if history.is_empty():
		return "+0"
	var latest: Dictionary[String, Variant] = _to_string_variant_dictionary(history[history.size() - 1])
	return "+%s" % str(int(round(float(latest.get("applied_gain", 0.0)))))


func _get_event_bus() -> Node:
	return _event_bus_override if _event_bus_override != null else EventBus


func _get_time_manager() -> Node:
	return _time_manager_override if _time_manager_override != null else TimeManager


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	var source: Dictionary = value as Dictionary
	for key_variant: Variant in source.keys():
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary
