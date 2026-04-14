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
	var t := _lifetime

	# ── Smoky fading trail ──
	for i in _trail.size():
		var pt := to_local(_trail[i])
		var frac := float(i) / float(TRAIL_LEN)
		var alpha := (1.0 - frac) * 0.4
		var size := 1.8 - frac * 1.0
		# Reddish smoke fading to dark
		var smoke_r := lerpf(1.0, 0.4, frac)
		var smoke_g := lerpf(0.2, 0.25, frac)
		var smoke_b := lerpf(0.0, 0.3, frac)
		draw_circle(pt, size, Color(smoke_r, smoke_g, smoke_b, alpha))
		# Smoke jitter
		var jx := sin(t * 9.0 + float(i) * 2.1) * 0.7
		var jy := cos(t * 7.5 + float(i) * 1.9) * 0.5
		draw_circle(pt + Vector2(jx, jy), size * 0.5, Color(smoke_r, smoke_g, smoke_b, alpha * 0.4))

	# ── Exhaust flame ──
	var flame_flicker := sin(t * 16.0) * 0.3 + 0.7
	# Outer — red-orange
	draw_circle(Vector2(0, 4.5), 2.0 * flame_flicker, Color(1.0, 0.25, 0.0, 0.55))
	# Inner — orange-yellow
	draw_circle(Vector2(0, 3.5), 1.2 * flame_flicker, Color(1.0, 0.7, 0.2, 0.7))
	# Core — white
	draw_circle(Vector2(0, 3.0), 0.6 * flame_flicker, Color(1.0, 0.9, 0.8, 0.85))
	# Exhaust particles
	for pi in 3:
		var px := sin(t * 12.0 + float(pi) * 2.09) * 1.5
		var py := 5.0 + float(pi) * 1.3 + sin(t * 9.0 + float(pi)) * 0.6
		var pa := 0.45 * (1.0 - float(pi) / 3.0)
		draw_circle(Vector2(px, py), 0.4, Color(1.0, 0.3, 0.05, pa))

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
	draw_line(Vector2(-1.5, 2.0), Vector2(-2.8, 4.0), Color(0.6, 0.4, 0.8), 1.0)
	draw_line(Vector2(1.5, 2.0), Vector2(2.8, 4.0), Color(0.6, 0.4, 0.8), 1.0)

	# Nose highlight
	draw_circle(Vector2(0, -5.5), 0.7, Color(1.0, 0.9, 1.0, 0.45))

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
