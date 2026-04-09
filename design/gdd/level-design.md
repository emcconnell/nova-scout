# NOVA SCOUT — Level Design Document

**Version:** 1.0

---

## Structure Overview

Each sector is a **linear scrolling level** ending in a **Star Cluster** where 3–6 stars can be investigated. Sectors are designed as authored experiences, not procedurally generated — each has specific beats, encounter placements, and pacing.

Total estimated play time per sector: 10–15 minutes

---

## SECTOR 1 — Alpha: The Inner Rim

**Theme:** Tutorial. Warm, familiar. The pilot has just left Earth's solar system.  
**Visual:** Deep black with warm blue-white starfield, distant nebula glow on horizon  
**Music:** Slow, curious ambient — theremin + soft synth arpeggios  
**Hazard Level:** ★☆☆  

### Encounter Sequence
1. **[0:00–1:30] Open Space** — Nearly empty. Sparse small asteroids drift past. Teaches movement + laser. A floating Fuel Cell tutorial prompt appears.
2. **[1:30–3:00] First Asteroid Field** — Medium density. 3 large, 6 medium asteroids. Teaches splitting mechanics.
3. **[3:00–4:00] Debris Cloud** — First debris cloud encounter. Slow, unavoidable corridor — teaches the slow/damage effect.
4. **[4:00–5:30] Second Asteroid Field** — Adds mines (2 stationary). Teaches mine avoidance.
5. **[5:30–7:00] Fuel Cache Event** — A drifting supply drone appears. Tutorial prompt: "Shoot it before it escapes!" Guaranteed fuel drop.
6. **[7:00–8:30] Arrival at Star Cluster**

### Star Cluster Alpha
- **Star A-1 (Guaranteed Barren):** Tutorial scan. No hazards during scan. Teaches scan mechanics. "Readings: no viable atmosphere detected."
- **Star A-2 (Barren):** Scan with light asteroid spray. Reward: Data Crystal ×2
- **Star A-3 (Optional, Barren):** Denser asteroid spray. Reward: Repair Kit

**Sector End:** Warp sequence. Mission log: *"Inner Rim cleared. Entering uncharted space. Fuel nominal. Hull intact. Proceeding to Beta sector."*

---

## SECTOR 2 — Beta: The Asteroid Fields

**Theme:** Dense, chaotic. First real danger. First alien sighting.  
**Visual:** Grey-brown asteroid cloud, distant red-dwarf star casting warm light  
**Music:** Tenser, rhythmic percussion enters — still retro but more urgent  
**Hazard Level:** ★★☆  

### Encounter Sequence
1. **[0:00–1:00] Transition Calm** — 10 seconds of empty space, then first wave begins
2. **[1:00–3:00] Dense Asteroid Field** — 5 large, 10 medium, scattered small. No enemies yet.
3. **[3:00–3:30] FIRST ALIEN CONTACT** — A formation of 3 Scouts cross the screen top-to-bottom, don't attack. Tutorial message: *"Unknown signatures detected. Maintain distance."* They continue offscreen — first encounter next.
4. **[3:30–5:00] Scout Attack Wave** — 3 Scouts attack. Teaches combat with enemies that fire back.
5. **[5:00–6:30] Mine Field** — Row of 8 mines in zigzag pattern. Missiles introduced here (tutorial prompt if none used yet).
6. **[6:30–8:00] Asteroid + Scout Combined** — Dense rocks + 4 Scouts simultaneously. Tests multitasking.
7. **[8:00–9:00] Derelict Ship Event** — Optional: shoot open hull for guaranteed Missile Pack + Crystal
8. **[9:00–10:00] Arrival at Star Cluster**

### Star Cluster Beta
- **Star B-1 (Barren):** Scan defended by 2 Scout waves. Teaches scanning under pressure. Reward: Crystal ×2
- **Star B-2 (Alien Territory):** First alien system fight! 2 Waves of Scouts + Elite (Interceptor variant). Teaches alien combat + escape option.
- **Star B-3 (Barren, optional):** Heavy asteroid defense. Reward: Shield Booster
- **Star B-4 (Anomaly, hidden, optional):** Faint flickering star on edge of cluster. Scan reveals derelict alien vessel — loot room: full missile reload + crystal ×3 + narrative beat: *"Alien vessel — crew compartment empty. Strange biomechanical architecture. These are not benevolent explorers."*

**Sector End:** Upgrade screen (first one). Mission log: *"Beta sector traversed. Alien presence confirmed. They are watching. Proceeding to Gamma."*

---

## SECTOR 3 — Gamma: The Nebula Crossing

**Theme:** Atmospheric, mysterious, beautiful, dangerous.  
**Visual:** Dense purple-pink nebula particles, reduced star visibility, occasional bright pulsar flash  
**Music:** Eerie, theremin prominent, slower tempo, sparse — the quiet before  
**Hazard Level:** ★★☆  

### Encounter Sequence
1. **[0:00–2:00] Nebula Entry** — Visibility drops to 60%. Tutorial: sensors detect nearby signatures but can't resolve clearly. Mines appear from fog.
2. **[2:00–4:00] Fog Ambush** — 6 Scouts emerge from nebula clouds (delayed detection — they appear at 60% distance instead of 100%). Teaches new danger of reduced visibility.
3. **[4:00–5:00] Cosmic Storm** — Screen fills with particle static. No enemies — just survive. Teaches patience. Repair Kit drops at the end.
4. **[5:00–6:30] Warrior Introduction** — First Alien Warrior appears. 1v1 with a single Warrior. Space to learn its patterns.
5. **[6:30–8:00] Warrior + Scout Combined** — 2 Warriors + 4 Scouts. First real sweat moment.
6. **[8:00–9:00] Nebula Clearing** — Visibility returns. Brief calm before star cluster.
7. **[9:00–10:30] Arrival at Star Cluster**

### Star Cluster Gamma — FIRST HABITABLE PLANET
- **Star G-1 (Barren):** Light defense. Atmospheric.
- **Star G-2 (HUMAN VIABLE — GUARANTEED):** The first discovery. Scan defended by asteroid spray + 3 Scouts. On completion: full planet reveal animation — warm blue-green marble spinning slowly. Voice log from mission AI: *"Probe Seven — biosignatures confirmed. Recording survey telemetry. Planet designated NOVA PRIMA. Humanity has a future."*  
  **Survey Beacon collected.** +3000 score. Repair Kit reward.
- **Star G-3 (Alien Territory):** 3-wave combat. Introduces Elite Variant B (Artillery).
- **Star G-4 (Barren, optional):** Dense asteroid field. Crystal ×4 reward.

**Sector End:** Emotional moment. Mission log: *"Survey Beacon 1 of 3 secured. Nova Prima data locked. Do not lose this craft. Proceeding to Delta — known alien space."*  
Upgrade screen. Player feeling confident and excited.

---

## SECTOR 4 — Delta: Alien Territory

**Theme:** Hostile, oppressive. The player is in enemy space now.  
**Visual:** Dark purple background, alien constructs visible at distance (non-interactive), alien glyphs on asteroids  
**Music:** Driving, tense — percussion-forward, theremin as alarm-like counter-melody  
**Hazard Level:** ★★★  

### Encounter Sequence
1. **[0:00–1:00] Immediate Hostility** — 4 Scouts attack within first 30 seconds. No easing in.
2. **[1:00–3:00] Destroyer First Encounter** — Single Destroyer with 4-Scout escort. Teaches Destroyer attack patterns. EMP tutorial prompt if player hasn't used one.
3. **[3:00–4:30] Alien Structure Gauntlet** — Non-shootable alien architecture scrolls past while Scouts launch from within it. Creates a frantic navigation challenge.
4. **[4:30–6:00] Dense Engagement** — 3 Warriors + 2 Destroyers + asteroid field. Hardest travel encounter so far.
5. **[6:00–7:00] Breathing Room** — Brief clear zone. Fuel Cache event. Repair Kit reward if hull < 50%.
6. **[7:00–8:30] Final Pre-Cluster Wave** — 3 Destroyers. Tests everything.
7. **[8:30–10:00] Arrival at Star Cluster**

### Star Cluster Delta — SECOND HABITABLE PLANET
- **Star D-1 (Alien Territory):** 4-wave alien fight. Elites in wave 4. Hardest fight yet.
- **Star D-2 (HUMAN VIABLE — GUARANTEED):** Scan defended by Warrior waves (3 waves, increasingly dense). Planet reveal: cold ice world with subsurface oceans. Mission AI: *"Biosignatures confirmed. Recording. Planet designated DEEP BLUE. Survey Beacon 2 secured. One more."*
- **Star D-3 (Alien Territory, optional):** 5-wave fight with Destroyer elite. Reward: full reload + crystal ×6
- **Star D-4 (Anomaly, optional):** Alien distress signal. Scan reveals an alien pod — it's a captured *human* survey probe. Text log: *"Survey Probe Four. Hull compromised. If anyone receives this — they are not hostile by nature. They're afraid. We triggered their border protocols. I'm sorry."* No combat. Emotional beat. Reward: Repair Kit ×2.

**Sector End:** Upgrade screen. Mission log: *"2 of 3 survey beacons secured. Deep Blue telemetry locked. One sector remains. The Frontier. Final coordinates locked."*

---

## SECTOR 5 — Epsilon: The Frontier

**Theme:** Maximum intensity, triumphant, epic. Everything the player has learned is tested.  
**Visual:** Brilliant star field — the Frontier is beautiful, overwhelmingly vivid, almost painfully bright at the edges  
**Music:** Full score — main theme returns, now with driving urgency and orchestral weight (synth orchestra in the retro style)  
**Hazard Level:** ★★★  

### Encounter Sequence
1. **[0:00–2:00] Full Force** — 6 Scouts + 2 Warriors in first 90 seconds. Sets tone.
2. **[2:00–4:00] Destroyer Gauntlet** — 3 Destroyers in sequence. Player must manage missiles and EMP carefully.
3. **[4:00–5:30] Triple-Threat** — Asteroid field + 2 Destroyers + Mine field simultaneously. Hardest travel encounter.
4. **[5:30–6:30] The Calm** — Empty space. Music fades to near-silence. Stars more vivid. This is the eye of the storm.
5. **[6:30–8:00] Elite Ambush** — All three Elite variants appear simultaneously (at reduced HP: 60% each). Designed to be survived with creativity.
6. **[8:00–9:00] Arrival at Star Cluster — MOTHERSHIP VISIBLE**  
   The Mothership is visible at the edge of the cluster. A chill visual moment.

### Star Cluster Epsilon — FINAL HABITABLE PLANET + MOTHERSHIP BOSS
- **Star E-1 (Alien Territory):** 4-wave fight with all enemy types. Warms up the player.
- **Star E-2 (Barren):** Scan with dense mixed hazards. Full Repair Kit + Missile ×4 reward. Intentionally generous — stocking up the player.
- **Star E-3 (HUMAN VIABLE — GUARANTEED):** The most defended scan in the game. 4 brutal waves during scan — Warriors, Destroyers, an Elite. But the scan only needs to complete, not with a specific score.  
  Planet reveal: Lush green and gold world, rings visible. Mission AI voice breaks: *"...Probe Seven. I have confirmed biosignature Class-A. Designation: GOLDEN SHORE. I'm— this is remarkable. Survey Beacon 3 secured. Come home."*  
  **WIN CONDITION TRIGGERED — must now escape.**
- **Star E-4 (MOTHERSHIP — mandatory encounter after E-3):** After collecting third beacon, the Mothership drops out of warp to block the escape route. This is the final boss.  
  **Context:** The player *doesn't have to fight it* — if they can survive 90 seconds without taking more than 40 HP of hull damage, an emergency warp option unlocks. But defeating it gives the **true ending**.

**True Ending (defeat Mothership):**  
Warp sequence. Earth visible ahead. Credits roll over the craft entering Earth orbit. Mission AI: *"Survey Probe Seven returning. Three habitable worlds confirmed. Golden Shore, Deep Blue, Nova Prima. The colony fleet launches in eight days. You did it. Rest now."*

**Standard Ending (escape):**  
Warp sequence. Earth visible. Briefer credits. Mission AI: *"Probe Seven returning with beacon data. The mission is complete. They'll have questions about the Mothership. But you're alive. That counts for everything."*
