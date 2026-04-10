## CRTOverlay — Applies scanline + vignette post-process via ColorRect + shader.
## Brief chromatic aberration triggered on player hit.
## GDD Ref: gameplay-mechanics.md §8
extends ColorRect

const ABERRATION_HIT_AMOUNT := 0.008
const ABERRATION_DECAY      := 8.0

var _aberration: float = 0.0
var _player: Player = null
var _mat: ShaderMaterial = null

func _ready() -> void:
	material = ShaderMaterial.new()
	_mat = material as ShaderMaterial
	var shader := load("res://assets/shaders/crt_overlay.gdshader") as Shader
	if shader:
		_mat.shader = shader
		_mat.set_shader_parameter("scanline_strength", 0.12)
		_mat.set_shader_parameter("vignette_strength", 0.35)
		_mat.set_shader_parameter("aberration_amount", 0.0)
	anchor_right  = 1.0
	anchor_bottom = 1.0
	color = Color(0, 0, 0, 0)  # Transparent — shader does the work
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50

func connect_player(p: Player) -> void:
	_player = p
	p.health.hull_changed.connect(func(_v): _trigger_aberration())

func _trigger_aberration() -> void:
	_aberration = ABERRATION_HIT_AMOUNT

func _process(delta: float) -> void:
	if _aberration > 0.0:
		_aberration = maxf(_aberration - ABERRATION_DECAY * delta * _aberration, 0.0)
		if _mat:
			_mat.set_shader_parameter("aberration_amount", _aberration)
