# Adoption Plan

> **Generated**: 2026-05-14
> **Project phase**: Concept
> **Engine**: Not configured
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

No blocking gaps were detected in the current template-managed files.

The current risk is different: the repository is still missing the template-native
artifacts that the skill pipeline expects, while the real design source lives in
external markdown files under `E:\code\game\game-design\` and `E:\code\game\ui-design\`.
Treat the high-priority migration below as the actual unlock path.

---

## Step 2: Fix High-Priority Gaps

### 2.1 Configure the project engine and core technical preferences
The template cannot route engine-specific skills or validate ADR compatibility because `.claude/docs/technical-preferences.md` still has placeholder values for Engine, Language, Rendering, and Physics.

**Fix command**: `/setup-engine`

**What to capture**:
- Engine and version
- Primary language
- Rendering pipeline
- Physics backend
- Target platforms and primary input

**Time**: 5 min
- [ ] Engine, Language, Rendering, and Physics are configured in `.claude/docs/technical-preferences.md`

### 2.2 Create `design/gdd/game-concept.md` from the external overview document
The repository does not have an authoritative template-format concept GDD. Skills that depend on `design/gdd/game-concept.md` currently have nothing to read.

**Source material**:
- `E:\code\game\game-design\00-足球小镇-策划总览.md`

**Recommended fix**:
- Use `/design-system` to author `design/gdd/game-concept.md`
- Port the following from the source document: game overview, core fantasy, target users, market positioning, and high-level loop
- Ensure the new file includes all 8 required sections:
  - `## Overview`
  - `## Player Fantasy`
  - `## Detailed Rules`
  - `## Formulas`
  - `## Edge Cases`
  - `## Dependencies`
  - `## Tuning Knobs`
  - `## Acceptance Criteria`
- Add a valid header field such as `**Status**: In Design`

**Time**: 30 min
- [ ] `design/gdd/game-concept.md` exists and matches the template section structure

### 2.3 Create `design/gdd/systems-index.md`
The repository has no systems index, so the template has no authoritative registry of systems, layers, priorities, or design status.

**Source material**:
- `E:\code\game\game-design\00-足球小镇-策划总览.md` section `2.2 各系统概述`
- `E:\code\game\game-design\02-足球小镇-数值平衡方案.md`
- `E:\code\game\game-design\03-足球小镇-玩家留存与商业化.md`
- `E:\code\game\game-design\04-足球小镇-音效与音乐设计.md`
- `E:\code\game\ui-design\足球小镇-UI交互设计文档.md`

**Manual steps**:
1. Create `design/gdd/systems-index.md`
2. Add a markdown table with at least these columns:
   - `System name`
   - `Layer`
   - `Priority`
   - `Status`
3. Use only valid status values:
   - `Not Started`
   - `In Progress`
   - `In Review`
   - `Designed`
   - `Approved`
   - `Needs Revision`
4. Seed rows for at least these systems:
   - Player Training
   - Match Simulation
   - Town Building
   - Economy
   - Reputation / Achievements
   - Random Events
   - Balance
   - UI / UX
   - Audio
   - Retention / Monetization

**Time**: 30 min
- [ ] `design/gdd/systems-index.md` exists with valid columns and valid status values

### 2.4 Recover or replace the empty system architecture source
`E:\code\game\game-design\01-足球小镇-系统架构设计.md` is currently a 0-byte file. That means one of the core source artifacts for migration is missing.

**Manual steps**:
- Decide whether the original content can be recovered from backup/version history
- If recoverable, restore the source file first
- If not recoverable, rebuild the missing architecture intent from:
  - `00-足球小镇-策划总览.md` section `2. 系统设计汇总`
  - `02-足球小镇-数值平衡方案.md`
  - `足球小镇-UI交互设计文档.md`
- Once the architecture intent is clear, begin creating ADRs under `docs/architecture/`

**Recommended follow-up command**:
- `/architecture-decision` for the first ADR after the recovery decision is made

**Time**: 30 min
- [ ] The missing system architecture intent is recovered, restored, or explicitly rebuilt into ADRs

### 2.5 Migrate the balance design into template-compatible GDDs
The balance document is detailed, but it does not use the template’s required section headings or valid status field, so story-generation and review skills cannot consume it reliably.

**Source material**:
- `E:\code\game\game-design\02-足球小镇-数值平衡方案.md`

**Recommended fix**:
- Create one or more GDDs in `design/gdd/` using `/design-system`
- At minimum, preserve:
  - core formulas
  - player attribute rules
  - training formulas
  - match outcome expectations
  - economy balance assumptions
- Each migrated file must include `## Acceptance Criteria`

**Suggested split**:
- `design/gdd/player-progression.md`
- `design/gdd/match-balance.md`
- `design/gdd/economy-balance.md`

**Time**: 1 session
- [ ] Balance design is migrated into template-compatible GDD files in `design/gdd/`

### 2.6 Migrate retention and monetization into template-compatible design docs
The retention/commercialization document contains strong product design input, but it is not in a structure the template can trace or review directly.

**Source material**:
- `E:\code\game\game-design\03-足球小镇-玩家留存与商业化.md`

**Recommended fix**:
- Convert the reusable game-system parts into GDDs, such as:
  - progression goals
  - achievement loops
  - challenge modes
  - long-term retention systems
- Keep purely business-facing sections as supporting docs if they do not need story generation yet

**Suggested split**:
- `design/gdd/meta-progression.md`
- `design/gdd/achievements-and-challenges.md`
- optional supporting doc in `design/` for pricing / DLC roadmap

**Time**: 1 session
- [ ] Retention-related system design is migrated into template-compatible files

### 2.7 Migrate the audio design into a template-managed artifact
The audio document is content-rich, but it currently lives outside the repository and is not connected to the template workflow.

**Source material**:
- `E:\code\game\game-design\04-足球小镇-音效与音乐设计.md`

**Recommended fix**:
- Either move it into `design/` as a repository-managed audio design document
- Or recreate it through the template audio workflow so later reviews can reference it consistently

**Recommended command**:
- `/team-audio`

**Time**: 30 min
- [ ] Audio design exists inside the repository in a stable, reviewable location

### 2.8 Migrate the UI document into a template UX spec
The UI document is extensive, but it is outside the repository and not in the format expected by the template’s UX validation flow.

**Source material**:
- `E:\code\game\ui-design\足球小镇-UI交互设计文档.md`

**Recommended fix**:
- Use `/ux-design` to create repository-native UX specs for the highest-priority screens first
- Start with:
  - main town HUD
  - player management screen
  - match preparation / match result flow
  - build mode flow
- Preserve accessibility-relevant details already present in the source doc, such as readability, color distinction, and resolution adaptation

**Time**: 1 session
- [ ] At least one core UX spec exists in the repository and is ready for `/ux-review`

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements (creates `tr-registry.yaml`)
Run `/architecture-review` — even if ADRs already exist, this run bootstraps the TR registry from your existing GDDs and ADRs.

**Important for this project**:
- Do this only after Step 2.1 through 2.5 are at least partially complete
- The review is much more useful once concept, systems index, and first GDDs/ADRs exist

**Time**: 1 session
- [ ] `docs/architecture/tr-registry.yaml` created

### 3b. Create control manifest
Run `/create-control-manifest`

**Time**: 30 min
- [ ] `docs/architecture/control-manifest.md` created

### 3c. Create sprint tracking file
Run `/sprint-plan update`

**Time**: 5 min
- [ ] `production/sprint-status.yaml` created

### 3d. Set authoritative project stage
Run `/gate-check Concept`

**Time**: 5 min
- [ ] `production/stage.txt` written

---

## Step 4: Medium-Priority Gaps

### 4.1 Backfill naming conventions in technical preferences
Naming conventions are still unset, which will slow down later code, asset, and doc generation.

**Fix location**:
- `.claude/docs/technical-preferences.md`

**Time**: 5 min
- [ ] Class, variable, file, scene/prefab, signal, and constant naming conventions are configured

### 4.2 Backfill performance budgets
Performance budgets are still placeholders, which weakens later architecture and review decisions.

**Fix location**:
- `.claude/docs/technical-preferences.md`

**Time**: 5 min
- [ ] Target framerate, frame budget, draw-call budget, and memory ceiling are configured

### 4.3 Backfill testing standards for this specific project
The project-level testing framework and minimum coverage are not configured yet.

**Fix location**:
- `.claude/docs/technical-preferences.md`

**Time**: 5 min
- [ ] Testing framework and minimum coverage are configured for this game

### 4.4 Add valid `**Status**:` fields to all migrated GDDs
The external source docs mostly use Chinese metadata or no status at all. Template skills expect a valid `**Status**:` field.

**Valid values**:
- `In Design`
- `Designed`
- `In Review`
- `Approved`
- `Needs Revision`

**Time**: 5 min per file
- [ ] Every migrated GDD includes a valid `**Status**:` field near the top of the file

### 4.5 Keep auxiliary business content separate from story-driving design content
Some monetization roadmap material is useful reference but should not be mixed into story-driving GDDs unless it produces player-facing mechanics.

**Manual steps**:
- Keep pricing / DLC / long-term release roadmap in supporting docs under `design/` or `docs/`
- Keep GDDs focused on mechanics and player-facing rules

**Time**: 30 min
- [ ] Business planning content is separated cleanly from mechanic-driving GDDs

### 4.6 Create the first ADR set after GDD migration starts
There are currently no ADRs in `docs/architecture/`, so technical assumptions are not yet captured in the format the pipeline expects.

**Recommended command**:
- `/architecture-decision`

**Suggested first ADR topics**:
- Engine and language choice
- Save system structure
- Match simulation architecture
- Data-driven balance configuration

**Time**: 1 session
- [ ] At least one ADR exists in `docs/architecture/` with required sections

### 4.7 Create architecture traceability after the first ADR/GDD review pass
The repository does not yet contain `docs/architecture/architecture-traceability.md`.

**Manual steps**:
- Generate or maintain it after the first serious architecture review pass
- Use it to confirm GDD requirements are covered by ADRs

**Time**: 30 min
- [ ] `docs/architecture/architecture-traceability.md` exists

### 4.8 Preserve external source paths during migration
These external files are currently the source of truth. Losing the mapping would make later verification harder.

**Manual steps**:
- In each migrated repository-native doc, note the original source path in a short provenance line near the top
- Example: `Source: E:\code\game\game-design\02-足球小镇-数值平衡方案.md`

**Time**: 5 min per file
- [ ] Each migrated file preserves a clear link back to its original source document

### 4.9 Re-run `/adopt` after the first migration wave
The initial audit was against a repository with almost no template-native artifacts. A second pass is needed after the first wave of migration.

**Fix command**:
- `/adopt`

**When**:
- After Step 2 and Step 3 are substantially complete

**Time**: 5 min
- [ ] A second adoption audit is run after the first migration wave

---

## Step 5: Optional Improvements

No low-priority items were recorded in this pass. Most remaining issues are still structural enough to belong in the high or medium buckets.

---

## What to Expect from Existing Stories

There are no template-native story files yet.

When you eventually create stories, existing legacy source documents do not need to be rewritten wholesale. The goal is to create repository-native, template-compatible source documents that preserve the intent of the original Chinese design set. Once those are in place, story generation and readiness checks become reliable.

---

## Notes from This Audit

- The repository itself is still close to a fresh template project.
- The real design material exists externally and is rich enough to support migration.
- `E:\code\game\game-design\01-足球小镇-系统架构设计.md` is currently empty (`0` bytes) and should be treated as a possible source-loss issue.
- `docs/engine-reference/` is present in the repository, so engine reference coverage exists once the engine choice is configured.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify the remaining gaps. The new run will reflect the current state of the repository rather than the initial “external docs only” state.
