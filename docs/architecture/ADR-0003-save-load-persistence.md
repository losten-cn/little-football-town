# ADR-0003: Save/Load Persistence

## Status

Accepted

## Date

2026-05-16

## Last Verified

2026-05-16

## Decision Makers

Technical Director, Godot Specialist

## Summary

ADR-0001 reserved SaveManager as an Autoload and ADR-0002 defined `save_completed`/`load_completed` signals, but neither specified what format saves use, how version migration works across releases, how Core systems register their serialization contracts, or how save slots are managed. This ADR defines: Godot `.tres` Resource format for saves, a mandatory `save_version` field with migration hooks, a 3-slot save system with auto-save, and a registration-based serializer pattern where each Core system registers `serialize()`/`deserialize()` callables with SaveManager at `_ready()` time.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core — Save/Load Persistence |
| **Knowledge Risk** | LOW — `ResourceSaver`, `ResourceLoader`, `FileAccess` are stable APIs |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | `FileAccess.store_*` returns `bool` (Godot 4.4 — was `void`; must check return). `duplicate_deep()` (Godot 4.5 — recommended for nested resource saves if used) |
| **Verification Required** | `FileAccess.store_*` return value handling — must not discard the `bool` |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (SaveManager Autoload reserved, ScreenManager exposes `get_active_screen_id()`), ADR-0002 (TimeManager exposes `get_state()` for save snapshots; `save_completed` / `load_completed` signals defined) |
| **Enables** | ADR-0005 through ADR-0009 (all Core ADRs define their serializable state — they declare what, this ADR defines how) |
| **Blocks** | All Core system implementation — save/load is a Foundation requirement before any Core system can be tested end-to-end |
| **Ordering Note** | Must be Accepted before Core ADRs (0005-0009) can be Accepted. TimeManager is deserialized first in the load order. |

## Context

### Problem Statement

The save-and-load-system GDD defines detailed persistence rules: 12 dependency systems, 7 dependency rules, stable save nodes, version migration, and corruption recovery. The architecture document assigns SaveManager as an Autoload with `save(slot)`/`load(slot)` and requires Core systems to register `serialize()`/`deserialize()`. But nothing defines: (1) what file format saves use, (2) how version migration detects and upgrades old saves, (3) how many save slots exist and where they live, (4) the exact registration contract Core systems must implement.

### Constraints

- Godot 4.6 + GDScript with Compatibility renderer (no GPU state to serialize)
- Single-player — no server-authoritative state, no conflict resolution
- Save-anywhere: player can manually save in `Planning` phase; auto-save at key nodes
- 512 MB memory budget — save snapshots must not exceed ~10 MB for a mature save
- Save/load must work across game version upgrades (forwards-compatible within reason)
- `FileAccess.store_*` returns `bool` since Godot 4.4 — save code must check return values

### Requirements

- Load time < 500ms for a full save (all 12 systems' state)
- Save file corruption must be detectable (hash or checksum)
- Version mismatch must produce a clear error message, not silent corruption
- Auto-save must not interrupt gameplay (async or fast enough to be imperceptible)
- Save slots must be user-selectable (not a single autosave-only slot)
- Core systems must not write save files directly — only SaveManager touches disk

## Decision

### Part A: Save Format — Godot Resource (.tres)

Saves use Godot's native `Resource` serialization via `ResourceSaver.save()` and `ResourceLoader.load()`. A typed `SaveSnapshot` Resource contains all persisted state:

```gdscript
# src/autoload/save_snapshot.gd
class_name SaveSnapshot
extends Resource

@export var save_version: int = 1
@export var timestamp: int = 0  # OS.get_unix_time()
@export var playtime_seconds: float = 0.0
@export var ui_screen_id: String = ""
@export var ui_stack_depth: int = 0

# System state blobs — each is a Dictionary serialized by the owning system
@export var time_state: Dictionary = {}
@export var player_state: Dictionary = {}
@export var match_state: Dictionary = {}
@export var economy_state: Dictionary = {}
@export var town_state: Dictionary = {}
@export var league_state: Dictionary = {}

# Metadata — displayed in save/load UI
@export var metadata: Dictionary = {}  # {town_name, season, league_tier, team_rating, integrity_hash, ...}
```

**Rationale**: `.tres` provides type-safe serialization (`@export var`), editor visibility for debugging, and native nested Resource handling. JSON was rejected because it requires manual type coercion for every field and gains no benefit for a single-player local save.

### Part B: Save Slot Management

Three save slots + one auto-save slot:

```
File structure:
  user://saves/
    slot_1.tres       # Manual save slot 1
    slot_2.tres       # Manual save slot 2
    slot_3.tres       # Manual save slot 3
    autosave.tres     # Auto-save (overwritten on key nodes)
```

**Save slot metadata**: SaveManager reads the `metadata` Dictionary from each slot file through the snapshot resource path to populate the save/load UI with: town name, season number, league tier, team rating, playtime, timestamp. Whether this is later optimized into a lighter index-read path is an implementation detail, not a contract requirement of this ADR.

**Auto-save triggers** (no player interaction required):
- After `match_completed` (post-match settlement done)
- After `time_season_ended`
- After `town_facility_completed`
- On application `NOTIFICATION_WM_CLOSE_REQUEST` (graceful shutdown)

### Part C: Core System Registration

Each Core system registers its serialize/deserialize callables with SaveManager in `_ready()`:

```gdscript
# src/autoload/save_manager.gd
extends Node

var _serializers: Dictionary = {}  # {system_id: {serialize: Callable, deserialize: Callable}}

func register_system(system_id: String, serialize_fn: Callable, deserialize_fn: Callable) -> void:
    _serializers[system_id] = {
        serialize = serialize_fn,
        deserialize = deserialize_fn,
    }

func save(slot: int) -> bool:
    var snapshot := SaveSnapshot.new()
    snapshot.save_version = ConfigLoader.get_save_version()
    snapshot.timestamp = Time.get_unix_time_from_system()
    snapshot.ui_screen_id = ScreenManager.get_active_screen_id()
    snapshot.ui_stack_depth = ScreenManager.get_screen_stack_depth()

    # Collect state from all registered systems
    for system_id: String in _serializers:
        var state: Dictionary = _serializers[system_id].serialize.call()
        snapshot.set(system_id + "_state", state)

    # Populate metadata
    snapshot.metadata = _build_metadata(snapshot)

    var path: String = _slot_path(slot)
    var err: int = ResourceSaver.save(snapshot, path)
    if err != OK:
        push_error("SaveManager: failed to save slot %d — error %d" % [slot, err])
        return false

    EventBus.emit("save_completed", {slot = slot, metadata = snapshot.metadata})
    return true

func load(slot: int) -> bool:
    var path: String = _slot_path(slot)
    if not FileAccess.file_exists(path):
        return false

    var snapshot: SaveSnapshot = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
    if not snapshot:
        push_error("SaveManager: failed to load slot %d — corrupted file" % slot)
        return false

    # Version migration
    if snapshot.save_version < ConfigLoader.get_save_version():
        snapshot = _migrate(snapshot, snapshot.save_version)

    # Deserialize in dependency order
    var load_order: Array[String] = ["time", "town", "player", "league", "economy", "match"]
    for system_id: String in load_order:
        if _serializers.has(system_id):
            var state: Dictionary = snapshot.get(system_id + "_state")
            _serializers[system_id].deserialize.call(state)

    # Restore UI
    ScreenManager.replace_screen(snapshot.ui_screen_id)
    EventBus.emit("load_completed", {slot = slot, snapshot = snapshot.metadata})
    return true
```

**Deserialize order rationale**: `TimeManager → TownBuilding → PlayerDevelopment → LeagueStructure → EconomyManager → MatchCompetition` — downstream consumers restore first, then the systems they depend on. If a match was in progress, restoring after its data sources exist prevents null references.

### Part D: Version Migration

Every save carries `save_version: int`. ConfigLoader defines `get_save_version()` — the current game version's save format version. Incremented only when save schema changes.

```gdscript
func _migrate(snapshot: SaveSnapshot, from_version: int) -> SaveSnapshot:
    var current := from_version
    while current < ConfigLoader.get_save_version():
        match current:
            1:
                # Example: v1→v2 — added town_state.prestige field
                # snapshot.town_state["prestige"] = 0
                pass
        current += 1
    snapshot.save_version = ConfigLoader.get_save_version()
    return snapshot
```

**Migration policy**: Migration is additive-forward. We never delete or rename fields — old fields are kept and marked `@deprecated` in the snapshot class. New fields are initialized to safe defaults. This prevents save corruption on version rollback.

### Part E: Save Integrity

SaveSnapshot carries an `integrity_hash` in `metadata`, computed from the serialized gameplay state. On load, SaveManager recomputes and compares it as a best-effort corruption detection step. A mismatch is treated as probable save corruption: report the slot to the player and offer recovery or deletion rather than silently loading.

```gdscript
func _verify_integrity(snapshot: SaveSnapshot) -> bool:
    var stored_hash: int = snapshot.metadata.get("integrity_hash", 0)
    var computed_hash: int = hash(snapshot.time_state) ^ hash(snapshot.player_state) ^ \
        hash(snapshot.economy_state) ^ hash(snapshot.town_state) ^ \
        hash(snapshot.league_state) ^ hash(snapshot.match_state)
    return stored_hash == computed_hash
```

### Part F: Error Recovery

| Failure | Behavior |
|---------|----------|
| Save file missing | Return `false`; UI shows "空存档槽" |
| Save file corrupted (hash mismatch) | Return `false`; UI shows "存档损坏 — 槽位 %d" |
| Version too new (future version) | Return `false`; UI shows "存档来自更新版本 — 请升级游戏" |
| Version too old, migration failed | Log error, offer "删除存档" or "导出旧存档数据" |
| Disk full on save | Catch error from `ResourceSaver.save()`; show "保存失败 — 磁盘空间不足" |
| Load during match (re-entrant) | Blocked at SaveManager level — `_loading` flag prevents concurrent loads |

```gdscript
func _slot_path(slot: int) -> String:
    if slot == 0:
        return "user://saves/autosave.tres"
    return "user://saves/slot_%d.tres" % slot
```

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                    SaveManager (Autoload)                  │
│  ┌────────────────────────────────────────────────────┐  │
│  │ register_system(id, serialize_fn, deserialize_fn)   │  │
│  │ save(slot) → bool                                   │  │
│  │ load(slot) → bool                                   │  │
│  │ delete_save(slot) → bool                            │  │
│  │ get_save_metadata(slot) → Dictionary                │  │
│  └────────────┬───────────────────────────────────┬───┘  │
│               │                                   │       │
│  ┌────────────┴──────────────┐   ┌────────────────┴────┐ │
│  │ REGISTERED SYSTEMS        │   │ DISK                 │ │
│  │ ┌───────────────────────┐ │   │ user://saves/        │ │
│  │ │ TimeManager           │ │   │  slot_1.tres         │ │
│  │ │ PlayerDevelopment     │ │   │  slot_2.tres         │ │
│  │ │ MatchCompetition      │ │   │  slot_3.tres         │ │
│  │ │ EconomyManager        │ │   │  autosave.tres       │ │
│  │ │ TownBuilding          │ │   └──────────────────────┘ │
│  │ │ LeagueStructure       │ │                             │
│  │ └───────────────────────┘ │                             │
│  └───────────────────────────┘                             │
└──────────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative 1: JSON (.json)

- **Description**: Serialize to human-readable JSON via `JSON.stringify()` and `FileAccess.store_string()`
- **Pros**: Human-readable, easy to debug with any text editor, cross-platform, version-control-friendly diffs
- **Cons**: No type safety — all values are `Variant`, requiring manual type coercion on load. Nested arrays of player data are verbose. `JSON.parse()` is slower than ResourceLoader for large files. Requires manual implementation of `@export`-style defaults.
- **Rejection Reason**: The primary consumer is the game engine, not a human. The `.tres` format provides type-safe serialization, native nested Resource handling, and Editor visibility for debugging — all of which reduce implementation bugs without meaningful downside for a single-player game.

### Alternative 2: ConfigFile (.cfg)

- **Description**: Use Godot's built-in `ConfigFile` class for INI-style saves
- **Pros**: Godot-native, section-key-value structure is simple, human-readable
- **Cons**: No nested data support — arrays of player objects require manual flattening. No type safety beyond string/float/int detection. Becomes unwieldy with 5+ systems each having nested state.
- **Rejection Reason**: PlayerDevelopment alone has arrays of player dictionaries with nested attribute objects. Flattening this into ConfigFile sections would be error-prone and unmaintainable.

### Alternative 3: SQLite via GDExtension

- **Description**: Use SQLite database for save data, one table per system
- **Pros**: Queryable, transactional (atomic saves), supports incremental writes
- **Cons**: Requires GDExtension or third-party plugin. Adds build complexity. Overkill for single-player save data that is loaded/saved as a complete snapshot.
- **Rejection Reason**: Adds a native dependency for no benefit — the game always loads the full state at once, never queries partial state.

## Consequences

### Positive

- `.tres` format provides Editor visibility — developers can inspect save files in the Godot Editor during development
- Registration pattern enforces that Core systems explicitly declare their persistence contract — no implicit "everything gets saved"
- Ordered deserialization guarantees data dependencies are available before consumers restore
- Version migration is explicit and additive — no silent data loss on upgrade
- Auto-save at key nodes protects against crash data loss without interrupting gameplay

### Negative

- `.tres` files are binary in practice — not human-readable for player troubleshooting
- Registration is opt-in — a Core system that forgets to call `register_system()` will silently not be saved
- Hash-based integrity checking is best-effort rather than cryptographic; collisions are possible, so this mechanism is for practical corruption detection, not tamper-proof guarantees
- No incremental/partial save — the entire snapshot is written each time

### Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Core system forgets to register serializer | Medium | High — state silently lost on save/load | Unit test: after save→load cycle, every registered system's state matches pre-save values. GUT test validates all 6 systems registered. |
| `ResourceSaver.save()` fails silently (returns error code not checked) | Low | High — player thinks save succeeded but file is corrupt | All `ResourceSaver.save()` calls check return value. On failure, emit `save_failed` event. |
| Version migration introduces bug that corrupts saves | Low | High — players lose progress | Migration is additive-only. Migrated saves write to a new slot first, verify integrity, then replace original. |
| Large save file (>10 MB) | Very Low | Medium — slow load | 2D management sim with ~100 players × ~15 fields each = ~2KB of player data. Even with 20 seasons of history, total < 1 MB. |
| `FileAccess.file_exists()` false negative due to permissions | Low | Low | Save directory is `user://` — Godot guarantees writable access on all platforms |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `save-and-load-system.md` | Rule 1: "存档与读档系统提供的是统一持久化边界" | SaveManager is the sole disk writer; Core systems only provide serialize/deserialize |
| `save-and-load-system.md` | Rule 2: "任何下游系统若希望新增必须持久化的长期字段…必须先回到本系统修订" | SaveSnapshot defines the canonical field set; new fields require SaveSnapshot version bump |
| `save-and-load-system.md` | Rule 3: "下游系统可以拥有自己的内容表…但必须明确区分哪些属于长期权威数据" | `serialize()` returns only authoritative state; derived/cached data is reconstructed on load |
| `save-and-load-system.md` | Edge Case: "存档损坏或升级后不兼容" | Hash integrity check + version migration chain + explicit error messages per failure mode |
| `save-and-load-system.md` | Edge Case: "读档恢复时当前状态停在关键节点中途" | Deserialize order ensures TimeManager restores first; UI restores to the recorded `ui_screen_id` |
| `time-and-season-progression-system.md` | Edge Case: "存档读取时当前状态停在关键节点中途" | TimeManager.get_state() captured atomically in save; restore goes to exact phase |
| `player-development-system.md` | AC: "已确认的训练成长不得在读档后丢失，也不得重复结算" | PlayerDevelopment.serialize() captures confirmed training results; deserialize() restores exact attribute values |
| `economy-management-system.md` | Rule 2: "任何下游系统不得直接修改三种资源的当前值" | EconomyManager.serialize() captures authoritative balances; all resource changes go through execute_transaction() |
| `match-competition-system.md` | Edge Case: "比赛中途异常退出后的恢复规则" | MatchCompetition.serialize() captures current match state; on load, if phase was Match In Progress, match resumes from last stable event |

## Performance Implications

- **CPU**: `ResourceSaver.save()` serializes ~6 dictionaries with ~200 total fields. Estimated time: 10-30ms. `ResourceLoader.load()` is comparable. Both well within the 500ms load budget.
- **Memory**: SaveSnapshot in memory is ~1-5 MB for a mature save. Transient during save/load only — freed after disk I/O completes.
- **Load Time**: Deserialization of 6 systems in dependency order: <100ms for state restoration + <200ms for scene transitions = <500ms total.
- **Disk**: Save files grow linearly with player count and season history. Single save file: ~500KB typical, <2 MB worst case. 4 slots × 2 MB = 8 MB maximum on disk.

## Migration Plan

Not applicable — no existing save system. This is the first save/load implementation.

## Validation Criteria

- [ ] SaveManager.register_system() accepts 3 callables and stores them keyed by system_id
- [ ] SaveManager.save(1) creates `user://saves/slot_1.tres` with valid SaveSnapshot Resource
- [ ] SaveManager.load(1) restores all 6 registered system states to their pre-save values (roundtrip test)
- [ ] SaveManager.load(999) returns `false` for non-existent slot
- [ ] Corrupted save (wrong hash) returns `false` and logs error
- [ ] Version migration: save with version=1, increment ConfigLoader save_version to 2, load → snapshot.save_version == 2 after migration
- [ ] Auto-save fires on `match_completed` event receipt
- [ ] `FileAccess.store_*` return values are checked (code review: no discarded bool returns)
- [ ] Save file does not exceed 2 MB with 100 players × 10 seasons of data
- [ ] Load completes in <500ms for a 2 MB save file (measured with `Time.get_ticks_msec()`)
- [ ] All 6 Core systems are registered by the time SaveManager processes its first `save()` call

## Related

- ADR-0001: Scene Management & Autoload Architecture — defines SaveManager + ScreenManager
- ADR-0002: Event/Signal Architecture + TimeManager — defines `save_completed`/`load_completed` signals and TimeManager.get_state()
- ADR-0005 through 0009: Core system ADRs — each defines its serializable state fields
- `docs/architecture/architecture.md` — master architecture document (v1.0)
