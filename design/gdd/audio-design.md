# NOVA SCOUT — Audio Design Document

**Version:** 2.0 (Dark Directive)
**Supersedes:** v1.0 "sound of the future as imagined in 1957" direction
**Binding creative source:** `design/gdd/dark-directive.md` §4.3 — implementation record in `production/dark-directive-changelog.md`
**Pipeline:** all assets generated deterministically by `scripts/generate_audio_assets.py`

---

## 1. Overview

NOVA SCOUT's v2.0 soundscape is the sound of old hardware in a hostile void: **1970s truckers-in-space, not 1950s theremin wonder**. The reference feeling is *Alien* (1979) — drones, tape hiss, irregular mechanical ticks, and long silences between events. The score is built on low drone beds and **phrygian/minor** motifs instead of v1.0's warm three-note Baroque motif; combat runs on low toms with dropped beats, phrygian sub-bass ostinati, and klaxon stabs. SFX moved from toy-bright square-wave beeps to dry hardware: the laser is a capacitor snap, impacts carry sub-bass layers, and UI chimes are replaced with relay clicks. Silence itself is a designed weapon — the mix ducks to near-nothing before elite waves and stalker attacks. The only unreserved warmth left in the game is the Discovery/ending "dawn" material, and even that is played weary.

**Reference points:** Jerry Goldsmith (*Alien*, 1979 — restraint, wrongness), the Nostromo's ambient hum, analog drone/tape-music practice, Atari-era SFX discipline retained for combat readability.

## 2. Player Fantasy

The ship is talking to you, and it is old. Every sound the player hears is diegetic-leaning: relay clicks when menus actuate, tape hiss under the scan sweep, hull groans when the ship is hurting, a heartbeat when the pilot is. Threats are heard before they are seen — the tracker ping tightening, a bass drone that means *it* is near, the music dropping out entirely. Combat is the loud, cathartic exception: heavy impacts, long explosion tails, bass. When the Discovery sting finally lands warm and major, it should feel like the first sunrise in an hour of night.

### Audio Pillars (binding)

1. **The void is quiet and that is bad.** Travel music is drones and silences. Absence of sound is the alarm.
2. **Every signal costs.** Scanning ducks the music to drone + heartbeat and ramps the tracker ping — the audio makes broadcasting feel dangerous.
3. **Juice the kill.** Combat SFX are maximal: sub-bass impacts, debris tails, klaxons. Fear in the quiet, power in the loud.
4. **Old hardware.** Relay clicks, tape hiss, degraded radio voices, typewriter text. Nothing sounds new.
5. **One dawn.** Discovery and the endings are the only major-key warmth. Guard it.

## 3. Detailed Rules

### 3.1 Music System

All 13 tracks are generated from three procedural builders (`scripts/generate_audio_assets.py`):

- **`track_dark_ambient`** — travel/menu beds: low drone bed with slow movement, tape hiss, irregular hull ticks, sparse minor/phrygian motifs. Options: whale tones (nebula), semitone cluster pads (alien territory).
- **`track_combat`** — combat/boss: low toms with dropped beats, phrygian sub-bass ostinato, klaxon stabs; a `phase` parameter escalates density, tempo, and noise content.
- **`track_dawn`** — discovery/endings: restrained warm major material; a `weary` flag keeps the endings tired rather than triumphant.

**Track list (13):**

| Track | Builder | Character |
|---|---|---|
| `mission_log` (menu) | dark_ambient, root A0 | Vast, near-empty drone. The mission has already gone wrong eleven times. |
| `inner_rim` (S1 travel) | dark_ambient + minor motif | The last safe light; a motif still audible. |
| `asteroid_fields` (S2 travel) | dark_ambient, heavier ticks | Mechanical unease. |
| `nebula_crossing` (S3 travel) | dark_ambient + whale tones | The quietest track; something large and distant. |
| `alien_territory` (S4 travel) | dark_ambient + cluster pads | Semitone clusters — the Other's harmony. |
| `the_frontier` (S5 travel) | combat builder at 84 BPM, phase 0 | Travel that already sounds like combat. |
| `alien_combat` (S3–5 combat) | combat, 132 BPM, phase 1 | Driving toms, phrygian ostinato, klaxons. |
| `mothership_phase1/2/3` | combat, 120/140/156 BPM, phases 1–3 | Three-stage escalation to near-noise: sirens and a heartbeat floor by phase 3. |
| `discovery` (habitable-world sting) | dawn, `weary=False`, 15 s | The one full warmth. Plays on planet reveal. |
| `golden_shore` (true ending) | dawn, weary | Earned, human, tired. |
| `returning` (standard ending) | dawn, weary, quieter | Ambivalent resolution. |

**Silence as a weapon:** `AudioManager.duck_music()` drops the mix to near-silence for 4–6 s before elite waves and stalker attack runs, and to drone + heartbeat during scanning. The drop *is* the telegraph.

**Continuous travel rotation:** `AudioManager.play_sector_music()` starts on the sector's theme, restarts the bed if it ends, and crossfades through the sector themes every 120 s during long travel/scan stretches. Menu, combat, boss, win, and death cues disable rotation so set-pieces stay clean.

### 3.2 Sound Effects

**Dread layer (new in v2.0):**

| SFX | Design |
|---|---|
| `tracker_ping` | Band-passed sonar blip with a 0.18 s echo tap. Interval tightens with proximity (1.4 s far → 0.45 s near); in nebula sectors it is the only early warning. |
| `heartbeat` | Two-beat thump loop below 25% hull; interval 1.1 s calm → 0.62 s panic. |
| `hull_groan` | Low detuned saw + filtered noise swell; random ambient below 40% hull. |
| `stalker_drone` | Beating detuned sines (~38 Hz pair) — The Silence is near. |
| `stalker_decloak` | Rising two-layer shriek + sub impact — the attack-run telegraph, synced with the CRT signal_roll. |
| `graze_spark` | 50 ms high-band noise tick + sine ping; near-miss reward. |
| `derelict_log` | Radio-degraded voice bed (vibrato carrier + gated static) under log-fragment reveals. |
| `alarm_danger` | Two-tone klaxon; Danger Pay activation. |
| `typewriter_click` | 30 ms band-passed noise per character on log text. |

**Redesigned core SFX (v1.0 → v2.0):**

- **Laser:** capacitor snap, not "pew" — fast 1750→420 Hz sweep plus high-band noise transient, thin and sharp.
- **Impacts/explosions:** all gain a sub-bass layer; explosions have longer decays with debris/noise tails (`craft_explosion` 1.5 s, `destroyer_destroy` 1.1 s).
- **UI:** every chime replaced with **dry relay clicks** (`ui_navigate`/`ui_confirm`/`ui_cancel` at descending click pitches); pickups keep two-note confirmations but dark-voiced and paired with relay clicks.
- **Scan:** `scan_begin` rising sweep gains tape hiss; `scan_complete` stays a bright major chime (`dark=False`) — scanning's payoff is one of the rationed warm sounds. Sector 5's scan-complete plays a semitone flat (narrative wrongness).
- **Enemies:** fire/destroy sounds rebuilt on the impact/sweep toolkit with ring-mod character; 5 distinct destroyer attack tones, elite appear/blink stings, mothership phase-change klaxon + sub hit, `desperation_charge` riser.
- **Beacon/discovery:** `beacon_collected` is a five-note bright chime (`dark=False`) — the other rationed warmth.

Full inventory (≈60 SFX + aliases like `emp_fire`, `enemy_laser`, `scan_start`, `pickup_collect`) is defined in `make_sfx()` in the generator script — that function is the canonical list.

### 3.3 Runtime Behavior

- SFX playback pitch is randomized **±6%** to kill machine-gun repetition.
- `duck_music()` handles pre-elite and stalker silences; scan ducking layers heartbeat as scan progress climbs.
- Hull-state loops: heartbeat starts/stops at the 25% threshold; hull groans roll randomly below 40%.
- Tracker ping pitch rises with proximity **and** contact count.

### 3.4 Implementation (Godot 4)

Unchanged from v1.0 where still true:

- `AudioStreamPlayer2D` for positional SFX; `AudioStreamPlayer` for UI, player SFX, music.
- Bus layout: Master → Music (low-pass on pause), SFX, UI.
- Mothership adaptive music via crossfade between the three pre-mixed phase tracks at HP thresholds.
- Formats: WAV one-shots, 44.1 kHz stereo, normalized ≈ −14 LUFS integrated.
- After regenerating WAVs run `godot --headless --path . --import --quit` so Godot refreshes `.godot/imported/*.sample` caches before playtesting or export.

## 4. Formulas

- `ping_interval = lerp(1.4 s, 0.45 s, proximity)` — tracker ping cadence (`dread.json → tracker`).
- `heartbeat_interval = lerp(1.1 s, 0.62 s, panic)` below 25% hull (`dread.json → heartbeat`).
- `sfx_pitch = base × (1 ± 0.06 × rand)` — runtime pitch randomization.
- `duck_duration = 4–6 s` pre-elite/stalker; music volume ducks to near-silence, restored on engagement.
- Music determinism: fixed-seed RNG in the generator — identical WAV output on every run (acceptance-testable).
- Track roots/tempi: see `make_music()` spec table (e.g. `alien_combat` root C1, 132 BPM; `mothership_phase3` root G0, 156 BPM).

## 5. Edge Cases

- **Silence vs. dead audio:** designed silences (pre-elite duck) must never coincide with the tracker going quiet — pings continue through music ducks so silence reads as *intent*, not a bug.
- **Overlapping ducks:** stalker attack during a scan → the deeper duck wins; restore to the scan-duck level, not full mix, while scanning continues.
- **Heartbeat + hull-critical alarm:** both trigger at 25%; heartbeat is the loop, `hull_critical` klaxon fires once on crossing the threshold — they must not stack per-frame.
- **Accessibility:** heartbeat and interference-linked audio scale with `dread_intensity`; all ducking respects user music/SFX volume settings (duck is relative, not absolute).
- **Missing-resource safety:** every runtime-referenced event name has a generated WAV or alias (`emp_fire`, `enemy_laser`, `missile_explode`, `scan_start`, `pickup_collect`, `wave_clear`, `asteroid_break`, `mine_armed`, `mine_explode`, `beacon_collected`, `elite_blink`) — game must boot with zero missing-resource errors.
- **Warm-sound rationing:** only `discovery`, `beacon_collected`, `scan_complete`, and the ending tracks may be major/bright. Any new SFX defaults to the dark voicing (`dark=True` chimes, relay clicks).

## 6. Dependencies

- `design/gdd/dark-directive.md` §4.3 — binding direction (drone/phrygian system, silence-as-weapon, SFX redesign)
- `scripts/generate_audio_assets.py` — canonical asset pipeline (music builders + `make_sfx()`)
- `src/core/audio_manager.gd` — buses, `duck_music()`, sector rotation, pitch randomization
- `assets/data/dread.json` — tracker ping and heartbeat intervals, hull thresholds
- `src/ui/threat_tracker.gd` — ping triggering; `src/gameplay/enemies/the_silence.gd` — drone/decloak cues
- `src/core/log_fragments.gd` — typewriter and derelict-log playback
- `design/gdd/art-bible.md` — audiovisual sync (decloak shriek ↔ CRT signal_roll; heartbeat ↔ vignette)

## 7. Tuning Knobs

| Knob | Default | Location |
|---|---|---|
| `tracker.ping_interval_far / near` | 1.4 s / 0.45 s | dread.json |
| `heartbeat.interval_calm / panic` | 1.1 s / 0.62 s | dread.json |
| `heartbeat.hull_threshold` | 0.25 | dread.json |
| Pre-elite/stalker duck length | 4–6 s | audio_manager.gd |
| SFX pitch randomization | ±6% | audio_manager.gd |
| Sector-music crossfade period | 120 s | audio_manager.gd |
| Track roots/tempi/durations | per-track | `make_music()` specs |
| Drone bed amp/movement, motif density, tick density | per-builder defaults | generator functions (`drone_bed`, `sparse_motif`, `irregular_ticks`) |
| Normalization peak | 0.80 music / ≈0.8–0.9 SFX | `write_wav` / `save_sfx` calls |

## 8. Acceptance Criteria

1. All 13 music tracks and ≥60 SFX regenerate deterministically from `scripts/generate_audio_assets.py`; two consecutive runs produce identical files.
2. Game boots with zero missing-resource audio errors; every runtime event name resolves to a WAV or alias.
3. Tracker ping is audible whenever a blip is on the tracker and its interval tightens from 1.4 s to 0.45 s with proximity.
4. Hull < 25% → heartbeat loop starts within one interval and stops on repair above threshold; interval tightens as hull drops.
5. Every Silence attack run is preceded by drone + shriek telegraph synced with the CRT interference ramp (100% of spawns).
6. Music ducks to near-silence 4–6 s before elite waves and stalker attacks, and to drone + heartbeat during scans; pings persist through ducks.
7. All UI navigation sounds are relay clicks (no v1.0 chimes remain in menus); laser reads as a sharp snap, not a "pew".
8. `discovery`, ending tracks, `scan_complete`, and `beacon_collected` are the only major/bright audio in the game; sector 5's scan-complete plays a semitone flat.
9. Loudness: tracks normalize ≈ −14 LUFS; no SFX clips at 0 dBFS in export builds.
10. Manual listening QA pass (headphones + speakers, exported build) signed off for fatigue, balance, and duck timing before release.
