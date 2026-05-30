# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Can a player complete one clear training-to-match-to-feedback loop in under 5 minutes without guidance?
# Date: 2026-05-30

extends RefCounted

const PlayerScript: Script = preload("res://src/core/player.gd")
const PlayerRosterScript: Script = preload("res://src/core/player_roster.gd")
const BalanceConfigResource: Resource = preload("res://config/balance_config.tres")
const EconomyConfigResource: Resource = preload("res://config/economy_config.tres")
const MatchConfigResource: Resource = preload("res://config/match_config.tres")


static func create_roster() -> Resource:
	var roster: Resource = PlayerRosterScript.new()
	roster.add_player(_make_player("林然", "FW", "明星", 82, 70, 76, 68, 75, 92, 1.18))
	roster.add_player(_make_player("周牧", "MF", "优秀", 72, 64, 78, 77, 73, 85, 1.05))
	roster.add_player(_make_player("高岳", "DF", "优秀", 66, 79, 61, 70, 80, 84, 1.02))
	roster.add_player(_make_player("许渡", "GK", "普通", 52, 70, 55, 72, 69, 78, 0.96))
	roster.add_player(_make_player("宋澄", "FW", "普通", 75, 62, 68, 64, 70, 76, 0.92))
	roster.add_player(_make_player("顾野", "DF", "普通", 61, 73, 58, 66, 74, 74, 0.90))
	roster.add_player(_make_player("何煦", "MF", "优秀", 69, 63, 75, 74, 72, 83, 1.04))
	roster.add_player(_make_player("白川", "DF", "普通", 58, 76, 57, 65, 78, 75, 0.94))
	roster.add_player(_make_player("简秋", "MF", "普通", 67, 60, 70, 71, 69, 77, 0.95))
	roster.add_player(_make_player("叶舟", "FW", "优秀", 78, 66, 73, 67, 71, 86, 1.08))
	roster.add_player(_make_player("温峤", "DF", "普通", 60, 74, 56, 68, 76, 76, 0.93))
	return roster


static func create_training_projects() -> Array:
	return [
		{
			"project_id": "finishing_focus",
			"label": "前锋终结训练",
			"primary_attribute": "TEC",
			"raw_growth_input": 3.0,
			"funds_cost": 30,
			"action_points_cost": 4,
			"time_cost": 1.0,
			"facility_training_multiplier": 1.1,
			"focus_match_multiplier": 1.15,
		},
		{
			"project_id": "team_shape",
			"label": "全队站位演练",
			"primary_attribute": "INT",
			"raw_growth_input": 2.4,
			"funds_cost": 22,
			"action_points_cost": 3,
			"time_cost": 1.0,
			"facility_training_multiplier": 1.0,
			"focus_match_multiplier": 1.05,
		},
	]


static func create_initial_time_snapshot() -> Dictionary:
	return {
		"season_label": "Season 1",
		"current_stage_display": "训练周",
		"current_date_display": "Week 1 / Day 1",
		"timeline_position": 0,
		"season_number": 1,
		"current_stage": 1,
		"current_stage_progress": 0,
		"stage_progress_target": 1,
		"scheduled_match_position": 2,
		"next_key_node_position": 2,
		"next_key_node_display": "周末主场比赛",
		"next_key_node": {
			"type": "match",
			"state": "Match Trigger",
			"position": 2,
			"display_name": "周末主场比赛",
		},
		"schedule_available": true,
		"schedule_loading": false,
		"schedule_missing": false,
		"match_center_available": true,
		"opponent_name": "港湾青年队",
		"next_match_display": "2 时间单位后 vs 港湾青年队",
		"season_progress": {
			"completed_units": 0,
			"total_units": 6,
			"progress_ratio": 0.0,
		},
		"available_action_windows": {
			"count": 2,
			"current_phase_time_budget": 2,
			"reserved_time": 0,
			"consumed_time": 0,
			"standard_window_size": 1,
		},
		"match": {
			"scheduled_position": 2,
			"center_available": true,
			"in_progress": false,
			"opponent_name": "港湾青年队",
			"next_match_display": "2 时间单位后 vs 港湾青年队",
			"home_team_id": 1,
			"away_team_id": 2,
		},
	}


static func create_match_context(roster: Resource, lineup_slots: Array) -> Dictionary[String, Variant]:
	var player_appearances: Array = []
	for lineup_slot_variant: Variant in lineup_slots:
		var lineup_slot: Dictionary = lineup_slot_variant
		var player: Variant = lineup_slot.get("player", null)
		if player == null:
			continue
		player_appearances.append({
			"player_id": player.id,
			"minutes": 90,
			"performance_score": _resolve_performance_score(player),
			"team_side": "home",
		})
	return {
		"match_id": "slice-match-001",
		"result": "home_win",
		"home_strength": 74.0,
		"away_strength": 66.0,
		"home_advantage_mod": 0.03,
		"condition_mod": 0.01,
		"event_mod": 0.02,
		"event_seed": 77,
		"match_seed": 77,
		"is_reversal": false,
		"has_out_of_position_player": false,
		"player_appearances": player_appearances,
	}


static func create_post_match_settlement_context() -> Dictionary[String, Variant]:
	return {
		"league_tier": 1,
		"stadium_revenue_multiplier": 1.0,
		"tactical_rating_ratio": 0.95,
	}


static func create_balance_config() -> Resource:
	return BalanceConfigResource.duplicate(true)


static func create_economy_config() -> Resource:
	return EconomyConfigResource.duplicate(true)


static func create_match_config() -> Resource:
	return MatchConfigResource.duplicate(true)


static func _make_player(name: String, position: String, tier: String, spd: int, pwr: int, tec: int, intelligence: int, sta: int, potential_cap: int, training_efficiency: float) -> Variant:
	var player: Variant = PlayerScript.new()
	player.name = name
	player.position = position
	player.tier = tier
	player.training_efficiency = training_efficiency
	player.condition_multiplier = 1.0
	player.morale_multiplier = 1.0
	player.attributes.spd.current = spd
	player.attributes.spd.potential = potential_cap
	player.attributes.pwr.current = pwr
	player.attributes.pwr.potential = potential_cap
	player.attributes.tec.current = tec
	player.attributes.tec.potential = potential_cap
	player.attributes.intelligence.current = intelligence
	player.attributes.intelligence.potential = potential_cap
	player.attributes.sta.current = sta
	player.attributes.sta.potential = potential_cap
	return player


static func _resolve_performance_score(player: Variant) -> float:
	match player.position:
		"FW":
			return 8.2 if player.tier == "明星" else 7.1
		"MF":
			return 7.4
		"DF":
			return 7.0
		"GK":
			return 7.3
	return 6.8
