extends PanelContainer
## Cadeado de 3 dígitos da mala.

signal submitted(code: String)
signal closed

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")

var digits: Array[int] = [0, 0, 0]
var _labels: Array[Label] = []


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 24)
	add_child(v)

	var title := ThemeFactory.label("Cadeado de latão", ThemeFactory.FONT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 32)
	v.add_child(row)
	for i in 3:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 12)
		var up := ThemeFactory.button("+", Vector2(130, 96))
		up.pressed.connect(_step.bind(i, 1))
		var digit := ThemeFactory.label("0", 96, ThemeFactory.ACCENT)
		digit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var down := ThemeFactory.button("−", Vector2(130, 96))
		down.pressed.connect(_step.bind(i, -1))
		col.add_child(up)
		col.add_child(digit)
		col.add_child(down)
		row.add_child(col)
		_labels.append(digit)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 24)
	v.add_child(actions)
	var back := ThemeFactory.button("Voltar", Vector2(220, 96))
	back.pressed.connect(closed.emit)
	var open := ThemeFactory.button("Abrir", Vector2(220, 96))
	open.pressed.connect(func(): submitted.emit(code()))
	actions.add_child(back)
	actions.add_child(open)


func code() -> String:
	return "%d%d%d" % [digits[0], digits[1], digits[2]]


func _step(index: int, delta: int) -> void:
	digits[index] = posmod(digits[index] + delta, 10)
	_labels[index].text = str(digits[index])
