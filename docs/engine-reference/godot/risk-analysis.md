# Godot 4.6 — Engine Risk Analysis for 足球小镇 (Football Town)

**Date**: 2026-05-16
**Project**: Football Town — pixel-art 2D football management sim
**Engine**: Godot 4.6 (LLM knowledge cutoff: May 2025)
**Analysis Scope**: 4.4 → 4.6 post-cutoff changes mapped to project systems

---

## Risk Summary

| Risk Level | Count | Action |
|------------|:-----:|--------|
| **HIGH** — must verify before implementing | 3 | Explicitly check before touching affected code |
| **MEDIUM** — verify during Technical Setup | 4 | Confirm before system implementation begins |
| **LOW** — irrelevant to this project | 5 | No action needed |
| **POSITIVE** — opportunities to exploit | 5 | Use to improve architecture |

---

## HIGH Risk Items

These affect core game code and MUST be verified before any `src/` implementation.

### H1 — Deprecated `yield()` → `await` (Godot 4.0+, post-cutoff in training data)

| Field | Detail |
|-------|--------|
| **Affected Systems** | ALL — every coroutine, every asynchronous flow |
| **Why HIGH** | The LLM's training data will suggest `yield()` for coroutines. Every agent touching `.gd` files must know to use `await` instead. A single `yield()` call will fail to compile. |
| **Verification** | Grep all `.gd` files for `yield` before any commit. Add to pre-commit hook. |
| **Mitigation** | Forbidden pattern already listed in `.claude/docs/technical-preferences.md`. All specialist agents must be briefed on this before writing code. |

### H2 — Deprecated `instance()` → `instantiate()` (Godot 4.0+, post-cutoff in training data)

| Field | Detail |
|-------|--------|
| **Affected Systems** | Scene instantiation everywhere — match flow screens, UI transitions, save/load restore |
| **Why HIGH** | Same class of error as H1. LLM will confidently suggest `PackedScene.instance()`. |
| **Verification** | Grep for `instance()` in all `.gd` files. |
| **Mitigation** | Forbidden pattern listed. Pre-commit grep check. |

### H3 — Dual-Focus Input System (Godot 4.6)

| Field | Detail |
|-------|--------|
| **Affected Systems** | `main-loop-ui-framework.md`, `player-management-ui.md`, `match-performance-ui.md` |
| **Why HIGH** | Godot 4.6 separates mouse/touch focus from keyboard/gamepad focus. UI code that assumes a single focus owner will have subtle bugs: focused buttons may not respond to keyboard, tab navigation may desync from mouse hover. |
| **Verification** | Test every UI screen with both mouse and keyboard navigation before marking any UI story done. |
| **Mitigation** | UI ADR must explicitly address dual-focus handling. All Control nodes that accept input must have `focus_mode` explicitly set, not relying on defaults. |

---

## MEDIUM Risk Items

These affect specific systems or workflows. Verify during Technical Setup before those systems are implemented.

### M1 — `FileAccess.store_*` Returns `bool` (Godot 4.4)

| Field | Detail |
|-------|--------|
| **Affected Systems** | `save-and-load-system.md` — save file writing |
| **Why MEDIUM** | Save system writes binary data. The LLM may assume `store_*` methods return `void`. Code that doesn't check the `bool` return will silently fail to save. |
| **Verification** | Save/load ADR must mandate return-value checking. All save I/O code must check `store_*` return values. |
| **Mitigation** | Wrap save writes in a helper that checks return values and logs failures. |

### M2 — Shader Texture Type Change: `Texture2D` → `Texture` (Godot 4.4)

| Field | Detail |
|-------|--------|
| **Affected Systems** | Any custom shaders (post-processing, pixel-art effects) |
| **Why MEDIUM** | If custom shaders are written, parameter/return types changed. LLM will suggest `Texture2D` which will fail to compile in shader code. |
| **Verification** | Test any custom `.gdshader` files against Godot 4.6 before committing. |
| **Mitigation** | Use `Texture` base type for all shader texture parameters. Covered in `current-best-practices.md`. |

### M3 — Accessibility: Screen Reader Support via AccessKit (Godot 4.5)

| Field | Detail |
|-------|--------|
| **Affected Systems** | All UI systems — main-loop-ui, player-management-ui, match-performance-ui, onboarding |
| **Why MEDIUM** | Accessibility is a project standard requirement (`design/accessibility-requirements.md`). Godot 4.5 added built-in screen reader support via AccessKit, but the LLM doesn't know about it. UI code that doesn't set `accessibility_name` and `accessibility_description` on Control nodes will be inaccessible. |
| **Verification** | Audit all `.tscn` files for accessibility properties before Pre-Production gate. |
| **Mitigation** | UI ADR must require accessibility properties on all interactive Control nodes. |

**Project Risk Record — HUD-A11Y-R1**

| Field | Detail |
|-------|--------|
| **Risk ID** | HUD-A11Y-R1 |
| **Title** | Screen reader support not yet verified in engine build |
| **Scope** | HUD framework and all dependent UI screens that inherit its accessibility baseline |
| **Current Status** | OPEN |
| **Why it matters** | UX specs require keyboard, contrast, redundant cues, and screen-reader-safe naming. The HUD now sets accessibility names, but AccessKit behavior has not yet been validated in a packaged or end-to-end engine build. |
| **Required Follow-up** | Verify HUD and pause-menu announcements with Godot 4.6 AccessKit in an engine build before any QA or release artifact claims full screen reader support. |
| **Interim Rule** | Until verified, documentation and QA sign-off must not claim screen reader support is complete; refer to this risk by ID instead. |

### M4 — `duplicate_deep()` for Nested Resources (Godot 4.5)

| Field | Detail |
|-------|--------|
| **Affected Systems** | `save-and-load-system.md`, `player-development-system.md` — any system that copies player data, facility state, or match configuration |
| **Why MEDIUM** | Deep-copying nested Resource objects (player stats, facility configurations) previously required manual recursion. The LLM will suggest `duplicate()` which only does shallow copies for Resources. This could cause shared-reference bugs where modifying one player's stats affects another. |
| **Verification** | All Resource duplication in save/load and data pipelines must use `duplicate_deep()`. |
| **Mitigation** | Enforced in save/load ADR. |

---

## LOW Risk Items (Irrelevant to This Project)

These Godot 4.4-4.6 changes do not affect Football Town:

| Change | Why Irrelevant |
|--------|---------------|
| Jolt default 3D physics (4.6) | No 3D physics — match simulation is formula-driven |
| D3D12 default renderer (4.6) | 2D pixel-art game — Compatibility renderer; D3D12/Vulkan irrelevant |
| Glow-before-tonemapping (4.6) | No post-processing glow effects planned |
| AgX tonemapper controls (4.6) | Compatibility renderer — no tonemapping |
| 3D interpolation rearchitected (4.5) | No 3D rendering |
| Navigation 2D dedicated server (4.5) | No pathfinding (grid-based town, menu-based football) |
| BoneConstraint3D / IK restored (4.5/4.6) | No skeletal animation (2D pixel art) |
| visionOS export (4.5) | PC-only target |
| Android 16KB page support (4.5) | No mobile target |

---

## POSITIVE Opportunities

These post-cutoff features actively benefit the project and should be used:

| Feature | Version | How to Exploit |
|---------|---------|---------------|
| `@abstract` classes (GDScript) | 4.5 | Enforce interface contracts for all Foundation-layer systems: `SaveableResource`, `EventBus`, `Screen`. Prevents implementation drift. |
| Variadic args (GDScript) | 4.5 | Cleaner logging macros, data pipeline signatures. `func log(level: String, ...args: Variant)` |
| Shader Baker | 4.5 | Pre-compile shaders at build time — eliminates startup hitching. Use even for a pixel-art game; every ms of startup matters. |
| SMAA 1x antialiasing | 4.5 | Better AA for upscaled pixel art. Use if the game renders at a lower resolution and scales up. |
| Script backtracing | 4.5 | Detailed call stacks in Release builds. Keep enabled — invaluable for bug reports from players. |

---

## Pre-Implementation Checklist

Before any `src/` code is written, the following must be verified against a Godot 4.6 editor:

- [ ] Open Godot 4.6, create a test project, confirm above deprecated APIs produce errors as documented
- [ ] Test dual-focus input behavior: create a button, test mouse click vs. Tab+Enter, observe focus visual differences
- [ ] Test `FileAccess.store_*` return values: write test data, confirm `bool` return, check error cases
- [ ] Test `duplicate_deep()` on a nested Resource: confirm deep copy, not shared reference
- [ ] Test `@abstract` enforcement: define an abstract class, attempt to instantiate it, confirm error
- [ ] Run GUT test suite setup to confirm `gdunit4` addon is compatible with Godot 4.6

---

## Agent Briefing Notes

All specialist agents writing Godot code for this project must be briefed on:

1. **Never use `yield()`** — use `await` (H1)
2. **Never use `.instance()`** — use `.instantiate()` (H2)
3. **Always check `FileAccess.store_*` return values** — they return `bool` (M1)
4. **Always use `duplicate_deep()` for Resource copies** — `duplicate()` is shallow (M4)
5. **Always set `accessibility_name` on interactive Control nodes** — AccessKit is built-in (M3)
6. **Always set explicit `focus_mode` on Control nodes that accept input** — dual-focus system (H3)
