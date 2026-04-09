# NOVA SCOUT — Gameplay Mechanics

**Version:** 1.0

---

## 1. Player Craft — Survey Probe Seven

### Movement
- **Control scheme:** WASD / left stick to thrust in 8 directions (tank-style rotation optional, but we use *direct directional* control — up is always screen-up)
- **Speed:** Base 180px/sec, boost 320px/sec (drains fuel)
- **Inertia:** Slight, forgiving — not full Asteroids drift; the craft responds quickly
- **Screen bounds:** Craft wraps horizontally; vertical is scroll-locked to level

### Stats
| Stat | Base | Max | Notes |
|------|------|-----|-------|
| Hull | 100 | 100 | Does NOT regenerate; requires Repair Kits |
| Shield | 60 | 100 | Regenerates at 5/sec after 3s no-hit |
| Fuel | 100 | 100 | Drains during boost and warp; refilled by Fuel Cells |
| Ammo (Missiles) | 6 | 12 | Found as pickups |
| Ammo (EMP) | 2 | 4 | Found as pickups |

---

## 2. Weapons

### Laser Cannon (primary — unlimited)
- **Input:** Space / right trigger (hold for auto-fire)
- **Fire rate:** 8 shots/sec
- **Damage:** 8 per hit
- **Range:** Full screen height
- **Visual:** Thin cyan bolt, small muzzle flash, classic pew sound
- **Upgrade path:** None in base game (scope for DLC)

### Missile (secondary — limited)
- **Input:** X / right bumper
- **Damage:** 60 per hit (AoE radius 40px)
- **Speed:** Homing (locks nearest enemy within 200px), else straight
- **Visual:** White rocket trail, satisfying explosion sprite
- **Use case:** Bosses, clustered enemies, large asteroids

### EMP Pulse (special — limited)
- **Input:** Z / left bumper
- **Effect:** Stuns all enemies on-screen for 2.5 seconds; destroys all bullets on-screen
- **Visual:** Expanding ring wave, screen briefly desaturates
- **Use case:** Emergency escape, dense bullet hell moments
- **Recharge:** Cannot recharge; find EMP Cartridges as pickups

---

## 3. Travel Phase (Between Stars)

The **Travel Phase** is the main traversal mode. The background auto-scrolls upward (creating the illusion of forward flight). The player steers, shoots, and collects while moving toward the next star cluster.

### Encounter Events (random during travel)
| Event | Frequency | Description |
|-------|-----------|-------------|
| Asteroid Field | Common | Dense rocks of 3 sizes; large split into 2 medium, medium into 2 small |
| Debris Cloud | Common | Floating wreckage from unknown ships; slows craft 40%, damages on contact |
| Space Mine Field | Uncommon | Proximity mines in patterns; shoot them or navigate gaps |
| Fuel Cache | Uncommon | Abandoned supply drone; flies away if not shot quickly |
| Alien Scout Patrol | Rare (Sector 1), Common (Sector 3+) | 3–5 scouts in formation; attack on sight |
| Cosmic Storm | Rare | Screen fills with particle static; visibility drops 60%; no enemies but dense debris |
| Derelict Ship | Rare | Drifting hulk; can shoot open for guaranteed loot drop |
| Alien Ambush | Sector 2+ | Surprise attack: 8 enemies spawn from sides simultaneously |

### Scrolling Speed
- Base: Moderate (the sector background tile takes ~8 minutes to traverse)
- Boost doubles travel speed but drains fuel

---

## 4. Star Investigation

When the player reaches a **Star Cluster**, scrolling stops. Stars are visible as glowing objects at various positions. The player chooses which to approach.

### Approach & Scan
1. Player flies toward a star icon
2. Within range, press **E / left trigger** to begin scan
3. Craft enters a **circular orbit** automatically (player can still fire, cannot exit without completing or aborting scan)
4. **Scan bar** fills over 20 seconds (Sector 1) → 30 seconds (Sector 5)
5. During scan: hazard waves spawn (asteroids + enemies depending on sector)
6. On completion: **Star Result** revealed (see below)

### Scan Abort
- Press **E again** to abort; no result, craft returns to free flight
- Full abort if hull < 20% (safety escape — craft auto-aborts and boosts away)

### Star Results
| Result | Probability | Outcome |
|--------|-------------|---------|
| **Barren** | 50% | Nothing — brief visual, move on |
| **Human Viable** | 20% | **Survey Data collected!** Beautiful planet animation. +Score bonus. Progress toward win. |
| **Alien Territory** | 25% | Triggers **Alien Combat Mode** |
| **Anomaly** | 5% | Special event: bonus loot room, mystery upgrade, or narrative beat |

*Note: Sector-specific stars are guaranteed results. The above probabilities apply to optional stars.*

---

## 5. Alien Combat Mode

When an Alien Territory star is scanned, the screen transitions to an **arena** — the star system's space with no auto-scroll.

### Structure
- **3 Waves** of aliens per alien system (Sector 2), up to **5 Waves** (Sector 5)
- Between waves: 5 second breathing room, small loot drop
- Boss wave: final wave of each alien system has an **Elite Enemy** (mini-boss)

### Escape Option
At any point the player can attempt **Emergency Warp**:
- Hold **E for 4 seconds** while not being hit
- Escaping costs 20 fuel
- Cannot escape during boss wave (until boss at 25% HP)

### Victory
- Defeat all waves → **Warp bonus** (fuel restored 15%) + exit animation
- The alien system is marked on the sector map as cleared

---

## 6. Collectibles & Pickups

All pickups are dropped by destroyed enemies, asteroids, derelicts, or float in space.

| Pickup | Visual | Effect |
|--------|--------|--------|
| **Fuel Cell** | Yellow canister, pulsing | +25 fuel |
| **Repair Kit** | Red cross box | +20 hull |
| **Missile Pack** | White torpedo cluster | +3 missiles |
| **EMP Cartridge** | Blue ring icon | +1 EMP charge |
| **Data Crystal** | Cyan gem, spinning | +Score ×multiplier |
| **Shield Booster** | Blue hexagon | +30 shield (one-time) |
| **Survey Beacon** | Gold satellite dish | Marks habitable planet — auto-collected on Human Viable result |

Pickups have a **5-second despawn timer** (flashing warning at 3s). They drift slowly.

---

## 7. Progression & Difficulty Curve

| Sector | New Mechanics Introduced | Enemy Count | Asteroid Density |
|--------|--------------------------|-------------|------------------|
| 1 | Lasers, asteroids, fuel management, scan | 0–5 per encounter | Low |
| 2 | Alien scouts, mines, missiles | 5–12 per encounter | Medium |
| 3 | EMP, nebula visibility reduction, elite aliens | 8–15 per encounter | Medium |
| 4 | Alien destroyers, multi-wave alien systems | 12–20 per encounter | High |
| 5 | Mothership boss, all mechanics combined | 15–25 per encounter | High |

### Medium Difficulty Tuning
- Shield regen delay: 3 seconds
- Asteroid split count: 2 (not 3)
- Enemy bullet speed: 180px/sec
- Scan duration: 25 seconds average
- Fuel drain: 1 unit per 2 seconds at boost

---

## 8. UI Systems

### HUD Elements
- **Hull Bar** — left side, analog-style gauge, red below 30%
- **Shield Bar** — left side below hull, blue arc gauge, flickers when regenerating
- **Fuel Gauge** — right side, analog dial, amber warning below 25%, red below 10%
- **Missile Counter** — bottom right, icon + number
- **EMP Counter** — bottom right below missiles, icon + number
- **Sector/Star Progress** — top center, small star map showing position
- **Score/Multiplier** — top right, phosphor green numbers
- **Scan Bar** — appears only during scan, large centered arc filling with CRT glow

### Scanlines & CRT Effect
- Subtle horizontal scanline overlay (50% opacity)
- Mild vignette on screen edges
- Occasional "screen flicker" on hit (1 frame)
- All UI uses **Space Mono** or similar monospace font in phosphor green/amber

---

## 9. Sector Transitions

Between sectors, a **warp sequence** plays:
1. Stars compress to streaks (classic hyperspace)
2. Stats screen shows sector performance
3. Brief narrative text card (flavor, mission log style)
4. New sector fades in

The player can **upgrade one stat** at sector transition using collected Data Crystals:
| Upgrade | Cost | Effect |
|---------|------|--------|
| Hull Reinforcement | 5 crystals | Max hull +20 |
| Fuel Tank | 5 crystals | Max fuel +25 |
| Shield Emitter | 8 crystals | Shield regen +3/sec |
| Missile Bay | 8 crystals | Max missiles +3 |
| Laser Focus | 10 crystals | Laser damage +4 |

---

## 10. Death & Retry

- **Death:** Short explosion animation, log entry "Probe Seven signal lost. Transmission ends."
- **Retry:** Restart current sector from beginning (not full game restart)
- **No lives system** — retry is immediate, no punishment beyond lost progress within sector
- **Narrative framing:** Each retry is framed as a simulation replay — "Reviewing flight data from final 14 minutes..."
