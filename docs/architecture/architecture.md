# 足球小镇 — Master Architecture

## Document Status

- **Version**: 2.3
- **Last Updated**: 2026-06-06
- **Engine**: Godot 4.6 + GDScript
- **GDDs Covered**: game-concept.md, systems-index.md, balance-system.md, time-and-season-progression-system.md, save-and-load-system.md, player-development-system.md, match-competition-system.md, economy-management-system.md, town-building-system.md, league-competition-structure-system.md, main-loop-ui-framework.md, player-management-ui.md, match-performance-ui.md, onboarding-system.md, skill-and-trait-system.md, reputation-and-achievement-system.md
- **ADRs Referenced**: ADR-0001 through ADR-0011 (Foundation + Core set with cross-system payload contract layer plus reputation/achievement recognition)
- **Architecture Review**: CONCERNS verdict (2026-06-03) — no Godot 4.6 engine blocker and no Foundation/Core hard gap; remaining gaps are future Random Event, Audio, and Presentation ADR coverage before their production work
- **Technical Director Sign-Off**: 2026-06-06 — APPROVED WITH CONDITIONS (Foundation/Core covered; Feature/Presentation warning ADRs carried forward)
- **Lead Programmer Feasibility**: Skipped — Lean mode

## Engine Knowledge Gap Summary

| Domain | Risk | Relevance |
|--------|------|-----------|
| GDScript (4.5+) | MEDIUM | variadic args, @abstract decorator |
| UI (4.6) | MEDIUM | Dual-focus system for mouse-driven UI |
| Accessibility (4.5) | MEDIUM | AccessKit screen reader for management sim UI |
| 2D / TileMapLayer (4.6) | LOW | Scene tile rotation — may affect town grid rendering |
| Rendering (4.6) | LOW | D3D12 default; Compatibility renderer used for 2D pixel art |
| Physics (4.6) | LOW | Jolt default — no physics in formula-driven game |
| Animation (4.5-4.6) | LOW | IK, BoneConstraint3D — 3D-only, not applicable |

All MEDIUM risk domains are addressable via engine reference docs. No HIGH risk domains impact this 2D management sim.

## System Layer Map

The architecture is ordered by dependency topology. Foundation and Core are implementation-blocking. Feature and Presentation gaps may be carried as warnings unless they affect the active implementation slice.

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION / POLISH LAYER                            │
│  MainLoopUI • PlayerMgmtUI • MatchPerfUI                │
│  TownMgmtUI [Alpha] • Onboarding • TutorialHint [Alpha] │
├─────────────────────────────────────────────────────────┤
│  FEATURE CONTRACT LAYER                                 │
│  LeagueStructure • SkillTraitSystem • ReputationAch     │
│  RandomEvent [WARNING: ADR gap] • Audio [WARNING: ADR]  │
├─────────────────────────────────────────────────────────┤
│  CORE LAYER                                             │
│  TownBuilding • PlayerDevelopment                       │
│  MatchCompetition • EconomyManager                      │
├─────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER                                       │
│  ConfigLoader / BalanceConfig • EventBus                │
│  TimeManager • SaveManager • ScreenManager              │
├─────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                         │
│  Godot 4.6 • GDScript • Compatibility Renderer          │
│  PC (Windows/Linux) • Keyboard/Mouse                    │
└─────────────────────────────────────────────────────────┘
```

### Layer Assignments

| System / Module | Source | Layer | Owns Exclusively | Boundary Rule |
|---|---|---|---|---|
| Godot Platform | technical-preferences.md | Platform | Engine API surface, renderer, file system, input primitives | Project must explicitly use the Compatibility renderer for pixel-art 2D instead of relying on Windows D3D12 defaults. |
| 数值系统 / ConfigLoader | balance-system.md, ADR-0004 | Foundation | Formula constants, tuning tables, config validation | Core systems read validated config; gameplay values are not hardcoded in `src/`. |
| EventBus | ADR-0002 | Foundation | Cross-system signal/event routing | Transmits serializable payloads only; no UI/Core object references cross this boundary. |
| 时间与赛季推进 / TimeManager | time-and-season-progression-system.md, ADR-0002 | Foundation | Timeline position, phase state, match triggers, stable settlement windows | Downstream systems react to scheduled nodes; they do not create competing clocks. |
| 存档与读档 / SaveManager | save-and-load-system.md, ADR-0003 | Foundation | Save slots, version validation, migration, atomic snapshot orchestration | Only stable durable state is saved; half-match and half-settlement runtime state is rejected or delayed. |
| ScreenManager | main-loop-ui-framework.md, ADR-0001 | Foundation | Screen stack, scene transitions, active screen ID | Presentation navigation goes through ScreenManager; gameplay systems never push screens directly. |
| 小镇建设 / TownBuilding | town-building-system.md, ADR-0008 | Core | Facility grid, facility state, construction progress, MVP facility outputs | MVP hard outputs are only `facility_training_multiplier`, `facility_total_maintenance`, and `home_advantage_bonus`. |
| 运动员培养 / PlayerDevelopment | player-development-system.md, ADR-0005 | Core | Player roster, attributes, growth history, training authority | Consumes config/time/town read models; outputs typed player and training payloads. |
| 比赛竞技 / MatchCompetition | match-competition-system.md, ADR-0006 | Core | Match state, lineup validation, simulation, result packet authority | Consumes `match_context` and pre-match snapshots; emits `match_result_packet` or `forfeit_result_packet`. |
| 经济管理 / EconomyManager | economy-management-system.md, ADR-0007 | Core | Funds, research, AP, transaction ledger, settlement grants | Only writer of resource balances; other systems submit requests or confirmed result packets. |
| 联赛与赛事 / LeagueStructure | league-competition-structure-system.md, ADR-0009 | Feature Contract | Schedule, standings, promotion/relegation, season tags | Provides `match_context`; consumes confirmed match packets only. |
| 技能与特性 / SkillTraitSystem | skill-and-trait-system.md, ADR-0010 | Feature Contract | Skill/trait durable outcomes, immutable pre-match read model, feedback lifecycle | Uses stable IDs and typed shallow payloads; no live Resource/Node references in durable contracts. |
| 声望与成就 / ReputationAchievementSystem | reputation-and-achievement-system.md, ADR-0011 | Feature Contract | Reputation state, achievement state, evaluated/processed reward ledgers | Consumes confirmed settlement facts; repeated settlement keys are idempotent no-ops. |
| 随机事件 / RandomEventSystem | random-event-system.md | Feature Contract | Pending event instance, event history, cooldowns, settlement keys | Warning carried: requires ADR before Random Event production work; not blocking Foundation/Core convergence. |
| 音频 / AudioSystem | audio-system.md | Feature Contract / Presentation Support | Audio settings, playback cooldowns, event-to-cue mapping | Warning carried: requires ADR before Audio production work; cues must consume stable events, not infer gameplay truth. |
| 主循环 UI / MainLoopUI | main-loop-ui-framework.md | Presentation | Main shell containers, route vocabulary, `screen_id` / `anchor_id` registry | Presentation consumes read models and owns visual sequencing, not gameplay truth. |
| 球员管理 UI / PlayerManagementUI | player-management-ui.md | Presentation | Roster/detail display state and player UI anchors | Reads PlayerDevelopment and SkillTrait payloads; does not recompute eligibility or effects. |
| 比赛表现 UI / MatchPerformanceUI | match-performance-ui.md | Presentation | Pre-match/live/result display state and match UI anchors | Reads match packets and snapshots; does not recompute match results or skill triggers. |
| 建设与经营 UI / TownManagementUI | town-management-ui.md | Presentation [Alpha] | Town view, budget preview display, facility anchors | Sends requests to Town/Economy/Time; does not deduct funds or mutate facilities directly. |
| 新手引导 / OnboardingSystem | onboarding-system.md | Polish / Presentation Support | Onboarding step state and completion markers | Targets stable MainLoop anchors; missing anchors degrade to text guidance rather than blocking navigation. |
| 教程与提示 / TutorialHintSystem | tutorial-and-hint-system.md | Polish / Presentation Support [Alpha] | Hint cooldowns, seen records, contextual help state | Hints trigger only in stable UI windows after core feedback. |

### Engine Awareness for Foundation/Core

| Domain | Risk | Applies To | Required Handling |
|---|---|---|---|
| GDScript typed containers and Resources | HIGH | SaveManager, EventBus, all Core payload APIs | Stable contracts use `Dictionary[String, Variant]` / typed arrays; untyped runtime containers are normalized before entering typed APIs. |
| FileAccess return values | MEDIUM | SaveManager | Godot 4.4+ `FileAccess.store_*` returns `bool`; save implementations must check write success instead of assuming void success. |
| UI dual-focus | HIGH | ScreenManager and Presentation consumers | Mouse and keyboard focus must be tested separately; focus behavior is not assumed from pre-4.6 Godot knowledge. |
| Rendering backend | HIGH | Platform, MainLoopUI, Town UI | Compatibility renderer must be explicit for the 2D pixel-art management sim; Windows D3D12 default is not the desired baseline. |
| Tile map API | LOW/MEDIUM | TownBuilding if tile rendering is adopted | Use `TileMapLayer`, never deprecated `TileMap`. |

### Warnings Carried Forward

- Random Event ADR gap is tracked and must be closed before Random Event production work.
- Audio ADR gap is tracked and must be closed before Audio production work.
- Presentation-specific ADRs for Main/Player/Match/Town UI are tracked and must be closed before deep UI production expansion.
- Requirements traceability and old story/architecture wording drift are cleanup warnings, not blockers for this topology convergence pass.

## Module Ownership

All exposed gameplay payloads that cross module boundaries must use stable scalar values, stable IDs, `Dictionary[String, Variant]`, and typed arrays. UI modules may copy these into local view models, but they do not own or recompute gameplay truth.

### Foundation Layer

| Module | Owns | Exposes | Consumes | Engine APIs / Risk |
|---|---|---|---|---|
| ConfigLoader / BalanceConfig | `.tres` configuration, formula constants, tuning tables, configuration validation | `get_config(id)`, `get_formula_constant(key)`, `validate_all()` | None | `ResourceLoader`, `Resource`; Resource typed boundaries are HIGH risk under post-cutoff GDScript/resource rules. |
| EventBus | Cross-system event queue, event priority, subscription registry | `emit_event(event_id, payload)`, `subscribe(event_id, callable)` | None | Godot `Signal`; string-based `connect()` is forbidden. |
| TimeManager | Timeline, phase state, season progress, stable settlement windows, match triggers | `advance_day()`, `get_time_state()`, `match_triggered`, `phase_changed` | ConfigLoader, EventBus | `Node` autoload; game logic is node-event driven, not per-frame. |
| SaveManager | Save slots, version validation, migration, atomic snapshots, restore order | `save(slot)`, `load(slot)`, `get_save_metadata()`, `register_system()` | TimeManager, ScreenManager, all authority systems | `FileAccess`, `ResourceSaver`, `ResourceLoader`; Godot 4.4+ FileAccess write return values must be checked. |
| ScreenManager | Screen stack, current `screen_id`, scene transition lifecycle | `push_screen()`, `replace_screen()`, `get_active_screen_id()` | EventBus | `PackedScene.instantiate()`, `Node.add_child()`, `queue_free()`; UI dual-focus is HIGH risk in Godot 4.6. |

### Core Layer

| Module | Owns | Exposes | Consumes | Engine APIs / Risk |
|---|---|---|---|---|
| TownBuilding | 5×5 grid, facility type/level/state/duration, MVP facility outputs | `get_facility_training_multiplier()`, `get_facility_total_maintenance()`, `get_home_advantage_bonus()`, `request_build()` | Economy authorization, TimeManager, ConfigLoader | Pure data plus optional Control rendering; use `TileMapLayer` if tile rendering is adopted. |
| PlayerDevelopment | Roster, player attributes, potential, training history, confirmed growth facts, player status | `get_player_state()`, `train_player()`, `get_roster_view_payload()` | TimeManager, TownBuilding read model, ConfigLoader, SkillTrait read model | `Resource` data tables; typed payload boundaries are HIGH risk. |
| MatchCompetition | Match state machine, lineup legality, simulation, `match_result_packet`, `forfeit_result_packet` | `start_match(match_context)`, `simulate_match()`, `get_match_result_packet()` | PlayerDevelopment, TownBuilding, League match context, pre-match snapshot | Formula/RNG pipeline; UI must not recompute match results. |
| EconomyManager | Funds, research, AP, transaction ledger, resource preview, AP safety grant, recovery floor | `preview_cost()`, `execute_transaction()`, `apply_match_settlement()`, `get_balances()` | Match result packet, Town maintenance, League season tags, ConfigLoader | `Resource` ledger; idempotency keys must be stable. |

### Feature Contract Layer

| Module | Owns | Exposes | Consumes | Engine APIs / Risk |
|---|---|---|---|---|
| LeagueStructure | Schedule, standings, promotion/relegation, season tags, `match_context` | `get_next_match_context()`, `record_result_packet()`, `get_standings_payload()` | TimeManager, match result packet, Economy tags | `Resource`; packet contract is covered by ADR-0009. |
| SkillTraitSystem | Skill/trait durable truth, immutable pre-match snapshot, pending feedback, identity history | `build_pre_match_snapshot()`, `get_skill_trait_read_model()`, `ack_feedback()` | Player confirmed facts, match settlement facts, SaveManager | ADR-0010; typed shallow payloads are HIGH risk and must remain serializable. |
| ReputationAchievementSystem | Reputation, achievements, evaluated/processed ledgers, pending rewards | `evaluate_settlement_fact()`, `get_reputation_view_payload()`, `claim_reward()` | Match, League, Player, Economy, Skill facts; Random Event facts are optional | ADR-0011; Random Event intake remains a warning until its ADR is written. |
| RandomEventSystem | Pending event instance, event history, cooldowns, processed event settlement keys | `offer_event()`, `resolve_event_choice()`, `get_event_view_payload()` | Time stable windows, Player/Economy/Town read models | Warning carried: requires ADR before Random Event production. |
| AudioSystem | Volume settings, mute categories, playback cooldowns, event-to-cue mapping | `play_cue_for_event()`, `set_volume()`, `get_audio_settings()` | Stable UI/Core event labels | Warning carried: requires ADR before Audio production. |

### Presentation / Polish Layer

| Module | Owns | Exposes | Consumes | Engine APIs / Risk |
|---|---|---|---|---|
| MainLoopUI | Main shell, Home/Roster/Match/Town containers, `screen_id` / `anchor_id` vocabulary | `refresh_screen()`, `show_feedback_queue()`, anchor registry | ScreenManager, EventBus, authority read models | `Control`, `Container`; Godot 4.6 dual-focus is HIGH risk. |
| PlayerManagementUI | Player list/detail display state, sort/filter UI, player anchors | `show_player_detail(player_id)`, anchor IDs | PlayerDevelopment read model, SkillTrait read model | `Control`, `ItemList`. |
| MatchPerformanceUI | Match Pre/Live/Result display state, pre-match summary, post-match feedback display | `show_pre_match()`, `show_live_match()`, `show_match_result()` | Match packets, League standings, SkillTrait snapshot | `Control`, `Timer`, `AnimationPlayer`. |
| TownManagementUI | Town screen, budget preview display, facility detail anchors | `show_budget_preview()`, `request_build_command()` | Town read model, Economy preview, Time duration | `Control`; Alpha warning. |
| OnboardingSystem | Onboarding step state, completion markers, current target anchor | `start_step()`, `complete_step()`, `get_current_hint_target()` | MainLoop anchors, SaveManager | `Control` overlay; missing anchors degrade safely to text guidance. |
| TutorialHintSystem | Seen hints, cooldowns, help unlock state, hint preferences | `maybe_show_hint()`, `mark_seen()` | Anchor IDs, authority payloads | `Control`; Alpha warning. |

### Required Topological Order

```text
ConfigLoader
  → EventBus
  → TimeManager
  → SaveManager
  → ScreenManager
  → TownBuilding
  → PlayerDevelopment
  → MatchCompetition
  → LeagueStructure
  → EconomyManager
  → SkillTraitSystem / ReputationAchievementSystem
  → MainLoopUI / PlayerManagementUI / MatchPerformanceUI / TownManagementUI
  → OnboardingSystem / TutorialHintSystem / AudioSystem
```

### Ownership Rules

1. Each authoritative data type has exactly one writer module.
2. EventBus transmits serializable payloads only, never object references.
3. Core systems never import UI modules; UI subscribes to Core events or reads explicit view payloads.
4. Foundation Autoloads form no circular dependencies.
5. Cross-system payloads with durable gameplay meaning must have one canonical writer and read-only consumers per ADR-0010.
6. Presentation modules may label or sequence payloads for display, but may not recompute unlock truth, trait triggers, forced-forfeit validity, resource settlement, or resolved match strength.
7. Random Event, Audio, Presentation ADR gaps, and traceability drift are warnings carried forward, not blockers for Foundation/Core convergence.

## Data Flow

### Frame / Update Path

本项目采用事件驱动主循环。Presentation 可在 `_process()`、`AnimationPlayer`、`Timer` 中处理动画与提示；Core 不靠 `_process()` 推进状态，Feature 也不自建轮询。时间只在玩家确认行动、比赛节点、阶段/赛季结算与读档恢复时由 TimeManager 推进，其余系统通过 EventBus 响应稳定节点。

### Event / Signal Path

数据流严格按 Foundation → Core → Feature → Presentation 单向展开。Foundation 发 `time_*`、`save_completed`、`load_completed` 等调度事件；Core 作为权威写入者结算比赛、资源、球员与小镇；Feature 只消费已确认结果，生成 standings、promotion/relegation、skill/trait durable feedback 等衍生真相；Presentation 只订阅事件或读取权威 payload 刷新 UI，不重算胜率、资源、技能触发或联赛结果。

### Save / Load Path

SaveManager 只在 `Planning`、`Match Trigger`、`Post-Match Settlement`、`Stage Settlement`、`Season Settlement`、`Offseason` 等稳定节点提交快照；`Match In Progress` 与任何半结算态必须延后或拒绝保存。保存时统一采集 `screen_id`、时间状态与各权威系统序列化结果，一次性写成原子快照；权威 blob 必须同时包含 durable companions 与 evaluated/processed settlement keys。读档先校验再迁移，随后按 `TimeManager → TownBuilding → PlayerDevelopment → LeagueStructure → EconomyManager → MatchCompetition` 的依赖顺序恢复；只接受完整 durable settlement result，禁止回放半发奖、半技能判定或半比赛结果。

### Initialization Order

启动顺序固定为 `ConfigLoader → EventBus → TimeManager → SaveManager → ScreenManager`；随后各权威系统完成配置加载、serializer/register 与事件订阅，再挂接 Feature 合同层，最后绑定 MainLoop 与其他 UI。只有首屏路由、赛季容器与必要恢复完成后，才开放玩家操作。

### Post-Match Settlement Chain

`MatchCompetition` 产出带 `settlement_id` 的 `match_result_packet`/`forfeit_result_packet` 后，经 EventBus 先更新 `LeagueStructure` 积分榜与赛季标签，再由 `EconomyManager` 结算赛后资源，由 Player/Skill 契约消费 confirmed facts 生成成长与反馈；`TimeManager` 在核心结算完成后切到 `Post-Match Settlement`，必要时继续触发阶段或赛季结算，最后才允许自动保存。

### Typed Payload / Idempotency Rules

跨系统 payload 必须是浅层、可序列化的稳定契约：标量、稳定 ID、`Dictionary[String, Variant]`、已排序 typed arrays；禁止 Node/Resource/Object 引用、未声明嵌套容器与 runtime Dictionary hash。每个 payload 只有一个 canonical writer，UI 只读不改真相。幂等边界使用 stable settlement key：`settlement_id + player_id + consumer_scope + rule_id`；`rule_version` 只作元数据不入 key。重复投递、重放或读档恢复命中 evaluated/processed keys 时必须直接 no-op。

### Warnings Carried Forward

Random Event ADR、Audio ADR 与 Presentation ADR 覆盖缺口继续作为 warning 保留；它们必须消费现有稳定事件与 payload 契约，但在补齐对应 ADR 前不扩展新的生产级数据流，不阻塞当前 Foundation/Core 收敛。

## API Boundaries

Boundary shorthand: `D = Dictionary[String, Variant]`, `AD = Array[Dictionary[String, Variant]]`. Stable cross-module, EventBus, and save payloads only carry shallow `D` / `AD`; `Variant` boundary data must be normalized before entering typed APIs. Core maintains single writers, and UI consumes read-only payloads.

### Foundation APIs

| Module | Entry Points | Caller Invariants | Module Guarantees |
|---|---|---|---|
| ConfigLoader | `get_balance(key: String) -> float`; `get_table(id: String) -> AD`; `get_save_version() -> int` | Queries are read-only; keys and table IDs are registered in config. | Loads and validates `.tres` data at startup; runtime config is not mutated. |
| EventBus | `emit_event(name: String, payload: D) -> void`; `subscribe(name: String, callback: Callable) -> void`; `unsubscribe(name: String, callback: Callable) -> void` | Payloads must not include `Node`, `Resource`, `Callable`, live `Object`, or unnormalized runtime containers. | Routes named events only; it never becomes a gameplay truth owner. |
| TimeManager | `get_time_state() -> D`; `advance_time(slots: int) -> D`; `register_match_context(context: D) -> void` | Only TimeManager advances time and opens stable settlement windows. | Owns time, phase, match trigger, stage, and season sequencing. |
| SaveManager | `register_system(id: String, serialize: Callable, deserialize: Callable) -> void`; `save(slot: int) -> bool`; `load(slot: int) -> bool`; `get_save_metadata(slot: int) -> D` | Registered systems provide authoritative durable state only; save/load occurs only at stable nodes. | Is the only disk writer; validates version/integrity and restores in dependency order. |
| ScreenManager | `push_screen(path: String, data: D) -> void`; `replace_screen(path: String, data: D) -> void`; `pop_screen() -> void`; `get_active_screen_id() -> String` | Screen data is view context only, not gameplay truth. | Owns screen stack lifecycle, return semantics, and active screen identity. |

### Core APIs

| Module | Entry Points | Caller Invariants | Module Guarantees |
|---|---|---|---|
| TownBuilding | `preview_action(cmd: D) -> D`; `commit_action(cmd: D) -> D`; `get_effects() -> D` | Economy and Time authorization must be satisfied before commit. | Single writer for facilities/grid; only exposes MVP outputs `facility_training_multiplier`, `facility_total_maintenance`, `home_advantage_bonus`. |
| PlayerDevelopment | `get_roster_summary() -> AD`; `get_player_view(player_id: String) -> D`; `train(player_id: String, training_id: String) -> D`; `consume_match_feedback(result: D) -> void` | Long-term player attributes/status are modified only here; training consumes skill read models, not live skill state. | Persists growth outcomes and emits confirmed facts for Match/Skill/UI consumers. |
| MatchCompetition | `start_match(match_context: D, lineup: D, tactic: D) -> void`; `get_match_state() -> D`; `get_result_view() -> D` | Enter only through `time_match_triggered`; AP safety grant is complete; no live skill backfill. | Single writer for `match_result_packet`, `forfeit_result_packet`, `settlement_id`, and snapshot status. |
| EconomyManager | `get_balances() -> D`; `preview_cost(scope: String, args: D) -> D`; `execute_transaction(tx: D) -> D`; `apply_match_day_ap_safety_grant(match_id: String) -> D` | All resource changes go through Economy; transactions include stable IDs. | Single writer for funds/AP/research; ledger is auditable and idempotent. |
| LeagueStructure | `get_match_context(match_id: String) -> D`; `record_result(packet: D) -> void`; `get_standings() -> AD`; `get_season_summary() -> D` | Consumes confirmed result packets only. | Single writer for schedule, standings, promotion/relegation, and season tags. |

### Feature Contract APIs

| Module | Entry Points | Caller Invariants | Module Guarantees |
|---|---|---|---|
| SkillTraitSystem | `build_pre_match_snapshot(lineup_player_ids: Array[String], settlement_id: String) -> D`; `consume_settlement(input: D) -> D`; `ack_feedback(feedback_key: String, surface_id: String) -> void`; `get_player_identity_view(player_id: String) -> D` | Consumes confirmed facts and stable `settlement_id` only. | Single writer for skill/trait state, candidates, identity history, feedback ack, and settlement-key ledgers. |
| ReputationAchievementSystem | `consume_event(input: D) -> D`; `get_reputation_view() -> D`; `get_achievement_view() -> D` | Consumes confirmed upstream events only; UI must not infer completion state. | Single writer for reputation total/level, achievement state, reward records, and idempotency keys. |

### Presentation API

| Module | Entry Points | Caller Invariants | Module Guarantees |
|---|---|---|---|
| MainLoopUI | `bind_home(view: D) -> void`; `present_growth_summary(route_id: String) -> void`; `request_navigation(screen_id: String, args: D) -> void` | Consumes read-only Core/Feature payloads; write actions route to owning systems. | Displays in order: core settlement → skill/trait → reputation/achievement → hints; never recomputes gameplay truth. |

### Godot 4.6 Risk Handling

- `Signal`: use typed `signal.connect(callable)` only; hidden screens must unsubscribe.
- `FileAccess`: Godot 4.4+ `store_*` returns `bool`; failed writes must be checked explicitly.
- `Resource`: `.tres` is valid for config/save resources, but EventBus/save payloads must not carry live `Resource` references; use `duplicate_deep()` for nested resource copies when needed.
- `PackedScene.instantiate()`: only `instantiate()` is valid; ScreenManager owns screen instantiation.
- `Control dual-focus`: Godot 4.6 separates mouse and keyboard focus; screen transitions and load restore must restore focus intentionally.

### Warnings / Future API

- RandomEvent submits confirmed `event_settlement_key` facts and effect request packages; it does not directly modify resources or growth.
- Audio subscribes to EventBus/ScreenManager events read-only and never owns Core truth.
- TutorialHint consumes stable `screen_id`, anchors, and view payloads; it never blocks core settlement.

## ADR Audit

| Area | Result | Notes |
|---|---|---|
| ADR status | 11/11 Accepted | ADR-0001 through ADR-0011 are accepted and remain valid for the current Foundation/Core topology. |
| Required sections | Complete | All accepted ADRs include Engine Compatibility and GDD Requirements Addressed sections. |
| Foundation/Core coverage | Pass | Scene/autoloads, EventBus/TimeManager, SaveManager, ConfigLoader, PlayerDevelopment, MatchCompetition, EconomyManager, TownBuilding, LeagueStructure, and cross-system settlement contracts are covered. |
| Conflicts/cycles | None known | No ADR dependency cycle or layer-ownership conflict is known. |
| Godot 4.6 risk | No blocker | Deprecated API usage is not present in the architecture contracts; post-cutoff risks remain explicitly flagged. |
| Traceability drift | Warning | Random Event, Audio, and Presentation ADR coverage remain future-slice warnings; TR-economy-008 and TR-town-013 wording drift is resolved in the traceability matrix. |

### Traceability Coverage Check

Foundation and Core requirements are sufficiently covered to proceed into Technical Setup / Pre-Production planning with warnings. ADR-0010 closes the implementation-blocking payload and settlement contract gaps for match fallback, pre-match skill/trait snapshots, save/load durability, and read-only UI consumption. ADR-0011 closes the implementation-blocking reputation/achievement recognition contract.

Remaining traceability warnings are not Foundation/Core blockers:

Gate Classification: Random Event, Audio, and future Presentation ADR gaps are future-slice warnings for this gate. They do not block Technical Setup → Pre-Production on the current Foundation/Core scope, but each becomes blocking before its own implementation starts.

| Gap | Status | Resolution Path |
|---|---|---|
| Random Event contracts | Warning | Write Random Event ADR before Random Event production. |
| Audio settings/persistence | Warning | Write Audio ADR before Audio production/settings work. |
| Presentation-specific UI architecture | Warning | Write UI ADRs before deep Main/Player/Match/Town UI production. |
| TR-economy-008 / TR-town-013 wording drift | Cleanup note | RTM wording cleanup only; not a gate blocker. |

## Required ADRs

### Must have before coding starts

No new Foundation/Core ADRs are required before coding starts. ADR-0001 through ADR-0011 cover the current Foundation, Core, and cross-system contract topology.

### Should have before the relevant system is built

| Proposed ADR | Covers | Needed Before |
|---|---|---|
| Random Event Settlement Contracts | RandomEvent authority, `event_settlement_key`, dedupe ledgers, save/load, effect request boundaries. | Random Event production/Beta implementation. |
| Audio Settings Persistence | `audio_*` settings ownership, UI → Audio → SaveManager persistence, read-only audio event consumption. | Audio settings or production audio integration. |

### Can defer as warnings

| Proposed ADR | Covers | Needed Before |
|---|---|---|
| Main UI Framework | Navigation, refresh triggers, focus/anchor rules. | Deep MainLoop UI production. |
| Player UI Architecture | List/detail read-only payloads, sorting/filtering, onboarding anchors. | Deep Player UI production. |
| Match Performance UI | Pre-match/live/post-match display sequencing and no-recompute truth rules. | Deep Match Performance UI production. |

Traceability/review wording drift remains a cleanup warning and should be resolved by the next `/architecture-review`, not by adding blocker ADRs.

## Architecture Principles

1. **Event-driven, not polling**: Core systems communicate exclusively through EventBus signals. No system polls another's state in `_process()`. This keeps the frame budget at near-zero when the player is idle.

2. **Single writer per data type**: Every piece of authoritative game state has exactly one owner. EconomyManager owns resource values. PlayerDevelopment owns player attributes. TimeManager owns the timeline. No other module writes these directly.

3. **Data-driven tuning, not hardcoded values**: All formula constants, balance parameters, and configuration tables live in `.tres` Custom Resources loaded by ConfigLoader at startup. Game designers tune by editing resource files, not by changing code.

4. **UI observes, Core decides**: Presentation layer modules are read-only consumers of Core system state. They subscribe to EventBus signals and refresh display. They never contain game logic or compute formula results.

5. **Foundation is acyclic**: Autoload singletons form a strict dependency hierarchy: ConfigLoader (no deps) → EventBus (no deps) → TimeManager → SaveManager → ScreenManager. No Autoload imports another Autoload that depends on it.

## Open Questions

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| QQ-01 | 存档版本迁移策略 — MVP 是否需要前向兼容，或允许破坏性变更？ | Low | ✅ ADR-0003 已决定（向前兼容 + 版本号迁移） |
| QQ-02 | 小镇网格使用 TileMapLayer 还是纯数据结构 + 自定义 Control 绘制？ | Medium | ✅ ADR-0008 已决定（纯数据结构 + 自定义 Control 绘制） |
| QQ-03 | 经济系统 RP 在 Alpha 接入时的 bank cap 或折算机制 | Medium | WARNING D3 已在 GDD cross-review 记录，Alpha 阶段解决 |
| QQ-04 | 音频系统触发锚点何时从预留升级为完整集成 | Low | Beta 阶段（audio GDD 完成后） |
