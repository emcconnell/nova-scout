## DropTable — Probability-weighted loot spawning.
## GDD Ref: enemies.md drop tables, gameplay-mechanics.md §6
class_name DropTable
extends RefCounted

# ─── Drop tables per enemy/hazard type ────────────────────────────────────────
const TABLES := {
	"scout": [
		{"type": "fuel_cell",   "weight": 30},
		{"type": "crystal",     "weight": 20},
		{"type": "nothing",     "weight": 50},
	],
	"warrior": [
		{"type": "missile_pack","weight": 25},
		{"type": "crystal",     "weight": 25},
		{"type": "repair_kit",  "weight": 10},
		{"type": "nothing",     "weight": 40},
	],
	"destroyer": [
		{"type": "repair_kit",  "weight": 50},
		{"type": "crystal",     "weight": 50},
	],
	"elite": [
		{"type": "repair_kit",  "weight": 33},
		{"type": "emp_cartridge","weight": 33},
		{"type": "crystal",     "weight": 34},
	],
	"mothership": [
		{"type": "repair_kit",   "weight": 12},
		{"type": "fuel_cell",    "weight": 12},
		{"type": "emp_cartridge","weight": 12},
		{"type": "crystal",      "weight": 64},
	],
	"shield_drone": [
		{"type": "crystal",     "weight": 60},
		{"type": "nothing",     "weight": 40},
	],
	"asteroid": [
		{"type": "fuel_cell",   "weight": 30},
		{"type": "crystal",     "weight": 20},
		{"type": "nothing",     "weight": 50},
	],
}

# Returns the pickup type to spawn (or "nothing")
static func roll(table_key: String) -> String:
	var table: Array = TABLES.get(table_key, TABLES["scout"])
	var total := 0
	for entry in table:
		total += int(entry["weight"])
	var roll_val := randi_range(0, total - 1)
	var cumulative := 0
	for entry in table:
		cumulative += int(entry["weight"])
		if roll_val < cumulative:
			return entry["type"]
	return "nothing"

# For mothership — multiple guaranteed drops
static func roll_multiple(table_key: String, count: int) -> Array[String]:
	var results: Array[String] = []
	for i in count:
		var r := roll(table_key)
		if r != "nothing":
			results.append(r)
	return results

# For guaranteed loot from wave clear
static func from_loot_list(loot_list: Array) -> Array[String]:
	var results: Array[String] = []
	for entry in loot_list:
		if entry is Dictionary:
			var type: String = entry.get("type", "nothing")
			var count: int = entry.get("count", 1)
			for i in count:
				if type != "nothing":
					results.append(type)
	return results
