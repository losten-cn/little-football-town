# Story 001: Audio Settings UI — 最小容器 stub

> **Epic**: 音频系统
> **Status**: Complete
> **Layer**: Presentation + Foundation
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/audio-system.md`
**Requirement**: `TR-audio-004`
**ADR**: ADR-0013 — Audio Settings & Event Consumption

This story is a minimum Alpha presentation stub for the Audio Settings UI and the `AudioManager` runtime authority it depends on. It does not implement audio playback, bus mapping, BGM streaming, SFX pooling, same-window suppression, or save/load persistence. Its only goal is to establish:

1. A minimal `AudioManager` autoload stub holding `audio_master_volume`, `audio_bgm_volume`, `audio_sfx_volume` in memory
2. A read-only settings UI panel with three volume sliders that reads from and writes through `AudioManager`

This is the first Audio story. It follows the same Presentation-stub pattern as S5-01 (Growth Summary) and S5-02 (Town Grid), but adds a minimal Foundation autoload stub because ADR-0013 defines `AudioManager` as a required runtime authority — the UI cannot consume what doesn't exist.

**ADR Governing Implementation**:

- Primary: ADR-0013 — Audio Settings & Event Consumption

**ADR Decision Summary**:

- ADR-0013 defines `AudioManager` as a long-lived Node-based Autoload that owns `audio_master_volume`, `audio_bgm_volume`, `audio_sfx_volume`, `audio_ambience_volume`, and `audio_muted_categories`. Other systems may request edits or read authoritative snapshots (via `build_audio_settings_payload()`), but they do not own these fields.
- Volume setters (`set_master_volume()`, `set_bgm_volume()`, `set_sfx_volume()`) are the only authoritative mutation entry points.
- MainLoopUI temporarily owns the minimum settings container and forwards user edits to `AudioManager`. It does not own audio defaults, mixing formulas, or playback truth.

**Engine**: Godot 4.6 | **Risk**: Medium

**Engine Notes**:

- ADR-0013 flags HIGH engine knowledge risk for Godot 4.6 audio buses and dual-focus behavior. This stub does NOT touch audio buses, streams, players, or focus — it only stores float values and renders sliders. Risk is effectively LOW for this stub.
- No post-cutoff Godot 4.6 audio APIs are used in this stub.

**Control Manifest Rules (Presentation / Foundation)**:

- Required: UI modules must consume `build_audio_settings_payload()` as read-only snapshot; writes must go through `AudioManager.set_*_volume()` entry points.
- Required: `AudioManager` must register with SaveManager for persistence (ADR-0003 contract) — **deferred to follow-up story** for this stub.
- Forbidden: UI must never own audio preference truth or compute mixing formulas.
- Forbidden: Never resolve authority nodes through hardcoded `NodePath`, arbitrary scene-tree search, or implicit pseudo-singletons. `AudioManager` as Autoload is accessed via `/root/AudioManager` or the equivalent `AudioManager` global.
- Guardrail: UI implementations must stay within the global 60fps / 16ms frame budget and 500 draw-call ceiling.

**Pre-Implementation Decisions (S4-02 checklist applied)**:

- [ ] Authority purity first — missing AudioManager → neutral placeholder sliders at default values
- [ ] Latest producer wins — slider values always read from AudioManager authoritative snapshot
- [ ] Explanatory fields from producer, UI read-only — volume labels from AudioManager payload
- [ ] Selection context from authority only — N/A for this story (no selection)
- [ ] `disable_reason` ≠ `risk_summary` — N/A for this story (no disable/risk fields)
- [ ] Test contract: new integration test file; existing L2/walkthrough should not be broken

---

## Acceptance Criteria

- [ ] An Audio Settings panel exists inside the existing MainLoop Shell, accessible from Home, without new route IDs.
- [ ] The panel contains three interactive volume sliders: Master Volume, BGM Volume, SFX Volume, each with range 0.0–1.0.
- [ ] Slider values are consumed from `AudioManager.build_audio_settings_payload()` as a read-only authoritative snapshot on panel open.
- [ ] Slider changes write through `AudioManager.set_master_volume()` / `set_bgm_volume()` / `set_sfx_volume()` — the UI does not own volume truth locally.
- [ ] `AudioManager` exists as an accessible runtime authority (autoload or equivalent) with the three volume fields and setter/getter methods defined in ADR-0013 §Key Interfaces.
- [ ] If `AudioManager` is unavailable or uninitialized, the panel degrades to sliders at default 1.0 without crash.
- [ ] This stub does not implement: audio playback, bus mapping, BGM streaming, SFX pooling, mute categories, ambience volume, save/load persistence, or same-window suppression.
- [ ] Existing Home visual exemplar cards (6 warm-town cards + Growth Summary + Town Grid) are not degraded by the addition of the settings panel.
- [ ] Automated regression coverage proves the panel consumes authoritative AudioManager state and writes through setter entry points.
- [ ] Existing route and handoff guardrails still pass.

---

## Scope

### In Scope

- `src/autoload/audio_manager.gd` — minimal `AudioManager` autoload stub (Node, `class_name AudioManager`) with:
  - `audio_master_volume: float`, `audio_bgm_volume: float`, `audio_sfx_volume: float` (default 1.0)
  - `build_audio_settings_payload() -> Dictionary[String, Variant]`
  - `set_master_volume(value: float)`, `set_bgm_volume(value: float)`, `set_sfx_volume(value: float)`
  - `audio_settings_changed` EventBus emission on any setter call
- `src/ui/audio_settings_panel.gd` — read-only settings PanelContainer with:
  - Three HSlider controls (Master / BGM / SFX), range 0.0–1.0, step 0.05
  - Read from `AudioManager.build_audio_settings_payload()` on panel open
  - Write through `AudioManager.set_*_volume()` on slider change
  - Close/back button returning to Home
- Mount in `MainLoopShell` — accessible from Home, visibility controlled by existing shell chrome pattern.
- Warm-town visual treatment consistent with approved Home exemplar direction.
- Integration test for AudioManager authority contract + settings panel consumption.
- Walkthrough/screenshot evidence.

### Out of Scope

- Audio playback (BGM streaming, SFX pooling, bus routing, AudioStreamPlayer management).
- Ambience volume slider (deferred to follow-up Audio story).
- Mute category toggles (deferred to follow-up Audio story).
- Save/load persistence of audio settings (deferred — ADR-0013 §6, two-phase restore).
- Same-window playback priority/suppression ledger (deferred — ADR-0013 §8).
- Audio asset loading, event-to-asset mapping, or bus layout configuration.
- Production audio assets.
- New route IDs, save/event schema changes, or Gameplay-layer authority changes.

---

## Dependencies

- Depends on:
  - `docs/architecture/adr-0013-audio-settings-event-consumption.md` (Accepted — AudioManager API contract)
  - `production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md` (Complete — Home card layout)
  - `docs/architecture/control-manifest.md` Manifest Version `2026-07-05`
- Parallel with:
  - S5-01 (Complete), S5-02 (Complete)
- Unlocks:
  - future Audio playback/BGM streaming stories
  - future Audio save/load persistence stories
  - future Audio mute-category and ambience stories
- Story dependencies: ADR-0013 is Accepted. No blocking code dependencies.

---

## Implementation Notes

This is a presentation-stub + foundation-stub story, not a feature-growth story.

Preserve:

- existing route IDs
- existing Home card layout (6 warm-town cards + Growth Summary + Town Grid)
- existing save/event schema
- existing MainLoop Shell mounting and return paths

Allowed changes:

- add `src/autoload/audio_manager.gd` as a minimal stub Node;
- register `AudioManager` as an autoload in `project.godot` (or instantiate via code for testability);
- add `src/ui/audio_settings_panel.gd` as a read-only settings container;
- mount settings panel in `MainLoopShell._content_box`, visible when toggled from Home;
- add a settings entry button in the Home area (e.g., a small gear icon or "设置" text button);
- add screenshot or walkthrough evidence.

Not allowed:

- adding audio playback, bus mapping, or stream management;
- adding save/load persistence hooks (deferred to follow-up);
- adding mute categories, ambience volume, or advanced mixing controls;
- adding new route IDs;
- changing `ScreenManager`;
- expanding into full Settings/Options interaction depth.

**AudioManager autoload note**: Per ADR-0013, `AudioManager` is an Autoload. For this stub, `AudioManager` is created as a `class_name AudioManager extends Node` and registered in `project.godot` autoload list at position after `ScreenManager`. The autoload registration is a project configuration change that must be done in the Godot editor or by editing `project.godot` directly. If autoload registration is deferred, the test must inject `AudioManager` as a scene child and the shell must locate it via `get_node_or_null("/root/AudioManager")`.

---

## Test Evidence

**Story Type**: UI

**Required evidence**:

- Manual visual evidence:
  - `production/qa/evidence/audio-settings-ui-stub-2026-07-10.md`
- Automated guardrails:
  - `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
  - `MVP_VISUAL_WALKTHROUGH_PASS` or updated walkthrough evidence
- Authority contract evidence:
  - `tests/integration/ui/audio_settings_authoritative_payload_test.gd`

**Status**: [ ] Not yet created

---

## Definition of Done

- [ ] Audio Settings panel exists and is accessible from Home.
- [ ] `AudioManager` stub exists with ADR-0013 key interfaces.
- [ ] Integration test for authoritative volume payload consumption passes.
- [ ] Existing route/handoff guardrails still pass.
- [ ] No new route IDs, gameplay formulas, or schema contracts were introduced.
- [ ] Code review confirms presentation-only + foundation-stub scope was preserved.
- [ ] Any advisory deviations are documented.

## Completion Notes
**Completed**: 2026-07-10
**Criteria**: 10/10 passing
**Deviations**: None. Save/load persistence and ambience/mute controls deferred to follow-up Audio stories per ADR-0013.
**Test Evidence**: `tests/integration/ui/audio_settings_authoritative_payload_test.gd` (3 test functions, PASS); `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`.
**Code Review**: Complete — lean mode, APPROVED.
