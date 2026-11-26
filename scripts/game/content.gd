extends RefCounted
## Conteúdo do prólogo: itens, vistas, pontos clicáveis e dicas.
## Coordenadas em pixels da tela de referência 1920x1080.
## Ao trocar a arte provisória pela final, ajuste só os retângulos daqui.

const ITEMS := {
	"camera": {
		"name": "Câmera",
		"desc": "Minha câmera de fole. Cada chapa guarda um lugar como ele é... ou como foi.",
	},
	"bilhete": {
		"name": "Bilhete",
		"desc": "Rio de Janeiro → São Lázaro das Cinzas. 14 de agosto de 1899. Passageira: Lúcia Vaz, 7 anos. Esse é o meu nome.",
	},
	"chave": {
		"name": "Chave",
		"desc": "Uma chave de latão. Em 1899 ela ainda brilhava.",
	},
	"carta": {
		"name": "Carta",
		"desc": "Não há tinta. A mensagem foi bordada em linha amarela: \"O bem-te-vi viu. Volte para casa. — C.\"",
	},
}

const VIEWS := {
	"bilheteria": {"title": "Bilheteria", "next": "estacao"},
	"estacao": {"title": "Plataforma", "next": "bilheteria"},
}

## shape: "rect", "circle" ou "bird" — usado só pela arte provisória.
## only: o ponto só existe nesse ano.
const HOTSPOTS := {
	"bilheteria": [
		{"id": "janela", "label": "Janela", "rect": Rect2(200, 70, 195, 440), "shape": "rect"},
		{"id": "quadro", "label": "Retrato", "rect": Rect2(1000, 125, 205, 160), "shape": "rect"},
		{"id": "fogao", "label": "Fogão", "rect": Rect2(1510, 110, 330, 770), "shape": "rect"},
		{"id": "gaveta", "label": "Gaveta", "rect": Rect2(1040, 560, 310, 110), "shape": "rect", "only": 1924},
		{"id": "gaveta", "label": "Gaveta", "rect": Rect2(990, 500, 370, 175), "shape": "rect", "only": 1899},
		{"id": "mala", "label": "Mala", "rect": Rect2(130, 740, 525, 140), "shape": "rect", "only": 1924},
	],
	"estacao": [
		{"id": "igreja", "label": "Igreja", "rect": Rect2(330, 290, 150, 170), "shape": "rect"},
		{"id": "relogio", "label": "", "rect": Rect2(820, 250, 300, 290), "shape": "circle"},
		{"id": "passaro", "label": "", "rect": Rect2(925, 105, 105, 85), "shape": "bird", "only": 1924},
		{"id": "casinha", "label": "Bilheteria", "rect": Rect2(1290, 260, 520, 600), "shape": "rect"},
		{"id": "banco", "label": "Banco", "rect": Rect2(860, 670, 270, 210), "shape": "rect"},
	],
}

## Horário mostrado no relógio da plataforma em cada ano.
const CLOCK_TIME := {1924: [3, 17], 1899: [9, 40]}

## Três níveis por etapa: um empurrão, uma direção, a solução.
const HINTS := {
	"mala": [
		"O relógio lá fora parou numa hora estranha.",
		"A mala pede três números. Que horas o relógio marca?",
		"Abra a mala com o código 3-1-7.",
	],
	"fotografar": [
		"Minha câmera guarda lugares. Talvez guarde mais do que isso.",
		"Toque em Fotografar para gastar uma chapa neste lugar.",
		"Vá até a plataforma e toque em Fotografar.",
	],
	"revelar": [
		"A chapa guardou o lugar, mas a imagem ainda está escondida.",
		"Abra o Álbum e toque em Revelar.",
		"Na câmara escura, toque em Retirar quando o marcador estiver na faixa amarela.",
	],
	"bilhete": [
		"O banco da plataforma já foi novo um dia.",
		"Revele a foto da plataforma e entre nela.",
		"Dentro da foto de 1899, toque no bilhete sobre o banco.",
	],
	"chave": [
		"A gaveta da bilheteria nem sempre esteve trancada.",
		"Fotografe a bilheteria, revele a chapa e entre na foto.",
		"Em 1899, toque na gaveta aberta e pegue a chave.",
	],
	"gaveta": [
		"Uma chave antiga para uma gaveta antiga.",
		"Volte para 1924 e toque na chave no inventário.",
		"Com a chave selecionada, toque na gaveta da bilheteria.",
	],
	"fim": [
		"Bem-te-vi! Escute... um apito de trem.",
		"Bem-te-vi! Alguém chegou para buscar você.",
		"Bem-te-vi! Não há mais nada aqui.",
	],
}


static func item_name(id: String) -> String:
	return ITEMS.get(id, {}).get("name", id)


static func item_desc(id: String) -> String:
	return ITEMS.get(id, {}).get("desc", "")


static func view_title(view: String) -> String:
	return VIEWS.get(view, {}).get("title", view)


static func hotspots_for(view: String, era: int) -> Array:
	var result: Array = []
	for h in HOTSPOTS.get(view, []):
		if h.has("only") and h["only"] != era:
			continue
		result.append(h)
	return result
