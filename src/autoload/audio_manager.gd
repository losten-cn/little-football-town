extends Node
## AudioManager autoload — authoritative runtime owner of audio preference state
## and Godot AudioServer integration layer.
##
## Owns five durable-preference fields:
##   audio_master_volume, audio_bgm_volume, audio_sfx_volume,
##   audio_ambience_volume, audio_muted_categories.
##
## Governed by ADR-0013 (Audio Settings & Event Consumption).
## Implements TR-audio-001 through TR-audio-005.
## Story: S7-04 (AudioManager Authority Stub) + S8-02 (AudioServer Integration + BGM).
##
## Audio preferences are durable playback settings only and must
## never affect gameplay or navigation outcomes. The serialize/deserialize
## contract registers with SaveManager under system id "audio".
##
## Usage:
##   var payload := AudioManager.build_audio_settings_payload()
##   AudioManager.set_master_volume(0.8)
##   AudioManager.set_bgm_volume(0.5)
##   AudioManager.set_sfx_volume(0.6)
##   AudioManager.set_ambience_volume(0.3)
##   AudioManager.set_category_muted("sfx", true)
##   AudioManager.set_game_state("match_live")
##   var eligible := AudioManager.request_sfx("goal")

const DEFAULT_VOLUME: float = 1.0
const VOLUME_MIN: float = 0.0
const VOLUME_MAX: float = 1.0

## DB value used when linear volume is 0.0 (effectively silent).
const DB_FLOOR: float = -80.0

## Default SFX cooldown in seconds. Same sfx_id cannot play again within this window.
const SFX_COOLDOWN_SECONDS: float = 2.0

## Ducking multiplier applied to BGM bus during match_live state.
## Does not modify the durable audio_bgm_volume preference.
const DUCK_BGM_VOLUME: float = 0.6

## Valid game state identifiers for BGM switching.
const GAME_STATE_DAILY: String = "daily"
const GAME_STATE_MATCH_LIVE: String = "match_live"
const GAME_STATE_POST_MATCH: String = "post_match"

const _KNOWN_GAME_STATES: Array[String] = [GAME_STATE_DAILY, GAME_STATE_MATCH_LIVE, GAME_STATE_POST_MATCH]

## Audio bus names used in the Godot AudioServer bus layout.
const BUS_MASTER: StringName = &"Master"
const BUS_BGM: StringName = &"BGM"
const BUS_SFX: StringName = &"SFX"
const BUS_AMBIENCE: StringName = &"Ambience"

## Master volume [0.0, 1.0]. Default 1.0.
var audio_master_volume: float = DEFAULT_VOLUME

## BGM volume [0.0, 1.0]. Default 1.0.
var audio_bgm_volume: float = DEFAULT_VOLUME

## SFX volume [0.0, 1.0]. Default 1.0.
var audio_sfx_volume: float = DEFAULT_VOLUME

## Ambience volume [0.0, 1.0]. Default 1.0.
var audio_ambience_volume: float = DEFAULT_VOLUME

## List of muted audio category names. Default empty.
var audio_muted_categories: Array = []  ## Array[String]

## Pending restored values waiting for two-phase apply.
## Set by deserialize() before save-managed restore; cleared after apply.
var _pending_restored_values: Variant = null

## Current game state for BGM switching. One of GAME_STATE_*.
var _game_state: String = GAME_STATE_DAILY

## SFX cooldown ledger: sfx_id -> last play time in msec (Time.get_ticks_msec()).
var _sfx_cooldowns: Dictionary[String, float] = {}

## Whether bus setup has completed. Prevents duplicate bus creation.
var _buses_ready: bool = false

## Cached bus indices. Populated by _setup_audio_buses().
var _bus_index_master: int = -1
var _bus_index_bgm: int = -1
var _bus_index_sfx: int = -1
var _bus_index_ambience: int = -1


# ─────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────

func _ready() -> void:
	name = "AudioManager"
	_setup_audio_buses()
	_apply_after_tree_ready()


# ─────────────────────────────────────────────
# Public API — ADR-0013 Key Interfaces
# ─────────────────────────────────────────────

## Returns a read-only dictionary snapshot of the current audio preference state.
## Consumers must treat this payload as a snapshot and never mutate it.
func build_audio_settings_payload() -> Dictionary[String, Variant]:
	var payload: Dictionary[String, Variant] = {}
	payload["audio_master_volume"] = audio_master_volume
	payload["audio_bgm_volume"] = audio_bgm_volume
	payload["audio_sfx_volume"] = audio_sfx_volume
	payload["audio_ambience_volume"] = audio_ambience_volume
	payload["audio_muted_categories"] = audio_muted_categories.duplicate(true)
	return payload


## Sets the master volume. Clamped to [0.0, 1.0]. Emits audio_settings_changed on EventBus.
## Applies to AudioServer immediately via _apply_volumes().
func set_master_volume(value: float) -> void:
	audio_master_volume = clampf(value, VOLUME_MIN, VOLUME_MAX)
	_apply_volumes()
	_emit_settings_changed()


## Sets the BGM volume. Clamped to [0.0, 1.0]. Emits audio_settings_changed on EventBus.
## Applies to AudioServer immediately via _apply_volumes().
func set_bgm_volume(value: float) -> void:
	audio_bgm_volume = clampf(value, VOLUME_MIN, VOLUME_MAX)
	_apply_volumes()
	_emit_settings_changed()


## Sets the SFX volume. Clamped to [0.0, 1.0]. Emits audio_settings_changed on EventBus.
## Applies to AudioServer immediately via _apply_volumes().
func set_sfx_volume(value: float) -> void:
	audio_sfx_volume = clampf(value, VOLUME_MIN, VOLUME_MAX)
	_apply_volumes()
	_emit_settings_changed()


## Sets the ambience volume. Clamped to [0.0, 1.0]. Emits audio_settings_changed on EventBus.
## Applies to AudioServer immediately via _apply_volumes().
func set_ambience_volume(value: float) -> void:
	audio_ambience_volume = clampf(value, VOLUME_MIN, VOLUME_MAX)
	_apply_volumes()
	_emit_settings_changed()


## Toggles a category's muted state.
## [param category] Category name to mute or unmute.
## [param muted] True to mute, false to unmute.
## Applies to AudioServer immediately via _apply_volumes().
func set_category_muted(category: String, muted: bool) -> void:
	if muted and not audio_muted_categories.has(category):
		audio_muted_categories.append(category)
	elif not muted and audio_muted_categories.has(category):
		audio_muted_categories.erase(category)
	_apply_volumes()
	_emit_settings_changed()


# ─────────────────────────────────────────────
# Public API — Story 002: AudioServer + BGM
# ─────────────────────────────────────────────

## Switches the audio playback configuration based on the game's logical state.
##
## Valid states:
##   - "daily":        All buses at user preference. No ducking.
##   - "match_live":   BGM ducked to 0.6x user preference, Ambience muted, SFX normal.
##   - "post_match":   BGM restored, Ambience muted, SFX normal.
##
## Unknown state strings are clamped to "daily" with a warning.
## [param state] One of GAME_STATE_* constants.
func set_game_state(state: String) -> void:
	if not _KNOWN_GAME_STATES.has(state):
		push_warning("AudioManager: unknown game state '%s', clamping to '%s'." % [state, GAME_STATE_DAILY])
		_game_state = GAME_STATE_DAILY
	else:
		_game_state = state
	_apply_volumes()


## Returns the current game state identifier. Useful for test assertions.
func get_game_state() -> String:
	return _game_state


## Checks eligibility and records a cooldown for the given SFX id.
##
## Returns true if the SFX is eligible to play:
##   - Not currently in cooldown (< SFX_COOLDOWN_SECONDS since last request).
##   - SFX bus is not muted.
##   - SFX volume > 0.
##
## Returns false (silently) if suppressed. Does not actually play audio —
## playback is deferred to Story 003+.
##
## [param sfx_id] Stable identifier for the SFX event (e.g. "goal", "whistle").
func request_sfx(sfx_id: String) -> bool:
	if not get_sfx_eligible(sfx_id):
		return false

	_sfx_cooldowns[sfx_id] = float(Time.get_ticks_msec())
	return true


## Checks whether the given SFX id is eligible to play without modifying cooldown state.
##
## Returns false if:
##   - SFX category is muted.
##   - SFX volume is 0.
##   - The sfx_id is still in cooldown.
##
## [param sfx_id] Stable identifier for the SFX event.
func get_sfx_eligible(sfx_id: String) -> bool:
	if audio_muted_categories.has("sfx"):
		return false
	if is_equal_approx(audio_sfx_volume, 0.0):
		return false

	var last_play: float = _sfx_cooldowns.get(sfx_id, -SFX_COOLDOWN_SECONDS * 1000.0 - 1.0)
	var elapsed_ms: float = float(Time.get_ticks_msec()) - last_play
	if elapsed_ms < SFX_COOLDOWN_SECONDS * 1000.0:
		return false

	return true


# ─────────────────────────────────────────────
# Persistence — ADR-0013 SaveManager Contract
# ─────────────────────────────────────────────

## Returns a read-only snapshot of serializable durable audio state.
func serialize() -> Dictionary[String, Variant]:
	return {
		"audio_master_volume": audio_master_volume,
		"audio_bgm_volume": audio_bgm_volume,
		"audio_sfx_volume": audio_sfx_volume,
		"audio_ambience_volume": audio_ambience_volume,
		"audio_muted_categories": audio_muted_categories.duplicate(true),
	}


## Restores durable audio state from serialized save data.
##
## Implements two-phase restore (ADR-0013 Decision #7):
## 1. Values are stored as pending.
## 2. If the node is inside the tree, apply immediately.
##    Otherwise, apply when _ready() fires and the runtime is ready.
func deserialize(data: Dictionary[String, Variant]) -> void:
	var pending: Dictionary[String, Variant] = {}
	pending["audio_master_volume"] = clampf(float(data.get("audio_master_volume", DEFAULT_VOLUME)), VOLUME_MIN, VOLUME_MAX)
	pending["audio_bgm_volume"] = clampf(float(data.get("audio_bgm_volume", DEFAULT_VOLUME)), VOLUME_MIN, VOLUME_MAX)
	pending["audio_sfx_volume"] = clampf(float(data.get("audio_sfx_volume", DEFAULT_VOLUME)), VOLUME_MIN, VOLUME_MAX)
	pending["audio_ambience_volume"] = clampf(float(data.get("audio_ambience_volume", DEFAULT_VOLUME)), VOLUME_MIN, VOLUME_MAX)

	var restored_muted_categories: Array[String] = []
	var muted_raw: Array = data.get("audio_muted_categories", []) as Array
	for category: Variant in muted_raw:
		var category_str: String = String(category)
		if not category_str.is_empty():
			restored_muted_categories.append(category_str)
	pending["audio_muted_categories"] = restored_muted_categories

	_pending_restored_values = pending
	audio_master_volume = pending["audio_master_volume"]
	audio_bgm_volume = pending["audio_bgm_volume"]
	audio_sfx_volume = pending["audio_sfx_volume"]
	audio_ambience_volume = pending["audio_ambience_volume"]
	audio_muted_categories = restored_muted_categories

	if is_inside_tree():
		_apply_after_tree_ready()


## Registers this system with SaveManager using the audio persistence contract.
##
## System id: "audio" — registered as a durable-state extension payload,
## not a required gameplay system.
func register_with_save_manager(save_manager: Node) -> bool:
	if save_manager == null:
		return false
	return save_manager.register_system("audio", Callable(self, "serialize"), Callable(self, "deserialize"))


# ─────────────────────────────────────────────
# Internal helpers — Bus Setup
# ─────────────────────────────────────────────

## Creates the Master -> BGM/SFX/Ambience bus hierarchy in AudioServer.
##
## Idempotent: if buses already exist with the expected names, this is a no-op.
## BGM, SFX, and Ambience are created as children of Master (bus send target).
## Called once from _ready().
func _setup_audio_buses() -> void:
	if _buses_ready:
		return

	# Resolve bus indices (Master always exists at index 0 in default layout).
	_bus_index_master = AudioServer.get_bus_index(BUS_MASTER)
	if _bus_index_master < 0:
		push_warning("AudioManager: Master bus not found. AudioServer integration will be limited.")
		_buses_ready = true
		return

	# Ensure BGM, SFX, Ambience buses exist. Create if missing.
	_bus_index_bgm = _ensure_bus_exists(BUS_BGM)
	_bus_index_sfx = _ensure_bus_exists(BUS_SFX)
	_bus_index_ambience = _ensure_bus_exists(BUS_AMBIENCE)

	_buses_ready = true


## Returns the bus index for [param bus_name], creating it as a child of Master
## if it does not already exist.
func _ensure_bus_exists(bus_name: StringName) -> int:
	var existing: int = AudioServer.get_bus_index(bus_name)
	if existing >= 0:
		return existing

	# Add the bus at the end and name it.
	var bus_count: int = AudioServer.get_bus_count()
	AudioServer.add_bus(bus_count)
	var new_index: int = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(new_index, bus_name)

	# Route through Master (send to Master bus).
	AudioServer.set_bus_send(new_index, BUS_MASTER)

	return new_index


# ─────────────────────────────────────────────
# Internal helpers — Volume Application
# ─────────────────────────────────────────────

## Applies all durable volume preferences to the AudioServer buses.
##
## This is the canonical volume-apply path. It:
##   1. Reads the four durable volume preference fields + master volume.
##   2. Converts linear [0.0, 1.0] to dB via linear2db().
##   3. Calls AudioServer.set_bus_volume_db() for each bus.
##   4. Applies per-category muting from audio_muted_categories.
##   5. Applies transient ducking from _apply_ducking() (ADR-0013 Decision #5:
##      ducking is a transient layer, not a durable pref mutation).
func _apply_volumes() -> void:
	if not _buses_ready:
		return

	# Master bus volume.
	var master_db: float = _linear_to_db(audio_master_volume)
	AudioServer.set_bus_volume_db(_bus_index_master, master_db)
	AudioServer.set_bus_mute(_bus_index_master, audio_muted_categories.has("master"))

	# BGM bus volume (durable preference).
	var bgm_db: float = _linear_to_db(audio_bgm_volume)
	AudioServer.set_bus_volume_db(_bus_index_bgm, bgm_db)
	AudioServer.set_bus_mute(_bus_index_bgm, audio_muted_categories.has("bgm"))

	# SFX bus volume (durable preference).
	var sfx_db: float = _linear_to_db(audio_sfx_volume)
	AudioServer.set_bus_volume_db(_bus_index_sfx, sfx_db)
	AudioServer.set_bus_mute(_bus_index_sfx, audio_muted_categories.has("sfx"))

	# Ambience bus volume (durable preference).
	var ambience_db: float = _linear_to_db(audio_ambience_volume)
	AudioServer.set_bus_volume_db(_bus_index_ambience, ambience_db)
	AudioServer.set_bus_mute(_bus_index_ambience, audio_muted_categories.has("ambience"))

	# Apply transient ducking layer on top of durable preferences (ADR-0013 Decision #5).
	_apply_ducking()


## Converts a linear [0.0, 1.0] volume value to dB.
##   - 0.0 -> DB_FLOOR (-80 dB, effectively silent)
##   - 1.0 -> 0 dB (unity gain)
##
## Uses Godot's linear2db() for the conversion; clamps minimum to DB_FLOOR.
func _linear_to_db(linear: float) -> float:
	if is_equal_approx(linear, 0.0):
		return DB_FLOOR
	var db: float = linear_to_db(linear)
	return maxf(db, DB_FLOOR)


## Applies transient ducking based on current _game_state.
##
## Per ADR-0013 Decision #5, this is a transient mixing layer applied on top
## of durable bus volume preferences. It never modifies the stored preference
## fields (audio_bgm_volume, audio_ambience_volume, etc.).
##
## Ducking rules:
##   - "daily":        No ducking. Buses use durable prefs as-is.
##   - "match_live":   BGM ducked to DUCK_BGM_VOLUME * durable pref,
##                     Ambience muted (transient mute, not durable).
##   - "post_match":   BGM restored, Ambience muted (transient mute).
func _apply_ducking() -> void:
	if not _buses_ready:
		return

	match _game_state:
		GAME_STATE_DAILY:
			# No ducking — durable volumes already applied in _apply_volumes().
			# Ensure ambience is not transient-muted (durable mute may still apply).
			AudioServer.set_bus_mute(_bus_index_ambience, audio_muted_categories.has("ambience"))
			pass

		GAME_STATE_MATCH_LIVE:
			# Duck BGM: multiply durable BGM volume by DUCK_BGM_VOLUME.
			if not audio_muted_categories.has("bgm"):
				var ducked_bgm_linear: float = clampf(audio_bgm_volume * DUCK_BGM_VOLUME, VOLUME_MIN, VOLUME_MAX)
				AudioServer.set_bus_volume_db(_bus_index_bgm, _linear_to_db(ducked_bgm_linear))
			# Transient mute ambience (match_whistle priority > ambience).
			AudioServer.set_bus_mute(_bus_index_ambience, true)

		GAME_STATE_POST_MATCH:
			# BGM restored (durable value already applied in _apply_volumes()).
			# Ambience stays muted transiently.
			AudioServer.set_bus_mute(_bus_index_ambience, true)


# ─────────────────────────────────────────────
# Internal helpers — Restore & Events
# ─────────────────────────────────────────────

## Emits the current authoritative audio settings snapshot through EventBus.
## This is a presentation-only event; consumers must not mutate gameplay truth in response.
func _emit_settings_changed() -> void:
	pass  # TODO: Wire EventBus emit in follow-up story


## Applies two-phase restored values after the node runtime is ready.
##
## Called from _ready() or immediately from deserialize() when the node is
## already inside the tree. Commits pending values to live fields, then
## invokes _apply_volumes().
func _apply_after_tree_ready() -> void:
	if _pending_restored_values == null:
		_apply_volumes()
		return
	if not (_pending_restored_values is Dictionary):
		_pending_restored_values = null
		_apply_volumes()
		return

	var pending: Dictionary = _pending_restored_values as Dictionary
	audio_master_volume = clampf(float(pending.get("audio_master_volume", DEFAULT_VOLUME)), VOLUME_MIN, VOLUME_MAX)
	audio_bgm_volume = clampf(float(pending.get("audio_bgm_volume", DEFAULT_VOLUME)), VOLUME_MIN, VOLUME_MAX)
	audio_sfx_volume = clampf(float(pending.get("audio_sfx_volume", DEFAULT_VOLUME)), VOLUME_MIN, VOLUME_MAX)
	audio_ambience_volume = clampf(float(pending.get("audio_ambience_volume", DEFAULT_VOLUME)), VOLUME_MIN, VOLUME_MAX)

	audio_muted_categories.clear()
	var categories: Array = pending.get("audio_muted_categories", []) as Array
	for category: Variant in categories:
		audio_muted_categories.append(String(category))

	_pending_restored_values = null
	_apply_volumes()
	_emit_settings_changed()
