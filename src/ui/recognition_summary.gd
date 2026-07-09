extends PanelContainer
## Read-only Recognition Summary stub consuming authoritative Reputation/Achievement state.
##
## This is a minimum Alpha presentation stub. It does not implement reputation
## calculation, achievement unlock logic, milestone evaluation, or reward
## settlement. It renders reputation level + progress and up to 3 recent
## achievements from authoritative payloads, and degrades to a neutral
## placeholder when payload is absent.

const UI_COLOR_TEXT := Color("3A2A1A")
const UI_COLOR_MUTED := Color("6D5A3A")
const UI_COLOR_ACCENT := Color("C76A00")

var _root_box: VBoxContainer = null
var _title_label: Label = null
var _reputation_label: Label = null
var _achievement_list: VBoxContainer = null
var _empty_placeholder: Label = null
var _reputation_payload: Dictionary = {}
var _achievements: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	_subscribe_events()
	_refresh()


func _exit_tree() -> void:
	EventBus.unsubscribe("reputation_state_changed", _on_reputation_state_changed)
	EventBus.unsubscribe("achievement_unlocked", _on_achievement_unlocked)


func set_reputation_payload_for_testing(payload: Dictionary) -> void:
	_reputation_payload = payload
	_refresh()


func add_achievement_for_testing(achievement: Dictionary) -> void:
	_achievements.append(achievement)
	_refresh()


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
	_root_box.name = "RecognitionSummaryRoot"
	_root_box.add_theme_constant_override("separation", 6)
	add_child(_root_box)

	_title_label = Label.new()
	_title_label.name = "RecognitionSummaryTitle"
	_title_label.text = _localized_text("RECOGNITION_TITLE", "声望与成就")
	_title_label.add_theme_color_override("font_color", UI_COLOR_ACCENT)
	_title_label.add_theme_font_size_override("font_size", 14)
	_root_box.add_child(_title_label)

	_reputation_label = Label.new()
	_reputation_label.name = "RecognitionReputation"
	_reputation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reputation_label.add_theme_color_override("font_color", UI_COLOR_TEXT)
	_reputation_label.add_theme_font_size_override("font_size", 13)
	_root_box.add_child(_reputation_label)

	_achievement_list = VBoxContainer.new()
	_achievement_list.name = "RecognitionAchievementList"
	_achievement_list.add_theme_constant_override("separation", 2)
	_root_box.add_child(_achievement_list)

	_empty_placeholder = Label.new()
	_empty_placeholder.name = "RecognitionSummaryEmpty"
	_empty_placeholder.text = _localized_text("RECOGNITION_EMPTY", "暂无声望记录")
	_empty_placeholder.add_theme_color_override("font_color", UI_COLOR_MUTED)
	_empty_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_placeholder.visible = false
	_root_box.add_child(_empty_placeholder)


func _subscribe_events() -> void:
	EventBus.subscribe("reputation_state_changed", _on_reputation_state_changed)
	EventBus.subscribe("achievement_unlocked", _on_achievement_unlocked)


func _on_reputation_state_changed(_event_name: String, payload: Dictionary) -> void:
	_reputation_payload = payload.duplicate()
	_refresh()


func _on_achievement_unlocked(_event_name: String, payload: Dictionary) -> void:
	_achievements.append(payload.duplicate())
	if _achievements.size() > 3:
		_achievements = _achievements.slice(_achievements.size() - 3)
	_refresh()


func _refresh() -> void:
	var has_content: bool = false

	# Reputation
	if not _reputation_payload.is_empty():
		var level: int = int(_reputation_payload.get("reputation_level", 0))
		var progress: float = float(_reputation_payload.get("reputation_progress_ratio", 0.0))
		_reputation_label.text = _localized_text("RECOGNITION_REPUTATION_FMT", "声望等级 Lv.%d (%.0f%%)") % [level, progress * 100]
		_reputation_label.visible = true
		has_content = true
	else:
		_reputation_label.visible = false

	# Achievements
	for child: Node in _achievement_list.get_children():
		child.queue_free()

	if not _achievements.is_empty():
		for achievement: Dictionary in _achievements:
			var label := Label.new()
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_color_override("font_color", UI_COLOR_TEXT)
			label.add_theme_font_size_override("font_size", 12)
			label.text = "★ %s" % str(achievement.get("achievement_name", achievement.get("name", "成就解锁")))
			_achievement_list.add_child(label)
		_achievement_list.visible = true
		has_content = true
	else:
		_achievement_list.visible = false

	_empty_placeholder.visible = not has_content


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized
