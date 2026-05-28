extends Button
## Reusable local tab button.
##
## This component is for in-screen tab sets only.
## It is not the global HUD navigation.

signal tab_activated(tab_index: int)

var _tab_index := 0
var _label_key := ""
var _selected := false
var _reduced_motion := false
var _pulse_tween: Tween

@onready var _indicator: Control = get_node_or_null("IndicatorBar")
@onready var _icon_rect: TextureRect = get_node_or_null("TabIcon")
@onready var _tab_label: Label = get_node_or_null("TabLabel")


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if EventBus:
		EventBus.subscribe("reduced_motion_changed", _on_reduced_motion_changed)
	if icon and _icon_rect:
		_icon_rect.texture = icon
		icon = null
	_refresh_visual_state()


func _exit_tree() -> void:
	if EventBus:
		EventBus.unsubscribe("reduced_motion_changed", _on_reduced_motion_changed)


func set_tab_icon(texture: Texture2D) -> void:
	if _icon_rect:
		_icon_rect.texture = texture


func set_tab_label(key: String) -> void:
	_label_key = key
	if _tab_label:
		_tab_label.text = tr(key)
	accessibility_name = tr(key)


func set_tab_index(index: int) -> void:
	_tab_index = index


func set_selected(selected: bool) -> void:
	_selected = selected
	button_pressed = selected
	_refresh_visual_state()


func set_active(active: bool) -> void:
	set_selected(active)


func set_pulse(enabled: bool) -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if not enabled:
		scale = Vector2.ONE
		return
	if _reduced_motion:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.5).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_IN)


func _on_pressed() -> void:
	tab_activated.emit(_tab_index)


func _on_mouse_entered() -> void:
	if _selected:
		return
	if _tab_label:
		_tab_label.add_theme_color_override("font_color", Color("EAEAEA"))
	if _icon_rect:
		_icon_rect.self_modulate = Color(1, 1, 1, 0.85)


func _on_mouse_exited() -> void:
	if _selected:
		return
	_refresh_visual_state()


func _on_reduced_motion_changed(_name: String, payload: Dictionary) -> void:
	_reduced_motion = payload.get("enabled", false)
	if _reduced_motion and _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
		scale = Vector2.ONE


func _refresh_visual_state() -> void:
	if _indicator:
		_indicator.visible = _selected
	if _tab_label:
		_tab_label.add_theme_color_override("font_color", Color("EAEAEA") if _selected else Color("9E9EB8"))
	if _icon_rect:
		_icon_rect.self_modulate = Color.WHITE if _selected else Color(1, 1, 1, 0.65)
	accessibility_description = _localized_text("SELECTED", "已选中") if _selected else ""


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized
