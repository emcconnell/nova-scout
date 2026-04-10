# Sprint 06 — Menus, Flow, Full Game Loop

**Goal:** All screens wired. Game can be played start to finish.
**Epics Covered:** E9 (Menus & Flow), E10 partial (Audio wiring — stubs only)
**Status:** ✅ COMPLETE

## Stories Completed

### STORY-035: Pause Menu
- ESC toggle, pauses tree, resume/restart/quit options
- **Files:** `src/ui/pause_menu.gd`

### STORY-036: Death Screen
- 2s delay, log entry aesthetic, retry/main menu prompt
- **Files:** `src/ui/death_screen.gd`

### STORY-037: Upgrade Screen
- 5 upgrade types, crystal cost check, apply_upgrade integration
- **Files:** `src/ui/upgrade_screen.gd`

### STORY-038: Sector Transition
- 3-phase: warp streaks (2.5s) → stat summary (2s) → mission log text
- Advances GameManager.current_sector, then shows upgrade screen
- **Files:** `src/ui/sector_transition.gd`

### STORY-039: Win Screens (True + Standard Ending)
- Separated by true_ending bool (defeated Mothership vs escaped)
- Score/beacons display, scrolling mission log, save high score
- **Files:** `src/ui/win_screen.gd`

### STORY-040: High Score Table
- H key on main menu, top-10 display, format: rank/score/sector/beacons
- **Files:** `src/core/main_menu.gd` (extended)

### STORY-041: GameWorld Full State Machine
- Travel → StarCluster → Arena → SectorTransition → Upgrade → (reload scene)
- Death → DeathScreen → retry / menu
- Win → WinScreen (true/standard)
- **Files:** `src/core/game_world.gd` (complete)

## Audio Note
Audio stubs (play_sfx / play_music calls) are in all scripts.
Actual audio assets require sourcing/compositing (E10-01, E10-02).
AudioManager handles missing files silently — game runs without audio assets.
