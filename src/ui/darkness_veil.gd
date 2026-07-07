## DarknessVeil — Radial visibility falloff for sectors 3–5.
## The player's ship glow is the brightest thing on screen; everything else
## emerges from murk. Radius per sector from assets/data/dread.json; the
## Mothership arena is exempt (the boss lights the field).
## GDD Ref: dark-directive.md §4.2 Darkness system
class_name DarknessVeil
extends ColorRect

var _mat: ShaderMaterial = null
var _player: Player = null
var _current_alpha: float = 0.0
var _boss_check_timer: float = 0.0
var _boss_present: bool = false

func _ready() -> void:
	material = ShaderMaterial.new()
	_mat = material as ShaderMaterial
	var shader := load("res://assets/shaders/post_darkness_falloff.gdshader") as Shader
	if shader:
		_mat.shader = shader
	anchor_right = 1.0
	anchor_bottom = 1.0
	color = Color(0, 0, 0, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 30   # Above world entities, below enemy projectiles (35) and HUD

func connect_player(p: Player) -> void:
	_player = p

## Sector darkness radius; 0 disables the veil entirely.
func _sector_radius() -> float:
	var radii: Variant = GameManager.dread_value("darkness", "sector_radius", {})
	if radii is Dictionary:
		return float((radii as Dictionary).get(str(GameManager.current_sector), 0.0))
	return 0.0

func _process(delta: float) -> void:
	if _mat == null or _player == null or not is_instance_valid(_player):
		visible = false
		return

	var radius := _sector_radius()
	var dread_scale := clampf(float(SaveManager.get_setting("dread_intensity")), 0.0, 1.0)
	var state := GameManager.current_state
	var active := radius > 0.0 and dread_scale > 0.0 and state in [
		GameManager.GameState.TRAVEL,
		GameManager.GameState.STAR_CLUSTER,
		GameManager.GameState.SCANNING,
		GameManager.GameState.ALIEN_COMBAT,
	]
	# Mothership arena exemption — poll cheaply, not every frame
	_boss_check_timer -= delta
	if _boss_check_timer <= 0.0:
		_boss_check_timer = 0.5
		_boss_present = false
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is EnemyBase and (e as EnemyBase).drop_table == "mothership":
				_boss_present = true
				break
	if _boss_present:
		active = false

	# Fade the veil in/out rather than snapping
	var target_alpha: float = float(GameManager.dread_value("darkness", "max_alpha", 0.82)) * dread_scale if active else 0.0
	_current_alpha = lerpf(_current_alpha, target_alpha, delta * 2.0)
	visible = _current_alpha > 0.01
	if not visible:
		return

	# Boost flares the engine — light radius grows 20%
	var boost_mult := 1.2 if _player.is_boosting() else 1.0
	# Scanning pulls the walls in — the scan iris (dark-directive.md §4.1)
	var scan_mult := 0.8 if GameManager.get_threat() > 0.55 else 1.0

	_mat.set_shader_parameter("light_pos", _player.global_position)
	_mat.set_shader_parameter("viewport_size", get_viewport_rect().size)
	_mat.set_shader_parameter("light_radius", radius * boost_mult * scan_mult)
	_mat.set_shader_parameter("edge_softness", float(GameManager.dread_value("darkness", "edge_softness", 55.0)))
	_mat.set_shader_parameter("max_alpha", _current_alpha)

	# TURN 4 flood cone — the beam is the renderer in the dead frequency.
	var half_angle: float = deg_to_rad(float(VisualState.value("beam", "half_angle_deg", 17.0)))
	var soft: float = deg_to_rad(float(VisualState.value("beam", "edge_softness_deg", 8.0)))
	_mat.set_shader_parameter("beam_dir", Vector2.UP)
	_mat.set_shader_parameter("beam_range", float(VisualState.value("beam", "range", 130.0)))
	_mat.set_shader_parameter("beam_cos_half", cos(half_angle))
	_mat.set_shader_parameter("beam_cos_soft", cos(half_angle + soft))
	_mat.set_shader_parameter("beam_strength", VisualState.beam_strength())
	# Murk hue fades blue-black (survey) → red-black (dead frequency).
	_mat.set_shader_parameter("dark_color",
		VisualState.col(Color(0.012, 0.014, 0.032), Color(0.03, 0.008, 0.006)))
