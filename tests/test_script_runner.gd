extends SceneTree
## Node-only headless launcher for tests that extend Node.
## Tests that extend SceneTree are full tree scripts and must run directly with --script.

const ARG_PREFIX: String = "--test-script="
const TESTS_PREFIX: String = "res://tests/"
const TEST_SUFFIX: String = "_test.gd"
const STARTUP_FAILURE_EXIT_CODE: int = 2


func _initialize() -> void:
	var test_script_path: String = _get_test_script_path()
	var validation_error: String = _validate_test_script_path(test_script_path)
	if not validation_error.is_empty():
		push_error(validation_error)
		call_deferred("_quit_with_code", STARTUP_FAILURE_EXIT_CODE)
		return

	var script_resource: Resource = load(test_script_path)
	if script_resource == null or not (script_resource is Script):
		push_error("Failed to load test script: %s" % test_script_path)
		call_deferred("_quit_with_code", STARTUP_FAILURE_EXIT_CODE)
		return

	var test_instance: Variant = (script_resource as Script).new()
	if not (test_instance is Node):
		push_error("Node test runner can only launch scripts that extend Node: %s. If this test extends SceneTree, run it directly with: godot --headless --path <project> --script %s" % [test_script_path, test_script_path])
		call_deferred("_quit_with_code", STARTUP_FAILURE_EXIT_CODE)
		return

	root.add_child(test_instance as Node)


func _get_test_script_path() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(ARG_PREFIX):
			return argument.trim_prefix(ARG_PREFIX)
	return ""


func _validate_test_script_path(test_script_path: String) -> String:
	if test_script_path.is_empty():
		return "Missing required arg: --test-script=res://tests/..._test.gd"
	if not test_script_path.begins_with(TESTS_PREFIX):
		return "Test script must be under res://tests/"
	if not test_script_path.ends_with(TEST_SUFFIX):
		return "Test script must end with _test.gd"
	return ""


func _quit_with_code(exit_code: int) -> void:
	quit(exit_code)
