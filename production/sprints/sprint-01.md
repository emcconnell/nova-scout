# Sprint 01 — Foundation & Playable Ship

**Goal:** A playable ship flying in empty space with working hazards. No enemies, no UI. Pure feel test.  
**Epics Covered:** E0 (complete), E1 (complete), E2 (complete)  
**Estimated Hours:** ~51h  

---

## Sprint Stories

### STORY-001: Project Setup
**Epic:** E0 | **Priority:** P0  
Set up the Godot 4 project with correct display settings, input map, audio buses, autoload singletons, and git.  
**Done when:** Project opens to a black 320×180 window with no errors. All autoloads initialize cleanly.  
**Tasks:** E0-01 through E0-10

---

### STORY-002: Player Movement
**Epic:** E1 | **Priority:** P0  
8-directional player movement, boost, screen bounds (horizontal wrap, vertical lock).  
**Done when:** Player moves fluidly in all 8 directions, boost increases speed and drains fuel, craft wraps horizontally.  
**Tasks:** E1-01, E1-02, E1-03, E1-10

---

### STORY-003: Player Stats & Damage
**Epic:** E1 | **Priority:** P0  
Hull, shield, and fuel stats. Player takes damage from contact. Shield regenerates. Death triggers signal.  
**Done when:** Player has working stats, takes damage, shield regens after 3s, dies when hull reaches 0.  
**Tasks:** E1-04, E1-05, E1-06

---

### STORY-004: Laser Weapon
**Epic:** E1 | **Priority:** P0  
Basic laser with pooled projectiles, auto-fire on hold, correct damage.  
**Done when:** Laser fires at 8/s, projectiles travel up the screen, destroy hazards on contact.  
**Tasks:** E1-07

---

### STORY-005: Missile Weapon
**Epic:** E1 | **Priority:** P0  
Missiles with limited ammo, homing logic (nearest enemy within 200px), explosion AoE.  
**Done when:** Missiles fire, home on nearest target or go straight, deal AoE damage, respect ammo count.  
**Tasks:** E1-08

---

### STORY-006: EMP Pulse
**Epic:** E1 | **Priority:** P0  
EMP stuns all enemies on screen for 2.5s, clears all bullets, limited charges.  
**Done when:** EMP fires, expanding ring visual, all enemies stunned, all bullets destroyed, charges tracked.  
**Tasks:** E1-09

---

### STORY-007: Player Visuals
**Epic:** E1 | **Priority:** P1  
All player sprites (idle, thrust, bank, hit, explosion), engine glow, shield shimmer.  
**Done when:** Player looks good with all animations and shader effects.  
**Tasks:** E1-11, E1-12, E1-13, E1-14

---

### STORY-008: Asteroids
**Epic:** E2 | **Priority:** P0  
Three sizes of asteroid with split logic, correct damage, loot drops.  
**Done when:** Asteroids spawn, drift, split correctly on destruction, drop pickups at correct rates.  
**Tasks:** E2-01, E2-02, E2-03, E2-05

---

### STORY-009: Space Mines
**Epic:** E2 | **Priority:** P0  
Mines trigger on proximity, chase player, explode on contact.  
**Done when:** Mines sit still, trigger when player approaches, chase and explode correctly.  
**Tasks:** E2-06

---

### STORY-010: Debris Cloud
**Epic:** E2 | **Priority:** P0  
Debris cloud area slows player and deals damage over time.  
**Done when:** Entering cloud reduces speed 40% and deals 3 damage/sec.  
**Tasks:** E2-08

---

### STORY-011: Hazard Visuals
**Epic:** E2 | **Priority:** P1  
All hazard sprites: asteroids (9 variants + rotation), mines, debris cloud.  
**Done when:** All hazards have polished sprites/animations.  
**Tasks:** E2-04, E2-07, E2-09

---

## Sprint 01 Exit Criteria
- [ ] Project runs cleanly at 60fps
- [ ] Player moves, boosts, wraps, takes damage, dies
- [ ] All 3 weapons fire and work correctly
- [ ] All 3 hazards spawn and behave correctly
- [ ] Player craft has all visual states
- [ ] No autoload errors on startup
- [ ] Game "feels good" — movement is responsive, laser is satisfying
