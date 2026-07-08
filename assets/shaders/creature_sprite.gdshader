// creature_sprite — alien chitin crossfaded SURVEY -> DEAD, with the player's
// flood cone revealing wet chitin PER PIXEL in world space (art bible v4.0:
// "the beam is the renderer"). Big creatures can be partially in the beam.
// TEXTURE = survey albedo; dead/wet baked from the same geometry.
shader_type canvas_item;

global uniform float ns_blend;
global uniform vec2 ns_player_pos;
// x = range px, y = cos(half_angle), z = cos(half_angle + softness), w = strength
global uniform vec4 ns_beam;

uniform sampler2D dead_tex: source_color, filter_linear_mipmap;
uniform sampler2D wet_tex: source_color, filter_linear_mipmap;
uniform sampler2D normal_tex: hint_normal, filter_linear_mipmap;
uniform float flash: hint_range(0.0, 1.0) = 0.0;

varying vec2 world_pos;

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
}
