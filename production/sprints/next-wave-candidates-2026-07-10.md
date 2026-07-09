# Next Presentation Wave — Candidate Stories — 2026-07-10

**Source**: Sprint 4 — S4-07 pre-check
**Context**: Sprint 3 completed the Home / Player / Training / Match visual exemplar baseline and the PlayerMgmt authority contract convergence. Sprint 4 completed governance and process improvement. The next wave should begin feature-adjacent Presentation work.

---

## Candidate Stories

### 1. Skill/Trait Growth Summary — Minimum Alpha UI Stub
**Estimate**: S–M
**Story Type**: UI
**Dependencies**: ADR-0010 (payload contracts), Story 003 (authority convergence pattern)
**Rationale**: Highest deferral risk (medium — Player UI may need refactoring later). Current MVP has `WhatNextGuidance` and Home summary stubs but no skill/trait feedback surface. A minimum UI stub would consume `pending_skill_trait_feedback` payload and show "growth summary" placeholder — not full unlock/trigger logic, just the consumption path.

### 2. Town Management UI — Minimum Facility Grid Stub
**Estimate**: S–M
**Story Type**: UI
**Dependencies**: ADR-0008 (TownBuilding), Home visual exemplar (story-002 main-loop-ui-framework)
**Rationale**: Second-highest deferral risk (medium). Current Home page shows town summary text only. A minimum grid stub would render a 5×5 layout with placeholder facility icons, consuming `TownBuilding` read models.

### 3. Match Live / Halftime — Minimum Command Readiness Stub
**Estimate**: S
**Story Type**: UI
**Dependencies**: Match visual exemplar (story-002 match-performance-ui), ADR-0006 (match simulation)
**Rationale**: Current MVP halves match depth at halftime (placeholder button, no real commands). A minimum stub would add one legal halftime decision (e.g., "change tactic to defensive") that wires through the existing `MatchStartCoordinator` without expanding live command depth.

### 4. Audio Settings UI — Minimum Container Stub
**Estimate**: S
**Story Type**: UI
**Dependencies**: ADR-0013 (Audio), Home visual exemplar
**Rationale**: Low risk but easy win. Current MVP has no audio settings at all. A minimum stub would add a settings container accessible from Home, consuming `audio_preferences` from ADR-0013, with master/bgm/sfx volume sliders that write through `AudioManager`.

---

## Recommended Priority

| # | Candidate | Risk | Dependencies Ready | Recommendation |
|---|-----------|------|-------------------|----------------|
| 1 | Skill/Trait Growth Summary | Medium | Yes | **Start first** — highest value, clears deferral risk |
| 2 | Town Management UI grid stub | Medium | Yes | **Parallel candidate** |
| 3 | Match Live halftime stub | Low | Yes | After #1 or #2 |
| 4 | Audio Settings UI | Low | Yes | Easy win, can slot in anytime |

## Recommended Next Sprint Composition

**Must Have** (2 stories, ~2-3d):
- Skill/Trait Growth Summary — minimum Alpha UI stub
- Town Management UI — minimum grid stub

**Should Have** (1 story, ~0.5d):
- Audio Settings UI — minimum container stub

**Nice to Have**:
- Match Live halftime stub

## Decision

This pre-check is advisory. The next sprint-planning session should select from these candidates based on available capacity and any new priorities that emerge.
