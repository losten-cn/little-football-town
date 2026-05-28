extends SceneTree

const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const ConfigLoaderScript: Script = preload("res://src/autoload/config_loader.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_actual_win_probability_clamps_to_configured_bounds()
	test_actual_win_probability_applies_match_modifiers_in_expected_direction()
	test_strength_adjusted_probability_preserves_underdog_upset_floor()
	if _failures.is_empty():
		print("ACTUAL_WIN_PROBABILITY_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("ACTUAL_WIN_PROBABILITY_TEST_FAIL: %s" % failure)
		quit(1)


func test_actual_win_probability_clamps_to_configured_bounds() -> void:
	var simulation: MatchSimulation = MatchSimulationScript.new()
	var config_loader: Node = ConfigLoaderScript.new()
	_expect(config_loader.load_all(), "config loader should load balance config for clamp test")
	var inside_range: float = simulation.compute_actual_win_probability(0.50, 0.05, 0.03, -0.02, 0.01)
	var clamped_low: float = simulation.compute_actual_win_probability(0.10, -0.10, -0.08, -0.03, 0.00)
	var clamped_high: float = simulation.compute_actual_win_probability(0.90, 0.08, 0.05, 0.02, 0.03)
	_expect(is_equal_approx(inside_range, 0.57), "actual win probability should preserve in-range sums")
	_expect(is_equal_approx(clamped_low, 0.05), "actual win probability should clamp to configured floor")
	_expect(is_equal_approx(clamped_high, 0.95), "actual win probability should clamp to configured ceiling")


func test_actual_win_probability_applies_match_modifiers_in_expected_direction() -> void:
	var simulation: MatchSimulation = MatchSimulationScript.new()
	var config_loader: Node = ConfigLoaderScript.new()
	_expect(config_loader.load_all(), "config loader should load balance config for modifier direction test")
	var baseline: float = simulation.compute_actual_win_probability(0.50, 0.00, 0.00, 0.00, 0.00)
	var home_only: float = simulation.compute_actual_win_probability(0.50, 0.04, 0.00, 0.00, 0.00)
	var tactical_only: float = simulation.compute_actual_win_probability(0.50, 0.00, 0.03, 0.00, 0.00)
	var condition_only: float = simulation.compute_actual_win_probability(0.50, 0.00, 0.00, -0.06, 0.00)
	var combined: float = simulation.compute_actual_win_probability(0.50, 0.04, 0.03, -0.06, 0.02)
	_expect(home_only > baseline, "home advantage modifier should increase actual win probability")
	_expect(tactical_only > baseline, "tactical modifier should increase actual win probability")
	_expect(condition_only < baseline, "negative condition modifier should decrease actual win probability")
	_expect(is_equal_approx(combined, 0.53), "combined modifiers should add linearly before clamping")


func test_strength_adjusted_probability_preserves_underdog_upset_floor() -> void:
	var simulation: MatchSimulation = MatchSimulationScript.new()
	var config_loader: Node = ConfigLoaderScript.new()
	_expect(config_loader.load_all(), "config loader should load balance config for strength-adjusted test")
	var stronger_team_probability: float = simulation.compute_strength_adjusted_win_probability(90.0, 50.0, 0.02, 0.03, 0.01, 0.00)
	var weaker_team_probability: float = simulation.compute_strength_adjusted_win_probability(50.0, 90.0, 0.00, 0.00, 0.00, 0.00)
	_expect(stronger_team_probability > weaker_team_probability, "stronger team should have higher actual win probability")
	_expect(weaker_team_probability >= 0.05, "weaker team should retain the configured upset floor")
	_expect(weaker_team_probability > 0.0, "weaker team should keep a non-zero upset chance")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
