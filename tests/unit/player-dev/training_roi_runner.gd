extends SceneTree

const TrainingRoiTestScript: Script = preload("res://tests/unit/player-dev/training_roi_test.gd")

func _initialize() -> void:
	var test_node: Node = TrainingRoiTestScript.new()
	root.add_child(test_node)
