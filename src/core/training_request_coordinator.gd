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
	_get_event_bus().subscribe("training_read_models_requested", _on_training_read_models_requested)
	_publish_training_read_models()


func _exit_tree() -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus != null:
		event_bus.unsubscribe("screen_requested", _on_screen_requested)
		event_bus.unsubscribe("training_requested", _on_training_requested)
		event_bus.unsubscribe("training_read_models_requested", _on_training_read_models_requested)
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


func _on_training_read_models_requested(_event_name: String, _payload: Dictionary) -> void:
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
		event_bus.emit("roster_updated", {
			"players": _build_roster_view(),
			"selected_player_id": null,
			"selected_player": {},
		})
	if _training_catalog != null and _training_catalog.has_method("get_training_options"):
		event_bus.emit("training_options_updated", {
			"training_available": true,
			"options": _build_training_options_view(),
		})
	if _economy_manager != null:
		var balances: Dictionary[String, float] = _economy_manager.get_balance_snapshot()
		event_bus.emit("system_state_changed", {
			"funds": int(balances.get("funds", 0.0)),
			"ap": int(balances.get("action_points", 0.0)),
			"team_overview": "训练系统已接入，球员成长可结算",
		})


func _build_roster_view() -> Array[Dictionary]:
	var roster_snapshot: Dictionary[String, Variant] = _to_string_variant_dictionary(_player_development.call("_serialize"))
	var players: Array[Dictionary] = []
	for player_variant: Variant in roster_snapshot.get("players", []):
		var player_data: Dictionary[String, Variant] = _to_string_variant_dictionary(player_variant)
		var attributes: Dictionary[String, Variant] = _to_string_variant_dictionary(player_data.get("attributes", {}))
		var tec: Dictionary[String, Variant] = _to_string_variant_dictionary(attributes.get("TEC", {}))
		var player_name: String = String(player_data.get("name", "球员"))
		var position: String = String(player_data.get("position", "MF"))
		var rating: int = int(tec.get("current", 50))
		var development_tier: String = String(player_data.get("tier", "普通"))
		var recent_growth: String = _recent_growth_text(player_data)
		var status_summary: String = "可训练"
		players.append({
			"id": int(player_data.get("id", 0)),
			"name": player_name,
			"position": position,
			"rating": rating,
			"development_tier": development_tier,
			"status_tag": status_summary,
			"status_summary": status_summary,
			"recent_growth": recent_growth,
			"growth_summary": _roster_growth_summary(recent_growth),
			"attention_reason": _roster_attention_reason(rating, recent_growth),
			"role_summary": _roster_role_summary(position, rating),
			"next_step_summary": _roster_next_step_summary(rating, recent_growth),
			"attributes_summary": _roster_attributes_summary(attributes),
			"training_reason": _roster_training_reason(rating, recent_growth),
			"training_payoff_summary": _roster_training_payoff_summary(position),
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


func _build_training_options_view() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if _training_catalog == null or not _training_catalog.has_method("get_training_options"):
		return options
	for option_variant: Variant in _training_catalog.call("get_training_options"):
		var option: Dictionary[String, Variant] = _to_string_variant_dictionary(option_variant)
		if not option.has("next_step_summary"):
			option["next_step_summary"] = "等待训练确认"
		if not option.has("risk_summary"):
			option["risk_summary"] = "暂无训练风险说明"
		options.append(option)
	return options


func _roster_growth_summary(recent_growth: String) -> String:
	return recent_growth if not recent_growth.is_empty() else "暂无近期成长记录"


func _roster_attention_reason(rating: int, recent_growth: String) -> String:
	if rating >= 70:
		return "当前评分靠前，适合优先检查首发价值。"
	if recent_growth.contains("+") and recent_growth != "+0":
		return "近期有成长记录，适合继续观察训练回报。"
	return "先看他的状态与位置，决定是否纳入下一次训练。"


func _roster_role_summary(position: String, rating: int) -> String:
	if rating >= 70:
		return "%s 主力候选，优先确认能否稳定出场。" % position
	if rating >= 55:
		return "%s 轮换候选，适合用训练补齐短板。" % position
	return "%s 培养候选，先看成长窗口再决定投入。" % position


func _roster_next_step_summary(rating: int, recent_growth: String) -> String:
	if rating >= 70 or (recent_growth.contains("+") and recent_growth != "+0"):
		return "进入详情后安排训练。"
	return "进入详情确认状态。"


func _roster_training_reason(rating: int, recent_growth: String) -> String:
	if rating >= 70 or (recent_growth.contains("+") and recent_growth != "+0"):
		return "他正处在适合加练的窗口，训练收益更容易被看见。"
	return "先给重点球员一次明确安排，能让下一场比赛更有牵挂。"


func _roster_training_payoff_summary(position: String) -> String:
	return "下一场%s位置的比赛处理会更容易转化。" % position


func _roster_attributes_summary(attributes: Dictionary[String, Variant]) -> String:
	var labels: Dictionary[String, String] = {
		"SPD": "速度",
		"PWR": "力量",
		"TEC": "技术",
		"INT": "智力",
		"STA": "体能",
	}
	var parts: Array[String] = []
	for key: String in ["SPD", "PWR", "TEC", "INT", "STA"]:
		if not attributes.has(key):
			continue
		var attribute_value: Dictionary[String, Variant] = _to_string_variant_dictionary(attributes[key])
		parts.append("%s %s/%s" % [labels[key], str(attribute_value.get("current", "?")), str(attribute_value.get("potential", "?"))])
	if parts.is_empty():
		return "暂无详细属性"
	return "｜".join(parts)


func _training_option_next_step_summary(is_available: bool) -> String:
	if is_available:
		return "确认训练后回到主页，看下一场比赛如何承接这次安排。"
	return "当前先处理阻塞原因，再决定是否安排这次训练。"


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
