# Nova Scout — Steam Release QA Checklist

**Purpose:** Release gate for a Steam-quality build.

Use this document after the major finish-roadmap milestones are implemented. A build is not a release candidate while any P0 or P1 launch blocker remains open.

---

## Build Identity

- [ ] Version number set correctly in `project.godot`.
- [ ] Export presets exist for Windows, Linux, and macOS.
- [ ] Build artifacts are created from a clean checkout.
- [ ] Build output directories do not include editor cache or source-only clutter.
- [ ] README and in-game version match the build.

---

## Campaign Completion

- [ ] New game starts from main menu.
- [ ] Sector 1 can be completed.
- [ ] Sector 2 can be completed.
- [ ] Sector 3 can be completed and first beacon can be collected.
- [ ] Sector 4 can be completed and second beacon can be collected.
- [ ] Sector 5 final beacon does not immediately bypass the Mothership.
- [ ] Mothership encounter begins reliably.
- [ ] Mothership phase transitions work.
- [ ] Mothership defeat triggers true ending.
- [ ] Death screen works from travel, scan, arena, and boss contexts.
- [ ] Restart/quit paths work after death and win.

---

## First-Time Player Experience

- [ ] Movement prompt appears only when useful. Automated: mission prompt system requests this once at game start and persists dismissal.
- [ ] Fire prompt appears before or during first combat object. Automated: prompt hook exists for asteroid fields and scout waves.
- [ ] Pickup prompt/feedback appears after first pickup opportunity. Automated: prompt hook exists for fuel cache encounters.
- [ ] Scan prompt appears near first star. Automated: prompt hook exists when a star cluster starts.
- [ ] Scan abort behavior is taught or discoverable. Automated: prompt hook exists when player enters star scan range.
- [ ] Upgrade screen explains costs and effects. Automated: prompt hook exists before upgrade screen display.
- [ ] Player sees a memorable discovery/danger beat within first five minutes.
- [ ] First star cluster appears by distance 4800 (~120 seconds at base scroll speed); currently enforced by `scripts/validate_data.py`.
- [ ] No late-game set-piece enemy appears before the first scan.
- [ ] No tutorial prompt blocks control during danger.

---

## Controls and Input

### Keyboard

- [ ] Movement works in 8 directions.
- [ ] Fire/boost/scan/missile/EMP work.
- [ ] Pause/resume works.
- [ ] Restart/quit confirmations work.

### Gamepad

- [ ] Movement works with stick/d-pad.
- [ ] Fire/boost/scan/missile/EMP work.
- [ ] Menus are navigable without mouse.
- [ ] Upgrade screen is navigable without mouse.
- [ ] Pause/death/win screens are navigable without mouse.
- [ ] Controller can complete a full run.

---

## Settings and Accessibility

- [ ] Music volume persists.
- [ ] SFX volume persists.
- [ ] Fullscreen/windowed setting persists.
- [ ] Screen shake amount/toggle works. Automated: default persists and `GameWorld.screen_shake()` applies the saved multiplier.
- [ ] CRT/scanline toggle works. Automated: main menu setting persists and `CRTOverlay` applies visibility/scanline strength at runtime.
- [ ] Flash intensity reduction works. Automated: main menu setting persists and `CRTOverlay` scales scanline/aberration intensity.
- [ ] Color-friendly bullets/pickups mode is readable. Save/menu setting exists; runtime palette hook still requires implementation.
- [ ] Text scale setting is readable in HUD and menus. Save/menu setting exists; broad runtime scaling still requires implementation.
- [ ] Hold/toggle boost option works if implemented. Automated: main menu setting persists and `Player` switches between hold and toggle boost behavior.
- [ ] Settings survive restart.
- [ ] Corrupted settings file falls back to defaults.

---

## Save and Persistence

- [ ] High score saves after death.
- [ ] High score saves after win.
- [ ] Settings and high scores do not corrupt each other.
- [ ] Missing save file creates a safe default.
- [ ] Corrupted save file does not crash.
- [ ] Save format changes are handled or versioned.

---

## Gameplay Balance Smoke Tests

- [ ] Sector 1 teaches without feeling empty.
- [ ] Sector 2 adds meaningful enemy pressure.
- [ ] Sector 3 combines hazards and scanning pressure.
- [ ] Sector 4 feels dangerous but fair.
- [ ] Sector 5 feels climactic before the boss.
- [ ] Fuel tension occurs without frequent unavoidable deaths.
- [ ] Upgrade economy allows meaningful choices, not everything every run.
- [ ] Physical pickups are collectible without forcing reckless movement every time.
- [ ] Optional stars are tempting but not mandatory for a normal clear.

---

## Performance

- [ ] Worst-case travel hazard scene holds target FPS.
- [ ] Worst-case arena wave holds target FPS.
- [ ] Mothership phase 3 holds target FPS.
- [ ] Large explosion/pickup/reward burst does not hitch noticeably.
- [ ] No runaway enemy/projectile/pickup counts.
- [ ] Object pools are used for high-frequency objects where implemented.
- [ ] Memory does not grow unbounded over a full run.

---

## Audio and Presentation

- [ ] Sector music starts and transitions correctly.
- [ ] Mothership music phase changes work.
- [ ] SFX volume affects all SFX.
- [ ] Important events have cues: beacon, scan complete, scan interrupted, low fuel, shield break, missile lock, boss phase, victory.
- [ ] No missing-file warnings for audio assets in release build.
- [ ] Screen shake/flash effects are not excessive with default settings.
- [ ] CRT effect does not obscure essential gameplay.

---

## Data Validation

Run `./scripts/verify.sh` for fast validation. Run `python3 scripts/export_smoke.py` to validate Linux release export creation plus native launch smoke where supported by the current host. On macOS it also exports `builds/macos/nova-scout.zip`, extracts the `.app`, and launches the app executable headless.

- [ ] Encounter distances are sorted.
- [ ] Each sector has a star-cluster endpoint.
- [ ] Encounter types are known.
- [ ] Enemy types are known.
- [ ] Referenced wave files exist.
- [ ] Star result types are known.
- [ ] No progression-critical ignored fields remain, e.g. unhandled `mandatory_after`.
- [ ] Drop table weights are valid.
- [ ] Balance JSON loads with no missing required keys.

---

## Steam Store Readiness

- [ ] Short description is accurate.
- [ ] Long description is accurate.
- [ ] Screenshots show real gameplay, not debug/prototype states.
- [ ] Trailer shot list or trailer exists.
- [ ] Capsule art brief or capsule art exists.
- [ ] Minimum system requirements are documented.
- [ ] Support/bug-report instructions exist.
- [ ] Known issues list contains no progression blockers.

---

## Release Candidate Rule

The build can be called an RC only when:

- [ ] All P0 items pass.
- [ ] No known crash, softlock, save corruption, or progression blocker remains. Automated: campaign spine smoke reaches true ending through required scans, arena clears, final reveal, and Mothership defeat.
- [ ] Full campaign has been completed at least twice from a clean save.
- [ ] Full campaign has been completed once with gamepad.
- [ ] Exported build, not editor run, has been used for final smoke testing.
