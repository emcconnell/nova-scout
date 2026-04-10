## AlienEliteSwarmCommander — Spawns scouts, fires homing missiles.
## GDD Ref: enemies.md — Tier 4 Elite Variant C
class_name AlienEliteSwarmCommander
extends EnemyBase

const BASE_SPEED       := 80.0
const SPAWN_INTERVAL   := 8.0
const MAX_SPAWNS       := 8
const MISSILE_INTERVAL := 4.0
const MISSILE_SPEED    := 180.0
const MISSILE_DAMAGE   := 40

const COL_HULL  := Color(0.45, 0.00, 0.60)
const COL_PORT  := Color(0.80, 0.00, 1.00, 0.7)
const COL_GLOW  := Color(0.60, 0.00, 0.90, 0.5)

var _spawn_timer: float = 5.0
var _missile_timer: float = 2.0
var _scouts_spawned: int = 0
var _wobble: float = 0.0
var _phase: float = 0.0
var hp_scale: float = 1.0

func _ready() -> void:
	super()
	hp = int(280 * hp_scale)
	max_hp = hp
	contact_damage = 25
	score_value = 1500
	drop_table = "elite"

func _update(delta: float) -> void:
	if _stunned:
		return
	_wobble += delta * 3.0
	_phase += delta

	var vp := get_viewport_rect()
	if global_position.y < 50.0:
		global_position.y += BASE_SPEED * delta
		return

	# Figure-8 patrol
	global_position.x = vp.size.x * 0.5 + cos(_phase * 0.5) * (vp.size.x * 0.35)
	global_position.y = 50.0 + abs(sin(_phase * 0.5)) * 30.0

	# Scout spawning
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _scouts_spawned < MAX_SPAWNS:
		_spawn_timer = SPAWN_INTERVAL
		_scouts_spawned += 2
		get_tree().call_group("game_world", "spawn_enemy_at",
			"scout", global_position + Vector2(-15, 15))
		get_tree().call_group("game_world", "spawn_enemy_at",
			"scout", global_position + Vector2(15, 15))
		AudioManager.play_sfx("enemy_spawn")

	# Homing missile fire
	_missile_timer -= delta
	if _missile_timer <= 0.0:
		_missile_timer = _scaled_interval(MISSILE_INTERVAL)
		_fire_homing_missile()

func _fire_homing_missile() -> void:
	if enemy_projectile_container == null:
		return
	var m := preload("res://scenes/projectiles/enemy_missile.tscn").instantiate() as Node2D
	enemy_projectile_container.add_child(m)
	m.global_position = global_position + Vector2(0, 15)
	var target := _get_player()
	if m.has_method("setup"):
		m.setup(MISSILE_DAMAGE, target, MISSILE_SPEED)

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var hull  := Color(1,1,1) if flash else COL_HULL
	# Central command pod
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -10), Vector2(12, -10),
		Vector2(14, 8), Vector2(-14, 8)
	]), hull)
	# Spawn bays (two ports)
	draw_rect(Rect2(-18, 0, 6, 10), hull)
	draw_rect(Rect2(12, 0, 6, 10), hull)
	var port_a: float = 0.5 + 0.5 * abs(sin(_wobble * 2.0))
	draw_circle(Vector2(-15, 8), 3.0, Color(COL_PORT.r, COL_PORT.g, COL_PORT.b, port_a))
	draw_circle(Vector2(15, 8), 3.0, Color(COL_PORT.r, COL_PORT.g, COL_PORT.b, port_a))
	# Central glow
	var ga := 0.4 + 0.4 * sin(_wobble)
	draw_circle(Vector2(0, 0), 5.0, Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, ga))
	if _stunned:
		draw_circle(Vector2(0, -12), 2.5, Color(0, 1, 1, 0.9))
