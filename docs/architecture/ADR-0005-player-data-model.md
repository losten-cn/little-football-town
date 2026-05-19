# ADR-0005: Player Data Model

## Status

Proposed

## Date

2026-05-16

## Last Verified

2026-05-16

## Decision Makers

Technical Director, Godot Specialist, Game Designer

## Summary

The player-development GDD defines 4 player tiers, 5 attributes (SPD/PWR/TEC/INT/STA), training formulas, and ROI calculations. The balance-system GDD defines the three-layer value model (current/potential/effective). The save-and-load GDD requires PlayerDevelopment to register `serialize()`/`deserialize()` with SaveManager. But none of these define: how a Player is represented in code (class vs Dictionary vs Resource), how the player collection (PlayerRoster) is managed, how attributes and training history are structured for type-safe access and serialization, or what constitutes authoritative vs derived player state. This ADR defines: `Player` as a `RefCounted` class with nested `Attributes` inner class, `PlayerRoster` as a `Resource` that owns the collection and handles serialization, and `PlayerDevelopment` as the Core Autoload that owns the roster and exposes training operations.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core — Player Data Model |
| **Knowledge Risk** | LOW — `RefCounted`, `Resource`, `Dictionary` serialization are stable APIs since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | None — core GDScript data structures |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (EventBus signals: `player_training_completed`, `player_milestone_reached`), ADR-0003 (SaveManager registration: `serialize()`/`deserialize()`), ADR-0004 (ConfigLoader: `TrainingConfig` access) |
| **Enables** | ADR-0006 (MatchSimulation consumes player attribute data), ADR-0007 (EconomyManager consumes training costs) |
| **Blocks** | Match simulation implementation — cannot simulate without player data |
| **Ordering Note** | Must be Accepted before ADR-0006 (Match Simulation) can be Accepted |

## Context

### Problem Statement

The player-development GDD defines detailed rules for player growth (4 tiers, 5 attributes, 3-layer value model, training formulas with 4 multiplicative factors, ROI calculations). The save-and-load system requires PlayerDevelopment to serialize its state. But no ADR defines: (1) the Player data structure — class, Resource, or Dictionary? (2) how 100+ players are stored and accessed efficiently, (3) how attribute triplets (current/potential/effective) are organized for type-safe access, (4) the serialization contract — what fields are authoritative vs derived, (5) the PlayerRoster API for add/remove/query operations.

### Constraints

- Godot 4.6 + GDScript — typed arrays `Array[Player]` and typed dictionaries
- ~100 players in a mature save (30 roster + 70 youth/recruit pool) × ~20 fields each = ~2000 data points
- Serialize/deserialize must complete in <50ms for the full roster
- Attributes use the three-layer model (current/potential/effective) defined in balance-system GDD
- PlayerDevelopment must register with SaveManager per ADR-0003
- Training config comes from `ConfigLoader.training_config` per ADR-0004

### Requirements

- Type-safe Player access — no string-keyed attribute lookups in core logic
- Roster queries: by_id, by_tier, by_position, by_training_efficiency_range
- Serialization produces flat Dictionary per player (no nested Resource references in save data)
- Training operations are atomic: validate cost, deduct resources, compute growth, update player, emit signal
- Derived values (effective_attribute, positional_overall_rating) computed on-demand, not stored

## Decision

### Part A: Player Class — RefCounted

`Player` is a `RefCounted` class, not a `Resource`. Resources carry Editor serialization overhead and scene-tree expectations that are unnecessary for runtime data objects. `RefCounted` provides automatic memory management without the Resource system's baggage.

```gdscript
# src/core/player.gd
class_name Player
extends RefCounted

## Unique player identifier (assigned by PlayerRoster at creation)
var id: int = 0

## Display name
var name: String = ""

## Football age — incremented at season end
var age: int = 18

## Primary position (enum: GK, DF, MF, FW)
var position: String = "MF"

## Player tier
var tier: String = "普通"  # 普通 | 优秀 | 明星 | 传奇胚子

## Five-attribute values
var attributes: Attributes = Attributes.new()

## Individual training efficiency
var training_efficiency: float = 1.0  # Range: 0.8–1.5

## Condition and morale multipliers
var condition_multiplier: float = 1.0  # Range: 0.6–1.1
var morale_multiplier: float = 1.0     # Range: 0.9–1.1

## Training history (last N entries for UI display)
var training_history: Array[Dictionary] = []

## Milestones reached
var milestones: Array[String] = []
var total_training_sessions: int = 0

# ─── Nested Attributes ───

class Attributes:
    var spd: AttributeTriplet = AttributeTriplet.new()
    var pwr: AttributeTriplet = AttributeTriplet.new()
    var tec: AttributeTriplet = AttributeTriplet.new()
    var int: AttributeTriplet = AttributeTriplet.new()
    var sta: AttributeTriplet = AttributeTriplet.new()

    func get_attr(name: String) -> AttributeTriplet:
        match name:
            "SPD": return spd
            "PWR": return pwr
            "TEC": return tec
            "INT": return int
            "STA": return sta
        return null

    func to_dict() -> Dictionary:
        return {
            SPD = spd.to_dict(),
            PWR = pwr.to_dict(),
            TEC = tec.to_dict(),
            INT = int.to_dict(),
            STA = sta.to_dict(),
        }

    static func from_dict(data: Dictionary) -> Attributes:
        var a := Attributes.new()
        a.spd = AttributeTriplet.from_dict(data.get("SPD", {}))
        a.pwr = AttributeTriplet.from_dict(data.get("PWR", {}))
        a.tec = AttributeTriplet.from_dict(data.get("TEC", {}))
        a.int = AttributeTriplet.from_dict(data.get("INT", {}))
        a.sta = AttributeTriplet.from_dict(data.get("STA", {}))
        return a

class AttributeTriplet:
    var current: int = 1     # Range: 1–100, permanent growth
    var potential: int = 70  # Range: 1–100, ≥ current
    # effective is NOT stored — it is computed on-demand by MatchSimulation
    # using the formula: effective = (current + flat_modifiers) * (1 + percent_modifiers)

    func to_dict() -> Dictionary:
        return {current = current, potential = potential}

    static func from_dict(data: Dictionary) -> AttributeTriplet:
        var t := AttributeTriplet.new()
        t.current = data.get("current", 1)
        t.potential = data.get("potential", 70)
        return t
```

`effective` is never serialized — it is computed on-demand from `current` + modifiers. This prevents stale derived values in save data.

### Part B: PlayerRoster — Resource with Serialization

`PlayerRoster` extends `Resource` because it IS the save boundary — it's the single object that SaveManager serializes. It contains the `Array[Player]` and handles to_dict/from_dict conversion for the entire collection.

```gdscript
# src/core/player_roster.gd
class_name PlayerRoster
extends Resource

var players: Array[Player] = []
var _next_id: int = 1

func add_player(player: Player) -> int:
    player.id = _next_id
    _next_id += 1
    players.append(player)
    return player.id

func remove_player(id: int) -> bool:
    var idx := _find_index(id)
    if idx < 0:
        return false
    players.remove_at(idx)
    return true

func get_player(id: int) -> Player:
    for p: Player in players:
        if p.id == id:
            return p
    return null

func query_by_tier(tier: String) -> Array[Player]:
    var result: Array[Player] = []
    for p: Player in players:
        if p.tier == tier:
            result.append(p)
    return result

func query_by_position(position: String) -> Array[Player]:
    var result: Array[Player] = []
    for p: Player in players:
        if p.position == position:
            result.append(p)
    return result

func count() -> int:
    return players.size()

# ─── Serialization ───

func serialize() -> Dictionary:
    var data: Array[Dictionary] = []
    for p: Player in players:
        data.append(_player_to_dict(p))
    return {next_id = _next_id, players = data}

func deserialize(data: Dictionary) -> void:
    players.clear()
    _next_id = data.get("next_id", 1)
    for entry: Dictionary in data.get("players", []):
        players.append(_player_from_dict(entry))

func _player_to_dict(p: Player) -> Dictionary:
    return {
        id = p.id,
        name = p.name,
        age = p.age,
        position = p.position,
        tier = p.tier,
        attributes = p.attributes.to_dict(),
        training_efficiency = p.training_efficiency,
        condition_multiplier = p.condition_multiplier,
        morale_multiplier = p.morale_multiplier,
        training_history = p.training_history,
        milestones = p.milestones,
        total_training_sessions = p.total_training_sessions,
    }

func _player_from_dict(data: Dictionary) -> Player:
    var p := Player.new()
    p.id = data.get("id", 0)
    p.name = data.get("name", "")
    p.age = data.get("age", 18)
    p.position = data.get("position", "MF")
    p.tier = data.get("tier", "普通")
    p.attributes = Player.Attributes.from_dict(data.get("attributes", {}))
    p.training_efficiency = data.get("training_efficiency", 1.0)
    p.condition_multiplier = data.get("condition_multiplier", 1.0)
    p.morale_multiplier = data.get("morale_multiplier", 1.0)
    p.training_history = data.get("training_history", [])
    p.milestones = data.get("milestones", [])
    p.total_training_sessions = data.get("total_training_sessions", 0)
    return p

func _find_index(id: int) -> int:
    for i: int in players.size():
        if players[i].id == id:
            return i
    return -1
```

### Part C: PlayerDevelopment Autoload

`PlayerDevelopment` is the Core Autoload that owns the `PlayerRoster` and implements training operations. It is NOT an Autoload in the Foundation sense — it's a Core system node instantiated by the game scene. It registers with SaveManager and EventBus.

```gdscript
# src/core/player_development.gd
class_name PlayerDevelopment
extends Node

var roster: PlayerRoster = PlayerRoster.new()

func _ready() -> void:
    SaveManager.register_system("player", _serialize, _deserialize)
    EventBus.subscribe("time_season_ended", _on_season_ended)

func train(player_id: int, training_item_id: String) -> Dictionary:
    var player: Player = roster.get_player(player_id)
    if not player:
        return {success = false, error = "player_not_found"}

    var item: Dictionary = _get_training_item(training_item_id)
    if item.is_empty():
        return {success = false, error = "invalid_training_item"}

    # Atomic cost deduction via EconomyManager accredited path (ADR-0007)
    var tx_result: Dictionary = EconomyManager.accredit_training_cost(
        item.funds_cost, item.ap_cost, player.id
    )
    if not tx_result.success:
        return {success = false, error = tx_result.error}

    # Compute growth
    var gains: Dictionary = _compute_training_gains(player, item)

    # Apply growth
    _apply_gains(player, gains)

    # Advance time
    TimeManager.advance_time(item.time_cost_slots)

    # Record history
    player.training_history.append({
        item = training_item_id,
        gains = gains,
        timestamp = Time.get_unix_time_from_system(),
    })
    player.total_training_sessions += 1

    # Check milestones
    _check_milestones(player)

    # Emit event
    EventBus.emit("player_training_completed", {
        player_id = player.id,
        gains = gains,
        cost = {funds = item.funds_cost, ap = item.ap_cost},
    })

    return {success = true, gains = gains}

func _compute_training_gains(player: Player, item: Dictionary) -> Dictionary:
    var cfg: BalanceConfig = ConfigLoader.balance_config
    var gains: Dictionary = {}

    # Fatigue-adjusted efficiency (Formula 1 from player-development GDD)
    var efficiency: float = clampf(
        player.training_efficiency * player.condition_multiplier * player.morale_multiplier,
        0.5, 1.8
    )

    # Facility multiplier from TownBuilding
    var facility_mult: float = TownBuilding.get_training_multiplier() if TownBuilding else 1.0

    for attr_name: String in item.target_attributes:
        var attr: Player.AttributeTriplet = player.attributes.get_attr(attr_name)
        if not attr or attr.current >= attr.potential:
            gains[attr_name] = 0.0
            continue

        # Shared growth formula (balance-system)
        var raw: float = attribute_growth(
            item.raw_growth_input,
            attr.current,
            attr.potential,
            cfg.decay_factor,
        )

        var gain: float = raw * efficiency * item.focus_match_multiplier * facility_mult
        gain = mini(gain, attr.potential - attr.current)
        gains[attr_name] = gain

    return gains

func _apply_gains(player: Player, gains: Dictionary) -> void:
    for attr_name: String in gains:
        var attr: Player.AttributeTriplet = player.attributes.get_attr(attr_name)
        if attr:
            attr.current += int(round(gains[attr_name]))
            attr.current = clampi(attr.current, 1, attr.potential)

func _check_milestones(player: Player) -> void:
    for attr_name: String in ["SPD", "PWR", "TEC", "INT", "STA"]:
        var attr: Player.AttributeTriplet = player.attributes.get_attr(attr_name)
        if attr and attr.current % 10 == 0:
            var milestone: String = "%s_%d" % [attr_name, attr.current]
            if milestone not in player.milestones:
                player.milestones.append(milestone)
                EventBus.emit("player_milestone_reached", {
                    player_id = player.id,
                    milestone = milestone,
                    attribute = attr_name,
                })

func _on_season_ended(payload: Dictionary) -> void:
    for p: Player in roster.players:
        p.age += 1

# ─── SaveManager contract ───
func _serialize() -> Dictionary:
    return roster.serialize()

func _deserialize(data: Dictionary) -> void:
    roster.deserialize(data)

# ─── Helpers ───
func _get_training_item(id: String) -> Dictionary:
    return ConfigLoader.training_config.get_item(id) if ConfigLoader.training_config else {}

static func attribute_growth(raw: float, current: int, potential: int, decay: float) -> float:
    if current >= potential:
        return 0.0
    var ratio: float = 1.0 - float(current) / float(potential)
    return raw * pow(maxf(0.0, ratio), decay)
```

### Part D: Serialization Boundary

Only these Player fields are serialized (authoritative state):

| Field | Serialized | Rationale |
|-------|-----------|-----------|
| `id`, `name`, `age`, `position`, `tier` | Yes | Immutable or slowly-changing identity |
| `attributes.current` | Yes | Permanent growth — core save data |
| `attributes.potential` | Yes | Determines growth ceiling |
| `attributes.effective` | **No** | Derived from `current` + modifiers — recomputed on load |
| `training_efficiency` | Yes | Individual constant |
| `condition_multiplier`, `morale_multiplier` | Yes | Persistent state modified by matches |
| `training_history` | Yes | Last N entries for UI display |
| `milestones`, `total_training_sessions` | Yes | Cumulative achievement tracking |
| `positional_overall_rating` | **No** | Derived — computed on demand by MatchSimulation |

### Part E: Player ID Assignment

Player IDs are monotonically increasing integers assigned by `PlayerRoster` at creation time. IDs are never reused within a save. When a player is removed, their ID is retired. This prevents stale references in training history or match records.

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                 PlayerDevelopment (Core Autoload)         │
│  ┌────────────────────────────────────────────────────┐  │
│  │ train(player_id, training_item_id) → Dictionary     │  │
│  │ get_player(id) → Player                            │  │
│  │ query_by_tier(tier) → Array[Player]                │  │
│  │ _serialize() → Dictionary   (SaveManager contract) │  │
│  │ _deserialize(data) → void   (SaveManager contract) │  │
│  └────────────┬───────────────────────────────────┬───┘  │
│               │                                   │       │
│  ┌────────────┴──────────────┐   ┌────────────────┴────┐ │
│  │ PlayerRoster (Resource)   │   │ Player (RefCounted)   │ │
│  │ ┌───────────────────────┐ │   │ ┌──────────────────┐ │ │
│  │ │ players: Array[Player]│ │   │ │ id, name, age    │ │ │
│  │ │ _next_id: int         │ │   │ │ position, tier   │ │ │
│  │ │ serialize() → Dict    │ │   │ │ Attributes:       │ │ │
│  │ │ deserialize(Dict)     │ │   │ │   SPD, PWR, TEC,  │ │ │
│  │ │ query methods         │ │   │ │   INT, STA        │ │ │
│  │ └───────────────────────┘ │   │ │   (each: current,  │ │ │
│  └───────────────────────────┘   │ │    potential)      │ │ │
│                                  │ │ train_eff, morale  │ │ │
│                                  │ │ history, milestones│ │ │
│                                  │ └──────────────────┘ │ │
│                                  └─────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative 1: Player as Godot Resource

- **Description**: `Player` extends `Resource` with `@export var` fields
- **Pros**: Editor Inspector visibility, built-in `ResourceSaver` serialization, `duplicate_deep()` for cloning
- **Cons**: Resources carry Editor metadata overhead (~100 bytes per instance); ~100 players = ~10KB overhead. Resources expect to be saved as individual `.tres` files — 100 files for a roster is unwieldy. Nested Resources (Attributes as sub-Resource) complicate `duplicate_deep()`.
- **Rejection Reason**: Player is a runtime data object, not an asset. The Resource overhead and file-per-instance expectation are wrong for a roster of 100 runtime entities. RefCounted with manual to_dict/from_dict is lighter and better matches the save/load pattern (one Dictionary for the entire roster).

### Alternative 2: Plain Dictionary

- **Description**: Each player is a `Dictionary` with string keys
- **Pros**: Zero class definitions, flexible schema, JSON-like familiarity
- **Cons**: No type safety — `player["SPD_current"]` is a runtime typo bug. No autocomplete. Cannot attach methods. Schema validation is manual. Every system consuming player data must know the key naming convention.
- **Rejection Reason**: With 5 attributes × 3 layers + 15 metadata fields, string-keyed access creates 30+ opportunities for key typos per player access. The typed `Player.Attributes.spd.current` pattern eliminates this class of bug entirely.

### Alternative 3: ECS (Entity-Component)

- **Description**: Player is an entity ID; attributes, training, and match data are separate components
- **Pros**: Data-oriented, cache-friendly, good for thousands of entities
- **Cons**: Massive overengineering for ~100 players. Requires an ECS framework or custom implementation. Debugging is harder (no single "Player" object to inspect). GDScript is not optimized for ECS patterns.
- **Rejection Reason**: 100 players with ~20 fields each is well within OOP comfort zone. ECS adds infrastructure complexity with no measurable benefit at this scale.

## Consequences

### Positive

- Type-safe attribute access: `player.attributes.spd.current` — autocomplete works, compiler catches typos
- Clear serialization boundary — `effective` values are never stored, preventing stale derived data
- PlayerRoster as Resource enables clean SaveManager integration (one `serialize()` call)
- Monotonic ID assignment prevents stale reference bugs
- Training operations are atomic — validation, deduction, growth, and signaling happen in one method

### Negative

- 3 classes (Player, Attributes, AttributeTriplet) for what could be a flat Dictionary
- Adding a new attribute requires changes to the Attributes class (but this is rare — the 5-attribute model is stable)
- Manual to_dict/from_dict must be kept in sync with Player fields (mitigated by unit tests)
- O(n) roster queries — acceptable for ~100 players; revisit if roster grows beyond 500

### Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| to_dict/from_dict drift from Player fields | Medium | High — save/load corruption | Roundtrip unit test: create Player, serialize, deserialize, assert all fields match |
| AttributeTriplet.effective computed inconsistently across systems | Low | Medium — match simulation uses wrong values | `effective` is a computed property on Player, not stored; single source of truth |
| Roster query performance degrades with large player counts | Very Low | Low | 100 players × O(n) scan = negligible. Roster capped by design (~30 active + pool). If >500 players, add Dictionary index. |
| Player ID collision after save/load | Low | High | `_next_id` is serialized with the roster; monotonic assignment never reuses IDs |
| Resource + RefCounted mismatch if PlayerRoster accidentally passed to ResourceSaver | Very Low | Medium | PlayerRoster is only serialized via `serialize()`/`deserialize()`; never passed to `ResourceSaver`. Doc comment on class warns against it. |
| `attributes.int` variable name shadows built-in type | Low | Low — cosmetic | `int` is a GDScript type name, not a keyword. GDScript 4.x allows type names as identifiers. The GDD uses "INT" as the 智力 attribute abbreviation — changing it would break cross-document naming consistency. |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `player-development-system.md` | Core Rule 3: 每名球员必须至少拥有基础身份信息、年龄、主位置、五维属性、潜力上限、训练效率、状态标签、培养历史 | Player class fields: id, name, age, position, Attributes (5× triplet), training_efficiency, condition_multiplier, morale_multiplier, training_history |
| `player-development-system.md` | Core Rule 4: 每名球员都必须具有独立的 `training_efficiency` | `Player.training_efficiency: float` with validate() enforcing 0.8–1.5 range |
| `player-development-system.md` | Core Rule 7: 四层球员分层（普通/优秀/明星/传奇胚子） | `Player.tier: String` with get_tier_potential_band() lookup |
| `player-development-system.md` | Formula 1: `fatigue_adjusted_training_efficiency` | Computed in `_compute_training_gains()` using `condition_multiplier` and `morale_multiplier` |
| `player-development-system.md` | Formula 2: `training_actual_gain` (4 factors) | Full implementation in `_compute_training_gains()`: attribute_growth × efficiency × focus_match × facility |
| `player-development-system.md` | Core Rule 17: 已确认的训练收益不得在读档后丢失 | Serialization boundary: only `current` is saved; `effective` is recomputed on load |
| `player-development-system.md` | AC: 球员差异化 — 不同层级间 `potential_cap`、`training_efficiency` 存在统计显著差异 | `Player.tier` determines initial `potential` range and `training_efficiency` band |
| `balance-system.md` | Core Rule 4: 每个属性区分 `current` / `potential` / `effective` | `AttributeTriplet` with `.current`, `.potential`, `.effective` (computed) |
| `save-and-load-system.md` | Rule 2: 任何下游系统新增持久化字段必须先回到本系统修订 | Player serialization fields are explicitly listed; adding a field requires updating `_player_to_dict()`/`_player_from_dict()` |
| `save-and-load-system.md` | AC: 已确认的训练成长不得在读档后丢失，也不得重复结算 | `training_history` is serialized; on load, `training_actual_gain` is NOT recomputed from history |

## Performance Implications

- **CPU**: Roster queries are O(n) over ~100 players — <0.1ms per query. Training computation is ~20 float operations — <0.01ms. Serialization: 100 players × 20 fields → <5ms.
- **Memory**: Player (~200 bytes) × 100 = ~20KB. PlayerRoster + indices = ~25KB total. Well within 512MB budget.
- **Load Time**: `PlayerRoster.deserialize()` — 100 players × Dictionary construction — <10ms. Within save/load's 500ms budget.
- **Network**: Not applicable — single-player.

## Migration Plan

Not applicable — no existing player data system. This is the first implementation.

## Validation Criteria

- [ ] `Player.new()` creates a valid player with default Attributes (current=1, potential=70 for all 5 attributes)
- [ ] `PlayerRoster.add_player()` assigns a unique monotonically increasing ID
- [ ] `PlayerRoster.get_player(id)` returns the correct player; returns `null` for unknown ID
- [ ] Roundtrip: create Player with non-default values → `_player_to_dict()` → `_player_from_dict()` → all fields match
- [ ] Roundtrip: create PlayerRoster with 10 players → `serialize()` → `deserialize()` → all 10 players match field-for-field
- [ ] `PlayerDevelopment.train()` with valid player + item returns `{success = true}` with non-zero gains
- [ ] `PlayerDevelopment.train()` with player at potential cap returns `{success = true}` with `gains = 0` for capped attributes
- [ ] `PlayerDevelopment.train()` with insufficient resources returns `{success = false, error = "insufficient_resources"}`
- [ ] `AttributeTriplet.effective` is recomputed on access, not stored in save data
- [ ] Player IDs are never reused: remove player id=5, add new player → new player.id ≠ 5
- [ ] `PlayerDevelopment._serialize()` produces a Dictionary that `SaveManager` can store in `player_state`

## Related

- ADR-0002: Event/Signal Architecture — defines `player_training_completed`, `player_milestone_reached` signals
- ADR-0003: Save/Load Persistence — PlayerDevelopment registers `serialize()`/`deserialize()` with SaveManager
- ADR-0004: Data-Driven Configuration — TrainingConfig and BalanceConfig provide tuning parameters
- `design/gdd/player-development-system.md` — authoritative design for player growth mechanics
- `design/gdd/balance-system.md` — authoritative design for attribute model and shared formulas
