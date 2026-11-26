extends PanelContainer
## Fim do prólogo.

signal restart_requested
signal menu_requested

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")

const LINES := [
	"Um apito corta a noite. Uma carruagem para diante da estação.",
	"O cocheiro tira o chapéu, sem surpresa nenhuma:",
	"— Dona Lúcia. Faz vinte e cinco anos que esperamos a senhora.",
	"No alto do relógio parado, o bem-te-vi canta uma vez.",
]


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 24)
	v.custom_minimum_size = Vector2(1100, 0)
	add_child(v)
	for line in LINES:
		v.add_child(ThemeFactory.label(line))
	v.add_child(ThemeFactory.label("Fim do prólogo", ThemeFactory.FONT_TITLE, ThemeFactory.ACCENT))
	v.add_child(ThemeFactory.label("Capítulo 1 — O Velório: em breve.", ThemeFactory.FONT_BODY, ThemeFactory.INK_QUIET))

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 24)
	v.add_child(actions)
	var menu := ThemeFactory.button("Menu", Vector2(220, 96))
	menu.pressed.connect(menu_requested.emit)
	var again := ThemeFactory.button("Jogar de novo", Vector2(320, 96))
	again.pressed.connect(restart_requested.emit)
	actions.add_child(menu)
	actions.add_child(again)
