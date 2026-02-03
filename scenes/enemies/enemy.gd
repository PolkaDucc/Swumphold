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
const MilitantAuraScene = preload("res://scenes/effects/militant_aura.tscn")

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
var is_dead: bool = false
var last_known_player_pos: Vector2 = Vector2.ZERO
var charge_target: Vector2 = Vector2.ZERO
var charge_timer: float = 0.0
var is_charging: bool = false
var avoid_direction: Vector2 = Vector2.ZERO
var avoid_timer: float = 0.0
var search_timer: float = 0.0
var attack_cooldown: float = 0.0
var attacks_before_reposition: int = 0
var is_repositioning: bool = false
var reposition_phase: int = 0 # 0 = not repositioning, 1 = fleeing, 2 = positioning
var reposition_timer: float = 0.0
var current_move_direction: Vector2 = Vector2.ZERO
var base_scale: Vector2 = Vector2.ONE
var is_clone: bool = false
var parasitic_stolen_health: int = 0
var has_militant_buff: bool = false
var militant_aura: Node2D = null
var skip_random_modifiers: bool = false


func _ready() -> void:
	set_level(level)
	_apply_modifiers()
	
	if Enums.EnemyModifier.MILITANT in modifiers:
		militant_aura = MilitantAuraScene.instantiate()
		add_child(militant_aura)
	current_health = modified_health
	if Enums.EnemyModifier.PARASITIC in modifiers:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.character_data:
			parasitic_stolen_health = int(player.character_data.max_health * 0.25)
			player.character_data.max_health -= parasitic_stolen_health
			player.current_health = min(player.current_health, player.character_data.max_health)
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
	if is_dead:
		return
	
	if is_aggroed:
		aggro_timer -= delta
		if aggro_timer <= 0:
			is_aggroed = false
	
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	if avoid_timer > 0:
		avoid_timer -= delta
	
	if reposition_timer > 0:
		reposition_timer -= delta
		if reposition_timer <= 0:
			if reposition_phase == 1:
				reposition_phase = 2
				reposition_timer = 1.0
			elif reposition_phase == 2:
				is_repositioning = false
				reposition_phase = 0
	
	_process_status_effects(delta)
	if is_dead:
		return
	_update_state()
	has_militant_buff = false
	if Enums.EnemyModifier.MILITANT not in modifiers:
		var enemies = get_tree().get_nodes_in_group("enemy")
		for other in enemies:
			if other == self or other.is_dead:
				continue
			if Enums.EnemyModifier.MILITANT in other.modifiers:
				if global_position.distance_to(other.global_position) < 100:
					has_militant_buff = true
					break
	_execute_state(delta)
	_handle_entity_push()

	if knockback_velocity.length() > 0:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
	
	move_and_slide()


func _update_state() -> void:
	if is_attacking or is_charging:
		return
	
	if not target:
		current_state = Enums.EnemyState.WANDER
		return

	if is_infected():
		var nearest_ally = _find_nearest_ally()
		if nearest_ally:
			target = nearest_ally
			attack_hitbox.set_collision_mask_value(1, false) #don hurt da playa
			attack_hitbox.set_collision_mask_value(2, true) #hurt da enemy
	else:
		attack_hitbox.set_collision_mask_value(1, true) #start detecting player again
		attack_hitbox.set_collision_mask_value(2, false) #no hurt da enemy

	if target.get("is_dead"):
		current_state = Enums.EnemyState.WANDER
		is_aggroed = false
		target = null
		return
	
	var distance = global_position.distance_to(target.global_position)
	var aggro_range = enemy_data.aggro_range if enemy_data else 150.0
	var attack_range = enemy_data.attack_range if enemy_data else 20.0
	var is_ranged = enemy_data.is_ranged if enemy_data else false
	var health_percent = float(current_health) / float(modified_health)

	if is_aggroed or distance <= aggro_range:
		last_known_player_pos = target.global_position
	if is_repositioning:
		if reposition_phase == 1:
			current_state = Enums.EnemyState.FLEE
		elif reposition_phase == 2:
			current_state = Enums.EnemyState.POSITION
		return
	if enemy_data:
		if enemy_data.can_heal and _should_heal():
			current_state = Enums.EnemyState.HEAL
			return
		if enemy_data.can_buff and _should_buff():
			current_state = Enums.EnemyState.BUFF
			return
		if enemy_data.can_spawn and _should_spawn():
			current_state = Enums.EnemyState.SPAWN
			return
		if enemy_data.can_shield and _should_shield():
			current_state = Enums.EnemyState.SHIELD
			return
	if health_percent < 0.3:
		if level >= 5 and is_ranged:
			current_state = Enums.EnemyState.HIDE
			return
		else:
			current_state = Enums.EnemyState.FLEE
			return
	if distance <= attack_range:
		if is_ranged:
			current_state = Enums.EnemyState.ATTACK_FAR
		else:
			current_state = Enums.EnemyState.ATTACK_CLOSE
		return
	if level >= 5 and is_ranged:
		if health_percent < 0.5 and randf() < 0.3:
			current_state = Enums.EnemyState.ATTACK_FLEE
			return
		if randf() < 0.2:
			current_state = Enums.EnemyState.ATTACK_AVOID
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
		Enums.EnemyState.ATTACK_FAR:
			_state_attack_far()
		Enums.EnemyState.FLEE:
			_state_flee()
		Enums.EnemyState.SPAWN:
			_state_spawn()
		Enums.EnemyState.SHIELD:
			_state_shield()
		Enums.EnemyState.HEAL:
			_state_heal()
		Enums.EnemyState.BUFF:
			_state_buff()
		Enums.EnemyState.CHARGE:
			_state_charge(delta)
		Enums.EnemyState.ATTACK_AVOID:
			_state_attack_avoid(delta)
		Enums.EnemyState.ATTACK_FLEE:
			_state_attack_flee()
		Enums.EnemyState.FIRE_FROM_COVER:
			_state_fire_from_cover()
		Enums.EnemyState.HIDE:
			_state_hide()
		Enums.EnemyState.SEARCH:
			_state_search(delta)


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
		current_move_direction = current_move_direction.lerp(wander_direction, 0.05)
		
		var speed = BASE_SPEED * 0.5 * modified_speed

		if has_status(StatusEffect.Type.FREEZE):
			speed *= 0.5
		
		velocity = current_move_direction * speed
		animated_sprite.flip_h = velocity.x < 0
		attack_hitbox.scale.x = -1 if velocity.x < 0 else 1
		animated_sprite.play("walk")
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")

func _state_position() -> void:
	var direction = (target.global_position - global_position).normalized()

	current_move_direction = current_move_direction.lerp(direction, 0.1)
	
	var speed = BASE_SPEED * modified_speed
	if has_militant_buff:
		speed *= 1.25

	if has_status(StatusEffect.Type.FREEZE):
		speed *= 0.5
	
	velocity = current_move_direction * speed
	
	animated_sprite.flip_h = velocity.x < 0
	attack_hitbox.scale.x = -1 if velocity.x < 0 else 1
	animated_sprite.play("walk")

func _state_attack_close() -> void:
	velocity = Vector2.ZERO

	if target and target.has_method("is_dead") and target.is_dead:
		current_state = Enums.EnemyState.WANDER
		is_aggroed = false
		return
	
	if not is_attacking:
		is_attacking = true
		has_hit_this_attack = false
		animated_sprite.play("attack")
		if Enums.EnemyModifier.JUICED in modifiers:
			animated_sprite.speed_scale = 1.5
		else:
			animated_sprite.speed_scale = 1.0
		attacks_before_reposition += 1

func _state_attack_far() -> void:
	velocity = Vector2.ZERO
	
	if not is_attacking and attack_cooldown <= 0:
		is_attacking = true
		has_hit_this_attack = false
		animated_sprite.play("attack")
		attack_cooldown = 1.5
		# TODO: Spawn projectile at attack frame

func _state_flee() -> void:
	if not target:
		return

	var to_player = (target.global_position - global_position).normalized()
	var perpendicular = Vector2(-to_player.y, to_player.x)

	if avoid_timer <= 0:
		avoid_timer = randf_range(0.5, 1.0)
		if randf() > 0.5:
			perpendicular = -perpendicular
		avoid_direction = (perpendicular + to_player * -0.3).normalized()
	current_move_direction = current_move_direction.lerp(avoid_direction, 0.1)
	var speed = BASE_SPEED * modified_speed * 1.2
	if has_status(StatusEffect.Type.FREEZE):
		speed *= 0.5
	
	velocity = current_move_direction * speed
	animated_sprite.flip_h = velocity.x < 0
	attack_hitbox.scale.x = -1 if velocity.x < 0 else 1
	animated_sprite.play("walk")

func _state_spawn() -> void:
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	# TODO: Implement minion spawning

func _state_shield() -> void:
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	# TODO: Implement shield behavior

func _state_heal() -> void:
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	# TODO: Implement healing

func _state_buff() -> void:
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	# TODO: Implement buffing

func _state_charge(delta: float) -> void:
	if not is_charging:
		is_charging = true
		charge_timer = 2.0
		charge_target = target.global_position if target else global_position
		velocity = Vector2.ZERO
		animated_sprite.play("idle")
		return
	
	charge_timer -= delta
	
	if charge_timer <= 0:
		var direction = (charge_target - global_position).normalized()
		var speed = BASE_SPEED * modified_speed * 3.0
		velocity = direction * speed
		animated_sprite.play("walk")

		if global_position.distance_to(charge_target) < 20:
			is_charging = false

func _state_attack_avoid(delta: float) -> void:
	if not target:
		return

	avoid_timer -= delta
	if avoid_timer <= 0:
		avoid_timer = randf_range(0.3, 0.8)
		avoid_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	
	var speed = BASE_SPEED * modified_speed
	if has_status(StatusEffect.Type.FREEZE):
		speed *= 0.5
	
	velocity = avoid_direction * speed

	animated_sprite.flip_h = target.global_position.x < global_position.x
	attack_hitbox.scale.x = -1 if target.global_position.x < global_position.x else 1
	animated_sprite.play("walk")

	if not is_attacking and attack_cooldown <= 0:
		is_attacking = true
		attack_cooldown = 1.5

func _state_attack_flee() -> void:
	if not target:
		return
	var direction = (global_position - target.global_position).normalized()
	var speed = BASE_SPEED * modified_speed * 0.8
	
	if has_status(StatusEffect.Type.FREEZE):
		speed *= 0.5
	
	velocity = direction * speed
	animated_sprite.flip_h = direction.x < 0
	attack_hitbox.scale.x = -1 if direction.x < 0 else 1
	animated_sprite.play("walk")
	if not is_attacking and attack_cooldown <= 0:
		is_attacking = true
		attack_cooldown = 2.0

func _state_fire_from_cover() -> void:
	# TODO: Find cover position and fire from there
	_state_attack_far()

func _state_hide() -> void:
	if not target:
		return
	var direction = (global_position - target.global_position).normalized()
	var speed = BASE_SPEED * modified_speed * 0.6
	
	if has_status(StatusEffect.Type.FREEZE):
		speed *= 0.5
	
	velocity = direction * speed
	animated_sprite.flip_h = direction.x < 0
	animated_sprite.play("walk")

func _state_search(delta: float) -> void:
	search_timer -= delta
	
	if search_timer <= 0:
		search_timer = randf_range(1.0, 2.0)
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		wander_direction = (last_known_player_pos + offset - global_position).normalized()
	
	var speed = BASE_SPEED * modified_speed * 0.5
	if has_status(StatusEffect.Type.FREEZE):
		speed *= 0.5
	
	velocity = wander_direction * speed
	animated_sprite.flip_h = velocity.x < 0
	animated_sprite.play("walk")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		animated_sprite.speed_scale = 1.0

		if attacks_before_reposition >= randi_range(1, 3):
			attacks_before_reposition = 0
			is_repositioning = true
			reposition_phase = 1  # start fleeing
			reposition_timer = 1.0

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
		var damage_to_deal = modified_damage
		if has_status(StatusEffect.Type.DUUMITE):
			var stacks = get_status_stacks(StatusEffect.Type.DUUMITE)
			var reduction = 0.5 - (stacks - 1) * 0.01
			reduction = max(0.1, reduction)  # cap at 90% reduction
			damage_to_deal = int(damage_to_deal * reduction)
		
		var puncture_to_deal = 0
		if Enums.EnemyModifier.SPIKED in modifiers:
			puncture_to_deal= 15
		if Enums.EnemyModifier.MONK in modifiers:
			if body.has_method("apply_knockback"):
				var kb_dir = (body.global_position - global_position).normalized()
				body.apply_knockback(kb_dir, float(damage_to_deal) * 45.0)
		else:
			body.take_damage(damage_to_deal, puncture_to_deal)
		has_hit_this_attack = true
		if Enums.EnemyModifier.VAMPIRIC in modifiers:
			var heal_amount = int(modified_health * 0.15)
			current_health = min(current_health + heal_amount, modified_health)
			health_bar.update_health(current_health)
		if Enums.EnemyModifier.STICKY in modifiers:
			if body.has_method("apply_slow"):
				body.apply_slow(0.05) 
		
		if body.has_method("apply_status"):
			if Enums.EnemyModifier.INFLAMED in modifiers:
				body.apply_status(StatusEffect.Type.FIRE, damage_to_deal)
			if Enums.EnemyModifier.COLD in modifiers:
				body.apply_status(StatusEffect.Type.FREEZE, damage_to_deal)
			if Enums.EnemyModifier.EVIL in modifiers:
				body.apply_status(StatusEffect.Type.CORRUPT, damage_to_deal)
			if Enums.EnemyModifier.HEMMORAGED in modifiers:
				body.apply_status(StatusEffect.Type.BLEED, damage_to_deal)
			if Enums.EnemyModifier.ELECTRIFIED in modifiers:
				body.apply_status(StatusEffect.Type.SHOCK, damage_to_deal)
			if Enums.EnemyModifier.ZOMBIFIED in modifiers:
				body.apply_status(StatusEffect.Type.INFECTED, damage_to_deal)
			if Enums.EnemyModifier.DUUM_RIDDEN in modifiers:
				body.apply_status(StatusEffect.Type.DUUMITE, damage_to_deal)

func take_damage(amount: int, puncture: int = 0, is_crit: bool = false, knockback: float = 0.0, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	var effective_defense = modified_defense - puncture
	if has_militant_buff:
		effective_defense = int(effective_defense * 1.25)
	var damage_multiplier = 100.0 / max(1.0, 100.0 + effective_defense)
	var final_damage = int(amount * damage_multiplier)

	if has_status(StatusEffect.Type.FREEZE):
		var stacks = get_status_stacks(StatusEffect.Type.FREEZE)
		var freeze_bonus = 0.10 + (stacks - 1) * 0.05
		final_damage = int(final_damage * (1.0 + freeze_bonus))

	if has_status(StatusEffect.Type.DUUMITE):
		var stacks = get_status_stacks(StatusEffect.Type.DUUMITE)
		var duumite_mult = 1.5 + (stacks - 1) * 0.01
		final_damage = int(final_damage * duumite_mult)
	
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
	if is_dead:
		return
	is_dead = true
	print("Enemy dying, playing death animation")
	set_physics_process(false)

	var player = get_tree().get_first_node_in_group("player")
	if player and player.current_weapon:
		player.current_weapon.on_kill()
	
	if Enums.EnemyModifier.BLOATED in modifiers:
		_spawn_bloated_maggots()
	if Enums.EnemyModifier.ASEXUAL in modifiers:
		_spawn_asexual_clones()
	if Enums.EnemyModifier.PARASITIC in modifiers:
		if player and player.character_data:
			player.character_data.max_health += parasitic_stolen_health
			player.current_health += parasitic_stolen_health
	set_collision_layer_value(2, false)
	set_collision_mask_value(1, false)
	attack_collision.disabled = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	status_effects.clear()
	animated_sprite.stop()
	if animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.play("die")
	else:
		animated_sprite.play("idle")

	await get_tree().create_timer(0.3).timeout
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(0.37, 0.37, 0.37, 1.0), 0.3)



func _apply_modifiers() -> void:
	modified_health = enemy_data.health if enemy_data else 50
	modified_damage = enemy_data.damage if enemy_data else 7
	modified_defense = enemy_data.defense if enemy_data else 15
	modified_speed = enemy_data.move_speed if enemy_data else 1.0

	var level_mult = level - 1
	var player = get_tree().get_first_node_in_group("player")
	@warning_ignore("unused_variable")
	var difficulty_mult = 1.0
	if player:
		difficulty_mult += player.difficulty_bonus
		if player.character_data:
			difficulty_mult += player.character_data.difficulty
	modified_health = int(modified_health * (1.0 + level_mult * 0.35))
	modified_damage = int(modified_damage * (1.0 + level_mult * 0.15))
	modified_defense = int(modified_defense * (1.0 + level_mult * 0.25))
	
	var scale_mod: float = 1.0

	for modifier in modifiers:
		var mods = ModifierEffects.get_stat_mods(modifier)
		modified_health = int(modified_health * mods.health)
		modified_damage = int(modified_damage * mods.damage)
		modified_defense = int(modified_defense * mods.defense)
		modified_speed = modified_speed * mods.speed
		scale_mod = scale_mod * mods.scale

	animated_sprite.scale = Vector2(scale_mod, scale_mod)
	base_scale = animated_sprite.scale

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
			if effect_type == StatusEffect.Type.DUUMITE:
				_update_duumite_size()
			return
	
	var new_effect = StatusEffect.new(effect_type, weapon_damage)
	status_effects.append(new_effect)
	
	if effect_type == StatusEffect.Type.DUUMITE:
		_update_duumite_size()

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


@warning_ignore("unused_parameter")
func _process_shock(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("shock_spawned"):
		status_timers["shock_spawned"] = true
		var damage = int(effect.source_damage * 1.25)
		var bonus = effect.stacks * 0.05
		damage = int(damage * (1.0 + bonus))
		_chain_lightning(damage)


@warning_ignore("unused_parameter")
func _process_infected(effect: StatusEffect, delta: float) -> void:
	pass

func is_infected() -> bool:
	return has_status(StatusEffect.Type.INFECTED)

func _find_nearest_ally() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var nearest_dist: float = 999999.0
	
	for enemy in enemies:
		if enemy == self:
			continue
		if enemy.is_dead:
			continue
		if enemy.is_infected():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest

@warning_ignore("unused_parameter")
func _process_duumite(effect: StatusEffect, delta: float) -> void:
	if not status_timers.has("duumite"):
		status_timers["duumite"] = 0.0
	
	status_timers["duumite"] += delta
	if status_timers["duumite"] >= 1.0:
		status_timers["duumite"] -= 1.0
		var damage_percent = 0.02 + (effect.stacks - 1) * 0.01
		var damage = int(modified_health * damage_percent)
		damage = max(1, damage)
		_take_status_damage(damage, DamageNumber.DamageType.DUUMITE)

func _update_duumite_size() -> void:
	var stacks = get_status_stacks(StatusEffect.Type.DUUMITE)
	var size_mult = 1.35 + (stacks - 1) * 0.01
	var target_scale = base_scale * size_mult
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "scale", target_scale, 0.3).set_ease(Tween.EASE_OUT)

func _should_heal() -> bool:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy != self and enemy.current_health < enemy.modified_health * 0.5:
			if global_position.distance_to(enemy.global_position) < 100:
				return true
	return false

func _should_buff() -> bool:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var allies_nearby = 0
	for enemy in enemies:
		if enemy != self and global_position.distance_to(enemy.global_position) < 100:
			allies_nearby += 1
	return allies_nearby >= 2

func _should_spawn() -> bool:
	if not target:
		return false
	var dist = global_position.distance_to(target.global_position)
	return dist > 50 and dist < 150

func _should_shield() -> bool:
	return is_aggroed and current_health > modified_health * 0.5


func _on_effect_expire(effect: StatusEffect) -> void:
	match effect.type:
		StatusEffect.Type.BLEED:
			var damage = int(modified_health * 0.15)
			_take_status_damage(damage, DamageNumber.DamageType.BLEED)
		StatusEffect.Type.INFECTED:
			_spawn_giblets(effect.stacks)
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				target = players[0]
			attack_hitbox.set_collision_mask_value(1, true)
			attack_hitbox.set_collision_mask_value(2, false)
		StatusEffect.Type.SHOCK:
			status_timers.erase("shock_spawned")
		StatusEffect.Type.DUUMITE:
			var tween = create_tween()
			tween.tween_property(animated_sprite, "scale", base_scale, 0.3).set_ease(Tween.EASE_OUT)
	
func _take_status_damage(damage: int, damage_type: DamageNumber.DamageType) -> void:
	if is_dead:
		return
	
	var final_damage = damage
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var elem_bonus = player.elemental_damage_bonus
		if player.character_data:
			elem_bonus += player.character_data.elemental_damage
		final_damage = int(final_damage * (1.0 + elem_bonus)) 
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

func _spawn_asexual_clones() -> void:
	if is_clone:
		return
	var enemy_scene = preload("res://scenes/enemies/enemy.tscn")
	for i in range(2):
		var clone = enemy_scene.instantiate()
		clone.enemy_data = enemy_data
		clone.level = level
		clone.is_clone = true
		# remove ASEXUAL from clone modifiers
		clone.modifiers = modifiers.duplicate()
		clone.modifiers.erase(Enums.EnemyModifier.ASEXUAL)
		get_parent().add_child(clone)
		var offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		clone.global_position = global_position + offset

func _spawn_bloated_maggots() -> void:
	# TODO: spawn 5 Maggahs or Spittahs when those enemy types exist
	# For now, spawn giblets as placeholder
	for i in range(5):
		var giblet = GibletScene.instantiate()
		get_tree().root.add_child(giblet)
		giblet.global_position = global_position
		var angle = randf() * TAU
		var dir = Vector2(cos(angle), sin(angle))
		giblet.setup(dir, int(modified_health * 0.1))

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
	
	# DEMO: all levels have 15% chance for modifier (regular game: level 15+)
	if not skip_random_modifiers:
		if randf() <= 0.10:
			var modifier = Enums.EnemyModifier.values()[randi() % Enums.EnemyModifier.size()]
			modifiers.append(modifier)
		
			# 15% chance for second modifier
			if randf() <= 0.05:
				var modifier2 = Enums.EnemyModifier.values()[randi() % Enums.EnemyModifier.size()]
				modifiers.append(modifier2)
			
				# 5% chance for third modifier
				if randf() <= 0.01:
					var modifier3 = Enums.EnemyModifier.values()[randi() % Enums.EnemyModifier.size()]
					modifiers.append(modifier3)

func _handle_entity_push() -> void:
	var push_force = 50.0
	var push_radius = 20.0

	var enemies = get_tree().get_nodes_in_group("enemy")
	for other in enemies:
		if other == self or other.is_dead:
			continue
		var distance = global_position.distance_to(other.global_position)
		if distance < push_radius and distance > 0:
			var push_dir = (global_position - other.global_position).normalized()
			var push_strength = (push_radius - distance) / push_radius
			velocity += push_dir * push_force * push_strength

	var player = get_tree().get_first_node_in_group("player")
	if player and not player.is_dead:
		var distance = global_position.distance_to(player.global_position)
		if distance < push_radius and distance > 0:
			var push_dir = (global_position - player.global_position).normalized()
			var push_strength = (push_radius - distance) / push_radius
			velocity += push_dir * push_force * push_strength
