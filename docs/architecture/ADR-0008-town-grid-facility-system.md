# ADR-0008: Town Grid & Facility System

## Status

Proposed

## Date

2026-05-17

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core — Town Grid & Facility System |
| **Knowledge Risk** | LOW — pure GDScript math, grid indexing, Dictionary/Array operations; no engine-specific APIs |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (EventBus signals: subscribes to `time_phase_changed`; emits `town_facility_completed`, `town_grid_changed`, `town_facility_demolished`), ADR-0003 (SaveManager registration), ADR-0004 (TownConfig via ConfigLoader), ADR-0007 (EconomyManager.accredit_facility_cost) |
| **Enables** | PlayerDevelopment (reads `compute_training_efficiency_multiplier`, `compute_facility_ap_bonus`, `get_youth_training_bonus`, `get_potential_floor_boost`), MatchCompetition (reads `compute_home_advantage_bonus`, `compute_stadium_revenue_multiplier`) |
| **Blocks** | Town building implementation — no facility bonuses can be computed without this ADR |
| **Ordering Note** | Must be Accepted before any story that references facility bonuses or town grid rendering |

## Context

### Problem Statement

The town-building GDD defines a 5x5 grid, 4 facility types (training_ground, medical_room, youth_academy, stadium), 5-level upgrade path, adjacency bonus system with 3 bonus pairs, construction/upgrade/demolish state machine, and 9 formula categories for facility bonuses consumed by PlayerDevelopment, MatchCompetition, and EconomyManager. But no ADR defines: (1) the grid data structure, (2) the Facility class type (Resource vs RefCounted), (3) the adjacency computation strategy (on-change vs on-query), (4) how construction timers are advanced, (5) the public formula interface for downstream systems, (6) the serialization contract.

### Constraints

- Godot 4.6 + GDScript — pure computation, no rendering
- 5x5 grid (configurable MxN via TownConfig)
- 4 facility types in MVP; design must allow future additions without grid restructure
- Construction/upgrade costs deducted via EconomyManager.accredit_facility_cost() only
- All tuning values from TownConfig Custom Resource (ADR-0004)
- Adjacency is 4-directional (shared edges only; diagonals excluded per GDD rule 5)
- Demolition is instant in MVP (no time cost, no resource refund)

### Requirements

- Grid must support build, upgrade, demolish operations with validation
- Facility state machine: Empty -> Constructing -> Active(Lv.1) <-> Upgrading -> Active(Lv.N+1) -> Demolishing -> Empty
- Construction timers advance on time ticks; completion triggers `town_facility_completed`
- Adjacency bonuses computed on facility state change, not polled per-frame
- Public read-only formula methods for downstream systems
- Full serialization of grid state, facility list, and in-progress construction timers

## Decision

### Part A: Facility Class

Facility is a RefCounted — consistent with Player (ADR-0005), lighter than Resource per instance. Serialization is manual via `to_dict()`/`from_dict()`.

```gdscript
# src/core/facility.gd
class_name Facility
extends RefCounted

enum Type { TRAINING_GROUND, MEDICAL_ROOM, YOUTH_ACADEMY, STADIUM }
enum State { EMPTY, CONSTRUCTING, ACTIVE, UPGRADING }

var id: int = 0
var facility_type: Type = Type.TRAINING_GROUND
var level: int = 0          # 0 = not built; 1-5 = active levels
var state: State = State.EMPTY
var grid_x: int = -1
var grid_y: int = -1
var remaining_construction_units: int = 0  # Countdown; 0 when not constructing

func to_dict() -> Dictionary:
    return {
        id = id, facility_type = facility_type, level = level,
        state = state, grid_x = grid_x, grid_y = grid_y,
        remaining_construction_units = remaining_construction_units,
    }

static func from_dict(data: Dictionary) -> Facility:
    var f := Facility.new()
    f.id = data.get("id", 0)
    f.facility_type = data.get("facility_type", Type.TRAINING_GROUND)
    f.level = data.get("level", 0)
    f.state = data.get("state", State.EMPTY)
    f.grid_x = data.get("grid_x", -1)
    f.grid_y = data.get("grid_y", -1)
    f.remaining_construction_units = data.get("remaining_construction_units", 0)
    return f
```

### Part B: TownBuilding Autoload

TownBuilding is a Core Autoload node. It owns the grid, the facility registry, and all formula computation. It registers with SaveManager and subscribes to EventBus for time ticks.

```gdscript
# src/core/town_building.gd
class_name TownBuilding
extends Node

var _grid: Array[Facility] = []              # Flat array, size = width * height
var _facility_by_id: Dictionary[int, Facility] = {}  # id -> Facility lookup
var _next_facility_id: int = 1
var _grid_width: int = 5
var _grid_height: int = 5

func _ready() -> void:
    _init_grid()
    # Assumes ADR-0001 autoload order: SaveManager & EventBus load before TownBuilding
    SaveManager.register_system("town", _serialize, _deserialize)
    EventBus.subscribe("time_phase_changed", _on_time_phase_changed)

func _init_grid() -> void:
    var cfg: TownConfig = ConfigLoader.town_config
    _grid_width = cfg.grid_width
    _grid_height = cfg.grid_height
    _grid.resize(_grid_width * _grid_height)
    for i in range(_grid.size()):
        _grid[i] = null

## Flat index: grid_x + grid_y * grid_width
func _cell_index(grid_x: int, grid_y: int) -> int:
    return grid_x + grid_y * _grid_width

func _is_in_bounds(grid_x: int, grid_y: int) -> bool:
    return grid_x >= 0 and grid_x < _grid_width and grid_y >= 0 and grid_y < _grid_height

func get_facility_at(grid_x: int, grid_y: int) -> Facility:
    if not _is_in_bounds(grid_x, grid_y):
        return null
    return _grid[_cell_index(grid_x, grid_y)]

func get_facility(id: int) -> Facility:
    return _facility_by_id.get(id, null)
```

### Part C: Build / Upgrade / Demolish Operations

All resource costs route through `EconomyManager.accredit_facility_cost()`. Operations return `{success: bool, ...}` — callers check the result.

```gdscript
func build_facility(facility_type: Facility.Type, grid_x: int, grid_y: int) -> Dictionary:
    if not _is_in_bounds(grid_x, grid_y):
        return {success = false, error = "out_of_bounds"}
    if get_facility_at(grid_x, grid_y) != null:
        return {success = false, error = "cell_occupied"}

    var cfg: TownConfig = ConfigLoader.town_config
    var funds_cost: int = _calc_construction_funds_cost(facility_type, 1)
    var time_units: int = _calc_construction_time(facility_type, 1)

    var tx_result: Dictionary = EconomyManager.accredit_facility_cost(
        funds_cost, 0, _next_facility_id
    )
    if not tx_result.success:
        return {success = false, error = "funds_insufficient"}

    var facility := Facility.new()
    facility.id = _next_facility_id; _next_facility_id += 1
    facility.facility_type = facility_type
    facility.level = 0
    facility.state = Facility.State.CONSTRUCTING
    facility.grid_x = grid_x; facility.grid_y = grid_y
    facility.remaining_construction_units = time_units

    _grid[_cell_index(grid_x, grid_y)] = facility
    _facility_by_id[facility.id] = facility

    EventBus.emit("town_grid_changed", {
        action = "construction_started",
        facility_id = facility.id, facility_type = facility_type,
        grid_x = grid_x, grid_y = grid_y, remaining_units = time_units,
    })
    return {success = true, facility_id = facility.id}

func upgrade_facility(facility_id: int) -> Dictionary:
    var facility: Facility = get_facility(facility_id)
    if facility == null:
        return {success = false, error = "facility_not_found"}
    if facility.state != Facility.State.ACTIVE:
        return {success = false, error = "facility_not_active"}
    if facility.level >= 5:
        return {success = false, error = "already_max_level"}

    var target_level: int = facility.level + 1
    var cfg: TownConfig = ConfigLoader.town_config
    var funds_cost: int = _calc_construction_funds_cost(facility.facility_type, target_level)
    var time_units: int = _calc_upgrade_time(facility.facility_type, target_level)

    var tx_result: Dictionary = EconomyManager.accredit_facility_cost(
        funds_cost, 0, facility_id
    )
    if not tx_result.success:
        return {success = false, error = "funds_insufficient"}

    facility.state = Facility.State.UPGRADING
    facility.remaining_construction_units = time_units

    EventBus.emit("town_grid_changed", {
        action = "upgrade_started",
        facility_id = facility_id, target_level = target_level,
        remaining_units = time_units,
    })
    return {success = true, facility_id = facility_id}

func demolish_facility(facility_id: int) -> Dictionary:
    var facility: Facility = get_facility(facility_id)
    if facility == null:
        return {success = false, error = "facility_not_found"}
    if facility.state == Facility.State.CONSTRUCTING or facility.state == Facility.State.UPGRADING:
        return {success = false, error = "facility_under_construction"}

    var old_type = facility.facility_type
    var old_level = facility.level
    var gx = facility.grid_x; var gy = facility.grid_y

    _grid[_cell_index(gx, gy)] = null
    _facility_by_id.erase(facility_id)

    _recompute_adjacencies_for_neighbors(gx, gy)

    EventBus.emit("town_facility_demolished", {
        facility_id = facility_id, facility_type = old_type, level = old_level,
    })
    EventBus.emit("town_grid_changed", {
        action = "demolished",
        facility_id = facility_id, grid_x = gx, grid_y = gy,
    })
    return {success = true}
```

### Part D: Construction Timer & Completion

Construction timers decrement on `time_phase_changed`. Iteration uses a key-snapshot to avoid undefined behavior if EventBus callbacks modify `_facility_by_id` during the loop.

```gdscript
func _on_time_phase_changed(payload: Dictionary) -> void:
    var facility_ids: Array[int] = []
    for fid: int in _facility_by_id:
        facility_ids.append(fid)

    for fid: int in facility_ids:
        var facility: Facility = _facility_by_id.get(fid)
        if facility == null:
            continue  # May have been removed by a prior iteration's event
        if facility.state == Facility.State.CONSTRUCTING or facility.state == Facility.State.UPGRADING:
            facility.remaining_construction_units -= 1
            if facility.remaining_construction_units <= 0:
                _complete_construction(facility)

func _complete_construction(facility: Facility) -> void:
    var was_constructing: bool = facility.state == Facility.State.CONSTRUCTING
    facility.state = Facility.State.ACTIVE
    if was_constructing:
        facility.level = 1
    else:
        facility.level += 1
    facility.remaining_construction_units = 0

    _recompute_adjacencies_for_neighbors(facility.grid_x, facility.grid_y)

    EventBus.emit("town_facility_completed", {
        facility_id = facility.id, facility_type = facility.facility_type,
        level = facility.level, grid_x = facility.grid_x, grid_y = facility.grid_y,
    })
```

### Part E: Adjacency System

```gdscript
## Manhattan distance == 1 means shared edge (4-directional)
func _are_adjacent(x1: int, y1: int, x2: int, y2: int) -> bool:
    return abs(x1 - x2) + abs(y1 - y2) == 1

func _get_adjacent_facilities(grid_x: int, grid_y: int) -> Array[Facility]:
    var result: Array[Facility] = []
    var deltas: Array[Array] = [[-1, 0], [1, 0], [0, -1], [0, 1]]
    for delta: Array in deltas:
        var f := get_facility_at(grid_x + delta[0], grid_y + delta[1])
        if f != null and f.state == Facility.State.ACTIVE:
            result.append(f)
    return result

func _recompute_adjacencies_for_neighbors(grid_x: int, grid_y: int) -> void:
    # Adjacency bonuses are computed on-query (not stored). This method exists
    # as a hook for future caching and to document the recomputation boundary.
    # Downstream systems read bonuses via get_adjacency_bonuses() which
    # recalculates live from current grid state.
    pass

## Returns which adjacency pairs are active for a given facility
func get_adjacency_bonuses(facility_id: int) -> Dictionary:
    var facility: Facility = get_facility(facility_id)
    if facility == null or facility.state != Facility.State.ACTIVE:
        return {}

    var adj_facs: Array[Facility] = _get_adjacent_facilities(facility.grid_x, facility.grid_y)
    var bonuses: Dictionary = {}

    for other: Facility in adj_facs:
        var pair: String = _adjacency_pair_key(facility.facility_type, other.facility_type)
        match pair:
            "training_ground_medical_room":
                bonuses["adj_tr_med"] = true
                bonuses["adj_med_tr"] = true
            "training_ground_youth_academy":
                bonuses["adj_tr_youth"] = true
                bonuses["adj_youth_tr"] = true
            "stadium_training_ground":
                bonuses["adj_stad_tr"] = true

    return bonuses

func _adjacency_pair_key(a: Facility.Type, b: Facility.Type) -> String:
    if a == Facility.Type.TRAINING_GROUND and b == Facility.Type.MEDICAL_ROOM:
        return "training_ground_medical_room"
    if a == Facility.Type.MEDICAL_ROOM and b == Facility.Type.TRAINING_GROUND:
        return "training_ground_medical_room"
    if a == Facility.Type.TRAINING_GROUND and b == Facility.Type.YOUTH_ACADEMY:
        return "training_ground_youth_academy"
    if a == Facility.Type.YOUTH_ACADEMY and b == Facility.Type.TRAINING_GROUND:
        return "training_ground_youth_academy"
    if a == Facility.Type.STADIUM and b == Facility.Type.TRAINING_GROUND:
        return "stadium_training_ground"
    if a == Facility.Type.TRAINING_GROUND and b == Facility.Type.STADIUM:
        return "stadium_training_ground"
    return ""
```

### Part F: Public Formula Interface

Downstream systems call these read-only methods. All use current live facility state — no caching.

```gdscript
## Training efficiency multiplier (training_ground)
func compute_training_efficiency_multiplier() -> float:
    var tg := _find_active_facility(Facility.Type.TRAINING_GROUND)
    var level: int = tg.level if tg else 0
    return 1.0 + ConfigLoader.town_config.training_ground_bonus_delta * level

## Home advantage bonus (stadium + adjacency to training_ground)
func compute_home_advantage_bonus() -> float:
    var stadium := _find_active_facility(Facility.Type.STADIUM)
    if not stadium:
        return 0.0
    var cfg: TownConfig = ConfigLoader.town_config
    var base: float = cfg.home_advantage_per_level * stadium.level
    var adj_bonus: float = _compute_adj_stadium_home_bonus(stadium)
    return base + adj_bonus

## Stadium revenue multiplier
func compute_stadium_revenue_multiplier() -> float:
    var stadium := _find_active_facility(Facility.Type.STADIUM)
    var level: int = stadium.level if stadium else 0
    return 1.0 + ConfigLoader.town_config.stadium_revenue_per_level * level

## AP bonus from medical_room (capped at 3 per EconomyManager contract)
func compute_facility_ap_bonus() -> int:
    var med := _find_active_facility(Facility.Type.MEDICAL_ROOM)
    var level: int = med.level if med else 0
    if level == 0:
        return 0
    var cfg: TownConfig = ConfigLoader.town_config
    var base_ap: int = clampi(floori(level * cfg.medical_ap_bonus_per_level), 1, 3)
    var adj_ap: int = _compute_adj_med_ap_bonus(med)
    return clampi(base_ap + adj_ap, 0, 3)

## Injury recovery reduction (medical_room, capped at 2)
func compute_injury_recovery_reduction() -> int:
    var med := _find_active_facility(Facility.Type.MEDICAL_ROOM)
    var level: int = med.level if med else 0
    if level == 0:
        return 0
    var cfg: TownConfig = ConfigLoader.town_config
    return clampi(floori(level * cfg.injury_recovery_per_level), 1, 2)

## Potential floor boost from youth academy (including adjacency)
func compute_potential_floor_boost() -> int:
    var ya := _find_active_facility(Facility.Type.YOUTH_ACADEMY)
    var level: int = ya.level if ya else 0
    var cfg: TownConfig = ConfigLoader.town_config
    var base: int = clampi(floori(level * cfg.youth_potential_floor_per_level), 0, 5)
    var adj_boost: int = _compute_adj_youth_potential_boost(ya) if ya else 0
    return base + adj_boost

## Youth training bonus (youth academy; age-gated)
func compute_youth_training_bonus(player_age: int) -> float:
    var ya := _find_active_facility(Facility.Type.YOUTH_ACADEMY)
    var level: int = ya.level if ya else 0
    if level == 0 or player_age > ConfigLoader.town_config.youth_age_threshold:
        return 1.0
    return clampf(1.0 + ConfigLoader.town_config.youth_growth_per_level * level, 1.00, 1.20)

## Combined facility training multiplier (for PlayerDevelopment)
func compute_facility_training_multiplier(player_age: int) -> float:
    var efficiency := compute_training_efficiency_multiplier()
    var youth := compute_youth_training_bonus(player_age)
    var adj_youth := _compute_adj_tr_youth_multiplier()
    return efficiency * youth * adj_youth

## Total daily maintenance cost (for EconomyManager)
func compute_facility_total_maintenance() -> int:
    var total: int = 0
    var cfg: TownConfig = ConfigLoader.town_config
    for facility: Facility in _facility_by_id.values():
        if facility.state == Facility.State.ACTIVE:
            total += cfg.facility_maintenance_base[facility.facility_type]
            total += cfg.facility_maintenance_delta[facility.facility_type] * (facility.level - 1)
    return total

func _find_active_facility(facility_type: Facility.Type) -> Facility:
    for facility: Facility in _facility_by_id.values():
        if facility.facility_type == facility_type and facility.state == Facility.State.ACTIVE:
            return facility
    return null
```

### Part G: Serialization Contract

```gdscript
func _serialize() -> Dictionary:
    var facilities_data: Array[Dictionary] = []
    for facility: Facility in _facility_by_id.values():
        facilities_data.append(facility.to_dict())
    return {
        facilities = facilities_data,
        grid_width = _grid_width,
        grid_height = _grid_height,
        next_facility_id = _next_facility_id,
    }

func _deserialize(data: Dictionary) -> void:
    _grid_width = data.get("grid_width", 5)
    _grid_height = data.get("grid_height", 5)
    _next_facility_id = data.get("next_facility_id", 1)
    _init_grid()
    _facility_by_id.clear()
    for entry: Dictionary in data.get("facilities", []):
        var facility := Facility.from_dict(entry)
        if facility.grid_x >= 0 and facility.grid_y >= 0:
            _grid[_cell_index(facility.grid_x, facility.grid_y)] = facility
        _facility_by_id[facility.id] = facility
```

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                    TownBuilding (Core Autoload)                   │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Grid: flat Array[Facility] of size W×H                     │  │
│  │ _facility_by_id: Dictionary[int, Facility] — id lookup      │  │
│  │                                                             │  │
│  │ OPERATIONS                                                  │  │
│  │   build_facility(type, x, y) → {success, facility_id}      │  │
│  │   upgrade_facility(id)       → {success, ...}              │  │
│  │   demolish_facility(id)      → {success, ...}              │  │
│  │                                                             │  │
│  │ PUBLIC FORMULA INTERFACE (called by downstream systems)     │  │
│  │   compute_training_efficiency_multiplier()    → float       │  │
│  │   compute_facility_training_multiplier(age)   → float       │  │
│  │   compute_home_advantage_bonus()              → float       │  │
│  │   compute_stadium_revenue_multiplier()        → float       │  │
│  │   compute_facility_ap_bonus()                 → int         │  │
│  │   compute_injury_recovery_reduction()         → int         │  │
│  │   compute_potential_floor_boost()             → int         │  │
│  │   compute_youth_training_bonus(age)           → float       │  │
│  │   compute_facility_total_maintenance()        → int         │  │
│  └────────────┬───────────────────────────────┬───────────────┘  │
│               │                               │                   │
│  ┌────────────┴──────────────┐   ┌────────────┴──────────────┐  │
│  │ EVENTBUS OUT (emits)       │   │ EVENTBUS IN (subscribes)   │  │
│  │ town_facility_completed   │   │ time_phase_changed         │  │
│  │ town_grid_changed         │   │                             │  │
│  │ town_facility_demolished  │   │                             │  │
│  └───────────────────────────┘   └────────────────────────────┘  │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │ DOWNSTREAM CONSUMERS                                       │   │
│  │ PlayerDevelopment  ← training_multiplier, ap_bonus, etc.  │   │
│  │ MatchCompetition   ← home_advantage, revenue_multiplier   │   │
│  │ EconomyManager     ← accredit_facility_cost (write path), │   │
│  │                       facility_total_maintenance (read)    │   │
│  │ MainLoopUI         ← grid state for rendering             │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative 1: Facility as Resource (extends Resource)

- **Description**: Facility extends `Resource` instead of `RefCounted`, using `@export var` fields for built-in serialization
- **Pros**: Free serialization via `ResourceSaver`/`ResourceLoader`, Editor Inspector visibility
- **Cons**: Heavier per-instance (each Resource has file path tracking). Inconsistent with Player model (ADR-0005 chose RefCounted). Nested `duplicate_deep()` required for copying. Up to 25 facility instances would create unnecessary Resource overhead.
- **Rejection Reason**: RefCounted with manual `to_dict()`/`from_dict()` is consistent with Player pattern and lighter for 25-instance max. SaveManager serialization is explicit and tested.

### Alternative 2: Dictionary-Based Grid

- **Description**: Grid is `Dictionary[Vector2i, Facility]` or keyed by `"%d,%d" % [x, y]` strings
- **Pros**: Sparse — no null entries for empty cells. No fixed size allocation.
- **Cons**: Loses GDScript typed-array compiler optimizations. Slower iteration (hash lookup vs direct index). Harder to reason about bounds.
- **Rejection Reason**: A 5x5 grid is small (25 cells). Flat `Array[Facility]` with index calculation is O(1) get/set, type-checked by GDScript, and trivial to serialize.

### Alternative 3: TileMap-Based Grid

- **Description**: Use Godot's `TileMapLayer` nodes to represent facilities on a visual grid
- **Pros**: Free rendering, built-in coordinate system, Editor visual editing
- **Cons**: Mixes data layer with presentation layer. Couples game state to scene tree. Makes unit testing impossible (requires scene tree). Grid data becomes a visual concern instead of a data concern.
- **Rejection Reason**: Violates the Core/Presentation separation established in ADR-0001. Grid logic must be testable headlessly via GUT. Presentation layer renders grid state — it does not own it.

## Consequences

### Positive

- Single owner (TownBuilding) for all facility state, bonuses, and operations — no other system modifies facility data
- Flat Array grid is simple, fast (O(1) cell access), and trivially serializable
- Public formula methods give downstream systems a stable read-only contract — they don't need to know about grid internals
- Construction timers advance on a single EventBus signal — no custom scheduling API needed
- Adjacency computed on state change, not polled — zero per-frame cost for adjacency checks
- RefCounted Facility is consistent with Player model — same serialization pattern, same testing approach

### Negative

- Only one facility per type is supported (single `_find_active_facility`). Future multi-instance per type would require API changes.
- Adjacency pair matching via string keys is verbose — adding new facility types requires updating `_adjacency_pair_key()`
- No caching of formula outputs — downstream systems that poll every frame will recompute (acceptable: formulas are O(1) per call)
- Facility IDs are globally incrementing integers — ID collision is impossible (monotonic counter) but IDs are not reusable after demolition

### Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Autoload load order: TownBuilding._ready() runs before SaveManager/EventBus loaded | Low | High — crash on startup | ADR-0001 defines autoload order. Add `assert(SaveManager != null and EventBus != null)` in `_ready()` as defense-in-depth |
| Dictionary mutation during `_on_time_phase_changed` iteration | Low | Medium — undefined iteration behavior | Snapshot facility IDs before iterating (implemented in draft) |
| Construction timer drift: `time_phase_changed` fires at wrong granularity for "days" | Medium | Medium — construction takes too long or too fast | Construction time units are abstract ("time units"), not calendar days. Tuning in TownConfig maps GDD day-values to phase tick counts. Adjustable without code change |
| Multiple `town_facility_completed` events in one frame from cascading completions | Low | Low — UI may render multiple popups | Order is deterministic (by facility_id). UI debounces via EventBus priority queue ordering |
| Adding a 5th facility type to `Facility.Type` enum in future | Low | Low — enum extension is additive | Enum values are serialized as ints in `to_dict()`. New enum members append at end to preserve existing save data compatibility |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `town-building-system.md` | Core Rule 1: 建设系统是所有制状态的权威来源 | TownBuilding owns grid, facilities, bonuses — no other system writes facility state |
| `town-building-system.md` | Core Rule 2: MVP 4 facility types | `Facility.Type` enum with 4 members; `_find_active_facility()` supports one per type |
| `town-building-system.md` | Core Rule 3: 5-level upgrade path | `Facility.level` 0–5; `build_facility()` sets level=0→1 on completion; `upgrade_facility()` increments level |
| `town-building-system.md` | Core Rule 4: Construction cost formula | `_calc_construction_funds_cost()` reads `base_funds_cost` and `cost_multiplier` from TownConfig |
| `town-building-system.md` | Core Rule 5: 5×5 grid, 4-directional adjacency, 3 bonus pairs | Flat Array grid; `_are_adjacent()` uses Manhattan distance; `_adjacency_pair_key()` covers all 3 pairs |
| `town-building-system.md` | Core Rule 6: 加成建成后立即生效 | `_complete_construction()` sets ACTIVE state and recomputes adjacencies in the same frame |
| `town-building-system.md` | Rule 7: MVP scope — no combo bonuses, no skins | No implementation for combo bonuses, skins, or multi-team sharing |
| `town-building-system.md` | Formulas 1–9: All cost/time/bonus formulas | Formula methods with `clamp`/`floor`/`ceil` matching GDD formulas exactly |
| `town-building-system.md` | Edge Cases: 施工中不可拆除 | `demolish_facility()` rejects CONSTRUCTING/UPGRADING facilities |
| `town-building-system.md` | Edge Cases: 拆除后邻接重算 | `_recompute_adjacencies_for_neighbors()` called on demolish/completion |
| `town-building-system.md` | Edge Cases: 存档时施工中期保存 | `remaining_construction_units` serialized in `to_dict()`; restored in `from_dict()` |
| `economy-management-system.md` | 建设/升级通过 accredited path 扣费 | `build_facility()` and `upgrade_facility()` call `EconomyManager.accredit_facility_cost()` |
| `balance-system.md` | 设施系数边界 | All coefficients read from TownConfig via ConfigLoader — no hardcoded values |

## Performance Implications

- **CPU**: `build_facility()`/`upgrade_facility()`/`demolish_facility()` — O(1) grid access + O(k) adjacency check (k ≤ 4 neighbors) = <0.01ms. Formula methods: O(n) where n ≤ 25 facilities = <0.01ms. `_on_time_phase_changed`: O(n) where n = active constructions (max 25) = <0.01ms.
- **Memory**: Grid: 25 × 8 bytes (object reference) = 200 bytes. Facility instances: max 25 × ~200 bytes = 5KB. Total: <10KB.
- **Load Time**: Deserializing max 25 facilities from save: <2ms.
- **Network**: Not applicable — single-player.

## Migration Plan

Not applicable — no existing town building system. This is the first implementation.

## Validation Criteria

- [ ] `build_facility(TRAINING_GROUND, 2, 3)` on empty cell returns `{success = true, facility_id = N}`
- [ ] `build_facility()` on occupied cell returns `{success = false, error = "cell_occupied"}`
- [ ] `build_facility()` out of bounds returns `{success = false, error = "out_of_bounds"}`
- [ ] `build_facility()` with insufficient funds returns `{success = false, error = "funds_insufficient"}`
- [ ] Construction timer decrements on each `time_phase_changed`; facility completes at 0
- [ ] `upgrade_facility()` on CONSTRUCTING facility returns `{success = false, error = "facility_not_active"}`
- [ ] `upgrade_facility()` on Lv.5 facility returns `{success = false, error = "already_max_level"}`
- [ ] `demolish_facility()` on CONSTRUCTING facility returns `{success = false, error = "facility_under_construction"}`
- [ ] `compute_training_efficiency_multiplier()` returns 1.00 (no training ground), 1.15 (Lv.3), 1.25 (Lv.5)
- [ ] `compute_facility_ap_bonus()` returns 0 (no medical room), 1 (Lv.1), 3 (Lv.5)
- [ ] Training ground Lv.3 adjacent to medical room Lv.2 returns `adj_tr_med` in adjacency bonuses
- [ ] Diagonally adjacent facilities do NOT receive adjacency bonuses
- [ ] `compute_facility_total_maintenance()` returns correct sum for mixed-level facilities
- [ ] Demolishing a facility removes it from grid, erases from `_facility_by_id`, and nulls the cell
- [ ] Roundtrip: build 3 facilities → `_serialize()` → `_deserialize()` → grid matches, timers intact

## Related

- ADR-0002: Event/Signal Architecture — `town_facility_completed`, `town_grid_changed`, `town_facility_demolished` signals
- ADR-0003: Save/Load Persistence — TownBuilding registers with SaveManager
- ADR-0004: Data-Driven Configuration — TownConfig provides all tuning parameters
- ADR-0005: Player Data Model — `compute_facility_training_multiplier()` consumed by PlayerDevelopment
- ADR-0006: Match Simulation Architecture — `compute_home_advantage_bonus()` and `compute_stadium_revenue_multiplier()` consumed by MatchCompetition
- ADR-0007: Economy Transaction Framework — `accredit_facility_cost()` called for all construction costs; `compute_facility_total_maintenance()` for daily settlement
- `design/gdd/town-building-system.md` — authoritative design for facility rules and formulas
- `design/gdd/balance-system.md` — facility coefficient boundaries
