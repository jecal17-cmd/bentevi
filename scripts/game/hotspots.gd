extends RefCounted
## Áreas de toque, variantes de arte e efeitos por estado.
## Coordenadas em pixels da tela de referência 1920x1080, sobre a arte da cena.
## shape ("rect", "circle", "bird") só afeta a arte provisória.
## only: o ponto só existe nesse ano. Itens posteriores ficam por cima dos anteriores.

const HOTSPOTS := {
	"bilheteria": [
		{"id": "janela", "label": "Janela", "rect": Rect2(200, 70, 195, 440), "shape": "rect"},
		{"id": "quadro", "label": "Retrato", "rect": Rect2(1000, 125, 205, 160), "shape": "rect"},
		{"id": "fogao", "label": "Fogão", "rect": Rect2(1510, 110, 330, 770), "shape": "rect"},
		{"id": "gaveta", "label": "Gaveta", "rect": Rect2(1040, 560, 310, 110), "shape": "rect", "only": 1924},
		{"id": "gaveta", "label": "Gaveta", "rect": Rect2(990, 500, 370, 175), "shape": "rect", "only": 1899},
		{"id": "mala", "label": "Mala", "rect": Rect2(130, 740, 525, 140), "shape": "rect", "only": 1924},
		{"id": "nome_peitoril", "label": "", "rect": Rect2(190, 505, 230, 60), "shape": "hidden", "only": 1924},
		{"id": "nome_fogao", "label": "", "rect": Rect2(1540, 600, 150, 130), "shape": "hidden", "only": 1899},
	],
	"estacao": [
		{"id": "igreja", "label": "Igreja", "rect": Rect2(330, 290, 150, 170), "shape": "rect"},
		{"id": "relogio", "label": "", "rect": Rect2(820, 250, 300, 290), "shape": "circle"},
		{"id": "passaro", "label": "", "rect": Rect2(925, 105, 105, 85), "shape": "bird", "only": 1924},
		{"id": "casinha", "label": "Bilheteria", "rect": Rect2(1290, 260, 520, 600), "shape": "rect"},
		{"id": "banco", "label": "Banco", "rect": Rect2(860, 670, 270, 210), "shape": "rect"},
		{"id": "nome_cerca", "label": "", "rect": Rect2(70, 560, 380, 120), "shape": "hidden", "only": 1924},
		{"id": "nome_portinha", "label": "", "rect": Rect2(1585, 560, 150, 280), "shape": "hidden", "only": 1899},
	],
	"salao": [
		{"id": "janela", "label": "Janela", "rect": Rect2(780, 80, 360, 360), "shape": "rect"},
		{"id": "gaiola", "label": "Gaiola", "rect": Rect2(1180, 250, 160, 220), "shape": "rect"},
		{"id": "coroa", "label": "Coroa de flores", "rect": Rect2(230, 300, 340, 480), "shape": "circle", "only": 1924},
		{"id": "caixao", "label": "Caixão", "rect": Rect2(620, 500, 680, 240), "shape": "rect", "only": 1924},
		{"id": "mesa", "label": "Mesa posta", "rect": Rect2(620, 500, 680, 240), "shape": "rect", "only": 1899},
		{"id": "castical", "label": "Castiçal", "rect": Rect2(1420, 200, 200, 650), "shape": "rect"},
		{"id": "nome_cavalete", "label": "", "rect": Rect2(660, 760, 160, 110), "shape": "hidden", "only": 1924},
		{"id": "nome_toalha", "label": "", "rect": Rect2(1100, 700, 180, 100), "shape": "hidden", "only": 1899},
	],
	"relogios": [
		{"id": "parede", "label": "Quatro relógios", "rect": Rect2(520, 110, 760, 300), "shape": "rect"},
		{"id": "pendulo", "label": "Relógio de pêndulo", "rect": Rect2(1420, 90, 320, 780), "shape": "rect"},
		{"id": "gaveta_cima", "label": "Gaveta de cima", "rect": Rect2(160, 470, 520, 110), "shape": "rect"},
		{"id": "gaveta_meio", "label": "Gaveta do meio", "rect": Rect2(160, 595, 520, 110), "shape": "rect"},
		{"id": "gaveta_baixo", "label": "Gaveta de baixo", "rect": Rect2(160, 720, 520, 110), "shape": "rect"},
	],
	"espelho": [
		{"id": "retrato", "label": "Retrato", "rect": Rect2(150, 160, 300, 400), "shape": "rect"},
		{"id": "espelho", "label": "Espelho", "rect": Rect2(700, 90, 520, 520), "shape": "rect"},
		{"id": "aparador", "label": "Aparador", "rect": Rect2(560, 630, 800, 230), "shape": "rect"},
		{"id": "bilhete_ester", "label": "Bilhete", "rect": Rect2(860, 640, 200, 90), "shape": "rect", "only": 1924},
		{"id": "porta", "label": "Porta", "rect": Rect2(1480, 110, 320, 760), "shape": "rect"},
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
	{"view": "salao", "era": 1924, "flag": "velas_acesas", "type": "glow", "at": Vector2(1520, 260)},
	{"view": "salao", "era": 1924, "flag": "caixao_aberto", "type": "open_coffin", "rect": Rect2(620, 500, 680, 240)},
]

## Vistas escuras demais para fotografar sem a marca indicada.
const PHOTO_NEEDS := {"salao": "velas_acesas"}

## Horário no relógio da plataforma (arte provisória e zoom).
const CLOCK_TIME := {1924: [3, 17], 1899: [9, 40]}
