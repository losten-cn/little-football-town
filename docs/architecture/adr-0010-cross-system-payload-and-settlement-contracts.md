# ADR-0010: Cross-System Payload and Settlement Contracts

## Status

Accepted

## Date

2026-06-01

## Last Verified

2026-06-02

## Decision Makers

Technical Director, Lead Programmer, Systems Designer

## Summary

The repaired GDD set now depends on several cross-system data contracts that are consistent in prose but not yet normalized at the architecture layer: `forfeit_result_packet`, `pre_match_skill_trait_snapshot`, post-match skill/trait feedback payloads, acknowledgement state, candidate visibility data, migration records, and stable settlement keys. This ADR defines a canonical payload ownership model, read-only UI consumption rules, a normalized match-strength naming map, and deterministic settlement-idempotency boundaries so implementation can proceed without duplicating logic across Core systems and UI layers.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / UI Contract / Persistence Boundary |
| **Knowledge Risk** | LOW — payload governance, typed dictionaries, save/load boundaries; no engine-specific post-cutoff APIs required |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/architecture/architecture.md`, `docs/architecture/adr-0003-save-load-persistence.md`, `docs/architecture/adr-0006-match-simulation-architecture.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Validate that typed payload normalization is applied consistently at runtime boundaries before shipping |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (Event/signal routing), ADR-0003 (Save/load persistence), ADR-0005 (Player data model), ADR-0006 (Match simulation architecture), ADR-0007 (Economy transaction framework), ADR-0009 (League competition structure) |
| **Enables** | Skill/trait implementation stories, forced-match fallback implementation, registry ownership cleanup, architecture review for post-patch contracts |
| **Blocks** | Cross-system implementation of skill/trait settlement feedback and forced-match fallback wiring |
| **Ordering Note** | Must be accepted before implementation begins on the repaired cross-system contracts introduced by the 2026-06-01 cross-review PASS WITH CONCERNS result |

## Context

### Problem Statement

The 2026-06-01 cross-GDD re-review cleared the prior blocker set and allowed Systems Design to advance to Technical Setup. However, the remaining concerns all concentrate at one boundary: several active cross-system payloads exist only as aligned prose contracts across design docs, without a single architecture-level authority describing who writes them, who may read them, how they are named, what part is persisted, and where idempotent settlement begins and ends.

Without this ADR, implementation is likely to drift in one of four ways:

1. Core systems duplicate payload assembly logic and diverge.
2. UI layers begin recomputing gameplay truth instead of consuming authoritative payloads.
3. Save/load and migration logic persist durable outcomes inconsistently or replay transient settlement state.
4. Match-strength naming and settlement-key generation fragment across systems, producing hidden inconsistency bugs.

### Current State

The architecture document already states that EventBus transports data-only payloads and that Core systems do not import UI modules. Existing ADRs also define:

- SaveManager as the sole persistence writer
- Match result packets as downstream settlement inputs
- Economy settlement as a transaction authority
- LeagueStructure as a standings/result consumer

What is still missing is a contract-level ADR for the new repaired interactions introduced by the recent GDD pass:

- `match_day_ap_safety_grant`
- `forfeit_result_packet`
- `pre_match_skill_trait_snapshot`
- `pending_skill_trait_feedback`
- `feedback_ack`
- `candidate_progress_record`
- `trait_cooldown_state`
- `player_identity_history_entry`
- `skill_trait_migration_record`
- stable `settlement_key`

### Constraints

- Godot 4.6 + GDScript; payloads should stay compatible with the project’s typed dictionary rules
- UI is mouse-driven, information-dense, and must stay read-only with respect to gameplay truth
- Save/load stores durable state only; half-settlement states are explicitly non-restorable
- Cross-system contracts must be testable via headless runners and not depend on scene-only assumptions
- Match and skill/trait settlement must remain deterministic and idempotent across reloads and repeated delivery attempts
- Registry and traceability artifacts exist and should remain the authoritative follow-through targets after architecture acceptance

### Requirements

- Every cross-system payload must have exactly one authoritative writer
- UI modules must consume read-only payloads and must not recompute gameplay truth
- Match-side strength naming must be normalized relative to balance-side formula inputs
- Stable settlement keys must be generated from deterministic scalar inputs only
- Save/load must persist durable result state and processed settlement keys, but never transient evaluation state
- Registry and traceability artifacts must be able to reference these contracts after acceptance

## Decision

### Part A: Canonical Payload Ownership

Each cross-system payload contract has one authoritative writer, zero or more read-only consumers, and one persistence boundary if durable.

| Payload / Contract | Authoritative Writer | Read-Only Consumers | Persisted? |
|--------------------|----------------------|---------------------|------------|
| `match_day_ap_safety_grant` | EconomyManager (triggered by TimeManager authority) | MainLoopUI, Onboarding | No — resolved as a transaction outcome, not a standalone long-term state blob |
| `forfeit_result_packet` | MatchCompetition | LeagueStructure, EconomyManager, MatchPerfUI, TimeManager follow-through | Yes — through durable match/result history paths |
| `match_result_packet` | MatchCompetition | EconomyManager, LeagueStructure, MatchPerfUI, MainLoopUI | Yes |
| `pre_match_skill_trait_snapshot` | MatchCompetition-owned wrapper over skill/trait read model | MatchPerfUI | No — consumed for the live match context, not a post-reload authority; post-match history may persist scalar companion summaries such as `skill_trait_snapshot_status` and `team_skill_trait_summary` result fields |
| `pending_skill_trait_feedback` | PlayerDevelopment / skill-trait authority | MainLoopUI, PlayerMgmtUI, MatchPerfUI | Yes |
| `feedback_ack` | PlayerDevelopment / skill-trait authority | MainLoopUI, PlayerMgmtUI | Yes |
| `candidate_progress_record` | PlayerDevelopment / skill-trait authority | PlayerMgmtUI | Yes |
| `trait_cooldown_state` | PlayerDevelopment / skill-trait authority | MatchCompetition (read-only eligibility), PlayerMgmtUI | Yes |
| `player_identity_history_entry` | PlayerDevelopment / skill-trait authority | PlayerMgmtUI, MainLoopUI result summaries | Yes |
| `skill_trait_migration_record` | SaveManager migration boundary | PlayerDevelopment on restore/migrate | Yes |
| evaluated stable settlement keys | SaveManager persistence + skill/trait authority evaluation log | PlayerDevelopment / settlement restore checks | Yes — includes no-op evaluations |
| processed stable settlement keys | SaveManager persistence + skill/trait authority durable outcome log | PlayerDevelopment / settlement restore checks | Yes — outcome keys only |

Rules:

1. Only the authoritative writer may construct or mutate a payload’s durable truth.
2. Consumers may reformat or label a payload for display, but must not recompute its truth conditions.
3. If a payload is persisted, SaveManager stores the writer’s durable result form, not a UI-expanded derivative.

### Part B: UI Read-Only Contract

Presentation modules consume snapshots, explanations, labels, acknowledgement flags, and visibility stages only.

UI modules may display:

- pre-match snapshot summaries
- candidate visibility stage, blocked reason, and read-only identity summary text
- post-match skill/trait explanation payloads
- feedback acknowledgement state
- identity history entries
- opponent strength labels or summary badges

UI modules must not compute:

- whether a skill unlocks
- whether a trait triggers
- whether a candidate has crossed a hidden threshold
- what action a player should take to optimize a candidate
- whether a forced forfeit is valid
- the actual `team_match_strength`
- whether a settlement event should be deduplicated

```gdscript
# Presentation rule: consume, do not decide
func bind_match_pre(snapshot: Dictionary[String, Variant], strength_label: String) -> void:
    _render_snapshot(snapshot)
    _render_strength_label(strength_label)

func bind_skill_feedback(
    feedback_payload: Dictionary[String, Variant],
    feedback_lifecycle: Dictionary[String, Variant]
) -> void:
    _render_feedback(feedback_payload)
    _render_feedback_lifecycle(feedback_lifecycle)
```

If a UI screen needs a new display field, that field must be added to the authoritative payload by the owning Core system rather than recomputed locally.

For Alpha skill/trait feedback, first-display ownership is unique per feedback key. `first_surface_id` may only be `match_result` or `main_loop`; Player Detail may show history, reread entries, and acknowledgement state, but it must not render a feedback record as a first-time new prompt.

### Part C: Match-Strength Naming Map

Three related concepts must be distinguished explicitly:

| Name | Layer | Meaning |
|------|-------|---------|
| `self_team_rating` / `opponent_team_rating` | Balance-facing formula input | Comparative rating inputs used to compute base win probability |
| `team_match_strength` | MatchCompetition resolved output | The side-specific strength value after lineup, position weights, chemistry, and allowed facility effects are aggregated |
| strength label / matchup badge | UI display-only derivative | Localized display summary derived from resolved strength comparison |

Architecture rule:

1. Balance owns comparative probability math.
2. MatchCompetition owns aggregation from lineup context into `team_match_strength`.
3. UI owns only labeling and visual framing of the resolved comparison.

```gdscript
func build_match_strength_inputs(team_profile: Dictionary) -> Dictionary[String, Variant]:
    return {
        "team_match_strength": _compute_team_match_strength(team_profile),
        "chemistry_factor": team_profile.get("chemistry_factor", 1.0),
        "facility_rating_bonus": team_profile.get("facility_rating_bonus", 0.0),
    }

func build_win_probability_inputs(home_strength: float, away_strength: float) -> Dictionary[String, Variant]:
    return {
        "self_team_rating": home_strength,
        "opponent_team_rating": away_strength,
    }
```

This mapping prevents duplicate “team power” fields from drifting across balance, match, and UI layers.

### Part D: Stable Settlement Key Contract

Stable settlement keys are the idempotency boundary for skill/trait unlock, upgrade, trait trigger records, acknowledgement facts, and durable feedback creation.

They must be generated from canonical scalar fields only:

- `settlement_id`
- `player_id`
- `consumer_scope`
- `rule_id`

`rule_version` is persisted as result metadata, but it must not enter the settlement-key source. Rule migration may update metadata or write migration records; it must not cause an already-consumed settlement fact to receive a new idempotency key.

```gdscript
func build_settlement_key(
    settlement_id: String,
    player_id: String,
    consumer_scope: String,
    rule_id: String,
) -> String:
    var canonical: String = "%s|%s|%s|%s" % [
        _normalize_key_scalar(settlement_id),
        _normalize_key_scalar(player_id),
        _normalize_key_scalar(consumer_scope),
        _normalize_key_scalar(rule_id),
    ]
    return _stable_digest(canonical)
```

Forbidden patterns:

- hashing runtime `Dictionary` instances directly
- hashing unordered `Variant` containers directly
- allowing UI or migration layers to generate alternate key formats
- embedding display-only fields in the settlement key input
- embedding `rule_version` in the settlement key input
- silently replacing null key fields with empty strings or defaults

A settlement key is evaluated once per player/rule/consumer scope. Replays, duplicate event delivery, reload recovery, or rule-version migration must check the evaluated-key log first; if the key exists, the system returns an idempotent no-op. Only evaluations that produce durable outcomes are also written to the processed-key log.

### Part E: Save/Load Boundary for Settlement State

SaveManager persists durable settlement outcomes and the idempotency logs needed to prevent replay, not transient evaluation scratch state. Skill/trait state changes, candidate deltas, cooldown deltas, pending feedback, identity history entries, acknowledgement seeds, evaluated keys, and processed keys produced by one settlement must be committed as one durable settlement result.

Persisted as a completed durable result:

- unlocked/leveled skill state
- candidate progress state
- trait cooldown state
- pending feedback payloads
- feedback acknowledgement state
- identity history entries
- migration records
- evaluated stable settlement keys
- processed stable settlement keys
- match-result scalar companions for skill/trait display history, such as `skill_trait_snapshot_status` and locked `team_skill_trait_summary` result values

Not persisted as a restorable in-progress state:

- half-resolved skill evaluation pass
- transient rule-scoring scratch data
- durable state changes without the matching processed key
- durable state changes without required feedback/history/candidate/cooldown deltas from the same result
- UI-local expansion of explanation payloads
- incomplete settlement queues waiting for re-execution
- `pre_match_skill_trait_snapshot` as a post-reload authority for applying or reconstructing skill/trait effects

```gdscript
func serialize_skill_trait_contract_state() -> Dictionary[String, Variant]:
    return {
        "owned_skills": owned_skills,
        "candidate_progress_record": candidate_progress_record,
        "trait_cooldown_state": trait_cooldown_state,
        "pending_skill_trait_feedback": pending_skill_trait_feedback,
        "feedback_ack": feedback_ack,
        "player_identity_history": player_identity_history,
        "evaluated_settlement_keys": evaluated_settlement_keys,
        "processed_settlement_keys": processed_settlement_keys,
        "skill_trait_migration_record": skill_trait_migration_record,
    }
```

Restore rule:

- restore may accept a completed durable settlement result
- restore may accept absence of a durable settlement result
- restore must reject partial results where durable skill/trait truth exists without its evaluated key, processed key when an outcome exists, feedback, history, candidate, or cooldown companions required by that result

Migration rule:

- migration may add fields, rename fields through explicit mapping, or normalize formats
- migration may update rule-version metadata through explicit records
- migration may not recompute player growth outcomes or replay settlement side effects

### Part F: EventBus and Contract Envelope Rules

EventBus transmits payload envelopes, not live object references.

Envelope rules:

1. Stable cross-system payloads must be top-level shallow typed dictionaries with explicitly sorted shallow record arrays.
2. Record arrays may contain scalar fields, stable ID arrays, and `Dictionary[String, String]` label args only; undeclared nested Dictionary/Array values are invalid.
3. Resource, Node, Object, Callable, Variant blob, live runtime container references, and runtime Dictionary hash order are forbidden in event and save payloads.
4. Consumer systems may copy payloads into local view models, but only the writer mutates source truth.
5. UI-facing payloads should prefer scalar, label-ready, or enum-ready fields over exposing internal computation structure.

```gdscript
EventBus.emit("match_completed", {
    "result_packet": result_packet,
    "settlement_id": settlement_id,
})

EventBus.emit("skill_trait_feedback_ready", {
    "player_id": player_id,
    "pending_skill_trait_feedback": feedback_payload,
    "feedback_ack": ack_payload,
})
```

### Architecture Diagram

```text
┌──────────────────────────────────────────────────────────────────┐
│                        Core Writers                              │
│                                                                  │
│  TimeManager ──triggers──► EconomyManager ──writes──► AP grant   │
│       │                                                          │
│       └────match node────► MatchCompetition ──writes──► result   │
│                                      │                 packets    │
│                                      │                            │
│                                      └──consumes read model──►    │
│                                         skill/trait snapshot      │
│                                                                  │
│  PlayerDevelopment / skill-trait authority ──writes──► feedback, │
│  candidate state, cooldowns, history, ack state                  │
└──────────────────────────────────────────────────────────────────┘
                    │                       │
                    │ EventBus payloads     │ SaveManager durable boundary
                    ▼                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                  Read-Only Consumers / Persistence               │
│                                                                  │
│  MatchPerfUI / PlayerMgmtUI / MainLoopUI / Onboarding            │
│    - render snapshots, labels, explanations, ack state           │
│    - never recompute gameplay truth                              │
│                                                                  │
│  SaveManager                                                     │
│    - persists durable outcomes                                   │
│    - stores evaluated and processed settlement keys              │
│    - migrates schema, not gameplay outcomes                      │
└──────────────────────────────────────────────────────────────────┘
```

### Implementation Guidelines

- Add payload builders at Core ownership boundaries rather than building ad hoc dictionaries inside UI code.
- Normalize any untyped runtime dictionary into `Dictionary[String, Variant]` before crossing stable system boundaries.
- Prefer versionable payload field names that describe durable meaning rather than current widget layout.
- When adding a new UI field, update the authoritative payload contract first, then registry/traceability, then presentation.
- Treat settlement idempotency as a data contract, not a convenience optimization.

All inbound runtime `Dictionary` / `Variant` containers must be normalized before crossing a durable, event, or public payload boundary. Stable contracts never expose untyped dictionaries as their authoritative interface.

```gdscript
func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
    var typed_dictionary: Dictionary[String, Variant] = {}
    if value is Dictionary:
        var source: Dictionary = value as Dictionary
        for key: Variant in source.keys():
            typed_dictionary[String(key)] = source[key]
    return typed_dictionary
```

## Alternatives Considered

### Alternative 1: Let Each Consumer Build Its Own View Model

- **Description**: Match, save, and UI systems each derive the fields they need from upstream raw state.
- **Pros**: Low initial coordination cost; fewer payload definitions upfront.
- **Cons**: High drift risk, duplicated logic, inconsistent replay behavior, and UI recomputation of gameplay truth.
- **Estimated Effort**: Lower initially, higher long-term.
- **Rejection Reason**: Directly conflicts with the repaired GDD boundary goals and would likely recreate the cross-review concerns during implementation.

### Alternative 2: Move All Cross-System Contracts Into a Single Global Mega-Payload

- **Description**: Emit one broad view-model dictionary shared by all systems and screens.
- **Pros**: Fewer named payload types; easy to inspect in logs.
- **Cons**: Blurs ownership, makes versioning brittle, encourages over-fetching, and couples unrelated systems tightly.
- **Estimated Effort**: Medium.
- **Rejection Reason**: Violates single-writer ownership and would make future migrations and testing harder.

## Consequences

### Positive

- Implementation gets a single authority map for repaired cross-system contracts.
- UI remains read-only and less likely to drift from gameplay truth.
- Save/load durability and idempotent settlement boundaries become explicit and testable.
- Future registry and traceability updates can reference architecture-level contract names rather than only free-text GDD wording.

### Negative

- Adds an additional ADR before implementation can begin on the repaired contracts.
- Forces some up-front payload design work that may feel slower than ad hoc dictionary passing.
- Requires disciplined follow-through to keep registry and traceability artifacts synchronized.

### Neutral

- Existing accepted ADRs remain valid; this ADR narrows and connects them rather than replacing them.
- Some contracts may eventually move into typed Resource or helper classes, but the ownership rules in this ADR remain the same.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Payload field sprawl reappears in UI code | Medium | High | Add payload builders in Core systems and reject UI-side recomputation during review |
| Settlement keys are implemented inconsistently across systems | Medium | High | Centralize key builder utility and persist processed keys through SaveManager |
| Registry/traceability lags behind accepted architecture | High | Medium | Make registry/TR updates a required follow-up task before architecture review |
| Match-strength aliasing remains ambiguous in code | Medium | Medium | Adopt the naming map in this ADR before match implementation resumes |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | ~0ms dedicated contract cost | ~0ms to negligible — payload assembly at event boundaries only | 16ms |
| Memory | Minimal ad hoc dictionaries | Slight increase from durable payload state already required by GDD | 512MB |
| Load Time | Existing save metadata path | No material change; durable fields already required | <500ms full save load |
| Network (if applicable) | N/A | N/A | N/A |

## Migration Plan

1. Add Core-side payload builders and canonical settlement key utility.
2. Update the affected system implementations to emit/consume the canonical payloads and naming map.
3. Extend registry and traceability artifacts with the accepted contract names and ownership.
4. Add regression tests for duplicate settlement delivery, reload after pending feedback, and forced-match fallback packet persistence.

**Rollback plan**: If the contract set proves over-scoped, keep the ownership rules and settlement-key rules, then split the payload taxonomy into smaller ADRs without changing existing writer authority.

## Validation Criteria

- [ ] No UI module recomputes skill unlock, trait trigger, forced forfeit validity, or resolved team-match strength.
- [ ] Repeating the same settlement event after reload does not duplicate durable skill/trait outcomes, including when only `rule_version` metadata changed.
- [ ] Save/load restores pending feedback, acknowledgement state, candidate progress, cooldowns, identity history, and processed settlement keys without replay drift.
- [ ] Save/load rejects partial skill/trait durable results where state changes exist without their matching processed key, feedback, history, candidate, or cooldown companions required by that result.
- [ ] Player Detail never renders Alpha skill/trait feedback as a first-time new prompt; first display is limited to Match Result or Main Loop.
- [ ] Match-strength naming in code follows the balance input → match resolved output → UI label map defined in this ADR.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/match-competition-system.md` | Match Competition | Forced formal matches must resolve legally through recommended lineup, out-of-position fill, or `forfeit_result_packet` | Defines `forfeit_result_packet` writer authority, consumer set, and durable contract boundary |
| `design/gdd/time-and-season-progression-system.md` | Time & Season Progression | Formal match nodes must not deadlock on insufficient AP | Clarifies `match_day_ap_safety_grant` trigger/write separation and read-only UI explanation boundary |
| `design/gdd/skill-and-trait-system.md` | Skill & Trait | Settlement results must be deterministic, idempotent, atomically durable, and keyed by stable settlement identity | Defines canonical settlement-key inputs, excludes `rule_version` from the key source, forbids non-deterministic key generation, and requires completed durable settlement results rather than partial restores |
| `design/gdd/save-and-load-system.md` | Save & Load | Durable skill/trait state, feedback, migration, and processed keys must survive save/load | Defines what is persisted versus what is transient and non-restorable |
| `design/gdd/player-management-ui.md` | Player Management UI | UI shows candidate visibility, blocked reasons, identity history, and ack state without recomputing logic | Defines read-only UI consumption rule and authoritative payload ownership |
| `design/gdd/match-performance-ui.md` | Match Performance UI | Match Pre uses locked snapshots and Match Result explains skill/trait outcomes without live recomputation | Defines pre-match snapshot and post-match explanation payload boundaries |
| `design/gdd/main-loop-ui-framework.md` | Main Loop UI | Main loop consumes automatic grants and feedback ordering without blocking primary flow | Defines payload envelope and read-only consumption expectations |
| `design/gdd/league-competition-structure-system.md` | League Structure | Match outcomes, including forfeits, must remain valid downstream league inputs | Defines `forfeit_result_packet` as a durable result form consumable by LeagueStructure |

## Related

- `docs/architecture/architecture.md`
- `docs/architecture/adr-0003-save-load-persistence.md`
- `docs/architecture/adr-0006-match-simulation-architecture.md`
- `docs/architecture/adr-0007-economy-transaction-framework.md`
- `docs/architecture/adr-0009-league-competition-structure.md`
