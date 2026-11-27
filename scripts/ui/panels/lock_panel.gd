extends PanelContainer
## Cadeado de discos numéricos (3 ou 4 dígitos).

signal submitted(code: String)
signal closed

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")

var digit_count := 3
var title_text := "Cadeado"
var digits: Array[int] = []
var _labels: Array[Label] = []


func setup(count: int, title_value: String) -> void:
	digit_count = count
	title_text = title_value


func _ready() -> void:
	digits.resize(digit_count)
	digits.fill(0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 24)
	add_child(v)

	var heading := ThemeFactory.title(title_text)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(heading)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	v.add_child(row)
	for i in digit_count:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 10)
		var up := ThemeFactory.button("+", Vector2(130, 96))
		up.pressed.connect(_step.bind(i, 1))
		var digit := ThemeFactory.label("0", 100)
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
	var s := ""
	for d in digits:
		s += str(d)
	return s


func _step(index: int, delta: int) -> void:
	digits[index] = posmod(digits[index] + delta, 10)
	_labels[index].text = str(digits[index])
	GameState.play("tick")
