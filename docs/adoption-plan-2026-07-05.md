# Adoption Plan

> **Generated**: 2026-07-05
> **Project phase**: Production
> **Engine**: Godot 4.6
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

No blocking gaps were found in this audit. The project is already template-compatible at the blocking level.

---

## Step 2: Fix High-Priority Gaps

### 2a. Add acceptance criteria checkbox list to `production/epics/index.md`
Problem: The epic index file is being picked up by the story audit but does not contain story-style acceptance checkboxes.
Manual steps: Either exclude this file from future story-format expectations in your workflow, or add a minimal note clarifying it is an index rather than a story artifact.
**Time**: 5 min
- [ ] Epic index handling clarified

### 2b. Add acceptance criteria checkbox list to Player Development stories
Problem: The following stories are missing checkbox-style acceptance criteria required by the template story audit:
- `production/epics/player-development-system/story-001-player-data-serialization-boundary.md`
- `production/epics/player-development-system/story-002-training-efficiency-formula.md`
- `production/epics/player-development-system/story-003-training-gain-cap.md`
- `production/epics/player-development-system/story-004-player-tier-band.md`
- `production/epics/player-development-system/story-005-training-roi.md`
- `production/epics/player-development-system/story-006-training-atomic-integration.md`
- `production/epics/player-development-system/story-007-player-milestone-history.md`
- `production/epics/player-development-system/story-008-player-state-boundary.md`
- `production/epics/player-development-system/story-009-player-development-regression.md`
Manual steps: For each story, convert existing acceptance criteria into checklist items using `- [ ]` format without regenerating the rest of the document.
**Time**: 30 min
- [ ] Player Development story acceptance checklists added

### 2c. Add acceptance criteria checkbox list to Save and Load stories
Problem: The following stories are missing checkbox-style acceptance criteria required by the template story audit:
- `production/epics/save-and-load-system/story-004-autosave-triggers.md`
- `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md`
- `production/epics/save-and-load-system/story-006-save-migration.md`
- `production/epics/save-and-load-system/story-007-load-restore-order.md`
- `production/epics/save-and-load-system/story-008-save-recovery-flow.md`
- `production/epics/save-and-load-system/story-009-save-summary-performance.md`
Manual steps: For each story, convert existing acceptance criteria into checklist items using `- [ ]` format without regenerating the rest of the document.
**Time**: 30 min
- [ ] Save and Load story acceptance checklists added

### 2d. Add acceptance criteria checkbox list to Economy Management stories
Problem: The following stories are missing checkbox-style acceptance criteria required by the template story audit:
- `production/epics/economy-management-system/story-006-staged-settlement-formulas.md`
- `production/epics/economy-management-system/story-007-accredited-entry-points.md`
- `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`
Manual steps: For each story, convert existing acceptance criteria into checklist items using `- [ ]` format without regenerating the rest of the document.
**Time**: 30 min
- [ ] Economy Management story acceptance checklists added

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements (creates tr-registry.yaml)
Run `/architecture-review` — even if ADRs already exist, this run bootstraps the TR registry from your existing GDDs and ADRs.
**Time**: 1 session (review can be long for large codebases)
- [ ] tr-registry.yaml created

### 3b. Create control manifest
Run `/create-control-manifest`
**Time**: 30 min
- [ ] docs/architecture/control-manifest.md created

### 3c. Create sprint tracking file
Run `/sprint-plan update`
**Time**: 5 min (if sprint plan already exists as markdown)
- [ ] production/sprint-status.yaml created

### 3d. Set authoritative project stage
Run `/gate-check Production`
**Time**: 5 min
- [ ] production/stage.txt written

---

## Step 4: Medium-Priority Gaps

### 4a. Add missing traceability metadata to `production/epics/index.md`
Problem: The epic index file lacks a TR-ID reference, ADR reference, and readable Status field, which lowers audit quality.
Manual steps: Either mark this file clearly as a non-story index artifact or add minimal metadata headers so audits do not flag it as incomplete.
**Time**: 5 min
- [ ] Epic index metadata clarified

### 4b. Add missing TR-ID reference to `production/epics/balance-system/story-009-balance-statistical-validation.md`
Problem: This story cannot participate fully in requirement staleness tracking without a TR-ID.
Manual steps: Add the appropriate `TR-...` reference in the story header or traceability section.
**Time**: 5 min
- [ ] `story-009-balance-statistical-validation.md` references a TR-ID

### 4c. Add missing ADR references to UI-oriented stories
Problem: The following stories do not reference at least one ADR:
- `production/epics/player-management-ui/story-001-roster-training-entry.md`
- `production/epics/onboarding-system/story-001-minimum-what-next-guidance.md`
- `production/epics/match-performance-ui/story-001-prematch-result-flow.md`
- `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
Manual steps: Add the most relevant ADR reference(s) to each story without rewriting story scope.
**Time**: 30 min
- [ ] UI-oriented stories reference ADRs

### 4d. Add `Manifest Version:` stamp to `docs/architecture/control-manifest.md`
Problem: The control manifest exists but is missing its manifest version stamp, so staleness checks are partially blind.
Fix command: `/create-control-manifest`
Manual steps: If you prefer manual editing, add a `Manifest Version:` line in the manifest header using the current template version.
**Time**: 5 min
- [ ] Control manifest includes `Manifest Version:`

---

## Step 5: Optional Improvements

### 5a. Fill `Tuning Knobs` content in `design/gdd/main-loop-ui-framework.md`
Problem: The required section exists but still looks placeholder-level, reducing downstream design usefulness.
Fix command: `/design-system retrofit design/gdd/main-loop-ui-framework.md`
**Time**: 30 min
- [ ] `main-loop-ui-framework.md` has concrete tuning knobs

### 5b. Add `Manifest Version:` to existing story files
Problem: Most legacy stories predate manifest-version stamping, so staleness checks auto-pass instead of tracking exact manifest lineage.
Manual steps: Add `Manifest Version:` to story headers as you touch those files naturally. Do not mass-regenerate in-progress stories.
Affected scope: 70 story-like files are missing this field in the current audit.
**Time**: 1 session
- [ ] Legacy stories gradually gain `Manifest Version:` stamps

---

## What to Expect from Existing Stories

Existing stories continue to work with all template skills. New format checks
(TR-ID validation, manifest version staleness) auto-pass when the fields are
absent — so nothing breaks. They won't benefit from staleness tracking until
regenerated. Do not regenerate stories that are in progress or done.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved. The new run will reflect the current state of the project.
