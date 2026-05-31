extends Node

const SaveManagerScript: Script = preload("res://src/autoload/save_manager.gd")
const PlayerScript: Script = preload("res://src/core/player.gd")
const PlayerDevelopmentScript: Script = preload("res://src/core/player_development.gd")
const PlayerRosterScript: Script = preload("res://src/core/player_roster.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_player_roster_serializes_authoritative_player_fields_only()
	test_player_roster_serializes_empty_history_and_milestones_as_empty_collections()
	test_player_development_registers_and_emits_player_snapshot_for_save_manager()
	test_player_development_deserialize_restores_growth_state_without_duplication()
	test_player_development_deserialize_matches_players_by_id_when_snapshot_order_changes()
	test_player_development_deserialize_ignores_legacy_derived_fields()
	if _failures.is_empty():
		print("PLAYER_DATA_SERIALIZATION_BOUNDARY_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("PLAYER_DATA_SERIALIZATION_BOUNDARY_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_player_roster_serializes_authoritative_player_fields_only() -> void:
	# Arrange
	var roster: PlayerRoster = PlayerRosterScript.new()
	var player: Player = _build_player("captain")
	roster.add_player(player)

	# Act
	var serialized_roster: Dictionary[String, Variant] = roster.serialize()
	var serialized_players: Array = serialized_roster["players"]
	var serialized_player: Dictionary[String, Variant] = _to_typed_dictionary(serialized_players[0])
	var serialized_attributes: Dictionary[String, Variant] = _to_typed_dictionary(serialized_player["attributes"])
	var spd_triplet: Dictionary[String, Variant] = _to_typed_dictionary(serialized_attributes["SPD"])
	var expected_player_keys: Array[String] = [
		"id", "name", "age", "position", "tier", "special_trait_source", "attributes",
		"training_efficiency", "condition_multiplier", "morale_multiplier", "training_history",
		"milestones", "review_flags", "total_training_sessions", "last_age_advanced_season",
	]
	var expected_attribute_keys: Array[String] = ["SPD", "PWR", "TEC", "INT", "STA"]
	var expected_triplet_keys: Array[String] = ["current", "potential"]

	# Assert
	_expect(serialized_player.has("id"), "serialized player should include id")
	_expect(serialized_player.has("name"), "serialized player should include name")
	_expect(serialized_player.has("age"), "serialized player should include age")
	_expect(serialized_player.has("position"), "serialized player should include position")
	_expect(serialized_player.has("tier"), "serialized player should include tier")
	_expect(serialized_player.has("attributes"), "serialized player should include attributes")
	_expect(serialized_player.has("training_efficiency"), "serialized player should include training_efficiency")
	_expect(serialized_player.has("condition_multiplier"), "serialized player should include condition_multiplier")
	_expect(serialized_player.has("morale_multiplier"), "serialized player should include morale_multiplier")
	_expect(serialized_player.has("training_history"), "serialized player should include training_history")
	_expect(serialized_player.has("milestones"), "serialized player should include milestones")
	_expect(serialized_player.has("total_training_sessions"), "serialized player should include total_training_sessions")
	_expect(not serialized_player.has("effective"), "serialized player should not include derived effective fields")
	_expect(not serialized_player.has("positional_overall_rating"), "serialized player should not include positional_overall_rating")
	_expect(spd_triplet.has("current"), "serialized SPD should include current")
	_expect(spd_triplet.has("potential"), "serialized SPD should include potential")
	_expect(not spd_triplet.has("effective"), "serialized SPD should not include effective")
	_expect(_same_string_keys(serialized_player, expected_player_keys), "serialized player should contain only the authoritative player keys")
	_expect(_same_string_keys(serialized_attributes, expected_attribute_keys), "serialized attributes should contain all five authoritative attributes only")
	_expect(_same_string_keys(spd_triplet, expected_triplet_keys), "serialized SPD should contain current and potential only")
	_expect(_all_authoritative_attributes_have_current_and_potential_only(serialized_attributes), "all serialized attributes should contain current and potential only")


func test_player_roster_serializes_empty_history_and_milestones_as_empty_collections() -> void:
	# Arrange
	var roster: PlayerRoster = PlayerRosterScript.new()
	var player: Player = _build_player("empty")
	player.training_history.clear()
	player.milestones.clear()
	roster.add_player(player)

	# Act
	var serialized_roster: Dictionary[String, Variant] = roster.serialize()
	var serialized_players: Array = serialized_roster.get("players", [])
	var serialized_player: Dictionary[String, Variant] = _to_typed_dictionary(serialized_players[0]) if not serialized_players.is_empty() else {}

	# Assert
	_expect(serialized_player.has("training_history"), "serialized player should keep training_history when empty")
	_expect(serialized_player.has("milestones"), "serialized player should keep milestones when empty")
	_expect((serialized_player.get("training_history", []) as Array).is_empty(), "serialized empty training_history should remain empty")
	_expect((serialized_player.get("milestones", []) as Array).is_empty(), "serialized empty milestones should remain empty")


func test_player_development_registers_and_emits_player_snapshot_for_save_manager() -> void:
	# Arrange
	var save_manager: Variant = SaveManagerScript.new()
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var roster: PlayerRoster = PlayerRosterScript.new()
	var player: Player = _build_player("prospect")
	roster.add_player(player)
	player_development.set_roster_for_testing(roster)
	player_development.save_manager = save_manager
	player_development._ready()

	# Act
	var has_registration: bool = save_manager.has_registered_system("player")
	var serialized_player_state: Dictionary[String, Variant] = save_manager.serialize_registered_system("player")
	var players_array: Array = serialized_player_state.get("players", [])
	var serialized_player: Dictionary[String, Variant] = _to_typed_dictionary(players_array[0]) if not players_array.is_empty() else {}

	# Assert
	_expect(has_registration, "PlayerDevelopment should register player save contracts with SaveManager")
	_expect(int(serialized_player_state.get("next_id", 0)) == 2, "serialized player state should expose next_id")
	_expect(players_array.size() == 1, "serialized player state should include one player")
	_expect(String(serialized_player.get("name", "")) == "Player prospect", "serialized player snapshot should preserve player identity")


func test_player_development_deserialize_restores_growth_state_without_duplication() -> void:
	# Arrange
	var save_manager: Variant = SaveManagerScript.new()
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	var source_roster: PlayerRoster = PlayerRosterScript.new()
	var player: Player = _build_player("veteran")
	player.attributes.spd.current = 44
	player.attributes.spd.potential = 81
	player.training_efficiency = 1.27
	player.age = 23
	player.training_history.append({
		"session_id": "session_1",
		"gain": 2,
	})
	player.milestones.append("SPD_40")
	player.total_training_sessions = 7
	source_roster.add_player(player)
	player_development.set_roster_for_testing(source_roster)
	player_development.save_manager = save_manager
	player_development._ready()
	_register_required_snapshot_systems(save_manager)
	var ui_state: Dictionary[String, Variant] = {
		"ui_screen_id": "player_roster",
		"ui_stack_depth": 1,
	}
	var slot_metadata: Dictionary[String, Variant] = {
		"town_name": "Player Town",
	}
	var commit_result: Dictionary[String, Variant] = save_manager.commit_registered_snapshot(
		"slot_1",
		ui_state,
		slot_metadata,
		321.5,
		5678
	)
	var slot_path: String = save_manager.resolve_slot_path("slot_1")
	var saved_snapshot: Resource = ResourceLoader.load(slot_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var snapshot_player_state: Dictionary[String, Variant] = _to_typed_dictionary(saved_snapshot.player_state if saved_snapshot != null else {})

	# Act
	player_development.set_roster_for_testing(PlayerRosterScript.new())
	player_development._deserialize(snapshot_player_state)
	player_development._deserialize(snapshot_player_state)
	var restored_player_state: Dictionary[String, Variant] = player_development._serialize()
	var restored_players: Array = restored_player_state.get("players", [])
	var restored_player: Dictionary[String, Variant] = _to_typed_dictionary(restored_players[0]) if not restored_players.is_empty() else {}

	# Assert
	_expect(commit_result["success"] as bool, "SaveManager commit should succeed for player save boundary roundtrip")
	_expect(saved_snapshot != null, "SaveManager should write a snapshot resource for the player roundtrip")
	_expect(not restored_player.is_empty(), "deserialized roster should restore the player")
	_expect(int(restored_player.get("age", 0)) == 23, "deserialized roster should preserve age")
	_expect(is_equal_approx(float(restored_player.get("training_efficiency", 0.0)), 1.27), "deserialized roster should preserve training_efficiency")
	var restored_attributes: Dictionary[String, Variant] = _to_typed_dictionary(restored_player.get("attributes", {}))
	var restored_spd: Dictionary[String, Variant] = _to_typed_dictionary(restored_attributes.get("SPD", {}))
	_expect(int(restored_spd.get("current", 0)) == 44, "deserialized roster should preserve current attributes")
	_expect(int(restored_spd.get("potential", 0)) == 81, "deserialized roster should preserve potential attributes")
	var restored_history: Array = restored_player.get("training_history", [])
	var restored_milestones: Array = restored_player.get("milestones", [])
	_expect(restored_history.size() == 2, "deserializing the same snapshot twice should not duplicate training history")
	_expect(restored_milestones.size() == 2, "deserializing the same snapshot twice should not duplicate milestones")
	_expect(int(restored_player.get("total_training_sessions", 0)) == 7, "deserialized roster should preserve total training sessions")


func test_player_development_deserialize_matches_players_by_id_when_snapshot_order_changes() -> void:
	# Arrange
	var roster: PlayerRoster = PlayerRosterScript.new()
	var first_player: Player = _build_player("alpha")
	first_player.attributes.spd.current = 48
	first_player.training_history = [{"session_id": "alpha_history", "gain": 3}]
	first_player.milestones = ["ALPHA"]
	roster.add_player(first_player)
	var second_player: Player = _build_player("beta")
	second_player.attributes.spd.current = 52
	second_player.training_history = [{"session_id": "beta_history", "gain": 4}]
	second_player.milestones = ["BETA"]
	roster.add_player(second_player)
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	player_development.set_roster_for_testing(roster)
	var snapshot_player_state: Dictionary[String, Variant] = _to_typed_dictionary(player_development._serialize())
	var snapshot_players: Array = snapshot_player_state.get("players", [])
	if snapshot_players.size() >= 2:
		var swapped_players: Array = [snapshot_players[1], snapshot_players[0]]
		snapshot_player_state["players"] = swapped_players

	# Act
	player_development.set_roster_for_testing(PlayerRosterScript.new())
	player_development._deserialize(snapshot_player_state)
	var restored_alpha: Player = player_development._roster.get_player(1)
	var restored_beta: Player = player_development._roster.get_player(2)

	# Assert
	_expect(restored_alpha != null, "deserialized roster should restore first player by id")
	_expect(restored_beta != null, "deserialized roster should restore second player by id")
	_expect(restored_alpha != null and restored_alpha.name == "Player alpha", "deserialized first player should match id 1 identity")
	_expect(restored_beta != null and restored_beta.name == "Player beta", "deserialized second player should match id 2 identity")
	_expect(restored_alpha != null and restored_alpha.attributes.spd.current == 48, "deserialized first player should keep its own growth state")
	_expect(restored_beta != null and restored_beta.attributes.spd.current == 52, "deserialized second player should keep its own growth state")
	_expect(restored_alpha != null and restored_alpha.training_history.size() == 1 and String((restored_alpha.training_history[0] as Dictionary).get("session_id", "")) == "alpha_history", "deserialized first player should keep its own training history")
	_expect(restored_beta != null and restored_beta.training_history.size() == 1 and String((restored_beta.training_history[0] as Dictionary).get("session_id", "")) == "beta_history", "deserialized second player should keep its own training history")
	_expect(restored_alpha != null and restored_alpha.milestones.size() == 1 and restored_alpha.milestones[0] == "ALPHA", "deserialized first player should keep its own milestones")
	_expect(restored_beta != null and restored_beta.milestones.size() == 1 and restored_beta.milestones[0] == "BETA", "deserialized second player should keep its own milestones")


func test_player_development_deserialize_ignores_legacy_derived_fields() -> void:
	# Arrange
	var player_development: PlayerDevelopment = PlayerDevelopmentScript.new()
	player_development.set_roster_for_testing(PlayerRosterScript.new())
	var snapshot_player_state: Dictionary[String, Variant] = {
		"next_id": 2,
		"players": [
			{
				"id": 1,
				"name": "Legacy Player",
				"age": 21,
				"position": "MF",
				"tier": "明星",
				"special_trait_source": "legacy",
				"attributes": {
					"SPD": {"current": 45, "potential": 82, "effective": 57},
					"PWR": {"current": 39, "potential": 76, "effective": 50},
					"TEC": {"current": 44, "potential": 84, "effective": 58},
					"INT": {"current": 47, "potential": 88, "effective": 61},
					"STA": {"current": 40, "potential": 79, "effective": 52},
				},
				"training_efficiency": 1.2,
				"condition_multiplier": 0.95,
				"morale_multiplier": 1.05,
				"training_history": [{"session_id": "legacy_session", "gain": 2}],
				"milestones": ["SIGNED"],
				"review_flags": ["legacy_flag"],
				"total_training_sessions": 3,
				"last_age_advanced_season": 1,
				"effective": 999,
				"positional_overall_rating": 123,
			},
		],
	}

	# Act
	player_development._deserialize(snapshot_player_state)
	var restored_player_state: Dictionary[String, Variant] = player_development._serialize()
	var restored_players: Array = restored_player_state.get("players", [])
	var restored_player: Dictionary[String, Variant] = _to_typed_dictionary(restored_players[0]) if not restored_players.is_empty() else {}
	var restored_attributes: Dictionary[String, Variant] = _to_typed_dictionary(restored_player.get("attributes", {}))
	var restored_spd: Dictionary[String, Variant] = _to_typed_dictionary(restored_attributes.get("SPD", {}))

	# Assert
	_expect(not restored_player.has("effective"), "deserialized player snapshot should ignore legacy player effective field")
	_expect(not restored_player.has("positional_overall_rating"), "deserialized player snapshot should ignore legacy positional rating field")
	_expect(not restored_spd.has("effective"), "deserialized player snapshot should ignore legacy attribute effective field")
	_expect(int(restored_spd.get("current", 0)) == 45, "deserialized player should preserve authoritative current value from legacy snapshot")
	_expect(int(restored_spd.get("potential", 0)) == 82, "deserialized player should preserve authoritative potential value from legacy snapshot")
	_expect(String(restored_player.get("name", "")) == "Legacy Player", "deserialized player should preserve legacy identity fields")


func _register_required_snapshot_systems(save_manager: Variant) -> void:
	save_manager.register_system("time", _serialize_stub.bind({
		"current_state": "Planning",
		"timeline_position": 3,
		"season_number": 1,
		"current_stage": 1,
		"current_stage_progress": 0,
		"stage_progress_target": 3,
		"season_progress": {
			"completed_units": 2,
			"total_units": 10,
		},
		"available_action_windows": {
			"current_phase_time_budget": 12,
			"reserved_time": 0,
			"consumed_time": 0,
			"standard_window_size": 1,
		},
		"scheduled_match_position": 8,
		"next_key_node_position": 8,
		"schedule_available": true,
		"schedule_loading": false,
		"schedule_missing": false,
		"match_center_available": true,
	}), _deserialize_stub)
	save_manager.register_system("town", _serialize_stub.bind({"facility_count": 2}), _deserialize_stub)
	save_manager.register_system("league", _serialize_stub.bind({"rank": 5}), _deserialize_stub)
	save_manager.register_system("economy", _serialize_stub.bind({
		"funds": 1200.0,
		"action_points": 12.0,
		"research_points": 0.0,
		"next_tx_id": 1,
		"transactions": [],
	}), _deserialize_stub)
	save_manager.register_system("match", _serialize_stub.bind({
		"state": 0,
		"state_name": "idle",
		"pending_match_context": {},
		"result_packet": {},
		"formal_state_history": [],
		"confirmed_results_by_match_id": {},
		"scheduled_position": 5,
		"in_progress": false,
	}), _deserialize_stub)


func _build_player(label: String) -> Player:
	var player: Player = PlayerScript.new()
	player.name = "Player %s" % label
	player.age = 19
	player.position = "MF"
	player.tier = "明星"
	player.training_efficiency = 1.15
	player.condition_multiplier = 0.93
	player.morale_multiplier = 1.08
	player.attributes.spd.current = 36
	player.attributes.spd.potential = 82
	player.attributes.pwr.current = 33
	player.attributes.pwr.potential = 76
	player.attributes.tec.current = 39
	player.attributes.tec.potential = 84
	player.attributes.intelligence.current = 41
	player.attributes.intelligence.potential = 88
	player.attributes.sta.current = 35
	player.attributes.sta.potential = 79
	player.training_history.append({
		"session_id": "bootstrap_%s" % label,
		"gain": 1,
	})
	player.milestones.append("SIGNED")
	player.total_training_sessions = 1
	return player


func _serialize_stub(payload: Variant) -> Dictionary[String, Variant]:
	return _to_typed_dictionary(payload).duplicate(true)


func _deserialize_stub(_payload: Dictionary) -> void:
	pass


func _same_string_keys(source: Dictionary[String, Variant], expected_keys: Array[String]) -> bool:
	var actual_keys: Array[String] = []
	for key: String in source.keys():
		actual_keys.append(key)
	actual_keys.sort()
	var sorted_expected_keys: Array[String] = expected_keys.duplicate()
	sorted_expected_keys.sort()
	return actual_keys == sorted_expected_keys


func _all_authoritative_attributes_have_current_and_potential_only(attributes: Dictionary[String, Variant]) -> bool:
	for attribute_name: String in ["SPD", "PWR", "TEC", "INT", "STA"]:
		var triplet: Dictionary[String, Variant] = _to_typed_dictionary(attributes.get(attribute_name, {}))
		if not _same_string_keys(triplet, ["current", "potential"]):
			return false
	return true


func _to_typed_dictionary(source: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (source is Dictionary):
		return typed_dictionary
	for key_variant: Variant in source:
		typed_dictionary[String(key_variant)] = _duplicate_variant_deep(source[key_variant])
	return typed_dictionary


func _duplicate_variant_deep(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
