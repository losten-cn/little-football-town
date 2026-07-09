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
	test_main_loop_shell_home_visual_exemplar_cards_are_player_facing()
	test_main_loop_shell_match_entry_uses_authoritative_disable_reason()
	test_main_loop_shell_bottom_match_entry_consumes_authoritative_disabled_state()
	test_main_loop_shell_schedule_missing_blocks_all_match_entries()
	await test_main_loop_shell_preserves_existing_active_route_on_mount()
	await test_main_loop_shell_training_read_model_refresh_preserves_match_lock()
	test_main_loop_shell_consumes_match_entry_state_as_single_authority()
	await test_main_loop_shell_match_entry_state_survives_later_refreshes()
	test_main_loop_shell_home_missing_payload_fields_remain_player_facing()
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
	_expect(summary_text.contains("现在该做什么"), "home summary should frame the player-facing next-step purpose")
	_expect(not summary_text.contains("待同步"), "home summary should not expose debug sync placeholders")
	_expect(not summary_text.contains("见顶部栏"), "home summary should not tell players to see the top bar")
	var primary_button: Button = _find_shell_button("PrimaryAction")
	_expect(primary_button != null and primary_button.text == "查看球员并训练", "non-match home primary CTA should send player toward roster/training")
	_press_shell_button("PrimaryAction")
	_expect(_shell.call("get_current_route") == "roster", "non-match home primary CTA should route to roster")


func test_main_loop_shell_home_visual_exemplar_cards_are_player_facing() -> void:
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
		"funds": 1200,
		"ap": 2,
		"town_anchor_summary": "训练场很热闹",
		"system_state_allows_match": true,
		"navigation_context_allows_match": true,
	})
	_shell.call("return_home")
	_expect(_find_node_by_name(_shell, "HomeInfoCards") != null, "home should expose a visual exemplar card container")
	_expect(_find_node_by_name(_shell, "HomeCardTime") != null, "home should show current date and phase card")
	_expect(_find_node_by_name(_shell, "HomeCardMatch") != null, "home should show next match card")
	_expect(_find_node_by_name(_shell, "HomeCardTeam") != null, "home should show team overview card")
	_expect(_find_node_by_name(_shell, "HomeCardResources") != null, "home should show resources and action windows card")
	_expect(_find_node_by_name(_shell, "HomeCardNextStep") != null, "home should show next-step card")
	_expect(_find_node_by_name(_shell, "HomeCardTownWarmth") != null, "home should show town warmth card")
	var card_text: String = _collect_label_text(_find_node_by_name(_shell, "HomeInfoCards"))
	_expect(card_text.contains("建议下一步"), "home cards should include an actionable next step")
	_expect(card_text.contains("俱乐部概览") or card_text.contains("球队概览"), "home cards should include club/team overview")
	_expect(card_text.contains("资源"), "home cards should include resource summary")
	_expect(card_text.contains("小镇"), "home cards should include warm-town framing")
	_expect(not card_text.contains("Opponent 1"), "home cards should not expose placeholder opponent IDs")
	_expect(not card_text.contains("待同步"), "home cards should not expose sync placeholders")
	_expect(not card_text.contains("debug"), "home cards should not expose debug labels")


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


func test_main_loop_shell_bottom_match_entry_consumes_authoritative_disabled_state() -> void:
	EventBus.emit("time_advanced", {
		"date_display": "Week 1 Match Day",
		"phase": "MATCH_TRIGGER",
		"available_action_windows": 0,
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
	var match_button: Button = _find_node_by_name(_hud, "MatchButton") as Button
	_expect(match_button != null, "bottom Match button should exist")
	_expect(match_button == null or match_button.disabled, "bottom Match button should respect authoritative system-disabled state")
	_expect(match_button == null or match_button.focus_mode == Control.FOCUS_NONE, "bottom disabled Match button should not present as an active keyboard target")
	_expect(match_button == null or match_button.tooltip_text.contains("比赛暂未开放"), "bottom disabled Match button should explain that Home has the reason")


func test_main_loop_shell_schedule_missing_blocks_all_match_entries() -> void:
	EventBus.emit("time_advanced", {
		"date_display": "Week 1 Match Day",
		"phase": "MATCH_TRIGGER",
		"available_action_windows": 0,
		"schedule_available": true,
		"schedule_missing": true,
		"match_trigger_reached": true,
		"match_center_available": true,
	})
	EventBus.emit("system_state_changed", {
		"system_state_allows_match": true,
		"navigation_context_allows_match": true,
	})
	_shell.call("return_home")
	_press_shell_button("PrimaryAction")
	_expect(_shell.call("get_current_route") == "home", "Home primary action should not enter match when authoritative schedule is missing")
	_expect(_find_shell_label_text("DisableReason").contains("赛程尚未公布"), "Home should explain missing schedule instead of entering match")
	var match_button: Button = _find_node_by_name(_hud, "MatchButton") as Button
	_expect(match_button != null and match_button.disabled, "bottom Match button should also stay disabled when schedule_missing is true")


func test_main_loop_shell_preserves_existing_active_route_on_mount() -> void:
	_teardown_hud()
	await get_tree().process_frame
	ScreenManager.reset_to_screen("roster")
	_hud = HudScene.instantiate() as CanvasLayer
	add_child(_hud)
	_shell = _hud.get_node("MainLoopShell") as Control
	await get_tree().process_frame
	_expect(_shell.call("get_current_route") == "roster", "shell mount should preserve existing ScreenManager active route instead of forcing Home")
	_expect(ScreenManager.get_active_screen_id() == "roster", "shell mount should not reset the active screen stack")


func test_main_loop_shell_training_read_model_refresh_preserves_match_lock() -> void:
	EventBus.emit("time_advanced", {
		"date_display": "Week 1 Match Day",
		"phase": "MATCH_TRIGGER",
		"available_action_windows": 0,
		"schedule_available": true,
		"schedule_missing": false,
		"match_trigger_reached": true,
		"match_center_available": true,
	})
	EventBus.emit("system_state_changed", {
		"system_state_allows_match": false,
		"system_state_disable_reason": "阵容不合法",
		"navigation_context_allows_match": true,
	})
	_shell.call("return_home")
	EventBus.emit("training_read_models_requested", {"source": "test"})
	await get_tree().process_frame
	await get_tree().process_frame
	_press_shell_button("PrimaryAction")
	_expect(_shell.call("get_current_route") == "home", "training read-model refresh should not overwrite authoritative match lock")
	_expect(_find_shell_label_text("DisableReason").contains("至少需要 7 名球员"), "match lock reason should survive training read-model refresh")


func test_main_loop_shell_consumes_match_entry_state_as_single_authority() -> void:
	EventBus.emit("time_advanced", {
		"date_display": "Week 1 Match Day",
		"phase": "MATCH_TRIGGER",
		"available_action_windows": 0,
		"schedule_available": true,
		"schedule_missing": false,
		"match_trigger_reached": true,
		"match_center_available": true,
	})
	EventBus.emit("system_state_changed", {
		"system_state_allows_match": true,
		"navigation_context_allows_match": true,
	})
	EventBus.emit("match_entry_state_changed", {
		"available": false,
		"disabled_reason": "权威比赛入口锁定",
		"available_text": "比赛可进入",
		"unavailable_text": "权威入口暂未开放",
	})
	_shell.call("return_home")
	_press_shell_button("PrimaryAction")
	_expect(_shell.call("get_current_route") == "home", "Home should obey match_entry_state even when raw gate fields look open")
	_expect(_find_shell_label_text("DisableReason").contains("权威比赛入口锁定"), "Home should show match_entry_state disabled reason")
	var match_button: Button = _find_node_by_name(_hud, "MatchButton") as Button
	_expect(match_button != null and match_button.disabled, "bottom Match button should obey match_entry_state availability")
	_expect(match_button == null or match_button.tooltip_text.contains("权威入口暂未开放"), "bottom Match tooltip should use match_entry_state unavailable text")


func test_main_loop_shell_match_entry_state_survives_later_refreshes() -> void:
	EventBus.emit("match_entry_state_changed", {
		"available": false,
		"disabled_reason": "权威入口保持锁定",
		"available_text": "比赛可进入",
		"unavailable_text": "权威入口仍未开放",
	})
	EventBus.emit("training_read_models_requested", {"source": "test"})
	await get_tree().process_frame
	await get_tree().process_frame
	_shell.call("return_home")
	_press_shell_button("PrimaryAction")
	_expect(_shell.call("get_current_route") == "home", "read-model refreshes should not overwrite authoritative match_entry_state lock")
	_expect(_find_shell_label_text("DisableReason").contains("权威入口保持锁定"), "Home should retain match_entry_state reason after read-model refreshes")
	var match_button: Button = _find_node_by_name(_hud, "MatchButton") as Button
	_expect(match_button != null and match_button.disabled, "bottom Match should remain disabled after read-model refreshes")
	_expect(match_button == null or match_button.tooltip_text.contains("权威入口仍未开放"), "bottom Match tooltip should retain match_entry_state text after read-model refreshes")


func test_main_loop_shell_home_missing_payload_fields_remain_player_facing() -> void:
	EventBus.emit("time_advanced", {
		"date_display": "Week 1",
		"phase": "PLANNING",
		"schedule_available": false,
		"schedule_missing": true,
		"match_trigger_reached": false,
		"match_center_available": false,
	})
	EventBus.emit("system_state_changed", {})
	_shell.call("return_home")
	var primary_button: Button = _find_shell_button("PrimaryAction")
	var secondary_button: Button = _find_shell_button("SecondaryAction")
	var card_text: String = _collect_label_text(_find_node_by_name(_shell, "HomeInfoCards"))
	_expect(primary_button != null and primary_button.visible and not primary_button.disabled, "Home primary CTA should remain visible with partial payloads")
	_expect(secondary_button != null and secondary_button.visible and not secondary_button.disabled, "Home secondary CTA should remain visible with partial payloads")
	_expect(not card_text.contains("Opponent 1"), "partial Home payload should not expose placeholder opponent IDs")
	_expect(not card_text.contains("debug"), "partial Home payload should not expose debug labels")
	_expect(not card_text.contains("<null>"), "partial Home payload should not expose null placeholders")


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
	if root == null:
		return null
	if root.name == node_name:
		return root
	for child: Node in root.get_children():
		var found: Node = _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _collect_label_text(root: Node) -> String:
	if root == null:
		return ""
	var text_parts: Array[String] = []
	_collect_label_text_recursive(root, text_parts)
	return "\n".join(text_parts)


func _collect_label_text_recursive(root: Node, text_parts: Array[String]) -> void:
	if root is Label:
		text_parts.append((root as Label).text)
	for child: Node in root.get_children():
		_collect_label_text_recursive(child, text_parts)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
