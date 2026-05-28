extends Node

const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")

var _failures: Array[String] = []

func _ready() -> void:
	test_balance_default_config_validates_successfully()
	test_balance_out_of_range_values_are_rejected()
	test_balance_boundary_values_are_accepted()
	test_balance_invalid_order_nan_inf_and_kpi_ranges_are_rejected()
	test_balance_formula_output_changes_when_config_changes()
	test_balance_formula_clamps_to_floor_and_ceiling()
	if _failures.is_empty():
		print("BALANCE_CONFIG_VALIDATION_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("BALANCE_CONFIG_VALIDATION_TEST_FAIL: %s" % failure)
		get_tree().quit(1)

func test_balance_default_config_validates_successfully() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var result: Dictionary[String, Variant] = config.validate()
	_expect(result["valid"] as bool, "default config should be valid")
	_expect((result["errors"] as Array[String]).is_empty(), "default config should not report validation errors")

func test_balance_out_of_range_values_are_rejected() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	config.flat_modifier_sum_budget_min = -11
	config.percent_modifier_sum_budget_max = 0.31
	config.decay_factor = 0.79
	config.potential_cap_span = 21
	config.rating_win_slope = 0.0061
	config.resource_buffer_multiplier = 1.99
	var result: Dictionary[String, Variant] = config.validate()
	var errors: Array[String] = result["errors"] as Array[String]
	_expect(not (result["valid"] as bool), "out-of-range config should be invalid")
	_expect(_contains_error(errors, "flat_modifier_sum_budget_min"), "flat modifier minimum validation error missing")
	_expect(_contains_error(errors, "percent_modifier_sum_budget_max"), "percent modifier maximum validation error missing")
	_expect(_contains_error(errors, "decay_factor"), "decay_factor validation error missing")
	_expect(_contains_error(errors, "potential_cap_span"), "potential_cap_span validation error missing")
	_expect(_contains_error(errors, "rating_win_slope"), "rating_win_slope validation error missing")
	_expect(_contains_error(errors, "resource_buffer_multiplier"), "resource_buffer_multiplier validation error missing")

func test_balance_boundary_values_are_accepted() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	config.decay_factor = 0.8
	config.potential_cap_span = 10
	config.rating_win_slope = 0.003
	config.resource_buffer_multiplier = 2.0
	config.win_probability_floor = 0.05
	config.win_probability_ceiling = 0.90
	_expect(config.validate()["valid"] as bool, "lower boundary values should pass")
	config.decay_factor = 1.8
	config.potential_cap_span = 20
	config.rating_win_slope = 0.006
	config.resource_buffer_multiplier = 4.0
	config.win_probability_floor = 0.10
	config.win_probability_ceiling = 0.95
	_expect(config.validate()["valid"] as bool, "upper boundary values should pass")

func test_balance_invalid_order_nan_inf_and_kpi_ranges_are_rejected() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	config.flat_modifier_sum_budget_min = 12
	config.flat_modifier_sum_budget_max = 11
	config.win_probability_floor = 0.96
	config.win_probability_ceiling = 0.94
	config.action_point_use_rate_target_min = NAN
	config.overall_win_rate_target_max = INF
	config.resource_efficiency_target_min = 1.3
	config.resource_efficiency_target_max = 1.2
	var result: Dictionary[String, Variant] = config.validate()
	var errors: Array[String] = result["errors"] as Array[String]
	_expect(not (result["valid"] as bool), "invalid order and non-finite values should be rejected")
	_expect(_contains_error(errors, "flat_modifier_sum_budget minimum"), "flat modifier ordering error missing")
	_expect(_contains_error(errors, "win_probability_floor"), "win probability floor range error missing")
	_expect(_contains_error(errors, "win_probability minimum"), "win probability ordering error missing")
	_expect(_contains_error(errors, "action_point_use_rate_target_min"), "action point target NaN error missing")
	_expect(_contains_error(errors, "overall_win_rate_target_max"), "overall win rate INF error missing")
	_expect(_contains_error(errors, "resource_efficiency_target minimum"), "resource efficiency ordering error missing")

func test_balance_formula_output_changes_when_config_changes() -> void:
	var low_slope: BalanceConfig = BalanceConfigScript.new()
	var high_slope: BalanceConfig = BalanceConfigScript.new()
	low_slope.rating_win_slope = 0.003
	high_slope.rating_win_slope = 0.006
	var low_probability: float = low_slope.compute_base_win_probability(60.0, 50.0)
	var high_probability: float = high_slope.compute_base_win_probability(60.0, 50.0)
	_expect(is_equal_approx(low_probability, 0.53), "low slope should produce 0.53 win probability")
	_expect(is_equal_approx(high_probability, 0.56), "high slope should produce 0.56 win probability")

func test_balance_formula_clamps_to_floor_and_ceiling() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	config.rating_win_slope = 0.006
	config.win_probability_floor = 0.10
	config.win_probability_ceiling = 0.90
	_expect(is_equal_approx(config.compute_base_win_probability(200.0, 0.0), 0.90), "win probability should clamp to ceiling")
	_expect(is_equal_approx(config.compute_base_win_probability(0.0, 200.0), 0.10), "win probability should clamp to floor")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _contains_error(errors: Array[String], field_name: String) -> bool:
	for error: String in errors:
		if error.contains(field_name):
			return true
	return false
