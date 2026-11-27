extends PanelContainer
## Tela de item: aparece ao pegar algo ("Novo item") e ao examinar pelo inventário.
## Documentos aparecem como papel e podem ser virados para ler o verso.
## Também mostra os nomes dos mineiros encontrados.

signal closed
signal use_requested(id: String)

const Content := preload("res://scripts/game/content.gd")
const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Art := preload("res://scripts/ui/art.gd")

const IMAGE_SIZE := Vector2(440, 440)

var item_id := ""
var is_new := false
var name_index := -1
var name_where := ""
var _showing_back := false
var _text: Label
var _flip: Button


func setup_item(id: String, new_item: bool) -> void:
	item_id = id
	is_new = new_item


func setup_name(index: int, where: String) -> void:
	name_index = index
	name_where = where


func _ready() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	add_child(row)
	row.add_child(_build_image())

	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(760, 0)
	v.add_theme_constant_override("separation", 18)
	row.add_child(v)

	if name_index >= 0:
		_build_name_card(v)
	else:
		_build_item_card(v)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 20)
	actions.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
	v.add_child(actions)
	if item_id != "" and Content.item_back(item_id) != "":
		_flip = ThemeFactory.button("Virar", Vector2(200, 96))
		_flip.pressed.connect(_toggle_back)
		actions.add_child(_flip)
	if item_id != "" and not is_new and Content.ITEM_TARGETS.has(item_id):
		var use := ThemeFactory.button("Usar", Vector2(200, 96))
		use.pressed.connect(func(): use_requested.emit(item_id))
		actions.add_child(use)
	var close := ThemeFactory.button("Continuar" if is_new or name_index >= 0 else "Fechar", Vector2(240, 96))
	close.pressed.connect(closed.emit)
	actions.add_child(close)


func _build_item_card(v: VBoxContainer) -> void:
	v.add_child(ThemeFactory.label("Novo item" if is_new else "Examinar", 30, ThemeFactory.INK_QUIET))
	v.add_child(ThemeFactory.title(Content.item_name(item_id)))
	if Content.is_document(item_id):
		var paper := PanelContainer.new()
		paper.add_theme_stylebox_override("panel", ThemeFactory.paper_style())
		v.add_child(paper)
		_text = ThemeFactory.label(Content.item_desc(item_id), 0, ThemeFactory.INK_DARK)
		_text.add_theme_font_override("font", ThemeFactory.FONT_ITALIC)
		paper.add_child(_text)
	else:
		_text = ThemeFactory.label(Content.item_desc(item_id))
		v.add_child(_text)
	if not is_new and Content.ITEM_TARGETS.has(item_id):
		v.add_child(ThemeFactory.label("Para usar, toque em Usar e depois no lugar certo da cena.", 28, ThemeFactory.INK_QUIET))


func _build_name_card(v: VBoxContainer) -> void:
	v.add_child(ThemeFactory.label("Nome %d de 31" % _names_count(), 30, ThemeFactory.INK_QUIET))
	v.add_child(ThemeFactory.label(name_where, 0, ThemeFactory.INK_QUIET))
	var parts: PackedStringArray = Content.MINERS[name_index].split(", ", true, 1)
	v.add_child(ThemeFactory.title(parts[0]))
	if parts.size() > 1:
		v.add_child(ThemeFactory.label(parts[1]))
	v.add_child(ThemeFactory.label("Um dos 31 mortos da Mina da Aurora. Anotado no caderno.", 28, ThemeFactory.INK_QUIET))


func _names_count() -> int:
	return GameState.names_found.size() if is_inside_tree() else 0


func _build_image() -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = IMAGE_SIZE
	frame.add_theme_stylebox_override("panel", ThemeFactory.box(Color(0, 0, 0, 0.25), Color(ThemeFactory.LINE, 0.6), 2, 16))
	var art: Texture2D = null
	if item_id != "":
		art = Art.load_art("items/" + item_id)
	if art != null:
		var tex := TextureRect.new()
		tex.texture = art
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.add_child(tex)
	else:
		var drawn := Control.new()
		drawn.draw.connect(_draw_placeholder.bind(drawn))
		frame.add_child(drawn)
	return frame


func _draw_placeholder(c: Control) -> void:
	var r := Rect2(Vector2.ZERO, c.size).grow(-40)
	if name_index >= 0:
		_draw_chalk_name(c, r)
		return
	var paper := Content.is_document(item_id)
	c.draw_rect(r, ThemeFactory.PAPER if paper else Color("4a3b2e"))
	c.draw_rect(r, ThemeFactory.LINE, false, 3.0)
	var font := c.get_theme_default_font()
	c.draw_string(font, Vector2(r.position.x, r.get_center().y + 14), Content.item_name(item_id),
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 40, ThemeFactory.INK_DARK if paper else ThemeFactory.INK)


## Nome escrito a giz numa tábua escura, como foi achado na cena.
func _draw_chalk_name(c: Control, r: Rect2) -> void:
	c.draw_rect(r, Color("5a4430"))
	var board := r.grow(-16)
	c.draw_rect(board, Color("23211e"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 31 + name_index
	for i in 14:
		var p := board.position + Vector2(rng.randf() * board.size.x, rng.randf() * board.size.y)
		c.draw_circle(p, rng.randf_range(20, 60), Color(0.85, 0.84, 0.8, 0.025))
	var font := ThemeFactory.FONT_ITALIC
	var words: PackedStringArray = Content.MINERS[name_index].split(", ")[0].split(" ", false, 1)
	var chalk := Color(0.9, 0.89, 0.84, 0.88)
	c.draw_set_transform(board.get_center(), -0.05, Vector2.ONE)
	for i in words.size():
		var y := -20.0 + i * 70.0 - (words.size() - 1) * 20.0
		for k in 3:
			var jitter := Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5))
			c.draw_string(font, Vector2(-board.size.x * 0.5, y) + jitter, words[i], HORIZONTAL_ALIGNMENT_CENTER,
				board.size.x, 62, Color(chalk, 0.45 if k > 0 else 0.88))
	c.draw_line(Vector2(-110, 92), Vector2(110, 86), Color(chalk, 0.6), 3.0)
	c.draw_string(font, Vector2(-board.size.x * 0.5, 136), "† 14 · VIII · 1899", HORIZONTAL_ALIGNMENT_CENTER,
		board.size.x, 34, Color(chalk, 0.7))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _toggle_back() -> void:
	_showing_back = not _showing_back
	_text.text = Content.item_back(item_id) if _showing_back else Content.item_desc(item_id)
	_flip.text = "Frente" if _showing_back else "Virar"
	GameState.play("page")
