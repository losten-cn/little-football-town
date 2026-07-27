extends SceneTree
## Story 002 — Reputation calculation + level progression automated tests.
##
## AC-1: formula correctness (base=12,bonus=3,weight=1.0,stage=1.0 → 15)
## AC-2: progress ratio (total=135,current=100,next=180 → 0.4375)
## AC-3: multi-level crossing (total=320, Lv.2→Lv.3→Lv.4)
## AC-4: single-writer durable truth fields
## AC-5: config-driven thresholds
##
## Implements TR-reputation-001 and TR-reputation-002 validation.

const ReputationAchievementManagerScript: Script = preload("res://src/core/reputation_achievement_manager.gd")
const ReputationConfigScript: Script = preload("res://src/config/reputation_config.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_ac1_formula_correctness()
	test_ac2_progress_ratio()
	test_ac3_multi_level_crossing()
	test_ac4_single_writer_durable_truth_fields()
	test_ac5_config_driven_thresholds()
	test_edge_zero_gain_early_return()
	test_edge_negative_gain_guard()
	test_edge_apply_config_null_keeps_defaults()
	test_edge_apply_config_invalid_keeps_defaults()
	test_edge_reputation_changed_signal()
	test_edge_exact_threshold_boundary()
	test_edge_exceed_max_level()
	test_edge_negative_weights_guard()

	if _failures.is_empty():
		print("REPUTATION_FORMULA_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("REPUTATION_FORMULA_TEST_FAIL: %s" % failure)
		quit(1)


# ─────────────────────────────────────────────
# AC-1 — Reputation gain formula correctness
# ─────────────────────────────────────────────

func test_ac1_formula_correctness() -> void:
	# Arrange
	var manager: Node = ReputationAchievementManagerScript.new() as Node

	# Act — Example 1 from GDD: normal match win
	var result_1: int = manager.calculate_reputation_gain(12, 3, 1.0, 1.0)

	# Assert
	_expect(result_1 == 15, "AC-1 Example 1: floor((12+3)*1.0*1.0) should be 15, got %d" % result_1)

	# Act — Example 2 from GDD: season promotion settlement
	var result_2: int = manager.calculate_reputation_gain(40, 20, 1.5, 1.2)

	# Assert
	var expected_2: int = floori(float(40 + 20) * 1.5 * 1.2)  # floor(108) = 108
	_expect(result_2 == expected_2, "AC-1 Example 2: floor((40+20)*1.5*1.2) should be %d, got %d" % [expected_2, result_2])

	# Act — Edge: zero base and bonus
	var result_3: int = manager.calculate_reputation_gain(0, 0, 1.0, 1.0)
	_expect(result_3 == 0, "AC-1 Zero: floor((0+0)*1.0*1.0) should be 0, got %d" % result_3)

	# Act — Edge: fractional result truncation
	var result_4: int = manager.calculate_reputation_gain(7, 2, 0.75, 1.3)
	# (7+2) * 0.75 * 1.3 = 9 * 0.75 * 1.3 = 9 * 0.975 = 8.775, floor = 8
	var expected_4: int = floori(float(7 + 2) * 0.75 * 1.3)
	_expect(result_4 == expected_4, "AC-1 Fractional: floor(9*0.75*1.3) should be %d, got %d" % [expected_4, result_4])

	# Act — Negative base should return 0 (error guard)
	var result_5: int = manager.calculate_reputation_gain(-5, 10, 1.0, 1.0)
	_expect(result_5 == 0, "AC-1 Negative base: should return 0 on invalid input, got %d" % result_5)

	manager.free()


# ─────────────────────────────────────────────
# AC-2 — Progress ratio
# ─────────────────────────────────────────────

func test_ac2_progress_ratio() -> void:
	# Arrange — create manager and manually set fields to test ratio formula
	var manager: Node = ReputationAchievementManagerScript.new() as Node

	# Set up a specific threshold table for isolated ratio testing.
	var config: Resource = _make_test_config({1: 0, 2: 100, 3: 180, 4: 260, 5: 360})
	manager.apply_config(config)

	# Scenario 1: GDD Example — total=135, Lv.2 (threshold 100→180)
	manager.reputation_total = 135
	manager.reputation_level = 2
	manager._recompute_progress_ratio()
	var ratio_1: float = manager.get_reputation_progress_ratio()
	# (135 - 100) / (180 - 100) = 35 / 80 = 0.4375
	_expect(is_equal_approx(ratio_1, 0.4375), "AC-2 Scenario 1: progress ratio should be 0.4375, got %.6f" % ratio_1)

	# Scenario 2: GDD Example — total=180 (exactly at next threshold)
	manager.reputation_total = 180
	manager.reputation_level = 2
	manager._recompute_progress_ratio()
	var ratio_2: float = manager.get_reputation_progress_ratio()
	_expect(is_equal_approx(ratio_2, 1.0), "AC-2 Scenario 2: exactly at threshold should be 1.0, got %.6f" % ratio_2)

	# Scenario 3: Edge — total below current threshold (data anomaly → clamp to 0.0)
	manager.reputation_total = 50
	manager.reputation_level = 2
	manager._recompute_progress_ratio()
	var ratio_3: float = manager.get_reputation_progress_ratio()
	_expect(is_equal_approx(ratio_3, 0.0), "AC-2 Scenario 3: below threshold anomaly should clamp to 0.0, got %.6f" % ratio_3)

	# Scenario 4: Edge — at max level, no next threshold (progress = 1.0)
	manager.reputation_total = 500
	manager.reputation_level = 5
	manager._recompute_progress_ratio()
	var ratio_4: float = manager.get_reputation_progress_ratio()
	_expect(is_equal_approx(ratio_4, 1.0), "AC-2 Scenario 4: at max level should be 1.0, got %.6f" % ratio_4)

	# Scenario 5: Zero interval — level 1 threshold=0, so 0→100
	manager.reputation_total = 0
	manager.reputation_level = 1
	manager._recompute_progress_ratio()
	var ratio_5: float = manager.get_reputation_progress_ratio()
	_expect(is_equal_approx(ratio_5, 0.0), "AC-2 Scenario 5: total=0 at Lv.1 should be 0.0, got %.6f" % ratio_5)

	manager.free()


# ─────────────────────────────────────────────
# AC-3 — Multi-level crossing
# ─────────────────────────────────────────────

func test_ac3_multi_level_crossing() -> void:
	# Arrange — start at Lv.2 with total=100 (exactly at Lv.2 threshold)
	var manager: Node = ReputationAchievementManagerScript.new() as Node
	var config: Resource = _make_test_config({1: 0, 2: 100, 3: 180, 4: 260, 5: 360})
	manager.apply_config(config)

	manager.reputation_total = 100
	manager.reputation_level = 2
	manager._recompute_progress_ratio()

	# Track level-up signals
	var leveled_up_to: Array[int] = []
	var _connect_leveled_up: Callable = func(level: int):
		leveled_up_to.append(level)
	manager.reputation_leveled_up.connect(_connect_leveled_up)

	# Act — apply gain that should cross Lv.2→Lv.3→Lv.4
	# From total=100, add 220 → total=320
	# Lv.2 threshold 100, Lv.3 threshold 180 → crosses to Lv.3
	# Lv.3 threshold 180, Lv.4 threshold 260 → total 320 >= 260 → crosses to Lv.4
	# Lv.4 threshold 260, Lv.5 threshold 360 → total 320 < 360 → stays at Lv.4
	manager.process_reputation_gain(220)

	# Assert — final state
	_expect(manager.reputation_total == 320, "AC-3: total should be 320, got %d" % manager.reputation_total)
	_expect(manager.reputation_level == 4, "AC-3: level should be 4, got %d" % manager.reputation_level)

	# Assert — progress ratio at Lv.4: (320-260)/(360-260) = 60/100 = 0.60
	var final_ratio: float = manager.get_reputation_progress_ratio()
	_expect(is_equal_approx(final_ratio, 0.60), "AC-3: progress ratio should be 0.60, got %.6f" % final_ratio)

	# Assert — level-up signals emitted in order
	_expect(leveled_up_to.size() == 2, "AC-3: should emit 2 level-up signals, got %d" % leveled_up_to.size())
	if leveled_up_to.size() >= 2:
		_expect(leveled_up_to[0] == 3, "AC-3: first level-up should be to Lv.3, got Lv.%d" % leveled_up_to[0])
		_expect(leveled_up_to[1] == 4, "AC-3: second level-up should be to Lv.4, got Lv.%d" % leveled_up_to[1])

	manager.free()


# ─────────────────────────────────────────────
# AC-4 — Single-writer durable truth fields
# ─────────────────────────────────────────────

func test_ac4_single_writer_durable_truth_fields() -> void:
	# Arrange
	var manager: Node = ReputationAchievementManagerScript.new() as Node

	# Assert — the three durable fields exist on the manager instance
	_expect(manager.has_method("calculate_reputation_gain"), "AC-4: manager must expose calculate_reputation_gain")
	_expect(manager.has_method("get_reputation_progress_ratio"), "AC-4: manager must expose get_reputation_progress_ratio")
	_expect(manager.has_method("process_reputation_gain"), "AC-4: manager must expose process_reputation_gain")

	# Verify reputation_total is an int and starts at 0
	_expect(manager.reputation_total is int, "AC-4: reputation_total must be int")
	_expect(manager.reputation_total == 0, "AC-4: reputation_total must start at 0, got %d" % manager.reputation_total)

	# Verify reputation_level is an int and starts at 1
	_expect(manager.reputation_level is int, "AC-4: reputation_level must be int")
	_expect(manager.reputation_level == 1, "AC-4: reputation_level must start at 1, got %d" % manager.reputation_level)

	# Verify reputation_progress_ratio is a float and starts at 0.0
	_expect(manager.reputation_progress_ratio is float, "AC-4: reputation_progress_ratio must be float")
	_expect(is_equal_approx(manager.reputation_progress_ratio, 0.0), "AC-4: reputation_progress_ratio must start at 0.0, got %.6f" % manager.reputation_progress_ratio)

	# Verify process_reputation_gain mutates the durable fields (writer ownership)
	var config: Resource = _make_test_config({1: 0, 2: 100, 3: 180, 4: 260, 5: 360})
	manager.apply_config(config)

	manager.process_reputation_gain(50)
	_expect(manager.reputation_total == 50, "AC-4: after gain 50, total should be 50, got %d" % manager.reputation_total)
	_expect(manager.reputation_level == 1, "AC-4: after gain 50 at Lv.1, level should still be 1, got %d" % manager.reputation_level)
	_expect(is_equal_approx(manager.reputation_progress_ratio, 0.5), "AC-4: after gain 50, Lv.1 progress should be 0.5 (50/100), got %.6f" % manager.reputation_progress_ratio)

	# Verify signals exist
	_expect(manager.has_signal("reputation_leveled_up"), "AC-4: manager must have reputation_leveled_up signal")
	_expect(manager.has_signal("reputation_changed"), "AC-4: manager must have reputation_changed signal")

	manager.free()


# ─────────────────────────────────────────────
# AC-5 — Config-driven thresholds
# ─────────────────────────────────────────────

func test_ac5_config_driven_thresholds() -> void:
	# Arrange — custom config with non-default thresholds
	var custom_config: ReputationConfig = ReputationConfigScript.new() as ReputationConfig
	custom_config.reputation_level_thresholds = {
		1: 0,
		2: 50,
		3: 120,
		4: 200,
	}

	# Validate custom config
	var validation: Dictionary[String, Variant] = custom_config.validate()
	_expect(validation["valid"] as bool, "AC-5: custom config must be valid. Errors: %s" % str(validation.get("errors", [])))

	# Create manager and apply custom config
	var manager: Node = ReputationAchievementManagerScript.new() as Node
	manager.apply_config(custom_config)

	# Act — gain that crosses all thresholds using the custom table
	manager.process_reputation_gain(250)

	# Assert — using custom thresholds
	# Lv.1 threshold=0, Lv.2=50, Lv.3=120, Lv.4=200
	# total=250: crosses Lv.1→Lv.2 at 50, Lv.2→Lv.3 at 120, Lv.3→Lv.4 at 200
	# stays at Lv.4 (no Lv.5 defined)
	_expect(manager.reputation_total == 250, "AC-5: total should be 250, got %d" % manager.reputation_total)
	_expect(manager.reputation_level == 4, "AC-5: level should be max 4, got %d" % manager.reputation_level)
	# Progress: (250-200)/(200-200) → denominator 0 → max(1,0)=1, so (250-200)/1 = 50.0 → clamped to 1.0
	_expect(is_equal_approx(manager.get_reputation_progress_ratio(), 1.0), "AC-5: at max level progress should be 1.0, got %.6f" % manager.get_reputation_progress_ratio())

	# Arrange — invalid config (non-consecutive levels)
	var bad_config: ReputationConfig = ReputationConfigScript.new() as ReputationConfig
	bad_config.reputation_level_thresholds = {1: 0, 3: 100}
	var bad_validation: Dictionary[String, Variant] = bad_config.validate()
	_expect(not (bad_validation["valid"] as bool), "AC-5: non-consecutive levels config must be invalid")

	# Arrange — invalid config (level 1 not 0)
	var bad_config_2: ReputationConfig = ReputationConfigScript.new() as ReputationConfig
	bad_config_2.reputation_level_thresholds = {1: 10, 2: 100}
	var bad_validation_2: Dictionary[String, Variant] = bad_config_2.validate()
	_expect(not (bad_validation_2["valid"] as bool), "AC-5: level 1 threshold not 0 must be invalid")

	# Arrange — invalid config (non-increasing)
	var bad_config_3: ReputationConfig = ReputationConfigScript.new() as ReputationConfig
	bad_config_3.reputation_level_thresholds = {1: 0, 2: 100, 3: 50}
	var bad_validation_3: Dictionary[String, Variant] = bad_config_3.validate()
	_expect(not (bad_validation_3["valid"] as bool), "AC-5: non-increasing thresholds must be invalid")

	manager.free()


# ─────────────────────────────────────────────
# Edge case — Zero gain early return
# ─────────────────────────────────────────────

func test_edge_zero_gain_early_return() -> void:
	var manager: Node = ReputationAchievementManagerScript.new() as Node
	var config: ReputationConfig = _make_test_config({1: 0, 2: 100, 3: 180, 4: 260, 5: 360})
	manager.apply_config(config)

	var signal_data: Array[bool] = [false]
	manager.reputation_changed.connect(func(_prev: int, _new: int): signal_data[0] = true)

	# Act
	manager.process_reputation_gain(0)

	# Assert — no state change, no signals
	_expect(manager.reputation_total == 0, "Edge Zero Gain: total should remain 0, got %d" % manager.reputation_total)
	_expect(manager.reputation_level == 1, "Edge Zero Gain: level should remain 1, got %d" % manager.reputation_level)
	_expect(not signal_data[0], "Edge Zero Gain: reputation_changed should NOT fire on zero gain")

	manager.free()


# ─────────────────────────────────────────────
# Edge case — Negative gain guard
# ─────────────────────────────────────────────

func test_edge_negative_gain_guard() -> void:
	var manager: Node = ReputationAchievementManagerScript.new() as Node
	var config: ReputationConfig = _make_test_config({1: 0, 2: 100, 3: 180})
	manager.apply_config(config)

	var signal_data: Array[bool] = [false]
	manager.reputation_changed.connect(func(_prev: int, _new: int): signal_data[0] = true)

	# Act
	manager.process_reputation_gain(-1)

	# Assert — no state change, no signals
	_expect(manager.reputation_total == 0, "Edge Negative Gain: total should remain 0, got %d" % manager.reputation_total)
	_expect(manager.reputation_level == 1, "Edge Negative Gain: level should remain 1, got %d" % manager.reputation_level)
	_expect(not signal_data[0], "Edge Negative Gain: reputation_changed should NOT fire on negative gain")

	manager.free()


# ─────────────────────────────────────────────
# Edge case — apply_config(null) keeps defaults
# ─────────────────────────────────────────────

func test_edge_apply_config_null_keeps_defaults() -> void:
	var manager: Node = ReputationAchievementManagerScript.new() as Node

	# Act — inject null
	manager.apply_config(null)

	# Assert — defaults preserved
	_expect(manager.reputation_level == 1, "Edge Null Config: level should still be 1, got %d" % manager.reputation_level)
	# Verify manager still functional with defaults
	var gain: int = manager.calculate_reputation_gain(10, 0, 1.0, 1.0)
	_expect(gain == 10, "Edge Null Config: calculate_reputation_gain should still work, got %d" % gain)

	manager.free()


# ─────────────────────────────────────────────
# Edge case — apply_config(invalid) keeps defaults
# ─────────────────────────────────────────────

func test_edge_apply_config_invalid_keeps_defaults() -> void:
	var manager: Node = ReputationAchievementManagerScript.new() as Node

	# Arrange — an invalid config (non-consecutive levels)
	var bad_config: ReputationConfig = ReputationConfigScript.new() as ReputationConfig
	bad_config.reputation_level_thresholds = {1: 0, 3: 100}

	# Act — inject invalid config
	manager.apply_config(bad_config)

	# Assert — defaults preserved, manager still functional
	_expect(manager.reputation_level == 1, "Edge Invalid Config: level should still be 1, got %d" % manager.reputation_level)
	var gain: int = manager.calculate_reputation_gain(10, 0, 1.0, 1.0)
	_expect(gain == 10, "Edge Invalid Config: calculate_reputation_gain should still work, got %d" % gain)

	manager.free()


# ─────────────────────────────────────────────
# Edge case — reputation_changed signal verification
# ─────────────────────────────────────────────

func test_edge_reputation_changed_signal() -> void:
	var manager: Node = ReputationAchievementManagerScript.new() as Node
	var config: ReputationConfig = _make_test_config({1: 0, 2: 100, 3: 180, 4: 260, 5: 360})
	manager.apply_config(config)

	# Godot 4.6.3: lambdas cannot reassign captured local variables.
	# Use Array/Dictionary for mutable captured state.
	var signal_data: Dictionary = {"prev": -1, "new": -1, "count": 0}
	manager.reputation_changed.connect(func(prev: int, new: int):
		signal_data["prev"] = prev
		signal_data["new"] = new
		signal_data["count"] = signal_data["count"] + 1
	)

	# Act
	manager.process_reputation_gain(50)

	# Assert
	_expect(signal_data["count"] == 1, "Edge Reputation Changed: signal should fire once, got %d" % signal_data["count"])
	_expect(signal_data["prev"] == 0, "Edge Reputation Changed: previous_total should be 0, got %d" % signal_data["prev"])
	_expect(signal_data["new"] == 50, "Edge Reputation Changed: new_total should be 50, got %d" % signal_data["new"])

	# Act again — verify cumulative signal
	manager.process_reputation_gain(30)
	_expect(signal_data["count"] == 2, "Edge Reputation Changed: signal should fire twice total, got %d" % signal_data["count"])
	_expect(signal_data["prev"] == 50, "Edge Reputation Changed: second previous_total should be 50, got %d" % signal_data["prev"])
	_expect(signal_data["new"] == 80, "Edge Reputation Changed: second new_total should be 80, got %d" % signal_data["new"])

	manager.free()


# ─────────────────────────────────────────────
# Edge case — Exact threshold boundary crossing
# ─────────────────────────────────────────────

func test_edge_exact_threshold_boundary() -> void:
	var manager: Node = ReputationAchievementManagerScript.new() as Node
	var config: Resource = _make_test_config({1: 0, 2: 100, 3: 180})
	manager.apply_config(config)

	# Total=100 at Lv.1 (exactly at Lv.2 threshold). Add 100 → total=200.
	manager.reputation_total = 100
	manager.reputation_level = 1
	manager._recompute_progress_ratio()

	var leveled_up_to: Array[int] = []
	manager.reputation_leveled_up.connect(func(level: int): leveled_up_to.append(level))

	# Act
	manager.process_reputation_gain(100)

	# Assert
	_expect(manager.reputation_total == 200, "Edge Threshold: total should be 200, got %d" % manager.reputation_total)
	_expect(manager.reputation_level == 3, "Edge Threshold: should cross Lv.2→Lv.3, got Lv.%d" % manager.reputation_level)
	_expect(leveled_up_to.size() == 2, "Edge Threshold: should emit 2 level-up signals, got %d" % leveled_up_to.size())
	# Progress: Lv.3 (180→360? no, next is undefined after Lv.3 since we only defined up to 3)
	# Actually config has Lv.3=180, no Lv.4 → at max level, progress = 1.0
	_expect(is_equal_approx(manager.get_reputation_progress_ratio(), 1.0), "Edge Threshold: at max level progress should be 1.0, got %.6f" % manager.get_reputation_progress_ratio())

	manager.free()


# ─────────────────────────────────────────────
# Edge case — Gain exceeds max level
# ─────────────────────────────────────────────

func test_edge_exceed_max_level() -> void:
	var manager: Node = ReputationAchievementManagerScript.new() as Node
	var config: Resource = _make_test_config({1: 0, 2: 100, 3: 180, 4: 260, 5: 360})
	manager.apply_config(config)

	# Start at max level
	manager.reputation_total = 500
	manager.reputation_level = 5
	manager._recompute_progress_ratio()

	var leveled_up_to: Array[int] = []
	manager.reputation_leveled_up.connect(func(level: int): leveled_up_to.append(level))

	# Act
	manager.process_reputation_gain(100)

	# Assert
	_expect(manager.reputation_total == 600, "Edge Exceed Max: total should be 600, got %d" % manager.reputation_total)
	_expect(manager.reputation_level == 5, "Edge Exceed Max: level should stay at max 5, got %d" % manager.reputation_level)
	_expect(leveled_up_to.size() == 0, "Edge Exceed Max: no level-up signals should fire, got %d" % leveled_up_to.size())
	_expect(is_equal_approx(manager.get_reputation_progress_ratio(), 1.0), "Edge Exceed Max: progress should remain 1.0, got %.6f" % manager.get_reputation_progress_ratio())

	manager.free()


# ─────────────────────────────────────────────
# Edge case — Negative source_weight / stage_multiplier
# ─────────────────────────────────────────────

func test_edge_negative_weights_guard() -> void:
	var manager: Node = ReputationAchievementManagerScript.new() as Node

	# Negative source_weight
	var result_1: int = manager.calculate_reputation_gain(10, 0, -0.5, 1.0)
	_expect(result_1 == 0, "Edge Negative Weights: negative source_weight should return 0, got %d" % result_1)

	# Negative stage_multiplier
	var result_2: int = manager.calculate_reputation_gain(10, 0, 1.0, -0.5)
	_expect(result_2 == 0, "Edge Negative Weights: negative stage_multiplier should return 0, got %d" % result_2)

	# Both negative
	var result_3: int = manager.calculate_reputation_gain(10, 0, -0.5, -0.5)
	_expect(result_3 == 0, "Edge Negative Weights: both negative should return 0, got %d" % result_3)

	manager.free()


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _make_test_config(thresholds: Dictionary[int, int]) -> ReputationConfig:
	var config: ReputationConfig = ReputationConfigScript.new() as ReputationConfig
	config.reputation_level_thresholds = thresholds
	var result: Dictionary[String, Variant] = config.validate()
	if not (result["valid"] as bool):
		push_error("_make_test_config: test config is invalid — %s" % str(result.get("errors", [])))
	return config
