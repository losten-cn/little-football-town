class_name TownBuilding
extends Node
## Authoritative town grid owner and facility query surface.

const TownConfigType = preload("res://src/config/town_config.gd")
const ConfigLoaderType = preload("res://src/autoload/config_loader.gd")
const EconomyManagerType = preload("res://src/core/economy_manager.gd")
const DEFAULT_GRID_WIDTH: int = 5
const DEFAULT_GRID_HEIGHT: int = 5

var _grid_width: int = DEFAULT_GRID_WIDTH
var _grid_height: int = DEFAULT_GRID_HEIGHT
var _grid: Array[Facility] = []
var _facility_by_id: Dictionary[int, Facility] = {}
var _next_facility_id: int = 1
var _town_config_override: TownConfigType = null
var _economy_manager_override: EconomyManagerType = null
var _event_bus_override: Node = null


func _init(town_config_override: TownConfigType = null, economy_manager_override: EconomyManagerType = null) -> void:
	_town_config_override = town_config_override
	_economy_manager_override = economy_manager_override
	_initialize_grid()


func _ready() -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus != null:
		event_bus.call("subscribe", "time_phase_changed", Callable(self, "_on_time_phase_changed"))


func _exit_tree() -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus != null:
		event_bus.call("unsubscribe", "time_phase_changed", Callable(self, "_on_time_phase_changed"))


## Overrides the runtime EventBus for deterministic tests.
func set_event_bus_for_testing(event_bus: Node) -> void:
	_event_bus_override = event_bus


## Reinitializes the authoritative flat grid with the provided dimensions.
func initialize_grid(width: int = DEFAULT_GRID_WIDTH, height: int = DEFAULT_GRID_HEIGHT) -> void:
	_grid_width = max(width, 0)
	_grid_height = max(height, 0)
	_initialize_grid()


## Returns a serializable snapshot of the authoritative town state.
func serialize() -> Dictionary[String, Variant]:
	var facilities: Array = []
	for facility: Facility in _facility_by_id.values():
		facilities.append(facility.to_dict())
	return {
		"grid_width": _grid_width,
		"grid_height": _grid_height,
		"next_facility_id": _next_facility_id,
		"facilities": facilities,
	}


## Restores the authoritative town state from serialized data.
func deserialize(data: Dictionary[String, Variant]) -> void:
	_grid_width = int(data.get("grid_width", DEFAULT_GRID_WIDTH))
	_grid_height = int(data.get("grid_height", DEFAULT_GRID_HEIGHT))
	_initialize_grid()
	_next_facility_id = int(data.get("next_facility_id", 1))
	for facility_data: Variant in data.get("facilities", []) as Array:
		var facility: Facility = Facility.from_dict(facility_data as Dictionary[String, Variant]) as Facility
		if not _is_in_bounds(facility.get_grid_x(), facility.get_grid_y()):
			continue
		if _facility_by_id.has(facility.get_id()):
			continue
		var cell_index: int = get_cell_index(facility.get_grid_x(), facility.get_grid_y())
		if _grid[cell_index] != null:
			continue
		_grid[cell_index] = facility
		_facility_by_id[facility.get_id()] = facility
		_next_facility_id = maxi(_next_facility_id, facility.get_id() + 1)


## Returns the flat-array index for a grid coordinate.
func get_cell_index(grid_x: int, grid_y: int) -> int:
	return grid_x + grid_y * _grid_width


## Returns the configured grid width.
func get_grid_width() -> int:
	return _grid_width


## Returns the configured grid height.
func get_grid_height() -> int:
	return _grid_height


## Returns the backing flat grid cell count.
func get_grid_cell_count() -> int:
	return _grid.size()

## Returns the number of authoritative registered facilities.
func get_registered_facility_count() -> int:
	return _facility_by_id.size()

## Starts construction for a new facility when grid and economy validation succeed.
func build_facility(facility_type: int, grid_x: int, grid_y: int) -> Dictionary[String, Variant]:
	if not Facility.is_supported_facility_type(facility_type):
		return {"success": false, "error": "unsupported_facility_type", "facility_id": null}
	if _has_facility_type(facility_type):
		return {"success": false, "error": "facility_type_exists", "facility_id": null}
	if not _is_in_bounds(grid_x, grid_y):
		return {"success": false, "error": "out_of_bounds", "facility_id": null}
	if _grid[get_cell_index(grid_x, grid_y)] != null:
		return {"success": false, "error": "cell_occupied", "facility_id": null}
	var funds_result: Dictionary[String, Variant] = compute_construction_funds_cost(facility_type, 1)
	if not (funds_result["success"] as bool):
		return {"success": false, "error": String(funds_result["error"]), "facility_id": null}
	var time_result: Dictionary[String, Variant] = compute_construction_time_cost(facility_type, 1)
	if not (time_result["success"] as bool):
		return {"success": false, "error": String(time_result["error"]), "facility_id": null}
	var facility_id: int = _next_facility_id
	var payment_result: Dictionary[String, Variant] = _resolve_economy_manager().accredit_facility_construction_cost(funds_result["value"] as int, 0, facility_id)
	if not (payment_result["success"] as bool):
		return {"success": false, "error": String(payment_result.get("error", "funds_insufficient")), "facility_id": null}
	var facility := Facility.new(
		facility_id,
		facility_type,
		0,
		Facility.FacilityState.CONSTRUCTING,
		grid_x,
		grid_y,
		time_result["value"] as int
	)
	_grid[get_cell_index(grid_x, grid_y)] = facility
	_facility_by_id[facility_id] = facility
	_next_facility_id += 1
	return {"success": true, "error": "", "facility_id": facility_id}

## Starts an upgrade for an active facility when payment succeeds.
func upgrade_facility(facility_id: int) -> Dictionary[String, Variant]:
	var facility: Facility = _facility_by_id.get(facility_id, null)
	if facility == null:
		return {"success": false, "error": "facility_not_found", "facility_id": null}
	if facility.get_state() != Facility.FacilityState.ACTIVE:
		return {"success": false, "error": "facility_not_active", "facility_id": facility_id}
	if facility.get_level() >= Facility.MAX_LEVEL:
		return {"success": false, "error": "already_max_level", "facility_id": facility_id}
	var target_level: int = facility.get_level() + 1
	var funds_result: Dictionary[String, Variant] = compute_upgrade_funds_cost(facility.get_facility_type(), target_level)
	if not (funds_result["success"] as bool):
		return {"success": false, "error": String(funds_result["error"]), "facility_id": facility_id}
	var time_result: Dictionary[String, Variant] = compute_upgrade_time_cost(facility.get_facility_type(), target_level)
	if not (time_result["success"] as bool):
		return {"success": false, "error": String(time_result["error"]), "facility_id": facility_id}
	var payment_result: Dictionary[String, Variant] = _resolve_economy_manager().accredit_facility_cost(funds_result["value"] as int, 0, facility_id)
	if not (payment_result["success"] as bool):
		return {"success": false, "error": String(payment_result.get("error", "funds_insufficient")), "facility_id": facility_id}
	facility._set_state(Facility.FacilityState.UPGRADING)
	facility._set_remaining_construction_units(time_result["value"] as int)
	return {"success": true, "error": "", "facility_id": facility_id}


## Demolishes an active facility immediately and frees the occupied grid cell.
func demolish_facility(facility_id: int) -> Dictionary[String, Variant]:
	var facility: Facility = _facility_by_id.get(facility_id, null)
	if facility == null:
		return {"success": false, "error": "facility_not_found", "facility_id": null}
	if facility.get_state() == Facility.FacilityState.CONSTRUCTING or facility.get_state() == Facility.FacilityState.UPGRADING:
		return {"success": false, "error": "facility_under_construction", "facility_id": facility_id}
	if facility.get_state() != Facility.FacilityState.ACTIVE:
		return {"success": false, "error": "facility_not_active", "facility_id": facility_id}
	var grid_x: int = facility.get_grid_x()
	var grid_y: int = facility.get_grid_y()
	var facility_type: int = facility.get_facility_type()
	var level: int = facility.get_level()
	_grid[get_cell_index(grid_x, grid_y)] = null
	_facility_by_id.erase(facility_id)
	var event_bus: Node = _get_event_bus()
	if event_bus != null:
		event_bus.call("emit", "town_facility_demolished", {
			"facility_id": facility_id,
			"facility_type": facility_type,
			"level": level,
			"grid_x": grid_x,
			"grid_y": grid_y,
		})
		event_bus.call("emit", "town_grid_changed", {
			"action": "demolished",
			"facility_id": facility_id,
			"grid_x": grid_x,
			"grid_y": grid_y,
		})
	return {"success": true, "error": "", "facility_id": facility_id}


## Returns the active training-ground efficiency multiplier, or 1.0 when absent/inactive.
func compute_training_efficiency_multiplier() -> float:
	var training_ground: Facility = _get_active_facility_by_type(Facility.FacilityType.TRAINING_GROUND)
	if training_ground == null:
		return 1.0
	return 1.0 + _resolve_town_config().get_training_ground_bonus_delta() * float(training_ground.get_level())


## Returns the stadium home-advantage bonus including the training-ground adjacency pair.
func compute_home_advantage_bonus() -> float:
	var stadium: Facility = _get_active_facility_by_type(Facility.FacilityType.STADIUM)
	if stadium == null:
		return 0.0
	var town_config: TownConfigType = _resolve_town_config()
	var base_bonus: float = clampf(town_config.get_home_advantage_per_level() * float(stadium.get_level()), 0.0, 10.0)
	var adjacency_bonus: float = _compute_adj_stadium_home_bonus(stadium)
	return clampf(base_bonus + adjacency_bonus, 0.0, 15.0)


## Returns the stadium revenue multiplier, or 1.0 when no active stadium exists.
func compute_stadium_revenue_multiplier() -> float:
	var stadium: Facility = _get_active_facility_by_type(Facility.FacilityType.STADIUM)
	if stadium == null:
		return 1.0
	return clampf(1.0 + _resolve_town_config().get_stadium_revenue_per_level() * float(stadium.get_level()), 1.0, 1.4)


## Returns the combined facility AP bonus from the medical room and training adjacency.
func compute_facility_ap_bonus() -> int:
	var medical_room: Facility = _get_active_facility_by_type(Facility.FacilityType.MEDICAL_ROOM)
	if medical_room == null:
		return 0
	var town_config: TownConfigType = _resolve_town_config()
	var medical_level: int = medical_room.get_level()
	var medical_ap_bonus: int = clampi(int(floorf(float(medical_level) * town_config.get_medical_ap_bonus_per_level())), 1, 3)
	return clampi(medical_ap_bonus + _compute_adj_med_ap_bonus(medical_room), 0, 3)


## Returns the medical-room injury recovery reduction in whole turns.
func compute_injury_recovery_reduction() -> int:
	var medical_room: Facility = _get_active_facility_by_type(Facility.FacilityType.MEDICAL_ROOM)
	if medical_room == null:
		return 0
	return clampi(int(floorf(float(medical_room.get_level()) * _resolve_town_config().get_injury_recovery_per_level())), 1, 2)


## Returns the youth-academy potential floor boost including training adjacency.
func compute_potential_floor_boost() -> int:
	var youth_academy: Facility = _get_active_facility_by_type(Facility.FacilityType.YOUTH_ACADEMY)
	if youth_academy == null:
		return 0
	var town_config: TownConfigType = _resolve_town_config()
	var base_boost: int = clampi(int(floorf(float(youth_academy.get_level()) * town_config.get_youth_potential_floor_per_level())), 0, 5)
	return clampi(base_boost + _compute_adj_youth_potential_boost(youth_academy), 0, 5)


## Returns the youth-academy training bonus for players at or below the configured youth age threshold.
func compute_youth_training_bonus(player_age: int) -> float:
	var youth_academy: Facility = _get_active_facility_by_type(Facility.FacilityType.YOUTH_ACADEMY)
	if youth_academy == null:
		return 1.0
	var town_config: TownConfigType = _resolve_town_config()
	if player_age > town_config.get_youth_age_threshold():
		return 1.0
	return clampf(1.0 + town_config.get_youth_growth_per_level() * float(youth_academy.get_level()), 1.0, 1.2)


## Returns the combined facility training multiplier for one player age.
func compute_facility_training_multiplier(player_age: int) -> float:
	return compute_training_efficiency_multiplier() * compute_youth_training_bonus(player_age) * _compute_adj_tr_youth_multiplier()


## Returns the total daily facility maintenance cost for all eligible facilities.
func compute_facility_total_maintenance() -> int:
	var total_maintenance_cost: int = 0
	var town_config: TownConfigType = _resolve_town_config()
	for facility: Facility in _facility_by_id.values():
		if facility.get_level() <= 0:
			continue
		if facility.get_state() != Facility.FacilityState.ACTIVE:
			continue
		var facility_type: int = facility.get_facility_type()
		total_maintenance_cost += town_config.get_facility_maintenance_base(facility_type)
		total_maintenance_cost += town_config.get_facility_maintenance_delta(facility_type) * (facility.get_level() - 1)
	return total_maintenance_cost


## Returns the daily AP bonus contributed by the eligible medical room and training-ground adjacency.
func get_daily_action_points_bonus() -> int:
	return compute_facility_ap_bonus()


## Returns the total daily facility maintenance cost for all eligible facilities.
func get_daily_maintenance_cost() -> int:
	return compute_facility_total_maintenance()


## Registers this system with SaveManager using the town persistence contract.
func register_with_save_manager(save_manager: Node) -> bool:
	if save_manager == null:
		return false
	return save_manager.register_system("town", Callable(self, "serialize"), Callable(self, "deserialize"))


## Computes construction funds cost for a facility type and target level.
func compute_construction_funds_cost(facility_type: int, target_level: int) -> Dictionary[String, Variant]:
	return _compute_formula_value(facility_type, target_level, _resolve_town_config().get_base_funds_cost(facility_type), _resolve_town_config().cost_multiplier, "invalid_target_level")

## Computes upgrade funds cost for a facility type and target level.
func compute_upgrade_funds_cost(facility_type: int, target_level: int) -> Dictionary[String, Variant]:
	return _compute_formula_value(facility_type, target_level, _resolve_town_config().get_base_funds_cost(facility_type), _resolve_town_config().cost_multiplier, "invalid_target_level")

## Computes construction time cost for a facility type and target level.
func compute_construction_time_cost(facility_type: int, target_level: int) -> Dictionary[String, Variant]:
	return _compute_formula_value(facility_type, target_level, _resolve_town_config().get_base_construction_time(facility_type), _resolve_town_config().time_multiplier, "invalid_target_level")

## Computes upgrade time cost for a facility type and target level.
func compute_upgrade_time_cost(facility_type: int, target_level: int) -> Dictionary[String, Variant]:
	return _compute_formula_value(facility_type, target_level, _resolve_town_config().get_base_upgrade_time(facility_type), _resolve_town_config().time_multiplier, "invalid_target_level")


## Returns the facility occupying a grid cell, or null when none is present.
func get_facility_at(grid_x: int, grid_y: int) -> Facility:
	if not _is_in_bounds(grid_x, grid_y):
		return null
	var facility: Facility = _grid[get_cell_index(grid_x, grid_y)]
	if facility == null:
		return null
	return facility.duplicate_for_query()


## Returns a facility by id, or null when it is not registered.
func get_facility(facility_id: int) -> Facility:
	var facility: Facility = _facility_by_id.get(facility_id, null)
	if facility == null:
		return null
	return facility.duplicate_for_query()


## Registers a facility in the authoritative grid.
func register_facility(facility: Facility) -> bool:
	if facility == null:
		return false
	if not facility.is_valid():
		return false
	if not _is_in_bounds(facility.get_grid_x(), facility.get_grid_y()):
		return false
	var cell_index: int = get_cell_index(facility.get_grid_x(), facility.get_grid_y())
	if _grid[cell_index] != null:
		return false
	_grid[cell_index] = facility
	_facility_by_id[facility.get_id()] = facility
	_next_facility_id = maxi(_next_facility_id, facility.get_id() + 1)
	return true


func _initialize_grid() -> void:
	_grid = []
	_grid.resize(_grid_width * _grid_height)
	_facility_by_id.clear()
	_next_facility_id = 1


func _on_time_phase_changed(_event_name: String, _payload: Dictionary) -> void:
	var completed_facilities: Array[Facility] = []
	for facility: Facility in _facility_by_id.values():
		if facility.get_state() != Facility.FacilityState.CONSTRUCTING and facility.get_state() != Facility.FacilityState.UPGRADING:
			continue
		facility._set_remaining_construction_units(facility.get_remaining_construction_units() - 1)
		if facility.get_remaining_construction_units() <= 0:
			completed_facilities.append(facility)
	for facility: Facility in completed_facilities:
		_complete_facility_progress(facility)


func _complete_facility_progress(facility: Facility) -> void:
	var was_constructing: bool = facility.get_state() == Facility.FacilityState.CONSTRUCTING
	facility._set_state(Facility.FacilityState.ACTIVE)
	if was_constructing:
		facility._set_level(1)
	else:
		facility._set_level(facility.get_level() + 1)
	facility._set_remaining_construction_units(0)
	var event_bus: Node = _get_event_bus()
	if event_bus != null:
		event_bus.call("emit", "town_facility_completed", {
			"facility_id": facility.get_id(),
			"facility_type": facility.get_facility_type(),
			"level": facility.get_level(),
			"grid_x": facility.get_grid_x(),
			"grid_y": facility.get_grid_y(),
		})


func _is_in_bounds(grid_x: int, grid_y: int) -> bool:
	return grid_x >= 0 and grid_x < _grid_width and grid_y >= 0 and grid_y < _grid_height

func _has_facility_type(facility_type: int) -> bool:
	for facility: Facility in _facility_by_id.values():
		if facility.get_facility_type() == facility_type:
			return true
	return false

func _get_active_facility_by_type(facility_type: int) -> Facility:
	for facility: Facility in _facility_by_id.values():
		if facility.get_facility_type() != facility_type:
			continue
		if facility.get_state() != Facility.FacilityState.ACTIVE and facility.get_state() != Facility.FacilityState.UPGRADING:
			continue
		return facility
	return null

func _get_highest_adjacent_level(facility: Facility, adjacent_type: int) -> int:
	var highest_level: int = 0
	for adjacent_facility: Facility in _get_adjacent_active_facilities(facility, adjacent_type):
		highest_level = maxi(highest_level, adjacent_facility.get_level())
	return highest_level

func _get_adjacent_active_facilities(facility: Facility, adjacent_type: int) -> Array[Facility]:
	var adjacent_facilities: Array[Facility] = []
	if facility == null:
		return adjacent_facilities
	for offset: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbor_x: int = facility.get_grid_x() + offset.x
		var neighbor_y: int = facility.get_grid_y() + offset.y
		if not _is_in_bounds(neighbor_x, neighbor_y):
			continue
		var adjacent_facility: Facility = _grid[get_cell_index(neighbor_x, neighbor_y)]
		if adjacent_facility == null:
			continue
		if adjacent_facility.get_facility_type() != adjacent_type:
			continue
		if adjacent_facility.get_state() != Facility.FacilityState.ACTIVE and adjacent_facility.get_state() != Facility.FacilityState.UPGRADING:
			continue
		adjacent_facilities.append(adjacent_facility)
	return adjacent_facilities

func _compute_adj_med_ap_bonus(medical_room: Facility) -> int:
	var adjacent_training_level: int = _get_highest_adjacent_level(medical_room, Facility.FacilityType.TRAINING_GROUND)
	var adjacency_level: int = mini(medical_room.get_level(), adjacent_training_level)
	if adjacency_level <= 0:
		return 0
	return clampi(int(floorf(_resolve_town_config().get_adj_med_tr_coeff() * float(adjacency_level))), 1, 2)

func _compute_adj_tr_youth_multiplier() -> float:
	var training_ground: Facility = _get_active_facility_by_type(Facility.FacilityType.TRAINING_GROUND)
	if training_ground == null:
		return 1.0
	var adjacent_youth_level: int = _get_highest_adjacent_level(training_ground, Facility.FacilityType.YOUTH_ACADEMY)
	if adjacent_youth_level <= 0:
		return 1.0
	var adjacency_level: int = mini(training_ground.get_level(), adjacent_youth_level)
	return 1.0 + _resolve_town_config().get_adj_tr_youth_coeff() * float(adjacency_level)

func _compute_adj_youth_potential_boost(youth_academy: Facility) -> int:
	var adjacent_training_level: int = _get_highest_adjacent_level(youth_academy, Facility.FacilityType.TRAINING_GROUND)
	var adjacency_level: int = mini(youth_academy.get_level(), adjacent_training_level)
	if adjacency_level <= 0:
		return 0
	return clampi(int(floorf(_resolve_town_config().get_adj_youth_tr_coeff() * float(adjacency_level))), 1, 2)

func _compute_adj_stadium_home_bonus(stadium: Facility) -> float:
	var adjacent_training_level: int = _get_highest_adjacent_level(stadium, Facility.FacilityType.TRAINING_GROUND)
	var adjacency_level: int = mini(stadium.get_level(), adjacent_training_level)
	if adjacency_level <= 0:
		return 0.0
	return clampf(_resolve_town_config().get_adj_stad_tr_coeff() * float(adjacency_level), 0.0, 5.0)

func _resolve_town_config() -> TownConfigType:
	if _town_config_override != null:
		return _town_config_override
	var config_loader := get_node_or_null("/root/ConfigLoader") as ConfigLoaderType
	assert(config_loader != null)
	assert(config_loader.town_config != null)
	return config_loader.town_config

func _resolve_economy_manager() -> EconomyManagerType:
	if _economy_manager_override != null:
		return _economy_manager_override
	var economy_manager := get_node_or_null("/root/EconomyManager") as EconomyManagerType
	assert(economy_manager != null)
	return economy_manager

func _get_event_bus() -> Node:
	if _event_bus_override != null:
		return _event_bus_override
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/EventBus")

func _compute_formula_value(facility_type: int, target_level: int, base_value: int, multiplier: float, invalid_level_error: String) -> Dictionary[String, Variant]:
	if not Facility.is_supported_facility_type(facility_type):
		return {"success": false, "error": "unsupported_facility_type", "value": null}
	if target_level < 1 or target_level > Facility.MAX_LEVEL:
		return {"success": false, "error": invalid_level_error, "value": null}
	var exponent: int = target_level - 1
	var raw_value: float = float(base_value) * pow(multiplier, exponent)
	return {"success": true, "error": "", "value": int(ceili(raw_value))}
