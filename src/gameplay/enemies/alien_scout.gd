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
	# Saucer body
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7, -2), Vector2(7, -2),
		Vector2(9, 2), Vector2(-9, 2)
	]), hull)
	# Dome
	draw_circle(Vector2(0, -3), 4.0, COL_HULL if not flash else Color(1,1,1))
	# Magenta glow ring
	var ring_alpha := 0.5 + 0.3 * sin(_wobble)
	draw_arc(Vector2.ZERO, 9.0, 0, TAU, 20, Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, ring_alpha), 1.5)
	# Eyes
	draw_circle(Vector2(-3, -2), 1.2, COL_EYE)
	draw_circle(Vector2(3, -2), 1.2, COL_EYE)
	# Stun indicator
	if _stunned:
		draw_circle(Vector2(0, -8), 2.0, Color(0.0, 1.0, 1.0, 0.8))

const COLOR_HIT := Color(1.0, 1.0, 1.0)
