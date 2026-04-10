## EncounterManager — Tracks world distance, fires scripted sector encounters.
## Loaded and started by GameWorld. Each sector has its own encounter JSON.
## GDD Ref: gameplay-mechanics.md §3, level-design.md
class_name EncounterManager
extends Node

# ─── Signals ─────────────────────────────────────────────────────────────────
signal encounter_triggered(encounter: Dictionary)
signal sector_complete()

# ─── Constants ───────────────────────────────────────────────────────────────
const SCROLL_SPEED  := 40.0      # px/sec virtual distance rate
const SECTOR_LENGTH := 6000.0    # ~2.5 min per sector (150s × 40)

# ─── State ───────────────────────────────────────────────────────────────────
var distance_traveled: float = 0.0
var scroll_speed: float = SCROLL_SPEED   # Can be doubled by boost
var _encounters: Array = []
var _next_idx: int = 0
var _active: bool = false
var _sector: int = 1

func start(sector: int) -> void:
	_sector = sector
	distance_traveled = 0.0
	_next_idx = 0
	_active = true
	_load_encounters(sector)

func stop() -> void:
	_active = false

func _process(delta: float) -> void:
	if not _active:
		return
	distance_traveled += scroll_speed * delta
	# Score trickle — reward the player for surviving (Change 7a)
	GameManager.add_score(int(scroll_speed * delta * 0.05))

	# Fire triggered encounters in order
	while _next_idx < _encounters.size():
		var enc: Dictionary = _encounters[_next_idx]
		if distance_traveled >= float(enc.get("distance", 999999)):
			encounter_triggered.emit(enc)
			_next_idx += 1
		else:
			break

	# Sector complete when all encounters have fired.
	# Guard: if stop() was called by a signal handler above (e.g. star_cluster
	# encounter), _active is already false — skip to avoid double-trigger.
	if _next_idx >= _encounters.size() and _encounters.size() > 0 and _active:
		_active = false
		sector_complete.emit()

func _load_encounters(sector: int) -> void:
	_encounters.clear()
	var path := "res://assets/data/encounters/sector_%d.json" % sector
	if not FileAccess.file_exists(path):
		push_warning("EncounterManager: no data for sector %d at %s" % [sector, path])
		# Fallback: emit sector_complete after a short distance
		_encounters = [{"distance": SECTOR_LENGTH, "type": "star_cluster", "params": {}}]
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary and data.has("encounters"):
		for entry in data["encounters"]:
			if entry is Dictionary:
				_encounters.append(entry)
		_encounters.sort_custom(func(a, b): return a["distance"] < b["distance"])
