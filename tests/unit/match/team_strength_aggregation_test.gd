extends SceneTree

const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")
const MatchConfigScript: Script = preload("res://src/config/match_config.gd")
const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")
const PlayerScript: Script = preload("res://src/core/player.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	test_team_match_strength_uses_weighted_rating_chemistry_and_facility_bonus()
	test_out_of_position_assignment_lowers_positional_rating()
	test_recommended_pre_match_setup_is_legal_without_manual_adjustment()
	if _failures.is_empty():
		print("TEAM_STRENGTH_AGGREGATION_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("TEAM_STRENGTH_AGGREGATION_TEST_FAIL: %s" % failure)
		quit(1)


func test_team_match_strength_uses_weighted_rating_chemistry_and_facility_bonus() -> void:
	var simulation: MatchSimulation = _build_simulation()
	var players: Array[Player] = _build_recommended_players()
	var lineup_slots: Array[Dictionary] = []
	for player: Player in players:
		lineup_slots.append({
			"player": player,
			"assigned_position": player.position,
			"lineup_weight": 1.0,
		})
	var chemistry_factor: float = 1.10
	var facility_rating_bonus: float = 6.0
	var weighted_sum: float = 0.0
	for lineup_slot_variant: Variant in lineup_slots:
		var lineup_slot: Dictionary = lineup_slot_variant as Dictionary
		weighted_sum += simulation.compute_player_positional_rating(lineup_slot["player"] as Player, String(lineup_slot["assigned_position"]))
	var expected_strength: float = (weighted_sum / float(lineup_slots.size())) * chemistry_factor + facility_rating_bonus
	var actual_strength: float = simulation.compute_team_match_strength(lineup_slots, chemistry_factor, facility_rating_bonus)
	_expect(is_equal_approx(actual_strength, expected_strength), "team_match_strength should equal weighted lineup average × chemistry + facility bonus")


func test_out_of_position_assignment_lowers_positional_rating() -> void:
	var simulation: MatchSimulation = _build_simulation()
	var player: Player = _create_player(1, "MF", 72, 68, 80, 78, 70)
	var preferred_rating: float = simulation.compute_player_positional_rating(player, "MF")
	var out_of_position_rating: float = simulation.compute_player_positional_rating(player, "FW")
	_expect(out_of_position_rating < preferred_rating, "out-of-position assignment should lower positional rating")
	_expect(out_of_position_rating >= 1.0, "out-of-position rating should remain within legal bounds")


func test_recommended_pre_match_setup_is_legal_without_manual_adjustment() -> void:
	var simulation: MatchSimulation = _build_simulation()
	var players: Array[Player] = _build_recommended_players()
	var setup: Dictionary[String, Variant] = simulation.build_recommended_pre_match_setup(players)
	var lineup_slots: Array[Dictionary] = setup.get("lineup_slots", []) as Array[Dictionary]
	_expect(lineup_slots.size() == 11, "recommended setup should produce an 11-player lineup")
	_expect(simulation.is_lineup_legal(lineup_slots), "recommended setup should be legal without manual adjustment")
	var tactics: Dictionary = setup.get("tactics", {}) as Dictionary
	_expect(String(tactics.get("label", "")) == "balanced", "recommended setup should expose the default recommended tactic")
	_expect(is_equal_approx(float(setup.get("chemistry_factor", 0.0)), 1.0), "recommended setup should use the default chemistry factor")


func _build_simulation() -> MatchSimulation:
	var simulation: MatchSimulation = MatchSimulationScript.new()
	root.add_child(simulation)
	simulation.set_match_config_for_testing(MatchConfigScript.new())
	simulation.set_balance_config_for_testing(BalanceConfigScript.new())
	return simulation


func _build_recommended_players() -> Array[Player]:
	return [
		_create_player(1, "GK", 48, 62, 40, 66, 71),
		_create_player(2, "DF", 60, 74, 52, 63, 76),
		_create_player(3, "DF", 58, 72, 50, 61, 74),
		_create_player(4, "DF", 57, 71, 49, 62, 73),
		_create_player(5, "DF", 59, 73, 51, 64, 75),
		_create_player(6, "MF", 69, 60, 74, 75, 68),
		_create_player(7, "MF", 68, 59, 73, 74, 67),
		_create_player(8, "MF", 70, 58, 75, 76, 69),
		_create_player(9, "FW", 77, 72, 78, 64, 66),
		_create_player(10, "FW", 79, 73, 80, 65, 67),
		_create_player(11, "FW", 76, 71, 77, 63, 65),
	]


func _create_player(id_value: int, position: String, spd: int, pwr: int, tec: int, intelligence: int, sta: int) -> Player:
	var player: Player = PlayerScript.new()
	player.id = id_value
	player.position = position
	player.condition_multiplier = 1.0
	player.morale_multiplier = 1.0
	player.attributes.spd.current = spd
	player.attributes.pwr.current = pwr
	player.attributes.tec.current = tec
	player.attributes.intelligence.current = intelligence
	player.attributes.sta.current = sta
	return player


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
