// CRT Scanline + Vignette overlay shader
// Applied to a ColorRect covering the full viewport
// GDD Ref: gameplay-mechanics.md §8 — Scanlines & CRT Effect
shader_type canvas_item;

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.12;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float aberration_amount : hint_range(0.0, 0.02) = 0.0;

void fragment() {
	vec2 uv = UV;
	
	// Chromatic aberration (set high on hit via script)
	vec4 col = texture(TEXTURE, uv);
	if (aberration_amount > 0.0) {
		col.r = texture(TEXTURE, uv + vec2(aberration_amount, 0.0)).r;
		col.b = texture(TEXTURE, uv - vec2(aberration_amount, 0.0)).b;
	}
	
	// Scanlines
	float scanline = sin(uv.y * 180.0 * PI) * 0.5 + 0.5;
	col.rgb *= 1.0 - scanline_strength * scanline;
	
	// Vignette
	vec2 vig_uv = uv * 2.0 - 1.0;
	float vignette = 1.0 - dot(vig_uv * vec2(0.7, 1.0), vig_uv * vec2(0.7, 1.0));
	vignette = clamp(vignette, 0.0, 1.0);
	vignette = pow(vignette, 1.5);
	col.rgb *= mix(1.0 - vignette_strength, 1.0, vignette);
	
	COLOR = col;
}
