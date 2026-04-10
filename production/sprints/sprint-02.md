# Sprint 02 — World Scrolling + Enemy Encounters

**Goal:** Scrolling world with scripted encounters. Scouts and Warriors attack player.  
**Epics Covered:** E3 partial (Scout, Warrior), E5 partial (Scrolling, Encounter System)  
**Status:** ✅ COMPLETE

## Stories Completed

### STORY-012: Parallax Scrolling Background
- 3-layer procedural starfield that scrolls vertically (wrap-based)
- Scroll offset drives encounter distance counter
- **Files:** `game_world.gd` (rewrite)

### STORY-013: Encounter Manager
- Loads per-sector JSON, fires encounters by distance threshold
- Covers: asteroid_field, mine_field, debris_cloud, scout_wave, warrior_wave, destroyer_wave, elite_wave, fuel_cache, derelict, star_cluster
- **Files:** `src/core/encounter_manager.gd`, `assets/data/encounters/sector_[1-5].json`

### STORY-014: EnemyBase Class
- HP, damage, scoring, drop table dispatch, stun, death signals
- Helper: `_fire_bolt()`, `_aim_at_player()`, score popup trigger
- **Files:** `src/gameplay/enemies/enemy_base.gd`

### STORY-015: Alien Scout
- Sine-wave drift, retreat-on-hit, 1.5s fire interval
- **Files:** `src/gameplay/enemies/alien_scout.gd`, `scenes/enemies/alien_scout.tscn`

### STORY-016: Alien Warrior
- Diagonal sweep, 3-shot burst, front-shield (50% from below)
- **Files:** `src/gameplay/enemies/alien_warrior.gd`, `scenes/enemies/alien_warrior.tscn`

### STORY-017: Enemy Projectiles
- `EnemyBolt` (instant-spawn, no pool), `EnemyMissile` (homing)
- **Files:** `src/gameplay/projectiles/enemy_bolt.gd`, `enemy_missile.gd` + scenes
