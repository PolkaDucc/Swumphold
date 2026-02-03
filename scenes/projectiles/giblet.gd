class_name Giblet
extends Area2D

const InfectedExplosionScene = preload("res://scenes/effects/infected_explosion.tscn")

var direction: Vector2 = Vector2.ZERO
var speed: float = 100.0
var damage: int = 0
var lifetime: float = 1.0
var has_exploded: bool = false
var spawned_by_player: bool = false

func setup(dir: Vector2, dmg: int) -> void:
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	speed = max(0, speed - 100 * delta)
	
	lifetime -= delta
	if lifetime <= 0 and not has_exploded:
		_explode()


func _explode() -> void:
	has_exploded = true
	
	var explosion = InfectedExplosionScene.instantiate()
	get_tree().root.add_child(explosion)
	explosion.global_position = global_position
	
	var sprite_size = explosion.sprite_frames.get_frame_texture("explode", 0).get_size()
	var scale_factor = 100.0 / sprite_size.x
	explosion.scale = Vector2(scale_factor, scale_factor)
	
	if spawned_by_player:
		var player = get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) < 50:
			if player.has_method("take_damage"):
				player.take_damage(damage)
	else:
		var enemies = get_tree().get_nodes_in_group("enemy")
		for enemy in enemies:
			if global_position.distance_to(enemy.global_position) < 50:
				if enemy.has_method("_take_status_damage"):
					enemy._take_status_damage(damage, DamageNumber.DamageType.INFECTED)
	
	queue_free()
