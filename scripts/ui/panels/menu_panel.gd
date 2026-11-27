extends PanelContainer
## Menu vertical de botões (pausa). Cada opção: [rótulo, id].

signal chosen(id: String)

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")

var title_text := ""
var options: Array = []


func setup(new_title: String, new_options: Array) -> void:
	title_text = new_title
	options = new_options


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.custom_minimum_size = Vector2(560, 0)
	add_child(v)
	var heading := ThemeFactory.title(title_text)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(heading)
	for option in options:
		var b := ThemeFactory.button(option[0], Vector2(560, 100))
		b.pressed.connect(chosen.emit.bind(option[1]))
		v.add_child(b)
