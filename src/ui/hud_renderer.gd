## HudRenderer — static draw helpers for hud.gd's TURN 4 flight-FUI + failure look.
## Extracted to keep hud.gd under the 300-line budget. Stateless: callers own
## all timers/caches and pass them in each frame.
class_name HudRenderer
extends Object

## Hairline corner-bracket frame — no fill, techy instrument look (Turn 4.1:
## 0.6px stroke, alpha ~0.5). Replaces the old filled double-bracket panel.
static func corner_brackets(ci: CanvasItem, x: float, y: float, w: float, h: float,
		col: Color, cs: float = 6.0) -> void:
	var c := Color(col.r, col.g, col.b, col.a * 0.5)
	ci.draw_line(Vector2(x, y), Vector2(x + cs, y), c, 0.6)
	ci.draw_line(Vector2(x, y), Vector2(x, y + cs), c, 0.6)
	ci.draw_line(Vector2(x + w, y), Vector2(x + w - cs, y), c, 0.6)
	ci.draw_line(Vector2(x + w, y), Vector2(x + w, y + cs), c, 0.6)
	ci.draw_line(Vector2(x, y + h), Vector2(x + cs, y + h), c, 0.6)
	ci.draw_line(Vector2(x, y + h), Vector2(x, y + h - cs), c, 0.6)
	ci.draw_line(Vector2(x + w, y + h), Vector2(x + w - cs, y + h), c, 0.6)
	ci.draw_line(Vector2(x + w, y + h), Vector2(x + w, y + h - cs), c, 0.6)

## Hairline instrument panel frame — corner brackets only, no backing fill
## (Turn 4.1 "techy" restyle: 0.6px stroke, alpha 0.5). Kept as `draw_panel`
## for call-site compatibility across hud.gd.
static func draw_panel(ci: CanvasItem, hud_col: Color, x: float, y: float,
		w: float, h: float, cs: float = 6.0) -> void:
	# Instrument-glass backing: keeps readouts legible over bright scene
	# elements (sun, flares) without reverting to a heavy filled panel.
	ci.draw_rect(Rect2(x, y, w, h), Color(0.0, 0.008, 0.016, 0.55))
	corner_brackets(ci, x, y, w, h, hud_col, cs)

## Compact heading tape — short tick strip with a center caret and a 3-digit
## heading readout INLINE to the right (Turn 4.2: one line of vertical space).
static func heading_tape(ci: CanvasItem, font: Font, center_x: float, y: float,
		w: float, scroll_px: float, col: Color) -> void:
	var half := w * 0.5
	var spacing := 4.0
	var offset := fmod(scroll_px, spacing)
	var x := center_x - half - offset
	var i := 0
	while x <= center_x + half:
		if x >= center_x - half:
			var tall: bool = i % 4 == 0
			var th: float = 2.0 if tall else 1.0
			var a: float = col.a if tall else col.a * 0.5
			ci.draw_line(Vector2(x, y), Vector2(x, y + th), Color(col.r, col.g, col.b, a), 0.6)
		x += spacing
		i += 1
	# Center caret (small downward triangle); heading digits sit inline right.
	ci.draw_colored_polygon(PackedVector2Array([
		Vector2(center_x - 1.2, y - 1.8), Vector2(center_x + 1.2, y - 1.8), Vector2(center_x, y - 0.2)
	]), col)
	var heading: int = int(fmod(scroll_px * 2.0, 360.0))
	ci.draw_string(font, Vector2(center_x + half + 3.0, y + 2.5), "%03d" % heading,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(col.r, col.g, col.b, col.a * 0.9))

## Re-draw `text` offset by (2.5, 1) at alpha 0.3*glitch — HUD failure ghosting.
static func text_ghost(ci: CanvasItem, font: Font, pos: Vector2, text: String,
		size: int, col: Color, glitch: float) -> void:
	if glitch <= 0.001:
		return
	var ghost_col := Color(col.r, col.g, col.b, col.a * 0.3 * glitch)
	ci.draw_string(font, pos + Vector2(2.5, 1.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size, ghost_col)

## Reseed 3-14 short glitch-bar rects near the top bar. Call from a ~0.4s
## timer in _process — never call this from _draw (no randf() in draw calls).
static func reseed_glitch_bars(rng: RandomNumberGenerator, vp_w: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var count: int = rng.randi_range(3, 14)
	for i in count:
		var bw: float = rng.randf_range(6.0, 34.0)
		var bx: float = rng.randf_range(0.0, maxf(vp_w - bw, 1.0))
		var by: float = rng.randf_range(0.0, 16.0)
		var bh: float = rng.randf_range(0.6, 2.0)
		out.append(Rect2(bx, by, bw, bh))
	return out

## Draw cached glitch-bar rects (bright/red flicker), scaled by `glitch`.
static func draw_glitch_bars(ci: CanvasItem, rects: Array[Rect2], col: Color, glitch: float) -> void:
	if glitch <= 0.001:
		return
	for i in rects.size():
		var flicker: float = 0.5 + 0.5 * sin(float(i) * 2.1 + Time.get_ticks_msec() * 0.02)
		var a: float = glitch * (0.35 + 0.4 * flicker)
		ci.draw_rect(rects[i], Color(col.r, col.g, col.b, a))

## Centered "// SIGNAL LOST //" banner, alpha ramps with blend*0.85.
static func signal_lost_banner(ci: CanvasItem, font: Font, vp_size: Vector2,
		blend: float, col: Color) -> void:
	var a: float = blend * 0.85
	if a <= 0.01:
		return
	var text := "// SIGNAL LOST //"
	var size := 6
	var text_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(vp_size.x * 0.5 - text_w * 0.5, 12.0)
	ci.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(col.r, col.g, col.b, a))

## Single stat readout row — micro-caps label, status square, hairline track
## with bright fill + 25%-interval ticks, right-aligned numeric value
## (Turn 4.1 compact instrument restyle — replaces the thick gradient bar).
static func draw_bar(ci: CanvasItem, font: Font, fs: int, hud_col: Color,
		x: float, y: float, bar_w: float, bar_h: float, wobble: float,
		lbl: String, val: float, max_val: float, col: Color) -> void:
	var pct: float = clampf(val / maxf(max_val, 1), 0.0, 1.0)
	# Status square: green (ok) / amber (caution) / red (critical) state dot.
	var state_col := Color(0.30, 1.0, 0.45, 0.9) if pct > 0.5 else \
		(Color(1.0, 0.78, 0.15, 0.9) if pct > 0.25 else Color(1.0, 0.20, 0.10, 0.9))
	ci.draw_rect(Rect2(x, y + 0.5, 2.0, 2.0), state_col)
	ci.draw_string(font, Vector2(x + 4.0, y + bar_h), lbl,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(hud_col.r, hud_col.g, hud_col.b, 0.8))
	# Hairline vertical rule between labels and bars.
	var rule_x := x + 17.0
	ci.draw_line(Vector2(rule_x, y - 0.5), Vector2(rule_x, y + bar_h + 0.5),
		Color(hud_col.r, hud_col.g, hud_col.b, 0.25), 0.6)
	var bx := rule_x + 3.0
	# Hairline track.
	ci.draw_line(Vector2(bx, y + bar_h * 0.5), Vector2(bx + bar_w, y + bar_h * 0.5),
		Color(hud_col.r, hud_col.g, hud_col.b, 0.22), 0.6)
	# 25%-interval tick marks.
	for tick_i in 3:
		var tx := bx + bar_w * (float(tick_i + 1) / 4.0)
		ci.draw_line(Vector2(tx, y), Vector2(tx, y + bar_h),
			Color(hud_col.r, hud_col.g, hud_col.b, 0.2), 0.6)
	var fill: float = pct * bar_w
	if fill > 0.5:
		# Hull-style red under-glow only when critical (caller passes low pct via col).
		ci.draw_line(Vector2(bx, y + bar_h * 0.5), Vector2(bx + fill, y + bar_h * 0.5), col, 1.5)
		var edge := Color(minf(col.r * 1.6, 1.0), minf(col.g * 1.6, 1.0), minf(col.b * 1.6, 1.0), 1.0)
		ci.draw_rect(Rect2(bx + fill - 0.6, y, 0.6, bar_h), edge)
	ci.draw_string(font, Vector2(bx + bar_w + 2.0, y + bar_h), "%3d" % int(pct * 100),
		HORIZONTAL_ALIGNMENT_RIGHT, 14.0, fs, Color(col.r, col.g, col.b, 0.65))

## Thin red under-glow beneath the hull track when hull% drops below 40%
## (Turn 4.1 techy garnish — subtle emergency cue, not a full bar restyle).
static func draw_hull_underglow(ci: CanvasItem, x: float, y: float, bar_w: float,
		bar_h: float, hull_pct: float, wobble: float) -> void:
	if hull_pct >= 0.4:
		return
	var a: float = (0.4 - hull_pct) / 0.4 * (0.25 + 0.15 * sin(wobble * 3.0))
	ci.draw_rect(Rect2(x - 1.0, y - 1.0, bar_w + 2.0, bar_h + 2.0), Color(1.0, 0.15, 0.08, a))

## Weapons row — hairline micro-caps labels + compact missile/EMP pip icons
## (Turn 4.1: smaller footprint, thinner strokes, same hairline language as
## the status panel).
static func draw_weapons_row(ci: CanvasItem, font: Font, fs: int, hud_col: Color,
		accent_col: Color, msl_col: Color, px: float, py: float,
		missiles: int, emp: int, wobble: float) -> void:
	var label_col := Color(hud_col.r, hud_col.g, hud_col.b, 0.8)
	ci.draw_string(font, Vector2(px + 3, py + 9), "MSL",
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, label_col)
	for i in 8:
		var ix: float = px + 18.0 + i * 4.4
		var iy: float = py + 3.0
		if i < missiles:
			var ga := 0.10 + 0.05 * sin(wobble * 2.0 + i * 0.4)
			ci.draw_circle(Vector2(ix + 1.1, iy + 2.0), 3.0, Color(msl_col.r, msl_col.g, msl_col.b, ga))
			ci.draw_colored_polygon(PackedVector2Array([
				Vector2(ix + 1.1, iy),
				Vector2(ix + 2.2, iy + 4.0),
				Vector2(ix,       iy + 4.0)
			]), msl_col)
		else:
			ci.draw_polyline(PackedVector2Array([
				Vector2(ix + 1.1, iy),
				Vector2(ix + 2.2, iy + 4.0),
				Vector2(ix,       iy + 4.0),
				Vector2(ix + 1.1, iy)
			]), Color(hud_col.r, hud_col.g, hud_col.b, 0.25), 0.6)
	var ex: float = px + 60.0
	ci.draw_string(font, Vector2(ex, py + 9), "EMP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, label_col)
	for i in 4:
		var rx: float = ex + 15.0 + i * 5.6
		var ry: float = py + 3.0
		if i < emp:
			var ga := 0.12 + 0.06 * sin(wobble * 2.0 + i * 0.6)
			ci.draw_circle(Vector2(rx + 2.0, ry + 2.0), 3.6, Color(accent_col.r, accent_col.g, accent_col.b, ga))
			ci.draw_rect(Rect2(rx, ry, 4, 4), Color(accent_col.r, accent_col.g, accent_col.b, 0.85))
			ci.draw_rect(Rect2(rx, ry, 4, 4), Color(1, 1, 1, 0.18), false, 0.6)
		else:
			ci.draw_rect(Rect2(rx, ry, 4, 4), Color(hud_col.r, hud_col.g, hud_col.b, 0.12), false, 0.6)

## Greedy word-wrap at a character budget per line.
static func wrap_text(text: String, chars_per_line: int) -> Array[String]:
	var lines: Array[String] = []
	var current := ""
	for word in text.split(" "):
		var candidate := word if current.is_empty() else current + " " + word
		if candidate.length() > chars_per_line and not current.is_empty():
			lines.append(current)
			current = word
		else:
			current = candidate
	if not current.is_empty():
		lines.append(current)
	return lines

## Recovered-log teletype panel body (title + wrapped lines + typing cursor).
static func draw_log_panel(ci: CanvasItem, font: Font, fs: int, px: float, py: float,
		lines: Array[String], title: String, reveal: float, total_len: int,
		wobble: float) -> void:
	var amber := Color(1.00, 0.69, 0.00, 0.85)
	ci.draw_string(font, Vector2(px + 6, py + 8), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, amber)
	for i in lines.size():
		ci.draw_string(font, Vector2(px + 6, py + 17 + i * 8.0), lines[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.62, 0.82, 0.62, 0.92))
	if reveal < float(total_len) and fmod(wobble, 0.5) < 0.3:
		var last_line: String = lines[lines.size() - 1] if not lines.is_empty() else ""
		var cx := px + 6 + font.get_string_size(last_line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		ci.draw_rect(Rect2(cx + 1, py + 12 + float(maxi(lines.size(), 1) - 1) * 8.0, 3, 5), amber)

## Score panel body — thin pulse hairline + micro "SCORE" subheader + readout
## (Turn 4.1: no heavy fill, smaller frame).
static func draw_score_display(ci: CanvasItem, font: Font, fs4: int, fs6: int,
		hud_col: Color, px: float, py: float, pw: float, ph: float,
		score: int, score_pulse: float) -> void:
	if score_pulse > 0.0:
		var pulse_col := Color(hud_col.r, hud_col.g, hud_col.b, score_pulse * 0.5)
		ci.draw_rect(Rect2(px - 1, py - 1, pw + 2, ph + 2), pulse_col, false, 0.6)
	ci.draw_string(font, Vector2(px + pw * 0.5 - 8, py + 4.5), "SCORE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs4, Color(hud_col.r, hud_col.g, hud_col.b, 0.75))
	ci.draw_string(font, Vector2(px + pw * 0.5 - 15, py + 9.5), "%07d" % score,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs6 - 1, hud_col)

## Kill-streak label + burn-down fuse bar, centered below the score panel.
static func draw_streak_display(ci: CanvasItem, font: Font, streak: int, streak_mult: int,
		streak_flash: float, fuse_pct: float, crit_flicker: Color, cx: float) -> void:
	var a: float = minf(streak_flash / 1.5, 1.0) if streak_flash > 0.0 else 0.65
	var col := Color(1.0, 0.80, 0.0, a)
	var label: String = "x%d STREAK" % streak_mult if streak_mult > 1 else "%d HITS" % streak
	ci.draw_string(font, Vector2(cx - 14.0, 25.0), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, col)
	var fuse_w := 28.0
	ci.draw_rect(Rect2(cx - fuse_w * 0.5, 27.0, fuse_w, 1.2), Color(0.25, 0.20, 0.02, 0.6))
	var fuse_col := Color(1.0, 0.80, 0.0, 0.75) if fuse_pct > 0.35 else crit_flicker
	ci.draw_rect(Rect2(cx - fuse_w * 0.5, 27.0, fuse_w * fuse_pct, 1.2), fuse_col)

## Danger-pay warning flag under the status panel.
static func draw_danger_pay(ci: CanvasItem, font: Font, fs: int, flick: float) -> void:
	ci.draw_string(font, Vector2(6.0, 58.0), "! DANGER PAY x1.5",
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.20, 0.10, flick))

## Mission-control tutorial-prompt panel body.
static func draw_mission_prompt(ci: CanvasItem, font: Font, fs: int, hud_col: Color,
		px: float, py: float, panel_w: float, pulse_alpha: float, text: String) -> void:
	var title_col := Color(hud_col.r, hud_col.g, hud_col.b, pulse_alpha)
	ci.draw_string(font, Vector2(px + 6, py + 8), "MISSION CONTROL",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, title_col)
	ci.draw_string(font, Vector2(px + 6, py + 17), text,
		HORIZONTAL_ALIGNMENT_LEFT, panel_w - 12.0, fs, Color(0.72, 1.00, 0.72, 0.92))

## Sector readout panel body — "SECTOR N" / "NO CARRIER" header + sector name.
static func draw_sector_display(ci: CanvasItem, font: Font, fs4: int, fs5: int,
		hud_col: Color, px: float, py: float, header_text: String,
		sector_name: String, glitch: float) -> void:
	ci.draw_string(font, Vector2(px + 4, py + 5.0), header_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs4, Color(hud_col.r, hud_col.g, hud_col.b, 0.8))
	text_ghost(ci, font, Vector2(px + 4, py + 5.0), header_text, fs4, hud_col, glitch)
	ci.draw_string(font, Vector2(px + 4, py + 10.5), sector_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs5, Color(hud_col.r, hud_col.g, hud_col.b, 0.88))

## Bottom-center context hint — state-aware flight prompt.
static func draw_context_hint(ci: CanvasItem, font: Font, fs: int, cx: float, y: float,
		state: int, state_enum: Dictionary) -> void:
	if state == int(state_enum["STAR_CLUSTER"]):
		ci.draw_string(font, Vector2(cx - 54, y),
			"FLY TO STAR  ▶  SCAN LOCKS ON IN RANGE",
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.22, 1.0, 0.08, 0.75))
	elif state == int(state_enum["SCANNING"]):
		ci.draw_string(font, Vector2(cx - 34, y),
			"SCANNING — [E] ABORT",
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.00, 0.80, 1.00, 0.85))
	elif state == int(state_enum["ALIEN_COMBAT"]):
		ci.draw_string(font, Vector2(cx - 46, y),
			"CLEAR ALL ENEMIES  ▶  HOLD [E] TO ESCAPE",
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.27, 0.0, 0.85))
