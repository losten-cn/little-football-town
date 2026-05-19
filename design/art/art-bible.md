# Art Bible: 足球小镇 (Football Town)

> **Status**: In Design
> **Author**: nico + art-director
> **Last Updated**: 2026-05-19
> **Reference**: 开罗游戏系列 (Kairosoft)
> **Pillars**: 轻度足球经营 / 像素小镇养成 / 低压力长期成长
> **Art Director Sign-Off (AD-ART-BIBLE)**: Pending

---

## 1. Visual Identity Statement

**Visual Rule**: "A pixel-art town you want to live in, with a football team you want to coach."

When any visual decision is ambiguous, prioritize **warmth, clarity, and invitation** over intensity, density, and pressure.

### Principle 1: Clarity Before Density (serves Pillar 1 — Lightweight Football Management)

*Design test:* "When information density is ambiguous, choose fewer, higher-contrast elements over many struggling-to-be-read ones."

This directly counters spreadsheet-heavy management sims. Every screen has one obvious focal point. The HUD embodies this with a small number of fixed, high-priority information groups and only the core navigation needed for MVP. Every future screen follows the same discipline.

### Principle 2: Grow, Don't Grid (serves Pillar 2 — Pixel-Art Town Nurturing)

*Design test:* "When composition is ambiguous, choose organic and lived-in over rigid and optimized — the town is a place to nurture, not a spreadsheet to optimize."

The pixel grid is a technical constraint; the layout grid is an emotional trap. This principle distinguishes a football *town* (lived-in, charming) from a football *facility planner* (cold, optimal). It affects building placement, scene composition, and UI card layouts.

### Principle 3: Always Forward (serves Pillar 3 — Low-Pressure Long-Term Growth)

*Design test:* "When feedback tone is ambiguous, choose the warmer visual treatment — every setback must read as a story turn, not a punishment."

Losing a match should feel like a plot development, not a failure screen. Progress bars should always show *some* forward momentum. Color language should signal "adjust course" before "you failed."

---

## 2. Mood & Atmosphere

### Guiding Thread: The Day Arc

The emotional through-line uses a single metaphorical day — morning through starry night — mirroring the player's journey from new arrival to legendary town owner. Warmth always dominates over intensity.

### Seasonal Micro-Adjustment (Daily Management)

The 日常经营 state uses the in-game season to subtly shift lighting temperature:
- **Spring**: +200K warmer (~4800K), pale green-gold tone
- **Summer**: Neutral midday (~5000K), brightest and clearest
- **Autumn**: +300K warmer (~4700K), amber-rich tone
- **Winter**: -500K cooler (~5500K), crisp blue-white tone, slightly lower saturation

All seasonal variants stay legible — the shift is atmospheric, not gameplay-affecting.

### State-by-State Mood Targets

| State | Primary Emotion | Lighting | Energy |
|-------|----------------|----------|--------|
| **新手起步** (New Start) | 期待 — "Something good is about to begin" | Early morning golden (~3500K), soft long shadows, pale gold to soft blue sky gradient | Measured, slow |
| **日常经营** (Daily Management) | 安逸 — "This is my town, I know what to do" | Midday (~5000K ± season), balanced, full visibility | Steady, rhythmic |
| **比赛准备** (Match Prep) | 专注 — "I am the coach, this decision matters" | Late afternoon (~4000K), angled light, "locker room hour" | Deliberate, rising tension |
| **比赛进行** (Match In Progress) | 投入 — "I care about every moment" | Stadium floodlights at dusk, high contrast pitch vs. dark surroundings | Frenetic but readable |
| **赛后结算** (Post-Match) | 满足 — "That mattered, and now I move forward" | Sunset afterglow (~3700K), soft shadows, settling warmth | Decelerating, reflective |
| **阶段结算** (Phase Settlement) | 成就感 — "Look how far we've come" | Rich golden hour (~3000K), dramatic long shadows, warmest light | Contemplative pause |
| **内容解锁** (Content Unlock) | 惊喜 — "There's more to this world" | Dawn breaking — cool (~5500K) → warm (~3800K) transition | Burst then settle |
| **长期完成** (Endgame) | 自豪+怀旧 — "This is the town I built" | Late dusk into starry night, deep blue-purple with warm pinpricks of light | Slowest, reflective |

### Climax Moment: Championship Victory

> **User decision**: A World Cup / championship victory needs a separate, explosive emotional peak.

| Dimension | Target |
|-----------|--------|
| **Primary emotion** | 狂喜 (Euphoric triumph) — the loudest, brightest moment in the game |
| **Lighting character** | Full celebration burst: stadium at peak brightness, confetti pixel particles flooding the screen, fireworks in the night sky. Center-white hot (~6500K pure white spotlight) with warm gold confetti/particle highlights (~3500K). Highest contrast in the game. |
| **Descriptors** | Explosive, overwhelming, earned, unforgettable, cinematic |
| **Energy level** | Peak — the only state that goes full-screen celebration with no UI chrome. Lasts 8-12 seconds, then dissolves into 长期完成. |
| **Mood-carrying visual** | Team lifting trophy in center frame, pixel confetti cascading, crowd silhouettes cheering, stadium lights sweeping across the pitch. Score/stats fade in gently after the initial burst. Player names scroll with honorific framing. |

### Energy Arc

```
New Start     ████░░░░░░░░  measured, slow
Daily Mgmt    ██████░░░░░░  steady, rhythmic
Match Prep    ████████░░░░  deliberate + tension
Match Play    ████████████  frenetic but readable
Post-Match    ██████░░░░░░  decelerating
Phase Sett    █████░░░░░░░  contemplative pause
Unlock        ████████░░░░  burst then settle
Championship  ████████████  MAX — peak celebration
Endgame       ████░░░░░░░░  slowest, reflective
```

---

## 3. Shape Language

Shape language should make the town feel welcoming at a glance and understandable at a small scale. Every major shape choice should support the core rule — “a pixel-art town you want to live in, with a football team you want to coach” — by favoring warmth, readability, and gentle forward motion over sharp aggression or visual clutter.

### 3.1 Character Silhouette Philosophy

**Supports:** Visual Rule + **轻度足球经营** and **低压力长期成长**

- All characters must read clearly at thumbnail size. Silhouettes should be identifiable by **2–3 large shape cues**, not by facial detail, outline decoration, or small accessories.
- Use a **soft, sturdy base language** for most town residents: rounded heads, compact torsos, short-to-medium limb reads, and stable poses.
- **Player-side footballers** should read as energetic and coachable: slightly forward-leaning poses, clean limb separation, and a balanced mix of rectangle + curve shapes.
- **Town NPCs** should feel rooted in daily life: wider lower silhouettes, aprons/bags/hats as single bold read-shapes, and calmer upright posture.
- **Opponents** may use slightly more angular or vertically rigid silhouettes, but only as a contrast in discipline, not as villain coding.
- Avoid silhouettes that depend on thin props, spiky hair, or tiny costume motifs to communicate role.

### 3.2 Environment Geometry

**Supports:** Visual Rule + **像素小镇养成**

- The town should be built from a **controlled mix of simple geometric masses and soft organic variation**:
  - **Primary forms:** rectangles, low trapezoids, simple pitched roofs
  - **Secondary softeners:** rounded trees, curved awnings, uneven fences, planter boxes, hanging signs
  - **Tertiary detail:** sparse and clustered, never spread evenly across every surface
- Architecture should feel **grown, not perfectly optimized**. Slight asymmetry, staggered rooflines, offset pots, and varied greenery make the town feel lived-in.
- Curves belong mostly to **nature, fabric, and human touch**; straighter geometry belongs to **construction, roads, and UI-relevant structures**.
- Streets and building edges should stay legible first. Decorative clutter must never break the readable silhouette of roads, entrances, or focal facilities.
- Use **detail clustering** rather than constant detail density.

### 3.3 UI Shape Grammar

**Supports:** Visual Rule + **轻度足球经营**

- UI should **echo the town aesthetic, but stay cleaner than the world art**.
- Preferred UI container language:
  - rounded or lightly chamfered rectangles
  - solid, stable panels
  - clear edge separation
  - minimal ornament
- Avoid ornate frames, sharp fantasy spikes, or sleek sci-fi cuts.
- Buttons and panels should use **broad, calm shapes** with obvious click targets.
- Data-heavy areas should favor **straight alignment and consistent panel rhythm** over environmental mimicry. When town flavor and readability conflict, readability wins.

### 3.4 Hero Shapes vs Supporting Shapes

**Supports:** Visual Rule + **低压力长期成长**

- **Hero shapes** are the largest, cleanest, highest-contrast masses in a scene. They draw the eye first and represent the current emotional focus.
- Hero shapes should generally be:
  - simpler in outline
  - slightly larger in proportion
  - more isolated from nearby clutter
  - supported by cleaner negative space
- **Supporting shapes** should be softer, lower-contrast, and more repetitive.
- In environment scenes, use one dominant focal family at a time: a clubhouse silhouette, a player group, or a highlighted menu card.
- In UI, the current priority action should use the most confident shape read; secondary and tertiary actions reduce contrast or visual weight rather than adding decoration.

### 3.5 Practical Pixel-Art Rules

**Supports:** Visual Rule + all three pillars

- Design with silhouette first, interior detail second.
- Favor **big readable masses** over micro-texture.
- Limit each asset to one dominant shape idea and one supporting variation.
- If a shape reads as noisy when zoomed out, remove detail before increasing contrast.
- When in doubt, choose the version that feels warmer, clearer, and easier to understand in one glance.

---

## 4. Color System

Use a restrained, warm palette anchored in cream and gold, with red reserved for football emotion and moment emphasis. Colors should read as lived-in and trustworthy, not neon or broadcast-sports aggressive. Keep hue relationships stable across the game; communicate state changes mostly through temperature, value, and saturation shifts rather than swapping to entirely different palettes.

### Primary Semantic Palette

Suggested foundation swatches; exact production values may drift slightly by asset set, but the semantic roles should remain fixed.

| Color | Suggested Hex | Role |
|---|---:|---|
| Cream | `#F2E8D5` | Base light, paper, trim, readable negative space, soft highlights |
| Town Gold | `#D6B35A` | Warmth, pride, progression, featured UI accents, civic identity |
| Club Red | `#B84A4A` | Team spirit, key action emphasis, match-day energy, alerts in small doses |
| Calm Blue | `#5E7FA3` | Information, planning, schedule, secondary UI structure, cool evening balance |
| Field Green | `#6F8F5B` | Growth, health, training, nature, town liveliness |
| Earth Brown | `#8A6B4F` | Buildings, paths, wood, grounded everyday life |
| Slate Neutral | `#4C4A4A` | Text, outlines, shadow anchors, contrast control |

### Semantic Usage Rules

- **Red** means football passion, active choice, and high-attention moments. Use for badges, selected match actions, critical alerts, and score-related emphasis. Do not use red as a default fill color for menus or large environments.
- **Gold** is the emotional accent of the world: belonging, progress, earned pride, warm aspiration. Use for featured buttons, milestones, promotion states, club identity trim, and celebratory highlights.
- **Blue** means thinking, planning, and calm structure. Use for schedules, tooltips, inactive but available options, and evening-state balancing.
- **Green** means development, stability, and healthy growth. Use for training, player improvement, upkeep success, and town vitality.
- **White/Cream** means clarity, breathing room, and human warmth. Use for backgrounds, card surfaces, text panels, uniforms where a clean read is needed, and soft lighting accents.
- **Browns/Neutrals** mean home, routine, and material honesty. Use for architecture, frames, roads, wood, dirt, and grounding UI containers. Neutrals should prevent the palette from becoming sugary or overly saturated.

### Saturation and Contrast Rules

- Favor **mid-to-low saturation** in the world; let focal objects win through value contrast and isolation, not raw chroma.
- Reserve the strongest saturation for **small focal areas**: team crest, selected action, match banner, key progression reward.
- In sprites and tiles, prefer **2–3 clear value steps** over subtle hue noise.
- For cozy readability, highlights should lean **warm**, while shadows lean **neutral-to-cool**, not pure black.

### Seasonal and Game-State Temperature

Use **moderate seasonal shifts** only. The town should feel alive through the year, but always remain recognizably the same place.

- **Spring:** slightly fresher greens, lighter creams, cleaner morning light.
- **Summer:** warmer golds, fuller greens, sun-softened browns.
- **Autumn:** deeper browns, muted greens, gentle amber highlights.
- **Winter:** cooler creams, desaturated greens, slightly bluer shadows; keep windows, signs, and interiors warm so the town still feels inviting.

Game-state temperature should follow the approved day arc:
- **Daily management:** balanced warm-neutral palette with seasonal adjustment; calm and readable.
- **Match prep / late afternoon:** push gold and red slightly warmer to build anticipation.
- **Match play / dusk floodlights:** cool the environment toward blue-slate shadows; keep players, ball, UI prompts, and key highlights warmer/brighter so action reads instantly.
- **Post-match / sunset:** soften contrast and return to warm amber-pink light, emphasizing reflection over adrenaline.
- **Celebration / major success:** increase gold brightness first, then add controlled red accents; never jump to neon or harsh full-screen saturation.

### UI Palette

UI may be slightly cleaner than the world palette for readability, but it must still feel like it belongs to the same town.

- Use **cream/light neutral panels** with **slate text** as the default readable base.
- Use **gold** for primary positive emphasis: featured buttons, progression, promotions, rewards.
- Use **blue** for informational framing: tabs, schedules, secondary panels, filters.
- Use **green** for growth/status improvement.
- Use **red** sparingly for warnings, destructive actions, urgent match emphasis, and selected competitive beats.
- UI colors may be **slightly higher contrast and slightly less textured** than world assets to avoid muddy reading at PC monitor scale.
- Avoid large pure-red or pure-gold screens; anchor strong accents with cream and slate.

### Colorblind Safety

Color must never carry gameplay meaning by itself.

Required backups:
- **Red vs Green**: always pair with icon, shape, and text label. This is the highest-risk semantic pairing.
- **Gold vs Cream**: differentiate with value contrast, border treatment, and iconography, not hue alone.
- **Blue informational states**: pair with placement and pattern so they are not confused with neutral inactive states.

Implementation rules:
- Warnings use **red + alert icon + explicit label**.
- Improvements use **green or gold + upward/growth icon + text**.
- Match-critical states use **color + shape change + sound cue** where applicable.
- Selected buttons/cards should change by **outline thickness, fill value, and state label**, not only hue.

---

## 5. Character Design Direction

Characters should communicate “beloved small-town football life” before they communicate individual drama. The cast is viewed primarily as a readable management roster and social ecosystem, not as action heroes. Designs should favor warmth, routine, and role clarity over spectacle, aligning with the pillars of light football management, pixel-town nurturing, and low-pressure long-term growth.

### Archetype Direction
- **Footballers:** Young, healthy, optimistic silhouettes with simple athletic proportions and one or two memorable traits each. They should feel like local talents being developed, not celebrity superstars. Variance should come from posture, haircut, build, socks, boots, and training gear rather than extreme anatomy.
- **Town NPCs:** Shopkeepers, residents, kids, grounds staff, and fans should feel rooted in daily life. Their shapes should be softer, more practical, and slightly less athletic than footballers. They represent the town’s warmth and continuity.
- **Staff and Coaches:** Calm, dependable, and readable as organizers rather than athletes. Their silhouettes should be more vertical and composed, using clipboards, jackets, caps, whistles, tablets, or shoulder bags to signal function quickly.
- **Opponents:** Distinct clubs with their own discipline and local identity, but never framed as sinister or villainous. They should read as respected rivals from other communities. Their design language can be slightly cooler, sharper, or more structured than the home club, while staying grounded and human.

### Role Readability Rules
At a glance, the player should be able to separate **footballer / staff / town resident / opponent** within one second.
- **Footballers:** clearest leg shape, visible socks, shorts, and team-color accent placement.
- **Staff/Coaches:** longer outerwear, straighter posture, accessory-led silhouettes, less exposed leg shape.
- **Town NPCs:** broader clothing variety, aprons, bags, hats, bicycles, groceries, umbrellas, or work tools.
- **Opponents:** different kit pattern logic and club-color blocking from the home team; avoid using the home club’s signature red emphasis in equal dominance.
- Keep each character to **one primary role read + one secondary personal trait**. If too many details compete, simplify.

### Expression and Pose Style
- Target **moderately expressive**, not stiff and not cartoon-chaotic.
- Faces should read clearly in portrait form with warm, approachable emotions: focused, proud, tired, hopeful, relieved, disappointed, excited.
- In sprite form, expression should rely more on **pose, tilt, spacing, and rhythm** than facial detail.
- Poses should favor:
  - relaxed everyday motion in town,
  - composed planning energy for staff,
  - readable athletic intent for footballers,
  - sportsmanship and professionalism for opponents.
- Avoid extreme aggression, grotesque exaggeration, or melodramatic rage poses; this world is competitive but not hostile.

### Pixel Readability and LOD Philosophy
- Design for **silhouette first, detail second, texture last**.
- At gameplay distance, each character must still read through:
  - overall body block,
  - head/hair shape,
  - outfit contrast,
  - one signature accessory or color accent.
- Small sprites should use **clustered shapes and clear value separation**, not fine internal linework.
- Portraits may carry more personality detail, but must remain visually consistent with sprite simplification.
- If a trait disappears at gameplay zoom, it should not be required for role recognition.
- Animation should prioritize a few strong readable keys over many subtle in-betweens.

### Costume and Accessory Rules
- Clothing should support a **cozy football-town identity**: practical sportswear, small-town casualwear, weather-aware layers, and modest local flair.
- Home club costumes should feel cared for and aspirational, not luxurious. Think repaired, washed, organized, and loved.
- Town residents may echo club colors lightly through scarves, pins, shop signs, or seasonal accessories to reinforce community identity.
- Staff accessories should signal responsibility: notebook, whistle, lanyard, stopwatch, radio, medical bag.
- Opponent kits may be more formal, regional, or stylistically distinct, but should still feel believable within the same world.
- Avoid high-fashion fantasy, militaristic styling, villain coding, or overly flashy streetwear that breaks the grounded town tone.

### Character Detail Limits
- Give each recurring character a maximum of:
  - **1 silhouette trait**,
  - **1 color/accent trait**,
  - **1 personal accessory or habit cue**.
- Reuse visual systems consistently so the roster feels broad but manageable for MVP production.
- Reserve the strongest uniqueness for high-value surfaces such as key portraits, coach/staff leads, and standout club rivals.

### Identity Check
A successful character design should answer:
1. What is this person’s role?
2. Do they belong in this town’s football ecosystem?
3. Do they feel warm, readable, and worth investing in over time?

If the answer to any of these is unclear, reduce detail and strengthen role-first silhouette and color blocking.

---

## 6. Environment Design Language

The town should feel like a place that existed before success and will keep living after any single match. Environment art must support the fantasy of building a beloved football life through warmth, familiarity, and visible care rather than spectacle or scale.

### Architectural Style
- Use a **low-rise, lived-in small-town vernacular**: homes, corner shops, cafés, school buildings, training grounds, and civic spaces should feel practical, modest, and accumulated over time.
- Favor **simple base forms with handmade variation**: sloped roofs, awnings, patched walls, small courtyards, fences, utility poles, benches, and mixed-use storefronts.
- The town’s football culture should read as **community-grown, not corporate-built**. Stadium and training spaces should feel integrated into everyday life, not isolated as elite compounds.
- Show history through **incremental adaptation**: repainted facades, repaired signage, added shade covers, expanded seating, upgraded fencing, better-maintained paths. Growth should feel like the town investing in itself.
- Avoid architecture that feels too luxurious, futuristic, or hostile. Even aspirational spaces should remain welcoming and human-scale.

### Texture Philosophy
- Use **material simplification first, texture second**. Surfaces should read clearly by shape, palette, and value before fine pixel detail is added.
- Prefer a **warm, lightly painted pixel-art treatment** over hard-edged sterile tiling. Tiles should feel crafted and tactile, but not noisy.
- Keep texture clusters selective: edge wear, brick variation, grass breakup, and fabric folds should appear in **controlled pockets**, not across every pixel.
- Large surfaces should stay calm. One or two material cues are enough to communicate plaster, wood, brick, concrete, dirt, or grass.
- Avoid overly crisp high-frequency detailing that makes the town feel technical or busy. The world should feel soft, readable, and restful at gameplay distance.

### Prop Density and Readability
- Use **clustered density**, not even density. Let props gather in believable pockets, with clear visual breathing room between them.
- **Calm zones**: navigation routes, building fronts, match-view spaces, and UI-heavy screens should stay sparse and legible.
- **Medium-density zones**: residential corners, shop exteriors, and school/community areas can carry personality through bikes, crates, flower pots, laundry, notice boards, and benches.
- **Higher-density zones**: training sidelines, club-adjacent streets, market pockets, and festival/match-day spaces can hold more overlap, layering, and football-related clutter.
- Do not place high-contrast prop clusters where they may falsely imply interaction. If a building is not playable or clickable, its dressing should support mood and identity without reading like a prompt.

### Environmental Storytelling
- Football identity should appear as part of daily life: worn goalposts, ball scuffs on walls, hand-painted banners, local club colors, practice cones, repaired nets, posters, laundry, sponsor signs, and small memorials to past wins.
- Show long-term growth through **care, pride, and gradual improvement**, not instant expansion. Better-maintained grass, repainted lines, tidier storefronts, fuller notice boards, upgraded seating, and more community decoration all communicate progress.
- Let different districts show different relationships to football:
  - homes and streets: personal attachment
  - shops and cafés: local support
  - school/community areas: youth aspiration
  - training/match spaces: discipline and ambition
- Keep storytelling optimistic and grounded. The town should feel invested, not commercialized or over-designed.

### MVP Home-Feeling Priorities
- Even before any full construction or upgrade systems exist, the town must already have **recognizable home anchors**: a club-facing street, a training ground edge, a community gathering spot, and a few memorable residential/shopfront silhouettes.
- Reuse those anchors consistently so players build emotional familiarity through repetition.
- Prioritize **state variation over structural complexity**: time of day, seasonal dressing, flags, lights, crowd presence, bicycles, laundry, benches, and match-day decorations can make the town feel alive without implying simulation depth that does not yet exist.
- A small number of highly readable landmark spaces will sell “home” better than a large map full of generic detail.
- Core rule: the town should always feel like **somewhere you want to return to**—supporting the pillars of light football management, pixel-town nurturing, and low-pressure long-term growth.

---

## 7. UI/HUD Visual Direction

The UI/HUD should read as the town’s organized “management layer”: visually related to the world, but cleaner, flatter, and more disciplined. It must support fast reading first and charm second, reinforcing warmth without adding decorative noise.

### Diegetic vs. Screen-Space Balance
- Critical information stays in fixed screen-space HUD regions only: persistent economy/time/status information in the top bar, primary navigation in the bottom band, and main decision content in the center.
- Diegetic overlays may be used sparingly for contextual labels or light town feedback, but never as the sole carrier of important state.
- If a player must make a management decision from it, it must remain readable without searching the world.

### Typography Direction
- Use a pixel font with friendly, open proportions rather than a sharp arcade feel.
- Prioritize medium and semibold weights over heavy display weights.
- Hierarchy should stay simple and stable:
  - large headings for screen titles
  - medium labels for sections and tabs
  - highly legible small text for data rows, costs, timers, and tooltips
- Numbers must be especially crisp and easy to scan at a glance.
- Avoid condensed styles, excessive outline treatments, or decorative mixed-font pairing.

### Iconography Style
- Icons should be simple, silhouette-first, and readable at small sizes, with minimal interior detail.
- They should feel civic and practical rather than sporty-aggressive: clear football, town, economy, training, growth, and schedule symbols with soft geometry and consistent stroke mass.
- Use icons to accelerate scanning, not replace text entirely; pair unfamiliar actions or systems with labels.

### Panel, Frame, and Button Style
- Panels should use broad, calm shapes with gentle corner treatment, subtle inner contrast, and restrained border definition.
- They may echo painted wood signs, notice boards, or enamel placards in proportion and palette, but should not imitate physical materials so literally that they reduce clarity.
- Buttons should be large, stable, and obviously interactive, with clear hover, pressed, selected, and disabled states.
- Ornament should be minimal; spacing, contrast, and grouping should do most of the work.

### Animation Feel
- UI motion should feel calm, light, and supportive.
- Favor short fades, small slides, soft pop-ins, and gentle scale changes over snappy bounces or flashy transitions.
- Animation should confirm state changes and guide attention, not perform for its own sake.
- Celebratory motion should be reserved for milestones, upgrades, and positive long-term progress.

### Maintaining World Identity Without Losing Readability
- The HUD should borrow the world’s warmth through palette family, rounded shape logic, and modest handcrafted character, while staying cleaner in value contrast, edge definition, and information spacing.
- In practice, this means less texture, fewer decorative clusters, clearer silhouettes, and stricter alignment than world art.
- The town can feel cozy and lived-in; the interface must feel trustworthy, tidy, and instantly readable.

### Accessibility and Input Clarity
- All interactive UI states must remain distinct through value contrast, shape change, and focus treatment, not color alone.
- Hover, focus, and selected states should be visually unambiguous for mouse and keyboard navigation.
- Text and icon sizes should favor relaxed reading over density.
- No visual treatment should conflict with the approved MVP HUD shell or add clutter that competes with core management tasks.

---

## 8. Asset Standards

Asset standards should protect three things first: pixel readability, production consistency, and clean handoff. Every asset must read clearly at intended gameplay size, sit comfortably inside the approved warm cream/gold visual system, and arrive production-ready without requiring downstream cleanup.

### File Format Preferences
- **Sprites, tiles, icons, UI art, portraits, and VFX sheets:** author and export as **PNG**.
- **Layered working files:** may use team-native editable formats (`.aseprite`, `.psd`, `.kra`), but production handoff must always include flattened runtime-ready PNG exports.
- **Large promotional or paintover reference art:** may use higher-fidelity working files, but any in-game implementation asset must be delivered as pixel-clean PNG.
- Avoid lossy formats for in-game 2D art. Do not use JPEG for production sprites, UI, tiles, or portraits.
- For pixel-authored runtime assets, import with nearest-neighbor sampling only. Do not allow filtering, blurry scaling, or lossy compression that softens pixel edges.

### Naming Convention
Use a functional, searchable runtime naming pattern:

`[category]_[name]_[variant]_[size].[ext]`

Examples:
- `char_striker_idle_small.png`
- `env_clubhouse_front_medium.png`
- `ui_btn_primary_hover_small.png`
- `vfx_confetti_burst_small.png`

Rules:
- Use role/object first, decorative descriptors second.
- Variants describe **state, facing, or sequence**, not personal shorthand.
- Size labels should reflect approved production tiers, not arbitrary artist preference.
- Re-exported revisions replace the same logical asset name unless the runtime role truly changed.

### Pixel-Perfect Scaling Rules
- Assets must be authored against a consistent base pixel grid and displayed at integer scale in gameplay views whenever possible.
- Do not hand off assets that only read correctly at fractional scaling.
- Avoid sub-pixel detail, anti-aliased diagonals, and 1-pixel noise clusters that depend on smooth scaling to look correct.
- If an asset requires non-integer runtime scaling to fit, it should be re-authored at the correct native size instead of relying on engine scaling.
- Outline thickness, icon strokes, and key silhouette breaks must remain readable at the smallest expected in-game display size.

### Resolution and Size Tiers
This project uses **tiered target sizes with small tolerance bands**, not purely relative guidance and not rigid one-off sizing for every asset. The goal is consistent hierarchy with enough flexibility for practical production.

Recommended production tiers:
- **UI icons:** use a strict small-size ladder, with `16 / 24 / 32 px` as the preferred set.
- **Characters:** keep gameplay sprites within one shared small-to-medium height family, with only modest role-based variation. Importance should come from silhouette and composition, not dramatic size inflation.
- **Environment props:** use only **small / medium / landmark** tiers.
- **Tiles:** author the world on one primary tile-size family per gameplay layer; do not mix unrelated tile dimensions in the same layer.
- **Portraits:** use one standard roster/display size, with one optional enlarged dialogue/detail size if needed.
- **VFX:** keep most gameplay effects in **small / medium** tiers; large sheets should be reserved for rare milestone celebrations only.

Ceiling guidance:
- Keep most gameplay sprite sheets at `1024x1024` or below.
- Use `2048x2048` only when a full set must remain together for batching or animation management.
- Avoid `4096x4096` textures for routine 2D production assets.

### Palette and Value Discipline
- Begin from the approved core palette. Add only limited local ramps where needed for material separation, district variation, or seasonal variants.
- Do not solve readability with runaway saturation.
- Value grouping should carry readability first; hue supports it second.
- Reserve the strongest saturation for focal points such as team crests, selected actions, match banners, or major rewards.
- UI assets must stay cleaner and slightly higher-contrast than world assets.

### Outline, Padding, and Detail Rules
- Use one outline philosophy per asset family. Characters and interactable props should use stable, readable outline treatment; UI should use cleaner, lighter edge treatment than world art.
- All exported sprites and sheets must include consistent transparent padding so animation, batching, and placement do not clip edges.
- Large transparent margins are not acceptable in production atlases.
- Favor big readable masses over micro-texture.
- Cluster texture and decoration in controlled pockets rather than spreading high-frequency detail evenly across a surface.
- If an asset becomes noisy when viewed at gameplay size, reduce detail before increasing saturation or outline weight.

### Animation Sheet Organization
- Keep each sheet focused on **one asset, one motion family, one scale tier**.
- Group states predictably: idle, walk, work, react, celebrate, and similar families.
- Maintain consistent frame box size and pivot logic within a sheet.
- Reserve generous spacing between frames; never pack sheets so tightly that export cleanup becomes manual labor.
- If an animation requires exceptions, document them in the handoff notes explicitly.

### Atlas, Material, and Draw-Call Discipline
- Assets that appear together frequently should share atlas space and material settings where practical.
- Prefer small-to-medium sprite sheets grouped by usage domain, not giant catch-all atlases.
- Split sheets by usage pattern:
  - characters by faction/set
  - tiles by district/biome
  - UI by screen family
  - VFX by effect family
- Minimize unique materials for 2D art.
- Prefer palette swaps, shader parameters, or reused shared materials over duplicating textures for small visual variants.
- Avoid one-off materials for minor props or UI elements unless they provide meaningful value.
- Keep transparency-heavy overlap under control; layered alpha stacks are a common hidden overdraw cost in 2D scenes.

### Memory-Bloat Prevention Rules
- Do not import source files larger than needed “just in case.”
- Do not store multiple exported sizes of the same asset unless they are genuinely distinct runtime uses.
- Do not duplicate textures to bake hover states, glow states, seasonal states, or color variants if the same result can be achieved through palette/state-driven methods.
- Texture variants must be deliberate; do not duplicate a full atlas if only a few regions change.
- Any asset family that repeatedly exceeds intended sheet size should be reviewed for reuse opportunities, sheet splits, or simplification.
- Portraits, splash art, and UI illustrations must not silently consume memory budget reserved for gameplay readability.

### Godot-Specific Handoff Notes
- Deliver exported runtime assets ready for Godot import, with consistent naming and stable dimensions so reimport does not break animation regions, atlas references, or UI layouts.
- Keep pivot/origin conventions consistent within each asset class, especially for character frames, props, and UI components.
- If an asset is intended for region slicing, tilesets, or 9-slice usage, that intent must be declared at handoff.
- If an asset depends on shader-driven behavior, provide the required blend mode, expected backdrop, and any palette/emission assumptions at handoff.
- Alpha should stay clean and controlled. Avoid semi-transparent fringe pixels that create halos in pixel art.

### Handoff Checklist
An asset is not ready for implementation unless it is:
- correctly named
- exported to the approved runtime format
- authored for intended in-game scale
- readable at gameplay distance
- padded and boxed correctly for atlas/animation use
- palette-disciplined and visually aligned with its asset family
- free of blurry scaling and fringe artifacts
- documented if it needs special slicing, pivot, shader, or exception handling

### Performance Guardrails
Asset production must support the project target of:
- **60 fps**
- **16 ms frame time**
- **500 draw calls per frame**
- **512 MB total memory ceiling**

Any asset set that materially increases draw-call count, atlas fragmentation, overdraw, or texture memory should trigger review before acceptance.

---

## 9. Style Prohibitions / Reference Direction

### Reference Direction

| Reference | Draw From This | Avoid / Diverge From This |
|---|---|---|
| **Kairosoft town-management games** | Use their discipline in **micro-scale readability**: buildings should read by function in one glance, sprite poses should communicate role before detail, and district layouts should stay legible even when densely packed. Good lesson: **repeat simple base tiles, then vary with 1–2 identity props** rather than over-detailing every cell. | Do not copy their **exact chibi proportions, boxy storefront silhouettes, toy-like saturation, or UI window framing**. Avoid making the town feel like a parody board game; 《足球小镇》 should feel warmer, more grounded, and more regionally lived-in. |
| **Stardew Valley** | Draw from its **seasonal palette shifting**, restrained pixel contrast, and use of **small prop storytelling** to imply maintenance, routine, and local history. Good production lesson: make season changes read through **palette temperature, foliage density, and ground accents**, not full asset replacement. | Avoid drifting into a **farm-first rustic fantasy**. Do not let overgrowth, wilderness dominance, or heavy midnight-blue scenes overpower the football-town identity. The town should feel organized and civic, not remote or shabby. |
| **Studio Ghibli small-town films** *(Whisper of the Heart / From Up on Poppy Hill)* | Borrow the **human-scale composition**: streets framed by fences, signs, trees, bikes, laundry, and storefront edges; warm windows against cooler evening air; everyday transition spaces that make a town feel inhabited. Use this as a rule for **approach shots and hub screens**: always include a sense of arrival and local routine. | Do not imitate **painterly rendering, soft brush textures, or nostalgic haze over every scene**. This project should preserve clean pixel structure and management-game clarity, not become a watercolor illustration. |
| **Football Manager** | Use it as a **UI hierarchy reference**, not a style reference: dense information should be organized by spacing, grouping, and one clear accent color per priority level. Good lesson: **actionable data must stand out before decorative chrome**. | Avoid the **cold spreadsheet feel**, dark corporate dashboards, and text-heavy compression that makes the player feel like they are operating software instead of caring for a town. Our UI should stay softer, friendlier, and more spatially breathable. |
| **Local football club posters / community sports noticeboards** | Draw from **civic pride graphics**: banners, match posters, painted signs, youth-team flyers, scarves, pennants, club crests, and large readable numerals. This is the right source for making football feel woven into town life rather than isolated in the stadium. | Avoid **real-club mimicry, sponsor-wall clutter, aggressive pro-sports gloss, or esports-style lightning/flame graphics**. The football identity should feel local, communal, and handmade before it feels commercial. |

### Style Prohibitions

- Do **not** use neon cyberpunk palettes, cold sci-fi lighting, or nightclub contrast.
- Do **not** push the town into grime, despair, or economic-collapse visuals; this world may be modest, but it should never feel hopeless.
- Do **not** copy Kairosoft building silhouettes, character proportions, façade layouts, or UI framing closely enough to read as homage-by-replication.
- Do **not** overfill scenes with uniform prop noise; every screen needs a clear primary read, secondary support, and quiet background space.
- Do **not** mix rendering languages carelessly: no HD gradients, painterly blur, vector-clean UI panels, or glossy effects sitting on top of a strict pixel world.
- Do **not** let football spectacle dominate the whole game; floodlights, dramatic night contrast, and big-match energy should be reserved for special peaks, not daily town play.
- Do **not** use oversized super-deformed heads or gag-heavy caricature that undermines the player’s emotional investment in residents and club staff.
- Do **not** default to dark-theme management UI; the baseline interface should stay bright, warm, and readable for long play sessions.
