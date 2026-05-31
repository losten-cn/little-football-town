# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Can a player complete one clear training-to-match-to-feedback loop in under 5 minutes without guidance?
# Date: 2026-05-30

extends VBoxContainer

@onready var _summary_label: Label = $Top/SummaryLabel
@onready var _player_list: ItemList = $Players/PlayerList
@onready var _project_list: ItemList = $Training/ProjectList
@onready var _result_label: RichTextLabel = $Result
@onready var _train_button: Button = $Actions/TrainButton
@onready var _home_button: Button = $Actions/HomeButton

var _session: Node = null
var _show_home_screen: Callable
var _selected_player_id: int = 0
var _selected_project_id: String = ""


func bind_session(session: Node, show_home_screen: Callable) -> void:
	_session = session
	_show_home_screen = show_home_screen
	_player_list.item_selected.connect(_on_player_selected)
	_project_list.item_selected.connect(_on_project_selected)
	_train_button.pressed.connect(_on_train_pressed)
	_home_button.pressed.connect(_on_home_pressed)
	_session.state_changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if _session != null and _session.state_changed.is_connected(_refresh):
		_session.state_changed.disconnect(_refresh)


func _refresh() -> void:
	if _session == null:
		return
	var team_view: Dictionary = _session.get_team_view_model()
	_summary_label.text = "选择一名球员并安排一次训练。剩余行动窗口：%d，经费：%d，AP：%d" % [
		int(team_view.get("available_action_windows", 0)),
		int(team_view.get("funds", 0)),
		int(team_view.get("action_points", 0)),
	]
	_player_list.clear()
	for player_summary_variant: Variant in team_view.get("players", []):
		var player_summary: Dictionary = player_summary_variant as Dictionary
		var label: String = "%s｜%s｜TEC %d｜STA %d｜效率 %.2f" % [
			String(player_summary.get("name", "")),
			String(player_summary.get("position", "")),
			int(player_summary.get("tec", 0)),
			int(player_summary.get("sta", 0)),
			float(player_summary.get("training_efficiency", 1.0)),
		]
		_player_list.add_item(label)
		_player_list.set_item_metadata(_player_list.item_count - 1, int(player_summary.get("id", 0)))
	_project_list.clear()
	for project_variant: Variant in team_view.get("training_projects", []):
		var project: Dictionary = project_variant as Dictionary
		var project_label: String = "%s｜主属性 %s｜经费 %d｜AP %d" % [
			String(project.get("label", "")),
			String(project.get("primary_attribute", "")),
			int(project.get("funds_cost", 0)),
			int(project.get("action_points_cost", 0)),
		]
		_project_list.add_item(project_label)
		_project_list.set_item_metadata(_project_list.item_count - 1, String(project.get("project_id", "")))
	var last_training_result: Dictionary = team_view.get("last_training_result", {}) as Dictionary
	if last_training_result.is_empty():
		_result_label.text = "[b]训练反馈[/b]\n还没有进行训练。"
	else:
		_result_label.text = "[b]训练反馈[/b]\n%s 完成了 %s，主属性 %s 提升 %.2f。" % [
			String(last_training_result.get("player_name", "球员")),
			String(last_training_result.get("project_label", "训练")),
			String(last_training_result.get("primary_attribute", "")),
			float(last_training_result.get("applied_gain", 0.0)),
		]
	_train_button.disabled = _selected_player_id == 0 or _selected_project_id.is_empty()


func _on_player_selected(index: int) -> void:
	_selected_player_id = int(_player_list.get_item_metadata(index))
	_train_button.disabled = _selected_player_id == 0 or _selected_project_id.is_empty()


func _on_project_selected(index: int) -> void:
	_selected_project_id = String(_project_list.get_item_metadata(index))
	_train_button.disabled = _selected_player_id == 0 or _selected_project_id.is_empty()


func _on_train_pressed() -> void:
	if _session == null:
		return
	_session.run_training(_selected_player_id, _selected_project_id)


func _on_home_pressed() -> void:
	if _show_home_screen.is_valid():
		_show_home_screen.call()
