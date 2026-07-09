extends Node
## Minimal AudioManager autoload stub — authoritative runtime owner of audio preference state.
##
## This is a minimum Alpha foundation stub. It does not implement audio playback,
## bus mapping, BGM streaming, SFX pooling, mute categories, ambience volume,
## same-window suppression, or save/load persistence. Its only goal is to store
## three float volume fields in memory and emit an authoritative snapshot on
## request, so the Audio Settings UI has a stable runtime authority to consume.
##
## ADR-0013 defines AudioManager as a long-lived Node-based Autoload. This stub
## establishes the getter/setter contract and EventBus integration point.
## SaveManager registration and full persistence are deferred to follow-up stories.
##
## Usage:
##   var payload := AudioManager.build_audio_settings_payload()
##   AudioManager.set_master_volume(0.8)
##   AudioManager.set_bgm_volume(0.5)
##   AudioManager.set_sfx_volume(0.6)

const DEFAULT_VOLUME: float = 1.0
const VOLUME_MIN: float = 0.0
const VOLUME_MAX: float = 1.0

## Master volume (0.0–1.0). Default 1.0.
var audio_master_volume: float = DEFAULT_VOLUME
## BGM volume (0.0–1.0). Default 1.0.
var audio_bgm_volume: float = DEFAULT_VOLUME
## SFX volume (0.0–1.0). Default 1.0.
var audio_sfx_volume: float = DEFAULT_VOLUME


func _ready() -> void:
	name = "AudioManager"


## Returns a read-only dictionary snapshot of the current audio preference state.
## Keys: "audio_master_volume", "audio_bgm_volume", "audio_sfx_volume".
## Consumers must treat this payload as a snapshot and never mutate it.
func build_audio_settings_payload() -> Dictionary[String, Variant]:
	var payload: Dictionary[String, Variant] = {}
	payload["audio_master_volume"] = audio_master_volume
	payload["audio_bgm_volume"] = audio_bgm_volume
	payload["audio_sfx_volume"] = audio_sfx_volume
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


## Emits the current authoritative audio settings snapshot through EventBus.
## This is a presentation-only event; consumers must not mutate gameplay truth in response.
func _emit_settings_changed() -> void:
	EventBus.emit("audio_settings_changed", build_audio_settings_payload())
