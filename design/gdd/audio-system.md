# 足球小镇：音频系统

> **Status**: Approved  
> **Author**: 用户 + Claude  
> **Last Updated**: 2026-06-03  
> **Implements Pillar**: 低压力长期成长、轻度足球经营、像素小镇养成  
> **Source**:
> - `design/gdd/game-concept.md`
> - `design/gdd/systems-index.md`
> - `design/gdd/match-competition-system.md`
> - `design/gdd/match-performance-ui.md`
> - `design/gdd/town-building-system.md`
> - `design/gdd/random-event-system.md`
> - `design/gdd/main-loop-ui-framework.md`
> - `E:\code\game\game-design\04-足球小镇-音效与音乐设计.md`

## Overview

音频系统是《足球小镇》中负责 BGM、环境音、音效、短促情绪反馈和基础混音规则的 Beta Presentation 层系统。它不拥有比赛、训练、建设、随机事件、资源、声望、时间推进或 UI 流程规则，也不新增奖励、任务、签到、宝箱、危机警报或压力提示；它只消费比赛竞技系统、比赛表现 UI、小镇建设系统、随机事件系统和主循环 UI 框架提供的稳定事件、界面锚点与情绪语义，将这些事件映射为温暖、轻快、可关闭且不抢占核心反馈的声音表现。音频系统的目标是在不制造焦虑、不改变玩法结算的前提下，强化“小镇在运转、球队在成长、比赛有起伏、失败也能继续”的低压力经营氛围。

## Player Fantasy

玩家在音频系统中应感受到：“我的小镇是有声音、有生活感的，我的球队成长和比赛起伏被温和地回应着。”白天的小镇音乐应让玩家觉得轻松、怀旧、阳光；训练和建设音效应像小镇日常中自然发生的小动作；比赛音频应有进球、扑救、终场等情绪峰值，但不能把游戏推向高压竞技或惩罚氛围。

好的音频反馈应帮助玩家理解状态变化，而不是催促玩家优化。资源不足、比赛失利、事件结果偏弱或维护费结算时，声音应表达“可以调整、下次再来、生活继续”，不得使用刺耳警报、危机倒计时或失败惩罚式音效。玩家可以降低音量、关闭某类音频或在无音频资产时继续游玩，不会因此损失信息、奖励或操作能力。

## Detailed Rules

### Core Rules

1. 音频系统是 Beta Presentation 层系统，不属于 MVP 核心闭环的必需权威系统。
2. 本系统只负责音频事件分类、BGM 状态选择、音效触发、环境音层级、短促情绪反馈、混音优先级、音量设置、去重冷却和无资产降级，不拥有任何玩法结算规则。
3. 本系统不得修改时间、资源、球员、训练、比赛、建设、随机事件、声望、成就、技能、特性、存档或 UI 导航状态。
4. 本系统不得新增每日签到、任务完成、宝箱开启、奖励弹窗、限时活动、危机事件、惩罚警报或任何独立目标体系。
5. 所有自动音频触发必须来自上游系统提供的稳定事件或 UI 框架定义的屏幕/交互事件，不得自行推断玩法事件是否发生。
6. 音频反馈必须服务低压力体验；失败、资源不足、维护费、事件负面结果等场景只能使用温和、短促、可恢复的反馈，不得使用刺耳、威胁性或倒计时式声音。
7. 比赛音频可以强化进球、关键扑救、逆转、终场等高情绪节点，但不得压过赛后信息理解、复盘节奏或小镇经营的温暖基调。
8. 小镇 BGM 与环境音应优先表达时间段、生活感和轻经营氛围，不得制造持续紧张感。
9. UI 音效必须短、轻、低疲劳，默认不抢占 BGM、比赛关键反馈或系统核心反馈。
10. 同一稳定窗口内出现多个音频事件时，必须按音频优先级选择、合并或压制，避免叠音和信息噪声。
11. 音频系统必须提供玩家可调的主音量、BGM 音量、音效音量和环境音音量；关闭音频不得影响玩法反馈的可理解性。
12. 若音频资产缺失、加载失败或对应事件未配置音频，本系统必须静默降级为无声或通用轻反馈，不得阻塞玩法流程。
13. 本系统可以记录音量设置、静音状态和必要的音频偏好，但这些记录只能影响声音播放，不得影响玩法状态。
14. 音频触发不得在存档写入、读档恢复、比赛演算、训练结算、经济扣费等半结算状态中制造额外流程；只允许在上游系统确认稳定展示节点后播放。
15. 任何未来语音、解说、中间件或动态音乐复杂编排都必须作为扩展范围重新评审，不得成为 Beta 首版硬需求。

### Audio Layers

| Layer | Content | Default mix role | Design intent |
|---|---|---|---|
| BGM | 小镇日常、比赛前后、菜单或阶段性主题音乐 | 中等音量、长期循环 | 提供温暖、怀旧、轻快的主情绪 |
| Ambience | 小镇环境、人群远景、训练场背景、比赛场氛围 | 低音量、可被压低 | 增强空间和生活感 |
| SFX | UI 点击、训练反馈、建设完成、比赛事件、随机事件确认 | 短促、清晰 | 标记操作和状态变化 |
| Special Stinger | 进球、终场、重要解锁等短促情绪节点 | 最高短期优先级 | 强化少量高价值情绪峰值 |

### Event Categories

| Category | Trigger source | Example events | Audio response boundary |
|---|---|---|---|
| 小镇日常 | 时间与主循环 UI | 时间段切换、进入小镇主界面 | 切换或淡入对应 BGM / ambience |
| UI 交互 | 主循环 UI 框架 | 按钮点击、页面进入、返回、确认 | 轻量短音效，不阻塞操作 |
| 比赛事件 | 比赛竞技系统 / 比赛表现 UI | 开赛、进球、关键扑救、逆转、终场 | 可使用短曲或重点 SFX，但不得遮挡赛后信息 |
| 建设反馈 | 小镇建设系统 | 建造开始、升级确认、完工 | 温暖、手作感音效，不制造维护压力 |
| 随机事件 | 随机事件系统 | 事件出现、选择确认、结果反馈 | 表达生活插曲，不使用危机警报 |
| 长期成长 | 声望、成就、球员成长等展示事件 | 解锁、成长回顾、阶段认可 | 短促认可反馈，不新增奖励感压力 |

## Formulas

### 1. 音频事件播放资格

`audio_event_eligibility = event_valid × asset_available × user_volume_weight × cooldown_weight × focus_allowed`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 事件有效 | `event_valid` | int | 0 or 1 | 上游系统是否提供合法、稳定、已确认的音频事件 |
| 资产可用 | `asset_available` | int | 0 or 1 | 对应音频资产或通用 fallback 音效是否可用 |
| 用户音量权重 | `user_volume_weight` | float | 0.00–1.00 | 对应音频分类的玩家音量设置；静音时为 0 |
| 冷却权重 | `cooldown_weight` | int | 0 or 1 | 同类音效是否仍处于去重冷却中 |
| 焦点允许 | `focus_allowed` | int | 0 or 1 | 当前是否处于稳定展示节点，且没有被更高优先级反馈禁止 |
| 音频事件播放资格 | `audio_event_eligibility` | float | 0.00–1.00 | 用于判断该音频事件是否允许播放 |

**Rule:** 若 `event_valid = 0`、`asset_available = 0`、`user_volume_weight = 0`、`cooldown_weight = 0` 或 `focus_allowed = 0`，该音频事件不得播放。该公式只控制声音播放，不影响任何玩法结算或 UI 状态。

**Example:** 玩家未静音、比赛表现 UI 提供合法进球事件、音频资产可用且当前无冷却：`1 × 1 × 0.8 × 1 × 1 = 0.8`，该事件可播放并按分类音量混音。

### 2. 音频事件优先级

`audio_event_priority = clamp(base_audio_priority + emotional_peak_bonus - recent_overlap_penalty - low_pressure_penalty, 0, max_audio_priority)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 基础音频优先级 | `base_audio_priority` | int | 0–100 | 音频事件表中定义的基础优先级 |
| 情绪峰值加成 | `emotional_peak_bonus` | int | 0–30 | 进球、终场、重要认可等少量高价值节点的短期加成 |
| 近期重叠惩罚 | `recent_overlap_penalty` | int | 0–60 | 最近已播放音频事件对新事件的压制 |
| 低压力惩罚 | `low_pressure_penalty` | int | 0–100 | 事件声音若可能制造高压、刺耳或危机感时施加的压制 |
| 最大音频优先级 | `max_audio_priority` | int | 100 | 排序上限 |
| 音频事件优先级 | `audio_event_priority` | int | 0–100 | 多个候选音频事件之间的排序依据 |

**Rule:** 同一稳定窗口内最多允许一个 Special Stinger 播放；其他低优先级 SFX 必须被延后、合并或压制。若 `low_pressure_penalty` 将结果压到 0，该事件不得自动播放。

**Example:** 一个基础优先级 70 的比赛失利短音效若使用了过强危机感配置，低压力惩罚为 80：`clamp(70 + 0 - 0 - 80, 0, 100) = 0`，该配置不得播放，应替换为温和过渡音。

### 3. 分层混音输出音量

`layer_output_volume = master_volume × layer_volume × category_volume × event_intensity × ducking_weight`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 主音量 | `master_volume` | float | 0.00–1.00 | 玩家设置中的总音量 |
| 分层音量 | `layer_volume` | float | 0.00–1.00 | BGM、Ambience、SFX 或 Special Stinger 的层级音量 |
| 分类音量 | `category_volume` | float | 0.00–1.00 | 具体分类的可选音量修正，如 UI、比赛、建设 |
| 事件强度 | `event_intensity` | float | 0.25–1.00 | 单个事件配置的相对强度 |
| 压低权重 | `ducking_weight` | float | 0.30–1.00 | 更高优先级音频出现时对当前层的压低倍率 |
| 分层混音输出音量 | `layer_output_volume` | float | 0.00–1.00 | 最终用于该音频层播放的归一化音量 |

**Rule:** 音量计算结果必须保持在 0.00–1.00。关闭主音量或分类音量时，对应音频层不得播放，但视觉/UI 信息仍必须完整可用。

**Example:** 主音量 0.8、BGM 层音量 0.65、分类音量 1.0、事件强度 0.9，且比赛进球短曲触发时 BGM 被压低到 0.5，则 `layer_output_volume = 0.8 × 0.65 × 1.0 × 0.9 × 0.5 = 0.234`。

### 4. 音频去重冷却结束时间

`audio_cooldown_until = current_audio_window_index + ceil(base_audio_cooldown_windows × category_cooldown_multiplier)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 当前音频窗口序号 | `current_audio_window_index` | int | ≥ 0 | 稳定 UI 或反馈节点对应的递增音频窗口 |
| 基础音频冷却窗口 | `base_audio_cooldown_windows` | int | 1–12 | 同一音效或同类音效再次播放前的基础窗口数 |
| 分类冷却倍率 | `category_cooldown_multiplier` | float | 0.50–3.00 | 不同音频分类的冷却倍率 |
| 音频冷却结束时间 | `audio_cooldown_until` | int | ≥ current | 该类音频再次允许自动播放的最早窗口 |

**Rule:** 冷却只限制自动重复播放，不限制玩家主动调整设置或重新进入界面后合法的关键反馈。非整数结果必须向上取整，避免音效提前重复。

**Example:** 当前音频窗口为 20，基础冷却为 4，分类倍率为 1.5，则 `audio_cooldown_until = 20 + ceil(4 × 1.5) = 26`。

### 5. BGM 切换淡入淡出时长

`bgm_transition_duration = clamp(base_transition_seconds × context_transition_multiplier, min_transition_seconds, max_transition_seconds)`

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| 基础切换时长 | `base_transition_seconds` | float | 0.50–4.00 | 默认 BGM 淡入淡出秒数 |
| 场景切换倍率 | `context_transition_multiplier` | float | 0.50–2.00 | 时间段、比赛、菜单等场景切换对过渡长度的倍率 |
| 最短切换时长 | `min_transition_seconds` | float | 0.20–1.00 | 防止突兀切换的下限 |
| 最长切换时长 | `max_transition_seconds` | float | 3.00–8.00 | 防止过渡拖沓的上限 |
| BGM 切换淡入淡出时长 | `bgm_transition_duration` | float | 0.20–8.00 | 实际用于 BGM 切换的过渡时长 |

**Rule:** 日常小镇 BGM 切换应优先平滑；比赛关键节点可以使用较短过渡或短曲叠加，但不得造成刺耳突变。

**Example:** 基础切换 2.0 秒、时间段切换倍率 1.5、范围 0.5–6.0 秒，则 `bgm_transition_duration = clamp(2.0 × 1.5, 0.5, 6.0) = 3.0` 秒。

## Edge Cases

- **If 上游系统未提供合法音频事件**: 不播放音频，不自行推断事件，不阻塞 UI 或玩法流程。
- **If 音频资产缺失或加载失败**: 静默跳过该音频或使用已配置的通用轻反馈；不得显示错误弹窗或中断游戏。
- **If 玩家关闭主音量**: 所有自动音频停止播放，但比赛、建设、资源、随机事件和 UI 信息必须继续通过视觉反馈表达。
- **If 玩家只关闭 BGM、SFX 或 Ambience 某一类**: 仅对应层级静音，其他层级按设置继续播放。
- **If 同一稳定窗口出现多个比赛关键事件音频**: 只播放优先级最高的一条 Special Stinger，其余事件可降级为轻 SFX、延后或压制。
- **If 比赛失利、资源不足、维护费结算或随机事件弱结果触发音频**: 必须使用温和、短促、可恢复的反馈，不得使用危机警报、刺耳失败音或倒计时音。
- **If 随机事件被音频表现得像限时任务或危机事件**: 该音频配置无效，必须压制或替换为生活插曲式反馈。
- **If BGM 切换发生在存档写入、读档恢复或半结算状态**: 延后到稳定展示节点再切换，不在半结算态制造额外反馈流程。
- **If 玩家快速切换多个 UI 页面**: UI 音效必须受去重冷却限制，避免连续点击音造成疲劳。
- **If 小镇时间段连续变化或被快速推进**: BGM 不必逐段完整播放，只需在最终稳定时间段选择合法背景音乐。
- **If 音频事件与核心视觉反馈同时出现**: 视觉反馈和可读信息优先，音频不得遮挡、延迟或替代关键文本说明。
- **If 音频配置引用未开放系统的事件**: 默认不播放，直到对应系统提供稳定事件和设计口径。
- **If 音频播放设备不可用**: 游戏继续运行并保留全部视觉反馈，不把无声状态解释为错误或失败。
- **If 同类音效重复提交**: 返回幂等 no-op 或刷新到合法冷却策略，不叠加播放同一音效。
- **If 未来引入语音、解说或音频中间件**: 必须先通过新的设计/技术评审，不得改变本系统 Beta 首版的基础播放边界。

## Dependencies

音频系统是 Presentation 层反馈系统。它依赖上游玩法系统和 UI 系统提供稳定事件、界面节点和情绪语义；它不得反向改变任何上游系统的规则、节奏或结算结果。

### Upstream Dependencies

| Dependency | Type | Why it matters | Required interface |
|---|---|---|---|
| `design/gdd/game-concept.md` | Hard | 定义温暖、低压力、轻经营和反焦虑体验边界 | 核心支柱、低压力语气、禁止高压/惩罚式反馈 |
| `design/gdd/systems-index.md` | Hard | 定义音频系统层级、优先级和设计顺序 | Beta Presentation 定位、依赖方向、系统边界 |
| `design/gdd/main-loop-ui-framework.md` | Hard | 提供屏幕切换、页面进入/退出、按钮点击等 UI 音效触发锚点 | `screen_id`、UI 交互事件、稳定展示节点、反馈优先级 |
| `design/gdd/match-competition-system.md` | Hard | 提供比赛关键情绪事件和结果语义 | 开赛、进球、关键扑救、逆转、终场、赛果等事件标签 |
| `design/gdd/match-performance-ui.md` | Hard | 提供赛前、赛中、赛后界面的音频触发时机和表现锚点 | 比赛 UI 阶段、关键事件展示节点、赛后反馈排序 |
| `design/gdd/town-building-system.md` | Hard | 提供建设、升级、完工和设施状态反馈语义 | 建设开始、升级确认、完工、设施存在感、维护费说明边界 |
| `design/gdd/random-event-system.md` | Hard | 提供随机事件出现、选择确认和轻量结果反馈语义 | 事件出现、选择、结果、历史记录等低压力事件标签 |
| `design/gdd/save-and-load-system.md` | Hard | 保存玩家音量、静音和音频偏好设置 | `audio_master_volume`、`audio_bgm_volume`、`audio_sfx_volume`、`audio_ambience_volume`、`audio_muted_categories` 的持久化字段与恢复时机 |
| `design/gdd/reputation-and-achievement-system.md` | Soft | 支持声望升级、成就认可和长期成长短促反馈 | 解锁、认可、阶段目标完成等展示事件 |
| `design/gdd/player-development-system.md` | Soft | 支持训练完成、成长反馈和球员状态变化音效 | 训练结算、成长、状态变化等展示事件 |

### Downstream Dependencies

| Dependent system | Type | What it consumes from 音频系统 | What must be back-referenced later |
|---|---|---|---|
| 主循环 UI 框架 | Hard | UI 交互音效、屏幕切换音频、全局音量入口和反馈优先级 | 必须声明 UI 音效触发时机与本系统事件分类和冷却规则对齐 |
| 比赛表现 UI | Hard | 赛前、赛中、赛后关键音频事件映射与播放优先级 | 必须将音频系统从 Soft (provisional) 升级，并声明关键事件触发时机由比赛 UI 提供、声音内容由本系统定义 |
| 存档与读档系统 | Soft | 玩家音量、静音和音频偏好设置 | 若实现音频设置持久化，必须声明这些字段只影响播放设置，不影响玩法状态 |
| 设置/选项 UI | Future | 主音量、BGM、SFX、Ambience 等音量设置 | 未提供专用系统前，主循环 UI 可临时承载最小音量入口 |
| 可访问性设置 | Future | 关闭音频、降低高频音效、保留视觉替代反馈 | 未提供专用系统前，必须至少支持静音且不丢失关键信息 |
| 本地化系统 / 文本管线 | Future | 音频字幕、音效说明文本或设置项名称 | 未提供专用系统前，设置项使用普通文本 key 管理 |

### Durable State Contract

音频系统 Beta 首版的最小持久化边界包含玩家偏好，而不包含玩法状态：

| Field | Type | Description |
|---|---|---|
| `audio_master_volume` | float | 玩家主音量设置，范围 0.00–1.00 |
| `audio_bgm_volume` | float | BGM 音量设置，范围 0.00–1.00 |
| `audio_sfx_volume` | float | SFX 音量设置，范围 0.00–1.00 |
| `audio_ambience_volume` | float | 环境音音量设置，范围 0.00–1.00 |
| `audio_muted_categories` | Array[String] / set-like contract | 被玩家静音的音频分类 |

**Rule:** 这些字段只影响声音播放，不得被其他系统用于判断比赛、训练、建设、经济、声望、随机事件或 UI 流程结果。

### Dependency Rules

1. 本系统必须从上游系统取得稳定事件后才能触发对应音频。
2. 本系统必须服从主循环 UI 和比赛表现 UI 的反馈排序，不得抢占核心信息展示。
3. 比赛系统和比赛表现 UI 定义“何时发生/何时展示”；音频系统只定义“听起来如何”。
4. 随机事件系统定义事件性质和结果语义；音频系统不得将普通生活插曲表现为危机或限时任务。
5. 小镇建设系统定义设施状态和维护费含义；音频系统不得用警报音强化建设或维护压力。
6. 声望与成就系统、运动员培养系统若提供成长或认可展示事件，音频系统只能为这些已确认展示节点提供短促认可反馈，不得把长期成长包装成新的奖励循环或高压提醒。
7. 若音频设置需要持久化，存档与读档系统必须保存并恢复玩家音频偏好，但这些偏好不得影响玩法结算。
8. 若后续引入语音解说、音频中间件、动态音乐分轨或复杂自适应混音，必须先修订本 GDD，并按技术影响补充 ADR 或实现评审。

## Tuning Knobs

| 调参项 | 控制内容 | 安全范围 | 调高风险 | 调低风险 | 主要影响 |
|---|---|---|---|---|---|
| 主音量 `audio_master_volume` | 所有音频整体输出 | 0.00–1.00 | 声音过大、疲劳 | 反馈存在感不足 | 总体可听性 |
| BGM 音量 `audio_bgm_volume` | 背景音乐输出 | 0.00–1.00 | 长时间压迫、遮挡 SFX | 氛围不足 | 小镇温暖感、场景情绪 |
| SFX 音量 `audio_sfx_volume` | UI、比赛、建设和事件音效输出 | 0.00–1.00 | 高频疲劳、打断感 | 状态变化反馈弱 | 操作确认、事件识别 |
| 环境音量 `audio_ambience_volume` | 小镇、人群、训练场等环境层 | 0.00–1.00 | 噪声堆叠 | 空间感不足 | 生活感、沉浸度 |
| Special Stinger 音量 `special_stinger_volume` | 进球、终场、重要认可短曲 | 0.00–1.00 | 情绪峰值过强、抢焦点 | 高价值节点不明显 | 比赛和成长情绪峰值 |
| BGM 基础切换时长 `base_transition_seconds` | BGM 淡入淡出基础秒数 | 0.50–4.00 | 切换拖沓 | 切换突兀 | 场景流畅度 |
| 最短切换时长 `min_transition_seconds` | 淡入淡出下限 | 0.20–1.00 | 快速反馈不够利落 | 声音突变 | 切换舒适度 |
| 最长切换时长 `max_transition_seconds` | 淡入淡出上限 | 3.00–8.00 | 旧情绪残留太久 | 场景转换生硬 | 情绪承接 |
| 基础音频冷却窗口 `base_audio_cooldown_windows` | 同类音效再次播放间隔 | 1–12 音频窗口 | 重要反馈被压制 | 重复叠音、疲劳 | 音效密度 |
| 分类冷却倍率 `category_cooldown_multiplier` | 不同音频分类冷却长度 | 0.50–3.00 | 某类音效过安静 | 某类音效刷屏 | 分类节奏 |
| 近期重叠惩罚 `recent_overlap_penalty` | 多事件重叠时压制强度 | 0–60 | 音频反馈过少 | 叠音明显 | 清晰度、疲劳度 |
| 低压力惩罚 `low_pressure_penalty` | 高压/刺耳配置的自动压制强度 | 0–100 | 可用音效被过度压制 | 高压音频漏出 | 低压力体验边界 |
| BGM ducking 权重 `bgm_ducking_weight` | 高优先级 SFX 出现时 BGM 压低程度 | 0.30–1.00 | BGM 突然消失 | 关键 SFX 不清晰 | 混音层次 |
| Ambience ducking 权重 `ambience_ducking_weight` | 高优先级反馈出现时环境音压低程度 | 0.20–1.00 | 空间感断裂 | 环境音遮挡反馈 | 信息清晰度 |
| UI 音效强度 `ui_event_intensity` | UI 点击、返回、确认音强度 | 0.25–0.80 | 点击疲劳 | 操作确认弱 | UI 手感 |
| 比赛事件强度 `match_event_intensity` | 进球、扑救、终场等比赛音效强度 | 0.40–1.00 | 比赛压过小镇基调 | 比赛起伏不足 | 比赛情绪 |
| 建设音效强度 `town_build_event_intensity` | 建造、升级、完工音效强度 | 0.30–0.90 | 建设反馈过重 | 小镇建设存在感不足 | 小镇身份感 |
| 随机事件音效强度 `random_event_intensity` | 随机事件出现、选择、结果反馈强度 | 0.25–0.75 | 插曲变得像任务或警报 | 事件存在感弱 | 生活插曲感 |
| 音频资产总预算 `audio_asset_budget_mb` | Beta 首版音频资源总大小 | 40–120 MB | 包体膨胀、加载压力 | 音频重复、质感不足 | 资源规模 |
| 低压力音频审核 `low_pressure_audio_check` | 是否启用高压/刺耳/危机感配置拦截 | true / false | 审核成本增加 | 体验边界失守 | 语气一致性 |

## Acceptance Criteria

- **GIVEN** 上游系统没有提供合法音频事件，**WHEN** 音频系统收到播放检查请求，**THEN** `event_valid` 必须为 0 且不得播放或推断任何音频事件。
- **GIVEN** 玩家将主音量设置为 0，**WHEN** 任意音频事件触发，**THEN** `user_volume_weight` 或最终输出音量必须为 0，且玩法流程和视觉反馈继续正常。
- **GIVEN** 玩家只关闭 BGM，**WHEN** UI 点击或比赛事件音效触发，**THEN** BGM 不播放，但合法 SFX 仍可按 SFX 音量播放。
- **GIVEN** 音频资产缺失或加载失败，**WHEN** 对应事件触发，**THEN** 音频系统必须静默跳过或使用已配置通用轻反馈，不得中断 UI、比赛或结算流程。
- **GIVEN** 同一稳定窗口出现多个 Special Stinger 候选，**WHEN** 音频系统排序事件，**THEN** 只能播放 `audio_event_priority` 最高且合法的一条。
- **GIVEN** 同类 UI 音效仍处于 `audio_cooldown_until` 之前，**WHEN** 玩家快速切换或点击多个页面，**THEN** 系统不得重复叠加播放该类音效。
- **GIVEN** 比赛表现 UI 提供合法进球事件，**WHEN** 当前无静音、资产可用且焦点允许，**THEN** 音频系统可以播放对应进球短曲或重点 SFX，但不得延迟赛后信息展示。
- **GIVEN** 比赛失利事件触发音频，**WHEN** QA 检查配置，**THEN** 该音频不得使用危机警报、刺耳失败音、倒计时或惩罚式声音。
- **GIVEN** 随机事件出现或结算，**WHEN** 音频系统播放反馈，**THEN** 声音必须表达生活插曲或轻量确认，不得让事件听起来像限时任务或危机。
- **GIVEN** 小镇建设完工，**WHEN** 上游建设系统提供稳定完工事件，**THEN** 音频系统可以播放温暖、手作感的建设完成音效，但不得新增奖励弹窗或改变建设收益。
- **GIVEN** 资源不足、维护费结算或弱结果反馈出现，**WHEN** 音频系统选择 SFX，**THEN** 必须使用低压力短反馈，不得用警报强化经营压力。
- **GIVEN** BGM 需要从小镇日常切换到比赛前状态，**WHEN** 进入合法稳定展示节点，**THEN** 切换时长必须由 `bgm_transition_duration` 公式计算并保持在配置上下限内。
- **GIVEN** 小镇时间段被快速推进多次，**WHEN** 时间推进恢复到稳定状态，**THEN** 音频系统只需选择最终时间段对应 BGM，不得逐段强制播放所有过渡。
- **GIVEN** 高优先级比赛短曲播放，**WHEN** BGM 同时存在，**THEN** BGM 输出必须按 `ducking_weight` 被压低或保持不抢占短曲。
- **GIVEN** 玩家保存并读档，**WHEN** 游戏恢复音频设置，**THEN** `audio_master_volume`、`audio_bgm_volume`、`audio_sfx_volume`、`audio_ambience_volume` 和 `audio_muted_categories` 必须与保存前一致。
- **GIVEN** 存档写入、读档恢复、比赛演算、训练结算或经济扣费正在进行，**WHEN** 音频系统收到非关键自动播放请求，**THEN** 必须延后或压制该音频，不得在半结算态插入额外反馈流程。
- **GIVEN** 音频配置引用尚未开放系统的事件，**WHEN** 该配置被加载，**THEN** 对应音频不得自动播放，直到该系统提供稳定事件与设计口径。
- **GIVEN** 音频播放设备不可用，**WHEN** 游戏启动或进入任意界面，**THEN** 游戏必须继续运行并保留全部视觉反馈，不把无声状态解释为失败。
- **GIVEN** QA 检查音频资源，**WHEN** 发现每日签到、任务完成、宝箱开启、危机警报或限时奖励音效配置，**THEN** 这些配置不得进入 Beta 首版音频事件表。
- **GIVEN** 后续设计想加入语音解说、FMOD/Wwise 等中间件或复杂动态分轨，**WHEN** 进入实现前评审，**THEN** 必须先修订本 GDD 并补充技术评审或 ADR。
