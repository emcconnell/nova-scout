## CRTOverlay — Applies scanline + vignette post-process via ColorRect + shader.
## Brief chromatic aberration triggered on player hit.
## GDD Ref: gameplay-mechanics.md §8
extends ColorRect

const ABERRATION_HIT_AMOUNT := 0.008
const ABERRATION_DECAY      := 8.0
const ROLL_DECAY            := 2.2

var _aberration: float = 0.0
var _interference: float = 0.0   # Smoothed threat-driven static
var _signal_roll: float = 0.0    # Event-pulsed sync loss
var _player: Player = null
var _mat: ShaderMaterial = null

func _ready() -> void:
	add_to_group("crt_overlay")   # Event systems pulse the signal roll via group call
	material = ShaderMaterial.new()
	_mat = material as ShaderMaterial
	var shader := load("res://assets/shaders/crt_overlay.gdshader") as Shader
	if shader:
		_mat.shader = shader
		_mat.set_shader_parameter("scanline_strength", 0.12)
		_mat.set_shader_parameter("vignette_strength", 0.35)
		_mat.set_shader_parameter("aberration_amount", 0.0)
		_mat.set_shader_parameter("interference", 0.0)
		_mat.set_shader_parameter("signal_roll", 0.0)
	anchor_right  = 1.0
	anchor_bottom = 1.0
	color = Color(0, 0, 0, 0)  # Transparent — shader does the work
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	_apply_accessibility_settings()

func connect_player(p: Player) -> void:
	_player = p
	p.health.hull_changed.connect(func(_v): _trigger_aberration())

func _trigger_aberration() -> void:
	_apply_accessibility_settings()
	_aberration = ABERRATION_HIT_AMOUNT * clampf(float(SaveManager.get_setting("flash_intensity")), 0.0, 1.0)

func _apply_accessibility_settings() -> void:
	visible = bool(SaveManager.get_setting("crt_enabled"))
	if _mat:
		var flash_multiplier := clampf(float(SaveManager.get_setting("flash_intensity")), 0.0, 1.0)
		_mat.set_shader_parameter("scanline_strength", 0.12 * flash_multiplier)
		_mat.set_shader_parameter("vignette_strength", 0.35 if visible else 0.0)

## Pulse a horizontal sync-loss roll — used on major events (stalker decloak,
## sector arrival, boss phase change).
func pulse_signal_roll(strength: float = 0.8) -> void:
	_signal_roll = maxf(_signal_roll, clampf(strength, 0.0, 1.0))

func _process(delta: float) -> void:
	_apply_accessibility_settings()
	if _mat == null:
		return
	if _aberration > 0.0:
		_aberration = maxf(_aberration - ABERRATION_DECAY * delta * _aberration, 0.0)
		_mat.set_shader_parameter("aberration_amount", _aberration)

	# Interference tracks the aggregate threat level — the display is the
	# motion tracker (dark-directive.md §4.2). Scaled by the DREAD setting.
	var dread_scale := clampf(float(SaveManager.get_setting("dread_intensity")), 0.0, 1.0)
	var target := GameManager.get_threat() * 0.85 * dread_scale
	_interference = lerpf(_interference, target, delta * 3.0)
	_mat.set_shader_parameter("interference", _interference)

	if _signal_roll > 0.001:
		_signal_roll = maxf(_signal_roll - ROLL_DECAY * delta * _signal_roll, 0.0)
	_mat.set_shader_parameter("signal_roll", _signal_roll * dread_scale)
