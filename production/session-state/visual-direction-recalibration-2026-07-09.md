# 视觉方向重校准 — 会话上下文转交文档

> **创建日期**: 2026-07-09
> **目的**: 在新 session 中快速恢复关于"美术风格偏差"讨论的全部上下文
> **触发**: 用户反馈"游戏当前的美术风格根本与我想要的有严重偏差"

---

## 1. 问题核心（一句话）

**当前项目实现的是一个基于暗色 UI 面板的管理仪表盘（类 MUD），而用户想要的是一个可以"看见"的 2D 像素足球小镇（类星露谷 + 开罗足球物语）。**

---

## 2. 用户的明确期望

经过多轮对话确认，用户的目标是：

- **2D 像素风格**，类似《星露谷物语》的 3/4 俯视视角（非严格等距 isometric）
- **可见的像素小镇**：建筑有外形、角色可以走动、季节在画面里变化
- **自动比赛演出**：球员在球场上自动跑动、传球、射门，类似开罗《足球物语》(Pocket League Story)
- **从世界进入功能**：点击训练场建筑进入训练界面，点击球场进入比赛，而不是从菜单导航
- **暖亮、温暖、有人情味的视觉基调**：不是暗色管理面板
- **需要完整的美术资源和音频资源**：目前几乎为零

### 参考游戏方向

| 参考 | 借鉴什么 | 避免什么 |
|------|---------|---------|
| 开罗足球物语 (Pocket League Story) | 自动比赛演出、小比例像素角色、管理可读性 | 不复制其 Q 版比例和 UI 框架 |
| 星露谷 (Stardew Valley) | 季节性调色偏移、温暖像素氛围、小镇归属感 | 不变成农场游戏 |
| 吉卜力小镇电影 | 人性化构图、日常感、到达感 | 不模仿绘画渲染 |

---

## 3. 断层分析

### 3.1 当前项目实际状态

| 维度 | 状态 | 详情 |
|------|------|------|
| 后端系统 | ✅ 完整 | 经济/比赛演算/球员培养/训练公式/小镇建设公式/联赛结构/存档——全齐，有 72+ 测试覆盖 |
| 设计文档 | ✅ 完整 | 20 个 GDD、art-bible、UX spec、13 个 ADR |
| 视觉世界 | ❌ 不存在 | 没有 TileMap、没有角色精灵、没有建筑精灵、没有比赛动画、没有摄像机 |
| 美术资产 | ❌ 几乎为零 | 仅 14 个 20px HUD 功能图标 + 1 个 Zpix 像素字体 |
| 音频资产 | ❌ 零 | 无 BGM、无 SFX |
| UI 框架 | ⚠️ 方向偏差 | Zone A/C 使用暗色面板 (#1A1A2E)，Zone B 使用文字信息卡片，与设计要求（暖亮基线）相反 |

### 3.2 设计要求 vs 当前实现

| 设计要求（art-bible 批准状态） | 当前实现 | 偏差 |
|------|------|------|
| HUD 暖亮基线 `#FFF2D2` | Zone A/C 全暗 `#1A1A2E` | 🔴 严重 |
| Zone B = 中央小镇地图主体（建筑/角色/环境动画） | Zone B = 6 张文字信息卡片 | 🔴 严重 |
| "不得默认使用暗色主题管理UI" | 顶部栏+底部栏=持久暗色框架 | 🔴 严重 |
| 从世界建筑交互进入功能 | 从底部导航栏按钮进入功能 | 🔴 严重 |
| 比赛=自动像素球员演出 | 比赛=文字结果面板 | 🔴 严重 |
| 强调色 Town Gold `#D6B35A` / Town Accent `#C76A00` | 使用 `#FF9800` 高饱和橙 | 🟠 中度 |

### 3.3 问题根源

**这不是"美术风格偏差"问题，而是整个视觉和音频层从未开工。** 两年来的产能全部投在了系统设计和后端实现上，做的 UI 框架方向是"管理仪表盘"而非"可视世界"。

---

## 4. 本次会话中达成的共识

1. **不做更多 UI panel story**——当前 Sprint 的 visual exemplar stories 已完成（Home/Player/Match），但后续不应继续在错误的视觉范式上优化细节
2. **需要切换到"世界构建 + 资产生产"方向**——优先建 tilemap 小镇原型，而非优化面板排版
3. **视角选择**：3/4 俯视 top-down（星露谷/开罗式），非严格等距 isometric
4. **视觉目标表述**：

> 暖亮 3/4 俯视 2D 像素足球小镇。玩家能看到小镇建筑、道路、训练场、球场、球员和居民的轻量循环动画；比赛以自动像素球员演出呈现，而不是纯文本结果。

5. **需要先做视觉原型验证方向**，再大规模生产资产

---

## 5. 需要做的事（优先级排序）

### P0 — 方向锁定 ✅ 已完成 (2026-07-10)
- [x] 视觉方向已通过《STYLE_GUIDE.md V1.0 终稿》锁定，无需图像生成工具验证
- [x] 像素精度：32×32，视角：3/4 俯视 top-down，色板：7色绝对闭环

### P1 — 最小视觉原型
- [ ] 在 `prototypes/` 下建像素小镇视觉原型
- [ ] 最小范围：1 个 TileMapLayer + Camera2D + 4 栋建筑临时像素块 + 几个角色走动 + 球场自动比赛概念验证
- [ ] 不接后端，纯验证视觉方向

### P2 — 资产清单与获取策略
- [ ] Tileset + 建筑精灵（训练场、医疗室、青训营、球场）
- [ ] 角色精灵（球员、教练、NPC 居民）
- [ ] 比赛画面精灵（球场、球员跑动、足球、球门）
- [ ] 音频（BGM 主旋律、核心 SFX）
- [ ] 决定获取方式：自制 / 购买 / 先用占位

### P3 — 视觉层重构
- [ ] HUD 暖亮化（Zone A/C 从 `#1A1A2E` 迁移到 Town-Light Delta Palette）
- [ ] 从世界建筑点击进入功能面板
- [ ] 比赛画面替代文字结果

---

## 6. 关键设计文档速查

所有文档均已完整阅读，以下是核心参考：

| 文档 | 路径 | 关键内容 |
|------|------|---------|
| 游戏概念 | `design/gdd/game-concept.md` | 三大支柱、视觉锚点、"一个你想住进去的像素小镇" |
| 美术圣经 | `design/art/art-bible.md` | 完整视觉规范、色板、形状语言、环境设计、禁止项 |
| HUD 视觉设计 | `design/art/hud-visual-design.md` | Town-Light Delta Palette、Zone A/C 视觉规格 |
| HUD UX | `design/ux/hud.md` | 严格 MVP HUD 布局、Zone A/B/C 定义 |
| 小镇主视图 UX | `design/ux/town-main-view.md` | Zone B = 中央小镇地图主体（建筑轮廓/环境角色/轻量提示） |
| 交互模式库 | `design/ux/interaction-patterns.md` | 32 个交互模式、动画标准、音效标准 |
| 系统索引 | `design/gdd/systems-index.md` | 20 个系统、依赖关系、MVP/Alpha/Beta 分层 |
| 小镇建设系统 | `design/gdd/town-building-system.md` | 4 类设施、5×5 网格、建造/升级/维护费公式 |
| 架构总览 | `docs/architecture/architecture.md` | 系统分层、13 个 ADR、模块所有权 |
| 当前 Sprint | `production/sprint-status.yaml` | Sprint 4: governance and technical foundation |

---

## 7. 项目当前数据一览

```
设计文档: 20 个 GDD + art-bible + UX spec 全套
ADR:      13 个 (ADR-0001 ~ ADR-0013)
源代码:   39 个 .gd 文件, ~12,000 行
测试:     72+ 个 (25 单元 + 42+ 集成)
美术资产: 14 个 20px PNG 图标 + 1 个 Zpix 字体
音频资产: 0
阶段:     Production (Sprint 4)
Gate:     CONCERNS (非 clean READY)
引擎:     Godot 4.6 + GDScript
```

---

## 8. 参考截图生成提示词

以下提示词用于在新 session 中用图像生成工具（如 DALL-E、Midjourney、Stable Diffusion）生成视觉方向参考图。

### 8.1 通用母提示词（所有图的基础）

```
Create a 2D pixel-art game screenshot concept for a cozy football town management game.

The game is a warm, charming, small-town football simulation where the player manages a local football club, grows the town, trains players, and watches automatic matches. The visual direction combines the cozy seasonal feeling of Stardew Valley, the readable management charm of Kairosoft sports games, and the human-scale warmth of a small Studio Ghibli town, without copying any of them.

Perspective: 3/4 top-down pixel-art view, not true isometric. Rectangular tilemap, readable buildings, visible roads, grass, fences, trees, benches, laundry, posters, banners, and football-related props. The town should feel lived-in, modest, optimistic, and cared for.

Art style: hand-crafted pixel art, warm cream and gold palette, soft greens, earthy browns, gentle red club accents, low-to-medium saturation, clean readable silhouettes, no photorealism, no vector art, no 3D render, no dark corporate dashboard.

Game UI: minimal warm pixel HUD, light cream panels, brown text, amber/gold borders, small pixel font, only essential information. UI should not dominate the image; the town world should be the main focus.

Mood: cozy, low-pressure, hopeful, charming, readable, inviting. A place the player wants to return to.

Aspect ratio 16:9, game screenshot composition, pixel-art scale, crisp pixels.
```

### 8.2 通用负面提示词

```
no photorealism, no 3D rendering, no smooth vector art, no glossy UI, no cyberpunk, no neon, no dark corporate dashboard, no spreadsheet interface, no realistic football broadcast, no FIFA-style stadium, no over-detailed high-frequency noise, no muddy colors, no horror, no dystopia, no huge chibi heads, no Kairosoft clone, no Stardew Valley clone, no text-heavy MUD interface, no black empty panels, no modern SaaS dashboard, no mobile gacha UI, no sci-fi UI, no esports lightning effects.
```

### 8.3 参考图 1：小镇主视图 (Home Hub)

> 最重要的一张——纠正"文字面板/MUD"问题

```
Create a 16:9 pixel-art game screenshot of the main town view for a cozy football town management game.

Scene:
A small football town viewed from a 3/4 top-down 2D pixel-art perspective. The central area shows a readable town map: a modest local clubhouse, a training ground, a small medical room, a youth academy building, a small stadium entrance, grass paths, fences, trees, benches, bicycles, laundry lines, shopfronts, community noticeboards, football posters, scarves, and local club banners.

The town should feel like a place people live in, not a menu screen. A few tiny pixel characters walk around: young football players in training kits, a coach with a clipboard, residents, kids kicking a ball near a wall, a groundskeeper near the training field.

UI:
Minimal warm HUD only:
- top bar with season/week, funds, action points, next match
- bottom bar with two buttons: Players and Match
Use cream panels, brown text, amber/gold borders, small pixel font.
The UI takes little space and does not cover the town.

Mood: Warm daytime, cozy, readable, low-pressure, inviting, optimistic. The player should immediately feel "this is my football town".
```

### 8.4 参考图 2：训练场

```
Create a 16:9 pixel-art game screenshot of a training ground scene in a cozy football town management game.

Scene:
A small local football training ground inside a warm pixel-art town. 3/4 top-down 2D pixel art view. Several tiny football players are automatically training: one dribbles around cones, two pass a ball, one shoots at a small goal, one stretches near the sideline. A coach with a clipboard watches calmly. Fences, trees, benches, water bottles, towels, football bags, hand-painted club signs, a small clubhouse nearby.

UI:
A small warm cream training panel on one side shows: selected training focus, action point cost, expected growth, a Start Training button. The panel should be readable but secondary; the animated training field is the main focus.

Mood: Cozy, productive, hopeful, low-pressure. Training should feel like daily growth, not intense professional sports pressure.
```

### 8.5 参考图 3：自动比赛

> 第二关键——确认"不是文字结果，是球员自动踢"

```
Create a 16:9 pixel-art game screenshot of an automatic football match in a cozy 2D pixel-art football town management game.

Scene:
A small community football stadium viewed from 3/4 top-down pixel-art perspective. Tiny pixel football players automatically move on the pitch. One player is dribbling, another is running into space, two defenders are closing in, the ball is visible, the goalkeeper stands near the goal. The match should feel readable and lively.

The stadium is modest and local: small stands, town residents watching, handmade banners, scarves, flags, simple floodlights, a scoreboard, benches, coaches on the sideline.

UI:
Minimal match HUD: score at top center, match time, small timeline/event feed with 2-3 recent events. No dense statistics panel. UI should be warm and readable with slightly more energetic red/gold accents, but still not a dark corporate sports broadcast.

Mood: Exciting but cozy, readable, charming, low-pressure. A local match that matters to the town.
```

---

## 9. 新 Session 启动步骤

在新 session 中，按以下顺序快速恢复上下文并开展工作：

1. **读取本文件** — 了解完整背景和已达成的共识
2. **生成参考截图** — 使用 §8 的提示词在图像生成工具中生成 3 张参考图
3. **对比参考图与当前实现** — 确认视觉方向
4. **锁定视角和像素精度** — 最终决策
5. **起草视觉原型 spec** — 在 `prototypes/` 下建最小 tilemap 小镇
6. **运行 `/sprint-status`** — 了解当前 sprint 状态
7. **决定后续 sprint 方向** — 从"面板优化"转向"世界构建 + 资产生产"
