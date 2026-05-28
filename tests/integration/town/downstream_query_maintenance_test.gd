extends SceneTree

const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const FacilityScript: Script = preload("res://src/core/facility.gd")

class SpyEconomyManager:
	extends "res://src/core/economy_manager.gd"

var _failures: Array[String] = []

func _initialize() -> void:
	await test_training_multiplier_matches_component_product()
	await test_maintenance_counts_only_active_facilities()
	await test_query_methods_are_read_only()
	if _failures.is_empty():
		print("DOWNSTREAM_QUERY_MAINTENANCE_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("DOWNSTREAM_QUERY_MAINTENANCE_TEST_FAIL: %s" % failure)
		quit(1)

func test_training_multiplier_matches_component_product() -> void:
	var town_building: TownBuilding = TownBuildingScript.new(TownConfigScript.new())
	town_building.initialize_grid(5, 5)
	_expect(is_equal_approx(town_building.compute_facility_training_multiplier(20), 1.0), "empty town should return neutral combined training multiplier")
	_expect(town_building.register_facility(_active_facility(1, Facility.FacilityType.TRAINING_GROUND, 4, 2, 2)), "training ground should register")
	_expect(town_building.register_facility(_active_facility(2, Facility.FacilityType.YOUTH_ACADEMY, 2, 3, 2)), "adjacent youth academy should register")
	var expected_young_multiplier: float = town_building.compute_training_efficiency_multiplier() * town_building.compute_youth_training_bonus(20) * _expected_training_youth_adjacency_multiplier(4, 2)
	var expected_over_age_multiplier: float = town_building.compute_training_efficiency_multiplier() * town_building.compute_youth_training_bonus(23) * _expected_training_youth_adjacency_multiplier(4, 2)
	_expect(is_equal_approx(town_building.compute_facility_training_multiplier(20), expected_young_multiplier), "combined training multiplier should equal the product of its component queries for youth players")
	_expect(is_equal_approx(town_building.compute_facility_training_multiplier(23), expected_over_age_multiplier), "combined training multiplier should equal the product of its component queries for over-age players")
	_expect(town_building.register_facility(_constructing_facility(3, Facility.FacilityType.STADIUM, 4, 1, 2, 2)), "constructing unrelated facility should register")
	_expect(is_equal_approx(town_building.compute_facility_training_multiplier(20), expected_young_multiplier), "non-related inactive facilities should not change the combined training multiplier")
	town_building.free()

func test_maintenance_counts_only_active_facilities() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(4000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for maintenance query test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	_expect(town_building.compute_facility_total_maintenance() == 0, "empty town should have zero maintenance")
	var training_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 1, 1)
	var medical_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 2, 1)
	_expect(training_result["success"] as bool, "training ground should build for maintenance setup")
	_expect(medical_result["success"] as bool, "medical room should build for maintenance setup")
	_expect(town_building.compute_facility_total_maintenance() == 0, "constructing facilities should not contribute maintenance")
	_complete_current_progress(event_bus, town_building, training_result["facility_id"] as int)
	_complete_current_progress(event_bus, town_building, medical_result["facility_id"] as int)
	_expect(town_building.compute_facility_total_maintenance() == 4, "active level-1 training ground and medical room should contribute their base maintenance only")
	var training_upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(training_result["facility_id"] as int)
	_expect(training_upgrade_result["success"] as bool, "training ground should enter upgrading state for maintenance boundary test")
	_expect(town_building.compute_facility_total_maintenance() == 2, "upgrading facilities should be excluded so only active facilities contribute maintenance")
	_complete_current_progress(event_bus, town_building, training_result["facility_id"] as int)
	_expect(town_building.compute_facility_total_maintenance() == 5, "completed upgrade should resume maintenance with base plus delta for the new active level")
	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func test_query_methods_are_read_only() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(5000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for read-only query test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	var build_ids: Array[int] = []
	for build_result: Dictionary[String, Variant] in [
		town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 2, 2),
		town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 2, 1),
		town_building.build_facility(Facility.FacilityType.YOUTH_ACADEMY, 3, 2),
		town_building.build_facility(Facility.FacilityType.STADIUM, 1, 2),
	]:
		_expect(build_result["success"] as bool, "all facilities should build for read-only query test")
		build_ids.append(build_result["facility_id"] as int)
	for facility_id: int in build_ids:
		_complete_current_progress(event_bus, town_building, facility_id)
	var training_upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(build_ids[0])
	_expect(training_upgrade_result["success"] as bool, "training ground should enter upgrading state for read-only snapshot test")
	var before_serialized: Dictionary[String, Variant] = town_building.serialize().duplicate(true)
	var before_balances: Dictionary[String, float] = economy_manager.get_balance_snapshot().duplicate()
	for _iteration: int in range(3):
		town_building.compute_training_efficiency_multiplier()
		town_building.compute_home_advantage_bonus()
		town_building.compute_stadium_revenue_multiplier()
		town_building.compute_facility_ap_bonus()
		town_building.compute_injury_recovery_reduction()
		town_building.compute_potential_floor_boost()
		town_building.compute_youth_training_bonus(20)
		town_building.compute_youth_training_bonus(23)
		town_building.compute_facility_training_multiplier(20)
		town_building.compute_facility_training_multiplier(23)
		town_building.compute_facility_total_maintenance()
		town_building.get_daily_action_points_bonus()
		town_building.get_daily_maintenance_cost()
	var after_serialized: Dictionary[String, Variant] = town_building.serialize()
	var after_balances: Dictionary[String, float] = economy_manager.get_balance_snapshot()
	_expect(_dictionaries_equal(before_serialized, after_serialized), "public query methods should not mutate serialized town state")
	_expect(_float_dictionary_equals(before_balances, after_balances), "public query methods should not mutate economy balances")
	var demolish_result: Dictionary[String, Variant] = town_building.demolish_facility(build_ids[1])
	_expect(demolish_result["success"] as bool, "demolition should succeed before post-demolition read-only check")
	var after_demolition_serialized: Dictionary[String, Variant] = town_building.serialize().duplicate(true)
	for _iteration: int in range(2):
		town_building.compute_facility_ap_bonus()
		town_building.compute_facility_total_maintenance()
		town_building.compute_facility_training_multiplier(20)
	_expect(_dictionaries_equal(after_demolition_serialized, town_building.serialize()), "queries after demolition should remain read-only")
	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func _complete_current_progress(event_bus: Node, town_building: TownBuilding, facility_id: int) -> void:
	var remaining_units: int = town_building.get_facility(facility_id).get_remaining_construction_units()
	for _tick_index: int in range(remaining_units):
		event_bus.call("emit", "time_phase_changed", {})

func _active_facility(id: int, facility_type: int, level: int, grid_x: int, grid_y: int) -> Facility:
	return FacilityScript.new(id, facility_type, level, Facility.FacilityState.ACTIVE, grid_x, grid_y, 0)

func _constructing_facility(id: int, facility_type: int, level: int, grid_x: int, grid_y: int, remaining_units: int) -> Facility:
	return FacilityScript.new(id, facility_type, level, Facility.FacilityState.CONSTRUCTING, grid_x, grid_y, remaining_units)

func _expected_training_youth_adjacency_multiplier(training_level: int, youth_level: int) -> float:
	return 1.0 + TownConfigScript.new().get_adj_tr_youth_coeff() * float(mini(training_level, youth_level))

func _float_dictionary_equals(left: Dictionary[String, float], right: Dictionary[String, float]) -> bool:
	if left.size() != right.size():
		return false
	for key: String in left.keys():
		if not right.has(key):
			return false
		if not is_equal_approx(float(left[key]), float(right[key])):
			return false
	return true

func _dictionaries_equal(left: Dictionary[String, Variant], right: Dictionary[String, Variant]) -> bool:
	return JSON.stringify(left) == JSON.stringify(right)

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
