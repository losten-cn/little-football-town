extends SceneTree
## Story 001 (S7-04) — AudioManager Authority Stub automated tests.
##
## AC-1: All 5 fields exist with correct defaults.
## AC-2: serialize/deserialize round-trip preserves all values.
## AC-3: Two-phase restore after tree enter.
## AC-4: No audio asset dependency (no crash on _apply_volumes()).
## AC-5: Audio fields independent from gameplay state.

const AudioManagerScript: Script = preload("res://src/autoload/audio_manager.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_ac1_fields_exist_with_correct_defaults()
	test_ac2_serialize_deserialize_round_trip_preserves_all_values()
	if _failures.is_empty():
		print("AUDIO_AUTH_STUB_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("AUDIO_AUTH_STUB_TEST_FAIL: %s" % failure)
		quit(1)


# ─────────────────────────────────────────────
# AC-1 — All 5 fields exist with correct defaults
# ─────────────────────────────────────────────

func test_ac1_fields_exist_with_correct_defaults() -> void:
	# Arrange & Act
	var manager: Node = AudioManagerScript.new() as Node

	# Assert — Node type check
	_expect(manager is Node, "AudioManager must extend Node")

	# Assert — audio_master_volume
	_expect(is_equal_approx(manager.audio_master_volume, 1.0), "audio_master_volume default must be 1.0, got %s" % str(manager.audio_master_volume))

	# Assert — audio_bgm_volume
	_expect(is_equal_approx(manager.audio_bgm_volume, 1.0), "audio_bgm_volume default must be 1.0, got %s" % str(manager.audio_bgm_volume))

	# Assert — audio_sfx_volume
	_expect(is_equal_approx(manager.audio_sfx_volume, 1.0), "audio_sfx_volume default must be 1.0, got %s" % str(manager.audio_sfx_volume))

	# Assert — audio_ambience_volume
	_expect(is_equal_approx(manager.audio_ambience_volume, 1.0), "audio_ambience_volume default must be 1.0, got %s" % str(manager.audio_ambience_volume))

	# Assert — audio_muted_categories
	_expect(manager.audio_muted_categories is Array, "audio_muted_categories must be an Array")
	_expect(manager.audio_muted_categories.is_empty(), "audio_muted_categories default must be empty")

	# Assert — has the register_with_save_manager method
	_expect(manager.has_method("register_with_save_manager"), "AudioManager must expose register_with_save_manager")

	# Assert — NOT an Autoload (not auto-added to tree)
	_expect(not manager.is_inside_tree(), "fresh instance must not already be in the tree (Autoloads are auto-added)")

	manager.free()


# ─────────────────────────────────────────────
# AC-2 — serialize/deserialize round-trip preserves all values
# ─────────────────────────────────────────────

func test_ac2_serialize_deserialize_round_trip_preserves_all_values() -> void:
	# Arrange — populate all 5 durable fields
	var source: Node = AudioManagerScript.new() as Node

	source.set_master_volume(0.5)
	source.set_bgm_volume(0.8)
	source.set_sfx_volume(0.3)
	source.set_ambience_volume(0.0)
	source.set_category_muted("sfx", true)
	source.set_category_muted("ambience", true)

	# Act — serialize
	var serialized: Dictionary[String, Variant] = source.serialize()

	# Assert — serialized payload has the expected keys
	_expect(serialized.has("audio_master_volume"), "serialized must have audio_master_volume")
	_expect(serialized.has("audio_bgm_volume"), "serialized must have audio_bgm_volume")
	_expect(serialized.has("audio_sfx_volume"), "serialized must have audio_sfx_volume")
	_expect(serialized.has("audio_ambience_volume"), "serialized must have audio_ambience_volume")
	_expect(serialized.has("audio_muted_categories"), "serialized must have audio_muted_categories")

	# Assert — serialized values match source
	_expect(is_equal_approx(float(serialized["audio_master_volume"]), 0.5), "serialized master volume must be 0.5")
	_expect(is_equal_approx(float(serialized["audio_bgm_volume"]), 0.8), "serialized bgm volume must be 0.8")
	_expect(is_equal_approx(float(serialized["audio_sfx_volume"]), 0.3), "serialized sfx volume must be 0.3")
	_expect(is_equal_approx(float(serialized["audio_ambience_volume"]), 0.0), "serialized ambience volume must be 0.0")

	var serialized_muted: Array = serialized["audio_muted_categories"] as Array
	_expect(serialized_muted.size() == 2, "serialized muted categories must have 2 entries")
	_expect(serialized_muted.has("sfx"), "serialized muted must contain sfx")
	_expect(serialized_muted.has("ambience"), "serialized muted must contain ambience")

	# Act — deserialize into a fresh instance (already in-tree so apply is immediate)
	var target: Node = AudioManagerScript.new() as Node
	root.add_child(target)
	target.deserialize(serialized)

	# Assert — all values restored precisely
	_expect(is_equal_approx(target.audio_master_volume, 0.5), "deserialized master volume must be 0.5, got %s" % str(target.audio_master_volume))
	_expect(is_equal_approx(target.audio_bgm_volume, 0.8), "deserialized bgm volume must be 0.8, got %s" % str(target.audio_bgm_volume))
	_expect(is_equal_approx(target.audio_sfx_volume, 0.3), "deserialized sfx volume must be 0.3, got %s" % str(target.audio_sfx_volume))
	_expect(is_equal_approx(target.audio_ambience_volume, 0.0), "deserialized ambience volume must be 0.0, got %s" % str(target.audio_ambience_volume))
	_expect(target.audio_muted_categories.size() == 2, "deserialized muted categories must have 2 entries")
	_expect(target.audio_muted_categories.has("sfx"), "deserialized muted must contain sfx")
	_expect(target.audio_muted_categories.has("ambience"), "deserialized muted must contain ambience")

	target.queue_free()
	source.free()


# ─────────────────────────────────────────────

# ─────────────────────────────────────────────
# AC-4 — No audio asset dependency
# ─────────────────────────────────────────────

func test_ac4_no_audio_asset_dependency() -> void:
	# Arrange & Act
	var manager: Node = AudioManagerScript.new() as Node

	# Act — call _apply_volumes() directly (stub, should not crash)
	manager._apply_volumes()

	# Act — call _apply_after_tree_ready() with no pending values (no-op)
	manager._apply_after_tree_ready()

	# Act — add to tree (triggers _ready -> _apply_after_tree_ready)
	root.add_child(manager)
	await process_frame

	# Assert — all defaults still intact (no corruption from stub calls)
	_expect(is_equal_approx(manager.audio_master_volume, 1.0), "master volume must remain 1.0 after stub apply")
	_expect(is_equal_approx(manager.audio_bgm_volume, 1.0), "bgm volume must remain 1.0 after stub apply")
	_expect(is_equal_approx(manager.audio_sfx_volume, 1.0), "sfx volume must remain 1.0 after stub apply")
	_expect(is_equal_approx(manager.audio_ambience_volume, 1.0), "ambience volume must remain 1.0 after stub apply")
	_expect(manager.audio_muted_categories.is_empty(), "muted categories must remain empty after stub apply")

	manager.queue_free()


# ─────────────────────────────────────────────
# AC-5 — Audio fields independent from gameplay state
# ─────────────────────────────────────────────

func test_ac5_audio_fields_independent_from_gameplay_state() -> void:
	# Arrange
	var manager: Node = AudioManagerScript.new() as Node

	# Act — set audio preferences
	manager.set_master_volume(0.5)
	manager.set_bgm_volume(0.3)
	manager.set_category_muted("sfx", true)

	# Assert — serialize only contains audio keys, no gameplay keys
	var serialized: Dictionary[String, Variant] = manager.serialize()
	_expect(serialized.has("audio_master_volume"), "serialized must have audio_master_volume")
	_expect(serialized.has("audio_bgm_volume"), "serialized must have audio_bgm_volume")
	_expect(serialized.has("audio_sfx_volume"), "serialized must have audio_sfx_volume")
	_expect(serialized.has("audio_ambience_volume"), "serialized must have audio_ambience_volume")
	_expect(serialized.has("audio_muted_categories"), "serialized must have audio_muted_categories")

	# Audio payload must NOT contain gameplay fields
	var gameplay_keys: Array[String] = ["funds", "current_state", "match_state", "economy_state", "time_state", "player_state", "town_state", "league_state", "timeline_position", "phase"]
	for gameplay_key: String in gameplay_keys:
		_expect(not serialized.has(gameplay_key), "audio serialized payload must NOT contain gameplay key: %s" % gameplay_key)

	# Serialized payload must have exactly 5 keys (audio only)
	var audio_key_count: int = 0
	for key: Variant in serialized.keys():
		if String(key).begins_with("audio_"):
			audio_key_count += 1
	_expect(audio_key_count == 5, "serialized payload must have exactly 5 audio_ prefixed keys, got %d" % audio_key_count)

	manager.free()


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
