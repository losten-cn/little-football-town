# Adoption Plan

> **Generated**: 2026-05-28
> **Project phase**: Production
> **Engine**: Godot 4.6
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

### 1.1 Rename ADR files to match template glob expectations
The repository originally stored ADRs as `docs/architecture/adr-0001-...md`, but template skills and format audits match `docs/architecture/adr-*.md` exactly, so they had to be normalized to lowercase names.

**Manual steps:**
1. Rename these files from uppercase `ADR-` to lowercase `adr-`:
   - `docs/architecture/adr-0001-scene-management.md`
   - `docs/architecture/adr-0002-event-signal-architecture.md`
   - `docs/architecture/adr-0003-save-load-persistence.md`
   - `docs/architecture/adr-0004-data-driven-configuration.md`
   - `docs/architecture/adr-0005-player-data-model.md`
   - `docs/architecture/adr-0006-match-simulation-architecture.md`
   - `docs/architecture/adr-0007-economy-transaction-framework.md`
   - `docs/architecture/adr-0008-town-grid-facility-system.md`
   - `docs/architecture/adr-0009-league-competition-structure.md`
2. Update in-repo references that still point to uppercase paths, especially `docs/registry/architecture.yaml` and any generated indexes.
3. Re-run `/adopt` or `/architecture-review` to confirm lowercase glob discovery now works.

**Time**: 30 min
- [ ] All ADR filenames use `adr-*.md`
- [ ] Uppercase ADR path references have been updated

---

## Step 2: Fix High-Priority Gaps

No current high-priority gaps were detected after the audit. Proceed to infrastructure verification so the template’s generated files become authoritative.

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements (creates or refreshes tr-registry.yaml)
Run `/architecture-review` — even if ADRs already exist, this run bootstraps or refreshes the TR registry from your existing GDDs and ADRs.
**Time**: 1 session
- [ ] `docs/architecture/tr-registry.yaml` created or refreshed after ADR filename normalization

### 3b. Create control manifest
Run `/create-control-manifest`
**Time**: 30 min
- [ ] `docs/architecture/control-manifest.md` regenerated with a `Manifest Version:` header

### 3c. Create sprint tracking file
Run `/sprint-plan update`
**Time**: 5 min
- [ ] `production/sprint-status.yaml` verified current

### 3d. Set authoritative project stage
Run `/gate-check Production`
**Time**: 5 min
- [ ] `production/stage.txt` written

---

## Step 4: Medium-Priority Gaps

### 4.1 Add a Manifest Version header to the control manifest
The control manifest exists, but it does not expose a `Manifest Version:` header, so story staleness checks cannot compare against it.

**Fix command:** `/create-control-manifest`
**Time**: 5 min
- [ ] `docs/architecture/control-manifest.md` contains `Manifest Version:` in the header

### 4.2 Write the authoritative stage file
The project phase can be inferred as Production, but `production/stage.txt` is still missing, so phase-sensitive skills rely on heuristics instead of the canonical value.

**Fix command:** `/gate-check Production`
**Time**: 5 min
- [ ] `production/stage.txt` exists and matches the current project phase

---

## Step 5: Optional Improvements

### 5.1 Backfill Manifest Version in existing stories only when you next touch them
Existing stories are missing `Manifest Version:` in their header blocks. This does not break the workflow because the new checks intentionally auto-pass when the field is absent, but those stories cannot benefit from manifest staleness tracking until updated.

**Manual guidance:**
- Do not bulk-regenerate completed or in-progress stories.
- When a story is legitimately edited for other reasons, add the current `Manifest Version:` header then.

**Time**: 1 session if done in batch; near-zero if done opportunistically
- [ ] Story headers gradually gain `Manifest Version:` during normal maintenance

---

## What to Expect from Existing Stories

Existing stories continue to work with all template skills. New format checks
(TR-ID validation, manifest version staleness) auto-pass when the fields are
absent — so nothing breaks. They won't benefit from staleness tracking until
regenerated or manually updated. Do not regenerate stories that are in progress or done.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and medium gaps
are resolved. The new run will reflect the current state of the project.
