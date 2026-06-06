extends Control
## L2 pre-match/live/result panel mounted by the MainLoop shell.

const ROUTE_MATCH_PRE: String = "match_pre"
const ROUTE_MATCH_LIVE: String = "match_live"
const ROUTE_MATCH_RESULT: String = "match_result"

var _current_route: String = ROUTE_MATCH_PRE
var _time_payload: Dictionary[String, Variant] = {}
var _system_payload: Dictionary[String, Variant] = {}
var _result_payload: Dictionary[String, Variant] = {}
var _league_payload: Dictionary[String, Variant] = {}
var _timeline: Array[String] = []

var _root_box: VBoxContainer = null
var _title_label: Label = null
var _summary_label: Label = null
var _pre_match_start_button: Button = null
var _live_timeline: VBoxContainer = null
var _live_exit_warning: Label = null
var _halftime_adjust_button: Button = null
var _result_confirm_button: Button = null
var _league_impact_summary: Label = null
var _disable_reason_label: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	_subscribe_events()
	_refresh()


func _exit_tree() -> void:
	EventBus.unsubscribe("time_advanced", _on_time_advanced)
	EventBus.unsubscribe("match_event_occurred", _on_match_event_occurred)
	EventBus.unsubscribe("match_completed", _on_match_completed)
	EventBus.unsubscribe("league_standings_updated", _on_league_standings_updated)


## Sets the mounted MatchPerf route without changing match state.
func set_route(route_id: String) -> void:
	_current_route = route_id
	_refresh()


## Applies the latest authoritative time/match-trigger payload.
func set_time_payload(payload: Dictionary[String, Variant]) -> void:
	_time_payload = payload.duplicate(true)
	_refresh()


## Applies the latest authoritative system/navigation affordance payload.
func set_system_payload(payload: Dictionary[String, Variant]) -> void:
	_system_payload = payload.duplicate(true)
	_refresh()


## Applies the latest authoritative match result packet.
func set_result_payload(payload: Dictionary[String, Variant]) -> void:
	_result_payload = payload.duplicate(true)
	_refresh()


## Returns the route currently displayed by this panel.
func get_current_route() -> String:
	return _current_route


func _setup_ui() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	_root_box = VBoxContainer.new()
	_root_box.name = "MatchPerfRoot"
	_root_box.add_theme_constant_override("separation", 12)
	add_child(_root_box)

	_title_label = Label.new()
	_title_label.name = "MatchPerfTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(_title_label)

	_summary_label = Label.new()
	_summary_label.name = "MatchSummary"
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root_box.add_child(_summary_label)

	_disable_reason_label = Label.new()
	_disable_reason_label.name = "MatchDisableReason"
	_disable_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root_box.add_child(_disable_reason_label)

	_pre_match_start_button = Button.new()
	_pre_match_start_button.name = "PreMatchStartButton"
	_pre_match_start_button.focus_mode = Control.FOCUS_ALL
	_pre_match_start_button.pressed.connect(_on_pre_match_start_pressed)
	_root_box.add_child(_pre_match_start_button)

	_live_timeline = VBoxContainer.new()
	_live_timeline.name = "LiveTimeline"
	_live_timeline.add_theme_constant_override("separation", 6)
	_root_box.add_child(_live_timeline)

	_live_exit_warning = Label.new()
	_live_exit_warning.name = "LiveExitWarning"
	_live_exit_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_live_exit_warning.text = "比赛进行中，如需离开请先完成本场比赛。"
	_root_box.add_child(_live_exit_warning)

	_halftime_adjust_button = Button.new()
	_halftime_adjust_button.name = "HalftimeAdjustButton"
	_halftime_adjust_button.text = "中场调整即将开放"
	_halftime_adjust_button.focus_mode = Control.FOCUS_ALL
	_halftime_adjust_button.disabled = true
	_root_box.add_child(_halftime_adjust_button)

	_league_impact_summary = Label.new()
	_league_impact_summary.name = "LeagueImpactSummary"
	_league_impact_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root_box.add_child(_league_impact_summary)

	_result_confirm_button = Button.new()
	_result_confirm_button.name = "ResultConfirmButton"
	_result_confirm_button.text = "返回主界面"
	_result_confirm_button.focus_mode = Control.FOCUS_ALL
	_result_confirm_button.pressed.connect(_on_result_confirm_pressed)
	_root_box.add_child(_result_confirm_button)


func _subscribe_events() -> void:
	EventBus.subscribe("time_advanced", _on_time_advanced)
	EventBus.subscribe("match_event_occurred", _on_match_event_occurred)
	EventBus.subscribe("match_completed", _on_match_completed)
	EventBus.subscribe("league_standings_updated", _on_league_standings_updated)


func _on_time_advanced(_event_name: String, payload: Dictionary) -> void:
	set_time_payload(_to_string_variant_dictionary(payload))


func _on_match_event_occurred(_event_name: String, payload: Dictionary) -> void:
	var event_payload: Dictionary[String, Variant] = _to_string_variant_dictionary(payload)
	_timeline.append(_format_timeline_event(event_payload))
	_refresh()


func _on_match_completed(_event_name: String, payload: Dictionary) -> void:
	set_result_payload(_to_string_variant_dictionary(payload))
	EventBus.emit("screen_requested", {"screen_id": ROUTE_MATCH_RESULT})


func _on_league_standings_updated(_event_name: String, payload: Dictionary) -> void:
	_league_payload = _to_string_variant_dictionary(payload)
	_refresh()


func _refresh() -> void:
	if _root_box == null:
		return
	_pre_match_start_button.visible = false
	_live_timeline.visible = false
	_live_exit_warning.visible = false
	_halftime_adjust_button.visible = false
	_result_confirm_button.visible = false
	_league_impact_summary.visible = false
	_disable_reason_label.visible = false
	match _current_route:
		ROUTE_MATCH_PRE:
			_mount_pre_match()
		ROUTE_MATCH_LIVE:
			_mount_live()
		ROUTE_MATCH_RESULT:
			_mount_result()
		_:
			_mount_pre_match()


func _mount_pre_match() -> void:
	_title_label.text = "比赛准备"
	_summary_label.text = _format_pre_match_summary()
	_pre_match_start_button.visible = true
	_pre_match_start_button.text = "开始比赛"
	_pre_match_start_button.disabled = not _can_start_match()
	_disable_reason_label.visible = not _can_start_match()
	_disable_reason_label.text = _match_disable_reason()


func _mount_live() -> void:
	_title_label.text = "比赛直播"
	_summary_label.text = _format_live_summary()
	_live_timeline.visible = true
	_live_exit_warning.visible = true
	_halftime_adjust_button.visible = true
	_mount_timeline()


func _mount_result() -> void:
	_title_label.text = "比赛结束"
	_summary_label.text = _format_result_summary()
	_mount_timeline()
	_live_timeline.visible = true
	_league_impact_summary.visible = true
	_league_impact_summary.text = _format_league_impact()
	_result_confirm_button.visible = true


func _mount_timeline() -> void:
	_clear_children(_live_timeline)
	if _timeline.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = _timeline_empty_text()
		_live_timeline.add_child(empty_label)
		return
	for index: int in range(_timeline.size() - 1, -1, -1):
		var event_label: Label = Label.new()
		event_label.text = _timeline[index]
		event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_live_timeline.add_child(event_label)


func _on_pre_match_start_pressed() -> void:
	if not _can_start_match():
		_disable_reason_label.visible = true
		_disable_reason_label.text = _match_disable_reason()
		return
	EventBus.emit("screen_requested", {"screen_id": ROUTE_MATCH_LIVE})


func _on_result_confirm_pressed() -> void:
	EventBus.emit("match_result_confirmed", {
		"match_id": str(_result_payload.get("match_id", "")),
		"result": str(_result_payload.get("result", "")),
	})


func _can_start_match() -> bool:
	return bool(_system_payload.get("system_state_allows_match", true)) and bool(_system_payload.get("navigation_context_allows_match", true)) and bool(_time_payload.get("schedule_available", false)) and bool(_time_payload.get("match_trigger_reached", false)) and bool(_time_payload.get("match_center_available", false))


func _match_disable_reason() -> String:
	if not bool(_system_payload.get("system_state_allows_match", true)):
		return str(_system_payload.get("system_state_disable_reason", "当前系统状态不允许进入比赛"))
	if not bool(_system_payload.get("navigation_context_allows_match", true)):
		return str(_system_payload.get("navigation_context_disable_reason", "当前导航上下文不允许进入比赛"))
	if bool(_time_payload.get("schedule_missing", false)) or not bool(_time_payload.get("schedule_available", false)):
		return "赛程尚未公布"
	if not bool(_time_payload.get("match_trigger_reached", false)):
		return "还未到比赛时间"
	if not bool(_time_payload.get("match_center_available", false)):
		return "比赛中心暂不可用"
	return "当前不可开始比赛"


func _format_pre_match_summary() -> String:
	return "对手：%s\n轮次：%s\n主客：%s\n排名摘要：%s\n阵容摘要：%s\n战术摘要：%s" % [
		str(_time_payload.get("opponent_name", "对手待同步")),
		str(_time_payload.get("round", _time_payload.get("current_round", "轮次待同步"))),
		str(_time_payload.get("home_away", _time_payload.get("venue", "主客待同步"))),
		str(_time_payload.get("ranking_summary", "排名待同步")),
		str(_time_payload.get("lineup_summary", "阵容待同步")),
		str(_time_payload.get("tactical_summary", "默认战术")),
	]


func _format_live_summary() -> String:
	return "比分：%s\n时间：%s\n阶段：%s" % [
		str(_time_payload.get("score_display", _result_score_text())),
		str(_time_payload.get("match_time", _time_payload.get("minute", "时间待同步"))),
		str(_time_payload.get("half", _time_payload.get("phase", "半场待同步"))),
	]


func _format_result_summary() -> String:
	return "终场比分：%s\n结果：%s\n原因：%s\n球员表现：%s" % [
		_result_score_text(),
		str(_result_payload.get("result", "结果待同步")),
		str(_result_payload.get("reason", _result_payload.get("result_reason", "原因待同步"))),
		str(_result_payload.get("player_performance_summary", "球员表现待同步")),
	]


func _format_league_impact() -> String:
	if _league_payload.is_empty():
		return "联赛影响待同步"
	return str(_league_payload.get("summary", _league_payload.get("league_impact_summary", "积分榜已按权威结果更新")))


func _result_score_text() -> String:
	var score: Dictionary[String, Variant] = _to_string_variant_dictionary(_result_payload.get("score", {}))
	if score.is_empty():
		return str(_time_payload.get("score_display", "比分待同步"))
	return "%s-%s" % [str(score.get("home", "?")), str(score.get("away", "?"))]


func _format_timeline_event(payload: Dictionary[String, Variant]) -> String:
	return "%s' %s" % [
		str(payload.get("minute", payload.get("time", "--"))),
		str(payload.get("summary", payload.get("event_type", "比赛事件"))),
	]


func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		child.queue_free()


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	var source: Dictionary = value as Dictionary
	for key_variant: Variant in source.keys():
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary
