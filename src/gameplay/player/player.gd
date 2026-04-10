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

	# Bank tilt offset
	var tilt := _bank_dir * 2.0

	# --- Main fuselage (narrow rectangle, nose up) ---
	var fuselage := PackedVector2Array([
		Vector2(-2 + tilt, -10),   # nose left
		Vector2(2 + tilt, -10),    # nose right
		Vector2(3, 4),             # body lower right
		Vector2(-3, 4),            # body lower left
	])
	draw_colored_polygon(fuselage, hull_col)

	# --- Left delta wing ---
	var left_wing := PackedVector2Array([
		Vector2(-3, 2),
		Vector2(-9, 7),
		Vector2(-4, 7),
		Vector2(-2, 3),
	])
	draw_colored_polygon(left_wing, wing_col)

	# --- Right delta wing ---
	var right_wing := PackedVector2Array([
		Vector2(3, 2),
		Vector2(9, 7),
		Vector2(4, 7),
		Vector2(2, 3),
	])
	draw_colored_polygon(right_wing, wing_col)

	# --- Engine bell ---
	draw_rect(Rect2(-2, 4, 4, 3), COLOR_HULL if not flash else COLOR_HIT)

	# --- Engine glow (animated) ---
	var glow_size := 2.5 + sin(_engine_anim) * 0.8
	if _is_boosting:
		glow_size *= 2.0
	var glow_alpha := 0.7 + sin(_engine_anim) * 0.3
	var engine_glow := Color(COLOR_ENGINE.r, COLOR_ENGINE.g, COLOR_ENGINE.b, glow_alpha)
	draw_circle(Vector2(0, 7), glow_size, engine_glow)
	draw_circle(Vector2(0, 9), glow_size * 0.6, Color(1.0, 0.8, 0.4, glow_alpha * 0.5))

	# --- Cockpit bubble ---
	draw_circle(Vector2(tilt * 0.5, -7), 2.0, COLOR_COCKPIT)

	# --- Shield arc (when shield > 0) ---
	if health.shield > 0 and not flash:
		var shield_alpha := (health.shield / 100.0) * 0.4
		draw_circle(Vector2.ZERO, 13.0, Color(COLOR_SHIELD.r, COLOR_SHIELD.g, COLOR_SHIELD.b, shield_alpha))

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
