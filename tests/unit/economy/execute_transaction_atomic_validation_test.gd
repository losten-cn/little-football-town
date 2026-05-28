extends SceneTree

const TransactionScript: Script = preload("res://src/core/transaction.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	test_execute_transaction_ap_floor_failure_leaves_balances_unchanged()
	test_execute_transaction_rp_floor_failure_leaves_balances_unchanged()
	test_execute_transaction_funds_may_enter_debt_when_other_floors_hold()
	test_execute_transaction_assigns_increasing_ids_only_to_successful_transactions()
	if _failures.is_empty():
		print("EXECUTE_TRANSACTION_ATOMIC_VALIDATION_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("EXECUTE_TRANSACTION_ATOMIC_VALIDATION_TEST_FAIL: %s" % failure)
		quit(1)

func test_execute_transaction_ap_floor_failure_leaves_balances_unchanged() -> void:
	# Arrange
	var manager: EconomyManager = EconomyManagerScript.new()
	manager.set_economy_config_for_testing(EconomyConfigScript.new())
	var valid_transaction: Transaction = TransactionScript.new()
	valid_transaction.funds_delta = 25.0
	valid_transaction.ap_delta = 1.0
	valid_transaction.rp_delta = 2.0
	valid_transaction.source_system = "test_suite"
	var invalid_transaction: Transaction = TransactionScript.new()
	invalid_transaction.ap_delta = -3.0
	invalid_transaction.source_system = "test_suite"
	var initial_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()

	# Act
	var valid_result: Dictionary[String, Variant] = manager.execute_transaction(valid_transaction)
	var after_valid_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var invalid_result: Dictionary[String, Variant] = manager.execute_transaction(invalid_transaction)
	var after_invalid_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()

	# Assert
	_expect(initial_snapshot["action_points"] == 1.0, "initial action_points should start at the configured floor")
	_expect(valid_result["success"] as bool, "valid transaction should succeed before invalid transaction runs")
	_expect(is_equal_approx(float(after_valid_snapshot["funds"]), 25.0), "valid transaction should apply funds completely")
	_expect(is_equal_approx(float(after_valid_snapshot["action_points"]), 2.0), "valid transaction should apply action_points completely")
	_expect(is_equal_approx(float(after_valid_snapshot["research_points"]), 2.0), "valid transaction should apply research_points completely")
	_expect(not (invalid_result["success"] as bool), "ap floor violation should fail validation")
	_expect(String(invalid_result["error"]) == "ap_below_floor", "ap floor violation should report ap_below_floor")
	_expect(is_equal_approx(float(after_invalid_snapshot["funds"]), float(after_valid_snapshot["funds"])), "failed ap transaction should not change funds")
	_expect(is_equal_approx(float(after_invalid_snapshot["action_points"]), float(after_valid_snapshot["action_points"])), "failed ap transaction should not change action_points")
	_expect(is_equal_approx(float(after_invalid_snapshot["research_points"]), float(after_valid_snapshot["research_points"])), "failed ap transaction should not change research_points")
	_expect(manager.get_transaction_log().size() == 1, "failed ap transaction should not create an audit record")

func test_execute_transaction_rp_floor_failure_leaves_balances_unchanged() -> void:
	# Arrange
	var manager: EconomyManager = EconomyManagerScript.new()
	manager.set_economy_config_for_testing(EconomyConfigScript.new())
	var valid_transaction: Transaction = TransactionScript.new()
	valid_transaction.rp_delta = 1.0
	valid_transaction.source_system = "test_suite"
	var invalid_transaction: Transaction = TransactionScript.new()
	invalid_transaction.rp_delta = -2.0
	invalid_transaction.source_system = "test_suite"

	# Act
	var valid_result: Dictionary[String, Variant] = manager.execute_transaction(valid_transaction)
	var after_valid_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var invalid_result: Dictionary[String, Variant] = manager.execute_transaction(invalid_transaction)
	var after_invalid_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()

	# Assert
	_expect(valid_result["success"] as bool, "setup transaction for rp floor test should succeed")
	_expect(is_equal_approx(float(after_valid_snapshot["research_points"]), 1.0), "setup transaction should raise research_points to 1.0")
	_expect(not (invalid_result["success"] as bool), "rp floor violation should fail validation")
	_expect(String(invalid_result["error"]) == "rp_below_floor", "rp floor violation should report rp_below_floor")
	_expect(is_equal_approx(float(after_invalid_snapshot["funds"]), float(after_valid_snapshot["funds"])), "failed rp transaction should not change funds")
	_expect(is_equal_approx(float(after_invalid_snapshot["action_points"]), float(after_valid_snapshot["action_points"])), "failed rp transaction should not change action_points")
	_expect(is_equal_approx(float(after_invalid_snapshot["research_points"]), float(after_valid_snapshot["research_points"])), "failed rp transaction should not change research_points")
	_expect(manager.get_transaction_log().size() == 1, "failed rp transaction should not create an audit record")

func test_execute_transaction_funds_may_enter_debt_when_other_floors_hold() -> void:
	# Arrange
	var manager: EconomyManager = EconomyManagerScript.new()
	manager.set_economy_config_for_testing(EconomyConfigScript.new())
	var debt_transaction: Transaction = TransactionScript.new()
	debt_transaction.funds_delta = -50.0
	debt_transaction.source_system = "test_suite"

	# Act
	var result: Dictionary[String, Variant] = manager.execute_transaction(debt_transaction)
	var snapshot: Dictionary[String, float] = manager.get_balance_snapshot()

	# Assert
	_expect(result["success"] as bool, "funds should be allowed to enter debt when floors still hold")
	_expect(is_equal_approx(float(snapshot["funds"]), -50.0), "funds should be allowed to go negative")
	_expect(is_equal_approx(float(snapshot["action_points"]), 1.0), "funds debt transaction should not change action_points")
	_expect(is_equal_approx(float(snapshot["research_points"]), 0.0), "funds debt transaction should not change research_points")
	_expect(manager.get_transaction_log().size() == 1, "successful debt transaction should create an audit record")

func test_execute_transaction_assigns_increasing_ids_only_to_successful_transactions() -> void:
	# Arrange
	var manager: EconomyManager = EconomyManagerScript.new()
	manager.set_economy_config_for_testing(EconomyConfigScript.new())
	var first_transaction: Transaction = TransactionScript.new()
	first_transaction.funds_delta = 10.0
	first_transaction.source_system = "test_suite"
	var failed_transaction: Transaction = TransactionScript.new()
	failed_transaction.ap_delta = -2.0
	failed_transaction.source_system = "test_suite"
	var second_transaction: Transaction = TransactionScript.new()
	second_transaction.rp_delta = 1.0
	second_transaction.source_system = "test_suite"

	# Act
	var first_result: Dictionary[String, Variant] = manager.execute_transaction(first_transaction)
	var failed_result: Dictionary[String, Variant] = manager.execute_transaction(failed_transaction)
	var second_result: Dictionary[String, Variant] = manager.execute_transaction(second_transaction)

	# Assert
	_expect(first_result["success"] as bool, "first transaction should succeed")
	_expect(not (failed_result["success"] as bool), "failed middle transaction should not succeed")
	_expect(second_result["success"] as bool, "second successful transaction should succeed")
	_expect(int(first_result["tx_id"]) == 1, "first successful transaction should receive tx_id 1")
	_expect(int(second_result["tx_id"]) == 2, "second successful transaction should receive tx_id 2")
	_expect(first_transaction.id == 1, "first transaction object should retain committed id")
	_expect(failed_transaction.id == 0, "failed transaction should not consume or retain an id")
	_expect(second_transaction.id == 2, "second transaction object should retain the next committed id")
	_expect(manager.get_transaction_log().size() == 2, "only successful transactions should be written to the audit log")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
