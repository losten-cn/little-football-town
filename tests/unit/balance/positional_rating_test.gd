extends Node

const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")

var _failures: Array[String] = []

func _ready() -> void:
	test_positional_rating_matches_manual_weighted_sum()
	test_positional_rating_uses_effective_values_only()
	test_positional_rating_ignores_zero_weight_attribute()
	test_positional_rating_normalizes_invalid_weights_and_falls_back_when_all_zero()
	if _failures.is_empty():
		print("POSITIONAL_RATING_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("POSITIONAL_RATING_TEST_FAIL: %s" % failure)
		get_tree().quit(1)

func test_positional_rating_matches_manual_weighted_sum() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var weights: BalanceConfig.AttributeWeights = BalanceConfig.AttributeWeights.new(0.3, 0.2, 0.2, 0.1, 0.2)
	var result: float = config.compute_positional_overall_rating(80.0, 60.0, 70.0, 50.0, 90.0, weights)
	_expect(is_equal_approx(result, 73.0), "positional rating should match manual weighted sum")
	_expect(config.are_locked_attribute_weights_valid(weights), "locked weights summing to one should be valid")

func test_positional_rating_uses_effective_values_only() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var spd_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(20.0, 95.0, 80.0)
	var pwr_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(99.0, 99.0, 60.0)
	var tec_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(10.0, 90.0, 70.0)
	var int_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(100.0, 100.0, 50.0)
	var sta_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(1.0, 100.0, 90.0)
	var weights: BalanceConfig.AttributeWeights = BalanceConfig.AttributeWeights.new(0.3, 0.2, 0.2, 0.1, 0.2)
	var result: float = config.compute_positional_overall_rating(
		spd_state.effective,
		pwr_state.effective,
		tec_state.effective,
		int_state.effective,
		sta_state.effective,
		weights
	)
	_expect(is_equal_approx(result, 73.0), "positional rating should depend on effective values rather than current or potential")

func test_positional_rating_ignores_zero_weight_attribute() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var weights: BalanceConfig.AttributeWeights = BalanceConfig.AttributeWeights.new(0.5, 0.0, 0.25, 0.0, 0.25)
	var baseline: float = config.compute_positional_overall_rating(80.0, 10.0, 70.0, 20.0, 90.0, weights)
	var changed_pwr: float = config.compute_positional_overall_rating(80.0, 100.0, 70.0, 20.0, 90.0, weights)
	_expect(is_equal_approx(baseline, changed_pwr), "zero-weight attributes should not affect positional rating")

func test_positional_rating_normalizes_invalid_weights_and_falls_back_when_all_zero() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var invalid_weights: BalanceConfig.AttributeWeights = BalanceConfig.AttributeWeights.new(-0.5, 2.0, 1.0, 0.0, 0.0)
	var normalized: BalanceConfig.AttributeWeights = config.normalize_attribute_weights(invalid_weights)
	_expect(is_equal_approx(normalized.spd, 0.0), "negative weights should normalize to zero")
	_expect(is_equal_approx(normalized.pwr, 2.0 / 3.0), "positive weights should normalize proportionally")
	_expect(is_equal_approx(normalized.tec, 1.0 / 3.0), "positive weights should preserve relative contribution after normalization")
	_expect(not config.are_locked_attribute_weights_valid(invalid_weights), "invalid draft/tuned weights should fail locked-data validation")
	var zero_weights: BalanceConfig.AttributeWeights = BalanceConfig.AttributeWeights.new(0.0, 0.0, 0.0, 0.0, 0.0)
	var fallback_result: float = config.compute_positional_overall_rating(80.0, 60.0, 70.0, 50.0, 90.0, zero_weights)
	_expect(is_equal_approx(fallback_result, 70.0), "all-zero weights should fall back to arithmetic mean")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
