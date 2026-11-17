extends Node

const DEBUG := true

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const SILENT_DB := -80.0

const AUDIO_EXTENSIONS := [".wav", ".mp3", ".ogg"]

const MUSIC := {
	"ace": "res://assets/audio/music/A_talking_automated_computing_entity(0.2)",
	"puzzle": "res://assets/audio/music/AMPM_on_my_computer(0.2)",
	"final": "",
}

const SFX := {
	"click": "res://assets/audio/sfx/click",
	"walk": "res://assets/audio/sfx/walk",
	"glitch": "res://assets/audio/sfx/glitch",
	"crash": "res://assets/audio/sfx/crash",
}

const MUSIC_GAIN_DB := {"ace": -12.0, "puzzle": -12.0, "final": -12.0}
const SFX_GAIN_DB := {"click": -13.0, "walk": -15.0, "glitch": -10.0, "crash": -20.0}

const REPEAT_INTERVAL := {"walk": 0.4}
const REPEAT_PITCH_VARIATION := {"walk": 0.08}

var current_music := ""

var _music_a := AudioStreamPlayer.new()
var _music_b := AudioStreamPlayer.new()
var _active: AudioStreamPlayer
var _fade: Tween
var _loops := {}
var _repeating := {}
var _cache := {}
var _warned := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for player in [_music_a, _music_b]:
		player.bus = MUSIC_BUS
		add_child(player)
	_active = _music_a

	get_tree().node_added.connect(_on_node_added)

	if DEBUG:
		_print_status()


func _process(delta: float) -> void:
	if get_tree().paused:
		return

	for key in _repeating:
		_repeating[key] -= delta
		if _repeating[key] <= 0.0:
			_repeating[key] = REPEAT_INTERVAL[key]
			play_sfx(key, 0.0, REPEAT_PITCH_VARIATION.get(key, 0.0))


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if DEBUG and key_event and key_event.pressed and key_event.keycode == KEY_F9:
		print("AudioManager: F9 test")
		play_sfx("click")
		play_music("ace", 0.0)


func _print_status() -> void:
	print("AudioManager ready")
	for bus_name in ["Master", "Music", "SFX"]:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx == -1:
			push_warning("AudioManager: there is no audio bus named '%s'" % bus_name)
		else:
			print("  bus %s: %.1f dB, muted: %s" % [bus_name, AudioServer.get_bus_volume_db(idx), AudioServer.is_bus_mute(idx)])
	for key in MUSIC:
		_check_path("music", key, MUSIC[key])
	for key in SFX:
		_check_path("sfx", key, SFX[key])


func _check_path(kind: String, key: String, base_path: String) -> void:
	if base_path.is_empty():
		print("  %s '%s': no file set" % [kind, key])
		return
	var path := _resolve_path(base_path)
	if path.is_empty():
		push_warning("AudioManager: %s '%s' has no usable file (%s with .wav, .mp3 or .ogg)" % [kind, key, base_path])
	else:
		print("  %s '%s': %s" % [kind, key, path.get_file()])


func play_music(key: String, fade_time: float = 1.0) -> void:
	var stream := _load_stream(MUSIC.get(key, ""))
	if stream == null and key == "final":
		key = "puzzle"
		stream = _load_stream(MUSIC.get(key, ""))

	if stream == null:
		stop_music(fade_time)
		return
	if key == current_music and _active.playing:
		return

	if DEBUG:
		print("AudioManager: music -> ", key)
	current_music = key
	_set_loop(stream, true)

	var target_db: float = MUSIC_GAIN_DB.get(key, 0.0)

	var previous := _active
	var next := _music_b if _active == _music_a else _music_a
	next.stream = stream
	next.volume_db = SILENT_DB if fade_time > 0.0 else target_db
	next.play()
	_active = next

	_kill_fade()
	if fade_time <= 0.0:
		previous.stop()
		return

	_fade = create_tween().set_parallel(true)
	_fade.tween_property(next, "volume_db", target_db, fade_time)
	if previous.playing:
		_fade.tween_property(previous, "volume_db", SILENT_DB, fade_time)
		_fade.chain().tween_callback(previous.stop)


func stop_music(fade_time: float = 1.0) -> void:
	current_music = ""
	_kill_fade()

	var other := _music_b if _active == _music_a else _music_a
	other.stop()

	if not _active.playing:
		return
	if fade_time <= 0.0:
		_active.stop()
		return

	_fade = create_tween()
	_fade.tween_property(_active, "volume_db", SILENT_DB, fade_time)
	_fade.tween_callback(_active.stop)


func _kill_fade() -> void:
	if _fade and _fade.is_valid():
		_fade.kill()


func play_sfx(key: String, volume_db: float = 0.0, pitch_variation: float = 0.0) -> void:
	var stream := _load_stream(SFX.get(key, ""))
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.bus = SFX_BUS
	player.stream = stream
	player.volume_db = SFX_GAIN_DB.get(key, 0.0) + volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func start_loop(key: String, volume_db: float = 0.0) -> void:
	if _loops.has(key) or _repeating.has(key):
		return

	if REPEAT_INTERVAL.has(key):
		_repeating[key] = 0.0
		return

	var stream := _load_stream(SFX.get(key, ""))
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	player.bus = SFX_BUS
	player.stream = stream
	player.volume_db = SFX_GAIN_DB.get(key, 0.0) + volume_db
	add_child(player)
	player.finished.connect(_on_loop_finished.bind(key))
	_loops[key] = player
	player.play()


func stop_loop(key: String) -> void:
	_repeating.erase(key)

	if not _loops.has(key):
		return
	var player: AudioStreamPlayer = _loops[key]
	_loops.erase(key)
	player.queue_free()


func _on_loop_finished(key: String) -> void:
	if _loops.has(key):
		_loops[key].play()


func _resolve_path(base_path: String) -> String:
	for extension in AUDIO_EXTENSIONS:
		var path: String = base_path + extension
		if not ResourceLoader.exists(path):
			continue
		if not _import_is_valid(path):
			var real := _real_format(path)
			if real == extension.trim_prefix("."):
				_warn_once(path, "%s could not be imported (the file may be damaged)" % path.get_file())
			else:
				_warn_once(path, "%s could not be imported. Its data looks like %s: rename it to .%s" % [path.get_file(), real.to_upper(), real])
			continue
		return path
	return ""


func _load_stream(base_path: String) -> AudioStream:
	if base_path.is_empty():
		return null
	if _cache.has(base_path):
		return _cache[base_path]

	var path := _resolve_path(base_path)
	if path.is_empty():
		_warn_once(base_path, "no usable audio file for %s" % base_path)
		return null

	var stream := load(path) as AudioStream
	if stream == null:
		_warn_once(base_path, "%s could not be loaded" % path)
		return null

	_cache[base_path] = stream
	return stream


func _import_is_valid(path: String) -> bool:
	var import_path := path + ".import"
	if not FileAccess.file_exists(import_path):
		return true
	var file := FileAccess.open(import_path, FileAccess.READ)
	return file != null and not file.get_as_text().contains("valid=false")


func _real_format(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "unknown"
	var head := file.get_buffer(4)
	if head.size() < 4:
		return "unknown"
	if head[0] == 0x52 and head[1] == 0x49 and head[2] == 0x46 and head[3] == 0x46:
		return "wav"
	if head[0] == 0x4F and head[1] == 0x67 and head[2] == 0x67 and head[3] == 0x53:
		return "ogg"
	if (head[0] == 0x49 and head[1] == 0x44 and head[2] == 0x33) \
			or (head[0] == 0xFF and (head[1] & 0xE0) == 0xE0):
		return "mp3"
	return "unknown"


func _warn_once(key: String, message: String) -> void:
	if DEBUG and not _warned.has(key):
		_warned[key] = true
		push_warning("AudioManager: " + message)


func _set_loop(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = enabled
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = enabled
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if enabled:
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			wav.loop_mode = AudioStreamWAV.LOOP_DISABLED


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button and not button.pressed.is_connected(_play_click):
		button.pressed.connect(_play_click)


func _play_click() -> void:
	play_sfx("click")
