# Adoption Plan

> **Generated**: 2026-06-28
> **Project phase**: Production
> **Engine**: Godot 4.6 / GDScript
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

No blocking gaps were found in this audit.

---

## Step 2: Fix High-Priority Gaps

### 2.1 Reclassify `gdd-cross-review-2026-05-31-skill-trait-patch.md`
This file was a review report stored under `design/gdd/`, so the template audited it as if it were a system GDD and reported all 8 required GDD sections plus the `**Status**` field as missing.

**Resolution**: Moved to `design/reviews/gdd-cross-review-2026-05-31-skill-trait-patch.md`.

**Time**: 5 min
- [x] `gdd-cross-review-2026-05-31-skill-trait-patch.md` no longer sits in the GDD directory

### 2.2 Reclassify `gdd-cross-review-2026-05-31.md`
This file was a review report stored under `design/gdd/`, so the template audited it as if it were a system GDD and reported all 8 required GDD sections plus the `**Status**` field as missing.

**Resolution**: Moved to `design/reviews/gdd-cross-review-2026-05-31.md`.

**Time**: 5 min
- [x] `gdd-cross-review-2026-05-31.md` no longer sits in the GDD directory

### 2.3 Reclassify `gdd-cross-review-2026-06-01.md`
This file was a review report stored under `design/gdd/`, so the template audited it as if it were a system GDD and reported all 8 required GDD sections plus the `**Status**` field as missing.

**Resolution**: Moved to `design/reviews/gdd-cross-review-2026-06-01.md`.

**Time**: 5 min
- [x] `gdd-cross-review-2026-06-01.md` no longer sits in the GDD directory

### 2.4 Reclassify `gdd-cross-review-2026-06-03.md`
This file was a review report stored under `design/gdd/`, so the template audited it as if it were a system GDD and reported all 8 required GDD sections plus the `**Status**` field as missing.

**Resolution**: Moved to `design/reviews/gdd-cross-review-2026-06-03.md`.

**Time**: 5 min
- [x] `gdd-cross-review-2026-06-03.md` no longer sits in the GDD directory

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements (creates tr-registry.yaml)
Already present in the current project state.
**Time**: 5 min verify
- [x] `docs/architecture/tr-registry.yaml` created

### 3b. Create control manifest
`docs/architecture/control-manifest.md` already exists, but it is missing the required header stamp.

**Manual steps**:
1. Add a header line near the top of `docs/architecture/control-manifest.md`:
   `Manifest Version: YYYY-MM-DD`
2. Keep the value stable until the next intentional manifest refresh.

**Time**: 5 min
- [ ] `docs/architecture/control-manifest.md` includes `Manifest Version:`

### 3c. Create sprint tracking file
Already present in the current project state.
**Time**: 5 min verify
- [x] `production/sprint-status.yaml` created

### 3d. Set authoritative project stage
Already present in the current project state (`production/stage.txt` = `Production`).
**Time**: 5 min verify
- [x] `production/stage.txt` written

---

## Step 4: Medium-Priority Gaps

### 4.1 Create architecture traceability matrix
There is no persistent architecture traceability document yet, so cross-checking GDD → ADR → story coverage remains harder than the template expects.

**Manual steps**:
1. Create `docs/architecture/architecture-traceability.md`.
2. Record the mapping between major GDD requirements, ADR coverage, and shipped stories.
3. Keep it as a maintained artifact instead of a one-off report.

**Time**: 30 min
- [ ] `docs/architecture/architecture-traceability.md` created

### 4.2 Add missing TR-ID references to legacy stories
Some existing stories predate the TR registry pattern and therefore do not carry a `TR-...` requirement reference.

**Affected files**:
- `production/epics/balance-system/story-009-balance-statistical-validation.md`
- `production/epics/onboarding-system/story-001-minimum-what-next-guidance.md`

**Manual steps**:
1. Add the appropriate `TR-...` reference to each story header or requirement section.
2. Confirm the referenced ID already exists in `docs/architecture/tr-registry.yaml`.

**Time**: 30 min
- [ ] Legacy stories include valid TR-ID references

### 4.3 Add missing ADR references to legacy stories
A few older stories do not reference any `ADR-...` record yet, which weakens architectural traceability.

**Affected files**:
- `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md`
- `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md`
- `production/epics/economy-management-system/story-003-warning-threshold-cooldown-events.md`
- `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md`
- `production/epics/economy-management-system/story-005-daily-recovery-maintenance-settlement.md`

**Manual steps**:
1. Add at least one relevant `ADR-xxxx` reference to each story.
2. Prefer the ADR that actually constrains or enables the story’s implementation.

**Time**: 30 min
- [ ] Legacy stories include ADR references

### 4.4 Add missing story status field
One legacy story is missing a readable status field, so workflow tooling cannot parse its lifecycle state consistently.

**Affected file**:
- `production/epics/index.md`

**Manual steps**:
1. Decide whether this file should remain in the audited story set.
2. If yes, add a readable `Status:` field.
3. If no, move it out of the story glob path or adjust future audits to exclude index files.

**Time**: 5 min
- [ ] Story audit scope or status field issue resolved for `production/epics/index.md`

### 4.5 Add missing acceptance checklists to legacy stories
Several older stories do not yet include checkbox-style acceptance criteria, which reduces compatibility with template-driven readiness and done checks.

**Affected files**:
- `production/epics/balance-system/story-001-balance-config-validation.md`
- `production/epics/balance-system/story-002-attribute-formula.md`
- `production/epics/balance-system/story-003-attribute-growth.md`
- `production/epics/balance-system/story-004-resource-settlement.md`
- `production/epics/balance-system/story-005-positional-rating.md`
- `production/epics/balance-system/story-006-win-probability.md`
- `production/epics/balance-system/story-007-kpi-formulas.md`
- `production/epics/balance-system/story-008-balance-consistency-scan.md`
- `production/epics/balance-system/story-009-balance-statistical-validation.md`
- `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md`
- `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md`
- `production/epics/economy-management-system/story-003-warning-threshold-cooldown-events.md`
- `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md`
- `production/epics/economy-management-system/story-005-daily-recovery-maintenance-settlement.md`
- `production/epics/league-competition-structure-system/story-001-minimum-league-loop.md`
- `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
- `production/epics/match-performance-ui/story-001-prematch-result-flow.md`
- `production/epics/onboarding-system/story-001-minimum-what-next-guidance.md`
- `production/epics/player-management-ui/story-001-roster-training-entry.md`

**Manual steps**:
1. Add checkbox-form acceptance criteria (`- [ ] ...`) to each story.
2. Keep them aligned with the original intent of the story instead of rewriting scope.

**Time**: 1 session
- [ ] Legacy stories include checkbox acceptance criteria

---

## Step 5: Optional Improvements

### 5.1 Add `Manifest Version:` to historical stories
All 69 audited stories are missing a `Manifest Version:` field. This is intentionally low priority because template checks auto-pass when the field is absent.

**Manual steps**:
1. Do not regenerate in-progress or completed stories just for this field.
2. Add the version opportunistically when a story is next substantively edited.
3. Use the current control manifest version when you do so.

**Time**: 1 session
- [ ] Historical stories gradually gain `Manifest Version:` fields when touched

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
