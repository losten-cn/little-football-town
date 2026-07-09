extends Control
## L2 roster/player/training panel mounted by the MainLoop shell.

const ROUTE_ROSTER: String = "roster"
const ROUTE_PLAYER_DETAIL: String = "player_detail"
const ROUTE_TRAINING: String = "training"
const UI_COLOR_TEXT := Color("3A2A1A")
const UI_COLOR_MUTED := Color("6D5A3A")
const UI_COLOR_ACCENT := Color("C76A00")
const UI_COLOR_ACCENT_SOFT := Color("E8B05C")
const UI_COLOR_SURFACE := Color("F5DDA8")
const UI_COLOR_SURFACE_SOFT := Color("FBF0CF")
const UI_COLOR_SURFACE_DISABLED := Color("E8D9BC")
const UI_COLOR_BORDER := Color("C58A3A")
const UI_COLOR_BORDER_FOCUS := Color("8F4C00")
const UI_COLOR_SELECTED := Color("F2C46D")
const UI_COLOR_SELECTED_DEEP := Color("D7861A")

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
	_apply_town_button_style(_training_confirm_button, true, false)
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
	_apply_town_button_style(_return_home_button, false, false)
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
		empty_label.text = _localized_text("PLAYER_ROSTER_EMPTY", "现在还没有可安排的球员，先回主界面推进下一步。")
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", UI_COLOR_MUTED)
		_roster_list.add_child(empty_label)
		return
	for player: Dictionary in players:
		var typed_player: Dictionary[String, Variant] = _to_string_variant_dictionary(player)
		var row_button: Button = Button.new()
		row_button.name = "RosterRow_%s" % str(typed_player.get("id", "unknown"))
		row_button.focus_mode = Control.FOCUS_ALL
		_apply_town_button_style(row_button, false, str(typed_player.get("id", "")) == _selected_player_id)
		row_button.text = _format_roster_row(typed_player)
		row_button.pressed.connect(_on_roster_row_pressed.bind(typed_player))
		_roster_list.add_child(row_button)


func _mount_player_detail() -> void:
	_title_label.text = _localized_text("PLAYER_DETAIL_TITLE", "球员详情")
	_detail_summary.visible = true
	_detail_summary.text = _format_player_detail(_resolve_selected_player())
	_training_confirm_button.visible = true
	_training_confirm_button.name = "TrainingEntryButton"

	_training_confirm_button.text = _training_entry_text()
	_training_confirm_button.disabled = not _training_entry_available()
	_apply_town_button_style(_training_confirm_button, true, false)


func _mount_training() -> void:
	_title_label.text = _localized_text("PLAYER_TRAINING_TITLE", "训练安排")
	_detail_summary.visible = true
	_detail_summary.text = _format_player_detail(_resolve_selected_player())
	_training_option_list.visible = true
	_training_confirm_button.name = "TrainingConfirmButton"
	_training_confirm_button.visible = true
	_training_confirm_button.text = _training_confirm_text()
	_training_confirm_button.disabled = not _training_confirm_available()
	_apply_town_button_style(_training_confirm_button, true, false)
	_training_result_summary.visible = true
	_training_result_summary.text = _format_training_result()
	_mount_training_options()


func _mount_training_options() -> void:
	_clear_children(_training_option_list)
	var options: Array[Dictionary] = _get_training_options()
	if options.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = _localized_text("PLAYER_TRAINING_EMPTY", "当前没有可展示的训练安排，先返回上一层确认球员状态。")
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", UI_COLOR_MUTED)
		_training_option_list.add_child(empty_label)
		return
	for option: Dictionary in options:
		var typed_option: Dictionary[String, Variant] = _to_string_variant_dictionary(option)
		var option_id: String = str(typed_option.get("training_id", typed_option.get("id", "")))
		var option_button: Button = Button.new()
		option_button.name = "TrainingOption_%s" % option_id
		option_button.focus_mode = Control.FOCUS_ALL
		option_button.disabled = not bool(typed_option.get("available", true))
		_apply_town_button_style(option_button, false, option_id == _selected_training_id)
		option_button.text = _format_training_option(typed_option)
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
	if not _training_confirm_available():
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


func _training_confirm_available() -> bool:
	var selected_option: Dictionary[String, Variant] = _resolve_selected_training_option()
	return _training_entry_available() and not _selected_training_id.is_empty() and not selected_option.is_empty() and bool(selected_option.get("available", true))


func _training_entry_text() -> String:
	if _training_entry_available():
		return _localized_text("PLAYER_TRAINING_ENTRY", "进入训练安排")
	var disable_reason: String = _resolve_training_payload_disabled_reason()
	return _localized_text("PLAYER_TRAINING_ENTRY_DISABLED_FORMAT", "训练暂不可安排｜%s") % disable_reason


func _format_roster_row(player: Dictionary[String, Variant]) -> String:
	return _localized_text("PLAYER_ROSTER_ROW_FORMAT", "%s｜%s｜评分 %s\n梯队：%s｜状态：%s｜成长：%s\n关注：%s\n下一步：%s") % [
		str(player.get("name", _localized_text("PLAYER_UNKNOWN", "未知球员"))),
		str(player.get("position", player.get("primary_position", "?"))),
		str(player.get("rating", player.get("positional_overall_rating", "?"))),
		str(player.get("development_tier", player.get("tier", "-"))),
		_resolve_status_summary(player),
		_resolve_growth_summary(player),
		_resolve_roster_attention_reason(player),
		_resolve_roster_next_step(player),
	]


func _format_player_detail(player: Dictionary[String, Variant]) -> String:
	if player.is_empty():
		return _localized_text("PLAYER_DETAIL_NONE", "先从左侧名单里选择一名球员，再查看他的训练判断。")
	var reference_option: Dictionary[String, Variant] = _resolve_reference_training_option()
	return _localized_text("PLAYER_DETAIL_FORMAT", "身份\n%s｜%s｜评分 %s｜%s\n\n属性\n%s\n\n成长\n%s\n\n状态\n%s\n\n行动建议\n本轮判断：%s\n成本/回报：成本：%s；回报：%s\n下一步：%s") % [
		str(player.get("name", _localized_text("PLAYER_UNKNOWN", "未知球员"))),
		str(player.get("position", player.get("primary_position", "?"))),
		str(player.get("rating", player.get("positional_overall_rating", "?"))),
		str(player.get("development_tier", player.get("tier", "-"))),
		_resolve_attribute_summary(player),
		_resolve_growth_summary(player),
		_resolve_status_summary(player),
		_resolve_training_why_summary(player),
		_resolve_training_cost_summary(reference_option),
		_resolve_training_impact_summary(reference_option),
		_training_entry_text(),
	]


func _format_training_option(option: Dictionary[String, Variant]) -> String:
	var option_name: String = str(option.get("name", option.get("training_name", _localized_text("PLAYER_TRAINING_OPTION", "训练项目"))))
	var summary: String = str(option.get("summary", option.get("expected_gain_summary", _localized_text("PLAYER_TRAINING_EXPECTED_GAIN", "预计提升本次重点能力"))))
	var marker: String = _localized_text("PLAYER_SELECTED_MARKER", "已选") if str(option.get("training_id", option.get("id", ""))) == _selected_training_id else _localized_text("PLAYER_UNSELECTED_MARKER", "可选")
	var option_text: String = _localized_text("PLAYER_TRAINING_OPTION_FORMAT", "%s｜%s\n回报：%s\n成本：%s") % [
		marker,
		option_name,
		summary,
		_resolve_training_cost_summary(option),
	]
	if bool(option.get("available", true)):
		return option_text
	return _localized_text("PLAYER_TRAINING_OPTION_DISABLED_FORMAT", "%s\n当前不可安排：%s") % [option_text, _resolve_training_disabled_reason(option)]


func _format_training_result() -> String:
	var selected_option: Dictionary[String, Variant] = _resolve_selected_training_option()
	var result_summary: String = _localized_text("PLAYER_TRAINING_RESULT_PENDING", "确认安排后，这里会回顾本次训练带来的直接反馈。")
	if not _last_training_result.is_empty():
		result_summary = str(_last_training_result.get("summary", _last_training_result.get("result_summary", _localized_text("PLAYER_TRAINING_DONE", "训练已完成，近期状态已更新"))))
	var availability_summary: String = _resolve_training_result_availability_summary(selected_option)
	return _localized_text("PLAYER_TRAINING_DECISION_FORMAT", "本轮判断：%s\n当前选择：%s\n成本/回报：成本：%s；回报：%s\n可用性：%s\n下一步：%s\n结果：%s") % [
		_resolve_training_risk_summary(selected_option),
		_resolve_training_option_name(selected_option),
		_resolve_training_cost_summary(selected_option),
		_resolve_training_impact_summary(selected_option),
		availability_summary,
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
	return _localized_text("PLAYER_GROWTH_NONE", "本轮暂无新的成长反馈")


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
	return _localized_text("PLAYER_STATUS_GOOD", "状态稳定")


func _resolve_roster_attention_reason(player: Dictionary[String, Variant]) -> String:
	var explicit_reason: String = str(player.get("recommendation_reason", player.get("attention_reason", "")))
	if not explicit_reason.is_empty():
		return explicit_reason
	var rating: float = float(player.get("rating", player.get("positional_overall_rating", 0.0)))
	if rating >= 70.0:
		return _localized_text("PLAYER_ATTENTION_HIGH_RATING", "当前评分靠前，值得先看清这轮是否要把训练资源给他。")
	var growth_summary: String = _resolve_growth_summary(player)
	if growth_summary.contains("+"):
		return _localized_text("PLAYER_ATTENTION_GROWING", "近期有成长迹象，适合继续跟进这次培养窗口。")
	return _localized_text("PLAYER_ATTENTION_DEFAULT", "先确认状态，再决定这轮是否值得投入训练。")


func _resolve_roster_next_step(player: Dictionary[String, Variant]) -> String:
	var explicit_step: String = str(player.get("next_step_summary", ""))
	if not explicit_step.is_empty():
		return explicit_step
	if _resolve_status_summary(player).contains("可训练"):
		return _localized_text("PLAYER_NEXT_STEP_TRAIN", "进入详情后看训练安排。")
	return _localized_text("PLAYER_NEXT_STEP_DETAIL", "进入详情确认他的当前状态。")


func _training_confirm_text() -> String:
	if not _training_entry_available():
		return _localized_text("PLAYER_TRAINING_CONFIRM_DISABLED_BY_ENTRY_FORMAT", "当前不能确认｜%s") % _resolve_training_payload_disabled_reason()
	var selected_option: Dictionary[String, Variant] = _resolve_selected_training_option()
	if selected_option.is_empty():
		return _localized_text("PLAYER_TRAINING_CONFIRM_PICK_FIRST", "先选择训练项目")
	if not bool(selected_option.get("available", true)):
		return _localized_text("PLAYER_TRAINING_CONFIRM_DISABLED_FORMAT", "当前不能确认｜%s") % _resolve_training_disabled_reason(selected_option)
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
		return _localized_text("PLAYER_TRAINING_WHY_READY", "这名球员正处在值得加练的窗口，本轮投入更容易看见反馈。")
	return _localized_text("PLAYER_TRAINING_WHY_DEFAULT", "先把训练资源给最值得观察的球员，下一场比赛更容易形成反馈闭环。")


func _resolve_training_impact_summary(option: Dictionary[String, Variant]) -> String:
	if option.is_empty():
		return _localized_text("PLAYER_TRAINING_IMPACT_DEFAULT", "会影响这轮训练反馈与下一场赛前判断。")
	var summary: String = str(option.get("summary", option.get("expected_gain_summary", "")))
	if not summary.is_empty():
		return summary
	return _localized_text("PLAYER_TRAINING_IMPACT_DEFAULT", "会影响这轮训练反馈与下一场赛前判断。")


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
	return _localized_text("PLAYER_TRAINING_COST_DEFAULT", "本轮不额外编造数值，只显示权威训练成本。")


func _resolve_training_disabled_reason(option: Dictionary[String, Variant]) -> String:
	var reason: String = str(option.get("disable_reason", option.get("disabled_reason", option.get("training_disable_reason", ""))))
	if reason.is_empty():
		return _localized_text("PLAYER_TRAINING_DISABLED", "暂不可安排")
	return reason


func _resolve_training_payload_disabled_reason() -> String:
	var reason: String = str(_training_payload.get("disable_reason", _training_payload.get("training_disable_reason", "")))
	if reason.is_empty():
		return _localized_text("PLAYER_TRAINING_DISABLED", "暂不可安排")
	return reason


func _resolve_training_risk_summary(option: Dictionary[String, Variant]) -> String:
	var explicit_risk: String = str(option.get("risk_summary", option.get("risk", option.get("tradeoff_summary", ""))))
	if not explicit_risk.is_empty():
		return explicit_risk
	if option.is_empty():
		return _localized_text("PLAYER_TRAINING_RISK_PICK_FIRST", "先定下训练项目，才能判断这轮资源要给谁。")
	if not bool(option.get("available", true)):
		return _resolve_training_disabled_reason(option)
	return _localized_text("PLAYER_TRAINING_RISK_DEFAULT", "这会占用本轮训练机会，其他球员本轮将先维持现状。")


func _resolve_training_next_step_summary(option: Dictionary[String, Variant]) -> String:
	var explicit_step: String = str(option.get("next_step_summary", ""))
	if not explicit_step.is_empty():
		return explicit_step
	if not _training_entry_available():
		return _localized_text("PLAYER_TRAINING_NEXT_STEP_WAIT", "先解决不可安排原因，再回来看训练选择。")
	if option.is_empty():
		return _localized_text("PLAYER_TRAINING_NEXT_STEP_PICK", "先选择一个训练项目。")
	if not bool(option.get("available", true)):
		return _localized_text("PLAYER_TRAINING_NEXT_STEP_BLOCKED", "换一个可安排项目，或先解决当前限制。")
	return _localized_text("PLAYER_TRAINING_NEXT_STEP_CONFIRM", "确认训练后回到主页，观察下一场比赛如何承接这次安排。")


func _resolve_training_result_availability_summary(option: Dictionary[String, Variant]) -> String:
	if not _training_entry_available():
		return _localized_text("PLAYER_TRAINING_AVAILABILITY_ENTRY_BLOCKED_FORMAT", "训练入口未开放：%s") % _resolve_training_payload_disabled_reason()
	if option.is_empty():
		return _localized_text("PLAYER_TRAINING_AVAILABILITY_PICK_FIRST", "还没选定训练项目")
	if not bool(option.get("available", true)):
		return _localized_text("PLAYER_TRAINING_AVAILABILITY_OPTION_BLOCKED_FORMAT", "当前项目不可安排：%s") % _resolve_training_disabled_reason(option)
	return _localized_text("PLAYER_TRAINING_AVAILABILITY_READY", "当前项目可以安排")


func _build_attribute_summary_from_dictionary(value: Variant) -> String:
	if not (value is Dictionary):
		return _localized_text("PLAYER_ATTRIBUTES_PENDING", "当前还没有可显示的属性摘要")
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
			var current_value: String = str(attribute_dictionary.get("current", "?"))
			var potential_value: String = str(attribute_dictionary.get("potential", "?"))
			var cap_marker: String = ""
			if current_value == potential_value and current_value != "?":
				cap_marker = _localized_text("PLAYER_ATTRIBUTE_CAPPED_MARKER", "（已接近上限）")
			parts.append("%s %s/100｜潜力 %s%s" % [labels[key], current_value, potential_value, cap_marker])
		else:
			parts.append("%s %s/100" % [labels[key], str(attribute_value)])
	if parts.is_empty():
		return _localized_text("PLAYER_ATTRIBUTES_PENDING", "当前还没有可显示的属性摘要")
	return "\n".join(parts)


func _compare_players_by_rating_desc(left: Dictionary, right: Dictionary) -> bool:
	return float(left.get("rating", left.get("positional_overall_rating", 0.0))) > float(right.get("rating", right.get("positional_overall_rating", 0.0)))


func _town_button_style(is_primary: bool, is_selected: bool, state: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_content_margin_individual(10.0, 8.0, 10.0, 8.0)
	style.set_border_width_all(1)
	match state:
		"disabled":
			style.bg_color = UI_COLOR_SURFACE_DISABLED
			style.border_color = UI_COLOR_MUTED
			style.set_border_width_all(1)
		"hover":
			style.bg_color = UI_COLOR_SELECTED if is_selected else UI_COLOR_ACCENT_SOFT if is_primary else UI_COLOR_SURFACE_SOFT
			style.border_color = UI_COLOR_SELECTED_DEEP if is_selected else UI_COLOR_BORDER_FOCUS
			style.set_border_width_all(2)
		"pressed":
			style.bg_color = UI_COLOR_SELECTED_DEEP if is_selected else UI_COLOR_ACCENT if is_primary else UI_COLOR_SELECTED
			style.border_color = UI_COLOR_BORDER_FOCUS
			style.set_border_width_all(2)
		"focus":
			style.bg_color = UI_COLOR_SELECTED if is_selected else UI_COLOR_ACCENT_SOFT if is_primary else UI_COLOR_SURFACE_SOFT
			style.border_color = UI_COLOR_BORDER_FOCUS
			style.set_border_width_all(3)
		_:
			style.bg_color = UI_COLOR_SELECTED if is_selected else UI_COLOR_ACCENT if is_primary else UI_COLOR_SURFACE
			style.border_color = UI_COLOR_SELECTED_DEEP if is_selected else UI_COLOR_BORDER
	return style


func _apply_town_button_style(button: Button, is_primary: bool, is_selected: bool) -> void:
	button.add_theme_stylebox_override("normal", _town_button_style(is_primary, is_selected, "normal"))
	button.add_theme_stylebox_override("hover", _town_button_style(is_primary, is_selected, "hover"))
	button.add_theme_stylebox_override("pressed", _town_button_style(is_primary, is_selected, "pressed"))
	button.add_theme_stylebox_override("focus", _town_button_style(is_primary, is_selected, "focus"))
	button.add_theme_stylebox_override("disabled", _town_button_style(is_primary, is_selected, "disabled"))
	button.add_theme_color_override("font_color", Color.WHITE if is_primary or is_selected else UI_COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE if is_primary or is_selected else UI_COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", Color.WHITE if is_primary or is_selected else UI_COLOR_TEXT)
	button.add_theme_color_override("font_focus_color", Color.WHITE if is_primary or is_selected else UI_COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", UI_COLOR_MUTED)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


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
