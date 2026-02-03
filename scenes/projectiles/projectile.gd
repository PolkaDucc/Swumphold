class_name Projectile
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

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
var is_laser_orb: bool = false
var laser_damage_timer: float = 0.0
var laser_base_damage: int = 0
var is_double_damage: bool = false
var homing: bool = false
var homing_timer: float = 0.0
var has_homed: bool = false
var homing_puncture_bonus: int = 0
var homing_target: Node2D = null
var accelerating_bullet: bool = false


const DamageNumberScene = preload("res://scenes/ui/damage_number.tscn")

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if accelerating_bullet:
		speed = min(speed * 1.08, 800.0)
		damage = int(base_damage * (speed / 250.0))
		if is_crit:
			damage = int(damage * source_weapon.final_crit_damage)

	if grows_over_distance:
		travel_time += delta
		scale = Vector2(1.0 + travel_time * 0.5, 1.0 + travel_time * 0.5)
		damage = int(base_damage * (1.0 + (travel_time / 0.5) * 0.45))
		if is_crit:
			damage = int(damage * source_weapon.final_crit_damage)

	if is_laser_orb:
		laser_damage_timer += delta
		if laser_damage_timer >= 0.25:
			laser_damage_timer -= 0.25
			_laser_orb_damage()

	if homing and not has_homed:
		homing_timer += delta
		if homing_timer >= 0.1:
			_start_homing()
	if has_homed and homing_target:
		if not is_instance_valid(homing_target) or homing_target.is_dead:
			has_homed = false
			homing_target = null
			homing_timer = 0.0
		else:
			var target_dir = (homing_target.global_position - global_position).normalized()
			direction = direction.lerp(target_dir, 0.1)
			rotation = direction.angle()
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func setup(dir: Vector2, weapon: Weapon, crit: bool = false, double_damage: bool = false) -> void:
	direction = dir.normalized()
	source_weapon = weapon.weapon_data
	is_crit = crit
	is_double_damage = double_damage
	rotation = direction.angle()

	var body_effects = weapon.get_body_effects()
	knockback_mult = body_effects.knockback_mult
	ignite_chance = body_effects.ignite_chance
	ricochet_on_crit = body_effects.ricochet_on_crit
	grows_over_distance = body_effects.grows_over_distance
	pierce = body_effects.pierce
	homing = body_effects.homing
	pierce_puncture_bonus = weapon.get_pierce_puncture_bonus()
	base_damage = weapon.get_damage_with_body()
	damage = base_damage
	puncture = weapon.get_puncture_with_body(is_crit)
	
	if weapon.weapon_data.has_effect("pistol_body_pink"):
		accelerating_bullet = true
		speed = 50
	
	if is_double_damage:
		damage *= 2

	if is_crit:
		damage = int(damage * source_weapon.final_crit_damage)
	damage = int(damage * randf_range(0.75, 1.05))
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
				
	if source_weapon.override_element >= 0:
		element = source_weapon.override_element as StatusEffect.Type

	if animated_sprite:
		animated_sprite.play()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):

		if body in enemies_hit:
			return
		if body is Enemy and Enums.EnemyModifier.CRYSTALLIC in body.modifiers:
			if randf() <= 0.25:
				direction = -direction
				rotation = direction.angle()
				enemies_hit.clear()
				return
		if body is Enemy and Enums.EnemyModifier.HUNGRY in body.modifiers:
			if randf() <= 0.25:
				queue_free()
				return
		enemies_hit.append(body)

		var final_puncture = puncture + homing_puncture_bonus
		
		var knockback_force = 50.0 * knockback_mult
		body.take_damage(damage, final_puncture, is_crit, knockback_force, direction)
		homing_timer = 0.0

		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("heal"):
			var total_lifesteal = player.lifesteal_bonus
			if player.character_data:
				total_lifesteal += player.character_data.lifesteal
			if total_lifesteal > 0:
				var heal_amount = int(damage * total_lifesteal / 100.0)
				if heal_amount > 0:
					player.heal(heal_amount)
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
		if enemy.is_dead:
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

func setup_laser_orb(dir: Vector2, weapon: Weapon, crit: bool = false) -> void:
	direction = dir.normalized()
	source_weapon = weapon.weapon_data
	is_crit = crit
	is_laser_orb = true
	rotation = direction.angle()
	
	speed = 100.0  # slow moving
	lifetime = 5.0  # lasts longer
	laser_base_damage = int(weapon.get_damage() * 0.77)
	pierce = 3  # pierce 
	
	# make it giga man
	scale = Vector2(2.0, 2.0)
	if animated_sprite:
		animated_sprite.play("start")
		animated_sprite.animation_finished.connect(_on_laser_orb_start_finished)

func _laser_orb_damage() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.is_dead:
			continue
		if global_position.distance_to(enemy.global_position) < 30.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(laser_base_damage, 0, is_crit, 0, Vector2.ZERO)

func _start_homing() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var nearest_dist: float = 300.0
	
	for enemy in enemies:
		if enemy.is_dead:
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	
	if nearest:
		has_homed = true
		homing_target = nearest
		homing_puncture_bonus = 50
		print("Bullet homing!")

func _on_laser_orb_start_finished() -> void:
	if is_laser_orb and animated_sprite:
		animated_sprite.play("loop")
