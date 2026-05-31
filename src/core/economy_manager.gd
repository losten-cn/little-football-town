class_name EconomyManager
extends Node
## Story 001 Core authority boundary for design/gdd/economy-management-system.md resources.

const AUTHORIZATION_TOKEN_KEY: String = "_authorization_token"
const MAX_TRANSACTION_LOG_ENTRIES: int = 200

var _funds: float = 0.0
var _action_points: float = 1.0
var _research_points: float = 0.0
var _next_transaction_id: int = 1
var _next_authorization_token: int = 1
var _transaction_log: Array[Transaction] = []
var _economy_config_override: EconomyConfig = null
var _event_bus_override: Node = null
var _warning_cooldown_by_type: Dictionary[String, float] = {}
var _authorized_transaction_tokens: Dictionary[int, bool] = {}
var _allow_test_source_transactions: bool = false


## Returns the authoritative funds balance.
func get_funds() -> float:
	return _funds


## Returns the authoritative action-points balance.
func get_action_points() -> float:
	return _action_points


## Returns the authoritative research-points balance.
func get_research_points() -> float:
	return _research_points


## Returns the authoritative AP-to-funds valuation weight.
func get_ap_to_funds_weight() -> float:
	var economy_config: EconomyConfig = _get_economy_config()
	if economy_config == null:
		return 0.0
	return economy_config.ap_to_funds_weight


## Returns a read-only snapshot of all authoritative economy balances.
func get_balance_snapshot() -> Dictionary[String, float]:
	return {
		"funds": _funds,
		"action_points": _action_points,
		"research_points": _research_points,
	}


## Overrides the runtime economy config for deterministic tests.
func set_economy_config_for_testing(economy_config: EconomyConfig) -> void:
	_economy_config_override = economy_config
	_allow_test_source_transactions = economy_config != null


## Returns committed transactions for deterministic tests and future audit surfaces.
func get_transaction_log() -> Array[Transaction]:
	var transaction_log_snapshot: Array[Transaction] = []
	transaction_log_snapshot.resize(_transaction_log.size())
	for transaction_index: int in range(_transaction_log.size()):
		transaction_log_snapshot[transaction_index] = Transaction.from_dict(_transaction_log[transaction_index].to_dict())
	return transaction_log_snapshot


## Overrides the runtime EventBus for deterministic tests.
func set_event_bus_for_testing(event_bus: Node) -> void:
	_event_bus_override = event_bus


## Overrides warning cooldown state for deterministic tests.
func set_warning_cooldown_for_testing(warning_type: String, next_allowed_timestamp: float) -> void:
	_warning_cooldown_by_type[warning_type] = next_allowed_timestamp


## Returns a read-only preview of current and projected balances for a proposed resource cost.
func get_budget_preview(funds_cost: float, action_points_cost: float, research_points_cost: float) -> Dictionary[String, Variant]:
	var projected_balances: Dictionary[String, float] = _calculate_projected_balances(funds_cost, action_points_cost, research_points_cost)
	var affordability: Dictionary[String, Variant] = _evaluate_affordability(projected_balances)
	return {
		"current_funds": _funds,
		"current_action_points": _action_points,
		"current_research_points": _research_points,
		"projected_funds": projected_balances["funds"],
		"projected_action_points": projected_balances["action_points"],
		"projected_research_points": projected_balances["research_points"],
		"affordable": affordability["affordable"],
		"reason_codes": affordability["reason_codes"],
	}


## Applies a transaction through the sole economy mutation boundary.
func execute_transaction(transaction: Transaction) -> Dictionary[String, Variant]:
	if transaction == null:
		return {"success": false, "error": "transaction_null"}
	if not _is_authorized_transaction(transaction):
		return {"success": false, "error": "unauthorized_source_system"}
	var validation: Dictionary[String, Variant] = _validate_transaction(transaction)
	if not (validation["success"] as bool):
		return validation
	transaction.metadata.erase(AUTHORIZATION_TOKEN_KEY)
	transaction.id = _next_transaction_id
	_next_transaction_id += 1
	transaction.timestamp = int(Time.get_unix_time_from_system())
	_funds += transaction.funds_delta
	_action_points += transaction.ap_delta
	_research_points += transaction.rp_delta
	_transaction_log.append(Transaction.from_dict(transaction.to_dict()))
	if _transaction_log.size() > MAX_TRANSACTION_LOG_ENTRIES:
		_transaction_log.remove_at(0)
	_emit_balance_changed(transaction)
	_check_warnings()
	return {"success": true, "tx_id": transaction.id}


## Applies a match-reward request through the accredited economy entry point.
func accredit_match_reward(funds_reward: int, action_points_reward: int, research_points_reward: int, match_id: int = 0) -> Dictionary[String, Variant]:
	var transaction: Transaction = Transaction.new()
	transaction.type = Transaction.TransactionType.INCOME
	transaction.funds_delta = float(funds_reward)
	transaction.ap_delta = float(action_points_reward)
	transaction.rp_delta = float(research_points_reward)
	transaction.reason = "match_reward"
	transaction.source_system = "match"
	transaction.metadata = {"match_id": match_id}
	return _execute_authorized_transaction(transaction)


## Applies a facility-construction-cost request through the accredited economy entry point.
func accredit_facility_construction_cost(funds_cost: int, action_points_cost: int, facility_id: int = 0) -> Dictionary[String, Variant]:
	if funds_cost > 0 and _funds < float(funds_cost):
		return {"success": false, "error": "funds_insufficient"}
	return accredit_facility_cost(funds_cost, action_points_cost, facility_id)


## Applies a facility-cost request through the accredited economy entry point.
func accredit_facility_cost(funds_cost: int, action_points_cost: int, facility_id: int = 0) -> Dictionary[String, Variant]:
	var transaction: Transaction = Transaction.new()
	transaction.type = Transaction.TransactionType.EXPENSE
	transaction.funds_delta = -float(funds_cost)
	transaction.ap_delta = -float(action_points_cost)
	transaction.rp_delta = 0.0
	transaction.reason = "facility_cost"
	transaction.source_system = "town"
	transaction.metadata = {"facility_id": facility_id}
	return _execute_authorized_transaction(transaction)


## Applies a training-cost request through the accredited economy entry point.
func accredit_training_cost(funds_cost: int, action_points_cost: int, player_id: int = 0) -> Dictionary[String, Variant]:
	var transaction: Transaction = Transaction.new()
	transaction.type = Transaction.TransactionType.EXPENSE
	transaction.funds_delta = -float(funds_cost)
	transaction.ap_delta = -float(action_points_cost)
	transaction.rp_delta = 0.0
	transaction.reason = "training_cost"
	transaction.source_system = "player"
	transaction.metadata = {"player_id": player_id}
	return _execute_authorized_transaction(transaction)


## Settles one in-game day through the transaction pipeline using TownBuilding query inputs.
func settle_day(is_rest_day: bool, town_building: TownBuilding) -> Dictionary[String, Variant]:
	if town_building == null:
		return {"success": false, "error": "town_building_null"}
	var economy_config: EconomyConfig = _get_economy_config()
	if economy_config == null:
		return {"success": false, "error": "economy_config_missing"}
	var facility_ap_bonus: int = town_building.get_daily_action_points_bonus()
	var facility_maintenance_cost: int = town_building.get_daily_maintenance_cost()
	var total_ap_recovery: float = economy_config.base_ap_recovery + float(facility_ap_bonus)
	if is_rest_day:
		total_ap_recovery += economy_config.base_rest_ap_recovery
	var next_action_points: float = minf(economy_config.action_points_max, _action_points + total_ap_recovery)
	var applied_ap_recovery: float = next_action_points - _action_points
	var maintenance_cost: float = economy_config.base_maintenance_cost + float(facility_maintenance_cost)
	var transaction: Transaction = Transaction.new()
	transaction.type = Transaction.TransactionType.TRANSFER
	transaction.funds_delta = -maintenance_cost
	transaction.ap_delta = applied_ap_recovery
	transaction.rp_delta = 0.0
	transaction.reason = "daily_settlement"
	transaction.source_system = "time"
	transaction.metadata = {
		"is_rest_day": is_rest_day,
		"base_ap_recovery": economy_config.base_ap_recovery,
		"facility_ap_bonus": facility_ap_bonus,
		"rest_ap_recovery": economy_config.base_rest_ap_recovery if is_rest_day else 0.0,
		"action_points_max": economy_config.action_points_max,
		"base_maintenance_cost": economy_config.base_maintenance_cost,
		"facility_maintenance_cost": facility_maintenance_cost,
	}
	var result: Dictionary[String, Variant] = _execute_authorized_transaction(transaction)
	if not (result.get("success", false) as bool):
		return result
	return {
		"success": true,
		"tx_id": result["tx_id"],
		"is_rest_day": is_rest_day,
		"ap_recovered": applied_ap_recovery,
		"maintenance_cost": maintenance_cost,
		"facility_ap_bonus": facility_ap_bonus,
		"facility_maintenance_cost": facility_maintenance_cost,
	}


## Settles post-match economy rewards through the transaction pipeline.
func settle_post_match(match_result_packet: Dictionary[String, Variant], settlement_context: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var economy_config: EconomyConfig = _get_economy_config()
	if economy_config == null:
		return {"success": false, "error": "economy_config_missing"}
	var match_result: String = String(match_result_packet.get("result", ""))
	var match_result_multiplier: float = _get_match_result_multiplier(match_result, economy_config)
	if match_result_multiplier < 0.0:
		return {"success": false, "error": "invalid_match_result"}
	var league_tier_multiplier: float = _resolve_league_tier_multiplier(settlement_context, economy_config)
	var stadium_revenue_multiplier: float = float(settlement_context.get("stadium_revenue_multiplier", 1.0))
	var tactical_rating_ratio: float = _clamp_tactical_rating_ratio(float(settlement_context.get("tactical_rating_ratio", 1.0)))
	var funds_reward: int = int(floor(economy_config.base_match_funds * league_tier_multiplier * match_result_multiplier * stadium_revenue_multiplier))
	var raw_research_reward: float = economy_config.tactical_rp_base * tactical_rating_ratio * league_tier_multiplier
	var floored_research_reward: int = int(floor(raw_research_reward))
	var available_research_capacity: float = maxf(0.0, economy_config.research_points_max - _research_points)
	var applied_research_reward: int = mini(floored_research_reward, int(floor(available_research_capacity)))
	var discarded_overflow: int = max(0, floored_research_reward - applied_research_reward)
	var transaction: Transaction = Transaction.new()
	transaction.type = Transaction.TransactionType.INCOME
	transaction.funds_delta = float(funds_reward)
	transaction.ap_delta = 0.0
	transaction.rp_delta = float(applied_research_reward)
	transaction.reason = "post_match_settlement"
	transaction.source_system = "match"
	transaction.metadata = {
		"match_id": String(match_result_packet.get("match_id", "")),
		"result": match_result,
		"league_tier_multiplier": league_tier_multiplier,
		"stadium_revenue_multiplier": stadium_revenue_multiplier,
		"tactical_rating_ratio": tactical_rating_ratio,
		"discarded_overflow": discarded_overflow,
	}
	var result: Dictionary[String, Variant] = _execute_authorized_transaction(transaction)
	if not (result.get("success", false) as bool):
		return result
	return {
		"success": true,
		"tx_id": result["tx_id"],
		"funds_reward": funds_reward,
		"research_points_reward": applied_research_reward,
		"applied_tactical_rating_ratio": tactical_rating_ratio,
		"discarded_overflow": discarded_overflow,
	}


## Settles stage-context rewards through the transaction pipeline.
func settle_stage(stage_context: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	return _settle_period_bonus("stage_settlement", stage_context)


## Settles season-context rewards through the transaction pipeline.
func settle_season(season_context: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var economy_config: EconomyConfig = _get_economy_config()
	if economy_config == null:
		return {"success": false, "error": "economy_config_missing"}
	var current_tier: int = int(season_context.get("current_tier", 1))
	var final_rank: int = int(season_context.get("final_rank", 1))
	var tier_multiplier: float = _resolve_league_tier_multiplier({"league_tier": current_tier}, economy_config)
	var ranking_multiplier: float = _resolve_season_ranking_multiplier(final_rank, economy_config)
	var resolved_context: Dictionary[String, Variant] = _to_string_variant_dictionary(season_context)
	resolved_context["funds_reward"] = economy_config.base_season_bonus * ranking_multiplier * tier_multiplier
	resolved_context["research_points_reward"] = economy_config.base_season_research * tier_multiplier
	resolved_context["ranking_multiplier"] = ranking_multiplier
	resolved_context["tier_multiplier"] = tier_multiplier
	return _settle_period_bonus("season_settlement", resolved_context)

func _duplicate_variant_deep(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value

func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = _duplicate_variant_deep(source[key])
	return typed_dictionary

func _validate_transaction(transaction: Transaction) -> Dictionary[String, Variant]:
	var projected_balances: Dictionary[String, float] = _calculate_projected_balances(-transaction.funds_delta, -transaction.ap_delta, -transaction.rp_delta)
	var affordability: Dictionary[String, Variant] = _evaluate_affordability(projected_balances)
	if not (affordability["affordable"] as bool):
		var reason_codes: Array[String] = affordability["reason_codes"] as Array[String]
		if reason_codes.is_empty():
			return {"success": false, "error": "transaction_rejected"}
		return {"success": false, "error": reason_codes[0]}
	return {"success": true}

func _execute_authorized_transaction(transaction: Transaction) -> Dictionary[String, Variant]:
	var authorization_token: int = _next_authorization_token
	_next_authorization_token += 1
	_authorized_transaction_tokens[authorization_token] = true
	var authorized_metadata: Dictionary[String, Variant] = _to_string_variant_dictionary(transaction.metadata)
	authorized_metadata[AUTHORIZATION_TOKEN_KEY] = authorization_token
	transaction.metadata = authorized_metadata
	var result: Dictionary[String, Variant] = execute_transaction(transaction)
	_authorized_transaction_tokens.erase(authorization_token)
	return result


## Registers this system with SaveManager using the economy persistence contract.
func register_with_save_manager(save_manager: Node) -> bool:
	if save_manager == null:
		return false
	return save_manager.register_system("economy", Callable(self, "serialize"), Callable(self, "deserialize"))


## Returns a serializable snapshot of balances, ids, and bounded transaction history.
func serialize() -> Dictionary[String, Variant]:
	var serialized_transactions: Array[Dictionary] = []
	serialized_transactions.resize(_transaction_log.size())
	for transaction_index: int in range(_transaction_log.size()):
		serialized_transactions[transaction_index] = _transaction_log[transaction_index].to_dict()
	return {
		"funds": _funds,
		"action_points": _action_points,
		"research_points": _research_points,
		"next_tx_id": _next_transaction_id,
		"transactions": serialized_transactions,
	}


## Restores balances, id counter, and bounded transaction history from save data.
func deserialize(data: Dictionary[String, Variant]) -> void:
	_funds = float(data.get("funds", 0.0))
	_action_points = float(data.get("action_points", 1.0))
	_research_points = float(data.get("research_points", 0.0))
	_next_transaction_id = int(data.get("next_tx_id", 1))
	_transaction_log.clear()
	for transaction_data: Variant in data.get("transactions", []) as Array:
		_transaction_log.append(Transaction.from_dict(_to_string_variant_dictionary(transaction_data)) as Transaction)
	if _transaction_log.size() > MAX_TRANSACTION_LOG_ENTRIES:
		_transaction_log = _transaction_log.slice(_transaction_log.size() - MAX_TRANSACTION_LOG_ENTRIES, _transaction_log.size())

func _settle_period_bonus(reason: String, settlement_context: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	var economy_config: EconomyConfig = _get_economy_config()
	if economy_config == null:
		return {"success": false, "error": "economy_config_missing"}
	var funds_reward: int = int(floor(float(settlement_context.get("funds_reward", 0.0))))
	var raw_research_reward: float = float(settlement_context.get("research_points_reward", 0.0))
	var floored_research_reward: int = int(floor(raw_research_reward))
	var available_research_capacity: float = maxf(0.0, economy_config.research_points_max - _research_points)
	var applied_research_reward: int = mini(floored_research_reward, int(floor(available_research_capacity)))
	var discarded_overflow: int = max(0, floored_research_reward - applied_research_reward)
	var transaction: Transaction = Transaction.new()
	transaction.type = Transaction.TransactionType.INCOME
	transaction.funds_delta = float(funds_reward)
	transaction.ap_delta = 0.0
	transaction.rp_delta = float(applied_research_reward)
	transaction.reason = reason
	transaction.source_system = "time"
	transaction.metadata = _to_string_variant_dictionary(settlement_context)
	transaction.metadata["discarded_overflow"] = discarded_overflow
	var result: Dictionary[String, Variant] = _execute_authorized_transaction(transaction)
	if not (result.get("success", false) as bool):
		return result
	return {
		"success": true,
		"tx_id": result["tx_id"],
		"funds_reward": funds_reward,
		"research_points_reward": applied_research_reward,
		"discarded_overflow": discarded_overflow,
	}

func _get_match_result_multiplier(match_result: String, economy_config: EconomyConfig) -> float:
	match match_result:
		"home_win", "away_win", "win":
			return economy_config.match_result_win_multiplier
		"draw":
			return economy_config.match_result_draw_multiplier
		"home_loss", "away_loss", "loss":
			return economy_config.match_result_loss_multiplier
		_:
			return -1.0

func _resolve_league_tier_multiplier(settlement_context: Dictionary[String, Variant], economy_config: EconomyConfig) -> float:
	if settlement_context.has("league_tier_multiplier"):
		return float(settlement_context.get("league_tier_multiplier", 1.0))
	var league_tier: int = int(settlement_context.get("league_tier", 1))
	if economy_config.league_tier_multipliers.has(league_tier):
		return float(economy_config.league_tier_multipliers[league_tier])
	return 1.0

func _clamp_tactical_rating_ratio(tactical_rating_ratio: float) -> float:
	return clampf(tactical_rating_ratio, 0.3, 1.0)

func _resolve_season_ranking_multiplier(final_rank: int, economy_config: EconomyConfig) -> float:
	if economy_config.season_ranking_multipliers.has(final_rank):
		return float(economy_config.season_ranking_multipliers[final_rank])
	return 1.0

func _is_authorized_transaction(transaction: Transaction) -> bool:
	var source_system: String = transaction.source_system
	if source_system in ["test", "test_suite"]:
		return _allow_test_source_transactions
	if source_system not in ["economy", "match", "town", "player", "time"]:
		return false
	var authorization_token: int = int(transaction.metadata.get(AUTHORIZATION_TOKEN_KEY, 0))
	return _authorized_transaction_tokens.has(authorization_token)

func _calculate_projected_balances(funds_cost: float, action_points_cost: float, research_points_cost: float) -> Dictionary[String, float]:
	return {
		"funds": _funds - funds_cost,
		"action_points": _action_points - action_points_cost,
		"research_points": _research_points - research_points_cost,
	}

func _evaluate_affordability(projected_balances: Dictionary[String, float]) -> Dictionary[String, Variant]:
	var economy_config: EconomyConfig = _get_economy_config()
	if economy_config == null:
		return {"affordable": false, "reason_codes": ["economy_config_missing"]}
	var reason_codes: Array[String] = []
	if projected_balances["funds"] < 0.0:
		reason_codes.append("funds_insufficient")
	if projected_balances["action_points"] < economy_config.action_points_floor:
		reason_codes.append("ap_below_floor")
	if projected_balances["research_points"] < economy_config.research_points_floor:
		reason_codes.append("rp_below_floor")
	return {
		"affordable": reason_codes.is_empty(),
		"reason_codes": reason_codes,
	}

func _check_warnings() -> void:
	var economy_config: EconomyConfig = _get_economy_config()
	if economy_config == null:
		return
	var current_timestamp: float = Time.get_unix_time_from_system()
	for warning: Dictionary in _get_active_warnings(economy_config):
		_emit_warning_if_ready(warning, current_timestamp, economy_config.warning_cooldown_seconds)

func _emit_balance_changed(transaction: Transaction) -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus == null:
		return
	event_bus.call("emit", "economy_balance_changed", {
		"resource_type": "all",
		"funds_delta": transaction.funds_delta,
		"ap_delta": transaction.ap_delta,
		"rp_delta": transaction.rp_delta,
		"new_funds": _funds,
		"new_ap": _action_points,
		"new_rp": _research_points,
		"reason": transaction.reason,
		"source_system": transaction.source_system,
	})

func _get_active_warnings(economy_config: EconomyConfig) -> Array[Dictionary]:
	var warnings: Array[Dictionary] = []
	if _funds <= economy_config.funds_low_threshold:
		warnings.append({
			"warning_type": "funds_low",
			"current_value": _funds,
			"threshold": economy_config.funds_low_threshold,
		})
	if _action_points <= economy_config.action_points_low_threshold:
		warnings.append({
			"warning_type": "ap_low",
			"current_value": _action_points,
			"threshold": economy_config.action_points_low_threshold,
		})
	if _funds <= economy_config.debt_warning_threshold:
		warnings.append({
			"warning_type": "debt",
			"current_value": _funds,
			"threshold": economy_config.debt_warning_threshold,
		})
	return warnings

func _emit_warning_if_ready(warning: Dictionary, current_timestamp: float, cooldown_seconds: float) -> void:
	var warning_type: String = String(warning.get("warning_type", ""))
	var next_allowed_timestamp: float = _warning_cooldown_by_type.get(warning_type, 0.0) as float
	if current_timestamp < next_allowed_timestamp:
		return
	_warning_cooldown_by_type[warning_type] = current_timestamp + cooldown_seconds
	var event_bus: Node = _get_event_bus()
	if event_bus == null:
		return
	event_bus.call("emit", "economy_warning_triggered", {
		"warning_type": warning_type,
		"current_value": float(warning.get("current_value", 0.0)),
		"threshold": float(warning.get("threshold", 0.0)),
	})

func _get_event_bus() -> Node:
	if _event_bus_override != null:
		return _event_bus_override
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/EventBus")

func _get_economy_config() -> EconomyConfig:
	if _economy_config_override != null:
		return _economy_config_override
	if not is_inside_tree():
		return null
	var config_loader: Node = get_node_or_null("/root/ConfigLoader")
	if config_loader == null:
		return null
	return config_loader.get("economy_config") as EconomyConfig
