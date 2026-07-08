// TURN 4 film post-pass: grain + vignette + anamorphic flare + red static tears.
// Applied to a ColorRect covering the full viewport. Replaces the phosphor-CRT
// scanline look with the "punched-up realism + the fade" film language —
// interference is now grain boost + tear frequency, not scanline artifacts.
// Target: GL Compatibility, trivial fragment cost.
// GDD Ref: art-bible.md Turn 4 — HUD + film pass
shader_type canvas_item;

uniform float grain_amount : hint_range(0.0, 0.2) = 0.035;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.30;
uniform float aberration_amount : hint_range(0.0, 0.02) = 0.0;
// 0..1 — interference = grain boost + tear frequency, driven by threat level
uniform float interference : hint_range(0.0, 1.0) = 0.0;
// 0..1 — horizontal sync-loss band sweeping down the frame (event pulses)
uniform float signal_roll : hint_range(0.0, 1.0) = 0.0;
// 0..1 — crossfade blend (SURVEY 0 -> DEAD FREQUENCY 1); gates red static tears
uniform float blend_amount : hint_range(0.0, 1.0) = 0.0;
// Screen-space sun/ember position (pixels, 320x180 native) for the anamorphic flare
uniform vec2 sun_screen_pos = vec2(48.0, 28.0);
// Faint legacy scanline density — kept only so disabling "CRT" still reads as a toggle
uniform float scanline_strength : hint_range(0.0, 0.2) = 0.0;
// Post-process source: the rendered screen behind this overlay
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

// Cheap hash noise — good enough for 1-frame grain speckle
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 native_px = uv * vec2(320.0, 180.0);

	// Signal roll — a band of horizontal displacement sweeping downward
	if (signal_roll > 0.001) {
		float band_pos = fract(TIME * 0.55);
		float band = smoothstep(0.06, 0.0, abs(uv.y - band_pos));
		uv.x += band * signal_roll * 0.02 * sin(TIME * 60.0 + uv.y * 40.0);
	}

	// Chromatic aberration (hit feedback via script; widened by interference)
	float ab = aberration_amount + interference * 0.0025;
	vec4 col = texture(screen_tex, uv);
	if (ab > 0.0) {
		col.r = texture(screen_tex, uv + vec2(ab, 0.0)).r;
		col.b = texture(screen_tex, uv - vec2(ab, 0.0)).b;
	}
	col.a = 1.0;

	// Film grain — hash speckle re-seeded a few times a second, boosted by interference
	float grain_seed_step = floor(TIME * 12.0);
	float grain_n = hash12(native_px + grain_seed_step) - 0.5;
	col.rgb += grain_n * (grain_amount + interference * 0.05);

	// Anamorphic flare — ghost-faint lens echo keyed to the sun/ember screen
	// position. This is post-process (it sits over moving bodies), so it must
	// stay at whisper level: the real streak is painted in scene_renderer.gd
	// and clips correctly behind rocks and ships.
	float flare_dy = abs(native_px.y - sun_screen_pos.y);
	float flare = smoothstep(6.0, 0.0, flare_dy) * smoothstep(120.0, 0.0, abs(native_px.x - sun_screen_pos.x));
	col.rgb += vec3(1.0, 0.96, 0.9) * flare * 0.025;

	// Red static tears (dead frequency) — 2-3 thin translucent lines, ~2 Hz reposition
	if (blend_amount > 0.01) {
		float tear_cycle = floor(TIME * 2.0);
		for (int i = 0; i < 3; i++) {
			float seed = tear_cycle * 3.0 + float(i) * 17.0;
			float tear_y = hash12(vec2(seed, 1.0));
			float d = abs(uv.y - tear_y);
			float line_vis = smoothstep(0.006, 0.0, d);
			col.rgb = mix(col.rgb, vec3(1.0, 0.1, 0.08), line_vis * 0.05 * blend_amount);
		}
	}

	// Legacy scanlines — near-zero by default; only present if explicitly dialed up
	if (scanline_strength > 0.001) {
		float scanline = sin(uv.y * 180.0 * PI) * 0.5 + 0.5;
		col.rgb *= 1.0 - scanline_strength * scanline;
	}

	// Vignette
	vec2 vig_uv = uv * 2.0 - 1.0;
	float vignette = 1.0 - dot(vig_uv * vec2(0.7, 1.0), vig_uv * vec2(0.7, 1.0));
	vignette = clamp(vignette, 0.0, 1.0);
	vignette = pow(vignette, 1.5);
	col.rgb *= mix(1.0 - vignette_strength, 1.0, vignette);

	COLOR = col;
}
