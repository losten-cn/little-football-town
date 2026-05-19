# Adoption Plan

> **Generated**: 2026-05-19
> **Project phase**: Production (inferred; `production/stage.txt` is missing)
> **Engine**: Godot 4.6
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Audit Summary

- GDDs audited: 16 markdown files under `design/gdd/` excluding `game-concept.md` and `systems-index.md`
  - 12 actual system GDDs are structurally compatible.
  - 4 cross-review reports are stored in the GDD folder and contaminate glob-based workflows.
- ADRs audited: 0
- Stories audited: 0
- Prior adoption plan detected: `docs/adoption-plan-2026-05-14.md`
- Engine preferences: configured
- Engine reference: present at `docs/engine-reference/godot/VERSION.md`
- TR registry: present at `docs/architecture/tr-registry.yaml`

Gap counts:

- **BLOCKING**: 1
- **HIGH**: 1
- **MEDIUM**: 4
- **LOW**: 2

---

## Step 1: Fix Blocking Gaps

### 1a. Move review reports out of the GDD corpus path

**Problem**: Four review reports live under `design/gdd/`, so glob-based template skills that scan `design/gdd/*.md` can misread review artifacts as system GDDs.

Affected files:

- `design/gdd/gdd-cross-review-2026-05-15.md`
- `design/gdd/gdd-cross-review-2026-05-16.md`
- `design/gdd/gdd-cross-review-2026-05-16-rerun.md`
- `design/gdd/gdd-cross-review-2026-05-16-v3.md`

**Fix**: Move these reports to a non-GDD report folder such as `design/reviews/` or update all GDD-scoped workflows to explicitly exclude `gdd-cross-review-*.md`.

**Time**: 5 min

- [ ] Review reports no longer contaminate `design/gdd/*.md` GDD scans

---

## Step 2: Fix High-Priority Gaps

### 2a. Create the architecture control manifest

**Problem**: `docs/architecture/control-manifest.md` is missing, so programmer rules, guardrails, and manifest version checks have no authoritative source.

**Fix command**: Run `/create-control-manifest`.

**Time**: 30 min

- [ ] `docs/architecture/control-manifest.md` created
- [ ] Manifest header includes `Manifest Version:`

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements

`docs/architecture/tr-registry.yaml` already exists. Re-run `/architecture-review` only if you need to refresh requirement traceability from current GDDs and architecture artifacts.

**Time**: 1 session if refreshed

- [ ] `docs/architecture/tr-registry.yaml` verified current

### 3b. Create control manifest

Run `/create-control-manifest` if Step 2a has not already completed it.

**Time**: 30 min

- [ ] `docs/architecture/control-manifest.md` created

### 3c. Create sprint tracking file

Run `/sprint-plan update`.

**Problem**: `production/sprint-status.yaml` is missing, so sprint tooling cannot rely on the preferred structured status file.

**Time**: 5 min if a sprint plan already exists as markdown

- [ ] `production/sprint-status.yaml` created

### 3d. Set authoritative project stage

Run `/gate-check Production` or the intended current phase.

**Problem**: `production/stage.txt` is missing, so project phase detection falls back to heuristics.

**Time**: 5 min

- [ ] `production/stage.txt` written

---

## Step 4: Medium-Priority Gaps

### 4a. Add architecture traceability output

**Problem**: `docs/architecture/architecture-traceability.md` is missing, so there is no persistent architecture traceability matrix.

**Fix command**: Run `/architecture-review` after the control manifest exists.

**Time**: 1 session

- [ ] `docs/architecture/architecture-traceability.md` created or refreshed

### 4b. Establish ADR corpus when architecture decisions are made

**Problem**: No `docs/architecture/adr-*.md` files exist yet. This is not a format failure, but ADR-based workflows cannot validate accepted technical decisions until ADRs are created.

**Fix command**: Use `/architecture-decision` for each significant technical decision.

**Time**: 30 min per ADR

- [ ] First foundation ADR created when the next architecture decision is needed

---

## Step 5: Optional Improvements

### 5a. Resolve placeholder content in economy GDD

**Problem**: `design/gdd/economy-management-system.md` still contains `[To be designed]` placeholders.

Known lines from audit: 347, 351, 379.

**Fix command**: Run `/design-system retrofit design/gdd/economy-management-system.md` or manually fill the placeholders with approved content.

**Time**: 30 min

- [ ] Economy GDD has no `[To be designed]` placeholders

### 5b. Resolve placeholder content in town-building GDD

**Problem**: `design/gdd/town-building-system.md` still contains `[To be designed]` placeholders.

Known lines from audit: 778, 782, 851.

**Fix command**: Run `/design-system retrofit design/gdd/town-building-system.md` or manually fill the placeholders with approved content.

**Time**: 30 min

- [ ] Town-building GDD has no `[To be designed]` placeholders

---

## What to Expect from Existing Stories

No story files were found under `production/epics/**/*.md` excluding `EPIC.md`.

When stories are created later, new format checks such as TR-ID validation and manifest-version staleness checks will work best after `docs/architecture/control-manifest.md` and `production/sprint-status.yaml` exist.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps are resolved. The new run will reflect the current state of the project.
