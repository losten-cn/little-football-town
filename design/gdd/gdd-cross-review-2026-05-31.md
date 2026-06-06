# Cross-GDD Review — 2026-05-31

**Scope:** `/review-all-gdds` full pass across MVP/Core GDDs  
**Engine Context:** Godot 4.6 / GDScript  
**Review Mode:** Full cross-document consistency + holistic design pass  
**Verdict:** PASS WITH WARNINGS

## Summary

The GDD set now forms a stable enough design baseline to advance beyond Systems Design without carrying forward unresolved cross-document blockers. The core loop of **训练 → 比赛 → 反馈 → 再培养** remains coherent, and the previously blocking issues around MVP boundary drift, forced match fallback, AP deadlock, stale ownership references, and research-point MVP semantics have been resolved.

The remaining concerns are no longer about contradictory requirements. They are now mostly experience-shaping warnings: town-building still risks reading as an optimization grid more than a warm hometown fantasy, pre-match attention load still needs careful UI staging, and long-term balance around facility snowballing and maintenance recovery still requires follow-through in implementation and tuning.

## Scope

本次复审基于以下文档的最新版本进行交叉一致性、整体设计与关键多系统场景复核：

- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/gdd/balance-system.md`
- `design/gdd/save-and-load-system.md`
- `design/gdd/time-and-season-progression-system.md`
- `design/gdd/player-development-system.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/league-competition-structure-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/match-performance-ui.md`
- `design/gdd/onboarding-system.md`
- `design/gdd/reputation-and-achievement-system.md`

本轮目标是验证 2026-05-31 上一版 cross-review 中的 blocker 修复后，系统集合是否仍存在阻塞后续阶段推进的跨文档矛盾、整体设计缺口或关键流程未闭环问题。

## Documents Reviewed

- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/gdd/balance-system.md`
- `design/gdd/save-and-load-system.md`
- `design/gdd/time-and-season-progression-system.md`
- `design/gdd/player-development-system.md`
- `design/gdd/match-competition-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/league-competition-structure-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/match-performance-ui.md`
- `design/gdd/onboarding-system.md`
- `design/gdd/reputation-and-achievement-system.md`

## Registry Baseline

`design/registry/entities.yaml` currently has no entity/item/constant entries, but does register active authoritative formulas including:

- `effective_attribute_value`
- `attribute_growth`
- `resource_settlement`
- `positional_overall_rating`
- `base_win_probability`
- `action_time_cost`
- `available_action_windows`
- `match_trigger_reached`
- `stage_settlement_trigger_reached`
- `season_progress_ratio`
- `remaining_time_to_next_key_node`
- `training_actual_gain`
- `player_tier_potential_band`

The review treats those registered formulas as the current shared authority. Entity / item / constant registry coverage is still empty, so non-formula consistency continues to rely on GDD text rather than registry enforcement.

## Verdict

**PASS WITH WARNINGS**

上一轮阻塞 Systems Design 继续推进的核心 blocker 已全部解除。当前 GDD 集合已具备进入下一阶段的设计完整度，不需要再因 cross-GDD 一致性问题继续阻塞 Systems Design → Technical Setup。

剩余问题主要集中在体验重心、后续平衡观察和 UI 负担控制上，属于明确 warning，而非当前阶段 blocker。

## Phase 2 — Cross-GDD Consistency

**Verdict:** PASS WITH WARNINGS

### Closed Blockers

#### 1. MVP 边界漂移已关闭
`design/gdd/systems-index.md` 已明确把最小小镇建设切片纳入 MVP，范围不再在 MVP / Alpha 之间摇摆。

#### 2. 小镇建设输出缺少下游消费方已关闭
MVP 所需设施输出现已形成明确消费链：

- `facility_training_multiplier` → `player-development-system.md`
- `facility_ap_bonus` → `economy-management-system.md`
- `facility_total_maintenance` → `economy-management-system.md`
- `home_advantage_bonus + adj_stadium_home_bonus` → `match-competition-system.md`
- `stadium_revenue_multiplier` → `economy-management-system.md`

小镇建设最小切片已不再是“只有产出、没有消费者”的悬空系统。

#### 3. 强制比赛缺少合法 fallback 已关闭
`design/gdd/match-competition-system.md` 已定义完整兜底顺序：

1. 推荐阵容  
2. 错位补位并施加位置适配折损  
3. 可出场人数不足时生成 `forfeit_result_packet`

该结果已与时间、联赛、经济、引导和比赛表现 UI 语义对齐，正式比赛节点不再因阵容非法而卡住。

#### 4. 比赛日 AP 死锁风险已关闭
`match_day_ap_safety_grant` 已在以下文档中达成统一：

- `time-and-season-progression-system.md`
- `economy-management-system.md`
- `main-loop-ui-framework.md`
- `onboarding-system.md`

正式比赛节点在 AP 不足时会被系统补足到最低开赛要求，不再形成“比赛必须打，但又没有资源开赛”的推进死锁。

#### 5. 研究点数 MVP 语义冲突已关闭
以下文档现已统一研究点数的 MVP 语义：

- `design/gdd/game-concept.md`
- `design/gdd/balance-system.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/systems-index.md`

统一后的定义为：

- 研究点数在 MVP 阶段正常后台累积并持久化；
- 不在 MVP UI 中展示；
- 不在 MVP 阶段开放消费出口；
- Alpha 阶段接入正式解锁/研究闭环。

此前“概念层写成核心可消费资源、系统层写成隐藏后台资源”的冲突已清除。

#### 6. 比赛“可推迟”表述冲突已关闭
`design/gdd/main-loop-ui-framework.md` 已移除会误导实现的通用“推迟比赛”语义，改为：

- 仅在时间系统允许取消返回的非强制场景中可离开赛前流程；
- 不可跳过的正式比赛节点不得被“推迟比赛”方式绕过。

UI 框架与时间系统现在对 Match Trigger 的强制性约束保持一致。

#### 7. 设施接口名与消费方归属漂移已关闭
`design/gdd/town-building-system.md` 中的旧接口残留已被修正：

- `facility_maintenance_cost` → `facility_total_maintenance`
- `stadium_revenue_multiplier` 不再错误挂在比赛系统消费链下，而是明确由经济系统在 `post_match_funds` 中消费

这一轮修订清除了实现期最容易出现的错接接口风险。

#### 8. 维护费软停滞缺少设计合同已关闭
`design/gdd/economy-management-system.md` 与 `design/gdd/town-building-system.md` 已新增“软停滞保护”约束：

- 经费可以归零；
- 经营压力可以存在；
- 但不得把玩家推进到必须重开档才能恢复的隐性失败态。

该约束把“低压力长期成长”支柱落实成了可验证的跨系统规则，而不再只是体验口号。

### Remaining Warnings

#### WARNING — UI return-path ambiguity is mostly resolved but now depends on implementation discipline

**Files involved:**

- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/player-management-ui.md`

**Issue:**  
The framework now distinguishes cross-system closure returns from same-context local returns, which resolves the direct contradiction. The remaining risk is implementation drift if screens do not preserve caller-aware navigation.

**Recommendation:**  
When implementing presentation flows, treat “return to caller context” as the default rule for subflows launched from a detail page.

#### WARNING — Stable node terminology can still be tightened

**Files involved:**

- `design/gdd/save-and-load-system.md`
- `design/gdd/time-and-season-progression-system.md`

**Issue:**  
No current blocker remains, but save/load and time progression still use slightly different emphasis when describing recoverable stable nodes.

**Recommendation:**  
Keep the save/load system as the authoritative stable-node vocabulary and align future examples in time progression and UI flows to it.

#### INFO — System status records are now synchronized

**Files involved:**

- `design/gdd/systems-index.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/match-performance-ui.md`

**Issue:**  
Previously stale UI system status records have been corrected.

**Recommendation:**  
Preserve `systems-index.md` as the single status authority for GDD readiness.

## Phase 3 — Holistic Design Review

**Verdict:** PASS WITH WARNINGS

### Closed Blockers

#### 1. MVP boundary instability around economy and town-building is closed
The project now clearly commits to an MVP that includes a minimum town-building slice rather than relying on fixed hidden defaults. That decision is reflected across the concept, systems index, economy, town-building, and main-loop UI docs.

#### 2. Match-day AP hard-lock risk is closed
The project now defines a single hard rule through `match_day_ap_safety_grant`, and that rule is reflected across time progression, economy, UI, and onboarding. Forced match progression no longer conflicts with affordability.

### Remaining Warnings

#### WARNING — Town-building still risks reading as an optimization grid rather than a warm town fantasy

**Files involved:**

- `design/gdd/game-concept.md`
- `design/gdd/town-building-system.md`

**Issue:**  
当前 MVP 小镇建设切片虽然已控制住范围，但规则重心仍偏向邻接、倍率、维护费、格子效率和长期回报优化。它并未违反概念支柱，但后续 UI 与表现层必须继续补足“温暖、生活感、归属感”的可感知反馈，否则玩家可能更容易把它读成“低压优化盘”，而不是“想照顾的足球小镇”。

**Recommendation:**  
Add or preserve visible town identity feedback in UI, presentation, and progression beats so that optimization remains in service of place attachment rather than replacing it.

#### WARNING — Youth academy plus training ground still needs balance observation

**Files involved:**

- `design/gdd/player-development-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/match-competition-system.md`

**Issue:**  
Current GDDs no longer over-promise Alpha-only recruitment and injury outputs in MVP, which reduces the previous snowball risk. But the combination of `facility_training_multiplier`, youth bonuses, and long-term match-strength payoff still looks like a potentially dominant safe route.

**Recommendation:**  
Keep this as a balance watchpoint during implementation and prototype playtests; do not assume the written cost alone is sufficient to create real trade-offs.

#### WARNING — League size and season-time low-end range still need implementation guardrails

**Files involved:**

- `design/gdd/time-and-season-progression-system.md`
- `design/gdd/league-competition-structure-system.md`

**Issue:**  
The GDD conflict is no longer structural, but tuning must still guarantee that MVP season-unit settings can legally contain the minimum supported league schedule.

**Recommendation:**  
Implementation should enforce or validate a legal lower bound such as `total_season_units_target >= matches_per_team_per_season`.

#### WARNING — Pre-match attention budget remains high

**Files involved:**

- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/player-management-ui.md`
- `design/gdd/match-performance-ui.md`
- `design/gdd/economy-management-system.md`
- `design/gdd/town-building-system.md`

**Issue:**  
Players may still face lineup legality, player state, opponent context, tactical choice, AP awareness, and fallback messaging around the same match-day moment. This is manageable, but it sits close to the limit of the project’s low-pressure pillar.

**Recommendation:**  
UI implementation should stage information by urgency and decision ownership, rather than surfacing all match-adjacent concerns at equal priority.

#### WARNING — Maintenance soft-stall is no longer undefined, but must be proven in implementation

**Files involved:**

- `design/gdd/economy-management-system.md`
- `design/gdd/town-building-system.md`
- `design/gdd/league-competition-structure-system.md`

**Issue:**  
The design contract now forbids irrecoverable soft-stall states, which closes the blocker. The remaining risk is practical: implementation and tuning still need to demonstrate that recovery paths are truly reachable without restart.

**Recommendation:**  
Treat recovery-from-zero-funds as a required scenario in prototype balancing and QA, not as a purely theoretical contract.

### INFO — Save/load and time stable-node design continues to support low-pressure play

**Files involved:**

- `design/gdd/save-and-load-system.md`
- `design/gdd/time-and-season-progression-system.md`

**Issue:**  
No major concern remains. Stable nodes, atomic match resolution, and non-recoverable match-in-progress state continue to support player trust.

**Recommendation:**  
Preserve this boundary during architecture and save implementation.

### INFO — Match result feedback loop remains coherent

**Files involved:**

- `design/gdd/match-competition-system.md`
- `design/gdd/match-performance-ui.md`
- `design/gdd/player-management-ui.md`

**Issue:**  
The match flow still supports readable expectation setting, event feedback, result review, and return to player-growth decisions.

**Recommendation:**  
Protect this feedback chain from later scope additions that add noise without new decision value.

## Phase 4 — Cross-System Scenario Walkthroughs

### Scenario 1 — AP-insufficient forced match day

**Trigger:** The player spends AP before a scheduled required match.  
**Activation order:** Time reaches `Match Trigger` → time requests `match_day_ap_safety_grant` → economy grants only the shortfall → UI surfaces minimum-match-AP message → pre-match flow continues.  
**Assessment:** Closed. The loop no longer hard-locks on required matches.

### Scenario 2 — Illegal-lineup forced match day

**Trigger:** The required match arrives and the current lineup is not legal.  
**Activation order:** Match entry opens → match system attempts recommended lineup → attempts out-of-position fill → falls back to `forfeit_result_packet` if necessary → time continues to post-match settlement → league and economy consume result.  
**Assessment:** Closed. The systems now define a legal continuation path rather than an undefined stall.

### Scenario 3 — Facility outputs affecting training, match strength, and economy

**Trigger:** The player invests in town facilities before a later match and training cycle.  
**Activation order:** Town outputs update → development consumes `facility_training_multiplier` → match consumes facility home-strength bonus → economy consumes maintenance and stadium revenue multiplier.  
**Assessment:** Closed for MVP-required outputs. The previous “producer without consumers” issue is no longer present.

### Scenario 4 — Low-win-rate plus high-maintenance state

**Trigger:** The player overbuilds, then loses repeatedly.  
**Activation order:** Maintenance drains funds → normal spending options narrow → forced matches still proceed → recovery depends on baseline revenue and protected fallback loops.  
**Assessment:** No longer a blocker because recovery is now a documented requirement. It remains a warning because real tuning still needs to prove the recovery path is practical.

## Closed Blockers Summary

The following blocker classes from the previous review are now considered resolved:

1. MVP boundary drift in `systems-index.md`
2. Town-building MVP outputs lacking downstream consumers
3. Forced match progression without legal fallback
4. Match-day AP deadlock risk
5. Research-point MVP semantic contradiction
6. “Postpone match” language conflicting with non-skippable match triggers
7. Stale facility interface naming and revenue-consumer ownership drift
8. Missing design contract for maintenance-driven soft-stall recovery

## Reputation System Addendum

After the initial PASS WITH WARNINGS baseline, `design/gdd/reputation-and-achievement-system.md` was added and reviewed against the current MVP/Core GDD set.

**Verdict:** PASS WITH WARNINGS, no new blockers.

### Closed Addendum Issues

1. **System index stale status closed**  
   `design/gdd/systems-index.md` now lists 声望与成就系统 as `In Design` and points to `design/gdd/reputation-and-achievement-system.md`.

2. **Save/load pending feedback persistence closed**  
   `design/gdd/save-and-load-system.md` now explicitly includes reputation/achievement confirmed results, claimed reward markers, pending reward display state, and pending prompt attachment state in the persistence boundary.

3. **UI feedback sequencing contract closed**  
   `design/gdd/main-loop-ui-framework.md` and `design/gdd/match-performance-ui.md` now mirror the reputation feedback order: core settlement first, then reputation gain/level-up, then achievement completion, then reward/prompt attachment.

4. **Dependency-map alignment closed for the reviewed scope**  
   `design/gdd/systems-index.md` now includes reputation dependencies on match, league, player development, town building, economy, time/season, and save/load, and reflects downstream Presentation/Polish integrations where relevant.

### Remaining Addendum Warnings

- Reputation threshold pacing cannot be fully validated until a concrete threshold table is created and checked against `design/gdd/balance-system.md` milestone targets.
- Future UI implementation must keep reputation and achievement feedback lightweight so it reinforces, rather than competes with, league, player-growth, and town-building goals.

## Remaining Warning Summary

The following concerns should carry forward as active design constraints:

1. Town-building must continue to feel like a warm hometown, not only an optimization board.
2. Youth academy plus training ground synergy still needs prototype balance scrutiny.
3. Season pacing lower bounds must remain compatible with the minimum legal league schedule.
4. Match-day UI must stage decisions carefully to protect the low-pressure pillar.
5. Soft-stall recovery must be demonstrated in real tuning, not only declared in docs.

## Overall Assessment

当前 GDD 集合已从“存在流程级 blocker 与跨文档归属冲突”提升到“核心结构闭环成立、剩余问题以体验调优和数值观察为主”的状态。

换句话说，项目当前不再卡在“文档彼此打架”的阶段，而是进入了“文档已足够支撑实现，但实现必须继续守住低压力、温暖、长期成长主线”的阶段。

## Flagged GDDs

Files that remain most important to watch during implementation and future review:

1. `design/gdd/economy-management-system.md`
2. `design/gdd/town-building-system.md`
3. `design/gdd/main-loop-ui-framework.md`
4. `design/gdd/player-development-system.md`
5. `design/gdd/time-and-season-progression-system.md`
6. `design/gdd/league-competition-structure-system.md`

These are no longer flagged because of unresolved contradiction, but because they now carry the key remaining warning areas.

## Recommendation

建议将本轮结果作为新的 cross-review 基线，并允许 Systems Design 进入下一阶段。

后续优先方向建议为：

1. `声望与成就系统`
2. `技能与特性系统`
3. `建设与经营 UI`

同时建议在进入实现拆解前，把以下 warning 作为明确执行约束保留下来：

- 不得把维护费压力实现成隐性不可恢复失败；
- 不得把小镇建设体验做成纯最优布局盘；
- 不得让比赛日前信息负担压过低压力经营基调；
- 不得让训练场 / 青训营组合在没有代价的情况下成为单一路线最优解。

## Gate Impact

This report no longer blocks Systems Design → Technical Setup on cross-GDD consistency grounds. Instead, it establishes the current baseline as implementation-ready with explicit follow-through warnings. The later addition of the reputation and achievement GDD does not reopen any blocker; it extends the baseline with Alpha-layer long-term recognition requirements and leaves only tuning/presentation warnings for later validation. The next gate should verify that those warnings were respected in architecture, UI structure, and prototype balance rather than re-litigating already-resolved document contradictions.
