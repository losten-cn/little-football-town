class_name ReputationConfig
extends Resource
## Data-driven reputation tuning resource validated at startup.
##
## Implements the level threshold table required by
## design/gdd/reputation-and-achievement-system.md Formulas section
## and TR-reputation-002 (progress ratio from authoritative thresholds).
##
## All numeric values are configurable via @export;
## the validate() contract is enforced by ConfigLoader at startup per ADR-0004.

## Level threshold table mapping level number (int) to the cumulative
## reputation_total required to reach that level.  Must include at least
## level 1 (threshold 0) and must be strictly increasing.
## Default MVP values: Lv.1:0, Lv.2:100, Lv.3:180, Lv.4:260, Lv.5:360
@export var reputation_level_thresholds: Dictionary[int, int] = {
	1: 0,
	2: 100,
	3: 180,
	4: 260,
	5: 360,
}

## Returns the maximum level defined in the threshold table.
func get_max_level() -> int:
	var max_level: int = 1
	for level: int in reputation_level_thresholds.keys():
		if level > max_level:
			max_level = level
	return max_level

## Returns the threshold value for a given level, or -1 if the level is not defined.
func get_threshold_for_level(level: int) -> int:
	return reputation_level_thresholds.get(level, -1)

## Returns whether this resource satisfies all reputation safe ranges.
func validate() -> Dictionary[String, Variant]:
	var errors: Array[String] = []

	if reputation_level_thresholds.is_empty():
		errors.append("reputation_level_thresholds must not be empty")
		return {"valid": false, "errors": errors}

	if not reputation_level_thresholds.has(1):
		errors.append("reputation_level_thresholds must include level 1")
		return {"valid": false, "errors": errors}

	var threshold_at_1: int = reputation_level_thresholds[1]
	if threshold_at_1 != 0:
		errors.append("reputation_level_thresholds[1] must be 0, got %d" % threshold_at_1)

	var previous_level: int = -1
	var previous_threshold: int = -1

	var sorted_levels: Array[int] = []
	sorted_levels.assign(reputation_level_thresholds.keys())
	sorted_levels.sort()

	for level: int in sorted_levels:
		var threshold: int = reputation_level_thresholds[level]
		if threshold < 0:
			errors.append("reputation_level_thresholds[%d] must be >= 0, got %d" % [level, threshold])
		if previous_level > 0 and level != previous_level + 1:
			errors.append("reputation_level_thresholds levels must be consecutive; found gap after level %d" % previous_level)
		if previous_level > 0 and threshold <= previous_threshold:
			errors.append("reputation_level_thresholds must be strictly increasing; level %d threshold %d <= level %d threshold %d" % [level, threshold, previous_level, previous_threshold])
		previous_level = level
		previous_threshold = threshold

	return {"valid": errors.is_empty(), "errors": errors}
