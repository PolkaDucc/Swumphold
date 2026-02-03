extends Node2D

func _ready() -> void:
	var test_level = 1
	
	for child in get_children():
		if child is Enemy:
			child.level = test_level
			child.set_level(test_level)
			child._apply_modifiers()
			child.current_health = child.modified_health
			
			var enemy_name = child.enemy_data.enemy_name if child.enemy_data else "Enemy"
			var modifier_text = child._get_modifier_display()
			child.health_bar.setup(enemy_name, modifier_text, child.modified_health, child.level)
			child.health_bar.hide()
