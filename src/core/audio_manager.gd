## AudioManager — Handles all music and SFX playback.
## Autoloaded singleton.
extends Node

# ─── Constants ───────────────────────────────────────────────────────────────
const MUSIC_FADE_TIME := 1.5
const LEVEL_MUSIC_ROTATION_TIME := 120.0
const SFX_POOL_SIZE := 16
const LEVEL_MUSIC_ROTATION_TRACKS := [
	"inner_rim",
	"asteroid_fields",
	"nebula_crossing",
	"alien_territory",
	"the_frontier",
]

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
var _audio_enabled: bool = true
var _level_music_active: bool = false
var _level_music_timer: float = 0.0
var _level_music_index: int = 0

# Tween for crossfade
var _fade_tween: Tween = null

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_audio_enabled = DisplayServer.get_name() != "headless"
	if not _audio_enabled:
		return

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

func _process(delta: float) -> void:
	if not _level_music_active:
		return
	if not _is_level_music_state():
		return
	_restart_current_level_track_if_needed()
	_level_music_timer += delta
	if _level_music_timer < LEVEL_MUSIC_ROTATION_TIME:
		return
	_level_music_timer = 0.0
	_level_music_index = (_level_music_index + 1) % LEVEL_MUSIC_ROTATION_TRACKS.size()
	_play_music_track(LEVEL_MUSIC_ROTATION_TRACKS[_level_music_index])

func _exit_tree() -> void:
	_cleanup_audio_streams()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_cleanup_audio_streams()

func _cleanup_audio_streams() -> void:
	if _fade_tween:
		_fade_tween.kill()
		_fade_tween = null
	_stop_and_clear_player(_music_player_a)
	_stop_and_clear_player(_music_player_b)
	for player in _sfx_pool:
		_stop_and_clear_player(player)
	_current_track = ""
	_level_music_active = false
	_level_music_timer = 0.0

func _stop_and_clear_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return
	player.stop()
	player.stream = null
	player.volume_db = -80.0

# ─── Music ───────────────────────────────────────────────────────────────────
func _is_level_music_state() -> bool:
	return GameManager.current_state in [
		GameManager.GameState.TRAVEL,
		GameManager.GameState.STAR_CLUSTER,
		GameManager.GameState.SCANNING,
	]

func _restart_current_level_track_if_needed() -> void:
	if not _audio_enabled:
		return
	if _current_track.is_empty():
		return
	if not is_instance_valid(_active_music):
		return
	if _active_music.stream == null:
		return
	if not _active_music.playing:
		_active_music.play()

func play_music(track_name: String, fade: bool = true) -> void:
	_level_music_active = false
	_play_music_track(track_name, fade)

func _play_music_track(track_name: String, fade: bool = true) -> void:
	if not _audio_enabled:
		_current_track = track_name
		return
	if _current_track == track_name:
		return
	_current_track = track_name

	var path := "res://assets/audio/music/%s.ogg" % track_name
	if not ResourceLoader.exists(path):
		path = "res://assets/audio/music/%s.wav" % track_name
		if not ResourceLoader.exists(path):
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
	var old := _active_music
	_fade_tween = create_tween()
	_fade_tween.tween_property(old, "volume_db", -80.0, MUSIC_FADE_TIME)
	_fade_tween.parallel().tween_property(target, "volume_db", linear_to_db(_music_volume), MUSIC_FADE_TIME)
	_fade_tween.finished.connect(func() -> void:
		if is_instance_valid(old) and old != _active_music:
			old.stop()
			old.stream = null
		_fade_tween = null
	)
	_active_music = target

func stop_music(fade: bool = true) -> void:
	_level_music_active = false
	_level_music_timer = 0.0
	if not _audio_enabled:
		return
	_current_track = ""
	if fade:
		if _fade_tween:
			_fade_tween.kill()
		var player := _active_music
		_fade_tween = create_tween()
		_fade_tween.tween_property(player, "volume_db", -80.0, MUSIC_FADE_TIME)
		_fade_tween.finished.connect(func() -> void:
			_stop_and_clear_player(player)
			_fade_tween = null
		)
	else:
		_stop_and_clear_player(_active_music)

func set_mothership_phase(phase: int) -> void:
	if _mothership_phase == phase:
		return
	_mothership_phase = phase
	match phase:
		1: play_music("mothership_phase1")
		2: play_music("mothership_phase2")
		3: play_music("mothership_phase3")

func play_sector_music(sector: int) -> void:
	_level_music_active = true
	_level_music_timer = 0.0
	_level_music_index = clampi(sector - 1, 0, LEVEL_MUSIC_ROTATION_TRACKS.size() - 1)
	_play_music_track(LEVEL_MUSIC_ROTATION_TRACKS[_level_music_index])

func play_music_for_state(state: GameManager.GameState) -> void:
	match state:
		GameManager.GameState.MENU: play_music("mission_log")
		GameManager.GameState.ALIEN_COMBAT: play_music("alien_combat")
		GameManager.GameState.WIN: play_music("golden_shore")
		GameManager.GameState.DEATH: stop_music()

# ─── SFX ─────────────────────────────────────────────────────────────────────
## Play a one-shot SFX. Pitch is randomized ±6% by default so repeated samples
## never machine-gun identically; pass an explicit pitch to override (e.g. the
## sector-5 detuned scan chime — dark-directive.md §4.2 "imperfect familiarity").
func play_sfx(sound_name: String, volume_scale: float = 1.0, pitch: float = 0.0) -> void:
	if not _audio_enabled:
		return
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
	player.pitch_scale = pitch if pitch > 0.0 else randf_range(0.94, 1.06)
	player.stream = stream
	player.play()

## Duck the music bed for a few seconds — silence as a warning sign.
## Used before elite contact and when The Silence acquires the player.
func duck_music(duration: float = 3.0, depth_db: float = -26.0) -> void:
	if not _audio_enabled or not is_instance_valid(_active_music):
		return
	var player := _active_music
	var tween := create_tween()
	tween.tween_property(player, "volume_db", linear_to_db(_music_volume) + depth_db, 0.35)
	tween.tween_interval(maxf(duration - 0.35 - 1.2, 0.1))
	tween.tween_property(player, "volume_db", linear_to_db(_music_volume), 1.2)

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player
	# All busy — reuse oldest (first)
	return _sfx_pool[0]

# ─── Volume ───────────────────────────────────────────────────────────────────
func set_music_volume(vol: float) -> void:
	_music_volume = clampf(vol, 0.0, 1.0)
	if _audio_enabled and is_instance_valid(_active_music):
		_active_music.volume_db = linear_to_db(_music_volume)

func set_sfx_volume(vol: float) -> void:
	_sfx_volume = clampf(vol, 0.0, 1.0)
