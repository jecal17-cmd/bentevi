extends Control
## Menu principal. Usa assets/art/capa.jpg como fundo se existir.

signal chosen(id: String)

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Art := preload("res://scripts/ui/art.gd")

var can_continue := false
var continue_label := "Continuar"


func setup(has_save: bool, where: String) -> void:
	can_continue = has_save
	if where != "":
		continue_label = "Continuar · %s" % where


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("1b140f")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var cover := Art.load_art("capa")
	if cover != null:
		var art := TextureRect.new()
		art.texture = cover
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(art)
		# Escurece a metade direita, onde fica o menu, para o texto ler bem.
		var shade := ColorRect.new()
		shade.color = Color(0, 0, 0, 0.45)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_right", 140)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)

	var name_label := ThemeFactory.title("BENTEVI", ThemeFactory.FONT_HERO)
	name_label.add_theme_color_override("font_color", ThemeFactory.ACCENT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_label)
	var tagline := ThemeFactory.title("O pássaro viu tudo", 48)
	tagline.add_theme_font_override("font", ThemeFactory.FONT_ITALIC)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tagline)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	v.add_child(gap)

	var options: Array = []
	if can_continue:
		options.append([continue_label, "continue"])
	options.append_array([["Novo jogo", "new"], ["Capítulos", "chapters"], ["Configurações", "settings"], ["Créditos", "credits"]])
	if OS.get_name() in ["Windows", "macOS", "Linux"]:
		options.append(["Sair", "quit"])
	for option in options:
		var b := ThemeFactory.button(option[0], Vector2(560, 92))
		b.pressed.connect(chosen.emit.bind(option[1]))
		v.add_child(b)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var footer := ThemeFactory.title("Protótipo 0.4 · Bentevi Apps", 26)
	footer.add_theme_color_override("font_color", ThemeFactory.INK_QUIET)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(footer)
