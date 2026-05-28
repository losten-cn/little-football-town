extends Node

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const SaveSnapshotScript: Script = preload("res://src/autoload/save_snapshot.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_same_version_snapshot_skips_migration_and_passes_validation()
	test_older_snapshot_migrates_forward_by_adding_safe_defaults()
	test_unknown_additive_fields_remain_loadable_when_required_fields_exist()
	test_future_or_structurally_incompatible_snapshot_is_rejected()
	if _failures.is_empty():
		print("SAVE_MIGRATION_TEST_PASS")
		_finish(0)
	else:
		for failure: String in _failures:
			push_error("SAVE_MIGRATION_TEST_FAIL: %s" % failure)
		_finish(1)


func test_same_version_snapshot_skips_migration_and_passes_validation() -> void:
	# Arrange
	var save_manager: Node = SaveManagerScript.new()
	var snapshot: SaveSnapshot = _make_current_snapshot()

	# Act
	var migration_result: Dictionary[String, Variant] = save_manager.migrate_snapshot_if_needed(snapshot)

	# Assert
	_expect(migration_result.get("success", false) as bool, "same-version snapshot should pass compatibility check")
	_expect(not (migration_result.get("migrated", true) as bool), "same-version snapshot should skip migration")
	_expect(migration_result.get("snapshot", null) == snapshot, "same-version snapshot should keep original snapshot instance")
	_free_if_node(save_manager)


func test_older_snapshot_migrates_forward_by_adding_safe_defaults() -> void:
	# Arrange
	var save_manager: Node = SaveManagerScript.new()
	var legacy_snapshot: SaveSnapshot = _make_legacy_v0_snapshot()
	var original_state_name: String = String(legacy_snapshot.match_state.get("state_name", ""))

	# Act
	var migration_result: Dictionary[String, Variant] = save_manager.migrate_snapshot_if_needed(legacy_snapshot)
	var migrated_snapshot: SaveSnapshot = migration_result.get("snapshot", null) as SaveSnapshot

	# Assert
	_expect(migration_result.get("success", false) as bool, "older snapshot should migrate successfully")
	_expect(migration_result.get("migrated", false) as bool, "older snapshot should report migrated")
	_expect(migrated_snapshot != null, "older snapshot migration should return a migrated snapshot")
	_expect(migrated_snapshot != legacy_snapshot, "older snapshot migration should not mutate the original snapshot instance")
	_expect(migrated_snapshot.save_version == save_manager.get_current_save_version(), "migrated snapshot should upgrade to current save version")
	_expect(String(migrated_snapshot.match_state.get("state_name", "")) == original_state_name, "migration should preserve existing match state fields")
	_expect(migrated_snapshot.match_state.has("formal_state_history"), "migration should add formal_state_history")
	_expect(migrated_snapshot.match_state.has("confirmed_results_by_match_id"), "migration should add confirmed_results_by_match_id")
	_expect(migrated_snapshot.match_state.has("scheduled_position"), "migration should add scheduled_position")
	_expect(migrated_snapshot.match_state.has("in_progress"), "migration should add in_progress")
	_free_if_node(save_manager)


func test_unknown_additive_fields_remain_loadable_when_required_fields_exist() -> void:
	# Arrange
	var save_manager: Node = SaveManagerScript.new()
	var snapshot: SaveSnapshot = _make_current_snapshot()
	snapshot.snapshot_metadata["unknown_meta"] = "keep_me"
	snapshot.match_state["future_nested_block"] = {"new_field": 9}
	snapshot.snapshot_metadata["integrity_hash"] = _compute_integrity_hash(snapshot)

	# Act
	var migration_result: Dictionary[String, Variant] = save_manager.migrate_snapshot_if_needed(snapshot)
	var migrated_snapshot: SaveSnapshot = migration_result.get("snapshot", null) as SaveSnapshot

	# Assert
	_expect(migration_result.get("success", false) as bool, "snapshot with unknown additive fields should remain loadable")
	_expect(not (migration_result.get("migrated", true) as bool), "same-version snapshot with unknown fields should not require migration")
	_expect(migrated_snapshot.snapshot_metadata.get("unknown_meta", "") == "keep_me", "unknown metadata should be preserved")
	_expect((migrated_snapshot.match_state.get("future_nested_block", {}) as Dictionary).get("new_field", 0) == 9, "unknown nested match fields should be preserved")
	_free_if_node(save_manager)


func test_future_or_structurally_incompatible_snapshot_is_rejected() -> void:
	# Arrange
	var save_manager: Node = SaveManagerScript.new()
	var future_snapshot: SaveSnapshot = _make_current_snapshot()
	future_snapshot.save_version = save_manager.get_current_save_version() + 1
	var invalid_snapshot: SaveSnapshot = _make_current_snapshot()
	invalid_snapshot.match_state.erase("state")
	invalid_snapshot.snapshot_metadata["integrity_hash"] = _compute_integrity_hash(invalid_snapshot)

	# Act
	var future_result: Dictionary[String, Variant] = save_manager.migrate_snapshot_if_needed(future_snapshot)
	var invalid_result: Dictionary[String, Variant] = save_manager.migrate_snapshot_if_needed(invalid_snapshot)

	# Assert
	_expect(not (future_result.get("success", true) as bool), "future-version snapshot should be rejected")
	_expect(not (invalid_result.get("success", true) as bool), "structurally incompatible snapshot should be rejected")
	_free_if_node(save_manager)


func _make_current_snapshot() -> SaveSnapshot:
	var snapshot: SaveSnapshot = SaveSnapshotScript.new()
	snapshot.save_version = 1
	snapshot.timestamp = 100
	snapshot.playtime_seconds = 10.0
	snapshot.ui_screen_id = "planning"
	snapshot.ui_stack_depth = 1
	snapshot.snapshot_metadata = {"seed": 1}
	snapshot.time_state = {
		"phase": "Planning",
		"timeline_position": 3,
		"current_state": "Planning",
	}
	snapshot.player_state = {"roster_count": 16}
	snapshot.match_state = {
		"state": 0,
		"state_name": "Planning",
		"pending_match_context": {},
		"result_packet": {},
		"formal_state_history": [],
		"confirmed_results_by_match_id": {},
		"scheduled_position": 4,
		"in_progress": false,
	}
	snapshot.economy_state = {"funds": 500}
	snapshot.town_state = {"facility_count": 1}
	snapshot.league_state = {"rank": 2}
	snapshot.snapshot_metadata["integrity_hash"] = _compute_integrity_hash(snapshot)
	return snapshot


func _make_legacy_v0_snapshot() -> SaveSnapshot:
	var snapshot: SaveSnapshot = SaveSnapshotScript.new()
	snapshot.save_version = 0
	snapshot.timestamp = 80
	snapshot.playtime_seconds = 8.0
	snapshot.ui_screen_id = "planning"
	snapshot.ui_stack_depth = 1
	snapshot.snapshot_metadata = {"seed": 0}
	snapshot.time_state = {
		"phase": "Planning",
		"timeline_position": 3,
		"current_state": "Planning",
	}
	snapshot.player_state = {"roster_count": 14}
	snapshot.match_state = {
		"state": 0,
		"state_name": "Planning",
		"pending_match_context": {},
		"result_packet": {},
	}
	snapshot.economy_state = {"funds": 400}
	snapshot.town_state = {"facility_count": 1}
	snapshot.league_state = {"rank": 3}
	snapshot.snapshot_metadata["integrity_hash"] = _compute_integrity_hash(snapshot)
	return snapshot


func _compute_integrity_hash(snapshot: SaveSnapshot) -> int:
	var payload: String = "%s|%s|%s|%s|%s|%s" % [
		_serialize_variant_for_integrity(snapshot.time_state),
		_serialize_variant_for_integrity(snapshot.player_state),
		_serialize_variant_for_integrity(snapshot.match_state),
		_serialize_variant_for_integrity(snapshot.economy_state),
		_serialize_variant_for_integrity(snapshot.town_state),
		_serialize_variant_for_integrity(snapshot.league_state),
	]
	return hash(payload)


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


func _finish(exit_code: int) -> void:
	call_deferred("_quit_with_code", exit_code)


func _quit_with_code(exit_code: int) -> void:
	get_tree().quit(exit_code)


func _free_if_node(value: Variant) -> void:
	if value is Node:
		(value as Node).free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
