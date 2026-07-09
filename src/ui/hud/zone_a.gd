extends PanelContainer
## Zone A for the strict MVP HUD.
##
## Displays:
## - current date / season stage
## - funds
## - action points
## - available action windows
## - next match status
## - pause menu button
##
## Expected node structure:
##   ZoneA (PanelContainer)
##     └── HBoxContainer
##           ├── Button "DateButton"
##           │     └── Label "%DateValue"
##           ├── HBoxContainer "FundsGroup"
##           │     ├── Label "%FundsValue"
##           │     └── Label "%FundsDelta"
##           ├── HBoxContainer "ActionPointsGroup"
##           │     ├── ProgressBarPixel "%ActionPointsProgress"
##           │     └── Label "%ActionPointsValue"
##           ├── Label "%ActionWindowsValue"
##           ├── Button "NextMatchButton"
##           │     └── Label "%NextMatchValue"
##           └── Button "MenuButton"

const Palette := preload("res://src/ui/hud/warm_palette.gd")

@onready var _date_button: BaseButton = %DateButton
@onready var _date_value: Label = %DateValue
@onready var _funds_value: Label = %FundsValue
@onready var _funds_delta: Label = %FundsDelta
@onready var _action_points_progress: Control = %ActionPointsProgress
@onready var _action_points_value: Label = %ActionPointsValue
@onready var _action_windows_value: Label = %ActionWindowsValue
@onready var _next_match_button: BaseButton = %NextMatchButton
@onready var _next_match_value: Label = %NextMatchValue
@onready var _menu_button: BaseButton = %MenuButton

var _schedule_available := false
var _match_available := false


func _ready() -> void:
	_setup_buttons()
	_apply_accessibility()
	_apply_loading_state()
	_subscribe_events()


func _exit_tree() -> void:
	EventBus.unsubscribe("time_advanced", _on_time_advanced)
	EventBus.unsubscribe("funds_changed", _on_funds_changed)
	EventBus.unsubscribe("ap_changed", _on_action_points_changed)


func _setup_buttons() -> void:
	_date_button.pressed.connect(_on_date_pressed)
	_next_match_button.pressed.connect(_on_next_match_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_menu_button.focus_mode = Control.FOCUS_ALL
	_set_button_enabled(_date_button, false)
	_set_button_enabled(_next_match_button, false)


func _apply_loading_state() -> void:
	_date_value.text = _localized_text("HUD_TIME_LOADING", "时间加载中")
	_funds_value.text = _localized_text("HUD_FUNDS_LOADING", "经费加载中")
	_funds_delta.visible = false
	_action_points_value.text = _localized_text("HUD_AP_LOADING", "点数加载中")
	_action_windows_value.text = _localized_text("HUD_ACTION_WINDOWS_LOADING", "窗口加载中")
	_next_match_value.text = _localized_text("HUD_SCHEDULE_LOADING", "赛程加载中")


func _subscribe_events() -> void:
	EventBus.subscribe("time_advanced", _on_time_advanced)
	EventBus.subscribe("funds_changed", _on_funds_changed)
	EventBus.subscribe("ap_changed", _on_action_points_changed)


func _on_time_advanced(_name: String, payload: Dictionary) -> void:
	_update_date(payload)
	_update_action_windows(payload)
	_update_next_match(payload)


func _on_funds_changed(_name: String, payload: Dictionary) -> void:
	if not payload.has("current"):
		return

	var current := float(payload.get("current", 0.0))
	_funds_value.text = _format_currency(current)

	var old_value := float(payload.get("old_value", current))
	var delta := current - old_value
	if abs(delta) <= 0.01:
		_funds_delta.visible = false
		return

	_funds_delta.visible = true
	_funds_delta.text = "▲ %d" % int(round(delta)) if delta > 0.0 else "▼ %d" % int(round(abs(delta)))
	_funds_delta.modulate = _theme_color("color_semantic_success", Color.WHITE) if delta > 0.0 else _theme_color("color_semantic_danger", Color.WHITE)


func _on_action_points_changed(_name: String, payload: Dictionary) -> void:
	if not payload.has("current"):
		return

	var current := int(payload.get("current", 0))
	var maximum := int(payload.get("max", 0))
	if maximum <= 0:
		maximum = 1

	_action_points_value.text = "%d/%d" % [current, maximum]
	if _action_points_progress.has_method("set_value_animated"):
		_action_points_progress.call("set_value_animated", current, maximum)
	elif _action_points_progress.has_method("set_value"):
		_action_points_progress.call("set_value", current, maximum)


func _update_date(payload: Dictionary) -> void:
	var date_display: String = payload.get("date_display", "")
	if date_display.is_empty():
		date_display = _localized_text("HUD_TIME_LOADING", "时间加载中")
	_date_value.text = date_display

	if payload.has("schedule_available"):
		_schedule_available = payload.get("schedule_available", false)
		_set_button_enabled(_date_button, _schedule_available)


func _update_action_windows(payload: Dictionary) -> void:
	if not payload.has("available_action_windows"):
		return
	var count := int(payload.get("available_action_windows", 0))
	_action_windows_value.text = _localized_text("HUD_ACTION_WINDOWS_FORMAT", "%d 可用") % count


func _update_next_match(payload: Dictionary) -> void:
	var has_match_signal := payload.has("match_trigger_reached") or payload.has("schedule_missing") or payload.has("schedule_loading") or payload.has("next_match_display") or payload.has("opponent_name") or payload.has("match_center_available")
	if not has_match_signal:
		return

	if payload.get("schedule_loading", false):
		_match_available = false
		_next_match_value.text = _localized_text("HUD_SCHEDULE_LOADING", "赛程加载中")
		_set_button_enabled(_next_match_button, false)
		return

	if payload.get("schedule_missing", false):
		_match_available = false
		_next_match_value.text = _localized_text("HUD_SCHEDULE_PENDING", "赛程待公布")
		_set_button_enabled(_next_match_button, false)
		return

	var opponent_name: String = payload.get("opponent_name", "")
	var next_match_display: String = payload.get("next_match_display", "")
	var match_trigger_reached := bool(payload.get("match_trigger_reached", false))
	var match_center_available := bool(payload.get("match_center_available", true))
	var has_schedule := bool(payload.get("schedule_available", not next_match_display.is_empty() or not opponent_name.is_empty()))

	_match_available = has_schedule and match_trigger_reached and match_center_available
	if _match_available:
		if opponent_name.is_empty():
			_next_match_value.text = _localized_text("HUD_MATCH_READY", "比赛已可开始")
		else:
			_next_match_value.text = _localized_text("HUD_MATCH_READY_VS", "对阵 %s") % opponent_name
		_set_button_enabled(_next_match_button, true, true)
		return

	if not next_match_display.is_empty():
		_next_match_value.text = next_match_display
	elif not opponent_name.is_empty():
		_next_match_value.text = _localized_text("HUD_NEXT_MATCH_VS", "下一场：%s") % opponent_name
	else:
		_next_match_value.text = _localized_text("HUD_SCHEDULE_PENDING", "赛程待公布")
	_set_button_enabled(_next_match_button, false)


func _on_date_pressed() -> void:
	if not _schedule_available:
		return
	EventBus.emit("screen_requested", {"screen_id": "schedule"})


func _on_next_match_pressed() -> void:
	if not _match_available:
		return
	EventBus.emit("screen_requested", {"screen_id": "match_pre"})


func _on_menu_pressed() -> void:
	EventBus.emit("pause_requested", {})


func _set_button_enabled(button: BaseButton, enabled: bool, highlighted: bool = false) -> void:
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if enabled and highlighted:
		button.modulate = Palette.CLUB_RED
	elif enabled:
		button.modulate = Color.WHITE
	else:
		button.modulate = _disabled_tint()


func _format_currency(value: float) -> String:
	return str(int(round(value)))


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized


func _apply_accessibility() -> void:
	_date_button.accessibility_name = _localized_text("HUD_DATE_BUTTON", "日期")
	_funds_value.accessibility_name = _localized_text("HUD_FUNDS_DISPLAY", "经费")
	_action_points_progress.accessibility_name = _localized_text("HUD_AP_PROGRESS", "运动点数")
	_action_windows_value.accessibility_name = _localized_text("HUD_ACTION_WINDOWS", "行动窗口")
	_next_match_button.accessibility_name = _localized_text("HUD_NEXT_MATCH", "下一场比赛")
	_menu_button.accessibility_name = _localized_text("HUD_MENU_BUTTON", "菜单")


func _theme_color(color_name: String, fallback: Color) -> Color:
	return get_theme_color(color_name) if has_theme_color(color_name) else fallback


func _disabled_tint() -> Color:
	var disabled := Palette.DISABLED_OVERLAY
	return disabled
