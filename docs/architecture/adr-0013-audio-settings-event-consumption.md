# ADR-0013: Audio Settings & Event Consumption

## Status
Accepted

## Date
2026-06-28

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Audio |
| **Knowledge Risk** | HIGH |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/modules/audio.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None — Godot 4.4–4.6 has no verified audio-specific breaking API changes for this ADR's chosen patterns. |
| **Verification Required** | Verify bus mapping validation, save/load restore timing, stable UI event routing under Godot 4.6 dual-focus behavior, missing-asset silent degradation, and same-window priority/suppression behavior before shipping. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 Event/Signal Architecture; ADR-0003 Save/Load Persistence |
| **Enables** | Audio settings UI implementation, production audio integration, and future audio content/data authoring against a stable runtime contract |
| **Blocks** | Audio settings work, production audio event integration, and any implementation that would otherwise invent its own audio preference or event-consumption contract |
| **Ordering Note** | This ADR should be Accepted before implementing audio settings UI, SaveManager persistence for `audio_*` preferences, or any production audio event-consumption layer. |

## Context

### Problem Statement

The current architecture and GDD set require audio to behave as a low-pressure Presentation-layer system that consumes only stable gameplay/UI events, never mutates gameplay or navigation truth, silently degrades when audio assets are unavailable, and preserves player playback preferences across save/load. However, the project does not yet have an Accepted ADR that defines who owns `audio_master_volume`, `audio_bgm_volume`, `audio_sfx_volume`, `audio_ambience_volume`, and `audio_muted_categories`; how audio consumes normalized events from EventBus and UI; how same-window playback priority and suppression are resolved; or how SaveManager restores these settings without creating a second source of truth.

Without this ADR, audio settings, UI containers, event consumers, and persistence code could drift into contradictory ownership models:
- MainLoopUI could begin owning audio settings semantics even though its GDD only grants it a temporary container role.
- Individual screens or gameplay systems could play sounds directly and bypass the EventBus contract.
- Save/load could persist audio fields without a clear runtime owner.
- Runtime playback heuristics could start inferring gameplay truth from transient focus, hover, or local state.

### Constraints

- Cross-system communication must use EventBus and must not use direct cross-system signal wiring (`docs/registry/architecture.yaml`).
- SaveManager remains the only disk I/O owner; audio must not persist itself directly.
- MainLoopUI may host the minimum settings container, but it does not own mixing formulas, defaults, or durable semantics.
- Audio is a Presentation/Beta system and must not mutate gameplay systems, navigation state, time progression, or settlement truth.
- Godot 4.6 introduces dual-focus UI behavior changes; raw focus/hover changes are not a safe source of stable semantic audio triggers.
- Audio feedback must preserve the project's low-pressure tone and must not create urgency, punishment loops, or warning-alarm semantics for normal management outcomes.

### Requirements

- Audio must consume only stable EventBus events and normalized UI interaction/screen events.
- Audio preference fields must be durable playback settings only and must never affect gameplay or navigation outcomes.
- Missing assets, invalid event mappings, and missing bus mappings must fail safely for players.
- Same-window audio events must support priority, merge, delay, cooldown, and suppression rules without becoming a second gameplay event source.
- Runtime audio implementation must be idiomatic for Godot 4.6 and must separate persistent user preference control from transient fades/ducking/crossfades.
- Save/load restore must be deterministic and must apply restored settings only after the audio runtime is ready.

## Decision

The project adopts a single `AudioManager` runtime authority for audio playback preferences and stable event consumption.

`AudioManager` is a long-lived Node-based runtime system implemented as an Autoload rather than a static utility, pure data object, or scene-local helper. This is required because it owns event subscriptions, runtime playback ledgers, pooled `AudioStreamPlayer` instances, and tween-driven transitions that depend on a live node lifecycle in Godot 4.6.

### Decision Summary

1. **Runtime ownership**
   - `AudioManager` is the sole runtime owner of:
     - `audio_master_volume`
     - `audio_bgm_volume`
     - `audio_sfx_volume`
     - `audio_ambience_volume`
     - `audio_muted_categories`
   - Other systems may request edits or read authoritative snapshots, but they do not own these fields.

2. **Read-only event consumption boundary**
   - `AudioManager` is a read-only consumer of stable EventBus events and normalized UI interaction/screen events.
   - It must not infer gameplay truth from transient focus, hover, partially initialized UI state, or generic runtime observation.
   - It must never mutate gameplay state, navigation state, save state, or settlement truth in response to audio playback decisions.
   - It must not implement business logic off ADR-0002's generic `event_fired` observability signal.

3. **Cross-system communication pattern**
   - All audio event intake uses `EventBus.subscribe()` / `EventBus.unsubscribe()` patterns established by ADR-0002.
   - Gameplay systems and UI modules must not wire direct cross-system signals into audio playback.
   - Screen/UI systems are responsible for emitting normalized, semantically stable events when audio should react to screen entry, screen exit, button confirmation, or other UI-level playback anchors.

4. **Playback implementation boundary**
   - `AudioManager` maps stable semantic events into playback requests for BGM, ambience, SFX, and short stingers.
   - It applies category preferences using Godot audio buses and pooled `AudioStreamPlayer` nodes.
   - Missing streams, unknown event mappings, unknown categories, or missing bus mappings degrade safely to no-op or configured lightweight fallback behavior for players.
   - Development builds may emit rate-limited diagnostic warnings for these failures; release behavior remains silent and non-blocking.

5. **Preference control separation**
   - Persistent player preferences are represented at the bus/category control layer.
   - Temporary runtime fades, ducking, and crossfades must be applied at the player layer or dedicated transient mixing layer rather than overwriting durable preference truth.
   - This prevents a BGM transition or stinger ducking pass from corrupting the player's saved preference values.

6. **Persistence boundary**
   - `AudioManager` registers serialize/deserialize callables with SaveManager under ADR-0003's persistence contract.
   - SaveManager remains the only owner of disk writes and disk reads.
   - Durable audio preference state must be stored through ADR-0003's registered durable-state extension boundary as a dedicated `audio_state` payload (or equivalently named AudioManager-owned state blob), not as UI-local state, ad hoc metadata stuffing, a canonical Core gameplay top-level field, or a second independent persistence path.
   - `audio_state` participates in SaveManager-managed integrity validation as durable preference truth even though it is not promoted to canonical Core gameplay state.
   - Restored `audio_*` fields affect playback configuration only; they must not affect gameplay formulas, settlement outcomes, or UI navigation rules.

7. **Two-phase restore rule**
   - Audio preference restore is a two-phase process:
     1. SaveManager restores `audio_state` during ADR-0003's registered durable-state extension phase and passes those durable values to `AudioManager.deserialize_audio_settings()`.
     2. `AudioManager` applies those values only after its Autoload runtime, bus mappings, and playback infrastructure are ready.
   - As an Autoload runtime authority, `AudioManager` must complete EventBus subscription setup and SaveManager registration before it treats restored values as fully applied.
   - This avoids partially restored audio state caused by applying preferences before node initialization or bus lookup has completed.
   - Older saves that do not contain `audio_state` must fall back to default audio preferences without blocking load.

8. **Same-window playback policy**
   - `AudioManager` owns a presentation-only playback ledger/queue for priority, merge, delay, cooldown, and suppression within the same stable window.
   - This ledger is not a gameplay event queue and must not become a second source of gameplay truth.
   - Its job is only to decide how already-confirmed audio-worthy events are rendered sonically.

9. **UI ownership boundary**
   - MainLoopUI temporarily owns the minimum settings container and forwards user edits to `AudioManager`.
   - It does not own audio defaults, mixing formulas, playback truth, or durable semantics.
   - If a dedicated Settings/Options UI is created later, it follows the same boundary.

10. **Low-pressure tone boundary**
    - Audio feedback for losses, shortages, maintenance fees, weak outcomes, and similar negative-but-normal management results must remain soft, suppressible, and non-punitive.
    - The audio layer may reinforce emotion but must not create alarm, crisis, countdown, or punishment semantics that contradict the GDD tone.

### Architecture Diagram

```text
                           ┌─────────────────────────────┐
                           │        SaveManager          │
                           │ register_system()           │
                           │ save/load only disk owner   │
                           └──────────────┬──────────────┘
                                          │ serialize/deserialize
                                          │
┌────────────────────┐     stable events  ▼
│ Gameplay / Core    │ ───────────────────────▶ ┌─────────────────────────────┐
│ systems            │                          │        AudioManager         │
│ Match / Economy /  │                          │ Node/Autoload runtime owner │
│ Town / RandomEvent │                          │ - audio_* preference truth  │
└─────────┬──────────┘                          │ - playback ledger/queue     │
          │                                      │ - bus mapping validation    │
          │ EventBus.emit()                      │ - pooled players / tweens   │
          ▼                                      └───────┬───────────┬─────────┘
┌────────────────────┐                                  │           │
│      EventBus      │                                  │           │
│ subscribe/unsub    │                                  │           │
└─────────┬──────────┘                                  │           │
          │                                      apply prefs   play requests
          │ normalized UI events                        │           │
          ▼                                             ▼           ▼
┌────────────────────┐                         ┌─────────────┐ ┌──────────────┐
│ MainLoopUI / other │ ─────────────────────▶ │ Audio buses │ │ Pooled        │
│ Presentation UI    │   forward edits        │ category ctl│ │ players/tweens│
│ emits stable UI    │ ─────────────────────▶ │ + mute ctl  │ │ BGM/SFX/Amb   │
│ semantic events    │                        └─────────────┘ └──────────────┘
└────────────────────┘
```

### Key Interfaces

#### 1. Audio preference runtime snapshot

```gdscript
AudioManager.build_audio_settings_payload() -> Dictionary[String, Variant]
```

Authoritative snapshot keys:
- `audio_master_volume: float`
- `audio_bgm_volume: float`
- `audio_sfx_volume: float`
- `audio_ambience_volume: float`
- `audio_muted_categories: Array[String]`

This payload is read-only for consumers.

#### 2. Preference update entry points

```gdscript
AudioManager.set_master_volume(value: float) -> void
AudioManager.set_bgm_volume(value: float) -> void
AudioManager.set_sfx_volume(value: float) -> void
AudioManager.set_ambience_volume(value: float) -> void
AudioManager.set_category_muted(category: String, muted: bool) -> void
```

These are the only authoritative runtime mutation entry points for `audio_*` preference state.

#### 3. Persistence hooks

```gdscript
AudioManager.serialize_audio_settings() -> Dictionary[String, Variant]
AudioManager.deserialize_audio_settings(payload: Dictionary[String, Variant]) -> void
AudioManager.apply_restored_audio_settings_if_ready() -> void
```

`deserialize_audio_settings()` may store pending values before full runtime apply. `apply_restored_audio_settings_if_ready()` commits them to buses/players only after the node runtime is initialized.

The serialized payload is the authoritative durable audio settings blob for SaveManager restore purposes and must not be replaced by UI container state, transient playback ledger state, or save metadata shortcuts. Under ADR-0003 it is restored as the `audio_state` registered durable-state extension payload rather than a canonical Core gameplay top-level field.

#### 4. Stable event consumption rule

```gdscript
EventBus.subscribe(event_name: String, callable: Callable)
EventBus.unsubscribe(event_name: String, callable: Callable)
```

Audio may subscribe only to event names explicitly treated as stable semantic playback anchors. It must not derive behavior from raw focus churn, transient hover state, or debug-only observability signals.

#### 5. Same-window playback ledger

```gdscript
AudioManager.submit_audio_event(event_key: String, payload: Dictionary[String, Variant]) -> void
```

Internally, `AudioManager` may assign each submitted event to a stable playback window and decide one of:
- play immediately
- merge with another event
- delay within the same presentation window
- suppress due to cooldown, mute, low-pressure boundary, or lower priority

This ledger is presentation-only and must not emit back into gameplay truth.

## Alternatives Considered

### Alternative 1: MainLoopUI owns audio settings and playback coordination

- **Description**: MainLoopUI keeps the runtime `audio_*` truth, applies settings directly, and dispatches playback requests to other UI/gameplay consumers.
- **Pros**: Fewer moving parts at the earliest UI prototype stage; minimal setup if only Home screen settings existed.
- **Cons**: Violates the GDD boundary that MainLoopUI only temporarily owns the settings container; couples audio semantics to one presentation shell; cannot safely scale to match, town, random event, onboarding, or other future screens; makes save/load ownership ambiguous; encourages UI truth drift.
- **Rejection Reason**: The project already states that MainLoopUI owns only the minimum container, not audio semantics. Promoting it to runtime authority would contradict both the GDD and the architecture ownership model.

### Alternative 2: Decentralized playback with shared config only

- **Description**: No `AudioManager` exists; each UI or gameplay-facing system plays its own sounds while reading a shared settings payload.
- **Pros**: Simple local implementation for each feature team; no central queue required.
- **Cons**: Creates many playback owners, weakens same-window suppression, makes Godot bus application inconsistent, increases risk of direct gameplay→audio wiring, and produces save/load ambiguity around who owns the preference truth.
- **Rejection Reason**: This breaks the single-writer architecture model and makes it too easy for screens or gameplay systems to bypass stable event and persistence boundaries.

### Alternative 3: Save schema only, no event-consumption contract

- **Description**: Define durable `audio_*` fields in save/load but leave event playback and runtime ownership unspecified.
- **Pros**: Quickly closes part of the persistence gap.
- **Cons**: Leaves the most important design risk unresolved: who owns runtime playback truth and how audio consumes stable events. Different teams would still invent incompatible runtime behavior.
- **Rejection Reason**: The architecture-review gap is not only about save fields; it is also about event consumption, same-window suppression, and read-only Presentation boundaries.

## Consequences

### Positive

- Establishes a single runtime owner for all durable playback preferences.
- Keeps audio aligned with the EventBus-driven cross-system contract.
- Prevents MainLoopUI or individual screens from silently becoming audio truth owners.
- Gives SaveManager a clear persistence boundary for `audio_*` fields.
- Provides a stable foundation for priority/suppression rules required by `audio-system.md`.
- Preserves the project's low-pressure tone at the architecture layer rather than leaving it to content-only judgment.
- Uses Godot 4.6 idioms that are stable and well-supported: buses, pooled players, and node lifecycle-based playback control.

### Negative

- Introduces another long-lived runtime manager that must be initialized, validated, and tested.
- Requires explicit mapping tables between semantic events and audio assets/categories.
- Adds implementation complexity around same-window ledgers, cooldowns, and transient-vs-durable mixing separation.
- Requires care to avoid over-consuming UI micro-events that are not semantically stable enough for audio.

### Risks

- **Risk: UI dual-focus drift under Godot 4.6**  
  `Control` focus/hover churn may differ by input method.  
  **Mitigation:** Audio consumes only UI-emitted normalized semantic events, not raw focus/hover transitions.

- **Risk: Persistent preference control and transient runtime mixing overwrite each other**  
  A fade or ducking transition could corrupt the saved preference truth if both target the same control surface.  
  **Mitigation:** Persistent preferences map to bus/category truth; transient fades/ducking/crossfades use player-level or dedicated transient mix controls.

- **Risk: Missing bus mapping or bus layout drift**  
  Named buses such as Music/BGM/SFX/Ambience may not exist or may be renamed.  
  **Mitigation:** Validate bus mappings during audio runtime initialization; fail safely for players and emit rate-limited development warnings.

- **Risk: Save/load restore applies too early**  
  Deserialized values may arrive before players, tweens, or bus mapping caches are ready.  
  **Mitigation:** Use two-phase restore: receive durable values first, apply only after `AudioManager` runtime initialization completes.

- **Risk: Silent degradation hides content authoring mistakes in development**  
  A release-safe no-op could make missing assets harder to catch while building content.  
  **Mitigation:** Keep silent player-facing failure, but provide editor/debug diagnostics with rate limiting or validation tooling.

- **Risk: Audio queue becomes a shadow event system**  
  Presentation-level suppression logic could accidentally turn into a second truth source.  
  **Mitigation:** The playback ledger never emits authoritative game events and only renders already-confirmed semantic input.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `audio-system.md` | Audio consumes stable events only and must never mutate gameplay or navigation state. | Defines `AudioManager` as a read-only stable-event consumer and forbids gameplay/navigation mutation or semantic inference from transient UI state. |
| `audio-system.md` | Playback eligibility and missing assets must degrade silently. | Requires safe-fail handling for missing streams, mappings, and bus layouts, with silent player-facing degradation and optional development diagnostics. |
| `audio-system.md` | Audio mixing formula must remain within a controlled playback boundary. | Separates durable bus/category preferences from transient fades/ducking and makes `AudioManager` the sole runtime owner of playback configuration. |
| `audio-system.md` | Audio preference fields are durable settings only. | Declares `audio_master_volume`, `audio_bgm_volume`, `audio_sfx_volume`, `audio_ambience_volume`, and `audio_muted_categories` as playback-only durable state serialized through SaveManager. |
| `audio-system.md` | Audio events in the same stable window must be prioritized, merged, delayed, or suppressed. | Establishes a presentation-only playback ledger/queue in `AudioManager` for same-window priority, cooldown, merge, delay, and suppression behavior. |
| `audio-system.md` | Low-pressure feedback constraints must apply to loss, shortage, maintenance, and weak outcomes. | Makes low-pressure tone a hard architecture boundary and bans alarm/crisis/punishment semantics for normal management outcomes. |
| `main-loop-ui-framework.md` | MainLoopUI temporarily owns the minimum audio settings container but not audio semantics. | Preserves MainLoopUI as container/forwarder only and assigns runtime preference truth to `AudioManager`. |
| `save-and-load-system.md` | `audio_*` fields must be restored through the unified save/load boundary and must not affect gameplay truth. | Routes all durable audio preference persistence through SaveManager as the AudioManager-owned registered durable-state extension payload `audio_state`, and codifies playback-only restore semantics. |
| `town-building-system.md` | Town-building completion and management outcomes may provide audio feedback without increasing pressure. | Keeps town audio feedback downstream, read-only, and subject to low-pressure suppression and stable-event consumption rules. |

## Performance Implications

- **CPU**: Low and event-driven. Playback work occurs only on stable event intake, settings changes, and fade/queue processing. Pooling avoids repeated node creation. Same-window ledger cost is bounded by the small number of human-timescale events in a management sim.
- **Memory**: Small but non-zero increase for pooled `AudioStreamPlayer` nodes, bus mapping caches, active tween state, and short-lived playback ledger entries.
- **Load Time**: Minor startup validation cost for bus mappings and audio runtime initialization. This should remain well below meaningful scene-load thresholds for a 2D management sim.
- **Network**: Not applicable.

## Migration Plan

1. Introduce `AudioManager` as a long-lived runtime node with no gameplay mutation rights.
2. Define stable category buses and bus-name validation rules.
3. Implement authoritative runtime getters/setters for `audio_*` preference state.
4. Register `AudioManager` with SaveManager for serialize/deserialize support.
5. Route MainLoopUI's minimum settings controls through `AudioManager` mutation entry points.
6. Add stable EventBus subscriptions for approved gameplay/UI semantic events.
7. Implement same-window playback ledger rules for priority/cooldown/merge/suppression.
8. Add debug/editor diagnostics for missing streams, invalid mappings, and missing buses while keeping player-facing release behavior non-blocking.
9. Expand asset/data authoring only after the runtime and persistence contract is verified.

## Validation Criteria

- [ ] `AudioManager` is implemented as a scene-tree Node/Autoload and survives normal runtime initialization/shutdown without duplicate subscriptions.
- [ ] MainLoopUI can edit `audio_master_volume`, `audio_bgm_volume`, `audio_sfx_volume`, `audio_ambience_volume`, and `audio_muted_categories` only through `AudioManager` entry points.
- [ ] Save/load restores the `audio_*` fields exactly via the registered durable-state extension payload `audio_state`, and applying them does not change gameplay or navigation truth.
- [ ] Restored settings apply correctly even when deserialization occurs before full audio runtime readiness.
- [ ] Older saves that omit `audio_state` restore to safe default audio preferences without blocking load.
- [ ] Missing stream, category mapping, or bus mapping produces silent player-facing degradation instead of blocking the game flow.
- [ ] Development builds can still diagnose missing mappings/resources without spamming logs uncontrollably.
- [ ] Audio playback never depends on raw `Control` focus churn or transient hover heuristics under Godot 4.6 dual-focus behavior.
- [ ] Same-window event handling can prioritize, merge, delay, or suppress events without emitting new gameplay truth.
- [ ] Negative-but-normal outcomes (loss, shortage, maintenance, weak random-event result) use low-pressure, non-alarm audio behavior.
- [ ] BGM fades/ducking/crossfades do not overwrite or corrupt persistent player preference truth.

## Related Decisions

- `docs/architecture/adr-0002-event-signal-architecture.md`
- `docs/architecture/adr-0003-save-load-persistence.md`
- `design/gdd/audio-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/save-and-load-system.md`
- `design/gdd/town-building-system.md`
