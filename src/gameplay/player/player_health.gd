## PlayerHealth — Manages hull and shield stats.
class_name PlayerHealth
extends Node

signal hull_changed(value: int)
signal shield_changed(value: int)
signal died()

const SHIELD_REGEN_DELAY := 3.0

var hull: int = 100
var shield: int = 60
var _max_hull: int = 100
var _max_shield: int = 100
var _shield_regen_rate: float = 5.0
var _no_hit_timer: float = 0.0
var _is_dead: bool = false

func _ready() -> void:
	_sync_from_manager()

func _sync_from_manager() -> void:
	hull = GameManager.player_hull
	_max_hull = GameManager.player_max_hull
	_shield_regen_rate = GameManager.player_shield_regen
	shield = GameManager.player_shield

func _process(delta: float) -> void:
	if _is_dead:
		return
	_no_hit_timer += delta
	if _no_hit_timer >= SHIELD_REGEN_DELAY and shield < _max_shield:
		shield = mini(shield + int(_shield_regen_rate * delta), _max_shield)
		GameManager.player_shield = shield
		shield_changed.emit(shield)

func take_damage(amount: int) -> void:
	if _is_dead:
		return
	_no_hit_timer = 0.0
	var remaining := amount
	if shield > 0:
		var absorbed := mini(shield, remaining)
		shield -= absorbed
		remaining -= absorbed
		GameManager.player_shield = shield
		shield_changed.emit(shield)
	if remaining > 0:
		hull -= remaining
		hull = maxi(hull, 0)
		GameManager.player_hull = hull
		hull_changed.emit(hull)
		if hull <= 0:
			_die()

func heal_hull(amount: int) -> void:
	hull = mini(hull + amount, _max_hull)
	GameManager.player_hull = hull
	hull_changed.emit(hull)

func heal_shield(amount: int) -> void:
	shield = mini(shield + amount, _max_shield)
	GameManager.player_shield = shield
	shield_changed.emit(shield)

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	died.emit()

func reset() -> void:
	_is_dead = false
	_sync_from_manager()
	hull_changed.emit(hull)
	shield_changed.emit(shield)
