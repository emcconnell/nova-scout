# Nova Scout — App Research and Game Improvement Report

Generated from code/design review of `/Volumes/RepoDrive/Code/star-finder/nova-scout`.

## 1. Executive Summary

Nova Scout is a Godot 4 retrofuturist top-down arcade shooter about Survey Probe Seven searching five sectors for human-habitable worlds. The current build already has a strong foundation: readable direct-control movement, a complete sector loop, star scanning, scripted encounter data, multiple enemy families, pickups, upgrades, audio management, save/high-score support, GUT tests, and a cohesive 1950s-70s sci-fi visual direction.

The biggest opportunity is not adding random features; it is sharpening the game into a tighter, more dramatic arcade campaign. The project currently has many good systems, but several are either too implicit, too hardcoded, or disconnected from the player's minute-to-minute experience. The game will get much better if it prioritizes:

1. Fixing progression/ending logic so the final sector and Mothership payoff work exactly as promised.
2. Making the first five minutes instantly sell the fantasy: scan, discover, fight, choose, upgrade.
3. Turning star scanning from a passive wait into the signature risk/reward mechanic.
4. Increasing encounter variety through authored combinations, better telegraphs, and stronger sector identity.
5. Making progression choices more meaningful and visible.
6. Moving core tuning out of hardcoded script constants into data tables.
7. Adding accessibility, settings, onboarding, and automated regression coverage.

If I had to pick one product direction: make Nova Scout feel like a complete 35-45 minute arcade story run with excellent pacing, juicy combat feedback, and a memorable final boss, rather than stretching the same loop to hit an arbitrary one-hour target.

## 2. What the App Is

### Pitch

Nova Scout is a top-down arcade space shooter with exploration mechanics. The player pilots Survey Probe Seven, travels through five sectors, survives hazards and alien attacks, scans star clusters, collects three Survey Beacons from habitable worlds, and tries to save humanity.

### Core Loop

The implemented loop matches the GDD at a high level:

```text
Travel through sector
  -> scripted encounters and ambient hazards
  -> reach star cluster
  -> scan stars
  -> barren / reward / alien combat / human viable result
  -> collect beacon or clear combat
  -> sector transition
  -> upgrade screen
  -> next sector
```

### Tech Stack

- Engine: Godot 4.6 configured for GL Compatibility.
- Language: GDScript.
- Render target: 320x180 viewport scaled to 1280x720.
- Autoloads: `GameManager`, `AudioManager`, `SaveManager`.
- Tests: GUT addon with unit tests under `tests/unit`.
- Data: encounter and wave JSON in `assets/data`.
- Assets: fonts, shaders, music/SFX WAV files, generated/import metadata.

## 3. Codebase Shape

I reviewed project files under `/Volumes/RepoDrive/Code/star-finder/nova-scout`, excluding `.git`, `.godot`, `addons`, `builds`, and the CCGS framework.

Approximate source/content footprint:

| Type | Files | Lines |
|---|---:|---:|
| GDScript `.gd` | 48 | 7,963 |
| Markdown `.md` | 279 | 58,041 |
| JSON `.json` | 12 | 401 |
| Godot scenes `.tscn` | 25 | 408 |
| Shader `.gdshader` | 1 | 32 |
| Project config `.godot` | 1 | 121 |
| Audio WAV | 55 | binary data counted as text by the quick scan |

Largest scripts over the project's stated 300-line guideline:

| File | Lines | Concern |
|---|---:|---|
| `src/core/game_world.gd` | 754 | Too many responsibilities: spawning, encounter dispatch, star clusters, arenas, pickups, win/death, rendering background. |
| `src/gameplay/effects/explosion.gd` | 435 | Visual variants likely should be data/components. |
| `src/ui/hud.gd` | 352 | HUD rendering and state display may need subcomponents. |
| `src/gameplay/player/player.gd` | 342 | Movement, orbiting, drawing, damage hooks in one class. |
| `src/core/main_menu.gd` | 333 | Menu UI drawing/control likely splittable. |
| `src/gameplay/enemies/space_leviathan.gd` | 328 | Boss/miniboss behavior complexity. |
| `src/gameplay/hazards/space_mine.gd` | 317 | Mine variants and draw logic are heavy but manageable. |

## 4. Implemented Strengths

### 4.1 Strong central state model

`GameManager` defines clear states: MENU, TRAVEL, ENCOUNTER, STAR_CLUSTER, SCANNING, ALIEN_COMBAT, SECTOR_TRANSITION, UPGRADE_SCREEN, DEATH, WIN. It also centralizes persistent player stats, score, crystals, streaks, sector progression, and upgrades.

### 4.2 Data-driven encounter sequencing

Each sector has an encounter JSON file, and `EncounterManager` loads, sorts, and triggers encounters by travel distance. This is a good architecture for pacing iteration.

Current sector encounter files are already compressed to star cluster at distance 5800:

- Sector 1: 16 encounters.
- Sector 2: 14 encounters.
- Sector 3: 10 encounters.
- Sector 4: 10 encounters.
- Sector 5: 11 encounters.

This suggests the earlier design problem of 8-minute travel to first star cluster has been partially addressed. `EncounterManager.SECTOR_LENGTH` is now 6000, which at 40 px/sec is about 150 seconds before the star cluster trigger.

### 4.3 Better-than-basic hazard design

The current `SpaceMine` implementation already includes:

- Standard / cluster / rapid variants.
- Erratic sine drift.
- Random lurch movement.
- Proximity chase.
- Telegraph charge.
- Six-shot spike burst.
- Cluster mine split behavior.

This is a meaningful improvement over passive mines.

### 4.4 Sector intensity exists

`GameManager.get_sector_intensity()` returns a scaling multiplier. `GameWorld` uses it for ambient spawning, and `EnemyBase` applies sector-based HP/fire-rate scaling. This supports a real difficulty curve.

### 4.5 Good retro presentation foundation

The game draws its own player craft, stars, nebula blobs, mines, HUD-like effects, CRT overlay, sector transition panels, and explosions. The result is cohesive and easy to tune without a huge sprite pipeline.

### 4.6 Audio and save managers are already present

`AudioManager` handles music crossfading, SFX pooling, sector music, and mothership phase music. `SaveManager` persists high scores and settings to `user://nova_scout_save.json`.

## 5. High-Priority Problems Found

### 5.1 The final boss / true ending path looks broken or bypassed

The README promises a Mothership boss and dual endings. The star cluster data includes Sector 5 star E4 with result `mothership`, but the current flow appears to trigger win too early:

- `StarClusterManager` sector 5 has:
  - E3: `human_viable`, guaranteed, with a wave path.
  - E4: `mothership`, mandatory_after E3.
- `GameWorld._on_viable_found()` immediately calls `_trigger_win(false)` if `GameManager.has_won()` is true.
- `GameManager.has_won()` becomes true when the third beacon is collected, which happens on E3.
- `mandatory_after` is present in the data but I did not see handling for it in `StarClusterManager`.

Likely effect: the player can win after scanning the third habitable world without ever being forced into the Mothership boss. This undercuts the campaign climax.

Recommended fix:

- Split `has_three_beacons` from `campaign_complete`.
- Add state such as `mothership_defeated` or `final_boss_required`.
- In Sector 5, after E3, spawn/reveal/activate E4 instead of ending immediately.
- Only trigger true ending after defeating Mothership.
- If dual endings are desired, make standard ending a deliberate escape choice after E3, not an accidental bypass.

### 5.2 Star scanning is still mostly a timer, not a signature mechanic

`StarNode` scanning is simple:

- Press E near star.
- Player enters orbit.
- Progress fills over `scan_duration`.
- Press E aborts.
- Auto-abort only at hull <= 5.
- On completion, emit result.

The GDD says scanning should create wonder and tension. Right now, the code's scan mechanic is more of a stationary wait. It does not obviously spawn scan-specific danger, ask the player to position carefully, or create escalating decisions during the scan.

Recommended improvements:

- Add scan-phase hazard pulses: small waves spawned at 25%, 50%, 75%, tuned by sector and star result.
- Add scan stability: taking damage slows or destabilizes progress rather than only aborting at near death.
- Add optional overcharge: hold scan longer for bonus crystals but risk an enemy ambush.
- Add star-specific tells before scan completion so players learn to read results without making them totally obvious.
- Add scan result reveal animation: planet silhouette, spectrum bars, noisy mission-control printout.

### 5.3 Critical tuning is split between JSON and hardcoded constants

The project standard says gameplay balance values should live in `assets/data/*.json`, not hardcoded. In practice, many important values are constants inside scripts:

- Player speed, boost speed, fuel drain in `player.gd`.
- Laser fire rate, energy cost, missile damage, EMP radius in `player_weapons.gd`.
- Spawn intervals and max hazards in `game_world.gd`.
- Sector length and scroll speed in `encounter_manager.gd`.
- Mine HP, damage, speed, fire timing in `space_mine.gd`.
- Drop tables in `drop_table.gd`.
- Upgrade costs/effects in `game_manager.gd`.
- Star scan configs in `star_cluster_manager.gd`.

This makes balance iteration slower than it should be.

Recommended fix:

Create these data files:

```text
assets/data/balance/player.json
assets/data/balance/weapons.json
assets/data/balance/hazards.json
assets/data/balance/enemies.json
assets/data/balance/upgrades.json
assets/data/balance/drops.json
assets/data/star_clusters/sector_1.json ... sector_5.json
```

Then load them through a small `BalanceDB` autoload or resource loader. Keep script constants only for non-gameplay implementation details.

### 5.4 `GameWorld` is the main architecture bottleneck

`GameWorld.gd` is 754 lines and owns too much:

- Background drawing.
- Travel hazard spawning.
- Encounter dispatch.
- Enemy spawning.
- Star cluster creation.
- Arena transitions.
- Sector transitions.
- Win/death flow.
- Pickup spawning.
- Explosion spawning.
- Screen shake.

This makes future improvements risky because almost every feature touches the same file.

Recommended split:

```text
src/core/game_world.gd                  # high-level orchestration only
src/systems/travel_spawner.gd           # ambient asteroids/mines/clouds
src/systems/encounter_dispatcher.gd      # JSON encounter type -> spawn action
src/systems/enemy_factory.gd             # enemy scene map and setup
src/systems/pickup_service.gd            # drops, scan rewards, anomaly loot
src/systems/sector_flow_controller.gd    # sector transition/upgrades/win/death
src/rendering/starfield_renderer.gd      # parallax/nebula drawing
```

### 5.5 Upgrade system is functional but not exciting enough

`GameManager.apply_upgrade()` supports hull, fuel, shield regen, missiles, and laser damage. Costs are fixed. Effects are linear. This is understandable but low-drama.

Problems:

- No mutually exclusive builds.
- No rare upgrades.
- No sector-specific tech discoveries.
- No preview of how upgrades affect stats.
- Laser upgrade just increases damage; it does not change feel.

Recommended improvements:

- Add 2-3 upgrade branches:
  - Explorer: fuel efficiency, scan speed, anomaly detection.
  - Fighter: laser spread, missile lock range, EMP duration.
  - Survivor: shield delay, hull plating, collision forgiveness.
- Add one rare `anomaly tech` upgrade per run.
- Add upgrade UI comparison: current value -> new value.
- Add hard cap or escalating costs to create meaningful choices.
- Add build-defining upgrades, e.g. `Twin Laser`, `Afterburner Trail`, `Survey Overclock`, `Magnetic Collector`.

### 5.6 The game needs more explicit onboarding

Controls exist in README and input map, but in-game onboarding should teach:

- Move.
- Boost drains fuel.
- Fire laser.
- Asteroids split.
- Pickups matter.
- Approach star and press E.
- Scanning locks orbit but can be aborted.
- Alien territory triggers combat.
- Upgrades are bought with crystals.

Recommended improvements:

- Add a 90-second Sector 1 tutorial layer using tiny mission-control prompts.
- Prompt only when relevant and dismiss permanently after first success.
- Make the first star cluster happen very early in Sector 1, even if later clusters take longer.
- Add a codex/help screen in pause menu.

### 5.7 There are design/code mismatches

Examples found:

- README says audio assets are not included, but the repo has many WAV files under `assets/audio/music` and `assets/audio/sfx`.
- README promises one hour, while current `SECTOR_LENGTH = 6000` and star cluster at 5800 imply much shorter travel phases.
- GDD says laser has unlimited ammo, but implementation uses energy and overheat.
- GDD says scan duration 20-30s, but code uses 8-12s for most non-combat stars and 0s for alien territory stars.
- GDD says pickup despawn behavior; physical pickup code should be checked to confirm exact behavior.
- GDD says escape from alien combat exists; `GameWorld.exit_arena_escape()` exists, but I did not see a full interactive emergency-warp implementation during this review.

Recommended fix:

Maintain a `docs/current-gameplay-state.md` file that documents what the build actually does now, separate from aspirational GDDs.

## 6. Design Improvements That Would Make the Game Much Better

### 6.1 Make the first session unforgettable within three minutes

Current code reaches star cluster quickly enough on paper, but the player still needs an authored opening arc.

Suggested first three minutes:

1. 0:00-0:20: Player launches, one simple asteroid lane, movement prompt.
2. 0:20-0:45: First asteroid split, laser prompt, satisfying pickup.
3. 0:45-1:15: Fuel cache or derelict, teaches shooting objects for resources.
4. 1:15-1:45: First star cluster appears early.
5. 1:45-2:15: First scan completes with a cinematic barren result plus crystals.
6. 2:15-3:00: A tiny alien signal or mine encounter foreshadows later sectors.

Goal: players should understand the fantasy before they decide whether the game is fun.

### 6.2 Turn star clusters into mini decision spaces

Currently star positions are computed in a ring, with fixed sector configs. Improve clusters so each star is a tactical choice:

- Show vague labels: `Faint Yellow`, `Magenta Interference`, `Stable G-Type`, `Unknown Signal`.
- Add scan risk estimates without spoiling result.
- Optional stars should be tempting: more reward, more risk, or story clues.
- Hidden anomalies should be discoverable via proximity, scan streak, or upgrade.
- Let players leave a cluster early if low on hull/fuel, sacrificing optional rewards.

### 6.3 Add sector-specific identity beyond spawn density

Each sector should change how the player thinks:

- Sector 1, Inner Rim: teach movement, asteroid splitting, first scan.
- Sector 2, Asteroid Fields: dense rocks, first scouts, mine introduction.
- Sector 3, Nebula Crossing: visibility/sensor interference, scan instability, first guaranteed habitable world.
- Sector 4, Alien Territory: flanking waves, destroyers, artillery, ambushes, dangerous optional stars.
- Sector 5, Frontier: compressed high-pressure gauntlet, elite combinations, Mothership finale.

Possible code/data additions:

```json
"sector_modifiers": {
  "3": { "visibility": 0.72, "scan_noise": 1.4 },
  "4": { "ambush_chance": 0.25, "enemy_fire_rate": 1.25 },
  "5": { "hazard_density": 1.5, "elite_support": true }
}
```

### 6.4 Make combat more expressive

The combat foundation is solid, but the primary laser and missile can become more satisfying.

Improvements:

- Add muzzle flash and tiny recoil impulse to the player craft.
- Add enemy hit sparks distinct from death explosions.
- Add shield impact rings for shield hits vs hull hits.
- Add near-miss score bonuses for dodging bullets/asteroids closely.
- Let missiles lock with a visible reticle and a short tone.
- Add enemy weak points for destroyers/elite enemies.
- Add weapon upgrade behaviors, not just damage numbers.

### 6.5 Improve enemy encounter composition

Existing encounter types include asteroid fields, mine fields, scout/warrior/destroyer waves, elite waves, mixed fields, ambush waves, leviathan, fuel cache, derelict, and star cluster. That is a good set.

Next step: authored combinations with explicit intent.

Examples:

```json
{ "distance": 2600, "type": "pincer_minefield", "params": { "mines": 3, "scouts": 4 } }
{ "distance": 3400, "type": "shielded_destroyer", "params": { "destroyers": 1, "drones": 2 } }
{ "distance": 4800, "type": "scan_disruption", "params": { "clouds": 2, "artillery": 1 } }
```

Better yet, give every encounter a `design_intent` comment field for future tuning:

```json
{
  "distance": 4000,
  "type": "ambush_wave",
  "design_intent": "teach side pressure before Sector 5 pincer fights",
  "params": { "type": "warrior", "count_left": 2, "count_right": 2 }
}
```

### 6.6 Add a proper Mothership climax

The Mothership should be the payoff for the entire run.

Recommended structure:

- Trigger only after the third beacon in Sector 5.
- Player gets a short mission-control warning and final supply drop.
- Phase 1: turrets and predictable sweeping fire.
- Phase 2: summons scouts/mines; player must manage adds.
- Phase 3: core exposed, screen shake, music shift, high-risk DPS window.
- Victory: beacon transmission sequence, Earth response, final score breakdown.

Code work:

- Implement mandatory-after reveal in `StarClusterManager`.
- Add `GameManager.mothership_defeated`.
- Trigger `_trigger_win(true)` only after boss death.
- Trigger `_trigger_win(false)` only if the player chooses to transmit and flee without boss victory, if that ending remains desired.

### 6.7 Add meta scoring depth

The current score system supports score, multiplier, kill streak, beacon score, survival trickle, and score popups. Build on it.

Add end-of-sector bonuses:

- No hull damage.
- Fuel efficiency.
- All stars scanned.
- Optional anomaly found.
- Fast scan chain.
- Enemies destroyed.
- Near-miss count.
- No EMP used.

This gives players reasons to replay sectors and optimize.

### 6.8 Make pickups more fun to collect

Current `spawn_pickup` instantly applies common travel pickups during travel instead of spawning physical pickups. That may be practical, but it removes collection dopamine.

Recommendation:

- Spawn physical pickups more often, especially crystals and fuel.
- Add a small magnet radius or upgradeable tractor beam.
- Use instant-apply only for offscreen/scripted rewards where a physical pickup would be annoying.
- Make crystals visually burst outward from enemies, then drift toward the player after a delay.

### 6.9 Add accessibility and settings

`SaveManager.settings` has music, SFX, fullscreen. Expand this into a real settings menu:

- Remappable controls.
- Screen shake amount.
- CRT/scanline toggle.
- Flash intensity toggle.
- Colorblind-friendly enemy bullets/pickups.
- Difficulty presets.
- Aim assist / missile lock assist.
- Text size scaling.
- Hold vs toggle boost.

This will materially improve usability without changing the game identity.

## 7. Technical Improvements

### 7.1 Refactor toward smaller systems

Priority extraction order:

1. `PickupService` from `GameWorld`.
2. `EnemyFactory` from `GameWorld`.
3. `TravelSpawner` from `GameWorld`.
4. `EncounterDispatcher` from `GameWorld`.
5. `StarfieldRenderer` from `GameWorld`.
6. `SectorFlowController` from `GameWorld`.

Acceptance criterion: `GameWorld.gd` under 300 lines and mostly wires systems together.

### 7.2 Move tuning to data

Start with the highest-iteration values:

- Player movement and fuel.
- Weapon stats.
- Mine variants.
- Enemy stats.
- Drops.
- Upgrade costs/effects.
- Star clusters.

This will let design changes happen in JSON without script edits.

### 7.3 Add validation scripts for data files

Create a small script to validate:

- Encounter distances are increasing.
- Final encounter is star cluster.
- Encounter type is known.
- Enemy type is known.
- Wave files referenced by stars exist.
- Star configs do not use unimplemented fields like `mandatory_after` without behavior.
- Drop table weights sum to expected totals.
- No sector lacks a guaranteed viable world where required.

### 7.4 Expand automated tests

Current tests cover `GameManager` basics and player tests exist. Add tests for:

- Encounter loading/sorting and trigger order.
- Sector transition increments sector exactly once.
- Third beacon in Sector 5 does not bypass required Mothership.
- Upgrade costs/effects/caps.
- DropTable statistical sanity with deterministic RNG where possible.
- StarCluster required vs optional completion.
- SaveManager corrupted/missing save behavior.
- Player fuel death/empty fuel behavior.
- Weapon energy overheat behavior.

### 7.5 Use static checks / headless Godot in CI

Add a verification command script, e.g.:

```bash
./scripts/verify.sh
```

It should run:

- Godot headless import/check if available.
- GUT tests.
- JSON schema validation.
- Simple line-count check for scripts over 300 lines.

### 7.6 Improve object pooling coverage

Lasers and missiles are pooled. Other frequent objects are not obviously pooled:

- Enemy bullets.
- Mine bolts.
- Explosions.
- Score popups.
- Pickups.
- Asteroid fragments.

Pooling enemy bullets and explosions would reduce allocation churn during busy sectors.

### 7.7 Reduce reliance on global singletons in gameplay code

`GameManager`, `AudioManager`, and `SaveManager` are practical autoloads, but lots of gameplay code reaches into them directly. This makes tests harder.

Suggested compromise:

- Keep autoloads.
- For systems with tests, pass dependencies through setup methods where practical.
- Use interfaces/service wrappers for balance, audio, and score events.

## 8. Content Improvements

### 8.1 Add narrative beats inside play, not just docs

The setting is strong, but the player needs to feel it in-game.

Add short mission-control lines:

- On sector entry.
- First alien contact.
- First habitable world.
- Low fuel.
- Low hull.
- Optional anomaly.
- Final beacon.
- Mothership reveal.

Keep them short, diegetic, and skippable.

### 8.2 Add anomaly content

Anomaly stars exist in data, but hidden/optional behavior appears underdeveloped. Use anomalies to add surprise:

- Ancient probe wreck with a log from another Survey Probe.
- Rare upgrade choice.
- Repair/fuel sanctuary.
- Alien trap.
- Star map fragment revealing optional star risk.

### 8.3 Add enemy personality

Enemy classes can be differentiated more by silhouettes and behavior:

- Scout: fast, fragile, strafes.
- Warrior: direct pressure, aimed fire.
- Destroyer: slow area denial.
- Artillery: telegraphed heavy shots.
- Interceptor: flanking and dives.
- Swarm commander: summons drones/mines.
- Leviathan: environmental miniboss.
- Mothership: phase-based centerpiece.

### 8.4 Upgrade audio feedback

The audio manager is ready. Ensure every important event has a satisfying cue:

- Beacon acquired.
- Scan nearing completion.
- Scan interrupted.
- Enemy weakpoint hit.
- Missile lock.
- Overheat warning and recovery.
- Shield break and shield recharge.
- Low fuel escalating alarm.
- Sector transition warp.

## 9. Prioritized Roadmap

### Phase 1: Fix the campaign spine

- Fix Sector 5 final beacon / Mothership / ending flow.
- Implement `mandatory_after` or remove it from data.
- Add tests for win conditions and sector progression.
- Update README/GDD mismatch around audio and playtime.

### Phase 2: Make scanning great

- Add scan-phase hazards.
- Add scan instability/damage consequences.
- Add result reveal presentation.
- Add optional star risk/reward labels.
- Add anomaly discovery behavior.

### Phase 3: Data-drive balance

- Move upgrades, drops, player weapons, hazard stats, and star cluster configs into JSON.
- Add data validation script.
- Keep design docs synchronized with implemented balance.

### Phase 4: Refactor hot files

- Split `GameWorld.gd` systems.
- Extract factories/services.
- Pool enemy bullets/explosions/score popups.
- Keep all scripts under the 300-line guideline where practical.

### Phase 5: Add polish and accessibility

- Settings menu.
- CRT/shake/flash toggles.
- Control remapping.
- More score feedback.
- More audio cues.
- Better tutorial prompts.

## 10. Concrete Backlog Items

### Bugs / correctness

- [ ] Prevent third beacon from immediately ending Sector 5 before Mothership.
- [ ] Implement or remove `mandatory_after` in star data.
- [ ] Decide whether `mothership` is a star result, an alien combat wave, or a sector event; implement consistently.
- [ ] Verify alien-combat escape is fully playable, not only a helper method.
- [ ] Reconcile README audio statement with actual audio assets.
- [ ] Reconcile target playtime docs with current 6000-distance sector pacing.

### Gameplay

- [ ] Add scan-phase enemy/hazard pressure.
- [ ] Add scan result reveal animation.
- [ ] Add early Sector 1 tutorial prompts.
- [ ] Add near-miss scoring.
- [ ] Add end-of-sector bonus breakdown.
- [ ] Add physical pickup magnet behavior.
- [ ] Add rare anomaly upgrades.
- [ ] Add build-defining upgrade branches.

### Technical

- [ ] Extract `TravelSpawner`.
- [ ] Extract `EncounterDispatcher`.
- [ ] Extract `EnemyFactory`.
- [ ] Extract `PickupService`.
- [ ] Extract starfield drawing.
- [ ] Add `BalanceDB` and JSON tuning files.
- [ ] Add data schema validation.
- [ ] Add headless verification script.
- [ ] Pool enemy bullets and explosions.

### Tests

- [ ] Test Sector 5 ending flow.
- [ ] Test encounter trigger ordering.
- [ ] Test star cluster required/optional completion.
- [ ] Test upgrade effects and caps.
- [ ] Test DropTable outputs.
- [ ] Test SaveManager corrupted JSON handling.
- [ ] Test weapon overheat/recovery.
- [ ] Test fuel depletion death/loss path.

## 11. Suggested North Star

Nova Scout should feel like this:

> A tight retro sci-fi arcade campaign where every sector teaches a new survival skill, every star scan feels like a dangerous discovery, and the final beacon wakes something enormous that the player must defeat to bring humanity home.

The code already supports most of this. The best next work is to close the gap between the strong concept and the actual player-facing arc: fix the ending, deepen scanning, tune pacing, make upgrades more expressive, and refactor the big orchestration file so future improvements are safer.
