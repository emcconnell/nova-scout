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

const CELL_SEED := 7          # solar cell hi/lo pattern (probe4 recipe)
const KAPTON_SEED := 41       # kapton wrinkle strokes
const CANOPY_SEED := 31       # canopy star-reflection specks

# ─── Sub-components ──────────────────────────────────────────────────────────
@onready var health: PlayerHealth = $PlayerHealth
@onready var weapons: PlayerWeapons = $PlayerWeapons
@onready var fuel_sys: PlayerFuel = $PlayerFuel
@onready var collision: CollisionShape2D = $CollisionShape2D

# ─── State ───────────────────────────────────────────────────────────────────
var _is_boosting: bool = false
var _hit_flash_timer: float = 0.0
var _graze_flash_timer: float = 0.0   # Near-miss spark ring (dark-directive.md §4.1)
var _muzzle_flash_timer: float = 0.0  # Laser muzzle flash (dark-directive.md §4.2)
var _bank_dir: float = 0.0           # -1 left, 0 center, 1 right
var _scan_orbit_path: Node2D = null  # Set during scanning
var _in_orbit: bool = false
var _engine_anim: float = 0.0
var _dead: bool = false
var _invincible: bool = false
var _invincible_timer: float = 0.0
var _boost_toggled: bool = false

# ─── Draw pass state (precomputed noise — never randf() inside _draw) ───────
var _cell_pattern: Array[bool] = []
var _kapton_wrinkles: Array[Vector4] = []
var _canopy_specks: Array[Vector2] = []

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	health.died.connect(_on_died)
	health.hull_changed.connect(_on_hull_changed)
	z_index = 10
	_build_noise_cache()

## Precomputes seeded solar-cell, kapton-wrinkle, and canopy-speck noise for PlayerRenderer.
func _build_noise_cache() -> void:
	var cell_rng := DrawKit.rng(CELL_SEED)
	_cell_pattern = []
	for i in (PlayerRenderer.CELL_COLS * PlayerRenderer.CELL_ROWS * 2):
		_cell_pattern.append(cell_rng.randf() > 0.5)

	var kapton_rng := DrawKit.rng(KAPTON_SEED)
	_kapton_wrinkles = []
	for i in 10:
		var x0 := kapton_rng.randf() * 2.0 - 1.0
		var y0 := kapton_rng.randf() * 2.0 - 1.0
		var sign_z := (1.0 if kapton_rng.randf() > 0.5 else -1.0)
		var y1 := (kapton_rng.randf() - 0.5) * 3.0
		_kapton_wrinkles.append(Vector4(x0, y0, sign_z, y1))

	var canopy_rng := DrawKit.rng(CANOPY_SEED)
	_canopy_specks = []
	for i in 5:
		_canopy_specks.append(Vector2(canopy_rng.randf() * 1.6 - 0.8, canopy_rng.randf() * 1.2 - 0.6))

func _process(delta: float) -> void:
	if _dead:
		return
	_engine_anim = fmod(_engine_anim + delta * 8.0, TAU)

	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
	if _graze_flash_timer > 0.0:
		_graze_flash_timer -= delta
	if _muzzle_flash_timer > 0.0:
		_muzzle_flash_timer -= delta
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

	_is_boosting = _wants_boost() and fuel_sys.fuel > 0.0
	if fuel_sys.fuel <= 0.0:
		_boost_toggled = false
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

func _wants_boost() -> bool:
	if bool(SaveManager.get_setting("hold_to_boost")):
		_boost_toggled = false
		return Input.is_action_pressed("boost")
	if Input.is_action_just_pressed("boost"):
		_boost_toggled = not _boost_toggled
	return _boost_toggled

# ─── Drawing ─────────────────────────────────────────────────────────────────
## Draws the SP-7 probe via PlayerRenderer — one geometry crossfaded SURVEY/DEAD FREQUENCY.
func _draw() -> void:
	if _dead:
		return

	var ds := PlayerRenderer.DrawState.new()
	ds.tilt = _bank_dir * 2.0
	ds.bank_abs = absf(_bank_dir)
	ds.t = _engine_anim
	ds.flash = _hit_flash_timer > 0.0
	ds.is_boosting = _is_boosting
	ds.hull_pct = float(health.hull) / maxf(float(GameManager.player_max_hull), 1.0)
	ds.shield = health.shield
	ds.muzzle_flash_timer = _muzzle_flash_timer
	ds.graze_flash_timer = _graze_flash_timer
	ds.cell_pattern = _cell_pattern
	ds.kapton_wrinkles = _kapton_wrinkles
	ds.canopy_specks = _canopy_specks

	PlayerRenderer.draw(self, ds)

# ─── Public API ──────────────────────────────────────────────────────────────
## A bolt grazed past — flash the near-miss ring (reward handled by the bolt).
func on_graze() -> void:
	_graze_flash_timer = 0.22

## Laser fired — flash the muzzle for 2 frames (dark-directive.md §4.2).
func on_laser_fired() -> void:
	_muzzle_flash_timer = 0.05

## True while boost is active — the DarknessVeil flares the light radius.
func is_boosting() -> bool:
	return _is_boosting

func take_damage(amount: int, source: String = "") -> void:
	if _invincible or _dead:
		return
	health.take_damage(amount)
	AudioManager.play_sfx("hull_hit" if source == "hull" else "shield_hit")
	# Impact feedback — hitstop + shake handled by the world (dark-directive.md §4.2)
	get_tree().call_group("game_world", "on_player_hull_hit")
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
