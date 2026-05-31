class_name Transaction
extends RefCounted
## Story 001 runtime economy transaction model for design/gdd/economy-management-system.md.


enum TransactionType {
	INCOME,
	EXPENSE,
	TRANSFER,
}

var id: int = 0
var type: TransactionType = TransactionType.TRANSFER
var funds_delta: float = 0.0
var ap_delta: float = 0.0
var rp_delta: float = 0.0
var reason: String = ""
var source_system: String = ""
var timestamp: int = 0
var metadata: Dictionary[String, Variant] = {}


## Returns a serializable snapshot of this runtime transaction.
func to_dict() -> Dictionary[String, Variant]:
	return {
		"id": id,
		"type": int(type),
		"funds_delta": funds_delta,
		"ap_delta": ap_delta,
		"rp_delta": rp_delta,
		"reason": reason,
		"source_system": source_system,
		"timestamp": timestamp,
		"metadata": metadata.duplicate(true),
	}


## Rebuilds a runtime transaction from serialized data.
static func _to_typed_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary


static func from_dict(data: Dictionary[String, Variant]) -> Transaction:
	var transaction := Transaction.new()
	transaction.id = int(data.get("id", 0))
	transaction.type = int(data.get("type", TransactionType.TRANSFER)) as TransactionType
	transaction.funds_delta = float(data.get("funds_delta", 0.0))
	transaction.ap_delta = float(data.get("ap_delta", 0.0))
	transaction.rp_delta = float(data.get("rp_delta", 0.0))
	transaction.reason = String(data.get("reason", ""))
	transaction.source_system = String(data.get("source_system", ""))
	transaction.timestamp = int(data.get("timestamp", 0))
	transaction.metadata = _to_typed_dictionary(data.get("metadata", {}))
	return transaction
