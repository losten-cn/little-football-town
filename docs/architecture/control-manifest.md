# Control Manifest

> **Engine**: Godot 4.6
> **Last Updated**: 2026-05-19
> **Manifest Version**: 2026-05-19
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

`Manifest Version` is the date this manifest was generated. Story files embed
this date when created. `/story-readiness` compares a story's embedded version
to this field to detect stories written against stale rules. Always matches
`Last Updated` — they are the same date, serving different consumers.

This manifest is a programmer's quick-reference extracted from all Accepted ADRs,
technical preferences, and engine reference docs. For the reasoning behind each
rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine initialisation*

### Required Patterns
- **All screen flows must use the Screen Stack pattern managed by `ScreenManager`; screens extend `Screen` and implement the lifecycle hooks `on_enter`, `on_leave`, `on_resume`, `on_pause`.** — source: ADR-0001
- **Use `push_screen` for drill-down navigation, `pop_screen` for back-navigation, and `replace_screen` for lateral screen changes.** — source: ADR-0001
- **All cross-screen communication must route through `EventBus`; no screen may access another screen's node tree directly.** — source: ADR-0001
- **Popped screens must be `queue_free()`d after `on_leave()` completes; the stack only keeps active screens.** — source: ADR-0001
- **`ScreenManager` must expose the active screen id and stack depth for save/load capture.** — source: ADR-0001
- **`EventBus` is the sole cross-system communication channel for Foundation→Core, Core→Core, and Core→UI messages.** — source: ADR-0002
- **Event payloads must be typed `Dictionary` values containing only serializable primitives or typed `Array[Dictionary]` data.** — source: ADR-0002
- **Gameplay and UI business logic must subscribe through `subscribe(event_name, callable)` and unsubscribe explicitly; `event_fired` is observability-only.** — source: ADR-0002
- **Event dispatch order must follow the fixed priority chain: `time_*` → `match_completed` → `league_*` → `economy_*` → `player_*` → `town_*` → `save_*`.** — source: ADR-0002
- **Autoload order must be `ConfigLoader → EventBus → TimeManager → SaveManager → ScreenManager`.** — source: ADR-0002
- **`TimeManager` must provide both synchronous pull access (`get_state`) and runtime push updates (time events).** — source: ADR-0002
- **`SaveManager` is the sole disk writer; Core systems only register `serialize()` / `deserialize()` contracts.** — source: ADR-0003
- **All gameplay tuning must load through `ConfigLoader` from typed Custom Resources under `res://config/`; invalid config must block startup.** — source: ADR-0004

### Forbidden Approaches
- **Never use `SceneTree.change_scene_to_file()` as the normal screen-flow architecture.** — it destroys stack semantics and breaks return-state preservation — source: ADR-0001
- **Never keep all screens permanently instantiated and toggle visibility as the primary screen architecture.** — it violates lifecycle and memory constraints — source: ADR-0001
- **Never couple producer and consumer systems through direct node-held signal wiring as the main architecture.** — source: ADR-0002
- **Never mix a hybrid communication model where Core systems call each other directly while UI alone uses EventBus.** — source: ADR-0002
- **Never consume the generic `event_fired` signal for gameplay or UI business logic.** — source: ADR-0002
- **Never put object references such as Nodes, Resources, or other runtime objects into EventBus payloads.** — they break decoupling and serialization assumptions — source: ADR-0002
- **Never allow Core systems to write save files directly.** — source: ADR-0003
- **Never use JSON, ConfigFile, or SQLite/GDExtension as the save architecture for this project.** — source: ADR-0003
- **Never define gameplay tuning as inline constants in `src/`.** — source: ADR-0004

### Performance Guardrails
- **Screen transitions**: target <1ms CPU per transition — source: ADR-0001
- **Active screen memory**: target <10MB — source: ADR-0001
- **Screen push load time**: target <200ms — source: ADR-0001
- **EventBus steady-state memory**: <50KB — source: ADR-0002
- **TimeManager startup work**: <1ms in `_ready()` — source: ADR-0002
- **Save/load total time**: load <500ms for a full save — source: ADR-0003
- **Config load**: all config resources combined <50ms — source: ADR-0004

---

## Core Layer Rules

*Applies to: core gameplay loop, main player systems, physics, collision*

### Required Patterns
- **Every Core system must register its serialization contract with `SaveManager` and restore only through the centralized load pipeline.** — source: ADR-0003
- **Deserialize Core systems in the fixed order `time → town → player → league → economy → match`.** — source: ADR-0003
- **Save migrations must be additive-forward; increment `save_version` only when schema changes.** — source: ADR-0003
- **Use `SaveSnapshot` Resource-based saves (`.tres`) with 3 manual slots plus 1 autosave slot.** — source: ADR-0003
- **Use `integrity_hash` as best-effort corruption detection and surface recovery/deletion flows on mismatch.** — source: ADR-0003
- **All config domains must be typed Custom Resources with a `validate()` contract enforced by `ConfigLoader`.** — source: ADR-0004
- **Core systems must access config through typed `ConfigLoader` properties, not string-keyed lookups.** — source: ADR-0004
- **Represent `Player` as `RefCounted`; represent the roster boundary as `PlayerRoster`; treat `effective` and positional ratings as derived-only values.** — source: ADR-0005
- **`PlayerDevelopment` must be a scene-instantiated Core system node, not a Foundation Autoload.** — source: ADR-0005
- **Training operations must be atomic: validate cost, deduct through accredited economy path, compute gains, apply gains, advance time, record history, emit events.** — source: ADR-0005
- **Represent match flow as a deterministic state machine with seeded RNG and an explicit halftime adjustment state.** — source: ADR-0006
- **Produce a standardized `MatchResultPacket` consumed by League, Economy, UI, and Time systems.** — source: ADR-0006
- **If a save occurs mid-match, abandon partial in-progress match state and restore to pre-match Entry state on load.** — source: ADR-0006
- **`EconomyManager.execute_transaction()` is the sole mutation path for Funds/AP/RP.** — source: ADR-0007
- **Validate all transactions before application and apply them atomically.** — source: ADR-0007
- **Keep a bounded recent transaction log and emit warning events from threshold checks.** — source: ADR-0007
- **Expose accredited economy entry points for caller-specific operations such as training cost and facility cost.** — source: ADR-0007
- **`TownBuilding` must be a scene-instantiated Core system node that owns the grid, facility registry, and facility formula surface.** — source: ADR-0008
- **Represent the town grid as a flat typed array indexed by coordinates, with `TownBuilding` as the authoritative gameplay-state owner.** — source: ADR-0008
- **Route all build/upgrade costs through `EconomyManager.accredit_facility_cost()`.** — source: ADR-0008
- **Advance construction timers on `time_phase_changed` and serialize in-progress timers.** — source: ADR-0008
- **Expose facility effects only through read-only formula/query methods for downstream systems.** — source: ADR-0008
- **Represent league state with typed runtime classes (`StandingsEntry`, `ScheduledMatch`, `LeagueSeason`).** — source: ADR-0009
- **Generate schedules deterministically at season start and keep them fixed for the season.** — source: ADR-0009
- **Update standings from `match_completed` events and finalize promotion/relegation on `time_season_ended`.** — source: ADR-0009
- **Keep league public APIs read-only to downstream systems.** — source: ADR-0009
- **Use a stable deterministic fallback key when MVP does not materialize a full head-to-head tiebreak matrix.** — source: ADR-0009
- **Use typed collections in GDScript for Core runtime data structures.** — source: technical-preferences.md
- **Check `FileAccess.store_*` return values when save code uses them.** — source: ADR-0003, current-best-practices.md
- **Use `duplicate_deep()` when duplicating nested resource trees for save/config-related workflows.** — source: ADR-0003, ADR-0004, current-best-practices.md

### Forbidden Approaches
- **Never serialize or persist derived player values such as `effective` or positional overall ratings.** — source: ADR-0005
- **Never model runtime players as individual Resource assets or plain nested Dictionaries.** — source: ADR-0005
- **Never introduce ECS/entity-component architecture for the player domain at current project scale.** — source: ADR-0005
- **Never implement match simulation as a one-shot black-box formula with no event flow.** — source: ADR-0006
- **Never build a physics-based real-time football simulation for MVP.** — source: ADR-0006
- **Never replace the explicit match state machine with a single generator function that removes halftime/state boundaries.** — source: ADR-0006
- **Never mutate Funds/AP/RP directly outside `execute_transaction()` / accredited paths.** — source: ADR-0007
- **Never split the economy into separate per-resource manager nodes.** — source: ADR-0007
- **Never use full event-sourcing as the economy architecture for MVP.** — source: ADR-0007
- **Never use Resource instances or Dictionary-keyed sparse maps as the authoritative town grid state model.** — source: ADR-0008
- **Never let a `TileMapLayer` own town gameplay state.** — presentation may render the grid, but `TownBuilding` remains the authority — source: ADR-0008
- **Never use nested Dictionary league state as the primary runtime model.** — source: ADR-0009
- **Never store runtime `LeagueSeason` state as a Resource asset or maintain external schedule files as the primary league schedule source.** — source: ADR-0009

### Performance Guardrails
- **Roster serialization**: <50ms for a full roster — source: ADR-0005
- **Player runtime memory**: ~25KB target for roster structures — source: ADR-0005
- **Full match simulation**: <20ms compute time — source: ADR-0006
- **Stored match result history**: ~400KB target for ~200 matches — source: ADR-0006
- **`execute_transaction()`**: <0.01ms — source: ADR-0007
- **Economy runtime memory**: <50KB — source: ADR-0007
- **Town operations/formula queries**: <0.01ms — source: ADR-0008
- **Town runtime memory**: <10KB — source: ADR-0008
- **League match update**: <0.01ms — source: ADR-0009
- **League runtime memory**: <10KB — source: ADR-0009
- **No Core system may exceed the global frame budget assumptions when queried from UI.** — source: technical-preferences.md

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, secondary features*

### Required Patterns
- **Match event generation must emit readable categorized events with minute, side, and narrative metadata.** — source: ADR-0006
- **Half-time tactical changes and substitutions must affect only the second half.** — source: ADR-0006
- **League season history must be capped by config retention, not allowed to grow without bound.** — source: ADR-0009
- **Promotion/relegation and next-tier resolution must be driven from finalized season results, not ad-hoc UI or simulation shortcuts.** — source: ADR-0009

### Forbidden Approaches
- **Never infer feature-level progression state from presentation order alone when tied-placement semantics matter.** — derive display semantics explicitly instead of trusting array order — source: ADR-0009

### Performance Guardrails
- **No additional feature-layer guardrails beyond the Core system budgets extracted above.**

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, shaders, animations*

### Required Patterns
- **UI screens must respect the `Screen` lifecycle and subscribe/unsubscribe from events at the correct lifecycle boundaries.** — source: ADR-0001, ADR-0002
- **UI is read-only over gameplay state; actions emit EventBus events rather than mutating Core state directly.** — source: architecture.md, ADR-0002
- **Keyboard/mouse is the only supported input method for this project.** — source: technical-preferences.md
- **For Godot 4.6, custom UI focus behavior must account for the dual-focus system.** — source: current-best-practices.md
- **When implementing accessible UI, use Godot Control-node accessibility support via AccessKit-aware patterns.** — source: current-best-practices.md
- **If the town grid is rendered visually, treat rendering nodes as presentation only; gameplay authority remains in `TownBuilding`.** — source: ADR-0008

### Forbidden Approaches
- **Never poll Core state from `_process()` for routine UI refresh when an EventBus update exists.** — source: ADR-0002
- **Never render the authoritative town/facility gameplay state directly out of `TileMapLayer` or other visual nodes.** — source: ADR-0008
- **Never design new controller/gamepad-first interaction patterns for MVP screens.** — source: technical-preferences.md

### Performance Guardrails
- **Windows builds must explicitly use the 2D Compatibility renderer for this pixel-art management sim.** — source: technical-preferences.md, current-best-practices.md
- **UI implementations must stay within the global 60fps / 16ms frame budget and 500 draw-call ceiling.** — source: technical-preferences.md

---

## Global Rules (All Layers)

### Naming Conventions
| Element | Convention | Example |
|---------|-----------|---------|
| Classes | `PascalCase` | `MatchSimulation` |
| Variables | `snake_case` | `current_funds` |
| Signals/Events | `snake_case` with past-tense verbs | `match_completed` |
| Files | `snake_case.gd` for scripts, `PascalCase.tscn` for scenes | `player_roster.gd`, `TownHud.tscn` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_AP` |

### Performance Budgets
| Target | Value |
|--------|-------|
| Framerate | 60 fps |
| Frame budget | 16 ms |
| Draw calls | 500 |
| Memory ceiling | 512 MB |

### Approved Libraries / Addons
- **GUT / gdunit4** — approved unit testing framework

### Engine-Derived Required Practices
- **Use `await`, not `yield()`.** — source: technical-preferences.md, deprecated-apis.md
- **Use `instantiate()`, not `instance()`.** — source: technical-preferences.md, deprecated-apis.md
- **Use callable-based typed signal connections, not string-based `connect()`.** — source: technical-preferences.md, deprecated-apis.md
- **Cache node references with `@onready var` instead of resolving `$NodePath` inside `_process()`.** — source: technical-preferences.md, deprecated-apis.md
- **Use typed `Array[Type]` / typed dictionaries instead of untyped collections.** — source: technical-preferences.md, deprecated-apis.md
- **Use `Time.get_ticks_msec()`, not `OS.get_ticks_msec()`.** — source: deprecated-apis.md
- **Use `duplicate_deep()` when copying nested resources that require true deep duplication.** — source: deprecated-apis.md, current-best-practices.md

### Forbidden APIs (Godot 4.6)
These APIs are deprecated or unverified for Godot 4.6:
- `TileMap` — use `TileMapLayer` for presentation-layer tile rendering only; never as gameplay-state authority
- `VisibilityNotifier2D` — use `VisibleOnScreenNotifier2D`
- `VisibilityNotifier3D` — use `VisibleOnScreenNotifier3D`
- `YSort` — use `Node2D.y_sort_enabled`
- `Navigation2D` / `Navigation3D` — use `NavigationServer2D` / `NavigationServer3D`
- `yield()` — use `await`
- `connect("signal", obj, "method")` — use `signal.connect(callable)`
- `instance()` / `PackedScene.instance()` — use `instantiate()` / `PackedScene.instantiate()`
- `get_world()` — use `get_world_3d()`
- `OS.get_ticks_msec()` — use `Time.get_ticks_msec()`
- `duplicate()` for nested resources — use `duplicate_deep()`
- `Skeleton3D.bone_pose_updated` — use `skeleton_updated`
- `AnimationPlayer.method_call_mode` — use `AnimationMixer.callback_mode_method`
- `AnimationPlayer.playback_active` — use `AnimationMixer.active`

### Cross-Cutting Constraints
- **All gameplay values must be data-driven and loaded from config, never hardcoded in gameplay code.** — source: technical-preferences.md, ADR-0004
- **All public story implementations must obey the Accepted ADRs referenced here; if a new requirement conflicts, update the ADR first.** — source: docs/CLAUDE.md, architecture process
- **Foundation Autoloads own cross-cutting boundaries; Core systems are scene-instantiated nodes unless an ADR explicitly says otherwise.** — source: ADR-0001, ADR-0005, ADR-0008, ADR-0009
- **The project is PC-only and mouse-first with keyboard shortcuts for power users; no touch or gamepad support should be assumed.** — source: technical-preferences.md
