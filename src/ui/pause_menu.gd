## PauseMenu — ESC opens pause. Resume, restart, quit.
## GDD Ref: gameplay-mechanics.md — Pause
extends CanvasLayer

const COL_BG    := Color(0.00, 0.02, 0.05, 0.82)
const COL_LABEL := Color(0.22, 1.00, 0.08)
const COL_SEL   := Color(0.00, 0.80, 1.00)
const COL_DIM   := Color(0.10, 0.30, 0.10)

var _visible_flag: bool = false
var _selection: int = 0
const ITEMS := ["RESUME", "RESTART SECTOR", "QUIT TO MENU"]
var _draw_node: Control = null

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Create a Control child to handle drawing
	_draw_node = Control.new()
	_draw_node.anchor_right  = 1.0
	_draw_node.anchor_bottom = 1.0
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_draw_node)
	_draw_node.draw.connect(_on_draw)
	hide()

func _on_draw() -> void:
	if not _visible_flag:
		return
	var vp  := _draw_node.get_viewport_rect()
	var cx  := vp.size.x * 0.5
	var cy  := vp.size.y * 0.5
	var font := ThemeDB.fallback_font
	_draw_node.draw_rect(Rect2(Vector2.ZERO, vp.size), Color(0,0,0,0.5))
	_draw_node.draw_rect(Rect2(cx - 50, cy - 32, 100, 72), COL_BG)
	_draw_node.draw_string(font, Vector2(cx - 18, cy - 22), "PAUSED",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, COL_LABEL)
	for i in ITEMS.size():
		var col := COL_SEL if i == _selection else COL_DIM
		_draw_node.draw_string(font, Vector2(cx - 36, cy - 6 + i * 14), ITEMS[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5, col)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle()

func toggle() -> void:
	_visible_flag = not _visible_flag
	if _visible_flag:
		get_tree().paused = true
		show()
		if _draw_node:
			_draw_node.queue_redraw()
	else:
		get_tree().paused = false
		hide()

func _unhandled_input(event: InputEvent) -> void:
	if not _visible_flag:
		return
	if event.is_action_just_pressed("move_up"):
		_selection = (_selection - 1 + ITEMS.size()) % ITEMS.size()
		if _draw_node: _draw_node.queue_redraw()
	elif event.is_action_just_pressed("move_down"):
		_selection = (_selection + 1) % ITEMS.size()
		if _draw_node: _draw_node.queue_redraw()
	elif event.is_action_just_pressed("ui_accept"):
		_activate()

func _activate() -> void:
	match _selection:
		0:
			toggle()
		1:
			get_tree().paused = false
			get_tree().reload_current_scene()
		2:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
