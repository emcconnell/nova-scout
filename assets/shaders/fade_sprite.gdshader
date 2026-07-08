// fade_sprite — textured body crossfaded SURVEY -> DEAD FREQUENCY per pixel.
// TEXTURE is the survey albedo; dead_tex the DEAD-state albedo baked from the
// same geometry; normal_tex feeds real-time 2D lights (art bible v4.0).
// v5.0 "Wet Black": spec_tex drives engine-native Blinn-Phong specular via
// SPECULAR_SHININESS — hulls and rock now GLINT under the sun and dynamic
// lights instead of only diffusing them.
// ns_blend is the global fade set by VisualState each frame.
// Target: GL Compatibility, 3 texture reads + 1 spec read per fragment.
shader_type canvas_item;

global uniform float ns_blend;
global uniform vec2 ns_player_pos;
// x = range px, y = cos(half_angle), z = cos(half_angle + softness), w = strength
global uniform vec4 ns_beam;
uniform sampler2D dead_tex: source_color, filter_linear_mipmap;
uniform sampler2D normal_tex: hint_normal, filter_linear_mipmap;
// Grayscale gloss mask baked by tools/texture_gen (black = matte).
uniform sampler2D spec_tex: hint_default_black, filter_linear_mipmap;
uniform float flash: hint_range(0.0, 1.0) = 0.0;
// Specular intensity scale on the baked gloss mask.
uniform float spec_strength: hint_range(0.0, 4.0) = 1.2;
// Shininess exponent control: engine maps a 0-1 value to exp2(15a+1)/4.
// 0.34 ≈ exponent 18 — broad metal sheen, not lacquer.
uniform float shininess: hint_range(0.0, 1.0) = 0.34;

varying float v_gloss;
varying vec2 world_pos;

// Warm flood-lamp tint on beam-revealed surfaces.
const vec3 BEAM_TINT = vec3(1.0, 0.93, 0.82);

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 survey = texture(TEXTURE, UV);
	vec4 dead = texture(dead_tex, UV);
	vec4 col = mix(survey, dead, ns_blend);

	// v5.0: the flood cone restores TRUE albedo — a rock or wreck caught in
	// the lamp shows its real surface, not the dead-frequency scorch. Same
	// cone math as creature_sprite (the beam is the renderer).
	vec2 rel = world_pos - ns_player_pos;
	float dist = max(length(rel), 0.001);
	float cos_ang = dot(rel / dist, vec2(0.0, -1.0));
	float angular = smoothstep(ns_beam.z, ns_beam.y, cos_ang);
	float radial = 1.0 - smoothstep(ns_beam.x * 0.55, ns_beam.x, dist);
	float lit = angular * radial * ns_beam.w * ns_blend;
	col.rgb = mix(col.rgb, survey.rgb * BEAM_TINT, lit * 0.85);

	col.rgb = mix(col.rgb, vec3(1.0), flash);
	COLOR = col * COLOR;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	// DEAD hulls are scorched — the sheen dulls as the frequency dies, but
	// the flood lamp brings the glint back with the true surface.
	v_gloss = texture(spec_tex, UV).r * spec_strength
		* max(1.0 - 0.45 * ns_blend, lit);
}

// Custom light pass: engine diffuse (N.L) + Blinn-Phong specular from the
// baked gloss mask. View is the 2D camera axis (0,0,1).
void light() {
	float ndl = clamp(dot(NORMAL, LIGHT_DIRECTION), 0.0, 1.0);
	vec3 half_vec = normalize(LIGHT_DIRECTION + vec3(0.0, 0.0, 1.0));
	float exponent = exp2(7.0 * shininess + 1.0);
	float spec = pow(clamp(dot(NORMAL, half_vec), 0.0, 1.0), exponent)
		* v_gloss * step(0.001, ndl);
	LIGHT = vec4(LIGHT_COLOR.rgb * LIGHT_ENERGY * (COLOR.rgb * ndl + vec3(spec)),
		LIGHT_COLOR.a);
}
