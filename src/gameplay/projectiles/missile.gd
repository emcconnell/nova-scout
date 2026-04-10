## Missile — Homing player missile with explosion AoE.
class_name Missile
extends Area2D

const SPEED := 220.0
const TURN_SPEED := 3.5   # radians/sec
const DAMAGE := 60
const AOE_RADIUS := 40.0
const COLOR_BODY := Color(0.95, 0.95, 0.95)
const COLOR_TRAIL := Color(1.0, 0.5, 0.1, 0.7)

var _target: Node2D = null
var _velocity: Vector2 = Vector2.UP * SPEED
var _lifetime: float = 0.0
var _trail: Array[Vector2] = []
const MAX_LIFETIME := 4.0
const TRAIL_LEN := 8

func _ready() -> void:
	add_to_group("player_bullets")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func setup(damage: int, target: Node2D) -> void:
	_target = target
	_lifetime = 0.0
	_trail.clear()

func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		_explode()
		return

	# Homing
	if is_instance_valid(_target):
		var desired := (_target.global_position - global_position).normalized()
		var current := _velocity.normalized()
		var angle := current.angle_to(desired)
		angle = clampf(angle, -TURN_SPEED * delta, TURN_SPEED * delta)
		_velocity = _velocity.rotated(angle).normalized() * SPEED
	else:
		_velocity = Vector2.UP * SPEED  # fly straight if no target

	global_position += _velocity * delta
	rotation = _velocity.angle() + PI / 2.0

	# Trail
	_trail.push_front(global_position)
	if _trail.size() > TRAIL_LEN:
		_trail.pop_back()

	var vp := get_viewport_rect()
	if global_position.y < -20:
		_return_to_pool()
	queue_redraw()

func _draw() -> void:
	# Trail
	for i in _trail.size():
		var pt := to_local(_trail[i])
		var alpha := (1.0 - float(i) / TRAIL_LEN) * 0.6
		draw_circle(pt, 1.5 - i * 0.15, Color(COLOR_TRAIL.r, COLOR_TRAIL.g, COLOR_TRAIL.b, alpha))
	# Body
	draw_rect(Rect2(-1.5, -5, 3, 8), COLOR_BODY)
	draw_circle(Vector2(0, -5), 1.5, COLOR_BODY)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") or area.is_in_group("hazards"):
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") or body.is_in_group("hazards"):
		_explode()

func _explode() -> void:
	# AoE damage
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = AOE_RADIUS
	query.shape = circle
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 18  # 2=enemies + 16=hazards
	var hits := space.intersect_shape(query)
	for hit in hits:
		var obj: Node = hit["collider"]
		if obj.has_method("take_damage"):
			obj.take_damage(DAMAGE)

	AudioManager.play_sfx("missile_explode")
	_return_to_pool()

func _return_to_pool() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()

func reset() -> void:
	_target = null
	_lifetime = 0.0
	_trail.clear()
