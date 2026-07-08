## VisualState — TURN 4 "Punched-Up Realism + The Fade" lighting director.
## One 0→1 blend value crossfades every procedurally drawn asset between two
## lighting states that share geometry: SURVEY (4A, hard sun, silent black)
## and DEAD FREQUENCY (4B, ember star, floodlight, wet chitin).
## Autoload — presentation state only, no gameplay state lives here.
## Tuning data: assets/data/visuals.json. GDD Ref: art-bible.md (Turn 4).
extends Node

signal blend_changed(value: float)

const _DATA_PATH := "res://assets/data/visuals.json"

# ─── SURVEY (4A) palette ─────────────────────────────────────────────────────
const SURVEY := {
	"bg": Color("000004"),
	"white": Color("F4F7FA"),
	"gray": Color("9AA3AE"),
	"gold": Color("E3B341"),
	"panel": Color("1B3B73"),
	"accent": Color("00D5FF"),       # HUD / friendly cyan
	"alien": Color("B03BFF"),        # alien bioluminescence
	"hud": Color(0.0, 0.835, 1.0, 0.85),
}

# ─── DEAD FREQUENCY (4B) palette ─────────────────────────────────────────────
const DEAD := {
	"bg": Color("020101"),
	"white": Color("101216"),
	"gray": Color("4E565F"),
	"gold": Color("7A0E12"),
	"panel": Color("101216"),
	"accent": Color("FF2A1D"),       # failing red HUD
	"alien": Color("FF2A3C"),        # eyes in the dark
	"hud": Color(1.0, 0.165, 0.114, 0.8),
}

# ─── Projectile palettes (LASER / MISSILE / EMP / BOLT) ──────────────────────
const PROJ_SURVEY := {
	"beam": Color("7AE8FF"), "core": Color("F2FCFF"),
	"flame": Color("FF9A3C"), "ring": Color("9AE8FF"), "orb": Color("FF3DDC"),
}
const PROJ_DEAD := {
	"beam": Color("FF3B2A"), "core": Color("FFD9D0"),
	"flame": Color("FF6A3C"), "ring": Color("8C939C"), "orb": Color("FF2A3C"),
}

var _data: Dictionary = {}
var _blend: float = 0.0
var _target_blend: float = 0.0
var _player: Node2D = null

func _ready() -> void:
	_load_data()
	process_priority = -100   # settle blend before anything draws this frame

func _load_data() -> void:
	var f := FileAccess.open(_DATA_PATH, FileAccess.READ)
	if f == null:
		push_warning("VisualState: cannot open %s" % _DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		_data = parsed

## Nested JSON lookup with default: value("fade", "lerp_speed", 0.55).
func value(section: String, key: String, def: Variant) -> Variant:
	var sec: Variant = _data.get(section, {})
	if sec is Dictionary:
		return (sec as Dictionary).get(key, def)
	return def

func _process(delta: float) -> void:
	_target_blend = _compute_target()
	var speed := float(value("fade", "lerp_speed", 0.55))
	var prev := _blend
	_blend = move_toward(_blend, _target_blend, speed * delta)
	if not is_equal_approx(prev, _blend):
		blend_changed.emit(_blend)
	# The whole world dims with the fade — including the clear color.
	RenderingServer.set_default_clear_color(SURVEY["bg"].lerp(DEAD["bg"], _blend))
	_update_shader_globals()

## Feeds the textured-body shaders (fade crossfade + flood-cone wet reveal).
## One set per frame — every fade_sprite/creature_sprite material reads these.
func _update_shader_globals() -> void:
	RenderingServer.global_shader_parameter_set("ns_blend", _blend)
	var p := _get_player()
	if p != null:
		RenderingServer.global_shader_parameter_set("ns_player_pos", p.global_position)
	var half := deg_to_rad(float(value("beam", "half_angle_deg", 17.0)))
	var soft := deg_to_rad(float(value("beam", "edge_softness_deg", 8.0)))
	RenderingServer.global_shader_parameter_set("ns_beam", Vector4(
		float(value("beam", "range", 130.0)), cos(half), cos(half + soft),
		beam_strength()))

func _compute_target() -> float:
	var sectors: Variant = value("fade", "sector_blend", {})
	var base := 0.0
	if sectors is Dictionary:
		base = float((sectors as Dictionary).get(str(GameManager.current_sector), 0.0))
	if GameManager.current_state == GameManager.GameState.MENU:
		return float(value("fade", "menu_blend", 0.25))
	# Hull damage drags the signal down with the ship.
	var p := _get_player()
	if p != null and "health" in p:
		var hull_pct: float = float(p.health.hull) / maxf(float(GameManager.player_max_hull), 1.0)
		base += (1.0 - hull_pct) * float(value("fade", "hull_dead_bonus", 0.18))
	base += GameManager.get_threat() * float(value("fade", "threat_bonus", 0.08))
	return clampf(base, 0.0, 1.0)

func _get_player() -> Node2D:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player

# ─── Blend API ───────────────────────────────────────────────────────────────

## Current 0→1 fade: 0 = SURVEY (4A), 1 = DEAD FREQUENCY (4B).
func blend() -> float:
	return _blend

## Crossfade two colors by the current world state.
func col(survey: Color, dead: Color) -> Color:
	return survey.lerp(dead, _blend)

## Crossfade two scalars by the current world state.
func f(survey: float, dead: float) -> float:
	return lerpf(survey, dead, _blend)

## Named palette color, crossfaded (keys shared by SURVEY/DEAD).
func pal(key: String) -> Color:
	return (SURVEY[key] as Color).lerp(DEAD[key] as Color, _blend)

## Named projectile color, crossfaded.
func proj(key: String) -> Color:
	return (PROJ_SURVEY[key] as Color).lerp(PROJ_DEAD[key] as Color, _blend)

# ─── Floodlight beam (4B: "the beam is the renderer") ───────────────────────

## Beam ramps in once the fade passes its enable threshold.
func beam_strength() -> float:
	var enable := float(value("beam", "enable_blend", 0.45))
	return smoothstep(enable, 1.0, _blend) * float(value("beam", "strength", 0.85))

## 0..1 — how strongly the player's flood cone lights a world position.
## Creatures draw their unlit state and lerp toward "lit" by this factor.
func beam_lit(world_pos: Vector2) -> float:
	var strength := beam_strength()
	if strength <= 0.0:
		return 0.0
	var p := _get_player()
	if p == null:
		return 0.0
	var rel := world_pos - p.global_position
	var dist := rel.length()
	var beam_range := float(value("beam", "range", 130.0))
	if dist > beam_range or dist < 0.001:
		return 0.0
	# Cone points straight up from the probe's nose.
	var half_angle := deg_to_rad(float(value("beam", "half_angle_deg", 17.0)))
	var soft := deg_to_rad(float(value("beam", "edge_softness_deg", 8.0)))
	var angle := absf(rel.angle_to(Vector2.UP))
	var angular := 1.0 - smoothstep(half_angle - soft, half_angle + soft, angle)
	var radial := 1.0 - smoothstep(beam_range * 0.55, beam_range, dist)
	return angular * radial * strength

# ─── Film pass hooks (grain / vignette scale with the fade) ─────────────────

func grain_amount() -> float:
	return lerpf(float(value("film", "grain_survey", 0.035)),
		float(value("film", "grain_dead", 0.085)), _blend)

func vignette_amount() -> float:
	return lerpf(float(value("film", "vignette_survey", 0.30)),
		float(value("film", "vignette_dead", 0.72)), _blend)

# ─── v5.0 "Wet Black" post stack hooks (bloom / tonemap / grade) ─────────────

## Scene exposure fed to the filmic curve (post_bloom_grade.gdshader).
func post_exposure() -> float:
	return float(value("post", "exposure", 1.0))

## Bloom gain — highlights bleed harder as the frequency dies.
func bloom_strength() -> float:
	return lerpf(float(value("post", "bloom_survey", 0.45)),
		float(value("post", "bloom_dead", 0.75)), _blend)

## Luminance knee above which pixels bloom.
func bloom_threshold() -> float:
	return float(value("post", "bloom_threshold", 0.62))

## 0..1 DEAD grade amount (crush + red lift + desat), scaled from the fade.
func grade_amount() -> float:
	return _blend * float(value("post", "grade_strength", 0.85))

## Sun screen position drifts from hard key light (4A) to ember star (4B).
func sun_screen_pos() -> Vector2:
	var s: Variant = value("sun", "survey_screen_pos", [48.0, 28.0])
	var d: Variant = value("sun", "dead_screen_pos", [31.0, 149.0])
	var sv := Vector2(float(s[0]), float(s[1])) if s is Array and s.size() >= 2 else Vector2(48, 28)
	var dv := Vector2(float(d[0]), float(d[1])) if d is Array and d.size() >= 2 else Vector2(31, 149)
	return sv.lerp(dv, _blend)
