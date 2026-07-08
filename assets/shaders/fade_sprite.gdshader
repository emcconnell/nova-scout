// fade_sprite — textured body crossfaded SURVEY -> DEAD FREQUENCY per pixel.
// TEXTURE is the survey albedo; dead_tex the DEAD-state albedo baked from the
// same geometry; normal_tex feeds real-time 2D lights (art bible v4.0).
// ns_blend is the global fade set by VisualState each frame.
shader_type canvas_item;

global uniform float ns_blend;
uniform sampler2D dead_tex: source_color, filter_linear_mipmap;
uniform sampler2D normal_tex: hint_normal, filter_linear_mipmap;
uniform float flash: hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 survey = texture(TEXTURE, UV);
	vec4 dead = texture(dead_tex, UV);
	vec4 col = mix(survey, dead, ns_blend);
	col.rgb = mix(col.rgb, vec3(1.0), flash);
	COLOR = col * COLOR;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
}
