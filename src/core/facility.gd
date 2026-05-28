class_name Facility
extends RefCounted
## Runtime town facility model owned by TownBuilding.

const MIN_LEVEL: int = 0
const MAX_LEVEL: int = 5

enum FacilityType {
	TRAINING_GROUND,
	MEDICAL_ROOM,
	YOUTH_ACADEMY,
	STADIUM,
}

enum FacilityState {
	EMPTY,
	CONSTRUCTING,
	ACTIVE,
	UPGRADING,
	DEMOLISHING,
}

var _id: int = 0
var _facility_type: int = FacilityType.TRAINING_GROUND
var _level: int = MIN_LEVEL
var _state: int = FacilityState.EMPTY
var _grid_x: int = -1
var _grid_y: int = -1
var _remaining_construction_units: int = 0


func _init(
	id: int = 0,
	facility_type: int = FacilityType.TRAINING_GROUND,
	level: int = MIN_LEVEL,
	state: int = FacilityState.EMPTY,
	grid_x: int = -1,
	grid_y: int = -1,
	remaining_construction_units: int = 0
) -> void:
	_id = id
	_facility_type = facility_type
	_level = level
	_state = state
	_grid_x = grid_x
	_grid_y = grid_y
	_remaining_construction_units = remaining_construction_units


## Returns whether the provided facility type belongs to the MVP set.
static func is_supported_facility_type(value: int) -> bool:
	return value >= FacilityType.TRAINING_GROUND and value <= FacilityType.STADIUM


## Returns whether the provided facility level is within the MVP range.
static func is_supported_level(value: int) -> bool:
	return value >= MIN_LEVEL and value <= MAX_LEVEL


## Returns whether this runtime facility satisfies the Story 001 contract.
func is_valid() -> bool:
	return is_supported_facility_type(_facility_type) and is_supported_level(_level)


## Returns the runtime facility identifier.
func get_id() -> int:
	return _id


## Returns the MVP facility type.
func get_facility_type() -> int:
	return _facility_type


## Returns the current runtime level.
func get_level() -> int:
	return _level


## Returns the current runtime state.
func get_state() -> int:
	return _state


## Returns the grid x coordinate.
func get_grid_x() -> int:
	return _grid_x


## Returns the grid y coordinate.
func get_grid_y() -> int:
	return _grid_y


## Returns the remaining construction units.
func get_remaining_construction_units() -> int:
	return _remaining_construction_units


## Returns a detached copy safe for read-only query results.
func duplicate_for_query() -> Facility:
	return Facility.new(_id, _facility_type, _level, _state, _grid_x, _grid_y, _remaining_construction_units)


## Updates the runtime level inside the authoritative owner only.
func _set_level(value: int) -> void:
	_level = value


## Updates the runtime state inside the authoritative owner only.
func _set_state(value: int) -> void:
	_state = value


## Updates the runtime position inside the authoritative owner only.
func _set_position(grid_x: int, grid_y: int) -> void:
	_grid_x = grid_x
	_grid_y = grid_y


## Updates the remaining construction units inside the authoritative owner only.
func _set_remaining_construction_units(value: int) -> void:
	_remaining_construction_units = value


## Returns a serializable snapshot of this runtime facility.
func to_dict() -> Dictionary[String, Variant]:
	return {
		"id": _id,
		"facility_type": _facility_type,
		"level": _level,
		"state": _state,
		"grid_x": _grid_x,
		"grid_y": _grid_y,
		"remaining_construction_units": _remaining_construction_units,
	}


## Rebuilds a runtime facility from serialized data.
static func from_dict(data: Dictionary[String, Variant]):
	return Facility.new(
		int(data.get("id", 0)),
		int(data.get("facility_type", FacilityType.TRAINING_GROUND)),
		int(data.get("level", MIN_LEVEL)),
		int(data.get("state", FacilityState.EMPTY)),
		int(data.get("grid_x", -1)),
		int(data.get("grid_y", -1)),
		int(data.get("remaining_construction_units", 0))
	)
