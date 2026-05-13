# Sector 5 Mothership Ending Flow Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Fix the campaign spine so the third beacon in Sector 5 leads into the existing Mothership climax, and true ending only occurs after boss defeat.

**Architecture:** Keep the first implementation minimal and behavior-preserving outside Sector 5. Separate “has enough beacons” from “campaign complete,” wire the existing Mothership scene/wave path into the Sector 5 star flow, and cover the sequence with regression tests before refactoring.

**Tech Stack:** Godot 4, GDScript, GUT tests, JSON wave/star data.

**Implementation status:** Code-level implementation is complete as of 2026-05-12. `./scripts/verify.sh` passes data validation and 56/56 GUT tests, including final-beacon reveal, Mothership arena entry, Mothership wave spawn/death wiring, and save/settings corruption safety. Manual in-engine Sector 5 boss QA remains before the milestone should be considered release-complete.

---

## Current Bug Summary

Files observed during review:

- `src/gameplay/star_scan/star_cluster_manager.gd`
  - Sector 5 E3 is `human_viable` and calls `GameManager.collect_beacon()`.
  - Sector 5 E4 is `mothership` with `mandatory_after: "E3"`, but no visible implementation handles `mandatory_after`.
  - `mothership` only emits `alien_combat_triggered` when `wave_path` is non-empty; E4 has an empty `wave_path`.
- `src/core/game_world.gd`
  - `_on_viable_found()` calls `_trigger_win(false)` immediately when `GameManager.has_won()` returns true.
- `src/core/game_manager.gd`
  - `has_won()` currently means `survey_beacons >= BEACONS_TO_WIN`.

Likely result: the third beacon can trigger an ending before the Mothership payoff.

---

## Task 1: Add tests documenting beacon count vs campaign completion

**Objective:** Prove that collecting three beacons is not the same as completing the campaign.

**Files:**

- Modify: `tests/unit/test_game_manager.gd`
- Modify: `src/core/game_manager.gd` only after the failing test is written

**Step 1: Write failing tests**

Add tests similar to:

```gdscript
func test_three_beacons_are_enough_for_finale_but_not_campaign_complete() -> void:
	GameManager.reset_run()
	GameManager.collect_beacon()
	GameManager.collect_beacon()
	GameManager.collect_beacon()

	assert_true(GameManager.has_required_beacons())
	assert_false(GameManager.is_campaign_complete())

func test_mothership_defeat_completes_campaign() -> void:
	GameManager.reset_run()
	GameManager.collect_beacon()
	GameManager.collect_beacon()
	GameManager.collect_beacon()
	GameManager.mark_mothership_defeated()

	assert_true(GameManager.is_campaign_complete())
```

If `reset_run()` has a different name, use the existing test setup convention in `test_game_manager.gd`.

**Step 2: Run tests to verify failure**

Run from repo root:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_game_manager.gd
```

Expected: FAIL because the new functions/properties do not exist yet.

**Step 3: Implement minimal GameManager API**

In `src/core/game_manager.gd`, add:

```gdscript
var mothership_defeated: bool = false

func has_required_beacons() -> bool:
	return survey_beacons >= BEACONS_TO_WIN

func is_campaign_complete() -> bool:
	return has_required_beacons() and mothership_defeated

func mark_mothership_defeated() -> void:
	mothership_defeated = true
```

Update run reset logic so `mothership_defeated = false` at the start of a new run.

Keep `has_won()` temporarily if many call sites exist, but make a follow-up task replace ambiguous use.

**Step 4: Run tests to verify pass**

Run:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_game_manager.gd
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/core/game_manager.gd tests/unit/test_game_manager.gd
git commit -m "test: separate beacon count from campaign completion"
```

---

## Task 2: Stop Sector 5 third beacon from immediately triggering win

**Objective:** Replace the ambiguous `has_won()` check in `_on_viable_found()`.

**Files:**

- Modify: `src/core/game_world.gd`
- Test: `tests/unit/test_game_manager.gd` or a new focused test if GameWorld is testable

**Step 1: Locate current code**

Check around:

```gdscript
func _on_viable_found(sector: int) -> void:
	if GameManager.has_won():
		_trigger_win(false)
```

**Step 2: Write failing behavior test if practical**

Preferred test behavior:

- Simulate three beacons.
- Confirm `GameManager.is_campaign_complete()` is false before `mark_mothership_defeated()`.

If GameWorld is not unit-testable yet, rely on Task 1 tests and add manual verification to this task.

**Step 3: Implement minimal flow change**

Replace the immediate win path with explicit logic:

```gdscript
func _on_viable_found(sector: int) -> void:
	if GameManager.current_sector == 5 and GameManager.has_required_beacons():
		_start_finale_after_beacon()
		return

	if GameManager.is_campaign_complete():
		_trigger_win(true)
```

Add helper:

```gdscript
func _start_finale_after_beacon() -> void:
	# Minimal first version: keep the player in star-cluster/finale flow.
	# The next task reveals or starts the Mothership encounter.
	if _star_cluster_mgr and _star_cluster_mgr.has_method("reveal_mandatory_after"):
		_star_cluster_mgr.reveal_mandatory_after("E3")
```

If `GameManager.current_sector` is not reliable in this context, use the `sector` parameter.

**Step 4: Run tests**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_game_manager.gd
```

Expected: PASS.

**Step 5: Manual check**

Temporarily instrument or debug-run Sector 5 to confirm `_trigger_win(false)` is not called immediately after E3.

**Step 6: Commit**

```bash
git add src/core/game_world.gd tests/unit/test_game_manager.gd
git commit -m "fix: prevent final beacon from bypassing mothership"
```

---

## Task 3: Implement `mandatory_after` reveal or remove the field

**Objective:** Make star data behavior match its schema.

**Files:**

- Modify: `src/gameplay/star_scan/star_cluster_manager.gd`
- Optional test: `tests/unit/test_star_cluster_manager.gd`

**Step 1: Write failing test if practical**

Target behavior:

- Sector 5 starts with E4 hidden or inactive until E3 is cleared.
- After E3 completes, E4 becomes available.

If StarClusterManager is hard to instantiate in tests, write a data validator in the data-validation plan later and perform manual verification here.

**Step 2: Implement reveal support**

Add state:

```gdscript
var _configs_by_id: Dictionary = {}
var _cleared_star_ids: Dictionary = {}
```

During `spawn_stars()`, store configs by id. Skip stars with `mandatory_after` until revealed:

```gdscript
if cfg.has("mandatory_after") and not _cleared_star_ids.has(cfg["mandatory_after"]):
	continue
```

When a scan completes, mark cleared:

```gdscript
var star_id: String = star_data.get("id", "")
if not star_id.is_empty():
	_cleared_star_ids[star_id] = true
```

Add public method:

```gdscript
func reveal_mandatory_after(required_id: String) -> void:
	for cfg in SECTOR_STARS.get(_sector, []):
		if cfg.get("mandatory_after", "") == required_id:
			_spawn_single_star(cfg)
```

Refactor single-star spawning out of `spawn_stars()` to avoid duplicate code.

**Step 3: Ensure required count does not complete before finale**

When E4 is mandatory, `_required_cleared` must include it once it becomes available, or the cluster must not emit `cluster_complete` before finale handling. Choose one clear behavior and document it in comments.

Recommended: E4 is required in Sector 5 once revealed.

**Step 4: Run tests/manual check**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit
```

Manual: scan E3 in Sector 5 and confirm E4 appears/activates.

**Step 5: Commit**

```bash
git add src/gameplay/star_scan/star_cluster_manager.gd tests/unit/test_star_cluster_manager.gd
git commit -m "feat: reveal mandatory follow-up stars"
```

---

## Task 4: Wire E4 to the existing Mothership encounter

**Objective:** Scanning or activating E4 starts the Mothership fight.

**Files:**

- Modify: `src/gameplay/star_scan/star_cluster_manager.gd`
- Modify or create: `assets/data/waves/sector_5_mothership.json`
- Verify: `src/gameplay/arena/arena_wave_spawner.gd`
- Verify: `scenes/enemies/mothership.tscn`

**Step 1: Create wave data if needed**

Create `assets/data/waves/sector_5_mothership.json`:

```json
{
  "waves": [
    {
      "delay": 0.5,
      "enemies": [
        { "type": "mothership", "count": 1, "position": "center_top" }
      ]
    }
  ]
}
```

Adjust to match the exact existing wave schema used by other files.

**Step 2: Set E4 wave path**

Update Sector 5 E4:

```gdscript
{"id":"E4","result":"mothership","scan_duration":0,"wave_path":"res://assets/data/waves/sector_5_mothership.json","mandatory_after":"E3"}
```

**Step 3: Verify ArenaWaveSpawner mapping**

Confirm this exists:

```gdscript
"mothership": return "res://scenes/enemies/mothership.tscn"
```

If wave position parsing does not support `center_top`, use the existing schema from current wave files.

**Step 4: Run validation/tests**

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit
```

Manual: trigger E4 and confirm arena starts with Mothership.

**Step 5: Commit**

```bash
git add src/gameplay/star_scan/star_cluster_manager.gd assets/data/waves/sector_5_mothership.json
git commit -m "feat: trigger mothership from final star"
```

---

## Task 5: Mark Mothership defeat and trigger true ending

**Objective:** Boss death completes the campaign and shows true ending.

**Files:**

- Modify: `src/gameplay/enemies/mothership.gd`
- Modify: `src/core/game_world.gd`
- Possibly modify: `src/gameplay/enemies/enemy_base.gd`

**Step 1: Inspect death signal path**

Find how normal enemies signal death and how GameWorld reacts. Reuse existing signal/group patterns.

**Step 2: Add or reuse boss death notification**

On Mothership death, call one of:

```gdscript
get_tree().call_group("game_world", "on_mothership_defeated")
```

or emit a typed signal if the arena spawner already surfaces enemy death.

Prefer signal wiring if straightforward; group call is acceptable as a minimal first fix because current code already uses group calls in places.

**Step 3: Add GameWorld handler**

```gdscript
func on_mothership_defeated() -> void:
	GameManager.mark_mothership_defeated()
	_trigger_win(true)
```

Make it idempotent:

```gdscript
if GameManager.is_campaign_complete():
	return
```

or use a `_win_triggered` guard if one exists.

**Step 4: Test/manual verify**

- Kill Mothership.
- Confirm true ending appears once.
- Confirm sector transition/cluster completion does not also trigger standard ending.

**Step 5: Commit**

```bash
git add src/gameplay/enemies/mothership.gd src/core/game_world.gd src/core/game_manager.gd
git commit -m "feat: complete campaign after mothership defeat"
```

---

## Task 6: Update docs to match real ending behavior

**Objective:** Remove mismatch between docs and implementation.

**Files:**

- Modify: `README.md`
- Create or modify: `docs/current-gameplay-state.md`
- Modify any relevant GDD if it contradicts implemented behavior

**Step 1: Create current gameplay state doc**

Document:

- Current run length target.
- Beacon flow.
- Standard vs true ending behavior.
- Mothership trigger.
- Scan durations.
- Audio asset status.

**Step 2: Update README**

Ensure README does not claim missing audio if audio exists, and does not promise a one-hour run if the current target is 35-45 minutes.

**Step 3: Commit**

```bash
git add README.md docs/current-gameplay-state.md design/gdd/*.md
git commit -m "docs: document current campaign ending flow"
```

---

## Final Verification

Run:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit
```

Then manual play/debug path:

1. Start a new run or debug-jump to Sector 5.
2. Collect third beacon from E3.
3. Confirm no immediate win.
4. Confirm E4 appears or activates.
5. Trigger Mothership fight.
6. Defeat Mothership.
7. Confirm true ending.
8. Confirm save/high-score behavior still works.

This plan is complete when the campaign spine is reliable enough to build the rest of the Steam finish roadmap on top of it.
