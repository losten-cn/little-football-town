# Story 008: 建立数值生命周期元数据与跨系统一致性扫描

> **Epic**: 数值系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/balance-system.md`
**Requirement**: `TR-balance-014`, `TR-balance-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-balance-014`: Numeric lifecycle states: Draft→Tuned→Locked→Revised→Deprecated
- `TR-balance-010`: All shared formula parameters must live in data-driven config, not hardcoded in src/

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0004: Data-Driven Configuration
**ADR Decision Summary**: `BalanceConfig` is the single data-driven source for shared balance constants; CI can scan config and code references to prevent drift and hardcoded gameplay tuning in `src/`.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Integration test or script should be deterministic and safe to run in CI/headless mode.

**Control Manifest Rules (this layer)**:
- Required: All gameplay tuning must load through `ConfigLoader` from typed Custom Resources under `res://config/`; invalid config must block startup.
- Forbidden: Never define gameplay tuning as inline constants in `src/`.
- Guardrail: Config load for all config resources combined must stay under 50ms.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/balance-system.md`, scoped to this story:*

- [ ] Every shared numeric rule has one lifecycle status: `Draft`, `Tuned`, `Locked`, `Revised`, or `Deprecated`.
- [ ] Deprecated rules are not referenced by any valid settlement path.
- [ ] CI scanning catches downstream constants, duplicate boundaries, duplicate multiplier ranges, and formula definitions that bypass this GDD.
- [ ] Shared system output and downstream consumer output match for the same attribute, resource, rating, or win probability inputs.
- [ ] Locked rule changes require lifecycle transition to `Revised` and downstream review before being treated as final.

---

## Implementation Notes

*Derived from ADR-0004 Implementation Guidelines:*

Use `BalanceConfig` and metadata as the authoritative source. The scan should distinguish test fixture constants from forbidden runtime constants and report actionable file/field locations when drift is detected.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: Defining config fields and validation.
- Downstream Core stories: implementing each consumer's business logic.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 数值生命周期元数据必须完整覆盖关键 balance 配置与公式参数
  - Given: 存在 `decay_factor`、`potential_cap_span`、`rating_win_slope`、modifier budget、`resource_buffer_multiplier` 等条目
  - When: 运行一致性扫描
  - Then: 每个条目都具备来源、默认值、合法范围、归属系统、测试链接或 TR 映射
  - Edge cases: 缺少 TR 编号、缺少 owner、缺少范围说明时扫描失败

- **AC-2**: 扫描必须发现 `BalanceConfig`、`ConfigLoader` 与消费者之间的键名/引用不一致
  - Given: 某配置键被重命名，但某个公式消费者仍引用旧键
  - When: 运行跨系统一致性扫描
  - Then: 报告缺失引用、孤儿配置键或陈旧消费者
  - Edge cases: 仅大小写不一致、路径变更、缓存旧配置引用都应被识别

- **AC-3**: 扫描必须阻止 `src/` 中出现违反 ADR-0004 的硬编码玩法数值
  - Given: 某公式脚本在 `src/` 中直接写入 `0.0045`、`1.2`、`15` 等应来自配置的数值
  - When: 运行一致性扫描
  - Then: 扫描失败，并指出具体文件、字段与建议迁移到 `BalanceConfig`/`ConfigLoader`
  - Edge cases: 测试夹具中的常量可豁免；`src/` 中影子常量、重复范围定义、魔法数字都应被标记

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/balance/balance_consistency_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/balance-system/story-001-balance-config-validation.md` — must be DONE
- Unlocks:
  - Downstream work: Downstream Core story readiness checks
