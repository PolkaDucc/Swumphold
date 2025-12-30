class_name Projectile
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 450.0
var damage: int = 5
var puncture: int = 0
var source_weapon: WeaponInstanceData
var lifetime: float = 3.0
var element: StatusEffect.Type = -1
var elemental_chance: float = 1

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

	for part in wpn.parts:
		match part.effect_id:
			"wand_rune_fire":
				element = StatusEffect.Type.FIRE
			"wand_rune_freeze":
				element = StatusEffect.Type.FREEZE
			"wand_rune_corrupt":
				element = StatusEffect.Type.CORRUPT
			"wand_rune_bleed":
				element = StatusEffect.Type.BLEED
			"wand_rune_shock":
				element = StatusEffect.Type.SHOCK
			"wand_rune_infected":
				element = StatusEffect.Type.INFECTED
			"wand_rune_duumitosis":
				element = StatusEffect.Type.DUUMITE

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, puncture)
		if element >= 0 and body.has_method("apply_status"):
			if randf() <= elemental_chance:
				body.apply_status(element, damage)
	
	queue_free()
