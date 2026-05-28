extends Node

const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")

var _failures: Array[String] = []

func _ready() -> void:
	test_action_point_use_rate_returns_expected_ratio_and_invalid_sample()
	test_overall_win_rate_normalizes_inputs_before_computation()
	test_even_match_win_rate_counts_only_even_probability_samples()
	test_milestone_completion_time_handles_valid_and_invalid_timestamps()
	test_kpi_target_ranges_are_config_backed_and_deterministic()
	if _failures.is_empty():
		print("KPI_FORMULA_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("KPI_FORMULA_TEST_FAIL: %s" % failure)
		get_tree().quit(1)

func test_action_point_use_rate_returns_expected_ratio_and_invalid_sample() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var valid_sample: BalanceConfig.DiagnosticSample = config.compute_action_point_use_rate(7.0, 10.0)
	_expect(is_equal_approx(valid_sample.value, 0.7), "action point use rate should equal spent divided by available")
	_expect(not valid_sample.invalid_sample, "non-zero denominator should remain a valid sample")
	var clamped_sample: BalanceConfig.DiagnosticSample = config.compute_action_point_use_rate(12.0, 10.0)
	_expect(is_equal_approx(clamped_sample.value, 1.0), "spent action points above available should clamp to the available total")
	_expect(not clamped_sample.invalid_sample, "clamped non-zero denominator sample should remain valid")
	var fractional_sample: BalanceConfig.DiagnosticSample = config.compute_action_point_use_rate(0.5, 0.5)
	_expect(is_equal_approx(fractional_sample.value, 1.0), "fractional non-zero availability should still divide by the actual available total")
	_expect(not fractional_sample.invalid_sample, "fractional non-zero denominator sample should remain valid")
	var invalid_sample: BalanceConfig.DiagnosticSample = config.compute_action_point_use_rate(7.0, 0.0)
	_expect(is_equal_approx(invalid_sample.value, 0.0), "zero available action points should return safe zero")
	_expect(invalid_sample.invalid_sample, "zero available action points should mark the sample invalid")
	var invalid_spent_sample: BalanceConfig.DiagnosticSample = config.compute_action_point_use_rate(NAN, 10.0)
	_expect(is_equal_approx(invalid_spent_sample.value, 0.0), "non-finite spent action points should return safe zero")
	_expect(invalid_spent_sample.invalid_sample, "non-finite spent action points should mark the sample invalid")
	var invalid_available_sample: BalanceConfig.DiagnosticSample = config.compute_action_point_use_rate(7.0, INF)
	_expect(is_equal_approx(invalid_available_sample.value, 0.0), "non-finite available action points should return safe zero")
	_expect(invalid_available_sample.invalid_sample, "non-finite available action points should mark the sample invalid")

func test_overall_win_rate_normalizes_inputs_before_computation() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var normalized_sample: BalanceConfig.DiagnosticSample = config.compute_overall_win_rate(11, 20)
	_expect(is_equal_approx(normalized_sample.value, 0.55), "overall win rate should match the normalized win ratio")
	_expect(not normalized_sample.invalid_sample, "positive played count should remain valid")
	var clamped_sample: BalanceConfig.DiagnosticSample = config.compute_overall_win_rate(30, 20)
	_expect(is_equal_approx(clamped_sample.value, 1.0), "wins above matches played should clamp to the total played count")
	var negative_wins_sample: BalanceConfig.DiagnosticSample = config.compute_overall_win_rate(-3, 20)
	_expect(is_equal_approx(negative_wins_sample.value, 0.0), "negative wins should normalize to zero before division")
	_expect(not negative_wins_sample.invalid_sample, "positive played count with normalized wins should remain valid")
	var invalid_sample: BalanceConfig.DiagnosticSample = config.compute_overall_win_rate(-1, 0)
	_expect(is_equal_approx(invalid_sample.value, 0.0), "zero matches played should return safe zero")
	_expect(invalid_sample.invalid_sample, "zero matches played should mark the sample invalid")

func test_even_match_win_rate_counts_only_even_probability_samples() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var sample_probabilities: Array[float] = [config.even_match_win_rate_target_min, 0.50, config.even_match_win_rate_target_max, 0.30, 0.80, NAN, INF]
	var sample_wins: Array[bool] = [true, false, true, true, false, true, true]
	var even_sample: BalanceConfig.DiagnosticSample = config.compute_even_match_win_rate(sample_probabilities, sample_wins)
	_expect(is_equal_approx(even_sample.value, 2.0 / 3.0), "even match win rate should only count finite samples inside the inclusive configured even-match window")
	_expect(not even_sample.invalid_sample, "presence of even-match samples should remain valid")
	var invalid_sample: BalanceConfig.DiagnosticSample = config.compute_even_match_win_rate([0.30, 0.80, NAN, INF], [true, false, true, true])
	_expect(is_equal_approx(invalid_sample.value, 0.0), "missing even-match samples should return safe zero")
	_expect(invalid_sample.invalid_sample, "missing even-match samples should mark the sample invalid")

func test_milestone_completion_time_handles_valid_and_invalid_timestamps() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	var valid_sample: BalanceConfig.DiagnosticSample = config.compute_milestone_completion_time(24.0, 0.0, true)
	_expect(is_equal_approx(valid_sample.value, 24.0), "milestone completion time should equal completion timestamp minus save start")
	_expect(not valid_sample.invalid_sample, "completed milestones with increasing timestamps should remain valid")
	var incomplete_sample: BalanceConfig.DiagnosticSample = config.compute_milestone_completion_time(24.0, 0.0, false)
	_expect(is_equal_approx(incomplete_sample.value, 0.0), "incomplete milestones should return safe zero")
	_expect(incomplete_sample.invalid_sample, "incomplete milestones should mark the sample invalid")
	var invalid_order_sample: BalanceConfig.DiagnosticSample = config.compute_milestone_completion_time(5.0, 10.0, true)
	_expect(is_equal_approx(invalid_order_sample.value, 0.0), "completion earlier than save start should return safe zero")
	_expect(invalid_order_sample.invalid_sample, "completion earlier than save start should mark the sample invalid")
	var invalid_completion_sample: BalanceConfig.DiagnosticSample = config.compute_milestone_completion_time(NAN, 0.0, true)
	_expect(is_equal_approx(invalid_completion_sample.value, 0.0), "non-finite completion timestamps should return safe zero")
	_expect(invalid_completion_sample.invalid_sample, "non-finite completion timestamps should mark the sample invalid")
	var invalid_start_sample: BalanceConfig.DiagnosticSample = config.compute_milestone_completion_time(24.0, INF, true)
	_expect(is_equal_approx(invalid_start_sample.value, 0.0), "non-finite save start timestamps should return safe zero")
	_expect(invalid_start_sample.invalid_sample, "non-finite save start timestamps should mark the sample invalid")

func test_kpi_target_ranges_are_config_backed_and_deterministic() -> void:
	var config: BalanceConfig = BalanceConfigScript.new()
	_expect(is_equal_approx(config.action_point_use_rate_target_min, 0.70), "action point target minimum should come from BalanceConfig")
	_expect(is_equal_approx(config.action_point_use_rate_target_max, 0.90), "action point target maximum should come from BalanceConfig")
	_expect(is_equal_approx(config.overall_win_rate_target_min, 0.55), "overall win rate target minimum should come from BalanceConfig")
	_expect(is_equal_approx(config.overall_win_rate_target_max, 0.65), "overall win rate target maximum should come from BalanceConfig")
	_expect(is_equal_approx(config.even_match_win_rate_target_min, 0.45), "even match target minimum should come from BalanceConfig")
	_expect(is_equal_approx(config.even_match_win_rate_target_max, 0.55), "even match target maximum should come from BalanceConfig")
	var threshold_sample: BalanceConfig.DiagnosticSample = config.compute_even_match_win_rate([config.even_match_win_rate_target_min, config.even_match_win_rate_target_max], [true, false])
	_expect(is_equal_approx(threshold_sample.value, 0.5), "configured even-match thresholds should be inclusive and drive sample selection")
	var first_sample: BalanceConfig.DiagnosticSample = config.compute_action_point_use_rate(7.0, 10.0)
	var second_sample: BalanceConfig.DiagnosticSample = config.compute_action_point_use_rate(7.0, 10.0)
	_expect(is_equal_approx(first_sample.value, second_sample.value), "repeated KPI calculations should be stable")
	_expect(first_sample.invalid_sample == second_sample.invalid_sample, "repeated KPI invalid-sample flags should be stable")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
