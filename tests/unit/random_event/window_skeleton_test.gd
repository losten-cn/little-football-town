extends SceneTree
## Story 002 — RandomEventManager Window Skeleton automated tests.
##
## AC-1: EventBus subscription — emit time_phase_changed, verify _evaluate_event_trigger runs.
## AC-2: Cooldown blocks re-trigger — active cooldown prevents pending event generation.
## AC-3: offer_view_payload is read-only — modifying returned dict does not mutate internal state.
## AC-4: history_view_payload is time-descending — entries returned newest-first.
## AC-5: No actual event effects fired — manager stub never mutates Economy/Player/Town/Match/Time/Reputation.

const RandomEventManagerScript: Script = preload("res://src/core/random_event_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	test_ac1_event_bus_subscription_triggers_evaluate()
	test_ac2_cooldown_blocks_re_trigger()
	test_ac3_offer_view_payload_read_only()
	test_ac4_history_view_payload_time_descending()
	test_ac5_no_actual_event_effects_fired()

	if _failures.is_empty():
		print("RANDOM_EVENT_WINDOW_SKELETON_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("RANDOM_EVENT_WINDOW_SKELETON_TEST_FAIL: %s" % failure)
		quit(1)


# ─────────────────────────────────────────────
# AC-1 — EventBus subscription triggers _evaluate_event_trigger
# ─────────────────────────────────────────────

func test_ac1_event_bus_subscription_triggers_evaluate() -> void:
	# Arrange
	var manager: Node = RandomEventManagerScript.new() as Node
	root.add_child(manager)

	# Wait one frame for _ready() to subscribe
	await _wait_one_frame()

	# Verify no pending event exists initially
	_expect(manager.pending_random_event_instance is Dictionary, "pending must be a Dictionary")
	_expect((manager.pending_random_event_instance as Dictionary).is_empty(), "pending must be empty before trigger")

	# Act — emit time_phase_changed with a valid stable window (Planning)
	_event_bus().emit("time_phase_changed", {
		"old_phase": "SeasonStart",
		"new_phase": "Planning",
		"timeline_position": 10,
		"season_number": 1,
		"current_stage": 2,
	})

	# Assert — pending event should now be populated
	var pending: Dictionary = manager.pending_random_event_instance
	_expect(not pending.is_empty(), "pending must be populated after emit into valid stable window")
	_expect(String(pending.get("trigger_window", "")) == "Planning", "pending trigger_window must be Planning")
	_expect(int(pending.get("timeline_position", 0)) == 10, "pending timeline_position must be 10")
	_expect(String(pending.get("event_id", "")) == "stub_window_event", "pending event_id must be stub_window_event")

	# Cleanup
	root.remove_child(manager)
	manager.queue_free()
	await _wait_one_frame()


# ─────────────────────────────────────────────
# AC-2 — Cooldown blocks re-trigger
# ─────────────────────────────────────────────

func test_ac2_cooldown_blocks_re_trigger() -> void:
	# Arrange — set an active cooldown (expiry at timeline_position 100)
	var manager: Node = RandomEventManagerScript.new() as Node
	manager.event_cooldown_state = {"town_life": 100}
	root.add_child(manager)
	await _wait_one_frame()

	# Verify no pending event
	_expect((manager.pending_random_event_instance as Dictionary).is_empty(), "pending must be empty before trigger")

	# Act — emit at timeline_position 50 (before cooldown expiry at 100)
	_event_bus().emit("time_phase_changed", {
		"old_phase": "Planning",
		"new_phase": "Stage Settlement",
		"timeline_position": 50,
		"season_number": 1,
		"current_stage": 1,
	})

	# Assert — cooldown is active (50 < 100), so pending must remain empty
	var pending: Dictionary = manager.pending_random_event_instance
	_expect(pending.is_empty(), "pending must remain empty when cooldown is active (50 < 100)")

	# Act — now emit after cooldown expiry (timeline_position 150 > 100)
	_event_bus().emit("time_phase_changed", {
		"old_phase": "Stage Settlement",
		"new_phase": "Planning",
		"timeline_position": 150,
		"season_number": 1,
		"current_stage": 2,
	})

	# Assert — cooldown expired, pending should now be set
	pending = manager.pending_random_event_instance
	_expect(not pending.is_empty(), "pending must be set after cooldown expires (150 > 100)")

	# Cleanup
	root.remove_child(manager)
	manager.queue_free()
	await _wait_one_frame()


# ─────────────────────────────────────────────
# AC-3 — offer_view_payload is read-only
# ─────────────────────────────────────────────

func test_ac3_offer_view_payload_read_only() -> void:
	# Arrange — set a known pending event instance directly (simulates triggered state)
	var manager: Node = RandomEventManagerScript.new() as Node
	manager.pending_random_event_instance = {
		"event_id": "evt_readonly_test",
		"event_instance_id": "inst_xyz",
		"trigger_window": "Offseason",
		"timeline_position": 42,
		"season_number": 2,
		"current_stage": 3,
	}

	# Act — get the read-only view payload
	var offer_payload: Dictionary[String, Variant] = manager.get_offer_view_payload()

	# Assert — payload contains expected fields
	_expect(String(offer_payload.get("event_id", "")) == "evt_readonly_test", "offer payload must have correct event_id")
	_expect(String(offer_payload.get("trigger_window", "")) == "Offseason", "offer payload must have correct trigger_window")

	# Act — mutate the returned payload
	offer_payload["event_id"] = "MUTATED"
	offer_payload["new_illegal_field"] = "INJECTED"

	# Assert — internal state must NOT be affected by mutations to the returned payload
	var internal_pending: Dictionary = manager.pending_random_event_instance
	_expect(String(internal_pending.get("event_id", "")) == "evt_readonly_test", "internal event_id must remain unchanged after payload mutation")
	_expect(not internal_pending.has("new_illegal_field"), "internal state must not contain field injected via payload mutation")

	# Cleanup
	manager.free()


# ─────────────────────────────────────────────
# AC-4 — history_view_payload is time-descending
# ─────────────────────────────────────────────

func test_ac4_history_view_payload_time_descending() -> void:
	# Arrange — populate history with 3 entries, oldest-first (as stored internally)
	var manager: Node = RandomEventManagerScript.new() as Node
	manager.recent_random_event_history = [
		{"event_id": "evt_history_1", "settlement_key": "sk_1", "resolved_at": 10},
		{"event_id": "evt_history_2", "settlement_key": "sk_2", "resolved_at": 20},
		{"event_id": "evt_history_3", "settlement_key": "sk_3", "resolved_at": 30},
	]

	# Act — get the history view payload
	var history_payload: Array = manager.get_history_view_payload()

	# Assert — must contain 3 entries
	_expect(history_payload.size() == 3, "history payload must have 3 entries")

	# Assert — ordered newest-first (time-descending: 30, 20, 10)
	_expect(String(history_payload[0].get("event_id", "")) == "evt_history_3", "history[0] must be newest entry (resolved_at=30)")
	_expect(String(history_payload[1].get("event_id", "")) == "evt_history_2", "history[1] must be middle entry (resolved_at=20)")
	_expect(String(history_payload[2].get("event_id", "")) == "evt_history_1", "history[2] must be oldest entry (resolved_at=10)")

	# Act — mutate a returned entry
	history_payload[0]["event_id"] = "MUTATED_HISTORY"

	# Assert — internal history must NOT be affected
	var internal_history: Array = manager.recent_random_event_history
	_expect(String((internal_history[2] as Dictionary).get("event_id", "")) == "evt_history_3", "internal history[2] must remain evt_history_3 after payload mutation")

	# Cleanup
	manager.free()


# ─────────────────────────────────────────────
# AC-5 — No actual event effects fired (stub only)
# ─────────────────────────────────────────────

func test_ac5_no_actual_event_effects_fired() -> void:
	# Arrange — the RandomEventManager must not reference any authority system
	# (Economy, Player, Town, Match, Time, Reputation) either via Autoload
	# lookup or direct mutation. This test verifies the stub creates a
	# pending event that is only a dictionary, not a mutated system state.

	var manager: Node = RandomEventManagerScript.new() as Node
	root.add_child(manager)
	await _wait_one_frame()

	# Act — trigger a valid window
	_event_bus().emit("time_phase_changed", {
		"old_phase": "Planning",
		"new_phase": "Post-Match Settlement",
		"timeline_position": 25,
		"season_number": 1,
		"current_stage": 1,
	})

	# Assert — pending event is a plain dictionary with only stub identity fields
	var pending: Dictionary = manager.pending_random_event_instance
	_expect(not pending.is_empty(), "pending must be set after trigger")

	# Verify no effect request payload fields (these don't exist yet in the stub)
	_expect(not pending.has("effect_requests"), "stub pending event must not contain effect_requests")
	_expect(not pending.has("target_scope"), "stub pending event must not contain target_scope")
	_expect(not pending.has("confirmed_fact"), "stub pending event must not contain confirmed_fact")
	_expect(not pending.has("economy_delta"), "stub pending event must not contain economy_delta")
	_expect(not pending.has("player_changes"), "stub pending event must not contain player_changes")
	_expect(not pending.has("town_changes"), "stub pending event must not contain town_changes")
	_expect(not pending.has("match_context"), "stub pending event must not contain match_context")
	_expect(not pending.has("reputation_fact"), "stub pending event must not contain reputation_fact")

	# Verify only stub identity fields are present
	_expect(pending.has("event_id"), "stub pending must have event_id")
	_expect(pending.has("event_instance_id"), "stub pending must have event_instance_id")
	_expect(pending.has("trigger_window"), "stub pending must have trigger_window")

	# Cleanup
	root.remove_child(manager)
	manager.queue_free()
	await _wait_one_frame()


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _event_bus() -> Node:
	return root.get_node("EventBus")


func _wait_one_frame() -> void:
	await process_frame
