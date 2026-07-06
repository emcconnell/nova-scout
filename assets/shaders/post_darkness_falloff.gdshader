// Darkness falloff veil — radial visibility around the player's light.
// Fullscreen ColorRect; alpha rises with distance from light_pos so enemies
// emerge from murk in sectors 3–5. Enemy projectiles render above this layer
// and stay visible (dark-directive.md §6 Edge Cases).
// Target: GL Compatibility. Cost: one distance + one smoothstep per fragment.
// GDD Ref: dark-directive.md §4.2 Darkness system
shader_type canvas_item;

uniform vec2 light_pos = vec2(160.0, 152.0);           // player position, pixels
uniform vec2 viewport_size = vec2(320.0, 180.0);
uniform float light_radius = 95.0;                     // fully-lit radius, pixels
uniform float edge_softness = 55.0;                    // lit→dark transition band
uniform float max_alpha : hint_range(0.0, 1.0) = 0.82; // darkness ceiling
// Blue-black, never pure black — darkness needs texture (dread brief §31)
uniform vec4 dark_color : source_color = vec4(0.012, 0.014, 0.032, 1.0);

void fragment() {
	vec2 px = UV * viewport_size;
	float d = distance(px, light_pos);
	float a = smoothstep(light_radius, light_radius + edge_softness, d) * max_alpha;
	COLOR = vec4(dark_color.rgb, a);
}
