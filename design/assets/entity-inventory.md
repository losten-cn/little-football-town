# Visual Entity & Screen Inventory

> Generated: 2026-05-19
> Sources: `design/gdd/systems-index.md`, `design/gdd/player-development-system.md`, `design/gdd/match-competition-system.md`, `design/gdd/town-building-system.md`, `design/gdd/league-competition-structure-system.md`, `design/gdd/main-loop-ui-framework.md`, `design/gdd/player-management-ui.md`, `design/gdd/match-performance-ui.md`, `design/gdd/time-and-season-progression-system.md`, `design/gdd/economy-management-system.md`, `design/gdd/balance-system.md`, `design/gdd/save-and-load-system.md`, `design/art/art-bible.md`

## Entities

| # | Name | Type | Description | Source | Status |
|---|------|------|-------------|--------|--------|
| 1 | Club Footballer | Character | 主力球员（训练/比赛核心角色） | `design/gdd/player-development-system.md`, `design/art/art-bible.md` | Needed |
| 2 | Youth Prospect Footballer | Character | 青训候选球员 | `design/gdd/player-development-system.md`, `design/gdd/town-building-system.md` | Needed |
| 3 | Coach / Club Staff NPC | Character | 教练与运营人员 | `design/art/art-bible.md` | Needed |
| 4 | Town Resident NPC | Character | 小镇居民与路人 | `design/art/art-bible.md` | Needed |
| 5 | Opponent Footballer | Character | 对手球队球员 | `design/gdd/match-competition-system.md`, `design/art/art-bible.md` | Needed |
| 6 | Crowd Supporter Silhouette | Character | 看台观众剪影群体 | `design/art/art-bible.md` | Needed |
| 7 | Training Ground | Building / Structure | 训练场设施 | `design/gdd/town-building-system.md` | Needed |
| 8 | Medical Room | Building / Structure | 医疗恢复设施 | `design/gdd/town-building-system.md` | Needed |
| 9 | Youth Academy | Building / Structure | 青训学院设施 | `design/gdd/town-building-system.md` | Needed |
| 10 | Stadium | Building / Structure | 主场球场 | `design/gdd/town-building-system.md` | Needed |
| 11 | Town House | Building / Structure | 住宅立面 | `design/art/art-bible.md` | Needed |
| 12 | Corner Shop | Building / Structure | 街角商铺立面 | `design/art/art-bible.md` | Needed |
| 13 | Café | Building / Structure | 咖啡馆立面 | `design/art/art-bible.md` | Needed |
| 14 | School Building | Building / Structure | 学校立面 | `design/art/art-bible.md` | Needed |
| 15 | Small-Town Street Block | Environment / Terrain | 小镇街区主背景 | `design/art/art-bible.md` | Needed |
| 16 | Civic Plaza | Environment / Terrain | 社区广场 | `design/art/art-bible.md` | Needed |
| 17 | Training Pitch | Environment / Terrain | 训练草坪 | `design/gdd/town-building-system.md`, `design/art/art-bible.md` | Needed |
| 18 | Match Pitch | Environment / Terrain | 比赛草坪 | `design/gdd/match-competition-system.md` | Needed |
| 19 | Residential Block Backdrop | Environment / Terrain | 住宅群背景层 | `design/art/art-bible.md` | Needed |
| 20 | Stadium Stand / Terrace | Environment / Terrain | 看台/场边结构背景 | `design/art/art-bible.md` | Needed |
| 21 | Football | Item / Prop | 比赛与训练用球 | `design/gdd/match-competition-system.md` | Needed |
| 22 | Practice Cone | Item / Prop | 训练标志桶 | `design/art/art-bible.md` | Needed |
| 23 | Goal Net | Item / Prop | 球门网 | `design/art/art-bible.md` | Needed |
| 24 | Trophy | Item / Prop | 冠军奖杯 | `design/art/art-bible.md`, `design/gdd/league-competition-structure-system.md` | Needed |
| 25 | Team Poster | Item / Prop | 球队海报 | `design/art/art-bible.md` | Needed |
| 26 | Sponsor Signboard | Item / Prop | 赞助看板 | `design/art/art-bible.md` | Needed |
| 27 | Notice Board | Item / Prop | 公告栏 | `design/art/art-bible.md` | Needed |
| 28 | Bench | Item / Prop | 长椅 | `design/art/art-bible.md` | Needed |
| 29 | Fence | Item / Prop | 围栏 | `design/art/art-bible.md` | Needed |
| 30 | Utility Pole | Item / Prop | 电线杆 | `design/art/art-bible.md` | Needed |
| 31 | Bicycle | Item / Prop | 自行车道具 | `design/art/art-bible.md` | Needed |
| 32 | Wooden Crate | Item / Prop | 木箱道具 | `design/art/art-bible.md` | Needed |
| 33 | Flower Pot | Item / Prop | 花盆道具 | `design/art/art-bible.md` | Needed |
| 34 | Laundry Line | Item / Prop | 晾衣绳道具 | `design/art/art-bible.md` | Needed |
| 35 | Confetti Burst | VFX / Particle | 冠军庆祝彩带粒子 | `design/art/art-bible.md` | Needed |
| 36 | Fireworks Burst | VFX / Particle | 庆祝烟花粒子 | `design/art/art-bible.md` | Needed |
| 37 | Team Crest / Club Badge | Other | 球队徽章与身份图形 | `design/gdd/league-competition-structure-system.md`, `design/gdd/main-loop-ui-framework.md` | Needed |
| 38 | Stat Icon Set (SPD/PWR/TEC/INT/STA) | Other | 五维属性图标组 | `design/gdd/balance-system.md` | Needed |
| 39 | Resource Icon Set (Funds/AP) | Other | 经费与行动点图标组 | `design/gdd/economy-management-system.md`, `design/gdd/balance-system.md` | Needed |
| 40 | Research Points Icon | Other | 研究点图标（未来可视化） | `design/gdd/economy-management-system.md` | Needed (Future) |
| 41 | Formation Position Marker | Other | 阵型位置标记 | `design/gdd/player-management-ui.md`, `design/gdd/match-competition-system.md` | Needed |
| 42 | Result Outcome Badge Set | Other | 胜/平/负结果徽章组 | `design/gdd/match-competition-system.md`, `design/gdd/league-competition-structure-system.md` | Needed |

## UI Screens

| # | Screen Name | Description | Source | Status |
|---|-------------|-------------|--------|--------|
| 1 | Home | 主循环首页 | `design/gdd/main-loop-ui-framework.md` | Needed |
| 2 | Roster | 球员列表页 | `design/gdd/main-loop-ui-framework.md`, `design/gdd/player-management-ui.md` | Needed |
| 3 | Player Detail | 球员详情页 | `design/gdd/player-management-ui.md` | Needed |
| 4 | Player Growth Tab | 球员成长子页 | `design/gdd/player-management-ui.md` | Needed |
| 5 | Player Training Action View | 球员训练动作面板 | `design/gdd/player-management-ui.md` | Needed |
| 6 | Training | 训练主界面 | `design/gdd/main-loop-ui-framework.md` | Needed |
| 7 | Match Center | 比赛中心页 | `design/gdd/main-loop-ui-framework.md` | Needed |
| 8 | Match Pre View | 赛前准备页 | `design/gdd/match-performance-ui.md` | Needed |
| 9 | Match Live View | 比赛进行页 | `design/gdd/match-performance-ui.md` | Needed |
| 10 | Match Result View | 赛后结算页 | `design/gdd/match-performance-ui.md` | Needed |
| 11 | Schedule / Calendar | 赛程日历页 | `design/gdd/main-loop-ui-framework.md`, `design/gdd/time-and-season-progression-system.md` | Needed |
| 12 | League Standings | 联赛积分榜页 | `design/gdd/league-competition-structure-system.md` | Needed |
| 13 | Pre-Season Overview | 季前概览页 | `design/gdd/league-competition-structure-system.md` | Needed |
| 14 | Season Settlement Summary | 赛季结算页 | `design/gdd/league-competition-structure-system.md` | Needed |
| 15 | Career Review | 生涯回顾页 | `design/gdd/league-competition-structure-system.md` | Needed |
| 16 | Match Highlights Replay | 比赛回放页 | `design/gdd/match-performance-ui.md` | Needed (Future) |
| 17 | 3D Match Presentation | 3D 比赛表现页 | `design/gdd/match-performance-ui.md` | Needed (Future) |

## HUD Elements

| # | Element | Description | Source | Status |
|---|---------|-------------|--------|--------|
| 1 | Date & Season Phase Label | 日期与赛季阶段 | `design/gdd/main-loop-ui-framework.md` | Needed |
| 2 | Funds Counter | 经费显示 | `design/gdd/main-loop-ui-framework.md`, `design/gdd/economy-management-system.md` | Needed |
| 3 | Action Points Counter | 行动点显示 | `design/gdd/main-loop-ui-framework.md`, `design/gdd/balance-system.md` | Needed |
| 4 | Next Match Panel | 下一场比赛提示 | `design/gdd/main-loop-ui-framework.md` | Needed |
| 5 | Team Strength Summary | 阵容强度摘要 | `design/gdd/main-loop-ui-framework.md` | Needed |
| 6 | Primary Navigation Tabs | 主导航入口组 | `design/gdd/main-loop-ui-framework.md` | Needed |
| 7 | State / Warning Banner | 状态与警示条 | `design/gdd/economy-management-system.md`, `design/gdd/save-and-load-system.md` | Needed |
| 8 | Season Progress Indicator | 赛季进度条 | `design/gdd/league-competition-structure-system.md`, `design/gdd/time-and-season-progression-system.md` | Needed |
| 9 | Match Scoreboard | 比分牌 | `design/gdd/match-performance-ui.md` | Needed |
| 10 | Match Phase Label | 比赛阶段标签 | `design/gdd/match-performance-ui.md` | Needed |
| 11 | Key Event Feed | 比赛关键事件流 | `design/gdd/match-competition-system.md`, `design/gdd/match-performance-ui.md` | Needed |
| 12 | Halftime Adjustment Prompt | 中场调整提示 | `design/gdd/match-competition-system.md`, `design/gdd/match-performance-ui.md` | Needed |
| 13 | Result Summary Panel | 赛果摘要面板 | `design/gdd/match-performance-ui.md` | Needed |
| 14 | Result Cause Tags | 赛果原因标签 | `design/gdd/match-competition-system.md` | Needed |
| 15 | Player Performance Summary | 球员赛后表现摘要 | `design/gdd/match-competition-system.md`, `design/gdd/player-management-ui.md` | Needed |
| 16 | Research Points Indicator | 研究点 HUD 项 | `design/gdd/economy-management-system.md` | Needed (Future) |
| 17 | Commentary Text Panel | 解说文本面板 | `design/gdd/match-performance-ui.md` | Needed (Future) |

## Audio

| # | Name | Type (SFX / Music / Ambient) | Description | Source | Status |
|---|------|------------------------------|-------------|--------|--------|
| 1 | UI Confirm Click | SFX | 确认点击音 | `design/gdd/main-loop-ui-framework.md` | Needed |
| 2 | UI Navigation Tick | SFX | 导航切换音 | `design/gdd/main-loop-ui-framework.md` | Needed |
| 3 | Screen Transition Sweep | SFX | 页面切换音 | `design/gdd/main-loop-ui-framework.md` | Needed |
| 4 | Goal Cheer Stinger | SFX | 进球提示音 | `design/gdd/match-competition-system.md` | Needed |
| 5 | Big Save Stinger | SFX | 扑救高光提示音 | `design/gdd/match-competition-system.md` | Needed |
| 6 | Momentum Swing Stinger | SFX | 形势反转提示音 | `design/gdd/match-competition-system.md` | Needed |
| 7 | Final Whistle | SFX | 终场哨音 | `design/gdd/match-competition-system.md` | Needed |
| 8 | Town Ambient Loop | Ambient | 小镇环境循环氛围 | `design/art/art-bible.md` | Needed |
| 9 | Stadium Crowd Loop | Ambient | 球场观众氛围循环 | `design/art/art-bible.md` | Needed |
| 10 | Home / Management BGM | Music | 主循环经营 BGM | `design/gdd/main-loop-ui-framework.md` | Needed |
| 11 | Match Tension BGM | Music | 比赛紧张氛围 BGM | `design/gdd/match-performance-ui.md` | Needed |
| 12 | Championship Celebration Theme | Music | 冠军庆祝主题 | `design/art/art-bible.md` | Needed |
| 13 | Fireworks Burst | SFX | 烟花爆发音效 | `design/art/art-bible.md` | Needed |