## PlayerWeapons — Handles laser, missile, and EMP firing.
## Laser now uses an energy pool that regens over time.
class_name PlayerWeapons
extends Node

signal missiles_changed(count: int)
signal emp_changed(count: int)
signal energy_changed(value: float)

const LASER_FIRE_RATE   := 0.125   # seconds between shots (8/sec)
const LASER_ENERGY_COST := 2.0     # energy per laser shot
const ENERGY_REGEN_RATE := 5.0     # energy/sec while not firing
const ENERGY_REGEN_TRAVEL := 8.0   # boosted regen during travel phase
const OVERHEAT_COOLDOWN := 1.5     # seconds of forced cooldown at 0 energy
const TRAVEL_DISTANCE_REGEN := 10.0  # energy granted per distance threshold
const TRAVEL_DISTANCE_THRESHOLD := 800.0  # pixels traveled between bonuses
const EMP_RADIUS := 300.0

var missiles: int = 6
var emp_charges: int = 2
var energy: float = 100.0
var max_energy: float = 100.0
var _laser_timer: float = 0.0
var _emp_active: bool = false
var _overheat_timer: float = 0.0
var _regen_pause: float = 0.0    # brief pause after firing before regen starts
var _travel_distance_acc: float = 0.0  # accumulated travel distance

# Injected by parent
var projectile_container: Node2D = null
var laser_pool: ObjectPool = null
var missile_pool: ObjectPool = null

func _ready() -> void:
	missiles = GameManager.player_missiles
	emp_charges = GameManager.player_emp
	energy = GameManager.player_laser_energy
	max_energy = GameManager.player_max_laser_energy

func _process(delta: float) -> void:
	_laser_timer = maxf(_laser_timer - delta, 0.0)

	# Overheat cooldown
	if _overheat_timer > 0.0:
		_overheat_timer -= delta
		if _overheat_timer <= 0.0:
			_overheat_timer = 0.0
		# No firing or regen during overheat
	else:
		# Regen pause after firing
		if _regen_pause > 0.0:
			_regen_pause -= delta
		else:
			# Energy regen
			var rate := ENERGY_REGEN_TRAVEL if GameManager.current_state == GameManager.GameState.TRAVEL else ENERGY_REGEN_RATE
			if energy < max_energy:
				energy = minf(energy + rate * delta, max_energy)
				GameManager.player_laser_energy = energy
				energy_changed.emit(energy)

		# Fire laser
		if Input.is_action_pressed("fire_laser") and _laser_timer <= 0.0:
			_fire_laser()

	if Input.is_action_just_pressed("fire_missile"):
		_fire_missile()

	if Input.is_action_just_pressed("fire_emp"):
		_fire_emp()

## Call from game_world during travel to grant distance-based energy.
func add_travel_distance(dist: float) -> void:
	_travel_distance_acc += dist
	if _travel_distance_acc >= TRAVEL_DISTANCE_THRESHOLD:
		_travel_distance_acc -= TRAVEL_DISTANCE_THRESHOLD
		add_energy(TRAVEL_DISTANCE_REGEN)

func _fire_laser() -> void:
	if laser_pool == null:
		return
	if energy < LASER_ENERGY_COST:
		# Overheat!
		if _overheat_timer <= 0.0:
			_overheat_timer = OVERHEAT_COOLDOWN
			AudioManager.play_sfx("hull_critical", 0.5)
		return
	energy -= LASER_ENERGY_COST
	GameManager.player_laser_energy = energy
	energy_changed.emit(energy)
	_laser_timer = LASER_FIRE_RATE
	_regen_pause = 0.4   # brief delay before regen kicks in

	var bullet := laser_pool.get_instance() as Node2D
	if bullet == null:
		return
	bullet.global_position = get_parent().global_position + Vector2(0, -12)
	bullet.setup(GameManager.player_laser_damage, Vector2.UP, 400.0, "player")
	AudioManager.play_sfx("laser_fire")

func _fire_missile() -> void:
	if missiles <= 0 or missile_pool == null:
		return
	missiles -= 1
	GameManager.player_missiles = missiles
	missiles_changed.emit(missiles)

	var m := missile_pool.get_instance() as Node2D
	if m == null:
		return
	m.global_position = get_parent().global_position + Vector2(0, -12)
	var target := _find_nearest_enemy(200.0)
	m.setup(60, target)
	AudioManager.play_sfx("missile_launch")

func _fire_emp() -> void:
	if emp_charges <= 0:
		return
	emp_charges -= 1
	GameManager.player_emp = emp_charges
	emp_changed.emit(emp_charges)
	_emp_active = true

	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e.has_method("stun"):
			e.stun(2.5)
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		b.queue_free()

	AudioManager.play_sfx("emp_fire")

func _find_nearest_enemy(max_range: float) -> Node2D:
	var closest: Node2D = null
	var best_dist := max_range
	var my_pos: Vector2 = (get_parent() as Node2D).global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		var d: float = my_pos.distance_to((e as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			closest = e
	return closest

func add_missiles(amount: int) -> void:
	missiles = mini(missiles + amount, GameManager.player_max_missiles)
	GameManager.player_missiles = missiles
	missiles_changed.emit(missiles)

func add_emp(amount: int) -> void:
	emp_charges = mini(emp_charges + amount, GameManager.player_max_emp)
	GameManager.player_emp = emp_charges
	emp_changed.emit(emp_charges)

func add_energy(amount: float) -> void:
	energy = minf(energy + amount, max_energy)
	GameManager.player_laser_energy = energy
	energy_changed.emit(energy)

func is_overheated() -> bool:
	return _overheat_timer > 0.0

func get_overheat_pct() -> float:
	return _overheat_timer / OVERHEAT_COOLDOWN if _overheat_timer > 0.0 else 0.0

func reset() -> void:
	missiles = GameManager.player_missiles
	emp_charges = GameManager.player_emp
	energy = GameManager.player_laser_energy
	max_energy = GameManager.player_max_laser_energy
	_laser_timer = 0.0
	_overheat_timer = 0.0
	_regen_pause = 0.0
	_travel_distance_acc = 0.0
	missiles_changed.emit(missiles)
	emp_changed.emit(emp_charges)
	energy_changed.emit(energy)
