extends SceneTree

const SaveIntegrityAtomicCommitTestScript: Script = preload("res://tests/integration/save/save_integrity_atomic_commit_test.gd")

func _initialize() -> void:
	var test_node: Node = SaveIntegrityAtomicCommitTestScript.new()
	root.add_child(test_node)
