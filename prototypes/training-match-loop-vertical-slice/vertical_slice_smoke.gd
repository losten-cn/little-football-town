# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Can a first-time player complete Training Day → Match Day → Post-Match Return in under 5 minutes without guidance?
# Date: 2026-05-30

extends Node

const SessionScript: Script = preload("res://prototypes/training-match-loop-vertical-slice/vertical_slice_session.gd")
const PASS_MESSAGE: String = "TRAINING_MATCH_LOOP_VERTICAL_SLICE_PASS"
const FAIL_EXIT_CODE: int = 1


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var session: Variant = SessionScript.new()
	add_child(session)
	await get_tree().process_frame

	var initial_state: Dictionary = session.get_state_summary()
	_assert_true(not bool(initial_state.get("can_open_match_center", true)), "match center should start locked")

	var players: Array = initial_state.get("players", [])
	var projects: Array = initial_state.get("training_projects", [])
	_assert_true(not players.is_empty(), "players should exist")
	_assert_true(not projects.is_empty(), "training projects should exist")

	var player: Dictionary = players[0]
	var project: Dictionary = projects[0]
	var training_result: Dictionary = session.run_training(int(player.get("id", 0)), String(project.get("project_id", "")))
	_assert_true(bool(training_result.get("success", false)), "training should resolve")

	var post_training_state: Dictionary = session.get_state_summary()
	_assert_true(bool(post_training_state.get("can_open_match_center", false)), "match center should unlock after training")

	var open_result: Dictionary = session.open_match_center()
	_assert_true(bool(open_result.get("success", false)), "match center should open")

	var step_guard: int = 0
	while session.get_match_view_model().get("latest_match_result", {}).is_empty() and step_guard < 10:
		session.advance_match_step()
		step_guard += 1

	var match_view: Dictionary = session.get_match_view_model()
	var latest_match_result: Dictionary = match_view.get("latest_match_result", {})
	_assert_true(not latest_match_result.is_empty(), "match result should exist")
	_assert_true(not String(latest_match_result.get("summary_text", "")).is_empty(), "match result should explain outcome")

	var return_result: Dictionary = session.confirm_match_result_and_return_home()
	_assert_true(bool(return_result.get("success", false)), "post-match return should resolve")
	_assert_true(String(return_result.get("next_phase", "")) == "Planning", "loop should return to Planning")

	print(PASS_MESSAGE)
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	get_tree().quit(FAIL_EXIT_CODE)
