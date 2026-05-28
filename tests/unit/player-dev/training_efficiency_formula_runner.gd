extends SceneTree

const TrainingEfficiencyFormulaTestScript: Script = preload("res://tests/unit/player-dev/training_efficiency_formula_test.gd")

func _initialize() -> void:
	var test_node: Node = TrainingEfficiencyFormulaTestScript.new()
	root.add_child(test_node)
