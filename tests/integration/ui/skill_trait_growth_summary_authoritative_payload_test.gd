extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	test_growth_summary_mounts_in_home_shell()
	test_growth_summary_shows_neutral_placeholder_when_payload_missing()
	test_growth_summary_consumes_authoritative_feedback_payload()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("SKILL_TRAIT_GROWTH_SUMMARY_AUTHORITATIVE_PAYLOAD_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("SKILL_TRAIT_GROWTH_SUMMARY_AUTHORITATIVE_PAYLOAD_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_growth_summary_mounts_in_home_shell() -> void:
	EventBus.emit("screen_requested", {"screen_id": "home"})
	_expect(_shell.call("get_current_route") == "home", "home route should mount")
	var growth_panel: Control = _find_control("GrowthSummary")
	_expect(growth_panel != null and growth_panel.visible, "GrowthSummary should be mounted and visible on Home")


func test_growth_summary_shows_neutral_placeholder_when_payload_missing() -> void:
	EventBus.emit("screen_requested", {"screen_id": "home"})
	var empty_label: Label = _find_control("GrowthSummaryEmpty") as Label
	_expect(empty_label != null and empty_label.visible, "GrowthSummary should show neutral placeholder when no feedback payload")
	var content_label: Label = _find_control("GrowthSummaryContent") as Label
	_expect(content_label == null or not content_label.visible, "GrowthSummary content should be hidden when no feedback")


func test_growth_summary_consumes_authoritative_feedback_payload() -> void:
	EventBus.emit("pending_skill_trait_feedback", {
		"feedbacks": [
			{"player_name": "High", "summary": "射门意识提升，下一场前场机会更容易转化"},
			{"player_name": "Low", "summary": "防守选位改善"},
		],
	})
	EventBus.emit("screen_requested", {"screen_id": "home"})
	var content_label: Label = _find_control("GrowthSummaryContent") as Label
	_expect(content_label != null and content_label.visible, "GrowthSummary should show content when feedback payload arrives")
	var content_text: String = content_label.text if content_label != null else ""
	_expect(content_text.contains("High"), "GrowthSummary should display player name from feedback")
	_expect(content_text.contains("射门意识提升"), "GrowthSummary should display feedback summary text")
	_expect(not content_text.contains("暂无技能/特性成长记录"), "GrowthSummary should not show empty placeholder when feedback exists")


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
