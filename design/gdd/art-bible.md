# NOVA SCOUT — Art Bible

**Version:** 2.0 (Dark Directive)
**Art Director:** Star-Finder Studio
**Supersedes:** v1.0 warm-Technicolor direction
**Binding creative source:** `design/gdd/dark-directive.md` — implementation record in `production/dark-directive-changelog.md`

---

## 1. Overview

NOVA SCOUT's visual language is **retrofuturist pixel art with CRT soul — turned toward the dark**. The v1.0 bible drew from the earnest wonder of 1950s pulp covers; v2.0 keeps the phosphor-and-scanline skeleton (native 320×180, analog instrumentation, monospace readouts) and trades Technicolor wonder for the working-class dread of *Alien* (1979). Space is nearly black. Color is rationed. Red is reserved for threat. Darkness is a mechanic (the visibility veil in sectors 3–5), and the CRT overlay is an actor: analog interference ramps with threat. Combat feedback stays maximal — hitstop, shake, flash, lingering embers — because dread only works against contrast.

## 2. Player Fantasy

You are a working pilot on old hardware, not a hero in a chrome rocket. The ship is weathered steel; the HUD is dimmed phosphor green, engineered in an era when instruments were built to be trusted — and old enough that they can't save you. The void is hostile and information-poor: enemies emerge from murk, announced by tracker blips and static before they are ever seen. When a habitable world is finally revealed, it should read as a genuine dawn — brighter *because* everything around it got darker.

### Core Visual Pillars (binding)

1. **The void is hostile.** Near-black space, sparse dim starfield, desaturated sickly nebulae. Visibility itself is scarce in sectors 3–5.
2. **Red is rationed.** Blood-red appears only on threat: The Silence's eye, emergency states, sector-4 tint, critical UI. Nothing decorative is red.
3. **Analog everything, dimmed.** Phosphor-green UI retained but dimmed ~15% from v1.0; amber for warnings. The Nostromo school of instrumentation.
4. **Interference is fear.** The CRT overlay's static, chroma wobble, and sync-roll are driven by threat level — the screen itself gets scared before the player does.
5. **Juice the kill.** Hitstop, rotation shake, muzzle flash, and embers that cool from orange to deep red. Power in the loud, fear in the quiet.
6. **Resolution discipline.** Native **320×180** (16:9), integer-scaled. Every sprite must be beautiful at native resolution.

## 3. Detailed Rules

### 3.1 Color Palette

Anchor values (design reference from `dark-directive.md`; per-entity constants live in the scripts cited below):

| Name | Hex / value | Use |
|------|-----|-----|
| Void Black | `#04050A` (project clear color) | Background, space |
| Star White (dimmed) | `#C8D2E8` range | Sparse starfield — fewer, dimmer stars than v1.0 |
| Probe Cyan | `#00E5FF` | Player laser, energy, scan beam (unchanged — player light is precious) |
| Phosphor Green (dim) | `#39FF14` dimmed ~15% in UI constants | Primary UI text, readouts, tracker |
| Amber Warning | `#FFB000` | Fuel, secondary UI, warning states |
| Threat Red | `#C41E1E` family | **Reserved:** Silence eye, hull-critical states, sector-4 emergency tint, mines |
| Alien Blood-Violet | `#4D0080`–`#8C14A6` range | Alien hulls and glows — shifted from v1.0 hot magenta toward blood-violet |
| Gold Shore | `#FFD700` | Final planet, true-ending reveal — the one unrationed warmth |

**Nebula tints per sector** (implemented in `src/core/game_world.gd`):

| Sector | Tint | Feel |
|---|---|---|
| 1 | Cold blue-grey `Color(0.07, 0.10, 0.20)` | The last safe light |
| 2 | Bruise violet `Color(0.11, 0.06, 0.15)` | Something is off |
| 3 | Sickly phosphor murk `Color(0.05, 0.13, 0.10)` | Wrong green-grey |
| 4 | Rust / dried blood `Color(0.13, 0.05, 0.03)` | Enemy space |
| 5 | Near-black violet `Color(0.08, 0.04, 0.10)` | Almost nothing left |

**UI palette:** near-black green panel backgrounds (`Color(0.0, 0.02, 0.0, 0.82)`), dim phosphor frames, active text in dimmed phosphor green, amber warnings, red only for critical.

### 3.2 Darkness Veil (sectors 3–5)

A radial visibility falloff centered on the player (`src/ui/darkness_veil.gd` + `assets/shaders/post_darkness_falloff.gdshader`):

- Fully-lit radius per sector: **3 = 95 px (heavy), 4 = 120 px (moderate + red emergency tint), 5 = 80 px (near-black)**.
- Lit→dark transition band `edge_softness = 55 px`; darkness ceiling `max_alpha = 0.82` (never a hard black wall).
- Boost flares the light radius **+20%**; scanning tightens it (scan pressure made visible).
- Player and enemy projectiles render **above** the veil — bolts carry their own glow.
- The Mothership arena is exempt: the boss is the light source.
- Enemies emerge from murk; first read is silhouette + glow, not full sprite.

### 3.3 CRT Overlay — Interference as Fear

Rewritten as a true post-process on the screen texture (`src/ui/crt_overlay.gd`, `assets/shaders/crt_overlay.gdshader`):

- Base treatment: scanlines (`scanline_strength = 0.12`), vignette (`vignette_strength = 0.35`), phosphor green-black shadow tint, bloom on bright objects.
- **`interference`** uniform (0–1): static specks, horizontal line tearing, chroma wobble, and widened chromatic aberration. Driven by the aggregate threat level — ramps when The Silence is near, on hull-critical, and during scan climaxes.
- **`signal_roll`** uniform (0–1): a horizontal sync-loss band that rolls down the screen, pulsed on major events (stalker telegraph, sector transitions, boss phase changes).
- Chromatic aberration on hit retained from v1.0 (single-frame ±2 px channel split), now also widened by interference.

### 3.4 Sprites

Resolution and style rules carry over from v1.0: clean pixel art, 1 px dark outlines on interactive sprites, no outlines on background elements, 8–12 fps animation choppiness intentional.

**Player craft — Survey Probe Seven.** 16×22 px, nose-up. Weathered steel hull replaces v1.0's warm silver-white — scuffed panels, faded "SP-7" monospace marking. (The menu tagline "you are the twelfth" counts the eleven silent probes plus you; the craft's registry name stays Probe Seven per `src/gameplay/player/player.gd`.) Red emergency cabin glow below 40% hull; damage sparks below 25%. States: idle, thrust (3-frame loop), left/right bank, hit flash, 8-frame explosion. Laser gains a 2-frame muzzle nose flash.

**Enemies.** Hulls in deep blood-violet, glows shifted off hot magenta (constants in `src/gameplay/enemies/*.gd`):
- **Alien Scout:** 12×10 px saucer, violet hull, dim red eye-lights.
- **Alien Warrior:** 18×14 px fin, violet body, glowing stripe.
- **Alien Destroyer:** 32×28 px beetle carapace, visible weapon ports.
- **Alien Elites (3 variants):** 24×22 px, distinct silhouettes; charge/blink accents in amber-gold (readability trumps palette here).
- **The Silence (stalker):** near-invisible at 2–8% shimmer alpha; pale shimmer outline, violet edge, and a single blood-red eye `Color(0.95, 0.12, 0.12)` — the only reliable read while cloaked. Decloaks fully for its attack run.
- **Mothership:** 160×80 px multi-part, near-black hull, ember-orange reactor veins; lights its own arena.

**Asteroids, projectiles:** unchanged sizes/variants from v1.0 (3 sizes × 3 variants; player laser 2×8 px cyan; alien bolts violet/pink pulses; Mothership sweep deep red with white core).

### 3.5 Backgrounds

Four parallax layers as v1.0, with v2.0 dressing: sparser, dimmer starfield; nebula wisps per the sector tint table; sector 4 keeps its alien architectural silhouettes, now barely lit; sector 5 is no longer "overwhelmingly vivid" — it is the darkest sector, with the Mothership and the final planet as the only brightness.

**The wrong star:** from sector 2 onward, 40% chance per sector that one background star drifts against the parallax. No gameplay effect. It's nothing. Probably.

### 3.6 HUD & UI

Philosophy stays *Mission Control, 1962* — instruments built by proud engineers — but the phosphor is dimmed and the room is dark. Layout as v1.0 (hull/shield top-left, sector/score top-right, fuel and ordnance bottom), plus:

- **Threat Tracker** (bottom-right, `src/ui/threat_tracker.gd`): circular sweep radar in dim phosphor greens; solid blips for tracked contacts, flickering **ghost blips** for The Silence; blips render for anything queued within 100 px above the viewport.
- **Streak fuse:** visible decay bar under the streak label.
- **Danger Pay flag:** red indicator + deep vignette + HUD flicker below 25% hull.
- **Log fragment panel:** typewriter-reveal panel for recovered probe transmissions, degraded phosphor text.
- Scan bar as v1.0 (arc gauge, phosphor green), with the screen iris-darkening ~20% while scanning.

Fonts unchanged: pixel monospace display font, uppercase Courier-style body text, dedicated digit sprites.

### 3.7 Animation & Kill Feedback

- Frame rates as v1.0 (8 fps environment/enemies, 12 fps player, 60 fps UI).
- **Hitstop:** 40 ms on kill, 90 ms on elite/boss kill, 55 ms on player hit.
- **Screen shake:** heavier curve than v1.0, now includes ±0.4° rotation.
- **Explosions:** debris burst plus **lingering embers that cool from orange to deep red** over their lifetime, on all ship kills.
- Enemy knockback on laser hits (light classes only).
- Warp/planet-reveal sequences as v1.0; planet reveal remains the emotional bright spot.

## 4. Formulas

- **Darkness falloff:** `alpha(d) = max_alpha × smoothstep(light_radius, light_radius + edge_softness, d)` where `d` = pixel distance from player; `max_alpha = 0.82`, `edge_softness = 55`, `light_radius` per sector {3: 95, 4: 120, 5: 80} (from `assets/data/dread.json`). Boost: `light_radius × 1.2`.
- **Interference drive:** `interference = clamp(threat_aggregate, 0, 1)` where threat aggregate accumulates stalker proximity, hull-critical state, and scan progress; aberration widens by `+0.0025 × interference`.
- **Ember cooling:** ember color lerps orange → deep red over particle lifetime (~0.8 s base explosion, embers linger beyond).
- **Hitstop:** `{kill: 40 ms, elite_kill: 90 ms, player_hit: 55 ms}` — data-driven from `dread.json`.
- **Silence shimmer:** cloaked alpha oscillates in the 0.02–0.08 band; eye alpha independent (always faintly visible).

## 5. Edge Cases

- **Projectile visibility:** darkness never hides bolts — all projectiles draw above the veil with self-glow. A player death to an invisible bolt is a bug.
- **Boss arena:** darkness veil disabled in the Mothership arena; the boss must remain fully readable through all three phases.
- **Red discipline vs. readability:** elite charge telegraphs stay amber-gold even though they are threats — telegraph readability beats palette purity. Red is reserved for *states* (critical, emergency, the eye), not attack telegraphs.
- **Hitstop & shake opt-out:** hitstop respects `screen_shake = 0`; all dread visuals (darkness, interference, vignette) scale with the `dread_intensity` accessibility setting (0–1).
- **High-contrast tracker:** tracker honors the existing `color_friendly` colorblind setting.
- **Photosensitivity:** signal_roll pulses and interference specks stay below rapid-flash thresholds; no full-screen white flashes in v2.0 except the retained single-frame hit flash.

## 6. Dependencies

- `design/gdd/dark-directive.md` — binding creative direction (this bible implements §4.2)
- `src/ui/crt_overlay.gd` + `assets/shaders/crt_overlay.gdshader` — interference/signal_roll
- `src/ui/darkness_veil.gd` + `assets/shaders/post_darkness_falloff.gdshader`
- `src/ui/threat_tracker.gd`, `src/ui/hud.gd` — tracker, streak fuse, danger-pay flag
- `src/core/game_world.gd` — nebula tints, starfield, wrong star, hitstop, embers
- `src/gameplay/enemies/*.gd` — per-enemy color constants, The Silence shimmer
- `assets/data/dread.json` — darkness radii, hitstop, tracker tuning
- `design/gdd/audio-design.md` — audiovisual sync on telegraphs (decloak shriek ↔ CRT roll)

## 7. Tuning Knobs

All in `assets/data/dread.json` or shader uniforms unless noted:

| Knob | Default | Location |
|---|---|---|
| `darkness.sector_radius` | {3: 95, 4: 120, 5: 80} px | dread.json |
| `darkness.edge_softness` | 55 px | dread.json |
| `darkness.max_alpha` | 0.82 | dread.json |
| `scanline_strength` | 0.12 | crt_overlay.gdshader |
| `vignette_strength` | 0.35 | crt_overlay.gdshader |
| `interference`, `signal_roll` | runtime-driven 0–1 | crt_overlay.gd |
| `hitstop.kill_ms / elite_kill_ms / player_hit_ms` | 40 / 90 / 55 | dread.json |
| Wrong-star chance | 0.4 per sector (≥2) | game_world.gd |
| Silence shimmer alpha band | 0.02–0.08 | the_silence.gd |
| `dread_intensity` | player setting 0–1 | settings menus |
| Boost light flare | +20% radius | darkness_veil.gd |

## 8. Acceptance Criteria

1. Project clear color is `#04050A`; no sector background renders brighter than sector-1's cold blue-grey tint.
2. Blood-red appears on screen only during threat states (Silence eye/telegraph, hull-critical, sector-4 tint, mines, critical UI) — audit via sector fly-through.
3. Sectors 3–5 render the darkness veil at 95/120/80 px radii; all projectiles remain visible above the veil; Mothership arena is exempt.
4. CRT interference visibly ramps before 100% of Silence decloaks and while hull < 25%; signal_roll pulses on stalker telegraph and boss phase changes.
5. Kills produce hitstop (40/90 ms) and ember particles that cool orange→red; player hits produce 55 ms hitstop; all respect `screen_shake = 0` and `dread_intensity`.
6. Player ship shows red cabin glow below 40% hull and damage sparks below 25%.
7. Threat tracker renders solid blips for contacts within 100 px lookahead and flickering ghost blips for The Silence.
8. All sprites read cleanly at native 320×180; enemy silhouettes are distinguishable in murk by glow color alone.
9. The wrong star, when present, drifts against parallax and has no collision or gameplay effect.
10. Discovery/ending sequences remain visibly warmer than every surrounding scene (the dawn contrast survives the dark pass).
