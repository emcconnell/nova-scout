## TextureKit — factory for textured, normal-mapped, fade-aware body sprites
## and light nodes (art bible v4.0 "Textured Light" pass).
## Bodies are baked PNG triplets (survey/dead/wet + normal) under
## assets/textures/; the fade + flood-cone reveal run in shaders driven by
## global uniforms that VisualState updates once per frame.
class_name TextureKit
extends Object

const TEX_ROOT := "res://assets/textures/"
const FADE_SHADER := "res://assets/shaders/fade_sprite.gdshader"
const CREATURE_SHADER := "res://assets/shaders/creature_sprite.gdshader"

static var _tex_cache: Dictionary = {}
static var _shader_cache: Dictionary = {}

## Cached texture load; returns null (with one warning) when a bake is missing.
static func tex(family: String, name: String) -> Texture2D:
	var key := family + "/" + name
	if _tex_cache.has(key):
		return _tex_cache[key]
	var path := TEX_ROOT + key + ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	if t == null:
		push_warning("TextureKit: missing texture %s" % path)
	_tex_cache[key] = t
	return t

static func _shader(path: String) -> Shader:
	if not _shader_cache.has(path):
		_shader_cache[path] = load(path)
	return _shader_cache[path]

## Textured hull/rock body: survey+dead albedo crossfade + normal map.
## Returns a child Sprite2D placed BELOW the owner's procedural FX drawing.
static func fade_body(parent: Node2D, family: String, name: String,
		px_per_unit: float = 12.0) -> Sprite2D:
	return _body(parent, family, name, FADE_SHADER, false, px_per_unit)

## Alien chitin body: adds the wet albedo revealed per-pixel by the flood cone.
static func creature_body(parent: Node2D, family: String, name: String,
		px_per_unit: float = 12.0) -> Sprite2D:
	return _body(parent, family, name, CREATURE_SHADER, true, px_per_unit)

static func _body(parent: Node2D, family: String, name: String,
		shader_path: String, wet: bool, px_per_unit: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = "Body"
	s.texture = tex(family, name + "_survey")
	var mat := ShaderMaterial.new()      # per-instance: flash is per-entity
	mat.shader = _shader(shader_path)
	mat.set_shader_parameter("dead_tex", tex(family, name + "_dead"))
	mat.set_shader_parameter("normal_tex", tex(family, name + "_normal"))
	if wet:
		mat.set_shader_parameter("wet_tex", tex(family, name + "_wet"))
	s.material = mat
	# bake density -> game units (the 320x180 canvas): 12 px/unit default
	s.scale = Vector2.ONE / px_per_unit
	s.z_index = -1                       # under the owner's procedural FX
	# leave headroom for the sun: lights model the form, albedo is the floor.
	# Chitin is already near-black — creatures keep most of their base read.
	s.self_modulate = Color(0.9, 0.9, 0.9) if wet else Color(0.66, 0.66, 0.66)
	parent.add_child(s)
	return s

## Per-entity hit flash (0..1) on a body sprite created by this kit.
static func set_flash(body: Sprite2D, amount: float) -> void:
	if body and body.material is ShaderMaterial:
		(body.material as ShaderMaterial).set_shader_parameter("flash", amount)

## Soft radial point light (light_radial cookie), e.g. engine glow, muzzle,
## explosions. radius is in game px (half the cookie's world footprint).
static func point_light(parent: Node2D, radius: float, color: Color,
		energy: float = 1.0) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = tex("world", "light_radial")
	l.texture_scale = radius * 2.0 / 256.0
	l.color = color
	l.energy = energy
	l.height = 24.0
	l.shadow_enabled = false
	parent.add_child(l)
	return l

## The flood-cone light (light_cone cookie points up, apex at the light pos).
static func cone_light(parent: Node2D, range_px: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = tex("world", "light_cone")
	# cookie: apex at center, reach = half the texture (256 of 512)
	l.texture_scale = range_px / 256.0
	l.offset = Vector2(0, -256.0 * 0.5)  # push the wedge ahead of the probe
	l.height = 30.0
	l.shadow_enabled = false
	parent.add_child(l)
	return l

## DirectionalLight2D whose rotation is set from "light comes FROM dir".
## Calibrated on Godot 4.6: rotation = PI/2 - from_angle.
static func sun_light(parent: Node2D) -> DirectionalLight2D:
	var sun := DirectionalLight2D.new()
	sun.name = "SunLight"
	sun.height = 0.6
	sun.shadow_enabled = false
	parent.add_child(sun)
	return sun

## Point the sun so light arrives FROM `from_dir` (screen-space vector).
static func aim_sun(sun: DirectionalLight2D, from_dir: Vector2) -> void:
	sun.rotation = PI / 2.0 - from_dir.angle()
