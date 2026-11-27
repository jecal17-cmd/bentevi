extends RefCounted
## Regras do Capítulo 1 — O Velório.
## Cadeia principal: medalha da coroa · fósforos → velas → foto do salão ·
## reflexo de 1899 (1408) → cômoda (medalha + atestado) · chave de corda de 1899 →
## pêndulo em 2h40 (medalha) · três medalhas → caixão.

const MIRROR_CODE := "1408"
const OFFICIAL_TIME := [2, 40]
const MEDALS := {"medalha_torre": "slot_torre", "medalha_muleta": "slot_muleta", "medalha_sol": "slot_sol"}
## Mineiro cujo nome está no recibo: o pai de Lúcia.
const FATHER_INDEX := 14


static func on_start(gs) -> void:
	gs.add_note("Casarão Monteverde, noite do velório. A família \"repousa\".")
	gs.say("A carruagem me deixou no casarão. A porta estava aberta, e ninguém veio me receber.")


static func interact(gs, id: String) -> Dictionary:
	var past: bool = gs.is_past()
	match id:
		"janela":
			gs.say("Lá fora, homens com lampiões descem a encosta, rumo à mina." if past
				else "A lua sobre o morro. Lá embaixo, a boca da mina, fechada com tábuas.")
		"gaiola":
			if not past:
				return {"open": "hint"}
			gs.say("A gaiola está aberta e vazia. Ninguém sabe dizer para onde ele foi.")
		"coroa":
			return _coroa(gs)
		"caixao":
			return _caixao(gs)
		"mesa":
			gs.add_note("Em 1899, a mesa estava posta para seis, com um sétimo prato de criança.")
			gs.commit()
			gs.say("Uma mesa posta para seis. No canto, um sétimo lugar improvisado: um prato pequeno, de criança.")
		"castical":
			return _castical(gs, past)
		"parede":
			return _parede(past)
		"pendulo":
			return _pendulo(gs, past)
		"gaveta_cima":
			return _gaveta_cima(gs, past)
		"gaveta_meio":
			if past:
				gs.say("Trancada também em 1899. Nesta casa, alguém sempre guardou segredos.")
				return {}
			if gs.has_flag("comoda_aberta"):
				gs.say("A gaveta do meio está vazia agora.")
				return {}
			return {"open": "lock", "id": "comoda", "digits": 4, "title": "Cadeado de quatro números"}
		"gaveta_baixo":
			return _gaveta_baixo(gs, past)
		"retrato":
			if past:
				gs.say("O coronel, mais jovem. Na moldura: \"Mina da Aurora, 1890\".")
				return {}
			gs.say("Coronel Joaquim Monteverde. Alguém raspou os olhos da pintura.")
			return _find_name_once(gs, 6, "Atrás da moldura, a lápis:")
		"espelho":
			return _espelho(gs, past)
		"aparador":
			gs.say("Sobre o aparador, uma passagem de volta nunca usada: Rio de Janeiro, 15 de agosto de 1899." if past
				else "Um aparador de jacarandá. Cheira a cera e a flores murchas.")
		"bilhete_ester":
			if gs.has_item("bilhete_ester"):
				gs.say("Já peguei o recado de Dona Ester.")
				return {}
			gs.play("page")
			gs.add_item("bilhete_ester")
			gs.commit()
		"porta":
			gs.say("Aberta. Do corredor vem o riso de duas crianças." if past
				else "Trancada. Do outro lado, passos que param quando eu paro.")
	return {}


static func _coroa(gs) -> Dictionary:
	var result := {
		"open": "zoom", "art": "coroa_zoom", "overlay": "ribbon",
		"caption": "Na fita: \"Saudades eternas — Ester, Augusto e Celeste.\"",
	}
	if not gs.has_flag("medalha_torre_pega"):
		result["caption"] += " Entre os lírios, algo prateado."
		result["action"] = {"label": "Pegar a medalha", "id": "pegar_medalha"}
	return result


static func zoom_action(gs, action_id: String) -> void:
	if action_id == "pegar_medalha" and not gs.has_flag("medalha_torre_pega"):
		gs.set_flag("medalha_torre_pega")
		gs.play("pickup")
		gs.add_item("medalha_torre")
		gs.commit()


static func _caixao(gs) -> Dictionary:
	var item: String = gs.selected_item
	if MEDALS.has(item):
		gs.set_flag(MEDALS[item])
		gs.remove_item(item)
		gs.play("lock_open")
		var placed := placed_medals(gs)
		if placed < 3:
			gs.say("A medalha se encaixa com um estalo. Faltam %d." % (3 - placed))
		else:
			_open_coffin(gs)
		gs.commit()
		return {}
	if gs.has_flag("caixao_aberto"):
		gs.say("Terra da mina escorre da boca do coronel. Não consigo olhar de novo.")
		return {}
	return {
		"open": "zoom", "art": "caixao_zoom", "overlay": "slots",
		"data": {"torre": gs.has_flag("slot_torre"), "muleta": gs.has_flag("slot_muleta"), "sol": gs.has_flag("slot_sol")},
		"caption": "Um fecho de latão com três encaixes: uma torre, uma muleta, um sol.",
	}


static func placed_medals(gs) -> int:
	var count := 0
	for slot in MEDALS.values():
		if gs.has_flag(slot):
			count += 1
	return count


static func _open_coffin(gs) -> void:
	gs.set_flag("caixao_aberto")
	gs.play("coffin")
	gs.add_note("Na boca do coronel, terra da mina — e uma pepita de ouro.")
	gs.add_item("pepita")


static func _castical(gs, past: bool) -> Dictionary:
	if past:
		gs.say("As velas estão acesas, e ninguém parece notar que estou aqui.")
		return {}
	if gs.has_flag("velas_acesas"):
		gs.say("As velas tremem. A luz chega até o caixão.")
		return {}
	if gs.selected_item == "fosforos":
		gs.set_flag("velas_acesas")
		gs.remove_item("fosforos")
		gs.play("match")
		gs.add_note("Acendi as velas do salão. Agora há luz para fotografar.")
		gs.say("Uma a uma, as cinco velas acendem. O salão aparece — e o caixão no meio dele.")
		gs.commit()
		return {}
	gs.say("Cinco velas apagadas. O salão está escuro demais.")
	return {}


static func _parede(past: bool) -> Dictionary:
	if past:
		return {
			"open": "zoom", "overlay": "clocks4", "data": {"times": [[9, 40], [6, 5], [11, 50], [3, 17]]},
			"caption": "Em 1899, cada um marca uma hora. Só o de Celeste já está em 3h17.",
		}
	return {
		"open": "zoom", "overlay": "clocks4", "data": {"times": [[3, 17], [3, 17], [3, 17], [3, 17]]},
		"caption": "Quatro relógios, quatro plaquinhas: Joaquim, Ester, Augusto, Celeste. Todos parados em 3h17.",
	}


static func _pendulo(gs, past: bool) -> Dictionary:
	if past:
		if gs.has_flag("chave_corda_pega"):
			gs.say("O pêndulo bate firme. A porta de vidro continua aberta.")
			return {}
		gs.set_flag("chave_corda_pega")
		gs.add_note("Em 1899, a chave de corda ficava pendurada dentro do relógio de pêndulo.")
		gs.play("pickup")
		gs.add_item("chave_corda")
		gs.commit()
		return {}
	if gs.has_flag("pendulo_aberto"):
		gs.say("O pêndulo balança. Os outros quatro continuam em 3h17.")
		return {}
	if gs.selected_item == "chave_corda":
		gs.set_flag("pendulo_com_corda")
		gs.remove_item("chave_corda")
		gs.play("tick")
		gs.say("Três voltas na corda. O pêndulo hesita... e começa a bater.")
		gs.commit()
		return {"open": "clock_set"}
	if gs.has_flag("pendulo_com_corda"):
		return {"open": "clock_set"}
	gs.say("Parado, sem corda há anos. Na base, gravado: \"Marque a hora oficial.\"")
	gs.add_note("Na base do relógio de pêndulo: \"Marque a hora oficial.\"")
	gs.commit()
	return {}


static func set_clock(gs, hour: int, minute: int) -> bool:
	if hour % 12 != OFFICIAL_TIME[0] or minute != OFFICIAL_TIME[1]:
		gs.play("tick")
		gs.say("Os ponteiros ficam onde os deixei, mas nada acontece.")
		return false
	gs.set_flag("pendulo_aberto")
	gs.add_note("O atestado diz 2h40. Os relógios dizem 3h17. Alguém mentiu.")
	gs.play("chime")
	gs.say("O relógio bate duas vezes. Na base, uma gavetinha se abre.")
	gs.add_item("medalha_sol")
	gs.commit()
	return true


static func _gaveta_cima(gs, past: bool) -> Dictionary:
	if past:
		gs.say("Guardanapos bordados, ainda engomados.")
		return {}
	if gs.has_flag("fosforos_pegos"):
		gs.say("Só tocos de vela e cheiro de mofo.")
		return {}
	gs.set_flag("fosforos_pegos")
	gs.play("drawer")
	gs.add_item("fosforos")
	gs.commit()
	return {}


static func _gaveta_baixo(gs, past: bool) -> Dictionary:
	if not past:
		gs.say("Emperrada. A madeira inchou com a umidade de muitos anos.")
		return {}
	if gs.names_found.has(FATHER_INDEX):
		gs.say("Só papéis da mina e o recibo com o nome do meu pai.")
		return {}
	gs.play("drawer")
	gs.add_note("Recibo da Mina da Aurora: Tomás Vaz, perfurador. Vaz. O meu sobrenome.")
	return _find_name_once(gs, FATHER_INDEX, "Num recibo de pagamento da Mina da Aurora, 14 de agosto de 1899:")


static func _espelho(gs, past: bool) -> Dictionary:
	if not past:
		if gs.has_item("bilhete_ester"):
			gs.say("Coberto por um pano preto. Dona Ester pediu... e, por enquanto, vou respeitar.")
		else:
			gs.say("Um espelho grande, coberto por um pano preto, como manda o luto.")
		return {}
	if not gs.has_flag("viu_reflexo"):
		gs.set_flag("viu_reflexo")
		gs.add_note("No reflexo de 1899, alguém escreveu a giz na parede, ao contrário: 1408.")
		gs.commit()
	return {
		"open": "zoom", "art": "espelho_1899", "region": Rect2(700, 90, 520, 520), "overlay": "mirror",
		"caption": "No reflexo, alguém escreveu a giz na parede atrás de mim — ao contrário. Atrás da cortina, a barra de um vestido claro.",
	}


static func _find_name_once(gs, index: int, where: String) -> Dictionary:
	if gs.names_found.has(index):
		return {}
	gs.names_found.append(index)
	gs.add_note("Nome %d de 31: %s." % [gs.names_found.size(), preload("res://scripts/game/content.gd").MINERS[index]])
	gs.play("name")
	gs.commit()
	return {"open": "name", "index": index, "where": where}


static func stage(gs) -> String:
	for pair in [
		["medalha_torre_pega", "c1_coroa"], ["fosforos_pegos", "c1_fosforos"], ["velas_acesas", "c1_velas"],
		["viu_reflexo", "c1_espelho"], ["comoda_aberta", "c1_comoda"], ["chave_corda_pega", "c1_corda"],
		["pendulo_aberto", "c1_pendulo"], ["caixao_aberto", "c1_caixao"],
	]:
		if not gs.has_flag(pair[0]):
			return pair[1]
	return "fim"


static func try_code(gs, code: String) -> bool:
	if code != MIRROR_CODE:
		gs.play("lock_fail")
		gs.say("Os quatro discos giram, mas a gaveta não cede.")
		return false
	gs.set_flag("comoda_aberta")
	gs.add_note("Na cômoda: o atestado de óbito do coronel, assinado pelo filho.")
	gs.play("lock_open")
	gs.say("A gaveta do meio abre. Uma medalha e um documento dobrado.")
	gs.add_item("medalha_muleta")
	gs.add_item("atestado")
	gs.commit()
	return true
