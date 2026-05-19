# Control Manifest

> **Engine**: Godot 4.6
> **Last Updated**: 2026-05-19
> **Manifest Version**: 2026-05-19
> **ADRs Covered**: None (no Accepted ADR files found)
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

`Manifest Version` is the date this manifest was generated. Story files embed
this date when created. `/story-readiness` compares a story's embedded version
to this field to detect stories written against stale rules. Always matches
`Last Updated` — they are the same date, serving different consumers.

This manifest is a programmer's quick-reference extracted from Accepted ADRs,
technical preferences, and engine reference docs. For reasoning behind each
rule, see the source documents.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine initialisation*

### Required Patterns
- No Accepted ADR rules available yet.

### Forbidden Approaches
- No Accepted ADR rules available yet.

### Performance Guardrails
- No Accepted ADR guardrails available yet.

---

## Core Layer Rules

*Applies to: core gameplay loop, main player systems, physics, collision*

### Required Patterns
- No Accepted ADR rules available yet.

### Forbidden Approaches
- No Accepted ADR rules available yet.

### Performance Guardrails
- No Accepted ADR guardrails available yet.

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, secondary features*

### Required Patterns
- No Accepted ADR rules available yet.

### Forbidden Approaches
- No Accepted ADR rules available yet.

### Performance Guardrails
- No Accepted ADR guardrails available yet.

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, shaders, animations*

### Required Patterns
- No Accepted ADR rules available yet.

### Forbidden Approaches
- No Accepted ADR rules available yet.

### Performance Guardrails
- No Accepted ADR guardrails available yet.

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | `PascalCase` | `MatchSimulator`, `TownGrid`, `PlayerRoster` |
| Variables | `snake_case` | `current_funds`, `training_multiplier`, `match_result` |
| Signals/Events | `snake_case` + past-tense verb | `match_completed`, `facility_built`, `season_ended` |
| Files | `snake_case.gd` (scripts), `PascalCase.tscn` (scenes) | `time_manager.gd`, `TownHud.tscn` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_AP`, `BASE_MATCH_FUNDS`, `DEFAULT_WINDOW_SIZE` |

Source: `.claude/docs/technical-preferences.md`

### Performance Budgets

| Target | Value |
|--------|-------|
| Framerate | 60 fps |
| Frame budget | 16 ms/frame |
| Draw calls | 500 |
| Memory ceiling | 512 MB |

Source: `.claude/docs/technical-preferences.md`

### Approved Libraries / Addons

- **GUT (gdunit4)** — unit testing framework
- **TBD** — additional addons approved via `/architecture-decision`

Source: `.claude/docs/technical-preferences.md`

### Forbidden APIs (Godot 4.6)

These APIs are deprecated or forbidden by project rules and engine references.

#### Project forbidden patterns
- `yield()` — use `await`
- `instance()` — use `instantiate()`
- String-based `connect("signal", obj, "method")` — use `signal.connect(callable)`
- `$NodePath` in `_process()` — cache with `@onready var`
- Untyped `Array` / `Dictionary` — use typed arrays and typed dictionaries
- `TileMap` (single-node multi-layer) — use `TileMapLayer`
- Hardcoded game values in `src/` — use data-driven config/resources
- `GodotPhysics3D` — use Jolt Physics (if 3D physics is ever needed)

Source: `.claude/docs/technical-preferences.md`

#### Engine deprecated class/API entries
- `TileMap` → `TileMapLayer` (since 4.3)
- `VisibilityNotifier2D` → `VisibleOnScreenNotifier2D` (since 4.0)
- `VisibilityNotifier3D` → `VisibleOnScreenNotifier3D` (since 4.0)
- `YSort` → `Node2D.y_sort_enabled` (since 4.0)
- `Navigation2D` / `Navigation3D` → `NavigationServer2D` / `NavigationServer3D` (since 4.0)
- `EditorSceneFormatImporterFBX` → `EditorSceneFormatImporterFBX2GLTF` (since 4.3)
- `yield()` → `await signal` (since 4.0)
- `connect("signal", obj, "method")` → `signal.connect(callable)` (since 4.0)
- `instance()` → `instantiate()` (since 4.0)
- `PackedScene.instance()` → `PackedScene.instantiate()` (since 4.0)
- `get_world()` → `get_world_3d()` (since 4.0)
- `OS.get_ticks_msec()` → `Time.get_ticks_msec()` (since 4.0)
- `duplicate()` for nested resources → `duplicate_deep()` (since 4.5)
- `Skeleton3D` signal `bone_pose_updated` → `skeleton_updated` (since 4.3)
- `AnimationPlayer.method_call_mode` → `AnimationMixer.callback_mode_method` (since 4.3)
- `AnimationPlayer.playback_active` → `AnimationMixer.active` (since 4.3)

Source: `docs/engine-reference/godot/deprecated-apis.md`

#### Engine deprecated patterns
- String-based `connect()` → typed signal connections
- `$NodePath` in `_process()` → `@onready var` cached reference
- Untyped `Array` / `Dictionary` → typed forms
- `Texture2D` in shader parameters → `Texture` base type (changed in 4.4)
- Manual post-process viewport chains → `Compositor` + `CompositorEffect`
- GodotPhysics3D for new projects → Jolt Physics 3D

Source: `docs/engine-reference/godot/deprecated-apis.md`

### Cross-Cutting Constraints

- For Godot API usage that changed after LLM cutoff, verify against `docs/engine-reference/godot/` before implementation.
- Prefer Compatibility renderer settings for this pixel-art 2D management sim.
- All tuning/gameplay values in runtime code must be data-driven, not hardcoded.

Sources:
- `docs/engine-reference/godot/VERSION.md`
- `.claude/docs/technical-preferences.md`
