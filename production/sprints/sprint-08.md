# Sprint 08 — Pre-Release & Launch Prep

**Goal:** Game is release-ready: export configs set, performance verified, tests passing, audio scaffolded, and all final polish applied.  
**Epics Covered:** E12 (Testing), E10 (Audio scaffold), Release prep  
**Status:** 🟡 IN PROGRESS

---

## Stories

### STORY-048: Performance Pass — Enemy Spawn Hot Path ✅ DONE
- Replaced runtime `load()` calls in `_spawn_enemy_node()` with compile-time `preload()` constants
- Eliminated O(n) group iteration in `_aim_at_player()` / `_get_player()` — now uses `get_first_node_in_group()`
- Cached `get_viewport_rect()` result in `_vp_size` — eliminates repeated call inside `_draw()` (60fps)
- **Files:** `src/core/game_world.gd`, `src/gameplay/enemies/enemy_base.gd`

### STORY-049: Export Configuration ✅ DONE
- `export_presets.cfg` created for Windows x64, macOS (zip), Linux x64, Web (HTML5)
- Build output directories: `builds/{windows,macos,linux,web}/`
- Bundle ID: `com.starfinder.novascout`
- Version bumped to `1.0.0` in `project.godot`
- **Files:** `export_presets.cfg`, `project.godot`

### STORY-050: Audio Asset Manifest ✅ DONE
- Full manifest at `assets/audio/AUDIO_MANIFEST.md`
- All 49 required files catalogued (13 music + 36 SFX)
- Exact filenames match AudioManager `play_music()` / `play_sfx()` call sites
- Sourcing options documented (sfxr.me, Suno/Udio, Freesound CC0)
- **Files:** `assets/audio/AUDIO_MANIFEST.md`

### STORY-051: Core Unit Tests
- GameManager state machine tests
- PlayerHealth damage / death / invincibility tests
- PlayerFuel drain / refuel / depletion tests
- PlayerWeapons fire rate / ammo tests
- **Files:** `tests/unit/test_game_manager.gd`, `tests/unit/test_player.gd`

### STORY-052: Economy & Balance Balancing Pass
- Review crystal drop rates against upgrade costs
- Confirm fuel tension: player should be at <40% fuel at least once per sector
- Enemy HP values validated against laser damage (8 base) + missile damage
- Wave difficulty curve: Sector 1 easy → Sector 5 hard confirmed in encounter JSONs
- **Files:** `assets/data/encounters/*.json`, `design/gdd/gameplay-mechanics.md` tuning knobs

### STORY-053: .gitignore & Build Hygiene
- Add proper `.gitignore` for Godot 4 projects
- Exclude build artifacts, `.godot/` cache, export templates
- **Files:** `.gitignore`

### STORY-054: README Polish
- Update README with gameplay summary, controls, how to run, build instructions
- **Files:** `README.md`

---

## Launch Gate Checklist

| Item | Status |
|------|--------|
| All gameplay systems implemented | ✅ |
| All 5 sectors scripted | ✅ |
| All enemy types complete | ✅ |
| Full game loop (start → play → die/win) | ✅ |
| High score persistence | ✅ |
| CRT overlay shader | ✅ |
| Score popups | ✅ |
| Screen shake | ✅ |
| Enemy HP bars | ✅ |
| External force (gravity pulse) | ✅ |
| Performance pass (preload, group lookup) | ✅ |
| Export configuration | ✅ |
| Audio asset manifest | ✅ |
| Version bumped to 1.0.0 | ✅ |
| Audio assets sourced | ⬜ (requires external sourcing) |
| Unit tests | ⬜ Story-051 |
| Balance pass | ⬜ Story-052 |
| .gitignore | ⬜ Story-053 |
| README | ⬜ Story-054 |
| Platform export templates installed | ⬜ (Godot editor required) |
| Final playthrough: all 5 sectors | ⬜ Manual QA |
