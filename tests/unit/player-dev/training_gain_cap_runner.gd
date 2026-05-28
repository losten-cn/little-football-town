extends SceneTree

const TrainingGainCapTestScript: Script = preload("res://tests/unit/player-dev/training_gain_cap_test.gd")

func _initialize() -> void:
	var test_node: Node = TrainingGainCapTestScript.new()
	root.add_child(test_node)
