extends SceneTree

const LoadRestoreOrderTestScript: Script = preload("res://tests/integration/save/load_restore_order_test.gd")

func _initialize() -> void:
	var test_node: Node = LoadRestoreOrderTestScript.new()
	root.add_child(test_node)
