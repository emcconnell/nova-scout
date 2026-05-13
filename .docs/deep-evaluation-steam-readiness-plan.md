# Nova Scout Deep Evaluation and Steam-Readiness Implementation Plan

> **For Hermes:** Use TDD and incremental verification. Continue autonomously through the task list until blocked by a platform/account/submission boundary. Do not ask for user input for ordinary implementation choices.

**Goal:** Convert the deep evaluation into a tracked implementation plan that improves release confidence, makes star scanning the signature Steam hook, completes accessibility/controller readiness, and strengthens progression/reward motivation.

**Architecture:** Prefer targeted, release-facing fixes over broad refactors. Add validation and tests before behavior changes where practical. Extract small helpers only when they make tuning, validation, or testing easier.

**Tech Stack:** Godot 4.6.2, GDScript, GUT, Python validation/export scripts, JSON data.

---

## Current Ground Truth

Verified after this plan pass:

- `./scripts/verify.sh` passes with data validation and 74/74 GUT tests.
- `python3 scripts/export_smoke.py` passes Linux export, macOS export, and native macOS launch smoke.
- `git diff --check` passes.
- Export smoke now fails on Godot script/runtime errors instead of trusting exit code alone.
- Headless export launch disables AudioManager streams, avoiding the previous `mission_log.wav` leak in smoke runs.

Important project files:

- `src/core/game_world.gd` — campaign/spawning/scan/arena/loot/death/win god-controller.
- `src/gameplay/star_scan/star_cluster_manager.gd` — hardcoded star configs and scan completion flow.
- `src/gameplay/star_scan/star_node.gd` — scan progress, star display, pressure pulses.
- `src/core/audio_manager.gd` — music/SFX; likely source of macOS launch resource leak.
- `scripts/validate_data.py` — JSON/content validator.
- `scripts/verify.sh` — fast verification gate.
- `scripts/export_smoke.py` — release export/launch smoke.
- `src/core/main_menu.gd`, `src/ui/pause_menu.gd`, `src/ui/hud.gd`, `src/ui/upgrade_screen.gd` — release-facing UX.

---

## Deep Evaluation Summary

### Strengths

- Campaign spine is now automated through final reveal, Mothership arena, Mothership defeat, and true ending.
- Sector 1 first star cluster appears at distance 4400, satisfying the 4800 onboarding pacing bar.
- Save/load hardening and prompt persistence have tests.
- Export templates are installed locally and export smoke works.
- Main menu settings expose audio, fullscreen, shake, CRT, flash, text scale, boost mode, and color mode.

### Major Risks / Opportunities

1. **Release validation trust:** `verify.sh` passes despite a Godot `SCRIPT ERROR` from GUT. Export smoke passes despite ObjectDB/resource leak warnings.
2. **Signature mechanic under-polished:** star scanning is still mostly timer-based and pre-scan color can spoil results.
3. **Data validation gaps:** reward tokens, encounter params, scan pressure, and wave/result compatibility are under-validated.
4. **Accessibility gap:** `text_scale` and `color_friendly` are exposed but not fully applied.
5. **Controller/Steam Deck gap:** several menus and hints are keyboard-first; debug sector skip keys are release-visible.
6. **Progression/reward gap:** upgrades are linear stat shopping; scoring lacks end-of-sector ceremony; pickups could feel more dopamine-rich.
7. **Architecture risk:** `GameWorld.gd` is 824 lines and many tuning values remain hardcoded.

---

## Implementation Task List

Status key: `[ ]` TODO, `[>]` IN PROGRESS, `[x]` DONE, `[!]` BLOCKED.

### Phase 1 — Release Validation Trust

- [x] Task 1.1: Fix AudioManager shutdown/resource leak.
  - Modify: `src/core/audio_manager.gd`.
  - Add `_exit_tree()` cleanup that kills tweens, stops both music players, clears streams, stops SFX players, and clears SFX streams.
  - Update crossfade/stop behavior so old players stop after fade.
  - Verify: native macOS launch smoke should no longer leak `mission_log.wav`.

- [x] Task 1.2: Patch known GUT startup script error or set missing ProjectSettings default.
  - Inspect: `addons/gut/gut_loader.gd:35`.
  - Prefer non-invasive project setting default if available; otherwise patch addon guard to coerce nil to false.
  - Verify: `./scripts/verify.sh` no longer prints `SCRIPT ERROR`.

- [x] Task 1.3: Make verification stricter.
  - Modify: `scripts/verify.sh`.
  - Fail on `SCRIPT ERROR` and unexpected `ERROR:` in product/test output.
  - Keep GUT success summary requirement.
  - Verify: tests pass with clean output.

### Phase 2 — Data Validation Hardening

- [x] Task 2.1: Fix invalid scan reward token.
  - Modify: `src/gameplay/star_scan/star_cluster_manager.gd` or reward parser.
  - Replace or implement `missile4` semantics.
  - Add regression coverage.

- [x] Task 2.2: Validate scan reward tokens.
  - Modify: `scripts/validate_data.py`.
  - Known pickup tokens: `fuel_cell`, `repair_kit`, `missile_pack`, `emp_cartridge`, `energy_cell`, `crystal`, `shield_booster`, `survey_beacon`.
  - Allow `crystalN` grammar.
  - Verify invalid reward examples fail.

- [x] Task 2.3: Validate wave_path/result compatibility.
  - `alien_territory` and `mothership` may use arena `wave_path`.
  - `human_viable` should not specify arena wave data unless a new explicit scan-wave field exists.
  - Resolve `sector_5_star_e3.json` intent.

- [x] Task 2.4: Validate scan pressure pulses.
  - Validate pulse `at` in 0..1, positive count, known pulse type.
  - Add tests or validator negative fixture coverage.

- [x] Task 2.5: Validate encounter params.
  - Positive counts, known `mine_type`, known ambush types, elite variants, sane `hp_scale`, asteroid tier range.
  - Add max encounter gap warning or error threshold if appropriate.

### Phase 3 — Star Scanning Signature Polish

- [x] Task 3.1: Hide pre-scan result spoilers.
  - Modify: `src/gameplay/star_scan/star_node.gd`.
  - Pre-scan color/icon should show unknown/risk class, not final result.
  - Reveal final result only after scan completion.

- [x] Task 3.2: Add scan stability.
  - Add stability/progress loss under scan pressure/damage.
  - Keep first Sector 1 scan forgiving.
  - Verify with GUT tests.

- [x] Task 3.3: Add first-discovery reveal beat.
  - Sector 1 first cluster should produce a memorable reveal/SFX/mission-control message.
  - Consider `src/ui/mission_prompt.gd`, `src/ui/hud.gd`, and star scan completion flow.

- [x] Task 3.4: Add scan result labels/reveal presentation.
  - Labels: `QUIET SIGNAL`, `TRACE MINERALS`, `BIO-SIGNATURE?`, `HOSTILE NOISE`, `ANOMALOUS STATIC`.
  - Add score/reward popup on scan completion.

### Phase 4 — Accessibility and Settings Completion

- [ ] Task 4.1: Create a central `SettingsApplier` or helper methods.
  - Avoid duplicated runtime setting logic in menus/world/UI.

- [x] Task 4.2: Apply `text_scale` to HUD and mission prompts.
  - Modify: `src/ui/hud.gd`, `src/ui/mission_prompt.gd` as needed.

- [x] Task 4.3: Apply `color_friendly` to pickups/projectiles/star scan/readability colors.
  - Modify relevant draw scripts.

- [x] Task 4.4: Add settings access to pause menu.
  - Modify: `src/ui/pause_menu.gd`.
  - Keep gameplay pausable and settings persistent.

### Phase 5 — Controller / Steam Deck Menu Safety

- [x] Task 5.1: Replace raw keyboard-only menu shortcuts with navigable options.
  - Modify: `src/core/main_menu.gd`.
  - High scores/settings should be selectable with controller.

- [x] Task 5.2: Gate or remove sector skip keys in release builds.
  - Debug sector start must not be visible/active in release exports.

- [x] Task 5.3: Add controller-aware prompt/hint text.
  - Prefer action-label helper.

### Phase 6 — Progression, Scoring, and Pickup Dopamine

- [x] Task 6.1: Add upgrade comparison UI.
  - Show current value -> upgraded value.
  - Modify: `src/ui/upgrade_screen.gd`, `src/core/game_manager.gd`.

- [x] Task 6.2: Add basic branch identity to upgrades.
  - Explorer, Fighter, Survivor.
  - Keep scope small and testable.

- [x] Task 6.3: Add end-of-sector scoring breakdown.
  - No damage, fuel conserved, scans completed, streak retained, fast scan.

- [x] Task 6.4: Improve pickup feedback.
  - More visible reward bursts, score/crystal popups, early magnet readability.

### Phase 7 — Final Verification and Documentation

- [x] Task 7.1: Run full verification.
  - `./scripts/verify.sh`
  - `python3 scripts/export_smoke.py`
  - `git diff --check`

- [x] Task 7.2: Update project docs.
  - `docs/current-gameplay-state.md`
  - `production/steam-ready-backlog.md`
  - `production/steam-release-qa-checklist.md`
  - This `.docs` plan.

- [ ] Task 7.3: Commit and push completed work if user has requested it or after a coherent milestone.

---

## Immediate Work Order

Start with Phase 1, then Phase 2, then Phase 3. These have the best risk/reward ratio:

1. Fix AudioManager resource leak and GUT script error.
2. Make verification stricter so future green runs mean more.
3. Harden data validation and fix known content issues.
4. Improve star scanning reveal/risk so the core hook is desirable.

---
