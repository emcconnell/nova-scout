## AlienEliteInterceptor — Mini-boss. Teleport-blink, aimed spread fire.
## GDD Ref: enemies.md — Tier 4 Elite Variant A
class_name AlienEliteInterceptor
extends EnemyBase

const BASE_SPEED    := 220.0
const BLINK_INTERVAL := 2.5
const BLINK_DIST     := 60.0
const FIRE_INTERVAL  := 1.0
const SPREAD_SHOTS   := 5
const BOLT_DAMAGE    := 12
const BOLT_SPEED     := 240.0

const COL_BLINK := Color(1.00, 0.80, 0.00, 0.8)
const COL_TRAIL := Color(0.80, 0.60, 1.00, 0.4)

var _fire_timer: float = 0.8
var _blink_timer: float = BLINK_INTERVAL
var _blink_flash: float = 0.0
var _wobble: float = 0.0
var _target_pos: Vector2 = Vector2.ZERO
var _moving: bool = true
var hp_scale: float = 1.0  # For scaled encounters
var _eye_dots: Array = []             # seeded eye cluster (dead frequency)
var _body: Sprite2D = null            # textured hull (art bible v4.0)

func _ready() -> void:
	super()
	hp = int(350 * hp_scale)
	max_hp = hp
	contact_damage = 25
	score_value = 1500
	drop_table = "elite"
	_body = TextureKit.creature_body(self, "enemies", "elite_interceptor")
	_eye_dots = [
		Vector3(-4, -4, 1.2), Vector3(4, -4, 1.2), Vector3(0, -8, 1.5),
		Vector3(-8, 2, 0.8), Vector3(8, 2, 0.8),
	]

func _update(delta: float) -> void:
	TextureKit.set_flash(_body, 1.0 if _hit_flash_timer > 0.0 else 0.0)
	if _stunned:
		return
	_wobble += delta * 6.0
	if _blink_flash > 0.0:
		_blink_flash -= delta

	var vp := get_viewport_rect()

	# Entry
	if global_position.y < 40.0:
		global_position.y += BASE_SPEED * 0.6 * delta
		return

	# Move toward target
	if _moving:
		if _target_pos == Vector2.ZERO:
			_target_pos = Vector2(randf_range(30, vp.size.x - 30), randf_range(20, 80))
		var dir := (_target_pos - global_position)
		if dir.length() < 5.0:
			_moving = false
			_target_pos = Vector2.ZERO
		else:
			global_position += dir.normalized() * BASE_SPEED * delta

	# Blink teleport
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = BLINK_INTERVAL + randf_range(-0.5, 0.5)
		_blink_flash = 0.15
		var angle := randf_range(0, TAU)
		global_position += Vector2(cos(angle), sin(angle)) * BLINK_DIST
		global_position.x = clampf(global_position.x, 15, vp.size.x - 15)
		global_position.y = clampf(global_position.y, 15, vp.size.y * 0.6)
		_moving = true
		AudioManager.play_sfx("elite_blink")

	# Spread fire
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = _scaled_interval(FIRE_INTERVAL)
		var spread := TAU / SPREAD_SHOTS
		for i in SPREAD_SHOTS:
			var angle := _aim_at_player().angle() + (i - SPREAD_SHOTS / 2) * spread * 0.3
			_fire_bolt(Vector2.from_angle(angle), BOLT_DAMAGE, BOLT_SPEED, "scout")
		AudioManager.play_sfx("enemy_laser")

func _draw() -> void:
	var lit := _lit_factor()
	var blend := VisualState.blend()

	EnemyRenderer.under_halo(self, Vector2(0, 4), 20.0)

	# Glow core — magenta in SURVEY, dies with blend
	var pulse: float = 0.5 + 0.5 * abs(sin(_wobble))
	var core_col := VisualState.col(Color("B03BFF"), Color("7A0E12"))
	DrawKit.glow(self, Vector2(0, -2), 4.0, Color(core_col.r, core_col.g, core_col.b, pulse * (1.0 - blend * 0.5)), 3)

	# Eye cluster wakes in dead frequency
	EnemyRenderer.eye_cluster(self, _eye_dots, lit, [0, 2])

	if lit > 0.01:
		var rim_pts := PackedVector2Array([Vector2(0, -14), Vector2(-10, 6), Vector2(-18, 10)])
		EnemyRenderer.lit_rim_stroke(self, rim_pts, lit)

	# Blink flash — kept as a bright teleport tell
	if _blink_flash > 0.0:
		draw_circle(Vector2.ZERO, 16.0, Color(COL_BLINK.r, COL_BLINK.g, COL_BLINK.b, _blink_flash * 5.0))
	if _stunned:
		draw_circle(Vector2(0, -16), 2.5, Color(0, 1, 1, 0.9))
	_draw_hit_flash()
