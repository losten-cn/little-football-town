extends SceneTree

const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const TransactionScript: Script = preload("res://src/core/transaction.gd")

var _failures: Array[String] = []
var _captured_warnings: Array[Dictionary] = []

func _event_bus() -> Node:
	return root.get_node("EventBus")

func _initialize() -> void:
	_setup_event_bus()
	test_budget_preview_returns_projected_balances_without_mutation()
	test_budget_preview_reports_affordability_and_reason_codes()
	test_budget_preview_recalculates_from_latest_authoritative_balances()
	_cleanup_event_bus()
	if _failures.is_empty():
		print("BUDGET_PREVIEW_AFFORDABILITY_QUERY_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("BUDGET_PREVIEW_AFFORDABILITY_QUERY_TEST_FAIL: %s" % failure)
		quit(1)

func test_budget_preview_returns_projected_balances_without_mutation() -> void:
	# Arrange
	_captured_warnings.clear()
	var manager: EconomyManager = _make_manager()
	var setup_transaction: Transaction = TransactionScript.new()
	setup_transaction.funds_delta = 150.0
	setup_transaction.ap_delta = 3.0
	setup_transaction.rp_delta = 2.0
	setup_transaction.source_system = "test"
	_expect(manager.execute_transaction(setup_transaction)["success"] as bool, "setup transaction should succeed before preview test")
	var before_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var before_log_size: int = manager.get_transaction_log().size()
	var before_next_tx_id: int = _peek_next_transaction_id(manager)
	_captured_warnings.clear()

	# Act
	var preview: Dictionary[String, Variant] = manager.get_budget_preview(120.0, 2.0, 1.0)
	var after_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var after_next_tx_id: int = _peek_next_transaction_id(manager)

	# Assert
	_expect(is_equal_approx(float(preview["current_funds"]), 150.0), "preview should report current funds")
	_expect(is_equal_approx(float(preview["current_action_points"]), 4.0), "preview should report current action points")
	_expect(is_equal_approx(float(preview["current_research_points"]), 2.0), "preview should report current research points")
	_expect(is_equal_approx(float(preview["projected_funds"]), 30.0), "preview should report projected funds")
	_expect(is_equal_approx(float(preview["projected_action_points"]), 2.0), "preview should report projected action points")
	_expect(is_equal_approx(float(preview["projected_research_points"]), 1.0), "preview should report projected research points")
	_expect(is_equal_approx(float(after_snapshot["funds"]), float(before_snapshot["funds"])), "preview must not mutate authoritative funds")
	_expect(is_equal_approx(float(after_snapshot["action_points"]), float(before_snapshot["action_points"])), "preview must not mutate authoritative action points")
	_expect(is_equal_approx(float(after_snapshot["research_points"]), float(before_snapshot["research_points"])), "preview must not mutate authoritative research points")
	_expect(manager.get_transaction_log().size() == before_log_size, "preview must not append to the transaction log")
	_expect(after_next_tx_id == before_next_tx_id, "preview must not advance the next committed tx_id")
	_expect(_captured_warnings.is_empty(), "preview must not emit warning events")

func test_budget_preview_reports_affordability_and_reason_codes() -> void:
	# Arrange
	var manager: EconomyManager = _make_manager()
	var setup_transaction: Transaction = TransactionScript.new()
	setup_transaction.funds_delta = 20.0
	setup_transaction.ap_delta = 1.0
	setup_transaction.source_system = "test"
	_expect(manager.execute_transaction(setup_transaction)["success"] as bool, "setup transaction should succeed before affordability test")

	# Act
	var affordable_preview: Dictionary[String, Variant] = manager.get_budget_preview(10.0, 1.0, 0.0)
	var unaffordable_preview: Dictionary[String, Variant] = manager.get_budget_preview(10.0, 2.0, 1.0)
	var unaffordable_reason_codes: Array[String] = unaffordable_preview["reason_codes"] as Array[String]

	# Assert
	_expect(affordable_preview["affordable"] as bool, "affordable preview should return affordable true")
	_expect((affordable_preview["reason_codes"] as Array[String]).is_empty(), "affordable preview should have no reason codes")
	_expect(not (unaffordable_preview["affordable"] as bool), "preview should report unaffordable when floors are violated")
	_expect(unaffordable_reason_codes.has("ap_below_floor"), "unaffordable preview should include ap_below_floor reason code")
	_expect(unaffordable_reason_codes.has("rp_below_floor"), "unaffordable preview should include rp_below_floor reason code")

func test_budget_preview_recalculates_from_latest_authoritative_balances() -> void:
	# Arrange
	var manager: EconomyManager = _make_manager()
	var first_preview: Dictionary[String, Variant] = manager.get_budget_preview(0.0, 0.0, 0.0)
	var transaction: Transaction = TransactionScript.new()
	transaction.funds_delta = 50.0
	transaction.ap_delta = 2.0
	transaction.rp_delta = 1.0
	transaction.source_system = "test"
	_expect(manager.execute_transaction(transaction)["success"] as bool, "real transaction should succeed before recalculation test")

	# Act
	var second_preview: Dictionary[String, Variant] = manager.get_budget_preview(10.0, 1.0, 1.0)

	# Assert
	_expect(is_equal_approx(float(first_preview["current_funds"]), 0.0), "first preview should start from the initial funds balance")
	_expect(is_equal_approx(float(second_preview["current_funds"]), 50.0), "second preview should use the updated authoritative funds balance")
	_expect(is_equal_approx(float(second_preview["current_action_points"]), 3.0), "second preview should use the updated authoritative action points balance")
	_expect(is_equal_approx(float(second_preview["current_research_points"]), 1.0), "second preview should use the updated authoritative research points balance")
	_expect(is_equal_approx(float(second_preview["projected_funds"]), 40.0), "second preview should recompute projected funds from latest balances")
	_expect(is_equal_approx(float(second_preview["projected_action_points"]), 2.0), "second preview should recompute projected action points from latest balances")
	_expect(is_equal_approx(float(second_preview["projected_research_points"]), 0.0), "second preview should recompute projected research points from latest balances")

func _setup_event_bus() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)
	var warning_callback := _capture_warning.bind(_captured_warnings)
	_event_bus().subscribe("economy_warning_triggered", warning_callback)

func _cleanup_event_bus() -> void:
	var event_bus: Node = root.get_node_or_null("EventBus")
	if event_bus != null:
		var warning_callback := _capture_warning.bind(_captured_warnings)
		_event_bus().unsubscribe("economy_warning_triggered", warning_callback)
		event_bus.queue_free()

func _make_manager() -> EconomyManager:
	var manager: EconomyManager = EconomyManagerScript.new()
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.action_points_floor = 1.0
	economy_config.research_points_floor = 0.0
	manager.set_economy_config_for_testing(economy_config)
	manager.set_event_bus_for_testing(_event_bus())
	return manager

func _peek_next_transaction_id(manager: EconomyManager) -> int:
	return int(manager.get("_next_transaction_id"))

func _capture_warning(_event_name: String, payload: Dictionary, sink: Array[Dictionary]) -> void:
	sink.append(_to_typed_dictionary(payload))

func _to_typed_dictionary(source: Dictionary) -> Dictionary:
	var typed_dictionary: Dictionary = {}
	for key_variant: Variant in source:
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
