extends RefCounted
## Design system do jogo: cores, tamanhos e estilos em um só lugar.
## Para mudar o visual da interface, mexa aqui.

const INK := Color("efe4cc")
const INK_QUIET := Color("b9a88a")
const PANEL := Color(0.10, 0.08, 0.06, 0.94)
const PANEL_PRESSED := Color(0.20, 0.15, 0.08, 0.96)
const LINE := Color("8c7350")
## O único acento: o amarelo do peito do bem-te-vi.
const ACCENT := Color("f2c230")
const DIM := Color(0, 0, 0, 0.65)

const RADIUS := 12
const FONT_BODY := 34
const FONT_TITLE := 48
const FONT_HERO := 150


static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_BODY

	t.set_color("font_color", "Label", INK)

	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_hover_pressed_color", "Button", ACCENT)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", INK_QUIET)
	t.set_stylebox("normal", "Button", box(PANEL, LINE, 2))
	t.set_stylebox("hover", "Button", box(PANEL, ACCENT, 2))
	t.set_stylebox("pressed", "Button", box(PANEL_PRESSED, ACCENT, 3))
	t.set_stylebox("hover_pressed", "Button", box(PANEL_PRESSED, ACCENT, 3))
	t.set_stylebox("disabled", "Button", box(Color(PANEL, 0.5), Color(LINE, 0.4), 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	# Botão selecionado (item ativo do inventário).
	t.add_type("SelectedButton")
	t.set_type_variation("SelectedButton", "Button")
	t.set_stylebox("normal", "SelectedButton", box(PANEL_PRESSED, ACCENT, 4))
	t.set_stylebox("hover", "SelectedButton", box(PANEL_PRESSED, ACCENT, 4))
	t.set_color("font_color", "SelectedButton", ACCENT)

	# Pontos clicáveis da cena: invisíveis, com contorno discreto ao passar o mouse.
	t.add_type("Hotspot")
	t.set_type_variation("Hotspot", "Button")
	t.set_stylebox("normal", "Hotspot", StyleBoxEmpty.new())
	t.set_stylebox("hover", "Hotspot", box(Color(1, 1, 1, 0.04), Color(ACCENT, 0.5), 2))
	t.set_stylebox("pressed", "Hotspot", box(Color(1, 1, 1, 0.08), ACCENT, 2))
	t.set_stylebox("hover_pressed", "Hotspot", box(Color(1, 1, 1, 0.08), ACCENT, 2))
	t.set_stylebox("focus", "Hotspot", StyleBoxEmpty.new())

	t.set_stylebox("panel", "PanelContainer", box(PANEL, LINE, 2, 32))
	return t


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


static func label(text: String, size: int = FONT_BODY, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, min_size: Vector2 = Vector2(0, 96)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	return b
