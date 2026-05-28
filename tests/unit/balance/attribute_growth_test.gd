extends SceneTree

const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	test_attribute_growth_stays_positive_and_close_to_raw_for_lower_current_values()
	test_attribute_growth_decays_as_current_attribute_approaches_potential_cap()
	test_attribute_growth_returns_zero_at_or_above_potential_cap()
	test_attribute_growth_normalizes_potential_cap_below_current()
	test_attribute_growth_uses_config_backed_decay_and_potential_span_defaults()
	if _failures.is_empty():
		print("ATTRIBUTE_GROWTH_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("ATTRIBUTE_GROWTH_TEST_FAIL: %s" % failure)
		quit(1)

func test_attribute_growth_stays_positive_and_close_to_raw_for_lower_current_values() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var result: float = config.compute_attribute_growth(10.0, 20.0, 80.0, 1.2)
	_expect(result > 0.0, "lower current attributes should still produce positive growth")
	_expect(result < 10.0, "growth below the cap should still decay below the raw growth input")
	_expect(result > 5.0, "lower current attributes should stay meaningfully close to raw growth input under the default decay curve")
	var zero_raw_result: float = config.compute_attribute_growth(0.0, 20.0, 80.0, 1.2)
	_expect(is_equal_approx(zero_raw_result, 0.0), "zero raw growth input should always produce zero growth")
	var zero_current_result: float = config.compute_attribute_growth(10.0, 0.0, 80.0, 1.2)
	_expect(zero_current_result > result, "a zero starting attribute should grow more than a higher starting attribute under the same inputs")

func test_attribute_growth_decays_as_current_attribute_approaches_potential_cap() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var mid_growth: float = config.compute_attribute_growth(10.0, 40.0, 80.0, 1.2)
	var near_cap_growth: float = config.compute_attribute_growth(10.0, 79.0, 80.0, 1.2)
	_expect(mid_growth > near_cap_growth, "growth should decay as current_attribute approaches potential_cap")
	_expect(near_cap_growth >= 0.0, "growth near the cap should never become negative")

func test_attribute_growth_returns_zero_at_or_above_potential_cap() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var at_cap_result: float = config.compute_attribute_growth(10.0, 80.0, 80.0, 1.2)
	_expect(is_equal_approx(at_cap_result, 0.0), "growth should return zero when current_attribute equals potential_cap")
	var above_cap_result: float = config.compute_attribute_growth(10.0, 81.0, 80.0, 1.2)
	_expect(is_equal_approx(above_cap_result, 0.0), "growth should return zero when current_attribute exceeds potential_cap")

func test_attribute_growth_normalizes_potential_cap_below_current() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var normalized_result: float = config.compute_attribute_growth(10.0, 70.0, 60.0, 1.2)
	_expect(is_equal_approx(normalized_result, 0.0), "potential caps below current should normalize up to current and preserve permanent growth as zero additional room")
	var clamped_result: float = config.compute_attribute_growth(10.0, 99.0, 140.0, 1.2)
	_expect(clamped_result >= 0.0, "potential caps above 100 should clamp into the legal attribute boundary without producing invalid growth")

func test_attribute_growth_uses_config_backed_decay_and_potential_span_defaults() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	_expect(is_equal_approx(config.decay_factor, 1.2), "decay_factor should keep the configured default value")
	_expect(config.potential_cap_span == 15, "potential_cap_span should keep the configured default value")
	var validation: Dictionary[String, Variant] = config.validate()
	_expect(validation["valid"] as bool, "default balance config should validate with the configured growth defaults")
	config.decay_factor = 2.0
	config.potential_cap_span = 25
	var invalid_validation: Dictionary[String, Variant] = config.validate()
	_expect(not (invalid_validation["valid"] as bool), "out-of-range decay_factor and potential_cap_span should fail validation")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
