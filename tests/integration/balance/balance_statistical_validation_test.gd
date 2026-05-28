extends SceneTree

const ConfigLoaderScript: Script = preload("res://src/autoload/config_loader.gd")
const PlayerDevelopmentScript: Script = preload("res://src/core/player_development.gd")
const BALANCE_CONFIG_PATH: String = "res://config/balance_config.tres"
const TRIAL_COUNT: int = 1000
const TOLERANCE: float = 0.05

class OperationSample:
	var spent: float
	var available: float
	var base_probability: float
	var did_win: bool
	var duration: float

	func _init(spent_value: float, available_value: float, base_probability_value: float, did_win_value: bool, duration_value: float) -> void:
		spent = spent_value
		available = available_value
		base_probability = base_probability_value
		did_win = did_win_value
		duration = duration_value

class AggregateSummary:
	var total_spent: float
	var total_available: float
	var total_duration: float
	var action_point_use_rate: BalanceConfig.DiagnosticSample
	var overall_win_rate: BalanceConfig.DiagnosticSample
	var even_match_win_rate: BalanceConfig.DiagnosticSample

	func _init(
		total_spent_value: float,
		total_available_value: float,
		total_duration_value: float,
		action_point_use_rate_value: BalanceConfig.DiagnosticSample,
		overall_win_rate_value: BalanceConfig.DiagnosticSample,
		even_match_win_rate_value: BalanceConfig.DiagnosticSample,
	) -> void:
		total_spent = total_spent_value
		total_available = total_available_value
		total_duration = total_duration_value
		action_point_use_rate = action_point_use_rate_value
		overall_win_rate = overall_win_rate_value
		even_match_win_rate = even_match_win_rate_value

var _failures: Array[String] = []
var _config: BalanceConfig = null


func _initialize() -> void:
	test_seeded_trials_match_theoretical_probability_within_tolerance_across_multiple_seeds()
	test_floor_and_ceiling_probabilities_hold_under_seeded_trials()
	test_manual_formula_samples_expose_intermediate_steps_and_match_system_output()
	test_illegal_inputs_normalize_before_formula_use_and_repeat_stably()
	test_aggregate_kpi_results_remain_identical_when_operation_order_changes()
	if _failures.is_empty():
		print("BALANCE_STATISTICAL_VALIDATION_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("BALANCE_STATISTICAL_VALIDATION_TEST_FAIL: %s" % failure)
		quit(1)


func test_seeded_trials_match_theoretical_probability_within_tolerance_across_multiple_seeds() -> void:
	# Arrange
	var config: BalanceConfig = _load_balance_config()
	if config == null:
		return
	var base_win_probability: float = config.compute_base_win_probability(80.0, 60.0)
	var seeds: Array[int] = [7, 17, 29, 53]
	var win_rates: Array[float] = []

	# Act
	for seed: int in seeds:
		var actual_win_rate: float = _simulate_seeded_trials(config, seed, TRIAL_COUNT, 80.0, 60.0)
		win_rates.append(actual_win_rate)

	# Assert
	for actual_win_rate: float in win_rates:
		_expect(absf(actual_win_rate - base_win_probability) <= TOLERANCE, "1000 seeded trials should stay within ±0.05 of the theoretical base win probability")
	_expect(_max_rate_delta(win_rates) <= 0.05, "changing deterministic seeds should not introduce a systemic statistical bias")


func test_floor_and_ceiling_probabilities_hold_under_seeded_trials() -> void:
	# Arrange
	var config: BalanceConfig = _load_balance_config()
	if config == null:
		return
	var floor_probability: float = config.compute_base_win_probability(0.0, 1000.0)
	var ceiling_probability: float = config.compute_base_win_probability(1000.0, 0.0)

	# Act
	var floor_win_rate: float = _simulate_seeded_trials(config, 11, TRIAL_COUNT, 0.0, 1000.0)
	var ceiling_win_rate: float = _simulate_seeded_trials(config, 23, TRIAL_COUNT, 1000.0, 0.0)

	# Assert
	_expect(is_equal_approx(floor_probability, config.win_probability_floor), "extreme underdog inputs should clamp to the configured floor")
	_expect(is_equal_approx(ceiling_probability, config.win_probability_ceiling), "extreme favorite inputs should clamp to the configured ceiling")
	_expect(absf(floor_win_rate - floor_probability) <= TOLERANCE, "floor-adjacent theoretical probability should stay within ±0.05 over 1000 seeded trials")
	_expect(absf(ceiling_win_rate - ceiling_probability) <= TOLERANCE, "ceiling-adjacent theoretical probability should stay within ±0.05 over 1000 seeded trials")
	_expect(ceiling_win_rate >= 0.95, "deterministically stronger side should win at least 95 percent of 1000 seeded trials")


func test_manual_formula_samples_expose_intermediate_steps_and_match_system_output() -> void:
	# Arrange
	var config: BalanceConfig = _load_balance_config()
	if config == null:
		return
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var source_state: BalanceConfig.AttributeState = BalanceConfig.AttributeState.new(72.0, 90.0)
	var normalized_state: BalanceConfig.AttributeState = config.normalize_attribute_state(source_state)
	var flat_adjusted_value: float = normalized_state.current + 8.0
	var multiplied_value: float = flat_adjusted_value * 1.10
	var effective_state: BalanceConfig.AttributeState = config.compute_effective_attribute_value(source_state, 8.0, 0.10)
	var growth_ratio: float = 1.0 - 40.0 / 80.0
	var expected_growth: float = 3.0 * pow(growth_ratio, 1.5)
	var actual_growth: float = player_development.attribute_growth(3.0, 40, 80, 1.5)
	var expected_positional_rating: float = 75.0 * 0.20 + 70.0 * 0.25 + 80.0 * 0.25 + 65.0 * 0.15 + 72.0 * 0.15
	var actual_positional_rating: float = config.compute_positional_overall_rating(
		75.0,
		70.0,
		80.0,
		65.0,
		72.0,
		BalanceConfig.AttributeWeights.new(0.20, 0.25, 0.25, 0.15, 0.15),
	)
	var unclamped_win_probability: float = 0.50 + (75.0 - 60.0) * config.rating_win_slope
	var actual_win_probability: float = config.compute_base_win_probability(75.0, 60.0)
	var clamped_effective_state: BalanceConfig.AttributeState = config.compute_effective_attribute_value(BalanceConfig.AttributeState.new(100.0, 100.0), 15.0, 0.30)

	# Assert
	_expect(is_equal_approx(flat_adjusted_value, 80.0), "manual review should expose the flat-modifier intermediate step before percent scaling")
	_expect(is_equal_approx(multiplied_value, 88.0), "manual review should expose the multiplied intermediate step before clamp")
	_expect(is_equal_approx(effective_state.effective, 88.0), "effective attribute sample should match the hand-calculated flat-then-percent result")
	_expect(is_equal_approx(expected_growth, actual_growth), "attribute growth sample should match the hand-calculated decay formula")
	_expect(is_equal_approx(actual_positional_rating, expected_positional_rating), "positional rating sample should match the hand-calculated weighted average")
	_expect(is_equal_approx(unclamped_win_probability, 0.5675), "manual review should expose the unclamped base win probability before final boundary enforcement")
	_expect(is_equal_approx(actual_win_probability, 0.5675), "base win probability sample should match the hand-calculated slope result")
	_expect(is_equal_approx(clamped_effective_state.effective, 100.0), "overflowing effective attribute samples should clamp at the configured upper bound")


func test_illegal_inputs_normalize_before_formula_use_and_repeat_stably() -> void:
	# Arrange
	var config: BalanceConfig = _load_balance_config()
	if config == null:
		return
	var fallback_weights: BalanceConfig.AttributeWeights = BalanceConfig.AttributeWeights.new(0.0, 0.0, 0.0, 0.0, 0.0)

	# Act / Assert
	for _attempt: int in range(100):
		var negative_state: BalanceConfig.AttributeState = config.normalize_attribute_state(BalanceConfig.AttributeState.new(-10.0, 0.0))
		var over_cap_state: BalanceConfig.AttributeState = config.normalize_attribute_state(BalanceConfig.AttributeState.new(120.0, 140.0))
		var reversed_state: BalanceConfig.AttributeState = config.normalize_attribute_state(BalanceConfig.AttributeState.new(70.0, 60.0))
		var normalized_weights: BalanceConfig.AttributeWeights = config.normalize_attribute_weights(BalanceConfig.AttributeWeights.new(-0.20, 0.20, 0.20, 0.20, 0.20))
		var fallback_rating: float = config.compute_positional_overall_rating(70.0, 72.0, 74.0, 68.0, 73.0, fallback_weights)
		var invalid_ap_sample: BalanceConfig.DiagnosticSample = config.compute_action_point_use_rate(NAN, INF)
		var missing_even_sample: BalanceConfig.DiagnosticSample = config.compute_even_match_win_rate([], [])
		_expect(is_equal_approx(negative_state.current, 1.0), "negative current attribute input should normalize to the lower bound")
		_expect(is_equal_approx(negative_state.potential, 1.0), "negative potential input should normalize up to the legal minimum")
		_expect(is_equal_approx(over_cap_state.current, 100.0), "current values above 100 should clamp to the upper bound")
		_expect(is_equal_approx(over_cap_state.potential, 100.0), "potential values above 100 should clamp to the upper bound")
		_expect(is_equal_approx(reversed_state.current, 70.0), "valid current values should remain unchanged during normalization")
		_expect(is_equal_approx(reversed_state.potential, 70.0), "potential values below current should normalize up to current")
		_expect(is_equal_approx(normalized_weights.spd, 0.0), "negative weights should clamp to zero before normalization")
		_expect(is_equal_approx(normalized_weights.pwr, 0.25), "remaining positive weights should renormalize after invalid entries are removed")
		_expect(is_equal_approx(fallback_rating, 71.4), "missing weights should fall back to the arithmetic average rating")
		_expect(is_equal_approx(invalid_ap_sample.value, 0.0), "invalid KPI samples should return a safe zero value")
		_expect(invalid_ap_sample.invalid_sample, "invalid KPI samples should remain flagged invalid across repeated runs")
		_expect(is_equal_approx(missing_even_sample.value, 0.0), "missing even-match samples should return a safe zero value")
		_expect(missing_even_sample.invalid_sample, "missing even-match samples should remain flagged invalid across repeated runs")


func test_aggregate_kpi_results_remain_identical_when_operation_order_changes() -> void:
	# Arrange
	var config: BalanceConfig = _load_balance_config()
	if config == null:
		return
	var ordered_operations: Array[OperationSample] = [
		OperationSample.new(3.0, 5.0, 0.45, true, 10.0),
		OperationSample.new(2.0, 4.0, 0.60, false, 8.0),
		OperationSample.new(1.0, 3.0, 0.55, true, 6.0),
	]
	var reordered_operations: Array[OperationSample] = [
		OperationSample.new(1.0, 3.0, 0.55, true, 6.0),
		OperationSample.new(3.0, 5.0, 0.45, true, 10.0),
		OperationSample.new(2.0, 4.0, 0.60, false, 8.0),
	]

	# Act
	var ordered_summary: AggregateSummary = _summarize_operations(config, ordered_operations)
	var reordered_summary: AggregateSummary = _summarize_operations(config, reordered_operations)

	# Assert
	_expect(is_equal_approx(ordered_summary.total_duration, reordered_summary.total_duration), "equal total duration should remain unchanged when atomic operation order changes")
	_expect(is_equal_approx(ordered_summary.total_spent, reordered_summary.total_spent), "equal total spent resources should remain unchanged when atomic operation order changes")
	_expect(is_equal_approx(ordered_summary.total_available, reordered_summary.total_available), "equal total available resources should remain unchanged when atomic operation order changes")
	_expect(is_equal_approx(ordered_summary.action_point_use_rate.value, reordered_summary.action_point_use_rate.value), "aggregate action point use rate should be order-independent when totals are unchanged")
	_expect(ordered_summary.action_point_use_rate.invalid_sample == reordered_summary.action_point_use_rate.invalid_sample, "aggregate action point invalid-sample flags should be order-independent")
	_expect(is_equal_approx(ordered_summary.overall_win_rate.value, reordered_summary.overall_win_rate.value), "aggregate overall win rate should be order-independent when totals are unchanged")
	_expect(ordered_summary.overall_win_rate.invalid_sample == reordered_summary.overall_win_rate.invalid_sample, "aggregate overall win-rate invalid flags should be order-independent")
	_expect(is_equal_approx(ordered_summary.even_match_win_rate.value, reordered_summary.even_match_win_rate.value), "aggregate even-match win rate should be order-independent when the even-match sample set is unchanged")
	_expect(ordered_summary.even_match_win_rate.invalid_sample == reordered_summary.even_match_win_rate.invalid_sample, "aggregate even-match invalid flags should be order-independent")


func _load_balance_config() -> BalanceConfig:
	if _config != null:
		return _config
	_config = ConfigLoaderScript.new().load_balance_config_from_path(BALANCE_CONFIG_PATH) as BalanceConfig
	if _config == null:
		_expect(false, "balance config resource should load successfully from %s" % BALANCE_CONFIG_PATH)
	return _config


func _simulate_seeded_trials(config: BalanceConfig, seed: int, trial_count: int, home_strength: float, away_strength: float) -> float:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	var base_win_probability: float = config.compute_base_win_probability(home_strength, away_strength)
	var wins: int = 0
	for _trial_index: int in range(trial_count):
		var roll: float = rng.randf()
		_expect(roll >= 0.0 and roll < 1.0, "seeded random terms should stay inside [0, 1)")
		if roll < base_win_probability:
			wins += 1
	return float(wins) / float(trial_count)


func _max_rate_delta(win_rates: Array[float]) -> float:
	var minimum_rate: float = win_rates[0]
	var maximum_rate: float = win_rates[0]
	for win_rate: float in win_rates:
		minimum_rate = minf(minimum_rate, win_rate)
		maximum_rate = maxf(maximum_rate, win_rate)
	return maximum_rate - minimum_rate


func _summarize_operations(config: BalanceConfig, operations: Array[OperationSample]) -> AggregateSummary:
	var total_spent: float = 0.0
	var total_available: float = 0.0
	var total_wins: int = 0
	var total_matches: int = 0
	var total_duration: float = 0.0
	var base_probabilities: Array[float] = []
	var did_win_samples: Array[bool] = []
	for operation: OperationSample in operations:
		total_spent += operation.spent
		total_available += operation.available
		total_duration += operation.duration
		base_probabilities.append(operation.base_probability)
		did_win_samples.append(operation.did_win)
		total_matches += 1
		if operation.did_win:
			total_wins += 1
	return AggregateSummary.new(
		total_spent,
		total_available,
		total_duration,
		config.compute_action_point_use_rate(total_spent, total_available),
		config.compute_overall_win_rate(total_wins, total_matches),
		config.compute_even_match_win_rate(base_probabilities, did_win_samples),
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
