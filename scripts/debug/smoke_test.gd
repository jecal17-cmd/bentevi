extends RefCounted
## Joga o prólogo e o Capítulo 1 inteiros pela interface, sem tela:
##   godot --headless -- --smoke [--shots=/pasta/para/capturas]
## Imprime "SMOKE OK" e sai com código 0, ou lista as falhas e sai com 1.

const LockPanel := preload("res://scripts/ui/panels/lock_panel.gd")
const DarkroomPanel := preload("res://scripts/ui/panels/darkroom_panel.gd")
const ListPanel := preload("res://scripts/ui/panels/list_panel.gd")
const ZoomPanel := preload("res://scripts/ui/panels/zoom_panel.gd")
const ItemPanel := preload("res://scripts/ui/panels/item_panel.gd")
const ClockSetPanel := preload("res://scripts/ui/panels/clock_set_panel.gd")
const StoryPanel := preload("res://scripts/ui/panels/story_panel.gd")
const TitleScreen := preload("res://scripts/ui/panels/title_screen.gd")
const MenuPanel := preload("res://scripts/ui/panels/menu_panel.gd")
const SettingsPanel := preload("res://scripts/ui/panels/settings_panel.gd")

static var failures: Array[String] = []
static var shots_dir := ""
static var tree: SceneTree


static func run(main: Node) -> void:
	tree = main.get_tree()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
	GameState.save_enabled = false
	Settings.save_enabled = false
	Settings.unlocked_chapter = 0

	main.menus.show_title()
	await _frames()
	_expect(_find(main, TitleScreen) != null, "menu principal aparece")
	await _shot(main, "00_menu")
	_find(main, TitleScreen).chosen.emit("settings")
	await _frames()
	_expect(_find(main, SettingsPanel) != null, "configurações abrem")
	await _shot(main, "01_configuracoes")
	_find(main, SettingsPanel).closed.emit()
	await _frames()
	_find(main, TitleScreen).chosen.emit("new")
	await _frames()
	_expect(GameState.view == "bilheteria", "novo jogo começa na bilheteria")
	_expect(Audio.current_bed() == "amb_1924", "ambiente de 1924 toca")

	await _prologue(main)
	await _chapter1(main)

	main.on_back(false)
	await _frames()
	if failures.is_empty():
		print("SMOKE OK")
		tree.quit(0)
	else:
		for f in failures:
			printerr("FALHOU: " + f)
		tree.quit(1)


static func _prologue(main: Node) -> void:
	main.right_button.pressed.emit()
	await _frames()
	main.on_hotspot("relogio")
	await _frames()
	_expect(_find(main, ZoomPanel) != null, "relógio abre o zoom")
	_find(main, ZoomPanel).closed.emit()
	main.left_button.pressed.emit()
	await _frames()
	await _shot(main, "02_bilheteria_1924")
	main.on_hotspot("mala")
	await _frames()
	var lock = _find(main, LockPanel)
	_expect(lock != null and lock.digit_count == 3, "mala abre cadeado de 3 dígitos")
	lock.submitted.emit("317")
	await _frames()
	_expect(main.modal_kind == "item", "câmera aparece na tela de item novo")
	await _shot(main, "03_item_novo")
	await _dismiss_items(main)

	main.photo_button.pressed.emit()
	main.right_button.pressed.emit()
	main.photo_button.pressed.emit()
	await _frames()
	main.on_back(false)
	await _frames()
	_expect(main.modal_kind == "pause", "voltar abre a pausa")
	await _shot(main, "04_pausa")
	_find(main, MenuPanel).chosen.emit("resume")
	await _develop_and_enter(main, "estacao")
	main.on_hotspot("banco")
	await _frames()
	_expect(main.modal_kind == "item", "bilhete aparece na tela de item")
	_find(main, ItemPanel)._toggle_back()
	await _frames()
	await _shot(main, "05_documento_verso")
	await _dismiss_items(main)
	main.on_hotspot("nome_portinha")
	await _frames()
	_expect(main.modal_kind == "name", "nome escondido abre a tela de nome")
	await _shot(main, "06_nome")
	_find(main, ItemPanel).closed.emit()
	main.leave_button.pressed.emit()
	await _frames()

	await _develop_and_enter(main, "bilheteria")
	main.on_hotspot("gaveta")
	await _dismiss_items(main)
	main.leave_button.pressed.emit()
	await _frames()
	main.inventory_bar.item_pressed.emit("chave")
	await _frames()
	await _shot(main, "07_item_selecionado")
	main.on_hotspot("gaveta")
	await _frames()
	await _dismiss_items(main)
	_expect(main.modal_kind == "chapter_end", "fim do prólogo")
	await _shot(main, "08_fim_prologo")
	_find(main, StoryPanel).chosen.emit("next")
	await _frames()
	_expect(GameState.chapter == 1 and GameState.view == "salao", "segue para o capítulo 1")
	_expect(Settings.unlocked_chapter >= 1, "capítulo 1 liberado no menu")


static func _chapter1(main: Node) -> void:
	await _shot(main, "10_salao_escuro")
	main.on_hotspot("coroa")
	await _frames()
	var zoom = _find(main, ZoomPanel)
	_expect(zoom != null and zoom.params.has("action"), "coroa com medalha")
	await _shot(main, "11_coroa")
	zoom.action.emit("pegar_medalha")
	await _frames()
	await _dismiss_items(main)

	main.right_button.pressed.emit()
	await _frames()
	_expect(GameState.view == "relogios", "seta leva à parede dos relógios")
	main.on_hotspot("parede")
	await _frames()
	await _shot(main, "12_quatro_relogios")
	_find(main, ZoomPanel).closed.emit()
	main.on_hotspot("gaveta_cima")
	await _frames()
	await _dismiss_items(main)
	main.left_button.pressed.emit()
	await _frames()
	main.inventory_bar.item_pressed.emit("fosforos")
	main.on_hotspot("castical")
	await _frames()
	_expect(GameState.has_flag("velas_acesas"), "acende as velas")
	await _shot(main, "13_salao_aceso")
	main.photo_button.pressed.emit()

	main.left_button.pressed.emit()
	await _frames()
	_expect(GameState.view == "espelho", "seta esquerda leva ao espelho")
	main.on_hotspot("bilhete_ester")
	await _frames()
	await _dismiss_items(main)
	main.photo_button.pressed.emit()
	await _develop_and_enter(main, "espelho")
	main.on_hotspot("espelho")
	await _frames()
	await _shot(main, "14_reflexo")
	_find(main, ZoomPanel).closed.emit()
	main.leave_button.pressed.emit()
	await _frames()

	main.left_button.pressed.emit()
	await _frames()
	main.on_hotspot("gaveta_meio")
	await _frames()
	var lock = _find(main, LockPanel)
	_expect(lock != null and lock.digit_count == 4, "cômoda tem cadeado de 4 dígitos")
	lock.submitted.emit("1408")
	await _frames()
	await _dismiss_items(main)
	_expect(GameState.has_item("atestado"), "cômoda dá o atestado")
	_expect(main.inventory_bar.get_child_count() >= GameState.inventory.size(), "todos os itens cabem na barra")

	main.photo_button.pressed.emit()
	await _develop_and_enter(main, "relogios")
	main.on_hotspot("pendulo")
	await _frames()
	await _dismiss_items(main)
	main.on_hotspot("gaveta_baixo")
	await _frames()
	_expect(main.modal_kind == "name" and GameState.names_found.has(14), "recibo com o nome do pai")
	_find(main, ItemPanel).closed.emit()
	main.leave_button.pressed.emit()
	await _frames()

	main.inventory_bar.item_pressed.emit("chave_corda")
	main.on_hotspot("pendulo")
	await _frames()
	var clock = _find(main, ClockSetPanel)
	_expect(clock != null, "chave de corda abre o acerto de ponteiros")
	clock._change(-1, 0)
	for i in 5:
		clock._change(0, 5)
	await _frames()
	await _shot(main, "15_ponteiros")
	clock.submitted.emit(clock.hour, clock.minute)
	await _frames()
	_expect(GameState.has_item("medalha_sol"), "2h40 dá a medalha do sol")
	await _dismiss_items(main)

	main.right_button.pressed.emit()
	main.right_button.pressed.emit()
	await _frames()
	_expect(GameState.view == "salao", "volta ao salão")
	main.on_hotspot("caixao")
	await _frames()
	await _shot(main, "16_caixao")
	_find(main, ZoomPanel).closed.emit()
	for medal in ["medalha_torre", "medalha_muleta", "medalha_sol"]:
		main.inventory_bar.item_pressed.emit(medal)
		main.on_hotspot("caixao")
		await _frames()
	await _dismiss_items(main)
	_expect(main.modal_kind == "chapter_end", "fim do capítulo 1")
	await _shot(main, "17_fim_capitulo1")
	main.open_notebook()
	await _frames()
	await _shot(main, "18_caderno")


static func _develop_and_enter(main: Node, view: String) -> void:
	main.album_button.pressed.emit()
	await _frames()
	_find(main, ListPanel).action.emit(view, "develop")
	await _frames()
	var darkroom = _find(main, DarkroomPanel)
	_expect(darkroom != null, "câmara escura (%s)" % view)
	darkroom.progress = 0.65
	darkroom._update_visuals()
	await _frames()
	if view == "espelho":
		await _shot(main, "09_camara_escura")
	darkroom.pull()
	await tree.create_timer(1.2).timeout
	await _frames()
	_expect(GameState.photos[view] == "developed", "revela %s" % view)
	_find(main, ListPanel).action.emit(view, "enter")
	await _frames()
	_expect(GameState.era == 1899 and GameState.view == view, "entra na foto (%s)" % view)


static func _dismiss_items(main: Node) -> void:
	for i in 6:
		await _frames()
		if main.modal_kind != "item":
			return
		_find(main, ItemPanel).closed.emit()


static func _frames() -> void:
	await tree.process_frame
	await tree.process_frame


static func _find(root: Node, script: Script) -> Node:
	for child in root.get_children():
		if child.is_queued_for_deletion():
			continue
		if child.get_script() == script:
			return child
		var found := _find(child, script)
		if found != null:
			return found
	return null


static func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


static func _shot(main: Node, name: String) -> void:
	if shots_dir == "":
		return
	await tree.process_frame
	var image := main.get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [shots_dir, name])
