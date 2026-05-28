extends SceneTree

const TimeManagerStateContractTestScript: Script = preload("res://tests/integration/time/time_manager_state_contract_test.gd")

func _initialize() -> void:
	var event_bus_script: Script = load("res://src/autoload/event_bus.gd")
	var time_manager_script: Script = load("res://src/autoload/time_manager.gd")

	var event_bus: Node = event_bus_script.new()
	event_bus.name = "EventBus"
	root.add_child(event_bus)

	var time_manager: Node = time_manager_script.new()
	time_manager.name = "TimeManager"
	root.add_child(time_manager)

	var save_manager := Node.new()
	save_manager.name = "SaveManager"
	root.add_child(save_manager)

	var test_node: Node = TimeManagerStateContractTestScript.new()
	root.add_child(test_node)
