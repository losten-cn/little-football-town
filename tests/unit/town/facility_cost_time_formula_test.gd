extends SceneTree

const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	test_construction_and_upgrade_funds_cost_use_ceil_and_level_exponent()
	test_construction_and_upgrade_time_use_correct_base_tables()
	test_illegal_target_levels_are_rejected()
	if _failures.is_empty():
		print("FACILITY_COST_TIME_FORMULA_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("FACILITY_COST_TIME_FORMULA_TEST_FAIL: %s" % failure)
		quit(1)

func test_construction_and_upgrade_funds_cost_use_ceil_and_level_exponent() -> void:
	var town_config = TownConfigScript.new()
	var town_building = TownBuildingScript.new(town_config)
	var facility_types: Array[int] = [
		Facility.FacilityType.TRAINING_GROUND,
		Facility.FacilityType.MEDICAL_ROOM,
		Facility.FacilityType.YOUTH_ACADEMY,
		Facility.FacilityType.STADIUM,
	]
	for facility_type: int in facility_types:
		var base_cost: int = town_config.get_base_funds_cost(facility_type)
		var level_one_result: Dictionary[String, Variant] = town_building.compute_construction_funds_cost(facility_type, 1)
		_expect(level_one_result["success"] as bool, "level 1 construction cost should succeed for facility type %s" % str(facility_type))
		_expect(level_one_result["value"] as int == base_cost, "level 1 construction cost should equal base cost for facility type %s" % str(facility_type))
		for target_level: int in [2, 3, 4, 5]:
			var expected_cost: int = int(ceili(float(base_cost) * pow(town_config.cost_multiplier, target_level - 1)))
			var construction_result: Dictionary[String, Variant] = town_building.compute_construction_funds_cost(facility_type, target_level)
			var upgrade_result: Dictionary[String, Variant] = town_building.compute_upgrade_funds_cost(facility_type, target_level)
			_expect(construction_result["success"] as bool, "construction cost should succeed for type %s level %s" % [str(facility_type), str(target_level)])
			_expect(upgrade_result["success"] as bool, "upgrade cost should succeed for type %s level %s" % [str(facility_type), str(target_level)])
			_expect(construction_result["value"] as int == expected_cost, "construction cost should match ceil formula for type %s level %s" % [str(facility_type), str(target_level)])
			_expect(upgrade_result["value"] as int == expected_cost, "upgrade cost should match ceil formula for type %s level %s" % [str(facility_type), str(target_level)])
	town_building.free()

func test_construction_and_upgrade_time_use_correct_base_tables() -> void:
	var town_config = TownConfigScript.new()
	var town_building = TownBuildingScript.new(town_config)
	for facility_type: int in [
		Facility.FacilityType.TRAINING_GROUND,
		Facility.FacilityType.MEDICAL_ROOM,
		Facility.FacilityType.YOUTH_ACADEMY,
		Facility.FacilityType.STADIUM,
	]:
		var construction_base: int = town_config.get_base_construction_time(facility_type)
		var upgrade_base: int = town_config.get_base_upgrade_time(facility_type)
		var level_one_construction: Dictionary[String, Variant] = town_building.compute_construction_time_cost(facility_type, 1)
		var level_one_upgrade: Dictionary[String, Variant] = town_building.compute_upgrade_time_cost(facility_type, 1)
		_expect(level_one_construction["success"] as bool, "level 1 construction time should succeed for facility type %s" % str(facility_type))
		_expect(level_one_upgrade["success"] as bool, "level 1 upgrade time should succeed for facility type %s" % str(facility_type))
		_expect(level_one_construction["value"] as int == construction_base, "level 1 construction time should use construction base table for facility type %s" % str(facility_type))
		_expect(level_one_upgrade["value"] as int == upgrade_base, "level 1 upgrade time should use upgrade base table for facility type %s" % str(facility_type))
		var level_five_construction: Dictionary[String, Variant] = town_building.compute_construction_time_cost(facility_type, 5)
		var level_five_upgrade: Dictionary[String, Variant] = town_building.compute_upgrade_time_cost(facility_type, 5)
		var expected_construction_level_five: int = int(ceili(float(construction_base) * pow(town_config.time_multiplier, 4)))
		var expected_upgrade_level_five: int = int(ceili(float(upgrade_base) * pow(town_config.time_multiplier, 4)))
		_expect(level_five_construction["value"] as int == expected_construction_level_five, "level 5 construction time should match ceil formula for facility type %s" % str(facility_type))
		_expect(level_five_upgrade["value"] as int == expected_upgrade_level_five, "level 5 upgrade time should match ceil formula for facility type %s" % str(facility_type))
	_expect(town_building.compute_construction_time_cost(Facility.FacilityType.MEDICAL_ROOM, 2)["value"] as int == 4, "medical room level 2 construction should ceil 3 × 1.3 to 4")
	_expect(town_building.compute_upgrade_time_cost(Facility.FacilityType.MEDICAL_ROOM, 2)["value"] as int == 3, "medical room level 2 upgrade should ceil 2 × 1.3 to 3")
	town_building.free()

func test_illegal_target_levels_are_rejected() -> void:
	var town_config = TownConfigScript.new()
	var town_building = TownBuildingScript.new(town_config)
	for illegal_level: int in [0, 6, -1]:
		for result_variant: Variant in [
			town_building.compute_construction_funds_cost(Facility.FacilityType.TRAINING_GROUND, illegal_level),
			town_building.compute_upgrade_funds_cost(Facility.FacilityType.TRAINING_GROUND, illegal_level),
			town_building.compute_construction_time_cost(Facility.FacilityType.TRAINING_GROUND, illegal_level),
			town_building.compute_upgrade_time_cost(Facility.FacilityType.TRAINING_GROUND, illegal_level),
		]:
			var result: Dictionary = result_variant as Dictionary
			_expect(not (result["success"] as bool), "illegal level %s should fail" % str(illegal_level))
			_expect(result["error"] as String == "invalid_target_level", "illegal level %s should report invalid_target_level" % str(illegal_level))
			_expect(result["value"] == null, "illegal level %s should not return executable value" % str(illegal_level))
	_expect(town_building.compute_construction_funds_cost(Facility.FacilityType.TRAINING_GROUND, 1)["success"] as bool, "level 1 should remain legal")
	_expect(town_building.compute_upgrade_time_cost(Facility.FacilityType.TRAINING_GROUND, 5)["success"] as bool, "level 5 should remain legal")
	town_building.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
