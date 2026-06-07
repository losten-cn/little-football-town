extends Control
## L2 pre-match/live/result panel mounted by the MainLoop shell.

const ROUTE_MATCH_PRE: String = "match_pre"
const ROUTE_MATCH_LIVE: String = "match_live"
const ROUTE_MATCH_RESULT: String = "match_result"
const UI_COLOR_TEXT := Color("3A2A1A")
const UI_COLOR_MUTED := Color("6D5A3A")
const UI_COLOR_ACCENT := Color("C76A00")
const UI_COLOR_WARNING := Color("8A4A00")
const UI_COLOR_SURFACE := Color("F5DDA8")
const UI_COLOR_BORDER := Color("C58A3A")

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
	_title_label.add_theme_color_override("font_color", UI_COLOR_ACCENT)
	_title_label.add_theme_font_size_override("font_size", 18)
	_root_box.add_child(_title_label)

	_summary_label = Label.new()
	_summary_label.name = "MatchSummary"
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.add_theme_color_override("font_color", UI_COLOR_TEXT)
	_root_box.add_child(_summary_label)

	_disable_reason_label = Label.new()
	_disable_reason_label.name = "MatchDisableReason"
	_disable_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_disable_reason_label.add_theme_color_override("font_color", UI_COLOR_WARNING)
	_root_box.add_child(_disable_reason_label)

	_pre_match_start_button = Button.new()
	_pre_match_start_button.name = "PreMatchStartButton"
	_pre_match_start_button.focus_mode = Control.FOCUS_ALL
	_apply_town_button_style(_pre_match_start_button, true)
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
	_live_exit_warning.add_theme_color_override("font_color", UI_COLOR_MUTED)
	_root_box.add_child(_live_exit_warning)

	_halftime_adjust_button = Button.new()
	_halftime_adjust_button.name = "HalftimeAdjustButton"
	_halftime_adjust_button.text = _localized_text("MATCH_HALFTIME_SOON", "中场调整将在后续版本开放")
	_halftime_adjust_button.focus_mode = Control.FOCUS_ALL
	_halftime_adjust_button.disabled = true
	_apply_town_button_style(_halftime_adjust_button, false)
	_root_box.add_child(_halftime_adjust_button)

	_league_impact_summary = Label.new()
	_league_impact_summary.name = "LeagueImpactSummary"
	_league_impact_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_league_impact_summary.add_theme_color_override("font_color", UI_COLOR_TEXT)
	_root_box.add_child(_league_impact_summary)

	_result_confirm_button = Button.new()
	_result_confirm_button.name = "ResultConfirmButton"
	_result_confirm_button.text = _localized_text("MATCH_RESULT_RETURN_HOME", "返回主界面")
	_result_confirm_button.focus_mode = Control.FOCUS_ALL
	_apply_town_button_style(_result_confirm_button, true)
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
	return _localized_text(
		"MATCH_PRE_SUMMARY_READABILITY_FORMAT",
		"赛前检查｜联赛第%s轮\n对阵：%s %s\n是否适合开赛：%s\n阵容状态：%s\n当前战术：%s\n下一步：%s"
	) % [
		str(_time_payload.get("round", _time_payload.get("current_round", _localized_text("MATCH_ROUND_PENDING", "本轮")))),
		_player_facing_venue(str(_time_payload.get("home_away", _time_payload.get("venue", "")))),
		_player_facing_opponent_name(str(_time_payload.get("opponent_name", ""))),
		_pre_match_focus_text(),
		_player_facing_lineup_summary(str(_time_payload.get("lineup_summary", ""))),
		str(_time_payload.get("tactical_summary", _localized_text("MATCH_TACTIC_DEFAULT", "均衡"))),
		_pre_match_next_step_text(),
	]


func _format_live_summary() -> String:
	return _localized_text(
		"MATCH_LIVE_SUMMARY_READABILITY_FORMAT",
		"比分：%s\n时间：%s｜阶段：%s\n刚刚重点：%s\n这意味着：%s\n当前操作：%s"
	) % [
		str(_time_payload.get("score_display", _result_score_text())),
		_match_time_text(),
		_match_phase_text(),
		_live_current_focus_text(),
		_live_outlook_text(),
		_live_next_step_text(),
	]


func _format_result_summary() -> String:
	return _localized_text(
		"MATCH_RESULT_SUMMARY_READABILITY_FORMAT",
		"终场比分：%s\n结果：%s\n结果解读：%s\n表现摘要：%s\n下一步：%s"
	) % [
		_result_score_text(),
		_player_facing_result_text(),
		_result_reason_text(),
		_result_player_performance_text(),
		_result_next_step_text(),
	]


func _format_league_impact() -> String:
	var impact_summary: String = ""
	if _league_payload.is_empty():
		impact_summary = _localized_text("MATCH_LEAGUE_IMPACT_PENDING", "积分榜将在赛后更新")
	else:
		impact_summary = str(
			_league_payload.get(
				"summary",
				_league_payload.get(
					"league_impact_summary",
					_localized_text("MATCH_LEAGUE_UPDATED", "积分榜已按权威结果更新")
				)
			)
		)
	return _localized_text(
		"MATCH_LEAGUE_IMPACT_GUIDANCE_FORMAT",
		"联赛影响：%s\n接下来：%s"
	) % [impact_summary, _result_next_step_text()]


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
	var event_data: Dictionary[String, Variant] = _to_string_variant_dictionary(payload.get("event_data", {}))
	var event_category: String = str(payload.get("event_category", event_data.get("category", payload.get("event_type", ""))))
	var side: String = str(event_data.get("side", payload.get("side", "")))
	var minute: String = str(payload.get("minute", payload.get("match_minute", event_data.get("minute", payload.get("time", "--")))))
	var summary: String = str(payload.get("summary", event_data.get("summary", "")))
	if summary.is_empty():
		summary = _player_facing_event_category_text(event_category, side)
	return _localized_text("MATCH_TIMELINE_EVENT_FORMAT", "%s' %s｜影响：%s") % [minute, summary, _event_impact_text(event_category, summary)]


func _match_time_text() -> String:
	if _time_payload.has("match_time"):
		return str(_time_payload.get("match_time"))
	if _time_payload.has("minute"):
		return "%s'" % str(_time_payload.get("minute"))
	return _localized_text("MATCH_TIME_INITIAL", "上半场 0'")


func _match_phase_text() -> String:
	var phase: String = str(_time_payload.get("half", _time_payload.get("phase", "")))
	match phase:
		"MATCH_TRIGGER", "FIRST_HALF", "first_half", "1":
			return _localized_text("MATCH_PHASE_FIRST_HALF", "上半场")
		"HALFTIME", "halftime", "HALFTIME_ADJUSTMENT":
			return _localized_text("MATCH_PHASE_HALFTIME", "中场")
		"SECOND_HALF", "second_half", "2":
			return _localized_text("MATCH_PHASE_SECOND_HALF", "下半场")
		"PLANNING":
			return _localized_text("MATCH_PHASE_PREPARING", "比赛准备")
		"":
			return _localized_text("MATCH_PHASE_FIRST_HALF", "上半场")
		_:
			return phase


func _player_facing_result_text() -> String:
	var result: String = str(_result_payload.get("result", ""))
	var player_team_side: String = _player_team_side()
	match result:
		"home_win", "home_victory":
			return _localized_text("MATCH_RESULT_WIN", "赢下这场") if player_team_side == "home" else _localized_text("MATCH_RESULT_LOSS", "今天失利")
		"away_win", "away_victory":
			return _localized_text("MATCH_RESULT_WIN", "赢下这场") if player_team_side == "away" else _localized_text("MATCH_RESULT_LOSS", "今天失利")
		"win":
			return _localized_text("MATCH_RESULT_WIN", "赢下这场")
		"loss":
			return _localized_text("MATCH_RESULT_LOSS", "今天失利")
		"draw":
			return _localized_text("MATCH_RESULT_DRAW", "本场战平")
		"":
			return _localized_text("MATCH_RESULT_PENDING", "结果整理中")
		_:
			return result


func _pre_match_focus_text() -> String:
	var ranking_summary: String = str(_time_payload.get("ranking_summary", ""))
	if not _can_start_match():
		return _localized_text("MATCH_PRE_FOCUS_BLOCKED", "这场比赛暂未满足开赛条件，先处理下方提示。")
	if ranking_summary.is_empty():
		return _localized_text("MATCH_PRE_FOCUS_DEFAULT", "比赛会按当前阵容与战术自动演算，先确认是否准备就绪。")
	return _localized_text("MATCH_PRE_FOCUS_RANKING_FORMAT", "这场对位参考：%s。比赛会按当前阵容与战术自动演算。") % ranking_summary


func _pre_match_next_step_text() -> String:
	if not _can_start_match():
		return _localized_text("MATCH_PRE_NEXT_STEP_BLOCKED_FORMAT", "先处理：%s") % _match_disable_reason()
	return _localized_text("MATCH_PRE_NEXT_STEP_READY", "确认信息后即可开始比赛")


func _live_current_focus_text() -> String:
	if _timeline.is_empty():
		return _localized_text("MATCH_LIVE_FOCUS_WAITING", "等待第一条关键事件。")
	return _timeline[_timeline.size() - 1]


func _live_outlook_text() -> String:
	if _timeline.is_empty():
		return _localized_text("MATCH_LIVE_OUTLOOK_WAITING", "先看比赛节奏，关键转折会出现在时间线。")
	var latest_event: String = _timeline[_timeline.size() - 1]
	if latest_event.contains("中场"):
		return _localized_text("MATCH_LIVE_OUTLOOK_HALFTIME", "上半场告一段落，先看比分与关键事件再进入下半场。")
	if latest_event.contains("进球"):
		return _localized_text("MATCH_LIVE_OUTLOOK_GOAL", "比分刚变化，这次进球就是当前局势的关键转折。")
	if latest_event.contains("射门"):
		return _localized_text("MATCH_LIVE_OUTLOOK_SHOT", "机会已经出现，接下来要看能否继续转化成比分。")
	if latest_event.contains("防守"):
		return _localized_text("MATCH_LIVE_OUTLOOK_DEFENSE", "防守回合在撑住局面，比赛仍可能被下一次机会改写。")
	if latest_event.contains("体能"):
		return _localized_text("MATCH_LIVE_OUTLOOK_STAMINA", "体能开始影响比赛，后续回合更容易出现转折。")
	if latest_event.contains("战术") or latest_event.contains("节奏"):
		return _localized_text("MATCH_LIVE_OUTLOOK_TACTICAL", "比赛节奏出现变化，继续观察它会不会影响比分。")
	return _localized_text("MATCH_LIVE_OUTLOOK_DEFAULT", "比赛正在推进，下一条关键事件会帮助解释局势。")


func _live_next_step_text() -> String:
	if not _timeline.is_empty() and _timeline[_timeline.size() - 1].contains("中场"):
		return _localized_text("MATCH_LIVE_NEXT_STEP_HALFTIME", "中场调整功能后续开放；现在先看下半场会不会延续这个走势。")
	if _timeline.is_empty():
		return _localized_text("MATCH_LIVE_NEXT_STEP_WAITING", "先继续观看，关键事件会显示在时间线上。")
	return _localized_text("MATCH_LIVE_NEXT_STEP_DEFAULT", "继续关注时间线；赛后结果会引用这些线索来解释输赢。")


func _result_reason_text() -> String:
	var base_reason: String = str(_result_payload.get("reason", _result_payload.get("result_reason", "")))
	if base_reason.is_empty():
		base_reason = _localized_text("MATCH_RESULT_REASON_DEFAULT", "球队执行了本场计划")
	var supporting_tag: String = _first_supporting_result_tag()
	if supporting_tag.is_empty() or base_reason.contains(supporting_tag):
		return base_reason
	return _localized_text("MATCH_RESULT_REASON_WITH_TAG_FORMAT", "%s；补充线索：%s") % [base_reason, supporting_tag]


func _result_player_performance_text() -> String:
	var summary: String = str(_result_payload.get("player_performance_summary", ""))
	if not summary.is_empty():
		return summary
	var performance_tag: String = _first_performance_result_tag()
	if not performance_tag.is_empty():
		return _localized_text("MATCH_RESULT_PLAYER_TAG_FORMAT", "本场额外记录：%s") % performance_tag
	return _localized_text("MATCH_RESULT_PLAYER_DEFAULT", "球员表现摘要将在赛后继续完善")


func _result_next_step_text() -> String:
	var result: String = str(_result_payload.get("result", ""))
	var player_team_side: String = _player_team_side()
	if result == "draw":
		return _localized_text("MATCH_RESULT_NEXT_STEP_DRAW", "返回主界面后，先看球员状态，再准备下一场。")
	if result == "loss":
		return _localized_text("MATCH_RESULT_NEXT_STEP_LOSS", "返回主界面后，先看球员与训练，再准备下一场。")
	if result == "win":
		return _localized_text("MATCH_RESULT_NEXT_STEP_WIN", "返回主界面后，延续这场有效做法，继续推进下一周。")
	if result == "home_win":
		if player_team_side == "home":
			return _localized_text("MATCH_RESULT_NEXT_STEP_WIN", "返回主界面后，延续这场有效做法，继续推进下一周。")
		return _localized_text("MATCH_RESULT_NEXT_STEP_LOSS", "返回主界面后，先看球员与训练，再准备下一场。")
	if result == "away_win":
		if player_team_side == "away":
			return _localized_text("MATCH_RESULT_NEXT_STEP_WIN", "返回主界面后，延续这场有效做法，继续推进下一周。")
		return _localized_text("MATCH_RESULT_NEXT_STEP_LOSS", "返回主界面后，先看球员与训练，再准备下一场。")
	return _localized_text("MATCH_RESULT_NEXT_STEP_DEFAULT", "返回主界面后，继续查看赛后变化并准备下一场。")


func _first_supporting_result_tag() -> String:
	var win_reasons: Array[String] = _to_string_array(_result_payload.get("win_reasons", []))
	for reason: String in win_reasons:
		if not reason.is_empty():
			return reason
	var post_match_tags: Array[String] = _to_string_array(_result_payload.get("post_match_tags", []))
	for tag: String in post_match_tags:
		if not tag.is_empty() and tag != "无":
			return tag
	return ""


func _first_performance_result_tag() -> String:
	var win_reasons: Array[String] = _to_string_array(_result_payload.get("win_reasons", []))
	var post_match_tags: Array[String] = _to_string_array(_result_payload.get("post_match_tags", []))
	for tag: String in post_match_tags:
		if tag.is_empty() or tag == "无":
			continue
		if not win_reasons.has(tag):
			return tag
	return ""


func _player_team_side() -> String:
	var venue: String = str(_time_payload.get("home_away", _time_payload.get("venue", ""))).to_lower()
	if venue == "客场" or venue == "away":
		return "away"
	return "home"


func _event_impact_text(event_category: String, summary: String) -> String:
	match event_category:
		"goal_scored":
			return _localized_text("MATCH_EVENT_IMPACT_GOAL", "比分或士气出现直接转折。")
		"shot_on_goal":
			return _localized_text("MATCH_EVENT_IMPACT_SHOT", "机会已经出现，下一步看能否转化。")
		"key_defense":
			return _localized_text("MATCH_EVENT_IMPACT_DEFENSE", "防守撑住了当前局面。")
		"stamina_decline":
			return _localized_text("MATCH_EVENT_IMPACT_STAMINA", "体能会影响后续回合质量。")
		"tactical_adaptation":
			return _localized_text("MATCH_EVENT_IMPACT_TACTIC", "比赛节奏开始变化。")
	if summary.contains("进球"):
		return _localized_text("MATCH_EVENT_IMPACT_GOAL", "比分或士气出现直接转折。")
	if summary.contains("射门"):
		return _localized_text("MATCH_EVENT_IMPACT_SHOT", "机会已经出现，下一步看能否转化。")
	return _localized_text("MATCH_EVENT_IMPACT_DEFAULT", "这是赛后解读会引用的线索。")


func _player_facing_event_category_text(event_category: String, side: String) -> String:
	var side_text: String = _player_facing_event_side_text(side)
	match event_category:
		"offensive_push":
			return _localized_text("MATCH_EVENT_OFFENSIVE_PUSH_FORMAT", "%s持续压上") % side_text
		"shot_on_goal":
			return _localized_text("MATCH_EVENT_SHOT_ON_GOAL_FORMAT", "%s形成一次射门") % side_text
		"goal_scored":
			return _localized_text("MATCH_EVENT_GOAL_SCORED_FORMAT", "%s取得进球") % side_text
		"key_defense":
			return _localized_text("MATCH_EVENT_KEY_DEFENSE_FORMAT", "%s完成关键防守") % side_text
		"tactical_adaptation":
			return _localized_text("MATCH_EVENT_TACTICAL_ADAPTATION_FORMAT", "%s调整了比赛节奏") % side_text
		"stamina_decline":
			return _localized_text("MATCH_EVENT_STAMINA_DECLINE_FORMAT", "%s体能开始下滑") % side_text
		_:
			return _localized_text("MATCH_EVENT_DEFAULT", "比赛事件")


func _player_facing_event_side_text(side: String) -> String:
	if side.is_empty():
		return _localized_text("MATCH_EVENT_SIDE_GENERIC", "场上")
	var player_team_side: String = _player_team_side()
	if side == player_team_side:
		return _localized_text("MATCH_EVENT_SIDE_OUR", "我方")
	if side == "home" or side == "away":
		return _localized_text("MATCH_EVENT_SIDE_OPPONENT", "对手")
	return side


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


func _town_button_style(is_primary: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UI_COLOR_ACCENT if is_primary else UI_COLOR_SURFACE
	style.border_color = UI_COLOR_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(6.0)
	return style


func _apply_town_button_style(button: Button, is_primary: bool) -> void:
	button.add_theme_stylebox_override("normal", _town_button_style(is_primary))
	button.add_theme_stylebox_override("hover", _town_button_style(true))
	button.add_theme_stylebox_override("pressed", _town_button_style(true))
	button.add_theme_stylebox_override("disabled", _town_button_style(false))
	button.add_theme_color_override("font_color", Color.WHITE if is_primary else UI_COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", UI_COLOR_MUTED)


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized


func _to_string_array(value: Variant) -> Array[String]:
	var strings: Array[String] = []
	if not (value is Array):
		return strings
	for entry: Variant in value as Array:
		strings.append(String(entry))
	return strings


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
