extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	test_l2_player_panel_mounts_roster_detail_training_and_requests_training()
	test_l2_match_panel_mounts_prematch_live_result_and_returns_home()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("L2_PLAYABLE_LOOP_PANELS_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("L2_PLAYABLE_LOOP_PANELS_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_l2_player_panel_mounts_roster_detail_training_and_requests_training() -> void:
	EventBus.emit("screen_requested", {"screen_id": "roster"})
	_expect(_shell.call("get_current_route") == "roster", "roster route should mount through shell")
	var player_panel: Control = _find_control("PlayerMgmtPanel")
	_expect(player_panel != null and player_panel.visible, "PlayerMgmtPanel should be mounted and visible")
	EventBus.emit("roster_updated", {
		"players": [
			{"id": 1, "name": "Low", "position": "DF", "rating": 45, "development_tier": "普通", "status_tag": "正常", "recent_growth": "+0"},
			{"id": 2, "name": "High", "position": "FW", "rating": 77, "development_tier": "重点", "status_tag": "可训练", "recent_growth": "+2"},
		],
	})
	EventBus.emit("training_options_updated", {
		"training_available": true,
		"options": [
			{"training_id": "finishing", "name": "射门训练", "summary": "权威预览", "available": true},
		],
	})
	_expect(_find_control("RosterList") != null, "RosterList stable node should exist")
	var roster_row: Button = _find_button("RosterRow_2")
	_expect(roster_row != null, "highest-rated player should sort first and expose row id")
	_press_button("RosterRow_2")
	_expect(_shell.call("get_current_route") == "player_detail", "roster row should request player_detail route")
	_expect(_find_control("PlayerDetailSummary") != null, "PlayerDetailSummary stable node should exist")
	_press_button("TrainingEntryButton")
	_expect(_shell.call("get_current_route") == "training", "training entry should request training route")
	_expect(_find_control("TrainingOptionList") != null, "TrainingOptionList stable node should exist")
	_expect(_find_button("TrainingConfirmButton") != null, "TrainingConfirmButton stable node should exist")


func test_l2_match_panel_mounts_prematch_live_result_and_returns_home() -> void:
	EventBus.emit("time_advanced", {
		"date_display": "Week 1",
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
	EventBus.emit("system_state_changed", {"system_state_allows_match": false, "system_state_disable_reason": "阵容不合法", "navigation_context_allows_match": true})
	EventBus.emit("screen_requested", {"screen_id": "match_pre"})
	_expect(_shell.call("get_current_route") == "match_pre", "match_pre should mount through shell")
	_expect(_find_control("MatchPerfPanel") != null, "MatchPerfPanel should be mounted")
	_expect(_find_button("PreMatchStartButton") != null, "PreMatchStartButton stable node should exist")
	_press_button("PreMatchStartButton")
	_expect(_shell.call("get_current_route") == "match_pre", "system-disabled pre-match start should stay on match_pre")
	EventBus.emit("system_state_changed", {"system_state_allows_match": true, "navigation_context_allows_match": true})
	_press_button("PreMatchStartButton")
	_expect(_shell.call("get_current_route") == "match_live", "pre-match start should request match_live")
	_expect(_find_control("LiveTimeline") != null, "LiveTimeline stable node should exist")
	_expect(_find_control("LiveExitWarning") != null, "LiveExitWarning stable node should exist")
	_expect(_find_button("HalftimeAdjustButton") != null, "HalftimeAdjustButton stable node should exist")
	EventBus.emit("match_event_occurred", {"minute": 45, "summary": "0-0 中场"})
	EventBus.emit("match_completed", {
		"match_id": "league_r01_m01",
		"result": "home_win",
		"score": {"home": 2, "away": 1},
		"reason": "机会把握更好",
		"player_performance_summary": "门将稳定",
	})
	EventBus.emit("league_standings_updated", {"summary": "积分榜已更新"})
	_expect(_shell.call("get_current_route") == "match_result", "match_completed should route to match_result")
	_expect(_find_button("ResultConfirmButton") != null, "ResultConfirmButton stable node should exist")
	_expect(_find_control("LeagueImpactSummary") != null, "LeagueImpactSummary stable node should exist")
	_press_button("ResultConfirmButton")
	_expect(_shell.call("get_current_route") == "home", "result confirm should return home")
	_expect(ScreenManager.get_active_screen_id() == "home", "ScreenManager should reset home after result confirm")


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
