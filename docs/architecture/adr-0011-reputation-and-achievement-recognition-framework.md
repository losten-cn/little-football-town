# ADR-0011: Reputation and Achievement Recognition Framework

## Status

Accepted

## Date

2026-06-01

## Last Verified

2026-06-03

## Decision Makers

User, Claude Code, godot-specialist（验证）

## Summary

`design/gdd/reputation-and-achievement-system.md` 已定义长期认可、声望等级、成就解锁和奖励挂接规则，但实现层此前缺少单一权威写入者、稳定去重边界、奖励耐久化模型与 UI 只读消费契约。该 ADR 决定由 `ReputationAchievementManager` 独占长期认可真值，采用排除 `rule_version` 的稳定 `reputation_settlement_key`、`evaluated`/`processed` 双账本，以及 `pending_reputation_rewards` + `granted_reputation_reward_records` 的耐久奖励模型，并把资源奖励统一路由到 EconomyManager。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / UI Contract / Persistence Boundary |
| **Knowledge Risk** | HIGH — Godot 4.5/4.6 的 UI 焦点、可访问性与 Control 行为属于知识截点后的变更；本 ADR 本身不依赖新增 API，但展示层约束已按引擎参考文档校验 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/deprecated-apis.md`, `docs/architecture/adr-0003-save-load-persistence.md`, `docs/architecture/adr-0007-economy-transaction-framework.md`, `docs/architecture/adr-0010-cross-system-payload-and-settlement-contracts.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | 验证声望/成就 UI 不会把 hover 或 keyboard focus 误当作奖励领取、完成或进度真值；验证读档后双账本、待发放队列与已发放记录以原子结果恢复 |

> **Note**: Godot 4.6 对鼠标悬停与键盘焦点作了更明确分离。长期认可的完成、可领取、已领取与进度显示必须完全来自权威 payload，而不是来自 UI 焦点状态。

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002（Event/signal routing）, ADR-0003（Save/load persistence）, ADR-0007（Economy transaction framework）, ADR-0009（League competition structure）, ADR-0010（Cross-system payload and settlement contracts） |
| **Enables** | Reputation & Achievement 实现故事、主循环与详情页只读绑定、随机事件长期认可映射、长期奖励存档恢复 |
| **Blocks** | Reputation & Achievement 的实现落地，以及 `TR-reputation-001` ～ `TR-reputation-006` 的完整 follow-through |
| **Ordering Note** | 必须先接受本 ADR，再实现奖励挂接、经济入账、UI 绑定与存档字段；否则稳定键、奖励状态与恢复边界会在下游各自漂移 |

## Context

### Problem Statement

声望与成就系统是 Alpha 阶段长期反馈层的核心，但在本 ADR 之前，项目只有 GDD 规则，没有统一的架构级权威说明来回答以下问题：

- 哪个系统拥有 `reputation_total`、等级进度与成就解锁真值
- 如何保证同一长期事件在重放、重进、重复读档后不会重复发放声望或奖励
- 奖励在“待展示/待挂接”与“已完成发放”之间如何持久化，才能避免半结算恢复
- 展示层是否可以本地重算成就完成、可领取状态或进度比例
- 随机事件向长期认可系统投递已确认事实时，未映射输入如何安全 no-op

如果这些边界不先被钉死，实现将很容易在 SaveManager、EconomyManager、主循环 UI 与未来的 Player Management / Match Performance 消费层之间产生重复逻辑与不一致恢复行为。

### Current State

当前已有一个 `Proposed` 状态的部分 ADR 草稿，但它仍保留三个关键缺口：

1. 旧稿把 `rule_version` 放进了 `reputation_settlement_key` 的键源，违背 ADR-0010 对稳定键的要求。
2. 旧稿只明确了 `processed_reputation_settlement_keys`，没有定义 `evaluated_reputation_settlement_keys`，因此无法区分“已判定但无 durable outcome 的稳定 no-op”与“已产出 durable outcome 的处理结果”。
3. 旧稿只有 `pending_reputation_rewards`，没有 `granted_reputation_reward_records`，无法可靠区分“尚未挂接/尚未发放”与“已完成发放且不能回退到队列”的状态。

与此同时，`design/gdd/reputation-and-achievement-system.md`、`design/gdd/save-and-load-system.md` 与 `docs/architecture/requirements-traceability.md` 都已经把该系统视为长期反馈、奖励挂接与恢复可信性的关键一环，因此该草稿必须补全并正式接受。

### Constraints

- 项目使用 Godot 4.6 + GDScript，稳定跨系统 payload 必须遵守 `Dictionary[String, Variant]` 边界规范
- SaveManager 是唯一持久化写入边界，不能恢复半结算状态
- EconomyManager 是资源奖励的唯一标准入账路径，声望系统不得直接改写资源余额
- 展示层必须是只读消费者，不得在 UI 中重算长期认可真值
- 长期反馈必须兼容主循环的低压力节奏，不得因多段弹窗链破坏核心结算体验
- 随机事件、联赛、比赛、球员培养与小镇建设都只能提交“已确认事实”，不得把长期认可判定权分散出去

### Requirements

- 必须有一个单一系统独占长期认可 durable truth
- 稳定 `reputation_settlement_key` 必须只由确定性标量组成，且排除 `rule_version`
- 必须同时支持 `evaluated` 与 `processed` 两类持久化幂等账本
- 必须同时支持待挂接奖励队列与已发放奖励记录，避免队列重放造成重复发放
- 资源奖励必须通过 EconomyManager accredited entry points 路由
- 读档恢复必须接受完整 durable result，拒绝不可能的半结算状态
- UI 必须只消费权威 payload，不能从 hover/focus、本地缓存或局部公式反推真值
- 对未映射的随机事件长期认可请求必须返回幂等 safe no-op

## Decision

由 `ReputationAchievementManager` 作为长期认可层的单一权威写入者，独占耐久真值、稳定键、双账本、奖励挂接状态与只读 payload 生成。

### Part A: Single-Writer Durable Truth

`ReputationAchievementManager` 独占以下 durable truth：

- `reputation_total`
- `reputation_level`
- `reputation_progress_ratio`
- `unlocked_achievement_ids`
- `pending_reputation_rewards`
- `granted_reputation_reward_records`
- `evaluated_reputation_settlement_keys`
- `processed_reputation_settlement_keys`

规则：

1. 只有 `ReputationAchievementManager` 可以累计声望、判定等级提升、解锁成就、创建长期奖励挂接项、标记已发放记录，以及写入上述持久化状态。
2. `reputation_progress_ratio` 可以作为伴随字段持久化，但它不是唯一真值来源。读档恢复时，必须用 `reputation_total`、当前等级与阈值表校验；若不一致，以权威总量和阈值表重算。
3. 上游系统只能提交已确认事实或稳定结算 ID，不能直接写入声望等级、成就状态或奖励结果。

### Part B: Stable Key and Dual-Ledger Idempotency

一次性声望/成就奖励的稳定键定义为：

`reputation_settlement_key = stable_digest(canonical_join([settlement_id, reward_scope, reward_id], "|"))`

规则：

1. 稳定键源只允许包含确定性标量。`rule_version` 只允许作为评价记录、奖励记录或迁移记录的元数据保存，不得进入键源。
2. `evaluated_reputation_settlement_keys` 记录首次被本系统接受并完成判定的稳定键，包括最终产生 safe no-op 的合法判定。
3. `processed_reputation_settlement_keys` 只记录已经产生 durable outcome 的稳定键，例如：声望增加、等级提升、成就解锁、奖励队列创建、奖励发放记录写入。
4. 重放投递、重复读档恢复、或仅 `rule_version` 元数据变化的迁移，都必须先检查 `evaluated_reputation_settlement_keys`；若命中，系统立即返回幂等 no-op。
5. 只有当一次判定真正写入 durable outcome 时，对应稳定键才允许同步写入 `processed_reputation_settlement_keys`。

### Part C: Durable Reward Queue and Grant Records

长期奖励采用“挂接队列 + 发放记录”模型：

- `pending_reputation_rewards`：保存尚未展示、尚未挂接或尚未完成外部发放的 durable 奖励队列
- `granted_reputation_reward_records`：保存已经完成发放或已确认不可再次发放的 durable 奖励记录

规则：

1. 奖励首次产生 durable outcome 时，必须至少进入以下两种 durable 形态之一：
   - 作为 `pending_reputation_rewards` 的待挂接项存在
   - 作为 `granted_reputation_reward_records` 的已发放记录存在
2. 资源型奖励只能通过 EconomyManager 的 accredited entry points（如 `execute_transaction()` 或 `accredit_*` 路径）发放。
3. `ReputationAchievementManager` 不得直接修改资金、AP、RP 或其他经济资源余额。
4. 若某奖励已经写入 `granted_reputation_reward_records`，恢复后不得重新回到 `pending_reputation_rewards`。
5. 若 durable outcome 已存在，但既没有对应的 `pending_reputation_rewards` 项，也没有对应的 `granted_reputation_reward_records` 项，则该存档状态视为非法部分结果，恢复逻辑必须拒绝或修复，而不是隐式重发。

### Part D: Read-Only UI Payload Contract

展示层只消费由 `ReputationAchievementManager` 生成的权威 payload，不得本地决定长期认可真值。

```gdscript
func build_reputation_view_payload() -> Dictionary[String, Variant]:
    return {
        "reputation_total": reputation_total,
        "reputation_level": reputation_level,
        "reputation_progress_ratio": reputation_progress_ratio,
        "pending_reward_count": pending_reputation_rewards.size(),
    }

func build_achievement_view_payload() -> Dictionary[String, Variant]:
    return {
        "unlocked_achievement_ids": unlocked_achievement_ids,
        "pending_reputation_rewards": pending_reputation_rewards,
        "granted_reward_record_count": granted_reputation_reward_records.size(),
    }
```

UI 规则：

1. UI 可以格式化、排序或分页显示这些结果，但不能重算是否完成、是否可领取、当前进度是否达标，或奖励是否已经发放。
2. UI 不得根据 hover、keyboard focus、控件展开状态或本地缓存推断任何长期成长真值。
3. 若展示层需要新字段，必须先扩展权威 payload，再扩展界面，不允许在 UI 层临时拼接推导。

### Part E: Save/Load Boundary

SaveManager 只持久化完整 durable result，不持久化半结算中间态。

```gdscript
func serialize_reputation_state() -> Dictionary[String, Variant]:
    return {
        "reputation_total": reputation_total,
        "reputation_level": reputation_level,
        "reputation_progress_ratio": reputation_progress_ratio,
        "unlocked_achievement_ids": unlocked_achievement_ids,
        "pending_reputation_rewards": pending_reputation_rewards,
        "granted_reputation_reward_records": granted_reputation_reward_records,
        "evaluated_reputation_settlement_keys": evaluated_reputation_settlement_keys,
        "processed_reputation_settlement_keys": processed_reputation_settlement_keys,
    }
```

恢复规则：

1. 可以恢复“没有待处理长期认可结果”的空状态。
2. 可以恢复“包含完整队列/发放/双账本伴随信息”的完成 durable result。
3. 不可以恢复以下部分结果：
   - 已有 durable 声望/成就变化，但缺少对应幂等账本
   - 已有奖励结果，但既不在 `pending_reputation_rewards`，也不在 `granted_reputation_reward_records`
   - `reputation_progress_ratio` 与权威总量和等级阈值明显冲突，却没有重算或修正

### Part F: Confirmed-Fact Intake

`ReputationAchievementManager` 只消费已确认事实。

1. 比赛、联赛、球员培养、小镇建设与时间/赛季推进系统只能提交已确认结果，不提交临时过程。
2. 随机事件系统提交 `target_scope = reputation` 的已确认事实时，必须提供 `event_settlement_key` 或等价稳定结算 ID。
3. 若 `effect_request_type` 没有映射到本系统声明的长期认可来源表，本系统必须返回幂等 safe no-op，不增加声望、不解锁成就、不生成奖励，也不要求随机事件层重结算。
4. 若随机事件事实被映射为长期认可输入，其 `event_settlement_key` 必须直接作为 `settlement_id`，或被稳定地纳入该 `settlement_id` 的来源。

### Architecture

```text
Upstream confirmed facts
  MatchCompetition / LeagueStructure / PlayerDevelopment /
  TownBuilding / RandomEvent / TimeManager
                │
                │ stable settlement IDs + confirmed facts
                ▼
     ReputationAchievementManager
       - evaluate reputation gain
       - resolve level-ups and achievements
       - build reputation_settlement_key
       - update evaluated/processed ledgers
       - create pending rewards or granted records
       - build read-only payloads
          │                │                  │
          │                │                  └──► SaveManager
          │                │                       durable state only
          │                └──► EventBus / UI consumers
          │                     payloads only
          └──► EconomyManager
               accredited reward handoff only
```

### Key Interfaces

```gdscript
func build_reputation_settlement_key(
    settlement_id: String,
    reward_scope: String,
    reward_id: String,
) -> String

func evaluate_recognition_facts(
    settlement_id: String,
    confirmed_facts: Array[Dictionary[String, Variant]],
    rule_version: String,
) -> Dictionary[String, Variant]

func build_reputation_view_payload() -> Dictionary[String, Variant]
func build_achievement_view_payload() -> Dictionary[String, Variant]
func serialize_reputation_state() -> Dictionary[String, Variant]
```

契约说明：

- `settlement_id`、`reward_scope`、`reward_id` 是稳定键源
- `rule_version` 是持久化元数据，不参与稳定键计算
- `evaluate_recognition_facts()` 返回的 durable result 必须与双账本、队列/发放记录一起提交或一起放弃，不能只提交其中一部分

### Implementation Guidelines

- 在任何 EventBus、公有 payload 或存档边界之前，把运行时字典标准化为 `Dictionary[String, Variant]`
- 先检查 `evaluated_reputation_settlement_keys`，再决定是否继续判定或直接 no-op
- 只有 durable outcome 真正落档时，才写入 `processed_reputation_settlement_keys`
- 奖励若尚未完成挂接或外部发放，必须停留在 `pending_reputation_rewards`；一旦完成发放，必须转入 `granted_reputation_reward_records`
- 任何资源奖励都必须通过 EconomyManager，而不是通过本系统直接改写资源值
- 读档恢复时优先以 `reputation_total`、等级阈值表和已解锁成就校验 `reputation_progress_ratio`，不信任陈旧缓存值
- 随机事件的未映射请求必须 safe no-op，不得抛回上游要求重算

## Alternatives Considered

### Alternative 1: 把 `rule_version` 保留在稳定键中，且只维护 processed 账本

- **Description**: 继续沿用旧稿，把 `rule_version` 作为稳定键组成部分，只在产生 durable outcome 时记录一类 `processed_reputation_settlement_keys`
- **Pros**: 账本字段更少，实现表面上更简单
- **Cons**: 规则元数据变化会制造新的稳定键；无法区分“已判定但无 durable outcome”的稳定 no-op 与“已处理完成”的 durable result；与 ADR-0010 冲突
- **Estimated Effort**: 初期更低，后期排查重复发放与迁移问题更高
- **Rejection Reason**: 这会破坏跨系统稳定键契约，也无法表达无产出判定的幂等边界

### Alternative 2: 只有 `pending_reputation_rewards`，不保存已发放记录

- **Description**: 奖励只通过待挂接队列持久化，发放完成后直接从队列移除，不保留 durable grant history
- **Pros**: 存档结构更短，列表管理更直接
- **Cons**: 无法在恢复后可靠区分“已经发放过”与“应重新入队”；外部发放成功后若发生存档边界问题，容易导致重复发放或状态丢失
- **Estimated Effort**: 初期更低，恢复与幂等验证更高
- **Rejection Reason**: 该方案不能满足挂接/发放分离后的 durable truth 需求，也不利于 SaveManager 判断是否出现半结算状态

## Consequences

### Positive

- 长期认可系统得到单一写入权、稳定键、双账本与奖励状态模型
- `rule_version` 不再影响稳定键，规则元数据迁移不会制造重复发放
- Save/load 可以明确接受完整 durable result，拒绝半结算恢复
- 主循环 UI、球员详情 UI 与后续展示层都获得了统一的只读 payload 消费规则
- 随机事件系统拥有了安全 no-op 的长期认可接入边界

### Negative

- 状态模型比旧稿更重，需要维护双账本与挂接/发放两类奖励记录
- 实现时必须严格遵守原子持久化，否则比单字段方案更容易暴露部分结果错误
- 下游 UI、存档与经济实现都必须对齐同一套命名和 durable boundary

### Neutral

- `reputation_progress_ratio` 仍可被持久化，但被降级为伴随字段，而不是唯一真值来源
- 奖励显示层可以继续自由决定视觉样式，但不再拥有任何长期认可判定权

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| UI 仍从 hover/focus 或本地缓存推断奖励状态 | Medium | High | 只暴露权威 payload 字段，并为主循环/详情页添加手动绑定检查 |
| 实现遗漏 `evaluated` 或 `processed` 之一，导致恢复边界错误 | Medium | High | 以双账本为一组耐久契约编写回归测试，覆盖 no-op、durable outcome 与重复提交 |
| `granted_reputation_reward_records` 无限增长 | Low | Medium | 只保存稳定 ID、时间戳与必要元数据，不保存展示冗余；后续若需压缩，通过新 ADR 处理 |
| `reputation_progress_ratio` 在旧存档或迁移后与阈值表不一致 | Medium | Medium | 读档统一按 `reputation_total` 与阈值表复核并重算 companion field |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | 无专门长期认可契约开销 | 近似可忽略；只在稳定结算边界做键计算、账本检查与 payload 组装 | 16ms/frame |
| Memory | 仅基础声望/成就字段 | 小幅增加，用于双账本与奖励队列/发放记录 | 512MB |
| Load Time | 当前 save/load 基线 | 轻微增加，取决于奖励与账本规模；不应出现可感知回归 | 无可感知回归 |
| Network (if applicable) | N/A | N/A | N/A |

## Migration Plan

1. 用本 ADR 的最终命名替换旧稿中的 `rule_version` 键源语义、单账本语义与 queue-only 奖励语义。
2. 在 `ReputationAchievementManager` 实现中落地稳定键构造、双账本、待挂接队列、已发放记录与只读 payload builder。
3. 让 SaveManager、EconomyManager 与 UI 消费层只接入这里定义的 durable result 与 payload 契约。
4. 为重复提交、仅元数据版本变化、随机事件未映射输入、读档恢复与奖励发放路径添加回归测试。

**Rollback plan**: 若后续发现奖励状态模型仍需调整，必须以新 ADR supersede 本决策；任何回退都不得重新把 `rule_version` 放回稳定键源，也不得删除已经形成的 durable processed/granted 历史来“解决”重复发放问题。

## Validation Criteria

- [ ] 同一 `settlement_id + reward_scope + reward_id` 重复提交时，不会重复增加 `reputation_total`、重复解锁成就、重复创建 pending reward 或重复生成 grant record。
- [ ] 仅 `rule_version` 元数据变化时，不会产生新的 `reputation_settlement_key`，也不会重复发放奖励。
- [ ] 读档恢复后，`pending_reputation_rewards`、`granted_reputation_reward_records`、`evaluated_reputation_settlement_keys` 与 `processed_reputation_settlement_keys` 保持一致，且不存在半结算状态。
- [ ] `reputation_progress_ratio` 在读档后与 `reputation_total`、当前等级和阈值表一致；不一致时会被权威重算。
- [ ] 主循环 UI 与其他展示层只消费 `reputation_view_payload` / `achievement_view_payload`，不从 hover/focus 或本地缓存推断真值。
- [ ] 任何资源型长期奖励都通过 EconomyManager 标准入口发放，不存在本系统直接改写资源余额的实现路径。
- [ ] `target_scope = reputation` 但未映射的随机事件已确认事实会返回幂等 safe no-op，不阻塞上游系统。

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/reputation-and-achievement-system.md` | Reputation & Achievement | 同一稳定事件不得重复增加声望、重复解锁成就或重复发放奖励 | 定义单一写入权、排除 `rule_version` 的稳定 `reputation_settlement_key`、`evaluated`/`processed` 双账本，以及挂接/发放奖励状态模型 |
| `design/gdd/save-and-load-system.md` | Save & Load | 已领取奖励标记、待展示奖励状态与长期认可记录必须可恢复 | 定义 `pending_reputation_rewards`、`granted_reputation_reward_records` 与双账本的 durable boundary，并禁止半结算恢复 |
| `design/gdd/main-loop-ui-framework.md` | Main Loop UI | 长期反馈必须作为权威结果挂接到主结算流中，展示层不得重算真值 | 定义 `reputation_view_payload` 与 `achievement_view_payload` 的只读消费规则，以及 hover/focus 非真值原则 |
| `design/gdd/economy-management-system.md` | Economy Management | 声望/成就奖励若包含资源发放，必须走标准经济入账接口 | 强制资源奖励通过 EconomyManager accredited entry points，而不是直接改写资源余额 |
| `design/gdd/random-event-system.md` | Random Event | `target_scope = reputation` 的已确认事实可被映射，否则必须 safe no-op | 定义确认事实摄入、`event_settlement_key` 的稳定引用方式，以及未映射请求的幂等 no-op 规则 |

## Related

- `docs/architecture/architecture.md`
- `docs/architecture/adr-0002-event-signal-architecture.md`
- `docs/architecture/adr-0003-save-load-persistence.md`
- `docs/architecture/adr-0007-economy-transaction-framework.md`
- `docs/architecture/adr-0009-league-competition-structure.md`
- `docs/architecture/adr-0010-cross-system-payload-and-settlement-contracts.md`
- `design/gdd/reputation-and-achievement-system.md`
