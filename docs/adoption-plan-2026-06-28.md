# Adoption Plan

> **Generated**: 2026-06-28
> **Project phase**: Production
> **Engine**: Godot 4.6
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

No blocking gaps found. The project is already compatible with the template's critical skill pipeline.

---

## Step 2: Fix High-Priority Gaps

No high-priority gaps found in the current project state.

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements
Run `/architecture-review` — even if ADRs already exist, this run bootstraps or refreshes the TR registry from the existing GDDs and ADRs.

**Time**: 1 session
- [ ] `docs/architecture/tr-registry.yaml` confirmed current

### 3b. Create or refresh the control manifest
Run `/create-control-manifest`
**Time**: 30 min
- [ ] `docs/architecture/control-manifest.md` refreshed
- [ ] `Manifest Version:` stamp present

### 3c. Create or refresh sprint tracking
Run `/sprint-plan update`
**Time**: 5 min
- [ ] `production/sprint-status.yaml` confirmed current

### 3d. Set authoritative project stage
Run `/gate-check Production`
**Time**: 5 min
- [ ] `production/stage.txt` confirmed authoritative

---

## Step 4: Medium-Priority Gaps

### 4.1 Create persistent architecture traceability report
**Problem**: `docs/architecture/architecture-traceability.md` is missing, so there is no persistent matrix artifact for architecture coverage review.

**Fix**: Run `/architecture-review rtm` or create the file manually from the latest RTM result.
**Time**: 30 min
- [ ] `docs/architecture/architecture-traceability.md` created

### 4.2 Fill real Tuning Knobs and Acceptance Criteria in economy GDD
**Problem**: `design/gdd/economy-management-system.md` has the required section headings, but `Tuning Knobs` and `Acceptance Criteria` appear to be placeholder/empty content, which weakens story generation and review quality.

**Fix**: `/design-system retrofit design/gdd/economy-management-system.md`
**Time**: 30 min
- [ ] `design/gdd/economy-management-system.md` has concrete `Tuning Knobs`
- [ ] `design/gdd/economy-management-system.md` has concrete `Acceptance Criteria`

### 4.3 Fill real Tuning Knobs and Acceptance Criteria in town-building GDD
**Problem**: `design/gdd/town-building-system.md` has the required section headings, but `Tuning Knobs` and `Acceptance Criteria` appear to be placeholder/empty content.

**Fix**: `/design-system retrofit design/gdd/town-building-system.md`
**Time**: 30 min
- [ ] `design/gdd/town-building-system.md` has concrete `Tuning Knobs`
- [ ] `design/gdd/town-building-system.md` has concrete `Acceptance Criteria`

### 4.4 Add missing TR-ID to balance regression story
**Problem**: `production/epics/balance-system/story-009-balance-statistical-validation.md` does not contain a `TR-...` reference, so it cannot participate in requirement-level tracking cleanly.

**Fix**: Manually add the relevant `TR-balance-...` reference to the story header/body.
**Time**: 5 min
- [ ] `story-009-balance-statistical-validation.md` references at least one TR-ID

### 4.5 Add ADR references to UI/onboarding stories that currently omit them
**Problem**: several existing stories have no `ADR-` reference, which weakens architecture traceability.

**Affected files**:
- `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
- `production/epics/match-performance-ui/story-001-prematch-result-flow.md`
- `production/epics/onboarding-system/story-001-minimum-what-next-guidance.md`
- `production/epics/player-management-ui/story-001-roster-training-entry.md`

**Fix**: Manually add at least one relevant ADR reference per story.
**Time**: 30 min
- [ ] Main Loop UI story has ADR reference(s)
- [ ] Match Performance UI story has ADR reference(s)
- [ ] Onboarding story has ADR reference(s)
- [ ] Player Management UI story has ADR reference(s)

### 4.6 Add acceptance checkbox lists to stories that still lack them
**Problem**: some existing stories do not include checkbox acceptance criteria lists, which reduces consistency with the template story workflow.

**Affected groups**:
- several `economy-management-system` stories
- most `player-development-system` stories
- later `save-and-load-system` stories

**Fix**: retrofit only the stories that are still active/useful; do not regenerate completed stories unnecessarily.
**Time**: 1 session
- [ ] Active stories missing checkbox AC lists are updated
- [ ] Completed historical stories are left alone unless there is a concrete workflow need

---

## Step 5: Optional Improvements

### 5.1 Add `Manifest Version:` to existing stories over time
**Problem**: most legacy stories do not include `Manifest Version:` fields.

**Fix**: Add the field only when a story is otherwise being touched.
**Time**: 1 session if done in bulk, otherwise near-zero incremental cost
- [ ] New/edited stories include `Manifest Version:`
- [ ] Legacy completed stories are left unchanged unless needed

### 5.2 Backfill story formatting consistency opportunistically
**Problem**: some legacy stories predate current format checks and therefore miss newer metadata fields.

**Fix**: Backfill only when revisiting the file for real work.
**Time**: ongoing
- [ ] Opportunistic metadata backfill policy adopted

---

## What to Expect from Existing Stories

Existing stories continue to work with all template skills. New format checks
(TR-ID validation, manifest version staleness) auto-pass when the fields are
absent — so nothing breaks. They won't benefit from staleness tracking until
regenerated or retrofitted. Do not regenerate stories that are already in
progress or done.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved. The new run will reflect the current state of the project.
