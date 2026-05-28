extends SceneTree

const SaveRegistrationSnapshotTestScript: Script = preload("res://tests/integration/save/save_registration_snapshot_test.gd")

func _initialize() -> void:
	var test_node: Node = SaveRegistrationSnapshotTestScript.new()
	root.add_child(test_node)
