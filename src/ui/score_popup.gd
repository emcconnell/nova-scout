## ScorePopup — Floating score text that rises and fades.
## Tinted live to VisualState.pal("hud")/pal("accent") — same fade family as the HUD.
## GDD Ref: polish — E11-04
class_name ScorePopup
extends Node2D

const RISE_SPEED := 22.0
const LIFETIME   := 1.2

var _text: String = ""
var _timer: float = 0.0
var _is_item: bool = false

## Configure the popup text and whether it uses the item (accent) or score (hud) tint.
func setup(text: String, is_item: bool = false) -> void:
	_text  = text
	_is_item = is_item

func _process(delta: float) -> void:
	_timer += delta
	global_position.y -= RISE_SPEED * delta
	if _timer >= LIFETIME:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var alpha := 1.0 - (_timer / LIFETIME)
	var font := ThemeDB.fallback_font
	var col := VisualState.pal("accent") if _is_item else VisualState.pal("hud")
	draw_string(font, Vector2(-12, 0), _text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(col.r, col.g, col.b, alpha))
