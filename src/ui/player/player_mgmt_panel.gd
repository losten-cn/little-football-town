extends Control
## L2 roster/player/training panel mounted by the MainLoop shell.

const ROUTE_ROSTER: String = "roster"
const ROUTE_PLAYER_DETAIL: String = "player_detail"
const ROUTE_TRAINING: String = "training"
const UI_COLOR_TEXT := Color("3A2A1A")
const UI_COLOR_MUTED := Color("6D5A3A")
const UI_COLOR_ACCENT := Color("C76A00")
const UI_COLOR_SURFACE := Color("F5DDA8")
const UI_COLOR_BORDER := Color("C58A3A")

var _current_route: String = ROUTE_ROSTER
var _roster_payload: Dictionary[String, Variant] = {}
var _training_payload: Dictionary[String, Variant] = {}
var _selected_player: Dictionary[String, Variant] = {}
var _selected_player_id: String = ""
var _selected_training_id: String = ""
var _last_training_result: Dictionary[String, Variant] = {}

var _root_box: VBoxContainer = null
var _title_label: Label = null
var _roster_list: VBoxContainer = null
var _detail_summary: Label = null
var _training_option_list: VBoxContainer = null
var _training_confirm_button: Button = null
var _training_result_summary: Label = null
var _return_home_button: Button = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	_subscribe_events()
	_refresh()


func _exit_tree() -> void:
	EventBus.unsubscribe("roster_updated", _on_roster_updated)
	EventBus.unsubscribe("player_selected", _on_player_selected)
	EventBus.unsubscribe("training_options_updated", _on_training_options_updated)
	EventBus.unsubscribe("training_completed", _on_training_completed)
	EventBus.unsubscribe("player_action_completed", _on_player_action_completed)


## Sets the mounted PlayerMgmt route without changing authoritative player state.
func set_route(route_id: String) -> void:
	_current_route = route_id
	_refresh()


## Applies the latest authoritative roster snapshot.
func set_roster_payload(payload: Dictionary[String, Variant]) -> void:
	_roster_payload = payload.duplicate(true)
	_select_first_player_if_needed()
	_refresh()


## Applies the latest authoritative training snapshot.
func set_training_payload(payload: Dictionary[String, Variant]) -> void:
	_training_payload = payload.duplicate(true)
	_select_first_training_if_needed()
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
	_root_box.name = "PlayerMgmtRoot"
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
	_title_label.name = "PlayerMgmtTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_color_override("font_color", UI_COLOR_ACCENT)
	_title_label.add_theme_font_size_override("font_size", 18)
	_root_box.add_child(_title_label)

	_roster_list = VBoxContainer.new()
	_roster_list.name = "RosterList"
	_roster_list.add_theme_constant_override("separation", 6)
	_root_box.add_child(_roster_list)

	_detail_summary = Label.new()
	_detail_summary.name = "PlayerDetailSummary"
	_detail_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_summary.add_theme_color_override("font_color", UI_COLOR_TEXT)
	_root_box.add_child(_detail_summary)

	_training_option_list = VBoxContainer.new()
	_training_option_list.name = "TrainingOptionList"
	_training_option_list.add_theme_constant_override("separation", 6)
	_root_box.add_child(_training_option_list)

	_training_confirm_button = Button.new()
	_training_confirm_button.name = "TrainingConfirmButton"
	_training_confirm_button.focus_mode = Control.FOCUS_ALL
	_apply_town_button_style(_training_confirm_button, true)
	_training_confirm_button.pressed.connect(_on_training_confirm_pressed)
	_root_box.add_child(_training_confirm_button)

	_training_result_summary = Label.new()
	_training_result_summary.name = "TrainingResultSummary"
	_training_result_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_training_result_summary.add_theme_color_override("font_color", UI_COLOR_MUTED)
	_root_box.add_child(_training_result_summary)

	_return_home_button = Button.new()
	_return_home_button.name = "ReturnHomeButton"
	_return_home_button.text = _localized_text("PLAYER_RETURN_HOME", "返回主页")
	_return_home_button.focus_mode = Control.FOCUS_ALL
	_apply_town_button_style(_return_home_button, false)
	_return_home_button.pressed.connect(_on_return_home_pressed)
	_root_box.add_child(_return_home_button)


func _subscribe_events() -> void:
	EventBus.subscribe("roster_updated", _on_roster_updated)
	EventBus.subscribe("player_selected", _on_player_selected)
	EventBus.subscribe("training_options_updated", _on_training_options_updated)
	EventBus.subscribe("training_completed", _on_training_completed)
	EventBus.subscribe("player_action_completed", _on_player_action_completed)


func _on_roster_updated(_event_name: String, payload: Dictionary) -> void:
	set_roster_payload(_to_string_variant_dictionary(payload))


func _on_player_selected(_event_name: String, payload: Dictionary) -> void:
	var typed_payload: Dictionary[String, Variant] = _to_string_variant_dictionary(payload)
	_selected_player = _extract_player_from_payload(typed_payload)
	_selected_player_id = str(typed_payload.get("player_id", _selected_player.get("id", _selected_player_id)))
	_refresh()


func _on_training_options_updated(_event_name: String, payload: Dictionary) -> void:
	set_training_payload(_to_string_variant_dictionary(payload))


func _on_training_completed(_event_name: String, payload: Dictionary) -> void:
	_last_training_result = _to_string_variant_dictionary(payload)
	_refresh()


func _on_player_action_completed(_event_name: String, payload: Dictionary) -> void:
	_last_training_result = _to_string_variant_dictionary(payload)
	_refresh()


func _refresh() -> void:
	if _root_box == null:
		return
	_clear_children(_roster_list)
	_clear_children(_training_option_list)
	_detail_summary.visible = false
	_training_option_list.visible = false
	_training_confirm_button.visible = false
	_training_result_summary.visible = false
	match _current_route:
		ROUTE_ROSTER:
			_mount_roster()
		ROUTE_PLAYER_DETAIL:
			_mount_player_detail()
		ROUTE_TRAINING:
			_mount_training()
		_:
			_mount_roster()


func _mount_roster() -> void:
	_title_label.text = _localized_text("PLAYER_ROSTER_TITLE", "球员列表")
	_roster_list.visible = true
	var players: Array[Dictionary] = _get_players_sorted_by_rating()
	if players.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = _localized_text("PLAYER_ROSTER_EMPTY", "暂无可显示球员")
		_roster_list.add_child(empty_label)
		return
	for player: Dictionary in players:
		var row_button: Button = Button.new()
		row_button.name = "RosterRow_%s" % str(player.get("id", "unknown"))
		row_button.focus_mode = Control.FOCUS_ALL
		_apply_town_button_style(row_button, false)
		row_button.text = _format_roster_row(player)
		row_button.pressed.connect(_on_roster_row_pressed.bind(player))
		_roster_list.add_child(row_button)


func _mount_player_detail() -> void:
	_title_label.text = _localized_text("PLAYER_DETAIL_TITLE", "球员详情")
	_detail_summary.visible = true
	_detail_summary.text = _format_player_detail(_resolve_selected_player())
	_training_confirm_button.visible = true
	_training_confirm_button.name = "TrainingEntryButton"
	_training_confirm_button.text = _training_entry_text()
	_training_confirm_button.disabled = not _training_entry_available()


func _mount_training() -> void:
	_title_label.text = _localized_text("PLAYER_TRAINING_TITLE", "训练")
	_detail_summary.visible = true
	_detail_summary.text = _format_player_detail(_resolve_selected_player())
	_training_option_list.visible = true
	_training_confirm_button.name = "TrainingConfirmButton"
	_training_confirm_button.visible = true
	_training_confirm_button.text = _training_confirm_text()
	_training_confirm_button.disabled = not _training_entry_available() or _selected_training_id.is_empty()
	_training_result_summary.visible = true
	_training_result_summary.text = _format_training_result()
	_mount_training_options()


func _mount_training_options() -> void:
	_clear_children(_training_option_list)
	var options: Array[Dictionary] = _get_training_options()
	if options.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = _localized_text("PLAYER_TRAINING_EMPTY", "暂无训练项目")
		_training_option_list.add_child(empty_label)
		return
	for option: Dictionary in options:
		var option_id: String = str(option.get("training_id", option.get("id", "")))
		var option_button: Button = Button.new()
		option_button.name = "TrainingOption_%s" % option_id
		option_button.focus_mode = Control.FOCUS_ALL
		_apply_town_button_style(option_button, option_id == _selected_training_id)
		option_button.text = _format_training_option(option)
		option_button.disabled = not bool(option.get("available", true))
		option_button.pressed.connect(_on_training_option_pressed.bind(option_id))
		_training_option_list.add_child(option_button)


func _on_roster_row_pressed(player: Dictionary) -> void:
	_selected_player = _to_string_variant_dictionary(player)
	_selected_player_id = str(_selected_player.get("id", ""))
	EventBus.emit("player_selected", {
		"player_id": _selected_player_id,
		"player": _selected_player,
	})
	EventBus.emit("screen_requested", {
		"screen_id": ROUTE_PLAYER_DETAIL,
		"player_id": _selected_player_id,
	})


func _on_training_option_pressed(training_id: String) -> void:
	_selected_training_id = training_id
	_refresh()


func _on_training_confirm_pressed() -> void:
	if _current_route == ROUTE_PLAYER_DETAIL:
		if _training_entry_available():
			EventBus.emit("screen_requested", {
				"screen_id": ROUTE_TRAINING,
				"player_id": _selected_player_id,
			})
		return
	if _selected_player_id.is_empty() or _selected_training_id.is_empty():
		return
	EventBus.emit("training_requested", {
		"player_id": _selected_player_id,
		"training_id": _selected_training_id,
	})


func _on_return_home_pressed() -> void:
	EventBus.emit("screen_requested", {"screen_id": "home"})


func _select_first_player_if_needed() -> void:
	if not _selected_player_id.is_empty():
		return
	var players: Array[Dictionary] = _get_players_sorted_by_rating()
	if players.is_empty():
		return
	_selected_player = _to_string_variant_dictionary(players[0])
	_selected_player_id = str(_selected_player.get("id", ""))


func _select_first_training_if_needed() -> void:
	if not _selected_training_id.is_empty():
		return
	var options: Array[Dictionary] = _get_training_options()
	for option: Dictionary in options:
		if bool(option.get("available", true)):
			_selected_training_id = str(option.get("training_id", option.get("id", "")))
			return


func _get_players_sorted_by_rating() -> Array[Dictionary]:
	var players: Array[Dictionary] = _to_dictionary_array(_roster_payload.get("players", []))
	players.sort_custom(_compare_players_by_rating_desc)
	return players


func _get_training_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = _to_dictionary_array(_training_payload.get("options", _training_payload.get("training_options", [])))
	return options


func _resolve_selected_player() -> Dictionary[String, Variant]:
	if not _selected_player.is_empty():
		return _selected_player
	for player: Dictionary in _get_players_sorted_by_rating():
		if str(player.get("id", "")) == _selected_player_id:
			return _to_string_variant_dictionary(player)
	return {}


func _extract_player_from_payload(payload: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	if payload.has("selected_player"):
		return _to_string_variant_dictionary(payload.get("selected_player", {}))
	if payload.has("player"):
		return _to_string_variant_dictionary(payload.get("player", {}))
	return {}


func _training_entry_available() -> bool:
	return bool(_training_payload.get("training_available", _training_payload.get("available", true)))


func _training_entry_text() -> String:
	if _training_entry_available():
		return _localized_text("PLAYER_TRAINING_ENTRY", "进入训练")
	return str(_training_payload.get("disable_reason", _training_payload.get("training_disable_reason", _localized_text("PLAYER_TRAINING_DISABLED", "训练暂不可用"))))


func _format_roster_row(player: Dictionary) -> String:
	var typed_player: Dictionary[String, Variant] = _to_string_variant_dictionary(player)
	return _localized_text("PLAYER_ROSTER_ROW_FORMAT", "%s｜%s｜评分 %s｜%s\n关注：%s｜用途：%s｜下一步：%s") % [
		str(typed_player.get("name", _localized_text("PLAYER_UNKNOWN", "未知球员"))),
		str(typed_player.get("position", typed_player.get("primary_position", "?"))),
		str(typed_player.get("rating", typed_player.get("positional_overall_rating", "?"))),
		str(typed_player.get("development_tier", typed_player.get("tier", "-"))),
		_resolve_roster_attention_reason(typed_player),
		_resolve_player_role_summary(typed_player),
		_resolve_roster_next_step(typed_player),
	]


func _format_player_detail(player: Dictionary[String, Variant]) -> String:
	if player.is_empty():
		return _localized_text("PLAYER_DETAIL_NONE", "未选择球员")
	var reference_option: Dictionary[String, Variant] = _resolve_reference_training_option()
	return _localized_text("PLAYER_DETAIL_FORMAT", "本轮判断：%s\n用途：%s\n成本/回报：成本：%s；回报：%s；时机：%s\n下一步：%s\n身份：%s｜%s｜%s\n技术特点：%s\n近期成长：%s\n当前状态：%s") % [
		_resolve_training_why_summary(player),
		_resolve_player_role_summary(player),
		_resolve_training_cost_summary(reference_option),
		_resolve_training_impact_summary(reference_option),
		_resolve_training_payoff_summary(player, reference_option),
		_training_entry_text(),
		str(player.get("name", _localized_text("PLAYER_UNKNOWN", "未知球员"))),
		str(player.get("position", player.get("primary_position", "?"))),
		str(player.get("development_tier", player.get("tier", "-"))),
		_resolve_attribute_summary(player),
		_resolve_growth_summary(player),
		_resolve_status_summary(player),
	]


func _format_training_option(option: Dictionary) -> String:
	var marker: String = "* " if str(option.get("training_id", option.get("id", ""))) == _selected_training_id else ""
	var option_text: String = _localized_text("PLAYER_TRAINING_OPTION_FORMAT", "%s%s — %s") % [
		marker,
		str(option.get("name", option.get("training_name", _localized_text("PLAYER_TRAINING_OPTION", "训练项目")))),
		str(option.get("summary", option.get("expected_gain_summary", _localized_text("PLAYER_TRAINING_EXPECTED_GAIN", "预计提升本次重点能力")))),
	]
	if bool(option.get("available", true)):
		return option_text
	return _localized_text("PLAYER_TRAINING_OPTION_DISABLED_FORMAT", "%s｜暂不可用：%s") % [option_text, _resolve_training_disabled_reason(_to_string_variant_dictionary(option))]


func _format_training_result() -> String:
	var selected_option: Dictionary[String, Variant] = _resolve_selected_training_option()
	var result_summary: String = _localized_text("PLAYER_TRAINING_RESULT_PENDING", "完成训练后会在这里显示结果")
	if not _last_training_result.is_empty():
		result_summary = str(_last_training_result.get("summary", _last_training_result.get("result_summary", _localized_text("PLAYER_TRAINING_DONE", "训练已完成，近期状态已更新"))))
	return _localized_text("PLAYER_TRAINING_DECISION_FORMAT", "本轮判断：%s\n当前选择：%s\n成本/回报：成本：%s；回报：%s；时机：%s\n下一步：%s\n结果：%s") % [
		_resolve_training_risk_summary(selected_option),
		_resolve_training_option_name(selected_option),
		_resolve_training_cost_summary(selected_option),
		_resolve_training_impact_summary(selected_option),
		_resolve_training_payoff_summary(_resolve_selected_player(), selected_option),
		_resolve_training_next_step_summary(selected_option),
		result_summary,
	]


func _resolve_attribute_summary(player: Dictionary[String, Variant]) -> String:
	var explicit_summary: String = str(player.get("attributes_summary", ""))
	if not explicit_summary.is_empty():
		return explicit_summary
	return _build_attribute_summary_from_dictionary(player.get("attributes", {}))


func _resolve_growth_summary(player: Dictionary[String, Variant]) -> String:
	var explicit_summary: String = str(player.get("growth_summary", ""))
	if not explicit_summary.is_empty():
		return explicit_summary
	var recent_growth: String = str(player.get("recent_growth", ""))
	if not recent_growth.is_empty():
		return recent_growth
	return _localized_text("PLAYER_GROWTH_NONE", "暂无近期成长记录")


func _resolve_status_summary(player: Dictionary[String, Variant]) -> String:
	var explicit_summary: String = str(player.get("status_summary", ""))
	if not explicit_summary.is_empty():
		return explicit_summary
	var status_tag: String = str(player.get("status_tag", ""))
	if not status_tag.is_empty():
		return status_tag
	var status: String = str(player.get("status", ""))
	if not status.is_empty():
		return status
	return _localized_text("PLAYER_STATUS_GOOD", "状态：良好")


func _resolve_roster_attention_reason(player: Dictionary[String, Variant]) -> String:
	var explicit_reason: String = str(player.get("recommendation_reason", player.get("attention_reason", "")))
	if not explicit_reason.is_empty():
		return explicit_reason
	var rating: float = float(player.get("rating", player.get("positional_overall_rating", 0.0)))
	if rating >= 70.0:
		return _localized_text("PLAYER_ATTENTION_HIGH_RATING", "当前评分靠前，适合优先检查首发价值。")
	var growth_summary: String = _resolve_growth_summary(player)
	if growth_summary.contains("+"):
		return _localized_text("PLAYER_ATTENTION_GROWING", "近期有成长记录，适合继续观察训练回报。")
	return _localized_text("PLAYER_ATTENTION_DEFAULT", "先看他的状态与位置，决定是否纳入下一次训练。")


func _resolve_player_role_summary(player: Dictionary[String, Variant]) -> String:
	var explicit_role: String = str(player.get("role_summary", player.get("usage_summary", "")))
	if not explicit_role.is_empty():
		return explicit_role
	var position: String = str(player.get("position", player.get("primary_position", "?")))
	var rating: float = float(player.get("rating", player.get("positional_overall_rating", 0.0)))
	if rating >= 70.0:
		return _localized_text("PLAYER_ROLE_STARTER_FORMAT", "%s 主力候选，优先确认能否稳定出场。") % position
	if rating >= 55.0:
		return _localized_text("PLAYER_ROLE_ROTATION_FORMAT", "%s 轮换候选，适合用训练补齐短板。") % position
	return _localized_text("PLAYER_ROLE_DEVELOPMENT_FORMAT", "%s 培养候选，先看成长窗口再决定投入。") % position


func _resolve_roster_next_step(player: Dictionary[String, Variant]) -> String:
	var explicit_step: String = str(player.get("next_step_summary", ""))
	if not explicit_step.is_empty():
		return explicit_step
	if _resolve_status_summary(player).contains("可训练"):
		return _localized_text("PLAYER_NEXT_STEP_TRAIN", "进入详情后安排训练。")
	return _localized_text("PLAYER_NEXT_STEP_DETAIL", "进入详情确认状态。")


func _training_confirm_text() -> String:
	var selected_option: Dictionary[String, Variant] = _resolve_selected_training_option()
	if selected_option.is_empty():
		return _localized_text("PLAYER_TRAINING_CONFIRM", "确认训练")
	return _localized_text("PLAYER_TRAINING_CONFIRM_WITH_OPTION_FORMAT", "确认训练：%s") % str(selected_option.get("name", selected_option.get("training_name", _localized_text("PLAYER_TRAINING_OPTION", "训练项目"))))


func _resolve_reference_training_option() -> Dictionary[String, Variant]:
	var selected_option: Dictionary[String, Variant] = _resolve_selected_training_option()
	if not selected_option.is_empty():
		return selected_option
	var options: Array[Dictionary] = _get_training_options()
	for option: Dictionary in options:
		if bool(option.get("available", true)):
			return _to_string_variant_dictionary(option)
	return {}


func _resolve_selected_training_option() -> Dictionary[String, Variant]:
	if _selected_training_id.is_empty():
		return {}
	for option: Dictionary in _get_training_options():
		if str(option.get("training_id", option.get("id", ""))) == _selected_training_id:
			return _to_string_variant_dictionary(option)
	return {}


func _resolve_training_why_summary(player: Dictionary[String, Variant]) -> String:
	var explicit_summary: String = str(player.get("training_reason", player.get("recommendation_reason", "")))
	if not explicit_summary.is_empty():
		return explicit_summary
	var status_summary: String = _resolve_status_summary(player)
	var growth_summary: String = _resolve_growth_summary(player)
	if status_summary.contains("可训练") or growth_summary.contains("+"):
		return _localized_text("PLAYER_TRAINING_WHY_READY", "他正处在适合加练的窗口，训练收益更容易被看见。")
	return _localized_text("PLAYER_TRAINING_WHY_DEFAULT", "先给重点球员一次明确安排，能让下一场比赛更有牵挂。")


func _resolve_training_impact_summary(option: Dictionary[String, Variant]) -> String:
	if option.is_empty():
		return _localized_text("PLAYER_TRAINING_IMPACT_DEFAULT", "会影响本轮训练反馈和下一场赛前判断。")
	var summary: String = str(option.get("summary", option.get("expected_gain_summary", "")))
	if not summary.is_empty():
		return summary
	return _localized_text("PLAYER_TRAINING_IMPACT_DEFAULT", "会影响本轮训练反馈和下一场赛前判断。")


func _resolve_training_option_name(option: Dictionary[String, Variant]) -> String:
	if option.is_empty():
		return _localized_text("PLAYER_TRAINING_OPTION_PENDING", "先选择一个训练项目")
	return str(option.get("name", option.get("training_name", _localized_text("PLAYER_TRAINING_OPTION", "训练项目"))))


func _resolve_training_cost_summary(option: Dictionary[String, Variant]) -> String:
	var explicit_cost: String = str(option.get("cost_summary", option.get("cost", "")))
	if not explicit_cost.is_empty():
		return explicit_cost
	var parts: Array[String] = []
	if option.has("funds_cost"):
		parts.append(_localized_text("PLAYER_TRAINING_FUNDS_COST_FORMAT", "经费 %s") % str(option.get("funds_cost")))
	if option.has("ap_cost") or option.has("action_points_cost"):
		parts.append(_localized_text("PLAYER_TRAINING_AP_COST_FORMAT", "运动点数 %s") % str(option.get("ap_cost", option.get("action_points_cost", ""))))
	if option.has("time_cost"):
		parts.append(_localized_text("PLAYER_TRAINING_TIME_COST_FORMAT", "时间 %s") % str(option.get("time_cost")))
	if not parts.is_empty():
		return "｜".join(parts)
	return _localized_text("PLAYER_TRAINING_COST_DEFAULT", "占用本轮一次训练机会，不编造额外数值成本。")


func _resolve_training_disabled_reason(option: Dictionary[String, Variant]) -> String:
	var reason: String = str(option.get("disable_reason", option.get("disabled_reason", option.get("training_disable_reason", ""))))
	if reason.is_empty():
		return _localized_text("PLAYER_TRAINING_DISABLED", "训练暂不可用")
	return reason


func _resolve_training_risk_summary(option: Dictionary[String, Variant]) -> String:
	var explicit_risk: String = str(option.get("risk_summary", option.get("risk", option.get("tradeoff_summary", ""))))
	if not explicit_risk.is_empty():
		return explicit_risk
	if not bool(option.get("available", true)):
		return str(option.get("disable_reason", _localized_text("PLAYER_TRAINING_RISK_DISABLED", "当前条件不足，暂不建议执行。")))
	return _localized_text("PLAYER_TRAINING_RISK_DEFAULT", "会消耗本轮训练安排，其他球员本轮暂时得不到这次关注。")


func _resolve_training_next_step_summary(option: Dictionary[String, Variant]) -> String:
	var explicit_step: String = str(option.get("next_step_summary", ""))
	if not explicit_step.is_empty():
		return explicit_step
	if option.is_empty():
		return _localized_text("PLAYER_TRAINING_NEXT_STEP_PICK", "先选择一个训练项目。")
	return _localized_text("PLAYER_TRAINING_NEXT_STEP_CONFIRM", "确认训练后回到主页，看下一场比赛如何承接这次安排。")


func _resolve_training_payoff_summary(player: Dictionary[String, Variant], option: Dictionary[String, Variant]) -> String:
	var payoff_summary: String = str(option.get("payoff_summary", option.get("match_payoff_summary", player.get("training_payoff_summary", ""))))
	if not payoff_summary.is_empty():
		return payoff_summary
	return _localized_text("PLAYER_TRAINING_PAYOFF_DEFAULT", "完成后先回主页，下一场比赛和赛后表现会承接这次训练。")


func _build_attribute_summary_from_dictionary(value: Variant) -> String:
	if not (value is Dictionary):
		return _localized_text("PLAYER_ATTRIBUTES_PENDING", "暂无详细属性")
	var attributes: Dictionary = value as Dictionary
	var labels: Dictionary[String, String] = {
		"SPD": "速度",
		"PWR": "力量",
		"TEC": "技术",
		"INT": "智力",
		"STA": "体能",
	}
	var parts: Array[String] = []
	for key: String in ["SPD", "PWR", "TEC", "INT", "STA"]:
		if not attributes.has(key):
			continue
		var attribute_value: Variant = attributes[key]
		if attribute_value is Dictionary:
			var attribute_dictionary: Dictionary = attribute_value as Dictionary
			parts.append("%s %s/%s" % [labels[key], str(attribute_dictionary.get("current", "?")), str(attribute_dictionary.get("potential", "?"))])
		else:
			parts.append("%s %s" % [labels[key], str(attribute_value)])
	if parts.is_empty():
		return _localized_text("PLAYER_ATTRIBUTES_PENDING", "暂无详细属性")
	return "｜".join(parts)


func _compare_players_by_rating_desc(left: Dictionary, right: Dictionary) -> bool:
	return float(left.get("rating", left.get("positional_overall_rating", 0.0))) > float(right.get("rating", right.get("positional_overall_rating", 0.0)))


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


func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _to_dictionary_array(value: Variant) -> Array[Dictionary]:
	var typed_array: Array[Dictionary] = []
	if not (value is Array):
		return typed_array
	for element: Variant in value:
		if element is Dictionary:
			typed_array.append(_to_string_variant_dictionary(element))
	return typed_array


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	var source: Dictionary = value as Dictionary
	for key_variant: Variant in source.keys():
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary
