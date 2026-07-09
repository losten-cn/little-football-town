# Deferred Systems Governance — Sprint 3 Follow-through
**Date**: 2026-07-09
**Source**: Sprint 3 — Production Visual Follow-through (S3-09 carryover → S4-01)
**Status**: Active governance record

## Purpose

This document records the explicit deferral status for systems that were accepted in architecture (ADRs exist, TR-IDs registered) but not yet scheduled into any production story wave. Each entry names the system, its current architecture/design status, the deferral rationale, and the expected future story chain trigger.

---

## Deferred Systems

### 1. Random Event
- **ADRs**: ADR-0012 (Accepted)
- **TR-IDs**: `TR-random-001` through `TR-random-008` (active)
- **GDD**: `design/gdd/random-event-system.md` (Designed)
- **Deferral rationale**: Random Event is a Beta-layer system. Current production focus is on Presentation visual exemplar follow-through (Home / Player / Training / Match). Random Event UI depends on stable Home and match-result containers first.
- **Future story chain trigger**: When Presentation visual exemplar baseline is signed off and a Beta-content wave is planned. Expected entry point: `RandomEventManager` wiring → `random_event_offer_view_payload` → Home/Result integration.
- **Risk of continued deferral**: Low — architecture contracts exist, no implementation dependency on Random Event for MVP loop.

### 2. Audio
- **ADRs**: ADR-0013 (Accepted)
- **TR-IDs**: `TR-audio-001` through `TR-audio-006` (active)
- **GDD**: `design/gdd/audio-system.md` (Approved)
- **Deferral rationale**: Audio is a Beta-layer system. Current MVP loop does not require audio feedback to validate the core training-match-result cycle. AudioManager Autoload placement and two-phase save/load restore semantics are already defined in ADR-0013 and do not block current production work.
- **Future story chain trigger**: When a Beta or Polish wave is planned. Expected entry point: `AudioManager` Autoload creation → event subscription wiring → settings UI container in Main Loop.
- **Risk of continued deferral**: Low — architecture contracts exist, no blocking dependency.

### 3. Skill and Trait
- **ADRs**: ADR-0010 covers cross-system settlement contracts
- **TR-IDs**: `TR-skill-001` through `TR-skill-008` (active)
- **GDD**: `design/gdd/skill-and-trait-system.md` (Approved)
- **Deferral rationale**: Skill/Trait is an Alpha-layer system. Current MVP loop validates the basic training-match-result cycle without skill/trait depth. Settlement key contract and payload ownership are already defined in ADR-0010.
- **Future story chain trigger**: When Player development depth is expanded beyond the current training-only MVP. Expected entry point: `PlayerDevelopment` skill evaluation integration → `pre_match_skill_trait_snapshot` → `pending_skill_trait_feedback` UI consumption.
- **Risk of continued deferral**: Medium — the longer Skill/Trait is deferred, the more likely Player/Training UI will need refactoring to accommodate feedback and identity-history display.

### 4. Reputation and Achievement
- **ADRs**: ADR-0011 (Accepted)
- **TR-IDs**: `TR-reputation-001` through `TR-reputation-006` (active)
- **GDD**: `design/gdd/reputation-and-achievement-system.md` (Designed)
- **Deferral rationale**: Reputation/Achievement is an Alpha-layer system. Current MVP loop does not require long-term meta-progression feedback. Architecture contracts (settlement keys, payload ownership) are already defined.
- **Future story chain trigger**: When Alpha meta-progression wave is planned. Expected entry point: `ReputationAchievementManager` → `reputation_view_payload` / `achievement_view_payload` → UI consumption.
- **Risk of continued deferral**: Low — architecture contracts exist, no blocking dependency.

### 5. Town Management UI
- **ADRs**: ADR-0008 (Accepted, covers TownBuilding authority)
- **TR-IDs**: `TR-townui-001` through `TR-townui-007` (active)
- **GDD**: `design/gdd/town-management-ui.md` (Designed)
- **Deferral rationale**: Town Management UI is an Alpha-layer system. MVP provides only the minimum town summary on Home and facility bonuses consumed passively by training/match. Full Town UI requires the TownBuilding grid, facility detail, and construction flow, which are out of current Presentation follow-through scope.
- **Future story chain trigger**: When Alpha town-building wave is planned. Expected entry point: Town grid rendering → facility build/upgrade flow → maintenance summary → budget preview integration.
- **Risk of continued deferral**: Medium — the longer Town UI is deferred, the more the Home page's town summary section may need refactoring to accommodate richer town data.

### 6. Tutorial and Hint
- **ADRs**: None (system-level ADR not yet created)
- **TR-IDs**: `TR-tutorial-001` through `TR-tutorial-007` (active)
- **GDD**: `design/gdd/tutorial-and-hint-system.md` (Designed)
- **Deferral rationale**: Tutorial/Hint is a Polish-layer system. Current MVP loop is validated via QA walkthrough and visual exemplar evidence without formal onboarding. The WhatNextGuidance panel provides minimum next-action cues.
- **Future story chain trigger**: When Polish wave is planned and all stable UI anchors are confirmed. Expected entry point: Tutorial system wiring → hint eligibility → anchor registry → seen/unseen state persistence.
- **Risk of continued deferral**: Low — onboarding is a polish concern; current MVP is validated through manual walkthrough evidence.

---

## Summary

| System | Layer | ADR | Deferral Risk | Next Wave Trigger |
|--------|-------|-----|--------------|-------------------|
| Random Event | Beta | ADR-0012 | Low | Beta-content wave |
| Audio | Beta | ADR-0013 | Low | Beta/Polish wave |
| Skill and Trait | Alpha | ADR-0010 | Medium | Player depth expansion |
| Reputation/Achievement | Alpha | ADR-0011 | Low | Alpha meta-progression wave |
| Town Management UI | Alpha | ADR-0008 | Medium | Alpha town-building wave |
| Tutorial/Hint | Polish | None | Low | Polish wave |

## Decision

All six systems remain deferred. No story chain is currently active for any of them. The earliest recommended next-wave targets, based on dependency topology and deferral risk, are:

1. **Skill and Trait** (medium risk — Player UI may need refactoring)
2. **Town Management UI** (medium risk — Home town summary may need refactoring)

These should be the first candidates when a new feature wave is planned beyond the current Presentation follow-through cycle.
