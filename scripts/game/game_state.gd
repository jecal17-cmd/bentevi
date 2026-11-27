extends Node
## Estado da partida (autoload "GameState").
## Toda mudança passa por aqui, é salva em disco e avisa a interface pelo sinal `changed`.

signal changed
signal message(text: String)
signal item_added(id: String)
signal sound(name: String)

const SAVE_PATH := "user://bentevi_save.json"
const MAX_PLATES := 3
const START_VIEW := "bilheteria"

## Desligado nos testes para não tocar no arquivo de salvamento real.
var save_enabled := true
var save_path := SAVE_PATH

var chapter: int = 0
var flags: Dictionary = {}
var inventory: Array[String] = []
## vista -> "taken" (fotografada) ou "developed" (revelada)
var photos: Dictionary = {}
var notes: Array[String] = []
## Índices dos mineiros cujos nomes já foram encontrados.
var names_found: Array[int] = []
var plates: int = MAX_PLATES
var view: String = START_VIEW
var era: int = 1924
var selected_item: String = ""
var hint_stage: String = ""
var hint_level: int = 0


func new_game() -> void:
	reset()
	commit()


func reset() -> void:
	chapter = 0
	flags = {}
	inventory = []
	photos = {}
	notes = []
	plates = MAX_PLATES
	view = START_VIEW
	era = 1924
	selected_item = ""
	hint_stage = ""
	hint_level = 0
	names_found = []


func commit() -> void:
	save_game()
	changed.emit()


func say(text: String) -> void:
	message.emit(text)


func play(sound_name: String) -> void:
	sound.emit(sound_name)


func is_past() -> bool:
	return era == 1899


func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func set_flag(flag: String) -> void:
	flags[flag] = true


func has_item(id: String) -> bool:
	return inventory.has(id)


func add_item(id: String, announce: bool = true) -> void:
	if not inventory.has(id):
		inventory.append(id)
		if announce:
			item_added.emit(id)


func remove_item(id: String) -> void:
	inventory.erase(id)
	if selected_item == id:
		selected_item = ""


func add_note(text: String) -> void:
	if not notes.has(text):
		notes.append(text)


func to_dict() -> Dictionary:
	return {
		"version": 2,
		"chapter": chapter,
		"flags": flags,
		"inventory": inventory,
		"photos": photos,
		"notes": notes,
		"names_found": names_found,
		"plates": plates,
		"view": view,
		"era": era,
		"hint_stage": hint_stage,
		"hint_level": hint_level,
	}


func from_dict(data: Dictionary) -> void:
	chapter = int(data.get("chapter", 0))
	flags = data.get("flags", {})
	inventory.assign(data.get("inventory", []))
	photos = data.get("photos", {})
	notes.assign(data.get("notes", []))
	names_found.clear()
	for n in data.get("names_found", []):
		names_found.append(int(n))
	plates = int(data.get("plates", MAX_PLATES))
	view = str(data.get("view", START_VIEW))
	era = int(data.get("era", 1924))
	hint_stage = str(data.get("hint_stage", ""))
	hint_level = int(data.get("hint_level", 0))
	selected_item = ""


func save_game() -> void:
	if not save_enabled:
		return
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Não foi possível salvar: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(to_dict()))


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func load_game() -> bool:
	if not has_save():
		return false
	var text := FileAccess.get_file_as_string(save_path)
	var data = JSON.parse_string(text)
	# Um arquivo corrompido não deve travar o jogo: começa do zero.
	if typeof(data) != TYPE_DICTIONARY:
		return false
	from_dict(data)
	changed.emit()
	return true
