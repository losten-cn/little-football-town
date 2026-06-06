# 音频系统评审记录

## Review — 2026-06-03 — Verdict: APPROVED WITH WARNINGS
Scope signal: M
Specialists: none (`lean` mode)
Blocking items: 0 | Recommended: 4 | Warnings/flags: 2
Summary: 音频系统 GDD 已具备 8/8 必需章节，核心边界清楚，符合低压力、温暖小镇和不改变玩法结算的设计目标。本次评审将 town-building 反向依赖缺口与主循环 UI 音量入口归属缺口记录为 warning/flag，而非继续阻塞方案收敛；后续实现前或相关 GDD 更新时补齐即可。
Prior verdict resolved: First review

### Warning / Flag Items
1. `design/gdd/town-building-system.md` 尚未反向声明音频系统消费建设开始、升级确认、完工等反馈语义。
2. `design/gdd/main-loop-ui-framework.md` 已声明 UI 音效触发，但尚未声明主音量、BGM、SFX、Ambience 或静音入口的最小设置归属。

### Non-blocking Recommendations
1. 明确 `audio_event_eligibility > 0` 即表示可播放，避免被误解为概率或评分阈值。
2. 为“稳定展示节点”补最小枚举或引用口径，避免各系统自行解释。
3. 说明 `special_stinger_volume` 属于内容/配置调参而非玩家偏好持久化字段，或明确它是否归入 SFX 设置。
4. 为低压力音频审核补 QA checklist，将“危机警报”“刺耳失败音”“限时任务感”等禁止样式转成可核对项。
