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

# ─── Colors (art bible — TURN 4 biomech, see EnemyRenderer for shared ramps) ──
const COL_RING  := Color(0.80, 0.00, 1.00, 0.55)

# ─── State ───────────────────────────────────────────────────────────────────
var _fire_timer: float = 0.8   # Stagger initial shot
var _sine_phase: float = 0.0
var _entry_done: bool = false  # Drift into play area first
var _retreat_timer: float = 0.0
var _entry_speed: float = BASE_SPEED
var _wobble: float = 0.0
var _eye_dots: Array = []             # seeded eye cluster offsets

# ─── Textured body (art bible v4.0 "Textured Light") ────────────────────────
var _body: Sprite2D = null

func _ready() -> void:
	super()
	hp = 20
	max_hp = 20
	contact_damage = 10
	score_value = 100
	drop_table = "scout"
	_body = TextureKit.creature_body(self, "enemies", "scout")
	_eye_dots = [
		Vector3(-6, -8, 1.0), Vector3(-2, -10, 1.35), Vector3(3, -9, 1.05),
		Vector3(7, -6, 0.8), Vector3(0, -6, 1.7), Vector3(-4, -5, 0.7),
	]

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
	var w := _wobble
	var lit := _lit_factor()
	var blend := VisualState.blend()
	TextureKit.set_flash(_body, 1.0 if flash else 0.0)

	# Under-halo — magenta in SURVEY, dying embers in DEAD (spec: soft under-halo)
	EnemyRenderer.under_halo(self, Vector2(0, 8), 30.0)

	# Dome fill color — hull ramp, whitens on hit flash
	var hi := EnemyRenderer.body_stop(0, lit)
	if flash:
		hi = Color(1, 1, 1)

	# Dome — larger, layered with interior glow that fades with blend
	var dome_center := Vector2(0, -4)
	draw_circle(dome_center, 5.0, hi)
	var dome_glow_a := (0.35 + 0.25 * sin(w * 1.8)) * (1.0 - blend)
	DrawKit.glow(self, dome_center, 3.5, Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, dome_glow_a), 3)
	draw_circle(dome_center + Vector2(-1.5, -1.5), 1.2, Color(1, 1, 1, 0.25))

	# Spinning rim notches — survey magenta ring fades out with blend
	var notch_a := 0.6 * (1.0 - blend * 0.7)
	var notch_col := VisualState.col(MAGENTA, EYE_DEAD_COL)
	for i in 6:
		var a: float = w * 1.2 + TAU / 6.0 * float(i)
		var nx := cos(a) * 9.0
		var ny := sin(a) * 1.8
		draw_circle(Vector2(nx, ny), 0.8, Color(notch_col.r, notch_col.g, notch_col.b, notch_a))

	# Outer + inner energy rings — survey magenta, dying with blend
	var ring_fade := 1.0 - blend
	if ring_fade > 0.01:
		var outer_alpha := (0.25 + 0.15 * sin(w * 1.3)) * ring_fade
		draw_arc(Vector2.ZERO, 12.0, w * 0.6, w * 0.6 + TAU, 24,
			Color(COL_RING.r, COL_RING.g, COL_RING.b, outer_alpha), 1.0)
		var ring_alpha := (0.5 + 0.3 * sin(w)) * ring_fade
		draw_arc(Vector2.ZERO, 9.5, -w * 0.8, -w * 0.8 + TAU, 20,
			Color(MAGENTA.r, MAGENTA.g, MAGENTA.b, ring_alpha), 1.5)
		for i in 4:
			var seg_start: float = -w * 0.8 + TAU / 4.0 * float(i)
			draw_arc(Vector2.ZERO, 9.5, seg_start, seg_start + 0.35, 6,
				Color(1, 1, 1, 0.35 * ring_fade), 1.0)
		# Belly gill slits (glowing)
		EnemyRenderer.magenta_vein(self, Vector2(-12, 3), Vector2(-8, 3))
		EnemyRenderer.magenta_vein(self, Vector2(-4, 5), Vector2(4, 5))
		EnemyRenderer.magenta_vein(self, Vector2(8, 3), Vector2(12, 3))

	# Eye cluster — dead-frequency red, softening to warm when beam-lit
	EnemyRenderer.eye_cluster(self, _eye_dots, lit, [1, 2])
	# Deep-red vein underline across the belly
	EnemyRenderer.dead_vein_line(self, Vector2(-10, 4), Vector2(10, 4))
	# Warm lit-rim echo when the flood beam crosses it
	if lit > 0.01:
		var rim_pts := PackedVector2Array([
			Vector2(-10, 0), Vector2(-7, -3), Vector2(7, -3), Vector2(10, 0),
		])
		EnemyRenderer.lit_rim_stroke(self, rim_pts, lit)

	# Stun indicator
	if _stunned:
		draw_circle(Vector2(0, -10), 2.0, Color(0.0, 1.0, 1.0, 0.8))
	_draw_hit_flash()

const MAGENTA := Color("B03BFF")
const EYE_DEAD_COL := Color("FF2A3C")
