# Validation Policy Normalization — 2026-06-08

> Verdict: COMPLETE WITH WARNINGS  
> Scope: Production MVP validation evidence wording normalization  
> Current validation rule: AI surrogate validation is accepted as effective project evidence; external-human validation is not required under the current project rule.

## Purpose

This note records the validation-policy normalization pass that closed the previous wording ambiguity around external-human validation.

Older evidence files were written while the project still used human-playtest wording. The current project rule supersedes that wording: AI surrogate validation is valid evidence for Production MVP route completion, decision readability, and main-loop return quality.

This pass does not claim that external-human participants were observed. It only clarifies that external-human validation is not required under the current project rule.

## AI Equivalent Player Validation Scope

The validation formerly described as human validation is now treated as AI equivalent player validation.

Fixed route:

```text
Home
→ Roster
→ Player Detail
→ Training
→ Home
→ Match Pre
→ Match Live
→ Match Result
→ Home
```

Required validation content:

- Main route completion.
- Successful return to Home after Match Result.
- No wrong route, blank page, blocking modal, or route stack failure.
- Home next-step readability.
- Roster attention / usage / next-step readability.
- Player Detail usage, this-round judgment, cost/return, and next-step readability.
- Training cost, AP cost, authoritative preview/return, risk/tradeoff, and next-step readability.
- Match Pre readiness and disabled-reason readability.
- Match Live state, latest highlight, impact, and next-focus readability.
- Match Result result, reason, performance/league impact, and return-Home readability.
- UI remains display/request layer and does not bypass gameplay authority.
- No route topology, `ScreenManager`, stable payload, stable node/button, save/event schema, or Match Live/Halftime depth expansion.

## AI Equivalent Player Validation Process

1. Run automated guardrails:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/main_loop_shell_navigation_test.gd
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/what_next_guidance_test.gd
godot --headless --path /home/kylin/little-football-town --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd
```

2. Run four AI surrogate review roles:

- New manager: checks whether the next step is clear without prior project knowledge.
- Management-game player: checks training cost, benefit, and tradeoff readability.
- Efficiency player: checks route speed, unnecessary stops, and return path clarity.
- UX expert surrogate: checks information hierarchy, CTA visibility, disabled reasons, and feedback clarity.

3. For each route page, record:

```text
Page:
Primary goal clear:
Next step clear:
System feedback clear:
Confusion point:
Self-recovery possible:
Blocker:
Warning:
Verdict: PASS / PASS WITH WARNING / FAIL
```

4. Classify issues:

Blockers:

- Main route breaks.
- Wrong route.
- Blank page.
- Blocking modal.
- Match Result cannot return Home.
- Match Pre disabled reason is not understandable.
- Training confirmation creates inconsistent state.
- UI bypasses core authority.
- `ScreenManager` behavior changes unexpectedly.
- Route topology changes.
- Required automated guardrail fails.

Accepted warnings:

- Copy is long or functional but understandable.
- Visual presentation remains MVP quality.
- Match Live / Halftime interaction depth is shallow.
- Training result feedback is lightweight but route-readable.
- Headless dummy renderer screenshot warnings occur while route assertions pass.
- AI surrogate briefly hesitates but can continue without route failure.

5. Verdict rule:

```text
If the complete route finishes, Home return succeeds, and blocker count is 0, verdict should be PASS WITH WARNINGS.
```

## Normalized Evidence Files

The following files were updated to align with the current validation rule:

- `production/gate-checks/2026-06-07-pre-production-to-production.md`
- `production/qa/evidence/human-validation-production-slice-2026-06-08.md`
- `production/qa/evidence/mvp-human-playtest-production-gate-2026-06-06.md`
- `production/qa/evidence/mvp-playtest-result-2026-06-06.md`
- `production/qa/evidence/mvp-route-sanity-2026-06-05.md`
- `production/qa/evidence/production-gate-convergence-2026-06-07.md`
- `production/qa/evidence/production-gate-player-experience-baseline-2026-06-06.md`
- `production/qa/evidence/ui-readiness-sprint-1.md`
- `production/qa/evidence/ux-review-production-gate-2026-06-06.md`
- `production/session-state/active.md`

The clean reference report for the current policy is:

- `production/qa/evidence/ai-surrogate-validation-production-slice-2026-06-08.md`

## Non-Claims Preserved

This normalization does not claim:

- External-human participants were observed.
- Remote GitHub Actions is green.
- Match Live / Halftime command depth is complete.
- Final visual polish is complete.

## Remaining Warnings

- Visual polish remains a Production polish warning.
- Match Live / Halftime command depth remains deferred.
- Headless dummy renderer screenshot capture may still emit environment warnings while walkthrough route assertions pass.
- Remote GitHub Actions green status is not claimed by this evidence.

## Final Decision

The Production MVP validation evidence is normalized under the current project rule.

AI surrogate validation is accepted as effective evidence. External-human validation is not required. Remaining warnings are non-blocking and should be carried into later Production polish unless a route, authority, or return-Home blocker appears.
