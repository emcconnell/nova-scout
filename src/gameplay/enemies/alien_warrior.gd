## AlienWarrior — Deliberate diagonal sweeper. Front-shield reduces damage from below.
## 3-shot burst every 2s. Tries to position above player.
## GDD Ref: enemies.md — Tier 2 Alien Warrior
class_name AlienWarrior
extends EnemyBase

# ─── Stats (from enemies.md) ─────────────────────────────────────────────────
const BASE_SPEED      := 140.0
const FIRE_INTERVAL   := 2.0
const BURST_COUNT     := 3
const BURST_DELAY     := 0.12
const BOLT_DAMAGE     := 10
const BOLT_SPEED      := 200.0
const FRONT_SHIELD_REDUCTION := 0.5   # 50% damage from front

# ─── Colors (art bible) ──────────────────────────────────────────────────────
const COL_HULL   := Color(0.40, 0.00, 0.65)
const COL_STRIPE := Color(0.70, 0.00, 1.00)
const COL_ENGINE := Color(0.60, 0.00, 0.90, 0.7)
const COL_SHIELD_INDICATOR := Color(0.00, 0.80, 1.00, 0.45)

# ─── State ───────────────────────────────────────────────────────────────────
enum Phase { ENTRY, SWEEP_RIGHT, SWEEP_LEFT, REPOSITION }
var _phase: Phase = Phase.ENTRY
var _fire_timer: float = 1.2
var _burst_queue: int = 0
var _burst_timer: float = 0.0
var _sweep_dir: float = 1.0   # +1 = right, -1 = left
var _wobble: float = 0.0

func _ready() -> void:
	super()
	hp = 60
	max_hp = 60
	contact_damage = 20
	score_value = 300
	drop_table = "warrior"
	_sweep_dir = 1.0 if randf() > 0.5 else -1.0

func _modify_damage(amount: int, from_pos: Vector2) -> int:
	# Half damage if attack comes from below (front shield)
	if from_pos != Vector2.ZERO and from_pos.y > global_position.y:
		return int(amount * FRONT_SHIELD_REDUCTION)
	return amount

func _update(delta: float) -> void:
	if _stunned:
		return
	_wobble += delta * 4.0

	var vp := get_viewport_rect()

	match _phase:
		Phase.ENTRY:
			global_position.y += BASE_SPEED * 0.7 * delta
			if global_position.y >= 45.0:
				_phase = Phase.SWEEP_RIGHT if _sweep_dir > 0 else Phase.SWEEP_LEFT

		Phase.SWEEP_RIGHT:
			global_position.x += BASE_SPEED * delta
			global_position.y += 15.0 * delta   # slight downward drift
			if global_position.x > vp.size.x - 20:
				_sweep_dir = -1.0
				_phase = Phase.SWEEP_LEFT

		Phase.SWEEP_LEFT:
			global_position.x -= BASE_SPEED * delta
			global_position.y += 15.0 * delta
			if global_position.x < 20:
				_sweep_dir = 1.0
				_phase = Phase.SWEEP_RIGHT

	# Despawn off bottom
	if global_position.y > vp.size.y + 30:
		queue_free()
		return

	# Burst firing
	if _burst_queue > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = BURST_DELAY
			_burst_queue -= 1
			var spread := (_burst_queue - 1) * 0.25
			_fire_bolt(_aim_at_player().rotated(spread), BOLT_DAMAGE, BOLT_SPEED, "warrior")
			AudioManager.play_sfx("enemy_laser")
	else:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = _scaled_interval(FIRE_INTERVAL) + randf_range(-0.4, 0.4)
			_burst_queue = BURST_COUNT
			_burst_timer = 0.0

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var hull  := Color(1, 1, 1) if flash else COL_HULL
	var dark_hull := Color(hull.r * 0.55, hull.g * 0.4, hull.b * 0.65)
	var w := _wobble

	# Main elongated fin body — wider, armored look
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -14), Vector2(5, -14),
		Vector2(7, 4), Vector2(-7, 4)
	]), hull)
	# Armor panel lines — horizontal plating
	for py in [-10, -5, 0]:
		var pw := 4.0 + (float(py) + 14.0) / 18.0 * 3.0
		draw_line(Vector2(-pw, py), Vector2(pw, py), dark_hull, 1.0)
	# Center keel (darker inset panel)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2, -12), Vector2(2, -12),
		Vector2(2.5, 3), Vector2(-2.5, 3)
	]), dark_hull)

	# Side fins — angular with armor edge highlight
	for side in [-1.0, 1.0]:
		var fin := PackedVector2Array([
			Vector2(side * 7, -6), Vector2(side * 16, 0),
			Vector2(side * 13, 7), Vector2(side * 6, 3)
		])
		draw_colored_polygon(fin, hull)
		# Fin edge highlight
		draw_line(Vector2(side * 7, -6), Vector2(side * 16, 0),
			Color(1, 1, 1, 0.15), 1.0)
		# Fin panel line
		draw_line(Vector2(side * 9, -2), Vector2(side * 12, 4), dark_hull, 1.0)

	# Weapon ports — small glowing circles on fin tips
	for side in [-1.0, 1.0]:
		var port_pos := Vector2(side * 14, 1)
		draw_circle(port_pos, 2.0, Color(COL_ENGINE.r, COL_ENGINE.g, COL_ENGINE.b, 0.5))
		var port_pulse := 0.6 + 0.4 * sin(w * 3.0 + side)
		draw_circle(port_pos, 1.2, Color(COL_STRIPE.r, COL_STRIPE.g, COL_STRIPE.b, port_pulse))

	# Energy veins — glowing lines running along body
	var vein_a := 0.4 + 0.3 * sin(w * 2.5)
	var vein_col := Color(COL_STRIPE.r, COL_STRIPE.g, COL_STRIPE.b, vein_a)
	draw_line(Vector2(-4, -12), Vector2(-6, 3), vein_col, 1.0)
	draw_line(Vector2(4, -12), Vector2(6, 3), vein_col, 1.0)

	# Ventral stripe (glowing, wider pulse)
	var stripe_a := 0.7 + 0.3 * sin(w)
	draw_line(Vector2(0, -12), Vector2(0, 3),
		Color(COL_STRIPE.r, COL_STRIPE.g, COL_STRIPE.b, stripe_a), 2.0)
	# Stripe glow bloom
	draw_line(Vector2(0, -12), Vector2(0, 3),
		Color(COL_STRIPE.r, COL_STRIPE.g, COL_STRIPE.b, stripe_a * 0.3), 4.0)

	# Engine nacelles — dual layered with exhaust flicker
	for side in [-1.0, 1.0]:
		var eng_pos := Vector2(side * 5.5, 5)
		# Outer glow
		var eng_a := 0.5 + 0.3 * sin(w * 4.0 + side * 2.0)
		draw_circle(eng_pos, 3.5, Color(COL_ENGINE.r, COL_ENGINE.g, COL_ENGINE.b, eng_a * 0.4))
		# Core
		draw_circle(eng_pos, 2.5, Color(COL_ENGINE.r, COL_ENGINE.g, COL_ENGINE.b, 0.8))
		# Hot center
		draw_circle(eng_pos, 1.0, Color(1, 0.6, 1, 0.6))
		# Exhaust trail flicker
		var trail_len := 2.0 + 1.5 * sin(w * 6.0 + side)
		draw_line(eng_pos, eng_pos + Vector2(0, trail_len),
			Color(COL_ENGINE.r, COL_ENGINE.g, COL_ENGINE.b, 0.5), 1.5)

	# Cockpit viewport (small bright slit near top)
	draw_line(Vector2(-2, -11), Vector2(2, -11), Color(0.5, 0.8, 1.0, 0.7), 1.5)

	# Front shield indicator (bottom face) — layered arcs
	draw_arc(Vector2(0, 4), 9.0, 0.0, PI, 16, COL_SHIELD_INDICATOR, 1.0)
	var shield_a := 0.35 + 0.15 * sin(w * 2.0)
	draw_arc(Vector2(0, 4), 11.0, 0.15, PI - 0.15, 16,
		Color(COL_SHIELD_INDICATOR.r, COL_SHIELD_INDICATOR.g, COL_SHIELD_INDICATOR.b, shield_a), 1.0)

	# Stun
	if _stunned:
		draw_circle(Vector2(0, -16), 2.0, Color(0.0, 1.0, 1.0, 0.8))
