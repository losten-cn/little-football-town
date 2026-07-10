# Story 001: AudioManager 最小 Auth + Save 集成

> **Epic**: 音频系统
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic + Integration
> **Estimate**: S (2-3 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/audio-system.md`
**Requirement**: `TR-audio-001`, `TR-audio-004`
**ADR Governing Implementation**: ADR-0013 (Audio Settings & Event Consumption)

**Engine**: Godot 4.6 + GDScript | **Risk**: LOW

## Acceptance Criteria

- [ ] **AC-1**: `AudioManager` 为场景实例化节点 (class_name)，不是 Autoload。独占运行时权威字段: `audio_master_volume` (0.0-1.0), `audio_bgm_volume`, `audio_sfx_volume`, `audio_ambience_volume`, `audio_muted_categories: Array[String]`
- [ ] **AC-2**: `serialize() → Dictionary[String, Variant]` 和 `deserialize(data: Dictionary[String, Variant]) → void` 契约注册到 SaveManager
- [ ] **AC-3**: Two-phase restore: SaveManager 提供耐久值 → AudioManager 在 runtime node/bus mapping 就绪后才 apply
- [ ] **AC-4**: 不加载实际音频资产——所有音量字段为纯数据，`_apply_volumes()` 为空壳（后续 story 接入 Godot AudioServer）
- [ ] **AC-5**: 耐久偏好不得影响 gameplay state——音量/静音字段独立于经济/球员/比赛状态

## Implementation Notes

- ADR-0013: "AudioManager must register audio preference serialize/deserialize callables with SaveManager"
- Two-phase restore: `deserialize()` stores values → `_apply_after_tree_ready()` applies after scene tree init
- 音量字段 clamped [0.0, 1.0]
- No actual AudioServer calls — this is a data-only stub

## Out of Scope

- 实际音频资产加载/播放
- BGM/AudioStreamPlayer 管理
- 事件到音频映射 (audio event-to-cue mapping)
- UI settings 面板 (handled by HUD story)

## QA Test Cases

- **AC-1**: AudioManager 字段初始化
  - Given: AudioManager.new()
  - When: 读取 5 个权威字段
  - Then: master=1.0, bgm=1.0, sfx=1.0, ambience=1.0, muted_categories=[]

- **AC-2**: serialize/deserialize round-trip
  - Given: 设置 master=0.5, bgm=0.8, muted=["sfx"]
  - When: serialize → deserialize 到新实例
  - Then: 所有值精确恢复

- **AC-3**: Two-phase restore
  - Given: AudioManager 已添加进 tree
  - When: deserialize(data) → await process_frame
  - Then: _apply_after_tree_ready() 被调用，音量字段正确

- **AC-4**: 无音频资产依赖
  - Given: AudioManager 实例化
  - When: 调用 _apply_volumes()
  - Then: 无错误/崩溃 (空壳实现)

- **AC-5**: 独立于 gameplay state
  - Given: AudioManager 已修改音量
  - When: 检查 EconomyManager/PlayerDevelopment 状态
  - Then: 无变化 (音频字段不进入 gameplay payload)

## Test Evidence

**Story Type**: Logic + Integration
**Required evidence**: `tests/unit/audio/auth_stub_test.gd`

## Dependencies

- Depends on: None (内存数据 stub，不依赖音频资产)
- Unlocks: Story 002 (音频播放 + BGM 管理)
