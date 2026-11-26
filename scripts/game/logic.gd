extends RefCounted
## Regras do prólogo. Funções estáticas que recebem o estado (`gs`),
## para poderem ser testadas sem interface.
##
## interact() devolve {} ou {"open": "<painel>"} quando a interface
## precisa abrir algo (cadeado, zoom).

const Content := preload("res://scripts/game/content.gd")

const LOCK_CODE := "317"


static func interact(gs, id: String) -> Dictionary:
	var past: bool = gs.is_past()
	var item: String = gs.selected_item

	if item != "" and not (id == "gaveta" and item == "chave" and not past):
		gs.say("Isso não parece servir aqui.")
		gs.selected_item = ""
		gs.commit()
		return {}

	match id:
		"mala":
			if gs.has_flag("mala_aberta"):
				gs.say("A mala está vazia. Só cheiro de viagem.")
				return {}
			return {"open": "lock"}
		"relogio":
			if past:
				gs.say("Funciona. O ponteiro anda devagar, como se hesitasse.")
				return {}
			gs.set_flag("viu_relogio")
			gs.add_note("O relógio da plataforma parou às 3h17.")
			gs.commit()
			return {"open": "zoom_relogio"}
		"passaro":
			return {"open": "hint"}
		"banco":
			return _banco(gs, past)
		"gaveta":
			return _gaveta(gs, past, item)
		"quadro":
			if past:
				gs.say("O mesmo retrato, novo. Uma menina de vestido claro olha direto para a câmera.")
			else:
				gs.say("Um retrato desbotado da estação recém-inaugurada. No canto: 1899.")
		"fogao":
			if past:
				gs.say("O fogão está aceso. Alguém esteve aqui há pouco.")
			else:
				gs.say("Frio há muitos anos.")
		"igreja":
			if past:
				gs.say("O sino toca... e mais uma vez, fora de hora.")
			else:
				gs.say("A torre da igreja matriz. O sino não toca há anos.")
		"janela":
			if past:
				gs.say("Pela janela, a plataforma nova em folha. O relógio anda.")
			else:
				gs.say("Pela janela, a plataforma. O relógio lá fora parou numa hora estranha.")
		"casinha":
			gs.say("A bilheteria onde deixei minha mala. A porta range com o vento.")
	return {}


static func _banco(gs, past: bool) -> Dictionary:
	if not past:
		gs.say("Madeira podre. Alguém esperou muito tempo aqui.")
		return {}
	if gs.has_flag("bilhete_pego"):
		gs.say("Só o banco, ainda com cheiro de verniz.")
		return {}
	gs.add_item("bilhete")
	gs.set_flag("bilhete_pego")
	gs.add_note("Bilhete de 1899 com o meu nome: Lúcia Vaz, 7 anos.")
	gs.say("Um bilhete de trem. Passageira: Lúcia Vaz, 7 anos. Esse é o meu nome.")
	gs.commit()
	return {}


static func _gaveta(gs, past: bool, item: String) -> Dictionary:
	if past:
		if gs.has_flag("chave_pega"):
			gs.say("A gaveta está aberta e vazia.")
			return {}
		gs.add_item("chave")
		gs.set_flag("chave_pega")
		gs.add_note("Em 1899 a gaveta da bilheteria estava aberta, com uma chave dentro.")
		gs.say("Uma chave de latão, ainda brilhando. Ninguém vai sentir falta... ou vai?")
		gs.commit()
		return {}
	if gs.has_flag("gaveta_aberta"):
		gs.say("A gaveta está vazia agora.")
		return {}
	if item == "chave":
		gs.remove_item("chave")
		gs.add_item("carta")
		gs.set_flag("gaveta_aberta")
		gs.add_note("Carta bordada em linha amarela: \"O bem-te-vi viu. Volte para casa. — C.\"")
		gs.say("A chave de 1899 serviu. Dentro, um envelope com o meu nome.")
		gs.commit()
		return {}
	gs.say("Trancada. A fechadura está tomada de ferrugem.")
	return {}


static func try_code(gs, code: String) -> bool:
	if code != LOCK_CODE:
		gs.say("O cadeado não cede.")
		return false
	gs.set_flag("mala_aberta")
	gs.add_item("camera")
	gs.add_note("Na mala: a câmera de fole e 3 chapas de vidro.")
	gs.say("A mala abriu. Minha câmera de fole e três chapas de vidro.")
	gs.commit()
	return true


static func select_item(gs, id: String) -> void:
	if gs.selected_item == id:
		gs.selected_item = ""
	else:
		gs.selected_item = id
		gs.say(Content.item_desc(id))
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
	gs.plates -= 1
	gs.photos[gs.view] = "taken"
	gs.say("Clique. A chapa guardou: %s. Revele no Álbum." % Content.view_title(gs.view))
	gs.commit()
	return true


static func develop(gs, view: String) -> void:
	gs.photos[view] = "developed"
	gs.say("A imagem surge... mas não é a %s de hoje." % Content.view_title(view).to_lower())
	gs.commit()


static func enter_photo(gs, view: String) -> void:
	if gs.photos.get(view, "") != "developed":
		return
	gs.era = 1899
	gs.view = view
	gs.selected_item = ""
	if not gs.has_flag("entrou_no_passado"):
		gs.set_flag("entrou_no_passado")
		gs.add_note("As fotos reveladas mostram 14 de agosto de 1899. Posso entrar nelas.")
		gs.say("O cheiro de verniz novo. O relógio anda. Isto é 1899.")
	gs.commit()


static func leave_photo(gs) -> void:
	gs.era = 1924
	gs.selected_item = ""
	gs.commit()


static func go_next_view(gs) -> void:
	if gs.is_past():
		return
	gs.view = Content.VIEWS[gs.view]["next"]
	gs.commit()


static func stage(gs) -> String:
	if not gs.has_flag("mala_aberta"):
		return "mala"
	if gs.photos.is_empty():
		return "fotografar"
	if not gs.photos.values().has("developed"):
		return "revelar"
	if not gs.has_flag("bilhete_pego"):
		return "bilhete"
	if not gs.has_flag("chave_pega"):
		return "chave"
	if not gs.has_flag("gaveta_aberta"):
		return "gaveta"
	return "fim"


## Cada pedido na mesma etapa sobe um nível (até a solução).
static func next_hint(gs) -> String:
	var current := stage(gs)
	if current != gs.hint_stage:
		gs.hint_stage = current
		gs.hint_level = 0
	var lines: Array = Content.HINTS[current]
	var index: int = mini(gs.hint_level, lines.size() - 1)
	gs.hint_level = index + 1
	gs.commit()
	return "Bem-te-vi (%d/3): %s" % [index + 1, lines[index]]


static func ending_ready(gs) -> bool:
	return gs.has_flag("bilhete_pego") and gs.has_flag("gaveta_aberta") and not gs.is_past()
