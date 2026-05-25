extends Node

const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")
const BALANCE_CONFIG_PATH: String = "res://config/balance_config.tres"

var _failures: Array[String] = []

func _ready() -> void:
	test_balance_default_config_validates_successfully()
	test_balance_out_of_range_values_are_rejected()
	test_balance_boundary_values_are_accepted()
	test_balance_resource_file_loads_and_matches_expected_values()
	test_balance_formula_output_changes_when_config_changes()
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
	config.decay_factor = 0.79
	config.potential_cap_span = 21
	config.rating_win_slope = 0.0061
	config.resource_buffer_multiplier = 1.99
	var result: Dictionary[String, Variant] = config.validate()
	var errors: Array[String] = result["errors"] as Array[String]
	_expect(not (result["valid"] as bool), "out-of-range config should be invalid")
	_expect(errors.size() >= 4, "out-of-range config should report every invalid field")
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
	_expect(config.validate()["valid"] as bool, "lower boundary values should pass")
	config.decay_factor = 1.8
	config.potential_cap_span = 20
	config.rating_win_slope = 0.006
	config.resource_buffer_multiplier = 4.0
	_expect(config.validate()["valid"] as bool, "upper boundary values should pass")

func test_balance_resource_file_loads_and_matches_expected_values() -> void:
	var loaded: Resource = ResourceLoader.load(BALANCE_CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	_expect(loaded is BalanceConfig, "default resource file should load as BalanceConfig")
	if not (loaded is BalanceConfig):
		return
	var config: BalanceConfig = loaded as BalanceConfig
	_expect(config.decay_factor == 1.2, "default decay_factor should be 1.2")
	_expect(config.potential_cap_span == 15, "default potential_cap_span should be 15")
	_expect(config.rating_win_slope == 0.0045, "default rating_win_slope should be 0.0045")
	_expect(config.resource_buffer_multiplier == 3.0, "default resource_buffer_multiplier should be 3.0")
	_expect(config.validate()["valid"] as bool, "default resource file should validate")

func test_balance_formula_output_changes_when_config_changes() -> void:
	var low_slope: BalanceConfig = BalanceConfigScript.new()
	var high_slope: BalanceConfig = BalanceConfigScript.new()
	low_slope.rating_win_slope = 0.003
	high_slope.rating_win_slope = 0.006
	var low_probability: float = low_slope.compute_base_win_probability(60.0, 50.0)
	var high_probability: float = high_slope.compute_base_win_probability(60.0, 50.0)
	_expect(is_equal_approx(low_probability, 0.53), "low slope should produce 0.53 win probability")
	_expect(is_equal_approx(high_probability, 0.56), "high slope should produce 0.56 win probability")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _contains_error(errors: Array[String], field_name: String) -> bool:
	for error: String in errors:
		if error.contains(field_name):
			return true
	return false
