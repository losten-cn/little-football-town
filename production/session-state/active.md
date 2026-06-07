# Active Session State

Task: Training request bridge verified with local baseline green
Date: 2026-06-07
Pipeline: Production — MVP route convergence evidence archived; A/B/C/D/E warnings reduced; training_requested now bridges to authoritative PlayerDevelopment.train() through runtime coordinator; local standard Node/SceneTree split-runner baseline passed 70/70; Match Live/Halftime command depth deferred; AI-agent surrogate playtest remains accepted gate compliance while external-human validation and remote GitHub Actions green status are not claimed

## Session Extract — Training request bridge 2026-06-07

- Minimum wiring completed: UI `training_requested` now has a production `src` consumer through `TrainingRequestCoordinator` in `Hud.tscn`.
- Authority preserved: request resolves through `TrainingCatalogConfig` → `PlayerDevelopment.train()` → `EconomyManager` / `TimeManager`; UI remains display/request layer.
- UI delivery stabilized: `MainLoopShell` caches roster/training read models for late-mounted `PlayerMgmtPanel`; `PlayerMgmtPanel` detaches old dynamic rows before queue-free so repeated refreshes keep stable node names.
- Verification passed: `TRAINING_REQUEST_BRIDGE_TEST_PASS`, `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`, `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`, `WHAT_NEXT_GUIDANCE_TEST_PASS`, `MVP_VISUAL_WALKTHROUGH_PASS`, and local standard split-runner baseline `node=33 scenetree=37 passed=70 failed=0 total=70 elapsed=20.43s`.
- Carry-forward warning: runtime seed players and starting resources remain MVP composition-root seed data; move to fuller new-game/save bootstrap later if scope expands. Tests/visual walkthrough prepare TimeManager state explicitly rather than letting the HUD coordinator reset time authority.
- Explicit non-claims: external-human participant validation and remote GitHub Actions green status are not claimed.
- Next recommended: keep this bridge closed as the minimum wiring slice; do not expand training depth until a dedicated Production story approves content/bootstrap scope.

## Session Extract — Production convergence evidence and warning reclassification 2026-06-07

- Evidence written: `production/qa/evidence/production-gate-convergence-2026-06-07.md`.
- Baseline updated: `production/qa/evidence/production-gate-player-experience-baseline-2026-06-06.md` now separates warnings into reduced, carried-forward, and deferred buckets.
- Reduced warning slices: A roster/player decision clarity, B training ROI/tradeoff readability, C Match Pre/Live/Result feedback readability, D warm town-light visual baseline, and E focused UI regression guardrails.
- Deferred warning: real Match Live / Halftime command depth remains out of current scope because it may require new tactical command semantics, UI-to-simulation contracts, or save/event schema implications.
- Guardrails kept: frozen route topology, no route ID changes, no `ScreenManager` changes, no save/event schema changes, no gameplay authority changes, and UI remains display/request layer.
- Evidence markers retained: `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`, `MVP_VISUAL_WALKTHROUGH_PASS`, `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`, `WHAT_NEXT_GUIDANCE_TEST_PASS`, compatible automated baseline 69/69, and local standard split-runner baseline 69/69.
- Explicit non-claims: external-human participant validation is not claimed; remote GitHub Actions green status is not claimed by the local standard split-runner evidence.
- CI baseline update: `production/qa/evidence/ci-runner-mismatch-waiver-2026-06-07.md` now records the prior SceneTree runner mismatch as locally resolved by the Node/SceneTree split-runner policy; remote CI proof remains future evidence if required.
- Next recommended: continue Production with warnings carried forward; do not expand Match Live/Halftime into real command depth until a dedicated gameplay/technical story approves the contract.

## Session Extract — Production gate focused display revision 2026-06-07

- Evidence updated: `production/qa/evidence/mvp-human-playtest-production-gate-2026-06-06.md` now records the focused revision verification and treats the 3 AI-agent expert surrogate sessions as this gate's accepted playtest compliance substitute.
- Files changed: `src/ui/hud/main_loop_shell.gd`, `src/ui/player/player_mgmt_panel.gd`, `src/ui/match/match_perf_panel.gd`, and the evidence file.
- Scope: Display-layer-only convergence using topology order — L1 Home information/warm-town presentation, L2 Player/Training decision clarity, and L2 Match readability/agency perception.
- Guardrails kept: no route ID changes, no `ScreenManager` changes, no core gameplay authority changes, and no new tactical/training systems.
- Verification passed: `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`, `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`, `WHAT_NEXT_GUIDANCE_TEST_PASS`, and `MVP_VISUAL_WALKTHROUGH_PASS`.
- Screenshot spot-check passed for Home, Player Detail, Match Pre, and Match Result; revised copy is visible and no blocking layout/route issue was observed.
- Verdict: PASS WITH WARNINGS for AI-agent surrogate playtest compliance and focused revision evidence; strict external-human participant validation is not claimed and remains optional future evidence only if requested later.
- Recommended next: proceed toward gate-readiness/UX sign-off convergence with warnings carried forward; do not reopen route topology unless a new route blocker appears.
- Gate-owner compliance decision: AI-agent expert surrogate sessions replace the original strict external-human playtest requirement for this Production gate; older notes that say human clarity/fun playtest is pending are superseded for this gate only, while external-human validation remains optional future evidence.
- UX/gate rereview update: `production/qa/evidence/ux-review-production-gate-2026-06-06.md` is now PASS WITH WARNINGS / READY WITH WARNINGS, and `production/qa/evidence/production-gate-player-experience-baseline-2026-06-06.md` is now READY / PASS WITH WARNINGS after focused revision rerun.
- Additional verification after typed-boundary cleanup: `L2_PLAYABLE_LOOP_PANELS_TEST_PASS` and `MVP_VISUAL_WALKTHROUGH_PASS` both passed after normalizing the selected player assignment in `src/ui/player/player_mgmt_panel.gd`.
- Next recommended: close player-experience gate readiness with warnings carried forward; separately decide whether to fix or waive the CI-like SceneTree runner mismatch before formal Production gate close.

## Session Extract — Pre-Production to Production gate readiness 2026-06-07

- Gate check written: `production/gate-checks/2026-06-07-pre-production-to-production.md`.
- Waiver written: `production/qa/evidence/ci-runner-mismatch-waiver-2026-06-07.md`.
- Verdict: Pre-Production → Production gate readiness is PASS WITH WARNINGS / READY TO ADVANCE TO PRODUCTION.
- Parallel final review: Producer, QA Lead, Release Manager, and Godot/GDScript specialist found no remaining route-level, UX-critical, or technical blocker under the accepted scope.
- Explicit non-claims: external-human participant validation is not claimed; standard CI-like runner baseline is not claimed green because SceneTree runner mismatch remains waived/tracked.
- Carry-forward warnings: low-fidelity visuals, roster/training/match depth, full localization/accessibility hardening, onboarding persistence/cooldowns/replay/analytics/anchor registry, and CI runner workflow cleanup.
- Scope guardrail: do not reopen `ScreenManager`, route IDs, shell topology, core gameplay authority, or new roster/training/match/town/onboarding systems during gate close.
- Next recommended: record Production entry if desired, then start Production work from warning-backed slices while scheduling CI runner cleanup separately.

## Current Checkpoint — 2026-06-04

- `docs/architecture/architecture.md` status header refreshed to Version 2.2 / 2026-06-04 after `/gate-check pre-production` found the old 2026-06-01 FAIL/Pending text stale.
- Technical Setup → Pre-Production remains acceptable with CONCERNS: no hard blockers, representative headless test passed, control manifest covers ADR-0001 through ADR-0011, and warnings are scoped to future Random Event/Audio ADRs plus `TR-economy-008` / `TR-town-013` follow-up.
- User preference confirmed: converge quickly, allow warnings, split work by dependency topology, and use subagents in parallel for independent tasks.
- Recommended topology: L0/L1 are complete; run L2 PlayerMgmtUI and MatchPerfUI in parallel against the frozen `shell_main_content` route/container contract, then run L3 minimum onboarding guidance after both anchors stabilize.

## Session Extract — Architecture convergence 2026-06-06

- Artifact updated: `docs/architecture/architecture.md` now has refreshed System Layer Map, Module Ownership, Data Flow, API Boundaries, ADR Audit, and Required ADRs sections.
- Phase 1-6 result: Foundation/Core topology is frozen with warnings; ADR-0001 through ADR-0011 remain accepted and cover scene/autoloads, EventBus/TimeManager, SaveManager, ConfigLoader, PlayerDevelopment, MatchCompetition, EconomyManager, TownBuilding, LeagueStructure, cross-system settlement contracts, and reputation/achievement recognition.
- Key contracts recorded: single-writer authority, stable typed payload boundaries (`Dictionary[String, Variant]`, typed arrays, stable IDs), EventBus/save payloads with no Node/Resource/Object/Callable references, stable settlement-key idempotency, and stable save/load restore order.
- No new Foundation/Core blocker ADRs are required before coding starts.
- Warnings carried forward: Random Event ADR before Random Event production; Audio Settings Persistence ADR before audio settings/production audio; Presentation UI ADRs before deep Main/Player/Match UI production; `TR-economy-008` / `TR-town-013` traceability wording drift for the next `/architecture-review`.
- Sign-off: TD-ARCHITECTURE self-review completed as APPROVED WITH CONDITIONS; LP-FEASIBILITY skipped per Lean mode; `architecture.md` Document Status updated to Version 2.3 / 2026-06-06.
- L4 readiness update: `production/qa/evidence/ui-readiness-sprint-1.md` is now READY WITH WARNINGS for S1-5/S1-6, based on story-level evidence and MVP playtest handoff.
- Automated visual walkthrough completed: `MVP_VISUAL_WALKTHROUGH_PASS` using `tests/integration/ui/mvp_visual_walkthrough_runner.gd`; screenshots reviewed from `C:/Users/kylin/AppData/Roaming/Godot/app_userdata/Football Town/mvp_visual_walkthrough`.
- Playtest result evidence updated: `production/qa/evidence/mvp-playtest-result-2026-06-06.md` is PASS WITH WARNINGS for automated route-and-screenshot coverage; original human clarity/fun playtest pending note is superseded for this gate by the 2026-06-07 gate-owner decision accepting AI-agent expert surrogate sessions as the playtest compliance substitute.
- Skill re-run evidence written: `production/qa/evidence/mvp-visual-walkthrough-2026-06-06.md` records the `/visual-walkthrough mvp` rerun, the exact command, screenshot review table, zero blockers, and carried warnings.
- Next: move to L5 gate/readiness if route-level automation is sufficient for this milestone; otherwise run a human-observed clarity/fun playtest before L5. If blockers appear, fix only the smallest route-breaking slice.

## Session Extract — Production gate player experience baseline 2026-06-06

- Evidence written: `production/qa/evidence/production-gate-player-experience-baseline-2026-06-06.md`.
- Scope: Production-entry player experience readiness, UX sign-off input, visible MVP route screenshots, and full automated test baseline.
- Playtest evidence: `production/qa/playtests/playtest-2026-06-06-player-experience.md` remains PASS WITH WARNINGS.
- Visual walkthrough: `MVP_VISUAL_WALKTHROUGH_PASS` via `tests/integration/ui/mvp_visual_walkthrough_runner.gd`; 12 screenshots reviewed from `C:/Users/kylin/AppData/Roaming/Godot/app_userdata/Football Town/mvp_visual_walkthrough`.
- Automated baseline: CI-like `tests/test_script_runner.gd` path reports 32 pass / 37 false-negative failures because existing `SceneTree` tests do not instantiate as `Node`; compatible execution passes 69/69 with `COMPATIBLE_AUTOMATED_TEST_BASELINE_PASS`.
- UX sign-off: NEEDS REVISION. No hard route blocker, but player-visible internal IDs/enums/placeholders, incomplete Home MVP information architecture, Match Pre readability, and weak pixel-town presence block Production UX approval.
- QA gate opinion: PASS WITH WARNINGS for product behavior evidence, with P1 test-runner/CI infrastructure debt before claiming standard automated baseline green.
- Decision: HOLD / NEEDS REVISION before formal Production entry; run a focused revision slice for copy hygiene, Home MVP info/town presence, disabled-state specificity, Match Pre/Live readability, and test-runner workflow compatibility.
- Next: implement the focused revision, then rerun visible MVP walkthrough, compatible full automated baseline, fixed project-standard baseline, and UX sign-off.

## Session Extract — Systems Design gate QA cleanup 2026-06-06

- Result: PASS cleanup complete — Systems Design → Technical Setup gate documentation concerns were resolved.
- Files changed: added missing MVP GDD review logs for Save/Load, Time/Season, Match Competition, League Competition, Main Loop UI, Player Management UI, Match Performance UI, and Onboarding; standardized `economy-management-system.md` and `town-building-system.md` from `## Detailed Design` to `## Detailed Rules`.
- Verification: MVP review-log presence and required-section scan now pass; latest cross-GDD review remains `PASS WITH WARNINGS` and no active blocker verdicts remain for MVP gate purposes.
- Next: Systems Design gate can now be reported as PASS; continue carrying playtest/prototype warnings into later phases.

## Pipeline Progress

| Area | Status |
|------|--------|
| Technical Setup → Pre-Production gate | Complete with CONCERNS — blockers cleared, report written to `production/gate-checks/2026-05-30-technical-setup-to-pre-production.md` |
| Test infrastructure blocker | Complete — added `tests/test_script_runner.gd`, `tests/README.md`, `tests/smoke/critical-paths.md`, `.github/workflows/tests.yml` |
| Test framework documentation alignment | Complete — `.claude/docs/technical-preferences.md` now reflects the custom headless runner path |
| Vertical slice implementation | Complete initial prototype — `prototypes/training-match-loop-vertical-slice/` contains the Home → Training → Match → Result → Home loop; Godot 4.6.2 console smoke passed with `TRAINING_MATCH_LOOP_VERTICAL_SLICE_PASS` |

## Vertical Slice Checkpoint

- **Concept**: 足球小镇 / Little Football Town
- **Slice name**: `训练日 → 比赛日 → 赛后回流`
- **Validation question**: 玩家能否在 5 分钟内、无需开发者讲解，完成一次“查看球队 → 安排训练 → 推进到比赛 → 完成比赛 → 查看赛后反馈 → 回到主界面继续做培养决策”的完整闭环，并明确感受到温馨、低压力、长期成长的足球小镇经营体验？
- **Current phase**: Phase 4 — Implement / initial loop ready for playtest
- **Art/UI quality level**: Placeholder art acceptable; UI hierarchy, interaction clarity, and feedback readability must be representative of production direction.
- **Hard time limit**: 5 working days; if the full loop is not demonstrable by Day 3, cut scope and reassess.

## Systems In Scope

- **Foundation**: `ConfigLoader`, `TimeManager`, `SaveManager`, `EventBus`, `ScreenManager`
- **Core**: `PlayerDevelopment`, `MatchCompetition`, minimum `EconomyManager`, minimum `LeagueStructure`
- **Presentation**: `MainLoopUI`, minimum `PlayerMgmtUI`, minimum `MatchPerfUI`
- **Support**: minimum onboarding / “what to do next” guidance only

## Loop In Scope

`Home → Roster/Training → one training resolution → advance to match day → Match Center / Pre-Match → one full match → Match Result → return Home`

## Explicitly Out of Scope

- Full town-building gameplay
- Full economy depth
- Multiple-season progression
- Reputation / achievements
- Random events
- Skills & traits
- Full onboarding/tutorial stack
- Deep schedule interaction
- Complete player sorting/filtering suite
- Audio polish
- Multi-run / New Game+

## Known Concerns to Carry Forward

- `production/stage.txt` is still absent; stage-aware workflows remain inference-based until a future PASS gate confirms advancement.
- `TR-economy-008` and `TR-town-013` remain partial traceability items and must be attached to later story acceptance criteria or ADR follow-up.
- One sampled unit test passes via the new runner but emits Godot object/resource leak warnings at exit; investigate before the Production gate.
- Scope discipline is critical: do not expand this slice into full HUD, full Player UI, and full Match UI production scope.

## Next Recommended Step

Current MVP topology wave is frozen with warnings after automated visual walkthrough passed. Next, carry warnings forward and start the next production step; only reopen this wave for route-breaking hotfixes.

<!-- STATUS -->
Epic: Production Gate Preparation
Feature: Player experience readiness
Task: Focused revision before Production entry
<!-- /STATUS -->

## Session Extract — MVP visual walkthrough freeze 2026-06-05
- Evidence written: `production/qa/evidence/mvp-visual-walkthrough-2026-06-05.md`.
- Runner written: `tests/integration/ui/mvp_visual_walkthrough_runner.gd`.
- Reusable skill written: `.claude/skills/visual-walkthrough/SKILL.md`; use `/visual-walkthrough mvp` for future visible Godot UI walkthrough and screenshot review gates.
- Command: `"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --path "E:/code/little-football-town" --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd`.
- Result: `MVP_VISUAL_WALKTHROUGH_PASS`; output dir `C:/Users/kylin/AppData/Roaming/Godot/app_userdata/Football Town/mvp_visual_walkthrough`.
- Screenshots: 12 route/action PNGs covering Home, Roster, Player Detail, Training, Training Result, Home after training, disabled match reason, Match Pre, Match Live, Live timeline, Match Result, and final Home.
- Blockers found: None.
- Warnings carried: placeholder synced fields in Player Detail/Training, narrow pre-match text wrapping, roster sort/filter depth, Match Live/Halftime depth, league impact polish, final PlayerDevelopment UI read model, localization, onboarding persistence/cooldowns/replay/analytics, and anchor registry remain deferred.
- Decision: Freeze MVP topology wave with warnings. Reopen only for route-breaking hotfixes, then rerun `/visual-walkthrough mvp` plus the failed route.

## Session Extract — MVP playtest handoff 2026-06-05
- Handoff written: `production/qa/evidence/mvp-playtest-handoff-2026-06-05.md`.
- Scope: current MVP vertical slice only — `Home → Roster / Training → one training resolution → Match Pre → Match Live → Match Result → Home`.
- Entering evidence: topology smoke and route sanity are both PASS WITH WARNINGS; A route passed `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`; B route passed `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`.
- Playtest rule: 5 minutes per player; observer should not explain the route unless the player is blocked for more than 30 seconds.
- Blocker policy: fix only crash/freeze/black screen, blank page, wrong route, blocked progress, missing required disabled-state text, authority gate errors, payload handoff failures, or inability to return Home.
- Warnings preserved: roster sort/filter depth, Match Live/Halftime depth, league impact polish, final PlayerDevelopment UI read model, localization, onboarding persistence/cooldowns/replay/analytics, and anchor registry.
- Next: run the human-observed playtest; if no blockers, freeze the MVP topology wave and carry warnings forward.

## Session Extract — MVP route sanity gate 2026-06-05
- Evidence written: `production/qa/evidence/mvp-route-sanity-2026-06-05.md`.
- Scope: A route `Home → Roster → Player Detail → Training → Home`; B route `Home → Match Pre → Match Live → Match Result → Home`.
- Result: PASS WITH WARNINGS.
- Verification: A route passed with `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`; B route passed with `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS` using Godot 4.6.2 console.
- Blockers found: 0 implementation-breaking blockers in the current headless route sanity coverage.
- Warnings carried: roster sort/filter depth, Match Live/Halftime command depth, league impact polish, final PlayerDevelopment UI read model, localization, onboarding persistence/cooldowns/replay/analytics, and anchor registry remain deferred.
- Next: package vertical slice playtest handoff; only fix issues that break A/B route completion in a human-observed pass.

## Session Extract — MVP topology smoke 2026-06-04
- Evidence written: `production/qa/evidence/mvp-topology-smoke-2026-06-04.md`.
- Scope: L0 LeagueStructure → L1 MainLoopShell → L2 PlayerMgmtUI / MatchPerfUI → L3 WhatNextGuidance.
- Result: PASS WITH WARNINGS.
- Verification: `WHAT_NEXT_GUIDANCE_TEST_PASS`, `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`, `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`, and `MINIMUM_LEAGUE_LOOP_TEST_PASS` using Godot 4.6.2 console.
- Review inputs: QA smoke review found no new blockers; GDScript static review found no parse/type blockers after the MatchPerf authority fix.
- Fix applied during smoke: `MatchPerfPanel.set_system_payload()` consumes system/navigation affordance payloads, `MainLoopShell` forwards `system_state_changed`, and the L2 regression asserts system-disabled pre-match start remains on `match_pre`.
- Warnings carried: roster sort/filter depth, Match Live/Halftime command depth, league-impact polish, final PlayerDevelopment UI read model, onboarding persistence/cooldowns/replay/analytics, full localization key coverage, and anchor registry remain deferred.
- Manual smoke recommended before playtest handoff: `Home → Roster → Player Detail → Training → Home → Match Pre → Match Live → Match Result → Home`; pass if no blank pages, wrong routes, blocking modals, or missing disabled-state text.
- Next: package the vertical slice for playtest, or fix only implementation-breaking warnings found by the manual route sanity check.

## Session Extract — L3 onboarding what-next guidance 2026-06-04
- Files changed: `src/ui/onboarding/what_next_guidance.gd`, `src/ui/hud/main_loop_shell.gd`, `tests/integration/ui/what_next_guidance_test.gd`, `production/qa/evidence/onboarding-system-story-001-minimum-what-next-guidance.md`, `production/epics/onboarding-system/story-001-minimum-what-next-guidance.md`, `production/epics/index.md`, `production/session-state/active.md`.
- Result: COMPLETE WITH WARNINGS — added a single non-modal `WhatNextGuidance` banner that follows Home/Roster/Training/Pre-Match/Result route context and hides after match result confirmation.
- Behavior: first Home cue is `先看看球员` (≤25 chars); direct Training path is allowed; training completion advances toward Pre-Match; match availability copy follows `time_advanced.match_trigger_reached` and `match_center_available`; missing anchors fall back to text-only guidance.
- Verification: `WHAT_NEXT_GUIDANCE_TEST_PASS`; regressions also passed with `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`, `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`, and `MINIMUM_LEAGUE_LOOP_TEST_PASS`.
- Warnings carried: Match Live/Halftime guidance, persistence, cooldown, replay, analytics, full localization keys, and anchor registry remain deferred.
- Next recommended: Run a focused smoke/regression sweep for the current MVP wave, then package the vertical slice for playtest or address only implementation-breaking warnings.

## Session Extract — L2 PlayerMgmtUI + MatchPerfUI panels 2026-06-04
- Files changed: `src/ui/player/player_mgmt_panel.gd`, `src/ui/match/match_perf_panel.gd`, `src/ui/hud/main_loop_shell.gd`, `tests/integration/ui/l2_playable_loop_panels_test.gd`, `production/qa/evidence/player-management-ui-story-001-roster-training-entry.md`, `production/qa/evidence/match-performance-ui-story-001-prematch-result-flow.md`, `production/epics/player-management-ui/story-001-roster-training-entry.md`, `production/epics/match-performance-ui/story-001-prematch-result-flow.md`, `production/epics/index.md`, `production/session-state/active.md`.
- Result: COMPLETE WITH WARNINGS — L2 PlayerMgmtPanel and MatchPerfPanel mount into the frozen `shell_main_content` contract without changing route IDs.
- Behavior: Player flow covers roster → player_detail → training handoff using authoritative `roster_updated` / `training_options_updated` payloads and request events only. Match flow covers match_pre → match_live → match_result → Home using `time_advanced`, `match_event_occurred`, `match_completed`, and `league_standings_updated` payloads.
- Verification: `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`; regressions also passed with `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS` and `MINIMUM_LEAGUE_LOOP_TEST_PASS`.
- Warnings carried: full roster sort/filter controls, final PlayerDevelopment UI read model, full lineup/fallback package, `team_match_strength` labels, league impact delta, and halftime command contract remain future depth; current MVP uses low-noise placeholders rather than recomputing authority in UI.
- Next recommended: Start L3 `production/epics/onboarding-system/story-001-minimum-what-next-guidance.md` to add minimum next-action guidance over the now-stable Home/Roster/Training/Pre-Match/Result anchors.

## Session Extract — L1 MainLoop shell implementation 2026-06-03
- Files changed: `src/ui/hud/main_loop_shell.gd`, `src/ui/hud/Hud.tscn`, `src/ui/hud/hud.gd`, `tests/integration/ui/main_loop_shell_navigation_test.gd`, `production/qa/evidence/main-loop-ui-framework-story-001-home-loop-navigation.md`, `production/epics/main-loop-ui-framework/EPIC.md`, `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`, `production/epics/index.md`, `production/session-state/active.md`.
- Result: COMPLETE — added `MainLoopShell` under HUD with frozen route IDs `home`, `roster`, `player_detail`, `training`, `match_pre`, `match_live`, `match_result`, and a single `shell_main_content` mount for L2 pages.
- Behavior: `screen_requested` routes mount inside the shell; `match_result_confirmed`, `training_cancelled`, and `roster_cancelled` return to Home through `ScreenManager.reset_to_screen("home")`; Home displays only authoritative payload snapshots from `time_advanced`, `system_state_changed`, and `player_action_completed` without recomputing gameplay truth.
- Verification: `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS` via `tests/integration/ui/main_loop_shell_navigation_test.gd`; L0 League regression also passed with `MINIMUM_LEAGUE_LOOP_TEST_PASS`.
- Evidence: `production/qa/evidence/main-loop-ui-framework-story-001-home-loop-navigation.md` created with automated smoke and manual walkthrough notes.
- Next recommended: Start L2 PlayerMgmtUI and MatchPerfUI in parallel; both should mount into `shell_main_content` and avoid altering route IDs or recomputing authoritative payloads.

## Session Extract — L0 League implementation 2026-06-03
- Files changed: `src/config/league_config.gd`, `config/league_config.tres`, `src/core/league_structure.gd`, `src/autoload/config_loader.gd`, `tests/integration/league/minimum_league_loop_test.gd`, `production/epics/league-competition-structure-system/EPIC.md`, `production/epics/league-competition-structure-system/story-001-minimum-league-loop.md`, `production/epics/index.md`, `production/session-state/active.md`.
- Result: COMPLETE — L0 LeagueConfig/LeagueStructure and the minimum league loop integration test are in place and verified.
- Verification: `"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/little-football-town" --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/league/minimum_league_loop_test.gd` passed with `MINIMUM_LEAGUE_LOOP_TEST_PASS`.
- Fixes during verification: added explicit `LeagueConfig` preload in `LeagueStructure`, normalized the test's `time_season_ended` payload to `Dictionary[String, Variant]`, and removed the LeagueConfig integer-division warning.
- Carry-forward warning: `SETTLEMENT` is currently an instantaneous internal transition to `COMPLETED`; keep it as acceptable for L0 unless a future story needs an observable settlement window.
- Next recommended: Start L1 `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`; L2 PlayerMgmtUI and MatchPerfUI should still wait for L1 route/container anchors.

## Session Extract — MVP topology story planning 2026-06-03
- Files changed: `production/epics/index.md`, `production/session-state/active.md`, plus 10 new planning files under `production/epics/league-competition-structure-system/`, `production/epics/main-loop-ui-framework/`, `production/epics/player-management-ui/`, `production/epics/match-performance-ui/`, and `production/epics/onboarding-system/`.
- Result: COMPLETE WITH WARNINGS — created topology-ordered current-wave epics/stories for L0 LeagueStructure, L1 MainLoop shell, L2 PlayerMgmt/MatchPerf UI packages, and L3 minimum what-to-do-next guidance.
- Topology: L0 League must freeze schedule/standings/next-match/settlement authority first; L1 MainLoop freezes route/container anchors next; L2 PlayerMgmtUI and MatchPerfUI can proceed in parallel after MainLoop contract; L3 onboarding waits for stable Home/Roster/Training/Pre-Match/Result anchors.
- Blockers retained: League save registration, `match_context` contract closure, `MatchResultPacket` read-only boundary, typed shallow payloads, duplicate result/settlement dedup, and UI not recomputing authoritative payloads.
- Warnings carried: Random Event and Audio remain future ADR gaps; `TR-economy-008`, `TR-town-013`, full Tutorial/Hint, full Town UI, deep schedule, complete sorting/filtering, and audio polish remain outside the current MVP wave.
- Next recommended: Start `production/epics/league-competition-structure-system/story-001-minimum-league-loop.md` with `godot-gdscript-specialist`; do not start UI implementation until L0 contract blockers are closed or explicitly accepted for additive-only scope.

## Session Extract — registry cleanup + RTM sync 2026-06-03
- Files changed: `docs/architecture/tr-registry.yaml`, `docs/architecture/requirements-traceability.md`.
- Result: COMPLETE WITH WARNINGS — fixed implementation-breaking registry wording drift and registered previously untracked designed systems without expanding gameplay scope.
- Registry changes: `last_updated` is now `2026-06-03`; active TR count is now 201; `TR-save-013`, `TR-skill-001`, and `TR-skill-008` now align with ADR-0010/control-manifest settlement rules (`rule_version` metadata-only; evaluated + processed ledgers tracked).
- New TR ranges: `TR-random-001`–`TR-random-008`, `TR-audio-001`–`TR-audio-006`, `TR-townui-001`–`TR-townui-007`, and `TR-tutorial-001`–`TR-tutorial-007`.
- RTM sync: full-chain coverage is now 90/201 (44.8%); 14 registered `NO ADR` rows are Random Event and Audio future-system gaps; there are still 0 missing stated automated test paths.
- Convergence posture: Warnings remain allowed. Random Event settlement and Audio settings require ADR coverage before Beta implementation; Town Management UI and Tutorial/Hint can wait until their Alpha/Polish story waves.
- Next recommended: Proceed to implementation planning rather than more broad cleanup.

## Session Extract — /architecture-review rtm 2026-06-03
- File changed: `docs/architecture/requirements-traceability.md`.
- Result: COMPLETE WITH WARNINGS — refreshed the full GDD → ADR → Story → Test RTM after the Control Manifest update.
- Coverage: 173 active TR entries; 90 full-chain covered (52.0%); 2 story/test-backed partial ADR warnings (`TR-economy-008`, `TR-town-013`); 81 `NO STORY`; 0 missing stated automated test paths; 0 registered `NO ADR` rows.
- Notes: Main gaps are unscheduled future work, not broken MVP evidence. Registry drift remains for Skill/Trait settlement key wording (`rule_version` must be metadata only), evaluated/processed settlement ledger wording, and unregistered Random Event / Audio / Town Management UI / Tutorial-Hint GDD contracts.
- Convergence posture: Continue allowing warnings; block only implementation-breaking stable payload, save/load, or settlement contract gaps before the related implementation starts.
- Next recommended: Focused registry cleanup before creating stories for Skill/Trait, Random Event, Audio settings, Town Management UI, or Tutorial-Hint implementation.

## Session Extract — /create-control-manifest update 2026-06-03
- File changed: `docs/architecture/control-manifest.md`.
- Result: COMPLETE — refreshed the manifest from 11 Accepted ADRs (`ADR-0001` through `ADR-0011`), `.claude/docs/technical-preferences.md`, and Godot 4.6 engine reference docs.
- Review mode: `lean`; TD-MANIFEST skipped per director-gate rules.
- Notes: Manifest version is now `2026-06-03`; ADR coverage now includes cross-system payload/settlement contracts and Reputation/Achievement recognition rules, plus current Godot 4.6 forbidden APIs and the custom headless runner test policy.
- Convergence posture: User wants fast convergence and allows warnings; continue to treat warnings as trackable unless they break implementation or stable payload/save/settlement contracts.
- Next recommended: Run `/architecture-review rtm`.

## Session Extract — /architecture-review 2026-06-03
- Report written: `docs/architecture/architecture-review-2026-06-03.md`.
- Verdict: CONCERNS — no Godot 4.6 engine blocker and no blocking accepted-ADR dependency cycle, but architecture artifacts still lag behind 2026-06-03 GDD/registry contract convergence.
- Requirements focus: Reviewed high-risk contracts from the registry; `match_result_packet` is covered, `forfeit_result_packet`, `pre_match_skill_trait_snapshot`, `pending_skill_trait_feedback`, `feedback_ack`, `match_context`, and reputation settlement keys remain partial, while Random Event settlement keys and Audio settings fields are architecture gaps until their implementation phases.
- GDD revision flags: None.
- Top follow-ups: refresh `control-manifest.md` beyond ADR-0009; update `architecture.md` stale FAIL/Pending status and coverage wording; use `/architecture-review rtm` for full production traceability after ADR cleanup.
- Next recommended: Run `/create-control-manifest update`, then `/architecture-review rtm`.

## Session Extract — payload registry coverage cleanup 2026-06-03
- Files changed: `design/registry/entities.yaml`.
- Fixes completed: Added a `contracts` registry section and registered 11 high-risk cross-system payload/durable-state/settlement contracts: `match_context`, `match_result_packet`, `forfeit_result_packet`, `pre_match_skill_trait_snapshot`, `pending_skill_trait_feedback`, `feedback_ack`, `event_settlement_key`, `processed_event_settlement_keys`, `reputation_settlement_key`, `processed_reputation_settlement_keys`, and `audio_settings_fields`.
- Verification: Lightweight structure check passed with `REGISTRY_CONTRACTS_CHECK_PASS 11`; `contracts` appears before `formulas`, all expected entries are present, and there are no duplicate contract names.
- Notes: No gameplay scope was expanded and no code/tests were run; this was registry/traceability cleanup for existing cross-system contracts.
- Remaining warnings: match-strength terminology normalization and playtest/prototype validation risks remain follow-up items, not GDD blockers.
- Next recommended: Proceed toward Technical Setup / architecture planning with warnings tracked.

## Session Extract — cross-feature contract cleanup 2026-06-03
- Files changed: `design/gdd/reputation-and-achievement-system.md`, `design/gdd/systems-index.md`, `design/gdd/match-competition-system.md`, `design/gdd/league-competition-structure-system.md`.
- Fixes completed: Closed Random Event → Reputation/Achievement receiving contract by adding random-event confirmed fact intake, safe no-op for unmapped `effect_request_type`, `event_settlement_key`-based reputation de-duplication, and acceptance criteria. Clarified Match ↔ League as a packet contract: `league -> match_context` before kickoff and `match -> match_result_packet` after final result, with no concrete runtime mutual state ownership.
- Notes: No design scope was expanded and no code/tests were run; this was warning/flag cleanup to reduce implementation ambiguity.
- Remaining warnings: non-formula payload registry coverage is still incomplete; facilities-first, Alpha attention budget, fallback-frequency, and town-identity risks remain playtest/prototype validation items rather than GDD blockers.
- Next recommended: Either add highest-risk non-formula registry entries, or proceed toward Technical Setup / architecture planning with warnings tracked.

## Session Extract — scoped warning cleanup 2026-06-03
- Files changed: `design/gdd/audio-system.md`, `design/gdd/player-development-system.md`, `design/gdd/town-management-ui.md`, `design/registry/entities.yaml`, `design/gdd/main-loop-ui-framework.md`, `design/gdd/town-building-system.md`.
- Fixes completed: Synced remaining obvious GDD header/status drift for Audio, Player Development, and Town Management UI; updated registry `training_actual_gain` to include `skill_training_multiplier` and `skill-and-trait-system.md` as a reference; assigned minimal audio Settings/Options UI container ownership to Main Loop UI without moving audio field semantics; added Town Building → Audio downstream dependency for construction/upgrade feedback events.
- Notes: No design scope was expanded and no code/tests were run; this was implementation-ambiguity cleanup for existing warnings/flags.
- Remaining warnings: non-formula payload registry coverage is still incomplete; Random Event → Reputation/Achievement receiving contract remains a scoped warning/flag; match/league packet wording and playtest validation risks remain follow-up items.
- Next recommended: If continuing cleanup, address match/league contract wording and highest-risk non-formula registry entries; otherwise proceed toward Technical Setup / architecture planning with warnings tracked.

## Session Extract — GDD tracking cleanup 2026-06-03
- Files changed: `design/gdd/gdd-cross-review-2026-06-03.md`, `design/gdd/systems-index.md`.
- Fixes completed: Renumbered Warning / Flag Items in the 2026-06-03 global review; replaced residual “scoped blocker” scenario and gate wording with scoped warning/flag language; updated Recommended Next GDD from already-approved Audio to `多周目与挑战模式系统`, with `商业化与 DLC 规划系统` as the following not-started item.
- Notes: No design scope was expanded; this was tracking/report cleanup to match the user-approved convergence posture.
- Next recommended: Continue scoped warning cleanup only where it reduces implementation ambiguity: sync remaining GDD headers, update `training_actual_gain` in the registry, assign minimal audio settings UI ownership, and add town-building → audio downstream back-reference.

## Session Extract — skill-and-trait lean re-review 2026-06-03
- Target: `design/gdd/skill-and-trait-system.md` and `design/gdd/reviews/skill-and-trait-system-review-log.md`.
- Verdict: APPROVED WITH WARNINGS — prior 2026-06-02 NEEDS REVISION blockers are accepted as resolved under the convergence posture.
- Files changed: `design/gdd/skill-and-trait-system.md`, `design/gdd/systems-index.md`, `design/gdd/reviews/skill-and-trait-system-review-log.md`.
- Fixes completed: Synchronized Skill & Trait status to Approved in the GDD header and both systems-index tables; appended a lean re-review entry documenting 0 blockers and 4 warnings/flags.
- Remaining warnings: UI optimization pressure needs playtest validation; high-risk non-formula payload contracts are not yet represented in the global registry; implementation must preserve typed payload boundaries and add regression coverage for stable keys, snapshot companions, feedback lifecycle, and partial-commit rejection.
- Next recommended: Continue status/report cleanup before implementation: fix stale cross-review wording/numbering, sync other GDD headers, update the recommended next GDD, then address registry/audio/town-building warning items as scoped follow-ups.

## Session Extract — /review-all-gdds 2026-06-03
- Report written: `design/gdd/gdd-cross-review-2026-06-03.md`.
- Scope: Full global GDD review after Audio approval and related Alpha/Beta system design additions, covering cross-GDD consistency, holistic design review, and key multi-system scenario walkthroughs.
- Verdict: PASS WITH WARNINGS — Systems Design may continue toward Technical Setup / architecture planning, with no project-blocking items.
- Scoped warning/flag: `random-event-system.md` can emit confirmed event facts for reputation/achievement consumption, but `reputation-and-achievement-system.md` does not yet define the receiving contract. Track before implementing that specific cross-feature hook, or explicitly scope it out; do not block global GDD convergence on it.
- Main warnings: GDD header/status and `systems-index.md` next-GDD drift; stale `training_actual_gain` registry entry missing `skill_training_multiplier`; empty non-formula registry contracts; audio settings entry ownership split across Audio/Save/Main UI; town-building lacks audio downstream back-reference; match/league should be phrased as packet contract exchange; facilities-first, Alpha attention budget, and fallback-frequency risks need validation.
- Notes: No code or tests were run; this was a design-document consistency and scenario review pass. User explicitly prefers warnings/flags for convergence unless a gap breaks implementation or core contracts.
- User choice: Wrote the PASS WITH WARNINGS report and updated session state.
- Next recommended: Resolve or scope out Random Event → Reputation/Achievement recognition, then sync status tracking and update the registry before implementation relies on those contracts.

## Session Extract — /review-all-gdds 2026-06-01
- Report written: `design/gdd/gdd-cross-review-2026-06-01.md`.
- Scope: Re-review after blocker-repair and skill/trait patch alignment, covering cross-GDD consistency, holistic design review, and key multi-system scenario walkthroughs.
- Verdict: PASS WITH CONCERNS — Systems Design may proceed to Technical Setup / architecture planning.
- Blockers closed: `match_day_ap_safety_grant` now aligns across time, economy, UI, and onboarding; illegal lineup fallback is closed through recommended lineup, out-of-position fill, or `forfeit_result_packet`; town-building MVP outputs are compressed to consumed contracts; skill/trait long-term state is fully carried by save/load; skill/trait UI consumption is closed through snapshot, feedback, candidate visibility, and identity-history contracts.
- Remaining concerns: match-strength terminology should be normalized between balance and match layers before implementation; `design/registry/entities.yaml` still lacks non-formula ownership entries for active payload contracts; economy soft-stall is formally recoverable but still needs feel validation; town-building facility attractiveness may still skew toward training-first choices.
- Notes: No code or tests were run; this was a design-document consistency and scenario review pass.
- User choice: Wrote the PASS WITH CONCERNS report file and did not update `systems-index.md` in the same step.
- Next recommended: Begin Technical Setup / architecture planning and track the remaining warnings as targeted follow-up work.

## Session Extract — GDD blocker repair 2026-05-31
- Source report: `design/gdd/gdd-cross-review-2026-05-31.md` — verdict was FAIL pending blocker fixes.
- Files changed: `design/gdd/systems-index.md`, `design/gdd/town-building-system.md`, `design/gdd/player-development-system.md`, `design/gdd/match-competition-system.md`, `design/gdd/economy-management-system.md`, `design/gdd/main-loop-ui-framework.md`, `design/gdd/time-and-season-progression-system.md`, `design/gdd/league-competition-structure-system.md`, `design/gdd/onboarding-system.md`.
- Fixes completed: MVP now includes a tightly scoped town-building slice; complete building UI/deep layout remains Alpha; core dependency direction no longer depends on Presentation UI; town-building MVP outputs are limited to consumed contracts; match-day AP deadlock is resolved via `match_day_ap_safety_grant`; illegal lineup fallback resolves through recommended lineup, out-of-position fill, or `forfeit_result_packet`.
- Notes: No code or tests were run; this was a design-document consistency pass. Remaining review warnings should be split into follow-up tasks rather than bundled into this blocker repair.
- Next recommended: Re-run `/review-all-gdds`; if PASS or PASS WITH CONCERNS, continue with scoped warning cleanup or Technical Setup planning.

## Session Extract — /review-all-gdds skill-trait patch 2026-05-31
- Report written: `design/gdd/gdd-cross-review-2026-05-31-skill-trait-patch.md`.
- Scope: Full global GDD re-review after the skill-and-trait targeted patch, including cross-GDD consistency, holistic design review, and multi-system scenario walkthrough.
- Verdict: FAIL — Systems Design should not advance to Technical Setup until blockers are resolved or explicitly accepted.
- Blockers originally: town-building still competes for primary progression; pre-match attention budget remains overloaded; economic soft-stall recovery is not proven; skill-system long-term state is not fully carried by save/load; skill-system UI consumption contract is incomplete.
- Resolved in this repair pass: #49 caps Match Pre active decisions at 4 and demotes AP/facility/skill/league/growth context to automatic or read-only summary; #50 compresses town-building MVP into a minimum visible support slice with no numeric adjacency, no facility AP recovery, no stadium revenue multiplier, `facility_training_multiplier` capped at 1.35, and `home_advantage_bonus` capped at 5; #51 proves economic soft-stall recovery through formal match progression, loss income, season bottom bonus, and `season_recovery_floor_grant` that tops up only to `minimum_regular_funds_action_cost` after season settlement; #52 closes the skill/trait UI consumption contract by defining Player Detail candidate stages, blocked reasons, identity history, feedback ack behavior, Match Pre read-only snapshots, and Match Result skill/trait explanations; #53 closes the skill/trait save-load contract by adding field-level persistence for `candidate_progress_record`, `trait_cooldown_state`, `feedback_ack`, `player_identity_history_entry`, `skill_trait_migration_record`, stable settlement keys, and illegal half-settlement restore prevention.
- Still pending: No known blockers from the skill-trait patch review; needs `/review-all-gdds` verification.
- User choice: Wrote a new report file and did not update `systems-index.md` for the FAIL verdict.
- Next recommended: Re-run `/review-all-gdds` to verify blocker closure.

## Session Extract — /dev-story 2026-05-25
- Story: `production/epics/balance-system/story-001-balance-config-validation.md` — Story 001: 定义 BalanceConfig 数据资源与启动校验
- Files changed: `src/config/balance_config.gd`, `src/autoload/config_loader.gd`, `config/balance_config.tres`, `tests/unit/balance/balance_config_validation_test.gd`, `production/epics/balance-system/story-001-balance-config-validation.md`
- Test written: `tests/unit/balance/balance_config_validation_test.gd` (5 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH (`godot --headless --quit` returned command not found). Static GDScript specialist review found no remaining definite Godot 4.6 syntax/type blockers.
- Next: Run `godot --headless -s tests/unit/balance/balance_config_validation_test.gd`, then `/code-review src/config/balance_config.gd src/autoload/config_loader.gd tests/unit/balance/balance_config_validation_test.gd`, then `/story-done production/epics/balance-system/story-001-balance-config-validation.md`

## Session Extract — /story-done 2026-05-25
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/balance-system/story-001-balance-config-validation.md` — Story 001: 定义 BalanceConfig 数据资源与启动校验
- Tech debt logged: None
- Next recommended: `production/epics/balance-system/story-006-win-probability.md` — Implement base win probability formula consuming BalanceConfig

## Session Extract — /dev-story 2026-05-25
- Story: `production/epics/save-and-load-system/story-001-save-snapshot-slots.md` — Story 001: 建立 SaveSnapshot 与存档槽结构
- Files changed: `production/epics/save-and-load-system/story-001-save-snapshot-slots.md`, `production/sprint-status.yaml`, `src/autoload/save_manager.gd`, `src/autoload/save_snapshot.gd`, `tests/integration/save/save_snapshot_slots_test.gd`
- Test written: `tests/integration/save/save_snapshot_slots_test.gd` (5 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH (`godot --headless --path "E:/code/little-football-town" --script "res://tests/integration/save/save_snapshot_slots_test.gd"` returned command not found).
- Next: `/code-review src/autoload/save_manager.gd src/autoload/save_snapshot.gd tests/integration/save/save_snapshot_slots_test.gd` then `/story-done production/epics/save-and-load-system/story-001-save-snapshot-slots.md`

## Session Extract — /dev-story 2026-05-25
- Story: `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md` — Story 001: 建立 EconomyManager 权威边界与 Transaction 数据模型
- Files changed: `src/core/transaction.gd`, `src/core/economy_manager.gd`, `tests/unit/economy/economy_authority_transaction_model_test.gd`, `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md`
- Test written: `tests/unit/economy/economy_authority_transaction_model_test.gd` (4 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH (`godot --headless -s tests/unit/economy/economy_authority_transaction_model_test.gd` returned command not found).
- Next: `/code-review src/core/transaction.gd src/core/economy_manager.gd tests/unit/economy/economy_authority_transaction_model_test.gd` then `/story-done production/epics/economy-management-system/story-001-economy-authority-transaction-model.md`

## Session Extract — /dev-story 2026-05-25
- Story: `production/epics/time-and-season-progression-system/story-001-time-manager-state-contract.md` — Story 001: 实现 TimeManager 状态模型与 Autoload 契约
- Files changed: `src/autoload/time_manager.gd`, `tests/integration/time/time_manager_state_contract_test.gd`, `tests/integration/time/time_manager_state_contract_runner.gd`, `tests/integration/save/save_registration_snapshot_test.gd`, `production/epics/time-and-season-progression-system/story-001-time-manager-state-contract.md`
- Test written: `tests/integration/time/time_manager_state_contract_test.gd` (4 test functions) via `tests/integration/time/time_manager_state_contract_runner.gd`
- Blockers: None — headless verification passed (`TIME_MANAGER_STATE_CONTRACT_TEST_PASS`). Runner uses a placeholder `SaveManager` node to isolate this story from unrelated SaveManager parse noise.
- Next: `/story-done production/epics/time-and-season-progression-system/story-001-time-manager-state-contract.md`

## Session Extract — /dev-story 2026-05-26
- Story: `production/epics/time-and-season-progression-system/story-002-action-window-formula.md` — Story 002: 实现行动时间消耗与可用窗口公式
- Files changed: `src/autoload/time_manager.gd`, `tests/unit/time/action_window_formula_test.gd`, `production/epics/time-and-season-progression-system/story-002-action-window-formula.md`
- Test written: `tests/unit/time/action_window_formula_test.gd` (5 test functions)
- Blockers: None — headless verification passed (`ACTION_WINDOW_FORMULA_TEST_PASS`).
- Next: `/story-done production/epics/time-and-season-progression-system/story-002-action-window-formula.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE
- Story: `production/epics/time-and-season-progression-system/story-002-action-window-formula.md` — Story 002: 实现行动时间消耗与可用窗口公式
- Tech debt logged: None
- Next recommended: `production/epics/time-and-season-progression-system/story-003-match-trigger.md` — Implement match trigger threshold logic on top of the completed action-window authority

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/time-and-season-progression-system/story-001-time-manager-state-contract.md` — Story 001: 实现 TimeManager 状态模型与 Autoload 契约
- Tech debt logged: None
- Notes: Automated integration evidence passed through `tests/integration/time/time_manager_state_contract_runner.gd`; runner uses a placeholder `SaveManager` node so this verdict covers TimeManager contract behavior, not SaveManager script compilability.
- Next recommended: `production/epics/time-and-season-progression-system/story-002-action-window-formula.md` — Implement actionable window calculation on top of the completed TimeManager state contract

## Session Extract — /story-done 2026-05-25
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/balance-system/story-002-attribute-formula.md` — Story 002: 实现属性模型与有效属性公式
- Tech debt logged: None
- Next recommended: `production/epics/balance-system/story-005-positional-rating.md` — Implement position-weighted overall rating after attribute formula completion

## Session Extract — /dev-story 2026-05-25
- Story: `production/epics/balance-system/story-005-positional-rating.md` — Story 005: 实现位置综合评分公式
- Files changed: `src/config/balance_config.gd`, `tests/unit/balance/positional_rating_test.gd`, `production/epics/balance-system/story-005-positional-rating.md`
- Test written: `tests/unit/balance/positional_rating_test.gd` (4 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH (headless unit test run could not be executed in this session).
- Next: `/code-review src/config/balance_config.gd tests/unit/balance/positional_rating_test.gd` then `/story-done production/epics/balance-system/story-005-positional-rating.md`

## Session Extract — /story-done 2026-05-25
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md` — Story 001: 建立 EconomyManager 权威边界与 Transaction 数据模型
- Tech debt logged: None
- Next recommended: `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md` — Implement atomic validation and execution on top of the authority boundary

## Session Extract — /story-done 2026-05-25
- Verdict: COMPLETE
- Story: `production/epics/match-competition-system/story-001-match-state-flow.md` — Story 001: 实现比赛状态机与正式比赛入口边界
- Tech debt logged: None
- Next recommended: `production/epics/match-competition-system/story-005-halftime-adjustment.md` — Build explicit halftime adjustment on top of the completed eight-state match flow

## Session Extract — /story-done 2026-05-25
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/town-building-system/story-001-town-grid-facility-contract.md` — Story 001: 建立 Facility 数据模型与网格索引契约
- Tech debt logged: None
- Next recommended: `production/epics/town-building-system/story-002-facility-cost-time-formulas.md` — Implement construction and upgrade cost/time formulas after the core grid contract is complete

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/town-building-system/story-002-facility-cost-time-formulas.md` — Story 002: 实现设施建造/升级成本与工期公式
- Tech debt logged: None
- Next recommended: `production/epics/town-building-system/story-003-build-request-validation.md` — Implement build request validation on top of the completed cost/time formula layer

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/town-building-system/story-003-build-request-validation.md` — Story 003: 实现建造发起校验与 accredited 扣费入口
- Tech debt logged: None
- Next recommended: `production/epics/town-building-system/story-004-upgrade-completion-flow.md` — Implement upgrade and completion flow on top of the validated build request entry path

## Session Extract — /story-done 2026-05-25
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/balance-system/story-005-positional-rating.md` — Story 005: 实现位置综合评分公式
- Tech debt logged: None
- Next recommended: `production/epics/balance-system/story-006-win-probability.md` — Implement base win probability formula after positional overall rating is available

## Session Extract — /dev-story 2026-05-25
- Story: `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md` — Story 002: 实现 execute_transaction 原子执行与资源底线校验
- Files changed: `src/config/economy_config.gd`, `config/economy_config.tres`, `src/autoload/config_loader.gd`, `src/core/economy_manager.gd`, `tests/unit/economy/execute_transaction_atomic_validation_test.gd`
- Test written: `tests/unit/economy/execute_transaction_atomic_validation_test.gd` (4 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH (headless unit test run could not be executed in this session).
- Next: `/code-review src/config/economy_config.gd src/autoload/config_loader.gd src/core/economy_manager.gd tests/unit/economy/execute_transaction_atomic_validation_test.gd production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md` then `/story-done production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md`

## Session Extract — /story-done 2026-05-25
- Verdict: COMPLETE
- Story: `production/epics/match-competition-system/story-003-actual-win-probability.md` — Story 003: 实现实际胜率修正与战术/状态影响
- Tech debt logged: None
- Next recommended: `production/epics/match-competition-system/story-004-key-event-generation.md` — Implement categorized key event generation on top of the completed actual win probability layer

## Session Extract — /dev-story 2026-05-25
- Story: `production/epics/balance-system/story-006-win-probability.md` — Story 006: 实现基准胜率公式与边界
- Files changed: `production/epics/balance-system/story-006-win-probability.md`, `tests/unit/balance/win_probability_test.gd`
- Test written: `tests/unit/balance/win_probability_test.gd` (4 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH (headless unit test run could not be executed in this session).
- Next: `/code-review src/config/balance_config.gd tests/unit/balance/win_probability_test.gd production/epics/balance-system/story-006-win-probability.md` then `/story-done production/epics/balance-system/story-006-win-probability.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE
- Story: `production/epics/match-competition-system/story-004-key-event-generation.md` — Story 004: 实现关键事件产量与事件分类生成
- Tech debt logged: None
- Next recommended: `production/epics/match-competition-system/story-005-halftime-adjustment.md` — Implement halftime tactical changes and substitution limits on top of the completed event and state-flow layers

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/balance-system/story-006-win-probability.md` — Story 006: 实现基准胜率公式与边界
- Tech debt logged: None
- Next recommended: `production/epics/balance-system/story-009-balance-statistical-validation.md` — Validate shared balance formulas against KPI target bands after the base win probability anchor is complete

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/save-and-load-system/story-001-save-snapshot-slots.md` — Story 001: 建立 SaveSnapshot 与存档槽结构
- Tech debt logged: None
- Next recommended: `production/epics/save-and-load-system/story-002-save-registration-snapshot.md` — Implement required system registration and snapshot assembly on top of the completed slot/snapshot boundary

## Session Extract — /dev-story 2026-05-26
- Story: `production/epics/player-development-system/story-001-player-data-serialization-boundary.md` — Story 001: 实现 Player / PlayerRoster 权威数据模型与序列化边界
- Files changed: `src/core/player.gd`, `src/core/player_roster.gd`, `src/core/player_development.gd`, `tests/integration/player-dev/player_data_serialization_boundary_test.gd`
- Test written: `tests/integration/player-dev/player_data_serialization_boundary_test.gd` (3 test functions)
- Blockers: Local runtime verification not executed in this session; static review fixed SaveManager injection, missing SaveManager preload, and duplicate-deserialize expectation counts.
- Next: `/code-review src/core/player.gd src/core/player_roster.gd src/core/player_development.gd tests/integration/player-dev/player_data_serialization_boundary_test.gd` then `/story-done production/epics/player-development-system/story-001-player-data-serialization-boundary.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md` — Story 002: 实现 execute_transaction 原子执行与资源底线校验
- Tech debt logged: None
- Next recommended: `production/epics/economy-management-system/story-003-warning-threshold-cooldown-events.md` — Add economy warning thresholds and cooldown behavior on top of the validated transaction boundary

## Session Extract — /dev-story 2026-05-26
- Story: `production/epics/balance-system/story-007-kpi-formulas.md` — Story 007: 实现 KPI 与诊断公式
- Files changed: `src/config/balance_config.gd`, `tests/unit/balance/kpi_formula_test.gd`, `production/epics/balance-system/story-007-kpi-formulas.md`
- Test written: `tests/unit/balance/kpi_formula_test.gd` (5 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH (headless unit test run could not be executed in this session).
- Next: `/code-review src/config/balance_config.gd tests/unit/balance/kpi_formula_test.gd production/epics/balance-system/story-007-kpi-formulas.md` then `/story-done production/epics/balance-system/story-007-kpi-formulas.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE
- Story: `production/epics/match-competition-system/story-005-halftime-adjustment.md` — Story 005: 实现中场调整与下半场独立生效
- Tech debt logged: None
- Next recommended: `production/epics/match-competition-system/story-006-match-result-packet.md` — Implement result packet assembly on top of completed state flow, probability, event generation, and halftime plan layers

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE
- Story: `production/epics/save-and-load-system/story-002-save-registration-snapshot.md` — Story 002: 实现系统注册契约与快照组装
- Tech debt logged: None
- Next recommended: `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md` — Implement integrity hash and atomic save commit on top of the completed registration and snapshot assembly layer

## Session Extract — /dev-story 2026-05-26
- Story: `production/epics/player-development-system/story-002-training-efficiency-formula.md` — Story 002: 实现训练效率与状态修正公式
- Files changed: `src/core/player.gd`, `src/core/player_development.gd`, `src/core/player_roster.gd`, `tests/unit/player-dev/training_efficiency_formula_test.gd`, `production/epics/player-development-system/story-002-training-efficiency-formula.md`
- Test written: `tests/unit/player-dev/training_efficiency_formula_test.gd` (4 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH; static review additionally fixed review_flags roster persistence and guarded restored-player assertions.
- Next: `/code-review src/core/player.gd src/core/player_development.gd src/core/player_roster.gd tests/unit/player-dev/training_efficiency_formula_test.gd` then `/story-done production/epics/player-development-system/story-002-training-efficiency-formula.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/player-development-system/story-002-training-efficiency-formula.md` — Story 002: 实现训练效率与状态修正公式
- Tech debt logged: None
- Notes: Static review passed, but automated local runtime evidence is still pending because `godot` is not available in PATH in this session.
- Next recommended: `production/epics/player-development-system/story-003-training-gain-cap.md` — Implement capped attribute gain output on top of the completed training efficiency layer

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/economy-management-system/story-003-warning-threshold-cooldown-events.md` — Story 003: 实现资源预警阈值、debt 预警与冷却机制
- Tech debt logged: None
- Notes: Local Godot headless verification passed via `tests/integration/economy/warning_threshold_cooldown_events_test.gd`; code review noted one non-blocking low-risk edge around cooldown being recorded before EventBus availability is confirmed.
- Next recommended: `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md` — Implement read-only budget preview and affordability queries on top of the completed transaction validation and warning layers

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md` — Story 004: 实现预算预览与可负担性查询合同
- Tech debt logged: None
- Notes: Local Godot headless verification passed via `tests/integration/economy/budget_preview_affordability_query_test.gd`; preview and real facility-cost execution now share the same debt-capable funds policy, and integration evidence confirms preview does not mutate balances, advance `tx_id`, append to the log, or emit warning events.
- Next recommended: `production/epics/economy-management-system/story-005-daily-recovery-maintenance-settlement.md` — Implement daily AP recovery, rest recovery, and maintenance settlement on top of the completed preview/query layer

## Session Extract — /dev-story 2026-05-26
- Story: `production/epics/time-and-season-progression-system/story-003-match-trigger.md` — Story 003: 实现比赛节点触发与 Match Trigger 状态转换
- Files changed: `src/autoload/time_manager.gd`, `tests/unit/time/match_trigger_test.gd`, `production/epics/time-and-season-progression-system/story-003-match-trigger.md`
- Test written: `tests/unit/time/match_trigger_test.gd` (5 test functions)
- Blockers: None — headless verification passed (`MATCH_TRIGGER_TEST_PASS`).
- Next: `/story-done production/epics/time-and-season-progression-system/story-003-match-trigger.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE
- Story: `production/epics/time-and-season-progression-system/story-003-match-trigger.md` — Story 003: 实现比赛节点触发与 Match Trigger 状态转换
- Tech debt logged: None
- Next recommended: `production/epics/time-and-season-progression-system/story-004-stage-settlement-trigger.md` — Implement stage settlement trigger after the match-trigger node transition is complete

## Session Extract — /code-review 2026-05-26
- Story: `production/epics/save-and-load-system/story-002-save-registration-snapshot.md` — Story 002: 实现系统注册契约与快照组装
- Files changed after review: `src/autoload/save_manager.gd`, `tests/integration/save/save_registration_snapshot_test.gd`
- Verification: `tests/integration/save/save_registration_snapshot_runner.gd` passed (`SAVE_REGISTRATION_SNAPSHOT_TEST_PASS`)
- Review outcome: Minimal fix pass resolved targeted issues; code review marked complete.

## Session Extract — /dev-story 2026-05-28
- Story: `production/epics/save-and-load-system/story-004-autosave-triggers.md` — Story 004: 接入自动保存触发与延后保存队列
- Files changed: `src/autoload/save_manager.gd`, `tests/integration/save/autosave_triggers_test.gd`, `tests/integration/save/autosave_triggers_runner.gd`, `production/epics/save-and-load-system/story-004-autosave-triggers.md`
- Test written: `tests/integration/save/autosave_triggers_test.gd` (4 test functions) via `tests/integration/save/autosave_triggers_runner.gd`
- Blockers: None — headless verification passed (`AUTOSAVE_TRIGGERS_TEST_PASS`).
- Next: `/code-review src/autoload/save_manager.gd tests/integration/save/autosave_triggers_test.gd tests/integration/save/autosave_triggers_runner.gd` then `/story-done production/epics/save-and-load-system/story-004-autosave-triggers.md`

## Session Extract — /dev-story 2026-05-28
- Story: `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md` — Story 005: 实现原子提交、完整性哈希与损坏检测
- Files changed: `src/autoload/save_manager.gd`, `tests/integration/save/save_integrity_atomic_commit_test.gd`, `tests/integration/save/save_integrity_atomic_commit_runner.gd`, `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md`
- Test written: `tests/integration/save/save_integrity_atomic_commit_test.gd` (4 test functions) via `tests/integration/save/save_integrity_atomic_commit_runner.gd`
- Blockers: None — headless verification passed (`SAVE_INTEGRITY_ATOMIC_COMMIT_TEST_PASS`).
- Next: `/code-review src/autoload/save_manager.gd tests/integration/save/save_integrity_atomic_commit_test.gd tests/integration/save/save_integrity_atomic_commit_runner.gd` then `/story-done production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md`

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/balance-system/story-009-balance-statistical-validation.md` — Story 009: 验证数值公式可复核性与随机统计边界
- Tech debt logged: None
- Notes: Local Godot headless verification passed via `tests/integration/balance/balance_statistical_validation_test.gd`. Minimal upstream fixes unblocked runtime verification in `src/core/player.gd`, `src/core/player_roster.gd`, and `src/core/player_development.gd`; the balance integration test now uses the project-standard `SceneTree` headless entrypoint.
- Next recommended: Downstream balance playtest evidence or simulation validation stories unlocked by the completed statistical validation baseline

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE
- Story: `production/epics/balance-system/story-004-resource-settlement.md` — Story 004: 实现资源结算共享公式
- Tech debt logged: None
- Notes: Local Godot headless verification passed via `tests/unit/balance/resource_settlement_test.gd`. Shared resource settlement now lives in `BalanceConfig` with config-backed resource buffer validation and explicit participation rules for funds, research, and action points.
- Next recommended: `production/epics/balance-system/story-003-attribute-growth.md` — Implement shared growth curve and potential-bound normalization on top of the completed balance formula surface

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/balance-system/story-007-kpi-formulas.md` — Story 007: 实现 KPI 与诊断公式
- Tech debt logged: None
- Next recommended: `production/epics/balance-system/story-009-balance-statistical-validation.md` — Validate shared balance formulas against KPI target bands after the diagnostic formula layer is complete

## Session Extract — /dev-story 2026-05-26
- Story: `production/epics/player-development-system/story-003-training-gain-cap.md` — Story 003: 实现训练成长结算与潜力上限裁剪
- Files changed: `src/core/player_development.gd`, `tests/unit/player-dev/training_gain_cap_test.gd`, `production/epics/player-development-system/story-003-training-gain-cap.md`
- Test written: `tests/unit/player-dev/training_gain_cap_test.gd` (3 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH; static review simplified attribute mapping initialization and expanded facility multiplier coverage to baseline/midpoint/upper-bound/out-of-range samples.
- Next: `/code-review src/core/player_development.gd tests/unit/player-dev/training_gain_cap_test.gd` then `/story-done production/epics/player-development-system/story-003-training-gain-cap.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/player-development-system/story-003-training-gain-cap.md` — Story 003: 实现训练成长结算与潜力上限裁剪
- Tech debt logged: None
- Notes: Static review passed, but automated local runtime evidence is still pending because `godot` is not available in PATH in this session.
- Next recommended: `production/epics/player-development-system/story-005-training-roi.md` — Implement ROI comparison on top of the completed training gain and capped-growth layer

## Session Extract — /dev-story 2026-05-26
- Story: `production/epics/player-development-system/story-005-training-roi.md` — Story 005: 实现训练项目匹配、副属性成长与 ROI 计算样本
- Files changed: `src/core/player_development.gd`, `tests/unit/player-dev/training_roi_test.gd`, `production/epics/player-development-system/story-005-training-roi.md`
- Test written: `tests/unit/player-dev/training_roi_test.gd` (4 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH.
- Next: `/code-review src/core/player_development.gd tests/unit/player-dev/training_roi_test.gd` then `/story-done production/epics/player-development-system/story-005-training-roi.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/player-development-system/story-005-training-roi.md` — Story 005: 实现训练项目匹配、副属性成长与 ROI 计算样本
- Tech debt logged: None
- Notes: Static review passed, but automated local runtime evidence is still pending because `godot` is not available in PATH in this session.
- Next recommended: `production/epics/player-development-system/story-009-player-development-regression.md` — Add regression coverage now that the ROI dependency chain is complete

## Session Extract — /dev-story 2026-05-26
- Story: `production/epics/time-and-season-progression-system/story-004-stage-settlement-trigger.md` — Story 004: 实现阶段结算与赛后连续触发
- Files changed: `src/autoload/time_manager.gd`, `tests/unit/time/stage_settlement_trigger_test.gd`, `production/epics/time-and-season-progression-system/story-004-stage-settlement-trigger.md`
- Test written: `tests/unit/time/stage_settlement_trigger_test.gd` (5 test functions)
- Blockers: None — headless verification passed (`STAGE_SETTLEMENT_TRIGGER_TEST_PASS`).
- Next: `/story-done production/epics/time-and-season-progression-system/story-004-stage-settlement-trigger.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE
- Story: `production/epics/time-and-season-progression-system/story-004-stage-settlement-trigger.md` — Story 004: 实现阶段结算与赛后连续触发
- Tech debt logged: None
- Next recommended: `production/epics/time-and-season-progression-system/story-005-season-progress-flow.md` — Implement season progress flow after stage settlement chaining is complete

## Session Extract — /dev-story 2026-05-26
- Story: `production/epics/player-development-system/story-004-player-tier-band.md` — Story 004: 实现球员层级、潜力区间与训练效率差异
- Files changed: `src/core/player.gd`, `src/core/player_roster.gd`, `src/core/player_development.gd`, `tests/unit/player-dev/player_tier_band_test.gd`, `production/epics/player-development-system/story-004-player-tier-band.md`
- Test written: `tests/unit/player-dev/player_tier_band_test.gd` (4 test functions)
- Blockers: Local runtime verification blocked because `godot` is not available in PATH; implementation adds explicit special-source persistence, tier-band validation, and cap-clipping comparison coverage.
- Next: `/code-review src/core/player.gd src/core/player_roster.gd src/core/player_development.gd tests/unit/player-dev/player_tier_band_test.gd` then `/story-done production/epics/player-development-system/story-004-player-tier-band.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/player-development-system/story-004-player-tier-band.md` — Story 004: 实现球员层级、潜力区间与训练效率差异
- Tech debt logged: None
- Notes: Static review passed and AC-3 evidence was strengthened to assert realized attribute growth, but automated local runtime evidence is still pending because `godot` is not available in PATH in this session.
- Next recommended: `production/epics/player-development-system/story-005-training-roi.md` — Re-validate Story 005 now that the tier-band dependency is complete

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE
- Story: `production/epics/match-competition-system/story-006-match-result-packet.md` — Story 006: 实现 MatchResultPacket、胜负原因与赛后标签
- Tech debt logged: None
- Next recommended: `production/epics/match-competition-system/story-008-match-restore-dedup.md` — Implement restore deduplication on top of the completed result packet and event emission contract

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE
- Story: `production/epics/match-competition-system/story-007-match-rng-determinism.md` — Story 007: 实现 seeded RNG 决定性与重复运行一致性
- Tech debt logged: None
- Next recommended: `production/epics/match-competition-system/story-008-match-restore-dedup.md` — Implement restore deduplication now that deterministic replay coverage is complete

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE
- Story: `production/epics/match-competition-system/story-008-match-restore-dedup.md` — Story 008: 实现存档降级恢复与重复触发防重赛
- Tech debt logged: None
- Next recommended: `production/epics/match-competition-system/story-009-match-loop-regression.md` — Add regression coverage now that restore downgrade and confirmed-result dedup are in place

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE
- Story: `production/epics/match-competition-system/story-009-match-loop-regression.md` — Story 009: 实现完整比赛闭环回归样本与性能验证
- Tech debt logged: None
- Next recommended: Downstream work — Economy post-match settlement, League standings integration, Match Performance UI implementation

## Session Extract — /dev-story 2026-05-27
- Story: `production/epics/economy-management-system/story-006-staged-settlement-formulas.md` — Story 006: 实现赛后/阶段/赛季结算公式与 floor 舍入
- Files changed: `src/config/economy_config.gd`, `src/core/economy_manager.gd`, `tests/integration/economy/staged_settlement_formulas_test.gd`, `production/epics/economy-management-system/story-006-staged-settlement-formulas.md`
- Test written: `tests/integration/economy/staged_settlement_formulas_test.gd` (3 test functions)
- Blockers: None — headless verification passed (`STAGED_SETTLEMENT_FORMULAS_TEST_PASS`), and economy regression checks passed for daily settlement plus accredited entry points.
- Next: `/code-review src/core/economy_manager.gd tests/integration/economy/staged_settlement_formulas_test.gd production/epics/economy-management-system/story-006-staged-settlement-formulas.md` then `/story-done production/epics/economy-management-system/story-006-staged-settlement-formulas.md`

## Session Extract — /dev-story 2026-05-26
- Story: `production/epics/time-and-season-progression-system/story-005-season-progress-flow.md` — Story 005: 实现赛季进度、赛季结算与休赛期流转
- Files changed: `src/autoload/time_manager.gd`, `tests/unit/time/season_progress_flow_test.gd`, `production/epics/time-and-season-progression-system/story-005-season-progress-flow.md`
- Test written: `tests/unit/time/season_progress_flow_test.gd` (5 test functions)
- Blockers: None — headless verification passed (`SEASON_PROGRESS_FLOW_TEST_PASS`).
- Next: `/story-done production/epics/time-and-season-progression-system/story-005-season-progress-flow.md`

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE
- Story: `production/epics/time-and-season-progression-system/story-005-season-progress-flow.md` — Story 005: 实现赛季进度、赛季结算与休赛期流转
- Tech debt logged: None
- Next recommended: `production/epics/time-and-season-progression-system/story-006-key-node-priority.md` — Implement deterministic key-node priority after match, stage, and season boundary flows are all in place

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/town-building-system/story-004-upgrade-completion-flow.md` — Story 004: 实现升级流转与 time_phase_changed 完工结算
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/town/upgrade_completion_flow_test.gd`; code review concluded with `APPROVED WITH SUGGESTIONS` and no remaining blocking issues.
- Next recommended: `production/epics/town-building-system/story-005-demolish-grid-release.md` — Implement controlled demolition flow on top of the completed upgrade/completion boundary

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/economy-management-system/story-005-daily-recovery-maintenance-settlement.md` — Story 005: 实现每日 AP 恢复、休息恢复与维护费结算
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/economy/daily_recovery_maintenance_settlement_test.gd`; code review concluded with `APPROVED WITH SUGGESTIONS`. Daily settlement now includes TownBuilding AP bonus, rest recovery, maintenance deduction, and balance-change event emission through the transaction boundary.
- Next recommended: `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md` — Add deterministic settlement-order and concurrency regression coverage on top of the completed daily settlement path

## Session Extract — /story-done 2026-05-26
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/town-building-system/story-005-demolish-grid-release.md` — Story 005: 实现拆除限制、空地释放与邻接重算触发
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/town/demolish_grid_release_test.gd`; code review concluded with `APPROVED WITH SUGGESTIONS`. Remaining review notes were non-blocking suggestions around extra edge-case coverage and event-contract clarity.
- Next recommended: `production/epics/town-building-system/story-007-stadium-adjacency-formulas.md` — Implement explicit stadium adjacency formula outputs on top of the completed demolition and adjacency invalidation boundary

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE
- Story: `production/epics/town-building-system/story-007-stadium-adjacency-formulas.md` — Story 007: 实现球场与三组邻接加成公式
- Tech debt logged: None
- Notes: Headless logic evidence passed via `tests/unit/town/stadium_adjacency_formula_test.gd`; code review and follow-up QA checks closed after adding story caps, undeclared-pair coverage, upgrading continuity, and state-boundary regression assertions.
- Next recommended: `production/epics/town-building-system/story-008-downstream-query-maintenance.md` — Wire the completed formula queries into downstream maintenance and consumer-facing accessors

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE
- Story: `production/epics/town-building-system/story-008-downstream-query-maintenance.md` — Story 008: 实现下游只读查询面与维护费汇总
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/town/downstream_query_maintenance_test.gd`; maintenance aggregation now counts only Active facilities, and repeated downstream query calls were verified as read-only across normal, upgrading, and post-demolition boundaries.
- Next recommended: `production/epics/town-building-system/story-009-serialization-restore-regression.md` — Add serialization and restore regression coverage on top of the completed downstream query surface

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE
- Story: `production/epics/town-building-system/story-009-serialization-restore-regression.md` — Story 009: 实现建设状态序列化与读档恢复回归
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/town/serialization_restore_regression_test.gd`; TownBuilding now registers its save contract with SaveManager, and restore regression coverage verifies exact state recovery, SaveManager-driven deserialization, and single-completion behavior across D=1, D>1, and multi-project boundaries.
- Next recommended: None identified

## Session Extract — /code-review 2026-05-27
- Story: `production/epics/economy-management-system/story-006-staged-settlement-formulas.md` — Story 006: 实现赛后/阶段/赛季结算公式与 floor 舍入
- Files changed after review: `src/config/economy_config.gd`, `src/core/economy_manager.gd`, `tests/integration/economy/staged_settlement_formulas_test.gd`, `tests/integration/economy/accredited_entry_points_test.gd`, `tests/integration/economy/daily_recovery_maintenance_settlement_test.gd`, `production/epics/economy-management-system/story-006-staged-settlement-formulas.md`
- Verification: `tests/integration/economy/staged_settlement_formulas_test.gd`, `tests/integration/economy/accredited_entry_points_test.gd`, and `tests/integration/economy/daily_recovery_maintenance_settlement_test.gd` passed
- Review outcome: APPROVED WITH SUGGESTIONS — prior blockers resolved; remaining notes are non-blocking only.
- Next: `/story-done production/epics/economy-management-system/story-006-staged-settlement-formulas.md`

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/economy-management-system/story-006-staged-settlement-formulas.md` — Story 006: 实现赛后/阶段/赛季结算公式与 floor 舍入
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/economy/staged_settlement_formulas_test.gd`, with supporting regression passes in `tests/integration/economy/accredited_entry_points_test.gd` and `tests/integration/economy/daily_recovery_maintenance_settlement_test.gd`; code review concluded with `APPROVED WITH SUGGESTIONS`, and the prior blockers were fully resolved.
- Next recommended: `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md` — Add deterministic settlement-order and concurrency regression coverage on top of the completed daily and staged settlement paths

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE
- Story: `production/epics/balance-system/story-003-attribute-growth.md` — Story 003: 实现属性成长公式与潜力边界
- Tech debt logged: None
- Notes: Local Godot headless verification passed via `tests/unit/balance/attribute_growth_test.gd`; shared attribute growth now lives in `BalanceConfig` with config-backed `decay_factor` defaults, `potential_cap_span` validation, and normalized potential-bound handling.
- Next recommended: `production/epics/balance-system/story-008-downstream-formula-consistency-scan.md` — Scan downstream systems for duplicated balance formulas now that the shared growth and settlement surface is in place

## Session Extract — /dev-story 2026-05-27
- Story: `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md` — Story 009: 实现结算顺序、并发请求拒绝与经济回归验证
- Files changed: `tests/integration/economy/settlement_order_concurrency_regression_test.gd`, `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`
- Test written: `tests/integration/economy/settlement_order_concurrency_regression_test.gd` (3 test functions)
- Blockers: None — headless verification passed (`SETTLEMENT_ORDER_CONCURRENCY_REGRESSION_TEST_PASS`).
- Next: `/story-done production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE
- Story: `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md` — Story 009: 实现结算顺序、并发请求拒绝与经济回归验证
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/economy/settlement_order_concurrency_regression_test.gd`; regression coverage now proves fixed settlement ordering, same-frame cost rejection without dirty state, and representative season ledger reconciliation including RP cap overflow handling.
- Next recommended: None identified

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE
- Story: `production/epics/balance-system/story-008-balance-consistency-scan.md` — Story 008: 建立数值生命周期元数据与跨系统一致性扫描
- Tech debt logged: None
- Notes: Local Godot headless verification passed via `tests/integration/balance/balance_consistency_test.gd`; the completed scope removed the confirmed duplicate growth formula from `PlayerDevelopment` and verified downstream/shared output consistency for the same inputs.
- Next recommended: Downstream player-development validation or broader downstream readiness work

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/economy-management-system/story-007-accredited-entry-points.md` — Story 007: 实现认证入口与 caller 约束
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/economy/accredited_entry_points_test.gd`; code review concluded with `APPROVED WITH SUGGESTIONS`. EconomyManager now requires an internal authorization token for business `source_system` writes, while preserving `test` / `test_suite` direct-call coverage and keeping committed audit metadata clean.
- Next recommended: `production/epics/economy-management-system/story-008-transaction-log-save-contract.md` — Implement transaction log save/load contract now that accredited entry points and caller constraints are complete

## Session Extract — /code-review 2026-05-27
- Story: `production/epics/match-competition-system/story-008-match-restore-dedup.md` — Story 008: 实现存档降级恢复与重复触发防重赛
- Verification: `tests/integration/match/match_restore_dedup_test.gd` maps 3/3 acceptance criteria and the implementation in `src/core/match_simulation.gd` satisfies restore degradation, recoverable load, and confirmed-result dedup behavior.
- Review outcome: APPROVED WITH SUGGESTIONS — no blocking issues remain; only an advisory note about making the retrigger event-contract assertion more explicit if that contract is later frozen.
- Next: `production/epics/match-competition-system/story-009-match-loop-regression.md`

## Session Extract — /code-review 2026-05-27
- Story: `production/epics/match-competition-system/story-009-match-loop-regression.md` — Story 009: 实现完整比赛闭环回归样本与性能验证
- Verification: `tests/integration/match/match_loop_regression_test.gd` maps 3/3 acceptance criteria and the implementation in `src/core/match_simulation.gd` satisfies full-loop closure, downstream handoff, and <100ms draw/performance requirements.
- Review outcome: APPROVED WITH SUGGESTIONS — no blocking issues remain; only advisory notes around repeated-run performance evidence and explicit event-contract assertions.
- Next: `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`

## Session Extract — /code-review 2026-05-27
- Story: `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md` — Story 009: 实现结算顺序、并发请求拒绝与经济回归验证
- Verification: `tests/integration/economy/settlement_order_concurrency_regression_test.gd` maps 3/3 acceptance criteria and the implementation in `src/core/economy_manager.gd` satisfies fixed ordering, same-frame rejection without dirty state, representative ledger reconciliation, and bounded transaction-log behavior.
- Review outcome: APPROVED WITH SUGGESTIONS — no blocking issues remain; only advisory notes around future queue-level same-frame signal coverage and explicit batch cooldown assertions if the event scheduler grows more complex.
- Next: None identified

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/economy-management-system/story-008-transaction-log-save-contract.md` — Story 008: 实现交易流水上限与存档序列化契约
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/economy/transaction_log_save_contract_test.gd`; bounded 200-entry retention, SaveManager registration, centralized economy-block restore, partial old-save payload behavior, and explicit cleanup verification all passed.
- Next recommended: `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md` — Add deterministic settlement-order and concurrency regression coverage on top of the completed bounded-log and save contract path

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/save-and-load-system/story-003-stable-node-save-gate.md` — Story 003: 实现稳定节点判定与瞬时节点保存拦截
- Tech debt logged: None
- Notes: Local headless verification passed via `tests/unit/save/stable_node_save_gate_test.gd`; SaveManager now blocks unstable runtime nodes before snapshot assembly, and code review concluded with `APPROVED WITH SUGGESTIONS`.
- Next recommended: `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md` — Resume save integrity hash and atomic commit work now that the stable-node save gate dependency is complete

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/economy-management-system/story-008-transaction-log-save-contract.md` — Story 008: 实现交易流水上限与存档序列化契约
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/economy/transaction_log_save_contract_test.gd`; code review passed after tightening the test-only authorization seam in `src/core/economy_manager.gd`, and targeted economy regressions confirmed the bounded log, save/load contract, accredited entry points, and warning flow remained stable.
- Next recommended: `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md` — Add deterministic settlement-order and concurrency regression coverage on top of the completed save contract and settlement path

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/town-building-system/story-006-training-medical-youth-formulas.md` — Story 006: 实现训练/医疗/青训基础公式接口
- Tech debt logged: None
- Notes: Story 006 专属逻辑证据已补齐至 `tests/unit/town/training_medical_youth_formula_test.gd`，并在本机 Godot 4.6.2 headless 下通过（`TRAINING_MEDICAL_YOUTH_FORMULA_TEST_PASS`）。`TownBuilding` 中对应基础公式实现已存在，本次工作主要是补齐独立 story evidence 而非新增公式逻辑。运行末尾仍有非阻塞资源清理 warning，但未影响通过判定。
- Next recommended: 如需更干净的测试输出，可后续单独清理该测试的退出资源 warning；否则 Town Building epic 当前无明显未闭环故事

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/economy-management-system/story-007-accredited-entry-points.md` — Story 007: 实现认证入口与 caller 约束
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/economy/accredited_entry_points_test.gd`; the final implementation keeps business writes behind an internal authorization-token seam, adds `accredit_facility_construction_cost()` for stricter build-only insufficient-funds rejection, preserves the debt-capable upgrade facility-cost path, and passed supporting regressions in `tests/integration/economy/budget_preview_affordability_query_test.gd`, `tests/integration/town/build_request_validation_test.gd`, and `tests/integration/town/upgrade_completion_flow_test.gd`.
- Next recommended: `production/epics/player-development-system/story-006-training-atomic-integration.md` — Implement the training atomic integration path now that the accredited economy entry surface is complete

## Session Extract — /dev-story 2026-05-28
- Story: `production/epics/player-development-system/story-006-training-atomic-integration.md` — Story 006: 实现训练原子性与 Economy/Time 集成
- Files changed: `src/core/player_development.gd`, `tests/integration/player-dev/training_atomic_integration_test.gd`, `production/epics/player-development-system/story-006-training-atomic-integration.md`, `production/sprint-status.yaml`
- Test written: `tests/integration/player-dev/training_atomic_integration_test.gd` (3 test functions)
- Blockers: None — local runtime verification not executed in this session.
- Next: `/code-review src/core/player_development.gd tests/integration/player-dev/training_atomic_integration_test.gd` then `/story-done production/epics/player-development-system/story-006-training-atomic-integration.md`

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/time-and-season-progression-system/story-006-key-node-priority.md` — Story 006: 实现关键节点优先级与同位置确定性结算
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/time/key_node_priority_test.gd`; `src/autoload/time_manager.gd` now tracks resolved key nodes per stable state, uses an explicit post-match settlement transition instead of match-in-progress toggling, and preserves deterministic same-position key-node ordering without replay on repeated evaluation.
- Next recommended: `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md` — Wire the now-stable time-domain resolution order into EventBus payload and downstream dispatch integration

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md` — Story 007: 实现时间事件发布与 EventBus 优先级集成
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/time/time_eventbus_integration_test.gd`; `src/autoload/event_bus.gd` now supports prioritized batch dispatch for `time_*` before downstream domain events, and `src/autoload/time_manager.gd` now queues stable-state time payloads with the required serializable fields before flush so subscribers read committed TimeManager state.
- Next recommended: `production/epics/time-and-season-progression-system/story-008-time-restore-boundary.md` — Validate save/restore boundary behavior now that stable time event ordering and state exposure are in place

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/time-and-season-progression-system/story-008-time-restore-boundary.md` — Story 008: 实现读档恢复节点与下游推进边界
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/time/time_restore_boundary_test.gd`; `src/autoload/time_manager.gd` now restores through a controlled stable-node boundary, normalizes half-complete key-node snapshots to verified stable states, and preserves post-restore progression without replaying completed nodes or auto-advancing beyond the committed restore point.
- Next recommended: `production/epics/time-and-season-progression-system/story-009-time-status-regression.md` — Build the final time-state display and regression sample coverage on top of the completed state, event, and restore boundaries

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/player-development-system/story-006-training-atomic-integration.md` — Story 006: 实现训练原子性与 Economy/Time 集成
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/player-dev/training_atomic_integration_test.gd` using `tests/integration/player-dev/training_atomic_integration_test.tscn`; `src/core/player_development.gd` now enforces validate→deduct→grow→apply→emit, routes costs only through `EconomyManager.accredit_training_cost()`, buffers economy/time events until commit, and rolls back funds/AP/time/attribute/history/session state on post-deduct failure. Supporting fixes also added EventBus override seams in `src/autoload/time_manager.gd` and resolved Godot 4.6 nested-typed-collection parse blockers in `src/autoload/time_manager.gd` and `src/autoload/event_bus.gd`. Test output still ends with non-blocking resource cleanup warnings, but the story-specific integration evidence passed (`TRAINING_ATOMIC_INTEGRATION_TEST_PASS`).
- Next recommended: `production/epics/player-development-system/story-008-player-state-boundary.md` — Validate downstream post-match player state consumption now that the authoritative training atomic boundary is complete

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/player-development-system/story-008-player-state-boundary.md` — Story 008: 实现赛后状态消费与下游写保护边界
- Tech debt logged: Independent regression issue remains in `tests/integration/player-dev/player_data_serialization_boundary_test.gd` typed-dictionary save-manager call; not part of story-008 acceptance but blocks a fully clean related regression sweep.
- Notes: Headless integration evidence passed via `tests/integration/player-dev/player_state_boundary_test.gd` using `tests/integration/player-dev/player_state_boundary_test.tscn`; `src/core/player_development.gd` now applies post-match condition/morale only through a formal boundary, rejects root-invalid and out-of-range payloads, flags stale/conflicting updates instead of silently overwriting state, and no longer exposes a direct mutable player read path through `PlayerDevelopment`. Supporting regression `tests/integration/player-dev/training_atomic_integration_test.tscn` remained passing (`TRAINING_ATOMIC_INTEGRATION_TEST_PASS`).
- Next recommended: `production/epics/player-development-system/story-007-player-milestone-history.md` — Build milestone emission, recent-growth history summary, and season-end age advancement on top of the now-completed training and state-boundary flows

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/player-development-system/story-007-player-milestone-history.md` — Story 007: 实现成长里程碑、训练历史与赛季年龄推进
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/player-dev/player_milestone_history_test.gd` using `tests/integration/player-dev/player_milestone_history_test.tscn`; `src/core/player_development.gd` now emits distinct attribute/training-session milestone events after legal training settlement, records recent-growth summary data from authoritative history entries, and advances player age exactly once per `time_season_ended` season number using serialized idempotence state. Supporting config/serialization updates landed in `src/config/balance_config.gd`, `config/balance_config.tres`, `src/core/player.gd`, and `src/core/player_roster.gd`. Verification also required a non-story blocker fix in `src/autoload/save_manager.gd` to replace a Godot-unsupported nested typed collection signature so the test environment could boot cleanly. Test output still ends with non-blocking resource cleanup warnings, but the story-specific integration evidence passed (`PLAYER_MILESTONE_HISTORY_TEST_PASS`).
- Next recommended: `production/epics/player-development-system/story-009-player-development-regression.md` — Build the final persistence and long-loop regression sample on top of the now-complete training, state-boundary, and milestone/history flow

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/player-development-system/story-009-player-development-regression.md` — Story 009: 实现培养闭环回归样本与持久化一致性验证
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/player-dev/player_development_regression_test.gd` using `tests/integration/player-dev/player_development_regression_test.tscn`; the regression sample now verifies a full MVP training loop with save/load consistency, compares focused/ordinary-priority/star-priority routes under matched budgets while allowing explicit `tuning_failure` classification, and confirms the no-facility training result matches the hand-calculated formula. Test-only fixes tightened SaveManager snapshot stubs and live time serialization so the regression path measures the authoritative state actually committed to save. Test output still ends with non-blocking resource cleanup warnings, but the story-specific integration evidence passed (`PLAYER_DEVELOPMENT_REGRESSION_TEST_PASS`).
- Next recommended: `production/epics/player-development-system/story-001-player-data-serialization-boundary.md` — Reconcile the remaining Ready story against the now-implemented player save boundary and decide whether to close it with evidence sync or finish any missing contract work

## Session Extract — /dev-story 2026-05-28
- Story: `production/epics/save-and-load-system/story-006-save-migration.md` — Story 006: 实现版本兼容判定与 additive-forward 迁移
- Files changed: `src/autoload/save_manager.gd`, `tests/integration/save/save_migration_test.gd`, `tests/integration/save/save_migration_runner.gd`, `production/epics/save-and-load-system/story-006-save-migration.md`
- Test written: `tests/integration/save/save_migration_test.gd` (4 test functions) via `tests/integration/save/save_migration_runner.gd`
- Blockers: None — headless verification passed (`SAVE_MIGRATION_TEST_PASS`).
- Next: `/code-review src/autoload/save_manager.gd tests/integration/save/save_migration_test.gd tests/integration/save/save_migration_runner.gd` then `/story-done production/epics/save-and-load-system/story-006-save-migration.md`

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/save-and-load-system/story-006-save-migration.md` — Story 006: 实现版本兼容判定与 additive-forward 迁移
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/save/save_migration_test.gd`; `src/autoload/save_manager.gd` now exposes schema-version compatibility checks through `migrate_snapshot_if_needed()`, performs additive-forward v0→v1 match-state field hydration without deleting persisted fields, recomputes integrity after migration, and rejects newer-version or structurally incompatible snapshots before restore. Verification runs through `tests/integration/save/save_migration_runner.gd` and passed with `SAVE_MIGRATION_TEST_PASS`.
- Next recommended: `production/epics/save-and-load-system/story-007-load-restore-order.md` — Implement ordered restore application now that migration compatibility and pre-restore validation are in place

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/time-and-season-progression-system/story-009-time-status-regression.md` — Story 009: 实现时间状态展示字段与节奏回归样本
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/time/time_status_regression_test.gd`; `src/autoload/time_manager.gd` now exposes aligned display-facing pull fields through `get_state()` and the regression sample covers the 9-state display model, non-negative next-key-node remaining time, HUD/state consistency, MVP loop checkpoints, and tuning target band validation (`TIME_STATUS_REGRESSION_TEST_PASS`).
- Next recommended: None — waiting for user to choose the next story

## Session Extract — story-001 verification sync 2026-05-28
- Story: `production/epics/player-development-system/story-001-player-data-serialization-boundary.md` — Story 001: 实现 Player / PlayerRoster 权威数据模型与序列化边界
- Files changed: `tests/integration/player-dev/player_data_serialization_boundary_test.gd`, `production/epics/player-development-system/story-001-player-data-serialization-boundary.md`, `production/epics/player-development-system/EPIC.md`
- Verification: Godot 4.6.2 headless evidence passed via `tests/integration/player-dev/player_data_serialization_boundary_test.tscn` with `PLAYER_DATA_SERIALIZATION_BOUNDARY_TEST_PASS`
- Notes: Refreshed the integration test to match current SaveManager typed-dictionary and snapshot-contract requirements, corrected the duplicate-deserialize assertions to reflect the saved fixture contents, and confirmed the authoritative player serialization boundary excludes derived values while preserving growth state across repeated restore.
- Next: `/code-review src/core/player.gd src/core/player_roster.gd src/core/player_development.gd tests/integration/player-dev/player_data_serialization_boundary_test.gd` then `/story-done production/epics/player-development-system/story-001-player-data-serialization-boundary.md`

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/player-development-system/story-001-player-data-serialization-boundary.md` — Story 001: 实现 Player / PlayerRoster 权威数据模型与序列化边界
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/player-dev/player_data_serialization_boundary_test.gd`; the strengthened boundary suite now verifies authoritative exact-key serialization, empty `training_history`/`milestones` persistence, multi-player restore stability by `id` even when snapshot order changes, and safe ignore semantics for legacy derived fields such as `effective` and `positional_overall_rating`. Player authority remains owned by `src/core/player.gd`, `src/core/player_roster.gd`, and `src/core/player_development.gd` under the SaveManager registration boundary.
- Next recommended: `production/epics/player-development-system/story-002-training-efficiency-formula.md` — Runtime evidence for story-002 was previously blocked by missing Godot PATH, so the next cleanup candidate is to re-verify or re-close adjacent early player-development stories under the now-working local Godot path

## Session Extract — story-002 runtime verification 2026-05-28
- Story: `production/epics/player-development-system/story-002-training-efficiency-formula.md` — Story 002: 实现训练效率与状态修正公式
- Files changed: `src/core/player_development.gd`, `tests/unit/player-dev/training_efficiency_formula_runner.gd`, `production/epics/player-development-system/story-002-training-efficiency-formula.md`
- Verification: Godot 4.6.2 headless evidence passed via `tests/unit/player-dev/training_efficiency_formula_runner.gd` with `TRAINING_EFFICIENCY_FORMULA_TEST_PASS`
- Notes: Added a minimal SceneTree runner so the unit script can execute under headless Godot, then aligned `PlayerDevelopment.normalize_training_efficiency()` with the story rule by clamping authoritative `training_efficiency` to the fixed `[0.8, 1.5]` range before fatigue adjustment instead of using tier-specific config bands.
- Next: Re-check adjacent early player-development stories that were previously marked complete without local runtime evidence, starting with `production/epics/player-development-system/story-003-training-gain-cap.md`

## Session Extract — story-003 runtime verification 2026-05-28
- Story: `production/epics/player-development-system/story-003-training-gain-cap.md` — Story 003: 实现训练成长结算与潜力上限裁剪
- Files changed: `tests/unit/player-dev/training_gain_cap_test.gd`, `tests/unit/player-dev/training_gain_cap_runner.gd`, `production/epics/player-development-system/story-003-training-gain-cap.md`
- Verification: Godot 4.6.2 headless evidence passed via `tests/unit/player-dev/training_gain_cap_runner.gd` with `TRAINING_GAIN_CAP_TEST_PASS`
- Notes: Added a minimal SceneTree runner so the unit script can execute under headless Godot, then corrected the room-limited fixture so AC-1 actually exercises the `min(remaining_growth_room, formula_output)` cap branch instead of accidentally staying formula-limited. Production gain-resolution logic required no change for this story.
- Next: Re-check the next adjacent early player-development story that was previously marked complete without local runtime evidence, starting with `production/epics/player-development-system/story-004-player-tier-band.md`

## Session Extract — story-004 runtime verification 2026-05-28
- Story: `production/epics/player-development-system/story-004-player-tier-band.md` — Story 004: 实现球员层级、潜力区间与训练效率差异
- Files changed: `tests/unit/player-dev/player_tier_band_runner.gd`, `production/epics/player-development-system/story-004-player-tier-band.md`
- Verification: Godot 4.6.2 headless evidence passed via `tests/unit/player-dev/player_tier_band_runner.gd` with `PLAYER_TIER_BAND_TEST_PASS`
- Notes: Added a minimal SceneTree runner so the unit script can execute under headless Godot. The existing implementation and assertions already matched the story acceptance criteria for tier-band mapping, special-source exceptions, and higher-efficiency gain comparison under open-room versus cap-clipped samples.
- Next: Re-check the next adjacent early player-development story that was previously marked complete without local runtime evidence, starting with `production/epics/player-development-system/story-005-training-roi.md`

## Session Extract — story-005 runtime verification 2026-05-28
- Story: `production/epics/player-development-system/story-005-training-roi.md` — Story 005: 实现训练项目匹配、副属性成长与 ROI 计算样本
- Files changed: `tests/unit/player-dev/training_roi_test.gd`, `tests/unit/player-dev/training_roi_runner.gd`, `production/epics/player-development-system/story-005-training-roi.md`
- Verification: Godot 4.6.2 headless evidence passed via `tests/unit/player-dev/training_roi_runner.gd` with `TRAINING_ROI_TEST_PASS`
- Notes: Added a minimal SceneTree runner so the unit script can execute under headless Godot, then strengthened the cap-limited secondary-gain fixture so AC-2 actually exercises a clipped-secondary sample. Production ROI and secondary-gain logic required no change for this story.
- Next: Re-check the next adjacent early player-development story that was previously marked complete without local runtime evidence, starting with `production/epics/player-development-system/story-006-training-atomic-integration.md`

## Session Extract — story-006 runtime recheck 2026-05-28
- Story: `production/epics/player-development-system/story-006-training-atomic-integration.md` — Story 006: 实现训练原子性与 Economy/Time 集成
- Files changed: None
- Verification: Godot 4.6.2 headless integration evidence re-ran via `tests/integration/player-dev/training_atomic_integration_test.tscn` with `TRAINING_ATOMIC_INTEGRATION_TEST_PASS`
- Notes: Existing integration evidence remained valid under the current local Godot environment. No runner, fixture, or production-code changes were needed for the authoritative validate→deduct→grow→apply→emit flow or the accredited Economy/Time integration boundary.
- Next: Re-check the next adjacent player-development story that may benefit from local runtime re-verification, starting with `production/epics/player-development-system/story-007-player-milestone-history.md`

## Session Extract — story-007 runtime recheck 2026-05-28
- Story: `production/epics/player-development-system/story-007-player-milestone-history.md` — Story 007: 实现成长里程碑、训练历史与赛季年龄推进
- Files changed: None
- Verification: Godot 4.6.2 headless integration evidence re-ran via `tests/integration/player-dev/player_milestone_history_test.tscn` with `PLAYER_MILESTONE_HISTORY_TEST_PASS`
- Notes: Existing integration evidence remained valid under the current local Godot environment. No runner, fixture, or production-code changes were needed for milestone emission, history recording, recent-growth summary generation, or once-per-season age advancement.
- Next: Re-check the next adjacent player-development story that may benefit from local runtime re-verification, starting with `production/epics/player-development-system/story-008-player-state-boundary.md`

## Session Extract — story-008 runtime recheck 2026-05-28
- Story: `production/epics/player-development-system/story-008-player-state-boundary.md` — Story 008: 实现赛后状态消费与下游写保护边界
- Files changed: None
- Verification: Godot 4.6.2 headless integration evidence re-ran via `tests/integration/player-dev/player_state_boundary_test.tscn` with `PLAYER_STATE_BOUNDARY_TEST_PASS`
- Notes: Existing integration evidence remained valid under the current local Godot environment. No runner, fixture, or production-code changes were needed for match-provided condition/morale carryover, downstream write-protection boundaries, or conflicting-state rejection/review handling.
- Next: Player-development early-story runtime rechecks are complete through story-008; remaining validated closure in this epic is already covered by `story-009-player-development-regression.md`

## Session Extract — player-development epic review 2026-05-28
- Epic: `production/epics/player-development-system/EPIC.md` — 运动员培养系统
- Files changed: `production/epics/player-development-system/EPIC.md`, `production/epics/player-development-system/story-004-player-tier-band.md`, `production/epics/player-development-system/story-005-training-roi.md`
- Review scope: Epic/story document review, code/test read-only review, and full local Godot 4.6.2 headless rerun of player-development unit + integration evidence
- Verification: `TRAINING_EFFICIENCY_FORMULA_TEST_PASS`, `TRAINING_GAIN_CAP_TEST_PASS`, `PLAYER_TIER_BAND_TEST_PASS`, `TRAINING_ROI_TEST_PASS`, `PLAYER_DATA_SERIALIZATION_BOUNDARY_TEST_PASS`, `TRAINING_ATOMIC_INTEGRATION_TEST_PASS`, `PLAYER_MILESTONE_HISTORY_TEST_PASS`, `PLAYER_STATE_BOUNDARY_TEST_PASS`, `PLAYER_DEVELOPMENT_REGRESSION_TEST_PASS`
- Notes: The epic now reflects completed implementation status with review notes. Story 004 and Story 005 passed runtime verification but retain explicit review notes where current automated coverage is narrower than the full AC wording. No production-code changes were made during the review pass.
- Next: If desired, the next follow-up is to strengthen Story 004 and Story 005 AC-level coverage rather than implementation logic.

## Session Extract — /dev-story 2026-05-28
- Story: `production/epics/save-and-load-system/story-007-load-restore-order.md` — Story 007: 实现读档恢复顺序与权威状态重建
- Files changed: `src/autoload/save_manager.gd`, `tests/integration/save/load_restore_order_test.gd`, `tests/integration/save/load_restore_order_runner.gd`, `production/epics/save-and-load-system/story-007-load-restore-order.md`
- Test written: `tests/integration/save/load_restore_order_test.gd` (4 test functions) via `tests/integration/save/load_restore_order_runner.gd`
- Blockers: None — headless verification passed (`LOAD_RESTORE_ORDER_TEST_PASS`).
- Next: `/code-review src/autoload/save_manager.gd tests/integration/save/load_restore_order_test.gd tests/integration/save/load_restore_order_runner.gd` then `/story-done production/epics/save-and-load-system/story-007-load-restore-order.md`

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/save-and-load-system/story-007-load-restore-order.md` — Story 007: 实现读档恢复顺序与权威状态重建
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/save/load_restore_order_test.gd`; `src/autoload/save_manager.gd` now restores snapshots only after migration/compatibility validation, deserializes in fixed `time → town → player → league → economy → match` order, aborts on the first restore failure before later systems run, and rejects match-in-progress snapshots as stable authority state. Verification runs through `tests/integration/save/load_restore_order_runner.gd` and passed with `LOAD_RESTORE_ORDER_TEST_PASS`.
- Next recommended: `production/epics/save-and-load-system/story-008-save-recovery-flow.md` — Implement structured recovery semantics on top of the completed ordered restore path

## Session Extract — /dev-story 2026-05-28
- Story: `production/epics/save-and-load-system/story-008-save-recovery-flow.md` — Story 008: 实现存档恢复失败与玩家风险操作语义
- Files changed: `src/autoload/save_manager.gd`, `tests/integration/save/save_recovery_flow_test.gd`, `tests/integration/save/save_recovery_flow_runner.gd`, `production/epics/save-and-load-system/story-008-save-recovery-flow.md`
- Test written: `tests/integration/save/save_recovery_flow_test.gd` (4 test functions) via `tests/integration/save/save_recovery_flow_runner.gd`
- Blockers: None — headless verification passed (`SAVE_RECOVERY_FLOW_TEST_PASS`).
- Next: `/code-review src/autoload/save_manager.gd tests/integration/save/save_recovery_flow_test.gd tests/integration/save/save_recovery_flow_runner.gd` then `/story-done production/epics/save-and-load-system/story-008-save-recovery-flow.md`

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/save-and-load-system/story-008-save-recovery-flow.md` — Story 008: 实现存档恢复失败与玩家风险操作语义
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/save/save_recovery_flow_test.gd`; `src/autoload/save_manager.gd` now classifies failed loads into structured recovery semantics before restore, preserves current runtime state on invalid/corrupted slot loads, exposes overwrite/delete confirmation contracts through dedicated risk-evaluation APIs, and only allows explicit confirmed deletion rather than silently repairing corrupted snapshots into authority state. Verification runs through `tests/integration/save/save_recovery_flow_runner.gd` and passed with `SAVE_RECOVERY_FLOW_TEST_PASS`.
- Next recommended: `production/epics/save-and-load-system/story-009-save-summary-performance.md` — Implement save slot summaries and the final performance/regression coverage on top of the completed persistence, migration, restore, and recovery boundaries

## Session Extract — /dev-story 2026-05-28
- Story: `production/epics/save-and-load-system/story-009-save-summary-performance.md` — Story 009: 实现存档摘要、性能预算与回归样本
- Files changed: `src/autoload/save_manager.gd`, `tests/integration/save/save_summary_performance_test.gd`, `tests/integration/save/save_summary_performance_runner.gd`, `production/epics/save-and-load-system/story-009-save-summary-performance.md`, `production/epics/save-and-load-system/EPIC.md`
- Test written: `tests/integration/save/save_summary_performance_test.gd` (4 test functions) via `tests/integration/save/save_summary_performance_runner.gd`
- Blockers: None — headless verification passed (`SAVE_SUMMARY_PERFORMANCE_TEST_PASS`).
- Next: `/story-done production/epics/save-and-load-system/story-009-save-summary-performance.md`

## Session Extract — /story-done 2026-05-28
- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/save-and-load-system/story-009-save-summary-performance.md` — Story 009: 实现存档摘要、性能预算与回归样本
- Tech debt logged: None
- Notes: Headless integration evidence passed via `tests/integration/save/save_summary_performance_test.gd`; `src/autoload/save_manager.gd` now exposes `get_save_metadata()` and `list_save_slot_metadata()` for UI-facing slot summaries, reports correct `save_summary_progress_ratio`, keeps empty/corrupted/incomplete slots distinguishable, and makes slot inspection migration-aware so legacy on-disk snapshots remain loadable and summary-valid without weakening save-time validation. Verification runs through `tests/integration/save/save_summary_performance_runner.gd` and passed with `SAVE_SUMMARY_PERFORMANCE_TEST_PASS`.
- Next recommended: None — Save/Load epic stories 001–009 are now complete

## Session Extract — story-005 coverage sync 2026-05-28
- Story: `production/epics/player-development-system/story-005-training-roi.md` — Story 005: 实现训练项目匹配、副属性成长与 ROI 计算样本
- Files changed: `src/config/economy_config.gd`, `config/economy_config.tres`, `src/core/economy_manager.gd`, `tests/unit/player-dev/training_roi_test.gd`, `production/epics/player-development-system/story-005-training-roi.md`, `production/epics/player-development-system/EPIC.md`
- Verification: `TRAINING_ROI_TEST_PASS`
- Notes: Added authoritative `ap_to_funds_weight` ownership to EconomyConfig/EconomyManager, updated ROI coverage to read the weight through EconomyManager and assert ordinary-vs-star short/mid-term sample tradeoffs directly, then synced the story review note and restored the player-development epic status to `Complete`.
- Next: None — player-development epic review notes are now closed

## Session Extract — /review-all-gdds 2026-05-31
- Report written: `design/gdd/gdd-cross-review-2026-05-31.md`
- Scope: Cross-GDD consistency, holistic design review, and multi-system scenario walkthrough across concept, systems index, balance, save/load, time/season, player development, match competition, economy, league, town building, main-loop UI, player-management UI, match-performance UI, and onboarding GDDs.
- Verdict: FAIL — Systems Design should not advance to Technical Setup until blockers are resolved or explicitly accepted.
- Blockers: `systems-index.md` dependency/MVP boundary drift; town-building outputs without complete downstream consumers; forced match progression lacks legal-state fallback; MVP economy/town-building scope is unstable; match-day AP deadlock risk.
- Warnings: Hidden MVP research-point resource, town-building optimization-grid drift from warm-town pillar, youth academy/training-ground snowball risk, maintenance soft-stall risk, league team count vs time pacing mismatch, home advantage double-count/stale cap wording, pre-match attention budget overload, training ROI time-cost ownership gap, UI return-path ambiguity.
- Next: Decide whether MVP includes a minimal town-building slice, update `systems-index.md`, define match-trigger fallback rules for insufficient AP and illegal lineup, normalize town-building outputs, then re-run `/review-all-gdds`.
