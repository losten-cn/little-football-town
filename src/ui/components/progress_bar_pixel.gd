extends Control
## Pixel-art progress bar for read-only HUD and screen displays.
##
## Provides threshold colors and reduced-motion aware updates.
## This control does not own labels outside its own optional value label.

const COLOR_HEALTHY := Color("FF9800")
const COLOR_WARNING := Color("FFC107")
const COLOR_DANGER := Color("E53935")
const COLOR_LABEL := Color("EAEAEA")

var _current_value := 0
var _max_value := 100
var _indeterminate := false
var _reduced_motion := false
var _track_width := 120.0
var _bar_height := 12.0
var _show_label := true
var _fill_direction := 1.0

@onready var _track_rect: ColorRect = $Track
@onready var _fill_rect: ColorRect = $Fill
@onready var _value_label: Label = $ValueLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	accessibility_name = _localized_text("HUD_PROGRESS_BAR", "进度条")
	if EventBus:
		EventBus.subscribe("reduced_motion_changed", _on_reduced_motion_changed)
	_refresh_display(false)


func _exit_tree() -> void:
	if EventBus:
		EventBus.unsubscribe("reduced_motion_changed", _on_reduced_motion_changed)


func configure(track_width: float, bar_height: int = 12, show_label: bool = true) -> void:
	_track_width = track_width
	_bar_height = float(bar_height)
	_show_label = show_label
	_track_rect.size = Vector2(_track_width, _bar_height)
	_fill_rect.size = Vector2.ZERO
	if _value_label:
		_value_label.visible = _show_label
		_value_label.position = Vector2(_track_width + 6.0, 0.0)
	_refresh_display(false)


func set_value(current: int, maximum: int) -> void:
	_current_value = clampi(current, 0, maxi(maximum, 1))
	_max_value = maxi(maximum, 1)
	_indeterminate = false
	_refresh_display(true)


func set_value_animated(current: int, maximum: int) -> void:
	set_value(current, maximum)


func set_indeterminate(enabled: bool) -> void:
	_indeterminate = enabled
	if not enabled:
		_fill_rect.position.x = 0.0
		_refresh_display(false)
		return
	_fill_rect.color = COLOR_HEALTHY
	_fill_rect.size = Vector2(_track_width * 0.3, _bar_height)
	_fill_rect.position = Vector2.ZERO
	if _show_label and _value_label:
		_value_label.text = _localized_text("HUD_LOADING", "加载中")


func get_ratio() -> float:
	return clampf(float(_current_value) / float(maxi(_max_value, 1)), 0.0, 1.0)


func _refresh_display(animated: bool) -> void:
	var ratio := get_ratio()
	var fill_width := float(roundi(_track_width * ratio))
	_fill_rect.color = _fill_color_for_ratio(ratio)
	if animated and not _reduced_motion:
		var tween := create_tween()
		tween.tween_property(_fill_rect, "size:x", fill_width, 0.2).set_ease(Tween.EASE_OUT)
	else:
		_fill_rect.size.x = fill_width
	_fill_rect.size.y = _bar_height
	if _show_label and _value_label:
		_value_label.text = "%d/%d" % [_current_value, _max_value]
		_value_label.add_theme_color_override("font_color", COLOR_LABEL)
		_value_label.add_theme_font_size_override("font_size", 10)
	accessibility_description = "%d / %d" % [_current_value, _max_value]


func _fill_color_for_ratio(ratio: float) -> Color:
	if ratio > 0.5:
		return COLOR_HEALTHY
	if ratio > 0.25:
		return COLOR_WARNING
	return COLOR_DANGER


func _on_reduced_motion_changed(_name: String, payload: Dictionary) -> void:
	_reduced_motion = payload.get("enabled", false)
	if _reduced_motion:
		_fill_rect.position.x = clampf(_fill_rect.position.x, 0.0, maxf(_track_width - _fill_rect.size.x, 0.0))


func _process(delta: float) -> void:
	if not _indeterminate or _reduced_motion:
		return
	var speed := 150.0 * _fill_direction
	_fill_rect.position.x += speed * delta
	if _fill_rect.position.x <= 0.0:
		_fill_rect.position.x = 0.0
		_fill_direction = 1.0
	elif _fill_rect.position.x >= _track_width - _fill_rect.size.x:
		_fill_rect.position.x = _track_width - _fill_rect.size.x
		_fill_direction = -1.0


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized
