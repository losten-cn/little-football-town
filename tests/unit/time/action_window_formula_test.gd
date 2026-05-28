extends SceneTree

const TimeManagerScript: Script = preload("res://src/autoload/time_manager.gd")
const EventBusScript: Script = preload("res://src/autoload/event_bus.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var event_bus: Node = EventBusScript.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	test_action_time_cost_matches_formula()
	test_invalid_action_time_cost_inputs_are_blocked()
	test_available_action_windows_uses_floor_formula()
	test_available_action_windows_never_returns_negative_values()
	test_insufficient_remaining_time_blocks_action_with_failure_reason()
	if _failures.is_empty():
		print("ACTION_WINDOW_FORMULA_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("ACTION_WINDOW_FORMULA_TEST_FAIL: %s" % failure)
		quit(1)


func test_action_time_cost_matches_formula() -> void:
	# Arrange
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.add_child(time_manager)

	# Act
	var half_cost: Dictionary[String, Variant] = time_manager.calculate_action_time_cost(4.0, 0.5)
	var double_cost: Dictionary[String, Variant] = time_manager.calculate_action_time_cost(4.0, 2.0)

	# Assert
	_expect(half_cost["success"] as bool, "half modifier should produce a valid action time cost")
	_expect(double_cost["success"] as bool, "double modifier should produce a valid action time cost")
	_expect(is_equal_approx(float(half_cost["action_time_cost"]), 2.0), "action time cost should equal base_time_cost × time_cost_modifier for 0.5 modifier")
	_expect(is_equal_approx(float(double_cost["action_time_cost"]), 8.0), "action time cost should equal base_time_cost × time_cost_modifier for 2.0 modifier")


func test_invalid_action_time_cost_inputs_are_blocked() -> void:
	# Arrange
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.add_child(time_manager)

	# Act
	var zero_base_result: Dictionary[String, Variant] = time_manager.calculate_action_time_cost(0.0, 1.0)
	var zero_modifier_result: Dictionary[String, Variant] = time_manager.calculate_action_time_cost(2.0, 0.0)
	var negative_result: Dictionary[String, Variant] = time_manager.calculate_action_time_cost(-1.0, 1.0)

	# Assert
	_expect(not (zero_base_result["success"] as bool), "zero base_time_cost should be blocked")
	_expect(not (zero_modifier_result["success"] as bool), "zero time_cost_modifier should be blocked")
	_expect(not (negative_result["success"] as bool), "negative time cost inputs should be blocked")
	_expect(String(zero_base_result["reason"]) == "invalid_time_cost", "invalid base_time_cost should report invalid_time_cost")
	_expect(String(zero_modifier_result["reason"]) == "invalid_time_cost", "invalid modifier should report invalid_time_cost")
	_expect(String(negative_result["reason"]) == "invalid_time_cost", "negative inputs should report invalid_time_cost")


func test_available_action_windows_uses_floor_formula() -> void:
	# Arrange
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.add_child(time_manager)
	time_manager.apply_snapshot({
		"available_action_windows": {
			"current_phase_time_budget": 10,
			"reserved_time": 3,
			"consumed_time": 2,
			"standard_window_size": 2,
		}
	})

	# Act
	var available_action_windows: int = time_manager.get_available_action_windows()

	# Assert
	_expect(available_action_windows == 2, "available action windows should use floor((budget - reserved - consumed) / standard_window_size)")


func test_available_action_windows_never_returns_negative_values() -> void:
	# Arrange
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.add_child(time_manager)
	time_manager.apply_snapshot({
		"available_action_windows": {
			"current_phase_time_budget": 4,
			"reserved_time": 3,
			"consumed_time": 5,
			"standard_window_size": 1,
		}
	})

	# Act
	var available_action_windows: int = time_manager.get_available_action_windows()

	# Assert
	_expect(available_action_windows == 0, "available action windows should clamp at zero when reserved and consumed time exceed budget")


func test_insufficient_remaining_time_blocks_action_with_failure_reason() -> void:
	# Arrange
	var time_manager: Node = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	root.add_child(time_manager)
	time_manager.apply_snapshot({
		"available_action_windows": {
			"current_phase_time_budget": 5,
			"reserved_time": 1,
			"consumed_time": 3,
			"standard_window_size": 1,
		}
	})

	# Act
	var blocked_result: Dictionary[String, Variant] = time_manager.can_consume_action_time(2.0)
	var allowed_result: Dictionary[String, Variant] = time_manager.can_consume_action_time(1.0)

	# Assert
	_expect(not (blocked_result["success"] as bool), "insufficient remaining time should block the action")
	_expect(String(blocked_result["reason"]) == "insufficient_time", "blocked action should report insufficient_time")
	_expect(is_equal_approx(float(blocked_result["remaining_time"]), 1.0), "blocked action should report the current remaining time")
	_expect(allowed_result["success"] as bool, "remaining time equal to the action cost should allow the action")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
