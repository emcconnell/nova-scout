## EnemyBase — Base class for all alien enemies.
## Handles HP, damage, scoring, drop table, stun, and death signals.
## Implements TR-003 (Enemy System) from technical-architecture.md.
class_name EnemyBase
extends Area2D

# ─── Signals ─────────────────────────────────────────────────────────────────
signal died(pos: Vector2, drop_table: String)

# ─── State ───────────────────────────────────────────────────────────────────
var hp: int = 20
var max_hp: int = 20
var contact_damage: int = 10
var score_value: int = 100
var drop_table: String = "scout"   # key into drop logic
var _dead: bool = false
var _stunned: bool = false
var _stun_timer: float = 0.0
var _hit_flash_timer: float = 0.0

# Injected by game world
var enemy_projectile_container: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	body_entered.connect(_on_body_entered)
	collision_layer = 2
	collision_mask = 5   # 1=player + 4=player_bullets
	# Scale HP by sector intensity after subclass _ready sets base values (Change 4)
	call_deferred("_apply_sector_scaling")

func _process(delta: float) -> void:
	if _dead:
		return
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
	if _stunned:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			_stunned = false
	_update(delta)
	queue_redraw()

## Override in subclass for per-frame behavior.
func _update(_delta: float) -> void:
	pass

## Scale HP by sector after subclass _ready has run (Change 4).
func _apply_sector_scaling() -> void:
	if GameManager.current_sector <= 1:
		return
	if score_value >= 1000:   # Elites/bosses have hp_scale; skip
		return
	var mult: float = 1.0 + float(GameManager.current_sector - 1) * 0.10
	hp = int(float(hp) * mult)
	max_hp = hp

## Returns base fire interval reduced by sector fire-rate scaling (Change 4).
func _scaled_interval(base: float) -> float:
	var mult: float = 1.0 + float(GameManager.current_sector - 1) * 0.12
	return base / mult

func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	var actual := _modify_damage(amount, from_position)
	hp -= actual
	_hit_flash_timer = 0.08
	if hp <= 0:
		_die()

## Override in subclass to apply damage modifiers (e.g. front shield).
func _modify_damage(amount: int, _from: Vector2) -> int:
	return amount

func stun(duration: float) -> void:
	_stunned = true
	_stun_timer = maxf(_stun_timer, duration)

func _on_body_entered(body: Node2D) -> void:
	if _dead:
		return
	if body.is_in_group("player"):
		body.take_damage(contact_damage, "hull")
		_die()

func _die() -> void:
	if _dead:
		return
	_dead = true
	GameManager.add_score(score_value)
	GameManager.enemies_destroyed += 1
	GameManager.on_enemy_killed()  # Streak tracking (Change 7c)
	died.emit(global_position, drop_table)
	AudioManager.play_sfx("enemy_explode")
	# Score popup
	get_tree().call_group("game_world", "spawn_score_popup", global_position, "+%d" % score_value)
	call_deferred("queue_free")

## Helper — spawn an enemy bolt toward a direction.
func _fire_bolt(direction: Vector2, damage: int, speed: float, variant: String = "scout") -> void:
	if enemy_projectile_container == null:
		return
	var bolt := preload("res://scenes/projectiles/enemy_bolt.tscn").instantiate() as EnemyBolt
	enemy_projectile_container.add_child(bolt)
	bolt.global_position = global_position
	bolt.setup(damage, direction, speed, variant)

## Helper — aim at player's current position.
func _aim_at_player() -> Vector2:
	var p := get_tree().get_first_node_in_group("player")
	if p:
		return (p.global_position - global_position).normalized()
	return Vector2.DOWN

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

## Draw flash overlay — call from subclass _draw() after own drawing.
func _draw_hit_flash() -> void:
	if _hit_flash_timer > 0.0:
		draw_rect(Rect2(-16, -16, 32, 32), Color(1, 1, 1, 0.5))
