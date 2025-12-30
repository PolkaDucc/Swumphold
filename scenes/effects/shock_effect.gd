extends AnimatedSprite2D

var effect_radius: float = 100.0
var duration: float = 4.0
var tick_timer: float = 0.0
var tick_interval: float = 0.5
var damage_per_tick: int = 0
var source_enemy: Node2D = null


func _ready() -> void:
	pass


func setup(radius: float, damage: int, enemy: Node2D) -> void:
	effect_radius = radius
	damage_per_tick = damage
	source_enemy = enemy
	
	var base_size: float = 64.0
	var scale_factor = (radius * 2) / base_size
	scale = Vector2(scale_factor, scale_factor)
	
	play("shock")


func _process(delta: float) -> void:

	if source_enemy and is_instance_valid(source_enemy):
		global_position = source_enemy.global_position
	else:
		queue_free()
		return

	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer -= tick_interval
		_deal_aoe_damage()

	duration -= delta
	if duration <= 0:
		queue_free()


func _deal_aoe_damage() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy != source_enemy and global_position.distance_to(enemy.global_position) < effect_radius:
			if enemy.has_method("_take_status_damage"):
				enemy._take_status_damage(damage_per_tick, DamageNumber.DamageType.SHOCK)
				_draw_lightning(enemy.global_position)

func _draw_lightning(target_pos: Vector2) -> void:
	var line = Line2D.new()
	line.width = 2.0
	line.default_color = Color(1.0, 1.0, 0.3, 0.8)
	
	var start = global_position
	var end = target_pos
	var points: Array[Vector2] = [start]
	
	var segments = 5
	for i in range(1, segments):
		var t = float(i) / segments
		var mid = start.lerp(end, t)
		mid += Vector2(randf_range(-10, 10), randf_range(-10, 10))
		points.append(mid)
	points.append(end)
	
	for point in points:
		line.add_point(point)
	
	get_tree().root.add_child(line)
	
	var tween = get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)
