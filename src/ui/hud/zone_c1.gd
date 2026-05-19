extends PanelContainer
## Zone C for the strict MVP HUD.
##
## Displays the two persistent navigation entries:
## - Roster
## - Match
##
## Expected node structure:
##   ZoneC1 (PanelContainer)
##     └── HBoxContainer
##           ├── Button "%RosterButton"
##           └── Button "%MatchButton"

@onready var _roster_button: BaseButton = %RosterButton
@onready var _match_button: BaseButton = %MatchButton

var _match_available := false


func _ready() -> void:
	_roster_button.pressed.connect(_on_roster_pressed)
	_match_button.pressed.connect(_on_match_pressed)
	_subscribe_events()
	_apply_accessibility()
	_update_match_button()
	_update_selection(ScreenManager.get_active_screen_id())


func _exit_tree() -> void:
	EventBus.unsubscribe("time_advanced", _on_time_advanced)
	EventBus.unsubscribe("screen_pushed", _on_screen_changed)
	EventBus.unsubscribe("screen_popped", _on_screen_changed)
	EventBus.unsubscribe("screen_stack_reset", _on_screen_changed)


func _subscribe_events() -> void:
	EventBus.subscribe("time_advanced", _on_time_advanced)
	EventBus.subscribe("screen_pushed", _on_screen_changed)
	EventBus.subscribe("screen_popped", _on_screen_changed)
	EventBus.subscribe("screen_stack_reset", _on_screen_changed)


func request_roster() -> void:
	_on_roster_pressed()


func request_match() -> void:
	_on_match_pressed()


func is_match_available() -> bool:
	return _match_available


func _on_roster_pressed() -> void:
	if ScreenManager.get_active_screen_id() == "roster":
		return
	EventBus.emit("screen_requested", {"screen_id": "roster"})


func _on_match_pressed() -> void:
	if not _match_available:
		return
	if ScreenManager.get_active_screen_id() == "match_pre":
		return
	EventBus.emit("screen_requested", {"screen_id": "match_pre"})


func _on_time_advanced(_name: String, payload: Dictionary) -> void:
	var has_match_state := payload.has("match_trigger_reached") or payload.has("schedule_missing") or payload.has("match_center_available") or payload.has("schedule_available")
	if not has_match_state:
		return

	var schedule_missing := bool(payload.get("schedule_missing", false))
	var schedule_available := bool(payload.get("schedule_available", not schedule_missing))
	var match_trigger_reached := bool(payload.get("match_trigger_reached", false))
	var match_center_available := bool(payload.get("match_center_available", true))

	_match_available = schedule_available and not schedule_missing and match_trigger_reached and match_center_available
	_update_match_button()


func _on_screen_changed(_name: String, _payload: Dictionary) -> void:
	_update_selection(ScreenManager.get_active_screen_id())


func _update_match_button() -> void:
	_match_button.disabled = not _match_available
	_match_button.focus_mode = Control.FOCUS_ALL if _match_available else Control.FOCUS_NONE
	_match_button.modulate = _theme_color("color_accent_primary_hover", Color.WHITE) if _match_available else _disabled_tint()
	_match_button.accessibility_description = _localized_text("HUD_MATCH_AVAILABLE", "比赛可进入") if _match_available else _localized_text("HUD_MATCH_UNAVAILABLE", "当前不可进入比赛")


func _update_selection(active_screen: String) -> void:
	var roster_selected := active_screen in ["roster", "player_detail", "training"]
	var match_selected := active_screen in ["match_pre", "match_live", "match_result"]
	_set_selected(_roster_button, roster_selected, false)
	_set_selected(_match_button, match_selected, _match_available)


func _set_selected(button: BaseButton, selected: bool, highlighted: bool) -> void:
	if button is Button:
		button.button_pressed = selected
	if button.disabled:
		button.modulate = _disabled_tint()
	elif selected and highlighted:
		button.modulate = _theme_color("color_accent_primary_hover", Color.WHITE)
	elif selected:
		button.modulate = Color.WHITE
	elif highlighted:
		button.modulate = _theme_color("color_accent_primary_hover", Color.WHITE)
	else:
		button.modulate = Color.WHITE


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized


func _apply_accessibility() -> void:
	_roster_button.accessibility_name = _localized_text("HUD_ROSTER_BUTTON", "球员")
	_match_button.accessibility_name = _localized_text("HUD_MATCH_BUTTON", "比赛")


func _theme_color(color_name: String, fallback: Color) -> Color:
	return get_theme_color(color_name) if has_theme_color(color_name) else fallback


func _disabled_tint() -> Color:
	var disabled := _theme_color("color_text_primary", Color.WHITE)
	disabled.a = 0.6
	return disabled
