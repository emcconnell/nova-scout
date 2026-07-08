## PostStack — v5.0 "Wet Black" always-on cinematic pass: threshold bloom,
## filmic tonemap, and the fade-driven grade (crushed blacks / red lift).
## MUST live on its own CanvasLayer (1), under the FilmLayer (2) so grain
## lands on the graded image: a screen-texture read inside the world canvas
## gets a stale backbuffer copy in GL Compatibility that is missing the
## projectile layer — bolts vanished (measured, Turn 6.1).
## Unlike the CRT overlay this never toggles off: it IS the lens, not a treat.
## Tuning: assets/data/visuals.json → "post". GDD Ref: art-bible.md §0 (v5.0)
class_name PostStack
extends ColorRect

var _mat: ShaderMaterial = null

func _ready() -> void:
	material = ShaderMaterial.new()
	_mat = material as ShaderMaterial
	var shader := load("res://assets/shaders/post_bloom_grade.gdshader") as Shader
	if shader:
		_mat.shader = shader
	# Anchors don't resolve under a Node2D parent — size the rect explicitly
	# to the fixed 320x180 canvas (same fix as DarknessVeil).
	position = Vector2.ZERO
	size = get_viewport_rect().size
	color = Color(0, 0, 0, 0)  # Transparent — shader does the work
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 45
	light_mask = 0  # the lens is not a surface

func _process(_delta: float) -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("exposure", VisualState.post_exposure())
	_mat.set_shader_parameter("bloom_strength", VisualState.bloom_strength())
	_mat.set_shader_parameter("bloom_threshold", VisualState.bloom_threshold())
	_mat.set_shader_parameter("grade_amount", VisualState.grade_amount())
