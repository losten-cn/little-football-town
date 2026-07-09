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
const GrowthSummaryScript: Script = preload("res://src/ui/growth_summary.gd")
const TownGridScript: Script = preload("res://src/ui/town_grid.gd")
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
const UI_COLOR_TOWN_SURFACE := Color("FFF2D2")
const UI_COLOR_TOWN_BORDER := Color("C58A3A")
const UI_COLOR_TOWN_TEXT := Color("3A2A1A")
const UI_COLOR_TOWN_ACCENT := Color("C76A00")

var _current_route: String = ROUTE_HOME
var _content_panel: PanelContainer = null
var _content_margin: MarginContainer = null
var _content_box: VBoxContainer = null
var _title_label: Label = null
var _summary_label: Label = null
var _home_cards_box: VBoxContainer = null
var _disable_reason_label: Label = null
var _primary_button: Button = null
var _secondary_button: Button = null
var _last_time_payload: Dictionary[String, Variant] = {}
var _last_system_payload: Dictionary[String, Variant] = {}
var _last_player_action_payload: Dictionary[String, Variant] = {}
var _last_roster_payload: Dictionary[String, Variant] = {}
var _last_training_payload: Dictionary[String, Variant] = {}
var _match_entry_state: Dictionary[String, Variant] = {}
var _player_panel: Control = null
var _match_panel: Control = null
var _guidance_panel: Control = null
var _growth_panel: Control = null
var _town_grid: Control = null
var _transition_tween: Tween = null


func _ready() -> void:
	name = "MainLoopShell"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_container()
	_subscribe_events()
	var active_route: String = ScreenManager.get_active_screen_id()
	if not _is_supported_route(active_route):
		active_route = ROUTE_HOME
		ScreenManager.reset_to_screen(ROUTE_HOME)
	_mount_route(active_route)
	_request_authoritative_refresh()


func _exit_tree() -> void:
	EventBus.unsubscribe("screen_requested", _on_screen_requested)
	EventBus.unsubscribe("screen_pushed", _on_screen_changed)
	EventBus.unsubscribe("screen_popped", _on_screen_changed)
	EventBus.unsubscribe("screen_stack_reset", _on_screen_changed)
	EventBus.unsubscribe("time_advanced", _on_time_advanced)
	EventBus.unsubscribe("system_state_changed", _on_system_state_changed)
	EventBus.unsubscribe("match_entry_state_changed", _on_match_entry_state_changed)
	EventBus.unsubscribe("roster_updated", _on_roster_updated)
	EventBus.unsubscribe("training_options_updated", _on_training_options_updated)
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
	_content_panel.add_theme_stylebox_override("panel", _town_panel_style())
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
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 16)
	_content_margin.add_child(_content_box)

	_title_label = Label.new()
	_title_label.name = "RouteTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_color_override("font_color", UI_COLOR_TOWN_ACCENT)
	_title_label.add_theme_font_size_override("font_size", 20)
	_content_box.add_child(_title_label)

	_summary_label = Label.new()
	_summary_label.name = "RouteSummary"
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.add_theme_color_override("font_color", UI_COLOR_TOWN_TEXT)
	_content_box.add_child(_summary_label)

	_home_cards_box = VBoxContainer.new()
	_home_cards_box.name = "HomeInfoCards"
	_home_cards_box.add_theme_constant_override("separation", 8)
	_content_box.add_child(_home_cards_box)

	_disable_reason_label = Label.new()
	_disable_reason_label.name = "DisableReason"
	_disable_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_disable_reason_label.add_theme_color_override("font_color", UI_COLOR_TOWN_TEXT)
	_disable_reason_label.add_theme_stylebox_override("normal", _disable_reason_style())
	_disable_reason_label.visible = false
	_content_box.add_child(_disable_reason_label)

	_primary_button = Button.new()
	_primary_button.name = "PrimaryAction"
	_primary_button.focus_mode = Control.FOCUS_ALL
	_apply_town_button_style(_primary_button, true)
	_primary_button.pressed.connect(_on_primary_action_pressed)
	_content_box.add_child(_primary_button)

	_secondary_button = Button.new()
	_secondary_button.name = "SecondaryAction"
	_secondary_button.focus_mode = Control.FOCUS_ALL
	_apply_town_button_style(_secondary_button, false)
	_secondary_button.pressed.connect(_on_secondary_action_pressed)
	_content_box.add_child(_secondary_button)

	_guidance_panel = WhatNextGuidanceScript.new() as Control
	_guidance_panel.name = "WhatNextGuidance"
	_content_box.add_child(_guidance_panel)

	_growth_panel = GrowthSummaryScript.new() as Control
	_growth_panel.name = "GrowthSummary"
	_content_box.add_child(_growth_panel)

	_town_grid = TownGridScript.new() as Control
	_town_grid.name = "TownGrid"
	_content_box.add_child(_town_grid)


func _town_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UI_COLOR_TOWN_SURFACE
	style.border_color = UI_COLOR_TOWN_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8.0)
	return style


func _town_button_style(is_primary: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UI_COLOR_TOWN_ACCENT if is_primary else Color("F5DDA8")
	style.border_color = UI_COLOR_TOWN_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(6.0)
	return style


func _town_button_focus_style(is_primary: bool) -> StyleBoxFlat:
	var style := _town_button_style(is_primary)
	style.border_color = Color("5B8C5A")
	style.set_border_width_all(3)
	return style


func _home_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("FFF8E8")
	style.border_color = Color("D8A85A")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8.0)
	return style


func _disable_reason_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("FFE9C2")
	style.border_color = UI_COLOR_TOWN_ACCENT
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8.0)
	return style


func _apply_town_button_style(button: Button, is_primary: bool) -> void:
	button.add_theme_stylebox_override("normal", _town_button_style(is_primary))
	button.add_theme_stylebox_override("hover", _town_button_focus_style(is_primary))
	button.add_theme_stylebox_override("focus", _town_button_focus_style(is_primary))
	button.add_theme_stylebox_override("pressed", _town_button_focus_style(is_primary))
	button.add_theme_stylebox_override("disabled", _town_button_style(false))
	button.add_theme_color_override("font_color", Color.WHITE if is_primary else UI_COLOR_TOWN_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE if is_primary else UI_COLOR_TOWN_TEXT)
	button.add_theme_color_override("font_focus_color", Color.WHITE if is_primary else UI_COLOR_TOWN_TEXT)
	button.add_theme_color_override("font_disabled_color", UI_COLOR_TOWN_TEXT)


func _subscribe_events() -> void:
	EventBus.subscribe("screen_requested", _on_screen_requested)
	EventBus.subscribe("screen_pushed", _on_screen_changed)
	EventBus.subscribe("screen_popped", _on_screen_changed)
	EventBus.subscribe("screen_stack_reset", _on_screen_changed)
	EventBus.subscribe("time_advanced", _on_time_advanced)
	EventBus.subscribe("system_state_changed", _on_system_state_changed)
	EventBus.subscribe("match_entry_state_changed", _on_match_entry_state_changed)
	EventBus.subscribe("roster_updated", _on_roster_updated)
	EventBus.subscribe("training_options_updated", _on_training_options_updated)
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
	var typed_payload: Dictionary[String, Variant] = _to_string_variant_dictionary(payload)
	for key: String in typed_payload.keys():
		_last_system_payload[key] = typed_payload[key]
	if _match_panel != null:
		_match_panel.call("set_system_payload", _last_system_payload)
	if _current_route == ROUTE_HOME:
		_mount_home()


func _on_match_entry_state_changed(_event_name: String, payload: Dictionary) -> void:
	_match_entry_state = _to_string_variant_dictionary(payload)
	if _current_route == ROUTE_HOME:
		_mount_home()


func _on_roster_updated(_event_name: String, payload: Dictionary) -> void:
	_last_roster_payload = _to_string_variant_dictionary(payload)
	if _player_panel != null:
		_player_panel.call("set_roster_payload", _last_roster_payload)


func _on_training_options_updated(_event_name: String, payload: Dictionary) -> void:
	_last_training_payload = _to_string_variant_dictionary(payload)
	if _player_panel != null:
		_player_panel.call("set_training_payload", _last_training_payload)


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
	_title_label.text = _localized_text("HOME_TITLE", "俱乐部主页")
	_summary_label.text = _build_home_summary_text()
	_rebuild_home_info_cards()
	_primary_button.text = _primary_home_action_text()
	_primary_button.disabled = false
	_primary_button.focus_mode = Control.FOCUS_ALL
	_primary_button.visible = true
	_secondary_button.text = _secondary_home_action_text()
	_secondary_button.disabled = false
	_secondary_button.focus_mode = Control.FOCUS_ALL
	_secondary_button.visible = true
	_sync_home_disable_reason()


func _mount_player_panel(route_id: String) -> void:
	_update_guidance_route(route_id)
	_set_shell_chrome_visible(false)
	_ensure_player_panel()
	_set_l2_panels_visible(true, false)
	if _last_roster_payload.is_empty() or _last_training_payload.is_empty():
		_request_training_read_models()
	_sync_player_panel_payloads()
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
	_player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_child(_player_panel)


func _sync_player_panel_payloads() -> void:
	if _player_panel == null:
		return
	if not _last_roster_payload.is_empty():
		_player_panel.call("set_roster_payload", _last_roster_payload)
	if not _last_training_payload.is_empty():
		_player_panel.call("set_training_payload", _last_training_payload)


func _request_training_read_models() -> void:
	EventBus.emit("training_read_models_requested", {"source": "main_loop_shell"})


func _ensure_match_panel() -> void:
	if _match_panel != null:
		return
	_match_panel = MatchPerfPanelScript.new() as Control
	_match_panel.name = "MatchPerfPanel"
	_match_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_match_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_child(_match_panel)


func _set_shell_chrome_visible(is_visible: bool) -> void:
	_title_label.visible = is_visible
	_summary_label.visible = is_visible
	if _home_cards_box != null:
		_home_cards_box.visible = is_visible and _current_route == ROUTE_HOME
	if _growth_panel != null:
		_growth_panel.visible = is_visible and _current_route == ROUTE_HOME
	if _town_grid != null:
		_town_grid.visible = is_visible and _current_route == ROUTE_HOME
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
	return _localized_text("HOME_VISUAL_EXEMPLAR_SUMMARY", "温暖的小镇俱乐部正在运转。这里保留当前状态、下一步行动和比赛入口，不需要打开深层菜单就能判断现在该做什么。")


func _rebuild_home_info_cards() -> void:
	if _home_cards_box == null:
		return
	_clear_children(_home_cards_box)
	var date_display: String = str(_last_time_payload.get("date_display", _localized_text("HOME_TIME_NOT_READY", "时间准备中")))
	var phase: String = _home_phase_display(str(_last_time_payload.get("phase", "PLANNING")))
	var action_windows: String = str(_last_time_payload.get("available_action_windows", "0"))
	var team_overview: String = str(_last_system_payload.get("team_overview", _localized_text("HOME_TEAM_EMPTY", "球队信息正在整理")))
	var recent_summary: String = _localized_text("HOME_RECENT_NONE", "暂无新的训练或比赛结果")
	if _last_player_action_payload.has("summary"):
		recent_summary = str(_last_player_action_payload.get("summary", recent_summary))
	_add_home_info_card("HomeCardTime", _localized_text("HOME_CARD_TIME_TITLE", "当前节奏"), _localized_text("HOME_CARD_TIME_FORMAT", "%s / %s") % [date_display, phase])
	_add_home_info_card("HomeCardMatch", _localized_text("HOME_CARD_MATCH_TITLE", "下一场比赛"), _resolve_next_match_summary())
	_add_home_info_card("HomeCardTeam", _localized_text("HOME_CARD_TEAM_TITLE", "球队概览"), team_overview)
	_add_home_info_card("HomeCardResources", _localized_text("HOME_CARD_RESOURCE_TITLE", "资源与行动"), _home_resource_summary(action_windows))
	_add_home_info_card("HomeCardNextStep", _localized_text("HOME_CARD_NEXT_STEP_TITLE", "建议下一步"), _recommended_home_action_summary())
	_add_home_info_card("HomeCardTownWarmth", _localized_text("HOME_CARD_TOWN_TITLE", "小镇氛围"), "%s\n%s\n%s" % [_home_town_anchor_summary(), _home_club_mood_summary(), recent_summary])


func _add_home_info_card(card_name: String, title: String, body: String) -> void:
	var card := PanelContainer.new()
	card.name = card_name
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _home_card_style())
	_home_cards_box.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 3)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)
	var title_label := Label.new()
	title_label.name = "%sTitle" % card_name
	title_label.text = title
	title_label.add_theme_color_override("font_color", UI_COLOR_TOWN_ACCENT)
	title_label.add_theme_font_size_override("font_size", 14)
	box.add_child(title_label)
	var body_label := Label.new()
	body_label.name = "%sBody" % card_name
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", UI_COLOR_TOWN_TEXT)
	box.add_child(body_label)


func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _home_phase_display(phase: String) -> String:
	match phase:
		"PLANNING":
			return _localized_text("HOME_PHASE_PLANNING", "日常经营")
		"MATCH_TRIGGER":
			return _localized_text("HOME_PHASE_MATCH_TRIGGER", "比赛日")
		"POST_MATCH", "POST_MATCH_SETTLEMENT":
			return _localized_text("HOME_PHASE_POST_MATCH", "赛后回顾")
		_:
			return phase.capitalize()


func _home_resource_summary(action_windows: String) -> String:
	var funds_text: String = str(_last_system_payload.get("funds", _localized_text("HOME_RESOURCE_UNKNOWN", "整理中")))
	var ap_text: String = str(_last_system_payload.get("ap", _last_system_payload.get("action_points", _localized_text("HOME_RESOURCE_UNKNOWN", "整理中"))))
	return _localized_text("HOME_RESOURCE_FORMAT", "资源：经费 %s｜运动点数 %s｜行动 %s") % [funds_text, ap_text, action_windows]


func _home_club_mood_summary() -> String:
	var action_windows: int = int(_last_time_payload.get("available_action_windows", 0))
	if _can_enter_match():
		return _localized_text("HOME_CLUB_MOOD_MATCH_READY", "更衣室已经热起来了，大家都在等你敲定今天的比赛。")
	if bool(_last_time_payload.get("match_trigger_reached", false)):
		return _localized_text("HOME_CLUB_MOOD_MATCH_BLOCKED", "比赛日已经到了，队员和镇上的支持者都在等你把最后细节安排妥当。")
	if action_windows <= 0:
		return _localized_text("HOME_CLUB_MOOD_WINDOWS_SPENT", "今天的安排已经排满，俱乐部正安静收尾，等你推进到下一步。")
	return _localized_text("HOME_CLUB_MOOD_DEFAULT", "训练场边有人聊天、有人收拾器材，这支小球队正一点点变得像个家。")


func _home_action_context_summary() -> String:
	var primary_action: String = _primary_home_action_text()
	var secondary_action: String = _secondary_home_action_text()
	var match_disable_reason: String = _home_match_disable_reason_hint()
	if not match_disable_reason.is_empty():
		return _localized_text("HOME_ACTION_CONTEXT_MATCH_LOCKED_FORMAT", "现在最直接的安排是先去%s；比赛入口会在%s后开放。也可以先%s。") % [primary_action, match_disable_reason, secondary_action]
	if _can_enter_match():
		return _localized_text("HOME_ACTION_CONTEXT_MATCH_READY_FORMAT", "现在最直接的安排是%s；如果你还想再确认一次状态，也可以先%s。") % [primary_action, secondary_action]
	return _localized_text("HOME_ACTION_CONTEXT_DEFAULT_FORMAT", "现在最直接的安排是%s；如果你想先看看队伍近况，也可以%s。") % [primary_action, secondary_action]


func _secondary_home_action_text() -> String:
	if _can_enter_match():
		return _localized_text("HOME_SECONDARY_ROSTER_CONFIRM", "先看球员状态")
	return _localized_text("HOME_SECONDARY_MATCH_PREP", "查看比赛准备")


func _home_match_disable_reason_hint() -> String:
	if not bool(_last_time_payload.get("match_trigger_reached", false)):
		return ""
	if _can_enter_match():
		return ""
	var reason: String = _resolve_match_disable_reason()
	if reason.is_empty():
		return ""
	return _localized_text("HOME_MATCH_DISABLE_REASON_HINT_FORMAT", "“%s”") % reason


func _sync_home_disable_reason() -> void:
	if not bool(_last_time_payload.get("match_trigger_reached", false)) or _can_enter_match():
		_clear_disable_reason()
		return
	_show_disable_reason(_localized_text("HOME_MATCH_DISABLED_VISIBLE_FORMAT", "比赛暂未开放：%s") % _resolve_match_disable_reason())


func _home_town_anchor_summary() -> String:
	var town_summary: String = str(_last_system_payload.get("town_anchor_summary", _last_system_payload.get("town_summary", "")))
	if not town_summary.is_empty():
		return _localized_text("HOME_TOWN_ANCHOR_FORMAT", "小镇球场：%s") % town_summary
	return _localized_text("HOME_TOWN_ANCHOR_DEFAULT", "小镇球场：训练场很热闹，大家都在为下一轮做准备。")


func _resolve_next_match_summary() -> String:
	if bool(_last_time_payload.get("schedule_loading", false)):
		return _localized_text("HOME_SCHEDULE_PREPARING", "赛程正在准备")
	if bool(_last_time_payload.get("schedule_missing", false)):
		return _localized_text("HOME_SCHEDULE_PENDING", "赛程待公布")
	var opponent_name: String = _player_facing_opponent_name(str(_last_time_payload.get("opponent_name", "")))
	var next_match_display: String = str(_last_time_payload.get("next_match_display", ""))
	if bool(_last_time_payload.get("match_trigger_reached", false)) and bool(_last_time_payload.get("match_center_available", true)):
		return _localized_text("HOME_MATCH_READY", "比赛已可开始") if opponent_name.is_empty() else _localized_text("HOME_MATCH_READY_VS", "可进入比赛：%s") % opponent_name
	if not next_match_display.is_empty():
		if next_match_display.contains("Opponent"):
			return _localized_text("HOME_NEXT_MATCH_PENDING", "周末比赛待公布")
		return next_match_display
	if not opponent_name.is_empty():
		return _localized_text("HOME_NEXT_MATCH_VS", "%s") % opponent_name
	return _localized_text("HOME_SCHEDULE_PENDING", "赛程待公布")


func _primary_home_action_text() -> String:
	if _can_enter_match():
		return _localized_text("HOME_PRIMARY_MATCH", "进入比赛")
	return _localized_text("HOME_PRIMARY_ROSTER", "查看球员并训练")


func _recommended_home_action_summary() -> String:
	if _can_enter_match():
		return _localized_text("HOME_RECOMMEND_MATCH", "建议下一步：阵容已就绪，可以进入比赛。")
	if bool(_last_time_payload.get("match_trigger_reached", false)):
		return _localized_text("HOME_RECOMMEND_FIX_LINEUP", "建议下一步：先查看球员，处理比赛前的阵容问题。")
	return _localized_text("HOME_RECOMMEND_TRAINING", "建议下一步：先查看球员，并安排一次训练。")


func _on_primary_action_pressed() -> void:
	if _current_route == ROUTE_HOME:
		if _can_enter_match():
			route_to(ROUTE_MATCH_PRE)
			return
		if bool(_last_time_payload.get("match_trigger_reached", false)):
			_show_disable_reason(_localized_text("HOME_MATCH_DISABLED_VISIBLE_FORMAT", "比赛暂未开放：%s") % _resolve_match_disable_reason())
			return
		route_to(ROUTE_ROSTER)
		return
	return_home()


func _on_secondary_action_pressed() -> void:
	if _current_route == ROUTE_HOME:
		if _can_enter_match():
			route_to(ROUTE_ROSTER)
			return
		route_to(ROUTE_MATCH_PRE)


func _can_enter_match() -> bool:
	return bool(_match_entry_state.get("available", false))


func _resolve_match_disable_reason() -> String:
	return _player_facing_disable_reason(String(_match_entry_state.get("disabled_reason", _localized_text("MATCH_DISABLED_DEFAULT", "当前不可进入比赛"))))


func _player_facing_disable_reason(reason: String) -> String:
	if reason.is_empty():
		return _localized_text("MATCH_DISABLED_DEFAULT", "当前不可进入比赛")
	if reason == "阵容不合法" or reason.contains("阵容不合法"):
		return _localized_text("MATCH_DISABLED_LINEUP_INCOMPLETE", "阵容不完整——至少需要 7 名球员和 1 名守门员")
	return reason


func _player_facing_opponent_name(opponent_name: String) -> String:
	if opponent_name.is_empty() or opponent_name.begins_with("Opponent"):
		return _localized_text("MATCH_OPPONENT_PENDING", "本轮对手待公布")
	return opponent_name


func _show_disable_reason(reason: String) -> void:
	_disable_reason_label.text = reason
	_disable_reason_label.visible = not reason.is_empty()


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized


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
