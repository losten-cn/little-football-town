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
	_root_box.anchor_left = 0.0
	_root_box.anchor_top = 0.0
	_root_box.anchor_right = 1.0
	_root_box.anchor_bottom = 1.0
	_root_box.offset_left = 0.0
	_root_box.offset_top = 0.0
	_root_box.offset_right = 0.0
	_root_box.offset_bottom = 0.0
	_root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	_live_exit_warning.text = _localized_text("MATCH_LIVE_EXIT_WARNING", "比赛进行中，如需离开请先完成本场比赛。")
	_root_box.add_child(_live_exit_warning)

	_halftime_adjust_button = Button.new()
	_halftime_adjust_button.name = "HalftimeAdjustButton"
	_halftime_adjust_button.text = _localized_text("MATCH_HALFTIME_SOON", "中场调整将在后续版本开放")
	_halftime_adjust_button.focus_mode = Control.FOCUS_ALL
	_halftime_adjust_button.disabled = true
	_root_box.add_child(_halftime_adjust_button)

	_league_impact_summary = Label.new()
	_league_impact_summary.name = "LeagueImpactSummary"
	_league_impact_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root_box.add_child(_league_impact_summary)

	_result_confirm_button = Button.new()
	_result_confirm_button.name = "ResultConfirmButton"
	_result_confirm_button.text = _localized_text("MATCH_RESULT_RETURN_HOME", "返回主界面")
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
	_title_label.text = _localized_text("MATCH_PRE_TITLE", "比赛准备")
	_summary_label.text = _format_pre_match_summary()
	_pre_match_start_button.visible = true
	_pre_match_start_button.text = _localized_text("MATCH_PRE_START", "开始比赛")
	_pre_match_start_button.disabled = not _can_start_match()
	_disable_reason_label.visible = not _can_start_match()
	_disable_reason_label.text = _match_disable_reason()


func _mount_live() -> void:
	_title_label.text = _localized_text("MATCH_LIVE_TITLE", "比赛直播")
	_summary_label.text = _format_live_summary()
	_live_timeline.visible = true
	_live_exit_warning.visible = true
	_halftime_adjust_button.visible = true
	_mount_timeline()


func _mount_result() -> void:
	_title_label.text = _localized_text("MATCH_RESULT_TITLE", "比赛结束")
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
		return _player_facing_disable_reason(str(_system_payload.get("system_state_disable_reason", _localized_text("MATCH_DISABLED_SYSTEM", "当前系统状态不允许进入比赛"))))
	if not bool(_system_payload.get("navigation_context_allows_match", true)):
		return _player_facing_disable_reason(str(_system_payload.get("navigation_context_disable_reason", _localized_text("MATCH_DISABLED_NAV", "当前导航上下文不允许进入比赛"))))
	if bool(_time_payload.get("schedule_missing", false)) or not bool(_time_payload.get("schedule_available", false)):
		return _localized_text("MATCH_DISABLED_SCHEDULE_MISSING", "赛程尚未公布")
	if not bool(_time_payload.get("match_trigger_reached", false)):
		return _localized_text("MATCH_DISABLED_TIME", "还未到比赛时间")
	if not bool(_time_payload.get("match_center_available", false)):
		return _localized_text("MATCH_DISABLED_CENTER", "比赛中心暂不可用")
	return _localized_text("MATCH_DISABLED_DEFAULT", "当前不可开始比赛")


func _format_pre_match_summary() -> String:
	return _localized_text("MATCH_PRE_SUMMARY_FORMAT", "联赛第%s轮\n%s %s\n排名对比：%s\n阵容状态：%s\n当前战术：%s") % [
		str(_time_payload.get("round", _time_payload.get("current_round", _localized_text("MATCH_ROUND_PENDING", "本轮")))),
		_player_facing_venue(str(_time_payload.get("home_away", _time_payload.get("venue", "")))),
		_player_facing_opponent_name(str(_time_payload.get("opponent_name", ""))),
		str(_time_payload.get("ranking_summary", _localized_text("MATCH_RANKING_PENDING", "排名稍后公布"))),
		_player_facing_lineup_summary(str(_time_payload.get("lineup_summary", ""))),
		str(_time_payload.get("tactical_summary", _localized_text("MATCH_TACTIC_DEFAULT", "均衡"))),
	]


func _format_live_summary() -> String:
	return _localized_text("MATCH_LIVE_SUMMARY_FORMAT", "比分：%s\n时间：%s\n阶段：%s") % [
		str(_time_payload.get("score_display", _result_score_text())),
		_match_time_text(),
		_match_phase_text(),
	]


func _format_result_summary() -> String:
	return _localized_text("MATCH_RESULT_SUMMARY_FORMAT", "终场比分：%s\n结果：%s\n关键原因：%s\n球员表现：%s") % [
		_result_score_text(),
		_player_facing_result_text(),
		str(_result_payload.get("reason", _result_payload.get("result_reason", _localized_text("MATCH_RESULT_REASON_DEFAULT", "球队执行了本场计划")))),
		str(_result_payload.get("player_performance_summary", _localized_text("MATCH_RESULT_PLAYER_DEFAULT", "球员表现摘要将在赛后继续完善"))),
	]


func _format_league_impact() -> String:
	if _league_payload.is_empty():
		return _localized_text("MATCH_LEAGUE_IMPACT_PENDING", "联赛影响：积分榜将在赛后更新")
	return str(_league_payload.get("summary", _league_payload.get("league_impact_summary", _localized_text("MATCH_LEAGUE_UPDATED", "积分榜已按权威结果更新"))))


func _result_score_text() -> String:
	var score: Dictionary[String, Variant] = _to_string_variant_dictionary(_result_payload.get("score", {}))
	if score.is_empty():
		return str(_time_payload.get("score_display", _localized_text("MATCH_SCORE_INITIAL", "0 : 0")))
	return "%s : %s" % [str(score.get("home", "?")), str(score.get("away", "?"))]


func _timeline_empty_text() -> String:
	if _current_route == ROUTE_MATCH_LIVE:
		return _localized_text("MATCH_TIMELINE_EMPTY_LIVE", "比赛正在推进，暂无关键事件。")
	return _localized_text("MATCH_TIMELINE_EMPTY_RESULT", "本场关键事件将在这里回顾。")


func _format_timeline_event(payload: Dictionary[String, Variant]) -> String:
	return _localized_text("MATCH_TIMELINE_EVENT_FORMAT", "%s' %s") % [
		str(payload.get("minute", payload.get("time", "--"))),
		str(payload.get("summary", payload.get("event_type", _localized_text("MATCH_EVENT_DEFAULT", "比赛事件")))),
	]


func _match_time_text() -> String:
	if _time_payload.has("match_time"):
		return str(_time_payload.get("match_time"))
	if _time_payload.has("minute"):
		return "%s'" % str(_time_payload.get("minute"))
	return _localized_text("MATCH_TIME_INITIAL", "上半场 0'")


func _match_phase_text() -> String:
	var phase: String = str(_time_payload.get("half", _time_payload.get("phase", "")))
	match phase:
		"MATCH_TRIGGER":
			return _localized_text("MATCH_PHASE_FIRST_HALF", "上半场")
		"PLANNING":
			return _localized_text("MATCH_PHASE_PREPARING", "比赛准备")
		"":
			return _localized_text("MATCH_PHASE_FIRST_HALF", "上半场")
		_:
			return phase


func _player_facing_result_text() -> String:
	var result: String = str(_result_payload.get("result", ""))
	match result:
		"home_win", "win", "home_victory":
			return _localized_text("MATCH_RESULT_WIN", "赢下这场")
		"away_win", "loss", "away_victory":
			return _localized_text("MATCH_RESULT_LOSS", "今天失利")
		"draw":
			return _localized_text("MATCH_RESULT_DRAW", "本场战平")
		"":
			return _localized_text("MATCH_RESULT_PENDING", "结果整理中")
		_:
			return result


func _player_facing_disable_reason(reason: String) -> String:
	if reason.is_empty():
		return _localized_text("MATCH_DISABLED_DEFAULT", "当前不可开始比赛")
	if reason == "阵容不合法" or reason.contains("阵容不合法"):
		return _localized_text("MATCH_DISABLED_LINEUP_INCOMPLETE", "阵容不完整——至少需要 7 名球员和 1 名守门员")
	return reason


func _player_facing_opponent_name(opponent_name: String) -> String:
	if opponent_name.is_empty() or opponent_name.begins_with("Opponent"):
		return _localized_text("MATCH_OPPONENT_PENDING", "本轮对手待公布")
	return opponent_name


func _player_facing_venue(venue: String) -> String:
	if venue == "主场":
		return _localized_text("MATCH_VENUE_HOME", "主场迎战")
	if venue == "客场":
		return _localized_text("MATCH_VENUE_AWAY", "客场挑战")
	if venue.is_empty():
		return _localized_text("MATCH_VENUE_PENDING", "比赛地点待公布")
	return venue


func _player_facing_lineup_summary(lineup_summary: String) -> String:
	if lineup_summary.is_empty():
		return _localized_text("MATCH_LINEUP_READY_DEFAULT", "推荐阵容待确认")
	if lineup_summary == "阵容不合法" or lineup_summary.contains("阵容不合法"):
		return _localized_text("MATCH_DISABLED_LINEUP_INCOMPLETE", "阵容不完整——至少需要 7 名球员和 1 名守门员")
	return lineup_summary


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized


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
