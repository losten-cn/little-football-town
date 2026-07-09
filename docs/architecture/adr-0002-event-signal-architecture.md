# ADR-0002: Event/Signal Architecture + TimeManager

## Status

Accepted

## Date

2026-05-16

## Last Verified

2026-05-16

## Decision Makers

Technical Director, Godot Specialist

## Summary

ADR-0001 defined EventBus as an Autoload for cross-system communication but left its internal contract unspecified — no event naming convention, no payload schema, no priority resolution for simultaneous events. Meanwhile, the architecture requires a TimeManager Autoload to own the global timeline, phase state, and key node scheduling (match triggers, stage settlement, season boundaries). This ADR completes both gaps: it defines the EventBus contract that all 12 GDD systems depend on for decoupled communication, and establishes TimeManager as the 5th Autoload with a fixed signal contract for scheduling game events.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core — Signal Architecture + Time Management |
| **Knowledge Risk** | LOW — `Signal` system unchanged since Godot 4.0; `Node` Autoload pattern is stable |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/current-best-practices.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None — core Godot `Signal`, `Callable`, and `Node` APIs are stable since 4.0 |
| **Verification Required** | None — no post-cutoff API surface touched |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (EventBus already reserved as Autoload; ScreenManager defines Screen base class) |
| **Enables** | ADR-0003 (Save/Load — needs TimeManager state for save snapshot), ADR-0005 through ADR-0009 (all Core ADRs depend on EventBus contract) |
| **Blocks** | All Core system implementation stories — they cannot be written against an unspecified EventBus |
| **Ordering Note** | Must be Accepted before Core ADRs (0005-0009) reach Accepted status |

## Context

### Problem Statement

The architecture document defines 5 Core systems, 4 UI modules, and 5 Foundation Autoloads that must communicate without tight coupling. ADR-0001 reserved an EventBus but did not define its contract. Without a specified EventBus contract, every Core system ADR would invent its own communication pattern, leading to inconsistent integration. Separately, the time-and-season-progression-system GDD defines a detailed state machine (9 states, 6 formulas) and the architecture assigns it to a TimeManager Autoload, but no ADR defines TimeManager's signal contract or its position in the Autoload hierarchy.

### Constraints

- Godot 4.6 + GDScript — uses `Signal` as the native mechanism
- Cross-system notifications and asynchronous runtime events route through EventBus; direct cross-system authority access is allowed only through explicitly registered command/query contracts (ADR-0001 still forbids ad hoc cross-screen node coupling)
- EventBus must support both broadcast (one producer, N consumers) and targeted (one producer, one consumer) patterns
- TimeManager must be queryable synchronously (for save/load snapshot) but must emit signals for runtime events
- Event payloads must be serializable (save/load captures them for mid-event recovery)
- All signal signatures must be GDScript-type-safe (typed parameters, no untyped `Variant`)

### Requirements

- Event naming must be self-documenting — a developer reading a signal name should understand what happened and which system produced it
- Payload format must be uniform across all producers and consumers
- Simultaneous events (multiple key nodes landing on the same timeline position) must resolve deterministically
- TimeManager must expose both push (signal) and pull (get_state) interfaces
- The system must survive save/load mid-event without replaying past events

## Decision

### Part A: EventBus Contract

**EventBus is the sole cross-system channel for broadcast notifications and asynchronous runtime event delivery.** Foundation→Core, Core→Core, and Core→UI notifications route through EventBus. Registered accredited direct calls are also allowed when one authoritative owner exposes a stable command or query contract; ad hoc direct node coupling remains forbidden. When a direct command/query contract targets a scene-instantiated Core authority node, the caller must receive that authority reference through gameplay-root injection or a scene-owned service container/runtime registry — never through implicit global `class_name` access, hardcoded `NodePath`, or arbitrary scene-tree search.

**Event naming convention**: `{system_slug}_{action}_{past_tense_verb}`

| Producer | Signal name | Payload keys |
|----------|------------|--------------|
| TimeManager | `time_phase_changed` | `old_phase: String`, `new_phase: String` |
| TimeManager | `time_match_triggered` | `home_team_id: int`, `away_team_id: int`, `match_context: Dictionary` |
| TimeManager | `time_season_ended` | `season_number: int`, `final_standings: Array[Dictionary]` |
| TimeManager | `time_stage_settled` | `stage_number: int`, `stage_result: Dictionary` |
| PlayerDevelopment | `player_training_completed` | `player_id: int`, `gains: Dictionary`, `cost: Dictionary` |
| PlayerDevelopment | `player_milestone_reached` | `player_id: int`, `milestone: String`, `attribute: String` |
| MatchCompetition | `match_event_occurred` | `event_category: String`, `event_data: Dictionary`, `match_minute: int` |
| MatchCompetition | `match_completed` | `match_id: int`, `settlement_id: String`, `result_packet: Dictionary` |
| EconomyManager | `economy_balance_changed` | `resource_type: String`, `old_value: float`, `new_value: float`, `reason: String` |
| EconomyManager | `economy_warning_triggered` | `warning_type: String`, `current_value: float`, `threshold: float` |
| TownBuilding | `town_facility_completed` | `facility_id: int`, `facility_type: String`, `effects: Dictionary` |
| TownBuilding | `town_grid_changed` | `grid_snapshot: Array` |
| LeagueStructure | `league_standings_updated` | `standings: Array[Dictionary]`, `matchday: int` |
| LeagueStructure | `league_promotion_triggered` | `team_id: int`, `old_tier: int`, `new_tier: int` |
| SaveManager | `save_completed` | `slot: int`, `metadata: Dictionary` |
| SaveManager | `load_completed` | `slot: int`, `snapshot: Dictionary` |

**Payload contract**: Every payload is a typed `Dictionary`. Values must be GDScript primitive types or typed `Array[Dictionary]`. Object references (nodes, resources) are forbidden in payloads — they create coupling and break serialization. `match_completed` is a canonical envelope payload rather than a bare result body: `result_packet` remains the authoritative match-result body, while `match_id` and `settlement_id` provide schedule correlation and durable settlement correlation for downstream consumers.

**Event priority queue**: When multiple events are emitted in the same frame (e.g., match completion triggers standings update and balance change simultaneously), EventBus processes them in fixed priority order:

```
Priority order (higher = dispatched first):
  1. time_* events (Foundation scheduling — always first)
  2. match_completed (game result — consumed by multiple Core systems)
  3. league_* events (season structure — depends on match result)
  4. economy_* events (resource changes — depends on league + match)
  5. player_* events (growth feedback — depends on economy + match)
  6. town_* events (facility changes — lowest runtime impact)
  7. save_* events (meta — dispatched after all game state is consistent)
```

### Part B: EventBus Implementation

```gdscript
# src/autoload/event_bus.gd
extends Node

signal event_fired(event_name: String, payload: Dictionary)

`event_fired` is an observability signal for debugging, logging, tracing, and tooling. Gameplay and UI business logic must not consume `event_fired` directly; production consumers subscribe through `subscribe(event_name, callable)` only.

var _subscribers: Dictionary = {}  # {event_name: Array[Callable]}
var _event_queue: Array[Dictionary] = []
var _processing: bool = false


func emit(event_name: String, payload: Dictionary = {}) -> void:
    if _processing:
        _event_queue.append({name = event_name, payload = payload})
        return
    _dispatch(event_name, payload)


func subscribe(event_name: String, callable: Callable) -> void:
    if not _subscribers.has(event_name):
        _subscribers[event_name] = []
    _subscribers[event_name].append(callable)


func unsubscribe(event_name: String, callable: Callable) -> void:
    if _subscribers.has(event_name):
        _subscribers[event_name].erase(callable)


func _dispatch(event_name: String, payload: Dictionary) -> void:
    _processing = true
    event_fired.emit(event_name, payload)
    if _subscribers.has(event_name):
        for callback: Callable in _subscribers[event_name]:
            callback.call(payload)
    _processing = false

    # Process queued events in priority order
    if not _event_queue.is_empty():
        var queued: Array = _event_queue.duplicate()
        _event_queue.clear()
        queued.sort_custom(_priority_sort)
        for event: Dictionary in queued:
            _dispatch(event.name, event.payload)


func _priority_sort(a: Dictionary, b: Dictionary) -> bool:
    return _event_priority(a.name) < _event_priority(b.name)


func _event_priority(event_name: String) -> int:
    if event_name.begins_with("time_"): return 0
    if event_name == "match_completed": return 1
    if event_name.begins_with("league_"): return 2
    if event_name.begins_with("economy_"): return 3
    if event_name.begins_with("player_"): return 4
    if event_name.begins_with("town_"): return 5
    if event_name.begins_with("save_"): return 6
    return 10
```

### Part C: TimeManager Autoload

TimeManager is the 5th Autoload, loaded after EventBus and before SaveManager:

```
Autoload order: ConfigLoader → EventBus → TimeManager → SaveManager → ScreenManager
```

```gdscript
# src/autoload/time_manager.gd
extends Node

# State
var _timeline_position: float = 0.0
var _phase: String = "Planning"
var _season_number: int = 1
var _current_stage: int = 1
var _season_units_completed: float = 0.0
var _scheduled_matches: Array[Dictionary] = []
var _key_nodes: Array[Dictionary] = []

# Pull interface (for save/load, UI queries)
func get_state() -> Dictionary:
    return {
        timeline_position = _timeline_position,
        phase = _phase,
        season_number = _season_number,
        current_stage = _current_stage,
        season_units_completed = _season_units_completed,
        season_progress_ratio = _get_season_progress_ratio(),
        available_action_windows = _get_available_action_windows(),
        next_key_node = _get_next_key_node(),
    }

func get_available_windows() -> int:
    return _get_available_action_windows()

# Push interface (action time consumption → key node detection)
func advance_time(amount: float) -> void:
    _timeline_position += amount
    _check_key_nodes()

func register_match(match_data: Dictionary) -> void:
    _scheduled_matches.append(match_data)

# Internal
func _check_key_nodes() -> void:
    for match: Dictionary in _scheduled_matches:
        if _timeline_position >= match.position and not match.triggered:
            match.triggered = true
            EventBus.emit("time_match_triggered", {
                home_team_id = match.home_team_id,
                away_team_id = match.away_team_id,
                match_context = match.context
            })
    # Check stage settlement, season end, etc.
    if _get_season_progress_ratio() >= 1.0:
        EventBus.emit("time_season_ended", {
            season_number = _season_number,
            final_standings = []  # populated by LeagueStructure
        })

func serialize() -> Dictionary: ...
func deserialize(data: Dictionary) -> void: ...
```

### Part D: Subscription Responsibility

**Producers** (Core systems, TimeManager, SaveManager): call `EventBus.emit(event_name, payload)`. Never know who consumes their events.

**Consumers** (UI modules, downstream Core systems): call `EventBus.subscribe(event_name, callable)` in `_ready()` and `EventBus.unsubscribe()` in `_exit_tree()`. Business logic consumers must not implement runtime behavior off the generic `event_fired` signal.

**Screen-based consumers** (UI): subscribe in `on_enter()`, unsubscribe in `on_leave()`. This prevents hidden screens from processing events.

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                     EventBus (Autoload)                    │
│  ┌────────────────────────────────────────────────────┐  │
│  │ emit(event_name, payload)                           │  │
│  │ subscribe(event_name, callable)                     │  │
│  │ unsubscribe(event_name, callable)                   │  │
│  │ Signal: event_fired(event_name, payload)            │  │
│  │ Internal: priority queue, re-entrant guard          │  │
│  └────────────┬───────────────────────────────────┬───┘  │
│               │                                   │       │
│  ┌────────────┴──────────────┐   ┌────────────────┴────┐ │
│  │ PRODUCERS (emit)          │   │ CONSUMERS (subscribe)│ │
│  │ ┌───────────────────────┐ │   │ ┌─────────────────┐ │ │
│  │ │ TimeManager           │ │   │ │ MainLoopUI      │ │ │
│  │ │ PlayerDevelopment     │ │   │ │ PlayerMgmtUI    │ │ │
│  │ │ MatchCompetition      │ │   │ │ MatchPerfUI     │ │ │
│  │ │ EconomyManager        │ │   │ │ Onboarding      │ │ │
│  │ │ TownBuilding          │ │   │ │ LeagueStructure │ │ │
│  │ │ LeagueStructure       │ │   │ │ EconomyManager  │ │ │
│  │ │ SaveManager           │ │   │ │ PlayerDev.      │ │ │
│  │ └───────────────────────┘ │   │ └─────────────────┘ │ │
│  └───────────────────────────┘   └─────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative 1: Godot Native Direct Signals (no EventBus)

- **Description**: Systems declare their own signals and consumers directly `connect()` to producer nodes
- **Pros**: Zero infrastructure, uses Godot's built-in signal connection inspector, type-safe at connection time
- **Cons**: Tight coupling — consumer must hold a reference to the producer node; cannot decouple Core from UI (violates ADR-0001 rule: no screen accesses another screen's node tree); save/load cannot capture "which signals are currently connected"; testing requires full scene instantiation
- **Rejection Reason**: Violates ADR-0001's decoupling requirement. Direct connections would make Core systems depend on UI nodes being in the scene tree, breaking the Core→UI ownership boundary.

### Alternative 2: Ad hoc Hybrid — unregistered Core→Core direct calls plus EventBus side-by-side

- **Description**: Core systems directly call each other opportunistically, while other traffic still routes through EventBus without an explicit authority-contract registry
- **Pros**: Slightly less indirection for some high-frequency Core→Core operations; fewer allocations in isolated call paths
- **Cons**: Two communication patterns drift without one contract source of truth; direct calls become hard to distinguish from authority-approved command/query boundaries; save/load, review, and implementation guidance become inconsistent; new developers must guess when direct access is allowed
- **Rejection Reason**: The project accepts a registered hybrid authority model, not an ad hoc one. EventBus remains the required path for notifications and asynchronous events, while direct calls are allowed only through explicitly registered command/query authority contracts.

### Alternative 3: Resource-Based State Observation

- **Description**: Core systems write state to shared `Resource` objects; UI and other systems poll or use `changed` signals on the resource
- **Pros**: State is self-documenting; Godot Inspector can display live state during development
- **Cons**: Every state change creates a Resource mutation; Resources are not designed for high-frequency updates; polling in `_process()` wastes frame budget; difficult to capture "what happened" vs "what is the current state"
- **Rejection Reason**: EventBus already defined in ADR-0001. Resource-based observation adds complexity without benefit over the simpler signal pattern for this game's event-driven design.

## Consequences

### Positive

- All cross-system communication uses one pattern — any developer can trace an event from producer to consumer by grepping for the event name
- Core systems have zero references to UI modules — the architectural boundary is enforced by the communication mechanism
- Event replay and save/load are possible because events have uniform payloads
- TimeManager's contract is fully specified — downstream ADRs can reference its signals without ambiguity
- Priority queue guarantees deterministic resolution of simultaneous events (Scenario 3 from GDD cross-review)

### Negative

- Indirection cost: every cross-system message goes through EventBus.emit() → Dictionary allocation → callback dispatch
- Event name strings are not compiler-checked — a typo in an event name is a runtime bug
- TimeManager is a single point of failure for all time-dependent systems

### Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Event name typo causes silent failure | Medium | Low | EventBus logs warning for events with zero subscribers (debug mode); test suite verifies critical event chains end-to-end |
| Priority queue grows unbounded under event storm | Low | Low | Game design is turn-based (action → resolve → wait); event storms are architecturally impossible |
| TimeManager blocks scene load if _ready() is slow | Low | Medium | TimeManager._ready() only initializes defaults; all data comes from deserialize() or ConfigLoader |
| Re-entrant event dispatch causes stack overflow | Low | High | `_processing` flag prevents re-entrant dispatch; queued events are processed after current dispatch completes |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `time-and-season-progression-system.md` | Rule 14: "本系统必须为 UI 提供明确的可显示信息：当前日期/阶段、下一比赛节点、下一结算节点、剩余可安排窗口、当前赛季所处位置" | TimeManager.get_state() provides pull interface for all display fields; EventBus time_phase_changed signals push updates |
| `time-and-season-progression-system.md` | Rule 15: "当下游系统需要基于时间推进触发效果时，必须接入本系统的统一节点" | TimeManager is the sole time authority; all downstream systems subscribe via EventBus to time_* events |
| `time-and-season-progression-system.md` | Edge Case: "多个关键节点落在同一时间轴位置" | EventBus priority queue processes time events first, then match → league → economy → player → town in deterministic order |
| `match-competition-system.md` | Rule 20: "MVP 阶段比赛系统的首要目标是稳定验证赛前准备真的重要、比赛结果看得懂、赛后反馈能回到培养决策" | `match_completed` signal routes results to EconomyManager, LeagueStructure, PlayerDevelopment, and UI simultaneously via EventBus |
| `economy-management-system.md` | Rule 2: "任何下游系统不得直接修改三种资源的当前值" | `economy_balance_changed` is the only signal for resource state changes; consumers read-only |
| `save-and-load-system.md` | Edge Case: "存档读取时当前状态停在关键节点中途" | TimeManager state is captured atomically in SaveManager.save() via get_state(); restore goes to the nearest stable phase |
| `main-loop-ui-framework.md` | Rule 3: "信息刷新必须通过 EventBus 事件驱动" | All UI modules subscribe to EventBus events; no polling in _process() |
| All 12 system GDDs | Dependency bidirectionality rule | EventBus contract defines both producer and consumer sides of every cross-system communication |

## Performance Implications

- **CPU**: EventBus.dispatch() is O(1) per subscriber. With 5-10 subscribers per event and ~10 events per player action, total dispatch cost per action is <0.1ms. No per-frame work.
- **Memory**: _subscribers Dictionary holds ~50-80 Callable references (all UI + Core). Each event Dictionary is ~200-500 bytes and is garbage collected after dispatch. Steady-state memory < 50KB.
- **Load Time**: TimeManager._ready() initializes defaults only (no config file reads). Impact: <1ms.
- **Network**: Not applicable — single-player game.

## Migration Plan

Not applicable — no existing code. This is the first EventBus and TimeManager specification for the project.

## Validation Criteria

- [ ] EventBus correctly dispatches a test event to 3 subscribers and all 3 receive the correct payload
- [ ] EventBus logs a warning (debug mode) when an event is emitted with zero subscribers
- [ ] Priority queue dispatches `time_match_triggered` before `match_completed` before `economy_balance_changed` when all three are emitted in the same frame
- [ ] Re-entrant guard: emitting an event from within a subscriber callback queues the second event and dispatches it after the first completes
- [ ] TimeManager.get_state() returns correct values after advance_time(2.0)
- [ ] TimeManager emits `time_match_triggered` when timeline_position crosses a registered match position
- [ ] Screen subscribes in on_enter() and unsubscribes in on_leave(); event does not reach the unsubscribed screen
- [ ] All 16 signal names follow the `{system}_{action}_{past_tense}` convention

## Related

- ADR-0001: Scene Management & Autoload Architecture — defines EventBus and ScreenManager
- ADR-0003: Save/Load Persistence — depends on TimeManager state for save snapshots
- `docs/architecture/architecture.md` — master architecture document (v1.0)
