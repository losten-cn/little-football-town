class_name MatchStartCoordinator
extends Node
## Bridges UI match start requests to the authoritative MatchSimulation entry.

const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const ROUTE_MATCH_PRE: String = "match_pre"
const ROUTE_MATCH_LIVE: String = "match_live"

var _match_simulation: MatchSimulation = null
var _event_bus_override: Node = null
var _time_manager_override: Node = null
var _last_system_payload: Dictionary[String, Variant] = {}


func _ready() -> void:
	if _match_simulation == null:
		_bootstrap_runtime_system()
	_subscribe_events()


func _exit_tree() -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus != null:
		event_bus.unsubscribe("match_start_requested", _on_match_start_requested)
		event_bus.unsubscribe("system_state_changed", _on_system_state_changed)


## Overrides runtime dependencies for isolated integration tests.
func configure_for_testing(match_simulation: MatchSimulation, event_bus: Node, time_manager: Node) -> void:
	_match_simulation = match_simulation
	_event_bus_override = event_bus
	_time_manager_override = time_manager
	if _match_simulation != null:
		_match_simulation.set_event_bus_for_testing(event_bus)
		_match_simulation.bind_time_manager(time_manager)


func _bootstrap_runtime_system() -> void:
	_match_simulation = MatchSimulationScript.new() as MatchSimulation
	_match_simulation.name = "MatchSimulation"
	_match_simulation.set_event_bus_for_testing(_get_event_bus())
	_match_simulation.bind_time_manager(_get_time_manager())
	add_child(_match_simulation)


func _subscribe_events() -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus == null:
		return
	event_bus.subscribe("match_start_requested", _on_match_start_requested)
	event_bus.subscribe("system_state_changed", _on_system_state_changed)


func _on_system_state_changed(_event_name: String, payload: Dictionary) -> void:
	_last_system_payload = _to_string_variant_dictionary(payload)


func _on_match_start_requested(_event_name: String, payload: Dictionary) -> void:
	var request_payload: Dictionary[String, Variant] = _to_string_variant_dictionary(payload)
	var source_screen_id: String = String(request_payload.get("source_screen_id", ROUTE_MATCH_PRE))
	var target_screen_id: String = String(request_payload.get("target_screen_id", ROUTE_MATCH_LIVE))
	if target_screen_id != ROUTE_MATCH_LIVE:
		_emit_match_start_failed(source_screen_id, target_screen_id, "unsupported_match_route", "")
		return
	if not _system_allows_match():
		_emit_match_start_failed(source_screen_id, target_screen_id, "system_state_disabled", String(_last_system_payload.get("system_state_disable_reason", "")))
		return
	if not _navigation_allows_match():
		_emit_match_start_failed(source_screen_id, target_screen_id, "navigation_context_disabled", String(_last_system_payload.get("navigation_context_disable_reason", "")))
		return
	if _match_simulation == null:
		_emit_match_start_failed(source_screen_id, target_screen_id, "match_authority_missing", "")
		return
	var match_context: Dictionary[String, Variant] = _build_match_context(request_payload)
	if not _match_simulation.start_formal_match(match_context, _get_time_manager()):
		_emit_match_start_failed(source_screen_id, target_screen_id, "formal_match_rejected", "")
		return
	_get_event_bus().emit("screen_requested", {
		"screen_id": ROUTE_MATCH_LIVE,
		"source_screen_id": source_screen_id,
	})


func _build_match_context(request_payload: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var match_context: Dictionary[String, Variant] = _to_string_variant_dictionary(request_payload.get("match_context", {}))
	var time_state: Dictionary[String, Variant] = _get_time_state()
	var match_state: Dictionary[String, Variant] = _to_string_variant_dictionary(time_state.get("match", {}))
	for key: String in ["scheduled_position", "opponent_name", "next_match_display", "home_team_id", "away_team_id"]:
		if not match_context.has(key) and match_state.has(key):
			match_context[key] = match_state[key]
	if not match_context.has("match_id"):
		match_context["match_id"] = _default_match_id(time_state, match_state)
	if not match_context.has("match_seed"):
		match_context["match_seed"] = int(time_state.get("season_number", 1)) * 1000 + int(match_state.get("scheduled_position", 0))
	return match_context


func _get_time_state() -> Dictionary[String, Variant]:
	var time_manager: Node = _get_time_manager()
	if time_manager != null and time_manager.has_method("get_state"):
		return _to_string_variant_dictionary(time_manager.call("get_state"))
	return {}


func _default_match_id(time_state: Dictionary[String, Variant], match_state: Dictionary[String, Variant]) -> String:
	var season_number: int = int(time_state.get("season_number", 1))
	var scheduled_position: int = int(match_state.get("scheduled_position", 0))
	return "season_%s_match_%s" % [str(season_number), str(scheduled_position)]


func _system_allows_match() -> bool:
	return bool(_last_system_payload.get("system_state_allows_match", true))


func _navigation_allows_match() -> bool:
	return bool(_last_system_payload.get("navigation_context_allows_match", true))


func _emit_match_start_failed(source_screen_id: String, target_screen_id: String, reason: String, detail: String) -> void:
	_get_event_bus().emit("match_start_failed", {
		"source_screen_id": source_screen_id,
		"target_screen_id": target_screen_id,
		"reason": reason,
		"detail": detail,
	})


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
