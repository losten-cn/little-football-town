extends SceneTree

const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	test_resource_settlement_applies_current_plus_gained_minus_spent()
	test_resource_settlement_clamps_to_lower_boundary()
	test_resource_settlement_clamps_to_upper_boundary()
	test_only_shared_resource_types_participate_in_shared_settlement()
	test_resource_buffer_multiplier_remains_config_backed()
	if _failures.is_empty():
		print("RESOURCE_SETTLEMENT_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("RESOURCE_SETTLEMENT_TEST_FAIL: %s" % failure)
		quit(1)

func test_resource_settlement_applies_current_plus_gained_minus_spent() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var result: float = config.compute_resource_settlement(100.0, 30.0, 20.0, 0.0, 200.0)
	_expect(is_equal_approx(result, 110.0), "resource settlement should equal current plus gained minus spent when the result stays inside bounds")
	var zero_gain_result: float = config.compute_resource_settlement(100.0, 0.0, 20.0, 0.0, 200.0)
	_expect(is_equal_approx(zero_gain_result, 80.0), "resource settlement should keep the same formula when gained_resource is zero")
	var zero_spend_result: float = config.compute_resource_settlement(100.0, 30.0, 0.0, 0.0, 200.0)
	_expect(is_equal_approx(zero_spend_result, 130.0), "resource settlement should keep the same formula when spent_resource is zero")

func test_resource_settlement_clamps_to_lower_boundary() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var result: float = config.compute_resource_settlement(10.0, 0.0, 50.0, 0.0, 200.0)
	_expect(is_equal_approx(result, 0.0), "resource settlement should clamp to resource_min when the raw result falls below the legal floor")
	var exact_floor_result: float = config.compute_resource_settlement(10.0, 0.0, 10.0, 0.0, 200.0)
	_expect(is_equal_approx(exact_floor_result, 0.0), "resource settlement should preserve the exact floor value without overshooting")

func test_resource_settlement_clamps_to_upper_boundary() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var result: float = config.compute_resource_settlement(190.0, 30.0, 0.0, 0.0, 200.0)
	_expect(is_equal_approx(result, 200.0), "resource settlement should clamp to resource_max when the raw result exceeds the legal ceiling")
	var exact_ceiling_result: float = config.compute_resource_settlement(170.0, 30.0, 0.0, 0.0, 200.0)
	_expect(is_equal_approx(exact_ceiling_result, 200.0), "resource settlement should preserve the exact ceiling value without overshooting")

func test_only_shared_resource_types_participate_in_shared_settlement() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	_expect(config.supports_shared_resource_settlement("funds"), "funds should participate in the shared settlement formula")
	_expect(config.supports_shared_resource_settlement("research"), "research should participate in the shared settlement formula")
	_expect(config.supports_shared_resource_settlement("action_points"), "action points should participate in the shared settlement formula")
	_expect(not config.supports_shared_resource_settlement("reputation"), "non-shared downstream resource types should stay outside the shared settlement formula")
	_expect(not config.supports_shared_resource_settlement(""), "empty resource type labels should not participate in shared settlement")

func test_resource_buffer_multiplier_remains_config_backed() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	_expect(is_equal_approx(config.resource_buffer_multiplier, 3.0), "resource buffer multiplier should keep the configured default value")
	var validation: Dictionary[String, Variant] = config.validate()
	_expect(validation["valid"] as bool, "default balance config should validate with the configured resource buffer multiplier range")
	config.resource_buffer_multiplier = 4.5
	var invalid_validation: Dictionary[String, Variant] = config.validate()
	_expect(not (invalid_validation["valid"] as bool), "resource buffer multiplier outside [2.0, 4.0] should fail validation")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
