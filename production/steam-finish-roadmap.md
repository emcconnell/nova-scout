# Nova Scout — Steam Finish Roadmap

**Purpose:** Turn the current playable build into a complete, polished Steam release candidate.

**Target outcome:** A tight 35-45 minute retro sci-fi arcade campaign that feels finished, performs reliably, teaches itself, has replay value, and can survive Steam user expectations for controls, settings, polish, stability, and store presentation.

**Primary player promise:** Every sector teaches a new survival skill, every star scan feels like a dangerous discovery, and the final beacon wakes something enormous that the player must defeat to bring humanity home.

---

## Release Strategy

Do not ship just because the loop technically works. Ship when the game has:

1. A complete campaign spine with the Mothership payoff.
2. A compelling first five minutes.
3. A signature star-scanning mechanic, not a passive timer.
4. Meaningful upgrade and scoring decisions.
5. Stable performance at peak enemy/projectile/effect load.
6. Settings, accessibility, controls, save data, and platform exports expected by PC players.
7. Enough polish, audio, tutorialization, juice, and content variety to earn positive Steam reviews.

Recommended positioning: a focused arcade story run, not a long roguelite. The Steam page should sell “retro sci-fi survey shooter with dangerous star scans and a cinematic final boss,” not generic space survival.

---

## Quality Bars

### Fun Bar

- First star-related discovery or objective appears within 90-120 seconds.
- No empty travel stretch lasts longer than 15-20 seconds.
- Each sector introduces or combines at least one new pressure pattern.
- Star scanning requires positioning, survival, and risk/reward decisions.
- Upgrades create noticeable feel changes, not only stat bumps.
- Player can clearly explain after one run why they died and what they would try next.

### Technical Bar

- Game runs at 60 FPS on a modest Steam Deck-class PC during worst-case combat.
- No script over 300 lines remains on the critical gameplay path unless explicitly accepted.
- Gameplay tuning lives in `assets/data/*.json` where practical.
- Save corruption, missing files, and settings defaults are handled safely.
- Headless test/validation command exists and passes.
- Release exports are reproducible for Windows, Linux, and macOS.

### Steam Bar

- Keyboard and gamepad are both tested.
- Windowed/fullscreen/resizable behavior works.
- Settings include audio volumes, screen shake, CRT/scanline, flash intensity, controls/help, and accessibility toggles.
- Store capsule/screenshot needs are planned.
- README/docs match the real build.
- Final build has no known progression blockers, crashers, or softlocks.

---

## Milestones

### M0 — Stabilize the Campaign Spine

**Goal:** The campaign can be completed as designed: three beacons, Mothership climax, true ending.

**Exit criteria:**

- Sector 5 third beacon does not accidentally end the game.
- Mothership is forced or deliberately surfaced after final beacon.
- True ending triggers only after Mothership defeat.
- Standard ending, if retained, is an explicit player choice rather than a bug.
- Regression tests cover the ending flow.
- Current gameplay docs reflect the actual build.

**Primary plan:** `docs/plans/sector-5-mothership-ending-flow.md`

---

### M1 — Make the First Five Minutes Sell the Game

**Goal:** A first-time player understands movement, shooting, pickups, scanning, danger, and the fantasy before they can get bored.

**Exit criteria:**

- Sector 1 has lightweight mission-control prompts.
- First scan/discovery occurs early.
- Opening encounters are authored: move -> shoot -> collect -> scan -> danger.
- Empty-screen downtime is below 20 seconds.
- First star result has a presentation beat.
- Tutorial prompts are dismissible or one-time.

**Primary plan:** `docs/plans/onboarding-polish-accessibility-steam.md`

---

### M2 — Make Star Scanning the Signature Mechanic

**Goal:** Scanning becomes tense, interactive, readable, and replayable.

**Exit criteria:**

- Scan phases can spawn pressure pulses at progress thresholds.
- Damage affects scan stability or progress.
- Optional overcharge rewards risk.
- Stars display vague risk/reward labels without spoiling exact outcomes.
- Result reveal feels cinematic: spectrum/mission-control/planet silhouette.
- Tests or validation cover scan completion, abort, hazards, and rewards.

**Primary plan:** `docs/plans/star-scanning-signature-mechanic.md`

---

### M3 — Data-Drive Tuning and Add Validation

**Goal:** Balance iteration happens through data and can be validated automatically.

**Exit criteria:**

- Add `BalanceDB` or equivalent loader with safe defaults.
- Migrate one domain first, then expand: upgrades -> drops -> weapons/player -> hazards/enemies -> star clusters.
- Data validation catches missing wave files, bad encounter ordering, unknown types, and unimplemented fields.
- `scripts/verify.sh` runs JSON validation and available tests.
- Hardcoded gameplay constants are documented and reduced.

**Primary plan:** `docs/plans/data-driven-balance-validation.md`

---

### M4 — Refactor Hot Paths and Lock Performance

**Goal:** Make future polish safer and keep the game smooth under pressure.

**Exit criteria:**

- `GameWorld.gd` becomes high-level orchestration, not a dumping ground.
- Extract services in this order: `PickupService`, `EnemyFactory`, `TravelSpawner`, `EncounterDispatcher`, `StarfieldRenderer`, `SectorFlowController`.
- Pool enemy bullets, explosions, pickups, score popups, and frequent fragments.
- Worst-case stress test holds target FPS.
- New systems have tests or simple verification scenes/scripts.

**Primary plan:** `docs/plans/gameworld-refactor-performance.md`

---

### M5 — Add Player-Facing Depth and Replayability

**Goal:** Give players reasons to replay and recommend the game.

**Exit criteria:**

- Upgrade branches create recognizable builds: Explorer, Fighter, Survivor.
- At least one rare anomaly tech can appear per run.
- End-of-sector bonuses reward mastery: no damage, fuel efficiency, all stars scanned, fast scans, near misses.
- Combat has stronger hit sparks, shield impacts, missile lock feedback, and near-miss scoring.
- Encounter compositions have authored intent and combine threats.

**Primary docs:**

- `production/steam-ready-backlog.md`
- `docs/plans/star-scanning-signature-mechanic.md`

---

### M6 — Steam Release Candidate

**Goal:** Prepare for public launch, including QA, store, exports, and platform expectations.

**Exit criteria:**

- Windows/Linux/macOS exports produced and smoke-tested.
- Full campaign playthrough tested on keyboard and controller.
- Settings and accessibility verified.
- Save/high-score behavior tested with new, existing, and corrupted saves.
- Store screenshots/capsule/trailer capture checklist complete.
- Known issues list contains no P0/P1 bugs.

**Primary docs:**

- `production/steam-release-qa-checklist.md`
- `production/steam-ready-backlog.md`

---

## Execution Order

1. Implement M0 before any broad refactor.
2. Add tests/validation before making balance changes large enough to hide regressions.
3. Improve scanning and onboarding before adding late-game feature depth.
4. Refactor `GameWorld` after the current behavior is protected.
5. Run Steam QA only after performance and settings are stable.

---

## Definition of Done for Every Task

A task is not done until:

- Code/data/docs are updated.
- Tests or validation are added where practical.
- The game can still run from a clean checkout.
- Relevant design docs match actual behavior.
- Performance impact is considered.
- The change improves the Steam player experience, not just internal architecture.
