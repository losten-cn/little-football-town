# 足球小镇：全局 GDD 复评 — 2026-06-03

> **Review Type**: `/review-all-gdds` full pass  
> **Scope**: Cross-GDD consistency, holistic design review, and cross-system scenario walkthrough  
> **Verdict**: PASS WITH WARNINGS — no project-blocking items; Random Event → Reputation/Achievement is a scoped warning/flag  
> **Engine Context**: Godot 4.6 / GDScript  
> **Review Posture**: 允许 warning / flag，优先收敛推进；只有真正破坏实现契约、结算安全或核心闭环、且无法通过范围裁剪继续推进的缺口才阻塞。

## Executive Summary

本轮复评覆盖当前已设计的 Foundation、Core、Feature、Presentation 与 Polish GDD。整体结论是：MVP 主闭环（培养 → 比赛 → 结算 → 回到培养）已经具备可推进的跨系统契约，比赛日 AP 兜底、非法阵容 fallback、赛后主结算、小镇建设最小切片、技能/特性反馈与存档安全边界均已从早期阻塞状态收敛为可实现方案。

本轮不建议因为 advisory 问题继续阻塞 Systems Design。随机事件系统声明可向声望与成就系统提交已确认事件事实，但声望与成就 GDD 当前没有反向声明随机事件来源，也没有定义事件事实如何映射到声望/成就判定；该问题记录为 Random Event → Reputation/Achievement 的 scoped warning/flag。后续可通过补接收契约或明确 Beta 首版暂不触发长期认可来收敛，不应阻塞 MVP 主闭环、技术架构继续推进或全局方案定稿。

## Phase Results

| Phase | Result | Notes |
|---|---|---|
| Cross-GDD consistency | PASS WITH WARNINGS | 未发现 MVP 主闭环断裂；发现状态追踪、registry、音频设置入口、town-building 音频反向依赖与 match/league contract wording 风险。 |
| Holistic design review | PASS WITH WARNINGS | 核心幻想一致；主要风险是设施优先 snowball、Alpha 信息叠层注意力预算、兜底机制过常态化。 |
| Cross-system walkthrough | PASS WITH WARNINGS | 比赛日、赛后结算、设施完工路径可走通；随机事件 → 长期认可链路未闭合，记录为 scoped warning/flag。 |

## Warning / Flag Items

1. **Random Event → Reputation/Achievement receiving contract is not closed.**
   - **Files**: `design/gdd/random-event-system.md`, `design/gdd/reputation-and-achievement-system.md`
   - **Evidence**: `random-event-system.md` declares that events must not directly grant achievements/reputation but may submit confirmed event facts to the reputation/achievement system; it also includes `target_scope = reputation` and `effect_request_type` values for reputation facts. Grep found no corresponding random-event intake language in `reputation-and-achievement-system.md`.
   - **Why it matters**: This creates an unclosed feature contract. Random events can emit a “long-term recognition fact,” but the receiving system does not define whether it consumes, ignores, deduplicates, scores, or rejects that fact.
   - **Recommended resolution**: Add a receiving contract in `reputation-and-achievement-system.md`, or explicitly scope Beta random events to not trigger reputation/achievement recognition until a later revision.
   - **Gate impact**: Warning/flag only. It should be tracked before implementing that specific cross-feature hook, but it does not block MVP implementation, architecture planning, audio/town/event standalone design convergence, or global GDD sign-off.

2. **Status and next-step tracking drift.**
   - **Files**: `design/gdd/systems-index.md`, `design/gdd/audio-system.md`, `design/gdd/player-development-system.md`, `design/gdd/skill-and-trait-system.md`, `design/gdd/town-management-ui.md`
   - **Evidence**: `systems-index.md` marks Audio as Approved, but `audio-system.md` header still says `In Design`; the index still recommends Audio as the next GDD after approving it. Similar status drift exists for several GDD headers versus index rows.
   - **Why it matters**: Planning and review gates can read the wrong readiness state.
   - **Recommended resolution**: Make `systems-index.md` the status source of truth or sync headers immediately after approval; update “Recommended Next GDD” to point to `多周目与挑战模式系统` or another genuinely not-started system.

3. **Registry baseline is stale for `training_actual_gain`.**
   - **Files**: `design/registry/entities.yaml`, `design/gdd/player-development-system.md`
   - **Evidence**: Registry entry for `training_actual_gain` describes the older formula and does not include `skill_training_multiplier`, while the current player-development GDD includes skill multiplier input.
   - **Why it matters**: Formula review and implementation traceability can validate against an outdated contract.
   - **Recommended resolution**: Update the registry formula entry; decide whether non-formula payload contracts should also be added to the registry or tracked elsewhere.

4. **Non-formula cross-system contracts are not represented in the registry.**
   - **Files**: `design/registry/entities.yaml`, multiple GDDs
   - **Evidence**: `entities`, `items`, and `constants` are empty while active payload contracts such as settlement keys, feedback payloads, save fields, and event packets are heavily used across GDDs.
   - **Why it matters**: Cross-review currently relies on full document reads rather than a registry baseline for payload/state ownership.
   - **Recommended resolution**: Add registry entries for the highest-risk payload contracts first: match result packet, `forfeit_result_packet`, skill/trait feedback payloads, random event settlement keys, reputation settlement keys, audio settings fields, and hint state fields.

5. **Audio settings ownership is split between Audio, Save/Load, and Main Loop UI.**
   - **Files**: `design/gdd/audio-system.md`, `design/gdd/save-and-load-system.md`, `design/gdd/main-loop-ui-framework.md`
   - **Evidence**: Audio defines persistent fields and acceptance criteria for restored settings; Save/Load treats audio preference fields as persistent state; Main Loop UI declares UI audio trigger events but does not clearly own the player-facing volume/settings entry.
   - **Why it matters**: The fields can be saved, but the player-facing edit surface remains ambiguous.
   - **Recommended resolution**: Assign temporary minimal settings ownership to Main Loop UI, or add a dedicated Settings/Options UI system before implementation.

6. **Town-building does not back-reference audio as a downstream consumer.**
   - **Files**: `design/gdd/audio-system.md`, `design/gdd/town-building-system.md`
   - **Evidence**: Audio depends on build start, upgrade confirm, and completion semantics; town-building does not list audio as a downstream consumer.
   - **Why it matters**: Construction/upgrade/complete audio hooks can be forgotten during implementation.
   - **Recommended resolution**: Add audio as a downstream consumer in town-building and name stable event outputs for construction feedback.

7. **Match ↔ League dependency should be phrased as contract exchange, not concrete mutual coupling.**
   - **Files**: `design/gdd/systems-index.md`, `design/gdd/match-competition-system.md`, `design/gdd/league-competition-structure-system.md`
   - **Evidence**: The index and both GDDs describe a hard mutual dependency, while the actual safe implementation boundary is league-provided match context and match-provided result packet.
   - **Why it matters**: Implementable as contracts; risky if translated into concrete circular runtime coupling.
   - **Recommended resolution**: Document the interface as `league -> match_context` and `match -> match_result_packet`.

8. **Facilities may still create a training-first dominant path.**
   - **Files**: `design/gdd/town-building-system.md`, `design/gdd/player-development-system.md`, `design/gdd/economy-management-system.md`
   - **Evidence**: Town-building deliberately caps MVP outputs, but `facility_training_multiplier` still directly boosts training; player-development also consumes skill multipliers; economy has recovery support.
   - **Why it matters**: Facilities-first or star-player-first routes may outperform balanced play enough to become dominant.
   - **Recommended resolution**: Validate three early-game routes in prototype/playtest: balanced, facilities-first, and star-player-first. Tune early facility slope and maintenance if needed.

9. **Alpha information layers may exceed the low-pressure attention budget.**
   - **Files**: `design/gdd/main-loop-ui-framework.md`, `design/gdd/player-management-ui.md`, `design/gdd/match-performance-ui.md`, `design/gdd/skill-and-trait-system.md`, `design/gdd/reputation-and-achievement-system.md`, `design/gdd/tutorial-and-hint-system.md`, `design/gdd/town-management-ui.md`
   - **Evidence**: Single-screen constraints exist, but Alpha systems add skill candidates, identity history, reputation progress, hints, and town management notices.
   - **Why it matters**: The game could drift from light management into multi-panel operations even if each individual screen is compliant.
   - **Recommended resolution**: Add a global UI rule: at any stable moment, only one system may ask for active player decision; all other systems must present passive summaries, badges, or deferred follow-up.

10. **Low-pressure fallback mechanisms need frequency validation.**
   - **Files**: `design/gdd/time-and-season-progression-system.md`, `design/gdd/economy-management-system.md`, `design/gdd/match-competition-system.md`, `design/gdd/onboarding-system.md`
   - **Evidence**: `match_day_ap_safety_grant`, `season_recovery_floor_grant`, and `forfeit_result_packet` protect players from deadlocks.
   - **Why it matters**: If triggered often, players may learn that resource mistakes are always erased by the system.
   - **Recommended resolution**: Treat these as low-frequency emergency safety nets and validate trigger rates during prototype/playtest.

11. **MVP town identity is visible but still mechanically light.**
    - **Files**: `design/gdd/systems-index.md`, `design/gdd/town-building-system.md`, `design/gdd/random-event-system.md`, `design/gdd/audio-system.md`, `design/gdd/town-management-ui.md`
    - **Evidence**: MVP town-building remains a minimum support slice; stronger town-life expression is deferred to Random Event, Audio, and Alpha Town Management UI.
    - **Why it matters**: Scope is healthy, but MVP may read more like a light football manager than a football town unless presentation reinforces the town identity.
    - **Recommended resolution**: Keep MVP mechanics narrow, but ensure Home, Match Result, and season settlement visibly reflect town changes.

## Scenario Walkthroughs

### 1. Match day with insufficient AP and illegal lineup

- **Trigger**: Match threshold reached while AP is insufficient and lineup is illegal.
- **Activation order**: Time → Economy `match_day_ap_safety_grant` → Match Pre UI → Match recommended lineup/out-of-position fill → `forfeit_result_packet` if still invalid → Time post-match settlement.
- **Result**: No deadlock found. The player can continue the season even in worst-case conditions.
- **Severity**: WARNING only — tutorial/hint/audio messaging for ordinary post-onboarding fallback can be clearer.

### 2. Post-match settlement chain

- **Trigger**: Normal result or forfeit result packet produced.
- **Activation order**: Match result → Time settlement → Economy → League → Player Development → Skill/Trait feedback → Reputation/Achievement → Match Result UI → Audio/Hints.
- **Result**: Main result flow is coherent and implementable.
- **Severity**: WARNING — cross-system authority order for conflicting post-match player status changes should be made more explicit before implementing complex status overlaps.

### 3. Facility build/upgrade completion

- **Trigger**: Construction or upgrade duration completes.
- **Activation order**: Time → Town Building state update → Player Development training multiplier / Economy maintenance → Main Loop UI / Town Management UI → Audio.
- **Result**: State flow is coherent.
- **Severity**: INFO — avoid duplicate completion presentation between MVP Home summary and Alpha Town Management UI.

### 4. Random event offer/result

- **Trigger**: Legal stable window after day start, training, match result, stage settlement, or build completion.
- **Activation order**: Time window → Random Event candidate → Player choice → Event settlement key → target authority system → UI → Audio/Hints.
- **Result**: Economy/player/town effects are safely routed through authority systems. Reputation/Achievement routing is not closed.
- **Severity**: WARNING/FLAG — track before implementing Random Event → Reputation/Achievement recognition, but do not block global GDD convergence.

## Design Theory Summary

- **Progression loop**: The primary loop remains cultivation → match → feedback → cultivation. Town, reputation, skills, random events, audio, and hints are mostly support layers.
- **Attention budget**: MVP is controlled; Alpha layering is the main future risk.
- **Dominant strategy**: Facilities-first and star-player-first routes require playtest validation.
- **Economy**: Recoverability is strong; fallback frequency and maintenance feel remain tuning risks.
- **Difficulty curve**: No direct contradiction found; avoid flattening stakes through overly common safety grants.
- **Pillar alignment**: Most systems explicitly preserve low-pressure, warm-town tone and avoid FOMO/high-pressure loops.
- **Player fantasy coherence**: Strong overall; the player identity remains “coach-manager of a growing small-town team,” not optimizer of a hostile economy.

## Recommended Follow-Up Order

1. Decide Random Event → Reputation/Achievement scope: close the contract or explicitly cut the integration for Beta first pass.
2. Sync tracking status between GDD headers, `systems-index.md`, and review logs; update the stale “Recommended Next GDD” section.
3. Update `design/registry/entities.yaml` for stale `training_actual_gain` and selected high-risk payload contracts.
4. Assign minimal audio settings entry ownership.
5. Add town-building → audio downstream back-reference.
6. Clarify match/league as packet-based contract exchange.
7. Carry facilities-first, attention-budget, and fallback-frequency risks into prototype/playtest validation rather than reopening broad Systems Design.

## Gate Recommendation

Systems Design remains suitable to proceed toward Technical Setup / architecture planning with warnings tracked. Do not block the project or global GDD convergence on the Random Event → Reputation/Achievement gap; track it as a scoped warning/flag and resolve it before implementing that optional recognition hook, or explicitly scope the hook out for the first Beta pass.
