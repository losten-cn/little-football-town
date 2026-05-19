extends Control
## Toast notification manager.
##
## Displays lightweight non-blocking feedback in the top-right corner.
## This overlay is read-only and never takes focus.

const MAX_VISIBLE_TOASTS := 3
const DISPLAY_DURATION := 3.0
const FADE_DURATION := 0.2
const REDUCED_MOTION_DURATION := 0.05

enum Level { INFO, SUCCESS, WARNING, ERROR }

var _queue: Array[Dictionary] = []
var _visible_toasts: Array[PanelContainer] = []
var _toast_serials: Dictionary = {}
var _reduced_motion := false

@onready var _vbox: VBoxContainer = $VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.subscribe("notification_queued", _on_notification_queued)
	EventBus.subscribe("reduced_motion_changed", _on_reduced_motion_changed)


func _exit_tree() -> void:
	EventBus.unsubscribe("notification_queued", _on_notification_queued)
	EventBus.unsubscribe("reduced_motion_changed", _on_reduced_motion_changed)


func _on_notification_queued(_name: String, payload: Dictionary) -> void:
	var message: String = payload.get("message", "")
	if message.is_empty():
		return
	var level: int = payload.get("level", Level.INFO)
	_queue.push_back({"message": message, "level": level})
	if _visible_toasts.size() < MAX_VISIBLE_TOASTS:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty() or _visible_toasts.size() >= MAX_VISIBLE_TOASTS:
		return
	var data: Dictionary = _queue.pop_front()
	var toast := _create_toast(data.get("message", ""), data.get("level", Level.INFO))
	_visible_toasts.push_back(toast)
	_toast_serials[toast] = true
	_vbox.add_child(toast)
	if _reduced_motion:
		toast.modulate.a = 0.0
		toast.position.x = 0.0
		var fade_in := create_tween()
		fade_in.tween_property(toast, "modulate:a", 1.0, REDUCED_MOTION_DURATION).set_ease(Tween.EASE_OUT)
	else:
		toast.position.x = toast.custom_minimum_size.x
		var tween := create_tween()
		tween.tween_property(toast, "position:x", 0.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(DISPLAY_DURATION).timeout.connect(_dismiss_toast.bind(toast))


func _create_toast(message: String, level: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 48)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", _color_for_level(level))
	panel.add_child(label)
	return panel


func _dismiss_toast(toast_object: Variant) -> void:
	if not is_instance_valid(toast_object) or not _toast_serials.has(toast_object):
		return
	var toast := toast_object as PanelContainer
	if toast == null:
		return
	var duration := REDUCED_MOTION_DURATION if _reduced_motion else FADE_DURATION
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(toast.queue_free)
	_visible_toasts.erase(toast)
	_toast_serials.erase(toast)
	await tween.finished
	if not _queue.is_empty():
		_show_next()


func clear_toasts() -> void:
	_queue.clear()
	_toast_serials.clear()
	for toast in _visible_toasts:
		if is_instance_valid(toast):
			toast.queue_free()
	_visible_toasts.clear()


func _on_reduced_motion_changed(_name: String, payload: Dictionary) -> void:
	_reduced_motion = payload.get("enabled", false)


func _color_for_level(level: int) -> Color:
	match level:
		Level.SUCCESS:
			return _theme_color("color_semantic_success", Color.WHITE)
		Level.WARNING:
			return _theme_color("color_semantic_warning", Color.WHITE)
		Level.ERROR:
			return _theme_color("color_semantic_danger", Color.WHITE)
		_:
			return _theme_color("color_text_primary", Color.WHITE)


func _theme_color(color_name: String, fallback: Color) -> Color:
	return get_theme_color(color_name) if has_theme_color(color_name) else fallback
