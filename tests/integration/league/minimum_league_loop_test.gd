extends Node

const LeagueConfigScript: Script = preload("res://src/config/league_config.gd")
const LeagueStructureScript: Script = preload("res://src/core/league_structure.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_minimum_league_loop_generates_double_round_robin_schedule()
	test_minimum_league_loop_result_packet_updates_standings()
	test_minimum_league_loop_duplicate_match_id_is_no_op()
	test_minimum_league_loop_finalize_on_time_season_ended_only_once()
	test_minimum_league_loop_serialize_deserialize_preserves_state_and_dedup()
	await get_tree().process_frame
	if _failures.is_empty():
		print("MINIMUM_LEAGUE_LOOP_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("MINIMUM_LEAGUE_LOOP_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_minimum_league_loop_generates_double_round_robin_schedule() -> void:
	var league: Node = _build_league()
	var schedule: Array[Dictionary] = _get_schedule(league)
	_expect(schedule.size() == 56, "8-team double round-robin should produce 56 matches")
	_assert_each_team_has_match_count(schedule, 8, 14)
	_assert_pairings_are_home_away_double_round_robin(schedule)
	_free_if_node(league)


func test_minimum_league_loop_result_packet_updates_standings() -> void:
	var league: Node = _build_league()
	var first_match: Dictionary = _get_schedule(league)[0]
	var home_team_id: int = int(first_match.get("home_team_id", -1))
	var away_team_id: int = int(first_match.get("away_team_id", -1))
	var applied: bool = _apply_match_result(league, _make_result_packet(String(first_match.get("match_id", "")), "home_win", 2, 1))
	_expect(applied, "first confirmed result should apply")
	var home_standing: Dictionary = _find_standing(_get_standings(league), home_team_id)
	var away_standing: Dictionary = _find_standing(_get_standings(league), away_team_id)
	_assert_standing(home_standing, 1, 1, 0, 0, 2, 1, 3, "home winner standing should update")
	_assert_standing(away_standing, 1, 0, 0, 1, 1, 2, 0, "away loser standing should update")
	_free_if_node(league)


func test_minimum_league_loop_duplicate_match_id_is_no_op() -> void:
	var league: Node = _build_league()
	var first_match: Dictionary = _get_schedule(league)[0]
	var match_id: String = String(first_match.get("match_id", ""))
	var packet: Dictionary[String, Variant] = _make_result_packet(match_id, "home_win", 2, 1)
	_expect(_apply_match_result(league, packet), "first result should apply before duplicate check")
	var standings_after_first: Array[Dictionary] = _get_standings(league)
	var completed_after_first: int = _count_completed_matches(_get_schedule(league))
	_expect(not _apply_match_result(league, packet), "duplicate match_id should be a no-op")
	_expect(_count_completed_matches(_get_schedule(league)) == completed_after_first, "duplicate should not increase completed match count")
	_assert_standings_equal(standings_after_first, _get_standings(league), "duplicate should not mutate standings")
	_free_if_node(league)


func test_minimum_league_loop_finalize_on_time_season_ended_only_once() -> void:
	var league: Node = _build_league()
	_expect(not _finalize_season(league), "early season end should be rejected while scheduled matches remain")
	_apply_all_remaining_matches(league)
	_expect(_finalize_season(league), "season end should finalize after all matches complete")
	var summary_after_first: Dictionary[String, Variant] = _get_summary(league)
	_expect(String(summary_after_first.get("season_state", "")) == "COMPLETED", "summary should report COMPLETED after finalization")
	_expect(bool(summary_after_first.get("season_completed", false)), "summary should flag season_completed")
	_expect(summary_after_first.has("next_tier"), "summary should include next_tier")
	_expect(summary_after_first.has("next_tier_intent"), "summary should include next_tier_intent")
	_expect(not _finalize_season(league), "second season end should be a no-op")
	_assert_dictionaries_equal(summary_after_first, _get_summary(league), "second finalization should not mutate summary")
	_free_if_node(league)


func test_minimum_league_loop_serialize_deserialize_preserves_state_and_dedup() -> void:
	var league: Node = _build_league()
	var first_match: Dictionary = _get_schedule(league)[0]
	var match_id: String = String(first_match.get("match_id", ""))
	var packet: Dictionary[String, Variant] = _make_result_packet(match_id, "home_win", 2, 1)
	_expect(_apply_match_result(league, packet), "first result should apply before serialize")
	var serialized: Dictionary[String, Variant] = _serialize_league(league)
	var restored: Node = _build_empty_league()
	_deserialize_league(restored, serialized)
	_assert_standings_equal(_get_standings(league), _get_standings(restored), "restored standings should match original")
	_expect(_count_completed_matches(_get_schedule(restored)) == 1, "restored schedule should preserve completed flags")
	_expect(_get_current_round(restored) == _get_current_round(league), "restored current round should match original")
	_assert_dictionaries_equal(_get_next_match(league), _get_next_match(restored), "restored next match should match original")
	_expect(not _apply_match_result(restored, packet), "restored completed match should still reject duplicate packet")
	_assert_standings_equal(_get_standings(league), _get_standings(restored), "duplicate after restore should not mutate standings")
	_free_if_node(league)
	_free_if_node(restored)


func _build_config() -> Resource:
	var config: Resource = LeagueConfigScript.new()
	var opponent_names: Array[String] = [
		"Opponent 1",
		"Opponent 2",
		"Opponent 3",
		"Opponent 4",
		"Opponent 5",
		"Opponent 6",
		"Opponent 7",
	]
	config.set("league_name", "Contract League")
	config.set("team_count", 8)
	config.set("player_team_name", "Player Team")
	config.set("opponent_team_names", opponent_names)
	config.set("double_round_robin", true)
	config.set("points_win", 3)
	config.set("points_draw", 1)
	config.set("points_loss", 0)
	config.set("promotion_slots", 1)
	config.set("relegation_slots", 1)
	return config


func _build_league() -> Node:
	var league: Node = _build_empty_league()
	league.call("initialize_from_config", _build_config())
	return league


func _build_empty_league() -> Node:
	return LeagueStructureScript.new() as Node


func _make_result_packet(match_id: String, result: String, home_score: int, away_score: int) -> Dictionary[String, Variant]:
	return {
		"match_id": match_id,
		"result": result,
		"score": {
			"home": home_score,
			"away": away_score,
		},
	}


func _apply_match_result(league: Node, packet: Dictionary[String, Variant]) -> bool:
	if league.has_method("apply_confirmed_match_result"):
		return bool(league.call("apply_confirmed_match_result", packet))
	if league.has_method("apply_match_result"):
		return bool(league.call("apply_match_result", packet))
	if league.has_method("_on_match_completed_event"):
		league.call("_on_match_completed_event", "match_completed", packet)
		return true
	_failures.append("LeagueStructure exposes no match result application method")
	return false


func _finalize_season(league: Node) -> bool:
	var payload: Dictionary[String, Variant] = {"season_number": 1}
	if league.has_method("finalize_on_time_season_ended"):
		return bool(league.call("finalize_on_time_season_ended", payload))
	if league.has_method("_on_time_season_ended_event"):
		league.call("_on_time_season_ended_event", "time_season_ended", payload)
		return true
	_failures.append("LeagueStructure exposes no season finalization method")
	return false


func _serialize_league(league: Node) -> Dictionary[String, Variant]:
	if league.has_method("serialize"):
		return _to_string_variant_dictionary(league.call("serialize"))
	_failures.append("LeagueStructure exposes no serialize method")
	return {}


func _deserialize_league(league: Node, data: Dictionary[String, Variant]) -> void:
	if league.has_method("deserialize"):
		league.call("deserialize", data)
		return
	_failures.append("LeagueStructure exposes no deserialize method")


func _get_schedule(league: Node) -> Array[Dictionary]:
	var serialized: Dictionary[String, Variant] = _serialize_league(league)
	return _to_dictionary_array(serialized.get("schedule", []))


func _get_standings(league: Node) -> Array[Dictionary]:
	if league.has_method("get_standings"):
		return _to_dictionary_array(league.call("get_standings"))
	var serialized: Dictionary[String, Variant] = _serialize_league(league)
	return _to_dictionary_array(serialized.get("standings", []))


func _get_next_match(league: Node) -> Dictionary[String, Variant]:
	if league.has_method("get_next_match"):
		return _to_string_variant_dictionary(league.call("get_next_match"))
	var schedule: Array[Dictionary] = _get_schedule(league)
	for match_record: Dictionary in schedule:
		if not bool(match_record.get("is_completed", false)):
			return _to_string_variant_dictionary(match_record)
	return {}


func _get_current_round(league: Node) -> int:
	if league.has_method("get_current_round"):
		return int(league.call("get_current_round"))
	return int(_get_next_match(league).get("round", 0))


func _get_summary(league: Node) -> Dictionary[String, Variant]:
	if league.has_method("get_season_summary"):
		return _to_string_variant_dictionary(league.call("get_season_summary"))
	return _serialize_league(league)


func _apply_all_remaining_matches(league: Node) -> void:
	var schedule: Array[Dictionary] = _get_schedule(league)
	for match_record: Dictionary in schedule:
		if bool(match_record.get("is_completed", false)):
			continue
		var match_id: String = String(match_record.get("match_id", ""))
		var home_id: int = int(match_record.get("home_team_id", -1))
		var away_id: int = int(match_record.get("away_team_id", -1))
		var result: String = "home_win" if home_id <= away_id else "away_win"
		var home_score: int = 2 if result == "home_win" else 1
		var away_score: int = 1 if result == "home_win" else 2
		_expect(_apply_match_result(league, _make_result_packet(match_id, result, home_score, away_score)), "remaining scheduled match should apply: %s" % match_id)


func _assert_each_team_has_match_count(schedule: Array[Dictionary], team_count: int, expected_count: int) -> void:
	var counts: Dictionary[int, int] = {}
	for team_id: int in range(team_count):
		counts[team_id] = 0
	for match_record: Dictionary in schedule:
		var home_id: int = int(match_record.get("home_team_id", -1))
		var away_id: int = int(match_record.get("away_team_id", -1))
		counts[home_id] = int(counts.get(home_id, 0)) + 1
		counts[away_id] = int(counts.get(away_id, 0)) + 1
	for team_id: int in range(team_count):
		_expect(int(counts.get(team_id, 0)) == expected_count, "team %s should have %s matches" % [str(team_id), str(expected_count)])


func _assert_pairings_are_home_away_double_round_robin(schedule: Array[Dictionary]) -> void:
	var pairings: Dictionary[String, Array] = {}
	for match_record: Dictionary in schedule:
		var home_id: int = int(match_record.get("home_team_id", -1))
		var away_id: int = int(match_record.get("away_team_id", -1))
		var low_id: int = mini(home_id, away_id)
		var high_id: int = maxi(home_id, away_id)
		var pairing_key: String = "%s:%s" % [str(low_id), str(high_id)]
		if not pairings.has(pairing_key):
			pairings[pairing_key] = []
		(pairings[pairing_key] as Array).append("%s-%s" % [str(home_id), str(away_id)])
	for pairing_key: String in pairings.keys():
		var meetings: Array = pairings[pairing_key]
		_expect(meetings.size() == 2, "pairing %s should appear exactly twice" % pairing_key)
		if meetings.size() == 2:
			var first_sides: PackedStringArray = String(meetings[0]).split("-")
			var second_sides: PackedStringArray = String(meetings[1]).split("-")
			_expect(first_sides[0] == second_sides[1] and first_sides[1] == second_sides[0], "pairing %s should reverse home/away" % pairing_key)


func _assert_standing(standing: Dictionary, played: int, wins: int, draws: int, losses: int, goals_for: int, goals_against: int, points: int, context: String) -> void:
	_expect(int(standing.get("played", -1)) == played, "%s played" % context)
	_expect(int(standing.get("wins", -1)) == wins, "%s wins" % context)
	_expect(int(standing.get("draws", -1)) == draws, "%s draws" % context)
	_expect(int(standing.get("losses", -1)) == losses, "%s losses" % context)
	_expect(int(standing.get("goals_for", -1)) == goals_for, "%s goals_for" % context)
	_expect(int(standing.get("goals_against", -1)) == goals_against, "%s goals_against" % context)
	_expect(int(standing.get("goal_difference", -999)) == goals_for - goals_against, "%s goal_difference" % context)
	_expect(int(standing.get("points", -1)) == points, "%s points" % context)


func _find_standing(standings: Array[Dictionary], team_id: int) -> Dictionary:
	for standing: Dictionary in standings:
		if int(standing.get("team_id", -1)) == team_id:
			return standing
	_failures.append("Standing not found for team_id %s" % str(team_id))
	return {}


func _count_completed_matches(schedule: Array[Dictionary]) -> int:
	var completed_count: int = 0
	for match_record: Dictionary in schedule:
		if bool(match_record.get("is_completed", false)):
			completed_count += 1
	return completed_count


func _assert_standings_equal(left: Array[Dictionary], right: Array[Dictionary], context: String) -> void:
	_expect(left.size() == right.size(), "%s standings size" % context)
	var record_count: int = mini(left.size(), right.size())
	for index: int in range(record_count):
		_assert_dictionaries_equal(_to_string_variant_dictionary(left[index]), _to_string_variant_dictionary(right[index]), "%s standings[%s]" % [context, str(index)])


func _assert_dictionaries_equal(left: Dictionary, right: Dictionary, context: String) -> void:
	var left_keys: Array = left.keys()
	var right_keys: Array = right.keys()
	left_keys.sort()
	right_keys.sort()
	_expect(left_keys == right_keys, "%s keys should match" % context)
	for key: Variant in left_keys:
		_expect(left[key] == right.get(key), "%s value for %s should match" % [context, String(key)])


func _to_dictionary_array(value: Variant) -> Array[Dictionary]:
	var typed_array: Array[Dictionary] = []
	if not (value is Array):
		return typed_array
	var source: Array = value as Array
	for element: Variant in source:
		if element is Dictionary:
			typed_array.append(element as Dictionary)
	return typed_array


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	var source: Dictionary = value as Dictionary
	for key: Variant in source.keys():
		typed_dictionary[String(key)] = source[key]
	return typed_dictionary


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _free_if_node(value: Variant) -> void:
	if value is Node:
		(value as Node).queue_free()
