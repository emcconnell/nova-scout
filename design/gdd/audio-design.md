# NOVA SCOUT — Audio Design Document

**Version:** 1.0

---

## Audio Identity

The soundscape of NOVA SCOUT exists in a specific moment in the history of science fiction: **the sound of the future as imagined in 1957**. This is the era of the theremin, the analog synthesizer, the Moog's earliest commercial recordings. Electronic music was new, strange, and inexorably linked in the cultural imagination with outer space, alien minds, and the unknown.

We are not imitating this with nostalgia — we are *continuing* it. NOVA SCOUT's audio should sound like it could have been composed for *Forbidden Planet* (1956, the first all-electronic film score) if the composer had a slightly more advanced synthesizer.

**Reference Composers:**
- Louis and Bebe Barron (*Forbidden Planet*, 1956)
- Bernard Herrmann (*The Day the Earth Stood Still*, 1951)
- Dick Hyman (early Moog recordings)
- Tangerine Dream (ambient texture)
- Atari sound designers circa 1979–1983 (SFX discipline)

---

## Music

### Instrument Palette
| Instrument | Role |
|------------|------|
| **Theremin** (real or simulated) | Lead melody on ambient tracks; eerie tension in alien sections |
| **Moog-style synthesizer** | Bass lines, chord pads, rhythmic elements |
| **Analog percussion** (drum machine) | Drive in combat tracks; very sparse in ambient |
| **Sine wave oscillators** | Background drones, tonal ambience |
| **Ring modulator effects** | Alien sections — the sound of the Other |
| **Reverb-heavy acoustic sounds** | Occasional human moment — a voice, a breath |

### Track List

#### 01 — MISSION LOG (Main Menu)
Slow, curious, vast-feeling. A single theremin line over sparse synth chords. Communicates scale, wonder, and the weight of the mission. Very quiet. 3-minute loop.

#### 02 — INNER RIM (Sector 1)
Gentle exploration theme. Warm. Hopeful. The debut of a simple three-note motif that will recur throughout the game. Slight Baroque feel — an organized, rational universe. Light analog percussion at medium tempo. 4-minute loop.

#### 03 — ASTEROID FIELDS (Sector 2 — Travel)
Tension enters. The three-note motif is now harmonically unstable — off-key variations. Rhythmic synth pulse drives the tempo. Not quite threatening yet — more vigilant.

#### 04 — FIRST CONTACT (Sector 2 — Alien Combat)
First combat theme. Staccato analog bass hits. Theremin plays chaotic runs between hits. Unsettling rhythms. The enemy is unknown. The sound should feel like a warning.

#### 05 — NEBULA CROSSING (Sector 3 — Travel)
The quietest travel track. The three-note motif on a very slow, breathy synth — almost obscured. The percussion drops to soft, unpredictable taps. Spacious. Eerie. Beautiful.

#### 06 — DISCOVERY (Star — Human Viable)
A 15-second non-looping sting. The three-note motif finally resolves — full, warm, harmonically complete, with a subtle string-like synth swelling underneath. This is the emotional payoff of the game. Should give the player chills. Plays during planet reveal animation.

#### 07 — ALIEN TERRITORY (Sector 4 — Travel)
Heavy. Oppressive. Ring-modulated bass drone under a driving percussion pattern. The theremin is gone — replaced by processed alien-sounding oscillators. The player is in enemy space.

#### 08 — ALIEN COMBAT (Sectors 3–5)
Full combat track. Driving, relentless. Synth arpeggios at high speed over thunderous analog drums. Ring modulator SFX punctuate between phrases. 2-minute loop.

#### 09 — THE FRONTIER (Sector 5 — Travel)
The main theme fully realized. All elements from previous tracks combined: theremin melody (now triumphant), full analog orchestra, driving percussion. Grand but not safe.

#### 10 — MOTHERSHIP BATTLE (Boss Fight)
Three-phase adaptive track:
- **Phase 1:** Building, urgent — full ensemble at high tempo
- **Phase 2:** Melody becomes chaotic — theremin distorted, percussion erratic
- **Phase 3:** Back to clarity but raised a half-step — everything is slightly wrong, wrong in an exciting way
- **Desperation (10% HP):** All music drops to a heartbeat-like pulse, then silence — then a single hit of orchestra on the killing blow

#### 11 — GOLDEN SHORE (True Ending)
The three-note motif, now in full orchestral resolution. Builds over 90 seconds. Credits roll. Ends on a single held note that fades into silence.

#### 12 — RETURNING (Standard Ending)
The motif, quieter, more bittersweet. Still resolved, but more reflective.

---

## Sound Effects

### Player Craft
| Event | Sound Description |
|-------|------------------|
| Laser fire | Short, bright square-wave beep — *pyew!* Clean and satisfying |
| Missile launch | Lower-pitched whoosh + ignition crackle |
| EMP pulse | Rising whine then POP — silence for 0.3s then all sounds return |
| Engine idle | Very soft continuous hum — low frequency, barely audible |
| Engine boost | Hum increases in pitch and volume |
| Shield hit | Metallic ping + brief static crackle |
| Hull hit | Deeper thunk + distorted alarm blip |
| Hull critical | Repeating low alarm beep (every 2 seconds while below 30%) |
| Craft explosion | Layered: initial boom + crackle + receding debris hits over 1 sec |

### Collectibles
| Event | Sound |
|-------|-------|
| Fuel Cell collect | Ascending 3-note chime |
| Repair Kit collect | Soft mechanical click + positive tone |
| Missile/EMP collect | Clunk + electronic confirmation |
| Crystal collect | Bright ping (pitched higher with score multiplier) |
| Survey Beacon collect | The full Discovery sting (15 sec) |

### Asteroids
| Event | Sound |
|-------|-------|
| Large split | Deep crack + whoosh of pieces |
| Medium split | Medium crack |
| Small destroy | Short stone-impact crunch |

### Enemies
| Event | Sound |
|-------|-------|
| Scout fire | High warble-beep |
| Scout destroy | Short electronic pop |
| Warrior fire burst | Triple low-mid beep sequence |
| Warrior destroy | Longer electronic crunch + fragment sounds |
| Destroyer attack pattern start | Distinct tone per pattern (5 unique tones) |
| Destroyer destroy | Large explosion — multi-layer boom |
| Elite appear | Short dramatic sting (3 notes — variant of main motif, reversed) |
| Mothership phases | Distinct musical cue at each threshold |

### UI
| Event | Sound |
|-------|-------|
| Menu navigate | Soft click |
| Menu confirm | Clean ascending 2-note beep |
| Menu cancel | Descending beep |
| Scan begin | Rising sweep tone |
| Scan complete | Discovery sting |
| Scan abort | Descending sweep + short alarm |
| Sector transition | Warp whoosh |
| Upgrade select | Positive mechanical confirmation |
| Mission log text | Subtle soft typewriter click per character |

---

## Audio Implementation Notes (Godot 4)

- Use **AudioStreamPlayer2D** for positional SFX (enemies, projectiles, asteroids)
- Use **AudioStreamPlayer** (non-positional) for UI, player craft SFX, and music
- Implement **AudioBus** mixer:
  - Master bus
  - Music bus (volume control, low-pass filter for pause)
  - SFX bus  
  - UI bus
- **Music transitions:** Use `AudioStreamInteractive` or tween volume between tracks
- **Adaptive music (Mothership):** Implement phase transitions by crossfading between track layers (all phases pre-mixed as individual streams, crossfaded by HP threshold)
- All SFX: **OGG format** for streaming; short one-shot sounds can use **WAV**
- Music: **OGG** with loop points set in metadata
- Target audio specs: 44.1kHz, stereo, normalized to -14 LUFS integrated

---

## Audio Budget

| Category | Estimated Files | Notes |
|----------|----------------|-------|
| Music tracks | 12 | Some adaptive (multiple layers) |
| Player SFX | 15 | All short, punchy |
| Enemy SFX | 20 | Per tier, per action |
| Environment SFX | 10 | Asteroids, debris, mines |
| UI SFX | 12 | Menu, HUD, transitions |
| **Total** | **~69 audio files** | |
