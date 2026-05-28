extends Node
## Minimal save/load orchestrator for registered Core systems.
## Story 001 scope: register serialize/deserialize contracts and snapshot them deterministically.

const DESERIALIZE_ORDER: Array[String] = [
	"time",
	"town",
	"player",
	"league",
	"economy",
	"match",
]

var _serialize_callbacks: Dictionary[String, Callable] = {}
var _deserialize_callbacks: Dictionary[String, Callable] = {}


## Registers a Core system save contract.
func register_system(system_name: String, serialize_callback: Callable, deserialize_callback: Callable) -> void:
	if system_name.is_empty():
		push_error("SaveManager: system_name must not be empty")
		return
	if not serialize_callback.is_valid():
		push_error("SaveManager: serialize callback is invalid for %s" % system_name)
		return
	if not deserialize_callback.is_valid():
		push_error("SaveManager: deserialize callback is invalid for %s" % system_name)
		return

	_serialize_callbacks[system_name] = serialize_callback
	_deserialize_callbacks[system_name] = deserialize_callback


## Unregisters a Core system save contract.
func unregister_system(system_name: String) -> void:
	_serialize_callbacks.erase(system_name)
	_deserialize_callbacks.erase(system_name)


## Returns whether a system save contract is registered.
func has_registered_system(system_name: String) -> bool:
	return _serialize_callbacks.has(system_name) and _deserialize_callbacks.has(system_name)


## Returns the registered system names.
func get_registered_system_names() -> Array[String]:
	var system_names: Array[String] = []
	for system_name_variant: Variant in _serialize_callbacks.keys():
		system_names.append(String(system_name_variant))
	system_names.sort()
	return system_names


## Serializes all registered systems into a typed snapshot dictionary.
func serialize_registered_systems() -> Dictionary[String, Variant]:
	var snapshot: Dictionary[String, Variant] = {}
	for system_name: String in get_registered_system_names():
		var serialize_callback: Callable = _serialize_callbacks[system_name]
		var serialized_variant: Variant = serialize_callback.call()
		if not (serialized_variant is Dictionary):
			push_error("SaveManager: serialized payload for %s must be a Dictionary" % system_name)
			continue
		var serialized_payload: Dictionary[String, Variant] = serialized_variant
		snapshot[system_name] = serialized_payload
	return snapshot


## Deserializes registered systems in manifest order, then any remaining registered systems.
func deserialize_registered_systems(snapshot: Dictionary[String, Variant]) -> void:
	for ordered_system_name: String in DESERIALIZE_ORDER:
		_deserialize_registered_system(snapshot, ordered_system_name)

	for system_name: String in get_registered_system_names():
		if DESERIALIZE_ORDER.has(system_name):
			continue
		_deserialize_registered_system(snapshot, system_name)


func _deserialize_registered_system(snapshot: Dictionary[String, Variant], system_name: String) -> void:
	if not _deserialize_callbacks.has(system_name):
		return
	if not snapshot.has(system_name):
		return

	var deserialize_callback: Callable = _deserialize_callbacks[system_name]
	deserialize_callback.call(snapshot[system_name])
