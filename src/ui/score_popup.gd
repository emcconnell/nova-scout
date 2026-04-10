## ScorePopup — Floating score text that rises and fades.
## GDD Ref: polish — E11-04
class_name ScorePopup
extends Node2D

const RISE_SPEED := 22.0
const LIFETIME   := 1.2
const COL_SCORE  := Color(0.22, 1.00, 0.08)
const COL_ITEM   := Color(0.00, 0.80, 1.00)

var _text: String = ""
var _timer: float = 0.0
var _color: Color = COL_SCORE

func setup(text: String, is_item: bool = false) -> void:
	_text  = text
	_color = COL_ITEM if is_item else COL_SCORE

func _process(delta: float) -> void:
	_timer += delta
	global_position.y -= RISE_SPEED * delta
	if _timer >= LIFETIME:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var alpha := 1.0 - (_timer / LIFETIME)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-12, 0), _text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(_color.r, _color.g, _color.b, alpha))
