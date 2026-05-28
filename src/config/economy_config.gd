class_name EconomyConfig
extends Resource
## Data-driven economy tuning resource validated at startup.

@export var action_points_floor: float = 1.0
@export var research_points_floor: float = 0.0
@export var funds_low_threshold: float = 100.0
@export var action_points_low_threshold: float = 2.0
@export var debt_warning_threshold: float = 0.0
@export var warning_cooldown_seconds: float = 60.0
@export var base_ap_recovery: float = 5.0
@export var base_rest_ap_recovery: float = 3.0
@export var action_points_max: float = 100.0
@export var base_maintenance_cost: float = 25.0
@export var ap_to_funds_weight: float = 50.0
@export var base_match_funds: float = 100.0
@export var match_result_win_multiplier: float = 1.5
@export var match_result_draw_multiplier: float = 1.0
@export var match_result_loss_multiplier: float = 0.7
@export var league_tier_multipliers: Dictionary[int, float] = {
	1: 1.0,
	2: 1.15,
	3: 1.3,
}
@export var tactical_rp_base: float = 15.0
@export var research_points_max: float = 999.0
@export var base_season_bonus: float = 1000.0
@export var base_season_research: float = 100.0
@export var season_ranking_multipliers: Dictionary[int, float] = {
	1: 1.5,
	2: 1.3,
	3: 1.2,
	4: 1.1,
	5: 1.0,
	6: 1.0,
	7: 0.9,
	8: 0.8,
	9: 0.7,
	10: 0.5,
}

## Returns whether this resource satisfies all economy safe ranges used by the current stories.
func validate() -> Dictionary[String, Variant]:
	var errors: Array[String] = []
	_add_minimum_error(errors, "action_points_floor", action_points_floor, 1.0)
	_add_minimum_error(errors, "research_points_floor", research_points_floor, 0.0)
	_add_finite_error(errors, "funds_low_threshold", funds_low_threshold)
	_add_finite_error(errors, "action_points_low_threshold", action_points_low_threshold)
	_add_finite_error(errors, "debt_warning_threshold", debt_warning_threshold)
	_add_minimum_error(errors, "warning_cooldown_seconds", warning_cooldown_seconds, 0.0)
	_add_minimum_error(errors, "base_ap_recovery", base_ap_recovery, 0.0)
	_add_minimum_error(errors, "base_rest_ap_recovery", base_rest_ap_recovery, 0.0)
	_add_minimum_error(errors, "action_points_max", action_points_max, 1.0)
	_add_minimum_error(errors, "base_maintenance_cost", base_maintenance_cost, 0.0)
	_add_range_error(errors, "ap_to_funds_weight", ap_to_funds_weight, 40.0, 60.0)
	_add_minimum_error(errors, "base_match_funds", base_match_funds, 0.0)
	_add_minimum_error(errors, "match_result_win_multiplier", match_result_win_multiplier, 0.0)
	_add_minimum_error(errors, "match_result_draw_multiplier", match_result_draw_multiplier, 0.0)
	_add_minimum_error(errors, "match_result_loss_multiplier", match_result_loss_multiplier, 0.0)
	_add_minimum_error(errors, "tactical_rp_base", tactical_rp_base, 0.0)
	_add_minimum_error(errors, "research_points_max", research_points_max, 0.0)
	_add_minimum_error(errors, "base_season_bonus", base_season_bonus, 0.0)
	_add_minimum_error(errors, "base_season_research", base_season_research, 0.0)
	_add_league_tier_multiplier_errors(errors)
	_add_season_ranking_multiplier_errors(errors)
	return {"valid": errors.is_empty(), "errors": errors}

func _add_minimum_error(errors: Array[String], field_name: String, value: float, minimum: float) -> void:
	if is_nan(value) or is_inf(value) or value < minimum:
		errors.append("%s %s below minimum %s" % [field_name, str(value), str(minimum)])

func _add_finite_error(errors: Array[String], field_name: String, value: float) -> void:
	if is_nan(value) or is_inf(value):
		errors.append("%s %s must be finite" % [field_name, str(value)])

func _add_range_error(errors: Array[String], field_name: String, value: float, minimum: float, maximum: float) -> void:
	if is_nan(value) or is_inf(value) or value < minimum or value > maximum:
		errors.append("%s %s outside range %s-%s" % [field_name, str(value), str(minimum), str(maximum)])

func _add_league_tier_multiplier_errors(errors: Array[String]) -> void:
	if league_tier_multipliers.is_empty():
		errors.append("league_tier_multipliers must not be empty")
		return
	for key_variant: Variant in league_tier_multipliers.keys():
		if not (key_variant is int):
			errors.append("league_tier_multipliers key %s must be int" % str(key_variant))
			continue
		var multiplier: float = float(league_tier_multipliers[key_variant])
		if is_nan(multiplier) or is_inf(multiplier) or multiplier < 0.0:
			errors.append("league_tier_multipliers[%s] %s below minimum 0" % [str(key_variant), str(multiplier)])

func _add_season_ranking_multiplier_errors(errors: Array[String]) -> void:
	if season_ranking_multipliers.is_empty():
		errors.append("season_ranking_multipliers must not be empty")
		return
	for key_variant: Variant in season_ranking_multipliers.keys():
		if not (key_variant is int):
			errors.append("season_ranking_multipliers key %s must be int" % str(key_variant))
			continue
		var multiplier: float = float(season_ranking_multipliers[key_variant])
		if is_nan(multiplier) or is_inf(multiplier) or multiplier < 0.0:
			errors.append("season_ranking_multipliers[%s] %s below minimum 0" % [str(key_variant), str(multiplier)])
