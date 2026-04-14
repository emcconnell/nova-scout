## AlienScout — Fast, erratic saucer. Sine-wave horizontal drift.
## Fires single aimed bolts every 1.5s. Retreats briefly when hit.
## GDD Ref: enemies.md — Tier 1 Alien Scout
class_name AlienScout
extends EnemyBase

# ─── Stats (from enemies.md) ─────────────────────────────────────────────────
const BASE_SPEED    := 200.0
const FIRE_INTERVAL := 1.5
const RETREAT_SPEED := 250.0
const RETREAT_TIME  := 0.6
const SINE_FREQ     := 3.5
const SINE_AMP      := 38.0
const BOLT_DAMAGE   := 8
const BOLT_SPEED    := 220.0

# ─── Colors (art bible) ──────────────────────────────────────────────────────
const COL_HULL  := Color(0.30, 0.00, 0.50)
const COL_GLOW  := Color(1.00, 0.10, 0.80)
const COL_EYE   := Color(1.00, 0.20, 0.20)
const COL_RING  := Color(0.80, 0.00, 1.00, 0.55)

# ─── State ───────────────────────────────────────────────────────────────────
var _fire_timer: float = 0.8   # Stagger initial shot
var _sine_phase: float = 0.0
var _entry_done: bool = false  # Drift into play area first
var _retreat_timer: float = 0.0
var _entry_speed: float = BASE_SPEED
var _wobble: float = 0.0

func _ready() -> void:
	super()
	hp = 20
	max_hp = 20
	contact_damage = 10
	score_value = 100
	drop_table = "scout"

func _update(delta: float) -> void:
	if _stunned:
		return
	_wobble += delta * 5.0

	# Entry phase — drift down until in screen
	if not _entry_done:
		global_position.y += _entry_speed * delta
		if global_position.y >= 30.0:
			_entry_done = true
		return

	# Retreat phase
	if _retreat_timer > 0.0:
		_retreat_timer -= delta
		global_position.y -= RETREAT_SPEED * delta
		return

	# Normal: sine horizontal + slow downward drift
	_sine_phase += SINE_FREQ * delta
	var vp := get_viewport_rect()
	global_position.x += cos(_sine_phase) * SINE_AMP * delta
	global_position.y += 30.0 * delta   # slow drift downward

	# Wrap horizontal
	if global_position.x < -10:
		global_position.x = vp.size.x + 10
	elif global_position.x > vp.size.x + 10:
		global_position.x = -10

	# Despawn off bottom
	if global_position.y > vp.size.y + 30:
		queue_free()
		return

	# Fire timer
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = _scaled_interval(FIRE_INTERVAL) + randf_range(-0.3, 0.3)
		_fire_bolt(_aim_at_player(), BOLT_DAMAGE, BOLT_SPEED, "scout")
		AudioManager.play_sfx("enemy_laser")

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	super(amount, from_position)
	if not _dead:
		_retreat_timer = RETREAT_TIME   # Retreat on hit

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var hull  := COLOR_HIT if flash else COL_HULL
	var w := _wobble

	# Outer energy ring — spins and pulses
	var outer_alpha := 0.25 + 0.15 * sin(w * 1.3)
	draw_arc(Vector2.ZERO, 12.0, w * 0.6, w * 0.6 + TAU, 24,
		Color(COL_RING.r, COL_RING.g, COL_RING.b, outer_alpha), 1.0)

	# Underlighting glow (soft wide disc below saucer)
	var under_a := 0.18 + 0.1 * sin(w * 2.0)
	draw_circle(Vector2(0, 4), 8.0, Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, under_a))

	# Saucer body — beveled double layer for depth
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, 0), Vector2(-7, -3), Vector2(7, -3), Vector2(10, 0),
		Vector2(9, 3), Vector2(-9, 3)
	]), hull)
	# Bottom hull highlight strip
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, 1), Vector2(8, 1), Vector2(9, 3), Vector2(-9, 3)
	]), Color(hull.r * 0.6, hull.g * 0.4, hull.b * 0.7))

	# Spinning detail notches on rim
	for i in 6:
		var a: float = w * 1.2 + TAU / 6.0 * float(i)
		var nx := cos(a) * 9.0
		var ny := sin(a) * 1.8  # flattened ellipse to look like rim
		draw_circle(Vector2(nx, ny), 0.8, Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, 0.6))

	# Dome — larger, layered with interior glow
	var dome_center := Vector2(0, -4)
	# Dome outer shell
	draw_circle(dome_center, 5.0, COL_HULL if not flash else Color(1, 1, 1))
	# Dome interior glow — pulses
	var dome_glow_a := 0.35 + 0.25 * sin(w * 1.8)
	draw_circle(dome_center, 3.5, Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, dome_glow_a))
	# Dome specular highlight
	draw_circle(dome_center + Vector2(-1.5, -1.5), 1.2, Color(1, 1, 1, 0.25))

	# Inner energy ring — counter-rotates
	var ring_alpha := 0.5 + 0.3 * sin(w)
	draw_arc(Vector2.ZERO, 9.5, -w * 0.8, -w * 0.8 + TAU, 20,
		Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, ring_alpha), 1.5)

	# Segmented inner ring dashes (rotating)
	for i in 4:
		var seg_start: float = -w * 0.8 + TAU / 4.0 * float(i)
		var seg_end: float = seg_start + 0.35
		draw_arc(Vector2.ZERO, 9.5, seg_start, seg_end, 6,
			Color(1, 1, 1, 0.35), 1.0)

	# Eyes — brighter with glow halos
	for ex in [-3.0, 3.0]:
		draw_circle(Vector2(ex, -3), 1.8, Color(COL_EYE.r, COL_EYE.g, COL_EYE.b, 0.3))
		draw_circle(Vector2(ex, -3), 1.2, COL_EYE)
		draw_circle(Vector2(ex, -3), 0.5, Color(1, 1, 1, 0.7))

	# Stun indicator
	if _stunned:
		draw_circle(Vector2(0, -10), 2.0, Color(0.0, 1.0, 1.0, 0.8))

const COLOR_HIT := Color(1.0, 1.0, 1.0)
