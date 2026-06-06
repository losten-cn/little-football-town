# MVP Playtest Handoff — 2026-06-05

> Scope: Current MVP vertical slice only
> Result entering playtest: READY WITH WARNINGS
> Timebox: 5 minutes per player

## Purpose

Validate whether a player can complete the current vertical slice without developer explanation:

`Home → Roster / Training → one training resolution → Match Pre → Match Live → Match Result → Home`

This handoff does not authorize new feature work. Treat polish, depth, localization, analytics, and future onboarding items as warnings unless they break the route loop.

## Evidence Entering Playtest

- `production/qa/evidence/mvp-topology-smoke-2026-06-04.md` — PASS WITH WARNINGS.
- `production/qa/evidence/mvp-route-sanity-2026-06-05.md` — PASS WITH WARNINGS.
- `L2_PLAYABLE_LOOP_PANELS_TEST_PASS` — A route headless sanity passed.
- `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS` — B route headless sanity passed.

## Playtest Script

Observer instruction: do not explain the route unless the player is blocked for more than 30 seconds. Record blockers only; non-blocking friction remains a warning.

### 0:00–2:00 — Player Management Route

Ask the player to start from Home and continue naturally.

Expected route:

`Home → Roster → Player Detail → Training → Home`

Observe:

- Does the player find the roster/player path from Home?
- Can the player reach a player detail view?
- Can the player enter Training and understand that one training resolution occurred?
- Can the player return Home without help?

### 2:00–4:30 — Match Route

Expected route:

`Home → Match Pre → Match Live → Match Result → Home`

Observe:

- Does the player find the match entry from Home?
- If match start is disabled, is the disabled-state reason visible?
- If match start is allowed, does the player reach Match Live?
- Does the player reach Match Result and confirm back to Home?

### 4:30–5:00 — Home Continuation Check

After returning Home, ask the player what they think they would do next.

Observe:

- Is Home still interactive?
- Does the player understand the loop can continue?
- Are they blocked by a modal, blank state, or missing CTA?

## Pass Criteria

PASS WITH WARNINGS if the player completes the route within 5 minutes and no implementation-breaking blocker appears.

## Blocker Criteria

Any one of these is a blocker:

- Crash, freeze, black screen, or soft lock.
- Blank page or missing mounted panel.
- Wrong route after a major button/request event.
- Route cannot proceed or cannot return Home.
- Blocking modal prevents route progress.
- Required disabled-state text is missing.
- Authoritative match gate is ignored or incorrectly blocks a valid start.
- Training, match start, result confirmation, or Home return fails due to payload handoff.
- Player needs developer explanation to find the next critical step.

## Warnings to Preserve

Do not fix these during this handoff unless they become blockers:

- Roster sorting/filtering depth.
- Match Live/Halftime command depth.
- League impact polish.
- Final PlayerDevelopment UI read model polish.
- Full localization key coverage.
- Onboarding persistence, cooldowns, replay, analytics, and anchor registry.
- Minor layout, copy, or feedback polish that does not stop route completion.

## Immediate Production Decision After Playtest

- If blockers found: open one smallest possible topology hotfix slice and fix only the route-breaking issue.
- If no blockers: freeze the MVP topology wave and move to the next production step with warnings carried forward.
