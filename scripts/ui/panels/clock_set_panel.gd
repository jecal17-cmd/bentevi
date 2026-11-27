extends PanelContainer
## Acertar os ponteiros do relógio de pêndulo.

signal submitted(hour: int, minute: int)
signal closed

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const ClockFace := preload("res://scripts/ui/clock_face.gd")
const Art := preload("res://scripts/ui/art.gd")

var hour := 3
var minute := 15
var _clock: Control
var _readout: Label


func _ready() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	add_child(row)

	var face := Control.new()
	face.custom_minimum_size = Vector2(520, 520)
	row.add_child(face)
	var dial := Art.load_art("pendulo_zoom")
	if dial != null:
		var tex := TextureRect.new()
		tex.texture = dial
		tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		face.add_child(tex)
	_clock = ClockFace.new()
	_clock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_clock.transparent_face = dial != null
	face.add_child(_clock)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	v.custom_minimum_size = Vector2(560, 0)
	row.add_child(v)
	v.add_child(ThemeFactory.title("Relógio de pêndulo"))
	v.add_child(ThemeFactory.label("Na base, gravado: \"Marque a hora oficial.\"", 0, ThemeFactory.INK_QUIET))
	_readout = ThemeFactory.label("", 72)
	v.add_child(_readout)
	v.add_child(_adjuster("Horas", func(d): _change(d, 0)))
	v.add_child(_adjuster("Minutos", func(d): _change(0, d * 5)))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 20)
	v.add_child(actions)
	var back := ThemeFactory.button("Voltar", Vector2(220, 96))
	back.pressed.connect(closed.emit)
	var ok := ThemeFactory.button("Soltar o pêndulo", Vector2(320, 96))
	ok.pressed.connect(func(): submitted.emit(hour, minute))
	actions.add_child(back)
	actions.add_child(ok)
	_update()


func _adjuster(label_text: String, on_change: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := ThemeFactory.label(label_text)
	l.custom_minimum_size = Vector2(200, 0)
	h.add_child(l)
	var minus := ThemeFactory.button("−", Vector2(120, 96))
	minus.pressed.connect(func(): on_change.call(-1))
	var plus := ThemeFactory.button("+", Vector2(120, 96))
	plus.pressed.connect(func(): on_change.call(1))
	h.add_child(minus)
	h.add_child(plus)
	return h


func _change(dh: int, dm: int) -> void:
	minute += dm
	hour += dh + floori(minute / 60.0)
	minute = posmod(minute, 60)
	hour = posmod(hour - 1, 12) + 1
	GameState.play("tick")
	_update()


func _update() -> void:
	_readout.text = "%dh%02d" % [hour, minute]
	_clock.set_time(hour, minute)
