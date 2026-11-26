extends PanelContainer
## Painel genérico com título, linhas e botão "Voltar".
## Usado pelo Álbum (linhas com ação) e pelo Caderno (só texto).

signal action(id: String, kind: String)
signal closed

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")

var title := ""
var empty_text := ""
## Cada linha: {"text": String, "action": String (opcional), "id": String, "kind": String}
var rows: Array = []


func setup(new_title: String, new_rows: Array, new_empty_text: String) -> void:
	title = new_title
	rows = new_rows
	empty_text = new_empty_text


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	v.custom_minimum_size = Vector2(1000, 0)
	add_child(v)

	v.add_child(ThemeFactory.label(title, ThemeFactory.FONT_TITLE))

	if rows.is_empty():
		v.add_child(ThemeFactory.label(empty_text, ThemeFactory.FONT_BODY, ThemeFactory.INK_QUIET))
	for row in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 24)
		var text := ThemeFactory.label(row["text"])
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		if row.has("action"):
			var b := ThemeFactory.button(row["action"], Vector2(300, 96))
			b.pressed.connect(action.emit.bind(row["id"], row["kind"]))
			line.add_child(b)
		v.add_child(line)

	var back := ThemeFactory.button("Voltar", Vector2(220, 96))
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(closed.emit)
	v.add_child(back)
