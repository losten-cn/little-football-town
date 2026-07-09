extends PanelContainer
## Read-only Audio Settings panel with three volume sliders.
##
## This is a minimum Alpha presentation stub. It does not implement audio
## playback, bus mapping, BGM streaming, SFX pooling, mute categories,
## ambience volume, or save/load persistence. It only renders Master Volume,
## BGM Volume, and SFX Volume as horizontal sliders, reads authoritative
## state from AudioManager.build_audio_settings_payload() on show, and
## writes user edits through AudioManager.set_*_volume() entry points.
##
## The UI never owns volume truth locally — sliders are refreshed from the
## authoritative payload on every show, and changes go through AudioManager
## immediately via value_changed signal.

const UI_COLOR_TEXT := Color("3A2A1A")
const UI_COLOR_MUTED := Color("6D5A3A")
const UI_COLOR_ACCENT := Color("C76A00")
const UI_COLOR_SURFACE := Color("F5DDA8")
const UI_COLOR_BORDER := Color("C58A3A")
const UI_COLOR_PANEL_BG := Color("FFF8E8")
const UI_COLOR_PANEL_BORDER := Color("D8A85A")

const DEFAULT_VOLUME: float = 1.0
const VOLUME_MIN: float = 0.0
const VOLUME_MAX: float = 1.0
const VOLUME_STEP: float = 0.05

var _root_box: VBoxContainer = null
var _title_label: Label = null
var _master_slider: HSlider = null
var _bgm_slider: HSlider = null
var _sfx_slider: HSlider = null
var _close_button: Button = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	visible = false


## Refreshes all slider values from AudioManager.build_audio_settings_payload().
## If AudioManager is unavailable, sliders default to 1.0 (neutral fallback).
func refresh_from_authority() -> void:
	var master_val: float = DEFAULT_VOLUME
	var bgm_val: float = DEFAULT_VOLUME
	var sfx_val: float = DEFAULT_VOLUME

	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("build_audio_settings_payload"):
		var payload: Dictionary[String, Variant] = audio_manager.call("build_audio_settings_payload")
		master_val = float(payload.get("audio_master_volume", DEFAULT_VOLUME))
		bgm_val = float(payload.get("audio_bgm_volume", DEFAULT_VOLUME))
		sfx_val = float(payload.get("audio_sfx_volume", DEFAULT_VOLUME))

	if _master_slider != null:
		_master_slider.set_value_no_signal(master_val)
	if _bgm_slider != null:
		_bgm_slider.set_value_no_signal(bgm_val)
	if _sfx_slider != null:
		_sfx_slider.set_value_no_signal(sfx_val)


func _setup_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = UI_COLOR_PANEL_BG
	panel_style.border_color = UI_COLOR_PANEL_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(12.0)
	add_theme_stylebox_override("panel", panel_style)

	_root_box = VBoxContainer.new()
	_root_box.name = "AudioSettingsRoot"
	_root_box.add_theme_constant_override("separation", 10)
	add_child(_root_box)

	_title_label = Label.new()
	_title_label.name = "AudioSettingsTitle"
	_title_label.text = _localized_text("AUDIO_SETTINGS_TITLE", "音频设置")
	_title_label.add_theme_color_override("font_color", UI_COLOR_ACCENT)
	_title_label.add_theme_font_size_override("font_size", 16)
	_root_box.add_child(_title_label)

	_master_slider = _create_slider_row(_localized_text("AUDIO_MASTER_LABEL", "主音量"))
	_root_box.add_child(_master_slider.get_parent())
	_master_slider.value_changed.connect(_on_master_volume_changed)

	_bgm_slider = _create_slider_row(_localized_text("AUDIO_BGM_LABEL", "背景音乐"))
	_root_box.add_child(_bgm_slider.get_parent())
	_bgm_slider.value_changed.connect(_on_bgm_volume_changed)

	_sfx_slider = _create_slider_row(_localized_text("AUDIO_SFX_LABEL", "音效"))
	_root_box.add_child(_sfx_slider.get_parent())
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	_close_button = Button.new()
	_close_button.name = "AudioSettingsCloseButton"
	_close_button.text = _localized_text("AUDIO_SETTINGS_CLOSE", "关闭")
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_apply_button_style(_close_button)
	_close_button.pressed.connect(_on_close_pressed)
	_root_box.add_child(_close_button)


func _create_slider_row(label_text: String) -> HSlider:
	var row := HBoxContainer.new()
	row.name = "%sRow" % label_text.replace(" ", "")
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.name = "%sLabel" % label_text.replace(" ", "")
	lbl.text = label_text
	lbl.add_theme_color_override("font_color", UI_COLOR_TEXT)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.custom_minimum_size = Vector2(100, 0)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.name = "%sSlider" % label_text.replace(" ", "")
	slider.min_value = VOLUME_MIN
	slider.max_value = VOLUME_MAX
	slider.step = VOLUME_STEP
	slider.value = DEFAULT_VOLUME
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(200, 0)
	row.add_child(slider)

	var value_label := Label.new()
	value_label.name = "%sValue" % label_text.replace(" ", "")
	value_label.text = "%d%%" % int(DEFAULT_VOLUME * 100)
	value_label.add_theme_color_override("font_color", UI_COLOR_MUTED)
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.custom_minimum_size = Vector2(44, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	## Update percentage label when slider changes.
	slider.value_changed.connect(
		func(v: float) -> void:
			value_label.text = "%d%%" % int(v * 100)
	)

	return slider


func _apply_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = UI_COLOR_SURFACE
	normal.border_color = UI_COLOR_BORDER
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	normal.set_content_margin_all(6.0)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = UI_COLOR_SURFACE
	hover.border_color = Color("5B8C5A")
	hover.set_border_width_all(3)
	hover.set_corner_radius_all(5)
	hover.set_content_margin_all(4.0)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)

	button.add_theme_color_override("font_color", UI_COLOR_ACCENT)
	button.add_theme_font_size_override("font_size", 14)


func _on_master_volume_changed(value: float) -> void:
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("set_master_volume"):
		audio_manager.call("set_master_volume", value)


func _on_bgm_volume_changed(value: float) -> void:
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("set_bgm_volume"):
		audio_manager.call("set_bgm_volume", value)


func _on_sfx_volume_changed(value: float) -> void:
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("set_sfx_volume"):
		audio_manager.call("set_sfx_volume", value)


func _on_close_pressed() -> void:
	visible = false


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized
