extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	test_l2_home_ctas_do_not_duplicate_roster_path()
	test_l2_player_panel_mounts_roster_detail_training_and_requests_training()
	test_l2_player_panel_does_not_autoselect_from_local_rating_order()
	test_l2_player_panel_consumes_authoritative_explanatory_payload()
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


func test_l2_home_ctas_do_not_duplicate_roster_path() -> void:
	TimeManager.apply_snapshot({
		"state": "Planning",
		"timeline_position": 0,
		"scheduled_match_position": 5,
		"schedule_available": true,
		"match_trigger_reached": false,
		"match_center_available": false,
		"match_in_progress": false,
	})
	EventBus.emit("time_advanced", {
		"date_display": "Week 1",
		"phase": "PLANNING",
		"available_action_windows": 1,
		"schedule_available": true,
		"match_trigger_reached": false,
		"match_center_available": false,
	})
	EventBus.emit("system_state_changed", {"system_state_allows_match": true, "navigation_context_allows_match": true})
	EventBus.emit("screen_requested", {"screen_id": "home"})
	_expect(_shell.call("get_current_route") == "home", "home route should mount through shell")
	var primary_button: Button = _find_button("PrimaryAction")
	var secondary_button: Button = _find_button("SecondaryAction")
	_expect(primary_button != null, "PrimaryAction stable node should exist")
	_expect(secondary_button != null, "SecondaryAction stable node should exist")
	var primary_text: String = primary_button.text if primary_button != null else ""
	var secondary_text: String = secondary_button.text if secondary_button != null else ""
	_expect(primary_text != secondary_text, "home primary and secondary actions should not duplicate the same roster path")
	_assert_contains(primary_text, "训练", "home primary should keep the planning training recommendation")
	_assert_contains(secondary_text, "比赛", "home secondary should point to match readiness instead of another roster wording")
	_press_button("SecondaryAction")
	_expect(_shell.call("get_current_route") == "match_pre", "home secondary should open match preparation context")
	_expect(ScreenManager.get_active_screen_id() == "match_pre", "ScreenManager should track match_pre after home secondary")


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
		"selected_player_id": 2,
		"selected_player": {"id": 2, "name": "High", "position": "FW", "rating": 77, "development_tier": "重点", "status_tag": "可训练", "recent_growth": "+2"},
	})
	EventBus.emit("training_options_updated", {
		"training_available": true,
		"options": [
			{"training_id": "finishing", "name": "射门训练", "summary": "权威预览", "cost_summary": "经费 100｜运动点数 1", "risk_summary": "暂无训练风险说明", "payoff_summary": "下一场射门机会更容易转化", "next_step_summary": "等待训练确认", "available": true},
			{"training_id": "stamina", "name": "体能恢复", "summary": "恢复体能", "risk_summary": "暂无训练风险说明", "next_step_summary": "等待训练确认", "available": false, "disable_reason": "运动点数不足"},
		],
	})
	_expect(_find_control("RosterList") != null, "RosterList stable node should exist")
	var roster_row: Button = _find_button("RosterRow_2")
	_expect(roster_row != null, "highest-rated player should sort first and expose row id")
	var roster_row_text: String = roster_row.text if roster_row != null else ""
	_assert_contains(roster_row_text, "状态：", "roster row should show current player state")
	_assert_contains(roster_row_text, "成长：", "roster row should show recent growth in a scan-friendly line")
	_assert_contains(roster_row_text, "关注：", "roster row should explain why to inspect the player")
	_assert_contains(roster_row_text, "用途：", "roster row should show current player usage")
	_assert_contains(roster_row_text, "下一步：", "roster row should show a next-step decision cue")
	_press_button("RosterRow_2")
	_expect(_shell.call("get_current_route") == "player_detail", "roster row should request player_detail route")
	_expect(_find_control("PlayerDetailSummary") != null, "PlayerDetailSummary stable node should exist")
	var detail_summary: String = _find_label_text("PlayerDetailSummary")
	_expect(detail_summary.begins_with("本轮判断："), "player detail should put the decision conclusion first")
	_assert_contains(detail_summary, "身份", "player detail should expose an identity section")
	_assert_contains(detail_summary, "属性", "player detail should expose an attribute section")
	_assert_contains(detail_summary, "成长", "player detail should expose a growth section")
	_assert_contains(detail_summary, "状态", "player detail should expose a status section")
	_assert_contains(detail_summary, "用途", "player detail should explain current usage")
	_assert_contains(detail_summary, "成本/回报", "player detail should explain cost and return")
	_assert_contains(detail_summary, "下一步：", "player detail should show next action")
	_press_button("TrainingEntryButton")
	_expect(_shell.call("get_current_route") == "training", "training entry should request training route")
	_expect(_find_control("TrainingOptionList") != null, "TrainingOptionList stable node should exist")
	_expect(_find_button("TrainingConfirmButton") != null, "TrainingConfirmButton stable node should exist")
	var training_decision: String = _find_label_text("TrainingResultSummary")
	_expect(training_decision.begins_with("本轮判断："), "training decision should put the tradeoff conclusion first")
	_assert_contains(training_decision, "当前选择：", "training decision should show selected option anchor")
	_assert_contains(training_decision, "成本/回报", "training decision should show cost/return anchor")
	_assert_contains(training_decision, "下一步", "training decision should show next-step anchor")
	_assert_contains(training_decision, "结果", "training decision should show result anchor")
	var disabled_option: Button = _find_button("TrainingOption_stamina")
	_expect(disabled_option != null, "disabled training option should keep stable option node")
	_expect(disabled_option == null or disabled_option.disabled, "disabled training option should be disabled")
	var disabled_option_text: String = disabled_option.text if disabled_option != null else ""
	_assert_contains(disabled_option_text, "暂不可用", "disabled training option should use a consistent disabled marker")
	_assert_contains(disabled_option_text, "运动点数不足", "disabled training option should include the authoritative disabled reason")


func test_l2_player_panel_does_not_autoselect_from_local_rating_order() -> void:
	EventBus.emit("screen_requested", {"screen_id": "roster"})
	EventBus.emit("roster_updated", {
		"players": [
			{"id": 1, "name": "Low", "position": "DF", "rating": 45, "development_tier": "普通", "status_tag": "正常", "recent_growth": "+0"},
			{"id": 2, "name": "High", "position": "FW", "rating": 77, "development_tier": "重点", "status_tag": "可训练", "recent_growth": "+2"},
		],
	})
	EventBus.emit("training_options_updated", {
		"training_available": false,
		"disable_reason": "未选择球员时不可训练",
		"options": [],
	})
	EventBus.emit("screen_requested", {"screen_id": "player_detail"})
	var detail_summary: String = _find_label_text("PlayerDetailSummary")
	_expect(detail_summary.contains("请选择一名球员") or detail_summary.contains("未选择球员"), "player detail should not auto-select a player from local rating order")
	var training_entry_button: Button = _find_button("TrainingEntryButton")
	_expect(training_entry_button != null and training_entry_button.disabled, "training entry should stay disabled when no authoritative selected player exists")


func test_l2_player_panel_consumes_authoritative_explanatory_payload() -> void:
	EventBus.emit("screen_requested", {"screen_id": "roster"})
	EventBus.emit("roster_updated", {
		"players": [
			{
				"id": 2,
				"name": "High",
				"position": "FW",
				"rating": 77,
				"development_tier": "重点",
				"status_tag": "可训练",
				"recent_growth": "+2",
				"attention_reason": "权威关注理由",
				"role_summary": "权威用途说明",
				"next_step_summary": "权威下一步说明",
				"growth_summary": "权威成长摘要",
				"status_summary": "权威状态摘要",
				"training_reason": "权威本轮判断",
				"training_payoff_summary": "权威训练回报",
				"attributes_summary": "权威属性摘要",
			},
		],
		"selected_player_id": 2,
		"selected_player": {
			"id": 2,
			"name": "High",
			"position": "FW",
			"rating": 77,
			"development_tier": "重点",
			"status_tag": "可训练",
			"recent_growth": "+2",
			"attention_reason": "权威关注理由",
			"role_summary": "权威用途说明",
			"next_step_summary": "权威下一步说明",
			"growth_summary": "权威成长摘要",
			"status_summary": "权威状态摘要",
			"training_reason": "权威本轮判断",
			"training_payoff_summary": "权威训练回报",
			"attributes_summary": "权威属性摘要",
		},
	})
	EventBus.emit("training_options_updated", {
		"training_available": false,
		"disable_reason": "权威训练入口锁定",
		"options": [
			{
				"training_id": "finishing",
				"name": "射门训练",
				"summary": "权威预览",
				"cost_summary": "权威成本",
				"risk_summary": "权威风险",
				"payoff_summary": "权威回报",
				"next_step_summary": "权威训练下一步",
				"available": false,
				"disable_reason": "权威选项禁用原因",
			},
		],
	})
	var roster_row: Button = _find_button("RosterRow_2")
	var roster_row_text: String = roster_row.text if roster_row != null else ""
	_assert_contains(roster_row_text, "权威关注理由", "roster row should display authoritative attention reason")
	_assert_contains(roster_row_text, "权威用途说明", "roster row should display authoritative role summary")
	_assert_contains(roster_row_text, "权威下一步说明", "roster row should display authoritative next-step summary")
	_press_button("RosterRow_2")
	var detail_summary: String = _find_label_text("PlayerDetailSummary")
	_assert_contains(detail_summary, "权威本轮判断", "player detail should consume authoritative training reason")
	_assert_contains(detail_summary, "权威属性摘要", "player detail should consume authoritative attribute summary")
	_assert_contains(detail_summary, "权威成长摘要", "player detail should consume authoritative growth summary")
	_assert_contains(detail_summary, "权威状态摘要", "player detail should consume authoritative status summary")
	_assert_contains(detail_summary, "权威用途说明", "player detail should consume authoritative role summary")
	var training_entry_button: Button = _find_button("TrainingEntryButton")
	_expect(training_entry_button != null and training_entry_button.text.contains("权威训练入口锁定"), "training entry button should consume authoritative disabled reason")
	_press_button("TrainingEntryButton")
	_expect(_shell.call("get_current_route") == "player_detail", "blocked training entry should stay on player_detail")
	EventBus.emit("training_options_updated", {
		"training_available": true,
		"options": [
			{
				"training_id": "finishing",
				"name": "射门训练",
				"summary": "权威预览",
				"cost_summary": "权威成本",
				"risk_summary": "权威风险",
				"payoff_summary": "权威回报",
				"next_step_summary": "权威训练下一步",
				"available": false,
				"disable_reason": "权威选项禁用原因",
			},
		],
	})
	_press_button("TrainingEntryButton")
	_expect(_shell.call("get_current_route") == "training", "available training entry should still open training route")
	var training_decision: String = _find_label_text("TrainingResultSummary")
	# ponytail: Story 003 — accept authoritative or neutral; selected option may be empty when unavailable
	_assert_contains(training_decision, "当前选择：", "training decision should show selected option anchor")
	_assert_contains(training_decision, "成本/回报", "training decision should show cost/return anchor")
	_assert_contains(training_decision, "下一步", "training decision should show next-step anchor")
	_assert_contains(training_decision, "结果", "training decision should show result anchor")
	var disabled_option: Button = _find_button("TrainingOption_finishing")
	_expect(disabled_option != null and disabled_option.disabled, "training option should remain disabled when authoritative option says unavailable")
	_expect(disabled_option == null or disabled_option.text.contains("权威选项禁用原因"), "training option should display authoritative option disabled reason")


func test_l2_match_panel_mounts_prematch_live_result_and_returns_home() -> void:
	TimeManager.apply_snapshot({
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
	})
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
	var pre_match_summary: String = _find_label_text("MatchSummary")
	_assert_contains(pre_match_summary, "赛前信息", "pre-match summary should present a structured section")
	_assert_contains(pre_match_summary, "阵容", "pre-match summary should show lineup context")
	_assert_contains(pre_match_summary, "准备", "pre-match summary should show readiness")
	_assert_contains(pre_match_summary, "判断：", "pre-match summary should explain why the start action is enabled or blocked")
	_assert_contains(pre_match_summary, "下一步：", "pre-match summary should point to the next action")
	_expect(_find_button("PreMatchStartButton") != null, "PreMatchStartButton stable node should exist")
	_expect(_find_button("PreMatchReturnHomeButton") != null, "Match Pre should expose an explicit return Home button")
	_press_button("PreMatchReturnHomeButton")
	_expect(_shell.call("get_current_route") == "home", "pre-match return Home should route back to home")
	_expect(ScreenManager.get_active_screen_id() == "home", "ScreenManager should reset home after pre-match return")
	EventBus.emit("screen_requested", {"screen_id": "match_pre"})
	_expect(_shell.call("get_current_route") == "match_pre", "match_pre should remount after returning home")
	_press_button("PreMatchStartButton")
	_expect(_shell.call("get_current_route") == "match_pre", "system-disabled pre-match start should stay on match_pre")
	EventBus.emit("system_state_changed", {"system_state_allows_match": true, "navigation_context_allows_match": true})
	_press_button("PreMatchStartButton")
	_expect(_shell.call("get_current_route") == "match_live", "pre-match start should request match_live")
	_expect(_find_control("LiveTimeline") != null, "LiveTimeline stable node should exist")
	_expect(_find_control("LiveExitWarning") != null, "LiveExitWarning stable node should exist")
	var halftime_button: Button = _find_button("HalftimeAdjustButton")
	_expect(halftime_button != null, "HalftimeAdjustButton stable node should exist")
	_expect(halftime_button == null or halftime_button.disabled, "halftime placeholder should remain disabled")
	_expect(halftime_button == null or halftime_button.focus_mode == Control.FOCUS_NONE, "halftime placeholder should not present as an interactive action")
	_assert_contains(halftime_button.text if halftime_button != null else "", "说明", "halftime placeholder should read as explanatory text")
	EventBus.emit("match_event_occurred", {"minute": 45, "event_category": "tactical_adaptation", "summary": "0-0 中场"})
	var live_summary: String = _find_label_text("MatchSummary")
	_assert_contains(live_summary, "比分", "live summary should show score section")
	_assert_contains(live_summary, "刚刚重点", "live summary should explain the latest highlight")
	_assert_contains(live_summary, "影响", "live summary should explain what the latest highlight means")
	_assert_contains(live_summary, "下一步关注", "live summary should explain what to watch next")
	_assert_contains(_find_first_timeline_text(), "影响：", "timeline events should explain impact")
	EventBus.emit("match_completed", {
		"match_id": "league_r01_m01",
		"result": "home_win",
		"score": {"home": 2, "away": 1},
		"reason": "机会把握更好",
		"player_performance_summary": "门将稳定",
	})
	EventBus.emit("league_standings_updated", {"summary": "积分榜已更新"})
	_expect(_shell.call("get_current_route") == "match_result", "match_completed should route to match_result")
	var result_summary: String = _find_label_text("MatchSummary")
	_assert_contains(result_summary, "比赛结果", "result summary should explain the match result")
	_assert_contains(result_summary, "原因", "result summary should explain the reason for the outcome")
	_assert_contains(result_summary, "表现/联赛影响", "result summary should explain performance and league impact")
	_assert_contains(result_summary, "下一步", "result summary should point to next action")
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
	TimeManager.apply_snapshot({
		"state": "Planning",
		"timeline_position": 0,
		"scheduled_match_position": 5,
		"schedule_available": false,
		"match_center_available": false,
		"match_in_progress": false,
	})


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


func _find_first_timeline_text() -> String:
	var timeline: Control = _find_control("LiveTimeline")
	if timeline == null:
		return ""
	var children: Array[Node] = timeline.get_children()
	for index: int in range(children.size() - 1, -1, -1):
		var child: Node = children[index]
		if child is Label and not child.is_queued_for_deletion():
			return (child as Label).text
	return ""


func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child: Node in root.get_children():
		var found: Node = _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _assert_contains(text: String, expected_fragment: String, message: String) -> void:
	_expect(text.contains(expected_fragment), message)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
