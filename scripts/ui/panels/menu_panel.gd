extends PanelContainer
## Menu vertical de botões (pausa). Cada opção: [rótulo, id].

signal chosen(id: String)

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")

var title_text := ""
var options: Array = []
var subtitle := ""


func setup(new_title: String, new_options: Array, new_subtitle: String = "") -> void:
	title_text = new_title
	options = new_options
	subtitle = new_subtitle


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.custom_minimum_size = Vector2(560, 0)
	add_child(v)
	var heading := ThemeFactory.title(title_text)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(heading)
	if subtitle != "":
		var sub := ThemeFactory.label(subtitle, 0, ThemeFactory.INK_QUIET)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(sub)
	for option in options:
		var b := ThemeFactory.button(option[0], Vector2(560, 100))
		b.pressed.connect(chosen.emit.bind(option[1]))
		v.add_child(b)
