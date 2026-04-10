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

	match pickup_type:
		"fuel_cell":
			# Yellow canister with pulsing ring
			draw_rect(Rect2(-4, -6, 8, 12), col)
			draw_circle(Vector2(0, -6), 3.0, col)
			var pa := 0.3 + 0.3 * sin(_wobble * 2.0)
			draw_arc(Vector2.ZERO, 7.0, 0, TAU, 20, Color(col.r, col.g, col.b, pa), 1.0)

		"repair_kit":
			# Red cross box
			draw_rect(Rect2(-5, -5, 10, 10), col)
			draw_rect(Rect2(-2, -6, 4, 12), Color(1,1,1, alpha))  # cross v
			draw_rect(Rect2(-6, -2, 12, 4), Color(1,1,1, alpha))  # cross h

		"missile_pack":
			# Torpedo cluster (3 small torpedoes)
			for i in 3:
				var ox := (i - 1) * 4.0
				draw_rect(Rect2(ox - 1.5, -6, 3, 9), col)
				draw_circle(Vector2(ox, -6), 1.5, col)

		"emp_cartridge":
			# Blue ring icon
			draw_circle(Vector2.ZERO, 5.0, Color(col.r, col.g, col.b, 0.3 * alpha))
			draw_arc(Vector2.ZERO, 5.0, 0, TAU, 20, col, 2.0)
			draw_circle(Vector2.ZERO, 2.0, col)

		"crystal":
			# Cyan spinning diamond
			var pts := PackedVector2Array([
				Vector2(0, -6).rotated(spin),
				Vector2(4, 0).rotated(spin),
				Vector2(0, 6).rotated(spin),
				Vector2(-4, 0).rotated(spin)
			])
			draw_colored_polygon(pts, col)
			draw_polyline(PackedVector2Array([pts[0], pts[2]]), Color(1,1,1,0.4*alpha), 1.0)

		"shield_booster":
			# Blue hexagon
			var hex := PackedVector2Array()
			for i in 6:
				var a := TAU / 6.0 * i + spin * 0.3
				hex.append(Vector2(cos(a) * 5.0, sin(a) * 5.0))
			draw_colored_polygon(hex, Color(col.r, col.g, col.b, 0.4 * alpha))
			draw_polyline(hex + PackedVector2Array([hex[0]]), col, 1.5)

		"survey_beacon":
			# Gold satellite dish
			draw_arc(Vector2(0, -2), 6.0, -PI * 0.8, PI * 1.8, 16, col, 2.0)
			draw_line(Vector2(0, -2), Vector2(0, 5), col, 1.5)
			draw_circle(Vector2(0, 5), 2.0, col)
			var ba := 0.5 + 0.5 * sin(_wobble * 3.0)
			draw_circle(Vector2(0, -8), 2.0, Color(1.0, 0.95, 0.0, ba * alpha))

		_:
			draw_circle(Vector2.ZERO, 4.0, col)
