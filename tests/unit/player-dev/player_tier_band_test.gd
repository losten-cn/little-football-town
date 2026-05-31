extends Node

const PlayerScript: Script = preload("res://src/core/player.gd")
const PlayerDevelopmentScript: Script = preload("res://src/core/player_development.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_tier_band_mapping_matches_story_ranges()
	test_tier_default_training_efficiency_ranges_are_distinguishable()
	test_validate_player_tier_band_accepts_in_band_players_and_flags_missing_special_source()
	test_validate_player_tier_band_allows_out_of_band_players_with_explicit_source()
	test_compare_training_efficiency_gain_distinguishes_open_room_from_cap_clipping()
	if _failures.is_empty():
		print("PLAYER_TIER_BAND_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("PLAYER_TIER_BAND_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_tier_band_mapping_matches_story_ranges() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()

	# Act
	var ordinary_band: Vector2i = player_development.get_tier_potential_band("普通")
	var excellent_band: Vector2i = player_development.get_tier_potential_band("优秀")
	var star_band: Vector2i = player_development.get_tier_potential_band("明星")
	var prodigy_band: Vector2i = player_development.get_tier_potential_band("传奇胚子")
	var unknown_band: Vector2i = player_development.get_tier_potential_band("未知")

	# Assert
	_expect(ordinary_band == Vector2i(60, 75), "ordinary tier should map to the 60-75 potential band")
	_expect(excellent_band == Vector2i(72, 85), "excellent tier should map to the 72-85 potential band")
	_expect(star_band == Vector2i(82, 95), "star tier should map to the 82-95 potential band")
	_expect(prodigy_band == Vector2i(90, 99), "legendary prospect tier should map to the 90-99 potential band")
	_expect(unknown_band == Vector2i.ZERO, "unknown tiers should fail explicitly instead of falling back to an implicit band")


func test_tier_default_training_efficiency_ranges_are_distinguishable() -> void:
	# Arrange
	var balance_config: BalanceConfig = load("res://config/balance_config.tres") as BalanceConfig
	var normal_range: Vector2 = balance_config.player_tier_training_efficiency.get("normal", Vector2.ZERO) as Vector2
	var excellent_range: Vector2 = balance_config.player_tier_training_efficiency.get("excellent", Vector2.ZERO) as Vector2
	var star_range: Vector2 = balance_config.player_tier_training_efficiency.get("star", Vector2.ZERO) as Vector2
	var legend_range: Vector2 = balance_config.player_tier_training_efficiency.get("legend_prospect", Vector2.ZERO) as Vector2

	# Act
	var ranges_are_ordered: bool = normal_range.x < excellent_range.x
	ranges_are_ordered = ranges_are_ordered and excellent_range.x < star_range.x
	ranges_are_ordered = ranges_are_ordered and star_range.x < legend_range.x
	var ceilings_are_ordered: bool = normal_range.y < excellent_range.y
	ceilings_are_ordered = ceilings_are_ordered and excellent_range.y < star_range.y
	ceilings_are_ordered = ceilings_are_ordered and star_range.y <= legend_range.y

	# Assert
	_expect(balance_config != null, "balance config should load for tier efficiency validation")
	_expect(normal_range == Vector2(0.8, 1.0), "normal tier should expose the default 0.8-1.0 training efficiency range")
	_expect(excellent_range == Vector2(0.95, 1.2), "excellent tier should expose the default 0.95-1.2 training efficiency range")
	_expect(star_range == Vector2(1.1, 1.35), "star tier should expose the default 1.1-1.35 training efficiency range")
	_expect(legend_range == Vector2(1.25, 1.5), "legend prospect tier should expose the default 1.25-1.5 training efficiency range")
	_expect(ranges_are_ordered, "tier default training efficiency floors should be distinguishable and strictly ordered")
	_expect(ceilings_are_ordered, "tier default training efficiency ceilings should be distinguishable and ordered")


func test_validate_player_tier_band_accepts_in_band_players_and_flags_missing_special_source() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var in_band_player: Player = _build_player("普通", 1.0, 50, 70)
	in_band_player.attributes.spd.potential = 60
	in_band_player.attributes.pwr.potential = 75
	var out_of_band_player: Player = _build_player("普通", 1.0, 50, 70, "   ")
	out_of_band_player.attributes.spd.potential = 80

	# Act
	var in_band_result: Dictionary[String, Variant] = player_development.validate_player_tier_band(in_band_player)
	var out_of_band_result: Dictionary[String, Variant] = player_development.validate_player_tier_band(out_of_band_player)
	var out_of_band_attributes: Array[String] = out_of_band_result["out_of_band_attributes"]

	# Assert
	_expect(in_band_result["valid"] as bool, "players whose potential caps stay inside the tier band should pass validation")
	_expect(not (in_band_result["special_case"] as bool), "ordinary in-band players should not be marked as special cases")
	_expect((in_band_result["out_of_band_attributes"] as Array[String]).is_empty(), "in-band players should not report out-of-band attributes")
	_expect(not (out_of_band_result["valid"] as bool), "out-of-band players without a real source marker should fail validation")
	_expect(not (out_of_band_result["special_case"] as bool), "blank special sources should not qualify as explicit special-case markers")
	_expect(out_of_band_attributes.has("SPD"), "validation should name the out-of-band attributes that require review")
	_expect(out_of_band_player.review_flags.has("potential_cap_out_of_tier_band"), "out-of-band players without source markers should be flagged for review")
	_expect(String(out_of_band_result["reason"]) == "potential_cap_out_of_tier_band", "failed tier-band validation should report the out-of-band reason")


func test_validate_player_tier_band_allows_out_of_band_players_with_explicit_source() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var special_player: Player = _build_player("普通", 1.0, 50, 70, "youth_tournament_award")
	special_player.attributes.tec.potential = 82

	# Act
	var validation_result: Dictionary[String, Variant] = player_development.validate_player_tier_band(special_player)
	var out_of_band_attributes: Array[String] = validation_result["out_of_band_attributes"]

	# Assert
	_expect(validation_result["valid"] as bool, "out-of-band players with an explicit source should pass as approved special cases")
	_expect(validation_result["special_case"] as bool, "explicit-source players should be marked as special cases")
	_expect(out_of_band_attributes.has("TEC"), "special-case validation should still report which attribute sits outside the default band")
	_expect(String(validation_result["reason"]) == "special_case_source_present", "special-case validation should explain why the out-of-band player was accepted")
	_expect(not special_player.review_flags.has("potential_cap_out_of_tier_band"), "approved special cases should not be flagged for review")


func test_compare_training_efficiency_gain_distinguishes_open_room_from_cap_clipping() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var lower_efficiency_open_room_player: Player = _build_player("明星", 1.1, 60, 85)
	var higher_efficiency_open_room_player: Player = _build_player("明星", 1.3, 60, 85)
	var equal_efficiency_player_a: Player = _build_player("明星", 1.2, 60, 85)
	var equal_efficiency_player_b: Player = _build_player("明星", 1.2, 60, 85)
	var lower_efficiency_cap_player: Player = _build_player("明星", 1.1, 84, 85)
	var higher_efficiency_cap_player: Player = _build_player("明星", 1.3, 84, 85)

	# Act
	var open_room_result: Dictionary[String, float] = player_development.compare_training_efficiency_gain(
		lower_efficiency_open_room_player,
		higher_efficiency_open_room_player,
		"SPD",
		12.0,
		1.0,
		1.0,
		1.0,
	)
	var equal_efficiency_result: Dictionary[String, float] = player_development.compare_training_efficiency_gain(
		equal_efficiency_player_a,
		equal_efficiency_player_b,
		"SPD",
		9.0,
		1.0,
		1.0,
		1.0,
	)
	var cap_limited_result: Dictionary[String, float] = player_development.compare_training_efficiency_gain(
		lower_efficiency_cap_player,
		higher_efficiency_cap_player,
		"SPD",
		100.0,
		1.0,
		1.0,
		1.0,
	)
	var open_room_lower_gain: float = open_room_result["lower_gain"]
	var open_room_higher_gain: float = open_room_result["higher_gain"]
	var equal_gain_a: float = equal_efficiency_result["lower_gain"]
	var equal_gain_b: float = equal_efficiency_result["higher_gain"]
	var cap_limited_lower_gain: float = cap_limited_result["lower_gain"]
	var cap_limited_higher_gain: float = cap_limited_result["higher_gain"]

	# Assert
	_expect(open_room_higher_gain > open_room_lower_gain, "with matching conditions and open room, higher training efficiency should produce more growth")
	_expect(higher_efficiency_open_room_player.attributes.spd.current > lower_efficiency_open_room_player.attributes.spd.current, "with open room, higher training efficiency should also produce a larger realized attribute increase")
	_expect(is_equal_approx(equal_gain_a, equal_gain_b), "players with equal training efficiency should resolve the same gain")
	_expect(equal_efficiency_player_a.attributes.spd.current == equal_efficiency_player_b.attributes.spd.current, "equal training efficiency should produce the same realized attribute increase")
	_expect(is_equal_approx(cap_limited_lower_gain, cap_limited_higher_gain), "cap clipping may collapse the efficiency difference to the same final resolved gain")
	_expect(is_equal_approx(cap_limited_lower_gain, 1.0), "the cap-limited sample should be explained by the final point of remaining growth room")
	_expect(lower_efficiency_cap_player.attributes.spd.current == 85, "cap-limited lower-efficiency sample should finish exactly at potential")
	_expect(higher_efficiency_cap_player.attributes.spd.current == 85, "cap-limited higher-efficiency sample should finish exactly at potential")


func _build_player(
	tier: String,
	training_efficiency: float,
	current_attribute: int,
	potential_cap: int,
	special_trait_source: String = "",
) -> Player:
	var player: Player = PlayerScript.new()
	player.tier = tier
	player.training_efficiency = training_efficiency
	player.condition_multiplier = 1.0
	player.morale_multiplier = 1.0
	player.special_trait_source = special_trait_source
	player.attributes.spd.current = current_attribute
	player.attributes.spd.potential = potential_cap
	player.attributes.pwr.current = current_attribute
	player.attributes.pwr.potential = potential_cap
	player.attributes.tec.current = current_attribute
	player.attributes.tec.potential = potential_cap
	player.attributes.intelligence.current = current_attribute
	player.attributes.intelligence.potential = potential_cap
	player.attributes.sta.current = current_attribute
	player.attributes.sta.potential = potential_cap
	return player


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
