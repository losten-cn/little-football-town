extends Node

const SessionScript: Script = preload("res://prototypes/little-football-town-vertical-slice/vertical_slice_session.gd")
const TeamScreenScene: PackedScene = preload("res://prototypes/little-football-town-vertical-slice/screens/team_screen.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	await test_team_screen_binds_session_and_refreshes_view_model()
	if _failures.is_empty():
		print("VERTICAL_SLICE_TEAM_SCREEN_BOUNDARY_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func test_team_screen_binds_session_and_refreshes_view_model() -> void:
	var session: Node = SessionScript.new()
	add_child(session)
	await get_tree().process_frame

	var team_screen: Control = TeamScreenScene.instantiate()
	add_child(team_screen)
	team_screen.call("bind_session", session, Callable(self, "_noop_show_home_screen"))
	await get_tree().process_frame

	var player_list: ItemList = team_screen.get_node("Players/PlayerList") as ItemList
	var project_list: ItemList = team_screen.get_node("Training/ProjectList") as ItemList
	var result_label: RichTextLabel = team_screen.get_node("Result") as RichTextLabel

	_expect(player_list.item_count == 11, "team screen should render all scenario players")
	_expect(project_list.item_count == 2, "team screen should render all scenario training projects")
	_expect(result_label.text.contains("训练反馈"), "team screen should render training feedback header")

	team_screen.queue_free()
	session.queue_free()


func _noop_show_home_screen() -> void:
	pass


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
