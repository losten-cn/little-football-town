extends Node
## Global event bus for cross-system communication.
## All 13 systems publish and subscribe through this singleton.
## See ADR-0002 for architecture details.
##
## Usage:
##   EventBus.subscribe("funds_changed", _on_funds_changed)
##   EventBus.emit("funds_changed", {"current": 500, "delta": -30})
##   EventBus.unsubscribe("funds_changed", _on_funds_changed)

## {event_name: Array[Callable]}
var _subscribers: Dictionary = {}
var _prioritized_event_queue: Array[Dictionary] = []
var _is_processing_prioritized_events: bool = false
var _next_prioritized_sequence: int = 0


## Subscribe a callback to an event.
## Duplicate subscriptions for the same callback are silently ignored.
func subscribe(event_name: String, callback: Callable) -> void:
	if not _subscribers.has(event_name):
		_subscribers[event_name] = []
	var callbacks: Array = _subscribers[event_name]
	if callback not in callbacks:
		callbacks.push_back(callback)


## Unsubscribe a callback from an event.
## If the callback is not subscribed, this is a no-op.
## If no subscribers remain, the event key is removed to avoid dictionary bloat.
func unsubscribe(event_name: String, callback: Callable) -> void:
	if not _subscribers.has(event_name):
		return
	var callbacks: Array = _subscribers[event_name]
	callbacks.erase(callback)
	if callbacks.is_empty():
		_subscribers.erase(event_name)


## Emit an event with an optional payload Dictionary.
## All subscribed callbacks are invoked with (event_name: String, payload: Dictionary).
## Callbacks are called in subscription order. Iterates a copy of the subscriber
## list so callbacks can safely unsubscribe themselves during emission.
func emit(event_name: String, payload: Dictionary = {}) -> void:
	if _is_processing_prioritized_events:
		_queue_prioritized_event(event_name, _to_typed_dictionary(payload))
		return
	_emit_immediately(event_name, payload)


## Emits a batch of events using the fixed project priority chain.
func emit_prioritized(events: Array) -> void:
	for event_variant: Variant in events:
		if not (event_variant is Dictionary):
			continue
		var event: Dictionary = event_variant
		var event_name: String = String(event.get("event_name", ""))
		if event_name.is_empty():
			continue
		var payload: Dictionary = _to_typed_dictionary(event.get("payload", {}))
		_queue_prioritized_event(event_name, payload)

	if _is_processing_prioritized_events:
		return

	_is_processing_prioritized_events = true
	while not _prioritized_event_queue.is_empty():
		_prioritized_event_queue.sort_custom(_compare_prioritized_events)
		var next_event: Dictionary = _prioritized_event_queue.pop_front()
		_emit_immediately(String(next_event["event_name"]), next_event["payload"] as Dictionary)
	_is_processing_prioritized_events = false


## Returns true if the event has at least one subscriber.
func has_subscribers(event_name: String) -> bool:
	return _subscribers.has(event_name) and not _subscribers[event_name].is_empty()


## Returns the number of subscribers for an event.
func subscriber_count(event_name: String) -> int:
	if not _subscribers.has(event_name):
		return 0
	return _subscribers[event_name].size()


## Remove all subscribers for all events.
## Useful during scene transitions or full game resets.
func clear_all() -> void:
	_subscribers.clear()
	_prioritized_event_queue.clear()
	_is_processing_prioritized_events = false


func _emit_immediately(event_name: String, payload: Dictionary) -> void:
	if not _subscribers.has(event_name):
		return
	var callbacks: Array = _subscribers[event_name]
	for callback in callbacks.duplicate():
		callback.call(event_name, payload)


func _queue_prioritized_event(event_name: String, payload: Dictionary) -> void:
	_prioritized_event_queue.append({
		"event_name": event_name,
		"payload": payload,
		"priority": _get_event_priority(event_name),
		"sequence": _next_prioritized_sequence,
	})
	_next_prioritized_sequence += 1


func _compare_prioritized_events(left: Dictionary, right: Dictionary) -> bool:
	var left_priority: int = int(left["priority"])
	var right_priority: int = int(right["priority"])
	if left_priority != right_priority:
		return left_priority < right_priority
	return int(left["sequence"]) < int(right["sequence"])


func _get_event_priority(event_name: String) -> int:
	if event_name == "time_match_triggered":
		return 0
	if event_name == "time_stage_settled":
		return 1
	if event_name == "time_season_ended":
		return 2
	if event_name == "match_completed":
		return 3
	if event_name.begins_with("league_"):
		return 4
	if event_name.begins_with("economy_"):
		return 5
	if event_name.begins_with("player_"):
		return 6
	if event_name.begins_with("town_"):
		return 7
	if event_name.begins_with("save_"):
		return 8
	if event_name.begins_with("time_"):
		return 9
	return 10


func _to_typed_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary

	for key_variant: Variant in value:
		typed_dictionary[String(key_variant)] = value[key_variant]
	return typed_dictionary
