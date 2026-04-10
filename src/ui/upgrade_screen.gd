## UpgradeScreen — Between-sector upgrade selection using Data Crystals.
## GDD Ref: gameplay-mechanics.md §9 — Sector Transitions
extends Control

signal upgrade_done()

const COL_BG    := Color(0.00, 0.02, 0.05, 0.95)
const COL_LABEL := Color(0.22, 1.00, 0.08)
const COL_SEL   := Color(0.00, 0.80, 1.00)
const COL_DIM   := Color(0.08, 0.25, 0.08)
const COL_COST  := Color(0.00, 0.80, 1.00)
const COL_CANT  := Color(0.50, 0.20, 0.20)

const UPGRADES := [
	{"id": "hull",         "label": "HULL REINFORCEMENT", "cost": 5,  "desc": "Max Hull +20"},
	{"id": "fuel",         "label": "FUEL TANK EXPANSION","cost": 5,  "desc": "Max Fuel +25"},
	{"id": "shield_regen", "label": "SHIELD EMITTER",     "cost": 8,  "desc": "Shield Regen +3/s"},
	{"id": "missiles",     "label": "MISSILE BAY",        "cost": 8,  "desc": "Max Missiles +3"},
	{"id": "laser",        "label": "LASER FOCUS",        "cost": 10, "desc": "Laser Damage +4"},
]

var _selection: int = 0
var _visible_flag: bool = false

func _ready() -> void:
	hide()
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE
	process_mode  = Node.PROCESS_MODE_ALWAYS

func show_upgrades() -> void:
	_visible_flag = true
	_selection = 0
	get_tree().paused = true
	show()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_flag:
		return
	if event.is_action_just_pressed("move_up"):
		_selection = (_selection - 1 + UPGRADES.size()) % UPGRADES.size()
		queue_redraw()
	elif event.is_action_just_pressed("move_down"):
		_selection = (_selection + 1) % UPGRADES.size()
		queue_redraw()
	elif event.is_action_just_pressed("ui_accept"):
		_try_purchase()
	elif event.is_action_just_pressed("pause"):
		_skip()

func _try_purchase() -> void:
	var upg: Dictionary = UPGRADES[_selection]
	if GameManager.apply_upgrade(upg["id"]):
		_skip()

func _skip() -> void:
	_visible_flag = false
	get_tree().paused = false
	hide()
	upgrade_done.emit()

func _draw() -> void:
	var vp  := get_viewport_rect()
	var cx  := vp.size.x * 0.5
	var cy  := vp.size.y * 0.5
	var font := ThemeDB.fallback_font

	draw_rect(Rect2(Vector2.ZERO, vp.size), COL_BG)
	draw_string(font, Vector2(cx - 40, 12), "SECTOR UPGRADE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COL_LABEL)
	draw_string(font, Vector2(cx - 36, 24),
		"CRYSTALS: %d" % GameManager.data_crystals,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, COL_COST)
	draw_line(Vector2(8, 30), Vector2(vp.size.x - 8, 30), Color(0.08, 0.25, 0.08), 0.5)

	for i in UPGRADES.size():
		var upg: Dictionary = UPGRADES[i]
		var cost: int = upg["cost"]
		var can_afford := GameManager.data_crystals >= cost
		var is_sel := i == _selection

		var col_label := COL_SEL if is_sel else (COL_LABEL if can_afford else COL_CANT)
		var y := 42.0 + i * 20.0
		var prefix := "> " if is_sel else "  "
		draw_string(font, Vector2(cx - 70, y), prefix + upg["label"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, col_label)
		draw_string(font, Vector2(cx + 30, y), "[%d]" % cost,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, COL_COST if can_afford else COL_CANT)
		if is_sel:
			draw_string(font, Vector2(cx - 70, y + 9), "   " + upg["desc"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(0.50, 0.80, 0.50))

	draw_string(font, Vector2(cx - 50, vp.size.y - 10),
		"[SPACE] BUY    [ESC] SKIP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 4, COL_DIM)
