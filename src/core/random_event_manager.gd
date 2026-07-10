## class_name RandomEventManager
extends Node
## Story 001–002 implementation for design/gdd/random-event-system.md.
##
## Owns the four random-event durable-truth fields:
##   pending_random_event_instance, recent_random_event_history,
##   event_cooldown_state, processed_event_settlement_keys.
##
## Governed by ADR-0012 (Random Event Settlement Contracts).
## Implements TR-randomevent-001 through TR-randomevent-006.
##
## This node is scene-instantiated (class_name), NOT an Autoload.
## It exports serialize/deserialize for SaveManager registration and
## provides the stable settlement-key generator for idempotency.
##
## Story 002 adds EventBus subscription to time_phase_changed, stable-window
## trigger evaluation, cooldown checks, and read-only view payloads for UI.

## Current pending random event instance, or empty dict when none is active.
var pending_random_event_instance: Variant = {}

## Recent confirmed-event history entries, ordered oldest-first.
var recent_random_event_history: Array = []  ## Array of Dictionary[String, Variant] entries

## Cooldown state keyed by category string, mapping to cooldown-expiry timestamp.
var event_cooldown_state: Variant = {}

## Set of already-processed settlement keys for idempotency.
var processed_event_settlement_keys: Variant = []

## Story 002 — Stable windows where random events may be evaluated.
## Per ADR-0012 Decision #2, these are the TimeManager states that mark
## legitimate settlement boundaries. Transient states (Match Trigger,
## Match In Progress, Action Resolution, SeasonStart) are excluded.
const VALID_TRIGGER_STATES: Array[String] = [
	"Planning",
	"Post-Match Settlement",
	"Stage Settlement",
	"Season Settlement",
	"Offseason",
]

## Test-only override — skips get_node_or_null for headless test environments.
var _event_bus_override: Node = null

## Tracks the last timeline position where evaluation ran, to avoid
## redundant checks within the same stable window.
var _last_evaluated_timeline_position: int = -1


# ─────────────────────────────────────────────
# Lifecycle — EventBus subscription
# ─────────────────────────────────────────────

func _ready() -> void:
	var event_bus: Node = _event_bus()
	if event_bus != null:
		event_bus.subscribe("time_phase_changed", _on_time_phase_changed)


func _exit_tree() -> void:
	var event_bus: Node = _event_bus()
	if event_bus != null:
		event_bus.unsubscribe("time_phase_changed", _on_time_phase_changed)


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


## Story 002 — Sets a test-only EventBus override so headless tests can
## inject a mock without depending on /root/EventBus existing.
func set_event_bus_for_testing(event_bus: Node) -> void:
	_event_bus_override = event_bus


## Story 002 — Returns a read-only Dictionary[String, Variant] view of the
## current pending_random_event_instance.
##
## Returns a shallow duplicate so callers cannot mutate internal state
## through the returned payload. Returns an empty dict when no pending
## event is active.
func get_offer_view_payload() -> Dictionary[String, Variant]:
	if pending_random_event_instance is Dictionary and not (pending_random_event_instance as Dictionary).is_empty():
		return _normalize_string_variant_dict(pending_random_event_instance)
	return {}


## Story 002 — Returns a read-only Array view
## of recent_random_event_history, ordered time-descending (newest first).
##
## Each entry is a shallow duplicate so callers cannot mutate internal
## history through the returned payload.
func get_history_view_payload() -> Array:
	var payload: Array = []
	for i: int in range(recent_random_event_history.size() - 1, -1, -1):
		var entry: Variant = recent_random_event_history[i]
		payload.append(_normalize_string_variant_dict(entry))
	return payload


# ─────────────────────────────────────────────
# Story 002 — Event evaluation & trigger
# ─────────────────────────────────────────────

## Callback subscribed to EventBus "time_phase_changed".
## Delegates to _evaluate_event_trigger with the canonical payload.
func _on_time_phase_changed(event_name: String, payload: Dictionary) -> void:
	_evaluate_event_trigger(payload)


## Evaluates whether a random event should be triggered at the current
## stable window boundary.
##
## Conditions (all must be met):
##   1. new_phase is one of the VALID_TRIGGER_STATES
##   2. No pending event is already active
##   3. No active cooldown blocks this window
##   4. This timeline position has not already been evaluated (deduplication)
##
## When conditions are met, sets pending_random_event_instance to a stub
## dictionary. This is a Story 002 stub — actual event pool selection,
## category assignment, and option generation are Beta story scope.
##
## [param payload] The time_phase_changed event payload from TimeManager.
func _evaluate_event_trigger(payload: Dictionary) -> void:
	# Condition 1 — verify the new phase is a valid stable window
	var new_phase: String = String(payload.get("new_phase", ""))
	if new_phase not in VALID_TRIGGER_STATES:
		return

	# Condition 2 — don't overwrite an existing pending event
	if pending_random_event_instance is Dictionary and not (pending_random_event_instance as Dictionary).is_empty():
		return

	# Condition 3 — check cooldown state
	var timeline_position: int = int(payload.get("timeline_position", 0))
	if _is_cooldown_active(timeline_position):
		return

	# Condition 4 — deduplicate by timeline position within the same window
	if _last_evaluated_timeline_position == timeline_position:
		return
	_last_evaluated_timeline_position = timeline_position

	# All conditions met — generate stub pending event instance
	# Actual event pool selection and option generation are Beta story scope.
	var season_number: int = int(payload.get("season_number", 1))
	var current_stage: int = int(payload.get("current_stage", 1))
	pending_random_event_instance = {
		"event_id": "stub_window_event",
		"event_instance_id": "stub_%d_%d_%d" % [season_number, current_stage, timeline_position],
		"trigger_window": new_phase,
		"timeline_position": timeline_position,
		"season_number": season_number,
		"current_stage": current_stage,
	}


## Returns true if any cooldown entry has not yet expired relative to
## [param game_time] (the current timeline_position).
##
## Each cooldown value is interpreted as the expiry timestamp; if the
## current game_time is less than the stored value, the cooldown is active.
func _is_cooldown_active(game_time: int) -> bool:
	if not (event_cooldown_state is Dictionary):
		return false
	var cooldown_dict: Dictionary = event_cooldown_state as Dictionary
	for category: Variant in cooldown_dict.keys():
		var cooldown_expiry: int = int(cooldown_dict[category])
		if game_time < cooldown_expiry:
			return true
	return false


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


# ─────────────────────────────────────────────
# EventBus accessor — respects test override
# ─────────────────────────────────────────────

## Returns the live EventBus node, or the test-injected override.
func _event_bus() -> Node:
	if _event_bus_override != null:
		return _event_bus_override
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/EventBus")
