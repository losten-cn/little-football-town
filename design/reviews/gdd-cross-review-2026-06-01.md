# Cross-GDD Review — 2026-06-01

**Scope:** `/review-all-gdds` re-review after blocker-repair and skill/trait patch alignment  
**Engine Context:** Godot 4.6 / GDScript  
**Review Mode:** Full cross-document consistency + holistic design pass + scenario walkthrough  
**Verdict:** PASS WITH CONCERNS

## Summary

The current GDD set is now coherent enough to advance from Systems Design into Technical Setup / architecture planning. The previously blocking issues around forced match progression, AP deadlock, town-building MVP boundary drift, skill/trait UI consumption, and skill/trait save/load persistence are now closed across owner, consumer, and UI-facing documents.

The remaining concerns are no longer blockers. They are governance, implementation-aliasing, and experience risks that should be tracked during architecture and playtest follow-through: shared match-strength terminology should be normalized before implementation, the entity registry still does not record several important cross-system payload contracts, economy soft-stall recovery is formally safe but still needs feel validation, and town-building facility attractiveness may still skew toward training-first investment.

## Scope

This review covers the latest versions of:

- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/gdd/balance-system.md`
- `design/gdd/save-and-load-system.md`
- `design/gdd/time-and-season-progression-system.md`
- `design/gdd/player-development-system.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/league-competition-structure-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/match-performance-ui.md`
- `design/gdd/onboarding-system.md`
- `design/gdd/skill-and-trait-system.md`
- `design/gdd/reputation-and-achievement-system.md`
- `design/registry/entities.yaml`

Historical review reports were treated as reference only and excluded from the system count:

- `design/gdd/gdd-cross-review-2026-05-31.md`
- `design/gdd/gdd-cross-review-2026-05-31-skill-trait-patch.md`

## Registry Baseline

`design/registry/entities.yaml` still has no entity, item, or constant entries, but it does register the current shared formulas baseline, including:

- `effective_attribute_value`
- `attribute_growth`
- `resource_settlement`
- `positional_overall_rating`
- `base_win_probability`
- `action_time_cost`
- `available_action_windows`
- `match_trigger_reached`
- `stage_settlement_trigger_reached`
- `season_progress_ratio`
- `remaining_time_to_next_key_node`
- `training_actual_gain`
- `player_tier_potential_band`

The formula registry is sufficient to anchor core numeric consistency, but non-formula cross-system contracts still rely on GDD prose rather than registry ownership.

## Verdict

**PASS WITH CONCERNS**

Systems Design no longer needs to remain blocked on cross-GDD consistency. The repaired documents now form a stable enough baseline to continue into Technical Setup and architecture definition.

The remaining issues are explicit warnings, not blockers.

## Phase 2 — Cross-GDD Consistency

**Verdict:** PASS

### Closed Blockers

#### 1. Match-day AP deadlock is closed

The `match_day_ap_safety_grant` rule is now consistent across:

- `design/gdd/time-and-season-progression-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/onboarding-system.md`

The time system owns the trigger, the economy system owns the grant execution, and presentation/onboarding treat it as automatic support rather than a player-selectable action.

#### 2. Forced-match illegal-lineup fallback is closed

The fallback chain now aligns across:

- `design/gdd/match-competition-system.md`
- `design/gdd/league-competition-structure-system.md`
- `design/gdd/match-performance-ui.md`
- `design/gdd/onboarding-system.md`

Recommended lineup, out-of-position fill, and `forfeit_result_packet` together guarantee that a formal match node can always resolve into a legal downstream result packet instead of stalling progression.

#### 3. Town-building MVP output ownership is closed

The MVP town-building slice now exposes only the outputs with known downstream consumers:

- `facility_training_multiplier` → `player-development-system.md`
- `facility_total_maintenance` → `economy-management-system.md`
- `home_advantage_bonus` → `match-competition-system.md`

The formerly drifting MVP outputs are now explicitly reserved as placeholders instead of active design contracts:

- `facility_ap_bonus = 0`
- `stadium_revenue_multiplier = 1.00`
- adjacency formulas are Alpha-only

#### 4. Skill/trait save-load contract is closed

`design/gdd/skill-and-trait-system.md` and `design/gdd/save-and-load-system.md` now align on the long-term persistence contract for:

- skill ownership, level, and progress
- `candidate_progress_record`
- `trait_cooldown_state`
- `pending_skill_trait_feedback`
- `feedback_ack`
- `player_identity_history_entry`
- `skill_trait_migration_record`
- processed stable settlement keys

The save/load system no longer leaves the skill/trait layer partially specified.

#### 5. Skill/trait UI consumption contract is closed

`design/gdd/player-management-ui.md`, `design/gdd/match-performance-ui.md`, and `design/gdd/main-loop-ui-framework.md` now consistently consume:

- read-only pre-match snapshots
- post-match skill/trait explanation payloads
- candidate visibility stages with blocked reasons
- feedback acknowledgement state
- identity history output

The UI layer no longer depends on recomputing the underlying logic contracts.

### Warnings

#### WARNING — Match-strength terminology still needs one implementation alias

**Files involved:**

- `design/gdd/balance-system.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/match-performance-ui.md`

**Issue:**
The formulas are compatible, but naming still spans `self_team_rating` / `opponent_team_rating` on the balance side and `team_match_strength` on the match/UI side. This is not a rule contradiction, but it is a likely implementation drift point if architecture does not establish one canonical mapping.

**Recommendation:**
Define a single architecture-level alias between balance-owned rating inputs and match-owned resolved strength output before implementation work begins.

#### WARNING — Registry ownership still lags behind document reality

**Files involved:**

- `design/registry/entities.yaml`
- `design/gdd/skill-and-trait-system.md`
- `design/gdd/save-and-load-system.md`
- `design/gdd/match-competition-system.md`

**Issue:**
Several active cross-system contracts still exist only in prose and are not represented in the registry, including:

- `forfeit_result_packet`
- `pre_match_skill_trait_snapshot`
- `pending_skill_trait_feedback`
- `feedback_ack`
- `candidate_progress_record`
- `trait_cooldown_state`
- `skill_trait_migration_record`
- stable `settlement_key`

**Recommendation:**
Register these payloads/constants before or during architecture work so future consistency checks can rely less on free-text alignment.

#### WARNING — Placeholder MVP values are aligned but duplicated across owner/consumer docs

**Files involved:**

- `design/gdd/town-building-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/player-development-system.md`
- `design/gdd/match-competition-system.md`

**Issue:**
The current MVP placeholder values are now consistent, but they are restated in multiple documents. This is acceptable for clarity, but it creates a future tuning-drift hazard.

**Recommendation:**
Preserve the producer/owner document as the authority for each placeholder and treat downstream docs as consuming references only.

## Phase 3 — Holistic Design Review

**Verdict:** PASS

### Closed Blockers

#### 1. Town-building no longer competes for primary progression

The MVP town-building slice has been compressed enough that it functions as supportive infrastructure rather than a rival progression loop. It now reinforces training, match readiness, and warm-town identity instead of demanding constant optimization attention.

#### 2. Pre-match attention overload is closed

`design/gdd/main-loop-ui-framework.md` and `design/gdd/match-performance-ui.md` now restrict active pre-match decision load to four or fewer meaningful actions. AP state, facilities, skill snapshots, league stakes, and growth expectations are now read-only context or automatic resolution.

#### 3. Skill/trait long-term state and UI feedback are now coherent

The skill/trait layer now has a consistent player-facing lifecycle: stable settlement, visible result explanation, persistent acknowledgement state, and durable reload behavior.

### Warnings

#### WARNING — Economy soft-stall is now recoverable, but still needs feel validation

**Files involved:**

- `design/gdd/economy-management-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/time-and-season-progression-system.md`

**Issue:**
The design now proves that prolonged loss/maintenance pressure does not force a hidden fail state because `season_recovery_floor_grant` restores the player to the minimum regular funds action threshold after season settlement. This closes the prior blocker. However, a player may still experience a long low-agency stretch before that recovery point.

**Recommendation:**
Treat this as a playtest watch item: verify that the system feels like temporary pressure rather than punishment or drift.

#### WARNING — Town-building facility attractiveness may still skew toward training-first choices

**Files involved:**

- `design/gdd/town-building-system.md`
- `design/gdd/player-development-system.md`
- `design/gdd/economy-management-system.md`

**Issue:**
The MVP outputs are now appropriately scoped, but training-related facilities may still dominate perceived value over the remaining facility set.

**Recommendation:**
Observe first-run player choices during prototype or vertical-slice testing and confirm that the system still reads as “build a warm football town,” not “rush only the training multipliers.”

#### WARNING — League pressure should be validated against the low-pressure pillar

**Files involved:**

- `design/gdd/league-competition-structure-system.md`
- `design/gdd/game-concept.md`

**Issue:**
The promotion/relegation structure is not inherently in conflict with the project pillars, but the docs still leave room for implementation/tuning to accidentally make relegation pressure too sharp relative to the intended cozy long-term tone.

**Recommendation:**
Anchor MVP default league penalties and rewards to the anti-pillar of avoiding punishment-driven management pressure.

## Phase 4 — Cross-System Scenario Walkthrough

### Key scenarios reviewed

1. Formal match day reached while AP is below match-start threshold.
2. Formal match day reached while the current lineup is illegal.
3. Match completes and triggers post-match skill/trait feedback, then the game is saved and loaded.
4. A high-maintenance, low-win season ends under economic pressure.

### Scenario 1 — Formal match day with insufficient AP

**Trigger:** The player reaches a formal match node without enough AP to pay the match-start requirement.

**Activation order:**
1. Time progression detects the forced match node.
2. Economy executes `match_day_ap_safety_grant` to raise AP to the minimum match-start threshold.
3. Main loop / onboarding present the grant as an automatic support event rather than an extra choice.
4. Match flow proceeds normally.

**Result:**
The previous deadlock is closed. No reviewed document reintroduces a competing rule that would let the node remain unresolved.

### Scenario 2 — Formal match day with illegal lineup

**Trigger:** The player reaches a forced match node with an invalid active lineup.

**Activation order:**
1. Match system attempts recommended lineup.
2. If still invalid, it attempts out-of-position fill with penalties.
3. If legal participation still cannot be formed, it emits `forfeit_result_packet`.
4. League, economy, and time progression consume the result as a resolved formal match outcome.
5. Match-performance UI explains the fallback without pretending the player made a normal tactical choice.

**Result:**
The previous illegal-state stall is closed. The flow now prioritizes schedule continuity over ideal player control, which matches the low-pressure / no-hidden-failure direction better than a hard block.

### Scenario 3 — Match result triggers skill/trait feedback, then save/load

**Trigger:** A match settlement unlocks or upgrades a skill/trait result and produces player-facing feedback.

**Activation order:**
1. Match settlement reaches a stable settlement node.
2. Skill/trait system resolves deterministic outcomes using stable settlement keys.
3. Result feedback is exposed to UI as explanation payload plus acknowledgement state.
4. Save/load persists the unlocked state, candidate progress, cooldowns, acknowledgement state, history records, and migration record.
5. Reload restores the same durable result state without replaying half-resolved settlement transitions.

**Result:**
The prior blocker is closed. I did not find a remaining cross-doc contradiction that would cause the skill/trait layer to be visible in UI but absent in persistence, or persisted but not explainable in UI.

### Scenario 4 — High maintenance plus poor performance over a season

**Trigger:** The player carries expensive facilities through a weak season and approaches a low-funds state.

**Activation order:**
1. Economy applies match-result income and recurring maintenance pressure.
2. Time progression advances the season.
3. League standing contributes to season bonus outcomes.
4. Economy applies `season_recovery_floor_grant` if the season-end state falls below the defined minimum regular funds action threshold.
5. The next season begins in a recoverable state.

**Result:**
The design no longer implies hidden permanent failure. The system now guarantees recovery to a minimal actionable floor. The remaining question is experiential, not structural: whether the route to that recovery feels too passive.

## Phase 5 — Recommendation

The GDD set should advance to Technical Setup / architecture work.

Recommended immediate follow-through:

1. Establish one canonical architecture alias for balance-side ratings versus match-side resolved strength.
2. Extend `design/registry/entities.yaml` to cover the now-active cross-system payload contracts.
3. Carry economy soft-stall feel validation and town-building attractiveness balance into prototype/playtest goals rather than reopening Systems Design.
4. Preserve owner/consumer authority boundaries so placeholder MVP values do not drift across docs during implementation.

## Final Decision

**PASS WITH CONCERNS**

Systems Design may proceed. No remaining issue in this review justifies keeping the project blocked at the GDD cross-review stage.
