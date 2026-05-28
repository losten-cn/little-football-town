extends SceneTree

const TownBuildingScript: Script = preload("res://src/core/town_building.gd")
const TownConfigScript: Script = preload("res://src/config/town_config.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")
const FacilityScript: Script = preload("res://src/core/facility.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

class SpyEconomyManager:
	extends "res://src/core/economy_manager.gd"

	var accredit_call_count: int = 0
	var last_funds_cost: int = -1
	var last_action_points_cost: int = -1
	var last_facility_id: int = -1

	func accredit_facility_cost(funds_cost: int, action_points_cost: int, facility_id: int = 0) -> Dictionary[String, Variant]:
		accredit_call_count += 1
		last_funds_cost = funds_cost
		last_action_points_cost = action_points_cost
		last_facility_id = facility_id
		return super.accredit_facility_cost(funds_cost, action_points_cost, facility_id)

var _failures: Array[String] = []
var _completion_events: Array[Dictionary] = []

func _initialize() -> void:
	await test_upgrade_starts_from_active_facility_and_preserves_old_level_queries()
	await test_upgrade_rejects_inactive_and_max_level_facilities()
	await test_upgrade_rejects_when_funds_are_insufficient_and_keeps_facility_state()
	await test_time_phase_changed_decrements_each_progress_timer_once()
	await test_completion_event_and_new_level_queries_share_same_tick()
	await test_upgrade_completion_event_and_new_level_queries_share_same_tick()
	if _failures.is_empty():
		print("UPGRADE_COMPLETION_FLOW_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("UPGRADE_COMPLETION_FLOW_TEST_FAIL: %s" % failure)
		quit(1)

func test_upgrade_starts_from_active_facility_and_preserves_old_level_queries() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(1000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for upgrade-start test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	_expect(event_bus.subscriber_count("time_phase_changed") == 1, "town building should subscribe to time_phase_changed on ready")
	_completion_events.clear()
	event_bus.call("subscribe", "town_facility_completed", Callable(self, "_on_completion_event"))

	var build_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 2, 2)
	_expect(build_result["success"] as bool, "setup facility should build successfully before upgrade-start test")
	event_bus.call("emit", "time_phase_changed", {})
	event_bus.call("emit", "time_phase_changed", {})
	event_bus.call("emit", "time_phase_changed", {})
	event_bus.call("emit", "time_phase_changed", {})
	var active_facility: Facility = town_building.get_facility(build_result["facility_id"] as int)
	_expect(active_facility != null, "setup facility should exist after construction completion")
	_expect(active_facility.get_state() == Facility.FacilityState.ACTIVE, "setup facility should become Active before upgrade")
	_expect(active_facility.get_level() == 1, "setup facility should become level 1 after construction completion")
	var old_multiplier: float = town_building.compute_training_efficiency_multiplier()
	var upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(build_result["facility_id"] as int)
	var expected_upgrade_cost: int = town_building.compute_upgrade_funds_cost(Facility.FacilityType.TRAINING_GROUND, 2)["value"] as int
	var upgrading_facility: Facility = town_building.get_facility(build_result["facility_id"] as int)

	_expect(upgrade_result["success"] as bool, "active facility below max level should start upgrading")
	_expect(economy_manager.accredit_call_count == 2, "upgrade start should perform one additional accredited payment call")
	_expect(economy_manager.last_funds_cost == expected_upgrade_cost, "upgrade start should pay the computed level-2 upgrade cost")
	_expect(economy_manager.last_action_points_cost == 0, "upgrade start should request zero action-point cost for MVP fixture")
	_expect(economy_manager.last_facility_id == build_result["facility_id"] as int, "upgrade start should pass the existing facility id to accredit_facility_cost")
	_expect(upgrading_facility.get_state() == Facility.FacilityState.UPGRADING, "upgrade start should set facility state to Upgrading")
	_expect(upgrading_facility.get_level() == 1, "upgrade start should preserve the old level until completion")
	_expect(is_equal_approx(town_building.compute_training_efficiency_multiplier(), old_multiplier), "upgrade start should preserve old-level formula results until completion")

	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func test_upgrade_rejects_inactive_and_max_level_facilities() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(10000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for upgrade rejection test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	_expect(event_bus.subscriber_count("time_phase_changed") == 1, "town building should subscribe to time_phase_changed on ready")

	var build_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 3, 1)
	_expect(build_result["success"] as bool, "setup facility should build successfully before rejection checks")
	var constructing_upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(build_result["facility_id"] as int)
	_expect(not (constructing_upgrade_result["success"] as bool), "constructing facility should reject upgrade requests")
	_expect(String(constructing_upgrade_result["error"]) == "facility_not_active", "constructing facility should reject with facility_not_active")
	for _i: int in range(4):
		event_bus.call("emit", "time_phase_changed", {})
	var facility_id: int = build_result["facility_id"] as int
	for _level_index: int in range(4):
		var upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(facility_id)
		_expect(upgrade_result["success"] as bool, "active facility below max level should keep upgrading during max-level setup")
		var remaining_units: int = town_building.get_facility(facility_id).get_remaining_construction_units()
		for _tick_index: int in range(remaining_units):
			event_bus.call("emit", "time_phase_changed", {})
	var max_level_upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(facility_id)
	_expect(not (max_level_upgrade_result["success"] as bool), "level-5 facility should reject upgrade requests")
	_expect(String(max_level_upgrade_result["error"]) == "already_max_level", "level-5 facility should reject with already_max_level")

	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func test_upgrade_rejects_when_funds_are_insufficient_and_keeps_facility_state() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(economy_config)
	var construction_cost: int = int(ceili(float(town_config.get_base_funds_cost(Facility.FacilityType.TRAINING_GROUND))))
	_expect(economy_manager.execute_transaction(_make_transaction(float(construction_cost), 0.0, 0.0))["success"] as bool, "setup transaction should seed only the construction cost for insufficient-funds test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	var build_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 4, 1)
	_expect(build_result["success"] as bool, "setup facility should build successfully before insufficient-funds upgrade test")
	for _tick_index: int in range(4):
		event_bus.call("emit", "time_phase_changed", {})
	var funds_before_upgrade: float = economy_manager.get_funds()
	var facility_before_upgrade: Facility = town_building.get_facility(build_result["facility_id"] as int)
	var upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(build_result["facility_id"] as int)
	var facility_after_upgrade: Facility = town_building.get_facility(build_result["facility_id"] as int)
	_expect(not (upgrade_result["success"] as bool), "upgrade should reject when funds are insufficient")
	_expect(String(upgrade_result["error"]) == "funds_insufficient", "insufficient-funds upgrade should reject with funds_insufficient")
	_expect(facility_before_upgrade.get_state() == Facility.FacilityState.ACTIVE, "facility should be Active before insufficient-funds upgrade attempt")
	_expect(facility_after_upgrade.get_state() == Facility.FacilityState.ACTIVE, "insufficient-funds upgrade should keep facility Active")
	_expect(facility_after_upgrade.get_level() == 1, "insufficient-funds upgrade should preserve the current facility level")
	_expect(facility_after_upgrade.get_remaining_construction_units() == 0, "insufficient-funds upgrade should not create upgrade progress")
	_expect(is_equal_approx(economy_manager.get_funds(), funds_before_upgrade), "insufficient-funds upgrade should not deduct any funds")

	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func test_time_phase_changed_decrements_each_progress_timer_once() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(2000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for timer test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	_expect(event_bus.subscriber_count("time_phase_changed") == 1, "town building should subscribe to time_phase_changed on ready")
	_completion_events.clear()
	event_bus.call("subscribe", "town_facility_completed", Callable(self, "_on_completion_event"))

	var constructing_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.STADIUM, 0, 0)
	_expect(constructing_result["success"] as bool, "constructing facility should start successfully in timer test")
	var active_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.MEDICAL_ROOM, 1, 0)
	_expect(active_result["success"] as bool, "second setup facility should start successfully in timer test")
	event_bus.call("emit", "time_phase_changed", {})
	event_bus.call("emit", "time_phase_changed", {})
	event_bus.call("emit", "time_phase_changed", {})
	var active_facility: Facility = town_building.get_facility(active_result["facility_id"] as int)
	_expect(active_facility.get_state() == Facility.FacilityState.ACTIVE, "medical room should complete into Active state before upgrade timing test")
	var upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(active_result["facility_id"] as int)
	_expect(upgrade_result["success"] as bool, "active medical room should enter Upgrading state for timer test")

	var constructing_before_tick: Facility = town_building.get_facility(constructing_result["facility_id"] as int)
	var upgrading_before_tick: Facility = town_building.get_facility(active_result["facility_id"] as int)
	var constructing_remaining_before: int = constructing_before_tick.get_remaining_construction_units()
	var upgrading_remaining_before: int = upgrading_before_tick.get_remaining_construction_units()
	event_bus.call("emit", "time_phase_changed", {})
	var constructing_after_tick: Facility = town_building.get_facility(constructing_result["facility_id"] as int)
	var upgrading_after_tick: Facility = town_building.get_facility(active_result["facility_id"] as int)
	_expect(constructing_after_tick.get_remaining_construction_units() == constructing_remaining_before - 1, "constructing timer should decrement exactly once per time_phase_changed")
	_expect(upgrading_after_tick.get_remaining_construction_units() == upgrading_remaining_before - 1, "upgrading timer should decrement exactly once per time_phase_changed")

	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func test_completion_event_and_new_level_queries_share_same_tick() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(1200.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for completion test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	_expect(event_bus.subscriber_count("time_phase_changed") == 1, "town building should subscribe to time_phase_changed on ready")
	_completion_events.clear()
	event_bus.call("subscribe", "town_facility_completed", Callable(self, "_on_completion_event"))

	var build_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 4, 4)
	_expect(build_result["success"] as bool, "setup facility should build successfully before completion test")
	event_bus.call("emit", "time_phase_changed", {})
	event_bus.call("emit", "time_phase_changed", {})
	event_bus.call("emit", "time_phase_changed", {})
	var before_final_tick: Facility = town_building.get_facility(build_result["facility_id"] as int)
	_expect(before_final_tick.get_state() == Facility.FacilityState.CONSTRUCTING, "facility should still be Constructing one tick before completion")
	_expect(before_final_tick.get_remaining_construction_units() == 1, "facility should be one tick away from completion before final tick")
	event_bus.call("emit", "time_phase_changed", {})
	var completed_facility: Facility = town_building.get_facility(build_result["facility_id"] as int)
	_expect(completed_facility.get_state() == Facility.FacilityState.ACTIVE, "facility should become Active on the completion tick")
	_expect(completed_facility.get_level() == 1, "facility should become level 1 on the construction completion tick")
	_expect(completed_facility.get_remaining_construction_units() == 0, "facility should clear remaining construction units on completion")
	_expect(_completion_events.size() == 1, "completion tick should emit exactly one facility completion event")
	_expect(int(_completion_events[0].get("facility_id", 0)) == build_result["facility_id"] as int, "completion event should reference the completed facility id")
	_expect(is_equal_approx(town_building.compute_training_efficiency_multiplier(), 1.05), "new-level formula query should see the completed training ground in the same tick")

	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func test_upgrade_completion_event_and_new_level_queries_share_same_tick() -> void:
	var event_bus: Node = EventBusScript.new()
	var town_config: Resource = TownConfigScript.new()
	var economy_manager := SpyEconomyManager.new()
	economy_manager.set_economy_config_for_testing(EconomyConfigScript.new())
	_expect(economy_manager.execute_transaction(_make_transaction(2000.0, 0.0, 0.0))["success"] as bool, "setup transaction should seed funds for upgrade completion test")
	var town_building: TownBuilding = TownBuildingScript.new(town_config, economy_manager)
	town_building.set_event_bus_for_testing(event_bus)
	var root: Window = get_root()
	root.call_deferred("add_child", town_building)
	await process_frame
	_expect(event_bus.subscriber_count("time_phase_changed") == 1, "town building should subscribe to time_phase_changed on ready")
	_completion_events.clear()
	event_bus.call("subscribe", "town_facility_completed", Callable(self, "_on_completion_event"))

	var build_result: Dictionary[String, Variant] = town_building.build_facility(Facility.FacilityType.TRAINING_GROUND, 1, 4)
	_expect(build_result["success"] as bool, "setup facility should build successfully before upgrade completion test")
	for _i: int in range(4):
		event_bus.call("emit", "time_phase_changed", {})
	_completion_events.clear()
	var upgrade_result: Dictionary[String, Variant] = town_building.upgrade_facility(build_result["facility_id"] as int)
	_expect(upgrade_result["success"] as bool, "active facility should enter upgrade before completion verification")
	var expected_upgrade_time: int = town_building.compute_upgrade_time_cost(Facility.FacilityType.TRAINING_GROUND, 2)["value"] as int
	var before_final_tick: Facility = town_building.get_facility(build_result["facility_id"] as int)
	_expect(before_final_tick.get_state() == Facility.FacilityState.UPGRADING, "facility should be Upgrading before final upgrade completion tick")
	_expect(before_final_tick.get_level() == 1, "facility should preserve old level before final upgrade completion tick")
	_expect(before_final_tick.get_remaining_construction_units() == expected_upgrade_time, "upgrade should start with the computed remaining time cost")
	for _tick_index: int in range(expected_upgrade_time - 1):
		event_bus.call("emit", "time_phase_changed", {})
	var one_tick_before_completion: Facility = town_building.get_facility(build_result["facility_id"] as int)
	_expect(one_tick_before_completion.get_state() == Facility.FacilityState.UPGRADING, "facility should still be Upgrading one tick before upgrade completion")
	_expect(one_tick_before_completion.get_remaining_construction_units() == 1, "facility should be one tick away from upgrade completion before final tick")
	_expect(is_equal_approx(town_building.compute_training_efficiency_multiplier(), 1.05), "old-level training multiplier should remain readable before upgrade completion")
	_completion_events.clear()
	var completion_query_watch: Array[Dictionary] = []
	var completion_callback := _capture_completion_and_query.bind(town_building, completion_query_watch)
	event_bus.call("subscribe", "town_facility_completed", completion_callback)
	_emit_time_phase_changed(event_bus)
	var completed_facility: Facility = town_building.get_facility(build_result["facility_id"] as int)
	_expect(completed_facility.get_state() == Facility.FacilityState.ACTIVE, "facility should become Active on the upgrade completion tick")
	_expect(completed_facility.get_level() == 2, "facility should become level 2 on the upgrade completion tick")
	_expect(completed_facility.get_remaining_construction_units() == 0, "facility should clear remaining construction units on upgrade completion")
	_expect(_completion_events.size() == 1, "upgrade completion tick should emit exactly one facility completion event")
	_expect(int(_completion_events[0].get("facility_id", 0)) == build_result["facility_id"] as int, "upgrade completion event should reference the upgraded facility id")
	_expect(int(_completion_events[0].get("level", 0)) == 2, "upgrade completion event should expose the new level")
	_expect(is_equal_approx(town_building.compute_training_efficiency_multiplier(), 1.10), "new-level training multiplier should be readable in the same tick as upgrade completion")
	_expect(completion_query_watch.size() == 1, "event-time observer should capture exactly one upgrade completion query snapshot")
	_expect(is_equal_approx(float(completion_query_watch[0].get("queried_training_multiplier", 0.0)), 1.10), "event-time query should observe the upgraded training multiplier in the same settlement boundary")
	event_bus.call("unsubscribe", "town_facility_completed", completion_callback)

	root.remove_child(town_building)
	town_building.free()
	economy_manager.free()
	event_bus.free()

func _emit_time_phase_changed(event_bus: Node) -> void:
	event_bus.call("emit", "time_phase_changed", {})

func _on_completion_event(_event_name: String, payload: Dictionary) -> void:
	_completion_events.append(payload.duplicate())

func _capture_completion_and_query(_event_name: String, payload: Dictionary, town_building: TownBuilding, sink: Array[Dictionary]) -> void:
	var snapshot: Dictionary = payload.duplicate()
	snapshot["queried_training_multiplier"] = town_building.compute_training_efficiency_multiplier()
	sink.append(snapshot)

func _make_transaction(funds_delta: float, ap_delta: float, rp_delta: float):
	var transaction = preload("res://src/core/transaction.gd").new()
	transaction.funds_delta = funds_delta
	transaction.ap_delta = ap_delta
	transaction.rp_delta = rp_delta
	transaction.source_system = "test"
	return transaction

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
