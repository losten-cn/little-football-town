# Production Gate Convergence Evidence — 2026-06-07

> Result: PASS WITH WARNINGS / READY TO CONTINUE PRODUCTION CONVERGENCE  
> Scope: Post-gate Production convergence evidence for MVP route readability, warning reduction, and deferred depth boundaries  
> Review Mode: lean  
> Compliance Note: AI-agent expert surrogate playtest evidence is accepted for this Production gate; external-human participant validation is not claimed.

## Executive Summary

The first Production convergence batch reduced the most immediate player-experience warnings without changing route topology or gameplay authority contracts.

The work stayed inside the UI display/request layer and focused on five topology slices:

| Slice | Status | Evidence |
|---|---:|---|
| A — Roster / Player decision clarity | Reduced | Roster rows now explain attention reason and next step; Player Detail explains current use and training judgment. |
| B — Training ROI decision line | Reduced | Training screen now shows selected option, cost, benefit, risk/tradeoff, payoff timing, next step, and result. |
| C — Match feedback readability | Reduced | Match Pre / Live / Result now provide checklist framing, current focus, impact language, and result next step. |
| D — Warm town-light visual baseline | Reduced | Global UI baseline now favors warm/light town panels, wood/amber borders, and deep-brown text; dark treatment is local to high-tension match contexts. |
| E — QA regression guardrails | Added | Focused UI integration checks now assert the new route readability markers. |

No new blocking player-experience issue was introduced in the reviewed MVP route.

## Verification Evidence

### Focused UI Regression

Observed markers from the convergence pass:

```text
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
MVP_VISUAL_WALKTHROUGH_PASS
```

Previously accepted focused baseline markers remain part of the Production gate evidence package:

```text
MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS
WHAT_NEXT_GUIDANCE_TEST_PASS
```

### Automated Baseline

The earlier compatible execution baseline remains part of this gate package:

```text
COMPATIBLE_AUTOMATED_TEST_BASELINE_SUMMARY passed=69 failed=0 total=69 elapsed=18.26s modes={'node_runner': 32, 'direct_scene_tree': 37}
COMPATIBLE_AUTOMATED_TEST_BASELINE_PASS
```

A current local standard split-runner rerun using the same Node/SceneTree routing recorded in `.github/workflows/tests.yml` also passed:

```text
STANDARD_AUTOMATED_TEST_BASELINE_SUMMARY node=32 scenetree=37 passed=69 failed=0 total=69 elapsed=19.00s
STANDARD_AUTOMATED_TEST_BASELINE_PASS
```

This closes the local SceneTree-vs-Node runner mismatch for the standard split-runner baseline. It does not claim remote GitHub Actions green status for the current branch.

### Visual Walkthrough

The MVP visual walkthrough passed after the first convergence batch and generated the 12-step route screenshot set:

```text
MVP_VISUAL_WALKTHROUGH_PASS
MVP_VISUAL_WALKTHROUGH_OUTPUT_DIR=C:/Users/kylin/AppData/Roaming/Godot/app_userdata/Football Town/mvp_visual_walkthrough
```

Reviewed route:

```text
Home → Roster → Player Detail → Training → Home → Match Pre → Match Live → Match Result → Home
```

The walkthrough confirms the route remains visible and navigable. It does not claim final visual polish, final art quality, or external-human comprehension validation.

## Warning Reclassification

| Warning Area | New Classification | Rationale |
|---|---:|---|
| Roster/player next-action clarity | Reduced | Roster and Player Detail now expose attention reason, usage, and training judgment in the walked MVP path. |
| Training ROI/tradeoff readability | Reduced | Training now exposes authoritative cost/benefit/risk/payoff wording from payloads without inventing gameplay values. |
| Match Pre readiness readability | Reduced | Pre-match screen now frames readiness as a checklist and explains whether the match can start. |
| Match Live moment-to-moment meaning | Reduced, still carried | Live screen and timeline now explain focus and impact, but command depth and emotional match feel remain shallow. |
| Match Result next step | Reduced | Result screen now explains outcome, performance, league impact, and return action. |
| Warm town-light visual identity | Reduced, still carried | Baseline palette and local UI styling now align with warm-town direction; bespoke final art and pixel fidelity remain future polish. |
| Low-fidelity placeholder visuals | Carried | Styling improved but placeholder visual production quality is not final. |
| Roster sorting/filtering depth | Carried | Current route clarity is acceptable; deeper roster tooling is out of the gate scope. |
| Player emotional attachment / deeper attributes | Carried | Detail screen explains decisions, but personality/attachment depth remains future work. |
| Match Live / Halftime command depth | Deferred warning | Real command-depth implementation would require tactics/UI command contracts and risks expanding gameplay authority scope. |
| Full localization key coverage | Carried | Reviewed route copy is acceptable, but full coverage remains a Release/Polish concern. |
| Onboarding persistence / cooldowns / analytics / anchor registry | Carried | Current guidance is non-blocking and route-helpful; persistence and analytics are future systems. |
| External-human participant validation | Policy-carried | AI-agent surrogate playtests are accepted for this Production gate; external-human validation is not claimed. |
| CI-like runner mismatch | Locally resolved / remote not claimed | Local standard Node/SceneTree split-runner baseline is green; remote GitHub Actions proof is still future evidence if required. |

## Training Request Bridge Addendum

The approved minimum training wiring slice now closes the previous `training_requested` consumer gap without making UI authoritative.

Evidence:

```text
TRAINING_REQUEST_BRIDGE_TEST_PASS
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS
WHAT_NEXT_GUIDANCE_TEST_PASS
MVP_VISUAL_WALKTHROUGH_PASS
STANDARD_AUTOMATED_TEST_BASELINE_SUMMARY node=33 scenetree=37 passed=70 failed=0 total=70 elapsed=20.43s
STANDARD_AUTOMATED_TEST_BASELINE_PASS
```

Scope notes:

- UI still emits only the training request and displays authoritative read models.
- `TrainingRequestCoordinator` bridges the request to `PlayerDevelopment.train()` and `EconomyManager` / `TimeManager` authority.
- Training project values now come from `TrainingCatalogConfig`, not UI text payloads.
- Runtime seed players and starting funds/AP remain MVP composition-root seed data and should move behind a fuller new-game/save bootstrap story later.
- Tests and visual walkthrough prepare the TimeManager action window explicitly; the HUD coordinator does not reset time authority.
- External-human validation and remote GitHub Actions green status are still not claimed.

## Match Start Authority Bridge Addendum

The approved minimum match-entry wiring slice closes the previous direct route gap without expanding Match Live or Halftime command depth.

Evidence:

```text
MATCH_START_REQUEST_BRIDGE_TEST_PASS
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS
TRAINING_REQUEST_BRIDGE_TEST_PASS
MATCH_STATE_FLOW_TEST_PASS
HALFTIME_ADJUSTMENT_TEST_PASS
MATCH_RESULT_PACKET_TEST_PASS
MVP_VISUAL_WALKTHROUGH_PASS
```

Scope notes:

- UI now emits `match_start_requested` instead of directly routing from Match Pre to Match Live.
- `MatchStartCoordinator` bridges the request to `MatchSimulation.start_formal_match()` with `TimeManager` as the time authority.
- Only core authorization emits `screen_requested: match_live`; rejection emits `match_start_failed` and keeps the route on Match Pre.
- Route IDs, `ScreenManager`, save payloads, match simulation depth, and halftime/tactical command scope remain unchanged.
- The local headless visual walkthrough emitted dummy-renderer null texture errors while still reporting `MVP_VISUAL_WALKTHROUGH_PASS`; this is recorded as environment/screenshot-backend warning, not as a bridge failure.

## Match Live / Halftime Scope Decision

Do not start a real Match Live / Halftime command-depth slice in this batch.

Reason:

- A real halftime interaction would likely require new tactical command semantics, UI-to-simulation contracts, or save/event schema implications.
- The Production gate convergence goal is warning reduction and evidence closure, not expansion of the match system.
- Current Match Live improvements are safe because they are read-only presentation of existing authoritative payloads.

If a future sprint chooses to touch this area, the safe minimum slice should stay presentation-only unless a new story explicitly approves tactics/simulation contracts:

- show a clear halftime state;
- show score and one-line match summary;
- explain that substitutions/tactical adjustment are future versions if unavailable;
- provide continue-watching guidance;
- avoid changing route IDs, event schemas, save schemas, or simulation authority.

## Guardrails Preserved

- Route topology remains frozen: `Home → Roster → Player Detail → Training → Home → Match Pre → Match Live → Match Result → Home`.
- No route ID changes.
- No `ScreenManager` changes.
- No save payload/schema changes.
- No existing event payload/schema changes; only the local `match_start_requested` / `match_start_failed` bridge events were added.
- Gameplay authority remains in core systems; match entry now goes through `MatchSimulation.start_formal_match()`.
- UI remains display/request layer.
- No external-human validation claim is made.
- No remote GitHub Actions green claim is made.

## Recommended Next Step

Close this convergence batch as evidence/warning reduction and continue Production with warnings carried forward.

Recommended immediate priority:

1. Keep the MVP route topology frozen.
2. Do not expand Match Live/Halftime into real command depth until a dedicated gameplay/technical story exists.
3. Keep collecting visual and UX evidence as UI polish continues.
4. Treat remote GitHub Actions proof as future evidence if a shared CI-green claim is needed.
