# active.md Template Convention (Project-Global)

`production/session-state/active.md` is the file-backed session memory
(see `.claude/docs/context-management.md`). It is rotated automatically
by `tools/dev/rotate-active.sh`, invoked from the session-stop hook.

**The rotator splits the file by `## Session Extract` anchors.** It
keeps the newest 5 extracts (top of file) and archives the rest. Any
content NOT inside a `## Session Extract` block is invisible to the
normal rotation path and accumulates without bound. A bulk-rotation
fallback now catches over-threshold non-conforming files, but bulk
rotation loses per-section granularity — only the per-extract schema
gives you incremental archival.

## The canonical schema

Every write to `active.md` (whether by a skill, hook, or agent) MUST
use the following structure:

```markdown
# Active Session State

<!-- STATUS -->
Epic: [optional]
Feature: [optional]
Task: [optional]
<!-- /STATUS -->

## Session Extract — YYYY-MM-DD HH:MM — [Short Title]

(newest extract goes here; PREPEND new extracts after the STATUS
block, never append)

[body of this session's work — decisions, files touched, next steps]

## Session Extract — YYYY-MM-DD HH:MM — [Older Title]

[older body]

...
```

### Hard rules

1. **The only top-level section type below the STATUS block is
   `## Session Extract — …`.** No `## Current Task`, no `## Notes`,
   no `## Findings`. If you need substructure, use `### H3 headers`
   INSIDE a Session Extract.

2. **Newest-on-top.** New extracts are prepended right after the
   STATUS block. The bottom of the file is always the oldest extract.

3. **One extract per logical work unit.** A `/design-review` is one
   extract. A `/story-done` is one extract. A multi-session ADR
   authoring is one extract per session — not one giant extract that
   spans days. Granularity = archival precision.

4. **Title format:** `## Session Extract — YYYY-MM-DD HH:MM — [Title]`
   The date is required (rotator uses creation order, not date, but
   the date is human-readable for audit). The title should reference
   the artifact or task (e.g., "B1 dTier Combat Math — Pass-2 Verify").

5. **Body is free-form Markdown.** Use H3 / H4 / lists / tables / code
   blocks as needed. The only constraint is no H2 headers inside.

6. **TL;DR first line (MANDATORY).** The first content line inside every
   `## Session Extract` block MUST be:

   ```markdown
   - **TL;DR:** <≤200 chars, single line, plain prose, no markdown inside the body>
   ```

   The TL;DR is the canonical "what happened" signal — readable in one
   line without parsing the rest of the extract. Skills doing a
   project-state survey grep for `^- \*\*TL;DR:\*\*` and read only those
   lines; full extracts are read only when an extract is load-bearing
   for the current task.

   Example:

   ```markdown
   ## Session Extract — YYYY-MM-DD — Short Title

   - **TL;DR:** One-line summary (≤200 chars) of what this session accomplished or decided. Plain prose, no markdown formatting inside.

   - **Files touched:**
     - `.claude/docs/some-doc.md` — new
     - `.claude/docs/another-doc.md` — added section
     - `CLAUDE.md` — references the new doc
   - **Recommended next:** Group 3 (GDD slug normalization).
   ```

   The hook `.claude/hooks/validate-active-md.sh` SHOULD warn on extracts
   missing a TL;DR line; promote to error once dogfooded for 1 week.

### Soft rules

- Keep each extract under ~200 lines. If an extract grows past that,
  it usually means the work itself should have been split.
- Reference files by path (e.g., `design/gdd/b1-dtier-combat-math.md`)
  so future sessions can find them.
- Don't paste large file contents into extracts — link to them.
- Keep the TL;DR under 200 chars. It's the line a future reader scans
  to decide whether to read the rest. Beyond 200 chars, it stops being
  a TL;DR.

## What writes to active.md

These skills/hooks are authorised writers:

- `/design-system`, `/design-review`, `/review-all-gdds`
- `/dev-story`, `/story-done`, `/story-readiness`
- `/map-systems`, `/create-architecture`, `/architecture-review`
- `/team-qa`, `/team-release`, `/ux-design`, `/create-epics`,
  `/create-stories`
- `.claude/hooks/session-stop.sh` (archives on exit)
- `.claude/hooks/pre-compact.sh` / `post-compact.sh` (preserve across
  compaction)

Each MUST emit the per-extract schema. The PostToolUse enforcement
hook (`.claude/hooks/validate-active-md.sh`) flags non-conforming
writes with a warning so drift is caught immediately, not at
rotation time.

## Enforcement

- **Authoring time:** the `validate-active-md.sh` hook runs after any
  `Write`/`Edit` to `active.md` and warns if the file violates the
  schema (e.g., contains a top-level `## X` that is not
  `## Session Extract`).
- **Rotation time:** if the file is over threshold but has fewer than
  6 `Session Extract` anchors, the rotator falls back to bulk
  rotation (archives the entire body, resets active.md to a fresh
  header). STATUS=rotated-bulk in the rotator output.

## Versioning

| Version | Date | Change |
|---|---|---|
| 1.0 | (your project's initial adoption date) | Initial template. |
| 1.1 | (later) | Added Hard Rule 6 — mandatory TL;DR first line in every Session Extract. |

Maintain this table in your own project as you customise the schema.
