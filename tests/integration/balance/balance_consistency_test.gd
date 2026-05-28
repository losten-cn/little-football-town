extends SceneTree

const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")
const PlayerScript: Script = preload("res://src/core/player.gd")
const PlayerDevelopmentScript: Script = preload("res://src/core/player_development.gd")
const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const MatchConfigScript: Script = preload("res://src/config/match_config.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_player_development_growth_matches_shared_balance_formula_for_same_inputs()
	test_player_development_normalizes_reversed_potential_to_zero_growth_consistently_with_shared_formula()
	test_player_development_tier_ranges_and_efficiency_bounds_follow_balance_config()
	test_match_simulation_probability_consumers_follow_balance_config_bounds()
	if _failures.is_empty():
		print("BALANCE_CONSISTENCY_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("BALANCE_CONSISTENCY_TEST_FAIL: %s" % failure)
		quit(1)


func test_player_development_growth_matches_shared_balance_formula_for_same_inputs() -> void:
	# Arrange
	var config: BalanceConfig = BalanceConfigScript.new()
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()

	# Act
	var shared_growth: float = config.compute_attribute_growth(3.0, 40.0, 80.0, 1.5)
	var downstream_growth: float = player_development.attribute_growth(3.0, 40, 80, 1.5)

	# Assert
	_expect(is_equal_approx(downstream_growth, shared_growth), "player development growth should match the shared balance formula for the same inputs")
	player_development.free()
	config = null


func test_player_development_normalizes_reversed_potential_to_zero_growth_consistently_with_shared_formula() -> void:
	# Arrange
	var config: BalanceConfig = BalanceConfigScript.new()
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()

	# Act
	var shared_growth: float = config.compute_attribute_growth(5.0, 70.0, 60.0, 1.2)
	var downstream_growth: float = player_development.attribute_growth(5.0, 70, 60, 1.2)

	# Assert
	_expect(is_equal_approx(shared_growth, 0.0), "shared balance formula should normalize reversed potential inputs to zero additional growth")
	_expect(is_equal_approx(downstream_growth, shared_growth), "player development growth should stay consistent with the shared formula when potential is below current")
	player_development.free()
	config = null


func test_player_development_tier_ranges_and_efficiency_bounds_follow_balance_config() -> void:
	# Arrange
	var config: BalanceConfig = BalanceConfigScript.new()
	config.player_tier_potential_caps["excellent"] = Vector2i(80, 88)
	config.player_tier_training_efficiency["excellent"] = Vector2(1.0, 1.1)
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	player_development.set_balance_config_for_testing(config)
	var band: Vector2i = player_development.get_tier_potential_band("优秀")
	var player: Player = PlayerScript.new()
	player.tier = "优秀"
	player.training_efficiency = 1.35

	# Act
	var normalized_efficiency: float = player_development.normalize_training_efficiency(player)

	# Assert
	_expect(band == Vector2i(80, 88), "player development should read tier potential caps from BalanceConfig")
	_expect(is_equal_approx(normalized_efficiency, 1.1), "player development should clamp training efficiency using the tier range from BalanceConfig")
	_expect(player.review_flags.has("training_efficiency_out_of_range"), "player development should keep the review flag when BalanceConfig clamps training efficiency")
	player_development.free()
	config = null


func test_match_simulation_probability_consumers_follow_balance_config_bounds() -> void:
	# Arrange
	var config: BalanceConfig = BalanceConfigScript.new()
	config.win_probability_floor = 0.10
	config.win_probability_ceiling = 0.90
	var match_config: MatchConfig = MatchConfigScript.new()
	match_config.min_key_events = 3
	match_config.max_key_events = 15
	var match_simulation: MatchSimulation = MatchSimulationScript.new()
	match_simulation.set_balance_config_for_testing(config)
	match_simulation.set_match_config_for_testing(match_config)

	# Act
	var actual_probability: float = match_simulation.compute_strength_adjusted_win_probability(150.0, 0.0, 0.0, 0.0, 0.0, 0.0)
	var estimated_event_count: int = match_simulation.call("_estimate_key_event_count", actual_probability)
	var half_events: Array[Dictionary] = match_simulation.call("_build_half_events", actual_probability, estimated_event_count, 0, estimated_event_count, 1)
	var home_event_count: int = 0
	for event_entry: Dictionary[String, Variant] in half_events:
		if String(event_entry.get("side", "")) == "home":
			home_event_count += 1

	# Assert
	_expect(is_equal_approx(actual_probability, 0.90), "match simulation should clamp actual win probability using BalanceConfig bounds")
	_expect(estimated_event_count == 15, "match simulation should scale key-event count against BalanceConfig probability bounds")
	_expect(home_event_count >= 1, "match simulation should still build events when using non-default BalanceConfig bounds")
	match_simulation.free()
	config = null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
