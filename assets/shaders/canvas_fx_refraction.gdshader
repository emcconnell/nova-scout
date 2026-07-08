// canvas_fx_refraction — v5.0 "Wet Black" screen-space refraction patch.
// Bends the already-rendered screen behind a masked quad: engine-plume heat
// haze, explosion shockwaves, and The Silence's cloak shimmer. The sprite's
// own texture alpha is the distortion mask (use light_radial.png for round
// patches, a body albedo for silhouettes) — the sprite emits no color of its
// own, it only displaces what is behind it.
// Target: GL Compatibility; 1 screen read + 1 mask read per fragment on
// small quads only (each instance costs a backbuffer copy — keep them rare).
shader_type canvas_item;

// The rendered screen behind this item.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
// Peak UV displacement at mask=1 (screen UV units; 0.006 ~ 2 native px).
uniform float strength : hint_range(0.0, 0.05) = 0.006;
// Spatial frequency of the wobble field across the quad.
uniform float noise_scale : hint_range(0.5, 24.0) = 7.0;
// Wobble animation speed (heat rises fast, cloaks crawl slow).
uniform float speed : hint_range(0.0, 12.0) = 3.0;
// Extra outward radial push (shockwave rings want ~1, haze wants 0).
uniform float radial_push : hint_range(0.0, 3.0) = 0.0;

void fragment() {
	float mask = texture(TEXTURE, UV).a * COLOR.a;
	// Two cheap crossed sine octaves — organic enough at 320x180, no noise tex.
	vec2 wob = vec2(
		sin(UV.y * noise_scale * TAU + TIME * speed * 3.1)
			+ sin(UV.x * noise_scale * 4.2 - TIME * speed * 2.3),
		cos(UV.x * noise_scale * 5.1 + TIME * speed * 2.7)
			+ cos(UV.y * noise_scale * 3.7 + TIME * speed * 3.7)) * 0.5;
	vec2 outward = UV - vec2(0.5);
	vec2 offset = (wob + outward * radial_push * 2.0) * strength * mask;
	vec3 scr = texture(screen_tex, SCREEN_UV + offset).rgb;
	COLOR = vec4(scr, mask);
}
