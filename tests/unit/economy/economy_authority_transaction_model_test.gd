extends SceneTree

const TransactionScript: Script = preload("res://src/core/transaction.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_economy_manager_get_balance_snapshot_exposes_authoritative_resources()
	test_transaction_to_dict_and_from_dict_round_trip_required_fields()
	test_economy_manager_execute_transaction_clamps_ap_and_rp_to_legal_floors()
	test_economy_manager_public_api_requires_execute_transaction_for_resource_changes()
	if _failures.is_empty():
		print("ECONOMY_AUTHORITY_TRANSACTION_MODEL_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("ECONOMY_AUTHORITY_TRANSACTION_MODEL_TEST_FAIL: %s" % failure)
		quit(1)


func test_economy_manager_get_balance_snapshot_exposes_authoritative_resources() -> void:
	# Arrange
	var manager: EconomyManager = EconomyManagerScript.new()
	var transaction: Transaction = TransactionScript.new()
	transaction.funds_delta = -50.0
	transaction.ap_delta = 2.0
	transaction.rp_delta = 3.0
	transaction.source_system = "test_suite"

	# Act
	manager.set_economy_config_for_testing(_make_default_economy_config())
	var initial_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var execute_result: Dictionary[String, Variant] = manager.execute_transaction(transaction)
	var updated_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()

	# Assert
	_expect(initial_snapshot.has("funds"), "balance snapshot should include funds")
	_expect(initial_snapshot.has("action_points"), "balance snapshot should include action_points")
	_expect(initial_snapshot.has("research_points"), "balance snapshot should include research_points")
	_expect(is_equal_approx(float(initial_snapshot["funds"]), 0.0), "default funds should start at 0.0")
	_expect(is_equal_approx(float(initial_snapshot["action_points"]), 1.0), "default action_points should start at 1.0")
	_expect(is_equal_approx(float(initial_snapshot["research_points"]), 0.0), "default research_points should start at 0.0")
	_expect(execute_result["success"] as bool, "execute_transaction should accept a valid Story 001 transaction request")
	_expect(is_equal_approx(manager.get_funds(), -50.0), "funds should update through execute_transaction")
	_expect(is_equal_approx(manager.get_action_points(), 3.0), "action_points should update through execute_transaction")
	_expect(is_equal_approx(manager.get_research_points(), 3.0), "research_points should update through execute_transaction")
	_expect(is_equal_approx(float(updated_snapshot["funds"]), -50.0), "updated snapshot should report funds owned by the manager")
	_expect(is_equal_approx(float(updated_snapshot["action_points"]), 3.0), "updated snapshot should report action_points owned by the manager")
	_expect(is_equal_approx(float(updated_snapshot["research_points"]), 3.0), "updated snapshot should report research_points owned by the manager")


func test_transaction_to_dict_and_from_dict_round_trip_required_fields() -> void:
	# Arrange
	var transaction: Transaction = TransactionScript.new()
	transaction.id = 42
	transaction.type = Transaction.TransactionType.EXPENSE
	transaction.funds_delta = 0.0
	transaction.ap_delta = -1.0
	transaction.rp_delta = 0.0
	transaction.reason = ""
	transaction.source_system = "test_suite"
	transaction.timestamp = 123456789
	transaction.metadata = {}

	# Act
	var payload: Dictionary[String, Variant] = transaction.to_dict()
	var restored_transaction: Transaction = Transaction.from_dict(payload)

	# Assert
	_expect(typeof(payload["id"]) == TYPE_INT, "serialized id should be a primitive int")
	_expect(typeof(payload["type"]) == TYPE_INT, "serialized type should be a primitive int")
	_expect(typeof(payload["funds_delta"]) == TYPE_FLOAT, "serialized funds_delta should be a primitive float")
	_expect(typeof(payload["reason"]) == TYPE_STRING, "serialized reason should be a primitive string")
	_expect(typeof(payload["metadata"]) == TYPE_DICTIONARY, "serialized metadata should be a primitive dictionary")
	_expect(restored_transaction.id == 42, "restored transaction should keep id")
	_expect(restored_transaction.type == Transaction.TransactionType.EXPENSE, "restored transaction should keep type")
	_expect(is_equal_approx(restored_transaction.funds_delta, 0.0), "restored transaction should keep funds_delta")
	_expect(is_equal_approx(restored_transaction.ap_delta, -1.0), "restored transaction should keep ap_delta")
	_expect(is_equal_approx(restored_transaction.rp_delta, 0.0), "restored transaction should keep rp_delta")
	_expect(restored_transaction.reason == "", "restored transaction should keep empty reason strings")
	_expect(restored_transaction.source_system == "test_suite", "restored transaction should keep source_system")
	_expect(restored_transaction.timestamp == 123456789, "restored transaction should keep timestamp")
	_expect(restored_transaction.metadata.is_empty(), "restored transaction should keep empty metadata dictionaries")


func test_economy_manager_execute_transaction_clamps_ap_and_rp_to_legal_floors() -> void:
	# Arrange
	var manager: EconomyManager = EconomyManagerScript.new()
	manager.set_economy_config_for_testing(_make_default_economy_config())
	var transaction: Transaction = TransactionScript.new()
	transaction.ap_delta = -10.0
	transaction.rp_delta = -10.0
	transaction.source_system = "test_suite"

	# Act
	var execute_result: Dictionary[String, Variant] = manager.execute_transaction(transaction)

	# Assert
	_expect(not (execute_result["success"] as bool), "execute_transaction should reject floor-violating requests after Story 002")
	_expect(String(execute_result["error"]) == "ap_below_floor", "ap floor violation should report ap_below_floor")
	_expect(is_equal_approx(manager.get_action_points(), 1.0), "action_points should remain at the legal floor after rejection")
	_expect(is_equal_approx(manager.get_research_points(), 0.0), "research_points should remain unchanged after rejection")


func test_economy_manager_public_api_requires_execute_transaction_for_resource_changes() -> void:
	# Arrange
	var manager: EconomyManager = EconomyManagerScript.new()
	var property_list: Array[Dictionary] = manager.get_property_list()

	# Act
	var has_public_funds_property: bool = _property_list_contains(property_list, "funds")
	var has_public_action_points_property: bool = _property_list_contains(property_list, "action_points")
	var has_public_research_points_property: bool = _property_list_contains(property_list, "research_points")

	# Assert
	_expect(manager.has_method("get_funds"), "read-only funds API should exist")
	_expect(manager.has_method("get_action_points"), "read-only action_points API should exist")
	_expect(manager.has_method("get_research_points"), "read-only research_points API should exist")
	_expect(manager.has_method("get_balance_snapshot"), "read-only balance snapshot API should exist")
	_expect(manager.has_method("execute_transaction"), "execute_transaction should exist as the controlled write request boundary")
	_expect(not manager.has_method("set_funds"), "public funds setter should not exist")
	_expect(not manager.has_method("set_action_points"), "public action_points setter should not exist")
	_expect(not manager.has_method("set_research_points"), "public research_points setter should not exist")
	_expect(not manager.has_method("apply_funds_delta"), "alternate funds mutation helper should not exist")
	_expect(not manager.has_method("apply_action_points_delta"), "alternate action_points mutation helper should not exist")
	_expect(not manager.has_method("apply_research_points_delta"), "alternate research_points mutation helper should not exist")
	_expect(not has_public_funds_property, "public funds property should not exist outside the controlled boundary")
	_expect(not has_public_action_points_property, "public action_points property should not exist outside the controlled boundary")
	_expect(not has_public_research_points_property, "public research_points property should not exist outside the controlled boundary")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _property_list_contains(property_list: Array[Dictionary], property_name: String) -> bool:
	for property_data: Dictionary in property_list:
		if String(property_data.get("name", "")) == property_name:
			return true
	return false

func _make_default_economy_config() -> EconomyConfig:
	return EconomyConfigScript.new()
