# 架构审查报告

**日期**: 2026-05-17
**引擎**: Godot 4.6 + GDScript (2D Compatibility Renderer)
**模式**: full
**GDDs 审查**: 14 (13 系统 GDD + systems-index)
**ADRs 审查**: 9 (ADR-0001 至 ADR-0009)

---

## 可追溯性总结

| 层级 | 总需求数 | ✅ 已覆盖 | ⚠️ 部分覆盖/不适用 | ❌ 缺口 |
|------|---------|----------|-------------------|---------|
| Foundation | 42 | 36 | 6 | **0** |
| Core | 56 | 54 | 2 | **0** |
| Feature | 14 | 14 | 0 | **0** |
| Presentation | 21 | 4 | 17 (N/A) | **0** |
| Polish | 10 | 0 | 10 (N/A) | **0** |
| **总计** | **143** | **108** | **35** | **0** |

**架构相关需求 (Foundation + Core + Feature)**: 112 个，其中 104 个完全覆盖，2 个部分覆盖。

### 部分覆盖详情

| TR-ID | 需求 | 问题 |
|-------|------|------|
| TR-economy-008 | AP 每日恢复公式 | ADR-0007 覆盖结算但不涉及每日 AP 再生时机细节 |
| TR-town-013 | 最大邻接加成 15.0 的强制上限 | ADR-0008 实时计算加成但未强制执行 GDD 指定的 15.0 上限 |

---

## 覆盖率缺口

**无阻止性缺口。**

8 个 systems-index.md 中的 "Not Started" 系统未出现在 architecture.md 中（声望与成就、随机事件、技能与特性、多周目、商业化、建设与经营 UI、音频、教程与提示），这些系统尚无 GDD，属于预期内缺失。

---

## 跨 ADR 冲突

### 冲突 #1: ADR-0005 vs ADR-0007 — 接口不一致

**类型**: 集成契约
**严重性**: 阻止性
**状态**: ✅ 已修复 (2026-05-17)

**ADR-0005 Part C** 的 `train()` 方法原本调用:
```gdscript
EconomyManager.validate_cost(item.funds_cost, item.ap_cost)
EconomyManager.deduct_cost(item.funds_cost, item.ap_cost)
```

**ADR-0007 Part D** 定义:
```gdscript
func accredit_training_cost(cost_funds: float, cost_ap: float, player_id: int) -> Dictionary
```

**修复**: ADR-0005 `train()` 已更新为使用 ADR-0007 的 `accredit_training_cost()` 单一认证入口，与 EconomyManager 原子性保证一致。

---

## ADR 依赖排序

### 推荐实施顺序 (拓扑排序)

**Foundation (无依赖)**:
1. ADR-0001: Scene Management & Autoload Architecture
2. ADR-0004: Data-Driven Configuration

**依赖 Foundation**:
3. ADR-0002: Event/Signal Architecture + TimeManager
4. ADR-0003: Save/Load Persistence

**Core 第 1 层**:
5. ADR-0005: Player Data Model
6. ADR-0006: Match Simulation Architecture

**Core 第 2 层**:
7. ADR-0007: Economy Transaction Framework
8. ADR-0008: Town Grid & Facility System

**Core 第 3 层**:
9. ADR-0009: League Competition Structure

**无依赖循环。** 所有 ADR 形成有向无环图 (DAG)。

### 未解决的依赖

所有 9 个 ADR 当前均为 Proposed —— 需同时 Accepted 方可开始实施。这不是错误，是正常的批处理状态。

---

## GDD 修订标记

**无需 GDD 修订标记。**

2026-05-16 的 consistency-failures.md 记录的 3 个冲突均已解决：
1. rating_win_slope: 0.015 → 0.0045 (town-building 示例修正)
2. ap_to_funds_weight: player-development 改为引用 economy 权威值 50
3. facility_training_multiplier: 统一为 1.0–1.75

---

## 引擎兼容性

### 审查结果

| 检查项 | 结果 |
|--------|------|
| ADRs 含引擎兼容性章节 | 9 / 9 |
| 废弃 API 引用 | 0 |
| 版本分歧 | 无 — 全部 Godot 4.6 |
| 架构模式一致性 | 全部使用 Godot 4.x 模式 |

### 引擎专家发现

| 发现 | ADR | 详情 |
|------|-----|------|
| Dual-Focus 文档缺失 | ADR-0001, ADR-0002 | Screen 基类和 EventBus 订阅者未提及 Godot 4.6 双焦点系统 |
| 潜在双重分发 | ADR-0002 | `event_fired` 信号 + `_subscribers` 迭代可能导致同一回调触发两次 |
| 加载类型提示 | ADR-0003 | `ResourceLoader.load()` 应使用 `"SaveSnapshot"` 类型提示 |
| Compatibility + D3D12 | 全局 | 无冲突 — `gl_compatibility` 不受 D3D12 默认影响 |

---

## 架构文档覆盖率

| 检查项 | 结果 |
|--------|------|
| systems-index 系统映射 | 20 个系统中 12 个已覆盖；8 个缺失均为 "Not Started" |
| 数据流覆盖 | ✅ 完整 + 战后结算链和赛前快照场景 |
| API 边界 | ✅ Foundation + Core 公共契约完整 |
| 孤立架构 | 无 |

### 开放问题状态

| ID | 问题 | 状态 |
|----|------|------|
| QQ-01 | 存档版本迁移策略 | ✅ ADR-0003 |
| QQ-02 | 小镇网格实现 | ✅ ADR-0008 |
| QQ-03 | RP bank cap | 开放 (Alpha) |
| QQ-04 | 音频触发锚点 | 开放 (Beta) |

---

## 裁决: **CONCERNS**

**理由**: 零架构缺口、无依赖循环、无废弃 API、无 GDD 修订标记。唯一阻止性问题（ADR-0005/ADR-0007 接口不一致）已修复。

### 建议修复 (非阻止)

| # | 操作 | ADR |
|---|------|-----|
| 1 | 在订阅者迭代前加入去重守卫，防止双重分发 | ADR-0002 |
| 2 | `ResourceLoader.load()` 使用 `"SaveSnapshot"` 类型提示 | ADR-0003 |
| 3 | 引擎兼容性章节标注 Dual-Focus 系统交互 | ADR-0001, ADR-0002 |
