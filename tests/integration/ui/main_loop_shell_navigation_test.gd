extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	test_main_loop_shell_exposes_frozen_routes_and_mount()
	test_main_loop_shell_routes_screen_requests_inside_single_stack()
	test_main_loop_shell_return_events_reset_to_home()
	test_main_loop_shell_home_uses_actionable_club_summary()
	test_main_loop_shell_match_entry_uses_authoritative_disable_reason()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("MAIN_LOOP_SHELL_NAVIGATION_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_main_loop_shell_exposes_frozen_routes_and_mount() -> void:
	var route_ids: Array = _shell.call("get_route_ids")
	_expect(route_ids == ["home", "roster", "player_detail", "training", "match_pre", "match_live", "match_result"], "shell should expose frozen current-wave route IDs")
	_expect(_shell.call("get_current_route") == "home", "shell should initialize at home")
	var main_content: Variant = _shell.call("get_main_content")
	_expect(main_content is Control, "shell should expose shell_main_content as Control")
	if main_content is Control:
		_expect((main_content as Control).name == "shell_main_content", "main content node should use frozen shell_main_content name")


func test_main_loop_shell_routes_screen_requests_inside_single_stack() -> void:
	EventBus.emit("screen_requested", {"screen_id": "roster"})
	_expect(_shell.call("get_current_route") == "roster", "roster request should route inside shell")
	_expect(ScreenManager.get_active_screen_id() == "roster", "ScreenManager active route should be roster")
	EventBus.emit("screen_requested", {"screen_id": "training"})
	_expect(_shell.call("get_current_route") == "training", "training request should route inside shell")
	_expect(ScreenManager.get_screen_stack_depth() <= 3, "current-wave deepest route should stay within depth 3")


func test_main_loop_shell_return_events_reset_to_home() -> void:
	EventBus.emit("screen_requested", {"screen_id": "match_result"})
	_expect(_shell.call("get_current_route") == "match_result", "match result request should route before confirmation")
	EventBus.emit("match_result_confirmed", {"match_id": "league_r01_m01"})
	_expect(_shell.call("get_current_route") == "home", "match result confirmation should return home")
	_expect(ScreenManager.get_active_screen_id() == "home", "ScreenManager should reset to home after match result confirmation")
	_expect(ScreenManager.get_screen_stack_depth() == 1, "return home should not leave a parallel navigation stack")


func test_main_loop_shell_home_uses_actionable_club_summary() -> void:
	EventBus.emit("time_advanced", {
		"date_display": "Week 1",
		"phase": "PLANNING",
		"available_action_windows": 2,
		"schedule_available": true,
		"match_trigger_reached": false,
		"match_center_available": true,
		"next_match_display": "周末 vs Opponent 1",
		"opponent_name": "Opponent 1",
	})
	EventBus.emit("system_state_changed", {
		"team_overview": "8 人阵容，1 人可重点训练",
		"system_state_allows_match": true,
		"navigation_context_allows_match": true,
	})
	_shell.call("return_home")
	_expect(_find_shell_label_text("RouteTitle") == "俱乐部主页", "home title should be player-facing club home copy")
	var summary_text: String = _find_shell_label_text("RouteSummary")
	_expect(summary_text.contains("建议下一步"), "home summary should show an actionable next step")
	_expect(summary_text.contains("俱乐部概览"), "home summary should show club overview")
	_expect(not summary_text.contains("待同步"), "home summary should not expose debug sync placeholders")
	_expect(not summary_text.contains("见顶部栏"), "home summary should not tell players to see the top bar")
	var primary_button: Button = _find_shell_button("PrimaryAction")
	_expect(primary_button != null and primary_button.text == "查看球员并训练", "non-match home primary CTA should send player toward roster/training")
	_press_shell_button("PrimaryAction")
	_expect(_shell.call("get_current_route") == "roster", "non-match home primary CTA should route to roster")


func test_main_loop_shell_match_entry_uses_authoritative_disable_reason() -> void:
	EventBus.emit("time_advanced", {
		"date_display": "Week 1",
		"phase": "PLANNING",
		"available_action_windows": 2,
		"schedule_available": true,
		"match_trigger_reached": true,
		"match_center_available": true,
		"opponent_name": "Opponent 1",
	})
	EventBus.emit("system_state_changed", {
		"system_state_allows_match": false,
		"system_state_disable_reason": "阵容不合法",
		"navigation_context_allows_match": true,
	})
	_shell.call("return_home")
	_press_shell_button("PrimaryAction")
	_expect(_shell.call("get_current_route") == "home", "disabled match CTA should stay on home")
	_expect(_find_shell_label_text("DisableReason").contains("至少需要 7 名球员"), "disabled match CTA should show player-facing lineup requirement")


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


func _press_shell_button(button_name: String) -> void:
	var button: Button = _find_shell_button(button_name)
	if button == null:
		_failures.append("Shell button not found: %s" % button_name)
		return
	button.pressed.emit()


func _find_shell_button(button_name: String) -> Button:
	if _shell == null:
		return null
	var found: Node = _find_node_by_name(_shell, button_name)
	return found as Button


func _find_shell_label_text(label_name: String) -> String:
	if _shell == null:
		return ""
	var found: Node = _find_node_by_name(_shell, label_name)
	if found is Label:
		return (found as Label).text
	return ""


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
