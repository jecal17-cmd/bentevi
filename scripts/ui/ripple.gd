extends Control
## Círculo que se expande e some: confirma o toque na cena no celular.

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")

var radius := 10.0
var alpha := 0.8


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "radius", 70.0, 0.45).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "alpha", 0.0, 0.45)
	tween.chain().tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(ThemeFactory.INK, alpha), 3.0)
