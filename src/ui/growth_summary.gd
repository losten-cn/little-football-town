extends PanelContainer
## Read-only Growth Summary stub consuming authoritative skill/trait feedback.
##
## This is a minimum Alpha presentation stub. It does not implement skill
## unlock, trait trigger, candidate evaluation, or settlement deduplication.
## It only renders pending_skill_trait_feedback entries as grouped, labeled,
## non-interactive text, and degrades to a neutral placeholder when the
## payload is absent or empty.

const UI_COLOR_TEXT := Color("3A2A1A")
const UI_COLOR_MUTED := Color("6D5A3A")
const UI_COLOR_ACCENT := Color("C76A00")
const UI_COLOR_SURFACE := Color("F5DDA8")
const UI_COLOR_BORDER := Color("C58A3A")

var _feedback_payload: Dictionary[String, Variant] = {}
var _root_box: VBoxContainer = null
var _title_label: Label = null
var _content_label: Label = null
var _empty_label: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	_subscribe_events()
	_refresh()


func _exit_tree() -> void:
	EventBus.unsubscribe("pending_skill_trait_feedback", _on_feedback_ready)


func _setup_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("FFF8E8")
	panel_style.border_color = Color("D8A85A")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(8.0)
	add_theme_stylebox_override("panel", panel_style)

	_root_box = VBoxContainer.new()
	_root_box.name = "GrowthSummaryRoot"
	_root_box.add_theme_constant_override("separation", 4)
	add_child(_root_box)

	_title_label = Label.new()
	_title_label.name = "GrowthSummaryTitle"
	_title_label.text = _localized_text("GROWTH_SUMMARY_TITLE", "球员成长")
	_title_label.add_theme_color_override("font_color", UI_COLOR_ACCENT)
	_title_label.add_theme_font_size_override("font_size", 14)
	_root_box.add_child(_title_label)

	_content_label = Label.new()
	_content_label.name = "GrowthSummaryContent"
	_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content_label.add_theme_color_override("font_color", UI_COLOR_TEXT)
	_content_label.visible = false
	_root_box.add_child(_content_label)

	_empty_label = Label.new()
	_empty_label.name = "GrowthSummaryEmpty"
	_empty_label.text = _localized_text("GROWTH_SUMMARY_EMPTY", "暂无技能/特性成长记录")
	_empty_label.add_theme_color_override("font_color", UI_COLOR_MUTED)
	_root_box.add_child(_empty_label)


func _subscribe_events() -> void:
	EventBus.subscribe("pending_skill_trait_feedback", _on_feedback_ready)


func _on_feedback_ready(_event_name: String, payload: Dictionary) -> void:
	_feedback_payload = _to_string_variant_dictionary(payload)
	_refresh()


func _refresh() -> void:
	var feedbacks: Array = _feedback_payload.get("feedbacks", _feedback_payload.get("pending_skill_trait_feedback", []))
	if feedbacks is Array:
		feedbacks = feedbacks as Array
	else:
		feedbacks = []
	if feedbacks.is_empty():
		_content_label.visible = false
		_empty_label.visible = true
		return
	_empty_label.visible = false
	_content_label.visible = true
	_content_label.text = _format_feedbacks(feedbacks)


func _format_feedbacks(feedbacks: Array) -> String:
	var lines: Array[String] = []
	var max_display: int = 3
	var count: int = 0
	for feedback_variant: Variant in feedbacks:
		if count >= max_display:
			lines.append(_localized_text("GROWTH_SUMMARY_MORE", "还有更多成长记录可查看"))
			break
		var feedback: Dictionary[String, Variant] = _to_string_variant_dictionary(feedback_variant)
		var player_name: String = str(feedback.get("player_name", feedback.get("name", _localized_text("GROWTH_SUMMARY_UNKNOWN_PLAYER", "球员"))))
		var summary: String = str(feedback.get("summary", feedback.get("change_summary", feedback.get("description", _localized_text("GROWTH_SUMMARY_UNKNOWN_CHANGE", "近期有变化")))))
		lines.append("%s：%s" % [player_name, summary])
		count += 1
	return "\n".join(lines)


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	var source: Dictionary = value as Dictionary
	for key_variant: Variant in source.keys():
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary
