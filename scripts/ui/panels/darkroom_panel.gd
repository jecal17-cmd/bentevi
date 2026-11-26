extends PanelContainer
## Câmara escura: a chapa escurece com o tempo; retire na faixa amarela.
## Errar não gasta a chapa — o objetivo é ritmo, não punição.

signal developed
signal closed

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")
const Art := preload("res://scripts/ui/art.gd")

const DURATION := 4.0
const TARGET_MIN := 0.55
const TARGET_MAX := 0.8
const PALE := Color("f3ead8")
const DARK := Color("1a120c")

var place_title := ""
## Imagem que surge na chapa: o lugar em 1899.
var picture: Texture2D
var progress := 0.0
var running := true
var _pale: ColorRect
var _dark: ColorRect
var _meter: Control
var _status: Label
var _pull: Button
var _retry: Button


func setup(title: String, view: String) -> void:
	place_title = title
	picture = Art.load_art("%s_1899" % view)


func _ready() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	add_child(v)

	var title := ThemeFactory.label("Câmara escura — %s" % place_title, ThemeFactory.FONT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var plate := ColorRect.new()
	plate.custom_minimum_size = Vector2(640, 360)
	plate.color = Color("6b5236")
	plate.clip_contents = true
	v.add_child(plate)
	if picture != null:
		var image := TextureRect.new()
		image.texture = picture
		image.set_anchors_preset(Control.PRESET_FULL_RECT)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		plate.add_child(image)
	_pale = ColorRect.new()
	_pale.color = PALE
	_pale.set_anchors_preset(Control.PRESET_FULL_RECT)
	plate.add_child(_pale)
	_dark = ColorRect.new()
	_dark.color = Color(DARK, 0.0)
	_dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	plate.add_child(_dark)

	_meter = Control.new()
	_meter.custom_minimum_size = Vector2(640, 40)
	_meter.draw.connect(_draw_meter)
	v.add_child(_meter)

	_status = ThemeFactory.label("Retire a chapa quando o marcador estiver na faixa amarela.", 30, ThemeFactory.INK_QUIET)
	_status.custom_minimum_size = Vector2(640, 0)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_status)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 24)
	v.add_child(actions)
	var back := ThemeFactory.button("Voltar", Vector2(220, 96))
	back.pressed.connect(closed.emit)
	_retry = ThemeFactory.button("Tentar de novo", Vector2(300, 96))
	_retry.pressed.connect(restart)
	_retry.visible = false
	_pull = ThemeFactory.button("Retirar", Vector2(260, 96))
	_pull.pressed.connect(pull)
	actions.add_child(back)
	actions.add_child(_retry)
	actions.add_child(_pull)


func _process(delta: float) -> void:
	if not running:
		return
	progress = minf(progress + delta / DURATION, 1.0)
	_update_visuals()
	if progress >= 1.0:
		_fail("Escureceu demais. A imagem se perdeu no preto.")


func restart() -> void:
	progress = 0.0
	running = true
	_pull.visible = true
	_retry.visible = false
	_status.text = "Retire a chapa quando o marcador estiver na faixa amarela."
	_update_visuals()


func pull() -> void:
	if not running:
		return
	if is_in_target(progress):
		running = false
		_pull.visible = false
		_status.text = "A imagem surge na chapa."
		_status.add_theme_color_override("font_color", ThemeFactory.ACCENT)
		await get_tree().create_timer(0.9).timeout
		developed.emit()
	elif progress < TARGET_MIN:
		_fail("Cedo demais. A chapa ainda está quase branca.")
	else:
		_fail("Tarde demais. A chapa escureceu.")


static func is_in_target(value: float) -> bool:
	return value >= TARGET_MIN and value <= TARGET_MAX


func _fail(text: String) -> void:
	running = false
	_status.text = text
	_pull.visible = false
	_retry.visible = true


func _update_visuals() -> void:
	# A imagem aparece no meio do processo e se perde no preto se passar do ponto.
	_pale.color.a = clampf(1.0 - progress / 0.65, 0.0, 1.0)
	_dark.color.a = clampf((progress - 0.7) / 0.3, 0.0, 1.0)
	_meter.queue_redraw()


func _draw_meter() -> void:
	var w := _meter.size.x
	var h := _meter.size.y
	_meter.draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.08))
	_meter.draw_rect(Rect2(w * TARGET_MIN, 0, w * (TARGET_MAX - TARGET_MIN), h), Color(ThemeFactory.ACCENT, 0.45))
	_meter.draw_rect(Rect2(w * progress - 4, -6, 8, h + 12), ThemeFactory.INK)
