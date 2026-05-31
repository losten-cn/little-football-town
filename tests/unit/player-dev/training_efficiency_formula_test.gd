extends Node

const PlayerScript: Script = preload("res://src/core/player.gd")
const PlayerDevelopmentScript: Script = preload("res://src/core/player_development.gd")
const PlayerRosterScript: Script = preload("res://src/core/player_roster.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_fatigue_adjusted_training_efficiency_clamps_product_to_formula_bounds()
	test_normalize_training_efficiency_clamps_abnormal_values_and_marks_review_once()
	test_low_condition_or_morale_reduces_effective_training_efficiency_without_breaking_lower_bound()
	test_review_flags_round_trip_through_player_roster_serialization()
	if _failures.is_empty():
		print("TRAINING_EFFICIENCY_FORMULA_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("TRAINING_EFFICIENCY_FORMULA_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_fatigue_adjusted_training_efficiency_clamps_product_to_formula_bounds() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var within_range_player: Player = PlayerScript.new()
	within_range_player.tier = "明星"
	within_range_player.training_efficiency = 1.2
	within_range_player.condition_multiplier = 1.0
	within_range_player.morale_multiplier = 1.1
	var lower_bound_player: Player = PlayerScript.new()
	lower_bound_player.training_efficiency = 0.8
	lower_bound_player.condition_multiplier = 0.4
	lower_bound_player.morale_multiplier = 0.6
	var upper_bound_player: Player = PlayerScript.new()
	upper_bound_player.tier = "传奇胚子"
	upper_bound_player.training_efficiency = 1.5
	upper_bound_player.condition_multiplier = 1.2
	upper_bound_player.morale_multiplier = 1.1

	# Act
	var within_range_result: float = player_development.get_fatigue_adjusted_training_efficiency(within_range_player)
	var lower_bound_result: float = player_development.get_fatigue_adjusted_training_efficiency(lower_bound_player)
	var upper_bound_result: float = player_development.get_fatigue_adjusted_training_efficiency(upper_bound_player)

	# Assert
	_expect(is_equal_approx(within_range_result, 1.32), "fatigue-adjusted efficiency should preserve in-range products")
	_expect(is_equal_approx(lower_bound_result, 0.5), "fatigue-adjusted efficiency should clamp to the lower bound")
	_expect(is_equal_approx(upper_bound_result, 1.8), "fatigue-adjusted efficiency should clamp to the upper bound")


func test_normalize_training_efficiency_clamps_abnormal_values_and_marks_review_once() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var low_player: Player = PlayerScript.new()
	low_player.training_efficiency = 0.4
	var high_player: Player = PlayerScript.new()
	high_player.tier = "传奇胚子"
	high_player.training_efficiency = 1.9
	var boundary_player: Player = PlayerScript.new()
	boundary_player.training_efficiency = 0.8

	# Act
	var low_result_first: float = player_development.normalize_training_efficiency(low_player)
	var low_result_second: float = player_development.normalize_training_efficiency(low_player)
	var high_result: float = player_development.normalize_training_efficiency(high_player)
	var boundary_result: float = player_development.normalize_training_efficiency(boundary_player)

	# Assert
	_expect(is_equal_approx(low_result_first, 0.8), "low training_efficiency should normalize to 0.8")
	_expect(is_equal_approx(low_result_second, 0.8), "repeat normalization should preserve the normalized low bound")
	_expect(low_player.review_flags.size() == 1, "repeat normalization should not duplicate the low-efficiency review flag")
	_expect(is_equal_approx(high_result, 1.5), "legend prospect high training_efficiency should normalize to its configured 1.5 ceiling")
	_expect(high_player.review_flags.size() == 1, "high abnormal value should create one review flag")
	_expect(is_equal_approx(boundary_result, 0.8), "boundary training_efficiency should remain unchanged")
	_expect(boundary_player.review_flags.is_empty(), "boundary training_efficiency should not create a review flag")


func test_low_condition_or_morale_reduces_effective_training_efficiency_without_breaking_lower_bound() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var baseline_player: Player = PlayerScript.new()
	baseline_player.tier = "明星"
	baseline_player.training_efficiency = 1.2
	baseline_player.condition_multiplier = 1.0
	baseline_player.morale_multiplier = 1.0
	var low_condition_player: Player = PlayerScript.new()
	low_condition_player.tier = "明星"
	low_condition_player.training_efficiency = 1.2
	low_condition_player.condition_multiplier = 0.7
	low_condition_player.morale_multiplier = 1.0
	var low_morale_player: Player = PlayerScript.new()
	low_morale_player.tier = "明星"
	low_morale_player.training_efficiency = 1.2
	low_morale_player.condition_multiplier = 1.0
	low_morale_player.morale_multiplier = 0.75
	var double_low_player: Player = PlayerScript.new()
	double_low_player.tier = "明星"
	double_low_player.training_efficiency = 1.2
	double_low_player.condition_multiplier = 0.2
	double_low_player.morale_multiplier = 0.2

	# Act
	var baseline_result: float = player_development.get_fatigue_adjusted_training_efficiency(baseline_player)
	var low_condition_result: float = player_development.get_fatigue_adjusted_training_efficiency(low_condition_player)
	var low_morale_result: float = player_development.get_fatigue_adjusted_training_efficiency(low_morale_player)
	var double_low_result: float = player_development.get_fatigue_adjusted_training_efficiency(double_low_player)

	# Assert
	_expect(low_condition_result < baseline_result, "lower condition should reduce effective training efficiency")
	_expect(low_morale_result < baseline_result, "lower morale should reduce effective training efficiency")
	_expect(low_condition_result >= 0.5, "low condition should not drop below the lower bound")
	_expect(low_morale_result >= 0.5, "low morale should not drop below the lower bound")
	_expect(is_equal_approx(double_low_result, 0.5), "combined low condition and morale should clamp to the lower bound")


func test_review_flags_round_trip_through_player_roster_serialization() -> void:
	# Arrange
	var roster: PlayerRoster = PlayerRosterScript.new()
	var player: Player = PlayerScript.new()
	player.review_flags = ["training_efficiency_out_of_range"]
	roster.add_player(player)

	# Act
	var serialized: Dictionary[String, Variant] = roster.serialize()
	var restored_roster: PlayerRoster = PlayerRosterScript.new()
	restored_roster.deserialize(serialized)
	var restored_player: Player = restored_roster.get_player(player.id)

	# Assert
	_expect(restored_player != null, "serialized roster should restore the player instance")
	if restored_player != null:
		_expect(restored_player.review_flags.size() == 1, "review flags should survive roster serialization")
		_expect(restored_player.review_flags.has("training_efficiency_out_of_range"), "restored player should keep the training efficiency review flag")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
