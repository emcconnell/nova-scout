## HUDDisplay — Immediate-mode HUD, TURN 4 flight-instrument aesthetic.
## Corner-bracket panels, bar polish, weapon icon rows, sector header.
## Retints cyan (SURVEY) → failing red (DEAD) via VisualState.pal("hud") and
## grows glitch/ghosting/dropouts as hull damage compounds with the fade.
## GDD Ref: gameplay-mechanics.md §8 — HUD; art-bible.md Turn 4
extends Control

# ─── Player reference ─────────────────────────────────────────────────────────
var _player: Player = null

# ─── Cached values ────────────────────────────────────────────────────────────
var _hull: int       = 100
var _max_hull: int   = 100
var _shield: int     = 60
var _fuel: float     = 100.0
var _max_fuel: float = 100.0
var _missiles: int   = 6
var _emp: int        = 2
var _energy: float   = 100.0
var _max_energy: float = 100.0
var _overheated: bool = false
var _score: int      = 0

# ─── Animation ────────────────────────────────────────────────────────────────
var _wobble: float = 0.0

# ─── Streak state (Change 7c) ─────────────────────────────────────────────────
var _streak: int = 0
var _streak_mult: int = 1
var _streak_flash: float = 0.0

# ─── Score pulse state ───────────────────────────────────────────────────────
var _score_pulse: float = 0.0

# ─── Mission-control prompt state ─────────────────────────────────────────────
var _mission_prompt_text: String = ""
var _mission_prompt_pulse: float = 0.0

# ─── Recovered log fragment state (dark-directive.md §4.4) ────────────────────
var _log_title: String = ""
var _log_text: String = ""
var _log_reveal: float = 0.0      # characters revealed (typewriter)
var _log_hold: float = 0.0        # seconds to hold after full reveal
var _log_click_acc: int = 0       # chars since last typewriter click

# ─── Palette (fallback tones; most panels retint live via _hud_col()/_pal()) ──
const COL_CRIT    := Color(1.00, 0.20, 0.10)
const COL_MSL     := Color(0.82, 0.84, 0.80)

const BAR_W := 34.0
const BAR_H := 2.0

# ─── HUD failure state (Turn 4: glitch = blend * (1 - hull%)) ─────────────────
var _glitch_bars: Array[Rect2] = []
var _glitch_timer: float = 0.0
var _glitch_rng := RandomNumberGenerator.new()
var _dropout_alpha: float = 1.0
var _dropout_timer: float = 0.0
var _heading_scroll: float = 0.0

var _font: Font = null

# ─── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	_font = load("res://assets/fonts/ShareTechMono-Regular.ttf") as Font
	if _font == null:
		_font = ThemeDB.fallback_font
	anchor_right  = 1.0
	anchor_bottom = 1.0
	mouse_filter  = Control.MOUSE_FILTER_IGNORE
	GameManager.score_changed.connect(func(v): _score = v; _score_pulse = 0.8; queue_redraw())
	GameManager.streak_changed.connect(_on_streak_changed)
	GameManager.danger_pay_changed.connect(func(_a): queue_redraw())

func _process(delta: float) -> void:
	_wobble += delta * 5.0
	_heading_scroll += delta * 6.0
	var hull_crit: bool = float(_hull) / maxf(_max_hull, 1) < 0.25
	var fuel_crit: bool = _fuel / maxf(_max_fuel, 1) < 0.15
	if hull_crit or fuel_crit:
		queue_redraw()
	if _streak_flash > 0.0:
		_streak_flash -= delta
		queue_redraw()
	if _streak >= 3 or GameManager.danger_pay_active:
		queue_redraw()   # Fuse bar and danger flicker animate continuously
	if _score_pulse > 0.0:
		_score_pulse -= delta
		queue_redraw()
	if not _mission_prompt_text.is_empty():
		_mission_prompt_pulse += delta * 3.0
		queue_redraw()
	_update_log_fragment(delta)
	_update_hud_failure(delta)

## Current HUD failure factor: blend * (1 - hull%), gated so damage-free flight
## at any blend stays clean (spec: glitch scales with hull% AND blend together).
func _hud_glitch() -> float:
	var hull_pct: float = float(_hull) / maxf(_max_hull, 1.0)
	var threshold: float = float(VisualState.value("film", "hud_glitch_hull_threshold", 0.5))
	var raw: float = VisualState.blend() * (1.0 - hull_pct)
	var gate: float = 1.0 - smoothstep(threshold * 0.6, threshold, hull_pct)
	return clampf(raw * gate, 0.0, 1.0)

## Advance glitch-bar reseed timer, dropout flicker, and queue redraws while failing.
func _update_hud_failure(delta: float) -> void:
	var glitch := _hud_glitch()
	if glitch <= 0.001:
		_dropout_alpha = 1.0
		return
	_glitch_timer -= delta
	if _glitch_timer <= 0.0:
		_glitch_timer = 0.4
		_glitch_rng.randomize()
		var vp_w: float = get_viewport_rect().size.x
		_glitch_bars = HudRenderer.reseed_glitch_bars(_glitch_rng, vp_w)
	_dropout_timer -= delta
	if _dropout_timer <= 0.0:
		_dropout_timer = randf_range(2.5, 6.0) / maxf(glitch, 0.1)
		_dropout_alpha = 1.0
	elif _dropout_timer > 0.0 and _dropout_timer < 0.08 * glitch and randf() < glitch * 0.6:
		_dropout_alpha = 0.35
	else:
		_dropout_alpha = 1.0
	queue_redraw()

## Advance the typewriter reveal; dismiss after the hold expires.
func _update_log_fragment(delta: float) -> void:
	if _log_text.is_empty():
		return
	if _log_reveal < float(_log_text.length()):
		_log_reveal = minf(_log_reveal + delta * 26.0, float(_log_text.length()))
		_log_click_acc += 1
		if _log_click_acc >= 3:
			_log_click_acc = 0
			AudioManager.play_sfx("typewriter_click", 0.35)
	else:
		_log_hold -= delta
		if _log_hold <= 0.0:
			_log_title = ""
			_log_text = ""
	queue_redraw()

## Display a recovered probe log with a typewriter reveal.
func show_log_fragment(title: String, text: String) -> void:
	_log_title = title
	_log_text = text
	_log_reveal = 0.0
	_log_hold = 6.5
	_log_click_acc = 0
	queue_redraw()

func connect_player(p: Player) -> void:
	_player   = p
	_max_hull = GameManager.player_max_hull
	_max_fuel = float(GameManager.player_max_fuel)
	_hull     = p.health.hull
	_shield   = p.health.shield
	_fuel     = p.fuel_sys.fuel
	_missiles = p.weapons.missiles
	_emp      = p.weapons.emp_charges
	_score    = GameManager.score
	p.health.hull_changed.connect(func(v):      _hull    = v; queue_redraw())
	p.health.shield_changed.connect(func(v):    _shield  = v; queue_redraw())
	p.fuel_sys.fuel_changed.connect(func(v):    _fuel    = v; queue_redraw())
	p.weapons.missiles_changed.connect(func(v): _missiles = v; queue_redraw())
	p.weapons.emp_changed.connect(func(v):      _emp     = v; queue_redraw())
	p.weapons.energy_changed.connect(func(v):   _energy  = v; queue_redraw())
	_energy = p.weapons.energy
	_max_energy = p.weapons.max_energy
	queue_redraw()

## Show a mission-control tutorial prompt in the HUD.
func show_mission_prompt(text: String) -> void:
	_mission_prompt_text = text
	_mission_prompt_pulse = 0.0
	queue_redraw()

## Clear the active mission-control tutorial prompt from the HUD.
func clear_mission_prompt() -> void:
	_mission_prompt_text = ""
	_mission_prompt_pulse = 0.0
	queue_redraw()

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _text_scale() -> float:
	return clampf(float(SaveManager.get_setting("text_scale")), 0.75, 1.5)

func _fs(base_size: int) -> int:
	return maxi(1, int(round(float(base_size) * _text_scale())))

## Primary HUD color — cyan flight-instrument (SURVEY) to failing red (DEAD).
func _pal_hud() -> Color:
	return VisualState.pal("hud")

## Secondary HUD accent — same fade family, used for shield/EMP readouts.
func _pal_accent() -> Color:
	return VisualState.pal("accent")

func _friendly_color(col: Color) -> Color:
	if not bool(SaveManager.get_setting("color_friendly")):
		return col
	if col == _pal_hud() or col == COL_CRIT:
		return Color(1.00, 0.72, 0.10, col.a)
	if col == _pal_accent():
		return Color(0.92, 0.75, 1.00, col.a)
	return col

func _flicker(col: Color) -> Color:
	col = _friendly_color(col)
	var a: float = 0.45 + 0.55 * abs(sin(_wobble * 2.5))
	return Color(col.r, col.g, col.b, a)

## Corner-bracket panel — thin flight-FUI style (Turn 4: line weight 0.8-1.2, alpha 0.5).
func _panel(x: float, y: float, w: float, h: float, cs: float = 6.0) -> void:
	HudRenderer.draw_panel(self, _pal_hud(), x, y, w, h, cs)

# ─── Main draw ────────────────────────────────────────────────────────────────

func _draw() -> void:
	# Hide HUD during overlay screens (sector transition, upgrade, death, win)
	var state := GameManager.current_state
	if state == GameManager.GameState.MENU or \
	   state == GameManager.GameState.DEATH or \
	   state == GameManager.GameState.WIN or \
	   state == GameManager.GameState.SECTOR_TRANSITION or \
	   state == GameManager.GameState.UPGRADE_SCREEN:
		return
	# HUD failure: occasional whole-panel alpha dropout (modulate covers every
	# draw call below without restructuring each one).
	modulate = Color(1.0, 1.0, 1.0, _dropout_alpha)
	var font := _font
	var glitch := _hud_glitch()
	_draw_status_panel(font)
	_draw_weapons_panel(font)
	_draw_score_display(font)
	_draw_sector_display(font)
	_draw_streak_display(font)
	_draw_danger_pay(font)
	_draw_mission_prompt(font)
	_draw_log_fragment(font)
	_draw_context_hint(font)
	_draw_flight_fui(font)
	HudRenderer.draw_glitch_bars(self, _glitch_bars, _pal_hud(), glitch)
	if glitch > 0.01:
		HudRenderer.signal_lost_banner(self, font, get_viewport_rect().size,
			VisualState.blend(), _pal_hud())

## Survey flight-instrument touch: one compact heading tape tucked under the
## score panel — no reticle (Turn 4.2: kill top-center clutter and overlap).
func _draw_flight_fui(font: Font) -> void:
	var vp := get_viewport_rect()
	var hud_col := _pal_hud()
	var tape_col := Color(hud_col.r, hud_col.g, hud_col.b, 0.45)
	HudRenderer.heading_tape(self, font, vp.size.x * 0.5, 15.5, 26.0, _heading_scroll, tape_col)

# ─── Recovered log — amber teletype panel, lower third ───────────────────────

func _draw_log_fragment(font: Font) -> void:
	if _log_text.is_empty():
		return
	var vp := get_viewport_rect()
	var lines := HudRenderer.wrap_text(_log_text.substr(0, int(_log_reveal)), 50)
	var panel_w := 236.0
	var panel_h := 16.0 + float(maxi(lines.size(), 1)) * 8.0
	var px: float = vp.size.x * 0.5 - panel_w * 0.5
	var py: float = vp.size.y - panel_h - 22.0
	_panel(px, py, panel_w, panel_h, 5.0)
	HudRenderer.draw_log_panel(self, font, _fs(5), px, py, lines, _log_title,
		_log_reveal, _log_text.length(), _wobble)

# ─── Status panel — top-left ──────────────────────────────────────────────────

func _draw_status_panel(font: Font) -> void:
	var px := 3.0; var py := 3.0; var pw := 62.0; var ph := 33.0
	_panel(px, py, pw, ph, 4.0)
	var hud_col := _pal_hud()

	# Header strip — hairline underline only, no filled bar (techy, less crowd).
	var header_text := "SHIP STATUS" if VisualState.blend() < 0.9 else "NO CARRIER"
	draw_string(font, Vector2(px + 4, py + 6.5), header_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(4), Color(hud_col.r, hud_col.g, hud_col.b, 0.75))
	HudRenderer.text_ghost(self, font, Vector2(px + 4, py + 6.5), header_text, _fs(4), hud_col, _hud_glitch())
	draw_line(Vector2(px + 2, py + 9), Vector2(px + pw - 2, py + 9),
		Color(hud_col.r, hud_col.g, hud_col.b, 0.2), 0.6)

	# Bars — hairline tracks, 6px row pitch.
	var hull_pct: float = float(_hull) / maxf(_max_hull, 1)
	var fuel_pct: float = _fuel / maxf(_max_fuel, 1)
	HudRenderer.draw_hull_underglow(self, px + 3, py + 12, BAR_W, BAR_H, hull_pct, _wobble)
	HudRenderer.draw_bar(self, font, _fs(4), hud_col, px + 3, py + 12, BAR_W, BAR_H, _wobble,
		"HULL", float(_hull), float(_max_hull),
		_friendly_color(hud_col) if hull_pct > 0.25 else _flicker(COL_CRIT))
	HudRenderer.draw_bar(self, font, _fs(4), hud_col, px + 3, py + 18, BAR_W, BAR_H, _wobble,
		"SHLD", float(_shield), 100.0, _friendly_color(_pal_accent()))
	HudRenderer.draw_bar(self, font, _fs(4), hud_col, px + 3, py + 24, BAR_W, BAR_H, _wobble,
		"FUEL", _fuel, _max_fuel,
		_friendly_color(hud_col) if fuel_pct > 0.15 else _flicker(COL_CRIT))
	# Energy bar — flashes red when overheated
	_overheated = _player.weapons.is_overheated() if _player and _player.weapons else false
	var energy_col := _flicker(COL_CRIT) if _overheated else _friendly_color(hud_col)
	HudRenderer.draw_bar(self, font, _fs(4), hud_col, px + 3, py + 30, BAR_W, BAR_H, _wobble,
		"ENRG", _energy, _max_energy, energy_col)

# ─── Weapons panel — bottom-left ──────────────────────────────────────────────

func _draw_weapons_panel(font: Font) -> void:
	var vp  := get_viewport_rect()
	var pw  := 96.0; var ph := 12.0
	var px  := 3.0;   var py := vp.size.y - ph - 3.0
	_panel(px, py, pw, ph, 3.5)
	var hud_col := _pal_hud()
	var msl_col := VisualState.col(COL_MSL, Color(0.82, 0.55, 0.52))
	HudRenderer.draw_weapons_row(self, font, _fs(4), hud_col, _pal_accent(), msl_col,
		px, py, _missiles, _emp, _wobble)

# ─── Score display — top-center ───────────────────────────────────────────────

func _draw_score_display(font: Font) -> void:
	var vp  := get_viewport_rect()
	var pw  := 40.0; var ph := 10.0
	var px: float  = vp.size.x * 0.5 - pw * 0.5
	var py  := 2.0
	_panel(px, py, pw, ph, 3.0)
	HudRenderer.draw_score_display(self, font, _fs(4), _fs(6), _pal_hud(),
		px, py, pw, ph, _score, _score_pulse)

func _on_streak_changed(streak: int, mult: int) -> void:
	_streak = streak
	_streak_mult = mult
	_streak_flash = 1.5
	queue_redraw()

# ─── Streak display — below score panel (Change 7c) ───────────────────────────

func _draw_streak_display(font: Font) -> void:
	if _streak < 3:
		return
	var decay: float = float(GameManager.dread_value("streak", "decay_time", 6.0))
	var fuse_pct: float = clampf(GameManager.streak_fuse / maxf(decay, 0.01), 0.0, 1.0)
	HudRenderer.draw_streak_display(self, font, _streak, _streak_mult, _streak_flash,
		fuse_pct, _flicker(COL_CRIT), get_viewport_rect().size.x * 0.5)

## Danger pay — hull-critical score bonus flag, drawn under the status panel.
## Red is reserved for threat; riding the edge for +50% is a threat you chose.
func _draw_danger_pay(font: Font) -> void:
	if not GameManager.danger_pay_active:
		return
	var flick := 0.62 + 0.38 * absf(sin(_wobble * 3.2))
	HudRenderer.draw_danger_pay(self, font, _fs(4), flick)

func _draw_mission_prompt(font: Font) -> void:
	if _mission_prompt_text.is_empty():
		return
	var vp := get_viewport_rect()
	var panel_w := 224.0
	var panel_h := 22.0
	var px: float = vp.size.x * 0.5 - panel_w * 0.5
	var py := 54.0
	_panel(px, py, panel_w, panel_h, 5.0)
	var pulse_alpha: float = 0.74 + 0.18 * abs(sin(_mission_prompt_pulse))
	HudRenderer.draw_mission_prompt(self, font, _fs(5), _pal_hud(), px, py, panel_w,
		pulse_alpha, _mission_prompt_text)

# ─── Sector display — top-right ───────────────────────────────────────────────

func _draw_sector_display(font: Font) -> void:
	var vp  := get_viewport_rect()
	var pw  := 74.0; var ph := 12.0
	var px: float  = vp.size.x - pw - 3.0
	var py  := 2.0
	_panel(px, py, pw, ph, 3.5)

	# "SECTOR N" subheader — replaced by "NO CARRIER" readout at high blend
	var header_text := "SECTOR %d" % GameManager.current_sector
	if VisualState.blend() > 0.85:
		header_text = "NO CARRIER"
	HudRenderer.draw_sector_display(self, font, _fs(4), _fs(5), _pal_hud(), px, py,
		header_text, GameManager.get_sector_name(), _hud_glitch())

# ─── Context hint — bottom-centre state-aware prompt ─────────────────────────

func _draw_context_hint(font: Font) -> void:
	var vp  := get_viewport_rect()
	HudRenderer.draw_context_hint(self, font, _fs(4), vp.size.x * 0.5, vp.size.y - 8.0,
		int(GameManager.current_state), GameManager.GameState)
