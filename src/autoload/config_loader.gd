extends Node
## Data-driven configuration loader.
## Loads all tuning values from Custom Resources at startup.
## See ADR-0004 for architecture details.

const BALANCE_CONFIG_PATH: String = "res://config/balance_config.tres"
const ECONOMY_CONFIG_PATH: String = "res://config/economy_config.tres"
const TOWN_CONFIG_PATH: String = "res://config/town_config.tres"
const MATCH_CONFIG_PATH: String = "res://config/match_config.tres"
const LEAGUE_CONFIG_PATH: String = "res://config/league_config.tres"
const REPUTATION_CONFIG_PATH: String = "res://config/reputation_config.tres"
const TRAINING_CATALOG_CONFIG_PATH: String = "res://config/training_catalog_config.tres"
const BalanceConfigType = preload("res://src/config/balance_config.gd")
const EconomyConfigType = preload("res://src/config/economy_config.gd")
const TownConfigType = preload("res://src/config/town_config.gd")
const MatchConfigType = preload("res://src/config/match_config.gd")
const LeagueConfigType = preload("res://src/config/league_config.gd")
const ReputationConfigType = preload("res://src/config/reputation_config.gd")
const TrainingCatalogConfigType = preload("res://src/config/training_catalog_config.gd")

var balance_config: BalanceConfigType = null
var economy_config: EconomyConfigType = null
var town_config: TownConfigType = null
var match_config: MatchConfigType = null
var league_config: LeagueConfigType = null
var reputation_config: ReputationConfigType = null
var training_catalog_config: TrainingCatalogConfigType = null
var last_errors: Array[String] = []

## Loads and validates startup configuration, quitting the game on failure.
func _ready() -> void:
	_register_ui_translations()
	if not load_all():
		push_error("ConfigLoader: failed to load config — game cannot start: %s" % str(last_errors))
		get_tree().quit(1)


func _register_ui_translations() -> void:
	var english_translation := Translation.new()
	english_translation.locale = "en"
	english_translation.add_message("SELECTED", "Selected")
	TranslationServer.add_translation(english_translation)

## Loads every config domain currently implemented by the project.
func load_all() -> bool:
	last_errors.clear()
	balance_config = _load_balance_config()
	economy_config = _load_economy_config()
	town_config = _load_town_config()
	match_config = _load_match_config()
	league_config = _load_league_config()
	reputation_config = _load_reputation_config()
	training_catalog_config = _load_training_catalog_config()
	return balance_config != null and economy_config != null and town_config != null and match_config != null and league_config != null and reputation_config != null and training_catalog_config != null

## Loads and validates a balance config resource from a specific path.
func load_balance_config_from_path(path: String):
	last_errors.clear()
	return _load_balance_config_from_path(path)

## Validates an already loaded balance config resource.
func validate_balance_config_resource(resource: Resource, path: String = BALANCE_CONFIG_PATH):
	last_errors.clear()
	return _validate_balance_config_resource(resource, path)

## Loads a town config resource from a specific path.
func load_town_config_from_path(path: String) -> Resource:
	last_errors.clear()
	return _load_town_config_from_path(path)

## Validates an already loaded town config resource.
func validate_town_config_resource(resource: Resource, path: String = TOWN_CONFIG_PATH) -> Resource:
	last_errors.clear()
	return _validate_town_config_resource(resource, path)

## Loads a league config resource from a specific path.
func load_league_config_from_path(path: String) -> Resource:
	last_errors.clear()
	return _load_league_config_from_path(path)

## Validates an already loaded league config resource.
func validate_league_config_resource(resource: Resource, path: String = LEAGUE_CONFIG_PATH) -> Resource:
	last_errors.clear()
	return _validate_league_config_resource(resource, path)

## Reloads one config domain for editor iteration.
func reload_config(domain: String) -> bool:
	if not OS.has_feature("editor"):
		last_errors = ["reload_config only available in editor builds"]
		push_error("ConfigLoader: %s" % last_errors[0])
		return false
	if domain == "balance":
		balance_config = _load_balance_config()
		return balance_config != null
	if domain == "economy":
		economy_config = _load_economy_config()
		return economy_config != null
	if domain == "town":
		town_config = _load_town_config()
		return town_config != null
	if domain == "match":
		match_config = _load_match_config()
		return match_config != null
	if domain == "league":
		league_config = _load_league_config()
		return league_config != null
	if domain == "reputation":
		reputation_config = _load_reputation_config()
		return reputation_config != null
	if domain == "training":
		training_catalog_config = _load_training_catalog_config()
		return training_catalog_config != null
	last_errors = ["unknown config domain: %s" % domain]
	push_error("ConfigLoader: %s" % last_errors[0])
	return false

func _load_balance_config():
	return _load_balance_config_from_path(BALANCE_CONFIG_PATH)

func _load_economy_config():
	return _load_economy_config_from_path(ECONOMY_CONFIG_PATH)

func _load_town_config() -> Resource:
	return _load_town_config_from_path(TOWN_CONFIG_PATH)

func _load_match_config() -> Resource:
	return _load_match_config_from_path(MATCH_CONFIG_PATH)

func _load_league_config() -> Resource:
	return _load_league_config_from_path(LEAGUE_CONFIG_PATH)

func _load_training_catalog_config() -> Resource:
	return _load_training_catalog_config_from_path(TRAINING_CATALOG_CONFIG_PATH)

func _load_balance_config_from_path(path: String):
	if not ResourceLoader.exists(path):
		last_errors.append("config file missing: %s" % path)
		return null
	var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	return _validate_balance_config_resource(resource, path)

func _load_economy_config_from_path(path: String):
	if not ResourceLoader.exists(path):
		last_errors.append("config file missing: %s" % path)
		return null
	var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	return _validate_economy_config_resource(resource, path)

func _load_town_config_from_path(path: String) -> Resource:
	if not ResourceLoader.exists(path):
		last_errors.append("config file missing: %s" % path)
		return null
	var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	return _validate_town_config_resource(resource, path)

func _load_match_config_from_path(path: String) -> Resource:
	if not ResourceLoader.exists(path):
		last_errors.append("config file missing: %s" % path)
		return null
	var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	return _validate_match_config_resource(resource, path)

func _load_league_config_from_path(path: String) -> Resource:
	if not ResourceLoader.exists(path):
		last_errors.append("config file missing: %s" % path)
		return null
	var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	return _validate_league_config_resource(resource, path)

func _load_training_catalog_config_from_path(path: String) -> Resource:
	if not ResourceLoader.exists(path):
		last_errors.append("config file missing: %s" % path)
		return null
	var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	return _validate_training_catalog_config_resource(resource, path)

func _validate_balance_config_resource(resource: Resource, path: String):
	if resource == null:
		last_errors.append("failed to load: %s" % path)
		return null
	var loaded_config = resource
	if loaded_config.get_script() != BalanceConfigType:
		last_errors.append("resource is not BalanceConfig: %s" % path)
		return null
	var result: Dictionary[String, Variant] = loaded_config.validate()
	if not (result["valid"] as bool):
		last_errors.append_array(result["errors"] as Array[String])
		return null
	return loaded_config

func _validate_economy_config_resource(resource: Resource, path: String):
	if resource == null:
		last_errors.append("failed to load: %s" % path)
		return null
	var loaded_config = resource
	if loaded_config.get_script() != EconomyConfigType:
		last_errors.append("resource is not EconomyConfig: %s" % path)
		return null
	var result: Dictionary[String, Variant] = loaded_config.validate()
	if not (result["valid"] as bool):
		last_errors.append_array(result["errors"] as Array[String])
		return null
	return loaded_config

func _validate_town_config_resource(resource: Resource, path: String) -> Resource:
	if resource == null:
		last_errors.append("failed to load: %s" % path)
		return null
	var loaded_config: Resource = resource
	if loaded_config.get_script() != TownConfigType:
		last_errors.append("resource is not TownConfig: %s" % path)
		return null
	var result: Dictionary[String, Variant] = loaded_config.call("validate")
	if not (result["valid"] as bool):
		last_errors.append_array(result["errors"] as Array[String])
		return null
	return loaded_config

func _validate_match_config_resource(resource: Resource, path: String) -> Resource:
	if resource == null:
		last_errors.append("failed to load: %s" % path)
		return null
	var loaded_config: Resource = resource
	if loaded_config.get_script() != MatchConfigType:
		last_errors.append("resource is not MatchConfig: %s" % path)
		return null
	var result: Dictionary[String, Variant] = loaded_config.call("validate")
	if not (result["valid"] as bool):
		last_errors.append_array(result["errors"] as Array[String])
		return null
	return loaded_config

func _validate_league_config_resource(resource: Resource, path: String) -> Resource:
	if resource == null:
		last_errors.append("failed to load: %s" % path)
		return null
	var loaded_config: Resource = resource
	if loaded_config.get_script() != LeagueConfigType:
		last_errors.append("resource is not LeagueConfig: %s" % path)
		return null
	var result: Dictionary[String, Variant] = loaded_config.call("validate")
	if not (result["valid"] as bool):
		last_errors.append_array(result["errors"] as Array[String])
		return null
	return loaded_config

func _validate_training_catalog_config_resource(resource: Resource, path: String) -> Resource:
	if resource == null:
		last_errors.append("failed to load: %s" % path)
		return null
	var loaded_config: Resource = resource
	if loaded_config.get_script() != TrainingCatalogConfigType:
		last_errors.append("resource is not TrainingCatalogConfig: %s" % path)
		return null
	var result: Dictionary[String, Variant] = loaded_config.call("validate")
	if not (result["valid"] as bool):
		last_errors.append_array(result["errors"] as Array[String])
		return null
	return loaded_config
