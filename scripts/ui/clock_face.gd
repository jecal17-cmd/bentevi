extends Control
## Mostrador de relógio desenhado em código (arte provisória).

const ThemeFactory := preload("res://scripts/ui/theme_factory.gd")

var hour := 3
var minute := 17
## Só os ponteiros, para desenhar sobre a imagem de um mostrador.
var transparent_face := false


func set_time(h: int, m: int) -> void:
	hour = h
	minute = m
	queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	draw_clock(self, size * 0.5, r, hour, minute, Color("d9c8a6"), not transparent_face)


static func draw_clock(ci: CanvasItem, center: Vector2, radius: float, h: int, m: int, face: Color, with_face: bool = true) -> void:
	var ink := Color("2b221b")
	if with_face:
		ci.draw_circle(center, radius, face)
		ci.draw_arc(center, radius, 0.0, TAU, 64, ink, maxf(3.0, radius * 0.05))
	for i in (12 if with_face else 0):
		var a := TAU * i / 12.0
		var dir := Vector2(sin(a), -cos(a))
		ci.draw_line(center + dir * radius * 0.82, center + dir * radius * 0.94, ink, maxf(2.0, radius * 0.03))
	var minute_angle := TAU * m / 60.0
	var hour_angle := TAU * (float(h % 12) + m / 60.0) / 12.0
	ci.draw_line(center, center + Vector2(sin(hour_angle), -cos(hour_angle)) * radius * 0.5, ink, maxf(4.0, radius * 0.06))
	ci.draw_line(center, center + Vector2(sin(minute_angle), -cos(minute_angle)) * radius * 0.78, ink, maxf(3.0, radius * 0.035))
	ci.draw_circle(center, maxf(4.0, radius * 0.05), ink)
