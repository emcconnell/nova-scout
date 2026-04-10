## PlayerWeapons — Handles laser, missile, and EMP firing.
class_name PlayerWeapons
extends Node

signal missiles_changed(count: int)
signal emp_changed(count: int)

const LASER_FIRE_RATE := 0.125   # seconds between shots (8/sec)
const EMP_RADIUS := 300.0

var missiles: int = 6
var emp_charges: int = 2
var _laser_timer: float = 0.0
var _emp_active: bool = false

# Injected by parent
var projectile_container: Node2D = null
var laser_pool: ObjectPool = null
var missile_pool: ObjectPool = null

func _ready() -> void:
	missiles = GameManager.player_missiles
	emp_charges = GameManager.player_emp

func _process(delta: float) -> void:
	_laser_timer = maxf(_laser_timer - delta, 0.0)

	if Input.is_action_pressed("fire_laser") and _laser_timer <= 0.0:
		_fire_laser()

	if Input.is_action_just_pressed("fire_missile"):
		_fire_missile()

	if Input.is_action_just_pressed("fire_emp"):
		_fire_emp()

func _fire_laser() -> void:
	if laser_pool == null:
		return
	_laser_timer = LASER_FIRE_RATE
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
	# Find nearest enemy
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

	# Spawn EMP visual and affect all enemies in range
	var enemies := get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e.has_method("stun"):
			e.stun(2.5)
	# Clear all enemy bullets
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		b.queue_free()

	AudioManager.play_sfx("emp_fire")
	# Visual handled by game_world

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

func reset() -> void:
	missiles = GameManager.player_missiles
	emp_charges = GameManager.player_emp
	_laser_timer = 0.0
	missiles_changed.emit(missiles)
	emp_changed.emit(emp_charges)
