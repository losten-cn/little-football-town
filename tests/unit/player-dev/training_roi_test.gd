extends Node

const PlayerScript: Script = preload("res://src/core/player.gd")
const PlayerDevelopmentScript: Script = preload("res://src/core/player_development.gd")
const EconomyManagerScript: Script = preload("res://src/core/economy_manager.gd")
const EconomyConfigScript: Script = preload("res://src/config/economy_config.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_training_focus_match_multiplier_distinguishes_matched_and_mismatched_projects()
	test_secondary_attribute_gain_ratio_stays_within_story_band_and_marks_cap_limited_cases()
	test_player_development_roi_uses_economy_manager_ap_to_funds_weight_without_local_override()
	test_roi_samples_derive_ordinary_vs_star_tradeoff_from_training_samples()
	test_roi_samples_report_tuning_failure_when_tradeoff_targets_are_missed()
	if _failures.is_empty():
		print("TRAINING_ROI_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("TRAINING_ROI_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_training_focus_match_multiplier_distinguishes_matched_and_mismatched_projects() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var matched_project: Dictionary[String, Variant] = {"focus_match_multiplier": 1.15}
	var neutral_project: Dictionary[String, Variant] = {"focus_match_multiplier": 1.0}
	var mismatched_project: Dictionary[String, Variant] = {"focus_match_multiplier": 0.85}
	var missing_project: Dictionary[String, Variant] = {}

	# Act
	var matched_multiplier: float = player_development.resolve_training_focus_match_multiplier(matched_project)
	var neutral_multiplier: float = player_development.resolve_training_focus_match_multiplier(neutral_project)
	var mismatched_multiplier: float = player_development.resolve_training_focus_match_multiplier(mismatched_project)
	var missing_multiplier: float = player_development.resolve_training_focus_match_multiplier(missing_project)

	# Assert
	_expect(matched_multiplier >= 1.0, "matched training projects should have a multiplier of at least 1.0")
	_expect(is_equal_approx(neutral_multiplier, 1.0), "neutral training projects may sit exactly at 1.0")
	_expect(mismatched_multiplier <= 1.0, "mismatched training projects should have a multiplier of at most 1.0")
	_expect(is_equal_approx(missing_multiplier, 1.0), "missing focus multiplier config should not default to a bonus")


func test_secondary_attribute_gain_ratio_stays_within_story_band_and_marks_cap_limited_cases() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var open_room_player: Player = _build_player(40, 90, 1.0, 1.0, 1.0)
	var cap_limited_player: Player = _build_player(40, 90, 1.0, 1.0, 1.0)
	cap_limited_player.attributes.pwr.current = 69
	cap_limited_player.attributes.pwr.potential = 70
	cap_limited_player.attributes.tec.current = 69
	cap_limited_player.attributes.tec.potential = 70
	var primary_gain: float = player_development.apply_training_gain_to_attribute(open_room_player, "SPD", 4.0, 1.1, 1.0, 1.0)

	# Act
	var secondary_result: Dictionary[String, Variant] = player_development.resolve_secondary_attribute_gains(
		open_room_player,
		["PWR", "TEC"],
		4.0,
		1.1,
		1.0,
		1.0,
		0.15,
	)
	var cap_limited_secondary_result: Dictionary[String, Variant] = player_development.resolve_secondary_attribute_gains(
		cap_limited_player,
		["PWR", "TEC"],
		200.0,
		1.1,
		1.0,
		1.0,
		0.35,
	)
	var secondary_gains: Dictionary[String, float] = secondary_result["gains"]
	var secondary_total_gain: float = secondary_gains.get("PWR", 0.0) + secondary_gains.get("TEC", 0.0)
	var ratio: float = secondary_total_gain / primary_gain if primary_gain > 0.0 else 0.0

	# Assert
	_expect(primary_gain >= secondary_total_gain, "primary attribute gain should be at least the total secondary gain")
	_expect(ratio >= 0.10, "secondary total gain should stay above the 10% lower ratio bound")
	_expect(ratio <= 0.35, "secondary total gain should stay below the 35% upper ratio bound")
	_expect(cap_limited_secondary_result["cap_limited"] as bool, "secondary attributes clipped by potential should be marked as cap-limited")


func test_player_development_roi_uses_economy_manager_ap_to_funds_weight_without_local_override() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var economy_manager: EconomyManager = EconomyManagerScript.new()
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_config.ap_to_funds_weight = 50.0
	economy_manager.set_economy_config_for_testing(economy_config)

	# Act
	var authoritative_weight: float = economy_manager.get_ap_to_funds_weight()
	var roi_with_authoritative_weight: float = player_development.calculate_player_development_roi(2.0, 0.4, 30.0, 5.0, 1.0, authoritative_weight)
	economy_config.ap_to_funds_weight = 60.0
	var roi_with_updated_authoritative_weight: float = player_development.calculate_player_development_roi(2.0, 0.4, 30.0, 5.0, 1.0, economy_manager.get_ap_to_funds_weight())
	economy_manager.set_economy_config_for_testing(null)
	var roi_with_missing_weight: float = player_development.calculate_player_development_roi(2.0, 0.4, 30.0, 5.0, 1.0, economy_manager.get_ap_to_funds_weight())
	var expected_authoritative_roi: float = (2.0 + 0.4 * 0.35) / (30.0 + 5.0 * 50.0 + 1.0)

	# Assert
	_expect(is_equal_approx(authoritative_weight, 50.0), "economy manager should expose the authoritative default AP-to-funds weight")
	_expect(is_equal_approx(roi_with_authoritative_weight, expected_authoritative_roi), "ROI should use the EconomyManager-provided AP-to-funds weight directly")
	_expect(roi_with_updated_authoritative_weight < roi_with_authoritative_weight, "raising the authoritative AP valuation should reduce ROI when all gains stay constant")
	_expect(is_equal_approx(roi_with_missing_weight, -1.0), "missing EconomyManager AP valuation should fail explicitly instead of silently using a local override")


func test_roi_samples_derive_ordinary_vs_star_tradeoff_from_training_samples() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var economy_manager: EconomyManager = EconomyManagerScript.new()
	var economy_config: EconomyConfig = EconomyConfigScript.new()
	economy_manager.set_economy_config_for_testing(economy_config)
	var ordinary_short_term_roi: float = player_development.calculate_player_development_roi(4.2, 0.7, 40.0, 1.0, 1.0, economy_manager.get_ap_to_funds_weight())
	var star_short_term_roi: float = player_development.calculate_player_development_roi(4.4, 0.8, 90.0, 2.0, 1.0, economy_manager.get_ap_to_funds_weight())
	var ordinary_mid_term_roi: float = player_development.calculate_player_development_roi(5.5, 0.9, 80.0, 2.0, 2.0, economy_manager.get_ap_to_funds_weight())
	var star_mid_term_roi: float = player_development.calculate_player_development_roi(8.8, 1.6, 90.0, 2.0, 2.0, economy_manager.get_ap_to_funds_weight())

	# Act
	var roi_evaluation: Dictionary[String, Variant] = player_development.evaluate_roi_sample(
		ordinary_short_term_roi,
		star_short_term_roi,
		ordinary_mid_term_roi,
		star_mid_term_roi,
	)

	# Assert
	_expect(ordinary_short_term_roi >= star_short_term_roi * 0.9, "ordinary short-term ROI should stay within the target band relative to the star sample")
	_expect(star_mid_term_roi > ordinary_mid_term_roi, "star mid-term ROI should exceed the ordinary sample in the longer horizon")
	_expect(roi_evaluation["passes"] as bool, "ordinary-vs-star ROI samples that satisfy the target tradeoff should pass")
	_expect(not (roi_evaluation["tuning_failure"] as bool), "passing ordinary-vs-star ROI samples should not mark tuning failure")


func test_roi_samples_report_tuning_failure_when_tradeoff_targets_are_missed() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()

	# Act
	var passing_result: Dictionary[String, Variant] = player_development.evaluate_roi_sample(1.0, 1.0, 0.8, 1.1)
	var failing_result: Dictionary[String, Variant] = player_development.evaluate_roi_sample(0.7, 1.0, 1.0, 0.9)

	# Assert
	_expect(passing_result["passes"] as bool, "ROI samples that satisfy short- and mid-term targets should pass")
	_expect(not (passing_result["tuning_failure"] as bool), "passing ROI samples should not mark tuning failure")
	_expect(not (failing_result["passes"] as bool), "ROI samples that miss target bands should fail")
	_expect(failing_result["tuning_failure"] as bool, "failing ROI samples should mark tuning failure instead of rewriting the formula")


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
	player.attributes.pwr.current = current_attribute
	player.attributes.pwr.potential = potential_cap
	player.attributes.tec.current = current_attribute
	player.attributes.tec.potential = potential_cap
	return player


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
