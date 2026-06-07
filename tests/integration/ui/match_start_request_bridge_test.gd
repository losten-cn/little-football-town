extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null
var _match_start_requests: Array[Dictionary] = []
var _screen_requests: Array[Dictionary] = []
var _match_start_failures: Array[Dictionary] = []


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	await test_match_start_request_authorized_by_core_routes_live()
	_teardown_hud()
	await get_tree().process_frame
	_setup_hud()
	await get_tree().process_frame
	await test_match_start_request_rejected_by_core_stays_pre_match()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("MATCH_START_REQUEST_BRIDGE_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("MATCH_START_REQUEST_BRIDGE_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_match_start_request_authorized_by_core_routes_live() -> void:
	_prepare_match_trigger_state(true)
	EventBus.emit("system_state_changed", {"system_state_allows_match": true, "navigation_context_allows_match": true})
	EventBus.emit("screen_requested", {"screen_id": "match_pre"})
	await get_tree().process_frame
	_clear_recorded_events()
	_press_button("PreMatchStartButton")
	await get_tree().process_frame
	_expect(_match_start_requests.size() == 1, "pre-match start should emit exactly one match_start_requested event")
	_expect(String(_match_start_requests[0].get("source_screen_id", "")) == "match_pre", "match start request should include source route")
	_expect(String(_match_start_requests[0].get("target_screen_id", "")) == "match_live", "match start request should include target route")
	_expect(_first_screen_request_id() == "match_live", "match_live screen request should be emitted after the match start request")
	_expect(_shell.call("get_current_route") == "match_live", "authorized match start should route to match_live")
	var coordinator: Node = _hud.get_node_or_null("MatchStartCoordinator")
	var simulation: Node = coordinator.get_node_or_null("MatchSimulation") if coordinator != null else null
	_expect(simulation != null, "runtime coordinator should own a MatchSimulation authority")
	if simulation != null:
		_expect(String(simulation.call("get_state_name")) == "Entry", "authorized match start should enter the formal match state machine")


func test_match_start_request_rejected_by_core_stays_pre_match() -> void:
	_prepare_match_trigger_state(false)
	EventBus.emit("time_advanced", {
		"date_display": "Week 1",
		"phase": "MATCH_TRIGGER",
		"available_action_windows": 0,
		"schedule_available": true,
		"match_trigger_reached": true,
		"match_center_available": true,
		"opponent_name": "Opponent 1",
	})
	EventBus.emit("system_state_changed", {"system_state_allows_match": true, "navigation_context_allows_match": true})
	EventBus.emit("screen_requested", {"screen_id": "match_pre"})
	await get_tree().process_frame
	_clear_recorded_events()
	_press_button("PreMatchStartButton")
	await get_tree().process_frame
	_expect(_match_start_requests.size() == 1, "rejected start should still emit one match_start_requested event")
	_expect(_match_start_failures.size() == 1, "core rejection should emit one match_start_failed event")
	if not _match_start_failures.is_empty():
		_expect(String(_match_start_failures[0].get("reason", "")) == "formal_match_rejected", "core rejection should report formal_match_rejected")
	_expect(_first_screen_request_id() != "match_live", "rejected start should not emit match_live routing")
	_expect(_shell.call("get_current_route") == "match_pre", "rejected match start should stay on match_pre")
	_expect(_find_label_text("MatchDisableReason").contains("比赛条件已变化"), "rejected match start should show a player-facing authority failure")


func _setup_hud() -> void:
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")
	_reset_time_state()
	_hud = HudScene.instantiate() as CanvasLayer
	add_child(_hud)
	_shell = _hud.get_node("MainLoopShell") as Control
	EventBus.subscribe("match_start_requested", _on_match_start_requested)
	EventBus.subscribe("screen_requested", _on_screen_requested)
	EventBus.subscribe("match_start_failed", _on_match_start_failed)


func _teardown_hud() -> void:
	EventBus.unsubscribe("match_start_requested", _on_match_start_requested)
	EventBus.unsubscribe("screen_requested", _on_screen_requested)
	EventBus.unsubscribe("match_start_failed", _on_match_start_failed)
	if _hud != null:
		_hud.queue_free()
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")
	_reset_time_state()
	_hud = null
	_shell = null
	_clear_recorded_events()


func _reset_time_state() -> void:
	TimeManager.apply_snapshot({
		"state": "Planning",
		"timeline_position": 0,
		"scheduled_match_position": 5,
		"schedule_available": false,
		"schedule_loading": false,
		"schedule_missing": false,
		"match_center_available": false,
		"match_in_progress": false,
	})


func _prepare_match_trigger_state(center_available: bool) -> void:
	TimeManager.apply_snapshot({
		"state": "Match Trigger",
		"season_number": 1,
		"timeline_position": 5,
		"scheduled_match_position": 5,
		"schedule_available": true,
		"schedule_loading": false,
		"schedule_missing": false,
		"match_center_available": center_available,
		"match_in_progress": false,
		"opponent_name": "Opponent 1",
		"next_match_display": "Week 1 vs Opponent 1",
		"home_team_id": 1,
		"away_team_id": 2,
	})


func _on_match_start_requested(_event_name: String, payload: Dictionary) -> void:
	_match_start_requests.append(_to_string_variant_dictionary(payload))


func _on_screen_requested(_event_name: String, payload: Dictionary) -> void:
	_screen_requests.append(_to_string_variant_dictionary(payload))


func _on_match_start_failed(_event_name: String, payload: Dictionary) -> void:
	_match_start_failures.append(_to_string_variant_dictionary(payload))


func _clear_recorded_events() -> void:
	_match_start_requests.clear()
	_screen_requests.clear()
	_match_start_failures.clear()


func _first_screen_request_id() -> String:
	if _screen_requests.is_empty():
		return ""
	return String(_screen_requests[0].get("screen_id", ""))


func _press_button(button_name: String) -> void:
	var button: Button = _find_button(button_name)
	if button == null:
		_failures.append("Button not found: %s" % button_name)
		return
	button.pressed.emit()


func _find_button(button_name: String) -> Button:
	var control: Control = _find_control(button_name)
	return control as Button


func _find_control(control_name: String) -> Control:
	if _hud == null:
		return null
	return _find_node_by_name(_hud, control_name) as Control


func _find_label_text(label_name: String) -> String:
	var control: Control = _find_control(label_name)
	if control is Label:
		return (control as Label).text
	return ""


func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child: Node in root.get_children():
		var found: Node = _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	var source: Dictionary = value as Dictionary
	for key_variant: Variant in source.keys():
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
