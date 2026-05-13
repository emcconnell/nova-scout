# GameWorld Refactor and Performance Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Reduce `src/core/game_world.gd` from a large high-risk orchestration file into smaller systems, while protecting performance for a Steam release.

**Architecture:** Refactor only after the campaign spine has regression coverage. Extract one responsibility at a time, keep public behavior unchanged, and run tests/manual smoke checks after every extraction.

**Tech Stack:** Godot 4, GDScript, GUT tests, manual performance smoke tests.

---

## Preconditions

Do not begin this plan until:

- `docs/plans/sector-5-mothership-ending-flow.md` is complete.
- `scripts/verify.sh` exists or equivalent test command is known.
- A manual full-run or debug-run can reach Sector 5 without immediate progression blockers.

---

## Extraction Order

1. `PickupService`
2. `EnemyFactory`
3. `TravelSpawner`
4. `EncounterDispatcher`
5. `StarfieldRenderer`
6. `SectorFlowController`

This order minimizes risk: simple services first, campaign-flow extraction last.

---

## Task 1: Characterize current GameWorld responsibilities

**Objective:** Create a quick map before changing code.

**Files:**

- Create: `docs/architecture/gameworld-responsibility-map.md`

**Steps:**

1. Read `src/core/game_world.gd`.
2. List functions grouped by responsibility:
   - background drawing
   - travel spawning
   - encounter dispatch
   - enemy spawn/factory
   - star cluster flow
   - arena flow
   - pickups/rewards
   - sector/win/death flow
   - screen shake/effects
3. Mark which functions can move with no behavior change.
4. Mark dependencies each extracted service needs.

**Verification:** The map identifies exact functions to move for Task 2.

---

## Task 2: Extract `PickupService`

**Objective:** Move pickup spawning/reward/drop logic out of GameWorld.

**Files:**

- Create: `src/systems/pickup_service.gd`
- Modify: `src/core/game_world.gd`
- Test if practical: `tests/unit/test_pickup_service.gd`

**Responsibilities:**

- `spawn_pickup`
- scan reward parsing/application
- anomaly loot spawning
- drop-table result spawning
- physical-vs-instant reward choice

**API sketch:**

```gdscript
class_name PickupService
extends Node

var pickup_container: Node2D
var player: Node2D

func setup(p_container: Node2D, p_player: Node2D) -> void:
	pickup_container = p_container
	player = p_player

func spawn_pickup(position: Vector2, pickup_type: String) -> void:
	# move existing GameWorld behavior here
```

**Verification:**

- Existing call sites still work through GameWorld wrapper methods.
- Pickups spawn/collect as before.
- Scan rewards and anomaly loot still work.

---

## Task 3: Extract `EnemyFactory`

**Objective:** Centralize enemy scene mapping and setup.

**Files:**

- Create: `src/systems/enemy_factory.gd`
- Modify: `src/core/game_world.gd`
- Modify: any wave/arena code only if necessary

**Responsibilities:**

- enemy type -> PackedScene mapping
- enemy instantiation
- initial position setup
- signal hookups common to all enemies

**API sketch:**

```gdscript
class_name EnemyFactory
extends Node

func spawn_enemy(enemy_type: String, position: Vector2, parent: Node) -> Node2D:
	var scene := _scene_for_type(enemy_type)
	if scene == null:
		push_warning("Unknown enemy type: %s" % enemy_type)
		return null
	var enemy := scene.instantiate() as Node2D
	parent.add_child(enemy)
	enemy.global_position = position
	return enemy
```

**Verification:**

- All existing enemy encounter types still spawn.
- Mothership still spawns.
- Unknown enemy type fails with warning, not crash.

---

## Task 4: Extract `TravelSpawner`

**Objective:** Move ambient asteroid/mine/debris/fill spawning out of GameWorld.

**Files:**

- Create: `src/systems/travel_spawner.gd`
- Modify: `src/core/game_world.gd`

**Responsibilities:**

- ambient hazard timers
- sector intensity spawn scaling
- dead-zone fill behavior
- max hazard caps

**Rules:**

- Keep behavior unchanged in first extraction.
- Add dead-zone fill only after extraction is verified.
- Use data-driven values when BalanceDB is available.

**Verification:**

- Travel still spawns hazards.
- Star cluster/arena states stop travel spawning correctly.
- No duplicate spawn loops remain active.

---

## Task 5: Extract `EncounterDispatcher`

**Objective:** Move encounter type -> action mapping out of GameWorld.

**Files:**

- Create: `src/systems/encounter_dispatcher.gd`
- Modify: `src/core/game_world.gd`

**Responsibilities:**

- match encounter type strings
- call appropriate spawn/factory/travel methods
- handle unknown encounter type safely
- support authored combined encounters

**API sketch:**

```gdscript
class_name EncounterDispatcher
extends Node

var world: Node
var enemy_factory: EnemyFactory
var travel_spawner: TravelSpawner

func dispatch(encounter_type: String, params: Dictionary) -> void:
	match encounter_type:
		"asteroid_field": world._encounter_asteroid_field(params)
		"mine_field": world._encounter_mine_field(params)
		"star_cluster": world._start_star_cluster()
		_:
			push_warning("Unknown encounter type: %s" % encounter_type)
```

Initial version may call existing GameWorld methods; later tasks can move the methods too.

**Verification:**

- All encounter JSON files still play.
- Unknown type validator catches issues before runtime.
- Runtime unknown type is non-fatal.

---

## Task 6: Extract `StarfieldRenderer`

**Objective:** Move background/parallax/nebula drawing out of GameWorld.

**Files:**

- Create: `src/rendering/starfield_renderer.gd`
- Modify: `src/core/game_world.gd`

**Responsibilities:**

- background stars
- parallax layers
- nebula blobs
- draw/update cached viewport size

**Verification:**

- Visual background looks unchanged.
- Resizing/window behavior remains correct.
- GameWorld `_draw()` shrinks or disappears.

---

## Task 7: Extract `SectorFlowController`

**Objective:** Isolate sector transitions, upgrade screens, death, and win flow after campaign behavior is stable.

**Files:**

- Create: `src/systems/sector_flow_controller.gd`
- Modify: `src/core/game_world.gd`
- Test: campaign flow tests where practical

**Responsibilities:**

- sector complete -> transition
- upgrade screen entry/exit
- death handling
- standard/true ending trigger
- finale guard logic

**Verification:**

- Sector transition increments exactly once.
- Upgrade screen appears between sectors.
- Death can occur in all major states.
- True ending still requires Mothership.

---

## Task 8: Pool high-frequency objects

**Objective:** Reduce runtime allocation and hitches.

**Files:**

- Modify or create object pool utility if present
- Modify projectile, explosion, pickup, score popup creation paths

**Pool candidates:**

1. enemy bullets
2. mine bolts
3. explosions
4. score popups
5. pickups
6. asteroid fragments

**Steps per object type:**

1. Identify creation/destruction path.
2. Add reset method to object script.
3. Replace instantiate/free with acquire/release.
4. Test reuse does not leak old state.
5. Stress test.

**Verification:**

- Busy Mothership/elite wave shows no obvious hitching.
- Reused objects reset visuals, collisions, timers, and signals correctly.
- No object remains active after release.

---

## Task 9: Add performance/stress verification scene or script

**Objective:** Make performance repeatable enough for release QA.

**Files:**

- Create: `tests/performance/` or `scenes/debug/performance_stress.tscn`
- Document usage in `production/steam-release-qa-checklist.md`

**Stress cases:**

- max ambient hazards
- mine spike burst
- elite mixed wave
- Mothership phase 3
- explosion/pickup burst

**Verification:**

- Developer can run the stress scene from editor or command line.
- Results are documented manually if automated FPS capture is not available.

---

## Final Acceptance Criteria

- `GameWorld.gd` is materially smaller and primarily orchestrates systems.
- No behavior regression in campaign, scanning, encounters, pickups, or boss flow.
- Performance is equal or better under stress.
- Extracted systems have clear setup methods and minimal singleton reliance.
- Future feature work can touch focused files instead of the entire world script.
