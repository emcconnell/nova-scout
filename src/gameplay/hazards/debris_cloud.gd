## DebrisCloud — Hazard area that slows the player and deals damage over time.
class_name DebrisCloud
extends Area2D

const DAMAGE_PER_SEC := 3.0
const COLOR_OUTER    := Color(0.40, 0.35, 0.28, 0.38)
const COLOR_INNER    := Color(0.50, 0.42, 0.32, 0.28)
const COLOR_PARTICLE := Color(0.60, 0.52, 0.40, 0.55)

var _players_inside: Array[Node] = []
var _damage_tick: float = 0.0
var _radius: float = 30.0
var velocity: Vector2 = Vector2(0, 22)   # Drifts downward by default

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("hazards")
	monitoring = true
	collision_layer = 16
	collision_mask = 1   # 1=player only
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Read radius from collision shape
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is CircleShape2D:
		_radius = (col.shape as CircleShape2D).radius

# ─── Per-frame ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	global_position += velocity * delta
	if global_position.y > get_viewport_rect().size.y + 60:
		_release_all_players()
		queue_free()
		return
	if _players_inside.is_empty():
		return
	_damage_tick += delta
	if _damage_tick >= 1.0:
		_damage_tick = 0.0
		for player in _players_inside:
			if is_instance_valid(player) and player.has_method("take_damage"):
				player.take_damage(int(DAMAGE_PER_SEC), "debris")

func _draw() -> void:
	# Static layered cloud look — no randf in draw to avoid flicker
	draw_circle(Vector2.ZERO, _radius, COLOR_OUTER)
	draw_circle(Vector2(-8, -4), _radius * 0.65, COLOR_INNER)
	draw_circle(Vector2(10, 6),  _radius * 0.55, COLOR_INNER)
	# Static debris dots (deterministic positions)
	var offsets := [
		Vector2(-15, -8), Vector2(12, -14), Vector2(-6, 16),
		Vector2(18, 4), Vector2(-18, 8), Vector2(5, -18),
	]
	for o in offsets:
		draw_circle(o, 1.5, COLOR_PARTICLE)

# ─── Player Detection ────────────────────────────────────────────────────────

func _release_all_players() -> void:
	for body in _players_inside:
		if is_instance_valid(body) and body.has_method("exit_debris"):
			body.exit_debris()
	_players_inside.clear()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_players_inside.append(body)
		if body.has_method("enter_debris"):
			body.enter_debris()

func _on_body_exited(body: Node2D) -> void:
	if _players_inside.has(body):
		_players_inside.erase(body)
		if body.has_method("exit_debris"):
			body.exit_debris()
