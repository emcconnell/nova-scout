## Player — Survey Probe Seven.
## Handles movement, input routing, and visual state.
class_name Player
extends CharacterBody2D

# ─── Signals ─────────────────────────────────────────────────────────────────
signal died()

# ─── Constants ───────────────────────────────────────────────────────────────
const BASE_SPEED := 180.0
const BOOST_SPEED := 320.0
const FUEL_DRAIN_BOOST := 8.0   # per second while boosting
const FUEL_DRAIN_IDLE := 0.5    # per second always

# Colors (art bible palette)
const COLOR_HULL := Color(0.91, 0.93, 1.0)      # Star White
const COLOR_ENGINE := Color(1.0, 0.45, 0.1)     # Orange-red
const COLOR_COCKPIT := Color(0.0, 0.9, 1.0)     # Probe Cyan
const COLOR_WING := Color(0.75, 0.78, 0.9)      # Slightly dimmer white
const COLOR_SHIELD := Color(0.0, 0.9, 1.0, 0.35)
const COLOR_HIT := Color(1.0, 1.0, 1.0)

# ─── Sub-components ──────────────────────────────────────────────────────────
@onready var health: PlayerHealth = $PlayerHealth
@onready var weapons: PlayerWeapons = $PlayerWeapons
@onready var fuel_sys: PlayerFuel = $PlayerFuel
@onready var collision: CollisionShape2D = $CollisionShape2D

# ─── State ───────────────────────────────────────────────────────────────────
var _is_boosting: bool = false
var _hit_flash_timer: float = 0.0
var _bank_dir: float = 0.0           # -1 left, 0 center, 1 right
var _scan_orbit_path: Node2D = null  # Set during scanning
var _in_orbit: bool = false
var _engine_anim: float = 0.0
var _dead: bool = false
var _invincible: bool = false
var _invincible_timer: float = 0.0

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	health.died.connect(_on_died)
	health.hull_changed.connect(_on_hull_changed)
	z_index = 10

func _process(delta: float) -> void:
	if _dead:
		return
	_engine_anim = fmod(_engine_anim + delta * 8.0, TAU)

	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
	if _invincible_timer > 0.0:
		_invincible_timer -= delta
		if _invincible_timer <= 0.0:
			_invincible = false

	queue_redraw()

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _in_orbit:
		_update_orbit(delta)
		return

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_bank_dir = dir.x

	_is_boosting = Input.is_action_pressed("boost") and fuel_sys.fuel > 0.0
	var speed := (BOOST_SPEED if _is_boosting else BASE_SPEED) * _speed_mult

	if _is_boosting:
		fuel_sys.drain(FUEL_DRAIN_BOOST * delta)
	else:
		fuel_sys.drain(FUEL_DRAIN_IDLE * delta)

	velocity = dir.normalized() * speed + _external_vel
	_external_vel = _external_vel.lerp(Vector2.ZERO, 0.15)  # Decay
	move_and_slide()
	_wrap_horizontal()

func _wrap_horizontal() -> void:
	var vp := get_viewport_rect()
	if position.x < -10:
		position.x = vp.size.x + 10
	elif position.x > vp.size.x + 10:
		position.x = -10

# ─── Drawing ─────────────────────────────────────────────────────────────────
func _draw() -> void:
	if _dead:
		return

	var flash := _hit_flash_timer > 0.0
	var hull_col := COLOR_HIT if flash else COLOR_HULL
	var wing_col := COLOR_HIT if flash else COLOR_WING
	var t := _engine_anim

	# Bank tilt offset
	var tilt := _bank_dir * 2.0
	var bank_abs := absf(_bank_dir)

	# ─── Engine exhaust (drawn first, behind everything) ─────────────
	var flame_len := 4.0 + sin(t * 1.3) * 1.5
	var flame_width := 2.0 + sin(t) * 0.5
	if _is_boosting:
		flame_len *= 2.5
		flame_width *= 1.6

	# Outer flame — deep orange-red
	var outer_flame := PackedVector2Array([
		Vector2(-flame_width, 7),
		Vector2(flame_width, 7),
		Vector2(sin(t * 2.7) * 0.8, 7 + flame_len + 2.0),
	])
	draw_colored_polygon(outer_flame, Color(1.0, 0.3, 0.05, 0.6 + sin(t) * 0.2))

	# Core flame — bright yellow-white
	var inner_flame := PackedVector2Array([
		Vector2(-flame_width * 0.5, 7),
		Vector2(flame_width * 0.5, 7),
		Vector2(sin(t * 3.1) * 0.4, 7 + flame_len * 0.7),
	])
	draw_colored_polygon(inner_flame, Color(1.0, 0.85, 0.5, 0.8 + sin(t * 1.5) * 0.2))

	# Spark particles — small dots trailing behind exhaust
	for i in range(3 if not _is_boosting else 6):
		var fi := float(i)
		var spark_y := 9.0 + fi * 2.5 + sin(t * (3.0 + fi)) * 1.5
		var spark_x := sin(t * (2.0 + fi * 1.7)) * (1.5 + fi * 0.5)
		var spark_alpha := clampf(0.7 - fi * 0.15, 0.1, 0.8)
		var spark_size := clampf(0.8 - fi * 0.1, 0.3, 1.0)
		if _is_boosting:
			spark_y += fi * 1.5
			spark_alpha = clampf(spark_alpha + 0.1, 0.0, 0.9)
		draw_circle(Vector2(spark_x, spark_y), spark_size,
			Color(1.0, 0.6 + fi * 0.08, 0.2, spark_alpha))

	# Engine glow halo behind the ship
	var glow_size := 3.0 + sin(t) * 0.8
	if _is_boosting:
		glow_size *= 1.8
	var glow_alpha := 0.35 + sin(t) * 0.15
	draw_circle(Vector2(0, 7), glow_size, Color(1.0, 0.45, 0.1, glow_alpha))

	# ─── Wing shadow (banking visual) ───────────────────────────────
	if bank_abs > 0.1:
		var shadow_alpha := bank_abs * 0.25
		var shadow_col := Color(0.0, 0.0, 0.1, shadow_alpha)
		if _bank_dir < 0.0:
			# Tilting left — shadow on right wing
			var rw_shadow := PackedVector2Array([
				Vector2(3, 3), Vector2(9, 8), Vector2(5, 8), Vector2(3, 5),
			])
			draw_colored_polygon(rw_shadow, shadow_col)
		else:
			# Tilting right — shadow on left wing
			var lw_shadow := PackedVector2Array([
				Vector2(-3, 3), Vector2(-9, 8), Vector2(-5, 8), Vector2(-3, 5),
			])
			draw_colored_polygon(lw_shadow, shadow_col)

	# ─── Left delta wing ────────────────────────────────────────────
	var left_wing := PackedVector2Array([
		Vector2(-3, 1),
		Vector2(-10, 7),
		Vector2(-6, 8),
		Vector2(-3, 4),
	])
	draw_colored_polygon(left_wing, wing_col)

	# Left wing-tip accent
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, 6), Vector2(-10, 7), Vector2(-8, 8), Vector2(-7, 7),
	]), Color(COLOR_COCKPIT.r, COLOR_COCKPIT.g, COLOR_COCKPIT.b, 0.6) if not flash else COLOR_HIT)

	# ─── Right delta wing ───────────────────────────────────────────
	var right_wing := PackedVector2Array([
		Vector2(3, 1),
		Vector2(10, 7),
		Vector2(6, 8),
		Vector2(3, 4),
	])
	draw_colored_polygon(right_wing, wing_col)

	# Right wing-tip accent
	draw_colored_polygon(PackedVector2Array([
		Vector2(9, 6), Vector2(10, 7), Vector2(8, 8), Vector2(7, 7),
	]), Color(COLOR_COCKPIT.r, COLOR_COCKPIT.g, COLOR_COCKPIT.b, 0.6) if not flash else COLOR_HIT)

	# ─── Main fuselage (tapered delta body) ─────────────────────────
	var fuselage := PackedVector2Array([
		Vector2(0 + tilt, -12),    # nose tip
		Vector2(3 + tilt * 0.3, -6),   # upper right
		Vector2(3.5, 2),           # mid right
		Vector2(3, 6),             # lower right
		Vector2(-3, 6),            # lower left
		Vector2(-3.5, 2),          # mid left
		Vector2(-3 + tilt * 0.3, -6),  # upper left
	])
	draw_colored_polygon(fuselage, hull_col)

	# ─── Panel lines (hull detail) ──────────────────────────────────
	if not flash:
		var line_col := Color(0.65, 0.68, 0.82, 0.4)
		# Centre spine
		draw_line(Vector2(tilt * 0.5, -10), Vector2(0, 5), line_col, 1.0)
		# Left panel seam
		draw_line(Vector2(-2 + tilt * 0.3, -5), Vector2(-2.5, 4), line_col, 1.0)
		# Right panel seam
		draw_line(Vector2(2 + tilt * 0.3, -5), Vector2(2.5, 4), line_col, 1.0)

	# ─── Dorsal fin ─────────────────────────────────────────────────
	var fin := PackedVector2Array([
		Vector2(0 + tilt * 0.7, -9),
		Vector2(1 + tilt * 0.3, -4),
		Vector2(-1 + tilt * 0.3, -4),
	])
	var fin_col := Color(hull_col.r * 0.85, hull_col.g * 0.85, hull_col.b * 0.9, 1.0)
	if flash:
		fin_col = COLOR_HIT
	draw_colored_polygon(fin, fin_col)

	# ─── Engine bell ────────────────────────────────────────────────
	var bell := PackedVector2Array([
		Vector2(-2.5, 5), Vector2(2.5, 5),
		Vector2(2, 7), Vector2(-2, 7),
	])
	draw_colored_polygon(bell, Color(0.55, 0.55, 0.65) if not flash else COLOR_HIT)

	# ─── Cockpit canopy ────────────────────────────────────────────
	var canopy := PackedVector2Array([
		Vector2(0 + tilt * 0.6, -10),
		Vector2(1.5 + tilt * 0.3, -6),
		Vector2(-1.5 + tilt * 0.3, -6),
	])
	draw_colored_polygon(canopy, COLOR_COCKPIT if not flash else COLOR_HIT)
	# Canopy glint
	if not flash:
		draw_circle(Vector2(tilt * 0.5 - 0.5, -8), 0.7,
			Color(1.0, 1.0, 1.0, 0.5 + sin(t * 0.5) * 0.2))

	# ─── Shield visualization (energy arc with ripple) ──────────────
	if health.shield > 0 and not flash:
		var shield_strength := health.shield / 100.0
		var base_alpha := shield_strength * 0.3

		# Outer ripple ring — pulses outward
		var ripple_phase := fmod(t * 0.6, 1.0)
		var ripple_radius := 12.0 + ripple_phase * 4.0
		var ripple_alpha := base_alpha * (1.0 - ripple_phase) * 0.5
		if ripple_alpha > 0.01:
			draw_arc(Vector2.ZERO, ripple_radius, -PI * 0.8, PI * 0.8, 24,
				Color(COLOR_SHIELD.r, COLOR_SHIELD.g, COLOR_SHIELD.b, ripple_alpha), 1.0)

		# Main shield arc — front-facing protective curve
		var arc_alpha := base_alpha + sin(t * 2.0) * 0.06
		draw_arc(Vector2.ZERO, 13.0, -PI * 0.75, PI * 0.75, 28,
			Color(COLOR_SHIELD.r, COLOR_SHIELD.g, COLOR_SHIELD.b, arc_alpha), 1.5)

		# Inner glow arc — tighter, brighter
		draw_arc(Vector2.ZERO, 11.0, -PI * 0.6, PI * 0.6, 20,
			Color(COLOR_SHIELD.r, COLOR_SHIELD.g, COLOR_SHIELD.b, arc_alpha * 0.4), 1.0)

		# Energy nodes along the arc — small bright dots
		for i in range(5):
			var angle := -PI * 0.6 + (PI * 1.2) * (float(i) / 4.0)
			var node_pulse := sin(t * 3.0 + float(i) * 1.2) * 0.5 + 0.5
			var node_pos := Vector2(cos(angle), sin(angle)) * 13.0
			draw_circle(node_pos, 0.8,
				Color(COLOR_SHIELD.r, COLOR_SHIELD.g, COLOR_SHIELD.b,
					base_alpha + node_pulse * 0.3))

# ─── Public API ──────────────────────────────────────────────────────────────
func take_damage(amount: int, source: String = "") -> void:
	if _invincible or _dead:
		return
	health.take_damage(amount)
	AudioManager.play_sfx("hull_hit" if source == "hull" else "shield_hit")
	_hit_flash_timer = 0.1
	# Brief invincibility to prevent multi-hit
	_invincible = true
	_invincible_timer = 0.4

func enter_orbit(center: Node2D, radius: float) -> void:
	_in_orbit = true
	_scan_orbit_path = center
	_orbit_radius = radius
	_orbit_angle = atan2(position.y - center.global_position.y,
						  position.x - center.global_position.x)

func exit_orbit() -> void:
	_in_orbit = false
	_scan_orbit_path = null

var _orbit_radius: float = 40.0
var _orbit_angle: float = 0.0
const ORBIT_SPEED := 1.8  # radians per second
var _speed_mult: float = 1.0   # Modified by debris clouds

func _update_orbit(delta: float) -> void:
	if not _in_orbit or _scan_orbit_path == null:
		return
	_orbit_angle += ORBIT_SPEED * delta
	var center := _scan_orbit_path.global_position
	position = center + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * _orbit_radius

func enter_debris() -> void:
	_speed_mult = 0.6

func exit_debris() -> void:
	_speed_mult = 1.0

## External forces (e.g. gravity pulse from Mothership)
var _external_vel: Vector2 = Vector2.ZERO

func apply_external_force(impulse: Vector2) -> void:
	_external_vel += impulse

# ─── Event Handlers ───────────────────────────────────────────────────────────
func _on_died() -> void:
	_dead = true
	AudioManager.play_sfx("craft_explosion")
	queue_redraw()
	# Spawn explosion particles handled by parent world
	died.emit()

func _on_hull_changed(_val: int) -> void:
	queue_redraw()

func reset() -> void:
	_dead = false
	_hit_flash_timer = 0.0
	_invincible = false
	_in_orbit = false
	_speed_mult = 1.0
	health.reset()
	weapons.reset()
	fuel_sys.reset()
	show()
