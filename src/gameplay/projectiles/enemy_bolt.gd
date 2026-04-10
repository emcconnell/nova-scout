## EnemyBolt — Enemy laser projectile.
## Spawned directly by enemies (no pool needed — bounded by arena/screen).
class_name EnemyBolt
extends Area2D

const COLOR_ORANGE := Color(1.0, 0.27, 0.0)
const COLOR_PURPLE := Color(0.80, 0.10, 1.00)
const COLOR_WARN   := Color(1.0, 0.00, 0.67)

var _damage: int = 8
var _velocity: Vector2 = Vector2.DOWN * 180.0
var _color: Color = COLOR_ORANGE
var _lifetime: float = 0.0
const MAX_LIFETIME := 3.0

func _ready() -> void:
	add_to_group("enemy_bullets")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func setup(damage: int, direction: Vector2, speed: float, variant: String = "scout") -> void:
	_damage = damage
	_velocity = direction.normalized() * speed
	_color = COLOR_PURPLE if variant == "warrior" else COLOR_ORANGE
	rotation = direction.angle() + PI / 2.0
	collision_layer = 8
	collision_mask = 1   # hits player layer

func _process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		queue_free()
		return
	global_position += _velocity * delta
	var vp := get_viewport_rect()
	if global_position.y > vp.size.y + 24 or global_position.y < -24 \
	or global_position.x < -10 or global_position.x > vp.size.x + 10:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-1, -4, 2, 8), _color)
	draw_circle(Vector2(0, -4), 1.2, Color(_color.r, _color.g, _color.b, 0.5))

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(_damage, "laser")
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(_damage, "laser")
		queue_free()
