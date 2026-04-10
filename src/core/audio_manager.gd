## AudioManager — Handles all music and SFX playback.
## Autoloaded singleton.
extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
const MUSIC_FADE_TIME := 1.5
const SFX_POOL_SIZE := 16

# ─── Node refs (assigned in _ready) ──────────────────────────────────────────
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []

# ─── State ───────────────────────────────────────────────────────────────────
var _current_track: String = ""
var _music_volume: float = 0.8
var _sfx_volume: float = 1.0
var _mothership_phase: int = 0

# Tween for crossfade
var _fade_tween: Tween = null

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Music players
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = "Music"
	_music_player_a.volume_db = linear_to_db(_music_volume)
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = "Music"
	_music_player_b.volume_db = -80.0
	add_child(_music_player_b)

	_active_music = _music_player_a

	# SFX pool
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = linear_to_db(_sfx_volume)
		add_child(player)
		_sfx_pool.append(player)

# ─── Music ───────────────────────────────────────────────────────────────────
func play_music(track_name: String, fade: bool = true) -> void:
	if _current_track == track_name:
		return
	_current_track = track_name

	var path := "res://assets/audio/music/%s.ogg" % track_name
	if not ResourceLoader.exists(path):
		# No audio file yet — stub silently
		return

	var stream := load(path) as AudioStream
	if stream == null:
		return

	var inactive := _music_player_b if _active_music == _music_player_a else _music_player_a
	inactive.stream = stream
	inactive.play()

	if fade:
		_crossfade_to(inactive)
	else:
		_active_music.stop()
		inactive.volume_db = linear_to_db(_music_volume)
		_active_music = inactive

func _crossfade_to(target: AudioStreamPlayer) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	var old := _active_music
	_fade_tween.tween_property(old, "volume_db", -80.0, MUSIC_FADE_TIME)
	_fade_tween.parallel().tween_property(target, "volume_db", linear_to_db(_music_volume), MUSIC_FADE_TIME)
	_active_music = target

func stop_music(fade: bool = true) -> void:
	_current_track = ""
	if fade:
		if _fade_tween:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_active_music, "volume_db", -80.0, MUSIC_FADE_TIME)
	else:
		_active_music.stop()

func set_mothership_phase(phase: int) -> void:
	if _mothership_phase == phase:
		return
	_mothership_phase = phase
	match phase:
		1: play_music("mothership_phase1")
		2: play_music("mothership_phase2")
		3: play_music("mothership_phase3")

func play_sector_music(sector: int) -> void:
	match sector:
		1: play_music("inner_rim")
		2: play_music("asteroid_fields")
		3: play_music("nebula_crossing")
		4: play_music("alien_territory")
		5: play_music("the_frontier")

func play_music_for_state(state: GameManager.GameState) -> void:
	match state:
		GameManager.GameState.MENU: play_music("mission_log")
		GameManager.GameState.ALIEN_COMBAT: play_music("alien_combat")
		GameManager.GameState.WIN: play_music("golden_shore")
		GameManager.GameState.DEATH: stop_music()

# ─── SFX ─────────────────────────────────────────────────────────────────────
func play_sfx(sound_name: String, volume_scale: float = 1.0) -> void:
	var path := "res://assets/audio/sfx/%s.wav" % sound_name
	if not ResourceLoader.exists(path):
		# Try OGG
		path = "res://assets/audio/sfx/%s.ogg" % sound_name
		if not ResourceLoader.exists(path):
			return

	var stream := load(path) as AudioStream
	if stream == null:
		return

	var player := _get_free_sfx_player()
	if player == null:
		return
	player.volume_db = linear_to_db(_sfx_volume * volume_scale)
	player.stream = stream
	player.play()

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	# All busy — reuse oldest (first)
	return _sfx_pool[0]

# ─── Volume ───────────────────────────────────────────────────────────────────
func set_music_volume(vol: float) -> void:
	_music_volume = clampf(vol, 0.0, 1.0)
	_active_music.volume_db = linear_to_db(_music_volume)

func set_sfx_volume(vol: float) -> void:
	_sfx_volume = clampf(vol, 0.0, 1.0)
