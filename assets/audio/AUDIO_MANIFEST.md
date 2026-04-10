# Nova Scout — Audio Asset Manifest

**Status:** 🔴 No assets sourced yet  
**Target Format:** Music → OGG (44.1kHz stereo, -14 LUFS); SFX → WAV or OGG (44.1kHz stereo)  
**Reference style:** Louis and Bebe Barron, Bernard Herrmann, early Moog era (1957–1975 retrofuturist)

---

## Music Tracks (`assets/audio/music/`)

| Filename | Track Name | Duration | Loop | Status | Notes |
|----------|-----------|----------|------|--------|-------|
| `mission_log.ogg` | 01 — Mission Log | 3 min loop | Yes | ⬜ TODO | Main menu. Theremin + sparse chords. Vast, quiet. |
| `inner_rim.ogg` | 02 — Inner Rim | 4 min loop | Yes | ⬜ TODO | Sector 1 travel. Warm, hopeful. 3-note motif debut. |
| `asteroid_fields.ogg` | 03 — Asteroid Fields | 3 min loop | Yes | ⬜ TODO | Sector 2 travel. Rhythmic synth pulse, unstable harmony. |
| `alien_combat.ogg` | 04 — First Contact / Alien Combat | 2 min loop | Yes | ⬜ TODO | Used for all alien combat arenas (sectors 2–5). |
| `nebula_crossing.ogg` | 05 — Nebula Crossing | 3 min loop | Yes | ⬜ TODO | Sector 3 travel. Breathy, eerie, slow. |
| `discovery.ogg` | 06 — Discovery | 15 sec | No | ⬜ TODO | **Critical sting.** Planet reveal. 3-note motif resolves fully. |
| `alien_territory.ogg` | 07 — Alien Territory | 3 min loop | Yes | ⬜ TODO | Sector 4 travel. Heavy drone, ring modulation. |
| `the_frontier.ogg` | 09 — The Frontier | 4 min loop | Yes | ⬜ TODO | Sector 5 travel. Full realization of main theme. |
| `mothership_phase1.ogg` | 10A — Mothership Phase 1 | 2 min loop | Yes | ⬜ TODO | Boss fight phase 1. Full ensemble, high tempo. |
| `mothership_phase2.ogg` | 10B — Mothership Phase 2 | 2 min loop | Yes | ⬜ TODO | Boss fight phase 2. Distorted, chaotic. |
| `mothership_phase3.ogg` | 10C — Mothership Phase 3 | 2 min loop | Yes | ⬜ TODO | Boss fight phase 3. Half-step up, everything wrong-exciting. |
| `golden_shore.ogg` | 11 — Golden Shore | 90 sec | No | ⬜ TODO | True ending / credits. Full orchestral resolution. |
| `returning.ogg` | 12 — Returning | 90 sec | No | ⬜ TODO | Standard ending. Bittersweet. |

**Total music files: 13**

---

## SFX — Player Craft (`assets/audio/sfx/`)

| Filename | Description | Format | Status |
|----------|-------------|--------|--------|
| `laser_fire.wav` | Short bright square-wave beep — *pyew!* | WAV | ⬜ TODO |
| `missile_launch.wav` | Whoosh + ignition crackle | WAV | ⬜ TODO |
| `emp_pulse.wav` | Rising whine then POP | WAV | ⬜ TODO |
| `engine_boost.wav` | Engine hum rises in pitch + volume | WAV | ⬜ TODO |
| `shield_hit.wav` | Metallic ping + brief static crackle | WAV | ⬜ TODO |
| `hull_hit.wav` | Deep thunk + distorted alarm blip | WAV | ⬜ TODO |
| `hull_critical.wav` | Repeating low alarm beep | WAV | ⬜ TODO |
| `craft_explosion.wav` | Layered boom + crackle + debris | WAV | ⬜ TODO |

---

## SFX — Collectibles (`assets/audio/sfx/`)

| Filename | Description | Format | Status |
|----------|-------------|--------|--------|
| `collect_fuel.wav` | Ascending 3-note chime | WAV | ⬜ TODO |
| `collect_repair.wav` | Soft mechanical click + positive tone | WAV | ⬜ TODO |
| `collect_weapon.wav` | Clunk + electronic confirmation | WAV | ⬜ TODO |
| `collect_crystal.wav` | Bright ping | WAV | ⬜ TODO |
| `collect_beacon.wav` | Plays `discovery.ogg` (reuse music sting) | — | ⬜ TODO |

---

## SFX — Asteroids (`assets/audio/sfx/`)

| Filename | Description | Format | Status |
|----------|-------------|--------|--------|
| `asteroid_large.wav` | Deep crack + whoosh | WAV | ⬜ TODO |
| `asteroid_medium.wav` | Medium crack | WAV | ⬜ TODO |
| `asteroid_small.wav` | Short stone-impact crunch | WAV | ⬜ TODO |

---

## SFX — Enemies (`assets/audio/sfx/`)

| Filename | Description | Format | Status |
|----------|-------------|--------|--------|
| `scout_fire.wav` | High warble-beep | WAV | ⬜ TODO |
| `scout_destroy.wav` | Short electronic pop | WAV | ⬜ TODO |
| `warrior_fire.wav` | Triple low-mid beep sequence | WAV | ⬜ TODO |
| `warrior_destroy.wav` | Longer crunch + fragment sounds | WAV | ⬜ TODO |
| `destroyer_attack_a.wav` | Pattern tone A | WAV | ⬜ TODO |
| `destroyer_attack_b.wav` | Pattern tone B | WAV | ⬜ TODO |
| `destroyer_attack_c.wav` | Pattern tone C | WAV | ⬜ TODO |
| `destroyer_attack_d.wav` | Pattern tone D | WAV | ⬜ TODO |
| `destroyer_attack_e.wav` | Pattern tone E | WAV | ⬜ TODO |
| `destroyer_destroy.wav` | Large multi-layer boom | WAV | ⬜ TODO |
| `elite_appear.wav` | 3-note dramatic sting (motif, reversed) | WAV | ⬜ TODO |
| `mothership_phase_change.wav` | Musical threshold cue | WAV | ⬜ TODO |

---

## SFX — UI (`assets/audio/sfx/`)

| Filename | Description | Format | Status |
|----------|-------------|--------|--------|
| `ui_navigate.wav` | Soft click | WAV | ⬜ TODO |
| `ui_confirm.wav` | Clean ascending 2-note beep | WAV | ⬜ TODO |
| `ui_cancel.wav` | Descending beep | WAV | ⬜ TODO |
| `scan_begin.wav` | Rising sweep tone | WAV | ⬜ TODO |
| `scan_complete.wav` | Plays `discovery.ogg` — see music sting | — | ⬜ TODO |
| `scan_abort.wav` | Descending sweep + short alarm | WAV | ⬜ TODO |
| `sector_transition.wav` | Warp whoosh | WAV | ⬜ TODO |
| `upgrade_select.wav` | Positive mechanical confirmation | WAV | ⬜ TODO |
| `typewriter_click.wav` | Subtle soft click per character | WAV | ⬜ TODO |

---

## Summary

| Category | Files | Status |
|----------|-------|--------|
| Music | 13 | 0/13 sourced |
| Player SFX | 8 | 0/8 sourced |
| Collectible SFX | 4 | 0/4 sourced |
| Asteroid SFX | 3 | 0/3 sourced |
| Enemy SFX | 12 | 0/12 sourced |
| UI SFX | 9 | 0/9 sourced |
| **Total** | **49** | **0/49 sourced** |

---

## Sourcing Options

1. **Generate procedurally** — Use [sfxr/jsfxr](https://sfxr.me) for retro SFX (perfect for the 1957 retrofuturist aesthetic)
2. **AI-compose music** — Suno/Udio with style prompts referencing the GDD (Forbidden Planet + Moog analog)
3. **Royalty-free** — Freesound.org filtered to CC0 license; filter by "theremin", "analog synth", "moog"
4. **Commission** — A single composer for all 13 tracks maintains cohesion

### Recommended sfxr.me preset hints
- Laser: `SHOOT` preset → lower wave freq, square wave
- Explosion: `EXPLOSION` → increase sustain
- Pickup: `PICKUP/COIN` → ascending
- Shield hit: `HIT/HURT` → metallic tone
