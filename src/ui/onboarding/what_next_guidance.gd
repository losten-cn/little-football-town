extends PanelContainer
## Non-modal current checkpoint guidance for the MVP loop.

const STEP_HOME: String = "home"
const STEP_ROSTER: String = "roster"
const STEP_TRAINING: String = "training"
const STEP_PRE_MATCH: String = "match_pre"
const STEP_RESULT: String = "match_result"
const STEP_DONE: String = "done"

var _current_route: String = STEP_HOME
var _current_step: String = STEP_HOME
var _dismissed: bool = false
var _training_completed: bool = false
var _result_seen: bool = false
var _anchor_available: bool = true
var _time_payload: Dictionary[String, Variant] = {}

var _box: VBoxContainer = null
var _hint_label: Label = null
var _target_label: Label = null
var _dismiss_button: Button = null


func _ready() -> void:
	name = "WhatNextGuidance"
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	_subscribe_events()
	_refresh()


func _exit_tree() -> void:
	EventBus.unsubscribe("time_advanced", _on_time_advanced)
	EventBus.unsubscribe("training_completed", _on_training_completed)
	EventBus.unsubscribe("player_action_completed", _on_player_action_completed)
	EventBus.unsubscribe("match_completed", _on_match_completed)
	EventBus.unsubscribe("match_result_confirmed", _on_match_result_confirmed)


## Sets the route context used by the current single guidance checkpoint.
func set_route(route_id: String) -> void:
	_current_route = route_id
	_advance_for_route(route_id)
	_dismissed = false
	_refresh()


## Applies authoritative time/match payload without recomputing game state.
func set_time_payload(payload: Dictionary[String, Variant]) -> void:
	_time_payload = payload.duplicate(true)
	_refresh()


## Marks whether the current suggested anchor exists in the mounted UI.
func set_anchor_available(is_available: bool) -> void:
	_anchor_available = is_available
	_refresh()


## Returns the active guidance step.
func get_current_step() -> String:
	return _current_step


## Returns the visible hint copy for tests and accessibility checks.
func get_hint_text() -> String:
	return _hint_label.text if _hint_label != null else ""


## Returns the visible target copy for tests and accessibility checks.
func get_target_text() -> String:
	return _target_label.text if _target_label != null else ""


func _setup_ui() -> void:
	add_theme_constant_override("content_margin_left", 10)
	add_theme_constant_override("content_margin_top", 8)
	add_theme_constant_override("content_margin_right", 10)
	add_theme_constant_override("content_margin_bottom", 8)

	_box = VBoxContainer.new()
	_box.name = "WhatNextBox"
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)

	_hint_label = Label.new()
	_hint_label.name = "WhatNextHintText"
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(_hint_label)

	_target_label = Label.new()
	_target_label.name = "WhatNextTarget"
	_target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(_target_label)

	_dismiss_button = Button.new()
	_dismiss_button.name = "WhatNextDismissButton"
	_dismiss_button.text = "知道了"
	_dismiss_button.focus_mode = Control.FOCUS_ALL
	_dismiss_button.pressed.connect(_on_dismiss_pressed)
	_box.add_child(_dismiss_button)


func _subscribe_events() -> void:
	EventBus.subscribe("time_advanced", _on_time_advanced)
	EventBus.subscribe("training_completed", _on_training_completed)
	EventBus.subscribe("player_action_completed", _on_player_action_completed)
	EventBus.subscribe("match_completed", _on_match_completed)
	EventBus.subscribe("match_result_confirmed", _on_match_result_confirmed)


func _on_time_advanced(_event_name: String, payload: Dictionary) -> void:
	set_time_payload(_to_string_variant_dictionary(payload))


func _on_training_completed(_event_name: String, _payload: Dictionary) -> void:
	_training_completed = true
	_current_step = STEP_PRE_MATCH
	_dismissed = false
	_refresh()


func _on_player_action_completed(_event_name: String, _payload: Dictionary) -> void:
	_training_completed = true
	_current_step = STEP_PRE_MATCH
	_dismissed = false
	_refresh()


func _on_match_completed(_event_name: String, _payload: Dictionary) -> void:
	_current_step = STEP_RESULT
	_dismissed = false
	_refresh()


func _on_match_result_confirmed(_event_name: String, _payload: Dictionary) -> void:
	_result_seen = true
	_current_step = STEP_DONE
	_dismissed = true
	_refresh()


func _advance_for_route(route_id: String) -> void:
	if _result_seen:
		_current_step = STEP_DONE
		return
	match route_id:
		STEP_HOME:
			if _training_completed:
				_current_step = STEP_PRE_MATCH
			else:
				_current_step = STEP_HOME
		STEP_ROSTER, "player_detail":
			if not _training_completed:
				_current_step = STEP_ROSTER
		STEP_TRAINING:
			if not _training_completed:
				_current_step = STEP_TRAINING
		STEP_PRE_MATCH, "match_live":
			_current_step = STEP_PRE_MATCH
		STEP_RESULT:
			_current_step = STEP_RESULT


func _refresh() -> void:
	if _hint_label == null:
		return
	visible = not _dismissed and _current_step != STEP_DONE
	_hint_label.text = _copy_for_step()
	_target_label.text = _target_for_step()
	_target_label.visible = not _target_label.text.is_empty()


func _copy_for_step() -> String:
	match _current_step:
		STEP_HOME:
			return "先看看球员"
		STEP_ROSTER:
			return "选一名球员"
		STEP_TRAINING:
			return "完成一次训练"
		STEP_PRE_MATCH:
			if _can_enter_match():
				return "开始这场比赛"
			return "等到比赛开启"
		STEP_RESULT:
			return "读结果并返回"
	return ""


func _target_for_step() -> String:
	if not _anchor_available:
		return "提示：当前页面没有高亮目标，请按上方提示继续。"
	match _current_step:
		STEP_HOME:
			return "目标：查看球员"
		STEP_ROSTER:
			return "目标：球员列表中的任意球员"
		STEP_TRAINING:
			return "目标：确认训练"
		STEP_PRE_MATCH:
			return "目标：开始比赛"
		STEP_RESULT:
			return "目标：确认结果并返回"
	return ""


func _can_enter_match() -> bool:
	return bool(_time_payload.get("match_trigger_reached", false)) and bool(_time_payload.get("match_center_available", false))


func _on_dismiss_pressed() -> void:
	_dismissed = true
	_refresh()


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	var source: Dictionary = value as Dictionary
	for key_variant: Variant in source.keys():
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary
