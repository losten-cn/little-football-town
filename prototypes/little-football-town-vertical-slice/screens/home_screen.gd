# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Can a player complete one clear training-to-match-to-feedback loop in under 5 minutes without guidance?
# Date: 2026-05-30

extends VBoxContainer

@onready var _phase_label: Label = $Header/PhaseLabel
@onready var _date_label: Label = $Header/DateLabel
@onready var _match_label: Label = $Header/MatchLabel
@onready var _resource_label: Label = $Header/ResourceLabel
@onready var _summary_label: RichTextLabel = $Summary
@onready var _team_button: Button = $Actions/TeamButton
@onready var _match_button: Button = $Actions/MatchButton

var _session: Node = null
var _show_team_screen: Callable
var _show_match_screen: Callable


func bind_session(session: Node, show_team_screen: Callable, show_match_screen: Callable) -> void:
	_session = session
	_show_team_screen = show_team_screen
	_show_match_screen = show_match_screen
	_team_button.pressed.connect(_on_team_pressed)
	_match_button.pressed.connect(_on_match_pressed)
	_session.state_changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if _session != null and _session.state_changed.is_connected(_refresh):
		_session.state_changed.disconnect(_refresh)


func _refresh() -> void:
	if _session == null:
		return
	var summary: Dictionary[String, Variant] = _session.get_state_summary()
	_phase_label.text = "当前阶段：%s" % String(summary.get("phase", "Planning"))
	_date_label.text = "日期：%s" % String(summary.get("date_display", "Week 1 / Day 1"))
	_match_label.text = "下一场：%s" % String(summary.get("next_match_display", "待定"))
	_resource_label.text = "经费 %d / AP %d" % [int(summary.get("funds", 0)), int(summary.get("action_points", 0))]
	_match_button.disabled = not bool(summary.get("can_open_match_center", false))
	var latest_match_result: Dictionary[String, Variant] = summary.get("latest_match_result", {})
	if latest_match_result.is_empty():
		_summary_label.text = "[b]目标[/b]：先看球员，再安排一次训练，然后进入周末比赛。"
	else:
		_summary_label.text = "[b]赛后总结[/b]\n%s" % String(latest_match_result.get("summary_text", "比赛已结束。"))


func _on_team_pressed() -> void:
	if _show_team_screen.is_valid():
		_show_team_screen.call()


func _on_match_pressed() -> void:
	if _show_match_screen.is_valid():
		_show_match_screen.call()
