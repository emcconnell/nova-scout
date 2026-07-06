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
var _grazed: bool = false   # One graze reward per bolt (dark-directive.md §5)
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
	_check_graze()
	var vp := get_viewport_rect()
	if global_position.y > vp.size.y + 24 or global_position.y < -24 \
	or global_position.x < -10 or global_position.x > vp.size.x + 10:
		queue_free()
		return
	queue_redraw()

## Graze — passing close by the player without hitting rewards nerve.
## One reward per bolt; bolts younger than min_bolt_age don't count.
func _check_graze() -> void:
	if _grazed:
		return
	if _lifetime < float(GameManager.dread_value("graze", "min_bolt_age", 0.15)):
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or not is_instance_valid(player):
		return
	var radius: float = float(GameManager.dread_value("graze", "radius", 6.0))
	# Graze band: just outside the hit zone (player collision ~5px core)
	var d := global_position.distance_to(player.global_position)
	if d < radius + 5.0 and d > 4.0:
		_grazed = true
		GameManager.add_score(int(GameManager.dread_value("graze", "score", 5)))
		if player.weapons:
			player.weapons.add_energy(float(GameManager.dread_value("graze", "energy", 1.0)))
		player.on_graze()
		AudioManager.play_sfx("graze_spark", 0.4)

func _draw() -> void:
	# Trail — 3 fading copies behind the bolt
	for i in range(1, 4):
		var trail_y := float(i) * 4.0
		var trail_a := 0.22 * (1.0 - float(i) / 4.0)
		draw_rect(Rect2(-0.5, -4.0 + trail_y, 1.0, 6.0), Color(_color.r, _color.g, _color.b, trail_a))

	# Outer glow
	var glow_a := 0.15 + 0.05 * sin(_lifetime * 14.0)
	draw_rect(Rect2(-2.5, -5.5, 5.0, 11.0), Color(_color.r, _color.g, _color.b, glow_a))

	# Core line
	draw_rect(Rect2(-0.5, -4.5, 1.0, 9.0), _color)
	# Hot center
	draw_rect(Rect2(-0.25, -4.0, 0.5, 8.0), Color(1.0, 1.0, 0.9, 0.7))

	# Tip glow
	draw_circle(Vector2(0, -4.5), 1.8, Color(_color.r, _color.g, _color.b, 0.35))
	draw_circle(Vector2(0, -4.5), 0.9, Color(1.0, 1.0, 0.9, 0.55))

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(_damage, "laser")
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(_damage, "laser")
		queue_free()
