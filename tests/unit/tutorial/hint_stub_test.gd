extends SceneTree
## Story 001 (S8-04) — TutorialHintManager Authority Stub automated tests.
##
## AC-1: All 4 durable fields exist with correct initial values.
##   Node is scene-instantiated (class_name), not Autoload.
## AC-2: Onboarding guided-state consumption — guided users get
##   first-time text; returning users get context help.
## AC-3: Cooldown suppression — same hint_id within cooldown
##   returns empty payload; disabled hints permanently suppressed.
## AC-4: serialize/deserialize round-trip preserves all fields
##   including cooldown timestamps.
## AC-5: disable_hint() only affects hint state; gameplay state
##   is untouched. Closing/ignoring hints causes no resource loss.

const TutorialHintManagerScript: Script = preload("res://src/core/tutorial_hint_manager.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_ac1_fields_exist_with_correct_defaults()
	test_ac2_onboarding_guided_state_consumption()
	test_ac3_cooldown_suppression_and_disabled_permanent_suppression()
	test_ac4_serialize_deserialize_round_trip()
	test_ac5_disable_hint_does_not_affect_gameplay_state()
	test_ac5b_get_hint_view_payload_read_only_no_side_effects()

	if _failures.is_empty():
		print("HINT_STUB_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("HINT_STUB_TEST_FAIL: %s" % failure)
		quit(1)


# ─────────────────────────────────────────────
# AC-1 — Fields exist with correct defaults; Node is scene-instantiated
# ─────────────────────────────────────────────

func test_ac1_fields_exist_with_correct_defaults() -> void:
	# Arrange & Act
	var manager: Node = TutorialHintManagerScript.new() as Node

	# Assert — Node type check
	_expect(manager is Node, "TutorialHintManager must extend Node")

	# Assert — seen_hints
	_expect(manager.seen_hints is Array, "seen_hints must be an Array")
	_expect(manager.seen_hints.is_empty(), "seen_hints default must be empty")

	# Assert — disabled_hints
	_expect(manager.disabled_hints is Array, "disabled_hints must be an Array")
	_expect(manager.disabled_hints.is_empty(), "disabled_hints default must be empty")

	# Assert — hint_cooldowns
	_expect(manager.hint_cooldowns is Dictionary, "hint_cooldowns must be a Dictionary")
	_expect(manager.hint_cooldowns.is_empty(), "hint_cooldowns default must be empty")

	# Assert — help_index_visible
	_expect(manager.help_index_visible == false, "help_index_visible default must be false")

	# Assert — NOT an Autoload (not auto-added to tree)
	_expect(not manager.is_inside_tree(), "fresh instance must not already be in the tree (Autoloads are auto-added)")

	# Assert — public methods exist
	_expect(manager.has_method("request_hint"), "TutorialHintManager must expose request_hint")
	_expect(manager.has_method("get_hint_view_payload"), "TutorialHintManager must expose get_hint_view_payload")
	_expect(manager.has_method("disable_hint"), "TutorialHintManager must expose disable_hint")
	_expect(manager.has_method("mark_seen"), "TutorialHintManager must expose mark_seen")
	_expect(manager.has_method("serialize"), "TutorialHintManager must expose serialize")
	_expect(manager.has_method("deserialize"), "TutorialHintManager must expose deserialize")
	_expect(manager.has_method("register_with_save_manager"), "TutorialHintManager must expose register_with_save_manager")
	_expect(manager.has_method("set_onboarding_check"), "TutorialHintManager must expose set_onboarding_check")

	manager.free()


# ─────────────────────────────────────────────
# AC-2 — Onboarding guided-state consumption
# ─────────────────────────────────────────────

func test_ac2_onboarding_guided_state_consumption() -> void:
	# Arrange — manager with guided=true override
	var manager_guided: Node = TutorialHintManagerScript.new() as Node
	manager_guided.set_onboarding_check(Callable(self, "_mock_is_guided_true"))

	# Act — request hint for guided user
	var guided_payload: Dictionary = manager_guided.request_hint("first_training", 1000.0)

	# Assert — guided payload
	_expect(not guided_payload.is_empty(), "guided user must receive a hint payload")
	_expect(String(guided_payload.get("user_type", "")) == "guided", "guided payload user_type must be 'guided', got '%s'" % String(guided_payload.get("user_type", "")))
	_expect(String(guided_payload.get("core_text", "")) != "", "guided core_text must not be empty")
	_expect(String(guided_payload.get("hint_id", "")) == "first_training", "guided payload hint_id must match")
	_expect(String(guided_payload.get("category", "")) != "", "guided payload category must not be empty")

	# Arrange — manager with guided=false override
	var manager_returning: Node = TutorialHintManagerScript.new() as Node
	manager_returning.set_onboarding_check(Callable(self, "_mock_is_guided_false"))

	# Act — request hint for returning user
	var returning_payload: Dictionary = manager_returning.request_hint("first_training", 1000.0)

	# Assert — returning payload
	_expect(not returning_payload.is_empty(), "returning user must receive a hint payload")
	_expect(String(returning_payload.get("user_type", "")) == "returning", "returning payload user_type must be 'returning', got '%s'" % String(returning_payload.get("user_type", "")))

	# Assert — guided and returning produce different core_text for
	# hints that have guided-specific copy (like "first_training")
	var guided_core: String = String(guided_payload.get("core_text", ""))
	var returning_core: String = String(returning_payload.get("core_text", ""))
	_expect(guided_core != returning_core, "guided and returning core_text must differ for hints with guided-specific copy: guided='%s' returning='%s'" % [guided_core, returning_core])

	manager_guided.free()
	manager_returning.free()


# ─────────────────────────────────────────────
# AC-3 — Cooldown suppression & permanent disable
# ─────────────────────────────────────────────

func test_ac3_cooldown_suppression_and_disabled_permanent_suppression() -> void:
	# Arrange — inject mock so _is_guided_user works without tree
	var manager: Node = TutorialHintManagerScript.new() as Node
	manager.set_onboarding_check(Callable(self, "_mock_is_guided_true"))

	# Act — first request at time=1000.0 (must succeed: no cooldown)
	var first_payload: Dictionary = manager.request_hint("first_training", 1000.0)
	_expect(not first_payload.is_empty(), "first request must return a valid payload")

	# Assert — hint is now in seen_hints
	_expect(manager.seen_hints.has("first_training"), "seen_hints must contain 'first_training' after first request")

	# Assert — cooldown is set
	_expect(manager.hint_cooldowns.has("first_training"), "hint_cooldowns must have 'first_training' entry after first request")

	# Act — second request at time=1100.0 (100s later, within 300s cooldown)
	var second_payload: Dictionary = manager.request_hint("first_training", 1100.0)
	_expect(second_payload.is_empty(), "second request within cooldown must return empty dict")

	# Act — third request at time=1500.0 (500s later, past 300s cooldown)
	var third_payload: Dictionary = manager.request_hint("first_training", 1500.0)
	_expect(not third_payload.is_empty(), "third request past cooldown must return a valid payload")

	# --- Permanent disable ---
	# Arrange — fresh manager with mock
	var manager2: Node = TutorialHintManagerScript.new() as Node
	manager2.set_onboarding_check(Callable(self, "_mock_is_guided_true"))

	# Act — disable a hint
	manager2.disable_hint("resource_summary")
	_expect(manager2.disabled_hints.has("resource_summary"), "disabled_hints must contain 'resource_summary' after disable_hint")

	# Act — request disabled hint
	var disabled_payload: Dictionary = manager2.request_hint("resource_summary", 1000.0)
	_expect(disabled_payload.is_empty(), "disabled hint must return empty payload from request_hint")

	# Act — get_hint_view_payload for disabled hint
	var disabled_view: Dictionary = manager2.get_hint_view_payload("resource_summary")
	_expect(disabled_view.is_empty(), "disabled hint must return empty payload from get_hint_view_payload")

	manager.free()
	manager2.free()


# ─────────────────────────────────────────────
# AC-4 — serialize/deserialize round-trip
# ─────────────────────────────────────────────

func test_ac4_serialize_deserialize_round_trip() -> void:
	# Arrange — populate all 4 durable fields
	var source: Node = TutorialHintManagerScript.new() as Node

	source.seen_hints.append("first_training")
	source.seen_hints.append("first_match_pre")
	source.seen_hints.append("first_match_result")
	source.disabled_hints.append("resource_summary")
	source.hint_cooldowns["first_training"] = 1500.0
	source.hint_cooldowns["first_match_pre"] = 1600.0
	source.hint_cooldowns["first_match_result"] = 1700.0
	source.help_index_visible = true

	# Act — serialize
	var serialized: Dictionary[String, Variant] = source.serialize()

	# Assert — serialized payload has expected keys
	_expect(serialized.has("seen_hints"), "serialized must have seen_hints")
	_expect(serialized.has("disabled_hints"), "serialized must have disabled_hints")
	_expect(serialized.has("hint_cooldowns"), "serialized must have hint_cooldowns")
	_expect(serialized.has("help_index_visible"), "serialized must have help_index_visible")

	# Act — deserialize into a fresh instance
	var target: Node = TutorialHintManagerScript.new() as Node
	target.deserialize(serialized)

	# Assert — seen_hints restored
	_expect(target.seen_hints.size() == 3, "deserialized seen_hints must have 3 entries, got %d" % target.seen_hints.size())
	_expect(target.seen_hints.has("first_training"), "deserialized seen_hints must contain first_training")
	_expect(target.seen_hints.has("first_match_pre"), "deserialized seen_hints must contain first_match_pre")
	_expect(target.seen_hints.has("first_match_result"), "deserialized seen_hints must contain first_match_result")

	# Assert — disabled_hints restored
	_expect(target.disabled_hints.size() == 1, "deserialized disabled_hints must have 1 entry, got %d" % target.disabled_hints.size())
	_expect(target.disabled_hints.has("resource_summary"), "deserialized disabled_hints must contain resource_summary")

	# Assert — hint_cooldowns restored with float precision
	_expect(target.hint_cooldowns.has("first_training"), "deserialized cooldowns must have first_training")
	_expect(is_equal_approx(float(target.hint_cooldowns.get("first_training", 0.0)), 1500.0), "cooldown first_training must be 1500.0, got %s" % str(target.hint_cooldowns.get("first_training")))
	_expect(is_equal_approx(float(target.hint_cooldowns.get("first_match_pre", 0.0)), 1600.0), "cooldown first_match_pre must be 1600.0, got %s" % str(target.hint_cooldowns.get("first_match_pre")))
	_expect(is_equal_approx(float(target.hint_cooldowns.get("first_match_result", 0.0)), 1700.0), "cooldown first_match_result must be 1700.0, got %s" % str(target.hint_cooldowns.get("first_match_result")))

	# Assert — help_index_visible restored
	_expect(target.help_index_visible == true, "deserialized help_index_visible must be true, got %s" % str(target.help_index_visible))

	source.free()
	target.free()


# ─────────────────────────────────────────────
# AC-5 — disable_hint does not affect gameplay state
# ─────────────────────────────────────────────

func test_ac5_disable_hint_does_not_affect_gameplay_state() -> void:
	# Arrange
	var manager: Node = TutorialHintManagerScript.new() as Node

	# Act — capture state before disable
	var seen_before: int = manager.seen_hints.size()
	var disabled_before: int = manager.disabled_hints.size()
	var cooldowns_before: int = manager.hint_cooldowns.size()
	var help_before: bool = manager.help_index_visible

	# Act — disable a hint
	manager.disable_hint("first_training")

	# Assert — only disabled_hints changed (1 element added), other fields untouched
	_expect(manager.seen_hints.size() == seen_before, "seen_hints must not change after disable_hint (was %d, now %d)" % [seen_before, manager.seen_hints.size()])
	_expect(manager.disabled_hints.size() == disabled_before + 1, "disabled_hints must increase by exactly 1 after disable_hint")
	_expect(manager.hint_cooldowns.size() == cooldowns_before, "hint_cooldowns must not change after disable_hint (was %d, now %d)" % [cooldowns_before, manager.hint_cooldowns.size()])
	_expect(manager.help_index_visible == help_before, "help_index_visible must not change after disable_hint")

	# Assert — double-disable is a no-op (no duplicate entries)
	manager.disable_hint("first_training")
	_expect(manager.disabled_hints.size() == disabled_before + 1, "double disable_hint must not create duplicate entries")

	# Assert — empty hint_id is a safe no-op
	manager.disable_hint("")
	_expect(manager.disabled_hints.size() == disabled_before + 1, "disable_hint with empty string must be a no-op")

	manager.free()


# ─────────────────────────────────────────────
# AC-5b — get_hint_view_payload is read-only (no side effects)
# ─────────────────────────────────────────────

func test_ac5b_get_hint_view_payload_read_only_no_side_effects() -> void:
	# Arrange — inject mock so _is_guided_user works without tree
	var manager: Node = TutorialHintManagerScript.new() as Node
	manager.set_onboarding_check(Callable(self, "_mock_is_guided_true"))

	# Act — capture state before view-payload calls
	var seen_before: int = manager.seen_hints.size()
	var cooldowns_before: int = manager.hint_cooldowns.size()

	# Act — call get_hint_view_payload (read-only)
	var payload: Dictionary = manager.get_hint_view_payload("first_training")

	# Assert — payload is returned
	_expect(not payload.is_empty(), "get_hint_view_payload must return a payload for known hint")
	_expect(String(payload.get("hint_id", "")) == "first_training", "get_hint_view_payload hint_id must match")

	# Assert — no side effects on durable state
	_expect(manager.seen_hints.size() == seen_before, "get_hint_view_payload must not modify seen_hints (was %d, now %d)" % [seen_before, manager.seen_hints.size()])
	_expect(manager.hint_cooldowns.size() == cooldowns_before, "get_hint_view_payload must not modify hint_cooldowns (was %d, now %d)" % [cooldowns_before, manager.hint_cooldowns.size()])

	# Act — empty hint_id returns empty dict safely
	var empty_payload: Dictionary = manager.get_hint_view_payload("")
	_expect(empty_payload.is_empty(), "get_hint_view_payload with empty hint_id must return empty dict")

	# Act — unrecognised hint_id returns empty dict safely
	var unknown_payload: Dictionary = manager.get_hint_view_payload("nonexistent_hint_id_xyz")
	_expect(unknown_payload.is_empty(), "get_hint_view_payload with unknown hint_id must return empty dict")

	manager.free()


# ─────────────────────────────────────────────
# Mock callables for DI testing
# ─────────────────────────────────────────────

func _mock_is_guided_true() -> bool:
	return true


func _mock_is_guided_false() -> bool:
	return false


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
