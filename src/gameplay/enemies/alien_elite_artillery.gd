## AlienEliteArtillery — Stationary at top. Fires precise aimed volley of 6.
## GDD Ref: enemies.md — Tier 4 Elite Variant B
class_name AlienEliteArtillery
extends EnemyBase

const VOLLEY_INTERVAL := 3.0
const VOLLEY_SIZE     := 6
const SHOT_DELAY      := 0.10
const BOLT_DAMAGE     := 14
const BOLT_SPEED      := 260.0
const TRACK_SPEED     := 80.0   # Slow horizontal tracking

const COL_CHARGE  := Color(1.00, 0.90, 0.00, 0.8)

var _volley_timer: float = 1.5
var _shot_queue: int = 0
var _shot_timer: float = 0.0
var _charge_anim: float = 0.0
var _charging: bool = false
var _wobble: float = 0.0
var hp_scale: float = 1.0
var _flecks: Array[Vector3] = []      # seeded chitin flecks (TURN 4)
var _eye_dots: Array = []             # seeded eye cluster (dead frequency)

func _ready() -> void:
	super()
	hp = int(500 * hp_scale)
	max_hp = hp
	contact_damage = 30
	score_value = 1500
	drop_table = "elite"
	_flecks = EnemyRenderer.seed_flecks(get_instance_id(), 36, Vector2(17, 8))
	_eye_dots = [
		Vector3(-10, -6, 1.2), Vector3(10, -6, 1.2), Vector3(-4, -7, 0.9),
		Vector3(4, -7, 0.9), Vector3(0, -5, 1.6),
	]

func _update(delta: float) -> void:
	if _stunned:
		return
	_wobble += delta * 2.0

	var vp := get_viewport_rect()
	# Entry: drop to fixed y-position
	if global_position.y < 30.0:
		global_position.y += 80.0 * delta
		return

	# Slow horizontal tracking toward player x
	var player := _get_player()
	if player:
		var dx := player.global_position.x - global_position.x
		global_position.x += sign(dx) * minf(abs(dx), TRACK_SPEED * delta)
	global_position.x = clampf(global_position.x, 20, vp.size.x - 20)

	# Charge up before volley
	if _charging:
		_charge_anim += delta * 4.0
		_shot_timer -= delta
		if _shot_timer <= 0.0 and _shot_queue > 0:
			_shot_timer = SHOT_DELAY
			_shot_queue -= 1
			# Aim precisely at player
			_fire_bolt(_aim_at_player(), BOLT_DAMAGE, BOLT_SPEED, "warrior")
			AudioManager.play_sfx("enemy_laser")
		if _shot_queue <= 0:
			_charging = false
			_charge_anim = 0.0
	else:
		_volley_timer -= delta
		if _volley_timer <= 0.0:
			_volley_timer = _scaled_interval(VOLLEY_INTERVAL)
			_charging = true
			_shot_queue = VOLLEY_SIZE
			_shot_timer = 0.0

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var lit := _lit_factor()
	var hi := EnemyRenderer.body_stop(0, lit)
	var mid := EnemyRenderer.body_stop(1, lit)
	var hull := hi if not flash else Color(1, 1, 1)
	var barrel_col := mid if not flash else Color(1, 1, 1)

	EnemyRenderer.under_halo(self, Vector2(0, 4), 24.0)

	# Wide flat body — fortress shape (silhouette unchanged)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -8), Vector2(18, -8),
		Vector2(16, 10), Vector2(-16, 10)
	]), hull)

	# Plate ridge across the front face
	EnemyRenderer.plate_ridge_line(self,
		PackedVector2Array([Vector2(-16, 0), Vector2(0, -3), Vector2(16, 0)]),
		PackedVector2Array([Vector2(-16, -1.4), Vector2(0, -4.4), Vector2(16, -1.4)]), lit)
	EnemyRenderer.draw_flecks(self, _flecks, lit)

	# Barrel array (6 barrels) — silhouette unchanged
	for i in 6:
		var bx := -12.5 + i * 5.0
		draw_rect(Rect2(bx - 1, 8, 2, 8), barrel_col)
	# Charge glow
	if _charging:
		var ga: float = 0.3 + 0.7 * abs(sin(_charge_anim))
		for i in 6:
			var bx := -12.5 + i * 5.0
			draw_circle(Vector2(bx, 16), 2.0, Color(COL_CHARGE.r, COL_CHARGE.g, COL_CHARGE.b, ga))
	# Side struts
	draw_rect(Rect2(-20, -4, 4, 12), hull)
	draw_rect(Rect2(16, -4, 4, 12), hull)

	# Eye cluster wakes on the fortress face in dead frequency
	EnemyRenderer.eye_cluster(self, _eye_dots, lit, [0, 1])
	EnemyRenderer.dead_vein_line(self, Vector2(-16, 6), Vector2(16, 6))
	if lit > 0.01:
		var rim_pts := PackedVector2Array([Vector2(-18, -8), Vector2(-16, 10)])
		EnemyRenderer.lit_rim_stroke(self, rim_pts, lit)

	if _stunned:
		draw_circle(Vector2(0, -10), 2.5, Color(0, 1, 1, 0.9))
	_draw_hit_flash()
