# Epic: 音频系统

> **Layer**: Presentation (Beta)
> **GDD**: `design/gdd/audio-system.md`
> **Architecture Module**: `AudioSystem` (Feature Contract / Presentation Support)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories audio-system`

## Overview

音频系统是负责 BGM、环境音、音效、短促情绪反馈和基础混音规则的 Beta Presentation 层系统。它只消费上游系统提供的稳定事件和 UI 锚点，映射为温暖、轻快、可关闭的声音表现。权威实现 `AudioManager` 独占 `audio_master_volume`、`audio_bgm_volume`、`audio_sfx_volume`、`audio_ambience_volume` 和 `audio_muted_categories` 的运行时权威，通过 SaveManager 注册的 `audio_state` 扩展 payload 持久化用户偏好。音频系统不得修改任何玩法状态，无资产时静默降级。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0013: Audio Settings & Event Consumption | AudioManager 通过 SaveManager registered durable-state extension 持久化音频偏好；two-phase restore；只消费稳定事件和 normalized UI semantic events | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-audio-001 | 只消费稳定事件，不得修改玩法状态 | ADR-0013 ✅ |
| TR-audio-002 | 播放资格检查（事件有效/资产可用/音量/冷却/焦点） | ADR-0013 ✅ |
| TR-audio-003 | 混音公式：layer_output_volume 层级计算 | ADR-0013 ✅ |
| TR-audio-004 | 音频偏好耐久字段，不影响玩法 | ADR-0013 ✅ |
| TR-audio-005 | 同窗口多事件优先级/合并/压制 | ADR-0013 ✅ |
| TR-audio-006 | 失败/资源不足场景使用低压反馈，禁用危机警报 | ADR-0013 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/audio-system.md` are verified
- `AudioManager` 正确注册 SaveManager callbacks 并通过 two-phase restore
- 无资产场景下静默降级不阻塞玩法

## Next Step

Run `/create-stories audio-system` to break this epic into implementable stories.
