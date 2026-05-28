extends Node

const PlayerScript: Script = preload("res://src/core/player.gd")
const PlayerDevelopmentScript: Script = preload("res://src/core/player_development.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_training_actual_gain_uses_formula_result_or_remaining_cap_whichever_is_lower()
	test_facility_training_multiplier_is_clamped_to_townbuilding_contract_range()
	test_capped_or_invalid_potential_attributes_resolve_to_zero_growth_and_mark_review()
	if _failures.is_empty():
		print("TRAINING_GAIN_CAP_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("TRAINING_GAIN_CAP_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_training_actual_gain_uses_formula_result_or_remaining_cap_whichever_is_lower() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var room_limited_player: Player = _build_player(60, 62, 1.2, 1.0, 1.0)
	var formula_limited_player: Player = _build_player(60, 90, 1.2, 1.0, 1.0)
	var expected_room_limited_gain: float = minf(
		2.0,
		player_development.attribute_growth(100.0, 60, 62, 1.0)
			* player_development.get_fatigue_adjusted_training_efficiency(room_limited_player)
			* 1.0
			* 1.0,
	)
	var expected_formula_limited_gain: float = minf(
		30.0,
		player_development.attribute_growth(1.0, 60, 90, 1.0)
			* player_development.get_fatigue_adjusted_training_efficiency(formula_limited_player)
			* 1.0
			* 1.0,
	)

	# Act
	var room_limited_gain: float = player_development.resolve_training_actual_gain(
		room_limited_player,
		60,
		62,
		100.0,
		1.0,
		1.0,
		1.0,
	)
	var applied_room_limited_gain: float = player_development.apply_training_gain_to_attribute(
		room_limited_player,
		"SPD",
		100.0,
		1.0,
		1.0,
		1.0,
	)
	var formula_limited_gain: float = player_development.resolve_training_actual_gain(
		formula_limited_player,
		60,
		90,
		1.0,
		1.0,
		1.0,
		1.0,
	)

	# Assert
	_expect(is_equal_approx(room_limited_gain, expected_room_limited_gain), "resolved gain should choose the smaller of formula output and remaining cap room")
	_expect(is_equal_approx(applied_room_limited_gain, expected_room_limited_gain), "applied gain should match resolved room-limited gain")
	_expect(room_limited_player.attributes.spd.current == 62, "applied gain should not push the attribute above potential")
	_expect(is_equal_approx(formula_limited_gain, expected_formula_limited_gain), "resolved gain should preserve the formula output when cap room is larger")
	_expect(formula_limited_gain < 30.0, "formula-limited sample should remain below the remaining cap room")


func test_facility_training_multiplier_is_clamped_to_townbuilding_contract_range() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var baseline_player: Player = _build_player(50, 90, 1.0, 1.0, 1.0)
	var midpoint_player: Player = _build_player(50, 90, 1.0, 1.0, 1.0)
	var boosted_player: Player = _build_player(50, 90, 1.0, 1.0, 1.0)
	var invalid_player: Player = _build_player(50, 90, 1.0, 1.0, 1.0)

	# Act
	var baseline_gain: float = player_development.resolve_training_actual_gain(
		baseline_player,
		50,
		90,
		2.0,
		1.0,
		1.0,
		1.0,
	)
	var midpoint_gain: float = player_development.resolve_training_actual_gain(
		midpoint_player,
		50,
		90,
		2.0,
		1.0,
		1.375,
		1.0,
	)
	var boosted_gain: float = player_development.resolve_training_actual_gain(
		boosted_player,
		50,
		90,
		2.0,
		1.0,
		1.75,
		1.0,
	)
	var invalid_gain: float = player_development.resolve_training_actual_gain(
		invalid_player,
		50,
		90,
		2.0,
		1.0,
		2.2,
		1.0,
	)

	# Assert
	_expect(midpoint_gain > baseline_gain, "midpoint facility multiplier should increase training gain above the no-facility baseline")
	_expect(boosted_gain > midpoint_gain, "upper-bound facility multiplier should increase training gain above the midpoint sample")
	_expect(is_equal_approx(invalid_gain, boosted_gain), "out-of-range facility multiplier should clamp to the upper contract bound")
	_expect(invalid_player.review_flags.has("facility_training_multiplier_out_of_range"), "out-of-range facility multiplier should mark the player for review")


func test_capped_or_invalid_potential_attributes_resolve_to_zero_growth_and_mark_review() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var capped_player: Player = _build_player(70, 70, 1.1, 1.0, 1.0)
	var invalid_player: Player = _build_player(70, 65, 1.1, 1.0, 1.0)

	# Act
	var capped_gain: float = player_development.apply_training_gain_to_attribute(
		capped_player,
		"SPD",
		3.0,
		1.0,
		1.0,
		1.0,
	)
	var invalid_gain: float = player_development.apply_training_gain_to_attribute(
		invalid_player,
		"SPD",
		3.0,
		1.0,
		1.0,
		1.0,
	)

	# Assert
	_expect(is_equal_approx(capped_gain, 0.0), "attributes already at potential should produce zero gain")
	_expect(capped_player.attributes.spd.current == 70, "capped attributes should remain unchanged")
	_expect(is_equal_approx(invalid_gain, 0.0), "invalid potential below current should normalize to zero growth")
	_expect(invalid_player.attributes.spd.potential == 70, "invalid potential should normalize up to the current attribute value")
	_expect(invalid_player.review_flags.has("attribute_potential_below_current"), "invalid potential should mark the player for review")


func _build_player(
	current_attribute: int,
	potential_cap: int,
	training_efficiency: float,
	condition_multiplier: float,
	morale_multiplier: float,
) -> Player:
	var player: Player = PlayerScript.new()
	player.training_efficiency = training_efficiency
	player.condition_multiplier = condition_multiplier
	player.morale_multiplier = morale_multiplier
	player.attributes.spd.current = current_attribute
	player.attributes.spd.potential = potential_cap
	return player


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
