---
name: visual-walkthrough
description: "Automate a Godot UI walkthrough in a visible window, capture screenshots after each route/action step, review the images for blank screens, wrong routes, blocking modals, missing disabled-state text, and route completion. Use for visual QA gates and vertical-slice playtest rehearsal."
argument-hint: "[runner-path | mvp | route-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion, Task
model: sonnet
---

# Visual Walkthrough

Automates a visible Godot UI route walkthrough, captures screenshots at each step,
and produces a concise visual QA verdict.

Use this when a UI or vertical-slice flow must be checked visually before or after
manual playtest, especially when the acceptance criterion is "no blank page / wrong
route / blocking modal / missing disabled-state text" rather than formula logic.

**Output:** screenshot PNGs under `user://...` plus optional evidence file in
`production/qa/evidence/`.

---

## 1. Parse Arguments

Supported modes:

- `/visual-walkthrough mvp` — run the current MVP route walkthrough.
- `/visual-walkthrough [runner-path]` — run an existing GDScript walkthrough runner.
- `/visual-walkthrough route-name` — inspect existing runners and ask which route to run.
- No argument — default to `mvp` if `tests/integration/ui/mvp_visual_walkthrough_runner.gd` exists; otherwise ask for runner path.

For this project, the MVP runner path is:

`tests/integration/ui/mvp_visual_walkthrough_runner.gd`

---

## 2. Preflight

1. Read `.claude/docs/technical-preferences.md` and confirm engine/language.
2. Read `docs/engine-reference/godot/VERSION.md` before suggesting Godot APIs.
3. Confirm the runner exists with Glob.
4. If no runner exists, ask before creating one.

When creating a runner, follow these rules:

- Do not use `--headless`; screenshots must come from a visible window.
- Instantiate the target scene and drive real route buttons/events.
- Save screenshots to `user://[walkthrough-name]/`.
- Print each absolute screenshot path with a stable marker:
  `VISUAL_WALKTHROUGH_SCREENSHOT=[path]`.
- Print the output dir with:
  `VISUAL_WALKTHROUGH_OUTPUT_DIR=[path]`.
- Print `VISUAL_WALKTHROUGH_PASS` only if route assertions and screenshot saves pass.

Godot screenshot pattern:

```gdscript
var image: Image = root.get_texture().get_image()
var error: int = image.save_png("user://walkthrough/step.png")
```

Prefer runtime autoload lookup inside direct `--script` runners:

```gdscript
var event_bus: Node = root.get_node_or_null("EventBus")
event_bus.callv("emit", [event_name, payload])
```

Direct `--script` runners can compile before autoload singleton names are available,
so avoid direct global references like `EventBus.emit(...)` inside standalone runners.

---

## 3. Run the Walkthrough

Use the local Godot executable if known. For this project on Windows:

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --path "E:/code/little-football-town" --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd
```

Do not add `--headless`.

If the command fails:

- Compile/runtime error in runner: fix the runner, then rerun.
- Screenshot save failure: verify `user://` directory creation and write path.
- Route assertion failure: inspect the screenshot for that step before deciding whether it is a real UI blocker or runner timing/selector drift.

---

## 4. Review Screenshots

Read the generated PNG files directly.

For each step, check:

- Screen is not blank or black.
- Expected route/page content is visible.
- No blocking modal prevents progress.
- Required CTA or disabled-state text is visible.
- Route chrome does not obscure the main content.
- Final route returns to Home when expected.

For MVP route walkthrough, expected core steps are:

1. Home initial.
2. Roster.
3. Player Detail.
4. Training.
5. Training Result.
6. Home after training.
7. Home with disabled match reason, if testing the disabled branch.
8. Match Pre.
9. Match Live.
10. Match Live with timeline.
11. Match Result.
12. Home final.

---

## 5. Verdict Rules

Use this verdict table:

| Verdict | Meaning |
|---|---|
| `PASS` | All screenshots and route assertions pass; no significant warnings. |
| `PASS WITH WARNINGS` | Route completes and screenshots are usable, but polish/readability/depth issues remain. |
| `BLOCKED` | Blank/black screen, wrong route, blocking modal, missing required disabled-state text, broken payload handoff, or cannot return Home. |
| `RUNNER ISSUE` | Failure is caused by the automation runner, not the product UI. Fix runner and rerun before judging the build. |

Warnings do not block convergence unless they prevent route completion.

---

## 6. Optional Evidence File

Before writing evidence, ask:

"May I write visual walkthrough evidence to `production/qa/evidence/[name]-[date].md`?"

Evidence format:

```markdown
# [Name] Visual Walkthrough — [date]

> Result: PASS / PASS WITH WARNINGS / BLOCKED / RUNNER ISSUE
> Runner: [path]
> Output Dir: [absolute screenshot dir]

## Command

```bash
[exact command]
```

## Screenshots Reviewed

| Step | Screenshot | Expected | Result | Notes |
|---|---|---|---|---|
| 01 | `[path]` | Home initial | PASS | ... |

## Blockers

- None / [list]

## Warnings

- None / [list]

## Decision

- Freeze topology / open minimal hotfix slice / rerun after runner fix.
```

---

## 7. Session State

If this walkthrough is part of an active gate, update
`production/session-state/active.md` after evidence is written:

- runner path
- screenshot output directory
- verdict
- blockers/warnings
- next decision

Do not commit unless the user explicitly asks.
