extends SceneTree

const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")
const FacilityScript: Script = preload("res://src/core/facility.gd")

var _failures: Array[String] = []
var _captured_warnings: Array[Dictionary] = []
var _captured_balance_changes: Array[Dictionary] = []

func _event_bus() -> Node:
	return root.get_node("EventBus")

func _initialize() -> void:
	_setup_event_bus()
	test_daily_settlement_applies_recovery_and_clamps_to_max()
	test_daily_settlement_adds_rest_recovery_before_clamp()
	test_daily_settlement_deducts_base_and_facility_maintenance_cost()
	test_daily_settlement_includes_medical_training_adjacency_bonus()
	_cleanup_event_bus()
	if _failures.is_empty():
		print("DAILY_RECOVERY_MAINTENANCE_SETTLEMENT_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("DAILY_RECOVERY_MAINTENANCE_SETTLEMENT_TEST_FAIL: %s" % failure)
		quit(1)

func test_daily_settlement_applies_recovery_and_clamps_to_max() -> void:
	# Arrange
	_captured_warnings.clear()
	var manager: EconomyManager = _make_manager()
	var town_building: TownBuilding = _make_town_building(manager)
	_register_facility(
		town_building,
		FacilityScript.new(1, Facility.FacilityType.MEDICAL_ROOM, 2, Facility.FacilityState.ACTIVE, 0, 0, 0)
	)
	var setup_result: Dictionary[String, Variant] = manager.execute_transaction(_make_resource_transaction(0.0, 2.0, 0.0, "test_ap_setup"))
	_expect(setup_result["success"] as bool, "setup transaction should raise AP before clamp test")
	var before_log_size: int = manager.get_transaction_log().size()

	# Act
	var result: Dictionary[String, Variant] = manager.settle_day(false, town_building)
	var snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var transaction_log: Array[Transaction] = manager.get_transaction_log()
	var committed_transaction: Transaction = transaction_log[transaction_log.size() - 1]

	# Assert
	_expect(result["success"] as bool, "daily settlement should succeed for clamp test")
	_expect(is_equal_approx(float(result["ap_recovered"]), 2.0), "daily settlement should clamp recovered AP to the configured max")
	_expect(is_equal_approx(float(snapshot["action_points"]), 5.0), "daily settlement should clamp final AP to action_points_max")
	_expect(is_equal_approx(float(snapshot["funds"]), -28.0), "daily settlement should deduct base and facility maintenance from funds")
	_expect(transaction_log.size() == before_log_size + 1, "daily settlement should append exactly one committed transaction")
	_expect(committed_transaction.reason == "daily_settlement", "daily settlement transaction should use the daily_settlement reason")
	_expect(is_equal_approx(committed_transaction.ap_delta, 2.0), "daily settlement transaction should record the applied AP recovery delta")
	_expect(is_equal_approx(committed_transaction.funds_delta, -28.0), "daily settlement transaction should record the maintenance deduction")
	_expect(_captured_balance_changes.size() == 2, "daily settlement should emit one balance-change event in addition to setup transaction")
	_expect(String(_captured_balance_changes[1].get("resource_type", "")) == "all", "balance-change payload should use the all resource_type contract")
	_expect(is_equal_approx(float(_captured_balance_changes[1].get("ap_delta", 0.0)), 2.0), "balance-change payload should report the applied AP recovery delta")
	_expect(is_equal_approx(float(_captured_balance_changes[1].get("funds_delta", 0.0)), -28.0), "balance-change payload should report the maintenance deduction")
	_dispose_town_building(town_building)
	_dispose_manager(manager)

func test_daily_settlement_adds_rest_recovery_before_clamp() -> void:
	# Arrange
	var manager: EconomyManager = _make_manager(12.0)
	var town_building: TownBuilding = _make_town_building(manager)
	_register_facility(
		town_building,
		FacilityScript.new(1, Facility.FacilityType.MEDICAL_ROOM, 1, Facility.FacilityState.ACTIVE, 0, 0, 0)
	)

	# Act
	var result: Dictionary[String, Variant] = manager.settle_day(true, town_building)
	var snapshot: Dictionary[String, float] = manager.get_balance_snapshot()

	# Assert
	_expect(result["success"] as bool, "rest-day settlement should succeed")
	_expect(result["is_rest_day"] as bool, "rest-day settlement should report the rest-day flag")
	_expect(is_equal_approx(float(result["ap_recovered"]), 9.0), "rest-day settlement should add rest recovery on top of normal daily recovery before clamping")
	_expect(is_equal_approx(float(snapshot["action_points"]), 10.0), "rest-day settlement should apply the combined rest-day recovery to the authoritative balance")
	_expect(is_equal_approx(float(snapshot["funds"]), -27.0), "rest-day settlement should still deduct maintenance while recovering AP")
	_dispose_town_building(town_building)
	_dispose_manager(manager)

func test_daily_settlement_deducts_base_and_facility_maintenance_cost() -> void:
	# Arrange
	_captured_warnings.clear()
	_captured_balance_changes.clear()
	var manager: EconomyManager = _make_manager()
	var town_building: TownBuilding = _make_town_building(manager)
	_register_facility(
		town_building,
		FacilityScript.new(1, Facility.FacilityType.TRAINING_GROUND, 2, Facility.FacilityState.ACTIVE, 0, 0, 0)
	)
	_register_facility(
		town_building,
		FacilityScript.new(2, Facility.FacilityType.STADIUM, 3, Facility.FacilityState.UPGRADING, 1, 0, 0)
	)
	var setup_result: Dictionary[String, Variant] = manager.execute_transaction(_make_income_transaction(100.0))
	_expect(setup_result["success"] as bool, "setup income should succeed before maintenance-cost test")
	_captured_warnings.clear()
	_captured_balance_changes.clear()

	# Act
	var result: Dictionary[String, Variant] = manager.settle_day(false, town_building)
	var snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var transaction_log: Array[Transaction] = manager.get_transaction_log()
	var committed_transaction: Transaction = transaction_log[transaction_log.size() - 1]

	# Assert
	_expect(result["success"] as bool, "maintenance settlement should succeed")
	_expect(is_equal_approx(float(result["maintenance_cost"]), 28.0), "maintenance settlement should combine base cost with active-facility maintenance only")
	_expect(is_equal_approx(float(result["facility_maintenance_cost"]), 3.0), "maintenance settlement should report TownBuilding active-facility maintenance total")
	_expect(is_equal_approx(float(snapshot["funds"]), 72.0), "maintenance settlement should deduct the combined maintenance cost from funds")
	_expect(is_equal_approx(committed_transaction.funds_delta, -28.0), "maintenance settlement transaction should store the combined maintenance deduction")
	_expect(not _has_warning_type("funds_low"), "maintenance settlement should not emit a low-funds warning when the committed balance stays above the threshold")
	_expect(_captured_balance_changes.size() == 1, "maintenance settlement should emit exactly one balance-change event")
	_expect(is_equal_approx(float(_captured_balance_changes[0].get("new_funds", 0.0)), 72.0), "balance-change payload should report the committed funds balance")
	_dispose_town_building(town_building)
	_dispose_manager(manager)

func test_daily_settlement_includes_medical_training_adjacency_bonus() -> void:
	# Arrange
	var manager: EconomyManager = _make_manager(12.0)
	var town_building: TownBuilding = _make_town_building(manager)
	_register_facility(
		town_building,
		FacilityScript.new(1, Facility.FacilityType.MEDICAL_ROOM, 4, Facility.FacilityState.ACTIVE, 1, 1, 0)
	)
	_register_facility(
		town_building,
		FacilityScript.new(2, Facility.FacilityType.TRAINING_GROUND, 5, Facility.FacilityState.ACTIVE, 1, 2, 0)
	)

	# Act
	var result: Dictionary[String, Variant] = manager.settle_day(false, town_building)
	var snapshot: Dictionary[String, float] = manager.get_balance_snapshot()

	# Assert
	_expect(result["success"] as bool, "adjacency settlement should succeed")
	_expect(int(result["facility_ap_bonus"]) == 3, "daily settlement should clamp medical-room base bonus plus training adjacency to 3")
	_expect(is_equal_approx(float(result["ap_recovered"]), 8.0), "daily settlement should include the adjacency AP bonus in the recovered AP total")
	_expect(is_equal_approx(float(snapshot["action_points"]), 9.0), "authoritative AP should reflect adjacency-enhanced recovery")
	_dispose_town_building(town_building)
	_dispose_manager(manager)

func _setup_event_bus() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)
	var warning_callback := _capture_warning.bind(_captured_warnings)
	var balance_change_callback := _capture_balance_change.bind(_captured_balance_changes)
	_event_bus().subscribe("economy_warning_triggered", warning_callback)
	_event_bus().subscribe("economy_balance_changed", balance_change_callback)

func _cleanup_event_bus() -> void:
	var event_bus: Node = root.get_node_or_null("EventBus")
	if event_bus != null:
		var warning_callback := _capture_warning.bind(_captured_warnings)
		var balance_change_callback := _capture_balance_change.bind(_captured_balance_changes)
		_event_bus().unsubscribe("economy_warning_triggered", warning_callback)
		_event_bus().unsubscribe("economy_balance_changed", balance_change_callback)
		event_bus.queue_free()

func _make_manager(action_points_max: float = 5.0) -> EconomyManager:
	var manager: EconomyManager = EconomyManagerScript.new()
	manager.name = "EconomyManager"
	root.add_child(manager)
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.action_points_floor = 1.0
	economy_config.research_points_floor = 0.0
	economy_config.funds_low_threshold = 70.0
	economy_config.debt_warning_threshold = 0.0
	economy_config.warning_cooldown_seconds = 300.0
	economy_config.base_ap_recovery = 5.0
	economy_config.base_rest_ap_recovery = 3.0
	economy_config.action_points_max = action_points_max
	economy_config.base_maintenance_cost = 25.0
	manager.set_economy_config_for_testing(economy_config)
	manager.set_event_bus_for_testing(_event_bus())
	return manager

func _make_town_building(manager: EconomyManager) -> TownBuilding:
	var town_config: TownConfig = TownConfigScript.new()
	town_config.medical_ap_bonus_per_level = 0.7
	town_config.facility_maintenance_base = {
		Facility.FacilityType.TRAINING_GROUND: 2,
		Facility.FacilityType.MEDICAL_ROOM: 2,
		Facility.FacilityType.YOUTH_ACADEMY: 3,
		Facility.FacilityType.STADIUM: 4,
	}
	town_config.facility_maintenance_delta = {
		Facility.FacilityType.TRAINING_GROUND: 1,
		Facility.FacilityType.MEDICAL_ROOM: 1,
		Facility.FacilityType.YOUTH_ACADEMY: 1,
		Facility.FacilityType.STADIUM: 2,
	}
	var town_building: TownBuilding = TownBuildingScript.new(town_config, manager)
	town_building.name = "TownBuilding"
	town_building.set_event_bus_for_testing(_event_bus())
	root.add_child(town_building)
	return town_building

func _dispose_manager(manager: EconomyManager) -> void:
	if manager != null:
		manager.queue_free()

func _dispose_town_building(town_building: TownBuilding) -> void:
	if town_building != null:
		town_building.queue_free()

func _register_facility(town_building: TownBuilding, facility: Facility) -> void:
	_expect(town_building.register_facility(facility), "test setup should register facility successfully")

func _make_income_transaction(funds_delta: float) -> Transaction:
	return _make_resource_transaction(funds_delta, 0.0, 0.0, "test_income")

func _make_resource_transaction(funds_delta: float, ap_delta: float, rp_delta: float, reason: String) -> Transaction:
	var transaction := Transaction.new()
	transaction.type = Transaction.TransactionType.TRANSFER
	transaction.funds_delta = funds_delta
	transaction.ap_delta = ap_delta
	transaction.rp_delta = rp_delta
	transaction.reason = reason
	transaction.source_system = "test"
	return transaction

func _has_warning_type(warning_type: String) -> bool:
	for payload: Dictionary in _captured_warnings:
		if String(payload.get("warning_type", "")) == warning_type:
			return true
	return false

func _capture_warning(_event_name: String, payload: Dictionary, sink: Array[Dictionary]) -> void:
	sink.append(_to_typed_dictionary(payload))

func _capture_balance_change(_event_name: String, payload: Dictionary, sink: Array[Dictionary]) -> void:
	sink.append(_to_typed_dictionary(payload))

func _to_typed_dictionary(source: Dictionary) -> Dictionary:
	var typed_dictionary: Dictionary = {}
	for key_variant: Variant in source:
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
