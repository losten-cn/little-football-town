# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Can a player complete one clear training-to-match-to-feedback loop in under 5 minutes without guidance?
# Date: 2026-05-30

extends VBoxContainer

@onready var _summary_label: Label = $Top/SummaryLabel
@onready var _state_label: Label = $Top/StateLabel
@onready var _history_label: Label = $Top/HistoryLabel
@onready var _result_label: RichTextLabel = $Result
@onready var _continue_button: Button = $Actions/ContinueButton
@onready var _home_button: Button = $Actions/HomeButton

var _session: Node = null
var _show_home_screen: Callable


func bind_session(session: Node, show_home_screen: Callable) -> void:
	_session = session
	_show_home_screen = show_home_screen
	_continue_button.pressed.connect(_on_continue_pressed)
	_home_button.pressed.connect(_on_home_pressed)
	_session.state_changed.connect(_refresh)
	_session.match_state_changed.connect(_refresh)
	_session.match_finished.connect(_refresh)
	var open_result: Dictionary[String, Variant] = _session.open_match_center()
	if not bool(open_result.get("success", false)):
		_result_label.text = "[b]比赛中心不可用[/b]\n请先完成训练并推进到比赛日。"
	_refresh()


func _exit_tree() -> void:
	if _session != null:
		if _session.state_changed.is_connected(_refresh):
			_session.state_changed.disconnect(_refresh)
		if _session.match_state_changed.is_connected(_refresh):
			_session.match_state_changed.disconnect(_refresh)
		if _session.match_finished.is_connected(_refresh):
			_session.match_finished.disconnect(_refresh)


func _refresh(_payload: Variant = null) -> void:
	if _session == null:
		return
	var match_view: Dictionary[String, Variant] = _session.get_match_view_model()
	_summary_label.text = "对手：%s｜%s" % [
		String(match_view.get("opponent_name", "待定")),
		String(match_view.get("next_match_display", "")),
	]
	_state_label.text = "当前比赛状态：%s" % String(match_view.get("match_state_name", "Idle"))
	_history_label.text = "状态序列：%s" % ", ".join(match_view.get("formal_state_history", []))
	var latest_match_result: Dictionary[String, Variant] = match_view.get("latest_match_result", {})
	if latest_match_result.is_empty():
		_result_label.text = "[b]目标[/b]\n连续点击“继续推进比赛”，完成赛前确认、上半场、中场调整、下半场与赛后结算。"
		_continue_button.text = "继续推进比赛"
		_continue_button.disabled = false
		_home_button.text = "返回 Home"
		return
	_result_label.text = "[b]赛后结果[/b]\n%s\n\n比分：%d : %d\n关键原因：%s" % [
		String(latest_match_result.get("summary_text", "比赛已结束。")),
		int(latest_match_result.get("score", {}).get("home", 0)),
		int(latest_match_result.get("score", {}).get("away", 0)),
		", ".join(latest_match_result.get("win_reasons", [])),
	]
	_continue_button.text = "确认结果并回到 Home"
	_continue_button.disabled = false
	_home_button.text = "留在此页"


func _on_continue_pressed() -> void:
	if _session == null:
		return
	var match_view: Dictionary[String, Variant] = _session.get_match_view_model()
	var latest_match_result: Dictionary[String, Variant] = match_view.get("latest_match_result", {})
	if latest_match_result.is_empty():
		_session.advance_match_step()
		return
	var result: Dictionary[String, Variant] = _session.confirm_match_result_and_return_home()
	if bool(result.get("success", false)) and _show_home_screen.is_valid():
		_show_home_screen.call()


func _on_home_pressed() -> void:
	if _show_home_screen.is_valid():
		_show_home_screen.call()
