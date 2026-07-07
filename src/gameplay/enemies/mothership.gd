## Mothership — Final boss. 3 phases, weak point cycle, shield drone.
## GDD Ref: enemies.md — Boss: The Mothership
class_name Mothership
extends EnemyBase

# ─── Stats ───────────────────────────────────────────────────────────────────
const TOTAL_HP        := 2000
const PHASE2_THRESHOLD := 0.60   # 60% HP
const PHASE3_THRESHOLD := 0.30   # 30% HP
const DESPERATE_HP     := 0.10   # 10% HP — desperation sweep

# ─── Weak point ──────────────────────────────────────────────────────────────
const CORE_CYCLE  := 15.0
const CORE_OPEN   := 4.0
const CORE_DAMAGE_MULT := 3.0

# ─── Colors ──────────────────────────────────────────────────────────────────
const COL_CORE   := Color(0.00, 0.90, 1.00)
const COL_CORE_CLOSED := Color(0.20, 0.10, 0.30)
const COL_ENRAGE := Color(1.00, 0.20, 0.00, 0.5)
const COL_WARN   := Color(1.00, 0.00, 0.00, 0.7)

# ─── State ───────────────────────────────────────────────────────────────────
var _phase: int = 1
var _core_timer: float = CORE_CYCLE
var _core_open: bool = false
var _core_open_timer: float = 0.0

# Laser sweep
var _laser_angle: float = -PI / 4.0
var _laser_sweep_dir: float = 1.0
var _laser_timer: float = 2.0
var _laser_rate_mult: float = 1.0

# Missile volley
var _missile_timer: float = 8.0

# Scout spawn
var _scout_timer: float = 12.0
var _total_scouts: int = 0

# Gravity pulse (phase 2+)
var _gravity_timer: float = 20.0
var _gravity_active: bool = false
var _gravity_duration: float = 2.0

# Shield drone (phase 2+)
var _shield_drone: Node2D = null
var _drone_respawn_timer: float = 0.0

# Desperation sweep
var _desperation_triggered: bool = false
var _sweep_warning: float = 0.0
var _sweep_active: bool = false
var _sweep_timer: float = 0.0
var _safe_gap: float = 0.0   # x-position of safe gap

var _wobble: float = 0.0
var _enrage_flash: float = 0.0
var _flecks: Array[Vector3] = []      # seeded chitin flecks (TURN 4)
var _eye_dots: Array = []             # seeded eye cluster (dead frequency)

func _ready() -> void:
	super()
	hp = TOTAL_HP
	max_hp = TOTAL_HP
	contact_damage = 50
	score_value = 10000
	drop_table = "mothership"
	collision_layer = 2
	collision_mask = 4   # Only player bullets; player contact handled differently
	_flecks = EnemyRenderer.seed_flecks(get_instance_id(), 90, Vector2(60, 20))
	_eye_dots = [
		Vector3(-30, -16, 2.0), Vector3(30, -16, 2.0), Vector3(-15, -18, 1.4),
		Vector3(15, -18, 1.4), Vector3(0, -14, 2.6), Vector3(-45, -10, 1.2),
		Vector3(45, -10, 1.2), Vector3(0, -20, 1.6),
	]

func _modify_damage(amount: int, _from: Vector2) -> int:
	# Shield drone blocks all damage while alive
	if is_instance_valid(_shield_drone):
		return 0
	if _core_open:
		return int(amount * CORE_DAMAGE_MULT)
	return amount

func _update(delta: float) -> void:
	if _stunned:
		return
	_wobble += delta * 2.0
	var vp := get_viewport_rect()
	var hp_pct := float(hp) / float(max_hp)

	# Entry: drop to upper 1/3 of screen
	if global_position.y < vp.size.y * 0.25:
		global_position.y += 50.0 * delta
		return

	# Slow horizontal drift
	global_position.x += sin(_wobble * 0.3) * 25.0 * delta
	global_position.x = clampf(global_position.x, 40, vp.size.x - 40)

	# Phase transitions
	if _phase == 1 and hp_pct <= PHASE2_THRESHOLD:
		_enter_phase(2)
	elif _phase == 2 and hp_pct <= PHASE3_THRESHOLD:
		_enter_phase(3)

	# Desperation sweep
	if not _desperation_triggered and hp_pct <= DESPERATE_HP:
		_desperation_triggered = true
		_trigger_desperation_sweep()

	# Core cycle (weak point)
	_core_timer -= delta
	if _core_timer <= 0.0 and not _core_open:
		_core_open = true
		_core_open_timer = CORE_OPEN
	if _core_open:
		_core_open_timer -= delta
		if _core_open_timer <= 0.0:
			_core_open = false
			_core_timer = CORE_CYCLE

	# Laser sweep
	_laser_timer -= delta
	if _laser_timer <= 0.0:
		_laser_timer = 0.05 / _laser_rate_mult
		var laser_dir := Vector2(cos(_laser_angle), sin(_laser_angle))
		_fire_bolt(laser_dir, 10, 300, "destroyer")
		_laser_angle += _laser_sweep_dir * 0.08 * _laser_rate_mult
		if abs(_laser_angle) > PI * 0.8:
			_laser_sweep_dir = -_laser_sweep_dir

	# Missile volley
	_missile_timer -= delta
	if _missile_timer <= 0.0:
		_missile_timer = 10.0 / _laser_rate_mult
		_fire_missile_volley()

	# Scout spawning
	_scout_timer -= delta
	if _scout_timer <= 0.0:
		_scout_timer = 12.0
		_spawn_scouts(3)

	# Phase 2+
	if _phase >= 2:
		_update_gravity_pulse(delta)
		_update_shield_drone(delta)

	# Desperation sweep active
	if _sweep_active:
		_sweep_timer -= delta
		if _sweep_timer <= 0.0:
			_sweep_active = false
			_sweep_warning = 0.0

func _enter_phase(phase: int) -> void:
	_phase = phase
	_laser_rate_mult = 1.0 + (phase - 1) * 0.3
	if phase == 2:
		_spawn_shield_drone()
		AudioManager.play_music("mothership_phase2")
	elif phase == 3:
		_laser_rate_mult = 1.6
		_spawn_shield_drone()
		_drone_respawn_timer = 20.0
		get_tree().call_group("game_world", "spawn_enemy_at", "destroyer",
			Vector2(get_viewport_rect().size.x * 0.5, -20))
		AudioManager.play_music("mothership_phase3")

func _fire_missile_volley() -> void:
	var player := _get_player()
	for i in 3:
		var offset := (i - 1) * 30.0
		get_tree().call_group("game_world", "spawn_missile_from",
			global_position + Vector2(offset, 20), player, 30)

func _spawn_scouts(count: int) -> void:
	var vp := get_viewport_rect()
	for i in count:
		_total_scouts += 1
		var pos := global_position + Vector2(randf_range(-60, 60), 25)
		get_tree().call_group("game_world", "spawn_enemy_at", "scout", pos)

func _update_gravity_pulse(delta: float) -> void:
	if _gravity_active:
		_gravity_duration -= delta
		var player := _get_player()
		if is_instance_valid(player):
			var pull := (global_position - player.global_position).normalized() * 120.0
			if player.has_method("apply_external_force"):
				player.apply_external_force(pull * delta)
		if _gravity_duration <= 0.0:
			_gravity_active = false
	else:
		_gravity_timer -= delta
		if _gravity_timer <= 0.0:
			_gravity_timer = 20.0
			_gravity_active = true
			_gravity_duration = 2.0
			AudioManager.play_sfx("gravity_pulse")

func _spawn_shield_drone() -> void:
	if is_instance_valid(_shield_drone):
		return
	_shield_drone = preload("res://scenes/enemies/shield_drone.tscn").instantiate() as Node2D
	get_parent().add_child(_shield_drone)
	if _shield_drone.has_method("attach_to"):
		_shield_drone.attach_to(self)

func _update_shield_drone(delta: float) -> void:
	if _phase == 3 and not is_instance_valid(_shield_drone):
		_drone_respawn_timer -= delta
		if _drone_respawn_timer <= 0.0:
			_drone_respawn_timer = 20.0
			_spawn_shield_drone()

func _trigger_desperation_sweep() -> void:
	_sweep_warning = 3.0   # 3 second warning
	_sweep_active = true
	_sweep_timer = 4.5
	_safe_gap = randf_range(30, get_viewport_rect().size.x - 30)
	AudioManager.play_sfx("desperation_charge")
	await get_tree().create_timer(3.0).timeout
	if not _dead:
		_fire_sweep()

func _fire_sweep() -> void:
	# Fire bolts across entire screen with safe gap
	var vp := get_viewport_rect()
	var x := 0.0
	if enemy_projectile_container == null:
		return
	var scene := load("res://scenes/projectiles/enemy_bolt.tscn") as PackedScene
	if scene == null:
		return
	while x < vp.size.x:
		if abs(x - _safe_gap) > 15.0:
			var b := scene.instantiate() as EnemyBolt
			enemy_projectile_container.add_child(b)
			b.global_position = Vector2(x, global_position.y + 20)
			b.setup(25, Vector2.DOWN, 350, "destroyer")
		x += 12.0

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var lit := _lit_factor()
	var blend := VisualState.blend()
	var hi := EnemyRenderer.body_stop(0, lit)
	var mid := EnemyRenderer.body_stop(1, lit)
	var hull  := hi if not flash else Color(1, 1, 1)
	var armor := mid if not flash else Color(1, 1, 1)
	var hp_pct: float = float(hp) / float(maxi(max_hp, 1))

	EnemyRenderer.under_halo(self, Vector2(0, 4), 90.0)

	# Enormous hull — multi-segment (silhouette unchanged)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-50, -18), Vector2(50, -18),
		Vector2(55, 10), Vector2(-55, 10)
	]), hull)
	# Wings
	draw_colored_polygon(PackedVector2Array([
		Vector2(-55, -5), Vector2(-80, 5), Vector2(-70, 15), Vector2(-50, 8)
	]), armor)
	draw_colored_polygon(PackedVector2Array([
		Vector2(55, -5), Vector2(80, 5), Vector2(70, 15), Vector2(50, 8)
	]), armor)

	# Plate ridges across the main hull
	EnemyRenderer.plate_ridge_line(self,
		PackedVector2Array([Vector2(-48, -6), Vector2(0, -10), Vector2(48, -6)]),
		PackedVector2Array([Vector2(-48, -7.4), Vector2(0, -11.4), Vector2(48, -7.4)]), lit, 2.0)
	EnemyRenderer.plate_ridge_line(self,
		PackedVector2Array([Vector2(-40, 4), Vector2(0, 7), Vector2(40, 4)]),
		PackedVector2Array([Vector2(-40, 2.6), Vector2(0, 5.6), Vector2(40, 2.6)]), lit, 1.6)
	EnemyRenderer.draw_flecks(self, _flecks, lit)

	# Energy veins — magenta bioluminescence, dies with blend
	var va := (0.5 + 0.3 * sin(_wobble)) * (1.0 - blend * 0.5)
	var vein_col := VisualState.col(MAGENTA_COL, Color("7A0E12"))
	draw_line(Vector2(-40, -10), Vector2(40, -10), Color(vein_col.r, vein_col.g, vein_col.b, va), 1.5)
	draw_line(Vector2(-30, 0), Vector2(30, 0), Color(vein_col.r, vein_col.g, vein_col.b, va), 1.5)
	EnemyRenderer.dead_vein_line(self, Vector2(-45, 8), Vector2(45, 8))

	# Weapon ports
	for i in 3:
		var px := -30.0 + i * 30.0
		var port_a := 0.7 * (1.0 - blend * 0.4)
		draw_circle(Vector2(px, -16), 4.0, Color(MAGENTA_COL.r, MAGENTA_COL.g, MAGENTA_COL.b, port_a))

	# Eye cluster — wakes across the hull in dead frequency
	EnemyRenderer.eye_cluster(self, _eye_dots, lit, [0, 1, 4])

	# Warm lit-rim when the flood beam crosses it
	if lit > 0.01:
		var rim_pts := PackedVector2Array([Vector2(-50, -18), Vector2(-55, 10)])
		EnemyRenderer.lit_rim_stroke(self, rim_pts, lit)

	# Reactor core (blast doors) — kept as the cyan tech-tell weak point
	var core_col := COL_CORE if _core_open else COL_CORE_CLOSED
	var core_pulse: float = 0.7 + 0.3 * abs(sin(_wobble * 3.0))
	draw_circle(Vector2(0, 0), 8.0, Color(core_col.r, core_col.g, core_col.b, core_pulse))
	if _core_open:
		draw_circle(Vector2(0, 0), 5.0, COL_CORE)
	# Phase 3 enrage flash
	if _phase == 3:
		var ef: float = 0.2 * abs(sin(_wobble * 5.0))
		draw_circle(Vector2.ZERO, 70.0, Color(COL_ENRAGE.r, COL_ENRAGE.g, COL_ENRAGE.b, ef))
	# Desperation warning
	if _sweep_active and _sweep_warning > 0.0:
		var warn_a: float = abs(sin(_wobble * 8.0)) * 0.6
		var vp := get_viewport_rect()
		# Drawn in world space, so local position is (0,0) relative to self
		draw_line(Vector2(-200, 40), Vector2(200, 40),
			Color(COL_WARN.r, COL_WARN.g, COL_WARN.b, warn_a), 2.0)
	_draw_hit_flash()

const MAGENTA_COL := Color("B03BFF")
