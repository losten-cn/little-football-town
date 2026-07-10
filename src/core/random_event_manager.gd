## class_name RandomEventManager
extends Node
## Story 001 Authority stub for design/gdd/random-event-system.md.
##
## Owns the four random-event durable-truth fields:
##   pending_random_event_instance, recent_random_event_history,
##   event_cooldown_state, processed_event_settlement_keys.
##
## Governed by ADR-0012 (Random Event Settlement Contracts).
## Implements TR-randomevent-001, TR-randomevent-004, TR-randomevent-005.
##
## This node is scene-instantiated (class_name), NOT an Autoload.
## It exports serialize/deserialize for SaveManager registration and
## provides the stable settlement-key generator for idempotency.

## Current pending random event instance, or empty dict when none is active.
var pending_random_event_instance: Variant = {}

## Recent confirmed-event history entries, ordered oldest-first.
var recent_random_event_history: Array = []  ## Array of Dictionary[String, Variant] entries

## Cooldown state keyed by category string, mapping to cooldown-expiry timestamp.
var event_cooldown_state: Variant = {}

## Set of already-processed settlement keys for idempotency.
var processed_event_settlement_keys: Variant = []


# ─────────────────────────────────────────────
# Public API — ADR-0012 Key Interfaces
# ─────────────────────────────────────────────

## Builds a stable, deterministic idempotency key from canonical scalar fields.
##
## The key is constructed as:
##   md5_text("|".join([event_instance_id, selected_option_id, target_scope, target_id]))
##
## [param event_instance_id] Stable event-instance identifier (non-empty).
## [param selected_option_id] Player-chosen or auto-settled option id (non-empty).
## [param target_scope] Target scope enum-string (e.g. "player", "economy").
## [param target_id] Target object id, or an empty string for no single target.
## [returns] Deterministic hex-digest settlement key.
##
## [b]rule_version is intentionally excluded[/b] from the key source per
## ADR-0012 Decision #4. A rule-version change alone must never produce a
## new settlement identity or force replay of an already-settled outcome.
func build_event_settlement_key(event_instance_id: String, selected_option_id: String, target_scope: String, target_id: String) -> String:
	var canonical_join: String = "|".join([event_instance_id, selected_option_id, target_scope, target_id])
	return canonical_join.md5_text()


## Returns a read-only snapshot of serializable durable event state.
func serialize() -> Dictionary[String, Variant]:
	return {
		"pending_random_event_instance": pending_random_event_instance.duplicate(true),
		"recent_random_event_history": recent_random_event_history.duplicate(true),
		"event_cooldown_state": event_cooldown_state.duplicate(true),
		"processed_event_settlement_keys": processed_event_settlement_keys.duplicate(true),
	}


## Restores durable event state from serialized save data.
func deserialize(data: Dictionary[String, Variant]) -> void:
	pending_random_event_instance = _normalize_string_variant_dict(data.get("pending_random_event_instance", {}))
	recent_random_event_history.clear()
	for entry: Variant in data.get("recent_random_event_history", []) as Array:
		recent_random_event_history.append(_normalize_string_variant_dict(entry))
	event_cooldown_state = _normalize_string_variant_dict(data.get("event_cooldown_state", {}))
	processed_event_settlement_keys.clear()
	for key_value: Variant in data.get("processed_event_settlement_keys", []) as Array:
		processed_event_settlement_keys.append(String(key_value))


## Registers this system with SaveManager using the random-event persistence contract.
func register_with_save_manager(save_manager: Node) -> bool:
	if save_manager == null:
		return false
	return save_manager.register_system("random_event", Callable(self, "serialize"), Callable(self, "deserialize"))


# ─────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────

## Returns true when [param key] has already been processed (idempotency guard).
func _is_settled(key: String) -> bool:
	return key in processed_event_settlement_keys


## Normalizes an untyped runtime container into a typed [Dictionary[String, Variant]].
func _normalize_string_variant_dict(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary
