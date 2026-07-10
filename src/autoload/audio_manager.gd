extends Node
## AudioManager autoload — authoritative runtime owner of audio preference state.
##
## Owns five durable-preference fields:
##   audio_master_volume, audio_bgm_volume, audio_sfx_volume,
##   audio_ambience_volume, audio_muted_categories.
##
## Governed by ADR-0013 (Audio Settings & Event Consumption).
## Implements TR-audio-001, TR-audio-004.
## Story: S7-04 (AudioManager Authority Stub).
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

const DEFAULT_VOLUME: float = 1.0
const VOLUME_MIN: float = 0.0
const VOLUME_MAX: float = 1.0

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


# ─────────────────────────────────────────────
# Lifecycle
# ─────────────────────────────────────────────

func _ready() -> void:
	name = "AudioManager"
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
func set_master_volume(value: float) -> void:
	audio_master_volume = clampf(value, VOLUME_MIN, VOLUME_MAX)
	_emit_settings_changed()


## Sets the BGM volume. Clamped to [0.0, 1.0]. Emits audio_settings_changed on EventBus.
func set_bgm_volume(value: float) -> void:
	audio_bgm_volume = clampf(value, VOLUME_MIN, VOLUME_MAX)
	_emit_settings_changed()


## Sets the SFX volume. Clamped to [0.0, 1.0]. Emits audio_settings_changed on EventBus.
func set_sfx_volume(value: float) -> void:
	audio_sfx_volume = clampf(value, VOLUME_MIN, VOLUME_MAX)
	_emit_settings_changed()


## Sets the ambience volume. Clamped to [0.0, 1.0]. Emits audio_settings_changed on EventBus.
func set_ambience_volume(value: float) -> void:
	audio_ambience_volume = clampf(value, VOLUME_MIN, VOLUME_MAX)
	_emit_settings_changed()


## Toggles a category's muted state.
## [param category] Category name to mute or unmute.
## [param muted] True to mute, false to unmute.
func set_category_muted(category: String, muted: bool) -> void:
	if muted and not audio_muted_categories.has(category):
		audio_muted_categories.append(category)
	elif not muted and audio_muted_categories.has(category):
		audio_muted_categories.erase(category)
	_emit_settings_changed()


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
# Internal helpers
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
		return
	if not (_pending_restored_values is Dictionary):
		_pending_restored_values = null
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


## Empty stub — no AudioServer calls yet.
##
## Will be filled in Story 002+ when audio bus mapping and
## AudioStreamPlayer pooling are implemented.
func _apply_volumes() -> void:
	pass
