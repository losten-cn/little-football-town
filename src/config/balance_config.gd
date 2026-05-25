class_name BalanceConfig
extends Resource
## Data-driven balance tuning resource validated at startup.

@export var flat_modifier_sum_budget_min: int = -10
@export var flat_modifier_sum_budget_max: int = 15
@export var percent_modifier_sum_budget_min: float = -0.20
@export var percent_modifier_sum_budget_max: float = 0.30
@export var resource_buffer_multiplier: float = 3.0
@export var decay_factor: float = 1.2
@export var potential_cap_span: int = 15
@export var rating_win_slope: float = 0.0045
@export var win_probability_floor: float = 0.05
@export var win_probability_ceiling: float = 0.95
@export var player_tier_potential_caps: Dictionary[String, Vector2i] = {
	"normal": Vector2i(60, 75),
	"excellent": Vector2i(72, 85),
	"star": Vector2i(82, 95),
	"legend_prospect": Vector2i(90, 99),
}
@export var player_tier_training_efficiency: Dictionary[String, Vector2] = {
	"normal": Vector2(0.8, 1.0),
	"excellent": Vector2(0.95, 1.2),
	"star": Vector2(1.1, 1.35),
	"legend_prospect": Vector2(1.25, 1.5),
}
@export var action_point_use_rate_target_min: float = 0.70
@export var action_point_use_rate_target_max: float = 0.90
@export var overall_win_rate_target_min: float = 0.55
@export var overall_win_rate_target_max: float = 0.65
@export var even_match_win_rate_target_min: float = 0.45
@export var even_match_win_rate_target_max: float = 0.55
@export var resource_efficiency_target_min: float = 0.80
@export var resource_efficiency_target_max: float = 1.20

## Returns whether this resource satisfies all balance safe ranges.
func validate() -> Dictionary[String, Variant]:
	var errors: Array[String] = []
	_add_range_error(errors, "flat_modifier_sum_budget_min", flat_modifier_sum_budget_min, -10.0, 15.0)
	_add_range_error(errors, "flat_modifier_sum_budget_max", flat_modifier_sum_budget_max, -10.0, 15.0)
	_add_order_error(errors, "flat_modifier_sum_budget", flat_modifier_sum_budget_min, flat_modifier_sum_budget_max)
	_add_range_error(errors, "percent_modifier_sum_budget_min", percent_modifier_sum_budget_min, -0.20, 0.30)
	_add_range_error(errors, "percent_modifier_sum_budget_max", percent_modifier_sum_budget_max, -0.20, 0.30)
	_add_order_error(errors, "percent_modifier_sum_budget", percent_modifier_sum_budget_min, percent_modifier_sum_budget_max)
	_add_range_error(errors, "resource_buffer_multiplier", resource_buffer_multiplier, 2.0, 4.0)
	_add_range_error(errors, "decay_factor", decay_factor, 0.8, 1.8)
	_add_range_error(errors, "potential_cap_span", potential_cap_span, 10.0, 20.0)
	_add_range_error(errors, "rating_win_slope", rating_win_slope, 0.003, 0.006)
	_add_range_error(errors, "win_probability_floor", win_probability_floor, 0.05, 0.10)
	_add_range_error(errors, "win_probability_ceiling", win_probability_ceiling, 0.90, 0.95)
	_add_order_error(errors, "win_probability", win_probability_floor, win_probability_ceiling)
	_validate_tier_ranges(errors)
	_validate_target_range(errors, "action_point_use_rate_target", action_point_use_rate_target_min, action_point_use_rate_target_max)
	_validate_target_range(errors, "overall_win_rate_target", overall_win_rate_target_min, overall_win_rate_target_max)
	_validate_target_range(errors, "even_match_win_rate_target", even_match_win_rate_target_min, even_match_win_rate_target_max)
	_validate_target_range(errors, "resource_efficiency_target", resource_efficiency_target_min, resource_efficiency_target_max)
	return {"valid": errors.is_empty(), "errors": errors}

## Computes the base win probability from rating difference using configured slope and clamps.
func compute_base_win_probability(home_strength: float, away_strength: float) -> float:
	var probability: float = 0.5 + rating_win_slope * (home_strength - away_strength)
	return clampf(probability, win_probability_floor, win_probability_ceiling)

func _add_range_error(errors: Array[String], field_name: String, value: float, minimum: float, maximum: float) -> void:
	if is_nan(value) or is_inf(value) or value < minimum or value > maximum:
		errors.append("%s %s outside [%s, %s]" % [field_name, str(value), str(minimum), str(maximum)])

func _add_order_error(errors: Array[String], field_name: String, minimum: float, maximum: float) -> void:
	if minimum > maximum:
		errors.append("%s minimum %s greater than maximum %s" % [field_name, str(minimum), str(maximum)])

func _validate_tier_ranges(errors: Array[String]) -> void:
	var required_tiers: Array[String] = ["normal", "excellent", "star", "legend_prospect"]
	for tier: String in required_tiers:
		if not player_tier_potential_caps.has(tier):
			errors.append("player_tier_potential_caps missing %s" % tier)
			continue
		if not player_tier_training_efficiency.has(tier):
			errors.append("player_tier_training_efficiency missing %s" % tier)
			continue
		var potential_cap: Vector2i = player_tier_potential_caps[tier]
		var efficiency: Vector2 = player_tier_training_efficiency[tier]
		_add_range_error(errors, "%s potential min" % tier, potential_cap.x, 1.0, 100.0)
		_add_range_error(errors, "%s potential max" % tier, potential_cap.y, 1.0, 100.0)
		_add_order_error(errors, "%s potential" % tier, potential_cap.x, potential_cap.y)
		_add_range_error(errors, "%s training efficiency min" % tier, efficiency.x, 0.5, 1.8)
		_add_range_error(errors, "%s training efficiency max" % tier, efficiency.y, 0.5, 1.8)
		_add_order_error(errors, "%s training efficiency" % tier, efficiency.x, efficiency.y)

func _validate_target_range(errors: Array[String], field_name: String, minimum: float, maximum: float) -> void:
	_add_range_error(errors, "%s_min" % field_name, minimum, 0.0, 2.0)
	_add_range_error(errors, "%s_max" % field_name, maximum, 0.0, 2.0)
	_add_order_error(errors, field_name, minimum, maximum)
