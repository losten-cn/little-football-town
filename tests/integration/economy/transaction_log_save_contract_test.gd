extends SceneTree

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const TransactionScript: Script = preload("res://src/core/transaction.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	test_transaction_log_retains_latest_200_entries_in_order()
	test_economy_serialize_deserialize_roundtrip_restores_state()
	test_economy_deserialize_partial_old_save_payload_uses_default_next_tx_id()
	test_economy_registers_with_save_manager_and_restores_through_pipeline()
	if _failures.is_empty():
		print("TRANSACTION_LOG_SAVE_CONTRACT_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("TRANSACTION_LOG_SAVE_CONTRACT_TEST_FAIL: %s" % failure)
		quit(1)

func test_transaction_log_retains_latest_200_entries_in_order() -> void:
	var manager: EconomyManager = _make_manager()
	for transaction_index: int in range(201):
		var transaction: Transaction = _make_test_transaction(float(transaction_index + 1), "log_%03d" % transaction_index)
		_expect(manager.execute_transaction(transaction)["success"] as bool, "setup transactions should all commit for log retention test")
	var transaction_log: Array[Transaction] = manager.get_transaction_log()
	_expect(transaction_log.size() == 200, "transaction log should retain only the latest 200 entries")
	_expect(transaction_log[0].reason == "log_001", "entry 201 should evict the oldest committed transaction")
	_expect(transaction_log[199].reason == "log_200", "newest committed transaction should remain at the end of the bounded log")
	var exact_limit_manager: EconomyManager = _make_manager()
	for transaction_index: int in range(200):
		_expect(exact_limit_manager.execute_transaction(_make_test_transaction(1.0, "exact_%03d" % transaction_index))["success"] as bool, "exact-limit setup transactions should commit")
	_expect(exact_limit_manager.get_transaction_log().size() == 200, "exactly 200 committed transactions should be retained without eviction")
	var empty_manager: EconomyManager = _make_manager()
	_expect(empty_manager.get_transaction_log().is_empty(), "empty transaction log should remain empty")
	var failed_transaction: Transaction = _make_test_transaction(0.0, "failed_expense")
	failed_transaction.type = Transaction.TransactionType.EXPENSE
	failed_transaction.ap_delta = -2.0
	_expect(not (empty_manager.execute_transaction(failed_transaction).get("success", false) as bool), "failed transaction should be rejected for retention edge-case coverage")
	_expect(empty_manager.get_transaction_log().is_empty(), "failed transactions must not be appended to the bounded log")
	_dispose_manager(manager)
	_dispose_manager(exact_limit_manager)
	_dispose_manager(empty_manager)

func test_economy_serialize_deserialize_roundtrip_restores_state() -> void:
	var source_manager: EconomyManager = _make_manager()
	_expect(source_manager.execute_transaction(_make_test_transaction(-50.0, "negative_funds_setup"))["success"] as bool, "setup should allow negative funds for roundtrip coverage")
	_expect(source_manager.execute_transaction(_make_test_transaction(0.0, "zero_rp_setup", 0.0, 0.0))["success"] as bool, "setup should preserve RP zero edge case")
	_expect(source_manager.execute_transaction(_make_test_transaction(25.0, "empty_metadata_setup", 0.0, 0.0, {}))["success"] as bool, "setup should preserve empty metadata edge case")
	var payload: Dictionary[String, Variant] = source_manager.serialize()
	var restored_manager: EconomyManager = _make_manager()
	restored_manager.deserialize(payload)
	_expect(_float_dictionary_equals(restored_manager.get_balance_snapshot(), source_manager.get_balance_snapshot()), "deserialize should restore all three balances exactly")
	_expect(JSON.stringify(restored_manager.serialize()) == JSON.stringify(payload), "serialize/deserialize roundtrip should preserve next_tx_id and transaction history")
	var restored_log: Array[Transaction] = restored_manager.get_transaction_log()
	_expect(restored_log.size() == 3, "deserialize should restore the committed transaction history size")
	_expect(restored_log[0].reason == "negative_funds_setup", "deserialize should preserve the oldest restored transaction reason")
	_expect(restored_log[2].metadata.is_empty(), "deserialize should preserve empty metadata dictionaries")
	var next_transaction_result: Dictionary[String, Variant] = restored_manager.execute_transaction(_make_test_transaction(10.0, "post_restore_tx"))
	_expect(next_transaction_result["success"] as bool, "post-restore transaction should still commit")
	_expect(int(next_transaction_result["tx_id"]) == 4, "restored next_tx_id should continue from the pre-save economy state")
	_dispose_manager(source_manager)
	_dispose_manager(restored_manager)

func test_economy_deserialize_partial_old_save_payload_uses_default_next_tx_id() -> void:
	var manager: EconomyManager = _make_manager()
	var old_save_payload: Dictionary[String, Variant] = {
		"funds": 75.0,
		"action_points": 4.0,
		"research_points": 2.0,
		"transactions": [
			_make_test_transaction(30.0, "legacy_000").to_dict(),
			_make_test_transaction(-10.0, "legacy_001").to_dict(),
		],
	}
	manager.deserialize(old_save_payload)
	_expect(_float_dictionary_equals(manager.get_balance_snapshot(), {
		"funds": 75.0,
		"action_points": 4.0,
		"research_points": 2.0,
	}), "partial old save payload should still restore serialized balances")
	_expect(manager.get_transaction_log().size() == 2, "partial old save payload should restore legacy transaction history")
	var next_transaction_result: Dictionary[String, Variant] = manager.execute_transaction(_make_test_transaction(5.0, "post_legacy_restore"))
	_expect(next_transaction_result["success"] as bool, "post-legacy restore transaction should still commit")
	_expect(int(next_transaction_result["tx_id"]) == 1, "missing next_tx_id should currently fall back to the default id counter")
	_dispose_manager(manager)

func test_economy_registers_with_save_manager_and_restores_through_pipeline() -> void:
	var source_manager: EconomyManager = _make_manager()
	for transaction_index: int in range(5):
		_expect(source_manager.execute_transaction(_make_test_transaction(10.0 + float(transaction_index), "pipeline_%03d" % transaction_index))["success"] as bool, "setup transactions should commit for save pipeline test")
	var save_manager: Node = SaveManagerScript.new()
	_expect(source_manager.register_with_save_manager(save_manager), "economy manager should register with SaveManager")
	_expect(save_manager.has_registered_system("economy"), "SaveManager should track the registered economy block")
	var serialized_economy_state: Dictionary[String, Variant] = save_manager.serialize_registered_system("economy")
	_expect(is_equal_approx(float(serialized_economy_state.get("funds", 0.0)), float(source_manager.get_balance_snapshot()["funds"])), "SaveManager serialization should include the current funds balance")
	_expect(int(serialized_economy_state.get("next_tx_id", 0)) == 6, "SaveManager serialization should include the next transaction id")
	var restored_manager: EconomyManager = _make_manager()
	_expect(restored_manager.register_with_save_manager(save_manager), "restored manager should be able to replace the economy save contract")
	_expect(save_manager.deserialize_registered_system("economy", serialized_economy_state), "SaveManager should restore the economy block through the centralized pipeline")
	_expect(JSON.stringify(save_manager.serialize_registered_system("economy")) == JSON.stringify(serialized_economy_state), "centralized pipeline should restore through the economy save block contract")
	_expect(_float_dictionary_equals(restored_manager.get_balance_snapshot(), source_manager.get_balance_snapshot()), "pipeline restore should recover the serialized economy balances")
	_expect(JSON.stringify(restored_manager.serialize()) == JSON.stringify(serialized_economy_state), "pipeline restore should recover next_tx_id and bounded transaction history")
	_expect(save_manager.deserialize_registered_system("economy", _to_typed_metadata({})), "registered economy block should accept empty restore payloads")
	_expect(_float_dictionary_equals(restored_manager.get_balance_snapshot(), {
		"funds": 0.0,
		"action_points": 1.0,
		"research_points": 0.0,
	}), "empty restore payload should fall back to default balances")
	_expect(restored_manager.get_transaction_log().is_empty(), "empty restore payload should clear restored transaction history")
	_dispose_manager(source_manager)
	_dispose_manager(restored_manager)
	save_manager.queue_free()

func _make_manager() -> EconomyManager:
	var manager: EconomyManager = EconomyManagerScript.new()
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.action_points_floor = 0.0
	economy_config.research_points_floor = 0.0
	economy_config.funds_low_threshold = -1000.0
	economy_config.debt_warning_threshold = -1000.0
	economy_config.warning_cooldown_seconds = 300.0
	manager.set_economy_config_for_testing(economy_config)
	return manager

func _make_test_transaction(funds_delta: float, reason: String, ap_delta: float = 0.0, rp_delta: float = 0.0, metadata: Dictionary = {"tag": "test"}) -> Transaction:
	var transaction: Transaction = TransactionScript.new()
	transaction.type = Transaction.TransactionType.TRANSFER
	transaction.funds_delta = funds_delta
	transaction.ap_delta = ap_delta
	transaction.rp_delta = rp_delta
	transaction.reason = reason
	transaction.source_system = "test"
	transaction.metadata = _to_typed_metadata(metadata)
	return transaction

func _to_typed_metadata(source: Dictionary) -> Dictionary[String, Variant]:
	var typed_metadata: Dictionary[String, Variant] = {}
	for key_variant: Variant in source:
		typed_metadata[String(key_variant)] = source[key_variant]
	return typed_metadata.duplicate(true)

func _float_dictionary_equals(left: Dictionary[String, float], right: Dictionary[String, float]) -> bool:
	if left.size() != right.size():
		return false
	for key: String in left.keys():
		if not right.has(key):
			return false
		if not is_equal_approx(float(left[key]), float(right[key])):
			return false
	return true

func _dispose_manager(manager: EconomyManager) -> void:
	if manager != null:
		manager.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
