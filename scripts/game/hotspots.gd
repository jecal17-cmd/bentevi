extends RefCounted
## Áreas de toque, variantes de arte e efeitos por estado.
## Coordenadas em pixels da tela de referência 1920x1080, sobre a arte da cena.
## shape ("rect", "circle", "bird") só afeta a arte provisória.
## only: o ponto só existe nesse ano. Itens posteriores ficam por cima dos anteriores.

const HOTSPOTS := {
	"bilheteria": [
		{"id": "janela", "label": "Janela", "rect": Rect2(127, 29, 214, 482), "shape": "rect"},
		{"id": "quadro", "label": "Retrato", "rect": Rect2(1004, 89, 225, 175), "shape": "rect"},
		{"id": "fogao", "label": "Fogão", "rect": Rect2(1564, 72, 356, 844), "shape": "rect"},
		{"id": "gaveta", "label": "Gaveta", "rect": Rect2(1048, 566, 340, 121), "shape": "rect", "only": 1924},
		{"id": "gaveta", "label": "Gaveta", "rect": Rect2(993, 500, 406, 192), "shape": "rect", "only": 1899},
		{"id": "mala", "label": "Mala", "rect": Rect2(50, 763, 576, 154), "shape": "rect", "only": 1924},
		{"id": "nome_peitoril", "label": "", "rect": Rect2(116, 505, 252, 66), "shape": "hidden", "only": 1924},
		{"id": "nome_fogao", "label": "", "rect": Rect2(1596, 610, 164, 143), "shape": "hidden", "only": 1899},
	],
	"estacao": [
		{"id": "igreja", "label": "Igreja", "rect": Rect2(255, 255, 168, 190), "shape": "rect"},
		{"id": "relogio", "label": "", "rect": Rect2(802, 210, 335, 324), "shape": "circle"},
		{"id": "passaro", "label": "", "rect": Rect2(920, 48, 117, 95), "shape": "bird", "only": 1924},
		{"id": "casinha", "label": "Bilheteria", "rect": Rect2(1328, 221, 581, 671), "shape": "rect"},
		{"id": "banco", "label": "Banco", "rect": Rect2(847, 680, 302, 235), "shape": "rect"},
		{"id": "nome_cerca", "label": "", "rect": Rect2(0, 624, 335, 145), "shape": "hidden", "only": 1924},
		{"id": "nome_portinha", "label": "", "rect": Rect2(1658, 557, 168, 313), "shape": "hidden", "only": 1899},
	],
	"salao": [
		{"id": "janela", "label": "Janela", "rect": Rect2(1000, 60, 400, 470), "shape": "rect"},
		{"id": "gaiola", "label": "Gaiola", "rect": Rect2(690, 270, 200, 260), "shape": "rect"},
		{"id": "coroa", "label": "Coroa de flores", "rect": Rect2(120, 170, 460, 570), "shape": "circle", "only": 1924},
		{"id": "caixao", "label": "Caixão", "rect": Rect2(600, 610, 880, 210), "shape": "rect", "only": 1924},
		{"id": "mesa", "label": "Mesa posta", "rect": Rect2(560, 580, 1090, 180), "shape": "rect", "only": 1899},
		{"id": "castical", "label": "Castiçal", "rect": Rect2(1510, 260, 250, 620), "shape": "rect"},
		{"id": "nome_cavalete", "label": "", "rect": Rect2(690, 820, 200, 60), "shape": "hidden", "only": 1924},
		{"id": "nome_toalha", "label": "", "rect": Rect2(1450, 650, 160, 70), "shape": "hidden", "only": 1899},
	],
	"relogios": [
		{"id": "parede", "label": "Cinco relógios", "rect": Rect2(501, 81, 797, 470), "shape": "rect"},
		{"id": "pendulo", "label": "Relógio de pêndulo", "rect": Rect2(1386, 26, 404, 885), "shape": "rect", "only": 1924},
		{"id": "pendulo", "label": "Relógio de pêndulo", "rect": Rect2(1386, 26, 448, 885), "shape": "rect", "only": 1899},
		{"id": "gaveta_cima", "label": "Gaveta de cima", "rect": Rect2(86, 643, 459, 98), "shape": "rect"},
		{"id": "gaveta_meio", "label": "Gaveta do meio", "rect": Rect2(86, 752, 459, 98), "shape": "rect"},
		{"id": "gaveta_baixo", "label": "Gaveta de baixo", "rect": Rect2(86, 857, 459, 63), "shape": "rect"},
	],
	"espelho": [
		{"id": "retrato", "label": "Retrato", "rect": Rect2(170, 155, 290, 375), "shape": "rect"},
		{"id": "espelho", "label": "Espelho", "rect": Rect2(620, 40, 475, 550), "shape": "rect"},
		{"id": "aparador", "label": "Aparador", "rect": Rect2(470, 615, 785, 265), "shape": "rect"},
		{"id": "bilhete_ester", "label": "Recado", "rect": Rect2(780, 600, 140, 70), "shape": "rect", "only": 1924},
		{"id": "porta", "label": "Porta", "rect": Rect2(1320, 110, 460, 770), "shape": "rect"},
	],
}

## Arte alternativa quando algo muda na cena (ex.: item pego).
const ART_VARIANTS := [
	{"view": "estacao", "era": 1899, "flag": "bilhete_pego", "art": "estacao_1899_sem_bilhete"},
	{"view": "bilheteria", "era": 1899, "flag": "chave_pega", "art": "bilheteria_1899_sem_chave"},
]

## Efeitos desenhados por cima da cena. flag = só com a marca; unless = só sem ela.
const OVERLAYS := [
	{"view": "salao", "era": 1924, "unless": "velas_acesas", "type": "dark"},
	{"view": "salao", "era": 1924, "flag": "velas_acesas", "type": "glow",
		"points": [Vector2(1533, 330), Vector2(1580, 322), Vector2(1633, 288), Vector2(1693, 330), Vector2(1733, 325)]},
	{"view": "salao", "era": 1924, "flag": "caixao_aberto", "type": "open_coffin", "rect": Rect2(620, 615, 840, 120)},
]

## Área do vidro do espelho em espelho_1899 (usada no zoom do reflexo).
const MIRROR_GLASS := Rect2(720, 150, 275, 370)

## Vistas escuras demais para fotografar sem a marca indicada.
const PHOTO_NEEDS := {"salao": "velas_acesas"}

## Horário no relógio da plataforma (arte provisória e zoom).
const CLOCK_TIME := {1924: [3, 17], 1899: [9, 40]}
