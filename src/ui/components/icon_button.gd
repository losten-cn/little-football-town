extends Button
## Reusable icon button for keyboard/mouse HUD and screen controls.
##
## Supports:
## - icon texture assignment
## - optional tooltip event emission
## - optional badge count
## - reduced-motion aware press feedback

signal icon_focused(button_name: String)

var _keyboard_focused := false
var _tooltip_key := ""
var _reduced_motion := false

@onready var _highlight: Control = get_node_or_null("HighlightCircle")
@onready var _badge: Label = get_node_or_null("Badge")


func _ready() -> void:
	custom_minimum_size = Vector2(32, 32)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	accessibility_name = name
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	button_down.connect(_on_press_down)
	button_up.connect(_on_press_up)
	if EventBus:
		EventBus.subscribe("reduced_motion_changed", _on_reduced_motion_changed)
	if _highlight:
		_highlight.visible = false


func _exit_tree() -> void:
	if EventBus:
		EventBus.unsubscribe("reduced_motion_changed", _on_reduced_motion_changed)


func set_icon_tex(texture: Texture2D) -> void:
	icon = texture


func set_tooltip_key(key: String) -> void:
	_tooltip_key = key


func set_badge_count(count: int) -> void:
	if _badge == null:
		return
	_badge.visible = count > 0
	_badge.text = str(count) if count <= 99 else "99+"


func _on_mouse_entered() -> void:
	if _highlight:
		_highlight.visible = true
	if not _tooltip_key.is_empty():
		EventBus.emit("tooltip_requested", {"trigger_node": String(get_path()), "text_key": _tooltip_key})


func _on_mouse_exited() -> void:
	if _highlight and not _keyboard_focused:
		_highlight.visible = false
	EventBus.emit("tooltip_dismissed", {})


func _on_focus_entered() -> void:
	_keyboard_focused = true
	if _highlight:
		_highlight.visible = true
	icon_focused.emit(name)


func _on_focus_exited() -> void:
	_keyboard_focused = false
	if _highlight:
		_highlight.visible = false


func _on_press_down() -> void:
	if _reduced_motion:
		modulate = Color(1.0, 1.0, 1.0, 0.85)
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1).set_ease(Tween.EASE_OUT)


func _on_press_up() -> void:
	if _reduced_motion:
		modulate = Color.WHITE
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_IN_OUT)


func _on_reduced_motion_changed(_name: String, payload: Dictionary) -> void:
	_reduced_motion = payload.get("enabled", false)
	if _reduced_motion:
		scale = Vector2.ONE
		modulate = Color.WHITE
