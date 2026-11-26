extends HBoxContainer
## Barra de inventário. Mostra o ícone em assets/art/items/<id>.png se existir.

signal item_pressed(id: String)

const Content := preload("res://scripts/game/content.gd")
const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Art := preload("res://scripts/ui/art.gd")

const SLOTS := 6
const SLOT_SIZE := Vector2(170, 110)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 12)


func refresh(items: Array[String], selected: String) -> void:
	for child in get_children():
		child.queue_free()
	for i in SLOTS:
		var slot := ThemeFactory.button("", SLOT_SIZE)
		if i < items.size():
			var id: String = items[i]
			var icon := Art.load_art("items/" + id)
			if icon != null:
				slot.icon = icon
				slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				slot.expand_icon = true
				slot.tooltip_text = Content.item_name(id)
			else:
				slot.text = Content.item_name(id)
			slot.add_theme_font_size_override("font_size", 28)
			if id == selected:
				slot.theme_type_variation = "SelectedButton"
			slot.pressed.connect(item_pressed.emit.bind(id))
		else:
			slot.disabled = true
		add_child(slot)
