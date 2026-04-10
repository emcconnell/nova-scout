## Asteroid — Drifting hazard in 3 sizes. Splits on destruction.
## Area2D-based: movement is manual, collision via signals.
class_name Asteroid
extends Area2D

signal destroyed(pos: Vector2, tier: int)

enum SizeTier { LARGE = 0, MEDIUM = 1, SMALL = 2 }

const DAMAGE  := [20, 12, 6]
const SCORE   := [50, 25, 10]
const RADII   := [12.0, 7.0, 4.0]
const HP      := [3, 2, 1]
const COLOR_ROCK  := Color(0.55, 0.53, 0.48)
const COLOR_CRACK := Color(0.38, 0.35, 0.30)

var size_tier: int = SizeTier.LARGE
var _hp: int = 3
var _dead: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _shape_pts: PackedVector2Array = PackedVector2Array()

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("hazards")
	monitoring = true
	monitorable = true
	collision_layer = 16
	collision_mask = 5   # 1=player + 4=player bullets
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func setup(tier: int, vel: Vector2) -> void:
	size_tier = clampi(tier, 0, 2)
	_hp = HP[size_tier]
	_dead = false
	_velocity = vel
	_build_shape()
	_resize_collision()

func _build_shape() -> void:
	var radius: float = RADII[size_tier]
	var count: int = [8, 6, 5][size_tier]
	_shape_pts = PackedVector2Array()
	for i in count:
		var angle: float = TAU / count * i + randf_range(-0.25, 0.25)
		var r: float = radius * randf_range(0.72, 1.0)
		_shape_pts.append(Vector2(cos(angle) * r, sin(angle) * r))

func _resize_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = RADII[size_tier]

# ─── Per-frame ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _dead:
		return
	global_position += _velocity * delta
	rotation       += 0.9 * delta * (1.0 if _velocity.x >= 0 else -1.0)
	# Despawn when far below screen
	if global_position.y > get_viewport_rect().size.y + 60:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if _shape_pts.size() < 3:
		return
	draw_colored_polygon(_shape_pts, COLOR_ROCK)
	# Simple crack lines for texture
	if size_tier == SizeTier.LARGE and _shape_pts.size() >= 4:
		draw_line(_shape_pts[0] * 0.3, _shape_pts[2] * 0.6, COLOR_CRACK, 1.0)
		draw_line(_shape_pts[1] * 0.4, _shape_pts[3] * 0.5, COLOR_CRACK, 1.0)

# ─── Damage & Destruction ─────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if _dead:
		return
	_hp -= amount
	if _hp <= 0:
		_destroy()

func _on_area_entered(area: Area2D) -> void:
	# Laser bolts call take_damage directly via their own handler.
	# This handler is a fallback for any area not covered.
	if area.is_in_group("player_bullets") and area.has_method("take_damage"):
		pass  # laser_bolt handles the call

func _on_body_entered(body: Node2D) -> void:
	if _dead:
		return
	if body.is_in_group("player"):
		body.take_damage(DAMAGE[size_tier], "hull")
		_destroy()

func _destroy() -> void:
	if _dead:
		return
	_dead = true
	GameManager.add_score(SCORE[size_tier])
	GameManager.enemies_destroyed += 1
	AudioManager.play_sfx("asteroid_break")
	destroyed.emit(global_position, size_tier)
	_try_drop_loot()
	queue_free()

func _try_drop_loot() -> void:
	var roll := randf()
	if roll < 0.30:
		get_tree().call_group("game_world", "spawn_pickup", global_position, "fuel_cell")
	elif roll < 0.50:
		get_tree().call_group("game_world", "spawn_pickup", global_position, "crystal")
