## UpgradeScreen — Between-sector upgrade selection. Hangar bay aesthetic.
## Selection highlight and cost readouts retint live to VisualState.pal("accent")
## (Turn 4). Title ghosts at high blend, matching the HUD failure language.
## GDD Ref: gameplay-mechanics.md §9 — Sector Transitions; art-bible.md Turn 4
extends Control

signal upgrade_done()

const COL_BG      := Color(0.03, 0.04, 0.07)
const COL_METAL   := Color(0.06, 0.08, 0.12)
const COL_DARK    := Color(0.02, 0.03, 0.05)
const COL_LABEL   := Color(0.22, 1.00, 0.08)
const COL_DIM     := Color(0.08, 0.25, 0.08)
const COL_CANT    := Color(0.40, 0.15, 0.15)
const COL_BORDER  := Color(0.08, 0.22, 0.12)
const COL_RIVET   := Color(0.08, 0.10, 0.14)

const UPGRADES := [
	{"id": "hull",         "branch": "SURVIVOR", "label": "HULL REINFORCEMENT", "cost": 5,  "desc": "Max Hull +20"},
	{"id": "fuel",         "branch": "EXPLORER", "label": "FUEL TANK EXPANSION","cost": 5,  "desc": "Max Fuel +25"},
	{"id": "shield_regen", "branch": "SURVIVOR", "label": "SHIELD EMITTER",     "cost": 8,  "desc": "Shield Regen +3/s"},
	{"id": "missiles",     "branch": "FIGHTER",  "label": "MISSILE BAY",        "cost": 8,  "desc": "Max Missiles +3"},
	{"id": "laser",        "branch": "FIGHTER",  "label": "LASER FOCUS",        "cost": 10, "desc": "Laser Damage +4"},
]

var _selection: int = 0
var _visible_flag: bool = false
var _anim: float = 0.0
var _font_title: Font = null
var _font_body: Font = null

func _ready() -> void:
	hide()
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE
	process_mode  = Node.PROCESS_MODE_ALWAYS
	_font_title = load("res://assets/fonts/Orbitron.ttf") as Font
	_font_body = load("res://assets/fonts/ShareTechMono-Regular.ttf") as Font
	if _font_title == null: _font_title = ThemeDB.fallback_font
	if _font_body == null: _font_body = ThemeDB.fallback_font

func show_upgrades() -> void:
	_visible_flag = true
	_selection = 0
	_anim = 0.0
	GameManager.change_state(GameManager.GameState.UPGRADE_SCREEN)
	get_tree().paused = true
	show()
	queue_redraw()

func _process(delta: float) -> void:
	if not _visible_flag:
		return
	_anim += delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_flag:
		return
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action("move_up"):
		_selection = (_selection - 1 + UPGRADES.size()) % UPGRADES.size()
		AudioManager.play_sfx("ui_navigate")
		queue_redraw()
	elif event.is_action("move_down"):
		_selection = (_selection + 1) % UPGRADES.size()
		AudioManager.play_sfx("ui_navigate")
		queue_redraw()
	elif event.is_action("ui_accept"):
		_try_purchase()
	elif event.is_action("pause"):
		_skip()

func _try_purchase() -> void:
	var upg: Dictionary = UPGRADES[_selection]
	if GameManager.apply_upgrade(upg["id"]):
		AudioManager.play_sfx("upgrade_select")
		_skip()

func _skip() -> void:
	_visible_flag = false
	get_tree().paused = false
	hide()
	upgrade_done.emit()

func _draw() -> void:
	var vp  := get_viewport_rect()
	var w   := vp.size.x
	var h   := vp.size.y
	var cx  := w * 0.5
	var font := _font_body
	var accent_col := VisualState.pal("accent")

	# === Fully opaque background ===
	draw_rect(Rect2(Vector2.ZERO, vp.size), COL_BG)

	# === Hangar frame ===
	# Top/bottom metal bars
	draw_rect(Rect2(0, 0, w, 16), COL_METAL)
	draw_rect(Rect2(0, 14, w, 2), COL_DARK)
	draw_rect(Rect2(0, h - 16, w, 16), COL_METAL)
	draw_rect(Rect2(0, h - 16, w, 2), COL_DARK)
	# Side rails
	draw_rect(Rect2(0, 16, 6, h - 32), COL_METAL)
	draw_rect(Rect2(w - 6, 16, 6, h - 32), COL_METAL)
	# Rivets
	for ri in 14:
		var rx := 16.0 + ri * 22.0
		if rx > w - 16:
			break
		draw_circle(Vector2(rx, 7), 1.2, COL_RIVET)
		draw_circle(Vector2(rx, h - 7), 1.2, COL_RIVET)

	# === Header ===
	var title := "UPGRADE BAY"
	var title_pos := Vector2(cx - 44, 30)
	draw_string(_font_title, title_pos, title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COL_LABEL)
	var glitch := VisualState.blend()
	if glitch > 0.5:
		draw_string(_font_title, title_pos + Vector2(2.5, 1.0), title,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(COL_LABEL.r, COL_LABEL.g, COL_LABEL.b, 0.3 * glitch))
	draw_line(Vector2(14, 36), Vector2(w - 14, 36), COL_BORDER, 1.0)

	# Crystal count
	var crystal_str := "DATA CRYSTALS:  %d" % GameManager.data_crystals
	draw_string(font, Vector2(cx - 38, 48), crystal_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, accent_col)

	# === Upgrade items ===
	for i in UPGRADES.size():
		var upg: Dictionary = UPGRADES[i]
		var cost: int = upg["cost"]
		var can_afford := GameManager.data_crystals >= cost
		var is_sel := i == _selection

		var item_y := 62.0 + i * 22.0

		# Selection highlight bar
		if is_sel:
			var sel_a := 0.08 + 0.04 * sin(_anim * 4.0)
			draw_rect(Rect2(14, item_y - 4, w - 28, 20),
				Color(accent_col.r, accent_col.g, accent_col.b, sel_a))
			draw_rect(Rect2(14, item_y - 4, w - 28, 20),
				Color(accent_col.r, accent_col.g, accent_col.b, 0.2), false, 1.0)

		# Selector arrow
		var label_col := accent_col if is_sel else (COL_LABEL if can_afford else COL_CANT)
		var prefix := "> " if is_sel else "  "
		draw_string(font, Vector2(18, item_y + 6), prefix + "[%s]" % String(upg.get("branch", "CORE")),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 4, accent_col if is_sel else COL_DIM)
		draw_string(font, Vector2(74, item_y + 6), upg["label"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, label_col)

		# Cost
		var cost_col := accent_col if can_afford else COL_CANT
		draw_string(font, Vector2(w - 60, item_y + 6), "[%d]" % cost,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, cost_col)

		# Description on selected item
		if is_sel:
			draw_string(font, Vector2(32, item_y + 15), upg["desc"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 4, Color(0.50, 0.80, 0.50))
			draw_string(font, Vector2(w - 132, item_y + 15), _upgrade_comparison_text(String(upg["id"])),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 4, accent_col if can_afford else COL_DIM)

	# === Footer ===
	draw_line(Vector2(14, h - 28), Vector2(w - 14, h - 28), COL_BORDER, 1.0)
	var hint_a := 0.5 + 0.3 * sin(_anim * 3.0)
	draw_string(font, Vector2(cx - 84, h - 18),
		"W/S OR STICK SELECT    A / SPACE INSTALL    ESC / START SKIP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(COL_DIM.r, COL_DIM.g, COL_DIM.b, hint_a))

func _upgrade_comparison_text(upgrade_id: String) -> String:
	match upgrade_id:
		"hull": return "CURRENT → NEXT  HULL %d → %d" % [GameManager.player_max_hull, GameManager.player_max_hull + 20]
		"fuel": return "CURRENT → NEXT  FUEL %d → %d" % [GameManager.player_max_fuel, GameManager.player_max_fuel + 25]
		"shield_regen": return "CURRENT → NEXT  REGEN %.1f → %.1f" % [GameManager.player_shield_regen, GameManager.player_shield_regen + 3.0]
		"missiles": return "CURRENT → NEXT  MSL %d → %d" % [GameManager.player_max_missiles, GameManager.player_max_missiles + 3]
		"laser": return "CURRENT → NEXT  DMG %d → %d" % [GameManager.player_laser_damage, GameManager.player_laser_damage + 4]
		_: return "CURRENT → NEXT"
