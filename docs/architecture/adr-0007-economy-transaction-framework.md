# ADR-0007: Economy Transaction Framework

## Status

Accepted

## Date

2026-05-17

## Last Verified

2026-05-17

## Decision Makers

Technical Director, Godot Specialist, Game Designer

## Summary

The economy-management GDD defines a triple-resource economy (经费 Funds / 运动点数 AP / 研究点数 RP), a transaction framework requiring `execute_transaction()` as the sole resource mutation path, stage/season/post-match settlement rules, safety floors (AP ≥ 1, debt allowed), and warning thresholds. The architecture assigns EconomyManager as a Core system. But no ADR defines: the Transaction class structure, the atomic execution contract, the settlement pipeline triggered by EventBus time events, the transaction history audit trail, or the serialization contract. This ADR defines: a `Transaction` RefCounted class with resource delta validation, an `EconomyManager` that owns the balances and executes all mutations through `execute_transaction()`, settlement handlers wired to EventBus signals, and a save contract that persists balances + last-N transaction history.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core — Economy Transaction Framework |
| **Knowledge Risk** | LOW — pure GDScript math, validation, Dictionary arrays; no engine-specific APIs |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (EventBus signals: `economy_balance_changed`, `economy_warning_triggered`; subscribes to `time_stage_settled`, `time_season_ended`, `match_completed`), ADR-0003 (SaveManager registration), ADR-0004 (EconomyConfig), ADR-0006 (MatchResultPacket for post-match settlement) |
| **Enables** | ADR-0008 (TownBuilding deducts facility costs via EconomyManager), ADR-0009 (LeagueStructure awards prize money via EconomyManager) |
| **Blocks** | Town building implementation — cannot deduct facility costs without accredited transaction path |
| **Ordering Note** | Must be Accepted before ADR-0008 (TownBuilding) can be Accepted |

## Context

### Problem Statement

The economy-management GDD defines Core Rule 2: "任何下游系统不得直接修改三种资源的当前值" — all resource changes must go through the accredited transaction framework. It defines three settlement stages, warning thresholds, and safety floors. But no ADR defines: (1) what a Transaction object looks like in code, (2) how `execute_transaction()` guarantees atomicity and validation, (3) how settlement is wired to EventBus time/match events, (4) the transaction history structure, (5) the serialize/deserialize contract for SaveManager.

### Constraints

- Godot 4.6 + GDScript — pure computation, no rendering
- Three resource types: Funds (float), AP (float), RP (float, hidden in MVP)
- Funds can go negative (debt); AP has a floor of 1.0; RP has a floor of 0
- Transaction execution must be atomic — partial application is forbidden
- All resource mutations must be auditable via transaction history
- Settlement stages fire in deterministic order

### Requirements

- `execute_transaction()` is the sole entry point for any resource change
- Pre-validation rejects transactions that would violate resource floors
- Warning thresholds trigger `economy_warning_triggered` events
- Transaction history retained for the current season (last ~200 entries)
- Settlement pipeline processes match_result → income, stage settlement → revenue cycle, season settlement → overview

## Decision

### Part A: Transaction Class

```gdscript
# src/core/transaction.gd
class_name Transaction
extends RefCounted

enum Type { INCOME, EXPENSE, TRANSFER }

var id: int = 0
var type: Type = Type.INCOME
var funds_delta: float = 0.0   # Positive = gain, negative = cost
var ap_delta: float = 0.0
var rp_delta: float = 0.0
var reason: String = ""
var source_system: String = ""  # Which system initiated: "match", "town", "league", "settlement"
var timestamp: int = 0
var metadata: Dictionary = {}   # Extra context: match_id, facility_id, etc.

func to_dict() -> Dictionary:
    return {
        id = id, type = type, funds_delta = funds_delta, ap_delta = ap_delta,
        rp_delta = rp_delta, reason = reason, source_system = source_system,
        timestamp = timestamp, metadata = metadata,
    }

static func from_dict(data: Dictionary) -> Transaction:
    var t := Transaction.new()
    t.id = data.get("id", 0); t.type = data.get("type", Type.INCOME)
    t.funds_delta = data.get("funds_delta", 0.0); t.ap_delta = data.get("ap_delta", 0.0)
    t.rp_delta = data.get("rp_delta", 0.0); t.reason = data.get("reason", "")
    t.source_system = data.get("source_system", ""); t.timestamp = data.get("timestamp", 0)
    t.metadata = data.get("metadata", {})
    return t
```

### Part B: EconomyManager Core

```gdscript
# src/core/economy_manager.gd
class_name EconomyManager
extends Node

var funds: float = 0.0
var action_points: float = 0.0
var research_points: float = 0.0

var _transaction_log: Array[Transaction] = []
var _next_tx_id: int = 1
var _warning_cooldown: Dictionary = {}  # Per-threshold cooldown tracking

func _ready() -> void:
    SaveManager.register_system("economy", _serialize, _deserialize)
    EventBus.subscribe("time_stage_settled", _on_stage_settled)
    EventBus.subscribe("time_season_ended", _on_season_ended)
    EventBus.subscribe("match_completed", _on_match_completed)

func execute_transaction(tx: Transaction) -> Dictionary:
    # Validate
    var validation := _validate_transaction(tx)
    if not validation.valid:
        return {success = false, error = validation.error}

    # Record pre-state
    var pre_funds := funds; var pre_ap := action_points; var pre_rp := research_points

    # Apply (atomic — all-or-nothing)
    tx.id = _next_tx_id; _next_tx_id += 1
    tx.timestamp = Time.get_unix_time_from_system()
    funds += tx.funds_delta
    action_points += tx.ap_delta
    research_points += tx.rp_delta

    # Enforce floors
    action_points = maxf(action_points, 1.0)
    research_points = maxf(research_points, 0.0)

    _transaction_log.append(tx)
    if _transaction_log.size() > 200:
        _transaction_log.pop_front()

    # Emit balance change
    EventBus.emit("economy_balance_changed", {
        resource_type = "all",
        funds_delta = tx.funds_delta, ap_delta = tx.ap_delta, rp_delta = tx.rp_delta,
        new_funds = funds, new_ap = action_points, new_rp = research_points,
        reason = tx.reason, source_system = tx.source_system,
    })

    # Check warnings
    _check_warnings()

    return {success = true, tx_id = tx.id}

func _validate_transaction(tx: Transaction) -> Dictionary:
    var cfg: EconomyConfig = ConfigLoader.economy_config

    # AP floor check
    if action_points + tx.ap_delta < cfg.ap_floor:
        return {valid = false, error = "ap_below_floor"}

    # RP floor check
    if research_points + tx.rp_delta < cfg.rp_floor:
        return {valid = false, error = "rp_below_floor"}

    # Funds debt ceiling check (optional safety net)
    if funds + tx.funds_delta < cfg.funds_debt_ceiling:
        return {valid = false, error = "funds_below_debt_ceiling"}

    return {valid = true}

func _check_warnings() -> void:
    var cfg: EconomyConfig = ConfigLoader.economy_config
    for warning: Dictionary in _get_active_warnings(cfg):
        var key: String = warning.type
        if _warning_cooldown.get(key, 0) < Time.get_unix_time_from_system():
            _warning_cooldown[key] = Time.get_unix_time_from_system() + cfg.warning_cooldown_seconds
            EventBus.emit("economy_warning_triggered", {
                warning_type = warning.type,
                current_value = warning.current_value,
                threshold = warning.threshold,
            })

func _get_active_warnings(cfg: EconomyConfig) -> Array[Dictionary]:
    var warnings: Array[Dictionary] = []
    if funds < cfg.funds_warning_low:
        warnings.append({type = "funds_low", current_value = funds, threshold = cfg.funds_warning_low})
    if action_points < cfg.ap_warning_low:
        warnings.append({type = "ap_low", current_value = action_points, threshold = cfg.ap_warning_low})
    if funds < 0:
        warnings.append({type = "debt", current_value = funds, threshold = 0.0})
    return warnings
```

### Part C: Settlement Pipeline

Three settlement handlers wired to EventBus:

```gdscript
func _on_match_completed(payload: Dictionary) -> void:
    var settlement_id: String = String(payload.get("settlement_id", ""))
    var result: Dictionary = payload.result_packet
    var cfg: EconomyConfig = ConfigLoader.economy_config

    # Base reward
    var match_income: float = cfg.base_match_income
    if result.home_score > result.away_score:
        match_income *= cfg.win_multiplier
    elif result.home_score == result.away_score:
        match_income *= cfg.draw_multiplier
    else:
        match_income *= cfg.loss_multiplier

    var tx: Transaction = _make_tx("match_income", match_income, cfg.match_ap_reward,
                                   0.0, "赛后收入")
    tx.metadata["settlement_id"] = settlement_id
    execute_transaction(tx)

func _on_stage_settled(payload: Dictionary) -> void:
    var cfg: EconomyConfig = ConfigLoader.economy_config
    var stage: int = payload.stage_number
    var stage_rp: float = cfg.stage_research_point_award * stage
    execute_transaction(_make_tx("stage_rp", 0.0, 0.0, stage_rp,
                                 "阶段%d结算 — 研究点数" % stage))

func _on_season_ended(payload: Dictionary) -> void:
    var cfg: EconomyConfig = ConfigLoader.economy_config
    # Season-end grants
    execute_transaction(_make_tx("season_grant", cfg.season_funds_grant,
                                  cfg.season_ap_grant, 0.0, "赛季%d结算" % payload.season_number))
```

### Part D: Accredited Entry Points

External systems call `execute_transaction()` through typed entry points. EconomyManager validates the caller's authority.

Because EconomyManager is a scene-instantiated Core authority rather than a Foundation Autoload, cross-system callers must receive its stable reference through gameplay-root injection or a scene-owned service container/runtime registry. Registered direct calls to `execute_transaction()` or any `accredit_*` entry point must not rely on implicit global class access, hardcoded `NodePath`, or arbitrary scene-tree search.


```gdscript
## Called by MatchCompetition after Settlement Handoff
func accredit_match_reward(match_result: Dictionary) -> Dictionary:
    var tx := _make_tx("match_reward", ...)
    tx.source_system = "match"
    return execute_transaction(tx)

## Called by TownBuilding for facility costs
func accredit_facility_cost(cost_funds: float, cost_ap: float, facility_id: int) -> Dictionary:
    var tx := _make_tx("facility", -cost_funds, -cost_ap, 0.0, "设施 #%d 费用" % facility_id)
    tx.source_system = "town"
    tx.metadata = {facility_id = facility_id}
    return execute_transaction(tx)

## Called by PlayerDevelopment for training costs
func accredit_training_cost(cost_funds: float, cost_ap: float, player_id: int) -> Dictionary:
    var tx := _make_tx("training", -cost_funds, -cost_ap, 0.0, "球员 #%d 训练" % player_id)
    tx.source_system = "player"
    return execute_transaction(tx)

func _make_tx(reason: String, funds_delta: float, ap_delta: float,
              rp_delta: float, description: String) -> Transaction:
    var tx := Transaction.new()
    tx.type = Transaction.Type.INCOME if funds_delta >= 0 else Transaction.Type.EXPENSE
    tx.funds_delta = funds_delta; tx.ap_delta = ap_delta; tx.rp_delta = rp_delta
    tx.reason = reason; tx.source_system = "economy"
    return tx
```

### Part E: Serialization Contract

```gdscript
func _serialize() -> Dictionary:
    return {
        funds = funds, action_points = action_points, research_points = research_points,
        next_tx_id = _next_tx_id,
        recent_transactions = _serialize_log(),
    }

func _deserialize(data: Dictionary) -> void:
    funds = data.get("funds", 0.0)
    action_points = data.get("action_points", 0.0)
    research_points = data.get("research_points", 0.0)
    _next_tx_id = data.get("next_tx_id", 1)
    _transaction_log.clear()
    for entry: Dictionary in data.get("recent_transactions", []):
        _transaction_log.append(Transaction.from_dict(entry))

func _serialize_log() -> Array[Dictionary]:
    var arr: Array[Dictionary] = []
    for tx: Transaction in _transaction_log:
        arr.append(tx.to_dict())
    return arr
```

### Part F: Resource Ownership

| Resource | Owner | Write Path | Consumer Systems |
|----------|-------|-----------|------------------|
| Funds (经费) | EconomyManager | `execute_transaction()` only | MatchCompetition, TownBuilding, PlayerDevelopment, MainLoopUI |
| AP (运动点数) | EconomyManager | `execute_transaction()` only | PlayerDevelopment, TownBuilding, MainLoopUI |
| RP (研究点数) | EconomyManager (hidden MVP) | `execute_transaction()` only | PlayerDevelopment (future) |

Post-match settlement transactions must preserve the canonical `settlement_id` from the `match_completed` envelope in transaction metadata or equivalent processed-key bookkeeping so replay, duplicate delivery, and restore paths can remain idempotent.

### Architecture Diagram

```
┌──────────────────────────────────────────────────────────┐
│                  EconomyManager (Core Node)               │
│  ┌────────────────────────────────────────────────────┐  │
│  │ Balances: funds, action_points, research_points     │  │
│  │ execute_transaction(tx) → {success, tx_id}         │  │
│  │ accredit_match_reward(result)                      │  │
│  │ accredit_facility_cost(funds, ap, facility_id)     │  │
│  │ accredit_training_cost(funds, ap, player_id)       │  │
│  │ _validate_transaction() → {valid, error}           │  │
│  │ _check_warnings() → emits economy_warning_triggered │  │
│  └────────────┬───────────────────────────────────┬───┘  │
│               │                                   │       │
│  ┌────────────┴──────────────┐   ┌────────────────┴────┐ │
│  │ WRITERS (accredited paths)│   │ EVENT SUBSCRIPTIONS   │ │
│  │ ┌───────────────────────┐ │   │ ┌──────────────────┐ │ │
│  │ │ MatchCompetition      │ │   │ │ match_completed  │ │ │
│  │ │ TownBuilding          │ │   │ │ time_stage_settled│ │ │
│  │ │ PlayerDevelopment     │ │   │ │ time_season_ended│ │ │
│  │ └───────────────────────┘ │   │ └──────────────────┘ │ │
│  └───────────────────────────┘   └─────────────────────┘ │
│                                                           │
│  ┌────────────────────────────────────────────────────┐   │
│  │ Transaction Log (last 200, serialized in save)     │   │
│  │ [tx#1, tx#2, ..., tx#200]  — full audit trail     │   │
│  └────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

## Alternatives Considered

### Alternative 1: Direct Balance Mutation (No Transaction Framework)

- **Description**: Each Core system directly modifies `EconomyManager.funds` / `.action_points` via property access
- **Pros**: Simplest API, fastest path, zero overhead
- **Cons**: Violates GDD Core Rule 2 explicitly. No audit trail. No validation. Systems could set values below floors. Debugging "who spent what" requires code grep, not a transaction log.
- **Rejection Reason**: Direct mutation makes it impossible to enforce floors, track spending, or audit resource changes. The GDD explicitly requires `execute_transaction()` as the sole mutation path.

### Alternative 2: Event Sourcing

- **Description**: Every resource change is an immutable event appended to a log; current balance is a projection of the log
- **Pros**: Full replay capability, perfect audit trail, time-travel debugging
- **Cons**: Every balance query recomputes from log (or requires cached projection). Overengineered for 3 resources with ~200 transactions per season. Adds ~20KB of log data that must be replayed on load.
- **Rejection Reason**: The GDD does not require replay or event sourcing semantics. A simple running balance + bounded transaction log provides auditability without the projection complexity. If future requirements demand full replays, the Transaction log already contains all necessary data — the migration is additive.

### Alternative 3: Per-Resource Manager (Separate FundsManager, APManager)

- **Description**: Each resource type has its own manager node with independent transaction handling
- **Pros**: Separation of concerns, per-resource validation rules
- **Cons**: Settlement stages often involve multiple resources (e.g., match reward grants funds + AP). Splitting forces cross-manager coordination or a coordinator class. Adds complexity for 3 simple float balances.
- **Rejection Reason**: Three resources managed by one node is simpler and more cohesive. The transaction framework handles per-resource validation without needing separate classes.

## Consequences

### Positive

- Single mutation path (`execute_transaction()`) guarantees all resource changes are validated and auditable
- Transaction log provides a complete season-level audit trail for debugging and balance analysis
- Warning thresholds fire `economy_warning_triggered` events — UI can react without polling
- Settlement pipeline is decoupled: EconomyManager subscribes to EventBus, not directly coupled to MatchCompetition/TownBuilding
- Serialization is clean: balances + log → restore

### Negative

- Every resource change requires constructing a Transaction object — overhead for high-frequency operations
- `accredit_*` entry points must be manually kept in sync with caller authentication needs
- Transaction log is bounded at 200 entries — historical transactions beyond the window are lost
- Warning cooldown requires fine-tuning to avoid alert spam during settlement cascades

### Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| System bypasses `execute_transaction()` and directly writes `funds` | Low | High — unvalidated mutations | GDScript can't enforce private fields. Use naming convention (`_funds` → `funds` is intentional public-read). Code review gate: grep for `= ` on balance fields outside EconomyManager. |
| Transaction log exceeds memory budget | Very Low | Low | 200 entries × ~200 bytes = 40KB. Well within budget. |
| Warning cooldown prevents important repeated warnings | Low | Medium — player misses critical info | Cooldown is per-warning-type, not global. Three independent timers for funds_low, ap_low, debt. |
| Settlement cascades (multiple time events in one frame) cause sequential balance_changed emissions | Low | Low | Each settlement stage is a separate `execute_transaction()` call → separate `economy_balance_changed` event. Priority queue handles ordering. |

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `economy-management-system.md` | Core Rule 2: "任何下游系统不得直接修改三种资源的当前值" | `execute_transaction()` is the sole mutation path; balance fields are read-only to external systems |
| `economy-management-system.md` | Core Rule 3: 经费可以负债，AP ≥ 1 底线，RP ≥ 0 底线 | `_validate_transaction()` enforces AP floor (1.0), RP floor (0.0), and funds debt ceiling |
| `economy-management-system.md` | Core Rule 6: 系统必须对外提供 `balance_type`, `balance_change`, `new_balance` | `economy_balance_changed` event payload includes funds_delta, ap_delta, rp_delta, and new_* values |
| `economy-management-system.md` | Warning thresholds: 经费 < 警戒线、AP < 警戒线、负债状态 | `_check_warnings()` emits `economy_warning_triggered` with type, current_value, and threshold |
| `economy-management-system.md` | Settlement: 比赛后收入、阶段结算RP、赛季结算综合 | Three settlement handlers wired to EventBus: `_on_match_completed`, `_on_stage_settled`, `_on_season_ended` |
| `economy-management-system.md` | AC: "任何未经认证的调用方不得成功执行经费或点数的增减操作" | `accredit_*` entry points with `source_system` tracking; each external system has a dedicated accredited path |
| `balance-system.md` | Resource buffers, multipliers, warning thresholds | All tuning values read from `EconomyConfig` via ConfigLoader |

## Performance Implications

- **CPU**: `execute_transaction()` — 3 float additions + 3 floor checks + log append = <0.01ms. Settlement pipeline: 3 transactions per settlement × <0.01ms = negligible.
- **Memory**: 3 float balances = 24 bytes. Transaction log: 200 entries × ~200 bytes = 40KB. Total: <50KB.
- **Load Time**: Deserializing 200 transactions from save: <5ms. Balances restoration: immediate.
- **Network**: Not applicable — single-player.

## Migration Plan

Not applicable — no existing economy system. This is the first implementation.

## Validation Criteria

- [ ] `execute_transaction()` with valid funding applies deltas and returns `{success = true, tx_id = N}`
- [ ] `execute_transaction()` with AP delta below floor returns `{success = false, error = "ap_below_floor"}`
- [ ] Three sequential `execute_transaction()` calls produce three unique ascending tx_ids
- [ ] `economy_balance_changed` event fires after each successful transaction with correct deltas
- [ ] `economy_warning_triggered` fires when funds drop below warning threshold
- [ ] Warning cooldown prevents duplicate warning within cooldown window
- [ ] `_on_match_completed()` correctly applies win/draw/loss multipliers to match income
- [ ] Transaction log bounded at 200 — 201st transaction pushes out the oldest
- [ ] Roundtrip: set balances + execute 5 transactions → `_serialize()` → `_deserialize()` → balances match, log matches
- [ ] External system cannot modify `funds` directly — code review: all balance changes go through `execute_transaction()` or `accredit_*`

## Related

- ADR-0002: Event/Signal Architecture — `economy_balance_changed`, `economy_warning_triggered` signals
- ADR-0003: Save/Load Persistence — EconomyManager registers with SaveManager
- ADR-0004: Data-Driven Configuration — EconomyConfig provides all tuning parameters
- ADR-0006: Match Simulation Architecture — MatchResultPacket consumed for post-match settlement
- ADR-0008: Town Grid & Facility System — calls `accredit_facility_cost()`
- `design/gdd/economy-management-system.md` — authoritative design for resource rules
- `design/gdd/balance-system.md` — resource buffers and thresholds
