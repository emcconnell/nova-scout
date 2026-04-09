# NOVA SCOUT — Enemy & Hazard Design

**Version:** 1.0

---

## HAZARDS (Non-Enemy)

### Asteroids
Three sizes — behave like classic *Asteroids* (1979).

| Size | HP | Speed | Damage | On Destroy |
|------|----|-------|--------|------------|
| Large | 30 | 40–60px/s, random dir | 25 hull | Splits into 2 Medium |
| Medium | 15 | 60–90px/s | 15 hull | Splits into 2 Small |
| Small | 5 | 80–120px/s | 8 hull | Destroyed, 50% chance of Fuel Cell or Crystal drop |

**Visual:** Jagged pixel rock sprites, subtle rotation, dark grey with lighter surface detail. Three visual variants per size (9 sprites total).

---

### Space Mines
- Stationary until within 80px of player
- Chase slowly (60px/s) once triggered
- **HP:** 10 | **Damage:** 40 hull on contact (explosion)
- **Visual:** Spiked sphere, amber warning light blinks faster as it closes

---

### Debris Clouds
- Area hazard — cannot be destroyed
- **Slow effect:** -40% player speed while inside
- **Damage:** 3 hull/second while inside
- **Visual:** Semi-transparent brownish-grey particle field, drifts slowly

---

## ALIEN ENEMIES

All alien enemies have a consistent visual language: **organic, bioluminescent edges with purple/magenta energy**, contrasting with the player's mechanical cyan/white aesthetic. Inspired by the "big-eyed alien" visual vocabulary of 50s sci-fi posters.

---

### Tier 1 — Alien Scout
*First appears: Sector 2*

**Behavior:** Fast, erratic movement in sine-wave patterns. Fires single laser shots every 1.5 seconds. Retreats momentarily when hit. Often appears in groups of 3–5.

| Stat | Value |
|------|-------|
| HP | 20 |
| Speed | 200px/s |
| Damage (contact) | 10 |
| Damage (laser) | 8 |
| Score | 100 |
| Drop | 30% Fuel Cell, 20% Crystal |

**Visual:** Small saucer shape, magenta glow ring, 2 small red "eye" lights. Wobbles in flight.  
**Sound:** High-pitched whirring engine tone; ascending beep when firing.

---

### Tier 2 — Alien Warrior
*First appears: Sector 3*

**Behavior:** Moves in deliberate diagonal sweeps across screen. Fires 3-shot spread burst every 2 seconds. Has a front shield (takes half damage from the front — attack from sides/rear). Tries to get above player to dive-bomb.

| Stat | Value |
|------|-------|
| HP | 60 |
| Speed | 140px/s |
| Damage (contact) | 20 |
| Damage (burst) | 10 per shot |
| Front shield reduction | 50% |
| Score | 300 |
| Drop | 50% chance of Missile Pack or Crystal |

**Visual:** Elongated fin-shaped craft, purple hull, glowing ventral stripe, twin engine nacelles. Slightly larger than Scout.  
**Sound:** Deep thrumming engine; triple-beep when firing burst.

---

### Tier 3 — Alien Destroyer
*First appears: Sector 4*

**Behavior:** Slow-moving but fires 5 different attack patterns (rotates through):
1. **Spiral Burst** — 8 shots in spiral pattern
2. **Twin Beam** — two parallel slow beams
3. **Homing Bolt** — one fast homing projectile
4. **Mine Drop** — drops 2 mines below it
5. **Shield Pulse** — 2-second invincibility + stuns player weapons (not movement)

Between patterns: 2-second pause. Takes double damage during pause window (exposed core glows).

| Stat | Value |
|------|-------|
| HP | 200 |
| Speed | 60px/s |
| Damage (contact) | 35 |
| Score | 800 |
| Drop | Guaranteed Repair Kit + Crystal × 2 |

**Visual:** Large beetle-shaped craft, thick carapace, glowing purple underbelly, 4 weapon ports. Occupies ~15% of screen width.  
**Sound:** Heavy reverberating engine drone; distinct sound per attack pattern.

---

### Tier 4 — Alien Elite (Mini-Boss)
*Appears as: Final wave of each alien system*

One of three variants (rotates per system encountered):

#### Variant A — The Interceptor
High speed, teleports short distances (0.3s blink), fires aimed spread. Tests player movement.  
HP: 350 | Speed: 220px/s (+ blink) | Score: 1500

#### Variant B — The Artillery
Stationary at top of screen. Fires extremely precise aimed shots in volleys of 6. Tests player dodging and use of EMP.  
HP: 500 | Score: 1500

#### Variant C — The Swarm Commander
Spawns 2 Scouts every 8 seconds. Fires homing missiles. Tests priority targeting.  
HP: 280 | Spawns up to 8 scouts total | Score: 1500

All Elites drop: Guaranteed Repair Kit + EMP Cartridge + 3 Crystals

---

### BOSS — The Mothership
*Sector 5 only — Final Boss*

The Mothership is the centerpiece of the Epsilon sector's final alien system. It occupies the upper third of the arena.

**Phase 1 (100–60% HP):**
- Twin rotating laser arrays sweep across the screen  
- Spawns Scouts in groups of 3 every 12 seconds
- Occasional targeted missile volley
- **Weak point:** Central reactor core (3× damage) — exposed 4 seconds per 15-second cycle

**Phase 2 (60–30% HP):**
- Adds a **shield drone** that orbits the Mothership (must be destroyed first to resume damage)
- Laser arrays speed up
- Begins using **Gravity Pulse** — pulls player toward Mothership for 2 seconds (terrifying, very telegraphed)

**Phase 3 (30–0% HP):**
- Shield drone respawns every 20 seconds
- Enrage: all attack speeds increase 30%
- Spawns one Destroyer as support
- **DESPERATION ATTACK:** At 10% HP, fires a full-screen energy sweep — player has 3 seconds to reach a safe gap (telegraphed by red indicator lanes)

**Stats:**
- HP: 2000
- Score on defeat: 10,000
- Drop: Full hull restore, max fuel, EMP × 2, Crystals × 8

**Visual:** Enormous organic-mechanical hybrid vessel. Purple-black hull with glowing orange veins of energy. Three visible weapon ports. The reactor core is a pulsing cyan orb behind blast doors that open on cycle. Designed to feel like a *Forbidden Planet* monster translated into spacecraft.

**Music:** The Mothership fight has its own unique track — theremin lead over driving percussion, building in intensity each phase.

---

## Enemy Spawn Patterns (by Sector)

| Sector | Spawn Composition |
|--------|------------------|
| 1 | Asteroids only |
| 2 | Asteroids 60%, Scouts 30%, Mines 10% |
| 3 | Asteroids 40%, Scouts 30%, Warriors 20%, Mines 10% |
| 4 | Asteroids 20%, Scouts 20%, Warriors 30%, Destroyers 20%, Elites 10% |
| 5 | Asteroids 15%, Warriors 25%, Destroyers 35%, Elites 15%, Mothership 10% |
