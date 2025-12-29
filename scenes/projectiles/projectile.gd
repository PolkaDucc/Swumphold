class_name Projectile
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: int = 5
var puncture: int = 0
var source_weapon: WeaponInstanceData
var lifetime: float = 3.0

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func setup(dir: Vector2, wpn: WeaponInstanceData) -> void:
	direction = dir.normalized()
	source_weapon = wpn
	damage = wpn.final_damage
	puncture = wpn.final_puncture
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, puncture)
	queue_free()
