extends Node

const MatchSimulationScript: Script = preload("res://src/core/match_simulation.gd")

var _failures: Array[String] = []


func _ready() -> void:
	test_key_event_count_stays_within_three_to_fifteen()
	test_key_event_generation_reaches_all_categories_with_complete_fields()
	test_low_event_match_still_returns_three_readable_events_with_slow_pace_explanation()
	if _failures.is_empty():
		print("KEY_EVENT_GENERATION_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("KEY_EVENT_GENERATION_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_key_event_count_stays_within_three_to_fifteen() -> void:
	var simulation: MatchSimulation = MatchSimulationScript.new()
	var low_density_events: Array[Dictionary] = simulation.generate_key_events(0.05)
	var mid_density_events: Array[Dictionary] = simulation.generate_key_events(0.50)
	var high_density_events: Array[Dictionary] = simulation.generate_key_events(0.95)
	_expect(low_density_events.size() >= 3 and low_density_events.size() <= 15, "low-density match should keep event count within 3..15")
	_expect(mid_density_events.size() >= 3 and mid_density_events.size() <= 15, "mid-density match should keep event count within 3..15")
	_expect(high_density_events.size() >= 3 and high_density_events.size() <= 15, "high-density match should keep event count within 3..15")


func test_key_event_generation_reaches_all_categories_with_complete_fields() -> void:
	var simulation: MatchSimulation = MatchSimulationScript.new()
	var events: Array[Dictionary] = simulation.generate_key_events(0.95)
	var seen_categories: Dictionary[String, bool] = {}
	for event_variant: Variant in events:
		var event: Dictionary = event_variant as Dictionary
		var category: String = String(event.get("category", ""))
		var minute: int = int(event.get("minute", 0))
		var half: int = int(event.get("half", 0))
		var side: String = String(event.get("side", ""))
		var narrative_tags: Variant = event.get("narrative_tags", [])
		var modifier_flags: Variant = event.get("modifier_flags", {})
		seen_categories[category] = true
		_expect(not category.is_empty(), "every event should have a non-empty category")
		_expect(minute >= 1 and minute <= 90, "every event should have a legal minute")
		_expect(half == 1 or half == 2, "every event should have a legal half identity")
		_expect(side == "home" or side == "away", "every event should have a legal side")
		_expect(narrative_tags is Array and not (narrative_tags as Array).is_empty(), "every event should have readable narrative tags")
		_expect(modifier_flags is Dictionary, "every event should have modifier flags")
	for category: String in MatchSimulation.KEY_EVENT_CATEGORIES:
		_expect(seen_categories.has(category), "all six key event categories should be reachable")


func test_low_event_match_still_returns_three_readable_events_with_slow_pace_explanation() -> void:
	var simulation: MatchSimulation = MatchSimulationScript.new()
	var events: Array[Dictionary] = simulation.generate_key_events(0.05)
	var has_slow_pace_tag: bool = false
	_expect(events.size() >= 3, "low-event match should still return at least three readable events")
	for event_variant: Variant in events:
		var event: Dictionary = event_variant as Dictionary
		var narrative_tags: Array = event.get("narrative_tags", []) as Array
		if narrative_tags.has("slow_pace"):
			has_slow_pace_tag = true
	_expect(has_slow_pace_tag, "low-event match should include a slow_pace explanation tag")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
