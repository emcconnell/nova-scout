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
			_fire_timer = FIRE_INTERVAL + randf_range(-0.4, 0.4)
			_burst_queue = BURST_COUNT
			_burst_timer = 0.0

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var hull  := Color(1,1,1) if flash else COL_HULL

	# Main elongated fin body
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -12), Vector2(4, -12),
		Vector2(6, 4), Vector2(-6, 4)
	]), hull)
	# Side fins
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -4), Vector2(-14, 2), Vector2(-10, 6), Vector2(-5, 2)
	]), hull)
	draw_colored_polygon(PackedVector2Array([
		Vector2(6, -4), Vector2(14, 2), Vector2(10, 6), Vector2(5, 2)
	]), hull)
	# Ventral stripe (glowing)
	var stripe_a := 0.7 + 0.3 * sin(_wobble)
	draw_line(Vector2(0, -10), Vector2(0, 3),
		Color(COL_STRIPE.r, COL_STRIPE.g, COL_STRIPE.b, stripe_a), 2.0)
	# Engine nacelles
	draw_circle(Vector2(-5, 4), 2.5, Color(COL_ENGINE.r, COL_ENGINE.g, COL_ENGINE.b, 0.8))
	draw_circle(Vector2(5, 4), 2.5, Color(COL_ENGINE.r, COL_ENGINE.g, COL_ENGINE.b, 0.8))
	# Front shield indicator (bottom face)
	draw_arc(Vector2(0, 3), 8.0, 0.0, PI, 16, COL_SHIELD_INDICATOR, 1.5)
	# Stun
	if _stunned:
		draw_circle(Vector2(0, -14), 2.0, Color(0.0, 1.0, 1.0, 0.8))
