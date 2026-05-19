# ADR-0001: Scene Management & Autoload Architecture

## Status

Proposed

## Date

2026-05-16

## Last Verified

2026-05-16

## Decision Makers

Technical Director (gate-check B2 resolution), Godot Specialist

## Summary

Football Town has 5+ screens (town HUD, player roster, match flow, build mode, save/load) with no architectural specification for scene transitions or state persistence across transitions. This ADR establishes a Screen Stack pattern with Autoload singletons for cross-cutting concerns, ensuring clean transitions, predictable state, and minimal coupling between the 13 GDD-defined systems.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / UI |
| **Knowledge Risk** | LOW — scene management and Autoload are stable, well-documented features |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — core Godot feature unchanged since 4.0 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0002 (Event/Signal Architecture), ADR-0003 (Save/Load), ADR-0004 (Data-Driven Config) |
| **Blocks** | All UI implementation stories, screen transition logic |
| **Ordering Note** | Must be Accepted before any `.tscn` file is created under `src/ui/` |

## Context

### Problem Statement

The main-loop UI GDD (`main-loop-ui-framework.md`) describes 5+ distinct screens that the player navigates between: Town HUD, Player Roster, Match Flow, Build Mode, and Save/Load. Each screen has different visibility rules, different data dependencies, and different lifecycle requirements. Without a defined scene management architecture, screen transitions will be implemented ad-hoc, leading to memory leaks (screens not freed), state corruption (screens sharing stale data), and inconsistent back-navigation behaviour.

### Current State

No Godot project exists. No scenes, no scripts, no Autoload configuration. This ADR is the first architectural decision for the project.

### Constraints

- Godot 4.6 with GDScript (primary)
- 2D Compatibility renderer (pixel-art management sim)
- 5+ screens with frequent transitions (town → roster → match → town loop)
- Save/load must capture screen state for save-anywhere support
- Mouse-driven UI with keyboard shortcuts

### Requirements

- Screen transitions must be predictable and debuggable
- Screens must not leak memory when hidden
- The active screen must be queryable (for save/load state capture)
- Back-navigation must be consistent across all screens
- Screen data must be refreshable without full re-instantiation

## Decision

Use a **Screen Stack** pattern managed by an Autoload `ScreenManager`, with a fixed set of Autoload singletons for cross-cutting systems.

### Architecture

```
┌─────────────────────────────────────────────┐
│                  SceneTree                   │
│  ┌───────────────────────────────────────┐  │
│  │         Autoload Singletons            │  │
│  │  ┌──────────┐ ┌──────────┐ ┌───────┐  │  │
│  │  │EventBus  │ │SaveMgr   │ │Config │  │  │
│  │  └──────────┘ └──────────┘ └───────┘  │  │
│  │  ┌──────────────────────────────────┐  │  │
│  │  │        ScreenManager              │  │  │
│  │  │  screen_stack: Array[Screen]      │  │  │
│  │  │  push(path) / pop() / replace()   │  │  │
│  │  └──────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
│  ┌───────────────────────────────────────┐  │
│  │           Active Screen                │  │
│  │  (town-hud / player-roster /           │  │
│  │   match-flow / build-mode / save-load) │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Key Interfaces

```gdscript
# src/autoload/screen_manager.gd
extends Node

signal screen_pushed(screen_id: String)
signal screen_popped(screen_id: String)
signal screen_replaced(screen_id: String)

func push_screen(screen_path: String, data: Dictionary = {}) -> void
func pop_screen() -> void
func replace_screen(screen_path: String, data: Dictionary = {}) -> void
func get_active_screen_id() -> String
func get_screen_stack_depth() -> int
```

```gdscript
# src/ui/screen.gd (base class for all screens)
extends Control
class_name Screen

func on_enter(data: Dictionary) -> void: pass
func on_leave() -> void: pass
func on_resume() -> void: pass
func on_pause() -> void: pass
func can_pop() -> bool: return true
```

### Implementation Guidelines

1. **Screen base class**: All screens extend `Screen` (a `Control` subclass). ScreenManager calls lifecycle methods in order: `on_enter` (first show), `on_leave` (hide), `on_resume` (return from pushed screen), `on_pause` (covered by new screen).
2. **Screen stack**: Push for drill-down (town → roster → player detail), pop for back. Replace for lateral transitions (town tab switching within HUD).
3. **Data passing**: Screens receive data via `on_enter(data: Dictionary)`. No screen accesses another screen's node tree directly — all cross-screen communication goes through EventBus.
4. **Memory**: Popped screens are `queue_free()`d after `on_leave()` completes. The stack only holds references to active screens.
5. **Save state**: ScreenManager exposes `get_active_screen_id()` and `get_screen_stack_depth()` for save/load to capture UI state. SaveManager calls this before serializing.

## Alternatives Considered

### Alternative 1: Manual `change_scene_to_file()`

- **Description**: Use Godot's built-in `SceneTree.change_scene_to_file()` for every screen transition
- **Pros**: Simplest Godot-native approach, no custom infrastructure
- **Cons**: Destroys entire scene tree each transition (loses Autoload state snapshots), no back-stack, no data passing between screens, full reload of shared resources
- **Estimated Effort**: Lower initially, higher long-term
- **Rejection Reason**: Cannot support "return to previous screen with preserved state" — a core requirement from the main-loop UI GDD (players must be able to check roster mid-match-planning and return to where they were)

### Alternative 2: All screens as permanent children under a root Control

- **Description**: Instantiate all screens at startup, toggle visibility
- **Pros**: No instantiation overhead during transitions, all state always in memory
- **Cons**: Memory ceiling violation (all screens loaded simultaneously), no lifecycle guarantees, all screens process `_process()` unless explicitly disabled
- **Estimated Effort**: Medium
- **Rejection Reason**: Violates memory budget (512MB ceiling — 5+ fully populated screens with player data would consume significant memory). Also violates "screens must not leak memory" requirement.

## Consequences

### Positive

- Predictable screen lifecycle with defined enter/leave/resume/pause hooks
- Back-navigation is deterministic (stack-based, not ad-hoc boolean flags)
- Save/load can capture exact UI position by querying ScreenManager
- Screens are isolated — one screen cannot corrupt another's state

### Negative

- Small overhead from scene instantiation on each push (mitigated by Godot's packed scene caching)
- Requires discipline: all screen code must use the Screen base class and EventBus
- Adds one more Autoload (ScreenManager) to the three already defined

### Neutral

- Screen transition animations are deferred — they can be added as visual polish without changing the architecture

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Screen instantiation stutter on push | Low | Low | Pixel-art 2D scenes are lightweight; if stutter occurs, preload commonly-used scenes |
| Developer bypasses ScreenManager and uses `change_scene_to_file()` | Medium | Medium | Forbidden pattern in `technical-preferences.md`; code review catches this |
| Screen base class becomes a God Object | Low | Medium | Keep Screen base class to lifecycle hooks only; no game logic |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | N/A | <1ms per transition | 16ms |
| Memory | N/A | <10MB for active screens | 512MB |
| Load Time | N/A | <200ms per screen push | 500ms |

## Migration Plan

Not applicable — this is the first architectural decision. No existing code to migrate.

## Validation Criteria

- [ ] ScreenManager correctly pushes, pops, and replaces screens in a test scene with 3+ screens
- [ ] Popped screens are freed (verified via `is_instance_valid()` after pop)
- [ ] `get_active_screen_id()` returns the correct screen after push/pop/replace sequences
- [ ] Screen lifecycle callbacks fire in correct order: on_enter → on_pause → on_resume → on_leave → on_enter (for push-pop-repush)
- [ ] Back-navigation from any depth returns to the correct previous screen with preserved state

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/main-loop-ui-framework.md` | Main Loop UI | Screen navigation between Town HUD, Player Roster, Match Flow, Build Mode, Save/Load | ScreenManager provides the navigation infrastructure for all 5+ screens |
| `design/gdd/save-and-load-system.md` | Save/Load | Save must capture current UI state | `get_active_screen_id()` exposes UI position for save serialization |
| `design/gdd/game-concept.md` | Game Concept | 低压力长期成长 — players must be able to pause and save anywhere | ScreenManager's stack preserves exact UI position for save-anywhere |

## Related

- ADR-0002: Event/Signal Architecture — screens communicate via EventBus
- ADR-0003: Save/Load Persistence — ScreenManager exposes state for serialization
- ADR-0004: Data-Driven Configuration — ConfigLoader is an Autoload singleton
