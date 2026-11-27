extends Node
## Som do jogo (autoload "Audio"): efeitos, ambiente por época e música do menu.
## Música e ambiente usam o barramento "Music"; efeitos, o "SFX".

const FOLDER := "res://assets/audio/"
const SFX_VOICES := 6
const FADE := 1.2
const SILENT_DB := -40.0

var _bed: AudioStreamPlayer
var _bed_name := ""
var _voices: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_bed = AudioStreamPlayer.new()
	_bed.bus = "Music"
	add_child(_bed)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)
	Settings.changed.connect(apply_volumes)
	apply_volumes()


func apply_volumes() -> void:
	_set_bus_volume("Music", Settings.music_volume)
	_set_bus_volume("SFX", Settings.sfx_volume)


func sfx(name: String) -> void:
	var stream := _load(name)
	if stream == null:
		return
	for p in _voices:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	# Todas ocupadas: reaproveita a primeira em vez de perder o som novo.
	_voices[0].stream = stream
	_voices[0].play()


## Troca o som de fundo (ambiente ou música) com fade. Nome vazio = silêncio.
func bed(name: String) -> void:
	if name == _bed_name:
		return
	_bed_name = name
	var tween := create_tween()
	if _bed.playing:
		tween.tween_property(_bed, "volume_db", SILENT_DB, FADE * 0.5)
	tween.tween_callback(_start_bed.bind(name))
	tween.tween_property(_bed, "volume_db", 0.0, FADE)


func current_bed() -> String:
	return _bed_name


func _start_bed(name: String) -> void:
	_bed.stop()
	if name == "":
		return
	var stream := _load(name)
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = true
	_bed.stream = stream
	_bed.volume_db = SILENT_DB
	_bed.play()


func _load(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var path := FOLDER + name + ".ogg"
	var stream: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_cache[name] = stream
	return stream


func _ensure_bus(name: String) -> void:
	if AudioServer.get_bus_index(name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, name)
	AudioServer.set_bus_send(index, "Master")


func _set_bus_volume(name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(name)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, linear <= 0.001)
