extends HBoxContainer
## Barra de inventário. 1º toque seleciona o item; 2º toque abre a tela de examinar.

signal item_pressed(id: String)

const Content := preload("res://scripts/game/content.gd")
const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Art := preload("res://scripts/ui/art.gd")

## Espaços mínimos; a barra cresce se houver mais itens (o Capítulo 1 chega a 8).
const MIN_SLOTS := 8
const SLOT_SIZE := Vector2(136, 120)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 10)


func refresh(items: Array[String], selected: String) -> void:
	for child in get_children():
		child.queue_free()
	for i in maxi(MIN_SLOTS, items.size()):
		var slot := ThemeFactory.button("", SLOT_SIZE)
		if i < items.size():
			var id: String = items[i]
			var icon := Art.load_art("items/" + id)
			slot.tooltip_text = Content.item_name(id)
			if icon != null:
				slot.icon = icon
				slot.expand_icon = true
				slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			else:
				slot.text = Content.item_short(id)
				slot.add_theme_font_size_override("font_size", 26)
				slot.clip_text = true
			if id == selected:
				slot.theme_type_variation = "SelectedButton"
			slot.pressed.connect(item_pressed.emit.bind(id))
		else:
			slot.disabled = true
		add_child(slot)
