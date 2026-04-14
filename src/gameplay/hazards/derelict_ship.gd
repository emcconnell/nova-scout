## DerelictShip — Shootable abandoned hull. Drops loot when destroyed.
## GDD Ref: gameplay-mechanics.md §4 — Derelict Ship encounter.
class_name DerelictShip
extends Area2D

signal destroyed(pos: Vector2)

const HULL_HP := 40
const DRIFT_SPEED := 12.0

const COL_HULL := Color(0.30, 0.28, 0.25)
const COL_DARK := Color(0.15, 0.13, 0.12)
const COL_GLOW := Color(0.00, 0.70, 0.90, 0.3)

var _hp: int = HULL_HP
var _dead: bool = false
var _hit_flash_timer: float = 0.0
var _wobble: float = 0.0
var _velocity: Vector2 = Vector2(0, DRIFT_SPEED)

func _ready() -> void:
	collision_layer = 16   # hazards layer
	collision_mask = 4     # player bullets
	add_to_group("enemies")

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 16)
	shape.shape = rect
	add_child(shape)

	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_wobble += delta * 1.5
	global_position += _velocity * delta

	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta

	# Remove if off screen
	if global_position.y > get_viewport_rect().size.y + 30:
		queue_free()

	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	# Hit by player projectile
	if area.is_in_group("player_projectiles"):
		var dmg: int = area.get("damage") if "damage" in area else 8
		take_damage(dmg)
		if area.has_method("on_hit"):
			area.on_hit()

func take_damage(amount: int) -> void:
	_hp -= amount
	_hit_flash_timer = 0.08
	AudioManager.play_sfx("hull_hit", 0.6)
	if _hp <= 0:
		_die()

func _die() -> void:
	if _dead:
		return
	_dead = true
	AudioManager.play_sfx("asteroid_large")
	destroyed.emit(global_position)
	GameManager.add_score(50)
	get_tree().call_group("game_world", "spawn_score_popup", global_position, "+50")
	queue_free()

func _draw() -> void:
	var flash := _hit_flash_timer > 0.0
	var hull := Color(1, 1, 1) if flash else COL_HULL
	var dark := Color(1, 1, 1) if flash else COL_DARK

	# Main hull — damaged rectangle
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, -8), Vector2(10, -7),
		Vector2(14, 2), Vector2(12, 8),
		Vector2(-10, 7), Vector2(-14, -2)
	]), hull)

	# Damage hole
	draw_circle(Vector2(3, -1), 4.0, dark)

	# Broken wing strut
	draw_line(Vector2(-14, 0), Vector2(-20, 5), hull, 1.5)

	# Flickering emergency light
	var glow_a: float = 0.15 + 0.25 * abs(sin(_wobble * 3.0))
	draw_circle(Vector2(-6, -4), 2.0, Color(COL_GLOW.r, COL_GLOW.g, COL_GLOW.b, glow_a))
