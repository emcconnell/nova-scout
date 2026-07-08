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
const REFRACTION_SHADER := "res://assets/shaders/canvas_fx_refraction.gdshader"

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

## Cached texture load that tolerates absence (optional bakes like _spec).
static func _tex_quiet(family: String, name: String) -> Texture2D:
	var key := family + "/" + name
	if _tex_cache.has(key):
		return _tex_cache[key]
	var path := TEX_ROOT + key + ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex_cache[key] = t
	return t

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
	# v5.0: baked gloss mask -> Blinn-Phong specular in the engine light pass.
	# Missing spec bakes fall back to the shader's black default (matte).
	var spec := _tex_quiet(family, name + "_spec")
	if spec:
		mat.set_shader_parameter("spec_tex", spec)
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

## v5.0 "Wet Black" — soft shadow casting on a light, tuned from visuals.json.
## Shadows never fully block (color_alpha < 1): the murk has no hard walls.
static func enable_shadows(l: Light2D) -> void:
	if not bool(VisualState.value("shadows", "enabled", true)):
		return
	l.shadow_enabled = true
	l.shadow_filter = Light2D.SHADOW_FILTER_PCF13
	l.shadow_filter_smooth = float(VisualState.value("shadows", "filter_smooth", 3.5))
	l.shadow_color = Color(0.0, 0.0, 0.0,
		float(VisualState.value("shadows", "color_alpha", 0.72)))

## Circular N-gon light occluder — solid bodies block the flood cone and
## blast light. Size to ~70% of the visual radius so rims stay lit; cull mode
## keeps the body's own footprint lit (shadow extends only behind it).
static func occluder(parent: Node2D, radius: float, verts: int = 10) -> LightOccluder2D:
	var poly := OccluderPolygon2D.new()
	var pts := PackedVector2Array()
	for i in verts:
		var a := TAU * float(i) / float(verts)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = pts
	poly.cull_mode = OccluderPolygon2D.CULL_CLOCKWISE
	var occ := LightOccluder2D.new()
	occ.occluder = poly
	parent.add_child(occ)
	return occ

## Screen-space refraction patch (heat haze / shockwave / cloak shimmer).
## The mask texture's alpha shapes the distortion; the patch emits no color.
## Each instance costs a backbuffer copy — keep them rare and small.
static func refraction_patch(parent: Node2D, radius: float, strength: float,
		mask: Texture2D = null) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = "Refraction"
	s.texture = mask if mask else tex("world", "light_radial")
	var m := ShaderMaterial.new()
	m.shader = _shader(REFRACTION_SHADER)
	m.set_shader_parameter("strength", strength)
	s.material = m
	if s.texture:
		s.scale = Vector2.ONE * (radius * 2.0 / maxf(float(s.texture.get_width()), 1.0))
	s.z_index = 20   # above world bodies and FX, below the darkness veil (30)
	s.light_mask = 0
	parent.add_child(s)
	return s

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
