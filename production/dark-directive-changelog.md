# Dark Directive v2.0 — Implementation Changelog

**Date:** 2026-07-06
**Design source:** `design/gdd/dark-directive.md`
**Scope:** Full tonal overhaul — gameplay tension systems, narrative, graphics, audio.

## Gameplay

- **Threat Tracker** (`src/ui/threat_tracker.gd`) — diegetic motion-tracker HUD,
  bottom-right. Blips for enemies/mines on-screen and up to 100 px above the
  viewport; periodic pings tighten with proximity. The Silence registers only
  as a flickering ghost blip.
- **The Silence** (`src/gameplay/enemies/the_silence.gd` + scene) — cloaked
  stalker, sectors 3–5 travel phase, one visit per sector. Menace sawtooth:
  stalk (threat ramps) → telegraph (music ducks, CRT roll, shriek) → decloaked
  attack run (vulnerable) → recloak/flee. Balance in `assets/data/dread.json`.
- **Danger Pay** — hull < 25%: all score gains ×1.5 (beacons exempt), heartbeat
  loop, HUD flag. Riding the edge is now a strategy.
- **Graze system** (`enemy_bolt.gd`) — bolts passing within ~6 px grant
  +5×mult score, +1 energy, spark ring. Once per bolt, no rewards in the first
  0.15 s of flight.
- **Streak decay fuse** — kill streak now also decays 6 s after the last kill
  (visible fuse bar under the streak label). Multiplier thresholds pay out
  +10/+20 weapon energy (aggression pays in survivability).
- **Salvage magnetism** — pickup attraction radius scales with streak
  multiplier (40 px base + 14 px per multiplier step).
- **Hitstop** — 40 ms on kills, 90 ms on elite/boss kills, 55 ms on player
  hits. Respects screen_shake=0 opt-out. Screen shake now includes ±0.4°
  rotation. Enemy knockback on laser hits (light classes only).
- **Muzzle flash + spread** — laser gets a 2-frame nose flash and ±1.8° spread.
- **Sector-1 scan teaching pulse** — star A2 now sends one soft asteroid pulse
  so "scanning broadcasts" is learned safely.
- New accessibility setting: **DREAD intensity** (0–1) scales darkness,
  interference, and heartbeat. In both settings menus.

## Graphics

- **CRT shader** rewritten as a true post-process (screen texture); adds
  threat-reactive `interference` (static, line tearing, chroma wobble) and
  event-pulsed `signal_roll` (sync-loss band). Phosphor green-black shadow
  tint. Interference is driven by the aggregate threat level.
- **Darkness veil** (`src/ui/darkness_veil.gd` + shader) — radial visibility
  falloff, sectors 3 (95 px) / 4 (120 px) / 5 (80 px). Boost flares the light
  +20%; scanning tightens it. Enemy and player projectiles render above the
  veil. Mothership arena exempt.
- **Palette** — deeper blue-black void clear color; nebulae desaturated to
  bruise-violet/phosphor-murk/rust; starfield sparser and dimmer; alien glows
  shifted from hot magenta to blood-violet (red reserved for threat).
- **The wrong star** — from sector 2, 40% chance one background star drifts
  against the parallax.
- **Player ship** — weathered steel hull; red emergency cabin glow below 40%
  hull; damage sparks below 25%.
- **Explosions** — lingering embers that cool from orange to deep red on all
  ship kills.

## Narrative

- **Log fragments** (`src/core/log_fragments.gd`) — 9 recovered transmissions
  from the eleven silent probes, served in authored escalation order when
  derelicts are destroyed. Typewriter reveal panel in the HUD. Derelict wrecks
  added to sectors 3–5 encounter tables (9 total across the campaign).
- **Mission Control decay** — prompts rewritten cold and terse ("Contact.
  Weapons free. Crew survival: secondary."); new prompts for the first stalker
  contact and Control going silent in sector 4.
- **Sector transition logs, win screens, death screen** rewritten with
  restraint. Death screen adds rotating final-transmission fragments and a
  personal-best comparison ("BEST: … (94%)" / "NEW RECORD").
- Menu tagline: *ELEVEN PROBES WENT SILENT. YOU ARE THE TWELFTH.*
- Sector 5 scan-complete chime plays a semitone flat.

## Audio (fully regenerated — `scripts/generate_audio_assets.py`)

- **Music**: 13 tracks rebuilt. Exploration = drone beds + tape hiss +
  irregular hull ticks + sparse phrygian motifs (nebula adds whale tones,
  alien territory adds semitone cluster pads). Combat/boss = low toms with
  dropped beats, phrygian sub-bass ostinato, klaxon stabs; boss phases
  escalate to sirens and a heartbeat floor. Discovery/endings = restrained
  warm "dawn" — the only major-key light in the game.
- **New SFX**: tracker_ping, heartbeat, hull_groan, stalker_decloak,
  stalker_drone, graze_spark, derelict_log, alarm_danger.
- **Redesigns**: laser = capacitor snap; impacts gain sub-bass layers; UI
  chimes replaced with dry relay clicks; scan sweep gains tape hiss.
- **Runtime**: SFX pitch randomized ±6%; `AudioManager.duck_music()` drops the
  mix before elite waves and stalker attacks — silence as the alarm.

## Verification

- 98/98 unit tests pass (20 new in `tests/unit/test_dread_systems.gd`).
- `scripts/validate_data.py` passes; export smoke passes (Linux + macOS).
- Live launch: clean boot, no script errors.
