## DerelictShip — Shootable abandoned hull. Drops loot when destroyed.
## GDD Ref: gameplay-mechanics.md §4 — Derelict Ship encounter.
class_name DerelictShip
extends Area2D

signal destroyed(pos: Vector2)

const HULL_HP := 40
const DRIFT_SPEED := 12.0

var _hp: int = HULL_HP
var _dead: bool = false
var _hit_flash_timer: float = 0.0
var _wobble: float = 0.0
var _velocity: Vector2 = Vector2(0, DRIFT_SPEED)
## Precomputed hulk geometry — seeded once in _ready, never randf in _draw.
var _hulk: DerelictShipRenderer.HulkData = null
## Textured hull sprite (art bible v4.0 "Textured Light") — under the
## procedural window/rim/antenna FX drawn by DerelictShipRenderer.
var _body: Sprite2D = null

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

	# Seeded wrecked-hulk geometry — precomputed, never randf in _draw.
	_hulk = DerelictShipRenderer.build(int(get_instance_id()))
	# Baked hull slab + plating + breach hole + wing stub. Windows, salvage
	# glints, and the antenna/rim light stay procedural on top.
	_body = TextureKit.fade_body(self, "hazards", "derelict")

func _process(delta: float) -> void:
	if _dead:
		return
	_wobble += delta * 1.5
	global_position += _velocity * delta

	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
	TextureKit.set_flash(_body, 1.0 if _hit_flash_timer > 0.0 else 0.0)

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
	get_tree().call_group("game_world", "spawn_explosion", global_position, Explosion.Type.DERELICT)
	destroyed.emit(global_position)
	GameManager.add_score(50)
	get_tree().call_group("game_world", "spawn_score_popup", global_position, "+50")
	queue_free()

## Wrecked survey-probe hulk — dead sibling of the SP-7, drawn via DerelictShipRenderer.
## Hull is a baked body sprite (_body); this only draws the procedural FX on top.
func _draw() -> void:
	if _hulk == null:
		return
	DerelictShipRenderer.draw(self, _hulk, _wobble)
