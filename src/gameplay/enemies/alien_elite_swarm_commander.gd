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

const COL_PORT  := Color(0.80, 0.00, 1.00, 0.7)

var _spawn_timer: float = 5.0
var _missile_timer: float = 2.0
var _scouts_spawned: int = 0
var _wobble: float = 0.0
var _phase: float = 0.0
var hp_scale: float = 1.0
var _eye_dots: Array = []             # seeded eye cluster (dead frequency)
var _body: Sprite2D = null            # textured hull (art bible v4.0)

func _ready() -> void:
	super()
	hp = int(280 * hp_scale)
	max_hp = hp
	contact_damage = 25
	score_value = 1500
	drop_table = "elite"
	_body = TextureKit.creature_body(self, "enemies", "elite_swarm")
	_eye_dots = [
		Vector3(-6, -6, 1.2), Vector3(6, -6, 1.2), Vector3(0, -8, 1.5),
		Vector3(-10, -2, 0.8), Vector3(10, -2, 0.8),
	]

func _update(delta: float) -> void:
	TextureKit.set_flash(_body, 1.0 if _hit_flash_timer > 0.0 else 0.0)
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
	var lit := _lit_factor()
	var blend := VisualState.blend()
	var lo := EnemyRenderer.body_stop(2, lit)

	EnemyRenderer.under_halo(self, Vector2(0, 2), 22.0)

	# Spawn bay glows — hatch bays baked into the body texture
	var port_a: float = (0.5 + 0.5 * abs(sin(_wobble * 2.0))) * (1.0 - blend * 0.5)
	draw_circle(Vector2(-15, 8), 3.0, Color(COL_PORT.r, COL_PORT.g, COL_PORT.b, port_a))
	draw_circle(Vector2(15, 8), 3.0, Color(COL_PORT.r, COL_PORT.g, COL_PORT.b, port_a))

	# Central glow — magenta dies to embers with blend
	var ga := 0.4 + 0.4 * sin(_wobble)
	DrawKit.glow(self, Vector2(0, 0), 5.0, Color(lo.r + 0.3, lo.g + 0.1, lo.b + 0.3, ga * (1.0 - blend * 0.4)), 3)

	EnemyRenderer.eye_cluster(self, _eye_dots, lit, [0, 1])
	EnemyRenderer.dead_vein_line(self, Vector2(-14, 6), Vector2(14, 6))
	if lit > 0.01:
		var rim_pts := PackedVector2Array([Vector2(-12, -10), Vector2(-14, 8)])
		EnemyRenderer.lit_rim_stroke(self, rim_pts, lit)

	if _stunned:
		draw_circle(Vector2(0, -12), 2.5, Color(0, 1, 1, 0.9))
	_draw_hit_flash()
