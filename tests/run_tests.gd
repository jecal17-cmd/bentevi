extends SceneTree
## Testes das regras do jogo:
##   godot --headless -s tests/run_tests.gd

const GameStateScript := preload("res://scripts/game/game_state.gd")
const Logic := preload("res://scripts/game/logic.gd")
const Content := preload("res://scripts/game/content.gd")
const Hotspots := preload("res://scripts/game/hotspots.gd")

var failures := 0
var passed := 0


func _init() -> void:
	test_prologue_walkthrough()
	test_photo_rules()
	test_wrong_item()
	test_names()
	test_hints()
	test_chapter1_walkthrough()
	test_save_roundtrip()
	test_content()
	print("%d testes ok, %d falhas" % [passed, failures])
	quit(1 if failures > 0 else 0)


func fresh():
	var gs = GameStateScript.new()
	gs.save_enabled = false
	gs.new_game()
	return gs


func test_prologue_walkthrough() -> void:
	var gs = fresh()
	check(Logic.interact(gs, "mala").get("open") == "lock", "mala fechada abre o cadeado")
	check(not Logic.try_code(gs, "mala", "123"), "código errado falha")
	check(Logic.try_code(gs, "mala", "317"), "317 abre a mala")
	check(gs.has_item("camera"), "ganha a câmera")
	check(Logic.take_photo(gs), "fotografa a bilheteria")
	Logic.go_next_view(gs)
	check(gs.view == "estacao", "seta leva à plataforma")
	check(Logic.interact(gs, "relogio").get("open") == "zoom", "relógio abre o zoom")
	Logic.take_photo(gs)
	Logic.develop(gs, "estacao")
	Logic.enter_photo(gs, "estacao")
	Logic.interact(gs, "banco")
	check(gs.has_item("bilhete"), "bilhete em 1899")
	Logic.leave_photo(gs)
	check(not Logic.chapter_complete(gs), "ainda não terminou")
	Logic.develop(gs, "bilheteria")
	Logic.enter_photo(gs, "bilheteria")
	Logic.interact(gs, "gaveta")
	check(gs.has_item("chave"), "chave em 1899")
	Logic.leave_photo(gs)
	Logic.interact(gs, "gaveta")
	check(not gs.has_flag("gaveta_aberta"), "sem selecionar a chave, não abre")
	Logic.select_item(gs, "chave")
	Logic.interact(gs, "gaveta")
	check(gs.has_item("carta") and not gs.has_item("chave"), "chave abre a gaveta e é gasta")
	check(Logic.chapter_complete(gs), "prólogo completo")
	gs.free()


func test_photo_rules() -> void:
	var gs = fresh()
	check(not Logic.take_photo(gs), "sem câmera não fotografa")
	Logic.try_code(gs, "mala", "317")
	Logic.take_photo(gs)
	check(not Logic.take_photo(gs), "não fotografa o mesmo lugar duas vezes")
	Logic.enter_photo(gs, "bilheteria")
	check(gs.era == 1924, "foto não revelada não deixa entrar")
	Logic.develop(gs, "bilheteria")
	Logic.enter_photo(gs, "bilheteria")
	check(gs.era == 1899 and not Logic.take_photo(gs), "dentro da foto não fotografa")
	Logic.go_next_view(gs)
	check(gs.view == "bilheteria", "não navega dentro da foto")
	gs.free()


func test_wrong_item() -> void:
	var gs = fresh()
	Logic.try_code(gs, "mala", "317")
	Logic.select_item(gs, "camera")
	Logic.interact(gs, "quadro")
	check(gs.selected_item == "", "item que não serve é desmarcado")
	gs.free()


func test_names() -> void:
	var gs = fresh()
	var r: Dictionary = Logic.interact(gs, "nome_peitoril")
	check(r.get("open") == "name" and gs.names_found.size() == 1, "nome escondido é encontrado")
	check(Logic.interact(gs, "nome_peitoril").is_empty() and gs.names_found.size() == 1, "nome não conta duas vezes")
	gs.free()


func test_hints() -> void:
	var gs = fresh()
	var first := Logic.next_hint(gs)
	Logic.next_hint(gs)
	Logic.next_hint(gs)
	var fourth := Logic.next_hint(gs)
	check(first.contains("1/3") and fourth.contains("3/3") and fourth.contains("3-1-7"), "dicas sobem até a solução")
	Logic.try_code(gs, "mala", "317")
	check(Logic.next_hint(gs).contains("1/3"), "nova etapa reinicia as dicas")
	gs.free()


func test_chapter1_walkthrough() -> void:
	var gs = fresh()
	Logic.start_chapter(gs, 1)
	check(gs.chapter == 1 and gs.view == "salao" and gs.plates == 3, "capítulo 1 começa no salão com 3 chapas")
	check(gs.has_item("camera") and gs.has_item("carta") and not gs.has_item("chave"), "leva os itens do prólogo")
	check(Logic.stage(gs) == "c1_coroa", "primeira etapa: coroa")

	var coroa: Dictionary = Logic.interact(gs, "coroa")
	check(coroa.has("action"), "coroa oferece pegar a medalha")
	Logic.zoom_action(gs, "pegar_medalha")
	check(gs.has_item("medalha_torre") and not Logic.interact(gs, "coroa").has("action"), "medalha da torre")
	check(not Logic.take_photo(gs), "salão escuro não fotografa")

	gs.view = "relogios"
	Logic.interact(gs, "gaveta_cima")
	check(gs.has_item("fosforos"), "fósforos na gaveta de cima")
	gs.view = "salao"
	Logic.select_item(gs, "fosforos")
	Logic.interact(gs, "castical")
	check(gs.has_flag("velas_acesas") and not gs.has_item("fosforos"), "fósforos acendem as velas")
	check(Logic.take_photo(gs), "com luz, fotografa o salão")

	gs.view = "espelho"
	Logic.interact(gs, "bilhete_ester")
	check(gs.has_item("bilhete_ester"), "pega o bilhete de Ester")
	Logic.take_photo(gs)
	Logic.develop(gs, "espelho")
	Logic.enter_photo(gs, "espelho")
	var mirror: Dictionary = Logic.interact(gs, "espelho")
	check(mirror.get("overlay") == "mirror" and gs.has_flag("viu_reflexo"), "reflexo de 1899")
	Logic.leave_photo(gs)

	gs.view = "relogios"
	var lock: Dictionary = Logic.interact(gs, "gaveta_meio")
	check(lock.get("digits") == 4, "gaveta do meio tem cadeado de 4 dígitos")
	check(not Logic.try_code(gs, "comoda", "8041"), "ler sem espelhar não abre")
	check(Logic.try_code(gs, "comoda", "1408"), "1408 abre a cômoda")
	check(gs.has_item("medalha_muleta") and gs.has_item("atestado"), "medalha da muleta e atestado")

	Logic.take_photo(gs)
	check(gs.plates == 0, "três fotos gastam as três chapas")
	Logic.develop(gs, "relogios")
	Logic.enter_photo(gs, "relogios")
	Logic.interact(gs, "pendulo")
	check(gs.has_item("chave_corda"), "chave de corda em 1899")
	var name_result: Dictionary = Logic.interact(gs, "gaveta_baixo")
	check(name_result.get("index") == 14, "recibo com o nome do pai")
	Logic.leave_photo(gs)

	check(Logic.interact(gs, "pendulo").is_empty(), "sem corda, o pêndulo não abre o acerto")
	Logic.select_item(gs, "chave_corda")
	check(Logic.interact(gs, "pendulo").get("open") == "clock_set", "com a chave, acerta os ponteiros")
	check(not Logic.set_clock(gs, 3, 15), "hora errada não abre")
	check(Logic.set_clock(gs, 2, 40), "2h40 abre a base")
	check(gs.has_item("medalha_sol"), "medalha do sol")

	gs.view = "salao"
	for medal in ["medalha_torre", "medalha_muleta"]:
		Logic.select_item(gs, medal)
		Logic.interact(gs, "caixao")
	check(not gs.has_flag("caixao_aberto"), "duas medalhas não bastam")
	Logic.select_item(gs, "medalha_sol")
	Logic.interact(gs, "caixao")
	check(gs.has_flag("caixao_aberto") and gs.has_item("pepita"), "três medalhas abrem o caixão")
	check(Logic.chapter_complete(gs) and Logic.stage(gs) == "fim", "capítulo 1 completo")
	gs.free()


func test_save_roundtrip() -> void:
	var gs = fresh()
	gs.save_enabled = true
	gs.save_path = "user://teste_save.json"
	Logic.start_chapter(gs, 1)
	Logic.interact(gs, "nome_cavalete")
	var other = GameStateScript.new()
	other.save_path = "user://teste_save.json"
	check(other.load_game(), "carrega o salvamento")
	check(other.chapter == 1 and other.names_found == [4] and other.has_item("carta"), "capítulo, nomes e itens voltam iguais")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://teste_save.json"))
	gs.free()
	other.free()


func test_content() -> void:
	var stages := ["mala", "fotografar", "revelar", "bilhete", "chave", "gaveta", "c1_coroa", "c1_fosforos",
		"c1_velas", "c1_espelho", "c1_comoda", "c1_corda", "c1_pendulo", "c1_caixao", "fim"]
	for s in stages:
		check(Content.HINTS.has(s) and Content.HINTS[s].size() == 3, "3 dicas para " + s)
	var ids := {}
	for view in Hotspots.HOTSPOTS:
		check(Content.VIEWS.has(view), "vista %s registrada" % view)
		for h in Hotspots.HOTSPOTS[view]:
			ids[h["id"]] = true
			var r: Rect2 = h["rect"]
			check(r.end.y <= 880 and r.end.x <= 1920, "%s/%s fica acima da barra de inventário" % [view, h["id"]])
	for item in Content.ITEM_TARGETS:
		check(Content.ITEMS.has(item), "item %s existe" % item)
		for target in Content.ITEM_TARGETS[item]:
			check(ids.has(target), "alvo %s existe" % target)
	for spot in Content.NAME_SPOTS:
		check(ids.has(spot), "ponto de nome %s existe" % spot)
	check(Content.MINERS.size() == 31, "31 mineiros")


func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failures += 1
		printerr("FALHOU: " + label)
