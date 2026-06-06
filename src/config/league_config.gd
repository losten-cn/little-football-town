class_name LeagueConfig
extends Resource
## Data-driven league structure tuning resource validated at startup.

const MIN_TEAM_COUNT: int = 8
const MAX_TEAM_COUNT: int = 12
const MIN_SUPPORTED_TIER: int = 1

@export var league_name: String = "Town League"
@export var league_tier: int = 1
@export var highest_tier: int = 1
@export var lowest_tier: int = 1
@export var team_count: int = 8
@export var player_team_name: String = "Player Team"
@export var opponent_team_names: Array[String] = [
	"Opponent 1",
	"Opponent 2",
	"Opponent 3",
	"Opponent 4",
	"Opponent 5",
	"Opponent 6",
	"Opponent 7",
]
@export var double_round_robin: bool = true
@export var points_win: int = 3
@export var points_draw: int = 1
@export var points_loss: int = 0
@export var promotion_slots: int = 1
@export var relegation_slots: int = 1


## Returns whether this resource satisfies the minimum league-loop contract.
func validate() -> Dictionary[String, Variant]:
	var errors: Array[String] = []
	_add_integer_range_error(errors, "highest_tier", highest_tier, MIN_SUPPORTED_TIER, 99)
	_add_integer_range_error(errors, "lowest_tier", lowest_tier, highest_tier, 99)
	_add_integer_range_error(errors, "league_tier", league_tier, highest_tier, lowest_tier)
	_add_integer_range_error(errors, "team_count", team_count, MIN_TEAM_COUNT, MAX_TEAM_COUNT)
	if team_count % 2 != 0:
		errors.append("team_count %s must be even for circle-method scheduling" % str(team_count))
	if not double_round_robin:
		errors.append("double_round_robin must remain true for Story 001")
	if String(league_name).strip_edges().is_empty():
		errors.append("league_name must not be empty")
	if String(player_team_name).strip_edges().is_empty():
		errors.append("player_team_name must not be empty")
	_add_points_rule_errors(errors)
	_add_slot_errors(errors)
	_add_team_name_errors(errors)
	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


## Returns the scheduled matches each team must play in one season.
func get_matches_per_team() -> int:
	if team_count < 2:
		return 0
	return 2 * (team_count - 1)


## Returns the total round count for one double round-robin season.
func get_total_rounds() -> int:
	if team_count < 2:
		return 0
	return 2 * (team_count - 1)


## Returns the total scheduled match count for the league season.
func get_total_matches() -> int:
	return int((team_count * get_matches_per_team()) / 2.0)


func _add_points_rule_errors(errors: Array[String]) -> void:
	if points_win < 0:
		errors.append("points_win %s below minimum 0" % str(points_win))
	if points_draw < 0:
		errors.append("points_draw %s below minimum 0" % str(points_draw))
	if points_loss < 0:
		errors.append("points_loss %s below minimum 0" % str(points_loss))
	if points_win <= points_draw:
		errors.append("points_win must be greater than points_draw")
	if points_draw < points_loss:
		errors.append("points_draw must be greater than or equal to points_loss")


func _add_slot_errors(errors: Array[String]) -> void:
	_add_integer_range_error(errors, "promotion_slots", promotion_slots, 0, maxi(0, team_count - 1))
	_add_integer_range_error(errors, "relegation_slots", relegation_slots, 0, maxi(0, team_count - 1))
	if promotion_slots + relegation_slots >= team_count:
		errors.append("promotion_slots + relegation_slots must be less than team_count")


func _add_team_name_errors(errors: Array[String]) -> void:
	var expected_opponent_count: int = maxi(0, team_count - 1)
	if opponent_team_names.size() != expected_opponent_count:
		errors.append(
			"opponent_team_names size %s does not match team_count - 1 (%s)" % [
				str(opponent_team_names.size()),
				str(expected_opponent_count),
			]
		)
	var normalized_player_name: String = String(player_team_name).strip_edges()
	var seen_names: Dictionary[String, bool] = {}
	if not normalized_player_name.is_empty():
		seen_names[normalized_player_name] = true
	for opponent_index: int in range(opponent_team_names.size()):
		var opponent_name: String = opponent_team_names[opponent_index].strip_edges()
		if opponent_name.is_empty():
			errors.append("opponent_team_names[%s] must not be empty" % str(opponent_index))
			continue
		if seen_names.has(opponent_name):
			errors.append("duplicate team name detected: %s" % opponent_name)
			continue
		seen_names[opponent_name] = true


func _add_integer_range_error(errors: Array[String], field_name: String, value: int, minimum: int, maximum: int) -> void:
	if value < minimum or value > maximum:
		errors.append("%s %s outside [%s, %s]" % [field_name, str(value), str(minimum), str(maximum)])
