## EnemyMissile — Homing enemy projectile (used by swarm commander and mothership).
class_name EnemyMissile
extends Area2D

const COLOR_TRAIL := Color(1.0, 0.20, 0.00, 0.6)
const COLOR_BODY  := Color(0.80, 0.60, 1.00)
const TURN_SPEED  := 2.5  # rad/sec

var _damage: int = 30
var _target: Node2D = null
var _velocity: Vector2 = Vector2.DOWN * 180.0
var _speed: float = 180.0
var _lifetime: float = 0.0
const MAX_LIFETIME := 6.0
var _trail: Array[Vector2] = []
const TRAIL_LEN := 6

func _ready() -> void:
	add_to_group("enemy_bullets")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	collision_layer = 8
	collision_mask = 1

func setup(damage: int, target: Node2D, speed: float = 180.0) -> void:
	_damage = damage
	_target = target
	_speed = speed
	_velocity = Vector2.DOWN * speed

func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		_explode()
		return

	if is_instance_valid(_target):
		var desired := (_target.global_position - global_position).normalized()
		var current := _velocity.normalized()
		var angle := current.angle_to(desired)
		angle = clampf(angle, -TURN_SPEED * delta, TURN_SPEED * delta)
		_velocity = _velocity.rotated(angle).normalized() * _speed
	else:
		_velocity = Vector2.DOWN * _speed

	global_position += _velocity * delta
	rotation = _velocity.angle() + PI / 2.0

	_trail.push_front(global_position)
	if _trail.size() > TRAIL_LEN:
		_trail.pop_back()

	var vp := get_viewport_rect()
	if global_position.y > vp.size.y + 20:
		queue_free()
	queue_redraw()

func _draw() -> void:
	for i in _trail.size():
		var pt := to_local(_trail[i])
		var a := (1.0 - float(i) / TRAIL_LEN) * 0.5
		draw_circle(pt, 1.2, Color(COLOR_TRAIL.r, COLOR_TRAIL.g, COLOR_TRAIL.b, a))
	draw_rect(Rect2(-1.5, -5, 3, 8), COLOR_BODY)
	draw_circle(Vector2(0, -5), 1.5, COLOR_BODY)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(_damage, "hull")
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(_damage, "hull")
		_explode()

func _explode() -> void:
	AudioManager.play_sfx("missile_explode")
	queue_free()
