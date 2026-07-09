# ADR-0012: Random Event Settlement Contracts

## Status

Accepted

## Date

2026-06-28

## Last Verified

2026-06-28

## Decision Makers

User, Claude Code, godot-specialist（验证）

## Summary

`design/gdd/random-event-system.md` 已经定义了随机事件系统的核心约束：它只能在合法稳定窗口内触发，不得直接写入资源、球员、设施、比赛、时间或长期认可真值，并且所有一次性事件结果都必须通过稳定 `event_settlement_key` 去重。该 ADR 决定由 `RandomEventManager` 独占随机事件 durable truth，采用 confirmed fact / effect request 路由其他权威系统，并把**排除 `rule_version` 的** `event_settlement_key` 作为随机事件结果的唯一幂等边界；`rule_version` 只作为 evaluation、history 与 migration metadata 保留，不参与 durable settlement identity。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Event Routing / Persistence Boundary / UI Contract |
| **Knowledge Risk** | HIGH — Godot 4.5/4.6 属于知识截点后版本；本 ADR 不依赖新增 API，但持久化与 UI 展示边界必须遵守已验证规则 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`, `docs/engine-reference/godot/modules/ui.md`, `docs/architecture/adr-0002-event-signal-architecture.md`, `docs/architecture/adr-0003-save-load-persistence.md`, `docs/architecture/adr-0007-economy-transaction-framework.md`, `docs/architecture/adr-0010-cross-system-payload-and-settlement-contracts.md`, `docs/architecture/adr-0011-reputation-and-achievement-recognition-framework.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | 验证随机事件待处理状态、历史记录、冷却与去重账本在保存/读档后保持一致；验证 UI 不从本地状态推断事件真值；验证相关保存路径检查 `FileAccess.store_*` 返回值；验证重复 UI 输入不会导致重复结算 |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002（EventBus routing）, ADR-0003（Save/load persistence）, ADR-0007（Economy transaction framework）, ADR-0010（Cross-system payload and settlement contracts）, ADR-0011（Reputation and achievement recognition framework） |
| **Enables** | Random Event Beta implementation stories、Random Event save/load recovery、Random Event → Reputation safe mapping、Random Event UI read-only binding |
| **Blocks** | `TR-random-001` ～ `TR-random-008` 的正式实现 |
| **Ordering Note** | 本 ADR 必须在 Random Event 进入生产实现前被接受 |

## Context

### Problem Statement

`design/gdd/random-event-system.md` 已经定义了随机事件系统的设计边界：它只能在合法稳定窗口中触发，不能直接修改资源、球员、设施、比赛、时间或长期认可真值，并且所有一次性事件结果都必须通过稳定 `event_settlement_key` 去重。

当前缺失的是架构层决策：

- 谁拥有随机事件 durable truth
- 事件结果如何跨系统提交
- 这些结果如何在保存/读档后保持幂等一致
- `target_scope = reputation` 的事件如何与 ADR-0011 对齐，在没有映射时安全 no-op
- UI 如何只读消费随机事件状态，而不在本地重抽、重算或补造结果

如果没有这个 ADR，Random Event 的实现很容易在多个系统之间形成第二套写入路径，破坏当前项目已经建立的单一权威边界。

### Current State

当前项目已经通过 Accepted ADR 建立了清晰的权威边界：TimeManager 拥有合法稳定窗口，SaveManager 是唯一磁盘写入者，EconomyManager、PlayerDevelopment、TownBuilding、MatchCompetition 和 ReputationAchievementManager 都分别拥有各自的 durable truth。

但是 Random Event 仍停留在 GDD 约束层：设计文档已经要求它持有 `pending_random_event_instance`、`recent_random_event_history`、`event_cooldown_state` 和 `processed_event_settlement_keys`，并要求结果通过效果请求包提交给对应权威系统，可当前还没有架构级 ADR 把这些边界正式钉死。

这意味着一旦进入实现，开发者很容易走向三种错误路径：

1. 让 Random Event 直接改写其他系统状态；
2. 让 UI 本地抽取事件、重算资格或补造结果；
3. 让读档恢复依赖“重新抽一遍事件池”而不是恢复 durable truth。

### Constraints

- SaveManager 是唯一磁盘写入者
- TimeManager 拥有合法稳定窗口与阶段推进权
- EconomyManager、PlayerDevelopment、TownBuilding、MatchCompetition、ReputationAchievementManager 已分别拥有各自状态真值
- UI 必须只消费只读 payload
- Random Event 是 Beta 层系统，不得反向扩大 MVP / Core scope
- 系统必须服务低压力长期成长，而不是制造高压危机节奏
- EventBus / signal 是瞬时路由机制，不是 durable state 本身

### Requirements

- 必须有单一模块拥有随机事件 durable truth
- 随机事件只能在合法稳定窗口中评估和触发
- 随机事件不能直接写其他系统真值
- 一次性事件结果必须有稳定 `event_settlement_key`
- 保存/读档后不得重新抽取、重复提交或丢失待处理事件
- `target_scope = reputation` 的未映射结果必须 safe no-op
- UI 必须只绑定权威事件 payload
- durable truth 与跨系统 payload 必须只包含可序列化稳定值，不得写入 Node / Resource / Callable / 运行时对象引用

## Decision

### 1. `RandomEventManager` is the single writer

`RandomEventManager` 是随机事件系统的单一权威写入者，独占以下 durable truth：

- `pending_random_event_instance`
- `recent_random_event_history`
- `event_cooldown_state`
- `processed_event_settlement_keys`

只有 `RandomEventManager` 可以创建、更新、清除这些状态。其他系统只能消费其导出结果，不得直接写入。

### 2. Trigger windows are owned by `TimeManager`

随机事件只能在 TimeManager 已开放的合法稳定窗口中执行 candidate evaluation、event offer 和 result resolution。

合法窗口包括：
- 每日开始后的稳定节点
- 训练结算完成后的稳定节点
- 比赛结算完成后的稳定节点
- 阶段/赛季结算后的稳定节点
- 建设完工确认后的稳定节点

随机事件不得在以下过程中插入：
- 比赛演算中途
- 训练公式处理中
- 经济扣费处理中
- 存档写入中
- 读档恢复未完成时

TimeManager 负责“何时允许触发”，RandomEventManager 只负责“在允许时是否触发、触发什么”。

### 3. Random events submit requests, not truth mutations

随机事件结果只能以 **confirmed fact** 或 **effect request** 的形式提交给权威系统，不得直接写入它们的 durable truth。

允许的结果路由：
- 资源相关 → EconomyManager
- 球员相关 → PlayerDevelopment / SkillTraitSystem
- 设施相关 → TownBuilding
- 比赛相关上下文影响 → MatchCompetition 的合法输入边界
- 长期认可候选事实 → ReputationAchievementManager

禁止的行为：
- 直接修改资源余额
- 直接修改球员属性、状态、技能、特性
- 直接修改设施等级、状态、工期
- 直接推进时间、跳阶段、跳赛季
- 直接解锁成就、增加声望、发放长期奖励

### 4. `event_settlement_key` is the idempotency boundary

一次性随机事件结果的稳定键为：

`event_settlement_key = stable_digest(canonical_join([event_instance_id, selected_option_id, target_scope, target_id], "|"))`

规则：

1. 同一 `event_settlement_key` 只能被处理一次。
2. 若该键已存在于 `processed_event_settlement_keys`，`RandomEventManager` 必须返回幂等 no-op。
3. 命中重复键时，不得：
   - 重复提交 effect request
   - 重复写入事件历史
   - 重复展示结果反馈
4. `stable_digest` 必须基于确定性 canonical string / bytes 生成；不得依赖运行时对象 ID、未排序 Dictionary 遍历顺序、隐式 `hash()` 行为或其他非稳定输入。
5. `rule_version` 只允许作为 evaluation metadata、history metadata 或 migration / compatibility metadata 保留，不得进入 durable settlement identity 的键源。
6. 仅 `rule_version` 变化时，不得生成新的 `event_settlement_key`，也不得因此重新提交 effect request、重写历史、重复展示反馈或重复向 Reputation 系统投递同一 confirmed fact。
7. 如果未来需要版本敏感判定，应在 evaluation / compatibility 层处理，而不是通过改变 durable settlement identity 处理。
8. 该键是随机事件系统自己的结果去重边界，不取代其他系统内部的幂等账本。

### 5. Reputation intake is confirmed-fact only

当随机事件使用 `target_scope = reputation` 时，`RandomEventManager` 只能提交 confirmed fact，不能决定该事实是否转化为长期认可。

规则：

1. 提交给 Reputation 系统的事件事实必须包含稳定事件身份（如 `event_settlement_key`）。
2. 是否映射为声望/成就，由 `ReputationAchievementManager` 决定。
3. 若 `effect_request_type` 未映射、目标非法或版本不兼容，结果必须 safe no-op。
4. 版本敏感判定如果存在，必须发生在 Reputation intake / evaluation 层，并把 `rule_version` 作为 metadata 处理；不得通过改变 `event_settlement_key` 或重新生成 durable settlement identity 处理版本差异。
5. safe no-op 不得要求 Random Event 重结算，也不得阻塞事件本身写入历史与完成结算。

### 6. UI is read-only

展示层只消费权威 payload：

- `random_event_offer_view_payload`
- `random_event_history_view_payload`

UI 不得：
- 本地重抽事件池
- 重算事件是否可触发
- 补造默认选项
- 根据 hover / focus / 本地缓存推断事件是否已处理
- 本地生成事件结果

即使 UI 因重复点击、键盘确认、焦点恢复或界面重建重复发出同一选择请求，最终也必须由 `processed_event_settlement_keys` 保证只结算一次。

### 7. Save/load restores durable event truth only

SaveManager 只持久化随机事件的完整 durable truth，不持久化“待重算”的中间过程，也不持久化 EventBus/Signal 是否曾经发出过。

恢复规则：

1. 若保存时存在待处理事件，恢复后必须回到同一待处理事件实例。
2. 不得在读档后重新抽取事件池以重建事件。
3. 已确认结果必须通过历史、冷却和去重账本恢复。
4. 若 durable 结果存在但缺少必要去重或历史伴随信息，恢复逻辑必须拒绝或修复，而不是重放结果。
5. 恢复语义必须以 durable truth 为准；`rule_version` 或其他 metadata 的版本差异不得触发新的 settlement identity，也不得因此把同一历史结果当作新结果重结算。
6. 保存路径必须检查 Godot 4.4+ `FileAccess.store_*` 的返回值；写入失败时不得把本次随机事件结果视为已安全持久化。

### Architecture

```text
TimeManager (stable trigger windows)
              │
              ▼
    RandomEventManager
      - owns pending instance
      - owns history
      - owns cooldown
      - owns processed_event_settlement_keys
      - evaluates candidate
      - resolves selected option
              │
              ├──► EconomyManager (resource request)
              ├──► PlayerDevelopment / SkillTraitSystem (player request)
              ├──► TownBuilding (facility request)
              ├──► MatchCompetition (legal match-context request)
              └──► ReputationAchievementManager (confirmed fact only)

UI / MainLoop
  - consumes read-only event payloads only
SaveManager
  - persists durable event truth only
```

### Key Interfaces

```gdscript
func build_random_event_offer_view_payload() -> Dictionary[String, Variant]
func build_random_event_history_view_payload() -> Dictionary[String, Variant]
func serialize_random_event_state() -> Dictionary[String, Variant]
func build_event_settlement_key(
    event_instance_id: String,
    selected_option_id: String,
    target_scope: String,
    target_id: String,
) -> String
func build_random_event_evaluation_metadata(
    event_id: String,
    rule_version: String,
    trigger_window: String,
) -> Dictionary[String, Variant]
```

### Implementation Guidelines

- `RandomEventManager` 的 durable truth 与跨系统 payload 只能包含稳定标识和可序列化基础值，不得把 Node、Resource、Callable、运行时 Object 或临时引用写入权威状态。
- `event_settlement_key` 的 durable key source 只包含稳定身份字段；`rule_version`、兼容性标记和其他版本相关信息只能进入 evaluation / history / migration metadata，不得进入 settlement identity。
- EventBus / signal 只负责瞬时事件路由；读档后 UI 与其他消费者必须基于 `RandomEventManager` 恢复出的 durable truth 重建只读视图，而不是依赖“曾经发出过哪些信号”。
- 若一个随机事件结果同时需要提交多个系统，必须先形成统一的 confirmed fact / effect request 集，再按权威系统边界分发，禁止部分系统直接写值、部分系统走请求边界的混搭实现。
- 若未来扩展多阶段事件链、嵌套后果或更复杂的剧情状态机，应通过新 ADR 或 superseding ADR 处理，不在本 ADR 内默认放宽当前边界。

## Alternatives Considered

### Alternative 1: `RandomEventManager` only emits confirmed facts and effect requests

- **Description**: `RandomEventManager` 拥有自己的 durable truth，只向其他系统提交 confirmed fact / request。
- **Pros**: 与现有单一权威边界一致；最容易与 ADR-0010 / ADR-0011 对齐；最适合幂等恢复。
- **Cons**: 需要更严格的契约设计。
- **Estimated Effort**: 中等
- **Rejection Reason**: 未拒绝；这是本 ADR 采用的方案。

### Alternative 2: `RandomEventManager` directly mutates target system state

- **Description**: 随机事件系统直接修改资源、球员、设施、声望等状态。
- **Pros**: 看似实现直接。
- **Cons**: 破坏所有权边界；恢复与测试困难；与现有 registry 和多个 ADR 冲突。
- **Estimated Effort**: 初期较低，后期维护极高
- **Rejection Reason**: 与 Accepted ADR 和 forbidden patterns 冲突。

## Consequences

### Positive

- 随机事件系统获得清晰 durable truth 与所有权边界
- 与 Time、Economy、Player、Town、Reputation 的接口关系保持一致
- 保存/读档后事件状态可以可信恢复
- UI 不会形成第二套事件真值逻辑
- 为 Random Event Beta story 链建立稳定前提

### Negative

- 需要维护 pending/history/cooldown/processed keys 四类状态
- 需要更明确地定义 confirmed fact / effect request payload

### Neutral

- 本 ADR 不改变现有其他权威系统的所有权，只为 Random Event 补上同层级的 durable truth 与路由契约
- `target_scope = reputation` 的事件输入只获得安全摄入边界，不自动意味着任何长期认可映射都会在 Beta 首版启用

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| 同一事件结果被重复处理 | Medium | High | 使用稳定 `event_settlement_key` 与 `processed_event_settlement_keys` 去重；保证 `rule_version` 变化不会生成新的 durable key |
| UI 从本地状态推断事件已处理 | Medium | Medium | 只消费权威 payload，并在验证中覆盖重复输入 / 鼠标 hover / keyboard focus 分离 / 焦点恢复场景 |
| 未映射 reputation 事件误产生长期奖励 | Low | High | 固定 safe no-op 规则，由 Reputation 系统决定映射 |
| evaluation compatibility 与 durable identity 混淆，导致版本变化后重复结算 | Medium | High | 把版本敏感判定限制在 evaluation / compatibility metadata 层，禁止通过改变 settlement identity 处理版本差异 |
| 恢复时 pending instance 与 processed/history 状态脱节 | Medium | High | 增加保存/恢复回归测试，发现非法 partial result 时拒绝或修复 |
| 保存路径默认假设写入成功 | Medium | High | 强制检查 `FileAccess.store_*` 返回值，失败时不得标记 durable success |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | ~0ms dedicated random-event contract cost | ~0ms to negligible — only at stable windows, selection confirmation, and restore boundaries | 16ms |
| Memory | No dedicated Random Event durable state in architecture | Slight increase for pending/history/cooldown/processed-key durable state | 512MB |
| Load Time | Existing save/load baseline without Random Event durable state | Slight increase from restoring event durable state; should remain non-perceptible | <500ms full save load |
| Network (if applicable) | N/A | N/A | N/A |

## Migration Plan

1. 建立 `RandomEventManager` 的 durable state 边界，并把随机事件待处理实例、历史、冷却与结果去重账本收敛到单一写入者。
2. 把随机事件结果统一收敛为 confirmed fact / effect request，并移除任何直接写其他系统真值的实现路径。
3. 接入 TimeManager 稳定窗口与 SaveManager 注册，确保只在合法窗口评估触发、只保存 durable truth。
4. 把 Reputation 目标事件限制为 confirmed fact intake，不在 Random Event 内直接发长期奖励。
5. 添加回归测试覆盖重复提交、待处理事件恢复、已结算事件恢复、仅 `rule_version` metadata 变化、未映射 reputation 事件、以及重复 UI 输入场景。

**Rollback plan**: 若后续发现 Random Event 需要更复杂的多阶段状态机或更细的幂等账本，不回退到 direct mutation 或 UI-only flavor 模型；而是以新的 ADR supersede 本决策，保留当前 single-writer、confirmed fact / request routing 与 durable-only persistence 原则。

## Validation Criteria

- [ ] 同一 `event_settlement_key` 重复提交时，不会重复提交效果、写历史或展示反馈
- [ ] 仅 `rule_version` metadata 变化时，不会生成新的 `event_settlement_key`，也不会重复提交 effect request、confirmed fact、历史或反馈
- [ ] 待处理事件保存并恢复后，事件实例保持一致
- [ ] 已结算事件恢复后，不会重新抽取或重复结算
- [ ] `target_scope = reputation` 且未映射的事件输入会 safe no-op
- [ ] UI 只消费权威事件 payload
- [ ] 所有资源、球员、设施影响都通过对应权威系统路径处理
- [ ] 重复 UI 输入、鼠标 hover / keyboard focus 分离、焦点恢复或界面重建不会导致重复结算
- [ ] 保存路径在相关 durable 写入中检查 `FileAccess.store_*` 返回值

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/random-event-system.md` | Random Event | 随机事件只能在合法稳定窗口触发 | 定义 trigger windows 由 TimeManager 拥有 |
| `design/gdd/random-event-system.md` | Random Event | 随机事件不得直接修改资源/球员/设施/时间/比赛/长期认可真值 | 定义 confirmed fact / effect request routing |
| `design/gdd/random-event-system.md` | Random Event | 必须持久化 pending instance、history、cooldown、processed keys | 定义 RandomEventManager 的 durable truth |
| `design/gdd/random-event-system.md` | Random Event | 一次性事件结果必须具备稳定 `event_settlement_key` | 定义稳定去重边界 |
| `design/gdd/reputation-and-achievement-system.md` | Reputation & Achievement | 未映射的 reputation 事件输入必须 safe no-op | 定义 confirmed-fact-only intake |
| `design/gdd/save-and-load-system.md` | Save & Load | 读档后不得重新抽取、重复结算或丢失待处理事件 | 定义 durable-only save/load boundary |
| `design/gdd/time-and-season-progression-system.md` | Time & Season Progression | 非稳定窗口不能插入随机事件 | 定义 TimeManager-owned trigger window rule |
| `design/gdd/economy-management-system.md` | Economy Management | 资源变化必须走标准经济接口 | 禁止 direct mutation，要求 request routing |
| `design/gdd/player-development-system.md` | Player Development | 球员影响必须由球员系统处理 | 定义 player-targeted request 边界 |
| `design/gdd/town-building-system.md` | Town Building | 设施影响必须由建设系统处理 | 定义 facility-targeted request 边界 |

## Related

- `docs/architecture/adr-0002-event-signal-architecture.md`
- `docs/architecture/adr-0003-save-load-persistence.md`
- `docs/architecture/adr-0007-economy-transaction-framework.md`
- `docs/architecture/adr-0010-cross-system-payload-and-settlement-contracts.md`
- `docs/architecture/adr-0011-reputation-and-achievement-recognition-framework.md`
- `design/gdd/random-event-system.md`
- `design/gdd/reputation-and-achievement-system.md`
