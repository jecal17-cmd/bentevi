extends RefCounted
## Joga o prólogo inteiro pela interface, sem tela:
##   godot --headless -- --smoke
## Imprime "SMOKE OK" e sai com código 0, ou lista as falhas e sai com 1.

const LockPanel := preload("res://scripts/ui/panels/lock_panel.gd")
const DarkroomPanel := preload("res://scripts/ui/panels/darkroom_panel.gd")
const ListPanel := preload("res://scripts/ui/panels/list_panel.gd")
const ZoomPanel := preload("res://scripts/ui/panels/zoom_panel.gd")
const EndingPanel := preload("res://scripts/ui/panels/ending_panel.gd")

static var failures: Array[String] = []
static var shots_dir := ""


static func run(main: Node) -> void:
	var tree := main.get_tree()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.trim_prefix("--shots=")
	GameState.save_enabled = false
	main.show_title()
	await _frames(tree)
	_shot(main, "00_titulo")
	main.start_new_game()
	await _frames(tree)
	_expect(GameState.view == "bilheteria" and GameState.era == 1924, "começa na bilheteria em 1924")
	_expect(main.hotspot_layer.get_child_count() == 5, "bilheteria tem 5 pontos clicáveis")
	_shot(main, "01_bilheteria_1924")

	main.right_button.pressed.emit()
	await _frames(tree)
	_expect(GameState.view == "estacao", "seta leva à plataforma")
	_shot(main, "02_plataforma_1924")
	main.on_hotspot("relogio")
	await _frames(tree)
	var zoom = _find(main.modal_layer, ZoomPanel)
	_expect(zoom != null, "relógio abre o zoom")
	_shot(main, "03_zoom_relogio")
	zoom.closed.emit()
	await _frames(tree)

	main.left_button.pressed.emit()
	await _frames(tree)
	main.on_hotspot("mala")
	await _frames(tree)
	var lock = _find(main.modal_layer, LockPanel)
	_expect(lock != null, "mala abre o cadeado")
	_shot(main, "04_cadeado")
	lock.submitted.emit("000")
	await _frames(tree)
	_expect(not GameState.has_item("camera"), "código errado não abre")
	lock.submitted.emit("317")
	await _frames(tree)
	_expect(GameState.has_item("camera"), "código 317 dá a câmera")
	_expect(_find(main.modal_layer, LockPanel) == null, "cadeado fecha ao abrir")

	main.photo_button.pressed.emit()
	main.right_button.pressed.emit()
	main.photo_button.pressed.emit()
	await _frames(tree)
	_expect(GameState.plates == 1 and GameState.photos.size() == 2, "duas fotos, uma chapa sobrando")

	await _develop_and_enter(main, tree, "estacao")
	_expect(GameState.era == 1899 and GameState.view == "estacao", "entra na foto da plataforma")
	_expect(not main.right_button.visible, "dentro da foto não há setas")
	_shot(main, "06_plataforma_1899")
	main.on_hotspot("banco")
	await _frames(tree)
	_expect(GameState.has_item("bilhete"), "pega o bilhete em 1899")
	_shot(main, "07_bilhete")
	main.leave_button.pressed.emit()
	await _frames(tree)
	_expect(GameState.era == 1924, "sai da foto")
	_expect(_find(main.modal_layer, EndingPanel) == null, "ainda não é o fim")

	await _develop_and_enter(main, tree, "bilheteria")
	await _frames(tree)
	_shot(main, "08_bilheteria_1899")
	main.on_hotspot("gaveta")
	main.leave_button.pressed.emit()
	await _frames(tree)
	_expect(GameState.has_item("chave"), "pega a chave em 1899")

	main.on_hotspot("gaveta")
	_expect(not GameState.has_flag("gaveta_aberta"), "sem a chave a gaveta não abre")
	main.inventory_bar.item_pressed.emit("chave")
	main.on_hotspot("gaveta")
	await _frames(tree)
	_expect(GameState.has_item("carta"), "a chave abre a gaveta e dá a carta")
	_expect(_find(main.modal_layer, EndingPanel) != null, "mostra o fim do prólogo")
	_shot(main, "09_fim")
	_expect(GameState.notes.size() >= 5, "caderno tem as anotações")

	main.show_title()
	await _frames(tree)

	if failures.is_empty():
		print("SMOKE OK")
		tree.quit(0)
	else:
		for f in failures:
			printerr("FALHOU: " + f)
		tree.quit(1)


static func _develop_and_enter(main: Node, tree: SceneTree, view: String) -> void:
	main.album_button.pressed.emit()
	await _frames(tree)
	var album = _find(main.modal_layer, ListPanel)
	album.action.emit(view, "develop")
	await _frames(tree)
	var darkroom = _find(main.modal_layer, DarkroomPanel)
	_expect(darkroom != null, "abre a câmara escura (%s)" % view)
	darkroom.progress = 0.3
	darkroom.pull()
	_expect(GameState.photos[view] == "taken", "retirar cedo não revela")
	darkroom.restart()
	darkroom.progress = 0.65
	darkroom._update_visuals()
	await _frames(tree)
	_shot(main, "05_camara_escura_" + view)
	darkroom.pull()
	await tree.create_timer(1.2).timeout
	await _frames(tree)
	_expect(GameState.photos[view] == "developed", "revela %s" % view)
	album = _find(main.modal_layer, ListPanel)
	album.action.emit(view, "enter")
	await _frames(tree)


static func _frames(tree: SceneTree) -> void:
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
	var image := main.get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [shots_dir, name])
