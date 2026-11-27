extends RefCounted
## Regras do prólogo — A Estação.

const Hotspots := preload("res://scripts/game/hotspots.gd")

const LOCK_CODE := "317"


static func interact(gs, id: String) -> Dictionary:
	var past: bool = gs.is_past()
	match id:
		"mala":
			if gs.has_flag("mala_aberta"):
				gs.say("A mala está vazia. Só cheiro de viagem.")
				return {}
			return {"open": "lock", "id": "mala", "digits": 3, "title": "Cadeado da mala"}
		"relogio":
			if past:
				gs.say("Funciona. O ponteiro anda devagar, como se hesitasse.")
				gs.play("tick")
				return {}
			gs.set_flag("viu_relogio")
			gs.add_note("O relógio da plataforma parou às 3h17.")
			gs.commit()
			return {"open": "zoom", "art": "relogio_zoom", "clock": Hotspots.CLOCK_TIME[1924],
				"caption": "Os ponteiros pararam às 3h17. Uma pena amarela presa sob o aro."}
		"passaro":
			return {"open": "hint"}
		"banco":
			return _banco(gs, past)
		"gaveta":
			return _gaveta(gs, past)
		"quadro":
			gs.say("O mesmo retrato, novo. Uma menina de vestido claro olha direto para a câmera." if past
				else "Um retrato desbotado da família que inaugurou a estação. No canto: 1899.")
		"fogao":
			gs.say("O fogão está aceso. Alguém esteve aqui há pouco." if past else "Frio há muitos anos.")
		"igreja":
			gs.say("O sino toca... e mais uma vez, fora de hora." if past
				else "A torre da igreja matriz. O sino não toca há anos.")
			if past:
				gs.play("chime")
		"janela":
			gs.say("Pela janela, a plataforma nova em folha. O relógio anda." if past
				else "Pela janela, a plataforma. O relógio lá fora parou numa hora estranha.")
		"casinha":
			gs.say("A bilheteria, recém-pintada. Alguém lá dentro cantarola." if past
				else "A bilheteria onde deixei minha mala. A porta range com o vento.")
	return {}


static func _banco(gs, past: bool) -> Dictionary:
	if not past:
		gs.say("Madeira podre. Alguém esperou muito tempo aqui.")
		return {}
	if gs.has_flag("bilhete_pego"):
		gs.say("Só o banco, ainda com cheiro de verniz.")
		return {}
	gs.set_flag("bilhete_pego")
	gs.add_note("Bilhete de 1899 com o meu nome: Lúcia Vaz, 7 anos.")
	gs.play("pickup")
	gs.add_item("bilhete")
	gs.commit()
	return {}


static func _gaveta(gs, past: bool) -> Dictionary:
	if past:
		if gs.has_flag("chave_pega"):
			gs.say("A gaveta está aberta e vazia.")
			return {}
		gs.set_flag("chave_pega")
		gs.add_note("Em 1899 havia uma chave sobre o balcão da bilheteria.")
		gs.play("pickup")
		gs.add_item("chave")
		gs.commit()
		return {}
	if gs.has_flag("gaveta_aberta"):
		gs.say("A gaveta está vazia agora.")
		return {}
	if gs.selected_item == "chave":
		gs.remove_item("chave")
		gs.set_flag("gaveta_aberta")
		gs.add_note("Carta bordada em linha amarela: \"O bem-te-vi viu. Volte para casa. — C.\"")
		gs.play("drawer")
		gs.say("A chave de 1899 serviu.")
		gs.add_item("carta")
		gs.commit()
		return {}
	gs.play("lock_fail")
	gs.say("Trancada. A fechadura está tomada de ferrugem.")
	return {}


static func try_code(gs, code: String) -> bool:
	if code != LOCK_CODE:
		gs.play("lock_fail")
		gs.say("O cadeado não cede.")
		return false
	gs.set_flag("mala_aberta")
	gs.add_note("Na mala: a câmera de fole e 3 chapas de vidro.")
	gs.play("lock_open")
	gs.say("A mala abriu. Minha câmera de fole e três chapas de vidro.")
	gs.add_item("camera")
	gs.commit()
	return true


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


## Estado de quem terminou o prólogo (usado ao começar o Capítulo 1 pelo menu).
static func apply_completed(gs) -> void:
	for flag in ["mala_aberta", "viu_relogio", "bilhete_pego", "chave_pega", "gaveta_aberta", "entrou_no_passado", "prologo_completo"]:
		gs.set_flag(flag)
	for item in ["camera", "bilhete", "carta"]:
		gs.add_item(item, false)
	gs.remove_item("chave")
	gs.add_note("Bilhete de 1899 com o meu nome: Lúcia Vaz, 7 anos.")
	gs.add_note("Carta bordada em linha amarela: \"O bem-te-vi viu. Volte para casa. — C.\"")
