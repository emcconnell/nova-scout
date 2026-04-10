# Sprint 04 — All Enemies: Destroyer, Elites, Mothership

**Goal:** Full enemy roster. All 3 Elite variants + 3-phase Mothership boss.
**Epics Covered:** E3 complete
**Status:** ✅ COMPLETE

## Stories Completed

### STORY-024: Alien Destroyer
- 5 rotating attack patterns (Spiral, Twin Beam, Homing, Mine Drop, Shield Pulse)
- Double damage window during 2s pause between patterns (exposed core glows cyan)
- Calls `game_world.spawn_mine_at()` for mine drops
- **Files:** `src/gameplay/enemies/alien_destroyer.gd`, scene

### STORY-025: Elite Interceptor
- Teleport blink (2.5s interval, 60px), aimed 5-shot spread
- **Files:** `src/gameplay/enemies/alien_elite_interceptor.gd`, scene

### STORY-026: Elite Artillery
- Stationary at top, slow horizontal track, 6-shot volley with charge-up visual
- **Files:** `src/gameplay/enemies/alien_elite_artillery.gd`, scene

### STORY-027: Elite Swarm Commander
- Figure-8 patrol, spawns 2 scouts every 8s (max 8 total), homing missiles
- **Files:** `src/gameplay/enemies/alien_elite_swarm_commander.gd`, scene

### STORY-028: Mothership Boss
- 3-phase HP thresholds (60%, 30%), rotating laser sweep, missile volley, scout spawning
- Gravity pull pulse (Phase 2+), shield drone orbit (Phase 2+, respawns every 20s Phase 3)
- Desperation sweep at 10% with 3s warning + safe gap indicator
- Weak point: reactor core cycle (15s closed, 4s open = 3× damage)
- **Files:** `src/gameplay/enemies/mothership.gd`, scene

### STORY-029: Shield Drone
- Orbits Mothership, blocks ALL damage while alive (Mothership._modify_damage returns 0)
- **Files:** `src/gameplay/enemies/shield_drone.gd`, scene
