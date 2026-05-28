class_name BalanceConfig
extends Resource
## Data-driven balance tuning resource validated at startup.

class AttributeState:
	var current: float
	var potential: float
	var effective: float

	func _init(current_value: float, potential_value: float, effective_value: float = 0.0) -> void:
		current = current_value
		potential = potential_value
		effective = effective_value

class AttributeWeights:
	var spd: float
	var pwr: float
	var tec: float
	var intelligence: float
	var sta: float

	func _init(spd_value: float, pwr_value: float, tec_value: float, intelligence_value: float, sta_value: float) -> void:
		spd = spd_value
		pwr = pwr_value
		tec = tec_value
		intelligence = intelligence_value
		sta = sta_value

class DiagnosticSample:
	var value: float
	var invalid_sample: bool

	func _init(sample_value: float, is_invalid_sample: bool) -> void:
		value = sample_value
		invalid_sample = is_invalid_sample

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
@export var player_training_session_milestones: Array[int] = [10, 25, 50]
@export var recent_growth_summary_limit: int = 5
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
	_validate_player_milestones(errors)
	_add_range_error(errors, "recent_growth_summary_limit", recent_growth_summary_limit, 1.0, 20.0)
	_validate_target_range(errors, "action_point_use_rate_target", action_point_use_rate_target_min, action_point_use_rate_target_max)
	_validate_target_range(errors, "overall_win_rate_target", overall_win_rate_target_min, overall_win_rate_target_max)
	_validate_target_range(errors, "even_match_win_rate_target", even_match_win_rate_target_min, even_match_win_rate_target_max)
	_validate_target_range(errors, "resource_efficiency_target", resource_efficiency_target_min, resource_efficiency_target_max)
	return {"valid": errors.is_empty(), "errors": errors}

## Computes normalized current/potential values and keeps effective temporary.
func normalize_attribute_state(attribute_state: AttributeState) -> AttributeState:
	var normalized_current: float = clampf(attribute_state.current, 1.0, 100.0)
	var normalized_potential: float = maxf(1.0, attribute_state.potential)
	if normalized_potential < normalized_current:
		normalized_potential = normalized_current
	if normalized_potential > 100.0:
		normalized_potential = 100.0
		normalized_current = minf(normalized_current, normalized_potential)
	return AttributeState.new(normalized_current, normalized_potential, attribute_state.effective)

## Computes effective attribute value by applying flat modifiers before percent modifiers.
func compute_effective_attribute_value(attribute_state: AttributeState, flat_modifier_sum: float, percent_modifier_sum: float) -> AttributeState:
	var normalized_state: AttributeState = normalize_attribute_state(attribute_state)
	var effective_value: float = clampf((normalized_state.current + flat_modifier_sum) * (1.0 + percent_modifier_sum), 1.0, 100.0)
	return AttributeState.new(normalized_state.current, normalized_state.potential, effective_value)

## Computes shared attribute growth from current value, potential cap, and decay factor.
func compute_attribute_growth(raw_growth_input: float, current_attribute: float, potential_cap: float, growth_decay_factor: float = decay_factor) -> float:
	var normalized_current: float = clampf(current_attribute, 0.0, 100.0)
	var normalized_potential: float = clampf(maxf(potential_cap, normalized_current), 1.0, 100.0)
	if normalized_current >= normalized_potential:
		return 0.0
	var growth_ratio: float = 1.0 - normalized_current / normalized_potential
	return raw_growth_input * pow(maxf(0.0, growth_ratio), growth_decay_factor)

## Computes the position-weighted overall rating from effective attributes.
func compute_positional_overall_rating(spd_effective: float, pwr_effective: float, tec_effective: float, intelligence_effective: float, sta_effective: float, attribute_weights: AttributeWeights) -> float:
	var normalized_weights: AttributeWeights = normalize_attribute_weights(attribute_weights)
	var weight_sum: float = _sum_attribute_weights(normalized_weights)
	if is_zero_approx(weight_sum):
		return clampf((clampf(spd_effective, 1.0, 100.0) + clampf(pwr_effective, 1.0, 100.0) + clampf(tec_effective, 1.0, 100.0) + clampf(intelligence_effective, 1.0, 100.0) + clampf(sta_effective, 1.0, 100.0)) / 5.0, 1.0, 100.0)
	var weighted_rating: float = clampf(spd_effective, 1.0, 100.0) * normalized_weights.spd
	weighted_rating += clampf(pwr_effective, 1.0, 100.0) * normalized_weights.pwr
	weighted_rating += clampf(tec_effective, 1.0, 100.0) * normalized_weights.tec
	weighted_rating += clampf(intelligence_effective, 1.0, 100.0) * normalized_weights.intelligence
	weighted_rating += clampf(sta_effective, 1.0, 100.0) * normalized_weights.sta
	return clampf(weighted_rating, 1.0, 100.0)

## Normalizes attribute weights by clamping negative values to zero and scaling positive totals to one.
func normalize_attribute_weights(attribute_weights: AttributeWeights) -> AttributeWeights:
	var normalized_spd: float = maxf(0.0, attribute_weights.spd)
	var normalized_pwr: float = maxf(0.0, attribute_weights.pwr)
	var normalized_tec: float = maxf(0.0, attribute_weights.tec)
	var normalized_intelligence: float = maxf(0.0, attribute_weights.intelligence)
	var normalized_sta: float = maxf(0.0, attribute_weights.sta)
	var total_weight: float = normalized_spd + normalized_pwr + normalized_tec + normalized_intelligence + normalized_sta
	if is_zero_approx(total_weight):
		return AttributeWeights.new(0.0, 0.0, 0.0, 0.0, 0.0)
	return AttributeWeights.new(
		normalized_spd / total_weight,
		normalized_pwr / total_weight,
		normalized_tec / total_weight,
		normalized_intelligence / total_weight,
		normalized_sta / total_weight
	)

## Returns whether the provided weights satisfy the locked-data invariant.
func are_locked_attribute_weights_valid(attribute_weights: AttributeWeights) -> bool:
	if attribute_weights.spd < 0.0 or attribute_weights.pwr < 0.0 or attribute_weights.tec < 0.0 or attribute_weights.intelligence < 0.0 or attribute_weights.sta < 0.0:
		return false
	return is_equal_approx(_sum_attribute_weights(attribute_weights), 1.0)

## Computes the base win probability from rating difference using configured slope and clamps.
func compute_base_win_probability(home_strength: float, away_strength: float) -> float:
	var probability: float = 0.5 + rating_win_slope * (home_strength - away_strength)
	return clampf(probability, win_probability_floor, win_probability_ceiling)

## Returns whether the resource type participates in shared settlement formulas.
func supports_shared_resource_settlement(resource_type: String) -> bool:
	return resource_type == "funds" or resource_type == "research" or resource_type == "action_points"

## Computes shared resource settlement inside the provided legal bounds.
func compute_resource_settlement(current_resource: float, gained_resource: float, spent_resource: float, resource_min: float, resource_max: float) -> float:
	return clampf(current_resource + gained_resource - spent_resource, resource_min, resource_max)

## Computes action point use rate and marks zero-denominator or invalid samples for review.
func compute_action_point_use_rate(action_points_spent: float, action_points_available: float) -> DiagnosticSample:
	if is_nan(action_points_spent) or is_inf(action_points_spent):
		return DiagnosticSample.new(0.0, true)
	if is_nan(action_points_available) or is_inf(action_points_available):
		return DiagnosticSample.new(0.0, true)
	var normalized_available: float = maxf(0.0, action_points_available)
	var normalized_spent: float = clampf(action_points_spent, 0.0, normalized_available)
	if is_zero_approx(normalized_available):
		return DiagnosticSample.new(0.0, true)
	return DiagnosticSample.new(normalized_spent / normalized_available, false)

## Computes overall win rate and marks zero-match samples invalid for review.
func compute_overall_win_rate(matches_won: int, matches_played: int) -> DiagnosticSample:
	var normalized_played: int = maxi(matches_played, 0)
	var normalized_won: int = clampi(matches_won, 0, normalized_played)
	if normalized_played == 0:
		return DiagnosticSample.new(0.0, true)
	return DiagnosticSample.new(float(normalized_won) / float(maxi(1, normalized_played)), false)

## Computes even-match win rate using only samples whose base probability stays inside the configured target window.
func compute_even_match_win_rate(base_probabilities: Array[float], did_win_samples: Array[bool]) -> DiagnosticSample:
	var even_matches_played: int = 0
	var even_matches_won: int = 0
	var sample_count: int = mini(base_probabilities.size(), did_win_samples.size())
	for sample_index: int in sample_count:
		var probability: float = base_probabilities[sample_index]
		if is_nan(probability) or is_inf(probability):
			continue
		if probability < even_match_win_rate_target_min or probability > even_match_win_rate_target_max:
			continue
		even_matches_played += 1
		if did_win_samples[sample_index]:
			even_matches_won += 1
	if even_matches_played == 0:
		return DiagnosticSample.new(0.0, true)
	return DiagnosticSample.new(float(even_matches_won) / float(maxi(1, even_matches_played)), false)

## Computes milestone completion time and marks incomplete or invalid timestamps as invalid samples.
func compute_milestone_completion_time(milestone_timestamp: float, save_start_timestamp: float, milestone_completed: bool) -> DiagnosticSample:
	if not milestone_completed:
		return DiagnosticSample.new(0.0, true)
	if is_nan(milestone_timestamp) or is_inf(milestone_timestamp):
		return DiagnosticSample.new(0.0, true)
	if is_nan(save_start_timestamp) or is_inf(save_start_timestamp):
		return DiagnosticSample.new(0.0, true)
	if milestone_timestamp < save_start_timestamp:
		return DiagnosticSample.new(0.0, true)
	return DiagnosticSample.new(milestone_timestamp - save_start_timestamp, false)

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

func _validate_player_milestones(errors: Array[String]) -> void:
	if player_training_session_milestones.is_empty():
		errors.append("player_training_session_milestones missing values")
		return
	var previous_threshold: int = 0
	for threshold: int in player_training_session_milestones:
		_add_range_error(errors, "player_training_session_milestones", threshold, 1.0, 999.0)
		if threshold <= previous_threshold:
			errors.append("player_training_session_milestones must be strictly ascending")
		previous_threshold = threshold

func _sum_attribute_weights(attribute_weights: AttributeWeights) -> float:
	return attribute_weights.spd + attribute_weights.pwr + attribute_weights.tec + attribute_weights.intelligence + attribute_weights.sta
