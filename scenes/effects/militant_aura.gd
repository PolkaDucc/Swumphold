extends Node2D

var radius: float = 100.0


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.502, 0.0, 0.682), 2.0, true)
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.5, 0.0, 0.1))
