class_name Enemy
extends CharacterBody2D

@export var enemy_data: EnemyData

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_collision: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var health_bar: EnemyHealthBar = $HealthBarPivot/EnemyHealthBarUI

const BASE_SPEED: float = 60.0
const DamageNumberScene = preload("res://scenes/ui/damage_number.tscn")
const ShockEffectScene = preload("res://scenes/effects/shock_effect.tscn")
const GibletScene = preload("res://scenes/projectiles/giblet.tscn")

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
var status_effects: Array[StatusEffect] = []
var status_timers: Dictionary = {}
var level: int = 1
var knockback_velocity: Vector2 = Vector2.ZERO



func _ready() -> void:
	set_level(level)
	_apply_modifiers()
	
	current_health = modified_health
	attack_collision.disabled = true
	
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)

	var enemy_name = enemy_data.enemy_name if enemy_data else "Enemy"
	var modifier_text = _get_modifier_display()
	health_bar.setup(enemy_name, modifier_text, modified_health, level)
	health_bar.hide()
	
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _physics_process(delta: float) -> void:
	if is_aggroed:
		aggro_timer -= delta
		if aggro_timer <= 0:
			is_aggroed = false
	
	_process_status_effects(delta)
	_update_state()
	_execute_state(delta)

	if knockback_velocity.length() > 0:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
	
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
		var speed = BASE_SPEED * 0.5 * modified_speed

		if has_status(StatusEffect.Type.FREEZE):
			speed *= 0.5
		
		velocity = wander_direction * speed
		animated_sprite.flip_h = velocity.x < 0
		attack_hitbox.scale.x = -1 if velocity.x < 0 else 1
		animated_sprite.play("walk")
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")

func _state_position() -> void:
	var direction = (target.global_position - global_position).normalized()
	var speed = BASE_SPEED * modified_speed

	if has_status(StatusEffect.Type.FREEZE):
		speed *= 0.5
	
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

func take_damage(amount: int, puncture: int = 0, is_crit: bool = false, knockback: float = 0.0, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	var effective_defense = modified_defense
	
	var puncture_percent = clamp(puncture / 100.0, 0.0, 0.88)
	effective_defense = int(effective_defense * (1.0 - puncture_percent))
	
	var damage_multiplier = 100.0 / (100.0 + effective_defense)
	var final_damage = int(amount * damage_multiplier)

	if has_status(StatusEffect.Type.FREEZE):
		var stacks = get_status_stacks(StatusEffect.Type.FREEZE)
		var freeze_bonus = 0.10 + (stacks - 1) * 0.05
		final_damage = int(final_damage * (1.0 + freeze_bonus))

	if has_status(StatusEffect.Type.DUUMITE):
		var stacks = get_status_stacks(StatusEffect.Type.DUUMITE)
		var duumite_bonus = 1.5 + (stacks - 1) * 0.01
		final_damage = int(final_damage * (1.0 + duumite_bonus))
	
	current_health -= final_damage
	health_bar.update_health(current_health)

	if knockback > 0 and knockback_dir != Vector2.ZERO:
		apply_knockback(knockback_dir, knockback)

	var dmg_num = DamageNumberScene.instantiate()
	get_tree().root.add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(0, -20)
	
	var damage_type = DamageNumber.DamageType.NORMAL
	if is_crit:
		damage_type = DamageNumber.DamageType.CRIT
	elif has_status(StatusEffect.Type.FREEZE):
		damage_type = DamageNumber.DamageType.FREEZE
	elif has_status(StatusEffect.Type.DUUMITE):
		damage_type = DamageNumber.DamageType.DUUMITE

	dmg_num.setup(final_damage, damage_type)
	
	is_aggroed = true
	aggro_timer = 10.0
	
	if not target:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]
	
	if current_health <= 0:
		_die()

func _die() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.current_weapon:
		player.current_weapon.on_kill()
	
	queue_free()

func _apply_modifiers() -> void:
	modified_health = enemy_data.health if enemy_data else 50
	modified_damage = enemy_data.damage if enemy_data else 7
	modified_defense = enemy_data.defense if enemy_data else 15
	modified_speed = enemy_data.move_speed if enemy_data else 1.0

	var level_mult = level - 1
	modified_health = int(modified_health * (1.0 + level_mult * 0.45))
	modified_damage = int(modified_damage * (1.0 + level_mult * 0.15))
	modified_defense = int(modified_defense * (1.0 + level_mult * 0.20))
	
	var scale_mod: float = 1.0

	for modifier in modifiers:
		var mods = ModifierEffects.get_stat_mods(modifier)
		modified_health = int(modified_health * mods.health)
		modified_damage = int(modified_damage * mods.damage)
		modified_defense = int(modified_defense * mods.defense)
		modified_speed = modified_speed * mods.speed
		scale_mod = scale_mod * mods.scale

	animated_sprite.scale = Vector2(scale_mod, scale_mod)

func _get_modifier_display() -> String:
	var names: Array[String] = []
	for modifier in modifiers:
		names.append(ModifierEffects.get_display_name(modifier))
	return " ".join(names)

func add_modifier(modifier: Enums.EnemyModifier) -> void:
	modifiers.append(modifier)

func apply_status(effect_type: StatusEffect.Type, weapon_damage: int) -> void:
	for effect in status_effects:
		if effect.type == effect_type:
			effect.add_stack()
			return
	
	var new_effect = StatusEffect.new(effect_type, weapon_damage)
	status_effects.append(new_effect)

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction * force

func _process_status_effects(delta: float) -> void:
	var effects_to_remove: Array[StatusEffect] = []
	
	for effect in status_effects:
		effect.duration -= delta

		match effect.type:
			StatusEffect.Type.FIRE:
				_process_fire(effect, delta)
			StatusEffect.Type.FREEZE:
				_process_freeze(effect)
			StatusEffect.Type.CORRUPT:
				_process_corrupt(effect, delta)
			StatusEffect.Type.BLEED:
				_process_bleed(effect, delta)
			StatusEffect.Type.SHOCK:
				_process_shock(effect, delta)
			StatusEffect.Type.INFECTED:
				_process_infected(effect, delta)
			StatusEffect.Type.DUUMITE:
				_process_duumite(effect, delta)
		
		if effect.duration <= 0:
			_on_effect_expire(effect)
			effects_to_remove.append(effect)
	
	for effect in effects_to_remove:
		status_effects.erase(effect)


func _process_fire(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("fire"):
		status_timers["fire"] = 0.0
	
	status_timers["fire"] += delta
	if status_timers["fire"] >= 0.25:
		status_timers["fire"] -= 0.25
		var damage = int(modified_health * 0.01 * effect.stacks)
		damage = max(1, damage)
		_take_status_damage(damage, DamageNumber.DamageType.FIRE)


@warning_ignore("unused_parameter")
func _process_freeze(effect: StatusEffect) -> void:
	pass


func _process_corrupt(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("corrupt"):
		status_timers["corrupt"] = 0.0
	
	status_timers["corrupt"] += delta
	if status_timers["corrupt"] >= 2.0:
		status_timers["corrupt"] -= 2.0
		var damage = int(effect.stacks * 5.5)
		damage = max(1, damage)
		_take_status_damage(damage, DamageNumber.DamageType.CORRUPT)


@warning_ignore("unused_parameter")
func _process_bleed(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("bleed"):
		status_timers["bleed"] = 0.0
	
	status_timers["bleed"] += delta
	if status_timers["bleed"] >= 1.0:
		status_timers["bleed"] -= 1.0
		var damage = int(modified_health * 0.025)
		damage = max(1, damage)
		_take_status_damage(damage, DamageNumber.DamageType.BLEED)


func _process_shock(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("shock_spawned"):
		status_timers["shock_spawned"] = true
		var damage = int(effect.source_damage * 2.5)
		var bonus = effect.stacks * 0.05
		damage = int(damage * (1.0 + bonus))
		_chain_lightning(damage)


@warning_ignore("unused_parameter")
func _process_infected(effect: StatusEffect, delta: float) -> void:
	pass


@warning_ignore("unused_parameter")
func _process_duumite(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("duumite"):
		status_timers["duumite"] = 0.0
	
	status_timers["duumite"] += delta
	if status_timers["duumite"] >= 1.0:
		status_timers["duumite"] -= 1.0
		var damage = int(modified_health * 0.02)
		damage = max(1, damage)
		_take_status_damage(damage, DamageNumber.DamageType.DUUMITE)


func _on_effect_expire(effect: StatusEffect) -> void:
	match effect.type:
		StatusEffect.Type.BLEED:
			var damage = int(modified_health * 0.15)
			_take_status_damage(damage, DamageNumber.DamageType.BLEED)
		StatusEffect.Type.INFECTED:
			_spawn_giblets(effect.stacks)
		StatusEffect.Type.SHOCK:
			status_timers.erase("shock_spawned")


func _take_status_damage(damage: int, damage_type: DamageNumber.DamageType) -> void:
	current_health -= damage
	health_bar.update_health(current_health)
	
	var dmg_num = DamageNumberScene.instantiate()
	get_tree().root.add_child(dmg_num)
	dmg_num.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	dmg_num.setup(damage, damage_type)
	
	if current_health <= 0:
		_die()


func _chain_lightning(damage: int) -> void:
	var shock_radius: float = 100.0

	var shock_vfx = ShockEffectScene.instantiate()
	get_tree().root.add_child(shock_vfx)
	shock_vfx.global_position = global_position
	shock_vfx.setup(shock_radius, damage, self)

func _spawn_giblets(stacks: int) -> void:
	var giblet_count = 3
	var damage_percent = 0.15 + (stacks * 0.015)
	var damage = int(modified_health * damage_percent)
	
	for i in range(giblet_count):
		var giblet = GibletScene.instantiate()
		get_tree().root.add_child(giblet)
		giblet.global_position = global_position

		var angle = randf() * TAU
		var dir = Vector2(cos(angle), sin(angle))
		giblet.setup(dir, damage)

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

func set_level(new_level: int) -> void:
	level = new_level
	
	# DEMO: All levels have 15% chance for modifier (regular game: level 15+)
	if randf() <= 0.15:
		var modifier = Enums.EnemyModifier.values()[randi() % Enums.EnemyModifier.size()]
		modifiers.append(modifier)
		
		# 15% chance for second modifier
		if randf() <= 0.10:
			var modifier2 = Enums.EnemyModifier.values()[randi() % Enums.EnemyModifier.size()]
			modifiers.append(modifier2)
			
			# 5% chance for third modifier
			if randf() <= 0.05:
				var modifier3 = Enums.EnemyModifier.values()[randi() % Enums.EnemyModifier.size()]
				modifiers.append(modifier3)
