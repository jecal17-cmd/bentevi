extends RefCounted
## Menus: principal, pausa, configurações, capítulos, créditos e fim de capítulo.

const Content := preload("res://scripts/game/content.gd")
const Logic := preload("res://scripts/game/logic.gd")
const TitleScreen := preload("res://scripts/ui/panels/title_screen.gd")
const MenuPanel := preload("res://scripts/ui/panels/menu_panel.gd")
const SettingsPanel := preload("res://scripts/ui/panels/settings_panel.gd")
const ListPanel := preload("res://scripts/ui/panels/list_panel.gd")
const StoryPanel := preload("res://scripts/ui/panels/story_panel.gd")

var main


func _init(owner) -> void:
	main = owner


func show_title() -> void:
	main.close_modal()
	main.modal_kind = "title"
	var screen := TitleScreen.new()
	var where := ""
	if GameState.has_save():
		var data_chapter := _saved_chapter()
		where = Content.chapter_title(data_chapter).split(" — ")[0]
	screen.setup(GameState.has_save(), where)
	screen.chosen.connect(_on_title_choice)
	main.modal_layer.add_child(screen)
	Audio.bed("music_menu")


func _saved_chapter() -> int:
	# Lê só o capítulo do arquivo, sem carregar a partida.
	var data = JSON.parse_string(FileAccess.get_file_as_string(GameState.save_path))
	if typeof(data) == TYPE_DICTIONARY:
		return int(data.get("chapter", 0))
	return 0


func _on_title_choice(id: String) -> void:
	GameState.play("click")
	match id:
		"continue":
			continue_game()
		"new":
			_confirm_overwrite(0, true)
		"chapters":
			show_chapters(true)
		"settings":
			show_settings(true)
		"credits":
			show_credits()
		"quit":
			main.get_tree().quit()


## Começar um capítulo apaga a partida salva; pergunta antes se há algo a perder.
func _confirm_overwrite(chapter: int, from_title: bool) -> void:
	if not GameState.has_save():
		start_chapter_fresh(chapter)
		return
	var panel := MenuPanel.new()
	var where := Content.chapter_title(_saved_chapter()).split(" — ")[0]
	panel.setup("Começar de novo?", [["Sim, apagar o jogo salvo", "yes"], ["Voltar", "no"]],
		"O jogo salvo (%s) será substituído." % where)
	panel.chosen.connect(func(choice: String):
		GameState.play("click")
		if choice == "yes":
			start_chapter_fresh(chapter)
		elif from_title:
			show_title()
		else:
			show_pause())
	main.open_modal(panel, "confirm", from_title)


func show_pause() -> void:
	var panel := MenuPanel.new()
	panel.setup("Pausa", [["Continuar", "resume"], ["Caderno", "notebook"], ["Configurações", "settings"], ["Menu principal", "title"]])
	panel.chosen.connect(_on_pause_choice)
	main.open_modal(panel, "pause")


func _on_pause_choice(id: String) -> void:
	GameState.play("click")
	match id:
		"resume":
			main.close_modal()
		"notebook":
			main.open_notebook()
		"settings":
			show_settings(false)
		"title":
			show_title()


func show_settings(from_title: bool) -> void:
	var panel := SettingsPanel.new()
	panel.closed.connect(func():
		if from_title:
			show_title()
		else:
			show_pause())
	panel.erase_requested.connect(func():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.save_path))
		Settings.set_value("unlocked_chapter", 0)
		GameState.reset()
		show_title())
	main.open_modal(panel, "settings", from_title)


func show_chapters(from_title: bool) -> void:
	var rows: Array = []
	for chapter in Content.CHAPTERS:
		var playable: bool = chapter <= Content.LAST_PLAYABLE_CHAPTER
		var unlocked: bool = chapter <= Settings.unlocked_chapter
		var label := "Jogar" if playable and unlocked else ("Em breve" if not playable else "Bloqueado")
		var text := Content.chapter_title(chapter)
		if playable and not unlocked:
			text += " · termine o capítulo anterior"
		rows.append({"text": text, "action": label, "id": str(chapter), "kind": "play", "disabled": not (playable and unlocked)})
	var panel := ListPanel.new()
	panel.setup("Capítulos", rows)
	panel.closed.connect(func():
		if from_title:
			show_title()
		else:
			main.close_modal())
	panel.action.connect(func(id, _kind): _confirm_overwrite(int(id), from_title))
	main.open_modal(panel, "chapters", from_title)


func show_credits() -> void:
	var rows: Array = []
	for line in Content.CREDITS:
		rows.append({"text": line})
	var panel := ListPanel.new()
	panel.setup("Créditos", rows)
	panel.closed.connect(show_title)
	main.open_modal(panel, "credits", true)


func continue_game() -> void:
	main.close_modal()
	if not GameState.load_game():
		start_chapter_fresh(0)
		return
	GameState.say("De volta a %s." % Content.view_title(GameState.view).to_lower())
	main.check_chapter_end()


func start_chapter_fresh(chapter: int) -> void:
	main.close_modal()
	main.item_queue.clear()
	GameState.reset()
	if chapter == 0:
		GameState.commit()
		GameState.say("Uma estação vazia. Minha mala. Lá fora, um pássaro insiste: bem-te-vi.")
	else:
		Logic.start_chapter(GameState, chapter)


func show_chapter_end() -> void:
	var names := GameState.names_found.size()
	var panel := StoryPanel.new()
	if GameState.chapter == 0:
		Settings.unlock(1)
		panel.setup([
			"Um apito corta a noite. Uma carruagem para diante da estação.",
			"O cocheiro tira o chapéu, sem surpresa nenhuma:",
			"— Dona Lúcia. Faz vinte e cinco anos que esperamos a senhora.",
			"No alto do relógio parado, o bem-te-vi canta uma vez.",
		], "Fim do prólogo", "Nomes dos mineiros encontrados: %d de 31." % names,
			[["Menu", "title"], ["Seguir para o casarão", "next"]], "carruagem")
		GameState.play("whistle")
	else:
		Settings.unlock(2)
		panel.setup([
			"O fecho cede. A tampa range.",
			"Dentro, o coronel de terno preto. Da boca entreaberta escorre terra escura — terra da mina.",
			"No meio dela, brilha uma pepita de ouro.",
			"Atrás de mim, a voz de Dona Ester:",
			"— Agora a senhora sabe por que todos os relógios param às 3h17.",
		], "Fim do Capítulo 1", "Capítulo 2 — A Botica: em breve. Nomes dos mineiros encontrados: %d de 31." % names,
			[["Menu", "title"], ["Jogar o capítulo de novo", "replay"]])
	panel.chosen.connect(_on_chapter_end_choice)
	main.open_modal(panel, "chapter_end")
	Audio.bed("music_menu")


func _on_chapter_end_choice(id: String) -> void:
	GameState.play("click")
	match id:
		"title":
			show_title()
		"next":
			main.close_modal()
			Logic.start_chapter(GameState, 1)
		"replay":
			start_chapter_fresh(1)
