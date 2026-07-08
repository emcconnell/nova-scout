// creature_sprite — alien chitin crossfaded SURVEY -> DEAD, with the player's
// flood cone revealing wet chitin PER PIXEL in world space (art bible v4.0:
// "the beam is the renderer"). Big creatures can be partially in the beam.
// v5.0 "Wet Black": spec_tex drives engine-native Blinn-Phong specular via
// SPECULAR_SHININESS. Chitin caught in the beam turns HIGH-GLOSS — the wet
// glisten is real light, not paint.
// TEXTURE = survey albedo; dead/wet baked from the same geometry.
// Target: GL Compatibility, 4 texture reads + 1 spec read per fragment.
shader_type canvas_item;

global uniform float ns_blend;
global uniform vec2 ns_player_pos;
// x = range px, y = cos(half_angle), z = cos(half_angle + softness), w = strength
global uniform vec4 ns_beam;

uniform sampler2D dead_tex: source_color, filter_linear_mipmap;
uniform sampler2D wet_tex: source_color, filter_linear_mipmap;
uniform sampler2D normal_tex: hint_normal, filter_linear_mipmap;
// Grayscale gloss mask baked by tools/texture_gen (black = matte).
uniform sampler2D spec_tex: hint_default_black, filter_linear_mipmap;
uniform float flash: hint_range(0.0, 1.0) = 0.0;
// Dry chitin sheen scale; beam-lit wet chitin multiplies this up.
uniform float spec_strength: hint_range(0.0, 4.0) = 1.1;
// Wet-gloss boost inside the flood cone (multiplies spec_strength).
uniform float wet_gloss_boost: hint_range(1.0, 6.0) = 3.2;
// Shininess (engine maps 0-1 to exp2(15a+1)/4): dry 0.30 -> wet 0.58 (~lacquer).
uniform float shininess_dry: hint_range(0.0, 1.0) = 0.30;
uniform float shininess_wet: hint_range(0.0, 1.0) = 0.58;

varying vec2 world_pos;
varying float v_gloss;
varying float v_shininess;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 survey = texture(TEXTURE, UV);
	vec4 dead = texture(dead_tex, UV);
	vec4 col = mix(survey, dead, ns_blend);

	// flood cone points straight up from the probe's nose
	vec2 rel = world_pos - ns_player_pos;
	float dist = max(length(rel), 0.001);
	float cos_ang = dot(rel / dist, vec2(0.0, -1.0));
	float angular = smoothstep(ns_beam.z, ns_beam.y, cos_ang);
	float radial = 1.0 - smoothstep(ns_beam.x * 0.55, ns_beam.x, dist);
	float lit = angular * radial * ns_beam.w * ns_blend;
	col = mix(col, texture(wet_tex, UV), lit);

	col.rgb = mix(col.rgb, vec3(1.0), flash);
	COLOR = col * COLOR;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	// Beam-lit chitin glistens: gloss and tightness both rise inside the cone.
	v_gloss = texture(spec_tex, UV).r * spec_strength * mix(1.0, wet_gloss_boost, lit);
	v_shininess = mix(shininess_dry, shininess_wet, lit);
}

// Custom light pass: diffuse (N.L) + Blinn-Phong specular. Wet chitin caught
// in the flood cone throws tight lacquer highlights — the glisten is light.
void light() {
	float ndl = clamp(dot(NORMAL, LIGHT_DIRECTION), 0.0, 1.0);
	vec3 half_vec = normalize(LIGHT_DIRECTION + vec3(0.0, 0.0, 1.0));
	float exponent = exp2(7.0 * v_shininess + 1.0);
	float spec = pow(clamp(dot(NORMAL, half_vec), 0.0, 1.0), exponent)
		* v_gloss * step(0.001, ndl);
	LIGHT = vec4(LIGHT_COLOR.rgb * LIGHT_ENERGY * (COLOR.rgb * ndl + vec3(spec)),
		LIGHT_COLOR.a);
}
