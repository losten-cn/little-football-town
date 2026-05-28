class_name PlayerRoster
extends Resource

const PlayerScript: Script = preload("res://src/core/player.gd")

var players: Array[Player] = []
var _next_id: int = 1


## Adds a player to the roster and assigns a new monotonically increasing id.
func add_player(player: Player) -> int:
	player.id = _next_id
	_next_id += 1
	players.append(player)
	return player.id


## Returns one player by id, or null when no player exists.
func get_player(player_id: int) -> Player:
	for player: Player in players:
		if player.id == player_id:
			return player
	return null


## Serializes the roster into authoritative save data only.
func serialize() -> Dictionary[String, Variant]:
	var serialized_players: Array[Dictionary] = []
	for player: Player in players:
		serialized_players.append(_serialize_player(player))
	return {
		"next_id": _next_id,
		"players": serialized_players,
	}


## Restores roster state from serialized authoritative save data.
func deserialize(data: Dictionary[String, Variant]) -> void:
	players.clear()
	_next_id = int(data.get("next_id", 1))
	var max_player_id: int = 0
	for entry_variant: Variant in data.get("players", []):
		if not (entry_variant is Dictionary):
			continue
		var player: Player = _deserialize_player(_to_typed_dictionary(entry_variant))
		players.append(player)
		max_player_id = maxi(max_player_id, player.id)
	_next_id = maxi(_next_id, max_player_id + 1)


func _serialize_player(player: Player) -> Dictionary[String, Variant]:
	return {
		"id": player.id,
		"name": player.name,
		"age": player.age,
		"position": player.position,
		"tier": player.tier,
		"special_trait_source": player.special_trait_source,
		"attributes": player.attributes.to_dict(),
		"training_efficiency": player.training_efficiency,
		"condition_multiplier": player.condition_multiplier,
		"morale_multiplier": player.morale_multiplier,
		"training_history": player.training_history.duplicate(true),
		"milestones": player.milestones.duplicate(),
		"review_flags": player.review_flags.duplicate(),
		"total_training_sessions": player.total_training_sessions,
		"last_age_advanced_season": player.last_age_advanced_season,
	}


func _deserialize_player(data: Dictionary[String, Variant]) -> Player:
	var player: Player = PlayerScript.new()
	player.id = int(data.get("id", 0))
	player.name = String(data.get("name", ""))
	player.age = int(data.get("age", 18))
	player.position = String(data.get("position", "MF"))
	player.tier = String(data.get("tier", "普通"))
	player.special_trait_source = String(data.get("special_trait_source", ""))
	player.attributes = Player.Attributes.from_dict(_to_typed_dictionary(data.get("attributes", {})))
	player.training_efficiency = float(data.get("training_efficiency", 1.0))
	player.condition_multiplier = float(data.get("condition_multiplier", 1.0))
	player.morale_multiplier = float(data.get("morale_multiplier", 1.0))
	player.training_history = _to_typed_history_array(data.get("training_history", []))
	player.milestones = _to_string_array(data.get("milestones", []))
	player.review_flags = _to_string_array(data.get("review_flags", []))
	player.total_training_sessions = int(data.get("total_training_sessions", 0))
	player.last_age_advanced_season = int(data.get("last_age_advanced_season", 0))
	return player


func _to_typed_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	for key_variant: Variant in value:
		typed_dictionary[String(key_variant)] = value[key_variant]
	return typed_dictionary


func _to_typed_history_array(value: Variant) -> Array[Dictionary]:
	var history: Array[Dictionary] = []
	if not (value is Array):
		return history
	for entry_variant: Variant in value:
		if entry_variant is Dictionary:
			history.append(_to_typed_dictionary(entry_variant))
	return history


func _to_string_array(value: Variant) -> Array[String]:
	var strings: Array[String] = []
	if not (value is Array):
		return strings
	for entry_variant: Variant in value:
		strings.append(String(entry_variant))
	return strings
