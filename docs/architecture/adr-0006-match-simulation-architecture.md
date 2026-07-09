# ADR-0006: Match Simulation Architecture

## Status

Accepted

## Date

2026-05-17

## Last Verified

2026-05-17

## Decision Makers

Technical Director, Godot Specialist, Game Designer

## Summary

The match-competition GDD defines an 8-state match flow, team_match_strength formula aggregation, 5-layer win probability modifiers, half-time tactical adjustment, key event generation with 6 event categories, and a standardized result packet consumed by LeagueStructure/EconomyManager. But no ADR defines: the MatchSimulation engine architecture (state machine, tick loop, RNG strategy), how lineup data flows from PlayerRoster into team strength computation, the event generation algorithm, the serialization contract for mid-match save/load, or the result packet schema. This ADR defines: `MatchSimulation` as a deterministic state machine with seeded RNG, a tick-based event generation pipeline over two halves, a `MatchState` snapshot for SaveManager registration, and a typed `MatchResultPacket` consumed by downstream systems.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core — Match Simulation |
| **Knowledge Risk** | LOW — pure GDScript: state machine, Dictionary math, no engine-specific APIs |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (EventBus signals: `match_event_occurred`, `match_completed`; TimeManager triggers match start), ADR-0003 (SaveManager registration for `serialize()`/`deserialize()`), ADR-0004 (ConfigLoader: `MatchConfig` access), ADR-0005 (PlayerRoster for lineup data) |
| **Enables** | ADR-0007 (EconomyManager consumes match results for settlement), ADR-0009 (LeagueStructure consumes result packets for standings) |
| **Blocks** | Economy settlement implementation — cannot compute post-match finances without match results |
| **Ordering Note** | Must be Accepted before ADR-0007 (Economy) and ADR-0009 (League) can be Accepted |

## Context

### Problem Statement

The match-competition GDD defines 20 core rules, 8 match states, 5 formulas, and 6 event categories. The architecture assigns MatchCompetition as a Core system. But no ADR defines: (1) how the match state machine is implemented — tick loop vs callback chain, (2) how RNG is seeded for deterministic replay, (3) how `team_match_strength` aggregates PlayerRoster data into a single value, (4) how key events are generated from team strengths + modifiers + RNG, (5) the serialization contract for mid-match save/load (Match In Progress is NOT a stable save point per GDD Rule 14, but the SaveManager still needs the serialize/deserialize contract), (6) the `MatchResultPacket` schema consumed by LeagueStructure, EconomyManager, and Post-Match Settlement.

### Constraints

- Godot 4.6 + GDScript — pure computational logic, no rendering
- ~10 matches per season × ~20 seasons in a full save = ~200 match results stored
- Match simulation must be fast — <100ms for a full match (8 ticks × event generation)
- Seeded RNG ensures same input → same output (unit-testable)
- Mid-match save is NOT a stable restore point (GDD Rule 14), but the system must still serialize via `_serialize()`/`_deserialize()`
- Half-time state is a valid adjustment window — player can change tactics affecting second half only

### Requirements

- 8-state match flow per GDD: Entry → Pre-Match → Confirmation → First Half → Halftime → Second Half → Result Review → Settlement
- `team_match_strength` must aggregate all 11 lineup positions + chemistry factor + facility bonus
- Key events must be generated with category, minute, and narrative tags
- `MatchResultPacket` must be a standardized Dictionary consumable by 4 downstream systems
- Match is unit-testable: same seed + same inputs = identical match outcome

## Decision

### Part A: MatchSimulation Class — State Machine

`MatchSimulation` is the engine class that runs one match from Entry to Settlement. It uses a finite state machine advanced by explicit `advance()` calls from match-trigger, player confirmation, halftime input, and settlement handoff events.

```gdscript
# src/core/match_simulation.gd
class_name MatchSimulation
extends Node

enum State {
    IDLE,
    ENTRY,
    PRE_MATCH_PREPARATION,
    CONFIRMATION,
    FIRST_HALF,
    HALFTIME_ADJUSTMENT,
    SECOND_HALF,
    RESULT_REVIEW,
    SETTLEMENT_HANDOFF,
}

var state: State = State.IDLE
var match_data: MatchData
var result_packet: MatchResultPacket
var _rng: RandomNumberGenerator

func _ready() -> void:
    _rng = RandomNumberGenerator.new()
    SaveManager.register_system("match", _serialize, _deserialize)

func start_match(home_roster: PlayerRoster, away_roster: PlayerRoster,
                  context: Dictionary) -> MatchData:
    match_data = MatchData.new()
    match_data.seed = randi()
    _rng.seed = match_data.seed
    match_data.home_team = _build_team_profile(home_roster, context)
    match_data.away_team = _build_team_profile(away_roster, context)
    match_data.home_team_strength = _compute_team_strength(match_data.home_team)
    match_data.away_team_strength = _compute_team_strength(match_data.away_team)
    match_data.base_win_prob = _compute_base_win_prob(match_data)
    state = State.ENTRY
    return match_data

func advance() -> void:
    match state:
        State.ENTRY:
            state = State.PRE_MATCH_PREPARATION
        State.PRE_MATCH_PREPARATION:
            state = State.CONFIRMATION
        State.CONFIRMATION:
            _lock_lineup()
            state = State.FIRST_HALF
            _simulate_half(match_data.first_half, 45)
        State.FIRST_HALF:
            state = State.HALFTIME_ADJUSTMENT
        State.HALFTIME_ADJUSTMENT:
            # Player adjusts tactics here; then advance
            state = State.SECOND_HALF
            _simulate_half(match_data.second_half, 45)
        State.SECOND_HALF:
            _finalize_result()
            state = State.RESULT_REVIEW
        State.RESULT_REVIEW:
            state = State.SETTLEMENT_HANDOFF
            _emit_result()
        State.SETTLEMENT_HANDOFF:
            state = State.IDLE
```

### Part B: Team Profile and Strength

```gdscript
## Aggregated per-position lineup snapshot for match consumption
class TeamProfile:
    var lineup: Array[LineupSlot] = []     # 11 slots
    var tactics: TacticsPlan
    var selected_lineup: PlayerRoster
    var facility_rating_bonus: float = 0.0
    var chemistry_factor: float = 1.0      # Position synergy, 0.85–1.15
    var home_advantage: bool = false


class LineupSlot:
    var player: Player
    var position: String                  # GK, DF, MF, FW
    var positional_rating: float           # Computed from Player.Attributes + position fit
    var lineup_weight: float = 1.0         # Position importance weight

## team_match_strength per GDD formula
func _compute_team_strength(team: TeamProfile) -> float:
    var weighted_sum: float = 0.0
    var weight_sum: float = 0.0
    for slot: LineupSlot in team.lineup:
        slot.positional_rating = _compute_positional_rating(slot.player, slot.position)
        weighted_sum += slot.positional_rating * slot.lineup_weight
        weight_sum += slot.lineup_weight
    var lineup_base: float = (weighted_sum / maxf(weight_sum, 1.0)) * team.chemistry_factor
    return lineup_base + team.facility_rating_bonus
```

### Part C: Win Probability Computation

```gdscript
func _compute_base_win_prob(data: MatchData) -> float:
    var cfg: BalanceConfig = ConfigLoader.balance_config
    var rating_diff: float = data.home_team_strength - data.away_team_strength
    var raw_prob: float = 0.5 + cfg.rating_win_slope * rating_diff
    raw_prob = clampf(raw_prob, cfg.win_probability_floor, cfg.win_probability_ceiling)

    # Apply match-level modifiers
    var home_mod: float = cfg.home_advantage_modifier if data.home_team.home_advantage else 0.0
    var condition_mod: float = _aggregate_condition_mod(data)
    var tactical_mod: float = _compute_tactical_matchup(data)

    var adjusted: float = raw_prob + home_mod + condition_mod + tactical_mod
    return clampf(adjusted, cfg.win_probability_floor, cfg.win_probability_ceiling)
```

### Part D: Event Generation Pipeline

Each half generates events in ticks. The generator walks through the half minute-by-minute, determining at each step whether an event fires based on team strengths, tactical state, and RNG:

```gdscript
func _simulate_half(half: MatchHalf, minutes: int) -> void:
    half.events.clear()
    for minute: int in range(1, minutes + 1):
        _tick_minute(half, minute)
    half.score = _compute_half_score(half)

func _tick_minute(half: MatchHalf, minute: int) -> void:
    var event_base_chance: float = ConfigLoader.match_config.base_event_chance
    var home_attack: float = match_data.home_team_strength * _tactical_attack_mult(true, minute)
    var away_attack: float = match_data.away_team_strength * _tactical_attack_mult(false, minute)

    # Determine possession by relative strength
    var possession_ratio: float = clampf(home_attack / maxf(home_attack + away_attack, 1.0), 0.3, 0.7)
    var attacking_side: bool = _rng.randf() <= possession_ratio  # true = home attacking

    if _rng.randf() < event_base_chance:
        var event: MatchEvent = _generate_event(attacking_side, minute)
        half.events.append(event)
        EventBus.emit("match_event_occurred", event.to_dict())
```

**Event categories** (GDD Core Rule 12):
1. `offensive_push` — attack progression, possession buildup
2. `shot_on_goal` — shot or save
3. `goal_scored` — goal (highest impact)
4. `key_defense` — tackle, interception, clearance
5. `tactical_adaptation` — tactic change takes visible effect
6. `stamina_decline` — player condition drop affects performance

```gdscript
class MatchEvent:
    var category: String = ""
    var minute: int = 0
    var half: int = 1
    var side: bool = true  # true = home
    var players_involved: Array[int] = []
    var narrative_tags: Array[String] = []
    var modifier_flags: Dictionary = {}  # e.g., {is_reversal: true, is_hattrick: false}

    func to_dict() -> Dictionary:
        return {
            category = category,
            minute = minute,
            half = half,
            side = side,
            players_involved = players_involved,
            narrative_tags = narrative_tags,
            modifier_flags = modifier_flags,
        }
```

### Part E: Result Packet

When Second Half completes, `_finalize_result()` produces a `MatchResultPacket`.

If another system consumes MatchCompetition-owned query or packet surfaces through a registered direct-call contract, that system must use an injected stable authority reference supplied by gameplay root or a scene-owned service container/runtime registry. MatchCompetition is a scene-instantiated Core authority, not a Foundation Autoload or implicit global singleton.


```gdscript
class MatchResultPacket:
    var home_score: int = 0
    var away_score: int = 0
    var result: String = ""           # "home_win", "away_win", "draw"
    var events: Array[MatchEvent] = []
    var player_performances: Array[Dictionary] = []  # {player_id, minutes, rating, key_moments}
    var condition_changes: Array[Dictionary] = []     # {player_id, old_condition, new_condition}
    var morale_changes: Array[Dictionary] = []         # {player_id, old_morale, new_morale}
    var win_reasons: Array[String] = []                # Top 3 reasons for outcome
    var match_stats: Dictionary = {}                   # possession, shots, saves, etc.
    var post_match_tags: Array[String] = []            # For LeagueStructure consumption until full implementation

    func to_dict() -> Dictionary: ...
    static func from_dict(data: Dictionary) -> MatchResultPacket: ...
```

`MatchResultPacket` is the authoritative result body, not the full EventBus envelope. `match_completed` must emit the canonical cross-system payload envelope with `match_id`, `settlement_id`, and `result_packet = MatchResultPacket.to_dict()`. `match_id` correlates the result to LeagueStructure schedule authority, while `settlement_id` is the durable settlement identity used by downstream idempotent settlement and save/load replay protection.

**Win reason generation** (GDD Core Rule 17): After the match, `_analyze_result()` produces reasons:
1. "阵容强度差距" — if team strength difference > threshold
2. "错位球员表现不足" — if any player played out of position with low rating
3. "体能不足影响下半场" — if condition decline events dominated
4. "战术克制生效" — if tactical mismatch contributed most
5. "关键事件逆转" — if a single event changed probability materially

### Part F: Half-Time Adjustment

The `HALFTIME_ADJUSTMENT` state allows the player to change tactics and substitute players. The UI displays first-half stats, then the player can modify the tactics plan and swap up to 3 players. Changes only affect the second half:

```gdscript
func apply_halftime_changes(new_tactics: TacticsPlan, substitutions: Array[Dictionary]) -> void:
    assert(state == State.HALFTIME_ADJUSTMENT)
    match_data.second_half_tactics = new_tactics
    for sub: Dictionary in substitutions:
        _substitute_player(sub.out_player_id, sub.in_player_id, match_data.second_half)
```

### Part G: Save/Load Contract

Per GDD Rule 14, `Match In Progress` is NOT a stable restore point. MatchCompetition registers with SaveManager, but its `serialize()` returns the current stable state — if a match is in progress, the save skips the partial state and records only the pre-match data with `state = ENTRY`. On load, the match restarts from the Entry state:

```gdscript
func _serialize() -> Dictionary:
    if state == State.FIRST_HALF or state == State.SECOND_HALF:
        # Mid-match: abandon partial state, restore to pre-match
        return {
            is_active = false,
            pending_context = match_data.context if match_data else {},
        }
    return {
        is_active = state != State.IDLE,
        state = state,
        match_data = match_data.to_dict() if match_data else {},
        result_packet = result_packet.to_dict() if result_packet else null,
    }

func _deserialize(data: Dictionary) -> void:
    if not data.get("is_active", false):
        state = State.IDLE
        return
    state = data.state
    match_data = MatchData.from_dict(data.match_data)
    if data.result_packet != null:
        result_packet = MatchResultPacket.from_dict(data.result_packet)
```

### Part H: RNG Strategy

Each match is seeded with a unique seed derived from `randi()` at match start. The seed is stored in `MatchData.seed` and serialized. This makes every match deterministic for unit testing — same seed + same inputs = same event sequence. The `RandomNumberGenerator` instance is re-seeded at the start of each match.

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                MatchSimulation (Core Node)                │
│  ┌────────────────────────────────────────────────────┐  │
│  │ STATE MACHINE: IDLE → ENTRY → PRE_MATCH →          │  │
│  │  CONFIRMATION → FIRST_HALF → HALFTIME →            │  │
│  │  SECOND_HALF → RESULT_REVIEW → SETTLEMENT → IDLE   │  │
│  │                                                     │  │
│  │ start_match(home_roster, away_roster, ctx) → Data  │  │
│  │ advance() → void                                    │  │
│  │ apply_halftime_changes(tactics, substitutions)      │  │
│  │ _serialize() / _deserialize() (SaveManager)         │  │
│  └────────────┬───────────────────────────────────┬───┘  │
│               │                                   │       │
│  ┌────────────┴──────────────┐   ┌────────────────┴────┐ │
│  │ INPUTS                     │   │ OUTPUTS               │ │
│  │ ┌───────────────────────┐ │   │ ┌──────────────────┐ │ │
│  │ │ PlayerRoster (ADR-5)  │ │   │ │ MatchEvent stream│ │ │
│  │ │ MatchConfig (ADR-4)   │ │   │ │ (via EventBus)   │ │ │
│  │ │ BalanceConfig (ADR-4) │ │   │ │ MatchResultPacket│ │ │
│  │ │ Seeded RNG            │ │   │ │ → LeagueStructure │ │ │
│  │ │ TacticsPlan (player)  │ │   │ │ → EconomyManager │ │ │
│  │ └───────────────────────┘ │   │ │ → TimeManager    │ │ │
│  └───────────────────────────┘   │ │ → MatchPerfUI    │ │ │
│                                  │ └──────────────────┘ │ │
│                                  └─────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative 1: Pure Formula One-Shot

- **Description**: Compute win/loss/draw from team strengths in a single calculation with no event generation
- **Pros**: Simple, fast, zero infrastructure
- **Cons**: Violates GDD Core Rule 12 (must produce key events). No half-time adjustment. No player-visible match narrative. "黑箱掷骰" — the exact experience the GDD forbids.
- **Rejection Reason**: Directly contradicts GDD requirements. The core loop requires match events to generate player feedback and create investment in the outcome.

### Alternative 2: Physics-Based Match Simulation

- **Description**: Simulate ball physics, player movement, and goalkeeper AI per frame
- **Pros**: Realistic match representation, emergent gameplay, player skill matters visibly
- **Cons**: Massive implementation effort (6+ months for a football physics engine). Unnecessary for a management sim where the core loop is "培养 → 比赛反馈 → 再培养". Per-frame simulation would consume >5ms per frame, exceeding performance budget.
- **Rejection Reason**: The GDD explicitly defines this as a management sim with "可观察演算 + 关键反馈", not a real-time sports game. Physics simulation adds months of development with no benefit to the design goals.

### Alternative 3: Single Event-Generator (No State Machine)

- **Description**: A single `generate_match()` function that takes lineups and returns a result packet with events, no explicit state machine
- **Pros**: Simpler API, fewer classes, faster to implement
- **Cons**: No half-time adjustment window — the player's tactical change mid-match is a core GDD requirement. No state tracking for UI to display per-phase progress. Save/load can't distinguish pre-match vs post-match.
- **Rejection Reason**: The half-time adjustment (GDD Core Rule 13) requires explicit state separation between halves. The 8-state machine maps directly to the player-visible match flow and makes UI integration straightforward.

## Consequences

### Positive

- Deterministic matches via seeded RNG — same inputs always produce the same result, enabling unit tests and balance verification
- Explicit state machine maps 1:1 to the GDD match flow — no impedance mismatch between design and code
- Half-time adjustment is a first-class state — tactical changes are cleanly scoped to second half only
- MatchResultPacket is a standardized output contract consumed identically by League, Economy, UI, and TimeManager
- Mid-match save safety: partial state is explicitly abandoned; restore goes to pre-match Entry state

### Negative

- 8-state machine adds complexity vs a simpler compute-and-return function
- Event generation is abstract (narrative tags) rather than physics-based — requires careful balancing to feel "real"
- RNG determinism means same seed always produces same events — replaying a match shows identical events
- Two halves share the same `_simulate_half()` code — special first-half/second-half behaviors (e.g., injury time) require conditional logic within the tick loop

### Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Event generation feels repetitive with fixed seed patterns | Medium | Medium — player boredom | Vary event narrative_tags based on player names, match context, and commentary flavor text |
| `team_match_strength` aggregation hides individual player contributions | Low | Medium — players feel undifferentiated | `player_performances` array in result packet tracks per-player stats; MatchPerfUI can display individual ratings |
| RNG seed collision (two matches with same seed) | Very Low | Very Low — identical matches | 32-bit seed from `randi()` — collision probability < 1/4B per match pair |
| Half-time substitutions cause unbalanced second half | Low | Low | Substitutions capped at 3 per team; substituted-in players' condition_multiplier resets to 1.0 |
| MatchState serialization drops in-progress match data | Low | Low | Intentional design — GDD Rule 14 forbids mid-match save points. UI warns player if they save during a match. |
| `assert()` state guards stripped in release builds | Low | Low | `apply_halftime_changes()` uses `assert()` for state check — no-op in `--release`. Replace with `if state != State.HALFTIME_ADJUSTMENT: push_error(...); return` before production. |
| `match state:` has no wildcard arm for IDLE | Very Low | Low — debug annoyance | Calling `advance()` in IDLE state silently does nothing. Add `_: push_warning("advance() called in IDLE state")` arm for debug visibility. |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `match-competition-system.md` | Core Rule 1: 比赛竞技系统是单场比赛流程的权威来源 | `MatchSimulation` class owns the full 8-state match flow |
| `match-competition-system.md` | Core Rule 7: `positional_overall_rating` 聚合为队伍比赛强度 | `_compute_team_strength()` aggregates 11 `LineupSlot.positional_rating` values with `lineup_weight` and `chemistry_factor` |
| `match-competition-system.md` | Core Rule 11: 比赛演算拆分为多个可解释阶段 | 8-state machine: ENTRY → PRE_MATCH → CONFIRMATION → FIRST_HALF → HALFTIME → SECOND_HALF → RESULT_REVIEW → SETTLEMENT |
| `match-competition-system.md` | Core Rule 12: 比赛过程必须产生可读关键事件 | Event generation pipeline with 6 categories and per-minute dice rolls based on team strengths |
| `match-competition-system.md` | Core Rule 13: 中场调整是正式可用策略窗口 | `HALFTIME_ADJUSTMENT` state with `apply_halftime_changes()` — changes only affect second half |
| `match-competition-system.md` | Core Rule 14: Match In Progress 不是标准可恢复存档点 | `_serialize()` abandons partial state during FIRST_HALF/SECOND_HALF; restores to ENTRY on load |
| `match-competition-system.md` | Core Rule 15: 终场结果必须立刻成为权威结果包 | `MatchResultPacket` class with score, events, performances, morale/condition changes, and win reasons |
| `match-competition-system.md` | Core Rule 17: 比赛反馈必须支持复盘 | `_analyze_result()` produces `win_reasons: Array[String]` with top 3 causes |
| `match-competition-system.md` | Formula 1: `team_match_strength` | Implemented in `_compute_team_strength()` — weighted sum with chemistry factor + facility bonus |
| `balance-system.md` | Formula: `base_win_probability` with `rating_win_slope` | `_compute_base_win_prob()` applies rating difference + home/tactical/condition modifiers with floor/ceiling clamping |

## Performance Implications

- **CPU**: Match simulation is compute-only (no rendering). Full match: ~90 ticks (45+45 minutes) × event generation = <10ms. Event generation per minute: ~5-10 float comparisons + RNG calls. Total per match: <20ms.
- **Memory**: `MatchData` + `MatchResultPacket` + event arrays: ~5KB per match. In-memory only during active match; freed after SETTLEMENT. Stored results: ~200 matches × 2KB = ~400KB.
- **Load Time**: Deserializing a saved MatchState: <1ms. Result packet consumed as Dictionary by downstream systems.
- **Network**: Not applicable — single-player.

## Migration Plan

Not applicable — no existing match simulation system. This is the first implementation.

## Validation Criteria

- [ ] `MatchSimulation.start_match()` initializes state to ENTRY with computed team strengths
- [ ] `_compute_team_strength()` returns a value in range [0, 100] for a default lineup
- [ ] Same seed + same inputs produces identical event sequence across 3 invocations
- [ ] `advance()` walks through all 8 states and reaches IDLE after SETTLEMENT
- [ ] `_simulate_half()` generates events for every minute; each event has a valid category and minute
- [ ] Half-time substitution changes are reflected in second half but NOT in first half events
- [ ] `_serialize()` during FIRST_HALF returns `{is_active = false, pending_context = {...}}` — no partial match state
- [ ] `MatchResultPacket.to_dict()` roundtrip preserves all fields
- [ ] `_analyze_result()` produces at least 1 win_reason when team strength difference > 10
- [ ] `match_completed` signal is emitted with the canonical envelope `{match_id, settlement_id, result_packet = MatchResultPacket.to_dict()}` on reaching SETTLEMENT
- [ ] `match_event_occurred` signal fires for each generated event with category, minute, side, and narrative_tags

## Related

- ADR-0002: Event/Signal Architecture — defines `match_event_occurred`, `match_completed` signals
- ADR-0003: Save/Load Persistence — MatchCompetition registers `serialize()`/`deserialize()` with SaveManager
- ADR-0004: Data-Driven Configuration — MatchConfig and BalanceConfig provide simulation parameters
- ADR-0005: Player Data Model — PlayerRoster provides lineup data for team strength computation
- ADR-0007: Economy Transaction Framework — consumes MatchResultPacket for post-match settlement
- ADR-0009: League Competition Structure — consumes MatchResultPacket for standings computation
- `design/gdd/match-competition-system.md` — authoritative design for match flow and formulas
- `design/gdd/balance-system.md` — authoritative design for shared formulas
