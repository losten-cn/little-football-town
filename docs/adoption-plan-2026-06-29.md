# Adoption Plan

> **Generated**: 2026-06-29
> **Project phase**: Production
> **Engine**: Godot 4.6
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

No blocking format gaps were found in this audit.

- [x] No immediate format blockers preventing template skills from running reliably

---

## Step 2: Fix High-Priority Gaps

### 2a. Refresh the control manifest to include current ADR coverage

**Problem:** `docs/architecture/control-manifest.md` still lists ADR coverage only through `ADR-0011`, so newer architecture rules from `ADR-0012` and `ADR-0013` are not reflected in the manifest that downstream story/readiness workflows consult.

**Fix command:** `/create-control-manifest update`

**Manual notes:** After regeneration, confirm the header updates `ADRs Covered` and `Manifest Version:` to a current value.

**Time:** 30 min
- [ ] `docs/architecture/control-manifest.md` refreshed to include current ADR set

---

## Step 3: Bootstrap Infrastructure

Infrastructure already exists in this project, so this step is a **verification/refresh checklist**, not a first-time bootstrap.

### 3a. Register existing requirements (refresh traceability artifacts)
Run `/architecture-review` — even though `tr-registry.yaml` already exists, this keeps the TR registry and architecture traceability artifacts aligned with the current GDD/ADR set.

**Time**: 1 session
- [ ] `docs/architecture/tr-registry.yaml` verified or refreshed
- [ ] `docs/architecture/architecture-traceability.md` verified or refreshed
- [ ] `docs/architecture/requirements-traceability.md` verified or refreshed

### 3b. Refresh control manifest after ADR updates
Run `/create-control-manifest update`

**Time**: 30 min
- [ ] `docs/architecture/control-manifest.md` matches the current Accepted ADR set

### 3c. Verify sprint tracking file remains authoritative
Run `/sprint-plan update` if sprint metadata has drifted.

**Time**: 5 min
- [ ] `production/sprint-status.yaml` verified current

### 3d. Verify authoritative project stage
Run `/gate-check production` when you want the workflow to re-assert stage authority.

**Time**: 5 min
- [ ] `production/stage.txt` still matches current project phase

---

## Step 4: Medium-Priority Gaps

### 4a. Add ADR references to UI/onboarding stories that currently omit them

**Problem:** Several existing stories do not reference any `ADR-` token, which weakens architecture traceability and reduces confidence in `/story-readiness` style checks.

**Affected files:**
- `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
- `production/epics/match-performance-ui/story-001-prematch-result-flow.md`
- `production/epics/onboarding-system/story-001-minimum-what-next-guidance.md`
- `production/epics/player-management-ui/story-001-roster-training-entry.md`

**Fix:** Edit each story header/context so it references the governing ADR(s).

**Time:** 30 min
- [ ] All affected UI/onboarding stories reference at least one governing ADR

### 4b. Normalize story acceptance criteria into checkbox lists where missing

**Problem:** A subset of stories lacks checkbox acceptance criteria, which weakens checklist-style validation and done/readiness workflows.

**Affected areas:**
- `production/epics/player-development-system/`
- `production/epics/save-and-load-system/` (several later stories)
- `production/epics/economy-management-system/` (selected stories)

**Fix:** Manually convert each story's acceptance criteria into explicit `- [ ]` checklist entries without changing the story's scope.

**Time:** 1 session
- [ ] All active stories use checkbox acceptance criteria

### 4c. Add a TR-ID note to the verification-only balance story

**Problem:** `production/epics/balance-system/story-009-balance-statistical-validation.md` has no TR-ID reference, which breaks direct requirement linkage for that story.

**Fix:** Add the relevant TR-ID(s), or explicitly note that the story is verification-only and references multiple upstream TRs.

**Time:** 5 min
- [ ] `story-009-balance-statistical-validation.md` has an explicit TR linkage note

### 4d. Remove or rename the non-standard `production/epics/index.md`

**Problem:** `production/epics/index.md` is neither `EPIC.md` nor a standard story file, so broad story scans may treat it as a candidate story artifact.

**Fix:** Rename it to a non-story filename, move it elsewhere, or replace it with per-epic `EPIC.md` usage only.

**Time:** 5 min
- [ ] `production/epics/index.md` no longer appears as a story-like artifact in scans

---

## Step 5: Optional Improvements

### 5a. Add `Manifest Version:` to legacy stories over time

**Problem:** Existing stories mostly predate manifest-version stamping, so they auto-pass staleness checks and do not benefit from rule-version drift detection.

**Fix:** When touching a legacy story for real work, add `Manifest Version:` matching `docs/architecture/control-manifest.md`.

**Time:** incremental
- [ ] Legacy stories gradually gain `Manifest Version:` as they are naturally edited

---

## What to Expect from Existing Stories

Existing stories continue to work with all template skills. New format checks
(TR-ID validation, manifest version staleness) auto-pass when the fields are
absent — so nothing breaks. They won't benefit from staleness tracking until
regenerated or incrementally updated. Do not regenerate stories that are in
progress or done.

---

## Re-run

Run `/adopt` again after completing Step 2 and the highest-priority items in Step 4
to verify all high-priority compatibility gaps are resolved. The new run will
reflect the current state of the project.
