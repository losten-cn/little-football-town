# ADR-0009: League Competition Structure

## Status

Accepted

## Date

2026-05-17

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core — League Competition Structure |
| **Knowledge Risk** | LOW — pure GDScript math, array sorting, round-robin algorithm; no engine-specific APIs |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (EventBus signals: subscribes to `match_completed`, `time_season_ended`; emits `league_standings_updated`, `league_season_completed`, `league_season_started`), ADR-0003 (SaveManager registration), ADR-0004 (LeagueConfig via ConfigLoader), ADR-0006 (MatchResultPacket for standings updates), ADR-0007 (EconomyManager for prize money settlement) |
| **Enables** | EconomyManager (consumes promotion/relegation tags for season rewards), MainLoopUI (standings/schedule display), MatchCompetition (opponent generation via strength bands) |
| **Blocks** | League standings UI, season progression loop — cannot display or advance without this ADR |
| **Ordering Note** | Last Core ADR. All Foundation ADRs (0001-0004) + all upstream Core ADRs (0005-0008) must be Accepted before this can be implemented. |

## Context

### Problem Statement

The league-competition-structure GDD defines a 2+ tier league chain, double round-robin scheduling, 3/1/0 point system, promotion/relegation mechanics, tiebreakers, season settlement, and multi-season career history. But no ADR defines: (1) the StandingsEntry/ScheduledMatch/LeagueSeason class structure, (2) the round-robin schedule generation algorithm, (3) how match results flow into standings updates, (4) the promotion/relegation determination logic, (5) the serialization contract for season state and history.

### Constraints

- Godot 4.6 + GDScript — pure data structures and math
- MVP: 2 league tiers (extensible to N via LeagueConfig)
- Double round-robin (home/away) per season
- Points: win=3, draw=1, loss=0
- Tiebreakers: points → goal difference → goals scored → head-to-head; if MVP implementation does not materialize a full head-to-head matrix, internal ordering falls back to a stable deterministic key while presentation may still display tied placement semantics
- Opponents are abstract team entities (no full player rosters in MVP)
- Season schedule generated at season start, fixed for entire season
- Season history capped at configurable retention count

### Requirements

- `match_completed` event drives standings updates — one result per scheduled match
- Season settlement triggered by `time_season_ended` → finalizes standings → determines promotion/relegation
- Next season starts at the correct tier based on prior season outcome
- Standings sort deterministically using the documented tiebreak chain; when MVP stops short of full head-to-head resolution, internal ordering uses a stable fallback key
- Full serialization of season state and capped history

## Decision

### Part A: StandingsEntry

```gdscript
# src/core/standings_entry.gd
class_name StandingsEntry
extends RefCounted

var team_id: int = 0
var team_name: String = ""
var played: int = 0
var wins: int = 0
var draws: int = 0
var losses: int = 0
var goals_for: int = 0
var goals_against: int = 0
var goal_difference: int = 0
var points: int = 0

func record_result(goals_scored: int, goals_conceded: int, result: String) -> void:
    played += 1
    goals_for += goals_scored
    goals_against += goals_conceded
    goal_difference = goals_for - goals_against
    match result:
        "win":  wins += 1; points += 3
        "draw": draws += 1; points += 1
        "loss": losses += 1

func to_dict() -> Dictionary:
    return {
        team_id = team_id, team_name = team_name,
        played = played, wins = wins, draws = draws, losses = losses,
        goals_for = goals_for, goals_against = goals_against,
        goal_difference = goal_difference, points = points,
    }

static func from_dict(data: Dictionary) -> StandingsEntry:
    var e := StandingsEntry.new()
    e.team_id = data.get("team_id", 0); e.team_name = data.get("team_name", "")
    e.played = data.get("played", 0); e.wins = data.get("wins", 0)
    e.draws = data.get("draws", 0); e.losses = data.get("losses", 0)
    e.goals_for = data.get("goals_for", 0); e.goals_against = data.get("goals_against", 0)
    e.goal_difference = data.get("goal_difference", 0); e.points = data.get("points", 0)
    return e
```

### Part B: ScheduledMatch

```gdscript
# src/core/scheduled_match.gd
class_name ScheduledMatch
extends RefCounted

var match_id: int = 0
var round: int = 0
var home_team_id: int = 0
var away_team_id: int = 0
var is_player_team_home: bool = false
var is_completed: bool = false
var home_score: int = 0
var away_score: int = 0
var result: String = ""  # "win", "draw", "loss" — from player perspective

func apply_result(home_score_val: int, away_score_val: int, result_val: String) -> void:
    home_score = home_score_val
    away_score = away_score_val
    result = result_val
    is_completed = true

func to_dict() -> Dictionary:
    return {
        match_id = match_id, round = round,
        home_team_id = home_team_id, away_team_id = away_team_id,
        is_player_team_home = is_player_team_home, is_completed = is_completed,
        home_score = home_score, away_score = away_score, result = result,
    }

static func from_dict(data: Dictionary) -> ScheduledMatch:
    var m := ScheduledMatch.new()
    m.match_id = data.get("match_id", 0); m.round = data.get("round", 0)
    m.home_team_id = data.get("home_team_id", 0); m.away_team_id = data.get("away_team_id", 0)
    m.is_player_team_home = data.get("is_player_team_home", false)
    m.is_completed = data.get("is_completed", false)
    m.home_score = data.get("home_score", 0); m.away_score = data.get("away_score", 0)
    m.result = data.get("result", "")
    return m
```

### Part C: LeagueSeason

```gdscript
# src/core/league_season.gd
class_name LeagueSeason
extends RefCounted

enum State { PRE_SEASON, IN_PROGRESS, SETTLEMENT, COMPLETED }

var season_number: int = 0
var tier: int = 0
var tier_name: String = ""
var team_count: int = 8
var promotion_slots: int = 2
var relegation_slots: int = 2
var state: State = State.PRE_SEASON
var standings: Array[StandingsEntry] = []
var schedule: Array[ScheduledMatch] = []
var player_team_id: int = 0

func get_standings_sorted() -> Array[StandingsEntry]:
    var sorted := standings.duplicate()
    sorted.sort_custom(_compare_standings)
    return sorted

func _compare_standings(a: StandingsEntry, b: StandingsEntry) -> bool:
    if a.points != b.points: return a.points > b.points
    if a.goal_difference != b.goal_difference: return a.goal_difference > b.goal_difference
    if a.goals_for != b.goals_for: return a.goals_for > b.goals_for
    # Head-to-head comparison for tied teams:
    # MVP does not maintain a full H2H matrix yet. Internal ordering therefore
    # falls back to team_id for deterministic storage and UI refresh stability.
    # If presentation needs true "tied placement" semantics, the display layer
    # must derive that explicitly instead of relying on array order alone.
    return a.team_id < b.team_id

func get_player_rank() -> int:
    var sorted := get_standings_sorted()
    for i in range(sorted.size()):
        if sorted[i].team_id == player_team_id:
            return i + 1
    return -1

func is_promotion_zone(tier_count: int) -> bool:
    return get_player_rank() <= promotion_slots and tier > 1

func is_relegation_zone(tier_count: int) -> bool:
    return get_player_rank() > (team_count - relegation_slots) and tier < tier_count

func generate_schedule(teams: Array[int]) -> void:
    var n: int = teams.size()
    schedule.clear()
    var match_id_counter: int = 1
    for round in range(1, 2 * (n - 1) + 1):
        var pairings: Array[Dictionary] = _round_robin_pairings(teams, round, n)
        for pair: Dictionary in pairings:
            var m := ScheduledMatch.new()
            m.match_id = match_id_counter; match_id_counter += 1
            m.round = round
            m.home_team_id = pair.home; m.away_team_id = pair.away
            m.is_player_team_home = (pair.home == player_team_id)
            schedule.append(m)

## Circle method for balanced round-robin schedule
func _round_robin_pairings(teams: Array[int], round: int, n: int) -> Array[Dictionary]:
    var pairings: Array[Dictionary] = []
    var half: int = n / 2

    # Build rotated team order for this round
    var rotated: Array[int] = teams.duplicate()
    if round > 1:
        var shift: int = (round - 1) % (n - 1)
        var others: Array[int] = []
        for i in range(1, n):
            others.append(teams[i])
        for _j in range(shift):
            var last := others.pop_back()
            others.insert(0, last)
        rotated = [teams[0]]
        rotated.append_array(others)

    for i in range(half):
        var home := rotated[i]
        var away := rotated[n - 1 - i]
        # First half of season: low-index home; second half: swap
        if round > n - 1:
            var temp := home; home = away; away = temp
        pairings.append({home = home, away = away})

    return pairings
```

### Part D: LeagueStructure Core System Node

```gdscript
# src/core/league_structure.gd
class_name LeagueStructure
extends Node

var current_season: LeagueSeason = null
var _season_history: Array[Dictionary] = []
var _next_match_index: int = 0

func _ready() -> void:
    SaveManager.register_system("league", _serialize, _deserialize)
    EventBus.subscribe("match_completed", _on_match_completed)
    EventBus.subscribe("time_season_ended", _on_season_ended)

func start_new_season(tier: int, team_name: String, is_fresh_start: bool) -> void:
    var cfg: LeagueConfig = ConfigLoader.league_config
    var tier_count: int = cfg.tier_names.size()
    var season := LeagueSeason.new()
    season.season_number = (current_season.season_number + 1) if current_season and not is_fresh_start else 1
    season.tier = tier
    season.tier_name = cfg.tier_names[tier - 1] if tier <= tier_count else "Tier %d" % tier
    season.team_count = cfg.team_count[tier - 1]
    season.promotion_slots = cfg.promotion_slots[tier - 1]
    season.relegation_slots = cfg.relegation_slots[tier - 1]
    season.state = LeagueSeason.State.PRE_SEASON
    season.player_team_id = 0

    # Generate opponent teams (player = ID 0, opponents = 1..N-1)
    var teams: Array[int] = [0]
    for i in range(1, season.team_count):
        teams.append(i)

    # Create standings entries
    for tid: int in teams:
        var entry := StandingsEntry.new()
        entry.team_id = tid
        entry.team_name = team_name if tid == 0 else _generate_opponent_name(tier, tid)
        season.standings.append(entry)

    season.generate_schedule(teams)
    season.state = LeagueSeason.State.IN_PROGRESS
    current_season = season

    EventBus.emit("league_season_started", {
        season_number = season.season_number, tier = season.tier,
        tier_name = season.tier_name, team_count = season.team_count,
    })

func _on_match_completed(payload: Dictionary) -> void:
    if current_season == null or current_season.state != LeagueSeason.State.IN_PROGRESS:
        return

    # match_id is included in the match_completed EventBus payload
    # alongside result_packet (per ADR-0006 integration contract)
    var completed_match_id: int = payload.get("match_id", -1)
    var result: Dictionary = payload.result_packet

    for match: ScheduledMatch in current_season.schedule:
        if match.match_id == completed_match_id and not match.is_completed:
            match.apply_result(result.home_score, result.away_score, result.result)

            _update_standings_for_match(match, result)
            EventBus.emit("league_standings_updated", {
                season_number = current_season.season_number,
                standings = current_season.get_standings_sorted(),
            })
            break

func _update_standings_for_match(match: ScheduledMatch, result: Dictionary) -> void:
    var home_entry := _find_standing(match.home_team_id)
    var away_entry := _find_standing(match.away_team_id)

    if home_entry:
        if result.home_score > result.away_score:
            home_entry.record_result(result.home_score, result.away_score, "win")
        elif result.home_score == result.away_score:
            home_entry.record_result(result.home_score, result.away_score, "draw")
        else:
            home_entry.record_result(result.home_score, result.away_score, "loss")

    if away_entry:
        if result.away_score > result.home_score:
            away_entry.record_result(result.away_score, result.home_score, "win")
        elif result.away_score == result.home_score:
            away_entry.record_result(result.away_score, result.home_score, "draw")
        else:
            away_entry.record_result(result.away_score, result.home_score, "loss")

func _on_season_ended(payload: Dictionary) -> void:
    if current_season == null:
        return
    current_season.state = LeagueSeason.State.SETTLEMENT

    var cfg: LeagueConfig = ConfigLoader.league_config
    var tier_count: int = cfg.tier_names.size()
    var player_rank := current_season.get_player_rank()
    var promoted := current_season.is_promotion_zone(tier_count)
    var relegated := current_season.is_relegation_zone(tier_count)

    # Determine next tier
    var next_tier: int = current_season.tier
    if promoted and current_season.tier > 1:
        next_tier = current_season.tier - 1
    elif relegated and current_season.tier < tier_count:
        next_tier = current_season.tier + 1

    # Store season summary
    var player_entry := _find_standing(0)
    var summary := {
        season_number = current_season.season_number,
        tier = current_season.tier, tier_name = current_season.tier_name,
        player_rank = player_rank, total_teams = current_season.team_count,
        points = player_entry.points if player_entry else 0,
        goals_for = player_entry.goals_for if player_entry else 0,
        goals_against = player_entry.goals_against if player_entry else 0,
        promoted = promoted, relegated = relegated, next_tier = next_tier,
    }
    _season_history.append(summary)

    # Cap history per config
    var retention: int = cfg.historical_season_retention
    while _season_history.size() > retention:
        _season_history.pop_front()

    current_season.state = LeagueSeason.State.COMPLETED

    EventBus.emit("league_season_completed", {
        season_number = current_season.season_number,
        tier = current_season.tier, player_rank = player_rank,
        points = summary.points, promoted = promoted, relegated = relegated,
        next_tier = next_tier, summary = summary,
    })

## Public read-only interface for downstream systems

func get_standings() -> Array[StandingsEntry]:
    if current_season == null:
        return []
    return current_season.get_standings_sorted()

func get_player_rank() -> int:
    if current_season == null:
        return -1
    return current_season.get_player_rank()

func get_upcoming_matches(count: int = 3) -> Array[ScheduledMatch]:
    var upcoming: Array[ScheduledMatch] = []
    if current_season == null:
        return upcoming
    for match: ScheduledMatch in current_season.schedule:
        if not match.is_completed:
            upcoming.append(match)
            if upcoming.size() >= count:
                break
    return upcoming

func get_season_progress() -> Dictionary:
    if current_season == null:
        return {completed = 0, total = 0, progress = 0.0}
    var total: int = current_season.schedule.size()
    var completed: int = 0
    for match: ScheduledMatch in current_season.schedule:
        if match.is_completed:
            completed += 1
    return {completed = completed, total = total, progress = float(completed) / float(total)}

func get_season_history() -> Array[Dictionary]:
    return _season_history

func _find_standing(team_id: int) -> StandingsEntry:
    if current_season == null:
        return null
    for entry: StandingsEntry in current_season.standings:
        if entry.team_id == team_id:
            return entry
    return null

func _generate_opponent_name(tier: int, team_id: int) -> String:
    var prefixes: Array[String] = ConfigLoader.league_config.opponent_name_prefixes
    var suffixes: Array[String] = ConfigLoader.league_config.opponent_name_suffixes
    var idx: int = (tier * 100 + team_id) % prefixes.size()
    var suffix_idx: int = team_id % suffixes.size()
    return "%s %s" % [prefixes[idx], suffixes[suffix_idx]]
```

### Part E: Serialization Contract

```gdscript
func _serialize() -> Dictionary:
    if current_season == null:
        return {current_season = null, season_history = []}

    var schedule_data: Array[Dictionary] = []
    for m: ScheduledMatch in current_season.schedule:
        schedule_data.append(m.to_dict())

    var standings_data: Array[Dictionary] = []
    for e: StandingsEntry in current_season.standings:
        standings_data.append(e.to_dict())

    return {
        current_season = {
            season_number = current_season.season_number,
            tier = current_season.tier, tier_name = current_season.tier_name,
            team_count = current_season.team_count,
            promotion_slots = current_season.promotion_slots,
            relegation_slots = current_season.relegation_slots,
            state = current_season.state, player_team_id = current_season.player_team_id,
            standings = standings_data, schedule = schedule_data,
            next_match_index = _next_match_index,
        },
        season_history = _season_history,
    }

func _deserialize(data: Dictionary) -> void:
    _season_history.clear()
    for entry: Dictionary in data.get("season_history", []):
        _season_history.append(entry)

    var cs_data: Dictionary = data.get("current_season", {})
    if cs_data.is_empty():
        current_season = null
        return

    var season := LeagueSeason.new()
    season.season_number = cs_data.get("season_number", 0)
    season.tier = cs_data.get("tier", 1)
    season.tier_name = cs_data.get("tier_name", "")
    season.team_count = cs_data.get("team_count", 8)
    season.promotion_slots = cs_data.get("promotion_slots", 2)
    season.relegation_slots = cs_data.get("relegation_slots", 2)
    season.state = cs_data.get("state", LeagueSeason.State.PRE_SEASON)
    season.player_team_id = cs_data.get("player_team_id", 0)
    _next_match_index = cs_data.get("next_match_index", 0)

    for entry: Dictionary in cs_data.get("standings", []):
        season.standings.append(StandingsEntry.from_dict(entry))
    for entry: Dictionary in cs_data.get("schedule", []):
        season.schedule.append(ScheduledMatch.from_dict(entry))

    current_season = season
```

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                 LeagueStructure (Core System Node)                │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ current_season: LeagueSeason                                │  │
│  │   ├── standings: Array[StandingsEntry]  (N teams)           │  │
│  │   ├── schedule: Array[ScheduledMatch]   (2×(N-1) rounds)   │  │
│  │   ├── tier, promotion_slots, relegation_slots               │  │
│  │   └── state: PRE_SEASON → IN_PROGRESS → SETTLEMENT → DONE  │  │
│  │                                                             │  │
│  │ _season_history: Array[Dictionary]  (last N seasons)        │  │
│  └────────────┬───────────────────────────────┬───────────────┘  │
│               │                               │                   │
│  ┌────────────┴──────────────┐   ┌────────────┴──────────────┐  │
│  │ EVENTBUS IN (subscribes)   │   │ EVENTBUS OUT (emits)       │  │
│  │ match_completed            │   │ league_standings_updated   │  │
│  │ time_season_ended          │   │ league_season_completed    │  │
│  └───────────────────────────┘   │ league_season_started      │  │
│                                   └───────────────────────────┘  │
│                                                                   │
│  PUBLIC READ-ONLY INTERFACE                                       │
│    get_standings() → Array[StandingsEntry]                       │
│    get_player_rank() → int                                       │
│    get_upcoming_matches(count) → Array[ScheduledMatch]           │
│    get_season_progress() → {completed, total, progress}          │
│    get_season_history() → Array[Dictionary]                      │
│                                                                   │
│  DOWNSTREAM CONSUMERS                                             │
│    MatchCompetition ← upcoming opponent data for match generation│
│    MainLoopUI       ← standings, schedule, progress, history     │
│    EconomyManager   ← season_completed summary for prize calc    │
└──────────────────────────────────────────────────────────────────┘
```

### EventBus Contract Note

The `match_completed` EventBus signal payload must include `match_id` to allow LeagueStructure to correlate results with scheduled matches. ADR-0006's MatchCompetition emits this signal with the following contract:

```
EventBus.emit("match_completed", {
    match_id = match_id,           # int — correlates to ScheduledMatch.match_id
    result_packet = result_packet, # Dictionary — MatchResultPacket.to_dict()
})
```

This is an additive field to the ADR-0002/ADR-0006 contract — does not change existing payload fields.

## Alternatives Considered

### Alternative 1: Dictionary-Based League State

- **Description**: Standings, schedule, and season data stored as nested Dictionaries instead of typed classes
- **Pros**: No class definitions needed, flexible schema, fast prototyping
- **Cons**: No type checking from GDScript compiler. Every access is string-keyed (typo-prone). Harder to reason about at scale. Violates project coding standards (untyped Dictionary forbidden).
- **Rejection Reason**: Typed RefCounted classes provide compiler-verified field access, clear serialization contracts, and consistency with Player (ADR-0005), Facility (ADR-0008), and Transaction (ADR-0007).

### Alternative 2: LeagueSeason as Resource

- **Description**: LeagueSeason extends Resource with @export var fields
- **Pros**: Built-in ResourceSaver serialization, Editor Inspector visibility
- **Cons**: 38 matches × ~15 fields = large nested Resource. Resource expects file-path association for each instance. Inconsistent with every other runtime state class in the project.
- **Rejection Reason**: Season state is runtime data, not configuration. It changes every match and persists only through SaveManager. RefCounted + manual serialization is the established project pattern.

### Alternative 3: External Schedule File

- **Description**: Pre-generated league schedules stored as .tres or .json config files
- **Pros**: Designers can hand-craft specific league formats
- **Cons**: Schedule must be regenerated when team count, tier, or promotion/relegation changes. Deterministic generation from config parameters is simpler and always correct.
- **Rejection Reason**: Circle method algorithm generates correct schedules for any N-team league from parameters. No need for external files or designer-maintained schedule data.

## Consequences

### Positive

- Deterministic round-robin schedule generation from league parameters — no external schedule files needed
- Standings update is O(1) per match (single entry lookup + record_result)
- Typed classes (StandingsEntry, ScheduledMatch, LeagueSeason) provide compiler-checked field access
- Season history capped at configurable retention — bounded memory growth over multi-season play
- Promotion/relegation logic is decoupled from match simulation — LeagueStructure consumes results, doesn't generate them
- All public methods are read-only queries — no downstream system can modify league state

### Negative

- Opponents are abstract team IDs with generated names — no individual opponent player data in MVP
- Circle method requires even team count; odd N requires a dummy "bye" team (handled by config: team_count must be even)
- `_compare_standings()` falls through to team_id tiebreaker rather than full H2H matrix — acceptable for MVP per GDD rule 7
- match_id coupling between LeagueStructure schedule and MatchCompetition emission requires coordination at implementation time

### Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| match_id mismatch between schedule generation and match_completed emission | Medium | High — standings never update | MatchCompetition must include schedule's match_id in the match_completed payload. Integration test validates round-trip. |
| Round-robin schedule produces unbalanced home/away distribution for odd team count | Low | Medium — one team plays extra home/away | Config enforces even team_count. Validation in `generate_schedule()` asserts `n % 2 == 0`. |
| Season history grows unbounded over 50+ season careers | Very Low | Low | `historical_season_retention` caps at 5 seasons. Each summary ~200 bytes. Max 1KB for history. |
| Deserializing a save from a different league config (e.g., team_count changed) | Low | Medium — schedule/standings mismatch | Save stores team_count. On deserialize, if config team_count differs, flag as incompatible and start fresh season. |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `league-competition-structure-system.md` | Core Rule 3: MVP 2-tier league chain | `start_new_season()` accepts tier parameter; `is_promotion_zone()` and `is_relegation_zone()` bound by tier_count |
| `league-competition-structure-system.md` | Core Rule 5: Double round-robin | Circle method in `_round_robin_pairings()` generates 2×(N−1) rounds with home/away alternation |
| `league-competition-structure-system.md` | Core Rule 6: 3/1/0 points | `StandingsEntry.record_result()` applies win=3, draw=1, loss=0 |
| `league-competition-structure-system.md` | Core Rule 7: Tiebreakers | `_compare_standings()`: points → GD → goals scored → team_id |
| `league-competition-structure-system.md` | Core Rule 8: Promotion/relegation at season end | `_on_season_ended()` determines promotion/relegation from final standings |
| `league-competition-structure-system.md` | Core Rule 9: Schedule fixed at season start | `generate_schedule()` called once in `start_new_season()`; schedule never modified after |
| `league-competition-structure-system.md` | Core Rule 12: Standings update immediately after match | `_on_match_completed()` calls `_update_standings_for_match()` and emits `league_standings_updated` in same frame |
| `league-competition-structure-system.md` | Core Rule 13: Season settlement on time_season_ended | `_on_season_ended()` finalizes standings, determines promotion/relegation, emits `league_season_completed` |
| `league-competition-structure-system.md` | Core Rule 14: New season based on prior outcome | `start_new_season()` accepts tier resolved from prior season's promotion/relegation result |
| `league-competition-structure-system.md` | Edge Cases: Duplicate match result rejected | `is_completed` flag prevents double-counting; second submission for same match_id is silently dropped |
| `league-competition-structure-system.md` | Edge Cases: Season history capped | `historical_season_retention` in LeagueConfig caps `_season_history` |
| `match-competition-system.md` | Core Rule 19: League owns standings, not match system | LeagueStructure owns standings; MatchCompetition owns single-match results only |

## Performance Implications

- **CPU**: `_on_match_completed()` — O(S) schedule scan for match_id lookup + O(1) standings update = <0.01ms for S=38. `get_standings_sorted()` — O(N log N) sort of N=12 entries = <0.01ms. Schedule generation — O(N²) pairings for N=12 = 132 match objects = <1ms at season start (once).
- **Memory**: LeagueSeason + standings + schedule: 12 teams × ~200 bytes entry + 38 matches × ~150 bytes = ~8KB. Season history: 5 summaries × ~200 bytes = 1KB. Total: <10KB.
- **Load Time**: Deserializing season state from save: <5ms.
- **Network**: Not applicable — single-player.

## Migration Plan

Not applicable — no existing league system. This is the first implementation.

## Validation Criteria

- [ ] `start_new_season(2, "Test FC", true)` creates a season with correct team_count, standings (N entries), and schedule (2×(N−1) rounds)
- [ ] Three matches completed → standings reflect correct points, GD, and goals
- [ ] `get_standings_sorted()` returns teams ordered by points → GD → goals scored → team_id
- [ ] Standings with tied points but different GD sort correctly by GD
- [ ] `get_player_rank()` returns 1 for top-scoring team, N for bottom
- [ ] `is_promotion_zone()` returns true when player rank ≤ promotion_slots and tier > 1
- [ ] `is_relegation_zone()` returns true when player rank > (team_count − relegation_slots) and tier < max_tier
- [ ] `_on_season_ended()` transitions state to COMPLETED, stores summary, caps history
- [ ] Duplicate match_id submission does not double-count in standings
- [ ] `get_upcoming_matches(3)` returns next 3 incomplete matches
- [ ] `get_season_progress()` returns correct {completed, total, progress} ratio
- [ ] Roundtrip: start season + complete 5 matches → serialize → deserialize → standings match, schedule matches, next_match_index preserved
- [ ] Circle method for N=8 generates exactly 14 rounds × 4 matches = 56 scheduled matches, each team appears once per round
- [ ] `generate_schedule()` asserts even team_count; odd count raises error

## Related

- ADR-0002: Event/Signal Architecture — `league_standings_updated`, `league_season_completed`, `league_season_started` signals
- ADR-0003: Save/Load Persistence — LeagueStructure registers with SaveManager
- ADR-0004: Data-Driven Configuration — LeagueConfig provides tier names, team counts, promotion/relegation slots
- ADR-0006: Match Simulation Architecture — MatchResultPacket consumed for standings updates; match_id correlation
- ADR-0007: Economy Transaction Framework — season_completed summary consumed for prize money calculation
- `design/gdd/league-competition-structure-system.md` — authoritative design for league rules
- `design/gdd/match-competition-system.md` — single-match results consumed by this system
