extends Node

const ConfigLoaderScript: Script = preload("res://src/autoload/config_loader.gd")
const BALANCE_CONFIG_PATH: String = "res://config/balance_config.tres"

var _failures: Array[String] = []

func _ready() -> void:
	test_balance_resource_file_loads_and_matches_expected_values()
	test_config_loader_loads_balance_config_from_resource_path()
	test_config_loader_reports_missing_file_errors()
	test_config_loader_rejects_invalid_loaded_resources()
	if _failures.is_empty():
		print("BALANCE_CONFIG_LOADER_INTEGRATION_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("BALANCE_CONFIG_LOADER_INTEGRATION_TEST_FAIL: %s" % failure)
		get_tree().quit(1)

func test_balance_resource_file_loads_and_matches_expected_values() -> void:
	var loader: Node = ConfigLoaderScript.new()
	var loaded_config: BalanceConfig = loader.load_balance_config_from_path(BALANCE_CONFIG_PATH) as BalanceConfig
	_expect(loaded_config != null, "default resource file should load through ConfigLoader")
	if loaded_config == null:
		return
	_expect(is_equal_approx(loaded_config.decay_factor, 1.2), "default decay_factor should be 1.2")
	_expect(loaded_config.potential_cap_span == 15, "default potential_cap_span should be 15")
	_expect(is_equal_approx(loaded_config.rating_win_slope, 0.0045), "default rating_win_slope should be 0.0045")
	_expect(is_equal_approx(loaded_config.resource_buffer_multiplier, 3.0), "default resource_buffer_multiplier should be 3.0")
	_expect(loader.last_errors.is_empty(), "successful load should not leave loader errors")

func test_config_loader_loads_balance_config_from_resource_path() -> void:
	var loader: Node = ConfigLoaderScript.new()
	var loaded_config: BalanceConfig = loader.load_balance_config_from_path(BALANCE_CONFIG_PATH) as BalanceConfig
	_expect(loaded_config is BalanceConfig, "ConfigLoader should return a typed BalanceConfig")
	_expect(loaded_config != null and loaded_config.validate()["valid"] as bool, "loaded resource should validate successfully")

func test_config_loader_reports_missing_file_errors() -> void:
	var loader: Node = ConfigLoaderScript.new()
	var loaded_config: BalanceConfig = loader.load_balance_config_from_path("res://config/missing_balance_config.tres") as BalanceConfig
	_expect(loaded_config == null, "missing resource path should fail to load")
	_expect(_contains_error(loader.last_errors, "config file missing"), "missing resource path should report a file missing error")

func test_config_loader_rejects_invalid_loaded_resources() -> void:
	var loader: Node = ConfigLoaderScript.new()
	var invalid_config: BalanceConfig = BalanceConfig.new()
	invalid_config.decay_factor = 0.79
	var loaded_config: BalanceConfig = loader.validate_balance_config_resource(invalid_config, BALANCE_CONFIG_PATH) as BalanceConfig
	_expect(loaded_config == null, "invalid balance config resource should be rejected")
	_expect(_contains_error(loader.last_errors, "decay_factor"), "invalid resource should expose the validation error details")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _contains_error(errors: Array[String], fragment: String) -> bool:
	for error: String in errors:
		if error.contains(fragment):
			return true
	return false
