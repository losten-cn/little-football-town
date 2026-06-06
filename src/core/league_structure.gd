class_name LeagueStructure
extends Node
## Authoritative league season model for the minimum league loop.

const LeagueConfig = preload("res://src/config/league_config.gd")


enum SeasonState {
	PRE_SEASON,
	IN_PROGRESS,
	SETTLEMENT,
	COMPLETED,
}


class StandingsEntry:
	extends RefCounted

	var team_id: int = 0
	var team_name: String = ""
	var played: int = 0
	var wins: int = 0
	var draws: int = 0
	var losses: int = 0
	var goals_for: int = 0
	var goals_against: int = 0
	var goal_difference: int = 0
	var points: int = 0


	## Applies one confirmed result from this team's perspective.
	func apply_result(goals_scored: int, goals_conceded: int, perspective_result: String, points_win: int, points_draw: int, points_loss: int) -> void:
		played += 1
		goals_for += goals_scored
		goals_against += goals_conceded
		goal_difference = goals_for - goals_against
		match perspective_result:
			"win":
				wins += 1
				points += points_win
			"draw":
				draws += 1
				points += points_draw
			"loss":
				losses += 1
				points += points_loss


	## Returns a serializable shallow standings record.
	func to_state_record() -> Dictionary[String, Variant]:
		return {
			"team_id": team_id,
			"team_name": team_name,
			"played": played,
			"wins": wins,
			"draws": draws,
			"losses": losses,
			"goals_for": goals_for,
			"goals_against": goals_against,
			"goal_difference": goal_difference,
			"points": points,
		}


class ScheduledMatch:
	extends RefCounted

	var match_id: String = ""
	var round: int = 1
	var home_team_id: int = 0
	var home_team_name: String = ""
	var away_team_id: int = 0
	var away_team_name: String = ""
	var is_player_team_home: bool = false
	var is_completed: bool = false
	var home_score: int = 0
	var away_score: int = 0
	var result: String = ""


	## Applies one confirmed result to this scheduled match.
	func apply_result(confirmed_home_score: int, confirmed_away_score: int, confirmed_result: String) -> void:
		home_score = confirmed_home_score
		away_score = confirmed_away_score
		result = confirmed_result
		is_completed = true


	## Returns a serializable shallow schedule record.
	func to_state_record() -> Dictionary[String, Variant]:
		return {
			"match_id": match_id,
			"round": round,
			"home_team_id": home_team_id,
			"home_team_name": home_team_name,
			"away_team_id": away_team_id,
			"away_team_name": away_team_name,
			"is_player_team_home": is_player_team_home,
			"is_completed": is_completed,
			"home_score": home_score,
			"away_score": away_score,
			"result": result,
		}


class LeagueSeason:
	extends RefCounted

	var league_name: String = ""
	var season_number: int = 1
	var current_tier: int = 1
	var highest_tier: int = 1
	var lowest_tier: int = 1
	var team_count: int = 0
	var player_team_id: int = 0
	var player_team_name: String = ""
	var points_win: int = 3
	var points_draw: int = 1
	var points_loss: int = 0
	var promotion_slots: int = 1
	var relegation_slots: int = 1
	var season_state: int = SeasonState.PRE_SEASON
	var standings: Array[StandingsEntry] = []
	var schedule: Array[ScheduledMatch] = []
	var completed_match_count: int = 0


	## Returns the total number of rounds in the current season.
	func get_total_rounds() -> int:
		if team_count < 2:
			return 0
		return 2 * (team_count - 1)


	## Returns the total scheduled match count in the current season.
	func get_total_matches() -> int:
		return schedule.size()


var _league_config: LeagueConfig = null
var _current_season: LeagueSeason = null
var _event_bus: Node = null
var _standings_index_by_team_id: Dictionary[int, int] = {}
var _schedule_index_by_match_id: Dictionary[String, int] = {}


func _ready() -> void:
	if _event_bus == null:
		bind_event_bus(_resolve_default_event_bus())


func _exit_tree() -> void:
	_unsubscribe_from_event_bus()


## Binds an EventBus-compatible node for optional automatic league event handling.
func bind_event_bus(event_bus: Node) -> void:
	if _event_bus == event_bus:
		return
	_unsubscribe_from_event_bus()
	_event_bus = event_bus
	_subscribe_to_event_bus()


## Registers this system with SaveManager using the league persistence contract.
func register_with_save_manager(save_manager: Node) -> bool:
	if save_manager == null:
		return false
	if not save_manager.has_method("register_system"):
		return false
	return bool(save_manager.call("register_system", "league", Callable(self, "serialize"), Callable(self, "deserialize")))


## Initializes a fresh league season from the provided configuration resource.
func initialize_from_config(config: LeagueConfig) -> void:
	if config == null:
		push_error("LeagueStructure: initialize_from_config received null config")
		_clear_state()
		return
	var validation: Dictionary[String, Variant] = config.validate()
	if not bool(validation.get("valid", false)):
		push_error("LeagueStructure: invalid LeagueConfig: %s" % str(validation.get("errors", [])))
		_clear_state()
		return

	_league_config = config
	var season_number: int = 1
	var starting_tier: int = config.league_tier
	if _current_season != null:
		season_number = _current_season.season_number + 1
		if _current_season.season_state == SeasonState.COMPLETED:
			starting_tier = _resolve_next_tier(_current_season)

	_current_season = LeagueSeason.new()
	_current_season.league_name = config.league_name
	_current_season.season_number = season_number
	_current_season.current_tier = starting_tier
	_current_season.highest_tier = config.highest_tier
	_current_season.lowest_tier = config.lowest_tier
	_current_season.team_count = config.team_count
	_current_season.player_team_id = 0
	_current_season.player_team_name = config.player_team_name
	_current_season.points_win = config.points_win
	_current_season.points_draw = config.points_draw
	_current_season.points_loss = config.points_loss
	_current_season.promotion_slots = config.promotion_slots
	_current_season.relegation_slots = config.relegation_slots
	_current_season.season_state = SeasonState.PRE_SEASON
	_current_season.completed_match_count = 0
	_current_season.standings.clear()
	_current_season.schedule.clear()

	_build_standings_from_config(config)
	_build_schedule_from_config(config)
	_rebuild_indexes()
	_current_season.season_state = SeasonState.IN_PROGRESS
	_emit_event_if_bound("league_season_started", _build_season_started_payload())


## Applies one confirmed match result packet to the authoritative league standings.
func apply_confirmed_match_result(result_packet: Dictionary[String, Variant]) -> bool:
	if _current_season == null:
		return false
	if _current_season.season_state != SeasonState.IN_PROGRESS:
		return false
	if result_packet.is_empty():
		return false

	var match_id: String = String(result_packet.get("match_id", "")).strip_edges()
	if match_id.is_empty():
		return false
	if not _schedule_index_by_match_id.has(match_id):
		return false

	var scheduled_match: ScheduledMatch = _current_season.schedule[_schedule_index_by_match_id[match_id]]
	if scheduled_match.is_completed:
		return false

	var result_name: String = String(result_packet.get("result", "")).strip_edges()
	var score: Dictionary[String, Variant] = _to_string_variant_dictionary(result_packet.get("score", {}))
	if not _is_valid_result_packet_shape(result_name, score):
		return false

	var home_score: int = int(score.get("home", 0))
	var away_score: int = int(score.get("away", 0))
	scheduled_match.apply_result(home_score, away_score, result_name)
	_apply_match_to_standings(scheduled_match)
	_current_season.completed_match_count += 1
	_emit_event_if_bound("league_standings_updated", _build_standings_updated_payload())
	return true


## Finalizes the current season only after all scheduled matches are complete.
func finalize_on_time_season_ended(payload: Dictionary[String, Variant] = {}) -> bool:
	if _current_season == null:
		return false
	if _current_season.season_state != SeasonState.IN_PROGRESS:
		return false
	if _current_season.completed_match_count < _current_season.get_total_matches():
		return false

	_current_season.season_state = SeasonState.SETTLEMENT
	var _ignored_payload: Dictionary[String, Variant] = payload
	_current_season.season_state = SeasonState.COMPLETED
	_emit_event_if_bound("league_season_completed", _build_season_completed_payload())
	return true


## Returns a serializable shallow snapshot of league authority state.
func serialize() -> Dictionary[String, Variant]:
	if _current_season == null:
		return {
			"season_initialized": false,
			"standings": [],
			"schedule": [],
		}
	return {
		"season_initialized": true,
		"league_name": _current_season.league_name,
		"season_number": _current_season.season_number,
		"current_tier": _current_season.current_tier,
		"highest_tier": _current_season.highest_tier,
		"lowest_tier": _current_season.lowest_tier,
		"team_count": _current_season.team_count,
		"player_team_id": _current_season.player_team_id,
		"player_team_name": _current_season.player_team_name,
		"points_win": _current_season.points_win,
		"points_draw": _current_season.points_draw,
		"points_loss": _current_season.points_loss,
		"promotion_slots": _current_season.promotion_slots,
		"relegation_slots": _current_season.relegation_slots,
		"season_state": _get_season_state_name(_current_season.season_state),
		"completed_matches": _current_season.completed_match_count,
		"standings": _serialize_standings(),
		"schedule": _serialize_schedule(),
	}


## Restores league authority state from a serialized shallow snapshot.
func deserialize(data: Dictionary[String, Variant]) -> void:
	_clear_state(false)
	if not bool(data.get("season_initialized", false)):
		return

	_current_season = LeagueSeason.new()
	_current_season.league_name = String(data.get("league_name", ""))
	_current_season.season_number = int(data.get("season_number", 1))
	_current_season.current_tier = int(data.get("current_tier", 1))
	_current_season.highest_tier = int(data.get("highest_tier", 1))
	_current_season.lowest_tier = int(data.get("lowest_tier", 1))
	_current_season.team_count = int(data.get("team_count", 0))
	_current_season.player_team_id = int(data.get("player_team_id", 0))
	_current_season.player_team_name = String(data.get("player_team_name", "Player Team"))
	_current_season.points_win = int(data.get("points_win", 3))
	_current_season.points_draw = int(data.get("points_draw", 1))
	_current_season.points_loss = int(data.get("points_loss", 0))
	_current_season.promotion_slots = int(data.get("promotion_slots", 1))
	_current_season.relegation_slots = int(data.get("relegation_slots", 1))
	_current_season.season_state = _parse_season_state(String(data.get("season_state", "PRE_SEASON")))
	_current_season.completed_match_count = int(data.get("completed_matches", 0))
	_current_season.standings = _deserialize_standings(data.get("standings", []))
	_current_season.schedule = _deserialize_schedule(data.get("schedule", []))
	_rebuild_indexes()
	_current_season.completed_match_count = _count_completed_matches()


## Returns the player team's next scheduled match as a shallow record.
func get_next_match() -> Dictionary[String, Variant]:
	var next_match: ScheduledMatch = _find_next_player_match()
	if next_match == null:
		return {}
	var opponent_team_id: int = next_match.away_team_id if next_match.is_player_team_home else next_match.home_team_id
	var opponent_team_name: String = next_match.away_team_name if next_match.is_player_team_home else next_match.home_team_name
	return {
		"match_id": next_match.match_id,
		"round": next_match.round,
		"home_team_id": next_match.home_team_id,
		"home_team_name": next_match.home_team_name,
		"away_team_id": next_match.away_team_id,
		"away_team_name": next_match.away_team_name,
		"opponent_team_id": opponent_team_id,
		"opponent_team_name": opponent_team_name,
		"is_player_team_home": next_match.is_player_team_home,
		"is_completed": next_match.is_completed,
		"home_score": next_match.home_score,
		"away_score": next_match.away_score,
		"result": next_match.result,
	}


## Returns sorted standings as shallow records for downstream consumers.
func get_standings() -> Array[Dictionary]:
	var standings_records: Array[Dictionary] = []
	if _current_season == null:
		return standings_records
	var sorted_standings: Array[StandingsEntry] = _get_sorted_standings_entries()
	for standing_index: int in range(sorted_standings.size()):
		var rank: int = standing_index + 1
		var standing: StandingsEntry = sorted_standings[standing_index]
		standings_records.append({
			"rank": rank,
			"team_id": standing.team_id,
			"team_name": standing.team_name,
			"played": standing.played,
			"wins": standing.wins,
			"draws": standing.draws,
			"losses": standing.losses,
			"goals_for": standing.goals_for,
			"goals_against": standing.goals_against,
			"goal_difference": standing.goal_difference,
			"points": standing.points,
			"is_player_team": standing.team_id == _current_season.player_team_id,
			"outcome_tag": _resolve_outcome_tag(rank, _current_season),
		})
	return standings_records


## Returns the current league round for the player-facing season surface.
func get_current_round() -> int:
	if _current_season == null:
		return 0
	var next_match: ScheduledMatch = _find_next_player_match()
	if next_match != null:
		return next_match.round
	return _current_season.get_total_rounds()


## Returns a shallow season summary for read-only downstream consumption.
func get_season_summary() -> Dictionary[String, Variant]:
	if _current_season == null:
		return {
			"season_initialized": false,
		}
	var player_entry: StandingsEntry = _get_standings_entry(_current_season.player_team_id)
	var player_rank: int = _get_player_rank()
	var total_matches: int = _current_season.get_total_matches()
	var next_tier_intent: String = _resolve_next_tier_intent(_current_season)
	return {
		"season_initialized": true,
		"league_name": _current_season.league_name,
		"season_number": _current_season.season_number,
		"season_state": _get_season_state_name(_current_season.season_state),
		"current_tier": _current_season.current_tier,
		"highest_tier": _current_season.highest_tier,
		"lowest_tier": _current_season.lowest_tier,
		"team_count": _current_season.team_count,
		"promotion_slots": _current_season.promotion_slots,
		"relegation_slots": _current_season.relegation_slots,
		"current_round": get_current_round(),
		"total_rounds": _current_season.get_total_rounds(),
		"completed_matches": _current_season.completed_match_count,
		"remaining_matches": maxi(0, total_matches - _current_season.completed_match_count),
		"total_matches": total_matches,
		"player_team_id": _current_season.player_team_id,
		"player_team_name": _current_season.player_team_name,
		"player_rank": player_rank,
		"player_points": player_entry.points if player_entry != null else 0,
		"player_goals_for": player_entry.goals_for if player_entry != null else 0,
		"player_goals_against": player_entry.goals_against if player_entry != null else 0,
		"player_goal_difference": player_entry.goal_difference if player_entry != null else 0,
		"player_outcome_tag": _resolve_outcome_tag(player_rank, _current_season),
		"next_tier": _resolve_next_tier(_current_season),
		"next_tier_intent": next_tier_intent,
		"season_completed": _current_season.season_state == SeasonState.COMPLETED,
	}


func _build_standings_from_config(config: LeagueConfig) -> void:
	if _current_season == null:
		return
	var player_entry: StandingsEntry = StandingsEntry.new()
	player_entry.team_id = 0
	player_entry.team_name = config.player_team_name
	_current_season.standings.append(player_entry)
	for opponent_index: int in range(config.opponent_team_names.size()):
		var opponent_entry: StandingsEntry = StandingsEntry.new()
		opponent_entry.team_id = opponent_index + 1
		opponent_entry.team_name = config.opponent_team_names[opponent_index]
		_current_season.standings.append(opponent_entry)


func _build_schedule_from_config(config: LeagueConfig) -> void:
	if _current_season == null:
		return
	var rotating_team_ids: Array[int] = []
	for team_id: int in range(config.team_count):
		rotating_team_ids.append(team_id)
	var matches_per_round: int = int(config.team_count / 2)
	var rounds_per_leg: int = config.team_count - 1
	for round_index: int in range(rounds_per_leg):
		for match_index_in_round: int in range(matches_per_round):
			var left_team_id: int = rotating_team_ids[match_index_in_round]
			var right_team_id: int = rotating_team_ids[(config.team_count - 1) - match_index_in_round]
			var home_team_id: int = left_team_id
			var away_team_id: int = right_team_id
			if match_index_in_round == 0:
				if round_index % 2 == 0:
					home_team_id = right_team_id
					away_team_id = left_team_id
			elif match_index_in_round % 2 == 1:
				home_team_id = right_team_id
				away_team_id = left_team_id
			_current_season.schedule.append(_build_scheduled_match(round_index + 1, match_index_in_round + 1, home_team_id, away_team_id, config))
		_rotate_team_ids(rotating_team_ids)

	var first_leg_match_count: int = _current_season.schedule.size()
	for first_leg_index: int in range(first_leg_match_count):
		var first_leg_match: ScheduledMatch = _current_season.schedule[first_leg_index]
		var second_leg_round: int = first_leg_match.round + rounds_per_leg
		var second_leg_match_index: int = ((first_leg_index % matches_per_round) + 1)
		_current_season.schedule.append(
			_build_scheduled_match(
				second_leg_round,
				second_leg_match_index,
				first_leg_match.away_team_id,
				first_leg_match.home_team_id,
				config
			)
		)


func _build_scheduled_match(round_number: int, match_index_in_round: int, home_team_id: int, away_team_id: int, config: LeagueConfig) -> ScheduledMatch:
	var scheduled_match: ScheduledMatch = ScheduledMatch.new()
	scheduled_match.match_id = "league_r%02d_m%02d" % [round_number, match_index_in_round]
	scheduled_match.round = round_number
	scheduled_match.home_team_id = home_team_id
	scheduled_match.home_team_name = _resolve_team_name_from_config(home_team_id, config)
	scheduled_match.away_team_id = away_team_id
	scheduled_match.away_team_name = _resolve_team_name_from_config(away_team_id, config)
	scheduled_match.is_player_team_home = home_team_id == 0
	return scheduled_match


func _resolve_team_name_from_config(team_id: int, config: LeagueConfig) -> String:
	if team_id == 0:
		return config.player_team_name
	var opponent_index: int = team_id - 1
	if opponent_index >= 0 and opponent_index < config.opponent_team_names.size():
		return config.opponent_team_names[opponent_index]
	return "Opponent %s" % str(team_id)


func _rotate_team_ids(rotating_team_ids: Array[int]) -> void:
	if rotating_team_ids.size() <= 2:
		return
	var last_team_id: int = rotating_team_ids[rotating_team_ids.size() - 1]
	rotating_team_ids.remove_at(rotating_team_ids.size() - 1)
	rotating_team_ids.insert(1, last_team_id)


func _apply_match_to_standings(scheduled_match: ScheduledMatch) -> void:
	if _current_season == null:
		return
	var home_entry: StandingsEntry = _get_standings_entry(scheduled_match.home_team_id)
	var away_entry: StandingsEntry = _get_standings_entry(scheduled_match.away_team_id)
	if home_entry == null or away_entry == null:
		return
	var home_perspective_result: String = _resolve_home_perspective_result(scheduled_match.result)
	var away_perspective_result: String = _resolve_away_perspective_result(scheduled_match.result)
	home_entry.apply_result(
		scheduled_match.home_score,
		scheduled_match.away_score,
		home_perspective_result,
		_current_season.points_win,
		_current_season.points_draw,
		_current_season.points_loss
	)
	away_entry.apply_result(
		scheduled_match.away_score,
		scheduled_match.home_score,
		away_perspective_result,
		_current_season.points_win,
		_current_season.points_draw,
		_current_season.points_loss
	)


func _resolve_home_perspective_result(result_name: String) -> String:
	match result_name:
		"home_win":
			return "win"
		"away_win":
			return "loss"
		_:
			return "draw"


func _resolve_away_perspective_result(result_name: String) -> String:
	match result_name:
		"home_win":
			return "loss"
		"away_win":
			return "win"
		_:
			return "draw"


func _is_valid_result_packet_shape(result_name: String, score: Dictionary[String, Variant]) -> bool:
	if not score.has("home") or not score.has("away"):
		return false
	var home_score: int = int(score.get("home", -1))
	var away_score: int = int(score.get("away", -1))
	if home_score < 0 or away_score < 0:
		return false
	match result_name:
		"home_win":
			return home_score > away_score
		"away_win":
			return away_score > home_score
		"draw":
			return home_score == away_score
		_:
			return false


func _serialize_standings() -> Array[Dictionary]:
	var serialized_standings: Array[Dictionary] = []
	if _current_season == null:
		return serialized_standings
	for standing: StandingsEntry in _current_season.standings:
		serialized_standings.append(standing.to_state_record())
	serialized_standings.sort_custom(_compare_standings_records_by_team_id)
	return serialized_standings


func _serialize_schedule() -> Array[Dictionary]:
	var serialized_schedule: Array[Dictionary] = []
	if _current_season == null:
		return serialized_schedule
	for scheduled_match: ScheduledMatch in _current_season.schedule:
		serialized_schedule.append(scheduled_match.to_state_record())
	serialized_schedule.sort_custom(_compare_schedule_records)
	return serialized_schedule


func _deserialize_standings(values: Variant) -> Array[StandingsEntry]:
	var deserialized_standings: Array[StandingsEntry] = []
	if not (values is Array):
		return deserialized_standings
	for standing_variant: Variant in values:
		if not (standing_variant is Dictionary):
			continue
		var standing_record: Dictionary[String, Variant] = _to_string_variant_dictionary(standing_variant)
		var standing: StandingsEntry = StandingsEntry.new()
		standing.team_id = int(standing_record.get("team_id", 0))
		standing.team_name = String(standing_record.get("team_name", ""))
		standing.played = int(standing_record.get("played", 0))
		standing.wins = int(standing_record.get("wins", 0))
		standing.draws = int(standing_record.get("draws", 0))
		standing.losses = int(standing_record.get("losses", 0))
		standing.goals_for = int(standing_record.get("goals_for", 0))
		standing.goals_against = int(standing_record.get("goals_against", 0))
		standing.goal_difference = int(standing_record.get("goal_difference", standing.goals_for - standing.goals_against))
		standing.points = int(standing_record.get("points", 0))
		deserialized_standings.append(standing)
	deserialized_standings.sort_custom(_compare_standings_entries_by_team_id)
	return deserialized_standings


func _deserialize_schedule(values: Variant) -> Array[ScheduledMatch]:
	var deserialized_schedule: Array[ScheduledMatch] = []
	if not (values is Array):
		return deserialized_schedule
	for match_variant: Variant in values:
		if not (match_variant is Dictionary):
			continue
		var match_record: Dictionary[String, Variant] = _to_string_variant_dictionary(match_variant)
		var scheduled_match: ScheduledMatch = ScheduledMatch.new()
		scheduled_match.match_id = String(match_record.get("match_id", "")).strip_edges()
		scheduled_match.round = int(match_record.get("round", 1))
		scheduled_match.home_team_id = int(match_record.get("home_team_id", 0))
		scheduled_match.home_team_name = String(match_record.get("home_team_name", ""))
		scheduled_match.away_team_id = int(match_record.get("away_team_id", 0))
		scheduled_match.away_team_name = String(match_record.get("away_team_name", ""))
		scheduled_match.is_player_team_home = bool(match_record.get("is_player_team_home", false))
		scheduled_match.is_completed = bool(match_record.get("is_completed", false))
		scheduled_match.home_score = int(match_record.get("home_score", 0))
		scheduled_match.away_score = int(match_record.get("away_score", 0))
		scheduled_match.result = String(match_record.get("result", ""))
		deserialized_schedule.append(scheduled_match)
	deserialized_schedule.sort_custom(_compare_scheduled_matches)
	return deserialized_schedule


func _count_completed_matches() -> int:
	if _current_season == null:
		return 0
	var completed_matches: int = 0
	for scheduled_match: ScheduledMatch in _current_season.schedule:
		if scheduled_match.is_completed:
			completed_matches += 1
	return completed_matches


func _get_standings_entry(team_id: int) -> StandingsEntry:
	if _current_season == null:
		return null
	if not _standings_index_by_team_id.has(team_id):
		return null
	return _current_season.standings[_standings_index_by_team_id[team_id]]


func _get_sorted_standings_entries() -> Array[StandingsEntry]:
	var sorted_standings: Array[StandingsEntry] = []
	if _current_season == null:
		return sorted_standings
	sorted_standings.assign(_current_season.standings)
	sorted_standings.sort_custom(_compare_standings_entries)
	return sorted_standings


func _get_player_rank() -> int:
	if _current_season == null:
		return 0
	var sorted_standings: Array[StandingsEntry] = _get_sorted_standings_entries()
	for standing_index: int in range(sorted_standings.size()):
		if sorted_standings[standing_index].team_id == _current_season.player_team_id:
			return standing_index + 1
	return 0


func _resolve_next_tier_intent(season: LeagueSeason) -> String:
	var player_rank: int = _get_player_rank()
	if player_rank <= 0:
		return "stay"
	if season.promotion_slots > 0 and player_rank <= season.promotion_slots and season.current_tier > season.highest_tier:
		return "promote"
	if season.relegation_slots > 0 and player_rank > (season.team_count - season.relegation_slots) and season.current_tier < season.lowest_tier:
		return "relegate"
	return "stay"


func _resolve_next_tier(season: LeagueSeason) -> int:
	var next_tier_intent: String = _resolve_next_tier_intent(season)
	match next_tier_intent:
		"promote":
			return maxi(season.highest_tier, season.current_tier - 1)
		"relegate":
			return mini(season.lowest_tier, season.current_tier + 1)
		_:
			return season.current_tier


func _resolve_outcome_tag(rank: int, season: LeagueSeason) -> String:
	if rank <= 0:
		return "unknown"
	if rank == 1:
		return "champion"
	if season.promotion_slots > 0 and rank <= season.promotion_slots and season.current_tier > season.highest_tier:
		return "promoted"
	if season.relegation_slots > 0 and rank > (season.team_count - season.relegation_slots) and season.current_tier < season.lowest_tier:
		return "relegated"
	return "stayed"


func _find_next_player_match() -> ScheduledMatch:
	if _current_season == null:
		return null
	for scheduled_match: ScheduledMatch in _current_season.schedule:
		if scheduled_match.is_completed:
			continue
		if scheduled_match.home_team_id == _current_season.player_team_id or scheduled_match.away_team_id == _current_season.player_team_id:
			return scheduled_match
	return null


func _rebuild_indexes() -> void:
	_standings_index_by_team_id.clear()
	_schedule_index_by_match_id.clear()
	if _current_season == null:
		return
	for standing_index: int in range(_current_season.standings.size()):
		_standings_index_by_team_id[_current_season.standings[standing_index].team_id] = standing_index
	for schedule_index: int in range(_current_season.schedule.size()):
		_schedule_index_by_match_id[_current_season.schedule[schedule_index].match_id] = schedule_index


func _clear_state(clear_config: bool = true) -> void:
	if clear_config:
		_league_config = null
	_current_season = null
	_standings_index_by_team_id.clear()
	_schedule_index_by_match_id.clear()


func _build_season_started_payload() -> Dictionary[String, Variant]:
	if _current_season == null:
		return {}
	return {
		"league_name": _current_season.league_name,
		"season_number": _current_season.season_number,
		"season_state": _get_season_state_name(_current_season.season_state),
		"current_tier": _current_season.current_tier,
		"team_count": _current_season.team_count,
		"current_round": get_current_round(),
		"total_rounds": _current_season.get_total_rounds(),
	}


func _build_standings_updated_payload() -> Dictionary[String, Variant]:
	if _current_season == null:
		return {}
	return {
		"league_name": _current_season.league_name,
		"season_number": _current_season.season_number,
		"season_state": _get_season_state_name(_current_season.season_state),
		"current_round": get_current_round(),
		"completed_matches": _current_season.completed_match_count,
		"total_matches": _current_season.get_total_matches(),
		"standings": get_standings(),
	}


func _build_season_completed_payload() -> Dictionary[String, Variant]:
	var summary: Dictionary[String, Variant] = get_season_summary()
	summary["final_standings"] = get_standings()
	return summary


func _emit_event_if_bound(event_name: String, payload: Dictionary[String, Variant]) -> void:
	if _event_bus == null:
		return
	if not _event_bus.has_method("emit"):
		return
	_event_bus.call("emit", event_name, payload)


func _subscribe_to_event_bus() -> void:
	if _event_bus == null:
		return
	if not _event_bus.has_method("subscribe"):
		return
	_event_bus.call("subscribe", "match_completed", Callable(self, "_on_match_completed_event"))
	_event_bus.call("subscribe", "time_season_ended", Callable(self, "_on_time_season_ended_event"))


func _unsubscribe_from_event_bus() -> void:
	if _event_bus == null:
		return
	if not _event_bus.has_method("unsubscribe"):
		_event_bus = null
		return
	_event_bus.call("unsubscribe", "match_completed", Callable(self, "_on_match_completed_event"))
	_event_bus.call("unsubscribe", "time_season_ended", Callable(self, "_on_time_season_ended_event"))
	_event_bus = null


func _resolve_default_event_bus() -> Node:
	if not is_inside_tree():
		return null
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return null
	return get_node_or_null("/root/EventBus")


func _get_season_state_name(season_state: int) -> String:
	match season_state:
		SeasonState.PRE_SEASON:
			return "PRE_SEASON"
		SeasonState.IN_PROGRESS:
			return "IN_PROGRESS"
		SeasonState.SETTLEMENT:
			return "SETTLEMENT"
		SeasonState.COMPLETED:
			return "COMPLETED"
		_:
			return "PRE_SEASON"


func _parse_season_state(value: String) -> int:
	match value:
		"IN_PROGRESS":
			return SeasonState.IN_PROGRESS
		"SETTLEMENT":
			return SeasonState.SETTLEMENT
		"COMPLETED":
			return SeasonState.COMPLETED
		_:
			return SeasonState.PRE_SEASON


func _compare_standings_entries(left: StandingsEntry, right: StandingsEntry) -> bool:
	if left.points != right.points:
		return left.points > right.points
	if left.goal_difference != right.goal_difference:
		return left.goal_difference > right.goal_difference
	if left.goals_for != right.goals_for:
		return left.goals_for > right.goals_for
	return left.team_id < right.team_id


func _compare_standings_entries_by_team_id(left: StandingsEntry, right: StandingsEntry) -> bool:
	return left.team_id < right.team_id


func _compare_standings_records_by_team_id(left: Dictionary, right: Dictionary) -> bool:
	return int(left.get("team_id", 0)) < int(right.get("team_id", 0))


func _compare_scheduled_matches(left: ScheduledMatch, right: ScheduledMatch) -> bool:
	if left.round != right.round:
		return left.round < right.round
	return left.match_id < right.match_id


func _compare_schedule_records(left: Dictionary, right: Dictionary) -> bool:
	var left_round: int = int(left.get("round", 0))
	var right_round: int = int(right.get("round", 0))
	if left_round != right_round:
		return left_round < right_round
	return String(left.get("match_id", "")) < String(right.get("match_id", ""))


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	var source: Dictionary = value as Dictionary
	for key_variant: Variant in source.keys():
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary


func _on_match_completed_event(_event_name: String, payload: Dictionary) -> void:
	apply_confirmed_match_result(_to_string_variant_dictionary(payload))


func _on_time_season_ended_event(_event_name: String, payload: Dictionary) -> void:
	finalize_on_time_season_ended(_to_string_variant_dictionary(payload))
