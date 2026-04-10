## PickupBase — Drifts, flashes warning before despawn, collects on player contact.
## GDD Ref: gameplay-mechanics.md §6 — Collectibles & Pickups
class_name PickupBase
extends Area2D

signal collected(type: String)

const DESPAWN_TIME   := 5.0
const FLASH_START    := 3.0   # Start flashing at this many seconds remaining
const MAGNET_RANGE   := 40.0
const MAGNET_SPEED   := 90.0
const DRIFT_SPEED    := 12.0

var pickup_type: String = "crystal"
var _lifetime: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _wobble: float = 0.0
var _dead: bool = false

func _ready() -> void:
	add_to_group("pickups")
	# monitoring defaults true on Area2D — skip explicit set to avoid physics errors
	collision_layer = 32
	collision_mask = 1   # player
	body_entered.connect(_on_body_entered)
	_velocity = Vector2(randf_range(-18.0, 18.0), randf_range(-8.0, 8.0))

func setup(type: String) -> void:
	pickup_type = type

func _process(delta: float) -> void:
	if _dead:
		return
	_lifetime += delta
	_wobble += delta * 4.0

	# Despawn
	if _lifetime >= DESPAWN_TIME:
		queue_free()
		return

	# Magnet toward player
	var player := _find_player()
	if player:
		var d := global_position.distance_to(player.global_position)
		if d < MAGNET_RANGE:
			var dir := (player.global_position - global_position).normalized()
			_velocity = _velocity.lerp(dir * MAGNET_SPEED, 0.15)

	global_position += _velocity * delta
	# Friction
	_velocity *= 0.96
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if _dead:
		return
	if body.is_in_group("player"):
		_dead = true
		_apply_effect(body)
		collected.emit(pickup_type)
		AudioManager.play_sfx("pickup_collect")
		queue_free()

func _apply_effect(player: Node2D) -> void:
	match pickup_type:
		"fuel_cell":
			player.fuel_sys.refuel(25.0)
			GameManager.add_score(10)
		"repair_kit":
			player.health.heal_hull(20)
			GameManager.add_score(15)
		"missile_pack":
			player.weapons.add_missiles(3)
			GameManager.add_score(20)
		"emp_cartridge":
			player.weapons.add_emp(1)
			GameManager.add_score(20)
		"crystal":
			GameManager.add_crystal(1)
			GameManager.add_score(25)
		"shield_booster":
			player.health.heal_shield(30)
			GameManager.add_score(20)
		"survey_beacon":
			GameManager.collect_beacon()
			GameManager.add_score(3000)

func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _get_flash() -> bool:
	var remaining := DESPAWN_TIME - _lifetime
	if remaining > FLASH_START:
		return false
	return sin(_wobble * (4.0 + (FLASH_START - remaining) * 3.0)) > 0.0

## Override in subclass for visual.
func _draw() -> void:
	var flash := _get_flash()
	var alpha := 0.4 if flash else 1.0
	_draw_pickup(alpha)

func _draw_pickup(_alpha: float) -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(0.0, 1.0, 1.0, _alpha))
