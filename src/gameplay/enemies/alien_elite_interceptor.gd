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

const COL_HULL  := Color(0.50, 0.00, 0.70)
const COL_BLINK := Color(1.00, 0.80, 0.00, 0.8)
const COL_GLOW  := Color(0.90, 0.20, 1.00, 0.6)
const COL_TRAIL := Color(0.80, 0.60, 1.00, 0.4)

var _fire_timer: float = 0.8
var _blink_timer: float = BLINK_INTERVAL
var _blink_flash: float = 0.0
var _wobble: float = 0.0
var _target_pos: Vector2 = Vector2.ZERO
var _moving: bool = true
var hp_scale: float = 1.0  # For scaled encounters

func _ready() -> void:
	super()
	hp = int(350 * hp_scale)
	max_hp = hp
	contact_damage = 25
	score_value = 1500
	drop_table = "elite"

func _update(delta: float) -> void:
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
		_fire_timer = FIRE_INTERVAL
		var spread := TAU / SPREAD_SHOTS
		for i in SPREAD_SHOTS:
			var angle := _aim_at_player().angle() + (i - SPREAD_SHOTS / 2) * spread * 0.3
			_fire_bolt(Vector2.from_angle(angle), BOLT_DAMAGE, BOLT_SPEED, "scout")
		AudioManager.play_sfx("enemy_laser")

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0 or _blink_flash > 0.0
	var hull  := Color(1,1,1) if flash else COL_HULL
	# Arrowhead body
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -14), Vector2(10, 6), Vector2(0, 2), Vector2(-10, 6)
	]), hull)
	# Wing tips
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, 6), Vector2(-18, 10), Vector2(-12, 12), Vector2(-8, 8)
	]), hull)
	draw_colored_polygon(PackedVector2Array([
		Vector2(10, 6), Vector2(18, 10), Vector2(12, 12), Vector2(8, 8)
	]), hull)
	# Glow core
	var pulse: float = 0.5 + 0.5 * abs(sin(_wobble))
	draw_circle(Vector2(0, -2), 4.0, Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, pulse))
	# Blink flash
	if _blink_flash > 0.0:
		draw_circle(Vector2.ZERO, 16.0, Color(COL_BLINK.r, COL_BLINK.g, COL_BLINK.b, _blink_flash * 5.0))
	if _stunned:
		draw_circle(Vector2(0, -16), 2.5, Color(0, 1, 1, 0.9))
