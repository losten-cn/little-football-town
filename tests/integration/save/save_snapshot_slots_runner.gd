extends SceneTree

const SaveSnapshotSlotsTestScript: Script = preload("res://tests/integration/save/save_snapshot_slots_test.gd")

func _initialize() -> void:
	var test_node: Node = SaveSnapshotSlotsTestScript.new()
	root.add_child(test_node)
