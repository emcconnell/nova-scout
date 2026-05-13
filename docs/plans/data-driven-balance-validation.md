# Data-Driven Balance and Validation Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Move high-iteration balance values into data files and add validation so Steam-release tuning is fast, safe, and reproducible.

**Architecture:** Build a small `BalanceDB` loader with safe defaults, migrate one gameplay domain at a time, and add a data validation script before large migrations. Do not migrate all constants in one change.

**Tech Stack:** Godot 4, GDScript, JSON, Python validation script, GUT tests.

---

## Target Data Layout

```text
assets/data/balance/player.json
assets/data/balance/weapons.json
assets/data/balance/hazards.json
assets/data/balance/enemies.json
assets/data/balance/upgrades.json
assets/data/balance/drops.json
assets/data/star_clusters/sector_1.json
assets/data/star_clusters/sector_2.json
assets/data/star_clusters/sector_3.json
assets/data/star_clusters/sector_4.json
assets/data/star_clusters/sector_5.json
scripts/validate_data.py
scripts/verify.sh
```

Keep script constants only for implementation details that are not balance decisions.

---

## Task 1: Add `scripts/verify.sh`

**Objective:** Create one command for local validation.

**Files:**

- Create: `scripts/verify.sh`

**Content:**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if command -v python3 >/dev/null 2>&1; then
  python3 scripts/validate_data.py
fi

if command -v godot >/dev/null 2>&1; then
  godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit
else
  echo "godot not found; skipped GUT tests"
fi
```

**Verification:**

```bash
chmod +x scripts/verify.sh
./scripts/verify.sh
```

Expected: validator runs; tests run if Godot CLI exists; otherwise skip message.

---

## Task 2: Add initial data validator

**Objective:** Catch bad JSON and progression-critical data mistakes.

**Files:**

- Create: `scripts/validate_data.py`

**Validation rules:**

- All `assets/data/**/*.json` parse.
- Encounter distances are increasing per sector file.
- Each sector encounter file ends in or includes a `star_cluster` encounter.
- Encounter types are in an allowlist matching `GameWorld._handle_encounter()`.
- Wave files referenced by star configs exist.
- Enemy types in wave files are in an allowlist matching `ArenaWaveSpawner`.
- Star result types are known.
- `mandatory_after` is only allowed if code supports it.
- Drop weights are positive.

**Verification:**

```bash
python3 scripts/validate_data.py
```

Expected: exits 0 with “data validation passed” or prints actionable file/field errors.

---

## Task 3: Add `BalanceDB` loader with fallbacks

**Objective:** Centralize balance loading without breaking existing gameplay.

**Files:**

- Create: `src/core/balance_db.gd`
- Modify: `project.godot` autoloads if BalanceDB should be global
- Test: `tests/unit/test_balance_db.gd`

**API sketch:**

```gdscript
class_name BalanceDB
extends Node

var _data: Dictionary = {}

func load_all() -> void:
	_load_json("player", "res://assets/data/balance/player.json")
	_load_json("weapons", "res://assets/data/balance/weapons.json")
	_load_json("upgrades", "res://assets/data/balance/upgrades.json")
	_load_json("drops", "res://assets/data/balance/drops.json")

func get_value(domain: String, path: String, default_value: Variant) -> Variant:
	var cursor: Variant = _data.get(domain, {})
	for part in path.split("."):
		if typeof(cursor) != TYPE_DICTIONARY or not cursor.has(part):
			return default_value
		cursor = cursor[part]
	return cursor
```

**Verification:**

- Missing file does not crash.
- Missing key returns provided default.
- Valid key returns JSON value.

---

## Task 4: Migrate upgrade costs/effects first

**Objective:** Move one low-risk, high-value domain to JSON.

**Files:**

- Create: `assets/data/balance/upgrades.json`
- Modify: `src/core/game_manager.gd`
- Test: `tests/unit/test_game_manager.gd`

**Example JSON:**

```json
{
  "hull": { "base_cost": 3, "cost_scale": 2, "max_level": 5, "effect_per_level": 20 },
  "fuel": { "base_cost": 2, "cost_scale": 2, "max_level": 5, "effect_per_level": 15 },
  "shield_regen": { "base_cost": 4, "cost_scale": 2, "max_level": 5, "effect_per_level": 0.25 },
  "missiles": { "base_cost": 2, "cost_scale": 1, "max_level": 5, "effect_per_level": 2 },
  "laser_damage": { "base_cost": 4, "cost_scale": 3, "max_level": 4, "effect_per_level": 2 }
}
```

**Verification:**

- Existing upgrade behavior remains equivalent unless deliberately tuned.
- Invalid upgrade key fails safely.
- Tests cover cost, caps, and stat changes.

---

## Task 5: Migrate drop tables

**Objective:** Make economy tuning data-driven.

**Files:**

- Create: `assets/data/balance/drops.json`
- Modify: `src/gameplay/pickups/drop_table.gd`
- Test: `tests/unit/test_drop_table.gd`

**Rules:**

- Weights must be positive.
- Empty or missing table returns no drop safely.
- Deterministic test path should be possible by injecting RNG or testing normalized table math.

**Verification:**

- Validator catches malformed weights.
- Existing enemies still drop expected categories.

---

## Task 6: Migrate weapons/player/hazards/enemies in separate PR-sized tasks

**Objective:** Avoid risky all-at-once tuning migration.

**Order:**

1. `assets/data/balance/player.json`
2. `assets/data/balance/weapons.json`
3. `assets/data/balance/hazards.json`
4. `assets/data/balance/enemies.json`

**Per-domain steps:**

1. Create JSON mirroring current constants.
2. Add loader calls with current constants as defaults.
3. Add tests for at least one value and missing-key fallback.
4. Run `./scripts/verify.sh`.
5. Manual smoke test affected mechanics.

---

## Task 7: Migrate star cluster configs last

**Objective:** Move star configs to data only after `mandatory_after` and finale behavior are fixed.

**Files:**

- Create: `assets/data/star_clusters/sector_1.json` through `sector_5.json`
- Modify: `src/gameplay/star_scan/star_cluster_manager.gd`
- Modify: `scripts/validate_data.py`

**Rules:**

- Star ids unique within a sector.
- `mandatory_after` references an existing id.
- Result type in allowlist.
- Referenced wave paths exist.
- Required/optional/hidden behavior is explicit.

**Verification:**

- All sectors spawn same stars as before migration.
- Sector 5 Mothership flow still works.

---

## Task 8: Add hardcoded-balance audit

**Objective:** Keep future code from reintroducing tuning sprawl.

**Files:**

- Modify: `scripts/verify.sh`
- Optionally create: `scripts/check_balance_constants.py`

**Simple first rule:**

Print warnings for suspicious constants in gameplay scripts:

- `DAMAGE`
- `SPEED`
- `RATE`
- `COST`
- `HP`
- `INTERVAL`

Do not fail initially. Promote to fail only after migration is mostly complete.

---

## Final Verification

Run:

```bash
./scripts/verify.sh
```

Manual smoke tests:

- Upgrade screen works.
- Enemy drops work.
- Player movement/fuel/weapons work.
- Mines/enemies keep current behavior unless tuned.
- All five sector star clusters spawn correctly.
- Sector 5 Mothership flow remains intact.
