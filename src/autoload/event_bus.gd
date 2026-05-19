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
	if not _subscribers.has(event_name):
		return
	var callbacks: Array = _subscribers[event_name]
	for callback in callbacks.duplicate():
		callback.call(event_name, payload)


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
