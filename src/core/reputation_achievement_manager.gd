class_name ReputationAchievementManager
extends Node
## Story 001-002 implementation for design/gdd/reputation-and-achievement-system.md.
##
## Owns the three core durable-truth fields for reputation:
##   reputation_total, reputation_level, reputation_progress_ratio.
##   (Story 003-004 add achievements, rewards, ledgers, settlement keys.)
##
## Governed by ADR-0011 (Reputation and Achievement Recognition Framework).
## Implements TR-reputation-001 and TR-reputation-002.
##
## This node is scene-instantiated (class_name), NOT an Autoload.
## It exports serialize/deserialize for SaveManager registration (Story 004).
##
## Story 002 adds:
##   - calculate_reputation_gain() — formula 1
##   - get_reputation_progress_ratio() — formula 2
##   - process_reputation_gain() — multi-level crossing (formula 3)
##   - Config-driven level threshold table via ReputationConfig Resource.

# ─────────────────────────────────────────────
# Durable fields (writer-owned per ADR-0011 Part A)
# ─────────────────────────────────────────────

## Total accumulated reputation. Sole writer: this manager.
var reputation_total: int = 0

## Current reputation level (1-based index into the threshold table).
## Sole writer: this manager.
var reputation_level: int = 1

## Progress ratio within the current level, 0.0–1.0.
## recomputed on every gain and on deserialize validation.
## Sole writer: this manager.
var reputation_progress_ratio: float = 0.0

# ─────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────

## Level threshold table loaded from ReputationConfig Resource.
## Format: {level: cumulative_threshold}.  Default MVP values:
##   Lv.1:0, Lv.2:100, Lv.3:180, Lv.4:260, Lv.5:360
## Values >= 0, strictly increasing, consecutive integer keys starting at 1.
var _level_thresholds: Dictionary[int, int] = {
	1: 0,
	2: 100,
	3: 180,
	4: 260,
	5: 360,
}

# ─────────────────────────────────────────────
# Config injection (called after instantiation)
# ─────────────────────────────────────────────

## Applies a ReputationConfig Resource, replacing the default threshold table.
## Must be called before any gain processing.
## The config must pass validate() before being injected here.
func apply_config(config: ReputationConfig) -> void:
	if config == null:
		push_error("ReputationAchievementManager.apply_config: config is null — keeping defaults")
		return
	var result: Dictionary[String, Variant] = config.validate()
	if not (result["valid"] as bool):
		push_error("ReputationAchievementManager.apply_config: config failed validation — keeping defaults. Errors: %s" % str(result["errors"]))
		return
	_level_thresholds = config.reputation_level_thresholds.duplicate()
	# Recompute progress in case thresholds changed.
	_recompute_progress_ratio()

# ─────────────────────────────────────────────
# Formula 1 — Reputation gain calculation
# ─────────────────────────────────────────────

## Calculates the reputation gain for a single event.
##
## Formula (TR-reputation-001, GDD Formulas section):
##   reputation_gain = floor((base_reputation_source + bonus_reputation_source)
##                            × source_weight × stage_multiplier)
##
## Parameters:
##   base: int — base reputation from the event type (>= 0)
##   bonus: int — bonus reputation from special conditions (>= 0)
##   source_weight: float — source-type weight, 0.5–2.0
##   stage_multiplier: float — league-stage multiplier, 1.0–1.5
##
## Returns:
##   int — floor of the formula result, always >= 0.
##
## Note: This only computes what the gain would be.  It does NOT mutate
## any state.  Call process_reputation_gain() to apply the result.
func calculate_reputation_gain(base: int, bonus: int, source_weight: float, stage_multiplier: float) -> int:
	if base < 0 or bonus < 0:
		push_error("ReputationAchievementManager.calculate_reputation_gain: base (%d) and bonus (%d) must be >= 0" % [base, bonus])
		return 0
	if source_weight < 0.0 or stage_multiplier < 0.0:
		push_error("ReputationAchievementManager.calculate_reputation_gain: source_weight (%.3f) and stage_multiplier (%.3f) must be >= 0" % [source_weight, stage_multiplier])
		return 0

	var combined: float = float(base + bonus)
	var weighted: float = combined * source_weight * stage_multiplier
	return floori(weighted)

# ─────────────────────────────────────────────
# Formula 2 — Level progress ratio
# ─────────────────────────────────────────────

## Returns the current level progress ratio (0.0–1.0).
##
## Formula (TR-reputation-002, GDD Formulas section):
##   reputation_progress_ratio = (reputation_total - current_level_threshold)
##                               / max(1, next_level_threshold - current_level_threshold)
##
## Returns:
##   float — 0.0–1.0.  If reputation_total is below the current level
##   threshold (data anomaly), returns 0.0.  If at or above the next
##   level threshold, returns 1.0.
##
## This is a read-only accessor.  The cached field
## reputation_progress_ratio is updated during process_reputation_gain()
## and after deserialize validation.
func get_reputation_progress_ratio() -> float:
	return reputation_progress_ratio

# ─────────────────────────────────────────────
# Formula 3 — Process reputation gain with multi-level crossing
# ─────────────────────────────────────────────

## Applies a reputation gain to the durable total and processes level-ups.
##
## Multi-level crossing rule (GDD Example 3):
##   If a single gain pushes reputation_total past multiple level thresholds,
##   the system must process each level sequentially:
##     Lv.2 → Lv.3 → Lv.4
##   After all crossing levels are resolved, the progress_ratio is
##   recomputed within the final level's interval.
##
## Parameters:
##   gain: int — the reputation gain to apply (must be >= 0)
##
## Emits:
##   reputation_level_up(level: int) — once for each level attained,
##     including intermediate levels crossed in a single gain event.
##   reputation_changed() — after all level-ups and progress recomputation.
##
## Note: In Story 002, signals are emitted as simple callables for test
## visibility.  Full EventBus integration arrives in Story 004.
func process_reputation_gain(gain: int) -> void:
	if gain < 0:
		push_error("ReputationAchievementManager.process_reputation_gain: gain (%d) must be >= 0" % gain)
		return
	if gain == 0:
		return

	var previous_total: int = reputation_total
	reputation_total += gain

	var max_level: int = _get_max_level()
	var levels_advanced: Array[int] = []

	# Multi-level crossing loop: while we are at or past the next threshold,
	# advance one level at a time.
	while reputation_level < max_level:
		var next_threshold: int = _get_threshold(reputation_level + 1)
		if next_threshold < 0:
			break
		if reputation_total >= next_threshold:
			reputation_level += 1
			levels_advanced.append(reputation_level)
		else:
			break

	# Recompute progress ratio at the final level.
	_recompute_progress_ratio()

	# Emit level-up signals for each level attained (including intermediate ones).
	for level: int in levels_advanced:
		_on_level_up(level)

	_on_reputation_changed(previous_total, reputation_total)

# ─────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────

## Recomputes reputation_progress_ratio from reputation_total and the
## current level's threshold interval.  Stores result in the durable field.
func _recompute_progress_ratio() -> void:
	var current_threshold: int = _get_threshold(reputation_level)
	var next_threshold: int = _get_threshold(reputation_level + 1)

	# Data anomaly guard: if total is below current threshold, clamp to 0.
	if reputation_total < current_threshold:
		push_error("ReputationAchievementManager: reputation_total (%d) < current_level_threshold (%d) for level %d — clamping progress to 0.0" % [reputation_total, current_threshold, reputation_level])
		reputation_progress_ratio = 0.0
		return

	# If there is no next level defined, progress is complete (1.0).
	if next_threshold < 0:
		reputation_progress_ratio = 1.0
		return

	var interval: int = next_threshold - current_threshold
	var numerator: int = reputation_total - current_threshold
	var denominator: int = maxi(1, interval)

	if reputation_total >= next_threshold:
		reputation_progress_ratio = 1.0
	else:
		reputation_progress_ratio = float(numerator) / float(denominator)

## Returns the threshold for a given level, or -1 if undefined.
func _get_threshold(level: int) -> int:
	return _level_thresholds.get(level, -1)

## Returns the maximum level defined in the threshold table.
func _get_max_level() -> int:
	var max_found: int = 1
	for level: int in _level_thresholds.keys():
		if level > max_found:
			max_found = level
	return max_found

# ─────────────────────────────────────────────
# Signal emitters (overridable for test visibility)
# ─────────────────────────────────────────────

## Called when a level-up occurs.  Emits the reputation_level_up signal.
## Parameters:
##   level: int — the level just attained
func _on_level_up(level: int) -> void:
	reputation_leveled_up.emit(level)

## Called after reputation_total changes and all level-ups are resolved.
func _on_reputation_changed(previous_total: int, new_total: int) -> void:
	reputation_changed.emit(previous_total, new_total)

# ─────────────────────────────────────────────
# Signals
# ─────────────────────────────────────────────

## Emitted for each level attained during process_reputation_gain(),
## including intermediate levels crossed in a single gain event.
signal reputation_leveled_up(level: int)

## Emitted after reputation_total changes and all level-ups are resolved.
signal reputation_changed(previous_total: int, new_total: int)
