extends Node

const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")

var _failures: Array[String] = []

func _ready() -> void:
	test_effective_attribute_value_applies_flat_before_percent()
	test_effective_attribute_value_clamps_to_formula_bounds()
	test_effective_attribute_value_keeps_current_and_potential_separate()
	test_normalize_attribute_state_repairs_illegal_inputs()
	if _failures.is_empty():
		print("ATTRIBUTE_FORMULA_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("ATTRIBUTE_FORMULA_TEST_FAIL: %s" % failure)
		get_tree().quit(1)

func test_effective_attribute_value_applies_flat_before_percent() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var attribute_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(50.0, 80.0)
	var result: BalanceConfig.AttributeState = config.compute_effective_attribute_value(attribute_state, 10.0, 0.20)
	_expect(is_equal_approx(result.effective, 72.0), "effective value should apply flat modifiers before percent modifiers")

func test_effective_attribute_value_clamps_to_formula_bounds() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var low_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(5.0, 80.0)
	var low_result: BalanceConfig.AttributeState = config.compute_effective_attribute_value(low_state, -20.0, 0.0)
	_expect(is_equal_approx(low_result.effective, 1.0), "effective value should clamp to lower bound")
	var high_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(95.0, 100.0)
	var high_result: BalanceConfig.AttributeState = config.compute_effective_attribute_value(high_state, 15.0, 0.30)
	_expect(is_equal_approx(high_result.effective, 100.0), "effective value should clamp to upper bound")

func test_effective_attribute_value_keeps_current_and_potential_separate() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var attribute_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(60.0, 85.0)
	var result: BalanceConfig.AttributeState = config.compute_effective_attribute_value(attribute_state, 5.0, 0.10)
	_expect(is_equal_approx(result.current, 60.0), "current value should not be overwritten by effective calculation")
	_expect(is_equal_approx(result.potential, 85.0), "potential value should not be overwritten by effective calculation")
	_expect(is_equal_approx(attribute_state.current, 60.0), "source current value should remain unchanged")
	_expect(is_equal_approx(attribute_state.potential, 85.0), "source potential value should remain unchanged")

func test_normalize_attribute_state_repairs_illegal_inputs() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var invalid_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(120.0, 0.0)
	var normalized: BalanceConfig.AttributeState = config.normalize_attribute_state(invalid_state)
	_expect(is_equal_approx(normalized.current, 100.0), "current value should clamp into [1, 100]")
	_expect(is_equal_approx(normalized.potential, 100.0), "potential value should normalize to at least current and at most 100")
	var reversed_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(70.0, 60.0)
	var reversed_normalized: BalanceConfig.AttributeState = config.normalize_attribute_state(reversed_state)
	_expect(is_equal_approx(reversed_normalized.current, 70.0), "normalized current should preserve valid current input")
	_expect(is_equal_approx(reversed_normalized.potential, 70.0), "potential below current should normalize up to current")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
