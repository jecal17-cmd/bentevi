extends PanelContainer
## Detalhe ampliado de um objeto. Usa assets/art/<nome>_zoom.png se existir.

signal closed

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const ClockFace := preload("res://scripts/ui/clock_face.gd")
const Art := preload("res://scripts/ui/art.gd")

var art_name := ""
var caption := ""
var clock_time: Array = []


func setup(new_art_name: String, new_caption: String, new_clock_time: Array = []) -> void:
	art_name = new_art_name
	caption = new_caption
	clock_time = new_clock_time


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	add_child(v)

	var picture := Art.load_art("%s_zoom" % art_name)
	if picture != null:
		var tex := TextureRect.new()
		tex.texture = picture
		tex.custom_minimum_size = Vector2(1100, 614)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(tex)
	elif clock_time.size() == 2:
		var clock := ClockFace.new()
		clock.custom_minimum_size = Vector2(600, 600)
		clock.set_time(clock_time[0], clock_time[1])
		v.add_child(clock)

	var text := ThemeFactory.label(caption)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.custom_minimum_size = Vector2(1100, 0)
	v.add_child(text)

	var back := ThemeFactory.button("Voltar", Vector2(220, 96))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(closed.emit)
	v.add_child(back)
