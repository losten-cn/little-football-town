## Retrospective: Sprint 5 — Feature-Adjacent Presentation
Period: 2026-07-11 -- 2026-07-18
Generated: 2026-07-10 (early close — all stories delivered ahead of schedule)

### Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Stories | 2 Must + 1 Should + 1 Nice | 4 | +0 |
| Completion Rate | -- | 100% | -- |
| Est. Effort Days | 4.0 | ~1.0 session | −3.0 (ahead) |
| Bugs Found (new) | -- | 0 | -- |
| Unplanned Tasks | -- | 0 | -- |
| Commits | -- | 2 | -- |

### Velocity Trend

| Sprint | Planned | Completed | Rate |
|--------|---------|-----------|------|
| Sprint 3 | — | 3 stories | — |
| Sprint 4 | 7 (governance) | 7 | 100% |
| Sprint 5 | 4 (Must 2 + Should 1 + Nice 1) | 4 | 100% |

**Trend**: Stable — 100% completion rate sustained across three consecutive sprints.

### What Went Well

- **Presentation-stub pattern matured**: S5-01 → S5-02 → S5-03 all followed the same architecture (PanelContainer + EventBus subscription + authority payload consumption + neutral fallback). The pattern is now battle-tested and repeatable — S5-03 was implemented in one pass without architectural surprises.
- **Authority-contract discipline held**: All 3 new UI stubs consumed only authoritative payloads (TownBuilding, AudioManager, pending_skill_trait_feedback). No UI layer truth drift. The S4 governance investment (authority-contract decision checklist) paid off in implementation speed.
- **S5-04 was a clean extension**: The halftime adjust stub was a single-file change (match_perf_panel.gd) — disabled placeholder → interactive OptionButton + confirm. Zero new files, zero test infrastructure, zero architectural impact. This validated that the presentation architecture is extensible without refactoring.
- **L2 regression guardrail rock-solid**: The L2 playable loop panels test caught broken halftime assertions immediately and was fixed in one round. This has been the single most valuable automated test across 3 sprints.

### What Went Poorly

- **S5-03 test debugging overhead**: The Audio Settings test required 3 debugging rounds (lambda callback vs EventBus, "previously freed" reference, test-order state pollution). Headless autoload testing has subtle behaviors that the team now understands but should document. Total debugging time was disproportionate to implementation time for a 0.5-day story.
- **No manual visual evidence files created**: All 4 UI stories lack `production/qa/evidence/` entries. This is an open advisory item carried from Sprints 3/4/5. The headless renderer can't produce screenshots, and the manual evidence workflow hasn't been triggered. This is now a process gap, not a one-time omission.

### Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| Headless renderer: no screenshots for UI evidence | Ongoing (3 sprints) | Accepted as known limitation; Structure Pass used as proxy | Document in `known-issues.md`; create evidence manually when editor is available |

### Estimation Accuracy

| Story | Estimated | Actual | Variance | Note |
|-------|-----------|--------|----------|------|
| S5-01 Growth Summary | 1.5d | ~sub-day | ahead | Presentation-stub pattern well-rehearsed |
| S5-02 Town Grid | 1.5d | ~sub-day | ahead | Required TownBuilding injection + test debugging |
| S5-03 Audio Settings | 0.5d | ~sub-day | ahead | Required new autoload + test debugging overhead |
| S5-04 Halftime | 0.5d | ~minutes | ahead | Single-file button replacement |

**Overall**: All stories completed significantly ahead of estimates. The 1.5-day estimates for S5-01/S5-02 are high for the actual scope; either the estimates were conservative or the Presentation-stub pattern is faster to execute than initially modeled.

### Technical Debt Status
- Current TODO: 1 (town_grid.gd progress bar — `TODO(S5-followup)`)
- Current FIXME: 0
- Current HACK: 0
- Trend: Stable — extremely low tech debt
- Pre-existing: `training_request_bridge_test.gd` (3 failures, pre-dates Sprint 5)

### Previous Action Items Follow-Up

| Action Item (from Sprint 4) | Status | Notes |
|-----------------------------|--------|-------|
| S4-02 authority-contract checklist applied in implementation | Done | Applied to S5-01, S5-02, S5-03 pre-implementation |
| S4-07 next-wave candidates pre-check | Done | S5-01 (Skill/Trait) and S5-02 (Town) were top candidates |

### Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | Document Presentation-stub pattern in `docs/architecture/` as a reusable template | UI Programmer | High | Sprint 6 |
| 2 | Create manual visual evidence files for S5-01/02/03/04 OR accept headless limitation formally | UI Programmer | Med | Sprint 6 |
| 3 | Triage `training_request_bridge_test.gd` pre-existing failures | Lead Programmer | Med | Sprint 6 |
| 4 | Document headless autoload test patterns (EventBus subscribe in tests, frame await requirements) | GDScript Specialist | Low | Sprint 7 |

### Process Improvements

- **Pre-commit evidence checklist**: Before `/story-done`, verify that either (a) manual evidence file exists, or (b) the story explicitly accepts the headless limitation. This prevents the ongoing advisory carryover.
- **Autoload test cookbook**: The S5-03 test debugging (lambda callbacks, "previously freed" references, frame await count) suggests creating a one-page reference for testing new autoloads headlessly.

### Summary

Sprint 5 was an exceptionally efficient sprint — 4 stories delivered ahead of schedule with zero regressions. The Presentation-stub pattern (PanelContainer + EventBus + authority payload + neutral fallback) has matured into a reliable template that makes adding new read-only UI surfaces trivial. The S4 governance investment in authority contracts and the L2 regression guardrail continue to pay returns.

The single most important improvement for Sprint 6: close the manual visual evidence gap. Three sprints of advisory carryover is a process smell. Either create the files or formally accept headless limitation.
