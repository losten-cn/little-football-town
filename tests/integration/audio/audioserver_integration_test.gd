extends Node
## Story 002 (S8-02) — AudioServer Integration + BGM automated integration tests.
##
## AC-1: _apply_volumes() sets AudioServer bus volumes correctly.
## AC-2: set_game_state() switches BGM/ducking per state.
## AC-3: request_sfx() enforces cooldown and returns false during suppression.
## AC-4: Null stream graceful degrade — no crash.
## AC-5: Priority ducking — match_whistle > sfx > ambience (ambience muted in match_live).

const AUDIO_MANAGER_PATH: String = "/root/AudioManager"
const EPSILON_DB: float = 0.01
const EPSILON_LINEAR: float = 0.001

var _failures: Array[String] = []


func _audio_manager() -> Node:
	return get_node(AUDIO_MANAGER_PATH)


func _ready() -> void:
	# Reset AudioManager to a clean state before running tests.
	_reset_audio_manager()

	test_ac1_apply_volumes_sets_bus_volumes()
	_reset_audio_manager()

	test_ac2_set_game_state_switches_bgm_ducking()
	_reset_audio_manager()

	test_ac3_sfx_cooldown_suppression()
	_reset_audio_manager()

	test_ac4_null_stream_graceful_degrade()
	_reset_audio_manager()

	test_ac5_priority_ducking_ambience_suppressed_in_match_live()
	_reset_audio_manager()

	if _failures.is_empty():
		print("AUDIOSERVER_INTEGRATION_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("AUDIOSERVER_INTEGRATION_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


# ─────────────────────────────────────────────
# Test State Helpers
# ─────────────────────────────────────────────

func _reset_audio_manager() -> void:
	var am: Node = _audio_manager()
	am.set_master_volume(1.0)
	am.set_bgm_volume(1.0)
	am.set_sfx_volume(1.0)
	am.set_ambience_volume(1.0)
	# Clear all muted categories.
	for category: String in ["master", "bgm", "sfx", "ambience"]:
		am.set_category_muted(category, false)
	am.set_game_state("daily")
	# Reset SFX cooldowns by clearing the internal dictionary.
	am._sfx_cooldowns.clear()


# ─────────────────────────────────────────────
# AC-1 — _apply_volumes() sets AudioServer bus volumes
# ─────────────────────────────────────────────

func test_ac1_apply_volumes_sets_bus_volumes() -> void:
	# Arrange
	var am: Node = _audio_manager()
	am.set_master_volume(0.5)

	# Act — _apply_volumes() is called internally by set_master_volume

	# Assert — master bus volume matches linear2db(0.5)
	var master_index: int = AudioServer.get_bus_index(&"Master")
	var actual_db: float = AudioServer.get_bus_volume_db(master_index)
	var expected_db: float = linear_to_db(0.5)
	_expect(_approx(actual_db, expected_db, EPSILON_DB),
		"AC-1: master bus volume should be %s dB, got %s dB" % [str(expected_db), str(actual_db)])

	# Arrange — set BGM to 0.25
	am.set_bgm_volume(0.25)

	# Assert
	var bgm_index: int = AudioServer.get_bus_index(&"BGM")
	var bgm_db: float = AudioServer.get_bus_volume_db(bgm_index)
	var expected_bgm_db: float = linear_to_db(0.25)
	_expect(_approx(bgm_db, expected_bgm_db, EPSILON_DB),
		"AC-1: BGM bus volume should be %s dB, got %s dB" % [str(expected_bgm_db), str(bgm_db)])

	# Arrange — SFX to 0.0 (floor)
	am.set_sfx_volume(0.0)

	# Assert — SFX at DB_FLOOR
	var sfx_index: int = AudioServer.get_bus_index(&"SFX")
	var sfx_db: float = AudioServer.get_bus_volume_db(sfx_index)
	_expect(sfx_db <= -70.0,
		"AC-1: SFX bus with volume 0.0 should be near DB_FLOOR, got %s dB" % str(sfx_db))

	# Arrange — Ambience to 0.0
	am.set_ambience_volume(0.0)
	var ambience_index: int = AudioServer.get_bus_index(&"Ambience")
	var ambience_db: float = AudioServer.get_bus_volume_db(ambience_index)
	_expect(ambience_db <= -70.0,
		"AC-1: Ambience bus with volume 0.0 should be near DB_FLOOR, got %s dB" % str(ambience_db))

	# Arrange — set all volumes to 1.0, verify they're back at 0 dB
	am.set_master_volume(1.0)
	am.set_bgm_volume(1.0)
	am.set_sfx_volume(1.0)
	am.set_ambience_volume(1.0)

	var master_unity: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Master"))
	_expect(_approx(master_unity, 0.0, EPSILON_DB),
		"AC-1: master bus at 1.0 should be ~0 dB, got %s dB" % str(master_unity))


# ─────────────────────────────────────────────
# AC-2 — set_game_state() switches BGM/ducking per state
# ─────────────────────────────────────────────

func test_ac2_set_game_state_switches_bgm_ducking() -> void:
	var am: Node = _audio_manager()
	var bgm_index: int = AudioServer.get_bus_index(&"BGM")
	var ambience_index: int = AudioServer.get_bus_index(&"Ambience")

	# Stage 1: daily — all buses at user prefs (1.0), no ducking.
	am.set_game_state("daily")
	var bgm_daily: float = AudioServer.get_bus_volume_db(bgm_index)
	_expect(_approx(bgm_daily, 0.0, EPSILON_DB),
		"AC-2: daily BGM should be 0 dB (unity), got %s dB" % str(bgm_daily))
	_expect(not AudioServer.is_bus_mute(ambience_index),
		"AC-2: daily ambience should not be muted")

	# Stage 2: match_live — BGM ducked, ambience muted.
	am.set_game_state("match_live")
	var bgm_ducked: float = AudioServer.get_bus_volume_db(bgm_index)
	var expected_ducked_db: float = linear_to_db(1.0 * 0.6)  # DUCK_BGM_VOLUME
	_expect(_approx(bgm_ducked, expected_ducked_db, EPSILON_DB),
		"AC-2: match_live BGM should be %s dB (ducked to 0.6x), got %s dB" % [str(expected_ducked_db), str(bgm_ducked)])
	_expect(AudioServer.is_bus_mute(ambience_index),
		"AC-2: match_live ambience should be muted")

	# Stage 3: post_match — BGM restored, ambience muted.
	am.set_game_state("post_match")
	var bgm_restored: float = AudioServer.get_bus_volume_db(bgm_index)
	_expect(_approx(bgm_restored, 0.0, EPSILON_DB),
		"AC-2: post_match BGM should be restored to 0 dB, got %s dB" % str(bgm_restored))
	_expect(AudioServer.is_bus_mute(ambience_index),
		"AC-2: post_match ambience should be muted")

	# Stage 4: return to daily — ambience unmuted.
	am.set_game_state("daily")
	_expect(not AudioServer.is_bus_mute(ambience_index),
		"AC-2: returning to daily should unmute ambience")

	# Stage 5: verify get_game_state() returns correct value.
	am.set_game_state("match_live")
	_expect(am.get_game_state() == "match_live",
		"AC-2: get_game_state() should return 'match_live', got '%s'" % am.get_game_state())

	# Stage 6: unknown state clamps to daily with warning.
	am.set_game_state("unknown_fantasy_state")
	_expect(am.get_game_state() == "daily",
		"AC-2: unknown state should clamp to 'daily', got '%s'" % am.get_game_state())
	_expect(not AudioServer.is_bus_mute(ambience_index),
		"AC-2: after unknown state clamp, ambience should not be muted")


# ─────────────────────────────────────────────
# AC-3 — request_sfx() cooldown suppression
# ─────────────────────────────────────────────

func test_ac3_sfx_cooldown_suppression() -> void:
	var am: Node = _audio_manager()

	# First request should succeed.
	var first: bool = am.request_sfx("goal")
	_expect(first, "AC-3: first request_sfx('goal') should return true")

	# Second request within cooldown should fail.
	var second: bool = am.request_sfx("goal")
	_expect(not second, "AC-3: second request_sfx('goal') within cooldown should return false")

	# Different SFX id should still pass (independent cooldowns).
	var different: bool = am.request_sfx("whistle")
	_expect(different, "AC-3: request_sfx('whistle') with independent cooldown should return true")

	# Muted SFX category should suppress.
	am.set_category_muted("sfx", true)
	var muted_check: bool = am.request_sfx("crowd_cheer")
	_expect(not muted_check, "AC-3: request_sfx should return false when SFX category is muted")
	am.set_category_muted("sfx", false)

	# SFX volume 0 should suppress.
	am.set_sfx_volume(0.0)
	var zero_volume_check: bool = am.request_sfx("crowd_cheer")
	_expect(not zero_volume_check, "AC-3: request_sfx should return false when SFX volume is 0")
	am.set_sfx_volume(1.0)

	# Fully new SFX id after cooldown resets should pass.
	am._sfx_cooldowns.clear()
	var fresh: bool = am.request_sfx("goal")
	_expect(fresh, "AC-3: request_sfx('goal') after cooldown clear should return true")


# ─────────────────────────────────────────────
# AC-4 — Null stream graceful degrade (no crash)
# ─────────────────────────────────────────────

func test_ac4_null_stream_graceful_degrade() -> void:
	var am: Node = _audio_manager()

	# Create an AudioStreamPlayer with null stream and add it to AudioManager.
	# AudioManager itself does not play streams yet (Story 003), but we verify
	# its internal infrastructure (buses, cooldowns, volume application) does not
	# crash in the absence of actual audio assets.
	var null_player := AudioStreamPlayer.new()
	null_player.stream = null
	null_player.name = "TestNullStreamPlayer"
	am.add_child(null_player)

	# Attempt to play — stream is null, should not crash.
	# Godot's AudioStreamPlayer.play() with null stream logs an error but does not crash.
	# We catch this by verifying the manager state is still consistent.
	null_player.play()

	# Verify AudioManager state is still intact post null-play.
	am.set_master_volume(0.7)
	am.set_bgm_volume(0.4)
	am.set_game_state("match_live")
	await get_tree().process_frame

	var bgm_index: int = AudioServer.get_bus_index(&"BGM")
	var bgm_db: float = AudioServer.get_bus_volume_db(bgm_index)
	var expected_db: float = linear_to_db(0.4 * 0.6)  # ducked
	_expect(_approx(bgm_db, expected_db, EPSILON_DB),
		"AC-4: After null-stream play, BGM ducking should still work correctly (got %s dB, expected %s dB)" % [str(bgm_db), str(expected_db)])

	# Clean up.
	null_player.queue_free()

	# Also verify that setting volumes to extreme values does not crash.
	am.set_master_volume(-0.5)  # clamped to 0.0
	_expect(_approx(am.audio_master_volume, 0.0, EPSILON_LINEAR),
		"AC-4: negative volume should clamp to 0.0, got %s" % str(am.audio_master_volume))

	am.set_master_volume(2.5)  # clamped to 1.0
	_expect(_approx(am.audio_master_volume, 1.0, EPSILON_LINEAR),
		"AC-4: volume > 1.0 should clamp to 1.0, got %s" % str(am.audio_master_volume))

	# Reset.
	am.set_master_volume(1.0)


# ─────────────────────────────────────────────
# AC-5 — Priority ducking: match_whistle > sfx > ambience
# ─────────────────────────────────────────────

func test_ac5_priority_ducking_ambience_suppressed_in_match_live() -> void:
	var am: Node = _audio_manager()
	var ambience_index: int = AudioServer.get_bus_index(&"Ambience")
	var bgm_index: int = AudioServer.get_bus_index(&"BGM")
	var sfx_index: int = AudioServer.get_bus_index(&"SFX")

	# Set all volumes to 1.0 for clear testing.
	am.set_master_volume(1.0)
	am.set_bgm_volume(1.0)
	am.set_sfx_volume(1.0)
	am.set_ambience_volume(1.0)

	# Stage 1: daily — ambience plays normally, SFX normal.
	am.set_game_state("daily")
	_expect(not AudioServer.is_bus_mute(ambience_index),
		"AC-5: daily ambience should be unmuted")
	_expect(_approx(AudioServer.get_bus_volume_db(ambience_index), 0.0, EPSILON_DB),
		"AC-5: daily ambience should be 0 dB")
	_expect(_approx(AudioServer.get_bus_volume_db(bgm_index), 0.0, EPSILON_DB),
		"AC-5: daily BGM should be 0 dB")
	_expect(_approx(AudioServer.get_bus_volume_db(sfx_index), 0.0, EPSILON_DB),
		"AC-5: daily SFX should be 0 dB")

	# Stage 2: match_live — match_whistle priority.
	#   BGM ducked, Ambience muted (transient), SFX normal.
	am.set_game_state("match_live")
	_expect(AudioServer.is_bus_mute(ambience_index),
		"AC-5: match_live — ambience should be muted (match_whistle > ambience)")
	var bgm_ducked_db: float = AudioServer.get_bus_volume_db(bgm_index)
	_expect(_approx(bgm_ducked_db, linear_to_db(0.6), EPSILON_DB),
		"AC-5: match_live — BGM should be ducked to 0.6x")
	_expect(_approx(AudioServer.get_bus_volume_db(sfx_index), 0.0, EPSILON_DB),
		"AC-5: match_live — SFX should remain at 0 dB (match_whistle path)")

	# Stage 3: post_match — BGM restored, Ambience still muted.
	am.set_game_state("post_match")
	_expect(AudioServer.is_bus_mute(ambience_index),
		"AC-5: post_match — ambience should remain muted")
	_expect(_approx(AudioServer.get_bus_volume_db(bgm_index), 0.0, EPSILON_DB),
		"AC-5: post_match — BGM should be restored to 0 dB")
	_expect(_approx(AudioServer.get_bus_volume_db(sfx_index), 0.0, EPSILON_DB),
		"AC-5: post_match — SFX should be 0 dB")

	# Stage 4: SFX bus muted at user request — durable, not transient.
	am.set_category_muted("sfx", true)
	_expect(AudioServer.is_bus_mute(sfx_index),
		"AC-5: SFX bus should be muted after set_category_muted('sfx', true)")
	am.set_category_muted("sfx", false)
	_expect(not AudioServer.is_bus_mute(sfx_index),
		"AC-5: SFX bus should be unmuted after set_category_muted('sfx', false)")

	# Stage 5: Verify durable preferences are untouched after ducking.
	_expect(_approx(am.audio_bgm_volume, 1.0, EPSILON_LINEAR),
		"AC-5: durable audio_bgm_volume should still be 1.0 after ducking (not 0.6)")
	_expect(_approx(am.audio_ambience_volume, 1.0, EPSILON_LINEAR),
		"AC-5: durable audio_ambience_volume should still be 1.0 after transient mute")
	_expect(not am.audio_muted_categories.has("ambience"),
		"AC-5: 'ambience' should NOT be in durable muted_categories (transient mute only)")


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

## Verifies two floats are equal within [param tolerance] (default EPSILON_DB).
func _approx(a: float, b: float, tolerance: float = EPSILON_DB) -> bool:
	return abs(a - b) <= tolerance


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
