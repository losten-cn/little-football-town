# ADR-0004: Data-Driven Configuration

## Status

Proposed

## Date

2026-05-16

## Last Verified

2026-05-16

## Decision Makers

Technical Director, Godot Specialist

## Summary

ADR-0001 reserved ConfigLoader as Autoload #1. ADR-0003 defined `ConfigLoader.get_save_version()`. But neither specified: what format game configuration uses, how tuning knobs from 5+ GDDs are organized, how validation prevents invalid config from reaching runtime, or how Core systems access their config at load time. This ADR defines: Godot Custom Resources (.tres) for all config data, a flat `res://config/` directory with one Resource file per config domain, validation at ConfigLoader startup (game refuses to start on invalid config), and typed accessor methods on ConfigLoader that Core systems call in `_ready()`.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core — Data-Driven Configuration |
| **Knowledge Risk** | LOW — `ResourceLoader`, `@export var`, Custom Resource classes are stable APIs since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | `@abstract` (Godot 4.5 — for base config validation contract); `duplicate_deep()` (Godot 4.5 — only if nested Resource configs are used) |
| **Verification Required** | `@abstract` class method enforcement on exported builds — verify it does not cause runtime errors |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (ConfigLoader reserved as Autoload #1, loaded before all other Autoloads) |
| **Enables** | ADR-0005 through ADR-0009 (all Core ADRs need their config classes defined before implementation), ADR-0003 (SaveManager calls `ConfigLoader.get_save_version()`) |
| **Blocks** | All Core system implementation — no Core system can load its tuning data without ConfigLoader |
| **Ordering Note** | Config Resource classes must be defined before any Core system can call ConfigLoader accessors |

## Context

### Problem Statement

The balance-system GDD defines 12+ tuning knobs with safe ranges, 9 formulas with configurable parameters, and 3 resource types with rules. The time-and-season GDD defines phase durations, season structure, and key node timing. The player-development, economy, town-building, and match-competition GDDs each define their own config tables (training costs, income/expense tables, facility costs, match simulation parameters). Coding any of these as GDScript constants violates the forbidden pattern: "Hardcoded game values in `src/`" (technical-preferences.md). ConfigLoader is reserved as Autoload #1, but no ADR specifies its format, validation, or access contract.

### Constraints

- Godot 4.6 + GDScript — Custom Resources are the engine's first-class data container
- All tuning values must be editable without recompiling the game
- Invalid config must produce a clear error message, not silent gameplay corruption
- Config must load before any other Autoload (ConfigLoader is #1 in load order)
- Each Core system owns its own config namespace — BalanceSystem does not define training costs
- Config must be testable — unit tests must be able to load a specific config resource in isolation

### Requirements

- Config load must complete in <50ms (all config files combined)
- Invalid config must prevent the game from reaching the main menu
- Each config Resource must validate its own fields (self-validating)
- Config access must be type-safe — no string-keyed Dictionary lookups for config values
- Hot-reload in editor for designer iteration (optional, nice-to-have)

## Decision

### Part A: Config Format — Godot Custom Resources (.tres)

Each config domain is a typed `Resource` class with `@export var` fields:

```gdscript
# src/config/balance_config.gd
class_name BalanceConfig
extends Resource

# Attribute decay
@export var decay_factor: float = 1.2           # Range: 0.8–1.8
@export var potential_cap_span: int = 15         # Range: 10–20

# Win probability
@export var rating_win_slope: float = 0.0045    # Range: 0.003–0.006
@export var win_probability_floor: float = 0.05  # Range: 0.05–0.10
@export var win_probability_ceiling: float = 0.95 # Range: 0.90–0.95

# Modifier budgets
@export var flat_modifier_sum_budget_min: int = -10
@export var flat_modifier_sum_budget_max: int = 15
@export var percent_modifier_sum_budget_min: float = -0.20
@export var percent_modifier_sum_budget_max: float = 0.30

# Resource buffer
@export var resource_buffer_multiplier: float = 3.0  # Range: 2.0–4.0

# KPI targets
@export var action_point_use_rate_target_min: float = 0.70
@export var action_point_use_rate_target_max: float = 0.90
@export var overall_win_rate_target_min: float = 0.55
@export var overall_win_rate_target_max: float = 0.65
@export var even_match_win_rate_target_min: float = 0.45
@export var even_match_win_rate_target_max: float = 0.55

# Validation
func validate() -> Dictionary:
    var errors: Array[String] = []
    if decay_factor < 0.8 or decay_factor > 1.8:
        errors.append("decay_factor %.2f outside [0.8, 1.8]" % decay_factor)
    if potential_cap_span < 10 or potential_cap_span > 20:
        errors.append("potential_cap_span %d outside [10, 20]" % potential_cap_span)
    if rating_win_slope < 0.003 or rating_win_slope > 0.006:
        errors.append("rating_win_slope %.4f outside [0.003, 0.006]" % rating_win_slope)
    # ... remaining validations
    if errors.is_empty():
        return {valid = true}
    return {valid = false, errors = errors}
```

**Rationale**: Custom Resources provide type-safe `@export var` fields, Editor visibility (designers can edit .tres files in the Godot Inspector), native `ResourceLoader.load()` for fast binary deserialization, and `validate()` can be called programmatically. JSON and ConfigFile were rejected (see Alternatives).

### Part B: Config File Structure

```
res://config/
  game_config.tres           # Master config: save_version, debug flags, game title
  balance_config.tres        # BalanceSystem — tuning knobs, formula parameters
  time_config.tres           # TimeManager — phase durations, season structure
  resource_config.tres       # Resource definitions — caps, starting values, resource types
  training_config.tres       # PlayerDevelopment — training costs, gain tables
  economy_config.tres        # EconomyManager — income/expense tables, settlement rules
  facility_config.tres       # TownBuilding — facility costs, effects, grid rules
  league_config.tres         # LeagueStructure — tier counts, promotion rules
  match_config.tres          # MatchCompetition — simulation parameters, event tables
```

**One file per config domain**. Each file contains one Resource instance of the corresponding typed class. A Core system loads exactly one config Resource (e.g., `EconomyManager` reads `economy_config.tres`). Config domains are owned by the system that consumes them — BalanceConfig is the only multi-consumer config.

### Part C: ConfigLoader API

ConfigLoader is the #1 Autoload. It loads all config Resources at startup and exposes typed accessors:

```gdscript
# src/autoload/config_loader.gd
extends Node

var game_config: GameConfig
var balance_config: BalanceConfig
var time_config: TimeConfig
var resource_config: ResourceConfig
var training_config: TrainingConfig
var economy_config: EconomyConfig
var facility_config: FacilityConfig
var league_config: LeagueConfig
var match_config: MatchConfig

var _config_paths: Dictionary = {
    game = "res://config/game_config.tres",
    balance = "res://config/balance_config.tres",
    time = "res://config/time_config.tres",
    resource = "res://config/resource_config.tres",
    training = "res://config/training_config.tres",
    economy = "res://config/economy_config.tres",
    facility = "res://config/facility_config.tres",
    league = "res://config/league_config.tres",
    match = "res://config/match_config.tres",
}

func _ready() -> void:
    var ok: bool = _load_all()
    if not ok:
        push_error("ConfigLoader: failed to load config — game cannot start")
        get_tree().quit(1)

func get_save_version() -> int:
    return game_config.save_version

func reload_config(domain: String) -> bool:
    if not OS.has_feature("editor"):
        push_error("ConfigLoader: reload_config only available in editor builds")
        return false
    return _load_domain(domain)

func _load_all() -> bool:
    var all_ok := true
    for domain: String in _config_paths:
        if not _load_domain(domain):
            all_ok = false
    return all_ok

func _load_domain(domain: String) -> bool:
    var path: String = _config_paths.get(domain, "")
    if not ResourceLoader.exists(path):
        push_error("ConfigLoader: config file missing — %s" % path)
        return false
    var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
    if not resource:
        push_error("ConfigLoader: failed to load — %s" % path)
        return false
    if resource.has_method("validate"):
        var result: Dictionary = resource.validate()
        if not result.valid:
            push_error("ConfigLoader: validation failed for %s — %s" % [domain, result.errors])
            return false
    _assign_config(domain, resource)
    return true

func _assign_config(domain: String, resource: Resource) -> void:
    match domain:
        "game":     game_config = resource as GameConfig
        "balance":  balance_config = resource as BalanceConfig
        "time":     time_config = resource as TimeConfig
        "resource": resource_config = resource as ResourceConfig
        "training": training_config = resource as TrainingConfig
        "economy":  economy_config = resource as EconomyConfig
        "facility": facility_config = resource as FacilityConfig
        "league":   league_config = resource as LeagueConfig
        "match":    match_config = resource as MatchConfig
    return true
```

**Access pattern**: Core systems access config by calling ConfigLoader properties directly in `_ready()`:
```gdscript
func _ready() -> void:
    var cfg := ConfigLoader.match_config
    _rating_slope = cfg.rating_win_slope
```

No string-keyed lookups. No casting. The typed property guarantees the correct Resource class.

### Part D: Validation Contract

Each config Resource must implement `validate() -> Dictionary`. The return Dictionary has:
- `valid: bool` — always present
- `errors: Array[String]` — present if `valid == false`, one message per failed check

ConfigLoader calls `validate()` on every resource after loading. If any resource fails validation, ConfigLoader prints all error messages and calls `get_tree().quit(1)`. The game does not reach the main menu with invalid config.

**Validation rules** (implemented in each Resource's `validate()`):
- Numeric fields must be within their declared safe range
- String fields must be non-empty where required
- Resource references (if any) must be non-null
- Enum fields must match a known set
- Cross-field constraints (e.g., `floor < ceiling`) must be satisfied

### Part E: Editor Hot-Reload

In editor builds only (`OS.has_feature("editor")`), `ConfigLoader.reload_config("balance")` re-loads a single config domain. This lets designers tweak a `.tres` value in the Inspector, then trigger a reload without restarting the game. The reloaded config is immediately available to all systems.

### Part F: Config Ownership

| Config Resource | Owner System | Other Consumers |
|-----------------|-------------|-----------------|
| `GameConfig` | ConfigLoader | SaveManager (`get_save_version()`) |
| `BalanceConfig` | ConfigLoader (multi-consumer) | BalanceSystem, PlayerDevelopment, MatchCompetition, EconomyManager, TownBuilding |
| `TimeConfig` | TimeManager | SaveManager (load order) |
| `ResourceConfig` | ConfigLoader (multi-consumer) | EconomyManager, PlayerDevelopment, TownBuilding |
| `TrainingConfig` | PlayerDevelopment | PlayerMgmtUI (display only) |
| `EconomyConfig` | EconomyManager | MainLoopUI (display only) |
| `FacilityConfig` | TownBuilding | BuildUI (display only) |
| `LeagueConfig` | LeagueStructure | MainLoopUI (display only) |
| `MatchConfig` | MatchCompetition | MatchPerfUI (display only) |

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                  ConfigLoader (Autoload #1)               │
│  ┌────────────────────────────────────────────────────┐  │
│  │ _load_all() → bool                                  │  │
│  │ reload_config(domain) → bool  (editor only)         │  │
│  │ get_save_version() → int                            │  │
│  │ Properties: game_config, balance_config, time_config│  │
│  │             resource_config, training_config, ...    │  │
│  └────────────┬───────────────────────────────────┬───┘  │
│               │                                   │       │
│  ┌────────────┴──────────────┐   ┌────────────────┴────┐ │
│  │ DISK: res://config/       │   │ CONSUMERS             │ │
│  │ ┌───────────────────────┐ │   │ ┌──────────────────┐ │ │
│  │ │ game_config.tres      │ │   │ │ SaveManager      │ │ │
│  │ │ balance_config.tres   │ │   │ │ TimeManager      │ │ │
│  │ │ time_config.tres      │ │   │ │ PlayerDevelopment│ │ │
│  │ │ resource_config.tres  │ │   │ │ MatchCompetition │ │ │
│  │ │ training_config.tres  │ │   │ │ EconomyManager   │ │ │
│  │ │ economy_config.tres   │ │   │ │ TownBuilding     │ │ │
│  │ │ facility_config.tres  │ │   │ │ LeagueStructure  │ │ │
│  │ │ league_config.tres    │ │   │ │ (all read in     │ │ │
│  │ │ match_config.tres     │ │   │ │  _ready())       │ │ │
│  │ └───────────────────────┘ │   │ └──────────────────┘ │ │
│  └───────────────────────────┘   └─────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative 1: JSON (.json)

- **Description**: Store config as JSON files loaded via `FileAccess.get_file_as_string()` + `JSON.parse_string()`
- **Pros**: Human-readable in any text editor, version-control-friendly diffs, no Godot dependency for editing
- **Cons**: No type safety — all values are `Variant`, requiring manual type coercion. No Editor Inspector integration. `JSON.parse_string()` returns untyped `Variant`. Must implement custom validation for every field. Schema drift between JSON keys and code references is a runtime bug.
- **Rejection Reason**: The primary consumer is the Godot Editor and GDScript code. Custom Resources provide Editor Inspector editing, typed `@export var`, and native `ResourceLoader` — all of which catch type errors at load time rather than at gameplay time.

### Alternative 2: ConfigFile (.cfg)

- **Description**: Use Godot's `ConfigFile` class with section-key-value INI-style files
- **Pros**: Godot-native class, simple section-key-value structure, built-in type detection (string/float/int)
- **Cons**: No nested data or typed arrays. All access is string-keyed (`get_value("section", "key")`). No compile-time type checking. Section-key typos are silent runtime bugs. No Editor Inspector for visual editing.
- **Rejection Reason**: BalanceConfig alone has 15+ fields with type constraints. String-keyed access would make refactoring and validation fragile. Custom Resources provide type safety and Editor visibility that ConfigFile cannot.

### Alternative 3: Inline GDScript Constants

- **Description**: Define all tuning values as `const` declarations in each Core system's GDScript file
- **Pros**: Zero infrastructure, compiler-verified, fastest possible access
- **Cons**: Violates the project's forbidden pattern against hardcoded game values. Requires recompilation to change values. Designers cannot tune without code access. Values scattered across files with no central overview.
- **Rejection Reason**: Explicitly forbidden by technical-preferences.md. Data-driven design is a Foundation requirement.

## Consequences

### Positive

- All tuning values are centralized in `res://config/` — a designer can find every adjustable number in one directory
- Editor Inspector enables visual editing of config values without touching code
- Type-safe access via typed properties eliminates string-keyed lookup bugs
- Self-validating config catches errors at game startup, not mid-gameplay
- Hot-reload accelerates designer iteration cycles during development

### Negative

- 9 config files required before the game can start — any missing file is a hard failure
- Adding a new config field requires changes in three places: the Resource class, the `.tres` file, and the consuming system
- `ResourceLoader.load()` is a blocking synchronous call — must complete before `_ready()` of any other Autoload
- Hot-reload is editor-only; shipped builds cannot reload config (by design)

### Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Config Resource class definition drifts from `.tres` file content | Medium | Medium — stale defaults or missing fields | `validate()` catches out-of-range values; unit test loads each `.tres` and asserts `validate().valid == true` |
| `ResourceLoader.load()` fails silently on exported build | Low | High — game cannot start | ConfigLoader checks return value and calls `get_tree().quit(1)` with clear error message |
| Designer edits `.tres` to an invalid value via Inspector | Medium | Low — caught at next startup | `validate()` prevents invalid config from reaching gameplay; error messages are specific |
| Config file count grows with new systems | Low | Low | 9 configs at Foundation + Core is manageable. If >20, group by layer into subdirectories. |
| `@abstract` validation contract not enforced at runtime | Very Low | Low | Base class provides default `validate()` returning `{valid = true}`; each concrete Resource overrides it. Even without @abstract enforcement, missing override = no validation (not a crash). |
| `get_tree().quit(1)` is queued, not immediate | Low | Low — other Autoloads' `_ready()` may run before quit | Harmless — those systems will read `null` config and may emit secondary errors, but the game is already shutting down. Acceptable for a fatal-error path. |
| `has_method("validate")` silently skips if `validate()` renamed | Very Low | Medium — validation gap | The typed `_assign_config()` via `match` reduces risk (each domain maps explicitly). In practice, renaming `validate()` would break unit tests first. |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `balance-system.md` | Tuning Knobs — 12+ shared tuning parameters with safe ranges | `BalanceConfig` Resource stores all balance tuning knobs with `validate()` enforcing safe ranges |
| `balance-system.md` | Core Rule 1: "数值系统是跨系统共享规则的权威来源" | `BalanceConfig` is the single file for shared formula parameters; consumed by all Core systems via typed ConfigLoader accessor |
| `balance-system.md` | AC: "CI 扫描所有数值边界、乘区、上下限的常量引用" | Every config value lives in a `.tres` file, not in code — CI can scan `.tres` files for boundary compliance |
| `time-and-season-progression-system.md` | Tuning Knobs — phase durations, season structure, key node timing | `TimeConfig` Resource owned by TimeManager |
| `player-development-system.md` | Tuning Knobs — training costs, gain tables, rarity boundaries | `TrainingConfig` Resource owned by PlayerDevelopment |
| `economy-management-system.md` | Tuning Knobs — income/expense tables, settlement rules | `EconomyConfig` Resource owned by EconomyManager |
| `town-building-system.md` | Tuning Knobs — facility costs, effects, grid rules | `FacilityConfig` Resource owned by TownBuilding |
| `league-competition-structure-system.md` | Tuning Knobs — tier counts, promotion rules | `LeagueConfig` Resource owned by LeagueStructure |
| `match-competition-system.md` | Tuning Knobs — simulation parameters, event tables | `MatchConfig` Resource owned by MatchCompetition |
| Technical Preferences | Forbidden Pattern: "Hardcoded game values in `src/`" | All tuning values live in `res://config/*.tres` files; `src/` code reads them via ConfigLoader |

## Performance Implications

- **CPU**: `ResourceLoader.load()` for 9 `.tres` files at startup. Each file is a small Resource with ~10-20 scalar fields. Estimated total load time: <10ms. Hot-reload of a single config: <1ms.
- **Memory**: 9 config Resource instances in memory. Each is ~200-500 bytes. Total: <5KB. Config Resources persist for the entire game session (intentional — they are read by systems in `_ready()` and cached).
- **Load Time**: ConfigLoader runs before any other Autoload. Its `_load_all()` must complete in <50ms to not delay game startup. 9 small `.tres` files easily meet this budget.
- **Network**: Not applicable — config is local to the game installation.

## Migration Plan

Not applicable — no existing config system. This is the first data-driven configuration implementation.

## Validation Criteria

- [ ] ConfigLoader._load_all() loads 9 config Resources successfully from `res://config/`
- [ ] ConfigLoader.get_save_version() returns the value stored in `game_config.tres`
- [ ] `BalanceConfig.validate()` returns `{valid = false, errors = [...]}` when `decay_factor = 3.0` (outside safe range)
- [ ] ConfigLoader calls `get_tree().quit(1)` when any config Resource fails validation
- [ ] ConfigLoader prints the domain name and specific error messages for each validation failure
- [ ] `ConfigLoader.reload_config("balance")` hot-reloads `balance_config.tres` in editor build
- [ ] A unit test loads `balance_config.tres` directly via `ResourceLoader.load()` and asserts `validate().valid == true`
- [ ] No Core system contains a hardcoded tuning value — all values read from ConfigLoader properties in `_ready()`
- [ ] All 9 config `.tres` files exist with default values matching their respective GDD safe ranges

## Related

- ADR-0001: Scene Management & Autoload Architecture — defines ConfigLoader as Autoload #1
- ADR-0003: Save/Load Persistence — depends on `ConfigLoader.get_save_version()`
- ADR-0005 through ADR-0009: Core system ADRs — each defines its config schema in its Config Resource class
- `design/gdd/balance-system.md` — authoritative source for all shared formula parameters
- `docs/architecture/architecture.md` — master architecture document (v1.0)
