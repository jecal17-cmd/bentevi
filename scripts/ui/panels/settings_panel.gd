extends PanelContainer
## Configurações: volumes, texto grande, ajuda para achar objetos e apagar progresso.

signal closed
signal erase_requested

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")

var _erase: Button
var _erase_armed := false


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 22)
	v.custom_minimum_size = Vector2(1000, 0)
	add_child(v)
	v.add_child(ThemeFactory.title("Configurações"))

	v.add_child(_slider("Música e ambiente", Settings.music_volume, func(value): Settings.set_value("music_volume", value)))
	v.add_child(_slider("Efeitos", Settings.sfx_volume, func(value):
		Settings.set_value("sfx_volume", value)
		GameState.play("click")))
	v.add_child(_toggle("Texto grande", Settings.large_text, "large_text"))
	v.add_child(_toggle("Mostrar áreas de toque", Settings.show_hotspots, "show_hotspots"))
	v.add_child(ThemeFactory.label("Contorna discretamente tudo o que pode ser tocado. Útil no celular.", 28, ThemeFactory.INK_QUIET))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 20)
	v.add_child(actions)
	_erase = ThemeFactory.button("Apagar progresso", Vector2(360, 96))
	_erase.pressed.connect(_on_erase)
	actions.add_child(_erase)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	var back := ThemeFactory.button("Voltar", Vector2(220, 96))
	back.pressed.connect(closed.emit)
	actions.add_child(back)


func _slider(text: String, value: float, on_change: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	var l := ThemeFactory.label(text)
	l.custom_minimum_size = Vector2(380, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(520, 72)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(on_change)
	h.add_child(s)
	return h


# Botão que alterna "Sim/Não": maior e mais claro no celular que um interruptor.
func _toggle(text: String, value: bool, key: String) -> Button:
	var b := ThemeFactory.button("", Vector2(0, 90))
	b.toggle_mode = true
	b.button_pressed = value
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var update := func(on: bool): b.text = "%s:  %s" % [text, "Sim" if on else "Não"]
	update.call(value)
	b.toggled.connect(func(on):
		update.call(on)
		Settings.set_value(key, on)
		GameState.play("click"))
	return b


# Confirmação em dois toques, sem diálogo extra.
func _on_erase() -> void:
	if not _erase_armed:
		_erase_armed = true
		_erase.text = "Toque de novo para apagar"
		return
	erase_requested.emit()
