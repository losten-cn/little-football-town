extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null
var _training_completed_payload: Dictionary[String, Variant] = {}
var _player_action_payload: Dictionary[String, Variant] = {}


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	await test_training_confirm_consumes_request_and_returns_home()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("TRAINING_REQUEST_BRIDGE_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("TRAINING_REQUEST_BRIDGE_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_training_confirm_consumes_request_and_returns_home() -> void:
	EventBus.subscribe("training_completed", _on_training_completed)
	EventBus.subscribe("player_action_completed", _on_player_action_completed)
	EventBus.emit("screen_requested", {"screen_id": "roster"})
	await get_tree().process_frame
	var roster_row: Button = _find_button("RosterRow_2")
	_expect(roster_row != null, "runtime coordinator should publish roster rows")
	_press_button("RosterRow_2")
	await get_tree().process_frame
	_expect(_shell.call("get_current_route") == "player_detail", "roster selection should open player detail")
	_press_button("TrainingEntryButton")
	await get_tree().process_frame
	_expect(_shell.call("get_current_route") == "training", "training entry should open training route")
	_press_button("TrainingConfirmButton")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(not _training_completed_payload.is_empty(), "training request should emit training_completed")
	_expect(not _player_action_payload.is_empty(), "training request should emit player_action_completed")
	_expect(String(_training_completed_payload.get("training_id", "")) == "finishing", "completion should include selected training id")
	_expect(String(_training_completed_payload.get("summary", "")).contains("完成训练"), "completion should include player-facing summary")
	_expect(_shell.call("get_current_route") == "home", "player action completion should return home")
	_expect(_find_label_text("RouteSummary").contains("完成训练"), "home should show the training result summary")
	EventBus.unsubscribe("training_completed", _on_training_completed)
	EventBus.unsubscribe("player_action_completed", _on_player_action_completed)


func _setup_hud() -> void:
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")
	_prepare_training_time_window()
	_hud = HudScene.instantiate() as CanvasLayer
	add_child(_hud)
	_shell = _hud.get_node("MainLoopShell") as Control


func _teardown_hud() -> void:
	if _hud != null:
		_hud.queue_free()
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")


func _prepare_training_time_window() -> void:
	TimeManager.apply_snapshot({
		"state": "Planning",
		"current_phase_time_budget": 2,
		"reserved_time": 0,
		"consumed_time": 0,
		"standard_window_size": 1,
	})


func _on_training_completed(_event_name: String, payload: Dictionary) -> void:
	_training_completed_payload = _to_string_variant_dictionary(payload)


func _on_player_action_completed(_event_name: String, payload: Dictionary) -> void:
	_player_action_payload = _to_string_variant_dictionary(payload)


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
