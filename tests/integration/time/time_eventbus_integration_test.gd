extends SceneTree

const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	await test_time_events_emit_serializable_payloads_with_required_fields()
	await test_time_events_dispatch_before_downstream_domain_events()
	await test_time_event_subscribers_read_stable_time_manager_state()
	if _failures.is_empty():
		print("TIME_EVENTBUS_INTEGRATION_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("TIME_EVENTBUS_INTEGRATION_TEST_FAIL: %s" % failure)
		quit(1)


func test_time_events_emit_serializable_payloads_with_required_fields() -> void:
	var time_manager: Node = await _create_time_manager(_priority_snapshot())
	var time_events: Array[Dictionary] = []
	var callback := _capture_event.bind(time_events)
	_event_bus().subscribe("time_match_triggered", callback)
	_event_bus().subscribe("time_stage_settled", callback)
	_event_bus().subscribe("time_season_ended", callback)
	time_events.clear()

	var resolution: Dictionary[String, Variant] = time_manager.resolve_current_key_nodes()

	_expect((resolution["processed_sequence"] as Array[String]).size() == 4, "priority resolution should process all time key nodes for payload test")
	_expect(time_events.size() == 3, "priority resolution should emit the three required time events")

	var match_payload: Dictionary[String, Variant] = time_events[0]
	_expect(match_payload.has("home_team_id"), "time_match_triggered payload should include home_team_id")
	_expect(match_payload.has("away_team_id"), "time_match_triggered payload should include away_team_id")
	_expect(match_payload.has("match_context"), "time_match_triggered payload should include match_context")

	var stage_payload: Dictionary[String, Variant] = time_events[1]
	_expect(stage_payload.has("stage_number"), "time_stage_settled payload should include stage_number")
	_expect(stage_payload.has("stage_result"), "time_stage_settled payload should include stage_result")

	var season_payload: Dictionary[String, Variant] = time_events[2]
	_expect(season_payload.has("season_number"), "time_season_ended payload should include season_number")
	_expect(season_payload.has("final_standings"), "time_season_ended payload should include final_standings")

	_event_bus().unsubscribe("time_match_triggered", callback)
	_event_bus().unsubscribe("time_stage_settled", callback)
	_event_bus().unsubscribe("time_season_ended", callback)


func test_time_events_dispatch_before_downstream_domain_events() -> void:
	var received_order: Array[String] = []
	var callback := _capture_event_name.bind(received_order)
	_event_bus().subscribe("time_match_triggered", callback)
	_event_bus().subscribe("time_stage_settled", callback)
	_event_bus().subscribe("time_season_ended", callback)
	_event_bus().subscribe("match_completed", callback)
	_event_bus().subscribe("economy_settled", callback)
	received_order.clear()

	var prioritized_events: Array = [
		{
			"event_name": "economy_settled",
			"payload": {},
		},
		{
			"event_name": "time_season_ended",
			"payload": {
				"season_number": 2,
				"final_standings": [],
			},
		},
		{
			"event_name": "match_completed",
			"payload": {},
		},
		{
			"event_name": "time_match_triggered",
			"payload": {
				"home_team_id": 1,
				"away_team_id": 2,
				"match_context": {},
			},
		},
		{
			"event_name": "time_stage_settled",
			"payload": {
				"stage_number": 1,
				"stage_result": {},
			},
		},
	]
	_event_bus().call("emit_prioritized", prioritized_events)

	_expect(received_order == ["time_match_triggered", "time_stage_settled", "time_season_ended", "match_completed", "economy_settled"], "time events should dispatch before downstream domain events in fixed priority order")

	_event_bus().unsubscribe("time_match_triggered", callback)
	_event_bus().unsubscribe("time_stage_settled", callback)
	_event_bus().unsubscribe("time_season_ended", callback)
	_event_bus().unsubscribe("match_completed", callback)
	_event_bus().unsubscribe("economy_settled", callback)


func test_time_event_subscribers_read_stable_time_manager_state() -> void:
	var time_manager: Node = await _create_time_manager(_priority_snapshot())
	var observed_states: Array[String] = []
	var callback := _capture_current_state.bind(time_manager, observed_states)
	_event_bus().subscribe("time_season_ended", callback)
	observed_states.clear()

	time_manager.resolve_current_key_nodes()

	_expect(observed_states == ["Season Settlement"], "time event subscribers should read the committed stable state from TimeManager")
	_expect(String(time_manager.get_state()["current_state"]) == "Season Settlement", "priority resolution should end in Season Settlement for stable-state read test")

	_event_bus().unsubscribe("time_season_ended", callback)


func _priority_snapshot() -> Dictionary[String, Variant]:
	return {
		"current_state": "Planning",
		"timeline_position": 5,
		"schedule_available": true,
		"match": {
			"scheduled_position": 5,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "Priority FC",
			"next_match_display": "vs Priority FC",
			"home_team_id": 11,
			"away_team_id": 22,
		},
		"current_stage_progress": 3,
		"stage_progress_target": 3,
		"season_progress": {
			"completed_units": 10,
			"total_units": 10,
		},
		"season_final_standings": [
			{"team_id": 11, "position": 1},
			{"team_id": 22, "position": 2},
		],
	}


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


func _capture_event_name(event_name: String, _payload: Dictionary, sink: Array[String]) -> void:
	sink.append(event_name)


func _capture_current_state(_event_name: String, _payload: Dictionary, time_manager: Node, sink: Array[String]) -> void:
	sink.append(String(time_manager.get_state()["current_state"]))


func _to_typed_dictionary(source: Dictionary) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	for key_variant: Variant in source:
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
