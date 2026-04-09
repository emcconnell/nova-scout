# NOVA SCOUT — Epic & Task Master List

**Version:** 1.0  
**Total Estimated Tasks:** 187  
**Build Order:** Sequential epics; tasks within each epic can be parallelized  

---

## EPIC 0 — Project Foundation *(Do first)*

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E0-01 | Initialize Godot 4.3 project, configure project.godot settings | P0 | 1h |
| E0-02 | Create full directory structure (src/, assets/, scenes/, etc.) | P0 | 0.5h |
| E0-03 | Set up input map (all actions: move, fire, boost, scan, etc.) | P0 | 0.5h |
| E0-04 | Configure display: native 320×180, scale mode integer 4× | P0 | 0.5h |
| E0-05 | Create AudioBus layout (Master, Music, SFX, UI) | P0 | 0.5h |
| E0-06 | Create GameManager autoload (state enum, basic structure) | P0 | 1h |
| E0-07 | Create AudioManager autoload (stub, wire up buses) | P0 | 1h |
| E0-08 | Create SaveManager autoload (high score, settings persistence) | P0 | 1h |
| E0-09 | Create ObjectPool utility class | P0 | 1h |
| E0-10 | Set up git repository, .gitignore for Godot | P0 | 0.5h |
| **E0 Total** | | | **~8h** |

---

## EPIC 1 — Player Craft

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E1-01 | Create Player scene (CharacterBody2D structure) | P0 | 1h |
| E1-02 | Implement 8-directional movement with configurable speed | P0 | 2h |
| E1-03 | Implement boost (speed multiplier + fuel drain) | P0 | 1h |
| E1-04 | Implement hull stat + damage + death signal | P0 | 1.5h |
| E1-05 | Implement shield stat + regen timer + hit flash | P0 | 2h |
| E1-06 | Implement fuel stat + drain rate + empty state | P0 | 1.5h |
| E1-07 | Implement laser weapon (fire rate, pooled projectiles) | P0 | 2h |
| E1-08 | Implement missile weapon (limited ammo, homing logic) | P0 | 3h |
| E1-09 | Implement EMP pulse (area stun, bullet clear, cooldown) | P0 | 2h |
| E1-10 | Screen bounds: horizontal wrap, vertical lock | P0 | 1h |
| E1-11 | Player sprite: idle, thrust, bank L/R, hit flash, explosion | P1 | 3h |
| E1-12 | Engine glow shader effect | P1 | 1.5h |
| E1-13 | Shield hexagon visual + hit shimmer | P1 | 1.5h |
| E1-14 | Player explosion animation (8 frames, debris) | P1 | 2h |
| **E1 Total** | | | **~26h** |

---

## EPIC 2 — Hazards

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E2-01 | Asteroid class: 3 sizes, random velocity, rotation | P0 | 2h |
| E2-02 | Asteroid split logic (large→medium→small) | P0 | 2h |
| E2-03 | Asteroid collision with player (damage per size) | P0 | 1h |
| E2-04 | Asteroid sprites: 3 sizes × 3 variants, 4-frame rotation | P1 | 4h |
| E2-05 | Asteroid loot drop (Fuel Cell 30%, Crystal 20%) | P0 | 1h |
| E2-06 | Space Mine: stationary, proximity trigger, chase, explode | P0 | 2.5h |
| E2-07 | Space Mine sprite + blinking warning light animation | P1 | 1h |
| E2-08 | Debris Cloud: area2D, slow + damage over time | P0 | 1.5h |
| E2-09 | Debris Cloud sprite: semi-transparent particle field | P1 | 2h |
| **E2 Total** | | | **~17h** |

---

## EPIC 3 — Enemies

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E3-01 | EnemyBase class: HP, damage, signals, drop table | P0 | 2h |
| E3-02 | Alien Scout: sine-wave movement, single laser, retreat-on-hit | P0 | 3h |
| E3-03 | Alien Warrior: sweep movement, 3-shot burst, front shield | P0 | 3h |
| E3-04 | Alien Destroyer: slow movement, 5 attack patterns, shield pulse | P0 | 5h |
| E3-05 | Alien Elite A (Interceptor): teleport blink, aimed spread | P0 | 3h |
| E3-06 | Alien Elite B (Artillery): stationary, aimed volleys | P0 | 2.5h |
| E3-07 | Alien Elite C (Swarm Commander): spawn scouts, homing missiles | P0 | 3h |
| E3-08 | Mothership Phase 1: rotating lasers, scout spawning, missile volley | P0 | 5h |
| E3-09 | Mothership Phase 2: shield drone, gravity pulse, laser speed up | P0 | 4h |
| E3-10 | Mothership Phase 3: enrage, desperation sweep, Destroyer support | P0 | 3h |
| E3-11 | Mothership weak point: reactor core cycle, 3× damage window | P0 | 2h |
| E3-12 | Scout sprite (8 frames incl. death) | P1 | 2h |
| E3-13 | Warrior sprite (8 frames incl. death) | P1 | 2h |
| E3-14 | Destroyer sprite (12 frames incl. death + secondary explosion) | P1 | 3h |
| E3-15 | Elite sprites × 3 variants | P1 | 4h |
| E3-16 | Mothership sprite (multi-part, animated reactor, blast doors) | P1 | 6h |
| E3-17 | Alien projectile sprites (scout bolt, warrior burst, destroyer beam) | P1 | 2h |
| **E3 Total** | | | **~54h** |

---

## EPIC 4 — Pickups & Collectibles

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E4-01 | Pickup base class: drift, despawn timer, flash warning | P0 | 1.5h |
| E4-02 | Fuel Cell: spawn, collect, +25 fuel effect | P0 | 1h |
| E4-03 | Repair Kit: spawn, collect, +20 hull effect | P0 | 1h |
| E4-04 | Missile Pack: spawn, collect, +3 ammo | P0 | 0.5h |
| E4-05 | EMP Cartridge: spawn, collect, +1 charge | P0 | 0.5h |
| E4-06 | Data Crystal: spawn, collect, score multiplier | P0 | 1h |
| E4-07 | Shield Booster: spawn, collect, +30 shield | P0 | 0.5h |
| E4-08 | Survey Beacon: auto-collect on human viable result | P0 | 1h |
| E4-09 | Pickup sprites × 8 types | P1 | 3h |
| E4-10 | Drop table system (probability-weighted spawning) | P0 | 1.5h |
| **E4 Total** | | | **~11.5h** |

---

## EPIC 5 — World & Scrolling

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E5-01 | Auto-scrolling background (constant upward scroll) | P0 | 2h |
| E5-02 | Parallax starfield: 3 layers, different scroll speeds | P0 | 2h |
| E5-03 | Encounter System: distance-triggered event spawner | P0 | 4h |
| E5-04 | Encounter JSON data files for all 5 sectors | P0 | 4h |
| E5-05 | Star Cluster phase: scroll stops, stars appear | P0 | 2h |
| E5-06 | StarNode scene (Area2D, approach range, type assignment) | P0 | 2h |
| E5-07 | Sector background art × 5 (tileable, 320×180) | P1 | 6h |
| E5-08 | Nebula fog shader (Sector 3 visibility reduction) | P1 | 2h |
| E5-09 | Alien structure parallax art (Sector 4 background) | P2 | 4h |
| **E5 Total** | | | **~28h** |

---

## EPIC 6 — Star Scan System

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E6-01 | Scan trigger: approach range, E key, transition to orbit | P0 | 2h |
| E6-02 | Orbital movement: player follows circular path, weapons active | P0 | 2h |
| E6-03 | Scan progress bar (fills over duration, hazard waves spawn) | P0 | 2h |
| E6-04 | Scan result system: probability table → result string | P0 | 1.5h |
| E6-05 | Guaranteed results: sector-specific star outcomes hardcoded | P0 | 1h |
| E6-06 | Scan abort: E key again / auto-abort at low hull | P0 | 1h |
| E6-07 | Barren result: brief animation + text | P0 | 1h |
| E6-08 | Human Viable result: planet reveal animation, beacon collect | P0 | 3h |
| E6-09 | Alien Territory result: transition to alien combat | P0 | 1h |
| E6-10 | Anomaly result: special event handler | P0 | 2h |
| E6-11 | Scan bar UI (centered arc, phosphor glow, percentage) | P1 | 2h |
| E6-12 | Planet reveal shader (shimmer effect) + unique planets × 3 | P1 | 4h |
| **E6 Total** | | | **~22.5h** |

---

## EPIC 7 — Alien Combat Arena

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E7-01 | Arena transition: scroll stops, arena bounds activate | P0 | 1.5h |
| E7-02 | Wave Spawner: load wave data, spawn sequence, count enemies | P0 | 3h |
| E7-03 | Wave data JSON for each alien system (5 sectors × avg 2 systems) | P0 | 4h |
| E7-04 | Between-wave pause (5s) + loot drop | P0 | 1h |
| E7-05 | Emergency Warp escape: 4-second hold, fuel cost, blocked on boss | P0 | 2h |
| E7-06 | Victory condition: all waves clear → warp bonus + exit | P0 | 1.5h |
| **E7 Total** | | | **~13h** |

---

## EPIC 8 — HUD & UI

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E8-01 | HUD scene: all gauge positions, CanvasLayer | P0 | 2h |
| E8-02 | Hull gauge (analog style, color changes at 30%) | P0 | 1.5h |
| E8-03 | Shield gauge (arc, flickers on regen) | P0 | 1.5h |
| E8-04 | Fuel gauge (dial, amber < 25%, red < 10%, alarm sound) | P0 | 2h |
| E8-05 | Missile/EMP ammo display (icons + count) | P0 | 1h |
| E8-06 | Score display + multiplier (phosphor green) | P0 | 1h |
| E8-07 | Sector/star progress indicator | P0 | 1.5h |
| E8-08 | CRT scanline + vignette shader overlay | P1 | 1.5h |
| E8-09 | Hit flash (red border flicker on hull damage) | P0 | 0.5h |
| E8-10 | Chromatic aberration shader (single-frame on hit) | P1 | 1h |
| E8-11 | Pixel font integration (Space Mono or custom 6×8) | P1 | 1h |
| **E8 Total** | | | **~15h** |

---

## EPIC 9 — Menus & Flow

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E9-01 | Main Menu scene: title, start, high scores, quit | P0 | 2h |
| E9-02 | Title card art (retro sci-fi poster style logo) | P1 | 3h |
| E9-03 | Pause menu: resume, restart, quit | P0 | 1.5h |
| E9-04 | Death screen: log entry text, retry sector, quit | P0 | 1.5h |
| E9-05 | Sector transition scene: warp animation + stat summary | P0 | 3h |
| E9-06 | Upgrade screen: crystal cost, stat selection, confirm | P0 | 3h |
| E9-07 | Win screen — True Ending (defeat Mothership) | P0 | 2h |
| E9-08 | Win screen — Standard Ending (escape Mothership) | P0 | 1.5h |
| E9-09 | High score table (top 10, sector reached) | P1 | 2h |
| E9-10 | Mission log narrative text cards (sector transitions) | P1 | 2h |
| **E9 Total** | | | **~21.5h** |

---

## EPIC 10 — Audio Implementation

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E10-01 | Create/source all 12 music tracks (composition/procurement) | P1 | 20h |
| E10-02 | Create/source all ~57 SFX | P1 | 10h |
| E10-03 | Wire all music tracks to AudioManager, test transitions | P0 | 2h |
| E10-04 | Wire all SFX to events across all systems | P0 | 4h |
| E10-05 | Adaptive Mothership music (phase crossfade) | P0 | 2h |
| E10-06 | Fuel alarm (looping beep below 10%) | P0 | 0.5h |
| E10-07 | Volume controls in settings | P1 | 1h |
| **E10 Total** | | | **~39.5h** |

---

## EPIC 11 — Polish & Juice

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E11-01 | Screen shake on explosions (calibrated by size) | P1 | 1h |
| E11-02 | Pickup magnet effect (items drift toward player within 40px) | P2 | 1.5h |
| E11-03 | Enemy HP bars (visible when hit, fade after 2s) | P1 | 1.5h |
| E11-04 | Score popup text (+100, +MISSILE, etc.) floating up and fading | P2 | 1.5h |
| E11-05 | Derelict ship event: shootable hull, guaranteed loot spray | P1 | 2h |
| E11-06 | Anomaly events: full implementations × 3 variants | P1 | 3h |
| E11-07 | Mission AI voice log text animations (typewriter effect) | P1 | 1.5h |
| E11-08 | Warp entry/exit particle effects | P1 | 2h |
| E11-09 | Controller vibration on hit, explosion, discovery | P2 | 1h |
| E11-10 | Pause music low-pass filter (muffled when paused) | P2 | 0.5h |
| **E11 Total** | | | **~16.5h** |

---

## EPIC 12 — Testing & Balancing

| ID | Task | Priority | Est. |
|----|------|----------|------|
| E12-01 | Full playthrough test: Sector 1 complete | P0 | 2h |
| E12-02 | Full playthrough test: Sector 2 complete | P0 | 2h |
| E12-03 | Full playthrough test: Sector 3 complete | P0 | 2h |
| E12-04 | Full playthrough test: Sector 4 complete | P0 | 2h |
| E12-05 | Full playthrough test: Sector 5 + Mothership | P0 | 3h |
| E12-06 | Difficulty balancing pass: enemy HP/damage | P0 | 4h |
| E12-07 | Timing balancing pass: scan duration, encounter spacing | P0 | 3h |
| E12-08 | Economy balancing: crystal/upgrade costs, drop rates | P0 | 2h |
| E12-09 | Performance test: max enemies + particles at 60fps | P0 | 1h |
| E12-10 | Input testing: keyboard and gamepad | P0 | 1h |
| E12-11 | Bug fix pass | P0 | 8h |
| **E12 Total** | | | **~30h** |

---

## Summary

| Epic | Name | Est. Hours |
|------|------|-----------|
| E0 | Foundation | 8 |
| E1 | Player Craft | 26 |
| E2 | Hazards | 17 |
| E3 | Enemies | 54 |
| E4 | Pickups | 11.5 |
| E5 | World & Scrolling | 28 |
| E6 | Star Scan | 22.5 |
| E7 | Alien Combat | 13 |
| E8 | HUD & UI | 15 |
| E9 | Menus & Flow | 21.5 |
| E10 | Audio | 39.5 |
| E11 | Polish | 16.5 |
| E12 | Testing | 30 |
| **TOTAL** | | **~302 hours** |

*At 8h/day autonomous development, this is approximately a 38-day build. At a 10h/day pace with parallelized systems work: ~25–30 days.*

---

## Recommended Sprint Order

1. **Sprint 1** (E0 + E1 + E2): Playable ship in empty space with hazards
2. **Sprint 2** (E3 partial: Scout/Warrior + E5): Scrolling world with encounters and basic enemies
3. **Sprint 3** (E6 + E7): Full scan system + alien combat arenas
4. **Sprint 4** (E3 complete: Destroyer/Elite/Mothership): All enemies implemented
5. **Sprint 5** (E4 + E8): Pickups, HUD, full gameplay loop functional
6. **Sprint 6** (E9 + E10): Menus, flow, audio
7. **Sprint 7** (E11 + E12): Polish, balance, testing, ship
