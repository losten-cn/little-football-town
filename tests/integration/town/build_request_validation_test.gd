extends SceneTree

const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const FacilityScript: Script = preload("res://src/core/facility.gd")

class SpyEconomyManager:
	extends "res://src/core/economy_manager.gd"

	var accredit_call_count: int = 0
	var last_funds_cost: int = -1
	var last_action_points_cost: int = -1
	var last_facility_id: int = -1

	func accredit_facility_construction_cost(funds_cost: int, action_points_cost: int, facility_id: int = 0) -> Dictionary[String, Variant]:
		accredit_call_count += 1
		last_funds_cost = funds_cost
		last_action_points_cost = action_points_cost
		last_facility_id = facility_id
		return super.accredit_facility_construction_cost(funds_cost, action_points_cost, facility_id)

var _failures: Array[String] = []

func _initialize() -> void:
	test_valid_construction_starts_through_accredited_payment()
	test_invalid_construction_requests_do_not_mutate_grid_state()
	test_build_path_never_bypasses_economy_manager_transaction_boundary()
	if _failures.is_empty():
		print("BUILD_REQUEST_VALIDATION_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("BUILD_REQUEST_VALIDATION_TEST_FAIL: %s" % failure)
		quit(1)

func test_valid_construction_starts_through_accredited_payment() -> void:
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	var setup_transaction = _make_transaction(1000.0, 0.0, 0.0)
	_expect(economy_manager.execute_transaction(setup_transaction)["success"] as bool, "setup transaction should seed sufficient funds")
	var town_building = TownBuildingScript.new(town_config, economy_manager)

	var result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 2, 1)
	var facility_id: int = result["facility_id"] as int
	var placed_facility: Facility = town_building.get_facility_at(2, 1)
	var expected_time: int = town_building.compute_construction_time_cost(Facility.FacilityType.TRAINING_GROUND, 1)["value"] as int
	var expected_funds_cost: int = town_building.compute_construction_funds_cost(Facility.FacilityType.TRAINING_GROUND, 1)["value"] as int
	var snapshot: Dictionary[String, float] = economy_manager.get_balance_snapshot()
	var transaction_log: Array = economy_manager.get_transaction_log()

	_expect(result["success"] as bool, "valid construction request should succeed")
	_expect(facility_id == 1, "first successful build should allocate facility id 1")
	_expect(placed_facility != null, "successful build should place a facility in the target cell")
	_expect(placed_facility.get_state() == Facility.FacilityState.CONSTRUCTING, "successful build should set facility state to Constructing")
	_expect(placed_facility.get_level() == 0, "successful build should keep runtime facility level at 0 while constructing")
	_expect(placed_facility.get_remaining_construction_units() == expected_time, "successful build should store remaining construction time from Story 002 formula")
	_expect(economy_manager.accredit_call_count == 1, "valid construction should call accredit_facility_cost exactly once")
	_expect(economy_manager.last_funds_cost == expected_funds_cost, "valid construction should pass the computed funds cost into accredit_facility_cost")
	_expect(economy_manager.last_action_points_cost == 0, "valid construction should request zero action-point cost for MVP fixture")
	_expect(economy_manager.last_facility_id == facility_id, "valid construction should pass the allocated facility id into accredit_facility_cost")
	_expect(is_equal_approx(float(snapshot["funds"]), 1000.0 - float(expected_funds_cost)), "successful build should pay funds through EconomyManager")
	_expect(is_equal_approx(float(snapshot["action_points"]), 1.0), "successful build should not directly spend action points for MVP fixture")
	_expect(transaction_log.size() == 2, "setup plus successful accredited facility payment should produce two transactions")
	_expect(String(transaction_log[1].reason) == "facility_cost", "successful build should use accredited facility cost reason")
	_expect(String(transaction_log[1].source_system) == "town", "successful build should identify TownBuilding as the source system")
	_expect(int(transaction_log[1].metadata.get("facility_id", 0)) == facility_id, "accredited facility payment should record the built facility id")
	town_building.free()
	economy_manager.free()

func test_invalid_construction_requests_do_not_mutate_grid_state() -> void:
	var town_config: Resource = TownConfigScript.new()
	var seeded_economy_manager := SpyEconomyManager.new()
	seeded_economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(seeded_economy_manager.execute_transaction(_make_transaction(1000.0, 0.0, 0.0))["success"] as bool, "seeded economy setup should succeed")
	var seeded_town_building = TownBuildingScript.new(town_config, seeded_economy_manager)
	_expect(seeded_town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 0, 0)["success"] as bool, "setup facility should build successfully before occupied-cell test")
	var occupied_snapshot: Dictionary[String, float] = seeded_economy_manager.get_balance_snapshot()
	var occupied_log_size: int = seeded_economy_manager.get_transaction_log().size()
	var occupied_count: int = seeded_town_building.get_registered_facility_count()
	var occupied_result: Dictionary[String, Variant] = seeded_town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 0, 0)
	_expect(not (occupied_result["success"] as bool), "occupied cell should reject build requests")
	_expect(String(occupied_result["error"]) == "cell_occupied", "occupied cell should report cell_occupied")
	_expect(seeded_town_building.get_registered_facility_count() == occupied_count, "occupied-cell failure should not create a new facility")
	_expect(seeded_economy_manager.get_transaction_log().size() == occupied_log_size, "occupied-cell failure should not create an accredited payment transaction")
	_expect(seeded_economy_manager.accredit_call_count == 1, "occupied-cell failure should not call accredit_facility_cost again")
	_expect(is_equal_approx(float(seeded_economy_manager.get_balance_snapshot()["funds"]), float(occupied_snapshot["funds"])), "occupied-cell failure should not mutate funds")

	var out_of_bounds_result: Dictionary[String, Variant] = seeded_town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 5, 0)
	_expect(not (out_of_bounds_result["success"] as bool), "out-of-bounds build should fail")
	_expect(String(out_of_bounds_result["error"]) == "out_of_bounds", "out-of-bounds build should report out_of_bounds")
	_expect(seeded_town_building.get_registered_facility_count() == occupied_count, "out-of-bounds failure should not create a facility")
	_expect(seeded_economy_manager.get_transaction_log().size() == occupied_log_size, "out-of-bounds failure should not create a payment transaction")
	_expect(seeded_economy_manager.accredit_call_count == 1, "out-of-bounds failure should not call accredit_facility_cost")

	var poor_economy_manager := SpyEconomyManager.new()
	poor_economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(poor_economy_manager.execute_transaction(_make_transaction(200.0, 0.0, 0.0))["success"] as bool, "partial-funds setup should succeed before insufficient-funds build test")
	var poor_town_building = TownBuildingScript.new(town_config, poor_economy_manager)
	var poor_snapshot: Dictionary[String, float] = poor_economy_manager.get_balance_snapshot()
	var poor_log_size: int = poor_economy_manager.get_transaction_log().size()
	var insufficient_result: Dictionary[String, Variant] = poor_town_building.build_facility(Facility.FacilityType.STADIUM, 1, 1)
	_expect(not (insufficient_result["success"] as bool), "insufficient funds should reject construction")
	_expect(String(insufficient_result["error"]) == "funds_insufficient", "insufficient funds should report funds_insufficient")
	_expect(poor_economy_manager.accredit_call_count == 1, "insufficient-funds request should still reach accredit_facility_cost once")
	_expect(poor_town_building.get_facility_at(1, 1) == null, "insufficient-funds failure should not place a facility")
	_expect(poor_town_building.get_registered_facility_count() == 0, "insufficient-funds failure should not create a facility registry entry")
	_expect(poor_economy_manager.get_transaction_log().size() == poor_log_size, "failed accredited payment should not create a committed transaction")
	_expect(is_equal_approx(float(poor_economy_manager.get_balance_snapshot()["funds"]), float(poor_snapshot["funds"])), "insufficient-funds failure should not mutate funds")
	var retry_result: Dictionary[String, Variant] = poor_town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 1, 1)
	_expect(retry_result["success"] as bool, "retrying after failure should still succeed when a later request is affordable")
	_expect(retry_result["facility_id"] as int == 1, "failed build should not consume the next facility id")
	seeded_town_building.free()
	seeded_economy_manager.free()
	poor_town_building.free()
	poor_economy_manager.free()

func test_build_path_never_bypasses_economy_manager_transaction_boundary() -> void:
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(500.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for accredited-path test")
	var baseline_snapshot: Dictionary[String, float] = economy_manager.get_balance_snapshot()
	var baseline_log_size: int = economy_manager.get_transaction_log().size()
	var town_building = TownBuildingScript.new(town_config, economy_manager)

	var result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 4, 4)
	var after_snapshot: Dictionary[String, float] = economy_manager.get_balance_snapshot()
	var after_log: Array = economy_manager.get_transaction_log()
	var expected_funds_cost: int = town_building.compute_construction_funds_cost(Facility.FacilityType.MEDICAL_ROOM, 1)["value"] as int

	_expect(result["success"] as bool, "affordable build should succeed in accredited-path test")
	_expect(economy_manager.accredit_call_count == 1, "build path should use exactly one accredited payment call")
	_expect(economy_manager.last_funds_cost == expected_funds_cost, "build path should send the computed construction cost through accredit_facility_cost")
	_expect(economy_manager.last_action_points_cost == 0, "build path should not request direct action-point spending")
	_expect(after_log.size() == baseline_log_size + 1, "successful build should add exactly one new committed economy transaction")
	_expect(is_equal_approx(float(after_snapshot["funds"]), float(baseline_snapshot["funds"]) - float(expected_funds_cost)), "funds should change only by the accredited facility cost")
	_expect(is_equal_approx(float(after_snapshot["action_points"]), float(baseline_snapshot["action_points"])), "build path should not directly mutate action points")
	_expect(is_equal_approx(float(after_snapshot["research_points"]), float(baseline_snapshot["research_points"])), "build path should not directly mutate research points")
	_expect(String(after_log[after_log.size() - 1].reason) == "facility_cost", "build path should record facility payments through the accredited entry point")
	town_building.free()
	economy_manager.free()

func _make_transaction(funds_delta: float, ap_delta: float, rp_delta: float):
	var transaction = preload("res://src/core/transaction.gd").new()
	transaction.funds_delta = funds_delta
	transaction.ap_delta = ap_delta
	transaction.rp_delta = rp_delta
	transaction.source_system = "test"
	return transaction

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
