# Nova Scout — Gameplay Improvements Proposal
**Author:** Lead Designer / Technical Review  
**Date:** 2026-04-10  
**Status:** DRAFT — Pending Approval  
**Version:** 1.0

---

## Executive Summary

Nova Scout has strong bones — the visual aesthetic, core loop concept, and star scanning mechanic are all compelling. However four structural problems are killing engagement:

1. **It takes ~8 minutes to reach the first star cluster** — the primary objective barely appears
2. **Space mines are passive and predictable** — a hazard that players can simply ignore
3. **Difficulty doesn't visibly escalate** — Sector 5 plays almost the same as Sector 2
4. **Too much dead space between encounters** — the screen empties out and there's nothing to do

This document draws on established game design principles (Csikszentmihalyi's Flow Channel, Nintendo's "introduce then escalate" structure, shmup pacing theory) and proposes specific, targeted fixes for each problem with exact implementation specs.

---

## Research Summary — What Makes a Great Arcade Shooter

Before proposing changes, let's establish the design principles we're building toward.

### The Flow Channel (Csikszentmihalyi)
The critical insight for engagement: **keep difficulty just above the player's current skill level.** Too easy = boredom. Too hard = anxiety. Great arcade games escalate challenge slightly faster than the player's growing skill — they always feel like you're *just barely* keeping up. Nova Scout currently flatlines in the boredom zone because the difficulty barely escalates and there's too much empty time.

### The First 5 Minutes Rule
Research and playtest data consistently show: **if nothing memorable happens in the first 3-5 minutes, players don't come back.** Currently the first 8 minutes of Nova Scout are mostly dodging slow asteroids. The first star cluster — the game's core fantasy moment — doesn't appear until minute 8. This is the single biggest retention killer.

### Nintendo's "Introduce → Complicate → Combine" Structure
Super Mario Bros teaches jumping in safety, then introduces gaps, then enemies, then both together. Each new mechanic has one safe introduction beat, then gets combined with existing threats. Nova Scout's sector structure should mirror this:
- **Sector 1:** Introduce mechanics in isolation (safe)
- **Sector 2:** Introduce first enemies + combine with asteroids  
- **Sector 3:** Combine all hazards simultaneously
- **Sector 4–5:** Pressure escalation — the same hazards, faster, in worse combinations

### The "Something Always Happening" Principle (shmup design)
In the great shooters — Galaga, DoDonPachi, R-Type, Ikaruga — **there is always at least one active threat requiring a decision.** Dead screen = dead engagement. The player should never be flying through an empty screen for more than 15-20 seconds. Nova Scout currently has gaps of 60-120+ seconds between encounters.

### Readable Threat Design
Threats must be **dangerous but readable**. Players need to feel "I could have dodged that." Random, instant damage feels unfair. Telegraphed, pattern-based damage feels like a challenge. Every hazard needs a visual or audio warning before it hurts the player. This principle applies especially to the mine overhaul.

### Reward Rhythm
**High-frequency small rewards keep players engaged better than infrequent large ones.** Players should feel like they're scoring, collecting, and progressing every 10-15 seconds — not every 2 minutes. More score popups, more crystal drops from varied sources, more small wins.

---

## Proposed Changes

---

### Change 1: Viewport Resize Support

**Problem:** The game window is locked to 1280×720. When the OS window is resized, the game either clips or doesn't scale correctly. Modern players expect a resizable window.

**Current state:**
```
window_width_override=1280
window_height_override=720
stretch/mode="canvas_items"
```

**Root cause:** The stretch mode `canvas_items` in Godot 4 correctly scales the 320×180 internal canvas to fill the window, but the window itself is capped. The HUD code uses `get_viewport_rect()` already, so most positional logic is already viewport-relative.

**Proposed fix — `project.godot` display section:**
```ini
window/size/mode=0              # Windowed
window/size/resizable=true      # Allow resize
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"    # Pillarbox/letterbox — preserves 16:9 feel
```

**Additional change:** Remove hardcoded `window_width_override` / `window_height_override` — let the player resize freely. The internal resolution stays at 320×180 (pixel-art scale) and gets upscaled.

**Impact:** Low risk. All existing draw calls use `get_viewport_rect().size` so they already adapt. The only audit needed is the `player.gd` position init (`vp.size.y - 28.0`) and any hardcoded spawn positions — all of these already reference `get_viewport_rect()`. ✅

---

### Change 2: Space Mine Overhaul — "The Screaming Mine"

**Problem:** Current mines drift slowly down, detect the player, then chase. They are entirely passive until the player enters their 60px detection radius — easy to spot and avoid by hugging one side of the screen. In playtesting they register as background noise, not threats.

**Current behavior:**
- Drift down at 18 px/sec
- On player within 60px: chase at 80 px/sec
- Explode on contact
- 2 HP
- 6 decorative spikes (drawn but completely inert)

**Proposed overhaul — make the spikes MEAN something:**

#### 2a. Erratic Movement (replaces simple drift)
Instead of a straight drift, mines move unpredictably — making them genuinely hard to predict at a glance:
```
Phase 1 (entering screen, y < 0 to 30px): Fast entry drift, 28–45 px/sec
Phase 2 (in play area, not chasing): 
  - Base drift: 20 px/sec downward
  - Lateral sine wave: amplitude 25px, frequency varies per mine (2.0–4.5 Hz)
  - Random "lurch" every 2–4 seconds: sudden velocity burst in a random direction, decays over 0.5s
Phase 3 (chasing): Current behavior, speed increased to 95 px/sec
```

#### 2b. Spike Shots (the key new mechanic)
Every **3.0–4.5 seconds** (randomised per mine, staggered), the mine **fires one small bolt from each of its 6 spike tips** toward the player's current position. This creates a radial burst pattern — 6 bolts spreading outward from the mine's position.

- **Bolt damage:** 6 (half a scout bolt — chip damage, not lethal alone)  
- **Bolt speed:** 140 px/sec  
- **Fire interval:** 3.0s + randf_range(0, 1.5) seconds per mine (stagger prevents all mines firing simultaneously)  
- **Fire warning:** 0.4 seconds before firing, the mine emits a rapid blink + a short "charge" audio cue, giving the player time to move
- **Bolts do NOT home** — pure directional, aimed at player position at fire moment
- **Bolts despawn** at screen edge

Visual tell for shot charge: spike tips change color from grey-metal to bright red-orange in the 0.4s window.

#### 2c. HP & Score Increase
- HP: 2 → **3** (takes more commitment to destroy)
- Score on destroy: 75 → **150** (reward for the extra effort)
- Explosion AoE damage radius: 32px → **28px** (slightly reduced so players aren't punished for proximity kill)

#### 2d. Mine-Type Variants (Sector 2+)
Introduce two mine subtypes via the encounter `params`:

| Type | Color | Behavior |
|------|-------|---------|
| `standard` | Red-grey | Current + spike shots + erratic drift |
| `cluster` (Sector 3+) | Purple-grey | Fires 3 mines on death (like asteroid split) — no spike shots |
| `rapid` (Sector 4+) | Orange-red | Fires every 1.8s, faster chase (110 px/sec), 1 HP only |

This gives the encounter designer three distinct threats to mix.

#### 2e. Updated Mine Field Spawn Pattern
The `mine_field` encounter type currently spawns mines evenly spaced across the screen. With shot-firing mines this remains viable but add a `stagger` parameter to offset fire timers so all mines don't fire simultaneously:

```json
{ "type": "mine_field", "params": { "count": 4, "mine_type": "standard", "stagger": true } }
```

---

### Change 3: Sector Travel Time — Cut to 5 Minutes

**Problem:** At `SCROLL_SPEED = 40.0` and star cluster at distance `~19,000`, reaching the first star cluster takes **~475 seconds = 7.9 minutes**. This is the single biggest pacing problem. The GDD targets 60-minute first play — five 8-minute travel sections alone = 40 minutes of mostly dodging asteroids.

**Target:** 5 minutes per sector travel phase. With star scanning and combat the total sector becomes ~7-8 minutes, giving a 35-40 minute first run (still satisfying, less punishing).

**Proposed fix — two-part approach:**

#### 3a. Reduce SECTOR_LENGTH
```gdscript
# encounter_manager.gd
const SCROLL_SPEED  := 40.0      # Unchanged
const SECTOR_LENGTH := 12000.0   # Was 19200 — now ~5 min (300s × 40)
```

#### 3b. Compress all encounter distances proportionally (~63% of original)
Each encounter fires at roughly the same *fraction* of sector progress, just faster.

**Sector 1 — revised:**
```json
{ "distance": 750,   "type": "asteroid_field", "params": { "count": 3, "tier": 0 } },
{ "distance": 2200,  "type": "asteroid_field", "params": { "count": 4, "tier": 0, "mix": true } },
{ "distance": 3800,  "type": "fuel_cache",      "params": {} },
{ "distance": 4500,  "type": "debris_cloud",   "params": { "count": 1 } },
{ "distance": 5500,  "type": "asteroid_field", "params": { "count": 5, "tier": 0, "mix": true } },
{ "distance": 7000,  "type": "mine_field",      "params": { "count": 2, "mine_type": "standard" } },
{ "distance": 8800,  "type": "asteroid_field", "params": { "count": 3, "tier": 1 } },
{ "distance": 11800, "type": "star_cluster",   "params": {} }
```

**Sector 2 — revised:**
```json
{ "distance": 600,   "type": "asteroid_field", "params": { "count": 5, "tier": 0, "mix": true } },
{ "distance": 2200,  "type": "scout_wave",     "params": { "count": 3 } },
{ "distance": 3400,  "type": "asteroid_field", "params": { "count": 4, "tier": 0, "mix": true } },
{ "distance": 4500,  "type": "mine_field",      "params": { "count": 4, "mine_type": "standard", "stagger": true } },
{ "distance": 5600,  "type": "scout_wave",     "params": { "count": 4 } },
{ "distance": 7000,  "type": "derelict_ship",  "params": {} },
{ "distance": 8400,  "type": "scout_wave",     "params": { "count": 5 } },
{ "distance": 10000, "type": "asteroid_field", "params": { "count": 3, "tier": 1 } },
{ "distance": 11800, "type": "star_cluster",   "params": {} }
```

**Sector 3 — revised:**
```json
{ "distance": 500,   "type": "mine_field",      "params": { "count": 3, "mine_type": "standard" } },
{ "distance": 1500,  "type": "scout_wave",     "params": { "count": 6 } },
{ "distance": 2800,  "type": "debris_cloud",   "params": { "count": 2 } },
{ "distance": 4200,  "type": "warrior_wave",   "params": { "count": 1 } },
{ "distance": 5400,  "type": "scout_wave",     "params": { "count": 4 } },
{ "distance": 6600,  "type": "warrior_wave",   "params": { "count": 2 } },
{ "distance": 7500,  "type": "mine_field",      "params": { "count": 3, "mine_type": "cluster" } },
{ "distance": 8800,  "type": "warrior_wave",   "params": { "count": 2 } },
{ "distance": 10000, "type": "fuel_cache",     "params": {} },
{ "distance": 11800, "type": "star_cluster",   "params": {} }
```

**Sector 4 — revised:**
```json
{ "distance": 300,   "type": "scout_wave",     "params": { "count": 4 } },
{ "distance": 1500,  "type": "destroyer_wave", "params": { "count": 1, "escort": 3 } },
{ "distance": 2800,  "type": "mine_field",      "params": { "count": 4, "mine_type": "rapid" } },
{ "distance": 4000,  "type": "warrior_wave",   "params": { "count": 3 } },
{ "distance": 5200,  "type": "destroyer_wave", "params": { "count": 2 } },
{ "distance": 6200,  "type": "mine_field",      "params": { "count": 3, "mine_type": "cluster" } },
{ "distance": 7200,  "type": "fuel_cache",     "params": {} },
{ "distance": 8400,  "type": "warrior_wave",   "params": { "count": 3 } },
{ "distance": 9800,  "type": "destroyer_wave", "params": { "count": 2 } },
{ "distance": 11800, "type": "star_cluster",   "params": {} }
```

**Sector 5 — revised:**  
*(Previous version had a 9,200-unit gap — over 3.5 minutes — between elite wave and star cluster)*
```json
{ "distance": 200,   "type": "scout_wave",     "params": { "count": 6 } },
{ "distance": 1200,  "type": "warrior_wave",   "params": { "count": 3 } },
{ "distance": 2400,  "type": "mine_field",      "params": { "count": 5, "mine_type": "rapid", "stagger": true } },
{ "distance": 3600,  "type": "destroyer_wave", "params": { "count": 3 } },
{ "distance": 4800,  "type": "asteroid_field", "params": { "count": 4, "tier": 0, "mix": true } },
{ "distance": 5800,  "type": "elite_wave",     "params": { "variants": ["interceptor", "artillery"], "hp_scale": 1.2 } },
{ "distance": 7200,  "type": "fuel_cache",     "params": {} },
{ "distance": 8600,  "type": "elite_wave",     "params": { "variants": ["swarm_commander", "interceptor"], "hp_scale": 1.35 } },
{ "distance": 9800,  "type": "mine_field",      "params": { "count": 4, "mine_type": "cluster" } },
{ "distance": 11800, "type": "star_cluster",   "params": {} }
```

---

### Change 4: Difficulty Escalation — Ambient Pressure System

**Problem:** The only difficulty scaling is the encounter list — when encounters aren't firing, the screen empties. Enemy base stats are identical regardless of sector. There's no sense of the universe becoming more hostile as you go deeper.

**Proposed: Sector Intensity Multiplier**

Add a `sector_intensity` value to `GameManager` that scales passive spawning and enemy stats:

```
Sector 1: intensity = 1.0  (baseline)
Sector 2: intensity = 1.3
Sector 3: intensity = 1.6
Sector 4: intensity = 2.0
Sector 5: intensity = 2.5
```

This multiplier affects:

#### 4a. Background Asteroid Spawn Rate (GameWorld)
Currently asteroids spawn every `SPAWN_INTERVAL = 3.0s`. Modify:
```gdscript
var effective_interval: float = SPAWN_INTERVAL / GameManager.sector_intensity
```
By Sector 5, asteroids spawn roughly 2.5× as often as Sector 1. The screen never empties.

#### 4b. Max Simultaneous Hazards (GameWorld)
Currently capped at `MAX_HAZARDS = 14`. Scale with sector:
```gdscript
var effective_max: int = int(MAX_HAZARDS * GameManager.sector_intensity * 0.7)
# Sector 1: ~10, Sector 5: ~25
```

#### 4c. Enemy Fire Rate (EnemyBase)
Add a `fire_rate_multiplier` property that all enemy subclasses apply to their fire timers:
```gdscript
# In enemy _ready()
var sector_mult: float = 1.0 + (GameManager.current_sector - 1) * 0.12
# Sector 1: 1.0×, Sector 2: 1.12×, Sector 5: 1.48× fire rate
```
This is subtle — players won't consciously notice it, but they'll *feel* more pressure.

#### 4d. Enemy HP Scaling (EnemyBase)
Scale base HP by sector — makes combat feel heavier in later sectors:
```gdscript
func _ready() -> void:
    hp = int(hp * (1.0 + (GameManager.current_sector - 1) * 0.10))
    max_hp = hp
```
Sector 1 scouts: 20 HP. Sector 5 scouts: 28 HP (+40%). Destroyers go from 80 HP to 112 HP.

---

### Change 5: Combined Hazard Encounters (New Encounter Types)

**Problem:** Hazard types appear in isolation. Asteroids → then mines → then enemies. In good shooters, the real difficulty comes from **simultaneous overlapping threats** that force split-attention decisions.

**Proposed: Two new encounter types**

#### 5a. `mixed_field` — Asteroids AND Mines Simultaneously
```json
{ "type": "mixed_field", "params": { "asteroids": 3, "mines": 2, "mine_type": "standard" } }
```
Spawn a wave of asteroids AND mines at the same time. The player must navigate around breaking rocks while also watching for mine spike-shots from different angles. This creates the "threading the needle" feeling the GDD describes.

First appearance: **Sector 3** — after the player has encountered both threats individually.

#### 5b. `ambush_wave` — Enemies from Both Sides Simultaneously
```json
{ "type": "ambush_wave", "params": { "type": "scout", "count_left": 2, "count_right": 2 } }
```
Spawn enemies entering from both the left AND right sides of the screen simultaneously. Forces the player to pick a side and commit. 

Currently enemies always enter from the top. Side-entering enemies require completely different dodging decisions.

First appearance: **Sector 3**.

**Implementation:** Add both new encounter types to `GameWorld._handle_encounter()`.

---

### Change 6: "Dead Zone" Audio/Visual Density Fill

**Problem:** Between scripted encounters, the screen can empty completely. Silence + empty screen = the player wonders if the game has stalled.

**Proposed: Opportunistic Background Spawning**

When no encounter is active AND the current hazard count falls below `sector_intensity × 3`, automatically spawn one of:
- A lone drifting asteroid (lowest intensity — any sector)
- A debris cloud (Sector 2+)
- A lone drifting mine (Sector 3+ only)
- A single passing scout that doesn't attack, just flies through (Sector 4+ — adds visual interest without always fighting)

This is a **passive fill system**, not a scripted encounter. It doesn't emit `encounter_triggered`, so it doesn't affect the encounter index or sector-complete logic.

```gdscript
# In GameWorld._update_travel_spawning()
if _background_fill_cooldown <= 0.0 and hazards_node.get_child_count() < 3:
    _spawn_background_filler()
    _background_fill_cooldown = 8.0 / GameManager.sector_intensity
```

---

### Change 7: Reward Rhythm Improvements

**Problem:** Players go long stretches without feedback. The score doesn't tick up unless hitting enemies/asteroids. Fuel/crystals only drop from specific encounters.

**Proposed changes:**

#### 7a. Score Trickle for Distance Traveled
Award small score for surviving — keeps the score counter moving and gives a sense of progress:
```gdscript
# In EncounterManager._process():
GameManager.add_score(int(scroll_speed * delta * 0.05))  # ~2 pts/sec at normal speed
```
At 40 px/sec: ~2 points/second. Over a 5-min sector = ~600 bonus score. Trivial amount but the counter moving feels good.

#### 7b. Crystal Drop from Mine Destruction
Mines currently drop nothing. Add to `SpaceMine._explode()`:
```gdscript
# 40% chance of crystal drop on mine destroy (player is rewarded for engaging)
if randf() < 0.40:
    get_tree().call_group("game_world", "spawn_pickup", global_position, "crystal")
```

#### 7c. Streak Multiplier (Visible)
When the player destroys 3+ enemies without taking damage, display a brief "x2 STREAK" notice and double the score multiplier. Reset on player hit. 

This encourages aggressive play and makes the HUD feel alive. Implementation: in `GameManager`, track `kill_streak` and `streak_multiplier`. Reset on `hull_changed` signal.

---

## Implementation Priority & Effort Estimates

| # | Change | Impact | Effort | Priority |
|---|--------|--------|--------|----------|
| 1 | Viewport resize | Medium | Low (config only) | HIGH — ship now |
| 3 | Sector travel time | Very High | Low (data only) | **CRITICAL** |
| 2 | Mine overhaul | High | Medium (1 script) | HIGH |
| 4 | Difficulty escalation | High | Medium (2 scripts) | HIGH |
| 5 | Combined encounters | Medium | Medium (2 new types) | MEDIUM |
| 6 | Dead zone fill | Medium | Low (10 lines) | MEDIUM |
| 7a | Score trickle | Low | Low | LOW |
| 7b | Crystal from mines | Low | Low | LOW |
| 7c | Streak multiplier | Medium | Medium | LOW |

**Recommended sprint order:**
1. Change 3 (travel time) — pure data, zero risk, maximum immediate impact
2. Change 1 (viewport) — config only, trivially safe  
3. Change 2 (mines) — single script overhaul
4. Change 4 (difficulty escalation) — requires careful tuning pass after
5. Changes 5 + 6 — new mechanics once core pacing is solid
6. Change 7 — polish pass

---

## Before / After Summary

| Metric | Before | After |
|--------|--------|-------|
| Time to first star cluster | ~8 min | ~5 min |
| Total travel time (5 sectors) | ~40 min | ~25 min |
| Mine behavior | Passive drift + chase | Erratic drift + spike shots every ~3.5s |
| Difficulty at Sector 5 vs 1 | Virtually identical base stats | ~2.5× asteroid density, 1.4× fire rate, 1.4× HP |
| Empty screen time | 60–120 seconds common | <20 seconds by design |
| Score feedback frequency | Every 5–15s (kill only) | Continuous low trickle + kills |
| Mine threat variety | 1 type | 3 types (standard / cluster / rapid) |
| Combined hazard encounters | Never | Sector 3+ |
| Ambush encounter (from sides) | Never | Sector 3+ |

---

## What This Preserves

All changes are **additive or rebalancing** — the core loop, art style, GDD narrative, and win condition are untouched. The star scanning mechanic, player weapons, sector structure, and boss (Mothership) are unchanged. These proposals address *pacing and threat design* only.

---

## Open Questions (Require Decision Before Implementation)

1. **Mine spike shot damage (6)** — is chip damage the right feel or should we make it more punishing (e.g., 10)?
2. **`cluster` mine** — splitting into 3 child mines on death: should child mines also shoot, or drift only?  
3. **Streak multiplier visibility** — inline HUD text flash, or a separate indicator panel?
4. **Sector 1 intent** — it's designed as a tutorial. Should it be the only sector with zero shooting mines (mine_type: "inert") to preserve the gentle introduction?
5. **Window aspect ratio** — keep aspect locked at 16:9 (pillarbox/letterbox on ultrawide) or allow full stretch?
