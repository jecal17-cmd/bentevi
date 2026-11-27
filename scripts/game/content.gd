extends RefCounted
## Conteúdo do jogo: capítulos, vistas, itens, dicas e os 31 mineiros.
## Posições das áreas de toque ficam em hotspots.gd.

const Hotspots := preload("res://scripts/game/hotspots.gd")

const CHAPTERS := {
	0: {"title": "Prólogo — A Estação", "start_view": "bilheteria", "plates": 3},
	1: {"title": "Capítulo 1 — O Velório", "start_view": "salao", "plates": 3},
	2: {"title": "Capítulo 2 — A Botica", "start_view": "", "plates": 3},
}
const LAST_PLAYABLE_CHAPTER := 1

## Vistas de cada capítulo formam um anel: as setas giram entre elas.
const VIEWS := {
	"bilheteria": {"chapter": 0, "title": "Bilheteria", "next": "estacao", "prev": "estacao"},
	"estacao": {"chapter": 0, "title": "Plataforma", "next": "bilheteria", "prev": "bilheteria"},
	"salao": {"chapter": 1, "title": "Salão do velório", "next": "relogios", "prev": "espelho"},
	"relogios": {"chapter": 1, "title": "Parede dos relógios", "next": "espelho", "prev": "salao"},
	"espelho": {"chapter": 1, "title": "Espelho", "next": "salao", "prev": "relogios"},
}

## doc: true = documento, mostrado como papel. back = o que há no verso.
const ITEMS := {
	"camera": {"name": "Câmera", "desc": "Minha câmera de fole. Cada chapa guarda um lugar como ele é... ou como foi."},
	"bilhete": {
		"name": "Bilhete", "doc": true,
		"desc": "Estrada de Ferro Oeste de Minas.\nRio de Janeiro → São Lázaro das Cinzas.\n14 de agosto de 1899.\nPassageira: Lúcia Vaz, 7 anos.",
		"back": "No verso, a lápis:\n\"Assento 14. Acompanhante: C. Monteverde.\"",
	},
	"chave": {"name": "Chave", "desc": "Uma chave de latão. Em 1899 ela ainda brilhava."},
	"carta": {
		"name": "Carta", "doc": true,
		"desc": "Não há tinta. A mensagem foi bordada em linha amarela:\n\n\"O bem-te-vi viu.\nVolte para casa.\n— C.\"",
		"back": "No avesso do bordado, um pequeno pássaro de peito amarelo... e um número em ponto-cruz: 14.",
	},
	"bilhete_ester": {
		"name": "Recado de Ester", "short": "Recado", "doc": true,
		"desc": "\"Seja bem-vinda, senhora Vaz.\nA família repousa.\nPor respeito ao meu marido,\nnão descubra o espelho.\n— Ester Monteverde\"",
	},
	"fosforos": {"name": "Fósforos", "desc": "Uma caixa de fósforos de pau. Restam poucos."},
	"medalha_torre": {"name": "Medalha (torre)", "short": "Torre", "desc": "Medalha de Santa Bárbara, padroeira dos mineiros. Uma torre gravada."},
	"medalha_muleta": {"name": "Medalha (muleta)", "short": "Muleta", "desc": "Medalha de São Lázaro. Uma muleta gravada. Fria, como se ninguém a tocasse há anos."},
	"medalha_sol": {"name": "Medalha (sol)", "short": "Sol", "desc": "Medalha de Nossa Senhora da Aurora. Um sol nascente — o mesmo nome da mina."},
	"atestado": {
		"name": "Atestado", "doc": true,
		"desc": "ATESTADO DE ÓBITO\nJoaquim Monteverde, 71 anos.\nCausa: o coração.\nHora oficial: 2h40.\n\nDr. Augusto Monteverde, médico e filho.",
		"back": "No verso, outra letra, tremida:\n\"Os relógios não mentem.\"",
	},
	"chave_corda": {"name": "Chave de corda", "short": "Corda", "desc": "Chave de dar corda, de latão. Veio de 1899 e ainda está morna."},
	"pepita": {"name": "Pepita", "desc": "Uma pepita de ouro coberta de terra escura. Terra da Mina da Aurora."},
}

## Onde cada item pode ser usado (id do ponto de toque).
const ITEM_TARGETS := {
	"chave": ["gaveta"],
	"fosforos": ["castical"],
	"medalha_torre": ["caixao"],
	"medalha_muleta": ["caixao"],
	"medalha_sol": ["caixao"],
	"chave_corda": ["pendulo"],
}

## Os 31 mineiros da Mina da Aurora (fictícios). O jogo completo esconde todos.
const MINERS := [
	"José Firmino da Silva, 34 anos, britador", "Benedito Alves, 41 anos, carregador",
	"Antônio Ribeiro, o Tonico, 19 anos, ajudante", "Sebastião Moreira, 52 anos, capataz",
	"Joaquim Pereira Lima, 28 anos, perfurador", "Raimundo Nonato, 37 anos, foguista",
	"Francisco das Chagas, 23 anos, carregador", "Manoel Bento, 45 anos, britador",
	"Luiz Gonzaga Prado, 31 anos, ferreiro", "Pedro Cândido, 26 anos, perfurador",
	"João Batista Cruz, 39 anos, madeireiro", "Geraldo Souza, 17 anos, ajudante",
	"Cícero Antunes, 48 anos, britador", "Domingos Ferreira, 33 anos, carregador",
	"Tomás Vaz, 36 anos, perfurador", "Vicente Paulo, 29 anos, foguista",
	"Expedito Gomes, 44 anos, carregador", "Olímpio Barbosa, 50 anos, britador",
	"Severino Matos, 22 anos, ajudante", "Belmiro Castro, 38 anos, madeireiro",
	"Lázaro Santana, 27 anos, perfurador", "Inácio Rocha, 35 anos, carregador",
	"Zacarias Lopes, 42 anos, britador", "Firmino Teles, 30 anos, ferreiro",
	"Bernardino Reis, 46 anos, carregador", "Agenor Dias, 24 anos, perfurador",
	"Hilário Campos, 55 anos, capataz", "Teodoro Nunes, 32 anos, foguista",
	"Valdomiro Assis, 20 anos, ajudante", "Arlindo Prates, 40 anos, britador",
	"Cândido Mendes, 18 anos, ajudante",
]

## Pontos escondidos com nomes: id → [índice do mineiro, onde estava escrito].
const NAME_SPOTS := {
	"nome_cerca": [0, "Riscado a canivete na cerca:"],
	"nome_portinha": [1, "Escrito a giz na porta da bilheteria:"],
	"nome_peitoril": [2, "Riscado no peitoril da janela:"],
	"nome_fogao": [3, "Gravado na porta do fogão, ainda quente:"],
	"nome_cavalete": [4, "Entalhado no cavalete do caixão:"],
	"nome_toalha": [5, "Bordado na barra da toalha:"],
}

## Três níveis por etapa: um empurrão, uma direção, a solução.
const HINTS := {
	"mala": ["O relógio lá fora parou numa hora estranha.", "A mala pede três números. Que horas o relógio marca?", "Abra a mala com o código 3-1-7."],
	"fotografar": ["Minha câmera guarda lugares. Talvez guarde mais do que isso.", "Toque em Fotografar para gastar uma chapa neste lugar.", "Vá até a plataforma e toque em Fotografar."],
	"revelar": ["A chapa guardou o lugar, mas a imagem ainda está escondida.", "Abra o Álbum e toque em Revelar.", "Na câmara escura, toque em Retirar quando o marcador estiver na faixa clara."],
	"bilhete": ["O banco da plataforma já foi novo um dia.", "Revele a foto da plataforma e entre nela.", "Dentro da foto de 1899, toque no bilhete sobre o banco."],
	"chave": ["A gaveta da bilheteria nem sempre esteve trancada.", "Fotografe a bilheteria, revele a chapa e entre na foto.", "Em 1899, toque na chave sobre o balcão."],
	"gaveta": ["Uma chave antiga para uma gaveta antiga.", "Volte para 1924 e toque na chave no inventário.", "Com a chave selecionada, toque na gaveta da bilheteria."],
	"c1_coroa": ["Flores de velório guardam mais do que saudade.", "Olhe de perto a coroa de flores.", "Na coroa, toque em Pegar a medalha."],
	"c1_fosforos": ["O salão está escuro demais. Onde se guardam fósforos numa casa assim?", "A cômoda da parede dos relógios tem três gavetas.", "Abra a gaveta de cima da cômoda."],
	"c1_velas": ["Sem luz, a câmera não guarda nada.", "Selecione os fósforos no inventário.", "Com os fósforos selecionados, toque no castiçal."],
	"c1_espelho": ["Ela pediu para não descobrir o espelho. Em 1899 ninguém pediu nada.", "Fotografe o espelho, revele e entre na foto.", "Em 1899, toque no espelho e leia o que está escrito no reflexo."],
	"c1_comoda": ["Números escritos ao contrário, vistos num espelho.", "No reflexo, lê-se 1408 — a data do bilhete: 14 de agosto.", "Na gaveta do meio da cômoda, use o código 1-4-0-8."],
	"c1_corda": ["O relógio grande está sem corda há 25 anos.", "Fotografe a parede dos relógios e entre na foto.", "Em 1899, toque no relógio de pêndulo e pegue a chave de corda."],
	"c1_pendulo": ["Na base do relógio: \"Marque a hora oficial.\"", "A hora oficial está num documento assinado pelo filho.", "Dê corda no pêndulo e acerte os ponteiros em 2h40."],
	"c1_caixao": ["Três medalhas, três encaixes.", "Selecione uma medalha e toque no caixão. Repita com as outras.", "Use as medalhas da torre, da muleta e do sol no fecho do caixão."],
	"fim": ["Bem-te-vi! Escute...", "Bem-te-vi! Alguém está vindo.", "Bem-te-vi! Não há mais nada aqui."],
}

const CREDITS := [
	"BENTEVI — O pássaro viu tudo",
	"Uma produção Bentevi Apps.",
	"Roteiro, programação e sons provisórios: Bentevi Apps com Claude.",
	"Arte de protótipo gerada com Nano Banana. A arte final será desenhada à mão.",
	"Fonte: Crimson Text (SIL Open Font License).",
	"Feito com o motor Godot.",
	"Em memória dos trabalhadores das minas de Minas Gerais.",
]


static func item_name(id: String) -> String:
	return ITEMS.get(id, {}).get("name", id)


## Nome curto para o espaço do inventário quando o item ainda não tem ícone.
static func item_short(id: String) -> String:
	return ITEMS.get(id, {}).get("short", item_name(id))


static func item_desc(id: String) -> String:
	return ITEMS.get(id, {}).get("desc", "")


static func item_back(id: String) -> String:
	return ITEMS.get(id, {}).get("back", "")


static func is_document(id: String) -> bool:
	return ITEMS.get(id, {}).get("doc", false)


static func view_title(view: String) -> String:
	return VIEWS.get(view, {}).get("title", view)


static func chapter_title(chapter: int) -> String:
	return CHAPTERS.get(chapter, {}).get("title", "")


static func hotspots_for(view: String, era: int) -> Array:
	var result: Array = []
	for h in Hotspots.HOTSPOTS.get(view, []):
		if h.has("only") and h["only"] != era:
			continue
		result.append(h)
	return result


static func can_use_on(item: String, target: String) -> bool:
	return ITEM_TARGETS.get(item, []).has(target)
