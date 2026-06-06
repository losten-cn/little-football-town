extends Control
## L2 roster/player/training panel mounted by the MainLoop shell.

const ROUTE_ROSTER: String = "roster"
const ROUTE_PLAYER_DETAIL: String = "player_detail"
const ROUTE_TRAINING: String = "training"

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
	_root_box.add_theme_constant_override("separation", 12)
	add_child(_root_box)

	_title_label = Label.new()
	_title_label.name = "PlayerMgmtTitle"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(_title_label)

	_roster_list = VBoxContainer.new()
	_roster_list.name = "RosterList"
	_roster_list.add_theme_constant_override("separation", 6)
	_root_box.add_child(_roster_list)

	_detail_summary = Label.new()
	_detail_summary.name = "PlayerDetailSummary"
	_detail_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root_box.add_child(_detail_summary)

	_training_option_list = VBoxContainer.new()
	_training_option_list.name = "TrainingOptionList"
	_training_option_list.add_theme_constant_override("separation", 6)
	_root_box.add_child(_training_option_list)

	_training_confirm_button = Button.new()
	_training_confirm_button.name = "TrainingConfirmButton"
	_training_confirm_button.focus_mode = Control.FOCUS_ALL
	_training_confirm_button.pressed.connect(_on_training_confirm_pressed)
	_root_box.add_child(_training_confirm_button)

	_training_result_summary = Label.new()
	_training_result_summary.name = "TrainingResultSummary"
	_training_result_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root_box.add_child(_training_result_summary)

	_return_home_button = Button.new()
	_return_home_button.name = "ReturnHomeButton"
	_return_home_button.text = "返回 Home"
	_return_home_button.focus_mode = Control.FOCUS_ALL
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
	_title_label.text = "球员列表"
	_roster_list.visible = true
	var players: Array[Dictionary] = _get_players_sorted_by_rating()
	if players.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "无匹配球员"
		_roster_list.add_child(empty_label)
		return
	for player: Dictionary in players:
		var row_button: Button = Button.new()
		row_button.name = "RosterRow_%s" % str(player.get("id", "unknown"))
		row_button.focus_mode = Control.FOCUS_ALL
		row_button.text = _format_roster_row(player)
		row_button.pressed.connect(_on_roster_row_pressed.bind(player))
		_roster_list.add_child(row_button)


func _mount_player_detail() -> void:
	_title_label.text = "球员详情"
	_detail_summary.visible = true
	_detail_summary.text = _format_player_detail(_resolve_selected_player())
	_training_confirm_button.visible = true
	_training_confirm_button.name = "TrainingEntryButton"
	_training_confirm_button.text = _training_entry_text()
	_training_confirm_button.disabled = not _training_entry_available()


func _mount_training() -> void:
	_title_label.text = "训练"
	_detail_summary.visible = true
	_detail_summary.text = _format_player_detail(_resolve_selected_player())
	_training_option_list.visible = true
	_training_confirm_button.name = "TrainingConfirmButton"
	_training_confirm_button.visible = true
	_training_confirm_button.text = "确认训练"
	_training_confirm_button.disabled = not _training_entry_available() or _selected_training_id.is_empty()
	_training_result_summary.visible = true
	_training_result_summary.text = _format_training_result()
	_mount_training_options()


func _mount_training_options() -> void:
	_clear_children(_training_option_list)
	var options: Array[Dictionary] = _get_training_options()
	if options.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "暂无训练项目"
		_training_option_list.add_child(empty_label)
		return
	for option: Dictionary in options:
		var option_id: String = str(option.get("training_id", option.get("id", "")))
		var option_button: Button = Button.new()
		option_button.name = "TrainingOption_%s" % option_id
		option_button.focus_mode = Control.FOCUS_ALL
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
	_selected_player = players[0]
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
		return "进入训练"
	return str(_training_payload.get("disable_reason", _training_payload.get("training_disable_reason", "训练暂不可用")))


func _format_roster_row(player: Dictionary) -> String:
	return "%s | %s | 评分 %s | %s | %s | %s" % [
		str(player.get("name", "未知球员")),
		str(player.get("position", player.get("primary_position", "?"))),
		str(player.get("rating", player.get("positional_overall_rating", "?"))),
		str(player.get("development_tier", player.get("tier", "-"))),
		str(player.get("status_tag", player.get("status", "正常"))),
		str(player.get("recent_growth", player.get("growth_summary", "成长待同步"))),
	]


func _format_player_detail(player: Dictionary[String, Variant]) -> String:
	if player.is_empty():
		return "未选择球员"
	return "身份：%s / %s / %s\n属性：%s\n成长：%s\n状态：%s\n行动：%s" % [
		str(player.get("name", "未知球员")),
		str(player.get("position", player.get("primary_position", "?"))),
		str(player.get("development_tier", player.get("tier", "-"))),
		str(player.get("attributes_summary", player.get("attributes", "属性待同步"))),
		str(player.get("growth_summary", "成长待同步")),
		str(player.get("status_summary", player.get("status", "状态待同步"))),
		_training_entry_text(),
	]


func _format_training_option(option: Dictionary) -> String:
	var marker: String = "* " if str(option.get("training_id", option.get("id", ""))) == _selected_training_id else ""
	return "%s%s — %s" % [
		marker,
		str(option.get("name", option.get("training_name", "训练项目"))),
		str(option.get("summary", option.get("expected_gain_summary", "效果待同步"))),
	]


func _format_training_result() -> String:
	if _last_training_result.is_empty():
		return "训练结果待同步"
	return str(_last_training_result.get("summary", _last_training_result.get("result_summary", "训练已完成")))


func _compare_players_by_rating_desc(left: Dictionary, right: Dictionary) -> bool:
	return float(left.get("rating", left.get("positional_overall_rating", 0.0))) > float(right.get("rating", right.get("positional_overall_rating", 0.0)))


func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
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
