class_name Player
extends CharacterBody2D

const ProjectileScene = preload("res://scenes/projectiles/projectile.tscn")

@export var character_data: CharacterData

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite
@onready var ability_timer: Timer = $AbilityCooldownTimer

const BASE_SPEED: float = 60.0

var current_health: int
var current_weapon: WeaponInstanceData
var current_ammo: int = 0
var is_reloading: bool = false

func _ready() -> void:
	print("Player _ready called")
	print("Character data: ", character_data)
	if character_data:
		current_health = character_data.max_health
		_equip_starting_weapon()
	else:
		print("No character data!")
		current_health = 100

func _equip_starting_weapon() -> void:
	current_weapon = WeaponFactory.generate_weapon(character_data.starting_weapon_type)
	current_ammo = current_weapon.final_magazine_size
	print("=== Weapon Equipped ===")
	print("Ammo: ", current_ammo)
	print("Damage: ", current_weapon.final_damage)
	for part in current_weapon.parts:
		var type_name = Enums.PartType.keys()[part.part_type]
		var rarity_name = Enums.Rarity.keys()[part.rarity]
		print("  ", type_name, " (", rarity_name, ")")

func _physics_process(delta: float) -> void:
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
	weapon_sprite.flip_v = aiming_left

func _handle_shooting() -> void:
	if Input.is_action_just_pressed("shoot") and current_ammo > 0 and not is_reloading:
		_fire_weapon()

func _fire_weapon() -> void:
	current_ammo -= 1
	var projectile = ProjectileScene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = weapon_pivot.global_position
	
	var direction = (get_global_mouse_position() - weapon_pivot.global_position).normalized()
	projectile.setup(direction, current_weapon)
	print("shot fired. ammo: ", current_ammo, "/", current_weapon.final_magazine_size)
	if current_ammo <= 0:
		_start_reload()

func _handle_reload() -> void:
	if Input.is_action_just_pressed("reload") and not is_reloading and current_ammo < current_weapon.final_magazine_size:
		_start_reload()

func _start_reload() -> void:
	is_reloading = true
	print("reloading...")
	
	await get_tree().create_timer(current_weapon.final_reload_speed).timeout
	current_ammo = current_weapon.final_magazine_size
	is_reloading = false
	print("Reload complete! Ammo: ", current_ammo)
