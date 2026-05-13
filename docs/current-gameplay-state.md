# Nova Scout — Current Gameplay State

**Purpose:** Ground future implementation work in what the build actually does now, separate from aspirational GDDs.

**Last reviewed:** 2026-05-12

---

## Project Snapshot

- Engine: Godot 4.x configured for GL Compatibility.
- Language: GDScript.
- Core autoloads: `GameManager`, `AudioManager`, `SaveManager`.
- Current repo path: `/Users/sqyer/star-finder/nova-scout`.
- Tests present: GUT tests under `tests/unit`.
- Audio assets are present under `assets/audio/music/` and `assets/audio/sfx/`; missing paths still fail gracefully.
- Sector 1 now has an authored opening pass documented in `design/quick-specs/first-five-minutes.md`; the first star cluster appears at distance 4400 (~110 seconds at base scroll speed).
- Mission-control tutorial prompts are wired for movement, fire, pickups, scan, abort, alien combat, and upgrades. They are one-time, non-blocking, and persist dismissal state through `SaveManager.prompt_history`.
- Key production docs:
  - `production/steam-finish-roadmap.md`
  - `production/steam-ready-backlog.md`
  - `production/steam-release-qa-checklist.md`

---

## Current Core Loop

```text
Travel through sector
  -> scripted encounters and ambient hazards
  -> star cluster
  -> scan stars
  -> barren / reward / alien combat / human viable result
  -> collect beacon or clear combat
  -> sector transition
  -> upgrade screen
  -> next sector
```

---

## Sector 5 Ending Flow Status

The previous campaign-spine blocker has been implemented at the code/test level:

- Sector 5 star E3 is `human_viable` and can collect the third beacon.
- `GameManager.has_required_beacons()` now means the finale is unlocked.
- `GameManager.is_campaign_complete()` and `GameManager.has_won()` now require both enough beacons and Mothership defeat.
- `GameWorld._on_viable_found()` no longer triggers the win state when E3 grants the third beacon.
- Sector 5 star E4 has result `mothership`, `mandatory_after: "E3"`, and a real wave path: `res://assets/data/waves/sector_5_mothership.json`.
- `StarClusterManager.reveal_mandatory_after("E3")` reveals E4 once the final beacon is found and counts it as required progression.
- Mothership defeat calls `GameManager.mark_mothership_defeated()` and true ending is triggered only after campaign completion.

Verified by `./scripts/verify.sh` on 2026-05-12: data validation passed and 64/64 GUT tests passed, including final-beacon reveal, Mothership arena entry, Mothership wave spawn/death wiring, automated full-campaign spine smoke, save/settings corruption safety, and persistent mission-control prompt behavior.

Remaining manual QA before calling this fully shippable:

- Automated full-campaign spine smoke now drives required sector scans, alien arenas, the final E3->E4 reveal, and Mothership defeat through true ending.
- Play or fast-forward through Sector 5 in-engine and confirm E4 appears after E3.
- Enter the Mothership arena, verify phase/music transitions, defeat it, and confirm the true-ending screen.
- Confirm restart/quit paths from the boss and win screen.

Implementation plan: `docs/plans/sector-5-mothership-ending-flow.md`

---

## Save and Settings Safety Status

- Missing save file keeps safe default high-score/settings state.
- Corrupted save JSON is ignored without crashing or clearing defaults.
- Malformed `settings`, `high_scores`, and tutorial prompt history payload types are ignored/sanitized.
- Settings now include safe defaults for audio, fullscreen, screen shake, CRT, flash intensity, text scale, hold-to-boost, and color-friendly mode.
- Main menu now exposes a compact settings overlay for audio, fullscreen, screen shake, CRT, flash intensity, text scale, hold/toggle boost, and color-friendly mode.
- Runtime hooks now apply music/SFX volume, fullscreen/windowed, screen shake multiplier, CRT toggle, flash intensity on CRT aberration/scanlines, and hold/toggle boost.
- Color-friendly palette and broad text-scale application still need full gameplay/menu runtime hooks.
- Covered by `tests/unit/test_save_manager.gd`.

---

## Export Smoke Status

- Export presets exist for Windows, macOS, Linux, and Web in `export_presets.cfg`.
- `scripts/export_smoke.py` exports Linux and validates native launch on supported hosts.
- Godot 4.6.2 export templates are installed on this host at `~/Library/Application Support/Godot/export_templates/4.6.2.stable/`.
- Latest macOS-host run passed Linux release export creation, macOS zip export creation, and native macOS executable launch smoke from `builds/macos/smoke/Nova Scout.app/Contents/MacOS/Nova Scout`.

---

## Current Strengths

- Strong retro sci-fi visual direction.
- Direct-control movement and arcade combat foundation.
- Five-sector campaign structure exists.
- Encounter JSON files exist.
- Enemy families, hazards, pickups, upgrades, audio manager, save manager, and tests exist.
- Mothership assets/code are now wired into the final flow and still need full in-engine boss QA.

---

## Current Technical Risks

- `src/core/game_world.gd` is the major architecture bottleneck and owns too many responsibilities.
- Many gameplay tuning values are still hardcoded in scripts rather than data files.
- Star scanning is currently more timer-like than signature mechanic.
- Basic data validation is centralized in `scripts/validate_data.py` and run by `scripts/verify.sh`; it now also enforces the Sector 1 first-discovery pacing bar.
- Scan pressure pulses are implemented for Sector 2+ star configs and covered by `tests/unit/test_star_node.gd`; damage/stability consequences and reveal presentation remain future work.
- Release QA checklist, Steam store capture, export validation, and full-campaign playthroughs still need execution.

---

## Current Product Direction

The target should be a focused 35-45 minute arcade story run with replay depth, not a stretched one-hour campaign.

Steam pitch direction:

> A retro sci-fi arcade survey shooter where every star scan is a dangerous discovery and the final beacon awakens a Mothership you must defeat to bring humanity home.

---

## Documentation Rule

When implementation changes actual behavior, update this file before declaring the task done.

Do not let README/GDD/store copy claim features or timings that the build does not actually support.
