# NOVA SCOUT — The Dark Directive (v2.0 Creative Direction)

**Status:** Binding creative direction for the v2.0 "ELEVEN SILENT" overhaul
**Owner:** Creative direction pass, 2026-07-06
**Supersedes tone guidance in:** game-concept.md §Tone, art-bible.md palette accents

---

## 1. Overview

Nova Scout keeps its retro-arcade skeleton — 320×180 phosphor pixel art, one
pilot, five sectors, scan-and-survive loop — and trades its 1950s Technicolor
wonder for 1970s truckers-in-space dread. The reference feeling is *Alien*
(1979): isolation, the unseen threat, working-class realism, restraint. Not a
horror game — an **arcade shooter that is afraid of the dark**. Combat stays
fast, loud, and juicy; everything between combat gets quieter, darker, and
wrong.

The player fantasy shifts from *"I am the last explorer"* to:

> "Eleven probes went out before me. I am flying through what's left of them."

---

## 2. Design Pillars (binding)

1. **THE VOID IS HOSTILE.** Information is the scarcest resource. Threats
   announce themselves through the tracker, the audio, and the static — not
   through polite on-screen spawns. Darkness is a mechanic, not a filter.
2. **EVERY SIGNAL COSTS.** Scanning — the win condition — is the moment of
   maximum vulnerability. Broadcasting attracts. The scan is the heartbeat of
   the game's tension: locked in orbit, watching the tracker fill with dots.
3. **JUICE THE KILL.** Dread only works against contrast. Combat feedback is
   maximal: hitstop, shake, flash, debris, bass. Fear in the quiet, power in
   the loud. (Vlambeer rules apply between encounters' silences.)
4. **ELEVEN CAME BEFORE.** The story is told through the wrecks of Probes
   1–11. Derelicts are graves; logs are found, not narrated. Restraint:
   the worst things are described, never shown.
5. **A HINT OF RETRO, NOT A COSTUME.** Phosphor-green CRT, scanlines, analog
   interference. The Nostromo school: technology old enough to trust and too
   old to save you.

---

## 3. Player Fantasy

Working pilot, not hero. Tired hands on old hardware. The HUD is the ship
talking to you; when the ship is dying the HUD dies with it. Every habitable
world found is a genuine dawn — brighter *because* the void around it got
darker. The endings stay earned and human.

---

## 4. Detailed Rules — What Changes

### 4.1 Gameplay (tension systems)

| System | Rule |
|---|---|
| **Threat Tracker** | Bottom-right HUD: circular sweep radar. Enemies/hazards above the visible screen appear as phosphor blips ~2.5 s before entering. Diegetic ping SFX, pitch rises with proximity and count. In nebula sectors the tracker is the *only* early warning. |
| **The Silence (stalker)** | New enemy, sectors 3–5 travel phase. Near-invisible (2–8 % shimmer alpha); telegraphed only by tracker pings, CRT interference ramp, and a bass drone. Decloaks for a strafing attack run, then recloaks and flees. Killable during its attack window for big score. Spawn cadence data-driven. It teaches players to fear the ping. |
| **Hull-critical: DANGER PAY** | Below 25 % hull: heartbeat loop, deep vignette, HUD flicker — and **+50 % score on all gains**. Risk/reward: limping to the repair kit versus riding the edge. |
| **Graze bonus** | Enemy bolt passing within 6 px without hitting: +5 score × multiplier, +1 energy, tiny spark. Near-miss psychology; rewards flying *into* the bullet stream. |
| **Streak decay** | Kill streak now also decays after 6 s without a kill (visible fuse on HUD). Breaking on hull damage stays. Creates aggression pressure, not just caution. |
| **Scan pressure presentation** | While scanning: screen iris-darkens ~20 %, tracker ping rate ramps with scan progress, music ducks to drone + heartbeat. All sectors get at least one scan pulse (sector 1 keeps a trivial one as the teaching moment). |
| **Salvage magnetism** | Pickup attraction radius scales with streak multiplier (×1 → 12 px, ×3 → 34 px). Rewards sustained aggression with convenience. |

### 4.2 Graphics

- **Palette shift:** background near-black `#04050A`; nebulae desaturated and
  sickly (teal-grey, rust, bruise-violet); alien accents blood-red `#C41E1E`
  over violet; UI phosphor green retained but dimmed 15 %; amber for warnings.
- **Darkness system:** sector 3+ travel/cluster phases get a visibility
  falloff (radial light around the player + engine glow; enemies emerge from
  murk). Sector 3 heavy, 4 moderate + red emergency tint, 5 near-black with
  the Mothership as a light source.
- **CRT interference as fear:** overlay gains `interference` and `signal_roll`
  uniforms — static ramps when the Silence is near, on hull-critical, and
  during scan climaxes; a horizontal roll flickers on major events.
- **Kill feedback:** hitstop (40 ms on kill, 90 ms on elite kill), muzzle
  flash frames, ember/afterglow particles that linger, heavier shake curve.
- **The wrong star:** rarely, one background star drifts against the parallax.
  It's nothing. Probably.

### 4.3 Audio (full regeneration — procedural pipeline)

- **Music:** all 13 tracks regenerated darker. Travel = low drones, sparse
  Lydian-minor pings, long silences. Combat = driving low toms, klaxon stabs,
  phrygian ostinato. Boss = three-phase escalation to near-noise. Victory
  stays warm — the one dawn — but restrained, weary.
- **New SFX:** `tracker_ping` (3 proximity tiers), `heartbeat`, `hull_groan`
  (random ambient below 40 % hull), `stalker_decloak` shriek, `stalker_drone`,
  `interference_burst`, `graze_spark`, `danger_pay_on`, log `typewriter`
  variants, `derelict_log` radio-degraded voice bed.
- **Silence as a weapon:** music ducks to near-silence for 4–6 s before elite
  waves and the star-cluster arrival. The absence is the alarm.
- **Redesigned core SFX:** lasers thinner/sharper (less "pew", more capacitor
  snap), impacts heavier (sub-thump layer), explosions longer decay with
  debris tail, UI clicks drier (relay clicks, not chimes).

### 4.4 Story

- **Frame:** the 11 silent probes become the spine. Derelict ships are
  identified as specific probes; destroying/salvaging one recovers a **log
  fragment** (typewriter reveal, degraded text). 8 fragments, escalating from
  mundane to wrong: Probe 3's cheerful sign-off → Probe 9's "it follows
  between stars" → Probe 11's fragment is mostly static.
- **Mission Control decays:** prompts start procedural and clipped; from
  sector 3 the log notes Control's replies lag, then stop. The tutorial voice
  quietly becomes the ship's own systems talking.
- **Sector transition logs** rewritten darker (restraint, no melodrama).
- **Endings:** true ending stays a dawn, written wearier; standard ending
  more ambivalent. Death screen gains rotating final-transmission fragments.

---

## 5. Formulas

- `danger_pay_multiplier = 1.5` applied in `GameManager.add_score` while
  `player_hull / player_max_hull < 0.25` (stacks multiplicatively with streak).
- `graze_score = 5 × streak_multiplier`, `graze_energy = +1.0`, per bolt,
  one graze per bolt lifetime.
- `streak_decay_time = 6.0 s` since last kill → reset to 0 (existing
  hull-damage reset retained).
- `magnet_radius = 40 + (streak_multiplier - 1) × 14` px.
- `tracker_lead_time ≈ spawn_y_offset / scroll_speed`; blips render for
  anything queued within 100 px above the viewport.
- Stalker: HP 45, decloak attack every 7–10 s, attack window 2.2 s,
  score 600, flees after 2 attack cycles.
- Darkness radii (visibility falloff): sector 3 = 95 px, sector 4 = 120 px,
  sector 5 = 80 px (Mothership arena exempt — boss lights the field).

## 6. Edge Cases

- Danger pay must not reward self-damage cheese: multiplier applies to score
  *gains* only; no interaction with beacon 3000 base (beacons excluded).
- Graze checks skip bolts spawned < 0.15 s ago (no free graze at muzzle).
- Stalker never spawns during scanning in sector 3 (scan pulses own that
  slot) and never more than one concurrent.
- Darkness never fully hides enemy projectiles: bolts carry their own glow
  and are exempt from the falloff.
- Accessibility: darkness intensity, interference, heartbeat, and hitstop all
  scale with existing `flash_intensity` / new `dread_intensity` setting;
  tracker has a high-contrast mode via existing `color_friendly`.

## 7. Dependencies

- HUD (tracker, streak fuse, danger pay indicator) — `src/ui/hud.gd`
- CRT overlay (interference uniforms) — `src/ui/crt_overlay.gd`, shader
- GameManager (danger pay, streak decay) — `src/core/game_manager.gd`
- GameWorld (darkness draw pass, hitstop, stalker spawns, wrong star)
- New: `src/gameplay/enemies/the_silence.gd`, `src/ui/threat_tracker.gd`,
  `src/core/log_fragments.gd`
- Audio pipeline — `scripts/generate_audio_assets.py`
- Balance data — `assets/data/dread.json` (new), encounters JSONs

## 8. Acceptance Criteria

1. Tracker blips appear ≥ 2 s before any travel-phase spawn enters view;
   ping SFX audible and pitch-tiered.
2. The Silence triggers CRT interference ramp before decloak, 100 % of spawns.
3. Hull < 25 % → heartbeat audible, vignette deepens, score gains ×1.5
   (verified by unit test).
4. Graze grants score+energy exactly once per bolt (unit test).
5. Streak resets 6 s after last kill (unit test).
6. Sectors 3–5 render visibility falloff; projectiles remain visible.
7. All 13 music tracks + ≥ 60 SFX regenerate deterministically from the
   script; game boots with zero missing-resource errors.
8. Every derelict destroyed yields a unique probe log fragment until the
   pool is exhausted; fragments display with typewriter reveal.
9. All existing unit tests still pass; new systems covered by new tests.
10. A full run (menu → sector 5 → both endings) completes without errors.
