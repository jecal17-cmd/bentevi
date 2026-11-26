extends SceneTree
## Testes da lógica do prólogo:
##   godot --headless -s tests/run_tests.gd

const GameStateScript := preload("res://scripts/game/game_state.gd")
const Logic := preload("res://scripts/game/logic.gd")
const Content := preload("res://scripts/game/content.gd")

var failures := 0
var passed := 0


func _init() -> void:
	test_lock()
	test_photo_rules()
	test_hints()
	test_save_roundtrip()
	test_content()
	print("%d testes ok, %d falhas" % [passed, failures])
	quit(1 if failures > 0 else 0)


func fresh():
	var gs = GameStateScript.new()
	gs.save_enabled = false
	gs.new_game()
	return gs


func test_lock() -> void:
	var gs = fresh()
	check(Logic.interact(gs, "mala").get("open") == "lock", "mala fechada abre o cadeado")
	check(not Logic.try_code(gs, "123"), "código errado falha")
	check(Logic.try_code(gs, "317"), "código certo abre")
	check(gs.has_item("camera"), "ganha a câmera")
	check(Logic.interact(gs, "mala").is_empty(), "mala aberta não reabre o cadeado")
	gs.free()


func test_photo_rules() -> void:
	var gs = fresh()
	check(not Logic.take_photo(gs), "sem câmera não fotografa")
	Logic.try_code(gs, "317")
	check(Logic.take_photo(gs), "fotografa a bilheteria")
	check(not Logic.take_photo(gs), "não fotografa o mesmo lugar duas vezes")
	Logic.enter_photo(gs, "bilheteria")
	check(gs.era == 1924, "foto não revelada não deixa entrar")
	Logic.develop(gs, "bilheteria")
	Logic.enter_photo(gs, "bilheteria")
	check(gs.era == 1899, "foto revelada leva a 1899")
	check(not Logic.take_photo(gs), "câmera não funciona dentro da foto")
	Logic.go_next_view(gs)
	check(gs.view == "bilheteria", "não navega dentro da foto")
	Logic.interact(gs, "gaveta")
	check(gs.has_item("chave"), "pega a chave em 1899")
	Logic.leave_photo(gs)
	gs.selected_item = "chave"
	Logic.interact(gs, "quadro")
	check(gs.selected_item == "", "item errado é desmarcado")
	Logic.select_item(gs, "chave")
	Logic.interact(gs, "gaveta")
	check(gs.has_flag("gaveta_aberta") and gs.has_item("carta"), "chave abre a gaveta em 1924")
	check(not Logic.ending_ready(gs), "sem o bilhete não termina")
	gs.free()


func test_hints() -> void:
	var gs = fresh()
	check(Logic.stage(gs) == "mala", "primeira etapa é a mala")
	var first := Logic.next_hint(gs)
	var second := Logic.next_hint(gs)
	Logic.next_hint(gs)
	var fourth := Logic.next_hint(gs)
	check(first.contains("1/3") and second.contains("2/3"), "dicas sobem de nível")
	check(fourth.contains("3/3") and fourth.contains("3-1-7"), "nível 3 é a solução e para ali")
	Logic.try_code(gs, "317")
	check(Logic.next_hint(gs).contains("1/3"), "nova etapa reinicia as dicas")
	check(Logic.stage(gs) == "fotografar", "segunda etapa é fotografar")
	gs.free()


func test_save_roundtrip() -> void:
	var gs = fresh()
	gs.save_enabled = true
	gs.save_path = "user://teste_save.json"
	Logic.try_code(gs, "317")
	Logic.take_photo(gs)
	var other = GameStateScript.new()
	other.save_path = "user://teste_save.json"
	check(other.load_game(), "carrega o salvamento")
	check(other.has_item("camera") and other.photos.has("bilheteria") and other.plates == 2, "estado volta igual")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://teste_save.json"))
	gs.free()
	other.free()


func test_content() -> void:
	for stage_name in ["mala", "fotografar", "revelar", "bilhete", "chave", "gaveta", "fim"]:
		check(Content.HINTS.has(stage_name) and Content.HINTS[stage_name].size() == 3, "3 dicas para " + stage_name)
	for view in Content.HOTSPOTS:
		for h in Content.HOTSPOTS[view]:
			var r: Rect2 = h["rect"]
			check(r.end.y <= 880, "%s/%s fica acima da barra de inventário" % [view, h["id"]])


func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failures += 1
		printerr("FALHOU: " + label)
