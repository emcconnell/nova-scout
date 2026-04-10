# Sprint 05 — Pickups + Full HUD + UI Integration

**Goal:** Physical pickup entities, drop table system, complete HUD pipeline.  
**Epics Covered:** E4 (Pickups), E8 (HUD complete)
**Status:** ✅ COMPLETE

## Stories Completed

### STORY-030: PickupBase
- Drifts with randomised velocity, magnet effect (40px range), 5s despawn, flash warning
- Auto-applies effect on player contact
- **Files:** `src/gameplay/pickups/pickup_base.gd`

### STORY-031: All 8 Pickup Types (PickupVisuals)
- fuel_cell, repair_kit, missile_pack, emp_cartridge, crystal, shield_booster, survey_beacon
- Each has unique procedural pixel visual
- **Files:** `src/gameplay/pickups/pickup_visuals.gd`, `scenes/pickups/pickup.tscn`

### STORY-032: Drop Table
- Probability-weighted per enemy type (scout, warrior, destroyer, elite, mothership)
- `roll()` static method, `from_loot_list()` for wave loot
- **Files:** `src/gameplay/pickups/drop_table.gd`

### STORY-033: PlayerHealth.heal_shield
- Added `heal_shield(amount)` API for shield booster pickup
- **Files:** `src/gameplay/player/player_health.gd`

### STORY-034: CRT Shader Overlay
- Scanlines + vignette (ShaderMaterial, ColorRect)
- Chromatic aberration triggered on hull hit, decays per frame
- **Files:** `assets/shaders/crt_overlay.gdshader`, `src/ui/crt_overlay.gd`
