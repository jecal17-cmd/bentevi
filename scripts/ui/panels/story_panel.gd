extends PanelContainer
## Texto narrativo com botões (fim de capítulo, transições). Opções: [rótulo, id].

signal chosen(id: String)

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Art := preload("res://scripts/ui/art.gd")

var art_name := ""
var lines: Array = []
var heading := ""
var subheading := ""
var options: Array = []


func setup(new_lines: Array, new_heading: String, new_subheading: String, new_options: Array, new_art: String = "") -> void:
	lines = new_lines
	heading = new_heading
	subheading = new_subheading
	options = new_options
	art_name = new_art


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	v.custom_minimum_size = Vector2(1240, 0)
	add_child(v)
	var art := Art.load_art(art_name) if art_name != "" else null
	if art != null:
		var tex := TextureRect.new()
		tex.texture = art
		tex.custom_minimum_size = Vector2(1240, 420)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.clip_contents = true
		v.add_child(tex)
	for line in lines:
		var l := ThemeFactory.label(line)
		l.add_theme_font_override("font", ThemeFactory.FONT_ITALIC)
		v.add_child(l)
	if heading != "":
		v.add_child(ThemeFactory.title(heading))
	if subheading != "":
		v.add_child(ThemeFactory.label(subheading, 0, ThemeFactory.INK_QUIET))
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 20)
	v.add_child(actions)
	for option in options:
		var b := ThemeFactory.button(option[0], Vector2(280, 96))
		b.pressed.connect(chosen.emit.bind(option[1]))
		actions.add_child(b)
