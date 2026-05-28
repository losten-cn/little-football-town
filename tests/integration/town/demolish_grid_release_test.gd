extends SceneTree

const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const FacilityScript: Script = preload("res://src/core/facility.gd")

class SpyEconomyManager:
	extends "res://src/core/economy_manager.gd"

	var accredit_call_count: int = 0
	var last_funds_cost: int = -1
	var last_action_points_cost: int = -1
	var last_facility_id: int = -1

	func accredit_facility_cost(funds_cost: int, action_points_cost: int, facility_id: int = 0) -> Dictionary[String, Variant]:
		accredit_call_count += 1
		last_funds_cost = funds_cost
		last_action_points_cost = action_points_cost
		last_facility_id = facility_id
		return super.accredit_facility_cost(funds_cost, action_points_cost, facility_id)

var _failures: Array[String] = []
var _demolition_events: Array[Dictionary] = []

func _initialize() -> void:
	await test_demolish_active_facility_releases_grid_without_refund()
	await test_demolish_in_progress_facilities_returns_error_and_preserves_state()
	await test_demolish_invalidates_adjacent_bonus_in_same_boundary()
	if _failures.is_empty():
		print("DEMOLISH_GRID_RELEASE_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("DEMOLISH_GRID_RELEASE_TEST_FAIL: %s" % failure)
		quit(1)

func test_demolish_active_facility_releases_grid_without_refund() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(1000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for active demolition test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	_demolition_events.clear()
	event_bus.call("subscribe", "town_facility_demolished", Callable(self, "_on_demolition_event"))

	var build_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 2, 2)
	_expect(build_result["success"] as bool, "setup facility should build successfully before demolition")
	_complete_current_progress(event_bus, town_building, build_result["facility_id"] as int)
	var facility_id: int = build_result["facility_id"] as int
	var baseline_snapshot: Dictionary[String, float] = economy_manager.get_balance_snapshot()
	var baseline_log_size: int = economy_manager.get_transaction_log().size()
	var demolish_result: Dictionary[String, Variant] = town_building.demolish_facility(facility_id)

	_expect(demolish_result["success"] as bool, "active facility demolition should succeed")
	_expect(town_building.get_facility(facility_id) == null, "successful demolition should remove the facility from id queries")
	_expect(town_building.get_facility_at(2, 2) == null, "successful demolition should clear the occupied grid cell")
	_expect(town_building.get_registered_facility_count() == 0, "successful demolition should remove the facility from the registry")
	_expect(_demolition_events.size() == 1, "successful demolition should emit exactly one town_facility_demolished event")
	_expect(int(_demolition_events[0].get("facility_id", 0)) == facility_id, "demolition event should reference the removed facility")
	_expect(economy_manager.accredit_call_count == 1, "demolition should not create an additional accredited payment call")
	_expect(economy_manager.get_transaction_log().size() == baseline_log_size, "demolition should not append refund or payment transactions")
	_expect(is_equal_approx(float(economy_manager.get_balance_snapshot()["funds"]), float(baseline_snapshot["funds"])), "demolition should not refund or otherwise mutate funds")

	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func test_demolish_in_progress_facilities_returns_error_and_preserves_state() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(2000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for in-progress demolition test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame

	var constructing_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 1, 1)
	_expect(constructing_result["success"] as bool, "constructing setup facility should build successfully")
	var constructing_before: Facility = town_building.get_facility(constructing_result["facility_id"] as int)
	var constructing_demolish_result: Dictionary[String, Variant] = town_building.demolish_facility(constructing_result["facility_id"] as int)
	var constructing_after: Facility = town_building.get_facility(constructing_result["facility_id"] as int)
	_expect(not (constructing_demolish_result["success"] as bool), "constructing facility should reject demolition")
	_expect(String(constructing_demolish_result["error"]) == "facility_under_construction", "constructing facility should reject with facility_under_construction")
	_expect(constructing_after != null, "constructing demolition rejection should preserve the facility")
	_expect(constructing_after.get_state() == Facility.FacilityState.CONSTRUCTING, "constructing demolition rejection should preserve facility state")
	_expect(constructing_after.get_remaining_construction_units() == constructing_before.get_remaining_construction_units(), "constructing demolition rejection should preserve remaining construction time")

	var active_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 3, 1)
	_expect(active_result["success"] as bool, "active setup facility should build successfully before upgrade demolition test")
	_complete_current_progress(event_bus, town_building, active_result["facility_id"] as int)
	var upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(active_result["facility_id"] as int)
	_expect(upgrade_result["success"] as bool, "active facility should enter upgrading state before demolition rejection test")
	var upgrading_before: Facility = town_building.get_facility(active_result["facility_id"] as int)
	var upgrading_demolish_result: Dictionary[String, Variant] = town_building.demolish_facility(active_result["facility_id"] as int)
	var upgrading_after: Facility = town_building.get_facility(active_result["facility_id"] as int)
	_expect(not (upgrading_demolish_result["success"] as bool), "upgrading facility should reject demolition")
	_expect(String(upgrading_demolish_result["error"]) == "facility_under_construction", "upgrading facility should reject with facility_under_construction")
	_expect(upgrading_after != null, "upgrading demolition rejection should preserve the facility")
	_expect(upgrading_after.get_state() == Facility.FacilityState.UPGRADING, "upgrading demolition rejection should preserve upgrading state")
	_expect(upgrading_after.get_remaining_construction_units() == upgrading_before.get_remaining_construction_units(), "upgrading demolition rejection should preserve remaining upgrade time")

	var missing_result: Dictionary[String, Variant] = town_building.demolish_facility(999)
	_expect(not (missing_result["success"] as bool), "missing facility id should reject demolition")
	_expect(String(missing_result["error"]) == "facility_not_found", "missing facility id should reject with facility_not_found")

	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func test_demolish_invalidates_adjacent_bonus_in_same_boundary() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(2500.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for adjacency demolition test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame

	var medical_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 2, 2)
	_expect(medical_result["success"] as bool, "medical room should build successfully before adjacency setup")
	_complete_current_progress(event_bus, town_building, medical_result["facility_id"] as int)
	var base_bonus_without_adjacency: int = town_building.get_daily_action_points_bonus()

	var training_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 2, 1)
	_expect(training_result["success"] as bool, "training ground should build successfully before adjacency demolition")
	_complete_current_progress(event_bus, town_building, training_result["facility_id"] as int)
	var bonus_with_adjacency: int = town_building.get_daily_action_points_bonus()
	_expect(bonus_with_adjacency > base_bonus_without_adjacency, "adjacent training ground should increase the medical room action-point bonus before demolition")

	_demolition_events.clear()
	event_bus.call("subscribe", "town_facility_demolished", Callable(self, "_on_demolition_event"))
	var demolition_query_watch: Array[Dictionary] = []
	var demolition_callback := _capture_demolition_and_query.bind(town_building, demolition_query_watch)
	event_bus.call("subscribe", "town_facility_demolished", demolition_callback)
	var demolish_result: Dictionary[String, Variant] = town_building.demolish_facility(training_result["facility_id"] as int)
	var bonus_after_demolition: int = town_building.get_daily_action_points_bonus()
	_expect(demolish_result["success"] as bool, "demolishing the adjacent training ground should succeed")
	_expect(_demolition_events.size() == 1, "demolition should emit exactly one town_facility_demolished event")
	_expect(bonus_after_demolition == base_bonus_without_adjacency, "demolition should remove the affected adjacency bonus while preserving the medical room base bonus")
	_expect(demolition_query_watch.size() == 1, "event-time observer should capture exactly one demolition query snapshot")
	_expect(int(demolition_query_watch[0].get("queried_daily_ap_bonus", -1)) == base_bonus_without_adjacency, "event-time demolition query should observe the updated bonus in the same settlement boundary")
	_expect(town_building.compute_training_efficiency_multiplier() == 1.0, "demolishing the only training ground should remove its query contribution immediately")
	_expect(town_building.get_daily_maintenance_cost() > 0, "unrelated active facility bonuses should remain available after adjacency demolition")
	event_bus.call("unsubscribe", "town_facility_demolished", demolition_callback)

	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func _complete_current_progress(event_bus: Node, town_building: TownBuilding, facility_id: int) -> void:
	var remaining_units: int = town_building.get_facility(facility_id).get_remaining_construction_units()
	for _tick_index: int in range(remaining_units):
		event_bus.call("emit", "time_phase_changed", {})

func _on_demolition_event(_event_name: String, payload: Dictionary) -> void:
	_demolition_events.append(payload.duplicate())

func _capture_demolition_and_query(_event_name: String, payload: Dictionary, town_building: TownBuilding, sink: Array[Dictionary]) -> void:
	var snapshot: Dictionary = payload.duplicate()
	snapshot["queried_daily_ap_bonus"] = town_building.get_daily_action_points_bonus()
	sink.append(snapshot)

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
