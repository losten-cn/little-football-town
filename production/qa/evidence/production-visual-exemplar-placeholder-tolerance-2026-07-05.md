# Production Visual Exemplar and Placeholder Tolerance — 2026-07-05

> **Result**: READY WITH WARNINGS
> **Scope**: Production gate visual-readiness evidence for MVP route surfaces
> **Art Bible**: `design/art/art-bible.md`
> **Visual walkthrough evidence**: `production/qa/evidence/mvp-visual-walkthrough-2026-06-06.md`
> **Player-experience baseline**: `production/qa/evidence/production-gate-player-experience-baseline-2026-06-06.md`
> **UX review**: `production/qa/evidence/ux-review-production-gate-2026-06-06.md`

## Purpose

Record the minimum production-representative visual exemplar and placeholder tolerance rule needed to reduce the Production gate Art Director concern.

This evidence does not claim final art quality. It defines which MVP route surfaces are representative enough to continue Production, which placeholders are tolerated, and which placeholder conditions must block or trigger a focused visual fix.

## Source Evidence

| Source | Relevant finding |
|---|---|
| `design/art/art-bible.md` | Art Bible approved; visual identity prioritizes warmth, clarity, invitation, pixel readability, and bright readable management UI. |
| `mvp-visual-walkthrough-2026-06-06.md` | 12-step MVP route screenshots passed; no visual blocker recorded. |
| `production-gate-player-experience-baseline-2026-06-06.md` | Focused revision made Home, Player/Training, Match Pre/Live/Result visually reviewable and route-complete. |
| `ux-review-production-gate-2026-06-06.md` | Placeholder presentation remains an accepted warning only because it does not create interaction ambiguity or route blockers. |
| `production/gate-checks/2026-07-01-pre-production-to-production.md` | Art Director concern is not missing visual direction; it is weak production-representative examples and loose placeholder boundaries. |

## Production-representative Exemplar Surfaces

The following MVP route surfaces are the current production-representative exemplar set for gate purposes:

| Surface | Evidence | Representative requirement | Current status |
|---|---|---|---|
| Home initial / Home return | visual walkthrough steps 01, 06, 12 | Warm town-light baseline, clear next step, readable management state | Representative with warnings |
| Roster / Player Detail | visual walkthrough steps 02, 03 | Readable player management hierarchy and training rationale | Representative with warnings |
| Training / Training Result | visual walkthrough steps 04, 05 | Clear action, cost/benefit feedback, return path | Representative with warnings |
| Match disabled reason | visual walkthrough step 07 | Disabled state must explain why and what to do next | Representative with warnings |
| Match Pre | visual walkthrough step 08 | Pre-match judgment, lineup/tactic state, start action | Representative with warnings |
| Match Live / Timeline | visual walkthrough steps 09, 10 | Live state and timeline readable; command depth may remain shallow | Representative with warnings |
| Match Result | visual walkthrough step 11 | Outcome, performance, league impact, and next step visible | Representative with warnings |

These surfaces are representative for **layout, hierarchy, color direction, and player comprehension**, not for final pixel-art asset fidelity.

## Placeholder Tolerance Rule

### Allowed placeholders

Placeholders are allowed during current Production continuation when all of the following are true:

1. They do not hide or obscure critical actions.
2. They do not create route ambiguity or imply a disabled/broken state.
3. They do not expose internal IDs, enums, or developer-only labels to players.
4. They preserve the approved warm-town direction:
   - cream / warm neutral panels
   - deep readable text
   - restrained gold/red/green/blue semantic accents
   - no dark corporate default UI
5. They remain readable at the reviewed resolution.
6. They are limited to asset fidelity, content depth, or polish gaps rather than interaction meaning.

Allowed examples:

- temporary portrait silhouettes
- simplified facility or town icons
- low-detail UI panels that still follow warm-town palette and spacing
- simple match timeline rows
- simplified roster cards
- placeholder town warmth elements that do not imply unimplemented interaction

### Not allowed placeholders

The following placeholder conditions are not acceptable for Production gate continuation and must trigger a focused fix:

1. Blank, black, or visually empty main content panels.
2. Gray-box surfaces with no player-facing meaning.
3. Internal IDs, enum names, debug payload keys, or sync placeholders visible in reviewed player-facing routes.
4. Placeholder buttons or panels that look clickable but are not, unless explicitly disabled with reason text.
5. Missing disabled-state explanation for route-critical actions.
6. Placeholder art that breaks the approved visual identity:
   - neon/cyberpunk palette
   - cold sci-fi dashboard treatment
   - dark spreadsheet-style management UI as the default
   - HD/vector/gloss elements mixed into pixel-art UI
   - close-copy Kairosoft silhouettes or UI framing
7. Text contrast, focus state, or icon-only state that violates reviewed accessibility expectations.
8. Placeholder elements that obscure the return path to Home.

## Art Director Closure Criteria

The Art Director concern can be reduced from CONCERNS toward READY WITH WARNINGS when all criteria below are true:

- [x] Art Bible exists and is approved.
- [x] MVP route has visual walkthrough evidence covering Home, Player/Training, Match, Result, and return to Home.
- [x] Existing placeholders are classified as accepted warnings, not blockers, under UX review.
- [x] Placeholder tolerance rule is documented.
- [x] Non-accepted placeholder conditions are explicitly listed.
- [ ] At least one future production art pass replaces representative placeholder assets for Home and Match surfaces.
- [ ] Future screenshot evidence confirms the first production art pass still preserves route clarity and accessibility.

For the current gate, the first five criteria are sufficient for **READY WITH WARNINGS**, not final visual PASS.

## Gate Impact

This evidence reduces the visual-readiness concern from:

> Visual production baseline is not fully locked; placeholder tolerance and final representative fidelity need tighter definition.

to:

> Visual identity and placeholder tolerance are defined enough for Production continuation with warnings. Final production art replacement and screenshot confirmation remain follow-up work.

This does not claim clean final-art readiness.

## Remaining Visual Follow-up

- Replace key Home / Match / Player placeholder assets with first-pass production pixel art.
- Capture a new visual walkthrough after the first production art pass.
- Keep warm-town palette and bright readable UI as baseline.
- Do not reopen route topology, ScreenManager, or gameplay authority as part of visual polish.
- Do not add unapproved interaction depth while replacing visual assets.

## Verdict

**READY WITH WARNINGS** for Production gate visual-readiness follow-through.

Production can continue under the existing warning posture. Clean visual READY still requires a future production art pass and fresh screenshot evidence, but placeholder boundaries are now explicit enough to reduce rework risk.
