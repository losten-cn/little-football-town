# Technical Preferences

<!-- Written by /gate-check 2026-05-16. Read by all agents for project-specific standards. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: 2D (Compatibility renderer — pixel-art management sim; no 3D requirements)
- **Physics**: Not applicable (match simulation is formula-driven, town building is grid-based)

## Input & Platform

<!-- Written by /gate-check. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Windows primary; Linux secondary)
- **Input Methods**: Keyboard/Mouse
- **Primary Input**: Mouse-driven UI with keyboard shortcuts for power users
- **Gamepad Support**: None (management sim — not designed for controller input)
- **Touch Support**: None (PC-only; no mobile or tablet target)
- **Platform Notes**: Godot 4.6 defaults to D3D12 on Windows. For a pixel-art 2D game, ensure Compatibility renderer is explicitly set to avoid unnecessary rendering overhead.

## Naming Conventions

- **Classes**: `PascalCase` (e.g., `MatchSimulator`, `TownGrid`, `PlayerRoster`)
- **Variables**: `snake_case` (e.g., `current_funds`, `training_multiplier`, `match_result`)
- **Signals/Events**: `snake_case` with past-tense verbs (e.g., `match_completed`, `facility_built`, `season_ended`)
- **Files**: `snake_case.gd` for scripts, `PascalCase.tscn` for scenes
- **Scenes/Prefabs**: `PascalCase.tscn` (e.g., `TownHud.tscn`, `MatchFlow.tscn`, `PlayerRoster.tscn`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `MAX_AP`, `BASE_MATCH_FUNDS`, `DEFAULT_WINDOW_SIZE`)

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16 ms per frame
- **Draw Calls**: 500 (pixel-art 2D game — generous budget)
- **Memory Ceiling**: 512 MB (management sim with mostly static assets)

## Testing

- **Framework**: Custom headless script runner (Godot CLI)
- **Current Pattern**: Automated tests are Node-based GDScript scripts under `tests/unit/` and `tests/integration/`, launched headlessly via `tests/test_script_runner.gd` or story-specific `*_runner.gd` wrappers.
- **Migration Note**: GdUnit4 or GUT may be adopted later via a dedicated migration decision, but they are not the active project-standard framework today.
- **Minimum Coverage**: 70% on formula/logic systems (balance formulas, match simulation, economy settlement)
- **Required Tests**: All cross-system formulas registered in `design/registry/entities.yaml` must have unit tests with boundary-value inputs. All GDD acceptance criteria for Logic-type systems must map to at least one automated test.

## GDScript Typed Collection Boundaries

<!-- Added after typed Dictionary runtime failures in vertical slice UI/session flow, 2026-05-30. -->

- Keep `Dictionary[String, Variant]` and `Array[Type]` for stable API contracts in `src/`, save payloads, event payloads, and test assertions that validate production interfaces.
- Do not assign untyped runtime containers directly into typed dictionary variables. Values from `Variant`, `Dictionary.get(..., {})`, signal payloads, serialized resources, `duplicate(true)` on untyped sources, and untyped array elements must be normalized first.
- Preferred normalization helper for typed payload contracts:

  ```gdscript
  func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary
  ```

- In UI screens and prototypes, local view-only data pulled from session view models may use plain `Dictionary` when the code only reads scalar values for labels, buttons, or list metadata. Coerce scalars at use sites with `String()`, `int()`, `float()`, and `bool()`.
- For loops over `Array[Dictionary]` or untyped arrays returned from runtime systems, iterate as `Variant` or plain `Dictionary`, then normalize only when passing the data into a typed API.
- Every bug fix for typed collection boundary failures must include a regression test that exercises the original boundary path, such as binding a scene to its session and letting `_refresh()` run for at least one frame.

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- `yield()` — use `await` (deprecated since Godot 4.0)
- `instance()` — use `instantiate()` (deprecated since Godot 4.0)
- String-based `connect("signal", obj, "method")` — use `signal.connect(callable)` (deprecated since Godot 4.0)
- `$NodePath` in `_process()` — cache with `@onready var` (performance)
- Untyped `Array` / `Dictionary` for stable contracts — use `Array[Type]` and typed dictionaries for production APIs; plain local dictionaries are allowed at volatile UI/prototype `Variant` boundaries per "GDScript Typed Collection Boundaries" above
- `TileMap` (single-node multi-layer) — use `TileMapLayer` (since Godot 4.3)
- Hardcoded game values in `src/` — all tuning values must read from data-driven config (Custom Resources)
- GodotPhysics3D — use Jolt Physics (default since Godot 4.6, if physics ever needed)

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- **No required third-party test addon** — the active automated test path uses the project's custom headless runner
- **TBD** — additional addons approved via `/architecture-decision`

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — Foundation ADRs pending (scene management, event/signal, save/load, data-driven config)]

## Engine Specialists

<!-- Written by /gate-check 2026-05-16. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: `godot-specialist` — general Godot 4.6 architecture and patterns
- **Language/Code Specialist**: `godot-gdscript-specialist` — GDScript idioms, static typing, signal patterns
- **Shader Specialist**: `godot-shader-specialist` — visual shaders, post-processing (if needed)
- **UI Specialist**: `godot-specialist` (Godot UI patterns via Control nodes)
- **Additional Specialists**: `godot-csharp-specialist` (if C# is adopted for specific systems), `godot-gdextension-specialist` (if native extensions are needed)
- **Routing Notes**: `.gd` files route to `godot-gdscript-specialist`; `.tscn` files route to primary `godot-specialist`; `.gdshader` files route to `godot-shader-specialist`; `.cs` files route to `godot-csharp-specialist`

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row's specialist is unavailable, fall back to Primary. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (`.gd`) | `godot-gdscript-specialist` |
| Shader / material files (`.gdshader`, `.tres`) | `godot-shader-specialist` |
| UI / screen files (`.tscn` under `src/ui/`) | `godot-specialist` |
| Scene / prefab / level files (`.tscn` under `src/`) | `godot-specialist` |
| Native extension / plugin files (`.gdns`, `.gdextension`) | `godot-gdextension-specialist` |
| General architecture review | `godot-specialist` |

## Engine-Specific Test Commands

### Godot 4 (GDScript)
- Single unit/integration test: `godot --headless --path <project> --script res://tests/test_script_runner.gd -- --test-script=res://tests/unit/..._test.gd`
- Single integration test: `godot --headless --path <project> --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/..._test.gd`
- CI path: `.github/workflows/tests.yml` enumerates `*_test.gd` files and runs them through `tests/test_script_runner.gd`

### Unity (C#)
- Unit tests: `UnityTestRunner --runTests --testPlatform EditMode --testResults result.xml`
- PlayMode tests: `UnityTestRunner --runTests --testPlatform PlayMode --testResults result.xml`

### Unreal Engine 5 (C++ / Blueprint)
- Automation tests: `UnrealEditor-Cmd.exe ProjectName -ExecCmds="Automation RunTests <TestGroup>; Quit"`
- Note: UE5 testing requires a running editor instance. Agents should queue tests
  and request user to run via editor console.
