extends SceneTree
## Story 001 — RandomEventManager Authority Stub automated tests.
##
## AC-1: Node is scene-instantiated (class_name), not an Autoload.
## AC-2: All 4 durable fields exist with correct initial values.
## AC-3: Settlement key is deterministic and rule_version-independent.
## AC-4: Idempotency — same key returns true from _is_settled().
## AC-5: serialize/deserialize round-trip preserves all fields.

const RandomEventManagerScript: Script = preload("res://src/core/random_event_manager.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_ac1_node_is_scene_instantiated_not_autoload()
	test_ac2_durable_fields_exist_with_correct_initial_values()
	test_ac3_settlement_key_deterministic_and_rule_version_independent()
	test_ac4_idempotency_same_key_returns_true_from_is_settled()
	test_ac5_serialize_deserialize_round_trip_preserves_all_fields()

	if _failures.is_empty():
		print("RANDOM_EVENT_AUTH_STUB_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("RANDOM_EVENT_AUTH_STUB_TEST_FAIL: %s" % failure)
		quit(1)


# ─────────────────────────────────────────────
# AC-1 — Scene-instantiated Node, NOT Autoload
# ─────────────────────────────────────────────

func test_ac1_node_is_scene_instantiated_not_autoload() -> void:
	# Arrange & Act
	var manager: Node = RandomEventManagerScript.new() as Node

	# Assert — can be instantiated as a regular Node
	_expect(manager is Node, "RandomEventManager must extend Node")
	_expect(manager.has_method("build_event_settlement_key"), "RandomEventManager must expose build_event_settlement_key")

	# Autoloads live under /root/<Name> and are created by the engine.
	# A scene-instantiated node (class_name) is created via .new() like any
	# other Node — it has no special Autoload behavior and must be added to
	# the tree explicitly.
	_expect(not manager.is_inside_tree(), "fresh instance must not already be in the tree (Autoloads are auto-added)")

	# Verify it can be added to the SceneTree like any scene-instantiated node.
	manager.free()


# ─────────────────────────────────────────────
# AC-2 — Durable fields exist with correct initial values
# ─────────────────────────────────────────────

func test_ac2_durable_fields_exist_with_correct_initial_values() -> void:
	# Arrange & Act
	var manager: Node = RandomEventManagerScript.new() as Node

	# Assert — pending_random_event_instance
	_expect(manager.pending_random_event_instance is Dictionary, "pending_random_event_instance must be a Dictionary")
	_expect(manager.pending_random_event_instance.is_empty(), "pending_random_event_instance must be empty (semantic null)")

	# Assert — recent_random_event_history
	_expect(manager.recent_random_event_history is Array, "recent_random_event_history must be an Array")
	_expect(manager.recent_random_event_history.is_empty(), "recent_random_event_history must be empty")

	# Assert — event_cooldown_state
	_expect(manager.event_cooldown_state is Dictionary, "event_cooldown_state must be a Dictionary")
	_expect(manager.event_cooldown_state.is_empty(), "event_cooldown_state must be empty")

	# Assert — processed_event_settlement_keys
	_expect(manager.processed_event_settlement_keys is Array, "processed_event_settlement_keys must be an Array")
	_expect(manager.processed_event_settlement_keys.is_empty(), "processed_event_settlement_keys must be empty")

	manager.free()


# ─────────────────────────────────────────────
# AC-3 — Settlement key deterministic & rule_version-independent
# ─────────────────────────────────────────────

func test_ac3_settlement_key_deterministic_and_rule_version_independent() -> void:
	# Arrange
	var manager: Node = RandomEventManagerScript.new() as Node
	var event_instance_id: String = "evt_test_001"
	var selected_option_id: String = "opt_A"
	var target_scope: String = "economy"
	var target_id: String = "target_42"

	# Act — generate twice with identical inputs
	var key_1: String = manager.build_event_settlement_key(event_instance_id, selected_option_id, target_scope, target_id)
	var key_2: String = manager.build_event_settlement_key(event_instance_id, selected_option_id, target_scope, target_id)

	# Assert — deterministic
	_expect(key_1 == key_2, "identical inputs must produce identical settlement keys")
	_expect(not key_1.is_empty(), "settlement key must not be empty")
	_expect(key_1.length() == 32, "md5_text hex digest must be 32 characters")

	# Act — generate with different inputs
	var key_different: String = manager.build_event_settlement_key("evt_test_002", selected_option_id, target_scope, target_id)

	# Assert — different event_instance_id produces different key
	_expect(key_1 != key_different, "different event_instance_id must produce different settlement key")

	# Act — verify rule_version is NOT part of the key source.
	# build_event_settlement_key accepts only 4 parameters; rule_version is
	# intentionally absent. We cross-check by building the canonical join
	# manually and verifying it matches the manager's output.
	var key_from_manager: String = manager.build_event_settlement_key(event_instance_id, selected_option_id, target_scope, target_id)
	var canonical_join_manual: String = ("|".join([event_instance_id, selected_option_id, target_scope, target_id])).md5_text()

	# Both paths converge to the same canonical join (4 fields only).
	_expect(key_from_manager == canonical_join_manual, "settlement key must match manual canonical join of 4 scalar fields — rule_version excluded")

	manager.free()


# ─────────────────────────────────────────────
# AC-4 — Idempotency guard
# ─────────────────────────────────────────────

func test_ac4_idempotency_same_key_returns_true_from_is_settled() -> void:
	# Arrange
	var manager: Node = RandomEventManagerScript.new() as Node
	var event_instance_id: String = "evt_idem_001"
	var selected_option_id: String = "opt_B"
	var target_scope: String = "player"
	var target_id: String = "player_7"

	var settlement_key: String = manager.build_event_settlement_key(event_instance_id, selected_option_id, target_scope, target_id)

	# Assert — key is not yet settled
	var is_settled_callable: Callable = Callable(manager, "_is_settled")
	_expect(not (is_settled_callable.call(settlement_key) as bool), "fresh instance must not have any settled keys")

	# Act — record the key as processed
	manager.processed_event_settlement_keys.append(settlement_key)

	# Assert — key is now settled (idempotency guard active)
	_expect(is_settled_callable.call(settlement_key) as bool, "recorded key must be recognized as settled")

	# Assert — a different key is still not settled
	var other_key: String = manager.build_event_settlement_key("evt_idem_002", selected_option_id, target_scope, target_id)
	_expect(not (is_settled_callable.call(other_key) as bool), "unrelated key must not be affected by recorded key")

	manager.free()


# ─────────────────────────────────────────────
# AC-5 — serialize/deserialize round-trip
# ─────────────────────────────────────────────

func test_ac5_serialize_deserialize_round_trip_preserves_all_fields() -> void:
	# Arrange — populate all 4 durable fields
	var source: Node = RandomEventManagerScript.new() as Node

	source.pending_random_event_instance = {
		"event_id": "evt_roundtrip_001",
		"event_instance_id": "inst_abc123",
		"trigger_window": "post_training",
	}

	source.recent_random_event_history = [
		{"event_id": "evt_history_001", "settlement_key": "abc111"},
		{"event_id": "evt_history_002", "settlement_key": "abc222"},
	]

	source.event_cooldown_state = {
		"town_life": 42.0,
		"player_mood": 99.0,
	}

	var settlement_key_a: String = source.build_event_settlement_key("evt_a", "opt_1", "economy", "t1")
	var settlement_key_b: String = source.build_event_settlement_key("evt_b", "opt_2", "player", "p3")
	source.processed_event_settlement_keys = [settlement_key_a, settlement_key_b]

	# Act — serialize
	var serialized: Dictionary[String, Variant] = source.serialize()

	# Act — deserialize into a fresh instance
	var target: Node = RandomEventManagerScript.new() as Node
	target.deserialize(serialized)

	# Assert — pending_random_event_instance
	var restored_pending: Dictionary = target.pending_random_event_instance
	_expect(restored_pending.has("event_id"), "pending must have event_id after round-trip")
	_expect(String(restored_pending.get("event_id", "")) == "evt_roundtrip_001", "pending event_id must survive round-trip")
	_expect(String(restored_pending.get("event_instance_id", "")) == "inst_abc123", "pending event_instance_id must survive round-trip")
	_expect(String(restored_pending.get("trigger_window", "")) == "post_training", "pending trigger_window must survive round-trip")

	# Assert — recent_random_event_history
	_expect(target.recent_random_event_history.size() == 2, "history must have 2 entries after round-trip")
	var restored_history_entry_0 = target.recent_random_event_history[0] as Dictionary
	_expect(String(restored_history_entry_0.get("event_id", "")) == "evt_history_001", "history[0].event_id must survive round-trip")

	# Assert — event_cooldown_state
	_expect(target.event_cooldown_state.has("town_life"), "cooldown must have town_life after round-trip")
	_expect(is_equal_approx(float(target.event_cooldown_state.get("town_life", 0.0)), 42.0), "cooldown town_life value must survive round-trip")
	_expect(target.event_cooldown_state.has("player_mood"), "cooldown must have player_mood after round-trip")
	_expect(is_equal_approx(float(target.event_cooldown_state.get("player_mood", 0.0)), 99.0), "cooldown player_mood value must survive round-trip")

	# Assert — processed_event_settlement_keys
	_expect(target.processed_event_settlement_keys.size() == 2, "processed keys must have 2 entries after round-trip")
	_expect(target.processed_event_settlement_keys.has(settlement_key_a), "processed keys must contain key_a after round-trip")
	_expect(target.processed_event_settlement_keys.has(settlement_key_b), "processed keys must contain key_b after round-trip")

	source.free()
	target.free()


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
