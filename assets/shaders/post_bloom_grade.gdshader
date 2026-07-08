// post_bloom_grade — v5.0 "Wet Black" cinematic pass: threshold bloom +
// filmic tonemap + fade-driven color grade. Sits on an always-on ColorRect
// (src/ui/post_stack.gd, z 45) UNDER the film/CRT overlay (50) so grain and
// tears land on the graded image, like a real lens recording.
// Bloom is a fixed 13-tap disc at native-canvas radii (game renders a 320x180
// coordinate canvas) — deterministic across renderers, no screen mipmaps
// needed (GL Compatibility safe).
// Target: GL Compatibility; 13 screen reads per fragment at fullscreen.
shader_type canvas_item;

// Post-process source: the rendered screen behind this overlay.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

// Scene exposure applied before the filmic curve.
uniform float exposure : hint_range(0.25, 2.0) = 1.0;
// Bloom gain on thresholded highlights (VisualState lerps survey -> dead).
uniform float bloom_strength : hint_range(0.0, 2.0) = 0.5;
// Luminance knee above which pixels bleed light.
uniform float bloom_threshold : hint_range(0.0, 1.5) = 0.62;
// 0..1 — DEAD FREQUENCY grade amount (crushed blacks, red lift, desat).
uniform float grade_amount : hint_range(0.0, 1.0) = 0.0;

// Native coordinate canvas the game is authored on (320x180).
const vec2 NATIVE = vec2(320.0, 180.0);
// Bloom disc radii in native px — inner tight halo, outer soft bleed.
const float RING_INNER = 1.6;
const float RING_OUTER = 4.2;
// Shadow tint pulled toward cold blue in SURVEY state (per-channel offset).
const vec3 SURVEY_SHADOW_TINT = vec3(-0.004, 0.002, 0.010);
// Rec.709 luma weights.
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

// Soft-knee highlight extraction.
vec3 bloom_tap(vec2 uv, float threshold) {
	vec3 c = texture(screen_tex, uv).rgb;
	float l = dot(c, LUMA);
	float k = smoothstep(threshold, threshold + 0.35, l);
	return c * k;
}

// ACES filmic fit (Narkowicz 2015) — gentle shoulder, no hue skew at our range.
vec3 aces(vec3 x) {
	return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_tex, uv).rgb;

	// ── Bloom: center + two 6-tap rings (13 reads total) ────────────────────
	vec2 px = 1.0 / NATIVE;   // one native-canvas pixel in screen UV
	vec3 bloom = bloom_tap(uv, bloom_threshold) * 0.20;
	for (int i = 0; i < 6; i++) {
		float a = float(i) * (PI / 3.0);
		vec2 dir = vec2(cos(a), sin(a));
		bloom += bloom_tap(uv + dir * px * RING_INNER, bloom_threshold) * 0.085;
		// outer ring rotated 30 degrees so the 12 ring taps interleave
		float a2 = a + PI / 6.0;
		bloom += bloom_tap(uv + vec2(cos(a2), sin(a2)) * px * RING_OUTER,
			bloom_threshold) * 0.048;
	}
	col += bloom * bloom_strength;

	// ── Filmic tonemap ───────────────────────────────────────────────────────
	col = aces(col * exposure);

	// ── Grade ────────────────────────────────────────────────────────────────
	float lum = dot(col, LUMA);
	// SURVEY: cold, clean documentary shadows.
	col += SURVEY_SHADOW_TINT * (1.0 - grade_amount) * (1.0 - smoothstep(0.0, 0.45, lum));
	// DEAD FREQUENCY: crush the blacks, keep the reds, drain the rest.
	float crushed = 1.0 + 0.38 * grade_amount;
	col = pow(max(col, vec3(0.0)), vec3(crushed));
	float red_dominance = smoothstep(0.04, 0.30, col.r - max(col.g, col.b));
	vec3 gray = vec3(dot(col, LUMA));
	col = mix(col, mix(gray, col, 0.62), grade_amount * (1.0 - red_dominance));

	COLOR = vec4(col, 1.0);
}
