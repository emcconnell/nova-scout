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
	var t := _lifetime

	# ── Smoky fading trail ──
	for i in _trail.size():
		var pt := to_local(_trail[i])
		var frac := float(i) / float(TRAIL_LEN)
		var alpha := (1.0 - frac) * 0.45
		var size := 2.0 - frac * 1.2
		# Smoke: gray-orange fading to transparent
		var smoke_r := lerpf(1.0, 0.5, frac)
		var smoke_g := lerpf(0.5, 0.4, frac)
		var smoke_b := lerpf(0.15, 0.35, frac)
		draw_circle(pt, size, Color(smoke_r, smoke_g, smoke_b, alpha))
		# Slight random offset for smokiness using time
		var jx := sin(t * 8.0 + float(i) * 2.3) * 0.8
		var jy := cos(t * 7.0 + float(i) * 1.7) * 0.6
		draw_circle(pt + Vector2(jx, jy), size * 0.6, Color(smoke_r, smoke_g, smoke_b, alpha * 0.5))

	# ── Exhaust flame (animated, behind the body) ──
	var flame_flicker := sin(t * 18.0) * 0.3 + 0.7
	# Outer flame — orange
	draw_circle(Vector2(0, 4.5), 2.2 * flame_flicker, Color(1.0, 0.45, 0.05, 0.6))
	# Inner flame — yellow-white
	draw_circle(Vector2(0, 3.5), 1.4 * flame_flicker, Color(1.0, 0.9, 0.4, 0.8))
	# Core — white hot
	draw_circle(Vector2(0, 3.0), 0.7 * flame_flicker, Color(1.0, 1.0, 0.9, 0.9))
	# Exhaust particles — small dots that scatter behind
	for pi in 4:
		var px := sin(t * 14.0 + float(pi) * 1.57) * 1.8
		var py := 5.0 + float(pi) * 1.5 + sin(t * 10.0 + float(pi)) * 0.8
		var pa := 0.5 * (1.0 - float(pi) / 4.0)
		draw_circle(Vector2(px, py), 0.5, Color(1.0, 0.6, 0.1, pa))

	# ── Missile body — tapered nose cone ──
	var body_pts := PackedVector2Array([
		Vector2(0, -6),      # nose tip
		Vector2(-1.5, -3),   # shoulder left
		Vector2(-1.5, 3),    # base left
		Vector2(1.5, 3),     # base right
		Vector2(1.5, -3),    # shoulder right
	])
	draw_colored_polygon(body_pts, COLOR_BODY)

	# Fins
	draw_line(Vector2(-1.5, 2.0), Vector2(-3.0, 4.0), Color(0.7, 0.7, 0.7), 1.0)
	draw_line(Vector2(1.5, 2.0), Vector2(3.0, 4.0), Color(0.7, 0.7, 0.7), 1.0)

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
	_return_to_pool()

func _return_to_pool() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()

func reset() -> void:
	_target = null
	_lifetime = 0.0
	_trail.clear()
