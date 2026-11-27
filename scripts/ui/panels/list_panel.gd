extends PanelContainer
## Painel com título, linhas e "Voltar". Usado pelo Álbum, Caderno, Capítulos e Créditos.
## Cada linha: {"text": String, "action": String (opcional), "id", "kind", "disabled": bool}

signal action(id: String, kind: String)
signal closed

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")

var title_text := ""
var empty_text := ""
var rows: Array = []


func setup(new_title: String, new_rows: Array, new_empty_text: String = "") -> void:
	title_text = new_title
	rows = new_rows
	empty_text = new_empty_text


func _ready() -> void:
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 20)
	outer.custom_minimum_size = Vector2(1200, 0)
	add_child(outer)
	outer.add_child(ThemeFactory.title(title_text))

	# Listas longas (caderno) rolam em vez de estourar a tela.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(1200, mini(640, 40 + rows.size() * 120))
	outer.add_child(scroll)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	if rows.is_empty():
		v.add_child(ThemeFactory.label(empty_text, 0, ThemeFactory.INK_QUIET))
	for row in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 24)
		var text := ThemeFactory.label(row["text"])
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		if row.has("action"):
			var b := ThemeFactory.button(row["action"], Vector2(320, 96))
			b.disabled = row.get("disabled", false)
			b.pressed.connect(action.emit.bind(row.get("id", ""), row.get("kind", "")))
			line.add_child(b)
		v.add_child(line)

	var back := ThemeFactory.button("Voltar", Vector2(220, 96))
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(closed.emit)
	outer.add_child(back)
