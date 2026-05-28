extends SceneTree

const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")
const FacilityScript: Script = preload("res://src/core/facility.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_training_efficiency_multiplier_matches_base_levels()
	test_medical_formulas_apply_floor_and_clamp_rules()
	test_youth_formulas_respect_level_and_age_gates()
	if _failures.is_empty():
		print("TRAINING_MEDICAL_YOUTH_FORMULA_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("TRAINING_MEDICAL_YOUTH_FORMULA_TEST_FAIL: %s" % failure)
		quit(1)


func test_training_efficiency_multiplier_matches_base_levels() -> void:
	var empty_town: TownBuilding = _make_town()
	_expect(is_equal_approx(empty_town.compute_training_efficiency_multiplier(), 1.0), "empty town should return neutral training multiplier")
	empty_town.free()

	var inactive_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.TRAINING_GROUND, 4, Facility.FacilityState.CONSTRUCTING, 2, 2))
	_expect(is_equal_approx(inactive_town.compute_training_efficiency_multiplier(), 1.0), "inactive training ground should not contribute training multiplier")
	inactive_town.free()

	var level_1_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.TRAINING_GROUND, 1, Facility.FacilityState.ACTIVE, 2, 2))
	_expect(is_equal_approx(level_1_town.compute_training_efficiency_multiplier(), 1.05), "level 1 training ground should return configured base multiplier")
	level_1_town.free()

	var level_3_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.TRAINING_GROUND, 3, Facility.FacilityState.ACTIVE, 2, 2))
	_expect(is_equal_approx(level_3_town.compute_training_efficiency_multiplier(), 1.15), "level 3 training ground should return configured base multiplier")
	level_3_town.free()

	var level_5_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.TRAINING_GROUND, 5, Facility.FacilityState.ACTIVE, 2, 2))
	_expect(is_equal_approx(level_5_town.compute_training_efficiency_multiplier(), 1.25), "level 5 training ground should return configured base multiplier cap")
	level_5_town.free()


func test_medical_formulas_apply_floor_and_clamp_rules() -> void:
	var empty_town: TownBuilding = _make_town()
	_expect(empty_town.compute_facility_ap_bonus() == 0, "empty town should return neutral AP bonus")
	_expect(empty_town.compute_injury_recovery_reduction() == 0, "empty town should return neutral injury recovery reduction")
	empty_town.free()

	var inactive_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.MEDICAL_ROOM, 5, Facility.FacilityState.CONSTRUCTING, 2, 2))
	_expect(inactive_town.compute_facility_ap_bonus() == 0, "inactive medical room should not contribute AP bonus")
	_expect(inactive_town.compute_injury_recovery_reduction() == 0, "inactive medical room should not contribute injury recovery reduction")
	inactive_town.free()

	var level_1_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.MEDICAL_ROOM, 1, Facility.FacilityState.ACTIVE, 2, 2))
	_expect(level_1_town.compute_facility_ap_bonus() == 1, "level 1 medical room should clamp AP bonus up to the minimum visible value")
	_expect(level_1_town.compute_injury_recovery_reduction() == 1, "level 1 medical room should clamp injury recovery reduction up to the minimum visible value")
	level_1_town.free()

	var level_2_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.MEDICAL_ROOM, 2, Facility.FacilityState.ACTIVE, 2, 2))
	_expect(level_2_town.compute_facility_ap_bonus() == 1, "level 2 medical room should still floor to 1 AP bonus")
	_expect(level_2_town.compute_injury_recovery_reduction() == 1, "level 2 medical room should still floor to 1 injury recovery reduction")
	level_2_town.free()

	var level_3_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.MEDICAL_ROOM, 3, Facility.FacilityState.ACTIVE, 2, 2))
	_expect(level_3_town.compute_facility_ap_bonus() == 2, "level 3 medical room should floor to 2 AP bonus")
	_expect(level_3_town.compute_injury_recovery_reduction() == 2, "level 3 medical room should floor to 2 injury recovery reduction")
	level_3_town.free()

	var level_5_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.MEDICAL_ROOM, 5, Facility.FacilityState.ACTIVE, 2, 2))
	_expect(level_5_town.compute_facility_ap_bonus() == 3, "level 5 medical room should clamp AP bonus at the story maximum")
	_expect(level_5_town.compute_injury_recovery_reduction() == 2, "level 5 medical room should clamp injury recovery reduction at the story maximum")
	level_5_town.free()


func test_youth_formulas_respect_level_and_age_gates() -> void:
	var empty_town: TownBuilding = _make_town()
	_expect(empty_town.compute_potential_floor_boost() == 0, "empty town should return neutral potential floor boost")
	_expect(is_equal_approx(empty_town.compute_youth_training_bonus(20), 1.0), "empty town should return neutral youth training bonus")
	empty_town.free()

	var inactive_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.YOUTH_ACADEMY, 5, Facility.FacilityState.CONSTRUCTING, 2, 2))
	_expect(inactive_town.compute_potential_floor_boost() == 0, "inactive youth academy should not contribute potential floor boost")
	_expect(is_equal_approx(inactive_town.compute_youth_training_bonus(20), 1.0), "inactive youth academy should not contribute youth training bonus")
	inactive_town.free()

	var level_3_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.YOUTH_ACADEMY, 3, Facility.FacilityState.ACTIVE, 2, 2))
	_expect(level_3_town.compute_potential_floor_boost() == 3, "level 3 youth academy should return its base potential floor boost")
	_expect(is_equal_approx(level_3_town.compute_youth_training_bonus(20), 1.12), "level 3 youth academy should apply the configured youth bonus below the age threshold")
	_expect(is_equal_approx(level_3_town.compute_youth_training_bonus(22), 1.12), "age exactly at the threshold should still receive the youth bonus")
	_expect(is_equal_approx(level_3_town.compute_youth_training_bonus(23), 1.0), "age above the threshold should return neutral youth bonus")
	level_3_town.free()

	var level_5_town: TownBuilding = _make_town(_facility(1, Facility.FacilityType.YOUTH_ACADEMY, 5, Facility.FacilityState.ACTIVE, 2, 2))
	_expect(level_5_town.compute_potential_floor_boost() == 5, "level 5 youth academy should clamp potential floor boost at the story maximum without adjacency")
	_expect(is_equal_approx(level_5_town.compute_youth_training_bonus(20), 1.2), "level 5 youth academy should clamp youth training bonus at the story maximum")
	level_5_town.free()


func _make_town(facility: Facility = null) -> TownBuilding:
	var town_building: TownBuilding = TownBuildingScript.new(TownConfigScript.new())
	town_building.initialize_grid(5, 5)
	if facility != null:
		_expect(town_building.register_facility(facility), "test fixture facility should register")
	return town_building


func _facility(id: int, facility_type: int, level: int, state: int, grid_x: int, grid_y: int) -> Facility:
	return FacilityScript.new(id, facility_type, level, state, grid_x, grid_y, 0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
