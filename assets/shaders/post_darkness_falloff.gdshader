// Darkness falloff veil — radial visibility around the player's light,
// plus the TURN 4 flood cone: a volumetric wedge ahead of the probe that
// actually reveals what's hiding in it (art-bible.md Turn 4 / 4B).
// Fullscreen ColorRect; alpha rises with distance from light_pos so enemies
// emerge from murk. Enemy projectiles render above this layer and stay
// visible (dark-directive.md §6 Edge Cases).
// Target: GL Compatibility. Cost: one distance, one dot, three smoothsteps.
// GDD Ref: dark-directive.md §4.2 Darkness system, art-bible.md Turn 4
shader_type canvas_item;

group_uniforms radial;
uniform vec2 light_pos = vec2(160.0, 152.0);           // player position, pixels
uniform vec2 viewport_size = vec2(320.0, 180.0);
uniform float light_radius = 95.0;                     // fully-lit radius, pixels
uniform float edge_softness = 55.0;                    // lit→dark transition band
uniform float max_alpha : hint_range(0.0, 1.0) = 0.82; // darkness ceiling

group_uniforms flood_cone;
uniform vec2 beam_dir = vec2(0.0, -1.0);               // cone axis (probe nose)
uniform float beam_range = 130.0;                      // cone reach, pixels
uniform float beam_cos_half = 0.956;                   // cos(half angle)
uniform float beam_cos_soft = 0.906;                   // cos(half angle + softness)
uniform float beam_strength : hint_range(0.0, 1.0) = 0.0; // 0 disables the cone

group_uniforms color;
// Fades blue-black (survey murk) → red-black (dead frequency) with the world.
uniform vec4 dark_color : source_color = vec4(0.012, 0.014, 0.032, 1.0);

void fragment() {
	vec2 px = UV * viewport_size;
	vec2 rel = px - light_pos;
	float d = length(rel);
	float a = smoothstep(light_radius, light_radius + edge_softness, d) * max_alpha;
	// Flood cone: carve visibility out of the murk along the beam axis.
	float along = dot(normalize(rel + vec2(0.0001)), beam_dir);
	float angular = smoothstep(beam_cos_soft, beam_cos_half, along);
	float radial = 1.0 - smoothstep(beam_range * 0.55, beam_range, d);
	a *= 1.0 - angular * radial * beam_strength;
	COLOR = vec4(dark_color.rgb, a);
}
