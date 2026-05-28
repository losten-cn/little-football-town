extends Node

const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")

var _failures: Array[String] = []

func _ready() -> void:
	test_base_win_probability_returns_even_odds_for_equal_ratings()
	test_base_win_probability_changes_linearly_with_rating_difference()
	test_base_win_probability_clamps_to_configured_floor_and_ceiling()
	test_base_win_probability_accepts_team_ratings_above_one_hundred()
	if _failures.is_empty():
		print("WIN_PROBABILITY_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("WIN_PROBABILITY_TEST_FAIL: %s" % failure)
		get_tree().quit(1)

func test_base_win_probability_returns_even_odds_for_equal_ratings() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var result: float = config.compute_base_win_probability(75.0, 75.0)
	_expect(is_equal_approx(result, 0.50), "equal ratings should produce a 0.50 base win probability")

func test_base_win_probability_changes_linearly_with_rating_difference() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var favored_result: float = config.compute_base_win_probability(80.0, 60.0)
	var underdog_result: float = config.compute_base_win_probability(60.0, 80.0)
	_expect(is_equal_approx(favored_result, 0.59), "a +20 rating difference should produce 0.59 at the default slope")
	_expect(is_equal_approx(underdog_result, 0.41), "a -20 rating difference should produce 0.41 at the default slope")

func test_base_win_probability_clamps_to_configured_floor_and_ceiling() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var ceiling_result: float = config.compute_base_win_probability(1000.0, 0.0)
	var floor_result: float = config.compute_base_win_probability(0.0, 1000.0)
	_expect(is_equal_approx(ceiling_result, 0.95), "extreme positive rating differences should clamp to the configured ceiling")
	_expect(is_equal_approx(floor_result, 0.05), "extreme negative rating differences should clamp to the configured floor")
	_expect(not is_nan(ceiling_result) and not is_nan(floor_result), "clamped win probability should never be NaN")

func test_base_win_probability_accepts_team_ratings_above_one_hundred() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var result: float = config.compute_base_win_probability(120.0, 100.0)
	_expect(is_equal_approx(result, 0.59), "team ratings above 100 should be consumed directly without attribute-style clamping")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
