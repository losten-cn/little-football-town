extends Node
## Data-driven configuration loader.
## Loads all tuning values from Custom Resources at startup.
## See ADR-0004 for architecture details.

const BALANCE_CONFIG_PATH: String = "res://config/balance_config.tres"

var balance_config: BalanceConfig
var last_errors: Array[String] = []

## Loads and validates startup configuration, quitting the game on failure.
func _ready() -> void:
	if not load_all():
		push_error("ConfigLoader: failed to load config — game cannot start: %s" % str(last_errors))
		get_tree().quit(1)

## Loads every config domain currently implemented by the project.
func load_all() -> bool:
	last_errors.clear()
	balance_config = _load_balance_config()
	return balance_config != null

## Reloads one config domain for editor iteration.
func reload_config(domain: String) -> bool:
	if not OS.has_feature("editor"):
		last_errors = ["reload_config only available in editor builds"]
		push_error("ConfigLoader: %s" % last_errors[0])
		return false
	if domain != "balance":
		last_errors = ["unknown config domain: %s" % domain]
		push_error("ConfigLoader: %s" % last_errors[0])
		return false
	balance_config = _load_balance_config()
	return balance_config != null

func _load_balance_config() -> BalanceConfig:
	if not ResourceLoader.exists(BALANCE_CONFIG_PATH):
		last_errors.append("config file missing: %s" % BALANCE_CONFIG_PATH)
		return null
	var resource: Resource = ResourceLoader.load(BALANCE_CONFIG_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		last_errors.append("failed to load: %s" % BALANCE_CONFIG_PATH)
		return null
	var loaded_config: BalanceConfig = resource as BalanceConfig
	if loaded_config == null:
		last_errors.append("resource is not BalanceConfig: %s" % BALANCE_CONFIG_PATH)
		return null
	var result: Dictionary[String, Variant] = loaded_config.validate()
	if not (result["valid"] as bool):
		last_errors.append_array(result["errors"] as Array[String])
		return null
	return loaded_config
