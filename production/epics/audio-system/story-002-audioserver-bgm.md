# Story 002: AudioServer 集成 + BGM 切换

> **Epic**: 音频系统
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: M (3-4 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/audio-system.md`
**Requirement**: `TR-audio-002`, `TR-audio-003`, `TR-audio-005`
**ADR Governing Implementation**: ADR-0013

**Engine**: Godot 4.6 + GDScript | **Risk**: MEDIUM (AudioServer API post-cutoff)

## Acceptance Criteria

- [ ] **AC-1**: `_apply_volumes()` 调用 Godot `AudioServer` —— 设置 Master/BGM/SFX/Ambience bus 音量
- [ ] **AC-2**: BGM 根据 game state 切换 —— 日常经营/比赛进行/赛后结算 各对应不同 BGM bus (stub 即可，不加载实际音频文件)
- [ ] **AC-3**: SFX 播放资格检查 —— 冷却/音量 > 0 / 聚焦允许，不合格时静默跳过
- [ ] **AC-4**: 无音频资产时静默降级 —— 不崩溃，不阻塞玩法
- [ ] **AC-5**: 同窗口多音频事件优先级合并/压制 —— 比赛哨声优先于环境音

## Implementation Notes

- Godot 4.6 AudioServer: `AudioServer.get_bus_index(bus_name)`, `AudioServer.set_bus_volume_db()`, `AudioServer.set_bus_mute()`
- 验证 API 签名对照 `docs/engine-reference/godot/`
- BGM bus: Master → BGM → SFX → Ambience (4 bus hierarchy)
- 无资产降级: `AudioStreamPlayer` 在 stream==null 时 catch error 并 log warning

## Out of Scope

- 实际 .ogg/.wav 音频文件加载
- 动态音乐编排
- 语音/解说

## QA Test Cases

- **AC-1**: 音量应用
  - Given: set_master_volume(0.5)
  - When: _apply_volumes()
  - Then: AudioServer master bus volume == linear2db(0.5)

- **AC-2**: BGM 切换
  - Given: game_state="match_live"
  - When: set_game_state("match_live")
  - Then: BGM bus active, others muted/ducked

- **AC-3**: SFX 冷却
  - Given: sfx "goal" 刚播放（在冷却中）
  - When: request_sfx("goal")
  - Then: 返回 false，无音频播放

- **AC-4**: 无资产降级
  - Given: AudioStreamPlayer.stream == null
  - When: 尝试播放
  - Then: 打印 warning，不崩溃

- **AC-5**: 优先级压制
  - Given: 环境音频正在播放
  - When: 比赛哨声触发
  - Then: 环境音被 duck/暂停，哨声优先

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/audio/audioserver_integration_test.gd`

## Dependencies

- Depends on: Story 001 (AudioManager save integration)
- Unlocks: Story 003 (SFX event-to-cue mapping)
