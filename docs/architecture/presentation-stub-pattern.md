# Presentation-Stub Pattern

> **Status**: Active
> **Created**: 2026-07-10
> **Applies to**: All Presentation-layer UI stubs
> **Derived from**: S5-01 (Growth Summary), S5-02 (Town Grid), S5-03 (Audio Settings), S5-04 (Halftime)

## Overview

The Presentation-stub pattern is the project's standard template for adding new read-only UI surfaces that consume authoritative Core/Foundation payloads. It emerged from Sprint 3 (Home/Player/Training/Match exemplars) and matured through Sprint 5 (4 additional stubs). Every Sprint 5 UI stub followed this pattern with zero architectural drift.

## When to Use

Use this pattern when:
- Adding a new read-only UI surface to the MainLoop Shell
- The UI must consume authoritative payloads from a Core/Foundation system
- The UI must not compute gameplay truth (cost, eligibility, unlock, trigger)
- The producer system may not yet produce all fields — UI must degrade safely

Do NOT use this pattern for:
- Interactive gameplay flows (build/upgrade/demolish, training confirmation)
- Route-level screens managed by ScreenManager
- UI that owns or writes gameplay state

## Template

### 1. UI Panel (e.g., `src/ui/[name].gd`)

```gdscript
extends PanelContainer
## Read-only [name] panel consuming authoritative [System] state.
##
## [Brief description — what it displays, what authority it consumes,
##  what it does NOT implement.]

# ── Constants ──────────────────────────────────────────────
const UI_COLOR_TEXT := Color("3A2A1A")
const UI_COLOR_MUTED := Color("6D5A3A")
const UI_COLOR_ACCENT := Color("C76A00")

# ── State ──────────────────────────────────────────────────
var _root_box: VBoxContainer = null
var _title_label: Label = null
var _empty_placeholder: Label = null
var _authority_override = null  # for testing

# ── Lifecycle ──────────────────────────────────────────────
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    _setup_ui()
    _subscribe_events()
    _refresh()

func _exit_tree() -> void:
    EventBus.unsubscribe("[event_name]", _on_event)

# ── Public API (test injection) ────────────────────────────
func set_authority_for_testing(authority) -> void:
    _authority_override = authority
    _refresh()

# ── Authority Refresh ──────────────────────────────────────
func refresh_from_authority() -> void:
    # Read from authoritative source
    # If authority unavailable → fallback to neutral defaults
    # Update UI elements via set_value_no_signal() or direct assignment
    pass

# ── Internal ───────────────────────────────────────────────
func _setup_ui() -> void:
    # Create all child nodes once
    # Apply warm-town StyleBoxFlat styling
    # Connect signals
    # Do NOT read authority here — wait for _refresh()
    pass

func _subscribe_events() -> void:
    EventBus.subscribe("[event_name]", _on_event)

func _on_event(_event_name: String, _payload: Dictionary) -> void:
    _refresh()

func _refresh() -> void:
    # Check authority availability
    # If available → render content
    # If absent/empty → show neutral placeholder
    pass

func _localized_text(key: String, fallback: String) -> String:
    var localized := tr(key)
    return fallback if localized == key else localized
```

### 2. Shell Mount (in `src/ui/hud/main_loop_shell.gd`)

```gdscript
# ── Preload ────────────────────────────────────────────────
const [Name]Script: Script = preload("res://src/ui/[name].gd")

# ── Field ──────────────────────────────────────────────────
var _[name]: Control = null

# ── Setup (in _setup_container) ────────────────────────────
_[name] = [Name]Script.new() as Control
_[name].name = "[Name]"
_content_box.add_child(_[name])

# ── Visibility (in _set_shell_chrome_visible) ──────────────
if _[name] != null:
    _[name].visible = is_visible and _current_route == ROUTE_HOME
```

### 3. Integration Test (e.g., `tests/integration/ui/[name]_test.gd`)

```gdscript
extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null

func _ready() -> void:
    _setup_hud()
    await get_tree().process_frame
    test_[name]_mounts_in_home()
    test_[name]_shows_neutral_placeholder()
    test_[name]_consumes_authoritative_payload()
    _teardown_hud()
    await get_tree().process_frame
    if _failures.is_empty():
        print("[NAME]_TEST_PASS")
        get_tree().quit(0)
    else:
        for failure in _failures:
            push_error("[NAME]_TEST_FAIL: %s" % failure)
        get_tree().quit(1)

func _setup_hud() -> void:
    EventBus.clear_all()
    ScreenManager.reset_to_screen("home")
    _hud = HudScene.instantiate() as CanvasLayer
    add_child(_hud)
    _shell = _hud.get_node("MainLoopShell") as Control

func _teardown_hud() -> void:
    if _hud != null:
        _hud.queue_free()
    EventBus.clear_all()
    ScreenManager.reset_to_screen("home")
```

## Pattern Rules

### Required
- UI panel extends `PanelContainer` (or `Control` for simple cases)
- EventBus subscribe in `_ready()`, unsubscribe in `_exit_tree()`
- Authority consumed as read-only snapshot — UI never writes back except through designated setter entry points
- Neutral placeholder on missing/empty payload (never expose internal IDs, debug labels, or false interaction)
- Public `set_*_for_testing()` method for test injection
- `mouse_filter = Control.MOUSE_FILTER_PASS` on root panel
- Warm-town visual treatment: `UI_COLOR_*` constants matching Home exemplar palette

### Forbidden
- Never recompute gameplay truth (cost, eligibility, unlock conditions, trigger logic, adjacency bonuses)
- Never resolve authority through hardcoded `NodePath` or scene-tree search
- Never add new route IDs
- Never change `ScreenManager` behavior
- Never use `yield()`, `instance()`, or string-based `connect()`
- Never poll in `_process()` — event-driven refresh only

### Guardrails
- Frame budget: 60fps / 16ms (no per-frame work)
- Draw calls: within 500 ceiling
- Test: at minimum 3 test functions (mount check, neutral placeholder, authority consumption)
- Regression: L2 playable loop panels + walkthrough structure must remain PASS

## Shell Chrome Visibility Rules

When mounting in MainLoopShell via `_content_box`:
- Panel visible only on `ROUTE_HOME`
- Hidden on all other routes
- Use `_set_shell_chrome_visible(is_visible)` for route-aware toggle
- If panel has its own toggle button (e.g., settings gear), toggle overrides route visibility

## Pre-Implementation Checklist

Before writing code for a new Presentation stub:

- [ ] Governing ADR identified and Accepted
- [ ] Authority payload contract documented (which EventBus events? which query methods?)
- [ ] Neutral placeholder text chosen (Chinese + English fallback via `_localized_text`)
- [ ] Test file path determined (`tests/integration/ui/[name]_authoritative_payload_test.gd`)
- [ ] Mount location in MainLoopShell decided (before/after existing cards)
- [ ] Existing L2/walkthrough assertions reviewed for potential conflicts

## Known Edge Cases

### Autoload testing
When the authority is a new Autoload (like AudioManager):
- Register in `project.godot` autoload list before testing
- `EventBus.clear_all()` in test setup clears subscriptions but not emits — safe
- `await get_tree().process_frame` × 2 may be needed after panel toggle to allow full refresh propagation
- Lambda callbacks in `EventBus.subscribe()` may not work in all Godot versions — use named instance methods

### "Previously freed" references
When toggling panel visibility via button press + `await`:
- Re-fetch panel reference via `_find_control()` after each toggle cycle
- Objects may be re-parented or invalidated during shell route changes

### Progress indicators
- If total construction units / time units are not available to the UI, use a simple ColorRect stub rather than a ProgressBar
- Mark with `TODO(S[N]-followup)` for deferred completion
