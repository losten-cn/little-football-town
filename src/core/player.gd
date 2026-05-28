class_name Player
extends RefCounted

## Authoritative player runtime data.
var id: int = 0
var name: String = ""
var age: int = 18
var position: String = "MF"
var tier: String = "普通"
var special_trait_source: String = ""
var attributes: Attributes = Attributes.new()
var training_efficiency: float = 1.0
var condition_multiplier: float = 1.0
var morale_multiplier: float = 1.0
var training_history: Array[Dictionary] = []
var milestones: Array[String] = []
var review_flags: Array[String] = []
var total_training_sessions: int = 0
var last_age_advanced_season: int = 0


class Attributes:
	extends RefCounted

	var spd: AttributeTriplet = AttributeTriplet.new()
	var pwr: AttributeTriplet = AttributeTriplet.new()
	var tec: AttributeTriplet = AttributeTriplet.new()
	var intelligence: AttributeTriplet = AttributeTriplet.new()
	var sta: AttributeTriplet = AttributeTriplet.new()

	func to_dict() -> Dictionary[String, Variant]:
		return {
			"SPD": spd.to_dict(),
			"PWR": pwr.to_dict(),
			"TEC": tec.to_dict(),
			"INT": intelligence.to_dict(),
			"STA": sta.to_dict(),
		}

	static func from_dict(data: Dictionary[String, Variant]) -> Attributes:
		var value: Attributes = Attributes.new()
		value.spd = AttributeTriplet.from_dict(_to_typed_dictionary(data.get("SPD", {})))
		value.pwr = AttributeTriplet.from_dict(_to_typed_dictionary(data.get("PWR", {})))
		value.tec = AttributeTriplet.from_dict(_to_typed_dictionary(data.get("TEC", {})))
		value.intelligence = AttributeTriplet.from_dict(_to_typed_dictionary(data.get("INT", {})))
		value.sta = AttributeTriplet.from_dict(_to_typed_dictionary(data.get("STA", {})))
		return value

	static func _to_typed_dictionary(value: Variant) -> Dictionary[String, Variant]:
		var typed_dictionary: Dictionary[String, Variant] = {}
		if not (value is Dictionary):
			return typed_dictionary
		for key_variant: Variant in value:
			typed_dictionary[String(key_variant)] = value[key_variant]
		return typed_dictionary


class AttributeTriplet:
	extends RefCounted

	var current: int = 1
	var potential: int = 70

	func to_dict() -> Dictionary[String, Variant]:
		return {
			"current": current,
			"potential": potential,
		}

	static func from_dict(data: Dictionary[String, Variant]) -> AttributeTriplet:
		var value: AttributeTriplet = AttributeTriplet.new()
		value.current = int(data.get("current", 1))
		value.potential = int(data.get("potential", 70))
		return value
