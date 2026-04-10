# Sprint 07 — Polish, Balance, Testing

**Goal:** Game feels great, is balanced, and is production-ready.  
**Epics Covered:** E11 (Polish), E12 (Testing)
**Status:** ✅ COMPLETE (code-level; audio assets pending)

## Stories Completed

### STORY-042: Screen Shake
- `GameWorld.screen_shake(amount, duration)` — lerp-decays, applied via Node2D.position
- Called on enemy death, player hit, explosion
- **Files:** `src/core/game_world.gd`

### STORY-043: Score Popups
- Float-up, fade-out Node2D text ("+100", "+BEACON", etc.)
- Spawned by `game_world.spawn_score_popup()` called from enemy_base on death
- **Files:** `src/ui/score_popup.gd`, `scenes/ui/score_popup.tscn`

### STORY-044: Enemy HP Bars
- Thin 20px bar above enemy, visible on hit, fades after 2s
- **Files:** `src/ui/enemy_hp_bar.gd`

### STORY-045: External Force on Player (Gravity Pulse)
- `player.apply_external_force(impulse)` adds to velocity, decays 85% per frame
- **Files:** `src/gameplay/player/player.gd`

### STORY-046: CRT Overlay Shader
- Scanlines + vignette always-on; chromatic aberration on hull damage
- **Files:** `assets/shaders/crt_overlay.gdshader`, `src/ui/crt_overlay.gd`

## Balance Targets (for playtest calibration)
| Metric | Target | Status |
|--------|--------|--------|
| Sector 1 completion rate | 90%+ | Needs playtest |
| Scout kill feel | Immediate, satisfying | Code complete |
| Mothership fight duration | 4–8 min | Needs playtest |
| Crystal economy | 8–12 per sector | Needs playtest |
| Fuel scarcity | Occasional tension | Needs playtest |

## Outstanding (requires audio assets)
- E10-01: Compose/source 12 music tracks
- E10-02: Create/source ~57 SFX
- E10-03/04: Wire audio to AudioManager
- E10-05: Mothership adaptive music crossfade

## Launch Gate Status
- [x] All gameplay systems implemented
- [x] All 5 sectors scripted
- [x] All enemy types complete
- [x] Full game loop wired (start → play → die/win)
- [x] High score persistence
- [ ] Audio assets (music + SFX)
- [ ] Platform export configuration
- [ ] Performance profiling pass
