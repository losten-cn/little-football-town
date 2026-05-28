extends SceneTree

const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const FacilityScript: Script = preload("res://src/core/facility.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_town_grid_initializes_with_flat_index_mapping()
	test_facility_model_stores_required_mvp_fields()
	test_town_grid_queries_do_not_mutate_state_for_invalid_lookups()
	if _failures.is_empty():
		print("TOWN_GRID_CONTRACT_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("TOWN_GRID_CONTRACT_TEST_FAIL: %s" % failure)
		quit(1)


func test_town_grid_initializes_with_flat_index_mapping() -> void:
	var town_building: TownBuilding = TownBuildingScript.new()
	_expect(town_building.get_grid_width() == 5, "grid width should default to 5")
	_expect(town_building.get_grid_height() == 5, "grid height should default to 5")
	_expect(town_building.get_grid_cell_count() == 25, "5x5 grid should allocate 25 cells")
	_expect(town_building.get_cell_index(0, 0) == 0, "(0,0) should map to flat index 0")
	_expect(town_building.get_cell_index(4, 4) == 24, "(4,4) should map to flat index 24")
	_expect(town_building.get_cell_index(2, 3) == 17, "(2,3) should map using x + y * width")
	town_building.free()


func test_facility_model_stores_required_mvp_fields() -> void:
	var training_ground_type: int = Facility.FacilityType.TRAINING_GROUND
	var medical_room_type: int = Facility.FacilityType.MEDICAL_ROOM
	var youth_academy_type: int = Facility.FacilityType.YOUTH_ACADEMY
	var stadium_type: int = Facility.FacilityType.STADIUM
	var constructing_state: int = Facility.FacilityState.CONSTRUCTING
	var active_state: int = Facility.FacilityState.ACTIVE
	var facility_types: Array[int] = [
		training_ground_type,
		medical_room_type,
		youth_academy_type,
		stadium_type,
	]
	for facility_type: int in facility_types:
		var facility: Facility = Facility.new(
			facility_type + 1,
			facility_type,
			5 if facility_type == stadium_type else 0,
			constructing_state if facility_type != stadium_type else active_state,
			facility_type,
			0,
			3 if facility_type != stadium_type else 0
		)
		_expect(facility.get_id() == facility_type + 1, "facility should retain id for type %s" % str(facility_type))
		_expect(facility.get_facility_type() == facility_type, "facility should retain facility_type %s" % str(facility_type))
		_expect(Facility.is_supported_level(facility.get_level()), "facility level should stay within 0-5")
		_expect(facility.get_grid_x() == facility_type and facility.get_grid_y() == 0, "facility should retain grid coordinates")
		_expect(facility.get_remaining_construction_units() >= 0, "facility remaining units should be non-negative")
		_expect(facility.is_valid(), "facility should validate as a supported MVP sample")
	_expect(not Facility.is_supported_facility_type(99), "unsupported facility type should be rejected by helper")
	_expect(not Facility.is_supported_level(6), "level 6 should be outside supported MVP range")
	var serialized: Dictionary[String, Variant] = Facility.new().to_dict()
	_expect(serialized.has("id"), "serialized facility should include id")
	_expect(serialized.has("facility_type"), "serialized facility should include facility_type")
	_expect(serialized.has("level"), "serialized facility should include level")
	_expect(serialized.has("state"), "serialized facility should include state")
	_expect(serialized.has("grid_x"), "serialized facility should include grid_x")
	_expect(serialized.has("grid_y"), "serialized facility should include grid_y")
	_expect(serialized.has("remaining_construction_units"), "serialized facility should include remaining_construction_units")


func test_town_grid_queries_do_not_mutate_state_for_invalid_lookups() -> void:
	var town_building: TownBuilding = TownBuildingScript.new()
	var facility: Facility = Facility.new(
		7,
		Facility.FacilityType.TRAINING_GROUND,
		1,
		Facility.FacilityState.ACTIVE,
		1,
		2,
		0
	)
	_expect(town_building.register_facility(facility), "valid facility should register successfully")
	var expected_cells: int = town_building.get_grid_cell_count()
	var queried_facility: Facility = town_building.get_facility_at(1, 2)
	_expect(queried_facility != null, "placed facility should be returned for occupied cell")
	_expect(queried_facility != facility, "query should return a detached copy instead of the authoritative instance")
	_expect(town_building.get_facility_at(-1, 0) == null, "negative x query should return null")
	_expect(town_building.get_facility_at(5, 4) == null, "out-of-bounds x query should return null")
	_expect(town_building.get_facility_at(0, -1) == null, "negative y query should return null")
	_expect(town_building.get_facility_at(0, 5) == null, "out-of-bounds y query should return null")
	_expect(town_building.get_facility_at(4, 4) == null, "empty cell query should return null")
	_expect(town_building.get_facility(999) == null, "unknown facility id should return null")
	var queried_by_id: Facility = town_building.get_facility(7)
	_expect(queried_by_id != null, "known facility id should return a registered facility copy")
	_expect(queried_by_id != facility, "id query should not leak the authoritative instance")
	_expect(town_building.get_facility_at(-1, 0) == null, "repeated invalid query should still return null")
	_expect(town_building.get_facility_at(0, 5) == null, "repeated y-out-of-bounds query should still return null")
	_expect(town_building.get_grid_cell_count() == expected_cells, "invalid queries should not change grid allocation")
	_expect(town_building.get_facility(7) != null, "invalid queries should not remove registered facilities")
	town_building.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
