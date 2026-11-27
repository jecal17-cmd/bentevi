extends RefCounted
## Regras comuns a todos os capítulos. Funções estáticas que recebem o estado (`gs`),
## para serem testadas sem interface. As regras de cada capítulo ficam em
## logic_prologo.gd e logic_cap1.gd.
##
## interact() devolve {} ou um pedido para a interface, por exemplo:
##   {"open": "lock", "id": "mala", "digits": 3, "title": "..."}
##   {"open": "zoom", "art": "...", "caption": "...", "overlay": "...", "action": {...}}
##   {"open": "name", "index": 14, "where": "..."}
##   {"open": "clock_set"} · {"open": "hint"}

const Content := preload("res://scripts/game/content.gd")
const Hotspots := preload("res://scripts/game/hotspots.gd")
const Prologo := preload("res://scripts/game/logic_prologo.gd")
const Cap1 := preload("res://scripts/game/logic_cap1.gd")


static func interact(gs, id: String) -> Dictionary:
	var item: String = gs.selected_item
	if item != "" and not Content.can_use_on(item, id):
		gs.say("Isso não parece servir aqui.")
		gs.play("lock_fail")
		gs.selected_item = ""
		gs.commit()
		return {}
	if Content.NAME_SPOTS.has(id):
		var spot: Array = Content.NAME_SPOTS[id]
		return find_name(gs, spot[0], spot[1])
	if _chapter_of_view(gs.view) == 0:
		return Prologo.interact(gs, id)
	return Cap1.interact(gs, id)


static func try_code(gs, lock_id: String, code: String) -> bool:
	match lock_id:
		"mala":
			return Prologo.try_code(gs, code)
		"comoda":
			return Cap1.try_code(gs, code)
	return false


static func zoom_action(gs, action_id: String) -> void:
	Cap1.zoom_action(gs, action_id)


static func set_clock(gs, hour: int, minute: int) -> bool:
	return Cap1.set_clock(gs, hour, minute)


## Registra um nome de mineiro. Se já foi encontrado, só repete onde estava.
static func find_name(gs, index: int, where: String) -> Dictionary:
	if gs.names_found.has(index):
		gs.say("%s %s" % [where, Content.MINERS[index].split(",")[0]])
		return {}
	gs.names_found.append(index)
	gs.add_note("Nome %d de 31: %s." % [gs.names_found.size(), Content.MINERS[index]])
	gs.play("name")
	gs.commit()
	return {"open": "name", "index": index, "where": where}


static func select_item(gs, id: String) -> void:
	gs.selected_item = "" if gs.selected_item == id else id
	gs.play("click")
	gs.commit()


static func take_photo(gs) -> bool:
	if gs.is_past():
		gs.say("Dentro de uma foto, a câmera não funciona.")
		return false
	if not gs.has_item("camera"):
		return false
	if gs.photos.has(gs.view):
		gs.say("Já tenho uma chapa deste lugar.")
		return false
	if gs.plates <= 0:
		gs.say("Acabaram as chapas.")
		return false
	var needs: String = Hotspots.PHOTO_NEEDS.get(gs.view, "")
	if needs != "" and not gs.has_flag(needs):
		gs.say("Escuro demais. A chapa não guardaria nada sem luz.")
		return false
	gs.plates -= 1
	gs.photos[gs.view] = "taken"
	gs.play("shutter")
	gs.say("Clique. A chapa guardou: %s. Revele no Álbum." % Content.view_title(gs.view))
	gs.commit()
	return true


static func develop(gs, view: String) -> void:
	gs.photos[view] = "developed"
	gs.play("reveal")
	gs.say("A imagem surge na chapa... mas não é o lugar de hoje.")
	gs.commit()


static func enter_photo(gs, view: String) -> void:
	if gs.photos.get(view, "") != "developed":
		return
	gs.era = 1899
	gs.view = view
	gs.selected_item = ""
	gs.play("enter_past")
	if not gs.has_flag("entrou_no_passado"):
		gs.set_flag("entrou_no_passado")
		gs.add_note("As fotos reveladas mostram 14 de agosto de 1899. Posso entrar nelas.")
		gs.say("O cheiro de verniz novo. O relógio anda. Isto é 1899.")
	gs.commit()


static func leave_photo(gs) -> void:
	gs.era = 1924
	gs.selected_item = ""
	gs.play("leave_past")
	gs.commit()


static func go_view(gs, direction: String) -> void:
	if gs.is_past():
		return
	gs.view = Content.VIEWS[gs.view][direction]
	gs.selected_item = ""
	gs.play("click")
	gs.commit()


static func go_next_view(gs) -> void:
	go_view(gs, "next")


## Começa um capítulo. Do menu, o jogo anterior é tratado como concluído.
static func start_chapter(gs, chapter: int) -> void:
	if chapter >= 1:
		Prologo.apply_completed(gs)
	gs.chapter = chapter
	gs.view = Content.CHAPTERS[chapter]["start_view"]
	gs.era = 1924
	gs.photos = {}
	gs.plates = Content.CHAPTERS[chapter]["plates"]
	gs.selected_item = ""
	gs.hint_stage = ""
	gs.hint_level = 0
	if chapter == 1:
		Cap1.on_start(gs)
	gs.commit()


static func stage(gs) -> String:
	if gs.chapter == 0:
		return Prologo.stage(gs)
	return Cap1.stage(gs)


## Cada pedido na mesma etapa sobe um nível (até a solução).
static func next_hint(gs) -> String:
	var current := stage(gs)
	if current != gs.hint_stage:
		gs.hint_stage = current
		gs.hint_level = 0
	var lines: Array = Content.HINTS[current]
	var index: int = mini(gs.hint_level, lines.size() - 1)
	gs.hint_level = index + 1
	gs.play("bird")
	gs.commit()
	return "Bem-te-vi (%d/3): %s" % [index + 1, lines[index]]


static func chapter_complete(gs) -> bool:
	if gs.is_past():
		return false
	if gs.chapter == 0:
		return gs.has_flag("bilhete_pego") and gs.has_flag("gaveta_aberta")
	return gs.has_flag("caixao_aberto")


static func _chapter_of_view(view: String) -> int:
	return Content.VIEWS.get(view, {}).get("chapter", 0)
