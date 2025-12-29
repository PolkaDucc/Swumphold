extends Node2D

func _ready() -> void:
	var enemy = get_node_or_null("Enemy")
	if enemy:
		enemy.add_modifier(Enums.EnemyModifier.BEEG)
