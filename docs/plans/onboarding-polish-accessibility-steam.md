# Onboarding, Polish, Accessibility, and Steam UX Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Make Nova Scout feel finished to first-time Steam players: clear onboarding, readable UI, satisfying feedback, expected settings, and accessibility options.

**Architecture:** Add player-facing polish incrementally. Start with the first-five-minutes tutorial and settings foundation, then add accessibility and release UX checks. Avoid large rewrites of HUD/menu code until behavior is protected.

**Tech Stack:** Godot 4, GDScript, SaveManager settings, HUD/menu scenes, manual screenshot/playtest verification.

---

## Task 1: Author the first-five-minutes flow

**Objective:** Define the exact opening experience before implementation.

**Files:**

- Create: `design/quick-specs/first-five-minutes.md`
- Modify if needed: `assets/data/encounters/sector_1.json`

**Required beats:**

1. 0:00-0:20 — launch, movement prompt, simple asteroid lane.
2. 0:20-0:45 — first asteroid split, laser prompt, pickup feedback.
3. 0:45-1:15 — fuel cache or derelict, teaches shooting objects for resources.
4. 1:15-1:45 — first star cluster appears early.
5. 1:45-2:15 — first scan completes with reveal and reward.
6. 2:15-3:00 — tiny alien signal or mine encounter foreshadows danger.

**Verification:** The spec states exact encounter edits and prompt triggers.

**Status 2026-05-12:** Implemented. `design/quick-specs/first-five-minutes.md` exists, Sector 1 first `star_cluster` is at distance 4400, and `scripts/validate_data.py` enforces the 4800-distance pacing bar.

---

## Task 2: Add mission-control prompt system

**Objective:** Provide short contextual onboarding without blocking control.

**Files:**

- Create: `src/ui/mission_prompt.gd` and scene if needed
- Modify: `src/ui/hud.gd` or appropriate UI root
- Modify: `src/core/save_manager.gd` for dismissed prompt flags

**Prompt rules:**

- Max one prompt visible at a time.
- Prompts auto-dismiss after a short duration or after the player performs the action.
- Prompts should not pause gameplay.
- Prompt history persists so repeated runs are not noisy.
- There is a setting or debug reset path for prompt history.

**Initial prompts:**

- Move: “Survey Probe Seven online. WASD / Stick to navigate.”
- Fire: “Break debris with the laser.”
- Boost: “Boost burns fuel. Use it to escape pressure.”
- Pickup: “Crystals fund upgrades. Fuel keeps the probe alive.”
- Scan: “Approach the star and press Scan.”
- Abort: “Scan locks orbit. Press Scan again to abort.”
- Alien: “Signal spike. Weapons free.”
- Upgrade: “Spend crystals between sectors to shape the run.”

**Verification:** Prompts appear in context, disappear correctly, persist dismissal, and remain readable at 320x180.

**Status 2026-05-12:** Implemented at code/test level. `src/ui/mission_prompt.gd` queues one prompt at a time, auto-dismisses, and persists dismissed prompt IDs through `SaveManager.prompt_history`. `GameWorld` requests prompts for movement, fire, pickups, scan, abort, alien combat, and upgrades; `HUD` renders the active mission-control panel. Manual readability/timing QA remains.

---

## Task 3: Tune Sector 1 for early discovery

**Objective:** Make the first scan happen quickly enough to sell the game.

**Files:**

- Modify: `assets/data/encounters/sector_1.json`
- Modify: `src/core/encounter_manager.gd` only if sector length/timing still blocks pacing

**Rules:**

- First star cluster or scripted early scan encounter should happen around 90-120 seconds.
- Keep danger low but non-empty.
- Ensure fuel and repair pickups teach resource collection.

**Verification:** Manual timed playthrough from new game reaches scan prompt/discovery within target time.

---

## Task 4: Expand settings model

**Objective:** Add Steam-expected player options.

**Files:**

- Modify: `src/core/save_manager.gd`
- Modify: `src/core/main_menu.gd` or settings menu scene/script
- Modify: `src/core/audio_manager.gd` if volume plumbing is incomplete

**Settings:**

- music volume
- SFX volume
- fullscreen/windowed
- screen shake amount
- CRT/scanline toggle
- flash intensity
- text scale
- hold/toggle boost
- color-friendly mode

**Rules:**

- All settings have safe defaults.
- Missing/corrupted setting values do not crash.
- Settings persist after restart.
- Runtime changes apply immediately where practical.

**Verification:** Change every setting, restart, confirm persistence.

**Status 2026-05-12:** Partially implemented. `SaveManager.DEFAULT_SETTINGS` now includes safe defaults for all listed settings and validates known setting types. Settings menu controls and complete runtime application still remain.

---

## Task 5: Add accessibility hooks to gameplay effects

**Objective:** Make effects adjustable without removing the game's identity.

**Files:**

- Modify: screen shake calls in `src/core/game_world.gd` or extracted system
- Modify: CRT overlay/shader toggles
- Modify: explosion/flash effects
- Modify: bullet/pickup color drawing as needed

**Features:**

- Screen shake multiplier.
- Flash intensity multiplier.
- CRT off/on.
- Color-friendly palette for enemy bullets/pickups.
- Text scale for UI prompts/menus.

**Verification:**

- At minimum settings, game remains readable and less intense.
- At default settings, intended retro style remains intact.
- No setting requires a new run to apply unless documented.

**Status 2026-05-12:** Partially implemented. Screen shake now reads `SaveManager.get_setting("screen_shake")` and scales/disables shake at runtime. Flash, CRT, color-friendly palette, and text scale hooks remain.

---

## Task 6: Add controls/help/codex screen

**Objective:** Give players a place to recover context mid-run.

**Files:**

- Create: `src/ui/help_screen.gd` and scene if needed
- Modify: pause menu / main menu flow

**Content:**

- Controls keyboard/gamepad.
- Core loop.
- Scanning and aborting.
- Pickups.
- Upgrades.
- Enemy/hazard basics.
- Accessibility/settings reminder.

**Verification:** Help is reachable from main menu and pause menu, and returns to the previous screen cleanly.

---

## Task 7: Add score and feedback polish

**Objective:** Increase moment-to-moment satisfaction and replay signals.

**Files:**

- Modify: `src/core/game_manager.gd`
- Modify: `src/ui/hud.gd`
- Modify: combat/projectile/enemy scripts as needed

**Features:**

- Visible streak indicator.
- Near-miss scoring with cooldown.
- End-of-sector bonus breakdown:
  - no hull damage
  - fuel efficiency
  - all stars scanned
  - optional anomaly found
  - fast scan chain
  - enemies destroyed
  - near-miss count
- Hit sparks and shield impact rings.

**Verification:** Player receives frequent feedback without HUD clutter or score spam.

---

## Task 8: Add audio cue completeness pass

**Objective:** Ensure major events sound finished.

**Files:**

- Modify: `src/core/audio_manager.gd`
- Modify event call sites
- Update: `assets/audio/AUDIO_MANIFEST.md`

**Required cues:**

- beacon acquired
- scan nearing completion
- scan interrupted
- enemy weakpoint hit
- missile lock
- overheat warning/recovery
- shield break/recharge
- low fuel escalating alarm
- sector transition warp
- Mothership reveal/phase/victory

**Verification:** No missing-file warnings and volume settings affect all cues.

---

## Task 9: Steam store capture readiness

**Objective:** Prepare the game for screenshots/trailer after core polish lands.

**Files:**

- Create: `production/steam-store-capture-plan.md`

**Shot list:**

1. Title/menu with retro identity.
2. Sector 1 movement/combat with HUD.
3. Star scan in progress with pressure pulse.
4. Human viable reveal.
5. Upgrade screen with meaningful choices.
6. Dense Sector 4/5 combat.
7. Mothership reveal.
8. Mothership phase 3 or victory.

**Verification:** Each shot exists in-game without debug overlays and represents actual gameplay.

---

## Final Acceptance Criteria

- A new player can understand the game without reading README.
- A returning player can disable/reduce distracting effects.
- Keyboard and gamepad users can navigate the whole experience.
- The first five minutes contain discovery, combat, reward, and a clear objective.
- Steam screenshots/trailer can be captured from real polished gameplay.
