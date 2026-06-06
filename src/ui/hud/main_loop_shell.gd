extends Control
## Owns the L1 main-loop route container and placeholder page mounting contract.

const ROUTE_HOME: String = "home"
const ROUTE_ROSTER: String = "roster"
const ROUTE_PLAYER_DETAIL: String = "player_detail"
const ROUTE_TRAINING: String = "training"
const ROUTE_MATCH_PRE: String = "match_pre"
const ROUTE_MATCH_LIVE: String = "match_live"
const ROUTE_MATCH_RESULT: String = "match_result"
const PlayerMgmtPanelScript: Script = preload("res://src/ui/player/player_mgmt_panel.gd")
const MatchPerfPanelScript: Script = preload("res://src/ui/match/match_perf_panel.gd")
const WhatNextGuidanceScript: Script = preload("res://src/ui/onboarding/what_next_guidance.gd")
const ROUTE_IDS: Array[String] = [
	ROUTE_HOME,
	ROUTE_ROSTER,
	ROUTE_PLAYER_DETAIL,
	ROUTE_TRAINING,
	ROUTE_MATCH_PRE,
	ROUTE_MATCH_LIVE,
	ROUTE_MATCH_RESULT,
]
const TOP_BAR_HEIGHT: int = 48
const BOTTOM_BAR_HEIGHT: int = 56
const TRANSITION_SECONDS: float = 0.2

var _current_route: String = ROUTE_HOME
var _content_panel: PanelContainer = null
var _content_margin: MarginContainer = null
var _content_box: VBoxContainer = null
var _title_label: Label = null
var _summary_label: Label = null
var _disable_reason_label: Label = null
var _primary_button: Button = null
var _secondary_button: Button = null
var _last_time_payload: Dictionary[String, Variant] = {}
var _last_system_payload: Dictionary[String, Variant] = {}
var _last_player_action_payload: Dictionary[String, Variant] = {}
var _player_panel: Control = null
var _match_panel: Control = null
var _guidance_panel: Control = null
var _transition_tween: Tween = null


func _ready() -> void:
	name = "MainLoopShell"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_container()
	_subscribe_events()
	ScreenManager.reset_to_screen(ROUTE_HOME)
	_mount_route(ROUTE_HOME)
	_request_authoritative_refresh()


func _exit_tree() -> void:
	EventBus.unsubscribe("screen_requested", _on_screen_requested)
	EventBus.unsubscribe("screen_pushed", _on_screen_changed)
	EventBus.unsubscribe("screen_popped", _on_screen_changed)
	EventBus.unsubscribe("screen_stack_reset", _on_screen_changed)
	EventBus.unsubscribe("time_advanced", _on_time_advanced)
	EventBus.unsubscribe("system_state_changed", _on_system_state_changed)
	EventBus.unsubscribe("player_action_completed", _on_player_action_completed)
	EventBus.unsubscribe("training_cancelled", _on_return_home_requested)
	EventBus.unsubscribe("roster_cancelled", _on_return_home_requested)
	EventBus.unsubscribe("match_result_confirmed", _on_return_home_requested)


## Returns the current frozen route ID mounted in shell_main_content.
func get_current_route() -> String:
	return _current_route


## Returns the route IDs supported by the L1 shell contract.
func get_route_ids() -> Array[String]:
	return ROUTE_IDS.duplicate()


## Returns the single L2 page mount container.
func get_main_content() -> Control:
	return _content_panel


## Routes to a supported screen inside the L1 shell.
func route_to(route_id: String) -> bool:
	if not _is_supported_route(route_id):
		_show_disable_reason("未知页面：%s" % route_id)
		return false
	if route_id == _current_route:
		return true
	if route_id == ROUTE_HOME:
		ScreenManager.reset_to_screen(ROUTE_HOME)
	else:
		ScreenManager.push_screen(route_id)
	_mount_route(route_id)
	_update_guidance_route(route_id)
	return true


## Returns to Home without creating a parallel navigation stack.
func return_home() -> void:
	ScreenManager.reset_to_screen(ROUTE_HOME)
	_mount_route(ROUTE_HOME)


func _setup_container() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0

	_content_panel = PanelContainer.new()
	_content_panel.name = "shell_main_content"
	_content_panel.unique_name_in_owner = true
	_content_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_content_panel.anchor_left = 0.0
	_content_panel.anchor_top = 0.0
	_content_panel.anchor_right = 1.0
	_content_panel.anchor_bottom = 1.0
	_content_panel.offset_left = 16.0
	_content_panel.offset_top = TOP_BAR_HEIGHT + 16.0
	_content_panel.offset_right = -16.0
	_content_panel.offset_bottom = -(BOTTOM_BAR_HEIGHT + 16.0)
	add_child(_content_panel)

	_content_margin = MarginContainer.new()
	_content_margin.name = "ContentMargin"
	_content_margin.add_theme_constant_override("margin_left", 24)
	_content_margin.add_theme_constant_override("margin_top", 24)
	_content_margin.add_theme_constant_override("margin_right", 24)
	_content_margin.add_theme_constant_override("margin_bottom", 24)
	_content_panel.add_child(_content_margin)

	_content_box = VBoxContainer.new()
	_content_box.name = "ContentBox"
	_content_box.add_theme_constant_override("separation", 16)
	_content_margin.add_child(_content_box)

	_title_label = Label.new()
	_title_label.name = "RouteTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_box.add_child(_title_label)

	_summary_label = Label.new()
	_summary_label.name = "RouteSummary"
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_box.add_child(_summary_label)

	_disable_reason_label = Label.new()
	_disable_reason_label.name = "DisableReason"
	_disable_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_disable_reason_label.visible = false
	_content_box.add_child(_disable_reason_label)

	_primary_button = Button.new()
	_primary_button.name = "PrimaryAction"
	_primary_button.focus_mode = Control.FOCUS_ALL
	_primary_button.pressed.connect(_on_primary_action_pressed)
	_content_box.add_child(_primary_button)

	_secondary_button = Button.new()
	_secondary_button.name = "SecondaryAction"
	_secondary_button.focus_mode = Control.FOCUS_ALL
	_secondary_button.pressed.connect(_on_secondary_action_pressed)
	_content_box.add_child(_secondary_button)

	_guidance_panel = WhatNextGuidanceScript.new() as Control
	_guidance_panel.name = "WhatNextGuidance"
	_content_box.add_child(_guidance_panel)


func _subscribe_events() -> void:
	EventBus.subscribe("screen_requested", _on_screen_requested)
	EventBus.subscribe("screen_pushed", _on_screen_changed)
	EventBus.subscribe("screen_popped", _on_screen_changed)
	EventBus.subscribe("screen_stack_reset", _on_screen_changed)
	EventBus.subscribe("time_advanced", _on_time_advanced)
	EventBus.subscribe("system_state_changed", _on_system_state_changed)
	EventBus.subscribe("player_action_completed", _on_player_action_completed)
	EventBus.subscribe("training_cancelled", _on_return_home_requested)
	EventBus.subscribe("roster_cancelled", _on_return_home_requested)
	EventBus.subscribe("match_result_confirmed", _on_return_home_requested)


func _request_authoritative_refresh() -> void:
	if TimeManager != null and TimeManager.has_method("request_refresh"):
		TimeManager.call("request_refresh")


func _on_screen_requested(_event_name: String, payload: Dictionary) -> void:
	var route_id: String = str(payload.get("screen_id", ""))
	if route_id == "schedule":
		_show_disable_reason("完整赛程页不在当前 MVP 范围内")
		return
	route_to(route_id)


func _on_screen_changed(_event_name: String, _payload: Dictionary) -> void:
	var active_route: String = ScreenManager.get_active_screen_id()
	if _is_supported_route(active_route) and active_route != _current_route:
		_mount_route(active_route)


func _on_time_advanced(_event_name: String, payload: Dictionary) -> void:
	_last_time_payload = _to_string_variant_dictionary(payload)
	if _match_panel != null:
		_match_panel.call("set_time_payload", _last_time_payload)
	if _guidance_panel != null:
		_guidance_panel.call("set_time_payload", _last_time_payload)
	if _current_route == ROUTE_HOME:
		_mount_home()


func _on_system_state_changed(_event_name: String, payload: Dictionary) -> void:
	_last_system_payload = _to_string_variant_dictionary(payload)
	if _match_panel != null:
		_match_panel.call("set_system_payload", _last_system_payload)
	if _current_route == ROUTE_HOME:
		_mount_home()


func _on_player_action_completed(_event_name: String, payload: Dictionary) -> void:
	_last_player_action_payload = _to_string_variant_dictionary(payload)
	return_home()


func _on_return_home_requested(_event_name: String, _payload: Dictionary) -> void:
	return_home()


func _mount_route(route_id: String) -> void:
	_current_route = route_id
	_clear_disable_reason()
	_play_transition()
	match route_id:
		ROUTE_HOME:
			_mount_home()
		ROUTE_ROSTER, ROUTE_PLAYER_DETAIL, ROUTE_TRAINING:
			_mount_player_panel(route_id)
		ROUTE_MATCH_PRE, ROUTE_MATCH_LIVE, ROUTE_MATCH_RESULT:
			_mount_match_panel(route_id)


func _mount_home() -> void:
	_update_guidance_route(ROUTE_HOME)
	_set_shell_chrome_visible(true)
	_set_l2_panels_visible(false, false)
	_title_label.text = "Home"
	_summary_label.text = _build_home_summary_text()
	_primary_button.text = _primary_home_action_text()
	_primary_button.disabled = false
	_primary_button.visible = true
	_secondary_button.text = "球员 / 训练"
	_secondary_button.disabled = false
	_secondary_button.visible = true


func _mount_player_panel(route_id: String) -> void:
	_update_guidance_route(route_id)
	_set_shell_chrome_visible(false)
	_ensure_player_panel()
	_set_l2_panels_visible(true, false)
	_player_panel.call("set_route", route_id)


func _mount_match_panel(route_id: String) -> void:
	_update_guidance_route(route_id)
	_set_shell_chrome_visible(false)
	_ensure_match_panel()
	_set_l2_panels_visible(false, true)
	_match_panel.call("set_route", route_id)
	if not _last_time_payload.is_empty():
		_match_panel.call("set_time_payload", _last_time_payload)
	if not _last_system_payload.is_empty():
		_match_panel.call("set_system_payload", _last_system_payload)


func _mount_placeholder(title: String, summary: String, return_text: String) -> void:
	_set_shell_chrome_visible(true)
	_set_l2_panels_visible(false, false)
	_title_label.text = title
	_summary_label.text = summary
	_primary_button.text = return_text
	_primary_button.disabled = false
	_primary_button.visible = true
	_secondary_button.visible = false


func _ensure_player_panel() -> void:
	if _player_panel != null:
		return
	_player_panel = PlayerMgmtPanelScript.new() as Control
	_player_panel.name = "PlayerMgmtPanel"
	_content_box.add_child(_player_panel)


func _ensure_match_panel() -> void:
	if _match_panel != null:
		return
	_match_panel = MatchPerfPanelScript.new() as Control
	_match_panel.name = "MatchPerfPanel"
	_content_box.add_child(_match_panel)


func _set_shell_chrome_visible(is_visible: bool) -> void:
	_title_label.visible = is_visible
	_summary_label.visible = is_visible
	_disable_reason_label.visible = is_visible and not _disable_reason_label.text.is_empty()
	_primary_button.visible = is_visible
	_secondary_button.visible = is_visible


func _set_l2_panels_visible(player_visible: bool, match_visible: bool) -> void:
	if _player_panel != null:
		_player_panel.visible = player_visible
	if _match_panel != null:
		_match_panel.visible = match_visible


func _update_guidance_route(route_id: String) -> void:
	if _guidance_panel == null:
		return
	_guidance_panel.call("set_route", route_id)
	_guidance_panel.call("set_anchor_available", _guidance_anchor_exists(route_id))


func _guidance_anchor_exists(route_id: String) -> bool:
	match route_id:
		ROUTE_HOME:
			return _secondary_button != null or _primary_button != null
		ROUTE_ROSTER:
			return _find_descendant_by_name(_player_panel, "RosterList") != null
		ROUTE_PLAYER_DETAIL:
			return _find_descendant_by_name(_player_panel, "TrainingEntryButton") != null
		ROUTE_TRAINING:
			return _find_descendant_by_name(_player_panel, "TrainingConfirmButton") != null
		ROUTE_MATCH_PRE:
			return _find_descendant_by_name(_match_panel, "PreMatchStartButton") != null
		ROUTE_MATCH_RESULT:
			return _find_descendant_by_name(_match_panel, "ResultConfirmButton") != null
	return false


func _find_descendant_by_name(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	if root.name == node_name:
		return root
	for child: Node in root.get_children():
		var found: Node = _find_descendant_by_name(child, node_name)
		if found != null:
			return found
	return null


func _build_home_summary_text() -> String:
	var date_display: String = str(_last_time_payload.get("date_display", "时间待同步"))
	var phase: String = str(_last_time_payload.get("phase", "阶段待同步"))
	var next_match: String = _resolve_next_match_summary()
	var action_windows: String = str(_last_time_payload.get("available_action_windows", "?"))
	var team_overview: String = str(_last_system_payload.get("team_overview", "球队摘要待同步"))
	var funds: String = str(_last_system_payload.get("funds", "经费见顶部栏"))
	var ap: String = str(_last_system_payload.get("ap", "AP 见顶部栏"))
	if _last_player_action_payload.has("summary"):
		team_overview = str(_last_player_action_payload.get("summary", team_overview))
	return "日期/阶段：%s / %s\n下一场：%s\n球队概览：%s\n行动窗口：%s\n经费：%s\nAP：%s" % [date_display, phase, next_match, team_overview, action_windows, funds, ap]


func _resolve_next_match_summary() -> String:
	if bool(_last_time_payload.get("schedule_loading", false)):
		return "赛程加载中"
	if bool(_last_time_payload.get("schedule_missing", false)):
		return "赛程待公布"
	var opponent_name: String = str(_last_time_payload.get("opponent_name", ""))
	var next_match_display: String = str(_last_time_payload.get("next_match_display", ""))
	if bool(_last_time_payload.get("match_trigger_reached", false)) and bool(_last_time_payload.get("match_center_available", true)):
		return "可进入比赛" if opponent_name.is_empty() else "可进入比赛：%s" % opponent_name
	if not next_match_display.is_empty():
		return next_match_display
	if not opponent_name.is_empty():
		return "下一场：%s" % opponent_name
	return "赛程待同步"


func _primary_home_action_text() -> String:
	if bool(_last_time_payload.get("match_trigger_reached", false)):
		return "进入比赛"
	return "查看 Home"


func _on_primary_action_pressed() -> void:
	if _current_route == ROUTE_HOME:
		if _can_enter_match():
			route_to(ROUTE_MATCH_PRE)
			return
		_show_disable_reason(_resolve_match_disable_reason())
		return
	return_home()


func _on_secondary_action_pressed() -> void:
	if _current_route == ROUTE_HOME:
		route_to(ROUTE_ROSTER)


func _can_enter_match() -> bool:
	var system_allows: bool = bool(_last_system_payload.get("system_state_allows_match", true))
	var navigation_allows: bool = bool(_last_system_payload.get("navigation_context_allows_match", true))
	var trigger_reached: bool = bool(_last_time_payload.get("match_trigger_reached", false))
	var match_center_available: bool = bool(_last_time_payload.get("match_center_available", true))
	var schedule_available: bool = bool(_last_time_payload.get("schedule_available", false))
	return system_allows and navigation_allows and trigger_reached and match_center_available and schedule_available


func _resolve_match_disable_reason() -> String:
	if not bool(_last_system_payload.get("system_state_allows_match", true)):
		return str(_last_system_payload.get("system_state_disable_reason", "当前系统状态不允许进入比赛"))
	if not bool(_last_system_payload.get("navigation_context_allows_match", true)):
		return str(_last_system_payload.get("navigation_context_disable_reason", "当前导航上下文不允许进入比赛"))
	if bool(_last_time_payload.get("schedule_missing", false)):
		return "赛程尚未公布"
	if not bool(_last_time_payload.get("match_trigger_reached", false)):
		return "还未到比赛时间"
	if not bool(_last_time_payload.get("match_center_available", true)):
		return "比赛中心暂不可用"
	return "当前不可进入比赛"


func _show_disable_reason(reason: String) -> void:
	_disable_reason_label.text = reason
	_disable_reason_label.visible = not reason.is_empty()


func _clear_disable_reason() -> void:
	_disable_reason_label.text = ""
	_disable_reason_label.visible = false


func _play_transition() -> void:
	if _transition_tween != null:
		_transition_tween.kill()
		_transition_tween = null
	if _content_panel == null:
		return
	_content_panel.modulate.a = 0.0
	_transition_tween = create_tween()
	_transition_tween.tween_property(_content_panel, "modulate:a", 1.0, TRANSITION_SECONDS)


func _is_supported_route(route_id: String) -> bool:
	return route_id in ROUTE_IDS


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	var source: Dictionary = value as Dictionary
	for key_variant: Variant in source.keys():
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary
