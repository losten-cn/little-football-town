class_name MatchConfig
extends Resource
## Data-driven match result tuning resource validated at startup.

@export var min_key_events: int = 3
@export var max_key_events: int = 15
@export var low_density_event_count: int = 3
@export var event_minute_start: int = 5
@export var event_minute_step: int = 7
@export var home_win_home_score: int = 2
@export var home_win_away_score: int = 1
@export var away_win_home_score: int = 1
@export var away_win_away_score: int = 2
@export var draw_home_score: int = 1
@export var draw_away_score: int = 1
@export var strength_gap_reason_threshold: float = 10.0
@export var morale_win_delta: float = 0.12
@export var morale_loss_delta: float = -0.10
@export var morale_draw_delta: float = 0.02
@export var condition_minutes_divisor: float = 180.0
@export var condition_floor: float = 0.45
@export var growth_tag_breakthrough_minutes: int = 75
@export var growth_tag_breakthrough_score: float = 8.5
@export var growth_tag_breakthrough_opponent_strength: float = 75.0
@export var growth_tag_significant_minutes: int = 60
@export var growth_tag_significant_score: float = 7.8
@export var growth_tag_regular_minutes: int = 30
@export var growth_tag_regular_score: float = 6.8
@export var growth_tag_light_minutes: int = 10
@export var growth_tag_none_minutes: int = 5
@export var default_chemistry_factor: float = 1.0
@export var chemistry_factor_min: float = 0.85
@export var chemistry_factor_max: float = 1.15
@export var out_of_position_penalty_multiplier: float = 0.85
@export var goalkeeper_lineup_weight: float = 0.9
@export var defender_lineup_weight: float = 0.95
@export var midfielder_lineup_weight: float = 1.0
@export var forward_lineup_weight: float = 1.0
@export var recommended_goalkeeper_count: int = 1
@export var recommended_defender_count: int = 4
@export var recommended_midfielder_count: int = 3
@export var recommended_forward_count: int = 3
@export var goalkeeper_attribute_weights: Array[float] = [0.05, 0.15, 0.10, 0.35, 0.35]
@export var defender_attribute_weights: Array[float] = [0.15, 0.25, 0.10, 0.20, 0.30]
@export var midfielder_attribute_weights: Array[float] = [0.20, 0.15, 0.25, 0.25, 0.15]
@export var forward_attribute_weights: Array[float] = [0.25, 0.20, 0.30, 0.10, 0.15]
@export var recommended_tactic_label: String = "balanced"
@export var recommended_tactical_match_mod: float = 0.0

## Returns whether this resource satisfies all match-result tuning ranges used by the current stories.
func validate() -> Dictionary[String, Variant]:
	var errors: Array[String] = []
	_add_minimum_error(errors, "min_key_events", min_key_events, 1)
	_add_minimum_error(errors, "max_key_events", max_key_events, min_key_events)
	_add_range_error(errors, "low_density_event_count", low_density_event_count, min_key_events, max_key_events)
	_add_minimum_error(errors, "event_minute_start", event_minute_start, 1)
	_add_minimum_error(errors, "event_minute_step", event_minute_step, 1)
	_add_minimum_error(errors, "strength_gap_reason_threshold", strength_gap_reason_threshold, 0.0)
	_add_score_relation_error(errors, "home_win", home_win_home_score, home_win_away_score, "greater")
	_add_score_relation_error(errors, "away_win", away_win_home_score, away_win_away_score, "less")
	_add_score_relation_error(errors, "draw", draw_home_score, draw_away_score, "equal")
	_add_range_error(errors, "morale_win_delta", morale_win_delta, -1.0, 1.0)
	_add_range_error(errors, "morale_loss_delta", morale_loss_delta, -1.0, 1.0)
	_add_range_error(errors, "morale_draw_delta", morale_draw_delta, -1.0, 1.0)
	_add_minimum_error(errors, "condition_minutes_divisor", condition_minutes_divisor, 1.0)
	_add_range_error(errors, "condition_floor", condition_floor, 0.0, 1.0)
	_add_minimum_error(errors, "growth_tag_none_minutes", growth_tag_none_minutes, 0)
	_add_minimum_error(errors, "growth_tag_light_minutes", growth_tag_light_minutes, growth_tag_none_minutes)
	_add_minimum_error(errors, "growth_tag_regular_minutes", growth_tag_regular_minutes, growth_tag_light_minutes)
	_add_minimum_error(errors, "growth_tag_significant_minutes", growth_tag_significant_minutes, growth_tag_regular_minutes)
	_add_minimum_error(errors, "growth_tag_breakthrough_minutes", growth_tag_breakthrough_minutes, growth_tag_significant_minutes)
	_add_range_error(errors, "growth_tag_regular_score", growth_tag_regular_score, 1.0, 10.0)
	_add_range_error(errors, "growth_tag_significant_score", growth_tag_significant_score, growth_tag_regular_score, 10.0)
	_add_range_error(errors, "growth_tag_breakthrough_score", growth_tag_breakthrough_score, growth_tag_significant_score, 10.0)
	_add_minimum_error(errors, "growth_tag_breakthrough_opponent_strength", growth_tag_breakthrough_opponent_strength, 0.0)
	_add_range_error(errors, "default_chemistry_factor", default_chemistry_factor, chemistry_factor_min, chemistry_factor_max)
	_add_range_error(errors, "chemistry_factor_min", chemistry_factor_min, 0.50, chemistry_factor_max)
	_add_range_error(errors, "chemistry_factor_max", chemistry_factor_max, chemistry_factor_min, 1.50)
	_add_range_error(errors, "out_of_position_penalty_multiplier", out_of_position_penalty_multiplier, 0.50, 1.0)
	_add_range_error(errors, "goalkeeper_lineup_weight", goalkeeper_lineup_weight, 0.1, 1.0)
	_add_range_error(errors, "defender_lineup_weight", defender_lineup_weight, 0.1, 1.0)
	_add_range_error(errors, "midfielder_lineup_weight", midfielder_lineup_weight, 0.1, 1.0)
	_add_range_error(errors, "forward_lineup_weight", forward_lineup_weight, 0.1, 1.0)
	_add_minimum_error(errors, "recommended_goalkeeper_count", recommended_goalkeeper_count, 1)
	_add_minimum_error(errors, "recommended_defender_count", recommended_defender_count, 0)
	_add_minimum_error(errors, "recommended_midfielder_count", recommended_midfielder_count, 0)
	_add_minimum_error(errors, "recommended_forward_count", recommended_forward_count, 0)
	if recommended_goalkeeper_count + recommended_defender_count + recommended_midfielder_count + recommended_forward_count != 11:
		errors.append("recommended lineup counts must sum to 11")
	_validate_weight_array(errors, "goalkeeper_attribute_weights", goalkeeper_attribute_weights)
	_validate_weight_array(errors, "defender_attribute_weights", defender_attribute_weights)
	_validate_weight_array(errors, "midfielder_attribute_weights", midfielder_attribute_weights)
	_validate_weight_array(errors, "forward_attribute_weights", forward_attribute_weights)
	return {"valid": errors.is_empty(), "errors": errors}

func _add_minimum_error(errors: Array[String], field_name: String, value: float, minimum: float) -> void:
	if is_nan(value) or is_inf(value) or value < minimum:
		errors.append("%s %s below minimum %s" % [field_name, str(value), str(minimum)])

func _add_range_error(errors: Array[String], field_name: String, value: float, minimum: float, maximum: float) -> void:
	if is_nan(value) or is_inf(value) or value < minimum or value > maximum:
		errors.append("%s %s outside [%s, %s]" % [field_name, str(value), str(minimum), str(maximum)])

func _add_score_relation_error(errors: Array[String], result_name: String, home_score: int, away_score: int, relation: String) -> void:
	if relation == "greater" and home_score <= away_score:
		errors.append("%s score must keep home > away" % result_name)
	elif relation == "less" and away_score <= home_score:
		errors.append("%s score must keep away > home" % result_name)
	elif relation == "equal" and home_score != away_score:
		errors.append("%s score must keep home == away" % result_name)


func _validate_weight_array(errors: Array[String], field_name: String, weights: Array[float]) -> void:
	if weights.size() != 5:
		errors.append("%s must contain exactly 5 weights" % field_name)
		return
	var total_weight: float = 0.0
	for weight: float in weights:
		if is_nan(weight) or is_inf(weight) or weight < 0.0:
			errors.append("%s contains invalid weight %s" % [field_name, str(weight)])
			return
		total_weight += weight
	if not is_equal_approx(total_weight, 1.0):
		errors.append("%s must sum to 1.0" % field_name)
