extends Control
## Tela de título. Usa assets/art/capa.png como fundo se existir.

signal continue_requested
signal new_game_requested

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Art := preload("res://scripts/ui/art.gd")

var can_continue := false


func setup(has_save: bool) -> void:
	can_continue = has_save


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
		var shade := ColorRect.new()
		shade.color = Color(0, 0, 0, 0.35)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 28)
	center.add_child(v)

	var name_label := ThemeFactory.label("BENTEVI", ThemeFactory.FONT_HERO, ThemeFactory.ACCENT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(name_label)
	var tagline := ThemeFactory.label("O pássaro viu tudo", ThemeFactory.FONT_TITLE)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(tagline)
	v.add_child(Control.new())

	if can_continue:
		var cont := ThemeFactory.button("Continuar", Vector2(420, 100))
		cont.pressed.connect(continue_requested.emit)
		v.add_child(cont)
	var new_game := ThemeFactory.button("Novo jogo", Vector2(420, 100))
	new_game.pressed.connect(new_game_requested.emit)
	v.add_child(new_game)

	var footer := ThemeFactory.label("Protótipo do prólogo · arte provisória · Bentevi Apps", 26, ThemeFactory.INK_QUIET)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(Control.new())
	v.add_child(footer)
