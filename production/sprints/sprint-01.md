# Sprint 01 — Foundation & Playable Ship

**Goal:** A playable ship flying in empty space with working hazards. No enemies, no UI. Pure feel test.  
**Epics Covered:** E0 (complete), E1 (complete), E2 (complete)  
**Status:** ✅ COMPLETE  

---

## Sprint Stories

### STORY-001: Project Setup ✅
Set up the Godot 4 project with correct display settings, input map, audio buses, autoload singletons.

### STORY-002: Player Movement ✅
8-directional movement, boost, screen bounds (horizontal wrap, vertical lock), external force API.

### STORY-003: Player Stats & Damage ✅
Hull, shield, fuel stats. Damage, shield regen, death signal, heal_shield API.

### STORY-004: Laser Weapon ✅
Pooled laser bolts at 8/s, correct damage, player_bullets group.

### STORY-005: Missile Weapon ✅
Homing missiles, AoE explosion, hits hazards AND enemies (collision_mask=18).

### STORY-006: EMP Pulse ✅
Stuns all enemies, destroys enemy_bullets, EMP charge tracking.

### STORY-007: Player Visuals ✅
Procedural draw: fuselage, wings, cockpit bubble, animated engine glow, shield arc.

### STORY-008: Asteroids ✅
3 sizes with split logic, pooled collision, loot drops.

### STORY-009: Space Mines ✅
Proximity trigger, chase, explode, drift into play area.

### STORY-010: Debris Cloud ✅
-40% speed, 3hp/s damage, cleanup on despawn, drift velocity.

### STORY-011: Hazard Visuals ✅
All hazards: procedural pixel drawing.

---

## Sprint 01 Exit Criteria
- [x] Project runs cleanly at 60fps
- [x] Player moves, boosts, wraps, takes damage, dies
- [x] All 3 weapons fire and work correctly
- [x] All 3 hazards spawn and behave correctly
- [x] Player craft has all visual states
- [x] No autoload errors on startup
- [ ] Game "feels good" — movement is responsive, laser is satisfying *(needs in-engine playtest)*

## Bug Fixes Applied (2026-04-09)
- **Missiles now hit hazards**: Extended to check `"hazards"` group; AoE mask = 18.
- **DebrisCloud now slows player 40%**: `_speed_mult` + `enter_debris()`/`exit_debris()` API.
- **All 3 hazards now spawn**: Mine timer (6s/12s) + debris cloud timer (10s/18s).
- **Hazards drift into play area**: Mine drifts to y=30 then holds; DebrisCloud drifts downscreen.
- **Player orbit dead code fixed**: `_physics_process` calls `_update_orbit(delta)` when in orbit.
