extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	test_what_next_guidance_follows_minimum_loop_and_ends_after_result()
	test_what_next_guidance_supports_text_only_fallback()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("WHAT_NEXT_GUIDANCE_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("WHAT_NEXT_GUIDANCE_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_what_next_guidance_follows_minimum_loop_and_ends_after_result() -> void:
	var guidance: Control = _guidance()
	_expect(guidance != null, "WhatNextGuidance should be mounted")
	_expect(guidance.call("get_hint_text") == "先看看球员", "Home should show first next-step cue")
	_expect(_text_length(guidance.call("get_hint_text")) <= 25, "Home core copy should be at most 25 characters")
	EventBus.emit("screen_requested", {"screen_id": "roster"})
	_expect(guidance.call("get_current_step") == "roster", "roster route should advance guidance to roster")
	_expect(guidance.call("get_hint_text") == "选一名球员", "roster should point toward selecting a player")
	EventBus.emit("screen_requested", {"screen_id": "training"})
	_expect(guidance.call("get_current_step") == "training", "direct training route should not require roster first")
	_expect(guidance.call("get_hint_text") == "完成一次训练", "training should point to one training action")
	EventBus.emit("training_completed", {"summary": "训练完成"})
	_expect(guidance.call("get_current_step") == "match_pre", "training completion should advance toward pre-match")
	EventBus.emit("time_advanced", {
		"match_trigger_reached": false,
		"match_center_available": false,
	})
	_expect(guidance.call("get_hint_text") == "等到比赛开启", "pre-match guidance should wait when match is unavailable")
	EventBus.emit("time_advanced", {
		"match_trigger_reached": true,
		"match_center_available": true,
		"schedule_available": true,
	})
	_expect(guidance.call("get_hint_text") == "开始这场比赛", "pre-match guidance should point to start when available")
	EventBus.emit("screen_requested", {"screen_id": "match_pre"})
	EventBus.emit("match_completed", {
		"match_id": "league_r01_m01",
		"result": "home_win",
		"score": {"home": 2, "away": 1},
	})
	_expect(guidance.call("get_current_step") == "match_result", "match completion should advance to result guidance")
	_expect(guidance.call("get_hint_text") == "读结果并返回", "result should point to reading and returning")
	EventBus.emit("match_result_confirmed", {"match_id": "league_r01_m01"})
	_expect(guidance.call("get_current_step") == "done", "result confirmation should complete current-wave guidance")
	_expect(not guidance.visible, "guidance should hide after completion")


func test_what_next_guidance_supports_text_only_fallback() -> void:
	var guidance: Control = _guidance()
	_expect(guidance != null, "WhatNextGuidance should be available for fallback test")
	if guidance == null:
		return
	guidance.call("set_anchor_available", false)
	_expect(_find_label_text("WhatNextTarget").contains("文字继续"), "missing anchors should fall back to text-only guidance")


func _setup_hud() -> void:
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")
	_hud = HudScene.instantiate() as CanvasLayer
	add_child(_hud)
	_shell = _hud.get_node("MainLoopShell") as Control


func _teardown_hud() -> void:
	if _hud != null:
		_hud.queue_free()
		_hud = null
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")


func _guidance() -> Control:
	return _find_control("WhatNextGuidance")


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


func _text_length(value: Variant) -> int:
	return str(value).length()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
