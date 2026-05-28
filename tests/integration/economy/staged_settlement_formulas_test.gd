extends SceneTree

const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")

var _failures: Array[String] = []
var _captured_balance_changes: Array[Dictionary] = []


func _event_bus() -> Node:
	return root.get_node("EventBus")


func _initialize() -> void:
	_setup_event_bus()
	test_post_match_settlement_applies_formula_and_floor_rounding()
	test_stage_and_season_settlement_use_current_context()
	test_settlement_clamps_abnormal_inputs_and_reports_overflow()
	_cleanup_event_bus()
	if _failures.is_empty():
		print("STAGED_SETTLEMENT_FORMULAS_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("STAGED_SETTLEMENT_FORMULAS_TEST_FAIL: %s" % failure)
		quit(1)


func test_post_match_settlement_applies_formula_and_floor_rounding() -> void:
	# Arrange
	_captured_balance_changes.clear()
	var manager: EconomyManager = _make_manager()
	var match_result_packet: Dictionary[String, Variant] = {
		"match_id": "story-006-match",
		"result": "draw",
	}
	var settlement_context: Dictionary[String, Variant] = {
		"league_tier": 2,
		"stadium_revenue_multiplier": 1.24,
		"tactical_rating_ratio": 0.87,
	}

	# Act
	var result: Dictionary[String, Variant] = manager.settle_post_match(match_result_packet, settlement_context)
	var snapshot: Dictionary[String, float] = manager.get_balance_snapshot()
	var transaction_log: Array[Transaction] = manager.get_transaction_log()
	var committed_transaction: Transaction = transaction_log[transaction_log.size() - 1]

	# Assert
	_expect(result["success"] as bool, "post-match settlement should succeed")
	_expect(int(result["funds_reward"]) == 241, "post-match funds should apply league tier, result, stadium multiplier, and floor rounding")
	_expect(int(result["research_points_reward"]) == 16, "post-match research should apply tactical ratio, league multiplier, and floor rounding")
	_expect(is_equal_approx(float(snapshot["funds"]), 241.0), "post-match settlement should commit funds reward to the authoritative balance")
	_expect(is_equal_approx(float(snapshot["research_points"]), 16.0), "post-match settlement should commit research reward to the authoritative balance")
	_expect(committed_transaction.reason == "post_match_settlement", "post-match settlement should write the post_match_settlement audit reason")
	_expect(committed_transaction.source_system == "match", "post-match settlement should attribute source_system to match")
	_expect(is_equal_approx(float(committed_transaction.metadata.get("league_tier_multiplier", 0.0)), 1.3), "post-match settlement should resolve the current league tier multiplier")
	_expect(_captured_balance_changes.size() == 1, "post-match settlement should emit one balance-change event")
	_dispose_manager(manager)


func test_stage_and_season_settlement_use_current_context() -> void:
	# Arrange
	var manager: EconomyManager = _make_manager(500.0)
	var stage_context: Dictionary[String, Variant] = {
		"stage_number": 2,
		"season_number": 1,
		"current_tier": 1,
		"funds_reward": 100.9,
		"research_points_reward": 12.4,
	}
	var season_context: Dictionary[String, Variant] = {
		"season_number": 1,
		"final_rank": 6,
		"current_tier": 1,
		"next_season_tier": 2,
	}

	# Act
	var stage_result: Dictionary[String, Variant] = manager.settle_stage(stage_context)
	var season_result: Dictionary[String, Variant] = manager.settle_season(season_context)
	var transaction_log: Array[Transaction] = manager.get_transaction_log()
	var stage_transaction: Transaction = transaction_log[0]
	var season_transaction: Transaction = transaction_log[1]

	# Assert
	_expect(stage_result["success"] as bool, "stage settlement should succeed")
	_expect(season_result["success"] as bool, "season settlement should succeed")
	_expect(int(stage_result["funds_reward"]) == 100, "stage settlement should floor current-context funds reward")
	_expect(int(stage_result["research_points_reward"]) == 12, "stage settlement should floor current-context research reward")
	_expect(int(season_result["funds_reward"]) == 1000, "season settlement should compute funds from current tier and current ranking context")
	_expect(int(season_result["research_points_reward"]) == 100, "season settlement should compute research from current tier context")
	_expect(int(stage_transaction.metadata.get("current_tier", 0)) == 1, "stage settlement should preserve current context in metadata")
	_expect(int(season_transaction.metadata.get("current_tier", 0)) == 1, "season settlement should use current tier context rather than next-season state")
	_expect(int(season_transaction.metadata.get("next_season_tier", 0)) == 2, "season settlement may carry next-season context as metadata without using it for reward computation")
	_expect(is_equal_approx(float(season_transaction.metadata.get("ranking_multiplier", 0.0)), 1.0), "season settlement should resolve ranking multiplier from current final rank")
	_expect(is_equal_approx(float(season_transaction.metadata.get("tier_multiplier", 0.0)), 1.0), "season settlement should resolve tier multiplier from current tier")
	_dispose_manager(manager)


func test_settlement_clamps_abnormal_inputs_and_reports_overflow() -> void:
	# Arrange
	var manager: EconomyManager = _make_manager(100.0)
	var setup_result: Dictionary[String, Variant] = manager.execute_transaction(_make_resource_transaction(0.0, 0.0, 90.0, "test_rp_setup"))
	_expect(setup_result["success"] as bool, "research setup should succeed before overflow test")
	var match_result_packet: Dictionary[String, Variant] = {
		"match_id": "overflow-match",
		"result": "loss",
	}
	var settlement_context: Dictionary[String, Variant] = {
		"league_tier_multiplier": 1.0,
		"stadium_revenue_multiplier": 1.0,
		"tactical_rating_ratio": 1.8,
	}

	# Act
	var result: Dictionary[String, Variant] = manager.settle_post_match(match_result_packet, settlement_context)
	var low_ratio_result: Dictionary[String, Variant] = manager.settle_post_match(match_result_packet, {
		"league_tier_multiplier": 1.0,
		"stadium_revenue_multiplier": 1.0,
		"tactical_rating_ratio": 0.1,
	})
	var transaction_log: Array[Transaction] = manager.get_transaction_log()
	var overflow_transaction: Transaction = transaction_log[1]
	var low_ratio_transaction: Transaction = transaction_log[2]

	# Assert
	_expect(result["success"] as bool, "overflow-clamp settlement should succeed")
	_expect(int(result["funds_reward"]) == 100, "loss result should use the floored minimum funds reward")
	_expect(is_equal_approx(float(result["applied_tactical_rating_ratio"]), 1.0), "high tactical ratio should clamp down to 1.0")
	_expect(int(result["research_points_reward"]) == 10, "research reward should clamp to remaining capacity at the RP cap")
	_expect(int(result["discarded_overflow"]) == 5, "overflow above RP cap should be reported")
	_expect(is_equal_approx(float(overflow_transaction.metadata.get("tactical_rating_ratio", 0.0)), 1.0), "clamped high tactical ratio should be stored in audit metadata")
	_expect(low_ratio_result["success"] as bool, "low-ratio settlement should still succeed")
	_expect(is_equal_approx(float(low_ratio_result["applied_tactical_rating_ratio"]), 0.3), "low tactical ratio should clamp up to 0.3")
	_expect(is_equal_approx(float(low_ratio_transaction.metadata.get("tactical_rating_ratio", 0.0)), 0.3), "clamped low tactical ratio should be stored in audit metadata")
	_dispose_manager(manager)


func _setup_event_bus() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)
	var balance_change_callback := _capture_balance_change.bind(_captured_balance_changes)
	_event_bus().subscribe("economy_balance_changed", balance_change_callback)


func _cleanup_event_bus() -> void:
	var event_bus: Node = root.get_node_or_null("EventBus")
	if event_bus != null:
		var balance_change_callback := _capture_balance_change.bind(_captured_balance_changes)
		_event_bus().unsubscribe("economy_balance_changed", balance_change_callback)
		event_bus.queue_free()


func _make_manager(research_points_max: float = 100.0) -> EconomyManager:
	var manager: EconomyManager = EconomyManagerScript.new()
	manager.name = "EconomyManager"
	root.add_child(manager)
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.action_points_floor = 0.0
	economy_config.research_points_floor = 0.0
	economy_config.funds_low_threshold = -1000.0
	economy_config.debt_warning_threshold = -1000.0
	economy_config.warning_cooldown_seconds = 300.0
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


func _make_resource_transaction(funds_delta: float, ap_delta: float, rp_delta: float, reason: String) -> Transaction:
	var transaction := Transaction.new()
	transaction.type = Transaction.TransactionType.TRANSFER
	transaction.funds_delta = funds_delta
	transaction.ap_delta = ap_delta
	transaction.rp_delta = rp_delta
	transaction.reason = reason
	transaction.source_system = "test"
	return transaction


func _dispose_manager(manager: EconomyManager) -> void:
	if manager != null:
		manager.queue_free()


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
