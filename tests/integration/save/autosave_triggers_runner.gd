extends SceneTree

const AutosaveTriggersTestScript: Script = preload("res://tests/integration/save/autosave_triggers_test.gd")

func _initialize() -> void:
	var test_node: Node = AutosaveTriggersTestScript.new()
	root.add_child(test_node)
