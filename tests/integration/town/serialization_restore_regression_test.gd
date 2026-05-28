extends SceneTree

const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

class SpyEconomyManager:
	extends "res://src/core/economy_manager.gd"

var _failures: Array[String] = []
var _completion_events: Array[Dictionary] = []

func _initialize() -> void:
	await test_serialize_captures_full_town_state()
	await test_deserialize_restores_construction_state_exactly()
	await test_restored_progress_completes_on_expected_tick_once()
	await test_restored_progress_handles_single_tick_and_multiple_projects()
	if _failures.is_empty():
		print("SERIALIZATION_RESTORE_REGRESSION_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("SERIALIZATION_RESTORE_REGRESSION_TEST_FAIL: %s" % failure)
		quit(1)

func test_serialize_captures_full_town_state() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(6000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for serialize test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var save_manager: Node = SaveManagerScript.new()
	_expect(town_building.register_with_save_manager(save_manager), "town building should register with SaveManager")
	_expect(save_manager.has_registered_system("town"), "SaveManager should record the town system registration")
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	var training_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 1, 1)
	var medical_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 2, 1)
	_expect(training_result["success"] as bool, "training ground should build for serialization test")
	_expect(medical_result["success"] as bool, "medical room should build for serialization test")
	_complete_current_progress(event_bus, town_building, medical_result["facility_id"] as int)
	var medical_upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(medical_result["facility_id"] as int)
	_expect(medical_upgrade_result["success"] as bool, "medical room should enter upgrading state for serialization test")
	var payload: Dictionary[String, Variant] = town_building.serialize()
	var registered_payload: Dictionary[String, Variant] = save_manager.serialize_registered_system("town")
	_expect(int(payload.get("grid_width", 0)) == 5, "serialized payload should include grid_width")
	_expect(int(payload.get("grid_height", 0)) == 5, "serialized payload should include grid_height")
	_expect(int(payload.get("next_facility_id", 0)) == 3, "serialized payload should include next_facility_id")
	_expect(payload.has("facilities"), "serialized payload should include the facility list")
	_expect((payload.get("facilities", []) as Array).size() == 2, "serialized payload should include both facilities")
	_expect(JSON.stringify(payload) == JSON.stringify(registered_payload), "SaveManager serialization should match direct town serialization")
	var serialized_training: Dictionary[String, Variant] = _find_serialized_facility(payload, training_result["facility_id"] as int)
	var serialized_medical: Dictionary[String, Variant] = _find_serialized_facility(payload, medical_result["facility_id"] as int)
	_expect(int(serialized_training.get("grid_x", -1)) == 1 and int(serialized_training.get("grid_y", -1)) == 1, "serialized constructing facility should preserve its grid position")
	_expect(int(serialized_training.get("level", -1)) == 0, "serialized constructing facility should preserve its level")
	_expect(int(serialized_training.get("state", -1)) == Facility.FacilityState.CONSTRUCTING, "serialized constructing facility should preserve its state")
	_expect(int(serialized_training.get("remaining_construction_units", -1)) > 0, "serialized constructing facility should preserve remaining construction units")
	_expect(int(serialized_medical.get("level", -1)) == 1, "serialized upgrading facility should preserve its pre-upgrade level")
	_expect(int(serialized_medical.get("state", -1)) == Facility.FacilityState.UPGRADING, "serialized upgrading facility should preserve its upgrading state")
	_expect(int(serialized_medical.get("remaining_construction_units", -1)) > 0, "serialized upgrading facility should preserve remaining upgrade units")
	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	save_manager.free()
	event_bus.free()

func test_deserialize_restores_construction_state_exactly() -> void:
	var event_bus: Node = EventBusScript.new()
	var source_config: Resource = TownConfigScript.new()
	var source_economy := SpyEconomyManager.new()
	source_economy.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(source_economy.execute_transaction(_make_transaction(6000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for deserialize test")
	var source_town: TownBuilding = TownBuildingScript.new(source_config, source_economy)
	source_town.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", source_town)
	await process_frame
	var stadium_result: Dictionary[String, Variant] = source_town.build_facility(Facility.FacilityType.STADIUM, 0, 0)
	var youth_result: Dictionary[String, Variant] = source_town.build_facility(Facility.FacilityType.YOUTH_ACADEMY, 4, 4)
	_expect(stadium_result["success"] as bool, "stadium should build for deserialize setup")
	_expect(youth_result["success"] as bool, "youth academy should build for deserialize setup")
	_complete_current_progress(event_bus, source_town, youth_result["facility_id"] as int)
	var youth_upgrade_result: Dictionary[String, Variant] = source_town.upgrade_facility(youth_result["facility_id"] as int)
	_expect(youth_upgrade_result["success"] as bool, "youth academy should enter upgrading state for deserialize setup")
	var payload: Dictionary[String, Variant] = source_town.serialize().duplicate(true)
	var restored_config: Resource = TownConfigScript.new()
	var restored_economy := SpyEconomyManager.new()
	var restored_town: TownBuilding = TownBuildingScript.new(restored_config, restored_economy)
	var save_manager: Node = SaveManagerScript.new()
	_expect(restored_town.register_with_save_manager(save_manager), "restored town should register with SaveManager before deserialize coverage")
	_expect(save_manager.deserialize_registered_system("town", payload), "SaveManager should dispatch the registered town deserialize callable")
	_expect(restored_town.get_grid_width() == source_town.get_grid_width(), "deserialize should restore grid width")
	_expect(restored_town.get_grid_height() == source_town.get_grid_height(), "deserialize should restore grid height")
	_expect(restored_town.get_registered_facility_count() == source_town.get_registered_facility_count(), "deserialize should restore the facility registry size")
	_expect(JSON.stringify(restored_town.serialize()) == JSON.stringify(payload), "deserialize should restore the exact serialized town payload")
	var restored_constructing: Facility = restored_town.get_facility(stadium_result["facility_id"] as int)
	var restored_upgrading: Facility = restored_town.get_facility(youth_result["facility_id"] as int)
	_expect(restored_constructing != null and restored_town.get_facility_at(0, 0) != null, "deserialize should restore constructing facility occupancy")
	_expect(restored_upgrading != null and restored_town.get_facility_at(4, 4) != null, "deserialize should restore upgrading facility occupancy")
	_expect(restored_constructing.get_state() == Facility.FacilityState.CONSTRUCTING, "deserialize should preserve constructing state")
	_expect(restored_upgrading.get_state() == Facility.FacilityState.UPGRADING, "deserialize should preserve upgrading state")
	_expect(restored_constructing.get_remaining_construction_units() == source_town.get_facility(stadium_result["facility_id"] as int).get_remaining_construction_units(), "deserialize should preserve constructing remaining units exactly")
	_expect(restored_upgrading.get_remaining_construction_units() == source_town.get_facility(youth_result["facility_id"] as int).get_remaining_construction_units(), "deserialize should preserve upgrading remaining units exactly")
	_expect(restored_upgrading.get_level() == source_town.get_facility(youth_result["facility_id"] as int).get_level(), "deserialize should preserve upgrading facility level without resetting it")
	root.remove_child(source_town)
	source_town.free()
	source_economy.free()
	restored_town.free()
	restored_economy.free()
	save_manager.free()
	event_bus.free()

func test_restored_progress_completes_on_expected_tick_once() -> void:
	var source_event_bus: Node = EventBusScript.new()
	var source_config: Resource = TownConfigScript.new()
	var source_economy := SpyEconomyManager.new()
	source_economy.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(source_economy.execute_transaction(_make_transaction(6000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for restored progress test")
	var source_town: TownBuilding = TownBuildingScript.new(source_config, source_economy)
	source_town.set_event_bus_for_testing(source_event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", source_town)
	await process_frame
	var build_result: Dictionary[String, Variant] = source_town.build_facility(Facility.FacilityType.TRAINING_GROUND, 2, 2)
	_expect(build_result["success"] as bool, "training ground should build for restored progress test")
	source_event_bus.call("emit", "time_phase_changed", {})
	source_event_bus.call("emit", "time_phase_changed", {})
	var remaining_at_save: int = source_town.get_facility(build_result["facility_id"] as int).get_remaining_construction_units()
	_expect(remaining_at_save == 2, "test setup should leave exactly two construction ticks remaining at save time")
	var payload: Dictionary[String, Variant] = source_town.serialize().duplicate(true)
	root.remove_child(source_town)
	source_town.free()
	source_economy.free()
	source_event_bus.free()
	var restored_event_bus: Node = EventBusScript.new()
	var restored_config: Resource = TownConfigScript.new()
	var restored_economy := SpyEconomyManager.new()
	var restored_town: TownBuilding = TownBuildingScript.new(restored_config, restored_economy)
	var save_manager: Node = SaveManagerScript.new()
	restored_town.set_event_bus_for_testing(restored_event_bus)
	_expect(restored_town.register_with_save_manager(save_manager), "restored town should register with SaveManager before progress resume coverage")
	root.call_deferred("add_child", restored_town)
	await process_frame
	_completion_events.clear()
	restored_event_bus.call("subscribe", "town_facility_completed", Callable(self, "_on_completion_event"))
	_expect(save_manager.deserialize_registered_system("town", payload), "SaveManager should restore the saved town payload before progress resumes")
	_expect(restored_town.get_facility(build_result["facility_id"] as int).get_remaining_construction_units() == remaining_at_save, "restored facility should keep the saved remaining construction units")
	restored_event_bus.call("emit", "time_phase_changed", {})
	_expect(_completion_events.is_empty(), "restored construction should not complete before the expected tick")
	_expect(restored_town.get_facility(build_result["facility_id"] as int).get_state() == Facility.FacilityState.CONSTRUCTING, "restored facility should remain constructing one tick before completion")
	restored_event_bus.call("emit", "time_phase_changed", {})
	_expect(_completion_events.size() == 1, "restored construction should emit completion exactly once on the expected tick")
	_expect(int(_completion_events[0].get("facility_id", 0)) == build_result["facility_id"] as int, "completion event should reference the restored facility id")
	_expect(restored_town.get_facility(build_result["facility_id"] as int).get_state() == Facility.FacilityState.ACTIVE, "restored facility should become active on the expected completion tick")
	restored_event_bus.call("emit", "time_phase_changed", {})
	_expect(_completion_events.size() == 1, "restored construction should not emit duplicate completion events after finishing")
	root.remove_child(restored_town)
	restored_town.free()
	restored_economy.free()
	save_manager.free()
	restored_event_bus.free()

func test_restored_progress_handles_single_tick_and_multiple_projects() -> void:
	var source_event_bus: Node = EventBusScript.new()
	var source_config: Resource = TownConfigScript.new()
	var source_economy := SpyEconomyManager.new()
	source_economy.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(source_economy.execute_transaction(_make_transaction(8000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for multi-project restore test")
	var source_town: TownBuilding = TownBuildingScript.new(source_config, source_economy)
	source_town.set_event_bus_for_testing(source_event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", source_town)
	await process_frame
	var training_result: Dictionary[String, Variant] = source_town.build_facility(Facility.FacilityType.TRAINING_GROUND, 0, 0)
	var stadium_result: Dictionary[String, Variant] = source_town.build_facility(Facility.FacilityType.STADIUM, 4, 4)
	_expect(training_result["success"] as bool, "training ground should build for multi-project restore test")
	_expect(stadium_result["success"] as bool, "stadium should build for multi-project restore test")
	source_event_bus.call("emit", "time_phase_changed", {})
	source_event_bus.call("emit", "time_phase_changed", {})
	source_event_bus.call("emit", "time_phase_changed", {})
	var training_remaining_at_save: int = source_town.get_facility(training_result["facility_id"] as int).get_remaining_construction_units()
	var stadium_remaining_at_save: int = source_town.get_facility(stadium_result["facility_id"] as int).get_remaining_construction_units()
	_expect(training_remaining_at_save == 1, "training ground should have exactly one tick remaining at save time")
	_expect(stadium_remaining_at_save == 5, "stadium should preserve an independent remaining timer at save time")
	var payload: Dictionary[String, Variant] = source_town.serialize().duplicate(true)
	root.remove_child(source_town)
	source_town.free()
	source_economy.free()
	source_event_bus.free()
	var restored_event_bus: Node = EventBusScript.new()
	var restored_config: Resource = TownConfigScript.new()
	var restored_economy := SpyEconomyManager.new()
	var restored_town: TownBuilding = TownBuildingScript.new(restored_config, restored_economy)
	var save_manager: Node = SaveManagerScript.new()
	restored_town.set_event_bus_for_testing(restored_event_bus)
	_expect(restored_town.register_with_save_manager(save_manager), "restored town should register with SaveManager before multi-project coverage")
	root.call_deferred("add_child", restored_town)
	await process_frame
	_completion_events.clear()
	restored_event_bus.call("subscribe", "town_facility_completed", Callable(self, "_on_completion_event"))
	_expect(save_manager.deserialize_registered_system("town", payload), "SaveManager should restore the saved town payload for multi-project coverage")
	restored_event_bus.call("emit", "time_phase_changed", {})
	_expect(_completion_events.size() == 1, "only the D=1 restored facility should complete on the first tick")
	_expect(int(_completion_events[0].get("facility_id", 0)) == training_result["facility_id"] as int, "the first restored completion should belong to the D=1 facility")
	_expect(restored_town.get_facility(training_result["facility_id"] as int).get_state() == Facility.FacilityState.ACTIVE, "the D=1 restored facility should become active on the first tick")
	_expect(restored_town.get_facility(stadium_result["facility_id"] as int).get_state() == Facility.FacilityState.CONSTRUCTING, "other restored projects should remain in progress after the first tick")
	_expect(restored_town.get_facility(stadium_result["facility_id"] as int).get_remaining_construction_units() == stadium_remaining_at_save - 1, "other restored projects should decrement exactly once per tick")
	restored_event_bus.call("emit", "time_phase_changed", {})
	_expect(_completion_events.size() == 1, "the already completed D=1 facility should not emit duplicate completion on later ticks")
	root.remove_child(restored_town)
	restored_town.free()
	restored_economy.free()
	save_manager.free()
	restored_event_bus.free()

func _find_serialized_facility(payload: Dictionary[String, Variant], facility_id: int) -> Dictionary[String, Variant]:
	for facility_data: Variant in payload.get("facilities", []) as Array:
		var typed_facility: Dictionary[String, Variant] = facility_data as Dictionary[String, Variant]
		if int(typed_facility.get("id", 0)) == facility_id:
			return typed_facility
	return {}

func _complete_current_progress(event_bus: Node, town_building: TownBuilding, facility_id: int) -> void:
	var remaining_units: int = town_building.get_facility(facility_id).get_remaining_construction_units()
	for _tick_index: int in range(remaining_units):
		event_bus.call("emit", "time_phase_changed", {})

func _on_completion_event(_event_name: String, payload: Dictionary) -> void:
	_completion_events.append(payload.duplicate())

func _make_transaction(funds_delta: float, ap_delta: float, rp_delta: float):
	var transaction = preload("res://src/core/transaction.gd").new()
	transaction.type = transaction.TransactionType.INCOME
	transaction.source_system = "test"
	transaction.reason = "test_setup"
	transaction.funds_delta = funds_delta
	transaction.ap_delta = ap_delta
	transaction.rp_delta = rp_delta
	return transaction

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
