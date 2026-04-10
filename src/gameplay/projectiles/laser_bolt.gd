## LaserBolt — Pooled player laser projectile.
class_name LaserBolt
extends Area2D

const COLOR_PLAYER := Color(0.0, 0.9, 1.0)
const COLOR_ENEMY := Color(1.0, 0.27, 0.0)
const COLOR_WARN := Color(1.0, 0.0, 0.67)

var _damage: int = 8
var _velocity: Vector2 = Vector2.ZERO
var _speed: float = 400.0
var _owner_type: String = "player"  # "player" or "enemy"
var _lifetime: float = 0.0
const MAX_LIFETIME := 1.2

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func setup(damage: int, direction: Vector2, speed: float, owner_type: String = "player") -> void:
	_damage = damage
	_velocity = direction.normalized() * speed
	_speed = speed
	_owner_type = owner_type
	_lifetime = 0.0
	rotation = direction.angle() + PI / 2.0
	if owner_type == "player":
		add_to_group("player_bullets")
		collision_layer = 4
		collision_mask = 18  # 2=enemies + 16=hazards
	else:
		add_to_group("enemy_bullets")
		collision_layer = 8
		collision_mask = 1   # hits player layer

func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		_return_to_pool()
		return
	global_position += _velocity * delta
	# Despawn off-screen
	var vp := get_viewport_rect()
	if global_position.y < -20 or global_position.y > vp.size.y + 20:
		_return_to_pool()
	queue_redraw()

func _draw() -> void:
	var col: Color
	match _owner_type:
		"player": col = COLOR_PLAYER
		"enemy_warrior": col = COLOR_WARN
		_: col = COLOR_ENEMY
	# Draw bolt: 2×8 rect
	draw_rect(Rect2(-1, -4, 2, 8), col)
	# Glow tip
	draw_circle(Vector2(0, -4), 1.5, Color(col.r, col.g, col.b, 0.5))

func _on_area_entered(area: Area2D) -> void:
	if _owner_type == "player":
		if area.is_in_group("enemies") or area.is_in_group("hazards"):
			if area.has_method("take_damage"):
				area.take_damage(_damage)
			_return_to_pool()
	elif area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(_damage)
		_return_to_pool()

func _on_body_entered(body: Node2D) -> void:
	if _owner_type == "player":
		if body.is_in_group("enemies") or body.is_in_group("hazards"):
			if body.has_method("take_damage"):
				body.take_damage(_damage)
			_return_to_pool()
	elif body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(_damage)
		_return_to_pool()

func _return_to_pool() -> void:
	remove_from_group("player_bullets")
	remove_from_group("enemy_bullets")
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()

func reset() -> void:
	_lifetime = 0.0
