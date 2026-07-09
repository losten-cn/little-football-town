extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	test_recognition_mounts_in_home()
	test_recognition_shows_neutral_placeholder_when_no_payload()
	test_recognition_consumes_reputation_payload()
	test_recognition_consumes_achievement_payload()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("RECOGNITION_SUMMARY_AUTHORITATIVE_PAYLOAD_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("RECOGNITION_SUMMARY_AUTHORITATIVE_PAYLOAD_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_recognition_mounts_in_home() -> void:
	EventBus.emit("screen_requested", {"screen_id": "home"})
	_expect(_shell.call("get_current_route") == "home", "home route should mount")
	var panel: Control = _find_control("RecognitionSummary")
	_expect(panel != null and panel.visible, "RecognitionSummary should be mounted and visible on Home")


func test_recognition_shows_neutral_placeholder_when_no_payload() -> void:
	EventBus.emit("screen_requested", {"screen_id": "home"})
	var empty_label: Label = _find_control("RecognitionSummaryEmpty") as Label
	_expect(empty_label != null and empty_label.visible, "RecognitionSummary should show neutral placeholder when no payload")
	var title_label: Label = _find_control("RecognitionSummaryTitle") as Label
	_expect(title_label != null, "RecognitionSummary title should exist")


func test_recognition_consumes_reputation_payload() -> void:
	EventBus.emit("reputation_state_changed", {
		"reputation_level": 3,
		"reputation_progress_ratio": 0.65,
	})
	await get_tree().process_frame
	EventBus.emit("screen_requested", {"screen_id": "home"})
	await get_tree().process_frame
	var rep_label: Label = _find_control("RecognitionReputation") as Label
	_expect(rep_label != null and rep_label.visible, "Reputation label should be visible after payload")
	var empty_label: Label = _find_control("RecognitionSummaryEmpty") as Label
	_expect(empty_label == null or not empty_label.visible, "Empty placeholder should be hidden when reputation payload arrives")


func test_recognition_consumes_achievement_payload() -> void:
	EventBus.emit("achievement_unlocked", {
		"achievement_name": "首胜",
		"achievement_id": "first_win",
	})
	await get_tree().process_frame
	EventBus.emit("screen_requested", {"screen_id": "home"})
	await get_tree().process_frame
	var achievement_list: Control = _find_control("RecognitionAchievementList") as Control
	_expect(achievement_list != null and achievement_list.visible, "Achievement list should be visible after unlock")


func _setup_hud() -> void:
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")
	_hud = HudScene.instantiate() as CanvasLayer
	add_child(_hud)
	_shell = _hud.get_node("MainLoopShell") as Control


func _teardown_hud() -> void:
	if _hud != null:
		_hud.queue_free()
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")


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
