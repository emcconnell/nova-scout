## PickupVisuals — Concrete pickup with visual per type. Extends PickupBase.
## All 8 pickup types use this single script (type determines visual + effect).
## Icons are machined survey-equipment casings (PickupVisualsRenderer), not bullets.
class_name PickupVisuals
extends PickupBase

const COLORS := {
	"fuel_cell":    Color(1.00, 0.75, 0.00),
	"repair_kit":   Color(0.90, 0.10, 0.10),
	"missile_pack": Color(0.85, 0.85, 0.85),
	"emp_cartridge":Color(0.20, 0.60, 1.00),
	"energy_cell":  Color(0.40, 1.00, 0.20),
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
			PickupVisualsRenderer.draw_fuel_cell(self, col, alpha, _wobble)
		"repair_kit":
			PickupVisualsRenderer.draw_repair_kit(self, col, alpha, _wobble)
		"missile_pack":
			PickupVisualsRenderer.draw_missile_pack(self, col, alpha, _wobble)
		"emp_cartridge":
			PickupVisualsRenderer.draw_emp_cartridge(self, col, alpha, _wobble)
		"energy_cell":
			PickupVisualsRenderer.draw_energy_cell(self, col, alpha, _wobble)
		"crystal":
			PickupVisualsRenderer.draw_crystal(self, col, alpha, _wobble, spin)
		"shield_booster":
			PickupVisualsRenderer.draw_shield_booster(self, col, alpha, _wobble, spin)
		"survey_beacon":
			PickupVisualsRenderer.draw_survey_beacon(self, col, alpha, _wobble)
		_:
			draw_circle(Vector2.ZERO, 4.0, col)
