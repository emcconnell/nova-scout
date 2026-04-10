## StarClusterManager — Spawns stars for a sector's star cluster phase.
## Manages scan results and transitions (viable planet, alien combat, anomaly).
## GDD Ref: gameplay-mechanics.md §4, level-design.md
class_name StarClusterManager
extends Node

signal cluster_complete()
signal alien_combat_triggered(wave_data_path: String)
signal human_viable_found(sector: int)

# ─── Star configs per sector ──────────────────────────────────────────────────
# Each entry: {type, result, scan_duration}
# result can be "barren", "human_viable", "alien_territory", "anomaly"
# scan_duration reduced: 20-30s was too punishing. 8-12s keeps tension manageable.
const SECTOR_STARS := {
	1: [
		{"id":"A1","result":"barren",        "scan_duration":8, "wave_path":""},
		{"id":"A2","result":"barren",        "scan_duration":8, "wave_path":"","reward":"crystal2"},
		{"id":"A3","result":"barren",        "scan_duration":8, "wave_path":"","reward":"repair_kit","optional":true},
	],
	2: [
		{"id":"B1","result":"barren",        "scan_duration":9, "wave_path":""},
		{"id":"B2","result":"alien_territory","scan_duration":0, "wave_path":"res://assets/data/waves/sector_2_star_b2.json"},
		{"id":"B3","result":"barren",        "scan_duration":9, "wave_path":"","optional":true},
		{"id":"B4","result":"anomaly",       "scan_duration":0, "wave_path":"","optional":true,"hidden":true},
	],
	3: [
		{"id":"G1","result":"barren",        "scan_duration":10,"wave_path":""},
		{"id":"G2","result":"human_viable",  "scan_duration":10,"wave_path":"","guaranteed":true},
		{"id":"G3","result":"alien_territory","scan_duration":0, "wave_path":"res://assets/data/waves/sector_3_star_g3.json","optional":true},
		{"id":"G4","result":"barren",        "scan_duration":10,"wave_path":"","optional":true},
	],
	4: [
		{"id":"D1","result":"alien_territory","scan_duration":0, "wave_path":"res://assets/data/waves/sector_4_star_d1.json"},
		{"id":"D2","result":"human_viable",  "scan_duration":12,"wave_path":"","guaranteed":true},
		{"id":"D3","result":"alien_territory","scan_duration":0, "wave_path":"res://assets/data/waves/sector_4_star_d3.json","optional":true},
		{"id":"D4","result":"anomaly",       "scan_duration":0, "wave_path":"","optional":true},
	],
	5: [
		{"id":"E1","result":"alien_territory","scan_duration":0, "wave_path":"res://assets/data/waves/sector_5_star_e1.json"},
		{"id":"E2","result":"barren",        "scan_duration":12,"wave_path":"","reward":"repair_kit+missile4"},
		{"id":"E3","result":"human_viable",  "scan_duration":12,"wave_path":"res://assets/data/waves/sector_5_star_e3.json","guaranteed":true},
		{"id":"E4","result":"mothership",    "scan_duration":0, "wave_path":"","mandatory_after":"E3"},
	],
}

var _sector: int = 1
var _star_nodes: Array[StarNode] = []
var _stars_cleared: int = 0
var _required_cleared: int = 0

# Injected
var stars_container: Node2D = null
var enemy_container: Node2D = null
var enemy_projectile_container: Node2D = null

const StarNodeScene := preload("res://scenes/star_scan/star_node.tscn")

func setup(sector: int) -> void:
	_sector = sector
	_star_nodes.clear()
	_stars_cleared = 0

func spawn_stars() -> void:
	var configs: Array = SECTOR_STARS.get(_sector, [])
	var vp := get_viewport().get_visible_rect()
	var positions := _compute_positions(configs.size(), vp)
	_required_cleared = 0

	for i in configs.size():
		var cfg: Dictionary = configs[i]
		if cfg.get("hidden", false):
			continue
		var star := StarNodeScene.instantiate() as StarNode
		stars_container.add_child(star)
		star.global_position = positions[i]
		var data := cfg.duplicate()
		data["sector"] = _sector
		star.setup(data)
		star.scan_completed.connect(_on_scan_completed.bind(star, cfg))
		star.scan_aborted.connect(_on_scan_aborted)
		_star_nodes.append(star)
		if not cfg.get("optional", false):
			_required_cleared += 1

func _compute_positions(count: int, vp: Rect2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var cx := vp.size.x * 0.5
	var cy := vp.size.y * 0.4
	var spread_x := vp.size.x * 0.35
	var spread_y := vp.size.y * 0.20
	for i in count:
		var angle := TAU / maxf(count, 1) * i - PI / 2.0
		positions.append(Vector2(
			cx + cos(angle) * spread_x,
			cy + sin(angle) * spread_y
		))
	return positions

func _on_scan_completed(result: String, star_data: Dictionary, _star: StarNode, _cfg: Dictionary) -> void:
	_stars_cleared += 1
	match result:
		"human_viable":
			GameManager.collect_beacon()
			human_viable_found.emit(_sector)
			AudioManager.play_sfx("beacon_collected")
		"alien_territory", "mothership":
			var wave_path: String = star_data.get("wave_path", "")
			if not wave_path.is_empty():
				alien_combat_triggered.emit(wave_path)
		"anomaly":
			_handle_anomaly(star_data)
		"barren":
			_spawn_scan_reward(star_data.get("reward", ""))

	if _stars_cleared >= _required_cleared:
		cluster_complete.emit()

func is_complete() -> bool:
	return _stars_cleared >= _required_cleared

func _on_scan_aborted() -> void:
	pass  # Player aborted — no consequence

func _handle_anomaly(data: Dictionary) -> void:
	# Loot room — spawn generous pickups
	get_tree().call_group("game_world", "spawn_anomaly_loot", data.get("id", ""))

func _spawn_scan_reward(reward: String) -> void:
	if reward.is_empty():
		return
	get_tree().call_group("game_world", "spawn_scan_reward", reward)
