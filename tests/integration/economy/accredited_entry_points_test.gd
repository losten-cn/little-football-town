extends SceneTree

const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")

var _failures: Array[String] = []
var _captured_balance_changes: Array[Dictionary] = []
var _captured_warning_events: Array[Dictionary] = []


func _event_bus() -> Node:
	return root.get_node("EventBus")


func _initialize() -> void:
	_setup_event_bus()
	test_accredited_entry_points_delegate_resource_changes_through_execute_transaction()
	test_accredited_entry_points_write_complete_audit_metadata()
	test_transaction_history_snapshots_remain_immutable()
	test_unaccredited_resource_writes_do_not_modify_authoritative_balances()
	test_settle_post_match_uses_internal_authorized_path()
	_cleanup_event_bus()
	if _failures.is_empty():
		print("ACCREDITED_ENTRY_POINTS_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("ACCREDITED_ENTRY_POINTS_TEST_FAIL: %s" % failure)
		quit(1)


func test_accredited_entry_points_delegate_resource_changes_through_execute_transaction() -> void:
	# Arrange
	_captured_balance_changes.clear()
	var manager: EconomyManager = _make_manager()
	var before_log_size: int = manager.get_transaction_log().size()
	var before_next_tx_id: int = _peek_next_transaction_id(manager)

	# Act
	var match_result: Dictionary[String, Variant] = manager.accredit_match_reward(120, 2, 1, 7)
	var facility_result: Dictionary[String, Variant] = manager.accredit_facility_construction_cost(50, 1, 11)
	var training_result: Dictionary[String, Variant] = manager.accredit_training_cost(30, 1, 23)
	var snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var transaction_log: Array[Transaction] = manager.get_transaction_log()
	var after_next_tx_id: int = _peek_next_transaction_id(manager)

	# Assert
	_expect(match_result["success"] as bool, "match reward should succeed through the accredited entry point")
	_expect(facility_result["success"] as bool, "facility cost should succeed through the accredited entry point")
	_expect(training_result["success"] as bool, "training cost should succeed through the accredited entry point")
	_expect(transaction_log.size() == before_log_size + 3, "each accredited entry point should append exactly one committed transaction")
	_expect(after_next_tx_id == before_next_tx_id + 3, "accredited entry points should advance tx_id only through committed transactions")
	_expect(is_equal_approx(float(snapshot["funds"]), 40.0), "accredited entry points should mutate funds only through committed transactions")
	_expect(is_equal_approx(float(snapshot["action_points"]), 1.0), "accredited entry points should mutate action points only through committed transactions")
	_expect(is_equal_approx(float(snapshot["research_points"]), 1.0), "accredited entry points should mutate research points only through committed transactions")
	_expect(_captured_balance_changes.size() == 3, "each accredited entry point should emit one balance-change event after commit")
	_dispose_manager(manager)


func test_accredited_entry_points_write_complete_audit_metadata() -> void:
	# Arrange
	var manager: EconomyManager = _make_manager()

	# Act
	_expect(manager.accredit_match_reward(90, 0, 0, 5)["success"] as bool, "match reward setup should succeed")
	_expect(manager.accredit_facility_construction_cost(10, 0, 12)["success"] as bool, "facility cost setup should succeed")
	_expect(manager.accredit_training_cost(0, 0, 34)["success"] as bool, "zero-cost training should still use the accredited entry point")
	var transaction_log: Array[Transaction] = manager.get_transaction_log()
	var match_transaction: Transaction = transaction_log[0]
	var facility_transaction: Transaction = transaction_log[1]
	var training_transaction: Transaction = transaction_log[2]

	# Assert
	_expect(match_transaction.reason == "match_reward", "match reward should use the match_reward audit reason")
	_expect(match_transaction.source_system == "match", "match reward should attribute source_system to match")
	_expect(int(match_transaction.metadata.get("match_id", 0)) == 5, "match reward metadata should include the match id")
	_expect(facility_transaction.reason == "facility_cost", "facility cost should use the facility_cost audit reason")
	_expect(facility_transaction.source_system == "town", "facility cost should attribute source_system to town")
	_expect(int(facility_transaction.metadata.get("facility_id", 0)) == 12, "facility cost metadata should include the facility id")
	_expect(training_transaction.reason == "training_cost", "training cost should use the training_cost audit reason")
	_expect(training_transaction.source_system == "player", "training cost should attribute source_system to player")
	_expect(int(training_transaction.metadata.get("player_id", 0)) == 34, "training cost metadata should include the player id")
	_dispose_manager(manager)


func test_transaction_history_snapshots_remain_immutable() -> void:
	# Arrange
	var manager: EconomyManager = _make_manager()
	var committed_transaction := Transaction.new()
	committed_transaction.type = Transaction.TransactionType.INCOME
	committed_transaction.funds_delta = 45.0
	committed_transaction.reason = "committed_income"
	committed_transaction.source_system = "test"

	# Act
	_expect(manager.execute_transaction(committed_transaction)["success"] as bool, "direct committed transaction should succeed before immutability check")
	committed_transaction.reason = "mutated_after_commit"
	var first_snapshot: Array[Transaction] = manager.get_transaction_log()
	first_snapshot[0].metadata["match_id"] = 999
	first_snapshot[0].reason = "mutated_snapshot"
	var second_snapshot: Array[Transaction] = manager.get_transaction_log()

	# Assert
	_expect(second_snapshot.size() == 1, "transaction history should keep the committed entry")
	_expect(second_snapshot[0].reason == "committed_income", "mutating the original transaction or returned snapshot must not rewrite committed history")
	_expect(not second_snapshot[0].metadata.has("match_id"), "mutating returned transaction metadata must not leak back into committed history")
	_dispose_manager(manager)


func test_unaccredited_resource_writes_do_not_modify_authoritative_balances() -> void:
	# Arrange
	_captured_balance_changes.clear()
	_captured_warning_events.clear()
	var manager: EconomyManager = _make_manager()
	var before_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var before_log_size: int = manager.get_transaction_log().size()
	var before_balance_events: int = _captured_balance_changes.size()
	var before_warning_events: int = _captured_warning_events.size()

	# Act
	var spoofed_transaction: Transaction = Transaction.new()
	spoofed_transaction.type = Transaction.TransactionType.EXPENSE
	spoofed_transaction.funds_delta = -10.0
	spoofed_transaction.ap_delta = -1.0
	spoofed_transaction.reason = "spoofed_write"
	spoofed_transaction.source_system = "rogue"
	var spoofed_result: Dictionary[String, Variant] = manager.execute_transaction(spoofed_transaction)

	var spoofed_match_transaction: Transaction = Transaction.new()
	spoofed_match_transaction.type = Transaction.TransactionType.INCOME
	spoofed_match_transaction.funds_delta = 25.0
	spoofed_match_transaction.ap_delta = 0.0
	spoofed_match_transaction.rp_delta = 0.0
	spoofed_match_transaction.reason = "spoofed_match_reward"
	spoofed_match_transaction.source_system = "match"
	spoofed_match_transaction.metadata = {"match_id": 99}
	var spoofed_match_result: Dictionary[String, Variant] = manager.execute_transaction(spoofed_match_transaction)
	var after_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()

	# Assert
	_expect(not (spoofed_result.get("success", false) as bool), "unaccredited transaction writes should fail instead of mutating balances")
	_expect(String(spoofed_result.get("error", "")) == "unauthorized_source_system", "unaccredited transaction writes should return a traceable unauthorized_source_system error")
	_expect(not (spoofed_match_result.get("success", false) as bool), "spoofed match writes must fail unless they pass through an accredited entry point")
	_expect(String(spoofed_match_result.get("error", "")) == "unauthorized_source_system", "spoofed match writes should return unauthorized_source_system")
	_expect(is_equal_approx(float(after_snapshot["funds"]), float(before_snapshot["funds"])), "failed unaccredited writes must not change funds")
	_expect(is_equal_approx(float(after_snapshot["action_points"]), float(before_snapshot["action_points"])), "failed unaccredited writes must not change action points")
	_expect(is_equal_approx(float(after_snapshot["research_points"]), float(before_snapshot["research_points"])), "failed unaccredited writes must not change research points")
	_expect(manager.get_transaction_log().size() == before_log_size, "failed unaccredited writes must not append committed transactions")
	_expect(_captured_balance_changes.size() == before_balance_events, "failed unaccredited writes must not emit balance-change events")
	_expect(_captured_warning_events.size() == before_warning_events, "failed unaccredited writes must not emit warning events")
	_dispose_manager(manager)


func test_settle_post_match_uses_internal_authorized_path() -> void:
	# Arrange
	_captured_balance_changes.clear()
	_captured_warning_events.clear()
	var manager: EconomyManager = _make_manager()
	var before_log_size: int = manager.get_transaction_log().size()
	var before_balance_events: int = _captured_balance_changes.size()
	var match_result_packet: Dictionary[String, Variant] = {
		"match_id": "match-42",
		"result": "win",
	}
	var settlement_context: Dictionary[String, Variant] = {
		"league_tier": 2,
		"stadium_revenue_multiplier": 1.2,
		"tactical_rating_ratio": 1.5,
	}

	# Act
	var result: Dictionary[String, Variant] = manager.settle_post_match(match_result_packet, settlement_context)
	var transaction_log: Array[Transaction] = manager.get_transaction_log()
	var committed_transaction: Transaction = transaction_log[before_log_size]

	# Assert
	_expect(result.get("success", false) as bool, "settle_post_match should succeed through the internal authorized path")
	_expect(transaction_log.size() == before_log_size + 1, "settle_post_match should append exactly one committed transaction")
	_expect(committed_transaction.reason == "post_match_settlement", "settle_post_match should write the post_match_settlement reason")
	_expect(committed_transaction.source_system == "match", "settle_post_match should keep match as the audit source_system")
	_expect(String(committed_transaction.metadata.get("match_id", "")) == "match-42", "settle_post_match should preserve match_id metadata")
	_expect(not committed_transaction.metadata.has("_authorization_token"), "internal authorization token must not leak into committed metadata")
	_expect(_captured_balance_changes.size() == before_balance_events + 1, "settle_post_match should emit one balance-change event after commit")
	_dispose_manager(manager)


func _setup_event_bus() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)
	var balance_change_callback := _capture_balance_change.bind(_captured_balance_changes)
	var warning_callback := _capture_warning_event.bind(_captured_warning_events)
	_event_bus().subscribe("economy_balance_changed", balance_change_callback)
	_event_bus().subscribe("economy_warning_triggered", warning_callback)


func _cleanup_event_bus() -> void:
	var event_bus: Node = root.get_node_or_null("EventBus")
	if event_bus != null:
		var balance_change_callback := _capture_balance_change.bind(_captured_balance_changes)
		var warning_callback := _capture_warning_event.bind(_captured_warning_events)
		_event_bus().unsubscribe("economy_balance_changed", balance_change_callback)
		_event_bus().unsubscribe("economy_warning_triggered", warning_callback)
		event_bus.queue_free()


func _make_manager() -> EconomyManager:
	var manager: EconomyManager = EconomyManagerScript.new()
	manager.name = "EconomyManager"
	root.add_child(manager)
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.action_points_floor = 0.0
	economy_config.research_points_floor = 0.0
	economy_config.funds_low_threshold = -1000.0
	economy_config.debt_warning_threshold = -1000.0
	economy_config.warning_cooldown_seconds = 300.0
	manager.set_economy_config_for_testing(economy_config)
	manager.set_event_bus_for_testing(_event_bus())
	return manager


func _peek_next_transaction_id(manager: EconomyManager) -> int:
	return int(manager.get("_next_transaction_id"))


func _dispose_manager(manager: EconomyManager) -> void:
	if manager != null:
		manager.queue_free()


func _capture_balance_change(_event_name: String, payload: Dictionary, sink: Array[Dictionary]) -> void:
	sink.append(_to_typed_dictionary(payload))


func _capture_warning_event(_event_name: String, payload: Dictionary, sink: Array[Dictionary]) -> void:
	sink.append(_to_typed_dictionary(payload))


func _to_typed_dictionary(source: Dictionary) -> Dictionary:
	var typed_dictionary: Dictionary = {}
	for key_variant: Variant in source:
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
