extends SceneTree

const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	await test_restore_from_stable_snapshot_preserves_verified_time_state()
	await test_restore_from_unstable_snapshot_normalizes_to_verified_stable_state()
	await test_restored_stable_state_preserves_key_node_progression_boundary()
	await test_restore_does_not_emit_or_advance_beyond_committed_state()
	if _failures.is_empty():
		print("TIME_RESTORE_BOUNDARY_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("TIME_RESTORE_BOUNDARY_TEST_FAIL: %s" % failure)
		quit(1)


func test_restore_from_stable_snapshot_preserves_verified_time_state() -> void:
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
		"timeline_position": 4,
		"season_number": 2,
		"current_stage": 3,
		"current_stage_progress": 1,
		"stage_progress_target": 3,
		"season_progress": {
			"completed_units": 4,
			"total_units": 12,
		},
		"match": {
			"scheduled_position": 6,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Restore FC",
			"next_match_display": "vs Restore FC",
		},
	})

	var restore_result: Dictionary[String, Variant] = time_manager.restore_from_snapshot({
		"current_state": "Offseason",
		"timeline_position": 9,
		"season_number": 3,
		"current_stage": 5,
		"current_stage_progress": 2,
		"stage_progress_target": 4,
		"season_progress": {
			"completed_units": 9,
			"total_units": 12,
		},
		"match": {
			"scheduled_position": 12,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Stable FC",
			"next_match_display": "vs Stable FC",
		},
	})
	var restored_state: Dictionary[String, Variant] = time_manager.get_state()

	_expect(restore_result["success"] as bool, "stable snapshot restore should succeed")
	_expect(not (restore_result["normalized"] as bool), "stable snapshot restore should not normalize the requested state")
	_expect(String(restored_state["current_state"]) == "Offseason", "stable snapshot restore should preserve the requested stable state")
	_expect(int(restored_state["timeline_position"]) == 9, "stable snapshot restore should preserve timeline position")
	_expect(int(restored_state["season_number"]) == 3, "stable snapshot restore should preserve season number")


func test_restore_from_unstable_snapshot_normalizes_to_verified_stable_state() -> void:
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
	})

	var match_trigger_restore: Dictionary[String, Variant] = time_manager.restore_from_snapshot({
		"current_state": "Match Trigger",
		"timeline_position": 5,
		"match": {
			"scheduled_position": 5,
			"center_available": true,
			"in_progress": false,
		},
	})
	_expect(match_trigger_restore["normalized"] as bool, "Match Trigger restore should normalize to a verified stable state")
	_expect(String(time_manager.get_state()["current_state"]) == "Planning", "Match Trigger restore should normalize to Planning")

	var post_match_restore: Dictionary[String, Variant] = time_manager.restore_from_snapshot({
		"current_state": "Post-Match Settlement",
		"current_stage_progress": 3,
		"stage_progress_target": 3,
		"season_progress": {
			"completed_units": 7,
			"total_units": 10,
		},
	})
	_expect(post_match_restore["normalized"] as bool, "Post-Match Settlement restore should normalize to a verified stable state")
	_expect(String(time_manager.get_state()["current_state"]) == "Stage Settlement", "ready Post-Match Settlement restore should normalize to Stage Settlement")


func test_restored_stable_state_preserves_key_node_progression_boundary() -> void:
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
	})

	time_manager.restore_from_snapshot({
		"current_state": "Planning",
		"timeline_position": 5,
		"schedule_available": true,
		"match": {
			"scheduled_position": 5,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Boundary FC",
			"next_match_display": "vs Boundary FC",
		},
		"current_stage_progress": 3,
		"stage_progress_target": 3,
		"season_progress": {
			"completed_units": 10,
			"total_units": 10,
		},
	})

	var first_resolution: Dictionary[String, Variant] = time_manager.resolve_current_key_nodes()
	var second_resolution: Dictionary[String, Variant] = time_manager.resolve_current_key_nodes()

	_expect((first_resolution["processed_sequence"] as Array[String]) == ["Match Trigger", "Post-Match Settlement", "Stage Settlement", "Season Settlement"], "restored stable state should still process the pending key-node chain once")
	_expect((second_resolution["processed_sequence"] as Array[String]).is_empty(), "restored stable state should not replay already-completed key nodes")
	_expect(String(second_resolution["final_state"]) == "Season Settlement", "restored stable state should preserve the committed final node after first resolution")


func test_restore_does_not_emit_or_advance_beyond_committed_state() -> void:
	var time_manager: Node = await _create_time_manager({
		"current_state": "Planning",
	})
	var season_events: Array[Dictionary] = []
	var callback := _capture_event.bind(season_events)
	_event_bus().subscribe("time_season_ended", callback)
	season_events.clear()

	var restore_result: Dictionary[String, Variant] = time_manager.restore_from_snapshot({
		"current_state": "SeasonStart",
		"timeline_position": 0,
		"season_number": 4,
		"current_stage": 1,
		"current_stage_progress": 0,
		"stage_progress_target": 3,
		"season_progress": {
			"completed_units": 0,
			"total_units": 12,
		},
	})

	_expect(restore_result["success"] as bool, "restore should succeed for stable SeasonStart snapshot")
	_expect(String(time_manager.get_state()["current_state"]) == "SeasonStart", "restore should stop at the committed stable node")
	_expect(season_events.is_empty(), "restore should not emit downstream time events by itself")

	_event_bus().unsubscribe("time_season_ended", callback)


func _create_time_manager(snapshot: Dictionary[String, Variant]) -> Node:
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.call_deferred("add_child", time_manager)
	await process_frame
	time_manager.apply_snapshot(snapshot)
	return time_manager


func _event_bus() -> Node:
	return root.get_node("EventBus")


func _capture_event(_event_name: String, payload: Dictionary, sink: Array[Dictionary]) -> void:
	sink.append(_to_typed_dictionary(payload))


func _to_typed_dictionary(source: Dictionary) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	for key_variant: Variant in source:
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
