extends SceneTree

const SaveSummaryPerformanceTestScript: Script = preload("res://tests/integration/save/save_summary_performance_test.gd")


func _initialize() -> void:
	var test_node: Node = SaveSummaryPerformanceTestScript.new()
	root.add_child(test_node)
