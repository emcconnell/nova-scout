## Missile — Homing player missile with explosion AoE.
class_name Missile
extends Area2D

const SPEED := 220.0
const TURN_SPEED := 3.5   # radians/sec
const DAMAGE := 60
const AOE_RADIUS := 40.0
const HULL_DARK  := Color(0.229, 0.251, 0.290)
const HULL_LIGHT := Color(0.788, 0.812, 0.847)

var _target: Node2D = null
var _velocity: Vector2 = Vector2.UP * SPEED
var _lifetime: float = 0.0
var _trail: Array[Vector2] = []
var _returning_to_pool: bool = false
const MAX_LIFETIME := 4.0
const TRAIL_LEN := 8

## Small warm exhaust light (art bible v4.0 "Textured Light"). Missiles are
## pooled — created once here so it persists across setup()/reset() reuse
## rather than being rebuilt on every activation.
var _light: PointLight2D = null

func _ready() -> void:
	add_to_group("player_bullets")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	_light = TextureKit.point_light(self, 18.0, Color(1.0, 0.62, 0.35), 0.5)
	_light.position = Vector2(0, 3.0)   # near the exhaust flame

func setup(damage: int, target: Node2D) -> void:
	_target = target
	_lifetime = 0.0
	_trail.clear()
	_returning_to_pool = false

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

## Metal-hull nose cone + proj "flame" exhaust glow + flickering shock diamonds.
func _draw() -> void:
	var t := _lifetime
	var flame := VisualState.proj("flame")

	# ── Smoky fading trail ──
	for i in _trail.size():
		var pt := to_local(_trail[i])
		var frac := float(i) / float(TRAIL_LEN)
		var alpha := (1.0 - frac) * 0.45
		var size := 2.0 - frac * 1.2
		var smoke := flame.lerp(Color(0.5, 0.4, 0.35), frac)
		draw_circle(pt, size, Color(smoke.r, smoke.g, smoke.b, alpha))
		# Slight random offset for smokiness using time
		var jx := sin(t * 8.0 + float(i) * 2.3) * 0.8
		var jy := cos(t * 7.0 + float(i) * 1.7) * 0.6
		draw_circle(pt + Vector2(jx, jy), size * 0.6, Color(smoke.r, smoke.g, smoke.b, alpha * 0.5))

	# ── Exhaust flame glow (animated, behind the body) ──
	var flame_flicker := sin(t * 18.0) * 0.3 + 0.7
	DrawKit.glow(self, Vector2(0, 4.0), 3.0 * flame_flicker, Color(flame.r, flame.g, flame.b, 0.65), 4)
	draw_circle(Vector2(0, 3.5), 1.2 * flame_flicker, Color(1.0, 0.9, 0.85, 0.85))

	# Shock-diamond flicker: 3 small bright rhombi at increasing distance, falling alpha.
	var diamond_phase := int(t * 8.0) % 3   # 8fps flicker cycle, matches concept cadence
	var diamond_alphas := [0.8, 0.55, 0.32]
	for di in 3:
		var dy := 5.0 + float(di) * 1.6
		var dsize := 0.9 - float(di) * 0.15 + (0.15 if di == diamond_phase else 0.0)
		var da: float = diamond_alphas[di]
		var dpts := PackedVector2Array([
			Vector2(0, dy - dsize), Vector2(dsize * 0.6, dy),
			Vector2(0, dy + dsize), Vector2(-dsize * 0.6, dy),
		])
		draw_colored_polygon(dpts, Color(flame.r, flame.g, flame.b, da))

	# ── Missile body — tapered nose cone, metal hull ramp ──
	var body_rect := Rect2(-1.5, -3, 3.0, 6.0)
	DrawKit.hgrad_rect(self, body_rect, HULL_DARK, HULL_LIGHT, 5)
	var nose_pts := PackedVector2Array([
		Vector2(0, -6), Vector2(-1.5, -3), Vector2(1.5, -3),
	])
	draw_colored_polygon(nose_pts, HULL_LIGHT.lerp(HULL_DARK, 0.3))

	# Fins
	draw_line(Vector2(-1.5, 2.0), Vector2(-3.0, 4.0), HULL_LIGHT.lerp(HULL_DARK, 0.4), 1.0)
	draw_line(Vector2(1.5, 2.0), Vector2(3.0, 4.0), HULL_LIGHT.lerp(HULL_DARK, 0.4), 1.0)

	# Nose highlight
	draw_circle(Vector2(0, -5.5), 0.8, Color(1.0, 1.0, 1.0, 0.5))

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
	get_tree().call_group("game_world", "spawn_explosion", global_position, Explosion.Type.MISSILE_HIT)
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
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()

func reset() -> void:
	_target = null
	_lifetime = 0.0
	_trail.clear()
	_returning_to_pool = false
