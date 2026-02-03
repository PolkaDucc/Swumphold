class_name Player
extends CharacterBody2D

const BulletScene = preload("res://scenes/projectiles/projectile_bullet.tscn")
const LaserOrbScene = preload("res://scenes/projectiles/projectile_laser_orb.tscn")
const WeaponScene = preload("res://scenes/weapons/weapon.tscn")
const PortalEffectScene = preload("res://scenes/effects/portal_effect.tscn")
const WandBoltScene = preload("res://scenes/projectiles/projectile_wand_bolt.tscn")
const GibletScene = preload("res://scenes/projectiles/giblet.tscn")

@export var character_data: CharacterData

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite
@onready var ability_timer: Timer = $AbilityCooldownTimer
@onready var camera: Camera2D = $Camera2D


const BASE_SPEED: float = 60.0

var current_health: int
var current_weapon: Weapon
var fire_rate_timer: float = 0.0
var camera_offset_target: Vector2 = Vector2.ZERO
var is_dead: bool = false
var crit_triggered_this_shot: bool = false
var elemental_damage_bonus: float = 0.0
var difficulty_bonus: float = 0.0
var lifesteal_bonus: float = 0.0
var healing_bonus: float = 0.0
var regen_bonus: float = 0.0
var regen_timer: float = 0.0
var status_effects: Array[StatusEffect] = []
var status_timers: Dictionary = {}
var stun_timer: float = 0.0
var slow_stacks: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	if character_data:
		current_health = character_data.max_health
		_equip_starting_weapon()
	else:
		current_health = 100

func _handle_camera() -> void:
	if not camera:
		return
	
	var mouse_pos = get_local_mouse_position()
	var target_offset = mouse_pos * 0.2
	target_offset = target_offset.clamp(Vector2(-100, -100), Vector2(100, 100))

	camera_offset_target = camera_offset_target.lerp(target_offset, 0.05)

	camera.offset = camera_offset_target.round()

func _equip_starting_weapon() -> void:
	var weapon_data = WeaponFactory.generate_weapon(character_data.starting_weapon_type)
	current_weapon = WeaponScene.instantiate()
	weapon_pivot.add_child(current_weapon)
	current_weapon.setup(weapon_data)
	# not in use rn dont show
	weapon_sprite.hide()
	
	print("Equipped: ", weapon_data.get_display_name())
	print("Manufacturer: ", Enums.Manufacturer.keys()[weapon_data.manufacturer])
	print("Parts:")
	for part in weapon_data.parts:
		print("  - ", Enums.PartType.keys()[part.part_type], " (", Enums.Rarity.keys()[part.rarity], "): ", part.effect_id)
	print("Stat modifiers: ", weapon_data.stat_modifiers)
	print("Final damage: ", weapon_data.final_damage)
	print("Final mag size: ", weapon_data.final_magazine_size)
	print("Final fire rate: ", weapon_data.final_fire_rate)
	print("Final crit chance:", weapon_data.final_crit_chance)
	print("Final crit damage:", weapon_data.final_crit_damage)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if stun_timer > 0:
		stun_timer -= delta
	if slow_stacks > 0:
		slow_stacks -= delta * 0.1
		slow_stacks = max(0, slow_stacks)
	_process_regen(delta)
	_process_player_statuses(delta)
	if not is_stunned():
		if fire_rate_timer > 0:
			fire_rate_timer -= delta
		_handle_aiming()
		_handle_shooting()
		_handle_movement()
		
		_handle_reload()
		_handle_entity_push()
		if Input.is_action_pressed("shoot") and current_weapon and current_weapon.can_fire():
			current_weapon.on_fire_mag_red(delta)
	else:
		velocity = Vector2.ZERO
	if knockback_velocity.length() > 0:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
	_handle_camera()
	_handle_animation()
	move_and_slide()

func _handle_movement() -> void:
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	input_dir = input_dir.normalized()
	
	var speed = BASE_SPEED
	if character_data:
		speed = BASE_SPEED * character_data.move_speed_multiplier
	if has_status(StatusEffect.Type.FREEZE):
		speed *= 0.5
	if slow_stacks > 0:
		speed *= max(0.1, 1.0 - slow_stacks)
	velocity = input_dir * speed

func _handle_aiming() -> void:
	var mouse_pos = get_global_mouse_position()
	weapon_pivot.look_at(mouse_pos)
	var aiming_left = mouse_pos.x < global_position.x
	if current_weapon:
		current_weapon.scale.y = -1 if aiming_left else 1

func _handle_shooting() -> void:
	if not current_weapon:
		return
	if not current_weapon.can_fire():
		return
	if Input.is_action_pressed("shoot") and current_weapon.current_ammo > 0 and not current_weapon.is_reloading and fire_rate_timer <= 0:
		_fire_weapon()

func _fire_weapon() -> void:
	current_weapon.current_ammo -= 1
	fire_rate_timer = 1.0 / current_weapon.get_fire_rate()
	crit_triggered_this_shot = false
	current_weapon.mag_purple_triggered_this_shot = false 
	
	var weapon_data = current_weapon.weapon_data
	
	# process barrel effects
	var barrel_result = current_weapon.process_barrel_effects()
	
	# handle jam (white barrel)
	if barrel_result.delay_fire:
		_delayed_fire(barrel_result.delay_bullets)
		return

	var is_double_damage = current_weapon.use_double_damage_bullet()
	var projectile_count = weapon_data.final_projectile_count + barrel_result.extra_projectiles
	var body_effects = current_weapon.get_body_effects()
	if body_effects.is_laser_orb:
		_fire_laser_orb(false)
		return

	var has_magnum = current_weapon.weapon_data.has_effect("pistol_mag_blue")
	if body_effects.triple_burst and not has_magnum:
		_fire_triple_burst(false, is_double_damage)
		return

	for i in range(projectile_count):
		_spawn_projectile(false, is_double_damage)

	if barrel_result.portal_bullet:
		_spawn_portal_bullet(false)
	
	if current_weapon.current_ammo <= 0:
		_start_reload()

func _handle_reload() -> void:
	if not current_weapon:
		return
	if current_weapon.weapon_data.has_effect("pistol_mag_red"):
		return
	if Input.is_action_just_pressed("reload") and not current_weapon.is_reloading:
		_start_reload()

func _handle_animation() -> void:
	if is_dead:
		return
	if velocity.length() > 0:
		sprite.play("walk")
	else:
		sprite.play("idle")

	var mouse_pos = get_global_mouse_position()
	sprite.flip_h = mouse_pos.x < global_position.x

func _start_reload() -> void:
	current_weapon.is_reloading = true
	print("Reloading... (", current_weapon.weapon_data.final_reload_speed, "s)")
	
	await get_tree().create_timer(current_weapon.weapon_data.final_reload_speed).timeout
	current_weapon.current_ammo = current_weapon.weapon_data.final_magazine_size
	current_weapon.is_reloading = false
	current_weapon.on_reload()
	print("Reloaded! Ammo: ", current_weapon.current_ammo)

func _process_regen(delta: float) -> void:
	var total_regen = regen_bonus
	if character_data:
		total_regen += character_data.regen
	
	if total_regen <= 0:
		return
	
	regen_timer += delta
	if regen_timer >= 1.0:
		regen_timer -= 1.0
		heal(int(total_regen))

func heal(amount: int) -> void:
	var total_healing = 1.0 + healing_bonus
	if character_data:
		total_healing += character_data.healing - 1.0
	
	var final_heal = int(amount * total_healing)
	var max_hp = character_data.max_health if character_data else 100
	current_health = min(current_health + final_heal, max_hp)

func take_damage(amount: int, puncture: int = 0) -> void:
	
	var effective_defense = character_data.defense if character_data else 0
	
	effective_defense = effective_defense - puncture
	
	var damage_multiplier = 100.0 / max(1.0, 100.0 + effective_defense)
	var final_damage = int(amount * damage_multiplier)
	
	current_health -= final_damage
	print("Player took ", final_damage, " damage! HP: ", current_health, "/", character_data.max_health if character_data else 100)
	
	if current_health <= 0:
		_die()

func take_status_damage(amount: int) -> void:
	if is_dead:
		return
	current_health -= amount
	print("Player took ", amount, " status damage! HP: ", current_health, "/", character_data.max_health if character_data else 100)
	
	if current_health <= 0:
		_die()

func apply_status(effect_type: StatusEffect.Type, damage: int) -> void:
	for effect in status_effects:
		if effect.type == effect_type:
			effect.add_stack()
			return
	var new_effect = StatusEffect.new(effect_type, damage)
	status_effects.append(new_effect)

func has_status(effect_type: StatusEffect.Type) -> bool:
	for effect in status_effects:
		if effect.type == effect_type:
			return true
	return false

func get_status_stacks(effect_type: StatusEffect.Type) -> int:
	for effect in status_effects:
		if effect.type == effect_type:
			return effect.stacks
	return 0

func _process_player_statuses(delta: float) -> void:
	if is_dead:
		return
	var to_remove: Array[StatusEffect] = []
	for effect in status_effects:
		if is_dead:
			break
		effect.duration -= delta
		
		match effect.type:
			StatusEffect.Type.FIRE:
				_process_player_fire(effect, delta)
			StatusEffect.Type.FREEZE:
				pass  # handled passively in movement or sumtim
			StatusEffect.Type.CORRUPT:
				_process_player_corrupt(effect, delta)
			StatusEffect.Type.BLEED:
				_process_player_bleed(effect, delta)
			StatusEffect.Type.SHOCK:
				_process_player_shock(effect, delta)
			StatusEffect.Type.INFECTED:
				_process_player_infected(effect, delta)
			StatusEffect.Type.DUUMITE:
				_process_player_duumite(effect, delta)
		
		if effect.duration <= 0:
			_on_player_effect_expire(effect)
			to_remove.append(effect)
	
	for effect in to_remove:
		status_effects.erase(effect)

func _process_player_fire(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("fire"):
		status_timers["fire"] = 0.0
	status_timers["fire"] += delta
	if status_timers["fire"] >= 0.25:
		status_timers["fire"] -= 0.25
		var max_hp = character_data.max_health if character_data else 100
		var damage = int(max_hp * 0.01 * effect.stacks)
		damage = max(1, damage)
		take_status_damage(damage)

func _process_player_corrupt(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("corrupt"):
		status_timers["corrupt"] = 0.0
	status_timers["corrupt"] += delta
	if status_timers["corrupt"] >= 2.0:
		status_timers["corrupt"] -= 2.0
		var damage = int(effect.stacks * 5.5)
		damage = max(1, damage)
		take_status_damage(damage)

func _process_player_bleed(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("bleed"):
		status_timers["bleed"] = 0.0
	status_timers["bleed"] += delta
	if status_timers["bleed"] >= 1.0:
		status_timers["bleed"] -= 1.0
		var max_hp = character_data.max_health if character_data else 100
		var damage = int(max_hp * 0.025)
		damage = max(1, damage)
		take_status_damage(damage)

func _process_player_shock(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("shock"):
		status_timers["shock"] = 0.0
	status_timers["shock"] += delta
	if status_timers["shock"] >= 1.0:
		status_timers["shock"] -= 1.0
		var damage = int(effect.source_damage * (1.0 + effect.stacks * 0.05))
		damage = max(1, damage)
		take_status_damage(damage)
		stun_timer = 0.25

func is_stunned() -> bool:
	return stun_timer > 0.0

func _process_player_infected(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("infected"):
		status_timers["infected"] = 0.0
	status_timers["infected"] += delta
	if status_timers["infected"] >= 1.0:
		status_timers["infected"] -= 1.0
		_shed_giblet()

func _shed_giblet() -> void:
	var giblet = GibletScene.instantiate()
	get_tree().root.add_child(giblet)
	giblet.global_position = global_position
	var angle = randf() * TAU
	var dir = Vector2(cos(angle), sin(angle))
	var max_hp = character_data.max_health if character_data else 100
	var damage = int(max_hp * 0.15)
	giblet.setup(dir, damage)
	giblet.spawned_by_player = true

func _process_player_duumite(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("duumite"):
		status_timers["duumite"] = 0.0
	status_timers["duumite"] += delta
	if status_timers["duumite"] >= 1.0:
		status_timers["duumite"] -= 1.0
		var max_hp = character_data.max_health if character_data else 100
		var damage_percent = 0.02 + (effect.stacks - 1) * 0.01
		var damage = int(max_hp * damage_percent)
		damage = max(1, damage)
		take_status_damage(damage)

func _on_player_effect_expire(effect: StatusEffect) -> void:
	match effect.type:
		StatusEffect.Type.BLEED:
			var max_hp = character_data.max_health if character_data else 100
			var damage = int(max_hp * 0.15)
			take_damage(damage)
		StatusEffect.Type.INFECTED:
			for i in range(3):
				_shed_giblet()
		StatusEffect.Type.SHOCK:
			status_timers.erase("shock")

func _handle_entity_push() -> void:
	if is_dead:
		return
	
	var push_force = 50.0
	var push_radius = 20.0

	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.is_dead:
			continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < push_radius and distance > 0:
			var push_dir = (global_position - enemy.global_position).normalized()
			var push_strength = (push_radius - distance) / push_radius
			velocity += push_dir * push_force * push_strength

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	print("Player died!")
	set_collision_layer_value(1, false)
	set_collision_mask_value(2, false)

	if current_weapon:
		current_weapon.hide()

	if sprite.sprite_frames.has_animation("die"):
		sprite.play("die")
		await sprite.animation_finished

	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.443, 0.443, 0.443, 1.0), 0.5)
	await tween.finished
	
	print("Game Over!")

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction * force
	print("Knockback applied: ", knockback_velocity)

func apply_slow(amount: float) -> void:
	slow_stacks += amount

func _spawn_projectile(forced_crit: bool = false, is_double_damage: bool = false) -> void:
	var is_crit = forced_crit
	if not forced_crit:
		var crit_chance = current_weapon.get_crit_chance()
		if is_double_damage:
			crit_chance *= 0.5
		is_crit = randf() <= crit_chance
		
		if is_crit and not crit_triggered_this_shot:
			crit_triggered_this_shot = true
			current_weapon.on_crit_handle()
			current_weapon.on_crit()
			current_weapon.on_crit_mag()
	var projectile
	if current_weapon.weapon_data.base.weapon_type == Enums.WeaponType.WAND:
		projectile = WandBoltScene.instantiate()
	else:
		projectile = BulletScene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = weapon_pivot.global_position
	
	var base_direction = (get_global_mouse_position() - weapon_pivot.global_position).normalized()
	var max_spread = (current_weapon.get_accuracy() - 1) * 5.0
	var spread = randf_range(-max_spread, max_spread)
	var direction = base_direction.rotated(deg_to_rad(spread))
	
	projectile.setup(direction, current_weapon, is_crit, is_double_damage)

func _delayed_fire(bullet_count: int) -> void:
	print("JAM! Firing ", bullet_count, " bullets after delay...")
	current_weapon.current_ammo = 0
	await get_tree().create_timer(2.5, false, true).timeout
	var body_effects = current_weapon.get_body_effects()
	for i in range(bullet_count):
		if body_effects.is_laser_orb:
			var projectile = LaserOrbScene.instantiate()
			get_tree().root.add_child(projectile)
			projectile.global_position = weapon_pivot.global_position
			var base_direction = (get_global_mouse_position() - weapon_pivot.global_position).normalized()
			projectile.setup_laser_orb(base_direction, current_weapon, false)
		else:
			_spawn_projectile(false)
		await get_tree().create_timer(0.05, false, true).timeout
	_start_reload()

func _spawn_portal_bullet(is_crit: bool) -> void:
	var portal = PortalEffectScene.instantiate()
	get_tree().root.add_child(portal)
	var to_mouse = (get_global_mouse_position() - global_position).normalized()
	portal.global_position = global_position - to_mouse * 50
	
	var projectile = BulletScene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = global_position - to_mouse * 50
	
	projectile.setup(to_mouse, current_weapon, is_crit, false)

func _fire_triple_burst(is_crit: bool, is_double_damage: bool) -> void:
	for i in range(3):
		_spawn_projectile(is_crit, is_double_damage)
		if i < 2:
			current_weapon.current_ammo -= 1
			if current_weapon.current_ammo <= 0:
				break
		await get_tree().create_timer(0.05).timeout
	
	if current_weapon.current_ammo <= 0:
		_start_reload()

func _fire_laser_orb(is_crit: bool) -> void:
	
	current_weapon.current_ammo -= 3
	
	var projectile = LaserOrbScene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = weapon_pivot.global_position
	
	var base_direction = (get_global_mouse_position() - weapon_pivot.global_position).normalized()
	
	projectile.setup_laser_orb(base_direction, current_weapon, is_crit)
	
	if current_weapon.current_ammo <= 0:
		_start_reload()
