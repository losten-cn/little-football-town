# 足球小镇 — Master Architecture

## Document Status

- **Version**: 2.0
- **Last Updated**: 2026-05-17
- **Engine**: Godot 4.6 + GDScript
- **GDDs Covered**: game-concept.md, systems-index.md, balance-system.md, time-and-season-progression-system.md, save-and-load-system.md, player-development-system.md, match-competition-system.md, economy-management-system.md, town-building-system.md, league-competition-structure-system.md, main-loop-ui-framework.md, player-management-ui.md, match-performance-ui.md, onboarding-system.md
- **ADRs Referenced**: ADR-0001 through ADR-0009 (full Foundation + Core set)
- **Architecture Review**: CONCERNS verdict (2026-05-17) — 0 gaps, 1 resolved conflict
- **Technical Director Sign-Off**: Pending
- **Lead Programmer Feasibility**: Skipped (Lean mode)

## Engine Knowledge Gap Summary

| Domain | Risk | Relevance |
|--------|------|-----------|
| GDScript (4.5+) | MEDIUM | variadic args, @abstract decorator |
| UI (4.6) | MEDIUM | Dual-focus system for mouse-driven UI |
| Accessibility (4.5) | MEDIUM | AccessKit screen reader for management sim UI |
| 2D / TileMapLayer (4.6) | LOW | Scene tile rotation — may affect town grid rendering |
| Rendering (4.6) | LOW | D3D12 default; Compatibility renderer used for 2D pixel art |
| Physics (4.6) | LOW | Jolt default — no physics in formula-driven game |
| Animation (4.5-4.6) | LOW | IK, BoneConstraint3D — 3D-only, not applicable |

All MEDIUM risk domains are addressable via engine reference docs. No HIGH risk domains impact this 2D management sim.

## System Layer Map

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐     │
│  │ MainLoopUI   │ │PlayerMgmtUI  │ │MatchPerfUI   │     │
│  │(screen stack)│ │(list/detail) │ │(pre/live/result)│  │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘     │
│         │                │                │              │
│  ┌──────┴────────────────┴────────────────┴───────┐     │
│  │              Onboarding (Polish)                │     │
│  └────────────────────────────────────────────────┘     │
├─────────────────────────────────────────────────────────┤
│  FEATURE LAYER                                           │
│  ┌──────────────────────────────────────────────┐       │
│  │         League & Competition Structure        │       │
│  │    (standings, promotion, season schedule)    │       │
│  └──────────────────────┬───────────────────────┘       │
├─────────────────────────────────────────────────────────┤
│  CORE LAYER                                              │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐          │
│  │PlayerDev   │ │MatchComp   │ │Economy     │          │
│  │(training,  │ │(simulation,│ │(funds/AP/  │          │
│  │ growth)    │ │ events)    │ │ RP)        │          │
│  └─────┬──────┘ └─────┬──────┘ └─────┬──────┘          │
│        │              │              │                   │
│  ┌─────┴──────────────┴──────────────┴──────┐           │
│  │           Town Building                   │           │
│  │    (facilities, grid, adjacency)          │           │
│  └────────────────────┬─────────────────────┘           │
├─────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER (Autoload Singletons)                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │Config    │ │TimeMgr   │ │SaveMgr   │ │EventBus  │  │
│  │(balance) │ │(calendar)│ │(persist) │ │(signals) │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│  ┌──────────────────────────────────────────────┐       │
│  │             ScreenManager                     │       │
│  └──────────────────────────────────────────────┘       │
├─────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                          │
│  Godot 4.6 + GDScript + Compatibility Renderer           │
│  PC (Windows/Linux) — Keyboard/Mouse                     │
└─────────────────────────────────────────────────────────┘
```

### Layer Assignments

| System | GDD | Layer | Rationale |
|--------|-----|-------|-----------|
| 数值系统 | balance-system.md | Foundation (ConfigLoader Autoload) | Shared formula constants and tuning data — read-only, loaded at startup |
| 存档与读档 | save-and-load-system.md | Foundation (SaveManager Autoload) | Unified persistence boundary — all systems register serialize/deserialize |
| 时间与赛季推进 | time-and-season-progression-system.md | Foundation (TimeManager Autoload) | Global clock — only authority for time advancement and key node scheduling |
| EventBus | (ADR-0001) | Foundation (Autoload) | Global signal routing — all cross-system communication |
| ScreenManager | (ADR-0001) | Foundation (Autoload) | Screen stack + lifecycle — all UI navigation |
| 运动员培养 | player-development-system.md | Core | Player growth authority — consumes Foundation, produces player state |
| 比赛竞技 | match-competition-system.md | Core | Match simulation authority — consumes player state, produces result packets |
| 经济管理 | economy-management-system.md | Core | Resource transaction authority — only writer of funds/AP/RP |
| 小镇建设 | town-building-system.md | Core | Facility grid authority — produces multipliers consumed by other Core systems |
| 联赛与赛事 | league-competition-structure-system.md | Feature | Season competition structure — consumes match results, produces standings |
| 主循环 UI | main-loop-ui-framework.md | Presentation | Screen containers and navigation — consumes EventBus events |
| 球员管理 UI | player-management-ui.md | Presentation | Player list/detail display — read-only consumer |
| 比赛表现 UI | match-performance-ui.md | Presentation | Match visual presentation — event-driven display |
| 新手引导 | onboarding-system.md | Polish | Guided onboarding — consumes UI anchor IDs |

## Module Ownership

### Foundation Layer — Autoload Singletons

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| ConfigLoader | All tuning values, formula constants, data tables (.tres Custom Resources) | `get_balance(key)`, `get_formula_constant(key)`, `get_table(path)` | None (self-sufficient) | `ResourceLoader.load()` |
| TimeManager | Timeline position, phase state, season progress, key node scheduling | `signal phase_changed`, `signal match_triggered`, `signal season_ended`, `get_state()` | None (consumed by downstream) | `Node` (Autoload) |
| SaveManager | Serialization/deserialization, version migration, save slot management | `save(slot)`, `load(slot)`, `signal save_completed`, `get_save_metadata()` | TimeManager (node state), ScreenManager (UI position), all Core `serialize()/deserialize()` | `FileAccess`, `ResourceSaver`, `ResourceLoader` |
| EventBus | Global signal routing, event priority queue | `emit(event, payload)`, `subscribe(event, callable)`, `signal event_fired` | None | `Signal` (Godot native) |
| ScreenManager | Screen stack, lifecycle callback orchestration | `push_screen(path, data)`, `pop_screen()`, `replace_screen(path, data)`, `get_active_screen_id()` | EventBus (cross-screen communication) | `PackedScene.instantiate()`, `Node.add_child()`, `queue_free()` |

### Core Layer — Gameplay Systems

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| PlayerDevelopment | Player current attributes, training efficiency, growth history, potential bands, training project data | `get_player_state(id)`, `train(player_id, project)`, `signal training_completed`, `signal milestone_reached` | TimeManager (action windows), ConfigLoader (formula constants), SaveManager (persistence), TownBuilding (`facility_training_multiplier`) | `Resource` (data tables) |
| MatchCompetition | Match state machine, lineup/tactics, key event stream, result packet | `start_match(home, away, context)`, `signal match_event`, `signal match_completed(result_packet)`, `get_match_state()` | PlayerDevelopment (player abilities), TimeManager (match trigger), TownBuilding (`facility_rating_bonus`), ConfigLoader (win probability parameters) | `Node` (state machine) |
| EconomyManager | Funds/AP/RP balances, transaction ledger, settlement formulas, warning thresholds | `get_balances()`, `preview_cost(action)`, `execute_transaction(tx)`, `signal balance_changed`, `signal warning_triggered` | MatchCompetition (result packet → reward calc), LeagueStructure (season bonus labels), TownBuilding (maintenance, revenue multipliers), ConfigLoader (resource formulas), SaveManager (persistence) | `Resource` |
| TownBuilding | Facility grid (5×5), construction progress, adjacency calculation, facility effect multipliers | `get_facility_multipliers()`, `build(x, y, facility_type)`, `signal facility_completed`, `signal grid_changed` | EconomyManager (resource sufficiency validation), TimeManager (construction duration), ConfigLoader (facility data tables), SaveManager (persistence) | `TileMapLayer` (2D grid render, if used) |
| LeagueStructure | Standings table, match schedule, league tiers, promotion/relegation rules | `get_standings()`, `record_result(match_packet)`, `signal standings_updated`, `signal promotion_triggered` | MatchCompetition (result packet), TimeManager (season nodes), ConfigLoader (league parameters) | `Resource` |

### Presentation Layer — UI Modules

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| MainLoopUI | Home/Roster/Match/SaveLoad containers, navigation rules, refresh triggers | Container placeholders, `refresh_trigger(screen_id)` | ScreenManager (navigation), EventBus (data update events), ConfigLoader (UI parameters) | `Control`, `Container` nodes |
| PlayerMgmtUI | Player list/detail/sort/filter display state | Display anchor IDs (for onboarding targeting) | EventBus (player data changes), PlayerDevelopment (read-only queries) | `Control`, `ItemList`, scroll containers |
| MatchPerfUI | Pre-match/live/post-match container UI state | Display anchor IDs, event display pacing control | EventBus (match event stream, final whistle signal), LeagueStructure (standings context) | `Control`, `AnimationPlayer`, `Timer` |
| Onboarding | Onboarding step state, completed step markers | Anchor targeting requests | ScreenManager (screen switching), all UI anchor IDs | `Control` (overlay) |

### Ownership Rules

1. Each authoritative data type has exactly one writer module
2. EventBus transmits data only (Dictionary payloads), never object references
3. Core systems never import UI modules — UI subscribes to Core events via EventBus
4. Foundation Autoloads form no circular dependencies

## Data Flow

### Frame Update Path

Event-driven management sim — no per-frame physics or rendering loop:

```
_process(delta):
  AnimationPlayer.tick(delta)      # UI transition animations
  Timer nodes (Godot native)       # UI timers only

# No Core system _process() — all logic is EventBus callback-driven
```

### Event/Signal Architecture

All cross-system communication routes through EventBus Autoload:

```
Foundation → Core:
  TimeManager.phase_changed(new_phase)       → all Core systems
  TimeManager.match_triggered(match_context)  → MatchCompetition
  TimeManager.season_ended(season_summary)    → EconomyManager, LeagueStructure
  TimeManager.stage_settled(stage_result)     → EconomyManager, TownBuilding
  SaveManager.load_completed(snapshot)        → all Core systems (state restore)

Core → Core:
  PlayerDevelopment.training_completed(player_id, gains)  → EventBus
  MatchCompetition.match_event(event)                     → EventBus
  MatchCompetition.match_completed(result_packet)          → EconomyManager, LeagueStructure, PlayerDevelopment
  EconomyManager.balance_changed(resource, new_value)      → EventBus
  EconomyManager.warning_triggered(warning_type)           → EventBus
  TownBuilding.facility_completed(facility, effects)       → EventBus
  TownBuilding.grid_changed(grid_snapshot)                 → EventBus
  LeagueStructure.standings_updated(standings)             → EventBus
  LeagueStructure.promotion_triggered(old_tier, new_tier)  → EventBus

Core → Presentation (UI read-only consumption):
  [via EventBus]:
  PlayerDevelopment.training_completed → MainLoopUI, PlayerMgmtUI
  MatchCompetition.match_event         → MatchPerfUI
  MatchCompetition.match_completed     → MainLoopUI
  EconomyManager.balance_changed       → MainLoopUI
  LeagueStructure.standings_updated    → MainLoopUI, MatchPerfUI
```

### Save/Load Path

```
Save (trigger: manual save / auto-save node):
  SaveManager.save(slot):
    1. ScreenManager.get_active_screen_id()  → record UI position
    2. TimeManager.get_state()               → record timeline/phase/season
    3. For each registered Core system .serialize():
       PlayerDevelopment.serialize() → {players: [...], training_history: [...]}
       MatchCompetition.serialize()    → current match state (if in-match)
       EconomyManager.serialize()      → {funds, ap, rp, ledger: [...]}
       TownBuilding.serialize()        → {grid: [...], facilities: [...]}
       LeagueStructure.serialize()     → {standings: [...], schedule: [...]}
    4. Package as SaveSnapshot Resource
    5. ResourceSaver.save(snapshot, "user://saves/slot_%d.tres" % slot)

Load:
  SaveManager.load(slot):
    1. ResourceLoader.load("user://saves/slot_%d.tres" % slot)
    2. Version migration check (ConfigLoader.get("save_version"))
    3. Deserialize in dependency order:
       TimeManager → TownBuilding → PlayerDevelopment → LeagueStructure → EconomyManager → MatchCompetition
    4. ScreenManager.replace_screen(snapshot.ui_screen_id)
    5. emit("load_completed", snapshot)
```

### Initialization Order

```
Application startup:
  1. Godot loads Autoloads (ProjectSettings order):
     ConfigLoader → EventBus → TimeManager → SaveManager → ScreenManager
  2. ConfigLoader._ready():
     - Load all .tres configuration files
     - Validate required fields exist
  3. ScreenManager._ready():
     - push_screen("res://src/ui/home.tscn")
  4. Check for existing save:
     - Save exists → SaveManager.load(latest_slot)
     - No save → trigger Onboarding
  5. Enter main loop: Planning state

Core system initialization (in-scene, within SceneTree):
  6. Home scene loads — instantiates all Core system nodes:
     PlayerDevelopment.new()  → load restore or initial player pool
     EconomyManager.new()     → load restore or starting resources
     TownBuilding.new()       → load restore or blank grid
     MatchCompetition.new()   → wait for match trigger
     LeagueStructure.new()    → load restore or new season init
  7. UI scenes load on-demand:
     MainLoopUI → PlayerMgmtUI, MatchPerfUI within respective Screen containers
```

### Key Multi-System Scenario: Post-Match Settlement Chain

```
MatchCompetition.match_completed(result_packet)
  ↓ EventBus
  ├→ LeagueStructure.record_result(result_packet)       # update standings
  │   ↓ standings_updated
  │   ↓ (if season-end) promotion_triggered
  │     ├→ EconomyManager (season bonus calculation)
  │     └→ EventBus (notify UI)
  ├→ EconomyManager (post-match reward settlement)
  │   ↓ balance_changed
  │   ↓ (if resource tight) warning_triggered
  ├→ PlayerDevelopment (post-match growth opportunity feedback)
  │   ↓ training_completed (if growth occurred)
  └→ TimeManager (record match complete, advance to Post-Match Settlement)
      ↓ phase_changed → MainLoopUI
```

### Key Multi-System Scenario: Pre-Match Snapshot Timing

Construction completion on match day — Scenario 3 from GDD cross-review:

Rule: `MatchCompetition.start_match()` snapshots current facility state upon call (calls `TownBuilding.get_facility_multipliers()`). Any `facility_completed` signal emitted before the match trigger is included in the snapshot. Unified rule: "Match snapshot captures facility state at the moment the match trigger fires; same-day completed facilities are included."

## API Boundaries

### Foundation — Autoload Public Contracts

```gdscript
# ---- ConfigLoader (Autoload) ----
# Read-only, all config loaded at startup

func get_balance(key: String) -> float
func get_formula_constant(key: String) -> float
func get_table(path: String) -> Array[Dictionary]
func get_save_version() -> int

# ---- EventBus (Autoload) ----
# Global signal routing

signal event_fired(event_name: String, payload: Dictionary)

func emit(event_name: String, payload: Dictionary) -> void
func subscribe(event_name: String, callable: Callable) -> void
func unsubscribe(event_name: String, callable: Callable) -> void

# ---- TimeManager (Autoload) ----
# Sole time authority

signal phase_changed(old_phase: String, new_phase: String)
signal match_triggered(match_context: Dictionary)
signal season_ended(season_summary: Dictionary)
signal stage_settled(stage_result: Dictionary)

func get_state() -> Dictionary
func advance_time(amount: float) -> void
func get_available_windows() -> int

# ---- SaveManager (Autoload) ----

signal save_completed(slot: int, metadata: Dictionary)
signal load_completed(snapshot: Dictionary)

func save(slot: int) -> bool
func load(slot: int) -> bool
func delete_save(slot: int) -> bool
func get_save_metadata(slot: int) -> Dictionary
func register_serializer(system_id: String, serialize_callable: Callable, deserialize_callable: Callable) -> void

# ---- ScreenManager (Autoload) ----

signal screen_pushed(screen_id: String)
signal screen_popped(screen_id: String)
signal screen_replaced(screen_id: String)

func push_screen(screen_path: String, data: Dictionary = {}) -> void
func pop_screen() -> void
func replace_screen(screen_path: String, data: Dictionary = {}) -> void
func get_active_screen_id() -> String
func get_screen_stack_depth() -> int
```

### Core — System Public Contracts

```gdscript
# ---- PlayerDevelopment ----
signal training_completed(player_id: int, gains: Dictionary)
signal milestone_reached(player_id: int, milestone: String)

func get_player_state(player_id: int) -> Dictionary
func get_roster_summary() -> Array[Dictionary]
func train(player_id: int, training_project_id: String) -> Dictionary
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void

# ---- MatchCompetition ----
signal match_event(event: Dictionary)
signal match_completed(result_packet: Dictionary)

func start_match(home_lineup: Dictionary, away_lineup: Dictionary, context: Dictionary) -> void
func get_match_state() -> Dictionary
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void

# ---- EconomyManager ----
signal balance_changed(resource_type: String, old_value: float, new_value: float, reason: String)
signal warning_triggered(warning_type: String, threshold: float)

func get_balances() -> Dictionary  # {funds: float, ap: float, rp: float}
func preview_cost(action_type: String, action_params: Dictionary) -> Dictionary
func execute_transaction(tx_type: String, tx_params: Dictionary) -> Dictionary
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void

# ---- TownBuilding ----
signal facility_completed(facility_id: int, facility_type: String, effects: Dictionary)
signal grid_changed(grid_snapshot: Array)

func get_facility_multipliers() -> Dictionary
func build(x: int, y: int, facility_type: String) -> Dictionary
func upgrade(x: int, y: int) -> Dictionary
func get_grid_state() -> Array
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void

# ---- LeagueStructure ----
signal standings_updated(standings: Array[Dictionary])
signal promotion_triggered(team_id: int, old_tier: int, new_tier: int)

func record_result(match_packet: Dictionary) -> void
func get_standings() -> Array[Dictionary]
func get_team_context(team_id: int) -> Dictionary
func serialize() -> Dictionary
func deserialize(data: Dictionary) -> void
```

### Presentation — Screen Base Class

```gdscript
class_name Screen
extends Control

func on_enter(data: Dictionary) -> void: pass
func on_leave() -> void: pass
func on_resume() -> void: pass
func on_pause() -> void: pass
func can_pop() -> bool: return true
func get_anchor_id() -> String: return ""
```

### Critical Invariants

| Rule | Detail |
|------|--------|
| Resource writes | Only EconomyManager modifies funds/AP/RP — all others use `execute_transaction()` |
| Time advancement | Only TimeManager advances the timeline — downstream systems query `get_available_windows()` only |
| Player attributes | Only PlayerDevelopment modifies `current_attribute` — match/events influence via feedback tags |
| Match state | Only MatchCompetition modifies the match state machine — UI is read-only display |
| Save files | Only SaveManager writes save files — Core systems provide `serialize()/deserialize()` only |
| Screen navigation | Only ScreenManager switches screens — others request navigation via EventBus |

## ADR Audit

| ADR | Status | Assessment |
|-----|--------|------------|
| ADR-0001: Scene Management & Autoload Architecture | Accepted | 5 Autoloads (ConfigLoader, EventBus, TimeManager, SaveManager, ScreenManager). Screen Stack pattern adopted. |
| ADR-0002: Event/Signal Architecture + TimeManager | Accepted | EventBus with 16 signals + TimeManager. All cross-system communication routed through EventBus. |
| ADR-0003: Save/Load Persistence | Accepted | .tres save format, 3+1 slots, version migration, all Core systems register serialize/deserialize. |
| ADR-0004: Data-Driven Configuration | Accepted | 9 .tres Custom Resource files loaded by ConfigLoader at startup. Read-only, all tuning values external. |
| ADR-0005: Player Data Model | Accepted | Player (RefCounted), PlayerRoster, 5-attribute triplets (current/potential/effective), training system. Fixed: uses `accredit_training_cost()` per ADR-0007. |
| ADR-0006: Match Simulation Architecture | Accepted | 8-state machine, seeded RNG, 6 event categories, result packet structure, lineup/tactics data. |
| ADR-0007: Economy Transaction Framework | Accepted | `execute_transaction()` sole mutation path, Transaction class, settlement formulas, warning thresholds. |
| ADR-0008: Town Grid & Facility System | Accepted | 5×5 grid, 4 facility types × 5 levels, adjacency bonus (capped 15.0), 8 formula methods. |
| ADR-0009: League Competition Structure | Accepted | Circle method round-robin, 3/1/0 points, 4-level tiebreaker, promotion/relegation, season schedule. |

All 9 ADRs currently Accepted. No dependency cycles.

### GDD Technical Requirement → ADR Coverage

| Req # | GDD System | Technical Requirement | ADR Coverage |
|-------|-----------|----------------------|--------------|
| TR-config-001 | balance-system.md | Data-driven config loader | ADR-0004 ✅ |
| TR-time-001 | time-and-season-progression-system.md | Unified timeline + phase scheduling | ADR-0002 ✅ |
| TR-save-001 | save-and-load-system.md | Serialization contract + version migration | ADR-0003 ✅ |
| TR-event-001 | All Core systems | Event naming conventions + payload schema | ADR-0002 ✅ |
| TR-player-001 | player-development-system.md | Player data model schema | ADR-0005 ✅ |
| TR-match-001 | match-competition-system.md | Match state machine + result packet structure | ADR-0006 ✅ |
| TR-econ-001 | economy-management-system.md | Transaction interface (preview → execute) | ADR-0007 ✅ |
| TR-town-001 | town-building-system.md | 5×5 grid + adjacency calculation | ADR-0008 ✅ |
| TR-league-001 | league-competition-structure-system.md | Standings + schedule + promotion rules | ADR-0009 ✅ |
| TR-screen-001 | main-loop-ui-framework.md | Screen stack navigation | ADR-0001 ✅ |
| TR-ui-core-001 | All Presentation GDDs | UI/Core decoupling via EventBus | ADR-0001 ✅ |

Coverage: 11/11 covered. Full traceability: 143 TRs across all layers, 0 gaps (see `architecture-review-2026-05-17.md`).

## Required ADRs

All 9 Foundation + Core ADRs (0001-0009) are complete as of 2026-05-17. See `architecture-review-2026-05-17.md` for full coverage analysis and dependency ordering.

Next ADRs needed (Feature/Presentation layer):
| # | Title | Covers |
|---|-------|--------|
| ADR-0010 | Main UI Framework | Screen container architecture, refresh triggers, navigation rules |
| ADR-0011 | Player UI Architecture | List/detail/sort/filter patterns, anchor IDs for onboarding |
| ADR-0012 | Match Performance UI | Pre-match/live/post-match display, event pacing, animation triggers |

> Presentation-layer ADRs are lower priority — UI can be prototyped against Core API contracts without formal ADRs in place. Create them when the UI GDDs enter their implementation phase.

## Architecture Principles

1. **Event-driven, not polling**: Core systems communicate exclusively through EventBus signals. No system polls another's state in `_process()`. This keeps the frame budget at near-zero when the player is idle.

2. **Single writer per data type**: Every piece of authoritative game state has exactly one owner. EconomyManager owns resource values. PlayerDevelopment owns player attributes. TimeManager owns the timeline. No other module writes these directly.

3. **Data-driven tuning, not hardcoded values**: All formula constants, balance parameters, and configuration tables live in `.tres` Custom Resources loaded by ConfigLoader at startup. Game designers tune by editing resource files, not by changing code.

4. **UI observes, Core decides**: Presentation layer modules are read-only consumers of Core system state. They subscribe to EventBus signals and refresh display. They never contain game logic or compute formula results.

5. **Foundation is acyclic**: Autoload singletons form a strict dependency hierarchy: ConfigLoader (no deps) → EventBus (no deps) → TimeManager → SaveManager → ScreenManager. No Autoload imports another Autoload that depends on it.

## Open Questions

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| QQ-01 | 存档版本迁移策略 — MVP 是否需要前向兼容，或允许破坏性变更？ | Low | ✅ ADR-0003 已决定（向前兼容 + 版本号迁移） |
| QQ-02 | 小镇网格使用 TileMapLayer 还是纯数据结构 + 自定义 Control 绘制？ | Medium | ✅ ADR-0008 已决定（纯数据结构 + 自定义 Control 绘制） |
| QQ-03 | 经济系统 RP 在 Alpha 接入时的 bank cap 或折算机制 | Medium | WARNING D3 已在 GDD cross-review 记录，Alpha 阶段解决 |
| QQ-04 | 音频系统触发锚点何时从预留升级为完整集成 | Low | Beta 阶段（audio GDD 完成后） |
