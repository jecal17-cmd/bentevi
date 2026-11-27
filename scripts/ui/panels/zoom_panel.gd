extends PanelContainer
## Detalhe ampliado. Mostra a arte (ou um recorte dela) e, por cima, o que precisa
## ser legível ou mudar com o estado, desenhado em código: a fita da coroa, os
## encaixes do caixão, o número espelhado e os cinco relógios.
## params: art, region (Rect2), caption, clock [h, m], overlay, data, action {label, id}

signal closed
signal action(id: String)

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const ClockFace := preload("res://scripts/ui/clock_face.gd")
const Art := preload("res://scripts/ui/art.gd")

const VIEW_SIZE := Vector2(1100, 620)
const CLOCK_NAMES := ["Joaquim", "Ester", "Augusto", "Celeste", "L."]

var params: Dictionary = {}
var _canvas: Control


func setup(new_params: Dictionary) -> void:
	params = new_params


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	add_child(v)

	var frame := Control.new()
	frame.custom_minimum_size = VIEW_SIZE
	frame.clip_contents = true
	v.add_child(frame)
	var tex := _texture()
	if tex != null:
		var image := TextureRect.new()
		image.texture = tex
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if params.get("overlay", "") == "mirror" else TextureRect.STRETCH_KEEP_ASPECT_COVERED
		frame.add_child(image)
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_canvas.bind(tex != null))
	frame.add_child(_canvas)

	var text := ThemeFactory.label(params.get("caption", ""))
	text.custom_minimum_size = Vector2(VIEW_SIZE.x, 0)
	v.add_child(text)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 20)
	v.add_child(actions)
	if params.has("action"):
		var act: Dictionary = params["action"]
		var b := ThemeFactory.button(act["label"], Vector2(320, 96))
		b.pressed.connect(func(): action.emit(act["id"]))
		actions.add_child(b)
	var back := ThemeFactory.button("Voltar", Vector2(220, 96))
	back.pressed.connect(closed.emit)
	actions.add_child(back)


func _texture() -> Texture2D:
	var art_name: String = params.get("art", "")
	if art_name == "":
		return null
	var tex := Art.load_art(art_name)
	if tex == null or not params.has("region"):
		return tex
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = params["region"]
	return atlas


func _draw_canvas(has_art: bool) -> void:
	var size := _canvas.size
	var overlay: String = params.get("overlay", "")
	if not has_art:
		_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color("3a2e24"))
		if params.has("clock"):
			var t: Array = params["clock"]
			ClockFace.draw_clock(_canvas, size * 0.5, size.y * 0.42, t[0], t[1], Color("d9c8a6"))
	match overlay:
		"ribbon":
			_draw_ribbon(size, has_art)
		"slots":
			_draw_slots(size, has_art)
		"mirror":
			_draw_mirror(size, has_art)
		"clocks":
			_draw_clocks(size)


func _draw_ribbon(size: Vector2, has_art: bool) -> void:
	var font := ThemeFactory.FONT_ITALIC
	if not has_art:
		for i in 14:
			var a := TAU * i / 14.0
			_canvas.draw_circle(size * 0.5 + Vector2(cos(a), sin(a)) * 220, 48, Color("d9cfb8", 0.8))
		if params.has("action"):
			_canvas.draw_circle(size * 0.5 + Vector2(150, -120), 26, Color("c0c4c8"))
	if has_art:
		# A fita já está na arte: só escrevemos sobre ela, acompanhando a inclinação.
		_canvas.draw_set_transform(Vector2(551, 367), -0.12, Vector2.ONE)
		_canvas.draw_string(font, Vector2(-330, 12), "Saudades eternas — Ester, Augusto e Celeste",
			HORIZONTAL_ALIGNMENT_CENTER, 660, 34, Color(0.18, 0.1, 0.06, 0.92))
		_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var band := Rect2(0, size.y * 0.62, size.x, 90)
	_canvas.draw_rect(band, Color(0.94, 0.9, 0.8, 0.88))
	_canvas.draw_string(font, Vector2(0, band.get_center().y + 16), "Saudades eternas — Ester, Augusto e Celeste",
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 46, ThemeFactory.INK_DARK)


func _draw_slots(size: Vector2, has_art: bool) -> void:
	var data: Dictionary = params.get("data", {})
	var keys := ["torre", "muleta", "sol"]
	if has_art:
		# Os encaixes vazios estão na arte; desenhamos só as medalhas já colocadas.
		var centers := [Vector2(388, 410), Vector2(551, 410), Vector2(715, 410)]
		for i in 3:
			if data.get(keys[i], false):
				_canvas.draw_circle(centers[i], 63, Color(0.76, 0.78, 0.8))
				_canvas.draw_arc(centers[i], 63, 0, TAU, 48, Color(0.5, 0.52, 0.55), 4.0)
				_canvas.draw_arc(centers[i], 50, 0, TAU, 48, Color(0.9, 0.91, 0.92, 0.7), 2.0)
				_draw_symbol(keys[i], centers[i], Color("2b221b"))
		return
	_canvas.draw_rect(Rect2(size.x * 0.1, size.y * 0.3, size.x * 0.8, size.y * 0.4), Color("8a6a3a"))
	for i in 3:
		var c := Vector2(size.x * (0.27 + 0.23 * i), size.y * 0.5)
		var filled: bool = data.get(keys[i], false)
		_canvas.draw_circle(c, 70, Color(0.75, 0.77, 0.8, 0.95) if filled else Color(0.08, 0.05, 0.03, 0.85))
		_canvas.draw_arc(c, 70, 0, TAU, 48, Color("c9a86a"), 5.0)
		_draw_symbol(keys[i], c, Color("2b221b") if filled else Color(0.79, 0.66, 0.42, 0.7))


func _draw_symbol(kind: String, c: Vector2, color: Color) -> void:
	match kind:
		"torre":
			_canvas.draw_rect(Rect2(c.x - 16, c.y - 30, 32, 60), color)
			for x in [-16, -2, 12]:
				_canvas.draw_rect(Rect2(c.x + x, c.y - 42, 6, 12), color)
		"muleta":
			_canvas.draw_line(c + Vector2(0, -32), c + Vector2(0, 36), color, 7.0)
			_canvas.draw_line(c + Vector2(-20, -32), c + Vector2(20, -32), color, 7.0)
		"sol":
			_canvas.draw_circle(c + Vector2(0, 10), 18, color)
			for i in 7:
				var a := PI + PI * i / 6.0
				_canvas.draw_line(c + Vector2(0, 10) + Vector2(cos(a), sin(a)) * 26, c + Vector2(0, 10) + Vector2(cos(a), sin(a)) * 40, color, 4.0)


func _draw_mirror(size: Vector2, has_art: bool) -> void:
	# Área ocupada pelo vidro (a arte entra centralizada, sem corte).
	var glass := Rect2(Vector2.ZERO, size)
	if has_art:
		var r: Rect2 = params.get("region", Rect2(0, 0, 3, 4))
		var w := size.y * r.size.x / r.size.y
		glass = Rect2((size.x - w) * 0.5, 0, w, size.y)
	else:
		_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color("b8a888"))
		_canvas.draw_rect(Rect2(0, 0, size.x * 0.22, size.y), Color("6b4a32"))
	# Os números aparecem espelhados: o jogador precisa lê-los ao contrário.
	var font := ThemeFactory.FONT_SEMIBOLD
	var font_size := 150 if glass.size.x > 700 else 110
	_canvas.draw_set_transform(Vector2(glass.get_center().x, size.y * 0.42), 0.0, Vector2(-1, 1))
	_canvas.draw_string(font, Vector2(-200, 40), "1408", HORIZONTAL_ALIGNMENT_CENTER, 400, font_size, Color(0.97, 0.96, 0.92, 0.85))
	_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# A barra de um vestido claro, refletida no canto do vidro.
	var x0 := glass.end.x - glass.size.x * 0.3
	var hem := PackedVector2Array([Vector2(x0, size.y * 0.8), Vector2(x0 + glass.size.x * 0.2, size.y * 0.8),
		Vector2(x0 + glass.size.x * 0.26, size.y), Vector2(x0 - glass.size.x * 0.04, size.y)])
	_canvas.draw_colored_polygon(hem, Color(0.95, 0.93, 0.88, 0.8))


func _draw_clocks(size: Vector2) -> void:
	var times: Array = params.get("data", {}).get("times", [])
	var font := ThemeFactory.FONT_SEMIBOLD
	_canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.05, 0.03, 0.55))
	var n := times.size()
	var step := size.x / float(n)
	for i in n:
		var c := Vector2(step * (i + 0.5), size.y * 0.42)
		var t: Array = times[i]
		ClockFace.draw_clock(_canvas, c, 86, t[0], t[1], Color("d9c8a6"))
		var plate := Rect2(c.x - 92, c.y + 115, 184, 56)
		_canvas.draw_rect(plate, Color("8a6a3a"))
		_canvas.draw_string(font, Vector2(plate.position.x, plate.position.y + 40), CLOCK_NAMES[i], HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, 32, ThemeFactory.INK_DARK)
