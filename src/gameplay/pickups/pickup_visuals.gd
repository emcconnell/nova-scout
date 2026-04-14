## PickupVisuals — Concrete pickup with visual per type. Extends PickupBase.
## All 8 pickup types use this single script (type determines visual + effect).
class_name PickupVisuals
extends PickupBase

const COLORS := {
	"fuel_cell":    Color(1.00, 0.75, 0.00),
	"repair_kit":   Color(0.90, 0.10, 0.10),
	"missile_pack": Color(0.85, 0.85, 0.85),
	"emp_cartridge":Color(0.20, 0.60, 1.00),
	"crystal":      Color(0.00, 0.90, 1.00),
	"shield_booster":Color(0.00, 0.50, 1.00),
	"survey_beacon":Color(1.00, 0.85, 0.00),
}

func _draw_pickup(alpha: float) -> void:
	var col: Color = COLORS.get(pickup_type, Color(0.8, 0.8, 0.8))
	col.a = alpha
	var spin := _wobble * 1.5

	# Outer glow ring (all pickups)
	var glow_r := 10.0 + 2.0 * sin(_wobble * 2.5)
	var glow_a := (0.08 + 0.06 * sin(_wobble * 2.0)) * alpha
	draw_arc(Vector2.ZERO, glow_r, 0, TAU, 20, Color(col.r, col.g, col.b, glow_a), 0.5)
	# Inner soft glow disc
	var disc_a := (0.06 + 0.04 * sin(_wobble * 1.8)) * alpha
	draw_circle(Vector2.ZERO, 8.0, Color(col.r, col.g, col.b, disc_a))

	match pickup_type:
		"fuel_cell":
			# Yellow canister with pulsing ring + energy dots
			draw_rect(Rect2(-4, -6, 8, 12), col)
			draw_circle(Vector2(0, -6), 3.0, col)
			# Highlight stripe on canister
			draw_rect(Rect2(-1, -5, 2, 10), Color(1, 1, 0.7, 0.4 * alpha))
			var pa := 0.3 + 0.3 * sin(_wobble * 2.0)
			draw_arc(Vector2.ZERO, 7.0, 0, TAU, 20, Color(col.r, col.g, col.b, pa), 1.0)
			# Orbiting energy dots
			for dot_i in 3:
				var da := TAU / 3.0 * dot_i + _wobble * 1.5
				var dx := cos(da) * 9.0
				var dy := sin(da) * 9.0
				draw_circle(Vector2(dx, dy), 0.8, Color(1.0, 0.9, 0.3, pa * alpha))

		"repair_kit":
			# Red cross box with pulsing glow cross
			draw_rect(Rect2(-5, -5, 10, 10), col)
			# Glow behind cross
			var rpa := 0.2 + 0.15 * sin(_wobble * 2.5)
			draw_rect(Rect2(-3, -7, 6, 14), Color(1, 0.5, 0.5, rpa * alpha))
			draw_rect(Rect2(-7, -3, 14, 6), Color(1, 0.5, 0.5, rpa * alpha))
			# White cross
			draw_rect(Rect2(-2, -6, 4, 12), Color(1,1,1, alpha))
			draw_rect(Rect2(-6, -2, 12, 4), Color(1,1,1, alpha))
			# Corner dots
			for ci in 4:
				var cdx := -5.0 if ci % 2 == 0 else 5.0
				var cdy := -5.0 if ci < 2 else 5.0
				draw_circle(Vector2(cdx, cdy), 0.8, Color(1, 0.3, 0.3, 0.5 * alpha))

		"missile_pack":
			# Torpedo cluster with exhaust glow
			for i in 3:
				var ox := (i - 1) * 4.0
				# Exhaust glow
				var exa := 0.2 + 0.15 * sin(_wobble * 3.0 + i)
				draw_circle(Vector2(ox, 4.0), 2.0, Color(1.0, 0.5, 0.0, exa * alpha))
				# Body
				draw_rect(Rect2(ox - 1.5, -6, 3, 9), col)
				draw_circle(Vector2(ox, -6), 1.5, col)
				# Nose highlight
				draw_circle(Vector2(ox, -6), 0.8, Color(1, 1, 1, 0.35 * alpha))

		"emp_cartridge":
			# Blue ring icon with electric arcs
			draw_circle(Vector2.ZERO, 5.0, Color(col.r, col.g, col.b, 0.3 * alpha))
			draw_arc(Vector2.ZERO, 5.0, 0, TAU, 20, col, 2.0)
			draw_circle(Vector2.ZERO, 2.0, col)
			# Pulsing outer ring
			var epr := 7.0 + 1.5 * sin(_wobble * 3.0)
			draw_arc(Vector2.ZERO, epr, 0, TAU, 16, Color(0.4, 0.7, 1.0, 0.25 * alpha), 0.5)
			# Electric arc segments
			for arc_i in 4:
				var arc_a := TAU / 4.0 * arc_i + _wobble * 2.0
				var arc_start := Vector2(cos(arc_a) * 5.0, sin(arc_a) * 5.0)
				var arc_mid := Vector2(cos(arc_a + 0.3) * 7.0, sin(arc_a + 0.3) * 7.0)
				var arc_end := Vector2(cos(arc_a + 0.6) * 5.5, sin(arc_a + 0.6) * 5.5)
				var arc_alpha := (0.3 + 0.3 * sin(_wobble * 4.0 + arc_i)) * alpha
				draw_line(arc_start, arc_mid, Color(0.6, 0.8, 1.0, arc_alpha), 0.5)
				draw_line(arc_mid, arc_end, Color(0.6, 0.8, 1.0, arc_alpha), 0.5)

		"crystal":
			# Cyan spinning diamond with inner facets and sparkle
			var pts := PackedVector2Array([
				Vector2(0, -7).rotated(spin),
				Vector2(5, 0).rotated(spin),
				Vector2(0, 7).rotated(spin),
				Vector2(-5, 0).rotated(spin)
			])
			# Glow behind crystal
			draw_circle(Vector2.ZERO, 5.0, Color(col.r, col.g, col.b, 0.15 * alpha))
			draw_colored_polygon(pts, col)
			# Inner facet lines
			draw_polyline(PackedVector2Array([pts[0], pts[2]]), Color(1,1,1,0.4*alpha), 1.0)
			draw_polyline(PackedVector2Array([pts[1], pts[3]]), Color(1,1,1,0.25*alpha), 0.5)
			# Sparkle at top
			var sp_a := 0.4 + 0.5 * sin(_wobble * 4.0)
			draw_circle(pts[0], 1.2, Color(1, 1, 1, sp_a * alpha))

		"shield_booster":
			# Blue hexagon with energy field
			var hex := PackedVector2Array()
			for i in 6:
				var a := TAU / 6.0 * i + spin * 0.3
				hex.append(Vector2(cos(a) * 5.0, sin(a) * 5.0))
			draw_colored_polygon(hex, Color(col.r, col.g, col.b, 0.4 * alpha))
			draw_polyline(hex + PackedVector2Array([hex[0]]), col, 1.5)
			# Pulsing shield ring
			var shr := 7.0 + 1.0 * sin(_wobble * 2.0)
			var sha := 0.2 + 0.15 * sin(_wobble * 2.5)
			draw_arc(Vector2.ZERO, shr, 0, TAU, 16, Color(0.3, 0.6, 1.0, sha * alpha), 0.5)
			# Inner glow
			draw_circle(Vector2.ZERO, 3.0, Color(0.4, 0.7, 1.0, 0.2 * alpha))

		"survey_beacon":
			# Gold satellite dish with broadcast waves
			draw_arc(Vector2(0, -2), 6.0, -PI * 0.8, PI * 1.8, 16, col, 2.0)
			draw_line(Vector2(0, -2), Vector2(0, 5), col, 1.5)
			draw_circle(Vector2(0, 5), 2.0, col)
			var ba := 0.5 + 0.5 * sin(_wobble * 3.0)
			draw_circle(Vector2(0, -8), 2.0, Color(1.0, 0.95, 0.0, ba * alpha))
			# Broadcast wave arcs
			for wi in 3:
				var wr := 4.0 + float(wi) * 3.0 + 1.5 * sin(_wobble * 2.0 + wi)
				var wa := (0.3 - float(wi) * 0.08) * alpha
				draw_arc(Vector2(0, -8), wr, -PI * 0.4, PI * 0.4, 8,
					Color(1.0, 0.9, 0.2, wa), 0.5)
			# Pulsing base glow
			draw_circle(Vector2(0, 5), 3.5, Color(col.r, col.g, col.b, 0.12 * alpha))

		_:
			draw_circle(Vector2.ZERO, 4.0, col)
