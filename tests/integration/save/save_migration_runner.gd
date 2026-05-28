extends SceneTree

const SaveMigrationTestScript: Script = preload("res://tests/integration/save/save_migration_test.gd")

func _initialize() -> void:
	var test_node: Node = SaveMigrationTestScript.new()
	root.add_child(test_node)
