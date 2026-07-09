extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	test_player_mgmt_panel_uses_neutral_placeholders_without_authoritative_explanatory_payloads()
	await test_player_mgmt_panel_refresh_preserves_authoritative_explanatory_payloads()
	await test_player_mgmt_panel_stale_selected_player_context_is_cleared()
	test_player_mgmt_panel_does_not_autoselect_player_without_authoritative_selection_context()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("PLAYER_MGMT_AUTHORITATIVE_EXPLANATORY_PAYLOAD_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("PLAYER_MGMT_AUTHORITATIVE_EXPLANATORY_PAYLOAD_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_player_mgmt_panel_uses_neutral_placeholders_without_authoritative_explanatory_payloads() -> void:
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
			},
		],
	})
	EventBus.emit("training_options_updated", {
		"training_available": true,
		"options": [
			{
				"training_id": "finishing",
				"name": "射门训练",
				"available": true,
			},
		],
	})
	var roster_row: Button = _find_button("RosterRow_2")
	var roster_row_text: String = roster_row.text if roster_row != null else ""
	_expect(not roster_row_text.contains("当前评分靠前"), "roster row should not generate local attention advice when payload omits explanatory fields")
	_expect(not roster_row_text.contains("主力候选"), "roster row should not generate local role advice when payload omits explanatory fields")
	_expect(not roster_row_text.contains("进入详情后安排训练"), "roster row should not generate local next-step advice when payload omits explanatory fields")
	_press_button("RosterRow_2")
	var detail_summary: String = _find_label_text("PlayerDetailSummary")
	_expect(not detail_summary.contains("适合加练的窗口"), "detail should not generate local training reason when payload omits explanatory fields")
	_expect(not detail_summary.contains("主力候选"), "detail should not generate local role summary when payload omits explanatory fields")
	_expect(not detail_summary.contains("下一场比赛和赛后表现会承接这次训练"), "detail should not generate local payoff text when payload omits explanatory fields")
	_press_button("TrainingEntryButton")
	var training_summary: String = _find_label_text("TrainingResultSummary")
	_expect(not training_summary.contains("占用本轮训练机会"), "training summary should not generate local risk explanation when payload omits explanatory fields")
	_expect(not training_summary.contains("确认训练后回到主页"), "training summary should not generate local next-step explanation when payload omits explanatory fields")
	_expect(not training_summary.contains("下一场比赛和赛后表现会承接这次训练"), "training summary should not generate local payoff explanation when payload omits explanatory fields")


func test_player_mgmt_panel_refresh_preserves_authoritative_explanatory_payloads() -> void:
	var selected_player: Dictionary = {
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
	}
	EventBus.emit("screen_requested", {"screen_id": "roster"})
	EventBus.emit("roster_updated", {
		"players": [selected_player],
		"selected_player_id": 2,
		"selected_player": selected_player,
	})
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
				"available": true,
			},
		],
	})
	_press_button("RosterRow_2")
	EventBus.emit("training_read_models_requested", {"source": "test"})
	await get_tree().process_frame
	await get_tree().process_frame
	var detail_summary: String = _find_label_text("PlayerDetailSummary")
	_expect(not detail_summary.contains("适合加练的窗口"), "detail should not regress to local training reason after refresh")
	_expect(not detail_summary.contains("主力候选"), "detail should not regress to local role summary after refresh")
	_press_button("TrainingEntryButton")
	var training_summary: String = _find_label_text("TrainingResultSummary")
	print("PLAYER_MGMT_REFRESH_TRAINING_SUMMARY=%s" % training_summary)
	_expect(not training_summary.contains("占用本轮训练机会"), "training summary should not regress to local risk summary after refresh")
	_expect(not training_summary.contains("确认训练后回到主页"), "training summary should not regress to local next-step summary after refresh")
	_expect(not training_summary.contains("下一场比赛和赛后表现会承接这次训练"), "training summary should not regress to local payoff summary after refresh")
	_expect(training_summary.contains("暂无训练风险说明") or training_summary.contains("权威风险"), "training summary should use authoritative or neutral risk text after refresh")
	_expect(training_summary.contains("暂无训练成本摘要") or training_summary.contains("权威成本"), "training summary should use authoritative or neutral cost text after refresh")
	_expect(training_summary.contains("暂无训练回报摘要") or training_summary.contains("权威回报"), "training summary should use authoritative or neutral payoff text after refresh")
	_expect(training_summary.contains("等待训练确认") or training_summary.contains("权威训练下一步") or training_summary.contains("先选择训练项目") or training_summary.contains("请选择训练项目"), "training summary should use authoritative or neutral next-step text after refresh")


func test_player_mgmt_panel_stale_selected_player_context_is_cleared() -> void:
	var selected_player: Dictionary = {
		"id": 2,
		"name": "High",
		"position": "FW",
		"rating": 77,
		"development_tier": "重点",
		"status_tag": "可训练",
		"recent_growth": "+2",
	}
	EventBus.emit("screen_requested", {"screen_id": "roster"})
	EventBus.emit("roster_updated", {
		"players": [selected_player],
		"selected_player_id": 2,
		"selected_player": selected_player,
	})
	_press_button("RosterRow_2")
	EventBus.emit("roster_updated", {
		"players": [selected_player],
	})
	EventBus.emit("screen_requested", {"screen_id": "player_detail"})
	var detail_summary: String = _find_label_text("PlayerDetailSummary")
	_expect(detail_summary.contains("请选择一名球员"), "detail should clear stale selected-player context when refresh omits authoritative selection")


func test_player_mgmt_panel_does_not_autoselect_player_without_authoritative_selection_context() -> void:
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
	_expect(detail_summary.contains("请选择一名球员"), "detail should require authoritative selected-player context instead of silently auto-selecting the top-rated row")
	var training_entry_button: Button = _find_button("TrainingEntryButton")
	_expect(training_entry_button != null and training_entry_button.disabled, "training entry should stay disabled when no authoritative selected player exists")


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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
