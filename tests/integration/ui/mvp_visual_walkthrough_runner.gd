extends SceneTree

const HUD_SCENE_PATH: String = "res://src/ui/hud/Hud.tscn"
const OUTPUT_DIR: String = "user://mvp_visual_walkthrough"
const TRANSITION_WAIT_SECONDS: float = 0.25

var _failures: Array[String] = []
var _screenshot_paths: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null
var _absolute_output_dir: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_setup_window()
	_prepare_output_dir()
	_setup_hud()
	await _wait_for_ui()

	_emit_planning_payloads()
	await _capture("01_home_initial", "home")

	await _press_button_and_wait("SecondaryAction", "球员 / 训练")
	_emit_player_payloads()
	await _capture("02_roster", "roster")

	await _press_button_and_wait("RosterRow_2", "High")
	await _capture("03_player_detail", "player_detail")

	await _press_button_and_wait("TrainingEntryButton", "进入训练")
	await _capture("04_training", "training")

	await _press_button_and_wait("TrainingConfirmButton", "确认训练")
	_emit_event("training_completed", {
		"player_id": "2",
		"training_id": "finishing",
		"summary": "High 完成射门训练，近期成长 +2",
		"attribute_changes": {"finishing": 1},
	})
	await _capture("05_training_result", "training")

	_emit_event("player_action_completed", {
		"player_id": "2",
		"summary": "High 完成训练，球队状态已更新",
	})
	await _capture("06_home_after_training", "home")

	_emit_match_ready_payloads(false)
	await _press_button_and_wait("PrimaryAction", "进入比赛")
	await _capture("07_home_match_disabled_reason", "home")

	_emit_match_ready_payloads(true)
	await _press_button_and_wait("PrimaryAction", "进入比赛")
	await _capture("08_match_pre", "match_pre")

	await _press_button_and_wait("PreMatchStartButton", "开始比赛")
	await _capture("09_match_live_empty", "match_live")

	_emit_event("match_event_occurred", {"minute": 15, "summary": "High 完成一次射门"})
	_emit_event("match_event_occurred", {"minute": 45, "summary": "0-0 中场"})
	await _capture("10_match_live_timeline", "match_live")

	_emit_event("match_completed", {
		"match_id": "league_r01_m01",
		"result": "home_win",
		"score": {"home": 2, "away": 1},
		"reason": "机会把握更好",
		"player_performance_summary": "门将稳定，High 制造关键机会",
	})
	_emit_event("league_standings_updated", {"summary": "积分榜已更新：小镇队升至第 3"})
	await _capture("11_match_result", "match_result")

	await _press_button_and_wait("ResultConfirmButton", "确认并返回 Home")
	await _capture("12_home_final", "home")

	_teardown_hud()
	_report_and_quit()


func _setup_window() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_title("Little Football Town MVP Visual Walkthrough")


func _prepare_output_dir() -> void:
	_absolute_output_dir = ProjectSettings.globalize_path(OUTPUT_DIR)
	var error: int = DirAccess.make_dir_recursive_absolute(_absolute_output_dir)
	if error != OK:
		_failures.append("Failed to create screenshot output dir: %s" % _absolute_output_dir)


func _setup_hud() -> void:
	_call_autoload("EventBus", "clear_all", [])
	_call_autoload("ScreenManager", "reset_to_screen", ["home"])
	var hud_scene: PackedScene = load(HUD_SCENE_PATH) as PackedScene
	if hud_scene == null:
		_failures.append("Failed to load Hud scene")
		return
	_hud = hud_scene.instantiate() as CanvasLayer
	root.add_child(_hud)
	_shell = _hud.get_node("MainLoopShell") as Control
	if _shell == null:
		_failures.append("MainLoopShell not found")


func _teardown_hud() -> void:
	if _hud != null:
		_hud.queue_free()
	_call_autoload("EventBus", "clear_all", [])
	_call_autoload("ScreenManager", "reset_to_screen", ["home"])


func _emit_planning_payloads() -> void:
	_emit_event("time_advanced", {
		"date_display": "Week 1",
		"phase": "PLANNING",
		"available_action_windows": 2,
		"schedule_available": true,
		"match_trigger_reached": false,
		"match_center_available": true,
		"next_match_display": "周末 vs Opponent 1",
		"opponent_name": "Opponent 1",
	})
	_emit_event("system_state_changed", {
		"team_overview": "8 人阵容，1 人可重点训练",
		"funds": 1200,
		"ap": 2,
		"system_state_allows_match": true,
		"navigation_context_allows_match": true,
	})


func _emit_player_payloads() -> void:
	_emit_event("roster_updated", {
		"players": [
			{"id": 1, "name": "Low", "position": "DF", "rating": 45, "development_tier": "普通", "status_tag": "正常", "recent_growth": "+0"},
			{"id": 2, "name": "High", "position": "FW", "rating": 77, "development_tier": "重点", "status_tag": "可训练", "recent_growth": "+2"},
		],
	})
	_emit_event("training_options_updated", {
		"training_available": true,
		"options": [
			{"training_id": "finishing", "name": "射门训练", "summary": "提升终结效率", "available": true},
		],
	})


func _emit_match_ready_payloads(system_allows_match: bool) -> void:
	_emit_event("time_advanced", {
		"date_display": "Week 1 Match Day",
		"phase": "MATCH_TRIGGER",
		"available_action_windows": 0,
		"schedule_available": true,
		"match_trigger_reached": true,
		"match_center_available": true,
		"opponent_name": "Opponent 1",
		"round": 1,
		"home_away": "主场",
		"ranking_summary": "第 3 vs 第 5",
		"lineup_summary": "首发合法",
		"tactical_summary": "默认战术",
	})
	_emit_event("system_state_changed", {
		"system_state_allows_match": system_allows_match,
		"system_state_disable_reason": "阵容不合法",
		"navigation_context_allows_match": true,
		"team_overview": "训练完成，准备比赛",
		"funds": 1200,
		"ap": 0,
	})


func _press_button(button_name: String, text_contains: String = "") -> void:
	var button: Button = _find_button(button_name, text_contains)
	if button == null:
		_failures.append("Button not found: %s" % button_name)
		return
	button.pressed.emit()


func _press_button_and_wait(button_name: String, text_contains: String = "") -> void:
	_press_button(button_name, text_contains)
	await _wait_for_ui()


func _emit_event(event_name: String, payload: Dictionary) -> void:
	_call_autoload("EventBus", "emit", [event_name, payload])


func _call_autoload(autoload_name: String, method_name: String, arguments: Array) -> Variant:
	var autoload_node: Node = root.get_node_or_null(autoload_name)
	if autoload_node == null:
		_failures.append("Autoload not found: %s" % autoload_name)
		return null
	if not autoload_node.has_method(method_name):
		_failures.append("Autoload %s missing method: %s" % [autoload_name, method_name])
		return null
	return autoload_node.callv(method_name, arguments)


func _find_button(button_name: String, text_contains: String = "") -> Button:
	var by_name: Button = _find_visible_button_by_name(root, button_name)
	if by_name != null:
		return by_name
	if not text_contains.is_empty():
		return _find_visible_button_by_text(root, text_contains)
	return null


func _find_visible_button_by_name(node: Node, button_name: String) -> Button:
	if node is Button and node.name == button_name and (node as Button).visible:
		return node as Button
	for child: Node in node.get_children():
		var found: Button = _find_visible_button_by_name(child, button_name)
		if found != null:
			return found
	return null


func _find_visible_button_by_text(node: Node, text_contains: String) -> Button:
	if node is Button:
		var button: Button = node as Button
		if button.visible and button.text.contains(text_contains):
			return button
	for child: Node in node.get_children():
		var found: Button = _find_visible_button_by_text(child, text_contains)
		if found != null:
			return found
	return null


func _capture(step_id: String, expected_route: String) -> void:
	await _wait_for_ui()
	if _shell != null:
		var current_route: String = str(_shell.call("get_current_route"))
		if current_route != expected_route:
			_failures.append("%s expected route %s but found %s" % [step_id, expected_route, current_route])
	var local_path: String = "%s/%s.png" % [OUTPUT_DIR, step_id]
	var absolute_path: String = ProjectSettings.globalize_path(local_path)
	var image: Image = root.get_texture().get_image()
	var error: int = image.save_png(local_path)
	if error != OK:
		_failures.append("%s failed to save screenshot: %s" % [step_id, absolute_path])
	else:
		_screenshot_paths.append(absolute_path)
		print("MVP_VISUAL_WALKTHROUGH_SCREENSHOT=%s" % absolute_path)


func _wait_for_ui() -> void:
	await process_frame
	await process_frame
	await create_timer(TRANSITION_WAIT_SECONDS).timeout
	await process_frame


func _report_and_quit() -> void:
	print("MVP_VISUAL_WALKTHROUGH_OUTPUT_DIR=%s" % _absolute_output_dir)
	if _failures.is_empty():
		print("MVP_VISUAL_WALKTHROUGH_PASS")
		quit(0)
		return
	for failure: String in _failures:
		push_error("MVP_VISUAL_WALKTHROUGH_FAIL: %s" % failure)
	quit(1)
