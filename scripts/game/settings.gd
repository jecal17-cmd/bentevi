extends Node
## Preferências do jogador e progresso de perfil (autoload "Settings").
## Ficam em arquivo separado do salvamento da partida, para sobreviver a "Novo jogo".

signal changed

const PATH := "user://settings.cfg"

var music_volume := 0.7
var sfx_volume := 0.9
var large_text := false
var show_hotspots := false
## Maior capítulo liberado no menu "Capítulos" (0 = prólogo).
var unlocked_chapter := 0
var save_enabled := true


func _ready() -> void:
	load_settings()


func set_value(key: String, value) -> void:
	set(key, value)
	save_settings()
	changed.emit()


func unlock(chapter: int) -> void:
	if chapter > unlocked_chapter:
		set_value("unlocked_chapter", chapter)


func save_settings() -> void:
	if not save_enabled:
		return
	var cfg := ConfigFile.new()
	for key in ["music_volume", "sfx_volume", "large_text", "show_hotspots", "unlocked_chapter"]:
		cfg.set_value("jogo", key, get(key))
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	music_volume = cfg.get_value("jogo", "music_volume", music_volume)
	sfx_volume = cfg.get_value("jogo", "sfx_volume", sfx_volume)
	large_text = cfg.get_value("jogo", "large_text", large_text)
	show_hotspots = cfg.get_value("jogo", "show_hotspots", show_hotspots)
	unlocked_chapter = cfg.get_value("jogo", "unlocked_chapter", unlocked_chapter)
