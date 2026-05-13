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

### STORY-051: Core Unit Tests ✅ DONE
- GameManager state machine tests
- PlayerHealth damage / death / invincibility tests
- PlayerFuel drain / refuel / depletion tests
- PlayerWeapons fire rate / ammo tests
- **Files:** `tests/unit/test_game_manager.gd`, `tests/unit/test_player.gd`

### STORY-052: Economy, Balance, and Onboarding Pass 🟡 IN PROGRESS
- Sector 1 opening retuned so the first star cluster appears at distance 4400 (~110s base scroll speed)
- Removed pre-scan Sector 1 leviathan set pieces from the authored opening so movement/shoot/pickup/scan are taught before late-game pressure
- Added `design/quick-specs/first-five-minutes.md`
- Added data validation for the Sector 1 first-discovery pacing bar
- Added persistent, one-time mission-control prompts for movement, firing, pickups, scanning, aborting scans, alien combat, and upgrades
- Added automated full-campaign spine smoke test covering required sector scans, alien arena clears, final Mothership reveal, and true ending
- Added settings/accessibility save defaults, main-menu settings overlay, runtime audio/fullscreen hooks, and runtime hooks for screen shake, CRT, flash intensity, and hold/toggle boost
- Installed Godot 4.6.2 export templates locally and verified Linux release export creation plus native macOS export/launch smoke via `scripts/export_smoke.py`
- Remaining: manual timed playthrough, pause-menu settings access/manual settings QA, color-friendly/text-scale runtime polish, upgrade/economy feel check
- **Files:** `assets/data/encounters/sector_1.json`, `scripts/validate_data.py`, `scripts/export_smoke.py`, `design/quick-specs/first-five-minutes.md`, `src/ui/mission_prompt.gd`, `src/ui/hud.gd`, `src/ui/crt_overlay.gd`, `src/core/save_manager.gd`, `src/core/main_menu.gd`, `src/core/game_world.gd`, `src/gameplay/player/player.gd`

### STORY-053: .gitignore & Build Hygiene ✅ DONE
- Add proper `.gitignore` for Godot 4 projects
- Exclude build artifacts, `.godot/` cache, export templates
- **Files:** `.gitignore`

### STORY-054: README Polish ✅ DONE
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
| Unit tests | ✅ 64/64 passing via `./scripts/verify.sh` |
| Balance/onboarding pass | 🟡 Sector 1 first scan now lands around 110s and prompts/settings are wired; manual timing remains |
| .gitignore | ✅ Story-053 |
| README | ✅ Story-054 |
| Platform export templates installed | ✅ Godot 4.6.2 templates installed locally; Linux export and native macOS export/launch smoke pass |
| Final playthrough: all 5 sectors | ⬜ Manual QA |
