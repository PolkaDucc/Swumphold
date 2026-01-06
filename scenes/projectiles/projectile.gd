class_name Projectile
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 450.0
var damage: int = 5
var puncture: int = 0
var source_weapon: WeaponInstanceData
var lifetime: float = 3.0
var element: StatusEffect.Type = -1
var elemental_chance: float = 0.1
var is_crit: bool = false
var knockback_mult: float = 1.0
var ignite_chance: float = 0.0
var ricochet_on_crit: bool = false
var grows_over_distance: bool = false
var ricochet_count: int = 0
var travel_time: float = 0.0
var base_damage: int = 0
var pierce: int = 0
var enemies_hit: Array = []
var pierce_puncture_bonus: int = 0
var enemies_pierced: int = 0


const DamageNumberScene = preload("res://scenes/ui/damage_number.tscn")

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	if grows_over_distance:
		travel_time += delta
		scale = Vector2(1.0 + travel_time * 2.0, 1.0 + travel_time * 2.0)
		damage = int(base_damage * (1.0 + (travel_time / 0.5) * 0.10))
		if is_crit:
			damage = int(damage * source_weapon.final_crit_damage)
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func setup(dir: Vector2, weapon: Weapon, crit: bool = false) -> void:
	direction = dir.normalized()
	source_weapon = weapon.weapon_data
	is_crit = crit
	rotation = direction.angle()

	var body_effects = weapon.get_body_effects()
	knockback_mult = body_effects.knockback_mult
	ignite_chance = body_effects.ignite_chance
	ricochet_on_crit = body_effects.ricochet_on_crit
	grows_over_distance = body_effects.grows_over_distance
	pierce = body_effects.pierce
	pierce_puncture_bonus = weapon.get_pierce_puncture_bonus()
	base_damage = weapon.get_damage_with_body()
	damage = base_damage
	puncture = weapon.get_puncture_with_body(is_crit)

	if is_crit:
		damage = int(damage * source_weapon.final_crit_damage)

	for part in source_weapon.parts:
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
		if body in enemies_hit:
			return
		enemies_hit.append(body)
		
		var knockback_force = 50.0 * knockback_mult
		body.take_damage(damage, puncture, is_crit, knockback_force, direction)

		var player = get_tree().get_first_node_in_group("player")
		if player and player.current_weapon:
			player.current_weapon.on_hit()

		if ignite_chance > 0 and randf() <= ignite_chance:
			if body.has_method("apply_status"):
				body.apply_status(StatusEffect.Type.FIRE, damage)

		if element >= 0 and body.has_method("apply_status"):
			if randf() <= elemental_chance:
				body.apply_status(element, damage)

		if ricochet_on_crit and is_crit and ricochet_count < 3:
			_ricochet(body)
			return

		if pierce > 0:
			pierce -= 1
			enemies_pierced += 1
			puncture += pierce_puncture_bonus
			return
	else:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.current_weapon:
			player.current_weapon.on_miss()
	
	queue_free()

func _ricochet(hit_body: Node2D) -> void:
	ricochet_count += 1

	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var nearest_dist: float = 200.0
	
	for enemy in enemies:
		if enemy == hit_body:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	
	if nearest:
		direction = (nearest.global_position - global_position).normalized()
		rotation = direction.angle()

		if ricochet_count == 3:
			damage *= 3
	else:
		queue_free()
