## ArenaWaveSpawner — Loads wave data, spawns enemies in sequence.
## Used during alien combat mode (post alien-territory scan).
## GDD Ref: gameplay-mechanics.md §5 — Alien Combat Mode
class_name ArenaWaveSpawner
extends Node

signal wave_started(wave_num: int, total: int)
signal wave_cleared(wave_num: int, loot: Array)
signal all_waves_cleared()
signal escape_available()

# ─── Constants ───────────────────────────────────────────────────────────────
const BETWEEN_WAVE_PAUSE := 5.0
const ESCAPE_HOLD_TIME   := 4.0

# ─── State ───────────────────────────────────────────────────────────────────
var _waves: Array = []
var _current_wave: int = 0
var _wave_timer: float = 0.0
var _between_waves: bool = false
var _enemies_alive: int = 0
var _active: bool = false
var _is_boss_wave: bool = false

# Escape warp
var _escape_held: float = 0.0
var _escape_available: bool = false
var _escape_blocked: bool = false

# Injected
var enemy_container: Node2D = null
var enemy_projectile_container: Node2D = null
var spawn_offset: Vector2 = Vector2.ZERO

func start(wave_data_path: String) -> void:
	_load_waves(wave_data_path)
	_current_wave = 0
	_active = true
	_escape_blocked = false
	_enemies_alive = 0
	_start_next_wave()

func stop() -> void:
	_active = false

func _process(delta: float) -> void:
	if not _active:
		return

	if _between_waves:
		_wave_timer -= delta
		if _wave_timer <= 0.0:
			_between_waves = false
			_start_next_wave()
		return

	# Check if wave cleared
	if _enemies_alive <= 0 and _current_wave <= _waves.size():
		_on_wave_cleared()
		return

	# Escape warp input (not during boss)
	if not _escape_blocked:
		if Input.is_action_pressed("interact"):
			_escape_held += delta
			if _escape_held >= ESCAPE_HOLD_TIME:
				_try_escape()
		else:
			_escape_held = 0.0

func _start_next_wave() -> void:
	if _current_wave >= _waves.size():
		all_waves_cleared.emit()
		_active = false
		return

	var wave_data: Dictionary = _waves[_current_wave]
	_is_boss_wave = wave_data.get("is_boss", false)
	_escape_blocked = _is_boss_wave
	_enemies_alive = 0

	var enemies_list: Array = wave_data.get("enemies", [])
	for group in enemies_list:
		var type: String = group.get("type", "scout")
		var count: int = group.get("count", 1)
		for i in count:
			_spawn_enemy(type, i, count)
			_enemies_alive += 1

	wave_started.emit(_current_wave + 1, _waves.size())

func _on_wave_cleared() -> void:
	var loot: Array = _waves[_current_wave].get("loot", [])
	wave_cleared.emit(_current_wave + 1, loot)
	_current_wave += 1

	if _current_wave >= _waves.size():
		all_waves_cleared.emit()
		_active = false
	else:
		_between_waves = true
		_wave_timer = BETWEEN_WAVE_PAUSE
		# Drop loot from cleared wave
		get_tree().call_group("game_world", "spawn_loot_wave", loot,
			get_viewport().get_visible_rect().size * 0.5)
		AudioManager.play_sfx("wave_clear")

func _spawn_enemy(type: String, index: int, total: int) -> void:
	if enemy_container == null:
		return
	var scene_path := _get_scene_path(type)
	if scene_path.is_empty():
		return

	var scene := load(scene_path) as PackedScene
	if scene == null:
		return

	var enemy := scene.instantiate() as EnemyBase
	enemy_container.add_child(enemy)
	enemy.enemy_projectile_container = enemy_projectile_container
	enemy.died.connect(_on_enemy_died)

	# Spread spawns horizontally
	var vp := get_viewport().get_visible_rect()
	var spacing: float = vp.size.x / maxi(total + 1, 2)
	enemy.global_position = Vector2(spacing * (index + 1), -25) + spawn_offset

func _on_enemy_died(_pos: Vector2, _drop: String) -> void:
	_enemies_alive = max(_enemies_alive - 1, 0)

func _try_escape() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.fuel_sys.fuel >= 20:
		player.fuel_sys.drain(20.0)
		get_tree().call_group("game_world", "exit_arena_escape")
	_active = false

func _load_waves(path: String) -> void:
	_waves.clear()
	if not FileAccess.file_exists(path):
		push_warning("ArenaWaveSpawner: no wave data at %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary and data.has("waves"):
		for w in data["waves"]:
			if w is Dictionary:
				_waves.append(w)

func _get_scene_path(type: String) -> String:
	match type:
		"scout":              return "res://scenes/enemies/alien_scout.tscn"
		"warrior":            return "res://scenes/enemies/alien_warrior.tscn"
		"destroyer":          return "res://scenes/enemies/alien_destroyer.tscn"
		"elite_interceptor":  return "res://scenes/enemies/alien_elite_interceptor.tscn"
		"elite_artillery":    return "res://scenes/enemies/alien_elite_artillery.tscn"
		"elite_swarm_commander": return "res://scenes/enemies/alien_elite_swarm_commander.tscn"
		"mothership":         return "res://scenes/enemies/mothership.tscn"
	push_warning("ArenaWaveSpawner: unknown enemy type '%s'" % type)
	return ""

func get_escape_progress() -> float:
	return _escape_held / ESCAPE_HOLD_TIME
