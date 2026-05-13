# Nova Scout — Steam-Ready Backlog

**Purpose:** Master task list for finishing Nova Scout to a Steam-quality release.

**Priority scale:**

- P0: Blocks a credible release.
- P1: Strongly affects reviews, retention, or polish.
- P2: Valuable but can be cut if schedule requires.
- P3: Nice-to-have or post-launch.

**Status values:** TODO, IN PROGRESS, DONE, CUT, DEFERRED.

---

## P0 — Release Blockers

| ID | Task | Area | Depends On | Status | Acceptance Criteria |
|---|---|---|---|---|---|
| P0-001 | Fix Sector 5 final beacon/Mothership/ending flow | Campaign | none | DONE | Third beacon does not bypass Mothership; true ending requires boss defeat |
| P0-002 | Add regression tests for campaign win conditions | Tests | P0-001 | DONE | GUT tests cover 1/2/3 beacons, Sector 5 final beacon, boss defeat |
| P0-003 | Implement or remove `mandatory_after` consistently | Star Scan | P0-001 | DONE | Data has no ignored progression-critical fields |
| P0-004 | Verify Mothership scene, phases, death signal, and arena exit | Boss | P0-001 | IN PROGRESS | Automated wiring coverage exists; manual phase/playthrough QA still required |
| P0-005 | Add `scripts/verify.sh` | Tooling | none | DONE | Runs tests, JSON validation, and basic project checks where tools are available |
| P0-006 | Validate encounter/wave/star data | Tooling | P0-005 | DONE | Validator catches unknown encounter/enemy types, missing wave files, bad ordering |
| P0-007 | Full campaign smoke playthrough | QA | P0-001 | IN PROGRESS | Automated campaign spine smoke reaches true ending; manual start -> Sector 5 -> Mothership -> true ending playthrough still required |
| P0-008 | Update current gameplay documentation | Docs | P0-001 | IN PROGRESS | Docs describe actual playtime, audio state, weapons, endings, scan durations |
| P0-009 | Confirm export presets and executable launch | Release | P0-005 | DONE | `scripts/export_smoke.py` passes: Linux release export succeeds, macOS export succeeds, and native macOS executable launch smoke passes on this host |
| P0-010 | Settings/save corruption safety pass | Platform | none | DONE | Missing/corrupted save/settings do not crash; defaults restore safely |

---

## P1 — Steam Review Drivers

| ID | Task | Area | Depends On | Status | Acceptance Criteria |
|---|---|---|---|---|---|
| P1-001 | Build authored first-five-minutes opening arc | Onboarding | P0-001 | IN PROGRESS | Quick spec exists; Sector 1 reaches first star cluster at distance 4400 (~110s); one-time mission-control prompts are wired; manual timing QA remains |
| P1-002 | Add mission-control tutorial prompts | UX | P1-001 | DONE | Prompts are short, contextual, one-time, non-blocking, and persist dismissal state |
| P1-003 | Add scan hazard pulses | Star Scan | P0-002 | DONE | Scan pressure pulses fire once at configured thresholds; GameWorld spawns asteroid/mine/enemy pressure from pulse data |
| P1-004 | Add scan stability/damage consequences | Star Scan | P1-003 | TODO | Damage slows, destabilizes, or risks aborting scan without feeling random |
| P1-005 | Add scan result reveal presentation | Presentation | P1-003 | TODO | Results have spectrum/planet/mission-control reveal beats |
| P1-006 | Add star risk/reward labels | UX | P1-003 | TODO | Optional stars communicate danger/reward without exact spoilers |
| P1-007 | Add upgrade stat comparison UI | Upgrades | none | TODO | UI shows current value -> upgraded value and cost |
| P1-008 | Add upgrade branches | Upgrades | P1-007 | TODO | Explorer/Fighter/Survivor paths include at least two feel-changing upgrades each |
| P1-009 | Add rare anomaly tech reward | Progression | P1-008 | TODO | At least one rare upgrade can appear from anomaly content per run |
| P1-010 | Add end-of-sector bonus breakdown | Scoring | none | TODO | Sector transition scores no-damage/fuel/all-stars/fast-scan/near-miss bonuses |
| P1-011 | Add near-miss scoring | Scoring | P1-010 | TODO | Bullets/asteroids can award readable near-miss bonuses with anti-spam cooldown |
| P1-012 | Improve physical pickup collection | Pickups | none | TODO | Crystals/fuel visibly spawn when practical; magnet behavior supports collection dopamine |
| P1-013 | Add settings menu expansion | Settings | P0-010 | IN PROGRESS | Main menu settings overlay exists for audio, fullscreen, screen shake, CRT, flash, text scale, boost mode, and color-friendly mode; pause-menu access/manual UI QA still needed |
| P1-014 | Add accessibility toggles | Accessibility | P1-013 | IN PROGRESS | Screen shake, CRT, flash intensity, and hold/toggle boost have runtime hooks; color-friendly palette and broad text scale still need completion |
| P1-015 | Gamepad QA and input help | Platform | P1-013 | TODO | Controller can complete a full run; prompts adapt or help screen lists controls |
| P1-016 | Audio cue completeness pass | Audio | none | TODO | Beacon, scan, interrupt, lock, overheat, shield, low fuel, warp all have cues |
| P1-017 | Steam Deck/performance stress pass | Performance | P0-005 | TODO | Worst-case scene sustains target FPS without allocation spikes where measurable |

---

## P1 — Architecture and Data Quality

| ID | Task | Area | Depends On | Status | Acceptance Criteria |
|---|---|---|---|---|---|
| A1-001 | Add `BalanceDB` loader with fallbacks | Data | P0-005 | TODO | JSON values can be loaded safely; missing keys use documented defaults |
| A1-002 | Move upgrade costs/effects into JSON | Data | A1-001 | TODO | Upgrade tuning changes do not require script edits |
| A1-003 | Move drop tables into JSON | Data | A1-001 | TODO | Drop weights validated and loaded through one path |
| A1-004 | Move weapons/player core tuning into JSON | Data | A1-001 | TODO | Speed/fuel/weapon values are data-driven |
| A1-005 | Move hazard/enemy stats into JSON | Data | A1-001 | TODO | Mine/enemy HP/damage/rates are data-driven |
| A1-006 | Move star clusters into JSON | Data | P0-003, A1-001 | TODO | Star result configs are external and validated |
| A1-007 | Extract `PickupService` from `GameWorld` | Architecture | P0-001 | TODO | Pickup spawn/reward/drop logic is isolated and tested where possible |
| A1-008 | Extract `EnemyFactory` from `GameWorld` | Architecture | A1-007 | TODO | Enemy scene mapping/spawn setup is isolated |
| A1-009 | Extract `TravelSpawner` from `GameWorld` | Architecture | A1-008 | TODO | Ambient hazards/fill logic is isolated |
| A1-010 | Extract `EncounterDispatcher` from `GameWorld` | Architecture | A1-009 | TODO | Encounter type -> action mapping is isolated |
| A1-011 | Extract `StarfieldRenderer` from `GameWorld` | Architecture | A1-010 | TODO | Background drawing no longer bloats GameWorld |
| A1-012 | Extract `SectorFlowController` from `GameWorld` | Architecture | A1-011 | TODO | Sector transitions/win/death flow are isolated |
| A1-013 | Pool enemy bullets and explosions | Performance | A1-008 | TODO | Frequent combat objects are reused instead of repeatedly allocated |
| A1-014 | Pool pickups/score popups/fragments | Performance | A1-007 | TODO | Busy reward/combat scenes avoid allocation churn |

---

## P2 — Content, Juice, and Replayability

| ID | Task | Area | Depends On | Status | Acceptance Criteria |
|---|---|---|---|---|---|
| P2-001 | Add sector-entry mission-control lines | Narrative | P1-001 | TODO | Each sector has a concise identity-setting line |
| P2-002 | Add first-contact/final-beacon/Mothership narrative beats | Narrative | P0-001 | TODO | Key campaign moments have in-game text/audio presentation |
| P2-003 | Add anomaly variants | Content | P1-009 | TODO | At least three anomaly outcomes: reward, lore, trap/sanctuary |
| P2-004 | Add authored encounter `design_intent` comments/fields | Level Design | P0-006 | TODO | Encounter data explains what each encounter teaches or tests |
| P2-005 | Add sector-specific modifiers | Level Design | A1-001 | TODO | Nebula/alien/frontier sectors affect visibility, scan noise, density, or elites |
| P2-006 | Add enemy hit sparks and shield impact rings | Juice | none | TODO | Shield vs hull damage is visually distinct |
| P2-007 | Add missile lock reticle/tone | Juice | P1-016 | TODO | Lock state is readable and satisfying |
| P2-008 | Add player muzzle flash/recoil impulse | Juice | none | TODO | Primary weapon feels more tactile without hurting controls |
| P2-009 | Add weak-point behavior for elite/boss enemies | Combat | P0-004 | TODO | At least Mothership exposes high-damage windows clearly |
| P2-010 | Add pause/help/codex screen | UX | P1-013 | TODO | Player can review controls, mechanics, and discovered lore |

---

## Steam Store and Launch Tasks

| ID | Task | Area | Depends On | Status | Acceptance Criteria |
|---|---|---|---|---|---|
| S-001 | Define Steam short/long description | Store | M0-M2 stable | TODO | Copy matches actual game features and tone |
| S-002 | Capture 8-12 store screenshots | Store | Polish pass | TODO | Screens show combat, scanning, upgrades, sector identity, Mothership |
| S-003 | Create capsule art brief | Store | Visual identity stable | TODO | Capsule requirements and composition brief are documented |
| S-004 | Capture trailer shot list | Store | Mothership/scanning polished | TODO | 60-90 second trailer plan exists with exact beats |
| S-005 | Prepare system requirements | Store | Perf pass | TODO | Minimum/recommended specs based on observed performance |
| S-006 | Prepare release notes | Launch | QA complete | TODO | Notes list features, controls, known issues, support path |
| S-007 | Prepare support/bug-report template | Launch | QA complete | TODO | Players can report crashes/bugs with useful info |

---

## Cut-Line Guidance

If schedule gets tight, protect these at all costs:

1. Campaign spine and Mothership ending.
2. First-five-minutes onboarding and pacing.
3. Stable exports and no softlocks.
4. Settings and controls.
5. Star scanning improvements.

Cut or defer before risking the core release:

- Extra anomaly variants beyond one polished example.
- Multiple rare upgrades if one excellent rare tech exists.
- Deep `GameWorld` refactor beyond the pieces needed for safety/performance.
- Nonessential store extras beyond screenshots/trailer/capsule.
