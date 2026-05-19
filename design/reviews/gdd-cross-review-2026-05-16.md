# Cross-GDD Review Report (Comprehensive)
**Date**: 2026-05-16
**GDDs Reviewed**: 13
**Mode**: full (consistency + design-theory + scenario walkthrough)
**Verdict**: CONCERNS (all 8 BLOCKING resolved 2026-05-16 — see post-fix addendum; 33 WARNING remain)

---

## Systems Covered
game-concept, balance, save-and-load, time-and-season, player-development, match-competition, economy-management, town-building, league-competition, main-loop-ui, player-management-ui, match-performance-ui, onboarding

---

## Consistency Issues

### BLOCKING

🔴 **B1 — Win probability clamp range contradiction**
- **Files**: `balance-system.md` (Edge Cases), `match-competition-system.md` (Formula 2)
- **Detail**: balance-system Edge Cases: "全部修正完成后再次钳制到 0.05–0.95；任何下游系统都不得绕过共享胜率上下限。" match-comp Formula 2: `clamp(..., 0.02, 0.98)`. These directly contradict.
- **Fix**: Either match-comp adopts [0.05, 0.95], or balance-system revises its shared boundary to [0.02, 0.98] and notifies all Hard dependents.

🔴 **B2 — town-building lists main-loop-ui as Hard downstream; UI doesn't list town-building**
- **Files**: `town-building-system.md` (Downstream Dependencies), `main-loop-ui-framework.md` (Upstream Dependencies)
- **Fix**: Add town-building to main-loop-ui-framework Upstream Dependencies as Hard.

🔴 **B3 — save-and-load lists player-management-ui as downstream; UI doesn't list save-load**
- **Files**: `save-and-load-system.md` (Downstream), `player-management-ui.md` (Upstream)
- **Fix**: Add save-and-load to player-management-ui Upstream Dependencies as Hard.

🔴 **B4 — save-and-load declares Hard dep on main-loop-ui; UI declares Soft — type mismatch**
- **Files**: `save-and-load-system.md`, `main-loop-ui-framework.md`
- **Fix**: Reconcile to a single dep type (recommend Hard given save metadata display requirements).

🔴 **B5 — economy declares Hard dep on main-loop-ui; UI declares Soft provisional**
- **Files**: `economy-management-system.md`, `main-loop-ui-framework.md`
- **Fix**: Reconcile to Hard given economy resource display requirements.

🔴 **B6 — balance-system CI AC would fail match-comp build**
- **Files**: `balance-system.md` (AC: CI scan), `match-competition-system.md` (Formula 2)
- **Detail**: balance AC requires all numerical boundaries registered in balance GDD. match-comp [0.02, 0.98] is unregistered. These ACs cannot both pass.
- **Fix**: Resolve B1 first; this resolves automatically.

🔴 **B7 — Post-match `league_tier_multiplier` undefined for promotion-clinching final match**
- **Files**: `economy-management-system.md`, `league-competition-structure-system.md`
- **Detail**: If the final match of a season clinches promotion, does `post_match_funds` use the old or new tier's `league_tier_multiplier`? Unspecified.
- **Fix**: Specify that match revenue uses the tier the team belonged to when the match was played.

🔴 **B8 — Research Points have 2 sources, ZERO MVP sinks — broken economic loop**
- **File**: `economy-management-system.md` (Edge Cases, line 284)
- **Detail**: RP has `post_match_research` and `season_bonus_research` as sources. MVP declares "持续累积但无可消费出口" as intentional. A resource displayed with no use undermines UI trust.
- **Fix**: Either remove RP from MVP UI, or add a minimal sink (e.g., tactical research conversion).

### WARNING

⚠️ **W1 — Dependency type mismatches (economy↔league-comp)**
- `economy-management-system.md` lists league-comp as Hard; league-comp lists economy as Soft provisional.

⚠️ **W2 — Dependency type mismatches (save-load↔onboarding naming)**
- `onboarding-system.md` lists save-load as Hard; save-load lists "新手引导相关流程" as Soft — naming inconsistency.

⚠️ **W3 — match-performance-ui missing time-and-season upstream dep**
- Time system lists match-performance-ui as downstream; match-performance-ui does not reciprocate.

⚠️ **W4 — economy missing game-concept in formal Upstream table**
- All other 12 GDDs include game-concept as Hard upstream. Economy omits it from the formal table.

⚠️ **W5 — Economy `post_match_funds` min [100] invalid at tuned `base_match_funds = 200`**
- Declared range [100, 630] assumes default 250. At tuned minimum 200, loss income = 80 — below floor.

⚠️ **W6 — Construction time uses "天" while time system uses "窗口"**
- town-building Formula 2 uses "天" (days); time system uses "窗口" (windows). Equivalence not formalized.

⚠️ **W7 — game-concept lists non-existent GDDs as dependencies**
- 声望与成就系统 GDD and 随机事件系统 GDD don't exist. Mitigated: all references correctly marked Soft/Alpha/Beta.

⚠️ **W8 — match-comp Hard-depends on town-building (Status: In Design) while match-comp is Designed**
- Temporal staging issue — match-comp locked before town-building design complete.

⚠️ **W9 — Entity registry incomplete**
- `entities`, `items`, `constants` sections empty. Several cross-boundary formulas (post_match_funds, daily_maintenance_cost, actual_win_probability) not registered.

⚠️ **W10 — Economy AC vs UI AC temporally contradictory**
- Economy AC expects real resource display; UI AC expects placeholders. Reflect different MVP staging assumptions.

⚠️ **W11 — Training facility upgrade same-window snapshot behavior unspecified**
- If facility upgrade completes on same action window as training, which `facility_training_multiplier` applies? Town-building Edge Cases cover "训练中途" but not same-window.

⚠️ **W12 — Season settlement player aging + youth bonus transition UI unspecified**
- Player crossing `youth_age_threshold` at season settlement: no GDD specifies how training multiplier summary presents pre/post transition.

⚠️ **W13 — Triple-hit compounding at season settlement**
- Relegation + youth bonus loss + unreduced maintenance in single settlement event has no mitigation.

⚠️ **W14 — RP season bonus displayed at settlement with no sink**
- Season summary shows RP gains player cannot use — undermining settlement satisfaction.

⚠️ **W15 — `team_match_strength` declared range (~5–100) narrower than mathematical minimum (~0.85)**
- `match-competition-system.md` Formula 1: no explicit clamp, approximate range.

---

## Game Design Issues

### BLOCKING

🔴 **B8 (same as above) — Research Points: broken economic loop (see Consistency B8)**

### WARNING

⚠️ **GD1 — Four systems compete as primary drivers despite stated dual-core**
- game-concept defines "培养+比赛" as dual core. Economy, town-building, and time system all position themselves as equally primary in their self-descriptions.

⚠️ **GD2 — Training Ground + Youth Academy adjacency is near-mandatory dominant strategy**
- Formula 8.3c: TG Lv.5 + YA Lv.3 adjacency yields 1.526× total training multiplier. No competing adjacency pair approaches this magnitude.

⚠️ **GD3 — Facility costs scale exponentially, benefits linearly — ROI collapses 92% by Lv.5**
- Lv.1→Lv.5 training ground: cost increases 10.5×, benefit increases only 1.19×. Marginal efficiency/cost drops 92%.

⚠️ **GD4 — Pillar 2 (像素小镇养成) severely underrepresented — only 5/13 GDDs**
- Onboarding doesn't include town building. Main-loop-ui has no Town tab. For a pillar-level system, visibility is critically low.

⚠️ **GD5 — Multiple mechanics create pressure violating Pillar 3 (低压力)**
- Relegation (binary high-stakes), maintenance deficit (razor-thin margins at high levels), silent AP waste, 2% loss floor for maxed teams.

⚠️ **GD6 — Six player identities (coach, accountant, mayor, competitor, spectator, planner) create cognitive overload**
- No GDD defines what the player does NOT do. Identity accumulates with every system.

⚠️ **GD7 — Planning phase presents 5+ simultaneous active decision domains**
- Training assignment, facility construction, recruitment evaluation, rest vs. action, match preparation — all constrained by same 3 resources.

⚠️ **GD8 — Specialized training dominates balanced training by 48% in ROI formula**
- Main/secondary attribute weight ratio 1.0:0.35 structurally favors single-attribute specialization over well-rounded development.

⚠️ **GD9 — Positive feedback loop without circuit breakers**
- Win → more funds → better facilities → stronger players → win more. Inverse death spiral has no bailout, no facility downgrade, no debt mechanic.

⚠️ **GD10 — Stadium-first build order dominates economically**
- Stadium Lv.1: immediate competitive benefit + economic returns. Training Ground Lv.1: only future training benefit. No tradeoff for new players.

⚠️ **GD11 — AP cap creates hidden resource waste punishing casual players**
- Economy Edge Cases: "系统不提示'你浪费了恢复'". Silent resource loss contradicts low-pressure pillar.

⚠️ **GD12 — League tier jumps have no player power guarantee ("promotion cliff")**
- Opponent rating jumps ~15 points on promotion; player growth is at most a few points per season. No promotion bonus or adaptation period.

⚠️ **GD13 — No facility downgrade option creates structural deficit risk**
- Lv.4+ facilities + losing streak = permanent deficit. No mothballing, no partial downgrade, no bailout mechanic.

⚠️ **GD14 — Player identity conflict: Accountant vs. Coach**
- Economy fantasy: "我亲手经营每一笔账." Player-dev fantasy: "我亲手把球员培养成传奇." These are different player identities competing for the same session time.

---

## Cross-System Scenario Issues

### Scenarios Walked: 3
1. Training Settlement (6 systems)
2. Match Resolution (7 systems)
3. Season Settlement (6 systems)

### BLOCKERS (from scenarios)

🔴 **S2-B1 — Win probability clamp contradiction** (same as B1)
Match resolution: `actual_win_probability` [0.02, 0.98] vs balance-system's [0.05, 0.95] rule.

🔴 **S2-B2 — Post-match league_tier_multiplier undefined for promotion final** (same as B7)
Season-final match that clinches promotion: which tier's multiplier applies to match revenue?

### WARNINGS (from scenarios)

⚠️ **S1-W1 — Training + facility upgrade same-window snapshot unspecified** (same as W11)

⚠️ **S3-W1 — Player aging crosses youth_age_threshold at settlement — UI transition unspecified** (same as W12)

⚠️ **S3-W2 — Triple-hit compounding at season settlement** (same as W13)

⚠️ **S3-W3 — RP season bonus displayed with no sink** (same as W14)

---

## GDDs Flagged for Revision

| GDD | Reason | Type | Priority |
|-----|--------|------|----------|
| `match-competition-system.md` | Win probability clamp [0.02, 0.98] violates balance-system boundary | Consistency | P0 |
| `balance-system.md` | Must either accept [0.02, 0.98] or enforce [0.05, 0.95] | Consistency | P0 |
| `economy-management-system.md` | RP has zero MVP sinks (broken loop); missing game-concept in upstream table | Both | P0 |
| `main-loop-ui-framework.md` | Missing town-building, economy Hard upstream deps; dep type mismatches | Consistency | P0 |
| `town-building-system.md` | Missing reciprocal dep verification; exponential cost/linear benefit ROI collapse | Both | P0 |
| `player-management-ui.md` | Missing save-and-load upstream dep | Consistency | P0 |
| `save-and-load-system.md` | Dep type mismatch with main-loop-ui; onboarding naming inconsistency | Consistency | P0 |
| `match-performance-ui.md` | Missing time-and-season upstream dep | Consistency | P1 |
| `onboarding-system.md` | Missing town-building content (Pillar 2 gap) | Design | P1 |
| `game-concept.md` | No "Player Role Boundaries" section; pillar representation gap | Design | P1 |

---

## Summary

| Category | BLOCKING | WARNING | INFO |
|----------|:---:|:---:|:---:|
| Phase 2: Consistency | 5 | 15 | 4 |
| Phase 3: Design Holism | 1 | 14 | 4 |
| Phase 4: Scenarios | 2 | 4 | 1 |
| **Total** | **8** | **33** | **9** |

### Verdict: FAIL
8 blocking issues must be resolved before architecture begins. Top priority: resolve the win probability clamp contradiction and RP dead-end loop.

### Required Actions Before Re-running:
1. Resolve win probability clamp range — match-comp [0.02, 0.98] vs balance [0.05, 0.95]
2. Fix RP economy — either add MVP sink or remove RP from MVP
3. Repair all 6 dependency bidirectionality issues (B2–B5)
4. Specify post-match `league_tier_multiplier` for promotion-clinching matches
5. Re-run `/review-all-gdds` after all fixes applied

---

## Post-Fix Addendum — 2026-05-16

All 8 BLOCKING issues resolved. Targeted verification confirms no remaining 0.02/0.98 references, all dependency bidirectionality gaps closed, RP hidden from MVP UI, and promotion-final league_tier_multiplier rule added.

| Blocker | Fix | Status |
|---------|-----|:------:|
| B1 | match-comp clamp → [0.05, 0.95]; all 5 occurrences updated | ✅ |
| B2 | main-loop-ui + town-building Hard upstream dep added | ✅ |
| B3 | player-management-ui + save-and-load Hard upstream dep added | ✅ |
| B4 | main-loop-ui save-and-load dep Soft→Hard | ✅ |
| B5 | main-loop-ui economy dep Soft provisional→Hard | ✅ |
| B6 | Auto-resolved by B1 | ✅ |
| B7 | Economy Edge Case: promotion-final uses pre-promotion tier multiplier | ✅ |
| B8 | RP hidden from MVP UI; 3 UI reference sites aligned to "经费和运动点数" | ✅ |

**Revised Verdict**: CONCERNS — 33 WARNING remain but none are architecture-blocking.
Verdict changed from FAIL to CONCERNS.
