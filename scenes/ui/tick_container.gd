extends Control

var max_health: int = 100
var tick_interval: int = 50


func setup(health: int) -> void:
	max_health = health
	queue_redraw()


func _draw() -> void:
	if max_health <= tick_interval:
		return
	
	var bar_width = size.x
	var bar_height = size.y

	var tick_hp = tick_interval
	while tick_hp < max_health:
		var x_pos = (float(tick_hp) / max_health) * bar_width
		draw_line(
			Vector2(x_pos, 0),
			Vector2(x_pos, bar_height),
			Color(0, 0, 0, 0.5),
			1.0
		)
		tick_hp += tick_interval
