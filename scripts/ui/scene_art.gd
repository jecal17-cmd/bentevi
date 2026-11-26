extends Control
## Fundo da cena. Usa a imagem final se existir em assets/art/<vista>_<ano>.png;
## senão desenha a arte provisória a partir dos pontos clicáveis.

const Content := preload("res://scripts/game/content.gd")
const ClockFace := preload("res://scripts/ui/clock_face.gd")
const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Art := preload("res://scripts/ui/art.gd")

const BG := {1924: Color("2b221b"), 1899: Color("6b5236")}
const FLOOR := {1924: Color("221a14"), 1899: Color("5a4430")}
const OBJECT_FILL := {1924: Color(0.94, 0.89, 0.8, 0.07), 1899: Color(1.0, 0.95, 0.85, 0.14)}
const OBJECT_LINE := {1924: Color(0.79, 0.66, 0.42, 0.55), 1899: Color(0.98, 0.9, 0.7, 0.8)}

var view := ""
var era := 1924
## Detalhes que mudam com o estado (ex.: "bilhete", "chave").
var extras: Array = []
var _texture_rect: TextureRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texture_rect)


func show_view(new_view: String, new_era: int, new_extras: Array) -> void:
	view = new_view
	era = new_era
	extras = new_extras
	_texture_rect.texture = Art.load_art("%s_%d" % [view, era])
	_texture_rect.visible = _texture_rect.texture != null
	queue_redraw()


func _draw() -> void:
	if view == "" or _texture_rect.visible:
		return
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), BG[era])
	draw_rect(Rect2(0, 760, size.x, size.y - 760), FLOOR[era])
	draw_line(Vector2(0, 760), Vector2(size.x, 760), OBJECT_LINE[era], 2.0)

	for h in Content.hotspots_for(view, era):
		var r: Rect2 = h["rect"]
		match h["shape"]:
			"circle":
				var t: Array = Content.CLOCK_TIME[era]
				draw_line(Vector2(r.get_center().x, r.end.y), Vector2(r.get_center().x, 760), OBJECT_LINE[era], 8.0)
				ClockFace.draw_clock(self, r.get_center(), r.size.x * 0.5, t[0], t[1], Color("d9c8a6") if era == 1899 else Color("a89878"))
			"bird":
				_draw_bird(r)
			_:
				draw_rect(r, OBJECT_FILL[era])
				draw_rect(r, OBJECT_LINE[era], false, 3.0)
		if h["label"] != "":
			draw_string(font, Vector2(r.position.x, r.position.y + r.size.y * 0.5 + 12), h["label"], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 32, Color(ThemeFactory.INK, 0.85))

	if extras.has("bilhete"):
		var b := Rect2(1040, 670, 110, 56)
		draw_rect(b, Color("efe4cc"))
		draw_rect(b, ThemeFactory.ACCENT, false, 3.0)
	if extras.has("chave"):
		draw_circle(Vector2(1070, 625), 18, ThemeFactory.ACCENT)
		draw_rect(Rect2(1086, 619, 50, 12), ThemeFactory.ACCENT)
	if extras.has("fogo"):
		draw_circle(Vector2(1630, 760), 60, Color(1.0, 0.55, 0.2, 0.55))


func _draw_bird(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c + Vector2(-6, 8), r.size.y * 0.42, ThemeFactory.ACCENT)
	draw_circle(c + Vector2(22, -10), r.size.y * 0.3, Color("1b140f"))
	draw_line(c + Vector2(8, -14), c + Vector2(40, -14), ThemeFactory.INK, 4.0)
	draw_line(c + Vector2(38, -8), c + Vector2(56, -4), Color("1b140f"), 5.0)
