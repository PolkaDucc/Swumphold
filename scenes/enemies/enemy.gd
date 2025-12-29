class_name Enemy
extends CharacterBody2D

@export var enemy_data: EnemyData

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_collision: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var health_bar: EnemyHealthBar = $HealthBarPivot/EnemyHealthBarUI

const BASE_SPEED: float = 60.0
const DamageNumberScene = preload("res://scenes/ui/damage_number.tscn")

var current_health: int
var is_infamous: bool = false
var target: Node2D = null
var has_hit_this_attack: bool = false
var is_attacking: bool = false
var is_aggroed: bool = false
var aggro_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var current_state: Enums.EnemyState = Enums.EnemyState.WANDER
var modifiers: Array[Enums.EnemyModifier] = []
var modified_health: int
var modified_damage: int
var modified_defense: int
var modified_speed: float

func _ready() -> void:
	_apply_modifiers()
	
	current_health = modified_health
	
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)

	var enemy_name = enemy_data.enemy_name if enemy_data else "Enemy"
	var modifier_text = _get_modifier_display()
	health_bar.setup(enemy_name, modifier_text, modified_health, 1)
	health_bar.hide()
	
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
		target = players[0]

func _physics_process(delta: float) -> void:
	if is_aggroed:
		aggro_timer -= delta
		if aggro_timer <= 0:
			is_aggroed = false
	
	_update_state()
	_execute_state(delta)
	move_and_slide()


func _update_state() -> void:
	if is_attacking:
		return
	
	if not target:
		current_state = Enums.EnemyState.WANDER
		return
	
	var distance = global_position.distance_to(target.global_position)
	var aggro_range = enemy_data.aggro_range if enemy_data else 150.0
	var attack_range = enemy_data.attack_range if enemy_data else 20.0
	
	if distance <= attack_range:
		current_state = Enums.EnemyState.ATTACK_CLOSE
		return
	
	if is_aggroed or distance <= aggro_range:
		current_state = Enums.EnemyState.POSITION
		return
	
	current_state = Enums.EnemyState.WANDER


func _execute_state(delta: float) -> void:
	match current_state:
		Enums.EnemyState.WANDER:
			_state_wander(delta)
		Enums.EnemyState.POSITION:
			_state_position()
		Enums.EnemyState.ATTACK_CLOSE:
			_state_attack_close()


func _state_wander(delta: float) -> void:
	wander_timer -= delta
	
	if wander_timer <= 0:
		if wander_direction == Vector2.ZERO:
			wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			wander_timer = randf_range(1.0, 2.5)
		else:
			wander_direction = Vector2.ZERO
			wander_timer = randf_range(1.0, 3.0)
	
	if wander_direction != Vector2.ZERO:
		var speed = BASE_SPEED * 0.5 * (enemy_data.move_speed if enemy_data else 1.0)
		velocity = wander_direction * speed
		animated_sprite.flip_h = velocity.x < 0
		attack_hitbox.scale.x = -1 if velocity.x < 0 else 1
		animated_sprite.play("walk")
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")


func _state_position() -> void:
	var direction = (target.global_position - global_position).normalized()
	var speed = BASE_SPEED * (enemy_data.move_speed if enemy_data else 1.0)
	velocity = direction * speed
	
	animated_sprite.flip_h = direction.x < 0
	attack_hitbox.scale.x = -1 if direction.x < 0 else 1
	animated_sprite.play("walk")


func _state_attack_close() -> void:
	velocity = Vector2.ZERO
	
	if not is_attacking:
		is_attacking = true
		has_hit_this_attack = false
		animated_sprite.play("attack")


func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false


func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack":
		var current_frame = animated_sprite.frame
		if current_frame == 5:
			_enable_attack_hitbox()
		else:
			_disable_attack_hitbox()


func _enable_attack_hitbox() -> void:
	attack_collision.disabled = false


func _disable_attack_hitbox() -> void:
	attack_collision.disabled = true


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if has_hit_this_attack:
		return
	if body.has_method("take_damage"):
		body.take_damage(modified_damage)
		has_hit_this_attack = true

func take_damage(amount: int, puncture: int = 0) -> void:
	var effective_defense = modified_defense
	
	var puncture_percent = clamp(puncture / 100.0, 0.0, 0.88)
	effective_defense = int(effective_defense * (1.0 - puncture_percent))
	
	var damage_multiplier = 100.0 / (100.0 + effective_defense)
	var final_damage = int(amount * damage_multiplier)
	
	current_health -= final_damage
	health_bar.update_health(current_health)

	var dmg_num = DamageNumberScene.instantiate()
	get_tree().root.add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(0, -20)
	dmg_num.setup(final_damage, DamageNumber.DamageType.NORMAL)
	
	is_aggroed = true
	aggro_timer = 10.0
	
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
	
	if current_health <= 0:
		_die()

func _die() -> void:
	queue_free()

func _apply_modifiers() -> void:
	# Start with base stats
	modified_health = enemy_data.health if enemy_data else 50
	modified_damage = enemy_data.damage if enemy_data else 7
	modified_defense = enemy_data.defense if enemy_data else 15
	modified_speed = enemy_data.move_speed if enemy_data else 1.0
	
	var scale_mod: float = 1.0
	
	# Apply each modifier
	for modifier in modifiers:
		var mods = ModifierEffects.get_stat_mods(modifier)
		modified_health = int(modified_health * mods.health)
		modified_damage = int(modified_damage * mods.damage)
		modified_defense = int(modified_defense * mods.defense)
		modified_speed = modified_speed * mods.speed
		scale_mod = scale_mod * mods.scale
	
	# Apply scale to sprite
	animated_sprite.scale = Vector2(scale_mod, scale_mod)


func _get_modifier_display() -> String:
	var names: Array[String] = []
	for modifier in modifiers:
		names.append(ModifierEffects.get_display_name(modifier))
	return " ".join(names)

func add_modifier(modifier: Enums.EnemyModifier) -> void:
	modifiers.append(modifier)
