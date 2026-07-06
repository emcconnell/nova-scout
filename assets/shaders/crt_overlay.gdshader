// CRT Scanline + Vignette + Interference overlay shader
// Applied to a ColorRect covering the full viewport.
// The interference channel is the fear channel: it ramps with threat level
// (The Silence near, hull critical, scan climax) so the player's own display
// becomes the motion tracker. Target: GL Compatibility, trivial fragment cost.
// GDD Ref: dark-directive.md §4.2 "CRT interference as fear"
shader_type canvas_item;

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.12;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float aberration_amount : hint_range(0.0, 0.02) = 0.0;
// 0..1 — static noise + chroma wobble driven by GameManager threat level
uniform float interference : hint_range(0.0, 1.0) = 0.0;
// 0..1 — horizontal sync-loss band sweeping down the frame (event pulses)
uniform float signal_roll : hint_range(0.0, 1.0) = 0.0;
// Post-process source: the rendered screen behind this overlay
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

// Cheap hash noise — good enough for 1-frame static speckle
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// Signal roll — a band of horizontal displacement sweeping downward
	if (signal_roll > 0.001) {
		float band_pos = fract(TIME * 0.55);
		float band = smoothstep(0.06, 0.0, abs(uv.y - band_pos));
		uv.x += band * signal_roll * 0.02 * sin(TIME * 60.0 + uv.y * 40.0);
	}

	// Interference jitter — per-line horizontal tearing scaled by threat
	if (interference > 0.001) {
		float line_n = hash12(vec2(floor(uv.y * 180.0), floor(TIME * 24.0)));
		uv.x += (line_n - 0.5) * 0.006 * interference;
	}

	// Chromatic aberration (hit feedback via script; widened by interference)
	float ab = aberration_amount + interference * 0.0025;
	vec4 col = texture(screen_tex, uv);
	if (ab > 0.0) {
		col.r = texture(screen_tex, uv + vec2(ab, 0.0)).r;
		col.b = texture(screen_tex, uv - vec2(ab, 0.0)).b;
	}
	col.a = 1.0;

	// Static speckle — the medium failing
	if (interference > 0.001) {
		float speck = hash12(uv * vec2(320.0, 180.0) + floor(TIME * 30.0));
		float speck_vis = step(1.0 - 0.10 * interference, speck);
		col.rgb = mix(col.rgb, vec3(speck * 0.75), speck_vis * 0.55 * interference);
	}

	// Scanlines
	float scanline = sin(uv.y * 180.0 * PI) * 0.5 + 0.5;
	col.rgb *= 1.0 - scanline_strength * scanline;

	// Phosphor tint — pull deep shadows toward green-black, never pure black
	col.rgb = mix(col.rgb, vec3(col.g * 0.9, col.g, col.g * 0.9),
		0.04 * (1.0 - smoothstep(0.0, 0.25, dot(col.rgb, vec3(0.333)))));

	// Vignette
	vec2 vig_uv = uv * 2.0 - 1.0;
	float vignette = 1.0 - dot(vig_uv * vec2(0.7, 1.0), vig_uv * vec2(0.7, 1.0));
	vignette = clamp(vignette, 0.0, 1.0);
	vignette = pow(vignette, 1.5);
	col.rgb *= mix(1.0 - vignette_strength, 1.0, vignette);

	COLOR = col;
}
