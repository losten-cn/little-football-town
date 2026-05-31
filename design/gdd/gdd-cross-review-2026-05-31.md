# Cross-GDD Review — 2026-05-31

**Scope:** `/review-all-gdds` full pass across MVP/Core GDDs  
**Engine Context:** Godot 4.6 / GDScript  
**Review Mode:** Full cross-document consistency + holistic design pass  
**Verdict:** FAIL

## Summary

The core loop of **训练 → 比赛 → 反馈 → 再培养** is visible and mostly coherent, but the current GDD set is not ready to serve as a stable implementation baseline. The main blockers are inconsistent MVP boundaries, stale dependency ownership in `systems-index.md`, and undefined fallback rules for forced match progression when the player lacks legal resources or lineup state.

Before advancing architecture or production planning from these documents, resolve the blocker items below or explicitly accept the risks with updated GDD language.

## Documents Reviewed

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

## Registry Baseline

`design/registry/entities.yaml` currently has no entity/item/constant entries, but does register active authoritative formulas including:

- `effective_attribute_value`
- `attribute_growth`
- `resource_settlement`
- `positional_overall_rating`
- `base_win_probability`
- time progression formulas
- `training_actual_gain`
- `player_tier_potential_band`

The review treats those registered formulas as the current shared authority.

## Phase 2 — Cross-GDD Consistency

**Verdict:** FAIL

### BLOCKER — `systems-index.md` no longer matches real dependencies or MVP boundaries

**Files involved:**

- `design/gdd/systems-index.md`
- `design/gdd/town-building-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/league-competition-structure-system.md`

**Issue:**  
The systems index still treats the town-building system as Alpha in places, while multiple MVP/Core systems consume town-building outputs as hard upstream inputs. The index also contains dependency directions that do not match the actual GDD relationships, such as UI being listed as an upstream dependency for systems that are actually consumed by UI.

**Recommendation:**  
Update `systems-index.md` as the single authoritative dependency map. Choose one of these approaches:

1. Promote the minimum town-building slice to MVP and make its dependencies explicit; or
2. Downgrade town-building effects in MVP docs to fixed defaults or soft dependencies.

### BLOCKER — Town-building defines core outputs without complete downstream consumers

**Files involved:**

- `design/gdd/town-building-system.md`
- `design/gdd/player-development-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/match-competition-system.md`

**Issue:**  
Town-building defines outputs such as `potential_floor_boost`, `adj_youth_potential_boost`, `injury_recovery_reduction`, and `training_injury_prob_multiplier`, but downstream GDDs do not fully define the corresponding recruitment, injury probability, recovery, UI, save, or acceptance-criteria contracts.

**Recommendation:**  
Either defer those outputs to Alpha or add formal downstream interfaces, formulas, state fields, UI expectations, save boundaries, and acceptance criteria.

### BLOCKER — Forced match progression can conflict with illegal match state

**Files involved:**

- `design/gdd/match-competition-system.md`
- `design/gdd/time-and-season-progression-system.md`
- `design/gdd/league-competition-structure-system.md`
- `design/gdd/onboarding-system.md`

**Issue:**  
The time and league systems require scheduled matches to resolve, but the match system can reject match start if the lineup is illegal. The GDDs do not define whether the result should be an automatic loss, delayed match, forced fill-in, emergency youth replacement, or another fallback.

**Recommendation:**  
Add a single authoritative fallback rule and reference it from time, league, match, and onboarding GDDs.

### WARNING — Training UI return path conflicts across documents

**Files involved:**

- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/player-management-ui.md`

**Issue:**  
The main-loop UI says completed or cancelled actions return to Home, while player-management UI says cancelling training from Player Detail returns to Player Detail.

**Recommendation:**  
Define navigation return contracts by entry context: Home-launched flows return Home; contextual subflows return to the caller screen.

### WARNING — Home advantage cap has stale wording

**Files involved:**

- `design/gdd/town-building-system.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/balance-system.md`

**Issue:**  
Town-building formulas and match downstream ranges support a combined facility/home advantage up to 15, but one town-building edge-case statement describes a `clamp(0, 5)` cap.

**Recommendation:**  
Remove or correct the stale `0–5` wording and keep a single shared range.

### WARNING — Training ROI time opportunity cost lacks ownership

**Files involved:**

- `design/gdd/player-development-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/time-and-season-progression-system.md`

**Issue:**  
`weighted_total_training_cost` uses `time_cost_slots`, while examples apply an implied conversion such as `time_cost_slots × 5`. The conversion rate is not owned by a system.

**Recommendation:**  
Define an explicit tuning knob such as `time_slot_to_funds_weight` and assign ownership to economy or time progression.

### WARNING — System status records are stale

**Files involved:**

- `design/gdd/systems-index.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/match-performance-ui.md`

**Issue:**  
The systems enumeration still marks some UI systems as Not Started even though the GDD files and tracker indicate Designed.

**Recommendation:**  
Synchronize enumeration status, progress tracker status, and actual GDD file state.

### INFO — Planned references remain in the concept document

**Files involved:**

- `design/gdd/game-concept.md`

**Issue:**  
The concept document references planned future systems such as reputation/achievement, random events, audio, and future ADRs.

**Recommendation:**  
Keep these references if they are intentional, but label them as planned/not-authored where needed.

### INFO — Stable node terminology can be tightened

**Files involved:**

- `design/gdd/save-and-load-system.md`
- `design/gdd/time-and-season-progression-system.md`

**Issue:**  
The save system defines a wider stable node set than some time-system examples mention.

**Recommendation:**  
Have the time system explicitly reference the save system's complete stable node set.

## Phase 3 — Holistic Design Review

**Verdict:** CONCERNS

### BLOCKER — MVP boundary is unstable around economy and town-building

**Files involved:**

- `design/gdd/systems-index.md`
- `design/gdd/game-concept.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/player-development-system.md`
- `design/gdd/match-competition-system.md`

**Issue:**  
The current GDD set does not clearly answer whether MVP includes a real economy/town-building loop or only consumes fixed defaults from those systems. This affects core loop scope, UI scope, onboarding, formulas, and acceptance criteria.

**Recommendation:**  
Lock one MVP baseline:

- MVP is a team-management loop, with town-building variables fixed to `1.0` or `0`; or
- MVP includes a minimal town-building slice, promoted consistently across index, UI, onboarding, formulas, and tests.

### BLOCKER — Match day AP deadlock risk

**Files involved:**

- `design/gdd/time-and-season-progression-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/match-competition-system.md`

**Issue:**  
A player can potentially spend AP before a required match node, then reach a state where the match must start but the match action is unaffordable.

**Recommendation:**  
Define one hard rule: reserve match AP, auto-refill minimum match AP, allow a rest action at match trigger, or allow controlled match postponement.

### WARNING — Research points are a hidden resource in MVP

**Files involved:**

- `design/gdd/game-concept.md`
- `design/gdd/balance-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/onboarding-system.md`

**Issue:**  
The concept and balance docs treat funds, research points, and AP as core resources, but MVP UI hides research points and provides no sink.

**Recommendation:**  
Either define MVP as a two-resource loop or add one small RP sink and display path.

### WARNING — Town-building risks becoming an optimization grid rather than a warm town fantasy

**Files involved:**

- `design/gdd/game-concept.md`
- `design/gdd/town-building-system.md`

**Issue:**  
The town-building GDD is dominated by adjacency, multipliers, maintenance, and rebuild cost. This supports optimization but under-serves the pillar of a pixel town players want to live in.

**Recommendation:**  
Add a non-numeric identity layer such as visible town milestones, cozy facility presentation, identity choices, or soft rewards that preserve warm-town fantasy.

### WARNING — Youth academy plus training ground may become a dominant long-term strategy

**Files involved:**

- `design/gdd/player-development-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/league-competition-structure-system.md`

**Issue:**  
Youth academy and training ground bonuses can stack across recruitment quality, training growth, adjacency growth, and match strength. This creates a likely low-risk snowball route.

**Recommendation:**  
Separate recruitment advantage from training advantage, make overlapping bonuses non-multiplicative, or add meaningful opportunity cost.

### WARNING — Maintenance can create low-pressure fantasy tension

**Files involved:**

- `design/gdd/economy-management-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/league-competition-structure-system.md`

**Issue:**  
High maintenance plus poor results can create a soft-stall state: the player is not bankrupt, but lacks enough funds to recover comfortably.

**Recommendation:**  
Add recovery valves such as minimum subsidy, maintenance relief, partial demolish refund, relegation safety payment, or early-season maintenance discount.

### WARNING — League team count range can exceed time pacing goals

**Files involved:**

- `design/gdd/time-and-season-progression-system.md`
- `design/gdd/league-competition-structure-system.md`

**Issue:**  
A 16–20 team double round-robin can exceed the intended season pacing and create repetitive long seasons.

**Recommendation:**  
Set MVP/Alpha team count to 8–12 and reserve higher counts for later expansion.

### WARNING — Home advantage may be injected twice

**Files involved:**

- `design/gdd/town-building-system.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/balance-system.md`

**Issue:**  
Stadium/town-building can affect `team_match_strength`, while match formulas also have `home_advantage_mod`. This can double-count home advantage if not separated.

**Recommendation:**  
Assign home advantage to either the strength layer or probability-modifier layer, or make one of them cosmetic/explanatory.

### WARNING — Pre-match attention budget may exceed 3–4 active systems

**Files involved:**

- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/match-performance-ui.md`
- `design/gdd/town-building-system.md`

**Issue:**  
Before a match, the player may need to consider training targets, AP reserve, funds, lineup, tactics, and construction. This risks cognitive overload.

**Recommendation:**  
Stage decisions by game phase: training/resource planning during normal days, lineup/tactics on match day, construction after settlement or stage transitions.

### INFO — Save/load and time stable-node design supports low-pressure play

**Files involved:**

- `design/gdd/save-and-load-system.md`
- `design/gdd/time-and-season-progression-system.md`

**Issue:**  
No major concern. Stable nodes, atomic match resolution, and non-recoverable match-in-progress state support player trust.

**Recommendation:**  
Preserve this boundary when implementing save/load.

### INFO — Match result feedback loop is coherent

**Files involved:**

- `design/gdd/match-competition-system.md`
- `design/gdd/match-performance-ui.md`
- `design/gdd/player-management-ui.md`

**Issue:**  
The match flow supports readable pre-match expectations, event feedback, result review, and return to player-growth decisions.

**Recommendation:**  
Protect this feedback chain from later scope additions.

## Phase 4 — Cross-System Scenario Walkthroughs

### BLOCKER — Match day with insufficient AP can hard-lock the loop

**Trigger:** Player spends AP before a scheduled match.  
**Activation order:** Time reaches match trigger → UI prioritizes match entry → economy says action is unaffordable → match cannot begin.  
**Failure mode:** Forced progression conflicts with resource affordability.  
**Recommendation:** Define an explicit escape rule before implementation.

### WARNING — First 30 minutes may feel like a team-manager prototype, not a football town

**Trigger:** New player completes Home → Roster → Training → Match → Result.  
**Activation order:** UI/onboarding expose roster, training, match, and result, but town-building may remain invisible.  
**Failure mode:** The town fantasy is not established early.  
**Recommendation:** Add a minimal town touchpoint early, even if the full construction loop is deferred.

### WARNING — Youth academy plus training ground snowball can dominate

**Trigger:** Player prioritizes youth academy and training ground adjacency.  
**Activation order:** Better recruitment floor → faster young player growth → stronger match performance → more resources → faster upgrades.  
**Failure mode:** A single build path can dominate long-term strategy.  
**Recommendation:** Split bonuses or add opportunity cost.

### WARNING — Overbuilding plus poor results can cause soft stagnation

**Trigger:** Player upgrades facilities aggressively, then loses multiple matches.  
**Activation order:** Maintenance drains funds → training/build actions become unaffordable → weaker performance continues.  
**Failure mode:** Low-pressure game becomes hard to recover from.  
**Recommendation:** Add recoverability valves.

## Flagged GDDs

Highest priority files to revise:

1. `design/gdd/systems-index.md`
2. `design/gdd/time-and-season-progression-system.md`
3. `design/gdd/match-competition-system.md`
4. `design/gdd/economy-management-system.md`
5. `design/gdd/town-building-system.md`
6. `design/gdd/player-development-system.md`
7. `design/gdd/main-loop-ui-framework.md`
8. `design/gdd/onboarding-system.md`

## Recommended Resolution Order

1. Decide whether MVP includes a minimum town-building slice.
2. Update `systems-index.md` to match that decision.
3. Define match-trigger fallback rules for insufficient AP and illegal lineup.
4. Normalize town-building outputs: keep only consumed MVP outputs or add downstream contracts.
5. Fix stale formula/range wording for home advantage.
6. Define ownership for time opportunity cost in training ROI.
7. Decide whether research points are hidden/deferred or given an MVP sink.
8. Re-run `/review-all-gdds` after edits.

## Gate Impact

This report should block Systems Design → Technical Setup until the blocker findings are resolved or explicitly accepted. The current documents are strong enough to show the intended game shape, but not yet stable enough to be used as architecture authority without carrying contradictory requirements forward.
