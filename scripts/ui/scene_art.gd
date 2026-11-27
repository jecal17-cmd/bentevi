extends Control
## Fundo da cena. Usa a imagem em assets/art/ se existir; senão desenha a arte
## provisória a partir das áreas de toque. Efeitos de estado (escuridão, luz de
## vela) ficam numa camada acima da imagem.

const Content := preload("res://scripts/game/content.gd")
const Hotspots := preload("res://scripts/game/hotspots.gd")
const ClockFace := preload("res://scripts/ui/clock_face.gd")
const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Art := preload("res://scripts/ui/art.gd")

const BG := {1924: Color("2b221b"), 1899: Color("6b5236")}
const FLOOR := {1924: Color("221a14"), 1899: Color("5a4430")}
const OBJECT_FILL := {1924: Color(0.94, 0.89, 0.8, 0.07), 1899: Color(1.0, 0.95, 0.85, 0.14)}
const OBJECT_LINE := {1924: Color(0.79, 0.66, 0.42, 0.55), 1899: Color(0.98, 0.9, 0.7, 0.8)}

var view := ""
var era := 1924
## Detalhes da arte provisória que mudam com o estado (ex.: "bilhete", "chave").
var extras: Array = []
## Efeitos de Hotspots.OVERLAYS ativos agora.
var overlays: Array = []
var _texture_rect: TextureRect
var _overlay_layer: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texture_rect)
	_overlay_layer = Control.new()
	_overlay_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.draw.connect(_draw_overlays)
	add_child(_overlay_layer)


func show_view(art_name: String, new_view: String, new_era: int, new_extras: Array, new_overlays: Array) -> void:
	view = new_view
	era = new_era
	extras = new_extras
	overlays = new_overlays
	_texture_rect.texture = Art.load_art(art_name)
	_texture_rect.visible = _texture_rect.texture != null
	queue_redraw()
	_overlay_layer.queue_redraw()


func _draw() -> void:
	if view == "" or _texture_rect.visible:
		return
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), BG[era])
	draw_rect(Rect2(0, 760, size.x, size.y - 760), FLOOR[era])
	draw_line(Vector2(0, 760), Vector2(size.x, 760), OBJECT_LINE[era], 2.0)
	draw_string(font, Vector2(24, 1050), "arte provisória", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(ThemeFactory.INK, 0.25))

	for h in Content.hotspots_for(view, era):
		var r: Rect2 = h["rect"]
		match h["shape"]:
			"hidden":
				continue
			"circle":
				if h["id"] == "relogio":
					var t: Array = Hotspots.CLOCK_TIME[era]
					draw_line(Vector2(r.get_center().x, r.end.y), Vector2(r.get_center().x, 760), OBJECT_LINE[era], 8.0)
					ClockFace.draw_clock(self, r.get_center(), r.size.x * 0.5, t[0], t[1], Color("d9c8a6") if era == 1899 else Color("a89878"))
				else:
					draw_circle(r.get_center(), minf(r.size.x, r.size.y) * 0.5, OBJECT_FILL[era])
					draw_arc(r.get_center(), minf(r.size.x, r.size.y) * 0.5, 0, TAU, 48, OBJECT_LINE[era], 3.0)
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
		draw_rect(b, ThemeFactory.INK_DARK, false, 3.0)
	if extras.has("chave"):
		draw_circle(Vector2(1070, 625), 18, Color("c9a86a"))
		draw_rect(Rect2(1086, 619, 50, 12), Color("c9a86a"))


func _draw_overlays() -> void:
	for o in overlays:
		match o["type"]:
			"dark":
				_overlay_layer.draw_rect(Rect2(Vector2.ZERO, _overlay_layer.size), Color(0.02, 0.015, 0.01, 0.5))
			"glow":
				var points: Array = o["points"]
				var c: Vector2 = points[2]
				for i in 9:
					_overlay_layer.draw_circle(c, 70.0 + i * 60.0, Color(1.0, 0.7, 0.35, 0.03))
				for p in points:
					_overlay_layer.draw_circle(p, 16, Color(1.0, 0.75, 0.35, 0.35))
					_overlay_layer.draw_circle(p, 7, Color(1.0, 0.9, 0.6, 0.95))
			"open_coffin":
				var r: Rect2 = o["rect"]
				_overlay_layer.draw_rect(Rect2(r.position + Vector2(40, 20), Vector2(r.size.x - 80, r.size.y * 0.45)), Color(0.05, 0.03, 0.02, 0.85))


func _draw_bird(r: Rect2) -> void:
	var c := r.get_center()
	draw_circle(c + Vector2(-6, 8), r.size.y * 0.42, ThemeFactory.ACCENT)
	draw_circle(c + Vector2(22, -10), r.size.y * 0.3, Color("1b140f"))
	draw_line(c + Vector2(8, -14), c + Vector2(40, -14), ThemeFactory.INK, 4.0)
	draw_line(c + Vector2(38, -8), c + Vector2(56, -4), Color("1b140f"), 5.0)
