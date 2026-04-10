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

const COL_HULL    := Color(0.30, 0.00, 0.50)
const COL_BARREL  := Color(0.55, 0.00, 0.80)
const COL_CHARGE  := Color(1.00, 0.90, 0.00, 0.8)

var _volley_timer: float = 1.5
var _shot_queue: int = 0
var _shot_timer: float = 0.0
var _charge_anim: float = 0.0
var _charging: bool = false
var _wobble: float = 0.0
var hp_scale: float = 1.0

func _ready() -> void:
	super()
	hp = int(500 * hp_scale)
	max_hp = hp
	contact_damage = 30
	score_value = 1500
	drop_table = "elite"

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
			_volley_timer = VOLLEY_INTERVAL
			_charging = true
			_shot_queue = VOLLEY_SIZE
			_shot_timer = 0.0

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var hull  := Color(1,1,1) if flash else COL_HULL
	# Wide flat body — fortress shape
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -8), Vector2(18, -8),
		Vector2(16, 10), Vector2(-16, 10)
	]), hull)
	# Barrel array (6 barrels)
	for i in 6:
		var bx := -12.5 + i * 5.0
		draw_rect(Rect2(bx - 1, 8, 2, 8), COL_BARREL)
	# Charge glow
	if _charging:
		var ga: float = 0.3 + 0.7 * abs(sin(_charge_anim))
		for i in 6:
			var bx := -12.5 + i * 5.0
			draw_circle(Vector2(bx, 16), 2.0, Color(COL_CHARGE.r, COL_CHARGE.g, COL_CHARGE.b, ga))
	# Side struts
	draw_rect(Rect2(-20, -4, 4, 12), hull)
	draw_rect(Rect2(16, -4, 4, 12), hull)
	if _stunned:
		draw_circle(Vector2(0, -10), 2.5, Color(0, 1, 1, 0.9))
