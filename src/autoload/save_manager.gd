extends Node
## Central save/load orchestrator.
## Coordinates save/load across all registered SaveableResource providers.
## See ADR-0003 for architecture details.

const SaveSnapshotScript: Script = preload("res://src/autoload/save_snapshot.gd")
const SAVE_DIRECTORY_PATH: String = "user://saves"
const SLOT_STATUS_EMPTY: String = "empty"
const SLOT_STATUS_VALID: String = "valid"
const SLOT_STATUS_INVALID: String = "invalid"
const SLOT_STATUS_CORRUPTED: String = "corrupted"
const CURRENT_SAVE_VERSION: int = 1
const TOTAL_REQUIRED_FIELDS: int = 12
const REQUIRED_SYSTEM_IDS: Array[String] = [
	"time",
	"town",
	"player",
	"league",
	"economy",
	"match",
]
const STABLE_SAVE_NODE_SET: Array[String] = [
	"Planning",
	"Match Trigger",
	"Post-Match Settlement",
	"Stage Settlement",
	"Season Settlement",
	"Offseason",
]

var last_errors: Array[String] = []
var _registered_systems: Dictionary[String, Variant] = {}
var _save_directory_path: String = SAVE_DIRECTORY_PATH
var _event_bus_override: Node = null
var _screen_manager_override: Node = null
var _pending_autosave_requested: bool = false
var _pending_autosave_reason: String = ""
var _pending_autosave_ui_state: Dictionary[String, Variant] = {}
var _pending_autosave_slot_metadata: Dictionary[String, Variant] = {}
var _pending_autosave_playtime_seconds: float = 0.0
var _pending_autosave_timestamp: int = 0


## Resolves a save slot id to its canonical snapshot path.
## Returns an empty string when the slot id is not one of the four legal Story 001 slots.
func resolve_slot_path(slot_id: String) -> String:
	match slot_id:
		"slot_1":
			return "%s/slot_1.tres" % _save_directory_path
		"slot_2":
			return "%s/slot_2.tres" % _save_directory_path
		"slot_3":
			return "%s/slot_3.tres" % _save_directory_path
		"autosave":
			return "%s/autosave.tres" % _save_directory_path
		_:
			return ""


func set_save_directory_path(save_directory_path: String) -> void:
	_save_directory_path = SAVE_DIRECTORY_PATH if save_directory_path.is_empty() else save_directory_path


func _ready() -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus != null:
		event_bus.call("subscribe", "match_completed", Callable(self, "_on_autosave_event"))
		event_bus.call("subscribe", "time_season_ended", Callable(self, "_on_autosave_event"))
		event_bus.call("subscribe", "town_facility_completed", Callable(self, "_on_autosave_event"))
		event_bus.call("subscribe", "time_phase_changed", Callable(self, "_on_time_phase_changed"))


func _exit_tree() -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus != null:
		event_bus.call("unsubscribe", "match_completed", Callable(self, "_on_autosave_event"))
		event_bus.call("unsubscribe", "time_season_ended", Callable(self, "_on_autosave_event"))
		event_bus.call("unsubscribe", "town_facility_completed", Callable(self, "_on_autosave_event"))
		event_bus.call("unsubscribe", "time_phase_changed", Callable(self, "_on_time_phase_changed"))


## Overrides the EventBus dependency for tests.
func set_event_bus_for_testing(event_bus: Node) -> void:
	_event_bus_override = event_bus


## Overrides the ScreenManager dependency for tests.
func set_screen_manager_for_testing(screen_manager: Node) -> void:
	_screen_manager_override = screen_manager


## Registers a system-specific serialize/deserialize contract.
func register_system(system_id: String, serialize_callable: Callable, deserialize_callable: Callable) -> bool:
	if system_id.is_empty() or not serialize_callable.is_valid() or not deserialize_callable.is_valid():
		return false
	_registered_systems[system_id] = {
		"serialize": serialize_callable,
		"deserialize": deserialize_callable,
	}
	return true


## Returns whether a named system has registered save contracts.
func has_registered_system(system_id: String) -> bool:
	return _registered_systems.has(system_id)


## Serializes one registered system by id.
func serialize_registered_system(system_id: String) -> Dictionary[String, Variant]:
	var serialized_state: Dictionary[String, Variant] = {}
	if not _registered_systems.has(system_id):
		return serialized_state
	var serialize_callable: Callable = _registered_systems[system_id].get("serialize", Callable()) as Callable
	if not serialize_callable.is_valid():
		return serialized_state
	var result: Variant = serialize_callable.call()
	if not result is Dictionary:
		return serialized_state
	for key: Variant in (result as Dictionary).keys():
		serialized_state[String(key)] = (result as Dictionary)[key]
	return serialized_state.duplicate(true)


## Deserializes one registered system by id.
func deserialize_registered_system(system_id: String, data: Dictionary[String, Variant]) -> bool:
	if not _registered_systems.has(system_id):
		return false
	var deserialize_callable: Callable = _registered_systems[system_id].get("deserialize", Callable()) as Callable
	if not deserialize_callable.is_valid():
		return false
	var result: Variant = deserialize_callable.call(data.duplicate(true))
	if result is bool:
		return result as bool
	return true


## Loads a snapshot from a legal slot and restores registered systems in dependency order.
func load_snapshot_from_slot(slot_id: String) -> Dictionary[String, Variant]:
	last_errors.clear()

	var path: String = resolve_slot_path(slot_id)
	if path.is_empty():
		last_errors = ["illegal slot id: %s" % slot_id]
		return _build_recovery_result(false, slot_id, null, [], "", last_errors.duplicate(), "missing", "show_recovery", false)
	if not FileAccess.file_exists(path):
		last_errors = ["snapshot slot is empty: %s" % slot_id]
		return _build_recovery_result(false, slot_id, null, [], "", last_errors.duplicate(), "missing", "show_recovery", false)

	var slot_result: Dictionary[String, Variant] = inspect_slot(slot_id)
	var slot_status: String = String(slot_result.get("status", ""))
	if slot_status == SLOT_STATUS_EMPTY:
		return _build_recovery_result(false, slot_id, null, [], "", ["snapshot slot is empty: %s" % slot_id], "missing", "show_recovery", false)
	if slot_status == SLOT_STATUS_CORRUPTED:
		return _build_recovery_result(false, slot_id, null, [], "", (slot_result.get("errors", []) as Array[String]).duplicate(), "corrupted", "show_recovery", false)
	if slot_status == SLOT_STATUS_INVALID:
		return _build_recovery_result(false, slot_id, null, [], "", (slot_result.get("errors", []) as Array[String]).duplicate(), "corrupted", "show_recovery", false)

	var loaded_resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded_resource == null or loaded_resource.get_script() != SaveSnapshotScript:
		last_errors = ["snapshot file could not be restored"]
		return _build_recovery_result(false, slot_id, null, [], "", last_errors.duplicate(), "corrupted", "show_recovery", false)

	var restore_result: Dictionary[String, Variant] = restore_snapshot(loaded_resource as SaveSnapshot)
	restore_result["slot_id"] = slot_id
	return restore_result


## Restores one snapshot after migration and compatibility validation.
func restore_snapshot(snapshot: SaveSnapshot) -> Dictionary[String, Variant]:
	var migration_result: Dictionary[String, Variant] = migrate_snapshot_if_needed(snapshot)
	if not (migration_result.get("success", false) as bool):
		var migration_errors: Array[String] = (migration_result.get("errors", []) as Array[String]).duplicate()
		var failure_reason: String = _classify_recovery_reason(snapshot, migration_errors)
		return _build_recovery_result(false, "", migration_result.get("snapshot", snapshot), [], "migration", migration_errors, failure_reason, "show_recovery", false)

	var migrated_snapshot: SaveSnapshot = migration_result.get("snapshot", null) as SaveSnapshot
	if migrated_snapshot == null:
		last_errors = ["snapshot is null"]
		return _build_recovery_result(false, "", null, [], "migration", last_errors.duplicate(), "corrupted", "show_recovery", false)
	if bool(migrated_snapshot.match_state.get("in_progress", false)):
		last_errors = ["match-in-progress snapshots cannot restore as stable authority state"]
		return _build_recovery_result(false, "", migrated_snapshot, [], "match", last_errors.duplicate(), "match_in_progress", "show_recovery", false)

	var restored_systems: Array[String] = []
	for system_id: String in REQUIRED_SYSTEM_IDS:
		var system_state: Dictionary[String, Variant] = _get_snapshot_system_state(migrated_snapshot, system_id)
		if not deserialize_registered_system(system_id, system_state):
			last_errors = ["failed to restore system: %s" % system_id]
			return _build_recovery_result(false, "", migrated_snapshot, restored_systems, system_id, last_errors.duplicate(), "restore_failed", "show_recovery", false)
		restored_systems.append(system_id)

	last_errors.clear()
	return _build_recovery_result(true, "", migrated_snapshot, restored_systems, "", [], "", "", false)


## Evaluates whether writing over a slot requires explicit player confirmation.
func evaluate_overwrite_risk(slot_id: String) -> Dictionary[String, Variant]:
	var slot_result: Dictionary[String, Variant] = inspect_slot(slot_id)
	var slot_status: String = String(slot_result.get("status", ""))
	if slot_status == SLOT_STATUS_EMPTY:
		return {
			"success": true,
			"slot_id": slot_id,
			"requires_confirmation": false,
			"recovery_reason": "",
			"recovery_action": "",
			"errors": [],
		}
	return {
		"success": false,
		"slot_id": slot_id,
		"requires_confirmation": true,
		"recovery_reason": "overwrite_requires_confirmation",
		"recovery_action": "confirm_overwrite",
		"errors": [],
	}


## Evaluates whether deleting a slot requires explicit player confirmation.
func evaluate_delete_risk(slot_id: String) -> Dictionary[String, Variant]:
	var slot_result: Dictionary[String, Variant] = inspect_slot(slot_id)
	var slot_status: String = String(slot_result.get("status", ""))
	if slot_status == SLOT_STATUS_EMPTY:
		return {
			"success": true,
			"slot_id": slot_id,
			"requires_confirmation": false,
			"recovery_reason": "",
			"recovery_action": "",
			"errors": [],
		}
	return {
		"success": false,
		"slot_id": slot_id,
		"requires_confirmation": true,
		"recovery_reason": "delete_requires_confirmation",
		"recovery_action": "confirm_delete",
		"errors": [],
	}


## Deletes a slot only after explicit confirmation.
func delete_slot(slot_id: String, confirmed: bool = false) -> Dictionary[String, Variant]:
	var path: String = resolve_slot_path(slot_id)
	if path.is_empty():
		last_errors = ["illegal slot id: %s" % slot_id]
		return {
			"success": false,
			"slot_id": slot_id,
			"deleted": false,
			"requires_confirmation": false,
			"recovery_reason": "missing",
			"recovery_action": "show_recovery",
			"errors": last_errors.duplicate(),
		}
	if not confirmed:
		return {
			"success": false,
			"slot_id": slot_id,
			"deleted": false,
			"requires_confirmation": true,
			"recovery_reason": "delete_requires_confirmation",
			"recovery_action": "confirm_delete",
			"errors": [],
		}
	if not FileAccess.file_exists(path):
		return {
			"success": true,
			"slot_id": slot_id,
			"deleted": false,
			"requires_confirmation": false,
			"recovery_reason": "",
			"recovery_action": "",
			"errors": [],
		}
	var directory: DirAccess = DirAccess.open(ProjectSettings.globalize_path(path.get_base_dir()))
	if directory == null:
		last_errors = ["failed to open slot directory for delete"]
		return {
			"success": false,
			"slot_id": slot_id,
			"deleted": false,
			"requires_confirmation": false,
			"recovery_reason": "delete_failed",
			"recovery_action": "show_recovery",
			"errors": last_errors.duplicate(),
		}
	var remove_error: int = directory.remove(path.get_file())
	if remove_error != OK:
		last_errors = ["failed to delete snapshot at %s (error %d)" % [path, remove_error]]
		return {
			"success": false,
			"slot_id": slot_id,
			"deleted": false,
			"requires_confirmation": false,
			"recovery_reason": "delete_failed",
			"recovery_action": "show_recovery",
			"errors": last_errors.duplicate(),
		}
	last_errors.clear()
	return {
		"success": true,
		"slot_id": slot_id,
		"deleted": true,
		"requires_confirmation": false,
		"recovery_reason": "",
		"recovery_action": "",
		"errors": [],
	}


## Returns structured save summary metadata for one slot.
func get_save_metadata(slot_id: String) -> Dictionary[String, Variant]:
	var slot_result: Dictionary[String, Variant] = inspect_slot(slot_id)
	var status: String = String(slot_result.get("status", SLOT_STATUS_EMPTY))
	if status != SLOT_STATUS_VALID:
		return {
			"slot_id": slot_id,
			"status": status,
			"save_label": "",
			"timestamp": 0,
			"playtime_seconds": 0.0,
			"season_phase": "",
			"key_resources": {},
			"recent_stable_node_type": "",
			"save_summary_progress_ratio": 0.0,
			"errors": (slot_result.get("errors", []) as Array[String]).duplicate(),
		}

	var path: String = String(slot_result.get("path", ""))
	var loaded_snapshot: SaveSnapshot = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveSnapshot
	if loaded_snapshot == null:
		return {
			"slot_id": slot_id,
			"status": SLOT_STATUS_CORRUPTED,
			"save_label": "",
			"timestamp": 0,
			"playtime_seconds": 0.0,
			"season_phase": "",
			"key_resources": {},
			"recent_stable_node_type": "",
			"save_summary_progress_ratio": 0.0,
			"errors": ["snapshot file could not be summarized"],
		}

	var time_state: Dictionary[String, Variant] = loaded_snapshot.time_state
	var town_state: Dictionary[String, Variant] = loaded_snapshot.town_state
	var economy_state: Dictionary[String, Variant] = loaded_snapshot.economy_state
	var completed_progress_units: int = int(time_state.get("timeline_position", 0))
	var total_progress_units: int = int(loaded_snapshot.snapshot_metadata.get("total_progress_units", completed_progress_units))
	var progress_ratio: float = float(completed_progress_units) / float(maxi(1, total_progress_units))
	return {
		"slot_id": slot_id,
		"status": status,
		"save_label": String(loaded_snapshot.snapshot_metadata.get("save_label", loaded_snapshot.snapshot_metadata.get("town_name", slot_id))),
		"timestamp": loaded_snapshot.timestamp,
		"playtime_seconds": loaded_snapshot.playtime_seconds,
		"season_phase": String(time_state.get("phase", "")),
		"key_resources": {
			"funds": economy_state.get("funds", 0),
			"facility_count": town_state.get("facility_count", 0),
		},
		"recent_stable_node_type": String(time_state.get("current_state", "")),
		"save_summary_progress_ratio": progress_ratio,
		"errors": [],
		}


## Returns structured save summary metadata for all legal slots.
func list_save_slot_metadata() -> Array:
	var slot_ids: Array[String] = ["slot_1", "slot_2", "slot_3", "autosave"]
	var summaries: Array[Dictionary] = []
	for slot_id: String in slot_ids:
		summaries.append(get_save_metadata(slot_id))
	return summaries


## Returns the required system ids that must participate in a full snapshot assembly.
func get_required_system_ids() -> Array[String]:
	return REQUIRED_SYSTEM_IDS.duplicate()


## Returns the stable runtime nodes that may be used as recoverable save points.
func get_stable_save_node_set() -> Array[String]:
	return STABLE_SAVE_NODE_SET.duplicate()


## Returns whether the provided runtime node is a recoverable stable save point.
func is_recoverable_stable_node(current_runtime_node: String) -> bool:
	return STABLE_SAVE_NODE_SET.has(current_runtime_node)


## Returns the current supported save schema version.
func get_current_save_version() -> int:
	return CURRENT_SAVE_VERSION


## Migrates a snapshot forward when needed and validates compatibility.
func migrate_snapshot_if_needed(snapshot: SaveSnapshot) -> Dictionary[String, Variant]:
	if snapshot == null:
		last_errors = ["snapshot is null"]
		return {"success": false, "migrated": false, "snapshot": null, "errors": last_errors.duplicate()}

	if snapshot.save_version > get_current_save_version():
		last_errors = ["save version %d is newer than supported version %d" % [snapshot.save_version, get_current_save_version()]]
		return {"success": false, "migrated": false, "snapshot": snapshot, "errors": last_errors.duplicate()}

	var migrated_snapshot: SaveSnapshot = snapshot if snapshot.save_version == get_current_save_version() else snapshot.duplicate(true) as SaveSnapshot
	var migrated: bool = false
	if migrated_snapshot.save_version < get_current_save_version():
		var migration_result: Dictionary[String, Variant] = _migrate_snapshot_forward(migrated_snapshot, migrated_snapshot.save_version, get_current_save_version())
		if not (migration_result.get("success", false) as bool):
			last_errors = (migration_result.get("errors", []) as Array[String]).duplicate()
			return migration_result
		migrated = true
		migrated_snapshot.snapshot_metadata["integrity_hash"] = _compute_snapshot_integrity_hash(migrated_snapshot)

	var validation: Dictionary[String, Variant] = validate_snapshot(migrated_snapshot)
	var consistency: Dictionary[String, Variant] = _evaluate_cross_system_consistency(migrated_snapshot)
	var errors: Array[String] = (validation["errors"] as Array[String]).duplicate()
	errors.append_array((consistency["errors"] as Array[String]).duplicate())
	if not _verify_snapshot_integrity(migrated_snapshot):
		errors.append("snapshot integrity hash mismatch")
	var success: bool = (validation["is_valid"] as bool) and is_equal_approx(consistency["cross_system_consistency_ratio"] as float, 1.0) and errors.is_empty()
	last_errors = errors.duplicate()
	return {
		"success": success,
		"migrated": migrated,
		"snapshot": migrated_snapshot,
		"errors": errors,
	}


## Evaluates whether the current time-state snapshot may proceed to save.
func evaluate_save_gate(time_state: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var current_runtime_node: String = String(time_state.get("current_state", ""))
	if current_runtime_node.is_empty():
		last_errors = ["current runtime node is missing"]
		return {
			"success": false,
			"recoverable_stable_node": false,
			"current_runtime_node": current_runtime_node,
			"errors": last_errors.duplicate(),
		}
	if not is_recoverable_stable_node(current_runtime_node):
		last_errors = ["save blocked at unstable runtime node: %s" % current_runtime_node]
		return {
			"success": false,
			"recoverable_stable_node": false,
			"current_runtime_node": current_runtime_node,
			"errors": last_errors.duplicate(),
		}
	last_errors.clear()
	return {
		"success": true,
		"recoverable_stable_node": true,
		"current_runtime_node": current_runtime_node,
		"errors": [],
	}


func request_autosave(reason: String, ui_state: Dictionary[String, Variant] = {}, slot_metadata: Dictionary[String, Variant] = {}, playtime_seconds: float = 0.0, timestamp: int = 0) -> Dictionary[String, Variant]:
	var resolved_ui_state: Dictionary[String, Variant] = _to_string_variant_dictionary(ui_state)
	if resolved_ui_state.is_empty():
		resolved_ui_state = _resolve_autosave_ui_state()
	var time_state: Dictionary[String, Variant] = serialize_registered_system("time")
	var save_gate: Dictionary[String, Variant] = evaluate_save_gate(time_state)
	if not (save_gate.get("success", false) as bool):
		_capture_autosave_request(reason, resolved_ui_state, slot_metadata, playtime_seconds, timestamp)
		return {
			"success": false,
			"deferred": true,
			"slot_id": "autosave",
			"reason": reason,
			"errors": (save_gate.get("errors", []) as Array).duplicate(),
		}

	var commit_result: Dictionary[String, Variant] = commit_registered_snapshot("autosave", resolved_ui_state, slot_metadata, playtime_seconds, timestamp)
	commit_result["deferred"] = false
	commit_result["slot_id"] = "autosave"
	commit_result["reason"] = reason
	return commit_result


func handle_close_request_autosave(ui_state: Dictionary[String, Variant] = {}, slot_metadata: Dictionary[String, Variant] = {}, playtime_seconds: float = 0.0, timestamp: int = 0) -> Dictionary[String, Variant]:
	return request_autosave("WM_CLOSE_REQUEST", ui_state, slot_metadata, playtime_seconds, timestamp)


func flush_pending_autosave() -> Dictionary[String, Variant]:
	if not _pending_autosave_requested:
		return {
			"success": true,
			"deferred": false,
			"slot_id": "autosave",
			"reason": "",
			"flushed": false,
		}
	var pending_reason: String = _pending_autosave_reason
	var pending_ui_state: Dictionary[String, Variant] = _to_string_variant_dictionary(_pending_autosave_ui_state)
	var pending_slot_metadata: Dictionary[String, Variant] = _to_string_variant_dictionary(_pending_autosave_slot_metadata)
	var pending_playtime_seconds: float = _pending_autosave_playtime_seconds
	var pending_timestamp: int = _pending_autosave_timestamp
	var time_state: Dictionary[String, Variant] = serialize_registered_system("time")
	var save_gate: Dictionary[String, Variant] = evaluate_save_gate(time_state)
	if not (save_gate.get("success", false) as bool):
		return {
			"success": false,
			"deferred": true,
			"slot_id": "autosave",
			"reason": pending_reason,
			"flushed": false,
			"errors": (save_gate.get("errors", []) as Array).duplicate(),
		}
	_pending_autosave_requested = false
	_pending_autosave_reason = ""
	_pending_autosave_ui_state = {}
	_pending_autosave_slot_metadata = {}
	_pending_autosave_playtime_seconds = 0.0
	_pending_autosave_timestamp = 0
	var result: Dictionary[String, Variant] = request_autosave(pending_reason, pending_ui_state, pending_slot_metadata, pending_playtime_seconds, pending_timestamp)
	result["flushed"] = true
	return result


## Assembles one atomic SaveSnapshot from all required registered systems.
## Returns structured assembly details and does not write to disk.
func assemble_snapshot(ui_state: Dictionary[String, Variant], slot_metadata: Dictionary[String, Variant] = {}, playtime_seconds: float = 0.0, timestamp: int = 0) -> Dictionary[String, Variant]:
	last_errors.clear()

	var missing_systems: Array[String] = []
	for system_id: String in REQUIRED_SYSTEM_IDS:
		if not has_registered_system(system_id):
			missing_systems.append(system_id)

	if not missing_systems.is_empty():
		last_errors = ["missing required systems: %s" % ", ".join(missing_systems)]
		return {
			"success": false,
			"snapshot": null,
			"missing_systems": missing_systems,
			"save_snapshot_completeness": 0.0,
			"cross_system_consistency_ratio": 0.0,
			"errors": last_errors.duplicate(),
		}

	var snapshot: Variant = SaveSnapshotScript.new()
	snapshot.timestamp = maxi(timestamp, 0)
	snapshot.playtime_seconds = maxf(playtime_seconds, 0.0)
	snapshot.ui_screen_id = String(ui_state.get("ui_screen_id", ""))
	snapshot.ui_stack_depth = maxi(int(ui_state.get("ui_stack_depth", 0)), 0)
	snapshot.snapshot_metadata = _to_string_variant_dictionary(slot_metadata)
	snapshot.time_state = serialize_registered_system("time")
	snapshot.town_state = serialize_registered_system("town")
	snapshot.player_state = serialize_registered_system("player")
	snapshot.league_state = serialize_registered_system("league")
	snapshot.economy_state = serialize_registered_system("economy")
	snapshot.match_state = serialize_registered_system("match")
	snapshot.snapshot_metadata["integrity_hash"] = _compute_snapshot_integrity_hash(snapshot)

	var validation: Dictionary[String, Variant] = validate_snapshot(snapshot)
	var consistency: Dictionary[String, Variant] = _evaluate_cross_system_consistency(snapshot)
	var errors: Array[String] = (validation["errors"] as Array[String]).duplicate()
	errors.append_array((consistency["errors"] as Array[String]).duplicate())
	last_errors = errors.duplicate()

	var is_valid: bool = (validation["is_valid"] as bool) and is_equal_approx(consistency["cross_system_consistency_ratio"] as float, 1.0)
	return {
		"success": is_valid,
		"snapshot": snapshot,
		"missing_systems": missing_systems,
		"save_snapshot_completeness": validation["save_snapshot_completeness"] as float,
		"cross_system_consistency_ratio": consistency["cross_system_consistency_ratio"] as float,
		"errors": errors,
	}


## Assembles and commits one registered snapshot through the Story 001 slot writer.
func commit_registered_snapshot(slot_id: String, ui_state: Dictionary[String, Variant], slot_metadata: Dictionary[String, Variant] = {}, playtime_seconds: float = 0.0, timestamp: int = 0) -> Dictionary[String, Variant]:
	var time_state: Dictionary[String, Variant] = serialize_registered_system("time")
	var save_gate: Dictionary[String, Variant] = evaluate_save_gate(time_state)
	if not (save_gate.get("success", false) as bool):
		return {
			"success": false,
			"snapshot": null,
			"missing_systems": [],
			"save_snapshot_completeness": 0.0,
			"cross_system_consistency_ratio": 0.0,
			"errors": (save_gate.get("errors", []) as Array).duplicate(),
		}
	var result: Dictionary[String, Variant] = assemble_snapshot(ui_state, slot_metadata, playtime_seconds, timestamp)
	var snapshot: Variant = result.get("snapshot", null)
	if not (result.get("success", false) as bool):
		return result
	if not is_equal_approx(result.get("save_snapshot_completeness", 0.0) as float, 1.0):
		result["success"] = false
		(result["errors"] as Array[String]).append("save_snapshot_completeness must equal 1 before commit")
		last_errors = (result["errors"] as Array[String]).duplicate()
		return result
	if not is_equal_approx(result.get("cross_system_consistency_ratio", 0.0) as float, 1.0):
		result["success"] = false
		(result["errors"] as Array[String]).append("cross_system_consistency_ratio must equal 1 before commit")
		last_errors = (result["errors"] as Array[String]).duplicate()
		return result
	if not save_snapshot_to_slot(slot_id, snapshot):
		result["success"] = false
		(result["errors"] as Array[String]).append_array(last_errors.duplicate())
		return result
	return result


## Validates a SaveSnapshot against Story 001 required-field completeness rules.
## Returns structured validation details including completeness ratio and field-level errors.
func validate_snapshot(snapshot: Variant) -> Dictionary[String, Variant]:
	last_errors.clear()

	var missing_fields: Array[String] = []
	var errors: Array[String] = []
	var present_required_fields: int = 0

	if snapshot == null:
		errors.append("snapshot is null")
		missing_fields = [
			"save_version",
			"timestamp",
			"playtime_seconds",
			"ui_screen_id",
			"ui_stack_depth",
			"snapshot_metadata",
			"time_state",
			"player_state",
			"match_state",
			"economy_state",
			"town_state",
			"league_state",
		]
		last_errors = errors.duplicate()
		return _build_validation_result(false, 0, missing_fields, errors)

	if not (snapshot is Resource) or (snapshot as Resource).get_script() != SaveSnapshotScript:
		errors.append("snapshot must be a SaveSnapshot")
		missing_fields = [
			"save_version",
			"timestamp",
			"playtime_seconds",
			"ui_screen_id",
			"ui_stack_depth",
			"snapshot_metadata",
			"time_state",
			"player_state",
			"match_state",
			"economy_state",
			"town_state",
			"league_state",
		]
		last_errors = errors.duplicate()
		return _build_validation_result(false, 0, missing_fields, errors)

	if snapshot.save_version >= 1:
		present_required_fields += 1
	else:
		missing_fields.append("save_version")
		errors.append("save_version must be >= 1")

	if snapshot.timestamp >= 0:
		present_required_fields += 1
	else:
		missing_fields.append("timestamp")
		errors.append("timestamp must be >= 0")

	if snapshot.playtime_seconds >= 0.0:
		present_required_fields += 1
	else:
		missing_fields.append("playtime_seconds")
		errors.append("playtime_seconds must be >= 0.0")

	if snapshot.ui_screen_id.is_empty():
		missing_fields.append("ui_screen_id")
		errors.append("ui_screen_id must be a non-empty String")
	else:
		present_required_fields += 1

	if snapshot.ui_stack_depth >= 0:
		present_required_fields += 1
	else:
		missing_fields.append("ui_stack_depth")
		errors.append("ui_stack_depth must be >= 0")

	present_required_fields += _validate_required_dictionary_field("snapshot_metadata", snapshot.snapshot_metadata, missing_fields, errors)
	present_required_fields += _validate_required_dictionary_field("time_state", snapshot.time_state, missing_fields, errors)
	present_required_fields += _validate_required_dictionary_field("player_state", snapshot.player_state, missing_fields, errors)
	present_required_fields += _validate_match_state_field(snapshot.match_state, missing_fields, errors)
	present_required_fields += _validate_required_dictionary_field("economy_state", snapshot.economy_state, missing_fields, errors)
	present_required_fields += _validate_required_dictionary_field("town_state", snapshot.town_state, missing_fields, errors)
	present_required_fields += _validate_required_dictionary_field("league_state", snapshot.league_state, missing_fields, errors)

	var is_valid: bool = missing_fields.is_empty() and errors.is_empty()
	last_errors = errors.duplicate()
	return _build_validation_result(is_valid, present_required_fields, missing_fields, errors)


## Saves a validated snapshot to one of the four legal Story 001 slots.
## SaveManager is the only production code path that writes snapshot files to disk.
func save_snapshot_to_slot(slot_id: String, snapshot: Variant) -> bool:
	last_errors.clear()

	var path: String = resolve_slot_path(slot_id)
	if path.is_empty():
		last_errors = ["illegal slot id: %s" % slot_id]
		push_error("SaveManager: %s" % last_errors[0])
		return false

	if snapshot is SaveSnapshot:
		(snapshot as SaveSnapshot).snapshot_metadata["integrity_hash"] = _compute_snapshot_integrity_hash(snapshot as SaveSnapshot)

	var validation: Dictionary[String, Variant] = validate_snapshot(snapshot)
	if not (validation["is_valid"] as bool):
		push_error("SaveManager: snapshot validation failed for %s: %s" % [slot_id, str(validation["errors"])])
		return false

	if not _ensure_save_directory_exists():
		push_error("SaveManager: failed to ensure save directory exists: %s" % SAVE_DIRECTORY_PATH)
		return false

	var temp_path: String = _resolve_temp_slot_path(path)
	var save_error: int = _save_resource_to_path(snapshot as Resource, temp_path)
	if save_error != OK:
		last_errors = ["failed to save snapshot to %s (error %d)" % [temp_path, save_error]]
		push_error("SaveManager: %s" % last_errors[0])
		return false

	var replace_error: int = _replace_file_atomic(temp_path, path)
	if replace_error != OK:
		last_errors = ["failed to replace snapshot at %s (error %d)" % [path, replace_error]]
		var cleanup_directory: DirAccess = DirAccess.open(ProjectSettings.globalize_path(_save_directory_path))
		if cleanup_directory != null and cleanup_directory.file_exists(temp_path.get_file()):
			cleanup_directory.remove(temp_path.get_file())
		push_error("SaveManager: %s" % last_errors[0])
		return false

	return true


## Inspects a slot and reports its status plus any snapshot_metadata or validation details.
## Status values are: empty, valid, invalid, corrupted.
func inspect_slot(slot_id: String) -> Dictionary[String, Variant]:
	last_errors.clear()

	var path: String = resolve_slot_path(slot_id)
	if path.is_empty():
		var slot_errors: Array[String] = ["illegal slot id: %s" % slot_id]
		last_errors = slot_errors.duplicate()
		return _build_slot_result(SLOT_STATUS_INVALID, slot_id, path, {}, 0.0, 0, slot_errors, ["slot_id"])

	if not FileAccess.file_exists(path):
		return _build_slot_result(SLOT_STATUS_EMPTY, slot_id, path, {}, 0.0, 0, [], [])

	var loaded_resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded_resource == null:
		var parse_errors: Array[String] = ["snapshot file could not be parsed"]
		last_errors = parse_errors.duplicate()
		return _build_slot_result(SLOT_STATUS_CORRUPTED, slot_id, path, {}, 0.0, 0, parse_errors, [])

	if loaded_resource.get_script() != SaveSnapshotScript:
		var type_errors: Array[String] = ["resource is not a SaveSnapshot"]
		last_errors = type_errors.duplicate()
		return _build_slot_result(SLOT_STATUS_CORRUPTED, slot_id, path, {}, 0.0, 0, type_errors, [])

	var snapshot: SaveSnapshot = loaded_resource as SaveSnapshot
	var migration_result: Dictionary[String, Variant] = migrate_snapshot_if_needed(snapshot)
	var migrated_snapshot: SaveSnapshot = migration_result.get("snapshot", snapshot) as SaveSnapshot
	var validation: Dictionary[String, Variant] = validate_snapshot(migrated_snapshot)
	var snapshot_metadata: Dictionary[String, Variant] = _to_string_variant_dictionary(migrated_snapshot.snapshot_metadata)
	var errors: Array[String] = (migration_result.get("errors", []) as Array[String]).duplicate()
	var is_structurally_valid: bool = validation["is_valid"] as bool
	var status: String = SLOT_STATUS_VALID if (migration_result.get("success", false) as bool) else SLOT_STATUS_INVALID
	if not is_structurally_valid:
		status = SLOT_STATUS_INVALID
	if is_structurally_valid and errors.has("snapshot integrity hash mismatch"):
		status = SLOT_STATUS_CORRUPTED
	elif is_structurally_valid and not _verify_snapshot_integrity(migrated_snapshot):
		status = SLOT_STATUS_CORRUPTED
		errors.append("snapshot integrity hash mismatch")
	last_errors = errors.duplicate()
	return _build_slot_result(
		status,
		slot_id,
		path,
		snapshot_metadata,
		validation["save_snapshot_completeness"] as float,
		validation["present_required_fields"] as int,
		errors,
		validation["missing_fields"] as Array[String]
	)


func _build_validation_result(is_valid: bool, present_required_fields: int, missing_fields: Array[String], errors: Array[String]) -> Dictionary[String, Variant]:
	var completeness: float = float(present_required_fields) / float(TOTAL_REQUIRED_FIELDS)
	return {
		"is_valid": is_valid,
		"save_snapshot_completeness": completeness,
		"present_required_fields": present_required_fields,
		"total_required_fields": TOTAL_REQUIRED_FIELDS,
		"missing_fields": missing_fields,
		"errors": errors,
	}


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = _duplicate_variant_deep(source[key])
	return typed_dictionary


func _duplicate_variant_deep(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value


func _validate_required_dictionary_field(field_name: String, value: Variant, missing_fields: Array[String], errors: Array[String]) -> int:
	if not (value is Dictionary):
		missing_fields.append(field_name)
		errors.append("%s must be a Dictionary" % field_name)
		return 0

	return 1


func _validate_match_state_field(value: Variant, missing_fields: Array[String], errors: Array[String]) -> int:
	if not (value is Dictionary):
		missing_fields.append("match_state")
		errors.append("match_state must be a Dictionary")
		return 0
	var match_state: Dictionary = value as Dictionary
	var field_missing: bool = false
	var field_invalid: bool = false
	var required_match_fields: Array[String] = [
		"state",
		"state_name",
		"pending_match_context",
		"result_packet",
		"formal_state_history",
		"confirmed_results_by_match_id",
	]
	for field_name: String in required_match_fields:
		if not match_state.has(field_name):
			missing_fields.append("match_state.%s" % field_name)
			field_missing = true
	if not match_state.has("state") or not match_state.get("state", null) is int:
		errors.append("match_state.state must be an int")
		field_invalid = true
	if not match_state.has("state_name") or not match_state.get("state_name", null) is String:
		errors.append("match_state.state_name must be a String")
		field_invalid = true
	if not match_state.has("pending_match_context") or not match_state.get("pending_match_context", null) is Dictionary:
		errors.append("match_state.pending_match_context must be a Dictionary")
		field_invalid = true
	if not match_state.has("result_packet") or not match_state.get("result_packet", null) is Dictionary:
		errors.append("match_state.result_packet must be a Dictionary")
		field_invalid = true
	if not match_state.has("formal_state_history") or not match_state.get("formal_state_history", null) is Array:
		errors.append("match_state.formal_state_history must be an Array")
		field_invalid = true
	if not match_state.has("confirmed_results_by_match_id") or not match_state.get("confirmed_results_by_match_id", null) is Dictionary:
		errors.append("match_state.confirmed_results_by_match_id must be a Dictionary")
		field_invalid = true
	if field_missing or field_invalid:
		return 0
	return 1


func _build_slot_result(status: String, slot_id: String, path: String, snapshot_metadata: Dictionary[String, Variant], completeness: float, present_required_fields: int, errors: Array[String], missing_fields: Array[String]) -> Dictionary[String, Variant]:
	return {
		"status": status,
		"slot_id": slot_id,
		"path": path,
		"snapshot_metadata": snapshot_metadata,
		"save_snapshot_completeness": completeness,
		"present_required_fields": present_required_fields,
		"total_required_fields": TOTAL_REQUIRED_FIELDS,
		"errors": errors,
		"missing_fields": missing_fields,
	}


func _build_recovery_result(success: bool, slot_id: String, snapshot: SaveSnapshot, restored_systems: Array[String], failed_system: String, errors: Array[String], recovery_reason: String, recovery_action: String, requires_confirmation: bool) -> Dictionary[String, Variant]:
	return {
		"success": success,
		"slot_id": slot_id,
		"snapshot": snapshot,
		"restored_systems": restored_systems,
		"failed_system": failed_system,
		"errors": errors,
		"recovery_reason": recovery_reason,
		"recovery_action": recovery_action,
		"requires_confirmation": requires_confirmation,
	}


func _classify_recovery_reason(snapshot: SaveSnapshot, errors: Array[String]) -> String:
	for error_message: String in errors:
		if error_message.contains("newer than supported"):
			return "unsupported"
		if error_message.contains("unsupported migration step"):
			return "migration_failed"
		if error_message.contains("integrity hash mismatch"):
			return "corrupted"
	if snapshot == null:
		return "corrupted"
	return "migration_failed"


func _get_snapshot_system_state(snapshot: SaveSnapshot, system_id: String) -> Dictionary[String, Variant]:
	match system_id:
		"time":
			return snapshot.time_state.duplicate(true)
		"town":
			return snapshot.town_state.duplicate(true)
		"player":
			return snapshot.player_state.duplicate(true)
		"league":
			return snapshot.league_state.duplicate(true)
		"economy":
			return snapshot.economy_state.duplicate(true)
		"match":
			return snapshot.match_state.duplicate(true)
		_:
			return {}


func _evaluate_cross_system_consistency(snapshot: SaveSnapshot) -> Dictionary[String, Variant]:
	var total_checks: int = 2
	var passed_checks: int = 0
	var errors: Array[String] = []
	var time_state: Dictionary[String, Variant] = snapshot.time_state
	var match_state: Dictionary[String, Variant] = snapshot.match_state

	var timeline_position: int = int(time_state.get("timeline_position", -1))
	var scheduled_position: int = int(match_state.get("scheduled_position", -1))
	if timeline_position < 0 or scheduled_position < 0 or timeline_position <= scheduled_position:
		passed_checks += 1
	else:
		errors.append("timeline position cannot exceed scheduled match position")

	var match_in_progress: bool = match_state.get("in_progress", false) as bool
	var current_state: String = String(time_state.get("current_state", ""))
	if not match_in_progress or current_state == "Match In Progress":
		passed_checks += 1
	else:
		errors.append("match in progress requires Match In Progress time state")

	var ratio: float = float(passed_checks) / float(total_checks)
	return {
		"passed_checks": passed_checks,
		"total_checks": total_checks,
		"cross_system_consistency_ratio": ratio,
		"errors": errors,
	}


func _ensure_save_directory_exists() -> bool:
	var absolute_save_directory_path: String = ProjectSettings.globalize_path(_save_directory_path)
	if DirAccess.dir_exists_absolute(absolute_save_directory_path):
		return true

	var make_directory_error: int = DirAccess.make_dir_recursive_absolute(absolute_save_directory_path)
	if make_directory_error != OK:
		last_errors = ["failed to create save directory %s (error %d)" % [_save_directory_path, make_directory_error]]
		return false

	return true


func _compute_snapshot_integrity_hash(snapshot: SaveSnapshot) -> int:
	var payload: String = "%s|%s|%s|%s|%s|%s" % [
		_serialize_variant_for_integrity(snapshot.time_state),
		_serialize_variant_for_integrity(snapshot.player_state),
		_serialize_variant_for_integrity(snapshot.match_state),
		_serialize_variant_for_integrity(snapshot.economy_state),
		_serialize_variant_for_integrity(snapshot.town_state),
		_serialize_variant_for_integrity(snapshot.league_state),
	]
	return hash(payload)


func _migrate_snapshot_forward(snapshot: SaveSnapshot, from_version: int, to_version: int) -> Dictionary[String, Variant]:
	var current_version: int = from_version
	while current_version < to_version:
		match current_version:
			0:
				if not snapshot.match_state.has("formal_state_history"):
					snapshot.match_state["formal_state_history"] = []
				if not snapshot.match_state.has("confirmed_results_by_match_id"):
					snapshot.match_state["confirmed_results_by_match_id"] = {}
				if not snapshot.match_state.has("scheduled_position"):
					snapshot.match_state["scheduled_position"] = int(snapshot.time_state.get("timeline_position", 0))
				if not snapshot.match_state.has("in_progress"):
					snapshot.match_state["in_progress"] = false
			_:
				return {
					"success": false,
					"migrated": false,
					"snapshot": snapshot,
					"errors": ["unsupported migration step %d -> %d" % [current_version, current_version + 1]],
				}
		current_version += 1
	snapshot.save_version = to_version
	return {"success": true, "migrated": true, "snapshot": snapshot, "errors": []}


func _verify_snapshot_integrity(snapshot: SaveSnapshot) -> bool:
	if snapshot == null:
		return false
	var stored_hash: int = int(snapshot.snapshot_metadata.get("integrity_hash", 0))
	return stored_hash != 0 and stored_hash == _compute_snapshot_integrity_hash(snapshot)


func _serialize_variant_for_integrity(value: Variant) -> String:
	if value is Dictionary:
		var dictionary_value: Dictionary = value as Dictionary
		var keys: Array[String] = []
		for key: Variant in dictionary_value.keys():
			keys.append(String(key))
		keys.sort()
		var parts: Array[String] = []
		for key: String in keys:
			parts.append("%s=%s" % [key, _serialize_variant_for_integrity(dictionary_value.get(key))])
		return "{%s}" % ",".join(parts)
	if value is Array:
		var parts: Array[String] = []
		for item: Variant in value as Array:
			parts.append(_serialize_variant_for_integrity(item))
		return "[%s]" % ",".join(parts)
	if value == null:
		return "null"
	return JSON.stringify(value)


func _save_resource_to_path(snapshot: Resource, path: String) -> int:
	return ResourceSaver.save(snapshot, path)


func _replace_file_atomic(source_path: String, target_path: String) -> int:
	var absolute_target_directory_path: String = ProjectSettings.globalize_path(target_path.get_base_dir())
	var directory: DirAccess = DirAccess.open(absolute_target_directory_path)
	if directory == null:
		return ERR_FILE_CANT_OPEN
	var target_file_name: String = target_path.get_file()
	var source_file_name: String = source_path.get_file()
	if directory.file_exists(target_file_name):
		var remove_error: int = directory.remove(target_file_name)
		if remove_error != OK:
			return remove_error
	return directory.rename(source_file_name, target_file_name)


func _resolve_temp_slot_path(path: String) -> String:
	return "%s.tmp.%s" % [path.get_basename(), path.get_extension()]


func _capture_autosave_request(reason: String, ui_state: Dictionary[String, Variant], slot_metadata: Dictionary[String, Variant], playtime_seconds: float, timestamp: int) -> void:
	_pending_autosave_requested = true
	_pending_autosave_reason = reason
	_pending_autosave_ui_state = _to_string_variant_dictionary(ui_state)
	_pending_autosave_slot_metadata = _to_string_variant_dictionary(slot_metadata)
	_pending_autosave_playtime_seconds = playtime_seconds
	_pending_autosave_timestamp = timestamp


func _on_autosave_event(event_name: String, _payload: Dictionary) -> void:
	request_autosave(event_name)


func _on_time_phase_changed(_event_name: String, payload: Dictionary) -> void:
	if not _pending_autosave_requested:
		return
	var next_phase: String = String(payload.get("new_phase", ""))
	if not is_recoverable_stable_node(next_phase):
		return
	flush_pending_autosave()


func _resolve_autosave_ui_state() -> Dictionary[String, Variant]:
	var screen_manager: Node = _get_screen_manager()
	if screen_manager == null:
		return {
			"ui_screen_id": "autosave",
			"ui_stack_depth": 0,
		}
	return {
		"ui_screen_id": String(screen_manager.call("get_active_screen_id")),
		"ui_stack_depth": int(screen_manager.call("get_screen_stack_depth")),
	}


func _get_event_bus() -> Node:
	if _event_bus_override != null:
		return _event_bus_override
	if not has_node("/root/EventBus"):
		return null
	return get_node("/root/EventBus")


func _get_screen_manager() -> Node:
	if _screen_manager_override != null:
		return _screen_manager_override
	if not has_node("/root/ScreenManager"):
		return null
	return get_node("/root/ScreenManager")
