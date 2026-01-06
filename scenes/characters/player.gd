class_name Player
extends CharacterBody2D

const ProjectileScene = preload("res://scenes/projectiles/projectile.tscn")
const WeaponScene = preload("res://scenes/weapons/weapon.tscn")

@export var character_data: CharacterData

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite
@onready var ability_timer: Timer = $AbilityCooldownTimer

const BASE_SPEED: float = 60.0

var current_health: int
var current_weapon: Weapon
var fire_rate_timer: float = 0.0

func _ready() -> void:
	if character_data:
		current_health = character_data.max_health
		_equip_starting_weapon()
	else:
		current_health = 100

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
	if fire_rate_timer > 0:
		fire_rate_timer -= delta
	
	_handle_aiming()
	_handle_shooting()
	_handle_movement()
	_handle_reload()
	move_and_slide()

func _handle_movement() -> void:
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	input_dir = input_dir.normalized()
	
	var speed = BASE_SPEED
	if character_data:
		speed = BASE_SPEED * character_data.move_speed_multiplier
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
	if Input.is_action_pressed("shoot") and current_weapon.current_ammo > 0 and not current_weapon.is_reloading and fire_rate_timer <= 0:
		_fire_weapon()

func _fire_weapon() -> void:
	current_weapon.current_ammo -= 1
	fire_rate_timer = 1.0 / current_weapon.get_fire_rate()
	
	var weapon_data = current_weapon.weapon_data

	var barrel_result = current_weapon.process_barrel_effects()
	
	if barrel_result.delay_fire:
		_delayed_fire(barrel_result.delay_bullets)
		return

	var is_crit = randf() <= current_weapon.get_crit_chance()
	if is_crit:
		current_weapon.on_crit()

	var projectile_count = weapon_data.final_projectile_count + barrel_result.extra_projectiles

	for i in range(projectile_count):
		_spawn_projectile(is_crit)

	if barrel_result.portal_bullet:
		_spawn_portal_bullet(is_crit)
	
	if current_weapon.current_ammo <= 0:
		_start_reload()

func _handle_reload() -> void:
	if not current_weapon:
		return
	if Input.is_action_just_pressed("reload") and not current_weapon.is_reloading and current_weapon.current_ammo < current_weapon.weapon_data.final_magazine_size:
		_start_reload()

func _start_reload() -> void:
	current_weapon.is_reloading = true
	print("Reloading... (", current_weapon.weapon_data.final_reload_speed, "s)")
	
	await get_tree().create_timer(current_weapon.weapon_data.final_reload_speed).timeout
	current_weapon.current_ammo = current_weapon.weapon_data.final_magazine_size
	current_weapon.is_reloading = false
	current_weapon.on_reload()
	print("Reloaded! Ammo: ", current_weapon.current_ammo)

func take_damage(amount: int, puncture: int = 0) -> void:
	var effective_defense = character_data.defense if character_data else 0
	
	var puncture_percent = clamp(puncture / 100.0, 0.0, 0.88)
	effective_defense = int(effective_defense * (1.0 - puncture_percent))
	
	var damage_multiplier = 100.0 / (100.0 + effective_defense)
	var final_damage = int(amount * damage_multiplier)
	
	current_health -= final_damage
	print("Player took ", final_damage, " damage! HP: ", current_health, "/", character_data.max_health if character_data else 100)
	
	if current_health <= 0:
		_die()

func _die() -> void:
	print("Player died!")

func _spawn_projectile(is_crit: bool) -> void:
	var projectile = ProjectileScene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = weapon_pivot.global_position
	
	var weapon_data = current_weapon.weapon_data
	var base_direction = (get_global_mouse_position() - weapon_pivot.global_position).normalized()
	var max_spread = (weapon_data.final_accuracy - 1) * 5.0
	var spread = randf_range(-max_spread, max_spread)
	var direction = base_direction.rotated(deg_to_rad(spread))
	
	projectile.setup(direction, current_weapon, is_crit)

func _delayed_fire(bullet_count: int) -> void:
	print("JAM! Firing ", bullet_count, " bullets after delay...")
	current_weapon.current_ammo = 0
	await get_tree().create_timer(2.5).timeout
	for i in range(bullet_count):
		_spawn_projectile(false)
		await get_tree().create_timer(0.05).timeout
	_start_reload()

func _spawn_portal_bullet(is_crit: bool) -> void:
	var projectile = ProjectileScene.instantiate()
	get_tree().root.add_child(projectile)
	# TODO: Spawn portal visual effect here
	var to_mouse = (get_global_mouse_position() - global_position).normalized()
	projectile.global_position = global_position - to_mouse * 50
	
	projectile.setup(to_mouse, current_weapon, is_crit)
