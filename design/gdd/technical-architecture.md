# NOVA SCOUT — Technical Architecture (Godot 4)

**Version:** 1.0

---

## Engine & Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Godot Engine | 4.3+ | Game engine |
| GDScript | Built-in | Primary scripting language |
| Aseprite | Latest | Sprite & animation authoring |
| LMMS / Audacity | Latest | Audio editing |
| Git | Latest | Version control |

---

## Scene Tree Architecture

```
Main (Node)
├── GameManager (Node) [Autoload singleton]
├── AudioManager (Node) [Autoload singleton]
├── SaveManager (Node) [Autoload singleton]
│
├── MainMenu (Control)
│   ├── TitleCard
│   ├── MenuButtons
│   └── BackgroundStarfield
│
├── GameWorld (Node2D)          ← Main game scene
│   ├── WorldCamera (Camera2D)
│   ├── Background (Node2D)
│   │   ├── StarfieldLayer1 (ParallaxBackground)
│   │   ├── StarfieldLayer2 (ParallaxBackground)
│   │   └── NebulaLayer (ParallaxBackground)
│   │
│   ├── GameplayLayer (Node2D)
│   │   ├── Player (CharacterBody2D)
│   │   ├── EnemyContainer (Node2D)
│   │   ├── ProjectileContainer (Node2D)
│   │   ├── PickupContainer (Node2D)
│   │   └── HazardContainer (Node2D)
│   │
│   ├── StarCluster (Node2D)    ← active during cluster phase
│   │   └── StarNode[] (Area2D)
│   │
│   ├── HUD (CanvasLayer)
│   │   ├── HullGauge
│   │   ├── ShieldGauge
│   │   ├── FuelGauge
│   │   ├── AmmoDisplay
│   │   ├── ScoreDisplay
│   │   ├── SectorMap
│   │   └── ScanBar (hidden unless scanning)
│   │
│   └── CRTEffect (CanvasLayer)  ← post-process overlay
│
├── SectorTransition (CanvasLayer)  ← warp sequence + upgrade screen
├── DeathScreen (CanvasLayer)
└── PauseMenu (CanvasLayer)
```

---

## Autoload Singletons

### GameManager
Central state machine managing game phases.

```gdscript
# States
enum GameState {
    MENU,
    TRAVEL,           # Auto-scrolling between encounters
    ENCOUNTER,        # Active combat/hazard event
    STAR_CLUSTER,     # Player can freely move around cluster
    SCANNING,         # Orbital scan in progress
    ALIEN_COMBAT,     # Arena-style alien fight
    SECTOR_TRANSITION,# Warp + upgrade screen
    DEATH,
    WIN
}

var current_state: GameState
var current_sector: int          # 1–5
var survey_beacons: int          # 0–3 (win at 3)
var data_crystals: int
var player_stats: Dictionary     # hull, shield, fuel, missiles, emp
```

### AudioManager
Handles music transitions, SFX pooling.

```gdscript
func play_music(track: String, fade_time: float = 1.0) -> void
func play_sfx(sound: String, position: Vector2 = Vector2.ZERO) -> void
func set_music_phase(phase: int) -> void   # For Mothership adaptive track
```

### SaveManager
Handles high score persistence (no mid-game save — single session).

```gdscript
func save_high_score(score: int, sector_reached: int) -> void
func load_high_scores() -> Array[Dictionary]
```

---

## Core Systems

### Player (CharacterBody2D)
```
Scripts:
  player.gd           — movement, state, input
  player_weapons.gd   — fire, reload, targeting
  player_health.gd    — hull, shield, damage handling
  player_fuel.gd      — fuel tracking, boost logic
```

**Signals:**
- `hull_changed(new_value: int)`
- `shield_changed(new_value: int)`
- `fuel_changed(new_value: int)`
- `player_died()`
- `weapon_fired(weapon_type: String)`

### Enemy Base Class (CharacterBody2D)
All enemies extend `EnemyBase`:
```gdscript
class_name EnemyBase extends CharacterBody2D

var max_hp: int
var current_hp: int
var move_speed: float
var score_value: int
var drop_table: Array[Dictionary]

func take_damage(amount: int) -> void
func die() -> void
func _process_ai(delta: float) -> void  # Override per enemy
```

Individual enemy scripts: `enemy_scout.gd`, `enemy_warrior.gd`, `enemy_destroyer.gd`, `enemy_elite.gd`, `boss_mothership.gd`

### Encounter System (Node)
Controls travel-phase event spawning.

```gdscript
# Sector encounter data loaded from JSON
# assets/data/encounters/sector_{n}.json
# Each sector file defines encounter sequence with timing and composition

func load_sector_encounters(sector: int) -> void
func trigger_next_encounter() -> void
func _on_scroll_distance_reached(distance: float) -> void
```

**Encounter data format (JSON):**
```json
{
  "sector": 2,
  "encounters": [
    {
      "trigger_distance": 800,
      "type": "asteroid_field",
      "params": { "large": 5, "medium": 10 }
    },
    {
      "trigger_distance": 1600,
      "type": "alien_scouts",
      "params": { "count": 3, "formation": "v-shape" }
    }
  ]
}
```

### Star Scan System
```gdscript
# star_node.gd
var star_type: String       # "barren", "human", "alien", "anomaly"
var scan_duration: float    # Set per sector
var is_scanning: bool

signal scan_complete(result: String)
signal scan_aborted()

func begin_scan() -> void
func _process_scan(delta: float) -> void
func _reveal_result() -> void
```

Orbital movement: Player `CharacterBody2D` is parented to a `RemoteTransform2D` path around the star during scan. Player input still controls weapons but not movement.

### Wave Spawner (Alien Combat)
```gdscript
# wave_spawner.gd
var wave_data: Array[Dictionary]   # Loaded per alien system
var current_wave: int
var enemies_alive: int

signal wave_complete(wave_index: int)
signal all_waves_complete()

func start_combat(system_data: Dictionary) -> void
func spawn_wave(wave_index: int) -> void
```

---

## Data Architecture

All gameplay balance data lives in **JSON files** (not hardcoded):

```
assets/data/
├── player_stats.json          # Base stats, upgrade costs
├── enemy_stats.json           # HP, speed, damage per enemy type
├── weapon_stats.json          # Damage, fire rate, speed per weapon
├── pickups.json               # Drop rates, values
├── upgrades.json              # Upgrade options, costs, effects
└── encounters/
    ├── sector_1.json
    ├── sector_2.json
    ├── sector_3.json
    ├── sector_4.json
    └── sector_5.json
```

This enables balancing without recompilation.

---

## Visual Effects (Shaders)

All shaders in `assets/shaders/`:

| Shader | Type | Effect |
|--------|------|--------|
| `crt_overlay.gdshader` | CanvasItem | Scanlines + vignette + slight barrel |
| `shield_hit.gdshader` | CanvasItem | Hex shield flash on player |
| `star_scan.gdshader` | CanvasItem | Pulsing phosphor arc fill |
| `nebula_fog.gdshader` | CanvasItem | Animated particle fog for Sector 3 |
| `warp_lines.gdshader` | CanvasItem | Star streak transition |
| `planet_shimmer.gdshader` | Sprite2D | Atmospheric edge on planet reveal |
| `engine_glow.gdshader` | CanvasItem | Player engine light cone |

---

## Input Map

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| `move_up` | W / ↑ | Left stick up |
| `move_down` | S / ↓ | Left stick down |
| `move_left` | A / ← | Left stick left |
| `move_right` | D / → | Left stick right |
| `boost` | Shift | Left bumper |
| `fire_laser` | Space | Right trigger |
| `fire_missile` | X | Right bumper |
| `fire_emp` | Z | Left trigger |
| `interact_scan` | E | Left trigger (hold) |
| `escape_warp` | E (hold) | Left trigger (hold) |
| `pause` | Escape | Start |

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Frame rate | 60 fps constant |
| Max enemies on screen | 25 |
| Max projectiles on screen | 80 |
| Max particles on screen | 500 |
| Draw calls | < 50 per frame |

**Object pooling:** Projectiles and particles use object pools (pre-allocated). No mid-gameplay instantiation for high-frequency objects.

---

## Project File Structure

```
nova-scout/
├── project.godot
├── src/
│   ├── core/
│   │   ├── game_manager.gd
│   │   ├── audio_manager.gd
│   │   └── save_manager.gd
│   ├── gameplay/
│   │   ├── player/
│   │   │   ├── player.gd
│   │   │   ├── player_weapons.gd
│   │   │   ├── player_health.gd
│   │   │   └── player_fuel.gd
│   │   ├── enemies/
│   │   │   ├── enemy_base.gd
│   │   │   ├── enemy_scout.gd
│   │   │   ├── enemy_warrior.gd
│   │   │   ├── enemy_destroyer.gd
│   │   │   ├── enemy_elite.gd
│   │   │   └── boss_mothership.gd
│   │   ├── systems/
│   │   │   ├── encounter_system.gd
│   │   │   ├── star_scan_system.gd
│   │   │   ├── wave_spawner.gd
│   │   │   ├── pickup_system.gd
│   │   │   └── upgrade_system.gd
│   │   └── hazards/
│   │       ├── asteroid.gd
│   │       ├── space_mine.gd
│   │       └── debris_cloud.gd
│   ├── ui/
│   │   ├── hud.gd
│   │   ├── scan_bar.gd
│   │   ├── upgrade_screen.gd
│   │   ├── death_screen.gd
│   │   └── main_menu.gd
│   └── systems/
│       ├── object_pool.gd
│       ├── parallax_manager.gd
│       └── sector_manager.gd
├── assets/
│   ├── sprites/
│   ├── audio/
│   ├── shaders/
│   └── data/
├── scenes/
│   ├── main.tscn
│   ├── game_world.tscn
│   ├── ui/
│   └── entities/
├── design/
├── docs/
├── production/
└── tests/
```
