extends SceneTree

const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const FacilityScript: Script = preload("res://src/core/facility.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

class SpyEconomyManager:
	extends "res://src/core/economy_manager.gd"

var _failures: Array[String] = []

func _initialize() -> void:
	test_only_manhattan_declared_pairs_produce_bonuses()
	test_training_medical_and_youth_formulas_use_min_level_rules()
	test_stadium_base_and_training_adjacency_formulas_apply_correctly()
	test_undeclared_pairs_and_story_caps_hold()
	test_youth_potential_floor_boost_caps_after_adjacency()
	await test_upgrading_preserves_old_level_bonuses_until_completion()
	await test_state_changes_update_queries_without_process_polling()
	if _failures.is_empty():
		print("STADIUM_ADJACENCY_FORMULA_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("STADIUM_ADJACENCY_FORMULA_TEST_FAIL: %s" % failure)
		quit(1)

func test_only_manhattan_declared_pairs_produce_bonuses() -> void:
	var town_building: TownBuilding = TownBuildingScript.new(TownConfigScript.new())
	town_building.initialize_grid(5, 5)
	_expect(town_building.register_facility(_active_facility(1, Facility.FacilityType.MEDICAL_ROOM, 3, 2, 2)), "medical room should register")
	_expect(town_building.register_facility(_active_facility(2, Facility.FacilityType.TRAINING_GROUND, 2, 2, 1)), "adjacent training ground should register")
	_expect(town_building.register_facility(_active_facility(3, Facility.FacilityType.YOUTH_ACADEMY, 5, 3, 3)), "diagonal youth academy should register")
	_expect(town_building.register_facility(_active_facility(4, Facility.FacilityType.STADIUM, 4, 1, 2)), "non-adjacent stadium should register")
	_expect(town_building.compute_facility_ap_bonus() == 3, "only the declared Manhattan training-medical pair should contribute AP bonus")
	_expect(is_equal_approx(town_building.compute_facility_training_multiplier(20), 1.32), "diagonal youth academy should not contribute training-youth adjacency beyond the youth academy base bonus")
	_expect(is_equal_approx(town_building.compute_home_advantage_bonus(), 8.0), "non-adjacent training ground should not contribute stadium home bonus")
	_expect(is_equal_approx(town_building.compute_stadium_revenue_multiplier(), 1.32), "stadium revenue multiplier should still use stadium base formula")
	town_building.free()

func test_training_medical_and_youth_formulas_use_min_level_rules() -> void:
	var town_building: TownBuilding = TownBuildingScript.new(TownConfigScript.new())
	town_building.initialize_grid(5, 5)
	_expect(town_building.register_facility(_active_facility(1, Facility.FacilityType.TRAINING_GROUND, 5, 2, 2)), "training ground should register")
	_expect(town_building.register_facility(_active_facility(2, Facility.FacilityType.MEDICAL_ROOM, 1, 2, 1)), "medical room should register")
	_expect(town_building.register_facility(_active_facility(3, Facility.FacilityType.YOUTH_ACADEMY, 1, 3, 2)), "youth academy should register")
	_expect(town_building.compute_facility_ap_bonus() == 2, "medical-room AP bonus should use min-level adjacency without final clamp masking the result")
	_expect(town_building.compute_injury_recovery_reduction() == 1, "medical-room recovery reduction should use floor and clamp rules")
	_expect(town_building.compute_potential_floor_boost() == 2, "youth potential floor boost should include the min-level adjacency bonus")
	_expect(is_equal_approx(town_building.compute_youth_training_bonus(20), 1.04), "youth training bonus should apply base age-gated formula")
	_expect(is_equal_approx(town_building.compute_youth_training_bonus(23), 1.0), "age above threshold should disable youth training bonus")
	_expect(is_equal_approx(town_building.compute_facility_training_multiplier(20), 1.339), "facility training multiplier should combine training, youth, and adjacency multipliers using min level")
	_expect(is_equal_approx(town_building.compute_facility_training_multiplier(23), 1.2875), "facility training multiplier should keep training-youth adjacency while removing age-gated youth bonus")
	town_building.free()

func test_stadium_base_and_training_adjacency_formulas_apply_correctly() -> void:
	var town_building: TownBuilding = TownBuildingScript.new(TownConfigScript.new())
	town_building.initialize_grid(5, 5)
	_expect(is_equal_approx(town_building.compute_home_advantage_bonus(), 0.0), "no stadium should yield zero home advantage bonus")
	_expect(is_equal_approx(town_building.compute_stadium_revenue_multiplier(), 1.0), "no stadium should yield neutral revenue multiplier")
	_expect(town_building.register_facility(_active_facility(1, Facility.FacilityType.STADIUM, 5, 2, 2)), "stadium should register")
	_expect(town_building.register_facility(_active_facility(2, Facility.FacilityType.TRAINING_GROUND, 5, 2, 1)), "adjacent training ground should register")
	_expect(is_equal_approx(town_building.compute_home_advantage_bonus(), 15.0), "stadium-training adjacency should raise max home advantage to 15.0")
	_expect(is_equal_approx(town_building.compute_stadium_revenue_multiplier(), 1.4), "stadium revenue multiplier should cap at 1.40 for level 5 stadium")
	var non_adjacent_town_building: TownBuilding = TownBuildingScript.new(TownConfigScript.new())
	non_adjacent_town_building.initialize_grid(5, 5)
	_expect(non_adjacent_town_building.register_facility(_active_facility(1, Facility.FacilityType.STADIUM, 3, 2, 2)), "non-adjacent stadium should register")
	_expect(non_adjacent_town_building.register_facility(_active_facility(2, Facility.FacilityType.TRAINING_GROUND, 5, 4, 4)), "non-adjacent training ground should register")
	_expect(is_equal_approx(non_adjacent_town_building.compute_home_advantage_bonus(), 6.0), "non-adjacent training ground should not add stadium home bonus")
	_expect(is_equal_approx(non_adjacent_town_building.compute_stadium_revenue_multiplier(), 1.24), "stadium revenue multiplier should depend only on stadium level")
	town_building.free()
	non_adjacent_town_building.free()

func test_undeclared_pairs_and_story_caps_hold() -> void:
	var undeclared_pair_building: TownBuilding = TownBuildingScript.new(TownConfigScript.new())
	undeclared_pair_building.initialize_grid(5, 5)
	_expect(undeclared_pair_building.register_facility(_active_facility(1, Facility.FacilityType.MEDICAL_ROOM, 3, 2, 2)), "medical room should register in undeclared-pair test")
	_expect(undeclared_pair_building.register_facility(_active_facility(2, Facility.FacilityType.YOUTH_ACADEMY, 5, 2, 1)), "adjacent youth academy should register in undeclared-pair test")
	_expect(undeclared_pair_building.register_facility(_active_facility(3, Facility.FacilityType.STADIUM, 4, 3, 2)), "adjacent stadium should register in undeclared-pair test")
	_expect(undeclared_pair_building.compute_facility_ap_bonus() == 2, "medical-room and youth-academy adjacency should not create undeclared AP bonus")
	_expect(undeclared_pair_building.compute_potential_floor_boost() == 5, "youth-academy and medical-room adjacency should not create undeclared potential bonus")
	_expect(is_equal_approx(undeclared_pair_building.compute_home_advantage_bonus(), 8.0), "stadium and medical-room adjacency should not create undeclared home bonus")
	_expect(is_equal_approx(undeclared_pair_building.compute_stadium_revenue_multiplier(), 1.32), "undeclared adjacency should not affect stadium revenue multiplier")
	var capped_config: TownConfig = TownConfigScript.new()
	capped_config.home_advantage_per_level = 2.5
	capped_config.stadium_revenue_per_level = 0.12
	capped_config.adj_stad_tr_coeff = 1.5
	_expect(capped_config.validate()["valid"] as bool, "high-but-valid story cap config should still validate")
	var capped_building: TownBuilding = TownBuildingScript.new(capped_config)
	capped_building.initialize_grid(5, 5)
	_expect(capped_building.register_facility(_active_facility(1, Facility.FacilityType.STADIUM, 5, 2, 2)), "capped stadium should register")
	var capped_home_bonus_before_adjacency: float = capped_building.compute_home_advantage_bonus()
	var capped_revenue_multiplier: float = capped_building.compute_stadium_revenue_multiplier()
	_expect(is_equal_approx(capped_home_bonus_before_adjacency, 10.0), "story home-advantage cap should hold even when config allows a larger base value (actual=%s)" % str(capped_home_bonus_before_adjacency))
	_expect(is_equal_approx(capped_revenue_multiplier, 1.4), "story revenue cap should hold even when config allows a larger base value (actual=%s)" % str(capped_revenue_multiplier))
	_expect(capped_building.register_facility(_active_facility(2, Facility.FacilityType.TRAINING_GROUND, 5, 2, 1)), "capped adjacent training ground should register")
	var capped_home_bonus_after_adjacency: float = capped_building.compute_home_advantage_bonus()
	_expect(is_equal_approx(capped_home_bonus_after_adjacency, 15.0), "story maximum home advantage should cap at 15.0 after stadium-training adjacency (actual=%s)" % str(capped_home_bonus_after_adjacency))
	undeclared_pair_building.free()
	capped_building.free()

func test_youth_potential_floor_boost_caps_after_adjacency() -> void:
	var capped_config: TownConfig = TownConfigScript.new()
	capped_config.youth_potential_floor_per_level = 1.0
	capped_config.adj_youth_tr_coeff = 0.5
	_expect(capped_config.validate()["valid"] as bool, "story-cap youth config should still validate")
	var town_building: TownBuilding = TownBuildingScript.new(capped_config)
	town_building.initialize_grid(5, 5)
	_expect(town_building.register_facility(_active_facility(1, Facility.FacilityType.YOUTH_ACADEMY, 5, 2, 2)), "level-5 youth academy should register")
	_expect(town_building.register_facility(_active_facility(2, Facility.FacilityType.TRAINING_GROUND, 5, 2, 1)), "adjacent level-5 training ground should register")
	_expect(town_building.compute_potential_floor_boost() == 5, "youth potential floor boost should remain capped at 5 after adjacency")
	town_building.free()

func test_upgrading_preserves_old_level_bonuses_until_completion() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(2500.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for upgrading-bonus test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	var build_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 2, 2)
	_expect(build_result["success"] as bool, "training ground should build before upgrading-bonus test")
	_complete_current_progress(event_bus, town_building, build_result["facility_id"] as int)
	var baseline_multiplier: float = town_building.compute_training_efficiency_multiplier()
	var upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(build_result["facility_id"] as int)
	_expect(upgrade_result["success"] as bool, "training ground should enter Upgrading state")
	_expect(is_equal_approx(town_building.compute_training_efficiency_multiplier(), baseline_multiplier), "upgrading facility should preserve old-level training bonus until completion")
	var upgrading_facility: Facility = town_building.get_facility(build_result["facility_id"] as int)
	_expect(upgrading_facility.get_state() == Facility.FacilityState.UPGRADING, "facility should be Upgrading before completion")
	_complete_current_progress(event_bus, town_building, build_result["facility_id"] as int)
	_expect(is_equal_approx(town_building.compute_training_efficiency_multiplier(), 1.10), "completed upgrade should expose the new-level training bonus")
	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func test_state_changes_update_queries_without_process_polling() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(3000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for state-change query test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	var medical_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 2, 2)
	var training_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 2, 1)
	_expect(medical_result["success"] as bool, "medical room should build before state-change query test")
	_expect(training_result["success"] as bool, "training ground should build before state-change query test")
	_expect(town_building.compute_facility_ap_bonus() == 0, "constructing facilities should not contribute AP bonus before completion")
	_complete_current_progress(event_bus, town_building, medical_result["facility_id"] as int)
	_complete_current_progress(event_bus, town_building, training_result["facility_id"] as int)
	_expect(town_building.compute_facility_ap_bonus() == 2, "completion should make adjacency AP bonus visible on the same state boundary")
	var demolish_result: Dictionary[String, Variant] = town_building.demolish_facility(training_result["facility_id"] as int)
	_expect(demolish_result["success"] as bool, "active adjacent training ground should demolish successfully")
	_expect(town_building.compute_facility_ap_bonus() == 1, "demolition should remove adjacency AP bonus on the same state boundary")
	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func _complete_current_progress(event_bus: Node, town_building: TownBuilding, facility_id: int) -> void:
	var remaining_units: int = town_building.get_facility(facility_id).get_remaining_construction_units()
	for _tick_index: int in range(remaining_units):
		event_bus.call("emit", "time_phase_changed", {})

func _make_transaction(funds_delta: float, ap_delta: float, rp_delta: float):
	var transaction = preload("res://src/core/transaction.gd").new()
	transaction.type = transaction.TransactionType.INCOME
	transaction.source_system = "test"
	transaction.reason = "test_setup"
	transaction.funds_delta = funds_delta
	transaction.ap_delta = ap_delta
	transaction.rp_delta = rp_delta
	return transaction

func _active_facility(id: int, facility_type: int, level: int, grid_x: int, grid_y: int) -> Facility:
	return FacilityScript.new(id, facility_type, level, Facility.FacilityState.ACTIVE, grid_x, grid_y, 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
