extends Node
## S6-02: Training request bridge test.
## Verifies the UI bridge: navigation flow → training option selection → confirm button ready.
## Full end-to-end training execution (train → economy → time → training_completed) requires
## deeper integration wiring and is deferred to a dedicated training regression story.

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	await get_tree().process_frame
	await test_training_request_bridge()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("TRAINING_REQUEST_BRIDGE_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("TRAINING_REQUEST_BRIDGE_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_training_request_bridge() -> void:
	# AC-1: Navigate roster → player_detail
	EventBus.emit("screen_requested", {"screen_id": "roster"})
	await get_tree().process_frame
	await get_tree().process_frame
	var roster_row: Button = _find_button("RosterRow_2")
	_expect(roster_row != null, "roster rows should be published by runtime coordinator")
	_press_button("RosterRow_2")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_shell.call("get_current_route") == "player_detail", "should open player detail after roster selection")

	# AC-2: Enter training route
	_press_button("TrainingEntryButton")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_shell.call("get_current_route") == "training", "should open training route")

	# AC-3: Training options are displayed
	var opt_button: Button = _find_button("TrainingOption_finishing")
	_expect(opt_button != null, "training option 'finishing' should be displayed")

	# AC-4: Select option enables confirm button
	_press_button("TrainingOption_finishing")
	await get_tree().process_frame
	var confirm: Button = _find_button("TrainingConfirmButton")
	_expect(confirm != null, "TrainingConfirmButton should exist in training route")
	_expect(not confirm.disabled, "TrainingConfirmButton should be enabled after option selection")

	# AC-5: Return home still works
	_shell.call("return_home")
	await get_tree().process_frame
	_expect(_shell.call("get_current_route") == "home", "should return home after training flow")


func _setup_hud() -> void:
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")
	TimeManager.apply_snapshot({
		"state": "Planning",
		"current_phase_time_budget": 2,
		"reserved_time": 0,
		"consumed_time": 0,
		"standard_window_size": 1,
	})
	_hud = HudScene.instantiate() as CanvasLayer
	add_child(_hud)
	_shell = _hud.get_node("MainLoopShell") as Control


func _teardown_hud() -> void:
	if _hud != null:
		_hud.queue_free()
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")


func _press_button(button_name: String) -> void:
	var button: Button = _find_button(button_name)
	if button == null:
		_failures.append("Button not found: %s" % button_name)
		return
	button.pressed.emit()


func _find_button(button_name: String) -> Button:
	return _find_control(button_name) as Button


func _find_control(control_name: String) -> Control:
	if _hud == null:
		return null
	return _find_node_by_name(_hud, control_name) as Control


func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child: Node in root.get_children():
		var found: Node = _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
