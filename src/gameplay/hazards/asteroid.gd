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

var size_tier: int = SizeTier.LARGE
var _hp: int = 3
var _dead: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _body: Sprite2D = null
var _instance_seed: int = 0

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("hazards")
	# monitoring and monitorable default true on Area2D — don't set explicitly
	# to avoid "can't change monitoring state during physics query" errors
	collision_layer = 16
	collision_mask = 5   # 1=player + 4=player bullets
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

## Configures tier/velocity and picks a baked rock variant (art bible v4.0):
## textured + normal-mapped, shaded live by the sun light. No spin — the
## slight fixed rotation per instance keeps variants from reading as clones.
func setup(tier: int, vel: Vector2) -> void:
	size_tier = clampi(tier, 0, 2)
	_hp = HP[size_tier]
	_dead = false
	_velocity = vel
	_instance_seed = int(get_instance_id()) ^ (size_tier * 104729)
	if _body:
		_body.queue_free()
	_body = TextureKit.fade_body(self, "hazards", "rock_%d" % (absi(_instance_seed) % 3))
	# baked at r=12 units, 12 px/unit; scale to this tier's radius. No mirror
	# flips — they would invert the normal map's X and break sun shading.
	_body.scale = Vector2.ONE * (RADII[size_tier] / 12.0 / 12.0)
	_resize_collision()

func _resize_collision() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = RADII[size_tier]

# ─── Per-frame ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _dead:
		return
	global_position += _velocity * delta
	# Despawn when far below screen
	if global_position.y > get_viewport_rect().size.y + 60:
		queue_free()

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
	call_deferred("queue_free")

func _try_drop_loot() -> void:
	var roll := randf()
	if roll < 0.30:
		get_tree().call_group("game_world", "spawn_pickup", global_position, "fuel_cell")
	elif roll < 0.50:
		get_tree().call_group("game_world", "spawn_pickup", global_position, "crystal")
