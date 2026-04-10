## EnemyHpBar — Thin HP bar that appears above an enemy when hit, fades after 2s.
## GDD Ref: polish — E11-03
## Attach this as a child Node2D to any enemy scene.
class_name EnemyHpBar
extends Node2D

const BAR_W    := 20.0
const BAR_H    := 2.0
const FADE_DUR := 2.0
const COL_BG   := Color(0.10, 0.05, 0.10)
const COL_HP   := Color(0.90, 0.10, 0.90)

var _fade_timer: float = 0.0
var _visible_flag: bool = false
var _hp_pct: float = 1.0

func show_hit(hp: int, max_hp: int) -> void:
	_hp_pct = float(hp) / maxf(max_hp, 1)
	_fade_timer = FADE_DUR
	_visible_flag = true
	queue_redraw()

func _process(delta: float) -> void:
	if not _visible_flag:
		return
	_fade_timer -= delta
	if _fade_timer <= 0.0:
		_visible_flag = false
	queue_redraw()

func _draw() -> void:
	if not _visible_flag:
		return
	var alpha := clampf(_fade_timer / FADE_DUR, 0.0, 1.0)
	var y := -22.0
	draw_rect(Rect2(-BAR_W * 0.5, y, BAR_W, BAR_H), Color(COL_BG.r, COL_BG.g, COL_BG.b, alpha))
	var fill := _hp_pct * BAR_W
	if fill > 0.0:
		draw_rect(Rect2(-BAR_W * 0.5, y, fill, BAR_H), Color(COL_HP.r, COL_HP.g, COL_HP.b, alpha))
