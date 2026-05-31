extends SceneTree

const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")
const FacilityScript: Script = preload("res://src/core/facility.gd")

var _failures: Array[String] = []
var _captured_balance_changes: Array[Dictionary] = []
var _captured_warnings: Array[Dictionary] = []


func _event_bus() -> Node:
	return root.get_node("EventBus")


func _initialize() -> void:
	_setup_event_bus()
	test_settlement_batch_processes_in_fixed_serial_priority()
	test_same_frame_cost_requests_validate_against_latest_balances()
	test_representative_season_ledger_reconciles_with_caps_and_rejections()
	_cleanup_event_bus()
	if _failures.is_empty():
		print("SETTLEMENT_ORDER_CONCURRENCY_REGRESSION_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("SETTLEMENT_ORDER_CONCURRENCY_REGRESSION_TEST_FAIL: %s" % failure)
		quit(1)


func test_settlement_batch_processes_in_fixed_serial_priority() -> void:
	# Arrange
	_captured_balance_changes.clear()
	_captured_warnings.clear()
	var manager: EconomyManager = _make_manager(120.0)
	var town_building: TownBuilding = _make_town_building(manager)
	_register_facility(
		town_building,
		FacilityScript.new(1, Facility.FacilityType.MEDICAL_ROOM, 2, Facility.FacilityState.ACTIVE, 0, 0, 0)
	)
	var batch_results: Array[Dictionary] = []

	# Act
	batch_results.append(manager.settle_post_match({
		"match_id": "batch-match",
		"result": "draw",
	}, {
		"league_tier": 2,
		"stadium_revenue_multiplier": 1.24,
		"tactical_rating_ratio": 0.87,
	}))
	batch_results.append(manager.settle_day(false, town_building))
	batch_results.append(manager.settle_stage({
		"stage_number": 2,
		"season_number": 1,
		"current_tier": 1,
		"funds_reward": 100.9,
		"research_points_reward": 12.4,
	}))
	batch_results.append(manager.settle_season({
		"season_number": 1,
		"final_rank": 6,
		"current_tier": 1,
		"next_season_tier": 2,
	}))
	var transaction_log: Array[Transaction] = manager.get_transaction_log()

	# Assert
	for result_variant: Variant in batch_results:
		var result: Dictionary = result_variant as Dictionary
		_expect(result.get("success", false) as bool, "each settlement in the same-frame batch should succeed")
	_expect(transaction_log.size() == 4, "settlement batch should append one committed transaction per settlement type")
	_expect(_transaction_reasons(transaction_log) == [
		"post_match_settlement",
		"daily_settlement",
		"stage_settlement",
		"season_settlement",
	], "settlement batch should preserve fixed serial priority in committed transaction order")
	_expect(_balance_change_reasons() == [
		"post_match_settlement",
		"daily_settlement",
		"stage_settlement",
		"season_settlement",
	], "balance-change events should mirror the committed settlement order without interleaving")
	_expect(int(transaction_log[0].id) == 1, "first settlement should receive the first committed transaction id")
	_expect(int(transaction_log[3].id) == 4, "same-frame settlement batch should advance tx ids serially")
	_dispose_town_building(town_building)
	_dispose_manager(manager)


func test_same_frame_cost_requests_validate_against_latest_balances() -> void:
	# Arrange
	_captured_balance_changes.clear()
	_captured_warnings.clear()
	var manager: EconomyManager = _make_manager(120.0)
	_expect(manager.execute_transaction(_make_resource_transaction(50.0, 0.0, 0.0, "test_funds_setup"))["success"] as bool, "same-frame cost setup should seed funds before AP floor coverage")
	var before_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()

	# Act
	var first_training_result: Dictionary[String, Variant] = manager.accredit_training_cost(20, 0, 10)
	var facility_result: Dictionary[String, Variant] = manager.accredit_facility_cost(0, 1, 20)
	var rejected_training_result: Dictionary[String, Variant] = manager.accredit_training_cost(5, 1, 30)
	var transaction_log: Array[Transaction] = manager.get_transaction_log()
	var after_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()

	# Assert
	_expect(first_training_result["success"] as bool, "first same-frame cost request should succeed")
	_expect(facility_result["success"] as bool, "second same-frame cost request should succeed while resources remain sufficient")
	_expect(not (rejected_training_result.get("success", false) as bool), "later same-frame cost request should fail once the updated AP balance hits the floor")
	_expect(String(rejected_training_result.get("error", "")) == "ap_below_floor", "rejected same-frame cost request should fail with the latest-balance floor error")
	_expect(transaction_log.size() == 3, "rejected same-frame cost request must not append a committed transaction")
	_expect(_transaction_reasons(transaction_log) == ["test_funds_setup", "training_cost", "facility_cost"], "successful same-frame cost requests should commit in submission order")
	_expect(is_equal_approx(float(after_snapshot["funds"]), float(before_snapshot["funds"]) - 20.0), "only successful same-frame cost requests should reduce funds")
	_expect(is_equal_approx(float(after_snapshot["action_points"]), float(before_snapshot["action_points"]) - 1.0), "failed same-frame cost request must not leave partial AP deltas")
	_expect(_captured_balance_changes.size() == 3, "setup plus successful same-frame cost requests should emit balance-change events")
	_dispose_manager(manager)


func test_representative_season_ledger_reconciles_with_caps_and_rejections() -> void:
	# Arrange
	_captured_balance_changes.clear()
	_captured_warnings.clear()
	var manager: EconomyManager = _make_manager(100.0)
	var town_building: TownBuilding = _make_town_building(manager)
	_register_facility(
		town_building,
		FacilityScript.new(1, Facility.FacilityType.TRAINING_GROUND, 2, Facility.FacilityState.ACTIVE, 0, 0, 0)
	)
	var starting_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	_expect(manager.execute_transaction(_make_resource_transaction(0.0, 0.0, 90.0, "test_rp_setup"))["success"] as bool, "season ledger setup should succeed before overflow coverage")
	var rejected_result: Dictionary[String, Variant] = {}
	var season_step_results: Array[Dictionary] = []

	# Act
	season_step_results.append(manager.settle_post_match({
		"match_id": "season-match-1",
		"result": "loss",
	}, {
		"league_tier_multiplier": 1.0,
		"stadium_revenue_multiplier": 1.0,
		"tactical_rating_ratio": 1.8,
	}))
	rejected_result = manager.accredit_training_cost(10, 2, 44)
	season_step_results.append(manager.settle_day(false, town_building))
	season_step_results.append(manager.settle_stage({
		"stage_number": 2,
		"season_number": 1,
		"current_tier": 1,
		"funds_reward": 50.2,
		"research_points_reward": 8.9,
	}))
	season_step_results.append(manager.settle_season({
		"season_number": 1,
		"final_rank": 10,
		"current_tier": 1,
		"next_season_tier": 2,
	}))
	var ending_snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var transaction_log: Array[Transaction] = manager.get_transaction_log()

	# Assert
	for result_variant: Variant in season_step_results:
		var result: Dictionary = result_variant as Dictionary
		_expect(result.get("success", false) as bool, "each representative season settlement step should succeed")
	_expect(not (rejected_result.get("success", false) as bool), "rejected season cost request should fail without mutating ledger state")
	_expect(String(rejected_result.get("error", "")) == "ap_below_floor", "rejected season cost request should fail against the latest AP floor")
	_expect(transaction_log.size() == 5, "representative season ledger should keep setup plus four committed settlement transactions only")
	_expect(_transaction_reasons(transaction_log) == [
		"test_rp_setup",
		"post_match_settlement",
		"daily_settlement",
		"stage_settlement",
		"season_settlement",
	], "representative season ledger should preserve committed order and omit rejected requests")
	_expect(int(season_step_results[0].get("discarded_overflow", -1)) == 5, "season regression should include RP cap overflow in post-match settlement")
	_expect(is_equal_approx(float(ending_snapshot["funds"]), float(starting_snapshot["funds"]) + _sum_transaction_delta(transaction_log, "funds")), "ending funds should reconcile against the committed ledger deltas")
	_expect(is_equal_approx(float(ending_snapshot["action_points"]), float(starting_snapshot["action_points"]) + _sum_transaction_delta(transaction_log, "ap")), "ending AP should reconcile against the committed ledger deltas")
	_expect(is_equal_approx(float(ending_snapshot["research_points"]), float(starting_snapshot["research_points"]) + _sum_transaction_delta(transaction_log, "rp")), "ending RP should reconcile against the committed ledger deltas")
	_expect(_captured_balance_changes.size() == transaction_log.size(), "each committed ledger entry should emit exactly one balance-change event")
	_expect(_has_warning_type("funds_low"), "representative season ledger should still trigger legal warning checks during committed settlement flow")
	_dispose_town_building(town_building)
	_dispose_manager(manager)


func _setup_event_bus() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)
	var balance_change_callback := _capture_balance_change.bind(_captured_balance_changes)
	var warning_callback := _capture_warning.bind(_captured_warnings)
	_event_bus().subscribe("economy_balance_changed", balance_change_callback)
	_event_bus().subscribe("economy_warning_triggered", warning_callback)


func _cleanup_event_bus() -> void:
	var event_bus: Node = root.get_node_or_null("EventBus")
	if event_bus != null:
		var balance_change_callback := _capture_balance_change.bind(_captured_balance_changes)
		var warning_callback := _capture_warning.bind(_captured_warnings)
		_event_bus().unsubscribe("economy_balance_changed", balance_change_callback)
		_event_bus().unsubscribe("economy_warning_triggered", warning_callback)
		event_bus.queue_free()


func _make_manager(research_points_max: float = 100.0) -> EconomyManager:
	var manager: EconomyManager = EconomyManagerScript.new()
	manager.name = "EconomyManager"
	root.add_child(manager)
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.action_points_floor = 0.0
	economy_config.action_points_low_threshold = 1.0
	economy_config.research_points_floor = 0.0
	economy_config.funds_low_threshold = 80.0
	economy_config.debt_warning_threshold = 0.0
	economy_config.warning_cooldown_seconds = 300.0
	economy_config.base_ap_recovery = 5.0
	economy_config.base_rest_ap_recovery = 3.0
	economy_config.action_points_max = 12.0
	economy_config.base_maintenance_cost = 25.0
	economy_config.base_match_funds = 250.0
	economy_config.match_result_win_multiplier = 1.0
	economy_config.match_result_draw_multiplier = 0.6
	economy_config.match_result_loss_multiplier = 0.4
	economy_config.league_tier_multipliers = {1: 1.0, 2: 1.3}
	economy_config.tactical_rp_base = 15.0
	economy_config.research_points_max = research_points_max
	economy_config.base_season_bonus = 1000.0
	economy_config.base_season_research = 100.0
	economy_config.season_ranking_multipliers = {1: 1.5, 6: 1.0, 10: 0.5}
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


func _make_resource_transaction(funds_delta: float, ap_delta: float, rp_delta: float, reason: String) -> Transaction:
	var transaction := Transaction.new()
	transaction.type = Transaction.TransactionType.TRANSFER
	transaction.funds_delta = funds_delta
	transaction.ap_delta = ap_delta
	transaction.rp_delta = rp_delta
	transaction.reason = reason
	transaction.source_system = "test"
	return transaction


func _transaction_reasons(transaction_log: Array[Transaction]) -> Array[String]:
	var reasons: Array[String] = []
	for transaction: Transaction in transaction_log:
		reasons.append(transaction.reason)
	return reasons


func _balance_change_reasons() -> Array[String]:
	var reasons: Array[String] = []
	for payload: Dictionary in _captured_balance_changes:
		reasons.append(String(payload.get("reason", "")))
	return reasons


func _sum_transaction_delta(transaction_log: Array[Transaction], resource_key: String) -> float:
	var total: float = 0.0
	for transaction: Transaction in transaction_log:
		match resource_key:
			"funds":
				total += transaction.funds_delta
			"ap":
				total += transaction.ap_delta
			"rp":
				total += transaction.rp_delta
	return total


func _has_warning_type(warning_type: String) -> bool:
	for payload: Dictionary in _captured_warnings:
		if String(payload.get("warning_type", "")) == warning_type:
			return true
	return false


func _capture_balance_change(_event_name: String, payload: Dictionary, sink: Array[Dictionary]) -> void:
	sink.append(_to_typed_dictionary(payload))


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
