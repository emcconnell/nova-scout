## LaserBolt — Pooled player laser projectile.
class_name LaserBolt
extends Area2D

var _damage: int = 8
var _velocity: Vector2 = Vector2.ZERO
var _speed: float = 400.0
var _owner_type: String = "player"  # "player" or "enemy"
var _lifetime: float = 0.0
var _returning_to_pool: bool = false
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
	_returning_to_pool = false
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

## Rounded-cap laser core + beam-tone underline + glow; cyan survey -> red dead tracer.
func _draw() -> void:
	var beam := VisualState.proj("beam")
	var core := VisualState.proj("core")
	if _owner_type == "enemy_warrior":
		beam = beam.lerp(Color(1.0, 0.0, 0.67), 0.65)

	# Trail — 3 fading copies behind the bolt (in local space, "behind" = +Y)
	for i in range(1, 4):
		var trail_y := float(i) * 4.0
		var trail_a := 0.25 * (1.0 - float(i) / 4.0)
		draw_rect(Rect2(-0.5, -4.0 + trail_y, 1.0, 6.0), Color(beam.r, beam.g, beam.b, trail_a))

	# Outer glow — softer, wider
	var glow_a := 0.15 + 0.05 * sin(_lifetime * 12.0)
	draw_rect(Rect2(-2.5, -5.5, 5.0, 11.0), Color(beam.r, beam.g, beam.b, glow_a))
	DrawKit.glow(self, Vector2(0, -1.0), 4.0, Color(beam.r, beam.g, beam.b, 0.18))

	# Beam-color underline (wider, alpha 0.5) + bright core line
	draw_rect(Rect2(-1.0, -4.5, 2.0, 9.0), Color(beam.r, beam.g, beam.b, 0.5))
	draw_rect(Rect2(-0.5, -4.5, 1.0, 9.0), core)

	# Tip glow — bright front, glowing core
	DrawKit.glow(self, Vector2(0, -4.5), 2.4, Color(beam.r, beam.g, beam.b, 0.5), 3)
	draw_circle(Vector2(0, -4.5), 1.0, core)

func _on_area_entered(area: Area2D) -> void:
	if _owner_type == "player":
		if area.is_in_group("enemies") or area.is_in_group("hazards"):
			if area is EnemyBase:
				# Pass hit origin so light enemies take knockback
				(area as EnemyBase).take_damage(_damage, global_position)
			elif area.has_method("take_damage"):
				area.take_damage(_damage)
			_return_to_pool()
	elif area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(_damage)
		_return_to_pool()

func _on_body_entered(body: Node2D) -> void:
	if _owner_type == "player":
		if body.is_in_group("enemies") or body.is_in_group("hazards"):
			if body is EnemyBase:
				(body as EnemyBase).take_damage(_damage, global_position)
			elif body.has_method("take_damage"):
				body.take_damage(_damage)
			_return_to_pool()
	elif body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(_damage)
		_return_to_pool()

func _return_to_pool() -> void:
	if _returning_to_pool:
		return
	_returning_to_pool = true
	if Engine.is_in_physics_frame():
		call_deferred("_apply_return_to_pool")
		return
	_apply_return_to_pool()

func _apply_return_to_pool() -> void:
	remove_from_group("player_bullets")
	remove_from_group("enemy_bullets")
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()

func reset() -> void:
	_lifetime = 0.0
	_returning_to_pool = false
