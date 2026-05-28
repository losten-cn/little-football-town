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
	test_warning_conditions_are_evaluated_after_successful_transactions()
	test_warning_event_payload_contains_required_fields()
	test_warning_cooldown_is_tracked_per_warning_type()
	_cleanup_event_bus()
	if _failures.is_empty():
		print("WARNING_THRESHOLD_COOLDOWN_EVENTS_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("WARNING_THRESHOLD_COOLDOWN_EVENTS_TEST_FAIL: %s" % failure)
		quit(1)

func test_warning_conditions_are_evaluated_after_successful_transactions() -> void:
	# Arrange
	_captured_warnings.clear()
	var manager: EconomyManager = _make_manager()
	var setup_transaction: Transaction = TransactionScript.new()
	setup_transaction.funds_delta = 150.0
	setup_transaction.ap_delta = 2.0
	setup_transaction.source_system = "test"
	_expect(manager.execute_transaction(setup_transaction)["success"] as bool, "setup transaction should succeed before warning evaluation test")
	_captured_warnings.clear()
	var warning_transaction: Transaction = TransactionScript.new()
	warning_transaction.funds_delta = -160.0
	warning_transaction.ap_delta = -2.0
	warning_transaction.source_system = "test"

	# Act
	var result: Dictionary[String, Variant] = manager.execute_transaction(warning_transaction)

	# Assert
	_expect(result["success"] as bool, "warning evaluation transaction should succeed")
	_expect(_has_warning_type("funds_low"), "funds_low warning should be detected after successful transaction")
	_expect(_has_warning_type("ap_low"), "ap_low warning should be detected after successful transaction")
	_expect(_has_warning_type("debt"), "debt warning should be detected after successful transaction")
	_dispose_manager(manager)

func test_warning_event_payload_contains_required_fields() -> void:
	# Arrange
	_captured_warnings.clear()
	var manager: EconomyManager = _make_manager()
	var transaction: Transaction = TransactionScript.new()
	transaction.funds_delta = -50.0
	transaction.source_system = "test"

	# Act
	var result: Dictionary[String, Variant] = manager.execute_transaction(transaction)
	var debt_warning: Dictionary = _find_warning("debt")

	# Assert
	_expect(result["success"] as bool, "payload test transaction should succeed")
	_expect(not debt_warning.is_empty(), "debt warning payload should be captured")
	_expect(debt_warning.has("warning_type"), "warning payload should include warning_type")
	_expect(debt_warning.has("current_value"), "warning payload should include current_value")
	_expect(debt_warning.has("threshold"), "warning payload should include threshold")
	_expect(String(debt_warning.get("warning_type", "")) == "debt", "warning_type should match the emitted warning")
	_expect(is_equal_approx(float(debt_warning.get("current_value", 0.0)), -50.0), "current_value should reflect the committed balance")
	_expect(is_equal_approx(float(debt_warning.get("threshold", 0.0)), 0.0), "threshold should come from config")
	_dispose_manager(manager)

func test_warning_cooldown_is_tracked_per_warning_type() -> void:
	# Arrange
	_captured_warnings.clear()
	var manager: EconomyManager = _make_manager()
	var setup_transaction: Transaction = TransactionScript.new()
	setup_transaction.funds_delta = 150.0
	setup_transaction.ap_delta = 2.0
	setup_transaction.source_system = "test"
	_expect(manager.execute_transaction(setup_transaction)["success"] as bool, "setup transaction should succeed before cooldown test")
	_captured_warnings.clear()
	var trigger_transaction: Transaction = TransactionScript.new()
	trigger_transaction.funds_delta = -160.0
	trigger_transaction.ap_delta = -1.0
	trigger_transaction.source_system = "test"
	_expect(manager.execute_transaction(trigger_transaction)["success"] as bool, "first warning trigger transaction should succeed")
	var first_warning_count: int = _captured_warnings.size()
	var repeat_transaction: Transaction = TransactionScript.new()
	repeat_transaction.funds_delta = 0.0
	repeat_transaction.ap_delta = 0.0
	repeat_transaction.source_system = "test"

	# Act
	var repeat_result: Dictionary[String, Variant] = manager.execute_transaction(repeat_transaction)
	var second_warning_count: int = _captured_warnings.size()
	manager.set_warning_cooldown_for_testing("ap_low", 0.0)
	var ap_only_retrigger_transaction: Transaction = TransactionScript.new()
	ap_only_retrigger_transaction.funds_delta = 0.0
	ap_only_retrigger_transaction.ap_delta = 0.0
	ap_only_retrigger_transaction.source_system = "test"
	var retrigger_result: Dictionary[String, Variant] = manager.execute_transaction(ap_only_retrigger_transaction)
	var third_warning_count: int = _captured_warnings.size()

	# Assert
	_expect(repeat_result["success"] as bool, "repeat transaction should still succeed during cooldown")
	_expect(retrigger_result["success"] as bool, "retrigger transaction should succeed after one warning cooldown is cleared")
	_expect(first_warning_count == 3, "first warning pass should emit all three warning types")
	_expect(second_warning_count == first_warning_count, "same warning types should not re-emit while cooldown is active")
	_expect(third_warning_count == second_warning_count + 1, "clearing one warning cooldown should allow only that warning type to re-emit")
	_expect(third_warning_count > 0, "retrigger pass should record at least one warning event")
	_expect(String(_captured_warnings[third_warning_count - 1].get("warning_type", "")) == "ap_low", "per-type cooldown should let ap_low re-emit independently")
	_dispose_manager(manager)

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
	manager.name = "EconomyManager"
	root.add_child(manager)
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.funds_low_threshold = 100.0
	economy_config.action_points_low_threshold = 2.0
	economy_config.debt_warning_threshold = 0.0
	economy_config.warning_cooldown_seconds = 300.0
	manager.set_economy_config_for_testing(economy_config)
	manager.set_event_bus_for_testing(_event_bus())
	return manager

func _dispose_manager(manager: EconomyManager) -> void:
	if manager != null:
		manager.queue_free()

func _has_warning_type(warning_type: String) -> bool:
	return not _find_warning(warning_type).is_empty()

func _find_warning(warning_type: String) -> Dictionary:
	for payload: Dictionary in _captured_warnings:
		if String(payload.get("warning_type", "")) == warning_type:
			return payload
	return {}

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
