extends SceneTree

const SaveRecoveryFlowTestScript: Script = preload("res://tests/integration/save/save_recovery_flow_test.gd")

func _initialize() -> void:
	var test_node: Node = SaveRecoveryFlowTestScript.new()
	root.add_child(test_node)
