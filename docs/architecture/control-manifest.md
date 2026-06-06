# Control Manifest

> **Engine**: Godot 4.6
> **Last Updated**: 2026-06-03
> **Manifest Version**: 2026-06-03
> **ADRs Covered**: ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011
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
- **All screen flows must use the Screen Stack pattern managed by `ScreenManager`; screens extend `Screen` and implement `on_enter`, `on_leave`, `on_resume`, and `on_pause`.** — source: ADR-0001
- **Use `push_screen` for drill-down navigation, `pop_screen` for back-navigation, and `replace_screen` for lateral screen changes.** — source: ADR-0001
- **Popped screens must be `queue_free()`d after `on_leave()` completes; the stack only keeps active screens.** — source: ADR-0001
- **`ScreenManager` must expose `get_active_screen_id()` and `get_screen_stack_depth()` for save/load capture.** — source: ADR-0001
- **Autoload order must be `ConfigLoader → EventBus → TimeManager → SaveManager → ScreenManager`.** — source: ADR-0002
- **`EventBus` is the sole cross-system communication channel for Foundation→Core, Core→Core, and Core→UI messages.** — source: ADR-0002
- **Gameplay and UI business logic must subscribe through `subscribe(event_name, callable)` and unsubscribe explicitly.** — source: ADR-0002
- **Event dispatch order must follow the fixed priority chain: `time_*` → `match_completed` → `league_*` → `economy_*` → `player_*` → `town_*` → `save_*`.** — source: ADR-0002
- **`TimeManager` must provide synchronous pull access through `get_state()` and runtime push updates through time events.** — source: ADR-0002
- **`SaveManager` is the sole disk writer; Core systems only register `serialize()` / `deserialize()` contracts.** — source: ADR-0003
- **Use `SaveSnapshot` Resource-based saves (`.tres`) with three manual slots plus one autosave slot.** — source: ADR-0003
- **Deserialize Core systems in the fixed order `time → town → player → league → economy → match`.** — source: ADR-0003
- **Save migrations must be additive-forward; increment `save_version` only when the save schema changes.** — source: ADR-0003
- **Save integrity must use a stable canonical serialized digest; runtime `hash(Dictionary)` is not an authoritative persistence checksum.** — source: ADR-0003
- **All gameplay tuning must load through `ConfigLoader` from typed Custom Resources under `res://config/`; invalid config must block startup.** — source: ADR-0004
- **All config domains must be typed Custom Resources with a `validate()` contract enforced by `ConfigLoader`.** — source: ADR-0004
- **Stable cross-system payloads must be top-level shallow typed dictionaries with explicitly sorted shallow record arrays.** — source: ADR-0010
- **EventBus and save payloads must transmit payload envelopes, not live object references.** — source: ADR-0010
- **Durable, event, and public payload boundaries must normalize inbound runtime `Dictionary` / `Variant` containers into `Dictionary[String, Variant]`.** — source: ADR-0010
- **SaveManager persists durable settlement outcomes and idempotency logs, not transient evaluation scratch state.** — source: ADR-0010
- **Reputation/Achievement save data must restore complete durable results only: reputation state, pending rewards, granted records, evaluated keys, and processed keys.** — source: ADR-0011

### Forbidden Approaches
- **Never use `SceneTree.change_scene_to_file()` as the normal screen-flow architecture.** — it destroys stack semantics and breaks return-state preservation — source: ADR-0001
- **Never keep all screens permanently instantiated and toggle visibility as the primary screen architecture.** — it violates lifecycle and memory constraints — source: ADR-0001
- **Never couple producer and consumer systems through direct node-held signal wiring as the main architecture.** — source: ADR-0002
- **Never mix a hybrid communication model where Core systems call each other directly while UI alone uses EventBus.** — source: ADR-0002
- **Never consume the generic `event_fired` signal for gameplay or UI business logic.** — source: ADR-0002
- **Never put Nodes, Resources, Objects, Callables, Variant blobs, live runtime containers, or runtime Dictionary hash order into EventBus/save payloads.** — source: ADR-0002, ADR-0010
- **Never allow Core systems to write save files directly.** — source: ADR-0003
- **Never use JSON, ConfigFile, or SQLite/GDExtension as the save architecture for this project.** — source: ADR-0003
- **Never define gameplay tuning as inline constants in `src/`.** — source: ADR-0004
- **Never persist half-resolved skill/trait evaluation passes or incomplete settlement queues as restorable state.** — source: ADR-0010
- **Never restore reputation/achievement partial results where durable truth exists without the matching idempotency ledgers or reward state.** — source: ADR-0011

### Performance Guardrails
- **Screen transitions**: target <1ms CPU per transition — source: ADR-0001
- **Active screen memory**: target <10MB — source: ADR-0001
- **Screen push load time**: target <200ms — source: ADR-0001
- **EventBus steady-state memory**: <50KB — source: ADR-0002
- **TimeManager startup work**: <1ms in `_ready()` — source: ADR-0002
- **Save/load total time**: load <500ms for a full save — source: ADR-0003
- **Typical save file size**: ~500KB typical, <2MB worst case per slot — source: ADR-0003
- **Config load**: all config resources combined <50ms — source: ADR-0004
- **Contract payload assembly**: event-boundary only, negligible frame cost — source: ADR-0010
- **Reputation/Achievement restoration**: no perceptible load-time regression from ledgers/reward records — source: ADR-0011

---

## Core Layer Rules

*Applies to: core gameplay loop, main player systems, physics, collision*

### Required Patterns
- **Every Core system must register its serialization contract with `SaveManager` and restore only through the centralized load pipeline.** — source: ADR-0003
- **Core systems must access config through typed `ConfigLoader` properties, not string-keyed lookups.** — source: ADR-0004
- **Represent `Player` as `RefCounted`; represent the roster boundary as `PlayerRoster`; treat `effective` attributes and positional ratings as derived-only values.** — source: ADR-0005
- **`PlayerDevelopment` must be a scene-instantiated Core system node, not a Foundation Autoload.** — source: ADR-0005
- **Player IDs must be monotonically increasing and never reused within a save.** — source: ADR-0005
- **Training operations must be atomic: validate cost, deduct through accredited economy path, compute gains, apply gains, advance time, record history, emit events.** — source: ADR-0005
- **Represent match flow as a deterministic state machine with seeded RNG and an explicit halftime adjustment state.** — source: ADR-0006
- **`team_match_strength` must be a MatchCompetition resolved output after lineup, position weights, chemistry, and allowed facility effects.** — source: ADR-0006, ADR-0010
- **Produce a standardized `MatchResultPacket` consumed by League, Economy, UI, and Time systems.** — source: ADR-0006
- **If a save occurs mid-match, abandon partial in-progress match state and restore to pre-match Entry state on load.** — source: ADR-0006
- **Half-time tactical changes and substitutions must affect only the second half.** — source: ADR-0006
- **`EconomyManager.execute_transaction()` is the sole mutation path for Funds/AP/RP.** — source: ADR-0007
- **Validate all transactions before application and apply them atomically.** — source: ADR-0007
- **Keep a bounded recent transaction log and emit warning events from threshold checks.** — source: ADR-0007
- **Expose accredited economy entry points for caller-specific operations such as training cost and facility cost.** — source: ADR-0007
- **Route all resource rewards from Reputation/Achievement through EconomyManager accredited entry points.** — source: ADR-0011
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
- **`match_completed` payloads must include `match_id` to correlate a result to `ScheduledMatch.match_id`.** — source: ADR-0009
- **Every cross-system payload must have exactly one authoritative writer.** — source: ADR-0010
- **Only a payload's authoritative writer may construct or mutate that payload's durable truth.** — source: ADR-0010
- **`match_day_ap_safety_grant` is written by EconomyManager and triggered by TimeManager authority.** — source: ADR-0010
- **`forfeit_result_packet` and `match_result_packet` are written by MatchCompetition and are durable result forms.** — source: ADR-0010
- **`pre_match_skill_trait_snapshot` is a MatchCompetition-owned live wrapper over the skill/trait read model, not a post-reload authority.** — source: ADR-0010
- **Skill/trait authority writes `pending_skill_trait_feedback`, `feedback_ack`, `candidate_progress_record`, `trait_cooldown_state`, and `player_identity_history_entry`.** — source: ADR-0010
- **Stable skill/trait settlement keys must be generated from canonical scalar fields only: `settlement_id`, `player_id`, `consumer_scope`, `rule_id`.** — source: ADR-0010
- **`rule_version` is persisted as metadata but must not enter skill/trait settlement-key inputs.** — source: ADR-0010
- **A settlement key is evaluated once; replays, duplicate delivery, reload recovery, and rule-version migration must check the evaluated-key log first.** — source: ADR-0010
- **Only evaluations that produce durable outcomes are also written to the processed-key log.** — source: ADR-0010
- **Skill/trait state changes, candidate deltas, cooldown deltas, feedback, identity history, acknowledgement seeds, evaluated keys, and processed keys produced by one settlement must commit as one durable result.** — source: ADR-0010
- **`ReputationAchievementManager` is the single authoritative writer for reputation total, level, progress, achievements, rewards, evaluated keys, and processed keys.** — source: ADR-0011
- **Build `reputation_settlement_key` from `settlement_id`, `reward_scope`, and `reward_id`; exclude `rule_version` from the key source.** — source: ADR-0011
- **Maintain both `evaluated_reputation_settlement_keys` and `processed_reputation_settlement_keys`.** — source: ADR-0011
- **Use `pending_reputation_rewards` plus `granted_reputation_reward_records` as the durable reward model.** — source: ADR-0011
- **Recover `reputation_progress_ratio` by validating it against `reputation_total`, current level, and threshold tables; recompute when inconsistent.** — source: ADR-0011
- **Random Event reputation facts with unmapped `effect_request_type` must return idempotent safe no-op.** — source: ADR-0011
- **Use typed collections in GDScript for stable Core runtime data structures and payload contracts.** — source: technical-preferences.md
- **Check `FileAccess.store_*` return values when save code uses them.** — source: ADR-0003, current-best-practices.md
- **Use `duplicate_deep()` when duplicating nested resource trees that need true deep copies.** — source: ADR-0003, ADR-0004, current-best-practices.md

### Forbidden Approaches
- **Never serialize or persist derived player values such as `effective` attributes or positional overall ratings.** — source: ADR-0005
- **Never model runtime players as individual Resource assets, plain Dictionaries, or ECS entities at current project scale.** — source: ADR-0005
- **Never recompute confirmed training gain from history during load.** — source: ADR-0005
- **Never implement match simulation as a one-shot black-box formula with no event flow.** — source: ADR-0006
- **Never build a physics-based real-time football simulation for MVP.** — source: ADR-0006
- **Never replace the explicit match state machine with a single generator function that removes halftime/state boundaries.** — source: ADR-0006
- **Never mutate Funds/AP/RP directly outside `execute_transaction()` / accredited paths.** — source: ADR-0007
- **Never split the economy into separate per-resource manager nodes or use full event-sourcing for MVP.** — source: ADR-0007
- **Never use Resource instances or Dictionary-keyed sparse maps as the authoritative town grid state model.** — source: ADR-0008
- **Never let a `TileMapLayer` own town gameplay state.** — presentation may render the grid, but `TownBuilding` remains the authority — source: ADR-0008
- **Never use nested Dictionary league state as the primary runtime model.** — source: ADR-0009
- **Never store runtime `LeagueSeason` state as a Resource asset or maintain external schedule files as the primary league schedule source.** — source: ADR-0009
- **Never hash runtime `Dictionary` instances, unordered Variant containers, display-only fields, null-defaulted fields, or UI/migration alternate formats into stable settlement keys.** — source: ADR-0010
- **Never embed `rule_version` in settlement-key inputs.** — source: ADR-0010, ADR-0011
- **Never let UI or migration layers generate alternate settlement-key formats.** — source: ADR-0010
- **Never replay settlement side effects during migration.** — source: ADR-0010
- **Never directly modify economic resource balances from `ReputationAchievementManager`.** — source: ADR-0011
- **Never move a granted reputation reward back to `pending_reputation_rewards` after restore.** — source: ADR-0011

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
- **Cross-system payload and settlement-contract overhead**: negligible and event-boundary only — source: ADR-0010
- **Reputation/Achievement ledger and reward-state memory**: bounded to necessary stable IDs and metadata; avoid display redundancy — source: ADR-0011

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, secondary features*

### Required Patterns
- **Match event generation must emit readable categorized events with minute, side, and narrative metadata.** — source: ADR-0006
- **Match result analysis must produce win reasons for player-facing review.** — source: ADR-0006
- **League season history must be capped by config retention, not allowed to grow without bound.** — source: ADR-0009
- **Promotion/relegation and next-tier resolution must be driven from finalized season results, not ad-hoc UI or simulation shortcuts.** — source: ADR-0009
- **Skill/trait candidate, cooldown, feedback, acknowledgement, identity-history, and migration records must follow the canonical payload ownership map.** — source: ADR-0010
- **First-display ownership for Alpha skill/trait feedback is unique per feedback key; `first_surface_id` may only be `match_result` or `main_loop`.** — source: ADR-0010
- **Player Detail may show history, reread entries, and acknowledgement state, but must not render a feedback record as a first-time new prompt.** — source: ADR-0010
- **Stable settlement keys are the idempotency boundary for skill/trait unlocks, upgrades, trait trigger records, acknowledgement facts, and durable feedback creation.** — source: ADR-0010
- **Reputation/Achievement consumes only confirmed facts from upstream systems.** — source: ADR-0011
- **Random Event `target_scope = reputation` confirmed facts must provide `event_settlement_key` or an equivalent stable settlement ID.** — source: ADR-0011
- **If a random-event fact maps to reputation recognition, its `event_settlement_key` must directly feed or stably source the reputation `settlement_id`.** — source: ADR-0011

### Forbidden Approaches
- **Never infer feature-level progression state from presentation order alone when tied-placement semantics matter.** — derive display semantics explicitly instead of trusting array order — source: ADR-0009
- **Never let each consumer build its own gameplay-truth view model for cross-system contracts.** — source: ADR-0010
- **Never move all cross-system contracts into one global mega-payload.** — source: ADR-0010
- **Never make unconfirmed process state from match, league, player development, town building, random events, or time progression a reputation/achievement input.** — source: ADR-0011
- **Never require Random Event to re-settle because Reputation/Achievement received an unmapped recognition request.** — source: ADR-0011

### Performance Guardrails
- **Feature-layer settlement work must occur at stable event/settlement boundaries, not per-frame.** — source: ADR-0010, ADR-0011
- **Reputation/Achievement key calculation, ledger checks, and payload assembly should remain negligible within the 16ms frame budget.** — source: ADR-0011

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, shaders, animations*

### Required Patterns
- **UI screens must respect the `Screen` lifecycle and subscribe/unsubscribe from events at the correct lifecycle boundaries.** — source: ADR-0001, ADR-0002
- **Screen-based UI consumers must subscribe in `on_enter()` and unsubscribe in `on_leave()`.** — source: ADR-0002
- **UI modules must consume snapshots, explanations, labels, acknowledgement flags, and visibility stages as read-only payloads.** — source: ADR-0010
- **If a UI screen needs a new display field, add it to the authoritative payload by the owning Core system before presenting it.** — source: ADR-0010
- **UI owns only labeling and visual framing for resolved strength comparisons.** — source: ADR-0010
- **Reputation/Achievement UI must consume `reputation_view_payload` and `achievement_view_payload` from `ReputationAchievementManager`.** — source: ADR-0011
- **Reputation/Achievement completion, claimability, claimed state, and progress displays must come from authoritative payload fields.** — source: ADR-0011
- **For Godot 4.6, custom UI focus behavior must account for the dual-focus system.** — source: current-best-practices.md
- **When implementing accessible UI, use Godot Control-node accessibility support via AccessKit-aware patterns.** — source: current-best-practices.md
- **If the town grid is rendered visually, treat rendering nodes as presentation only; gameplay authority remains in `TownBuilding`.** — source: ADR-0008
- **Keyboard/mouse is the only supported input method for this project.** — source: technical-preferences.md

### Forbidden Approaches
- **Never poll Core state from `_process()` for routine UI refresh when an EventBus update exists.** — source: ADR-0002
- **Never recompute whether a skill unlocks, trait triggers, candidate threshold is crossed, forced forfeit is valid, settlement should deduplicate, or what actual `team_match_strength` is.** — source: ADR-0010
- **Never recompute reputation completion, claimability, current progress truth, or reward grant state in UI.** — source: ADR-0011
- **Never use hover, keyboard focus, control expansion state, or local UI cache to infer long-term reputation/achievement truth.** — source: ADR-0011
- **Never render the authoritative town/facility gameplay state directly out of `TileMapLayer` or other visual nodes.** — source: ADR-0008
- **Never design new controller/gamepad-first, touch-first, or mobile interaction patterns for MVP screens.** — source: technical-preferences.md

### Performance Guardrails
- **Windows builds must explicitly use the 2D Compatibility renderer for this pixel-art management sim.** — source: technical-preferences.md, current-best-practices.md
- **UI implementations must stay within the global 60fps / 16ms frame budget and 500 draw-call ceiling.** — source: technical-preferences.md
- **UI should prefer scalar, label-ready, or enum-ready fields over exposing internal computation structures.** — source: ADR-0010

---

## Global Rules (All Layers)

### Naming Conventions
| Element | Convention | Example |
|---------|-----------|---------|
| Classes | `PascalCase` | `MatchSimulator` |
| Variables | `snake_case` | `current_funds` |
| Signals/Events | `snake_case` with past-tense verbs | `match_completed` |
| Files | `snake_case.gd` for scripts, `PascalCase.tscn` for scenes | `player_roster.gd`, `TownHud.tscn` |
| Scenes/Prefabs | `PascalCase.tscn` | `MatchFlow.tscn` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_AP` |

### Performance Budgets
| Target | Value |
|--------|-------|
| Framerate | 60 fps |
| Frame budget | 16 ms |
| Draw calls | 500 |
| Memory ceiling | 512 MB |

### Approved Libraries / Addons
- **No required third-party test addon** — the active automated test path uses the project's custom headless runner.
- **TBD** — additional addons require approval through `/architecture-decision`.

### Engine-Derived Required Practices
- **Use `await`, not `yield()`.** — source: technical-preferences.md, deprecated-apis.md
- **Use `instantiate()`, not `instance()`.** — source: technical-preferences.md, deprecated-apis.md
- **Use callable-based typed signal connections, not string-based `connect()`.** — source: technical-preferences.md, deprecated-apis.md
- **Cache node references with `@onready var` instead of resolving `$NodePath` inside `_process()`.** — source: technical-preferences.md, deprecated-apis.md
- **Use `Array[Type]` and `Dictionary[String, Variant]` for stable production contracts, save payloads, event payloads, and test assertions.** — source: technical-preferences.md
- **Normalize untyped runtime containers before assigning them to typed dictionary variables.** — source: technical-preferences.md, ADR-0010
- **Use `Time.get_ticks_msec()`, not `OS.get_ticks_msec()`.** — source: deprecated-apis.md
- **Use `duplicate_deep()` when copying nested resources that require true deep duplication.** — source: deprecated-apis.md, current-best-practices.md
- **Use Jolt Physics 3D if 3D physics is ever introduced; 2D physics remains Godot Physics 2D.** — source: current-best-practices.md
- **Use `rg --glob "*.gd"` or Grep `glob: "*.gd"` for GDScript searches; `rg --type gdscript` is invalid.** — source: current-best-practices.md

### Forbidden APIs (Godot 4.6)
These APIs are deprecated or unverified for Godot 4.6:
- `TileMap` — use `TileMapLayer`
- `VisibilityNotifier2D` — use `VisibleOnScreenNotifier2D`
- `VisibilityNotifier3D` — use `VisibleOnScreenNotifier3D`
- `YSort` — use `Node2D.y_sort_enabled`
- `Navigation2D` / `Navigation3D` — use `NavigationServer2D` / `NavigationServer3D`
- `EditorSceneFormatImporterFBX` — use `EditorSceneFormatImporterFBX2GLTF`
- `yield()` — use `await signal`
- `connect("signal", obj, "method")` — use `signal.connect(callable)`
- `instance()` / `PackedScene.instance()` — use `instantiate()` / `PackedScene.instantiate()`
- `get_world()` — use `get_world_3d()`
- `OS.get_ticks_msec()` — use `Time.get_ticks_msec()`
- `duplicate()` for nested resources — use `duplicate_deep()`
- `Skeleton3D.bone_pose_updated` — use `skeleton_updated`
- `AnimationPlayer.method_call_mode` — use `AnimationMixer.callback_mode_method`
- `AnimationPlayer.playback_active` — use `AnimationMixer.active`
- `GodotPhysics3D` for new 3D work — use Jolt Physics 3D

### Cross-Cutting Constraints
- **All gameplay values must be data-driven and loaded from config, never hardcoded in gameplay code.** — source: technical-preferences.md, ADR-0004
- **All public story implementations must obey the Accepted ADRs referenced here; if a new requirement conflicts, update the ADR first.** — source: docs/CLAUDE.md, architecture process
- **Foundation Autoloads own cross-cutting boundaries; Core systems are scene-instantiated nodes unless an ADR explicitly says otherwise.** — source: ADR-0001, ADR-0005, ADR-0008, ADR-0009
- **The project is PC-only and mouse-first with keyboard shortcuts for power users; no touch or gamepad support should be assumed.** — source: technical-preferences.md
- **Stable keys must be deterministic scalar contracts, not display labels, runtime container hashes, or UI-derived strings.** — source: ADR-0003, ADR-0010, ADR-0011
- **Warnings are allowed during convergence, but any implementation that crosses a stable payload, save/load, or settlement boundary must follow this manifest before story work proceeds.** — source: ADR-0010, ADR-0011
