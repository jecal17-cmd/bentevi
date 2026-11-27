extends RefCounted
## Design system do jogo: cores, fontes, tamanhos e estilos em um só lugar.
## Para mudar o visual da interface, mexa aqui.

const INK := Color("efe4cc")
const INK_QUIET := Color("b9a88a")
const INK_DARK := Color("2b221b")
const PAPER := Color("efe4cc")
const PANEL := Color(0.10, 0.08, 0.06, 0.94)
const PANEL_RAISED := Color(0.22, 0.17, 0.12, 0.97)
const LINE := Color("8c7350")
## O único acento: o amarelo do peito do bem-te-vi. Reservado à marca e ao pássaro;
## seleção e foco usam o creme (INK), para não competir com ele.
const ACCENT := Color("f2c230")
const DIM := Color(0, 0, 0, 0.7)

const RADIUS := 12
const FONT_BODY := 38
const FONT_BODY_LARGE := 46
const FONT_TITLE := 52
const FONT_HERO := 160

const FONT_REGULAR := preload("res://assets/fonts/CrimsonText-Regular.ttf")
const FONT_SEMIBOLD := preload("res://assets/fonts/CrimsonText-SemiBold.ttf")
const FONT_ITALIC := preload("res://assets/fonts/CrimsonText-Italic.ttf")


static func build(large_text: bool = false) -> Theme:
	var t := Theme.new()
	t.default_font = FONT_REGULAR
	t.default_font_size = FONT_BODY_LARGE if large_text else FONT_BODY

	t.set_color("font_color", "Label", INK)

	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_hover_pressed_color", "Button", INK)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK_QUIET, 0.6))
	t.set_stylebox("normal", "Button", box(PANEL, LINE, 2))
	t.set_stylebox("hover", "Button", box(PANEL, INK_QUIET, 2))
	t.set_stylebox("pressed", "Button", box(PANEL_RAISED, INK, 3))
	t.set_stylebox("hover_pressed", "Button", box(PANEL_RAISED, INK, 3))
	t.set_stylebox("disabled", "Button", box(Color(PANEL, 0.5), Color(LINE, 0.35), 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	# Item ativo do inventário: moldura creme e fundo mais claro, sem amarelo.
	t.add_type("SelectedButton")
	t.set_type_variation("SelectedButton", "Button")
	t.set_stylebox("normal", "SelectedButton", box(PANEL_RAISED, INK, 4))
	t.set_stylebox("hover", "SelectedButton", box(PANEL_RAISED, INK, 4))
	t.set_stylebox("pressed", "SelectedButton", box(PANEL_RAISED, INK, 4))

	# Pontos clicáveis: invisíveis; contorno creme discreto com mouse.
	t.add_type("Hotspot")
	t.set_type_variation("Hotspot", "Button")
	t.set_stylebox("normal", "Hotspot", StyleBoxEmpty.new())
	t.set_stylebox("hover", "Hotspot", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "Hotspot", StyleBoxEmpty.new())
	t.set_stylebox("hover_pressed", "Hotspot", StyleBoxEmpty.new())
	t.set_stylebox("focus", "Hotspot", StyleBoxEmpty.new())

	t.set_stylebox("panel", "PanelContainer", box(PANEL, LINE, 2, 32))

	# Barras de volume.
	var track := box(Color(INK_QUIET, 0.25), Color(0, 0, 0, 0), 0, 6)
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", box(Color(INK, 0.6), Color(0, 0, 0, 0), 0, 6))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(INK, Color(0, 0, 0, 0), 0, 6))
	t.set_color("font_color", "CheckButton", INK)
	t.set_color("font_hover_color", "CheckButton", INK)
	t.set_color("font_pressed_color", "CheckButton", INK)
	t.set_color("font_hover_pressed_color", "CheckButton", INK)
	return t


## Estilo do contorno quando o jogador liga "Mostrar áreas de toque".
static func hotspot_hint_style() -> StyleBoxFlat:
	return box(Color(1, 1, 1, 0.05), Color(INK, 0.55), 2)


static func paper_style() -> StyleBoxFlat:
	var s := box(PAPER, Color("8c7350"), 2, 40)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 18
	return s


static func box(bg: Color, border: Color, width: int, pad: int = 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(RADIUS)
	s.content_margin_left = pad + 8
	s.content_margin_right = pad + 8
	s.content_margin_top = pad
	s.content_margin_bottom = pad
	return s


## size 0 = tamanho padrão do tema (acompanha a opção "texto grande").
static func label(text: String, size: int = 0, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	if size >= FONT_TITLE:
		l.add_theme_font_override("font", FONT_SEMIBOLD)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func title(text: String, size: int = FONT_TITLE) -> Label:
	var l := label(text, size)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


## Altura mínima de toque: 112 px de 1080 ≈ 48 dp num celular comum na horizontal.
const TOUCH_MIN := 112.0


static func button(text: String, min_size: Vector2 = Vector2(0, TOUCH_MIN)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_size.x, maxf(min_size.y, TOUCH_MIN))
	b.focus_mode = Control.FOCUS_NONE
	return b
