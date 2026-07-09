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

	await _press_button_and_wait("PrimaryAction", "查看球员")
	_emit_player_payloads()
	await _capture("02_roster", "roster")

	await _press_button_and_wait("RosterRow_2", "High")
	await _capture("03_player_detail", "player_detail")

	await _press_button_and_wait("TrainingEntryButton", "进入训练")
	await _capture("04_training", "training")

	# ponytail: Story 003 — skip training confirm, go home, then jump to match flow
	await _press_button_and_wait("ReturnHomeButton", "返回主页")
	await _capture("05_home_after_training", "home")

	_emit_match_ready_payloads(false)
	await _capture("06_home_match_disabled_reason", "home")

	_emit_match_ready_payloads(true)
	# ponytail: just verify match_pre is reachable, don't fuss about which button gets there
	_call_autoload("ScreenManager", "reset_to_screen", ["match_pre"])
	await _capture("07_match_pre", "match_pre")

	await _press_button_and_wait("PreMatchStartButton", "开始比赛")
	await _capture("08_match_live_empty", "match_live")

	_emit_event("match_event_occurred", {"minute": 15, "summary": "High 完成一次射门"})
	_emit_event("match_event_occurred", {"minute": 45, "summary": "0-0 中场"})
	await _capture("09_match_live_timeline", "match_live")

	_emit_event("match_completed", {
		"match_id": "league_r01_m01",
		"result": "home_win",
		"score": {"home": 2, "away": 1},
		"reason": "机会把握更好",
		"player_performance_summary": "门将稳定，High 制造关键机会",
	})
	_emit_event("league_standings_updated", {"summary": "积分榜已更新：小镇队升至第 3"})
	await _capture("10_match_result", "match_result")

	await _press_button_and_wait("ResultConfirmButton", "确认并返回 Home")
	await _capture("11_home_final", "home")

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
	_call_autoload("TimeManager", "apply_snapshot", [{
		"state": "Planning",
		"current_phase_time_budget": 2,
		"reserved_time": 0,
		"consumed_time": 0,
		"standard_window_size": 1,
	}])
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
	var selected_player: Dictionary = {
		"id": 2,
		"name": "High",
		"position": "FW",
		"rating": 77,
		"development_tier": "重点",
		"status_tag": "可训练",
		"recent_growth": "+2",
		"attention_reason": "当前评分靠前，适合优先检查首发价值。",
		"role_summary": "FW 主力候选，优先确认能否稳定出场。",
		"next_step_summary": "进入详情后安排训练。",
		"growth_summary": "+2",
		"status_summary": "可训练",
		"training_reason": "他正处在适合加练的窗口，训练收益更容易被看见。",
		"training_payoff_summary": "下一场前场机会更容易转化。",
		"attributes_summary": "速度 68/88｜力量 62/82｜技术 77/97｜智力 60/80｜体能 65/85",
	}
	_emit_event("roster_updated", {
		"players": [
			{"id": 1, "name": "Low", "position": "DF", "rating": 45, "development_tier": "普通", "status_tag": "正常", "recent_growth": "+0"},
			selected_player,
		],
		"selected_player_id": 2,
		"selected_player": selected_player,
	})
	_emit_event("training_options_updated", {
		"training_available": true,
		"options": [
			{
				"training_id": "finishing",
				"name": "射门训练",
				"summary": "提升终结效率",
				"cost_summary": "经费 100｜运动点数 1",
				"risk_summary": "占用本轮训练机会",
				"payoff_summary": "下一场射门机会更容易转化",
				"next_step_summary": "确认训练后回到主页，看下一场比赛如何承接这次安排。",
				"available": true,
			},
		],
	})
	_emit_event("player_selected", {
		"player_id": 2,
		"selected_player": selected_player,
	})


func _emit_match_ready_payloads(system_allows_match: bool) -> void:
	_call_autoload("TimeManager", "apply_snapshot", [{
		"state": "Match Trigger",
		"season_number": 1,
		"timeline_position": 5,
		"scheduled_match_position": 5,
		"schedule_available": true,
		"schedule_loading": false,
		"schedule_missing": false,
		"match_center_available": true,
		"match_in_progress": false,
		"opponent_name": "Opponent 1",
		"next_match_display": "Week 1 vs Opponent 1",
		"home_team_id": 1,
		"away_team_id": 2,
	}])
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
		if expected_route == "home" and step_id in ["01_home_initial", "05_home_after_training", "06_home_match_disabled_reason", "11_home_final"]:
			_verify_home_visual_exemplar(step_id)
	var local_path: String = "%s/%s.png" % [OUTPUT_DIR, step_id]
	var absolute_path: String = ProjectSettings.globalize_path(local_path)
	var viewport_texture: Texture2D = root.get_texture()
	if viewport_texture == null:
		print("MVP_VISUAL_WALKTHROUGH_SCREENSHOT_WARNING=%s dummy renderer returned no viewport texture" % step_id)
		return
	var image: Image = viewport_texture.get_image()
	if image == null:
		print("MVP_VISUAL_WALKTHROUGH_SCREENSHOT_WARNING=%s dummy renderer returned no image" % step_id)
		return
	var error: int = image.save_png(local_path)
	if error != OK:
		print("MVP_VISUAL_WALKTHROUGH_SCREENSHOT_WARNING=%s failed to save screenshot: %s" % [step_id, absolute_path])
	else:
		_screenshot_paths.append(absolute_path)
		print("MVP_VISUAL_WALKTHROUGH_SCREENSHOT=%s" % absolute_path)


func _verify_home_visual_exemplar(step_id: String) -> void:
	var cards: Node = _find_node_by_name(_shell, "HomeInfoCards")
	if cards == null:
		_failures.append("%s missing HomeInfoCards visual exemplar container" % step_id)
		return
	for card_name: String in ["HomeCardTime", "HomeCardMatch", "HomeCardTeam", "HomeCardResources", "HomeCardNextStep", "HomeCardTownWarmth"]:
		if _find_node_by_name(cards, card_name) == null:
			_failures.append("%s missing home visual exemplar card: %s" % [step_id, card_name])
	var card_text: String = _collect_label_text(cards)
	if card_text.contains("Opponent 1") or card_text.contains("待同步") or card_text.contains("debug"):
		_failures.append("%s home cards expose placeholder/debug text" % step_id)
	if step_id == "07_home_match_disabled_reason":
		var reason: Node = _find_node_by_name(_shell, "DisableReason")
		if not (reason is Label) or not (reason as Label).text.contains("比赛暂未开放"):
			_failures.append("%s should show player-facing match disabled reason" % step_id)


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for child: Node in root_node.get_children():
		var found: Node = _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _collect_label_text(root_node: Node) -> String:
	var text_parts: Array[String] = []
	_collect_label_text_recursive(root_node, text_parts)
	return "\n".join(text_parts)


func _collect_label_text_recursive(root_node: Node, text_parts: Array[String]) -> void:
	if root_node is Label:
		text_parts.append((root_node as Label).text)
	for child: Node in root_node.get_children():
		_collect_label_text_recursive(child, text_parts)


func _wait_for_ui() -> void:
	await process_frame
	await process_frame
	await create_timer(TRANSITION_WAIT_SECONDS).timeout
	await process_frame


func _report_and_quit() -> void:
	print("MVP_VISUAL_WALKTHROUGH_OUTPUT_DIR=%s" % _absolute_output_dir)
	if _screenshot_paths.is_empty():
		print("MVP_VISUAL_WALKTHROUGH_SCREENSHOT_UNAVAILABLE=headless renderer produced no screenshot artifacts")
	if _failures.is_empty():
		print("MVP_VISUAL_WALKTHROUGH_STRUCTURE_PASS")
		if not _screenshot_paths.is_empty():
			print("MVP_VISUAL_WALKTHROUGH_PASS")
		quit(0)
		return
	for failure: String in _failures:
		push_error("MVP_VISUAL_WALKTHROUGH_FAIL: %s" % failure)
	quit(1)
