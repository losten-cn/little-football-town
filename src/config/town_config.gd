class_name TownConfig
extends Resource
## Data-driven town-building tuning resource validated at startup.

const MIN_LEVEL: int = 1
const MAX_LEVEL: int = 5
const MIN_COST_MULTIPLIER: float = 1.5
const MAX_COST_MULTIPLIER: float = 2.0
const MIN_TIME_MULTIPLIER: float = 1.2
const MAX_TIME_MULTIPLIER: float = 1.5
const MIN_BASE_FUNDS_COST: int = 100
const MAX_BASE_FUNDS_COST: int = 650
const MIN_BASE_CONSTRUCTION_TIME: int = 2
const MAX_BASE_CONSTRUCTION_TIME: int = 10
const MIN_BASE_UPGRADE_TIME: int = 1
const MAX_BASE_UPGRADE_TIME: int = 6
const MIN_TRAINING_GROUND_BONUS_DELTA: float = 0.03
const MAX_TRAINING_GROUND_BONUS_DELTA: float = 0.07
const MIN_MEDICAL_AP_BONUS_PER_LEVEL: float = 0.5
const MAX_MEDICAL_AP_BONUS_PER_LEVEL: float = 0.9
const MIN_INJURY_RECOVERY_PER_LEVEL: float = 0.5
const MAX_INJURY_RECOVERY_PER_LEVEL: float = 0.8
const MIN_YOUTH_POTENTIAL_FLOOR_PER_LEVEL: float = 0.5
const MAX_YOUTH_POTENTIAL_FLOOR_PER_LEVEL: float = 1.5
const MIN_YOUTH_GROWTH_PER_LEVEL: float = 0.02
const MAX_YOUTH_GROWTH_PER_LEVEL: float = 0.06
const MIN_YOUTH_AGE_THRESHOLD: int = 20
const MAX_YOUTH_AGE_THRESHOLD: int = 24
const MIN_ADJ_TR_MED_COEFF: float = 0.03
const MAX_ADJ_TR_MED_COEFF: float = 0.08
const MIN_ADJ_MED_TR_COEFF: float = 0.4
const MAX_ADJ_MED_TR_COEFF: float = 0.8
const MIN_ADJ_TR_YOUTH_COEFF: float = 0.02
const MAX_ADJ_TR_YOUTH_COEFF: float = 0.05
const MIN_ADJ_YOUTH_TR_COEFF: float = 0.4
const MAX_ADJ_YOUTH_TR_COEFF: float = 0.8
const MIN_HOME_ADVANTAGE_PER_LEVEL: float = 1.0
const MAX_HOME_ADVANTAGE_PER_LEVEL: float = 2.5
const MIN_STADIUM_REVENUE_PER_LEVEL: float = 0.05
const MAX_STADIUM_REVENUE_PER_LEVEL: float = 0.12
const MIN_ADJ_STAD_TR_COEFF: float = 0.5
const MAX_ADJ_STAD_TR_COEFF: float = 1.5
const MIN_FACILITY_MAINTENANCE_BASE: int = 2
const MAX_FACILITY_MAINTENANCE_BASE: int = 4
const MIN_FACILITY_MAINTENANCE_DELTA: int = 1
const MAX_FACILITY_MAINTENANCE_DELTA: int = 2

@export var base_funds_cost: Dictionary[int, int] = {
	Facility.FacilityType.TRAINING_GROUND: 200,
	Facility.FacilityType.MEDICAL_ROOM: 150,
	Facility.FacilityType.YOUTH_ACADEMY: 300,
	Facility.FacilityType.STADIUM: 500,
}
@export var base_construction_time: Dictionary[int, int] = {
	Facility.FacilityType.TRAINING_GROUND: 4,
	Facility.FacilityType.MEDICAL_ROOM: 3,
	Facility.FacilityType.YOUTH_ACADEMY: 6,
	Facility.FacilityType.STADIUM: 8,
}
@export var base_upgrade_time: Dictionary[int, int] = {
	Facility.FacilityType.TRAINING_GROUND: 3,
	Facility.FacilityType.MEDICAL_ROOM: 2,
	Facility.FacilityType.YOUTH_ACADEMY: 4,
	Facility.FacilityType.STADIUM: 5,
}
@export var cost_multiplier: float = 1.8
@export var time_multiplier: float = 1.3
@export var training_ground_bonus_delta: float = 0.05
@export var medical_ap_bonus_per_level: float = 0.7
@export var injury_recovery_per_level: float = 0.7
@export var youth_potential_floor_per_level: float = 1.0
@export var youth_growth_per_level: float = 0.04
@export var youth_age_threshold: int = 22
@export var adj_tr_med_coeff: float = 0.05
@export var adj_med_tr_coeff: float = 0.6
@export var adj_tr_youth_coeff: float = 0.03
@export var adj_youth_tr_coeff: float = 0.6
@export var home_advantage_per_level: float = 2.0
@export var stadium_revenue_per_level: float = 0.08
@export var adj_stad_tr_coeff: float = 1.0
@export var facility_maintenance_base: Dictionary[int, int] = {
	Facility.FacilityType.TRAINING_GROUND: 2,
	Facility.FacilityType.MEDICAL_ROOM: 2,
	Facility.FacilityType.YOUTH_ACADEMY: 3,
	Facility.FacilityType.STADIUM: 4,
}
@export var facility_maintenance_delta: Dictionary[int, int] = {
	Facility.FacilityType.TRAINING_GROUND: 1,
	Facility.FacilityType.MEDICAL_ROOM: 1,
	Facility.FacilityType.YOUTH_ACADEMY: 1,
	Facility.FacilityType.STADIUM: 2,
}

## Returns whether this resource satisfies all town formula safe ranges.
func validate() -> Dictionary[String, Variant]:
	var errors: Array[String] = []
	_add_range_error(errors, "cost_multiplier", cost_multiplier, MIN_COST_MULTIPLIER, MAX_COST_MULTIPLIER)
	_add_range_error(errors, "time_multiplier", time_multiplier, MIN_TIME_MULTIPLIER, MAX_TIME_MULTIPLIER)
	_add_range_error(errors, "training_ground_bonus_delta", training_ground_bonus_delta, MIN_TRAINING_GROUND_BONUS_DELTA, MAX_TRAINING_GROUND_BONUS_DELTA)
	_add_range_error(errors, "medical_ap_bonus_per_level", medical_ap_bonus_per_level, MIN_MEDICAL_AP_BONUS_PER_LEVEL, MAX_MEDICAL_AP_BONUS_PER_LEVEL)
	_add_range_error(errors, "injury_recovery_per_level", injury_recovery_per_level, MIN_INJURY_RECOVERY_PER_LEVEL, MAX_INJURY_RECOVERY_PER_LEVEL)
	_add_range_error(errors, "youth_potential_floor_per_level", youth_potential_floor_per_level, MIN_YOUTH_POTENTIAL_FLOOR_PER_LEVEL, MAX_YOUTH_POTENTIAL_FLOOR_PER_LEVEL)
	_add_range_error(errors, "youth_growth_per_level", youth_growth_per_level, MIN_YOUTH_GROWTH_PER_LEVEL, MAX_YOUTH_GROWTH_PER_LEVEL)
	_add_integer_range_error(errors, "youth_age_threshold", youth_age_threshold, MIN_YOUTH_AGE_THRESHOLD, MAX_YOUTH_AGE_THRESHOLD)
	_add_range_error(errors, "adj_tr_med_coeff", adj_tr_med_coeff, MIN_ADJ_TR_MED_COEFF, MAX_ADJ_TR_MED_COEFF)
	_add_range_error(errors, "adj_med_tr_coeff", adj_med_tr_coeff, MIN_ADJ_MED_TR_COEFF, MAX_ADJ_MED_TR_COEFF)
	_add_range_error(errors, "adj_tr_youth_coeff", adj_tr_youth_coeff, MIN_ADJ_TR_YOUTH_COEFF, MAX_ADJ_TR_YOUTH_COEFF)
	_add_range_error(errors, "adj_youth_tr_coeff", adj_youth_tr_coeff, MIN_ADJ_YOUTH_TR_COEFF, MAX_ADJ_YOUTH_TR_COEFF)
	_add_range_error(errors, "home_advantage_per_level", home_advantage_per_level, MIN_HOME_ADVANTAGE_PER_LEVEL, MAX_HOME_ADVANTAGE_PER_LEVEL)
	_add_range_error(errors, "stadium_revenue_per_level", stadium_revenue_per_level, MIN_STADIUM_REVENUE_PER_LEVEL, MAX_STADIUM_REVENUE_PER_LEVEL)
	_add_range_error(errors, "adj_stad_tr_coeff", adj_stad_tr_coeff, MIN_ADJ_STAD_TR_COEFF, MAX_ADJ_STAD_TR_COEFF)
	_validate_required_table(errors, "base_funds_cost", base_funds_cost, MIN_BASE_FUNDS_COST, MAX_BASE_FUNDS_COST)
	_validate_required_table(errors, "base_construction_time", base_construction_time, MIN_BASE_CONSTRUCTION_TIME, MAX_BASE_CONSTRUCTION_TIME)
	_validate_required_table(errors, "base_upgrade_time", base_upgrade_time, MIN_BASE_UPGRADE_TIME, MAX_BASE_UPGRADE_TIME)
	_validate_required_table(errors, "facility_maintenance_base", facility_maintenance_base, MIN_FACILITY_MAINTENANCE_BASE, MAX_FACILITY_MAINTENANCE_BASE)
	_validate_required_table(errors, "facility_maintenance_delta", facility_maintenance_delta, MIN_FACILITY_MAINTENANCE_DELTA, MAX_FACILITY_MAINTENANCE_DELTA)
	return {"valid": errors.is_empty(), "errors": errors}

## Returns the configured base funds cost for one facility type.
func get_base_funds_cost(facility_type: int) -> int:
	return int(base_funds_cost.get(facility_type, 0))

## Returns the configured base construction time for one facility type.
func get_base_construction_time(facility_type: int) -> int:
	return int(base_construction_time.get(facility_type, 0))

## Returns the configured base upgrade time for one facility type.
func get_base_upgrade_time(facility_type: int) -> int:
	return int(base_upgrade_time.get(facility_type, 0))

## Returns the configured per-level training efficiency delta.
func get_training_ground_bonus_delta() -> float:
	return training_ground_bonus_delta

## Returns the configured AP bonus coefficient used by active medical rooms.
func get_medical_ap_bonus_per_level() -> float:
	return medical_ap_bonus_per_level

## Returns the configured per-level injury recovery reduction coefficient.
func get_injury_recovery_per_level() -> float:
	return injury_recovery_per_level

## Returns the configured per-level youth potential floor coefficient.
func get_youth_potential_floor_per_level() -> float:
	return youth_potential_floor_per_level

## Returns the configured per-level youth growth coefficient.
func get_youth_growth_per_level() -> float:
	return youth_growth_per_level

## Returns the configured maximum age that counts as youth.
func get_youth_age_threshold() -> int:
	return youth_age_threshold

## Returns the configured training-ground to medical-room adjacency coefficient.
func get_adj_tr_med_coeff() -> float:
	return adj_tr_med_coeff

## Returns the configured medical-room to training-ground adjacency AP coefficient.
func get_adj_med_tr_coeff() -> float:
	return adj_med_tr_coeff

## Returns the configured training-ground to youth-academy adjacency coefficient.
func get_adj_tr_youth_coeff() -> float:
	return adj_tr_youth_coeff

## Returns the configured youth-academy to training-ground adjacency coefficient.
func get_adj_youth_tr_coeff() -> float:
	return adj_youth_tr_coeff

## Returns the configured per-level stadium home-advantage bonus.
func get_home_advantage_per_level() -> float:
	return home_advantage_per_level

## Returns the configured per-level stadium revenue multiplier delta.
func get_stadium_revenue_per_level() -> float:
	return stadium_revenue_per_level

## Returns the configured stadium-to-training adjacency coefficient.
func get_adj_stad_tr_coeff() -> float:
	return adj_stad_tr_coeff

## Returns the configured level-1 daily maintenance for one facility type.
func get_facility_maintenance_base(facility_type: int) -> int:
	return int(facility_maintenance_base.get(facility_type, 0))

## Returns the configured per-level maintenance delta for one facility type.
func get_facility_maintenance_delta(facility_type: int) -> int:
	return int(facility_maintenance_delta.get(facility_type, 0))

func _validate_required_table(errors: Array[String], field_name: String, values: Dictionary[int, int], minimum: int, maximum: int) -> void:
	for facility_type: int in [
		Facility.FacilityType.TRAINING_GROUND,
		Facility.FacilityType.MEDICAL_ROOM,
		Facility.FacilityType.YOUTH_ACADEMY,
		Facility.FacilityType.STADIUM,
	]:
		if not values.has(facility_type):
			errors.append("%s missing facility type %s" % [field_name, str(facility_type)])
			continue
		_add_integer_range_error(errors, "%s[%s]" % [field_name, str(facility_type)], int(values[facility_type]), minimum, maximum)

func _add_range_error(errors: Array[String], field_name: String, value: float, minimum: float, maximum: float) -> void:
	if is_nan(value) or is_inf(value) or value < minimum or value > maximum:
		errors.append("%s %s outside [%s, %s]" % [field_name, str(value), str(minimum), str(maximum)])

func _add_integer_range_error(errors: Array[String], field_name: String, value: int, minimum: int, maximum: int) -> void:
	if value < minimum or value > maximum:
		errors.append("%s %s outside [%s, %s]" % [field_name, str(value), str(minimum), str(maximum)])
