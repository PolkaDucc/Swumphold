class_name Weapon
extends Node2D

@onready var body_sprite: Sprite2D = $BodySprite
@onready var barrel_sprite: Sprite2D = $BarrelSprite
@onready var handle_sprite: Sprite2D = $HandleSprite
@onready var magazine_sprite: Sprite2D = $MagazineSprite

var weapon_data: WeaponInstanceData
var current_ammo: int = 0
var is_reloading: bool = false
var fire_rate_timer: float = 0.0
var shots_this_mag: int = 0
var crit_fire_rate_stacks: int = 0
var crit_stack_timer: float = 0.0
var fire_rate_bonus: float = 0.0
var puncture_bonus: int = 0
var damage_bonus: float = 0.0
var consecutive_hits: int = 0
var random_fire_rate_mult: float = 1.0
var purple_handle_pierce_stacks: int = 0
var orange_handle_puncture_stacks: int = 0
var mag_broken: bool = false
var mag_broken_timer: float = 0.0

func setup(data: WeaponInstanceData) -> void:
	weapon_data = data
	current_ammo = data.final_magazine_size
	_load_part_sprites()
	_reset_runtime_bonuses()


func _load_part_sprites() -> void:
	# TODO: Load sprites based on weapon_data.parts
	for part in weapon_data.parts:
		match part.part_type:
			Enums.PartType.BODY:
				pass
			Enums.PartType.BARREL:
				pass
			Enums.PartType.HANDLE:
				pass
			Enums.PartType.MAGAZINE:
				pass


func _reset_runtime_bonuses() -> void:
	fire_rate_bonus = 0.0
	puncture_bonus = 0
	damage_bonus = 0.0
	consecutive_hits = 0
	purple_handle_pierce_stacks = 0
	orange_handle_puncture_stacks = 0


func get_fire_rate() -> float:
	if weapon_data.has_effect("pistol_barrel_blue"):
		return 0.5
	var rate = weapon_data.final_fire_rate + fire_rate_bonus
	rate *= 1.0 + (crit_fire_rate_stacks * 0.15)
	rate *= random_fire_rate_mult
	return rate


func get_crit_chance() -> float:
	var chance = weapon_data.final_crit_chance
	chance += crit_fire_rate_stacks * 0.05
	return chance


func get_damage() -> int:
	var dmg = weapon_data.final_damage * (1.0 + damage_bonus)
	dmg *= 1.0 + get_blue_barrel_damage_bonus()

	if mag_broken:
		dmg *= 1.55
	
	return int(dmg)


func get_puncture() -> int:
	var punc = weapon_data.final_puncture + puncture_bonus

	if weapon_data.has_effect("pistol_handle_green"):
		punc += weapon_data.final_magazine_size

	if weapon_data.has_effect("pistol_handle_orange"):
		punc += orange_handle_puncture_stacks * 15

	if weapon_data.has_effect("pistol_handle_pink"):
		punc += 10
	
	return punc


func get_accuracy() -> int:
	var acc = weapon_data.final_accuracy

	if weapon_data.has_effect("pistol_handle_pink"):
		return 5
	
	return acc


func get_pierce() -> int:
	var p = 0
	if weapon_data.has_effect("pistol_handle_purple"):
		p += 1 + purple_handle_pierce_stacks
	
	return p


func get_pierce_puncture_bonus() -> int:
	if weapon_data.has_effect("pistol_handle_purple"):
		return 10
	return 0


func get_body_effects() -> Dictionary:
	var result = {
		"ignite_chance": 0.0,
		"bonus_puncture": 0,
		"knockback_mult": 1.0,
		"ricochet_on_crit": false,
		"grows_over_distance": false,
		"is_sonar_wave": false,
		"pierce": get_pierce()
	}

	if weapon_data.has_effect("pistol_body_white"):
		result.ignite_chance = 0.10

	if weapon_data.has_effect("pistol_body_blue"):
		result.knockback_mult = 2.0

	if weapon_data.has_effect("pistol_body_orange"):
		result.ricochet_on_crit = true

	if weapon_data.has_effect("pistol_body_red"):
		result.grows_over_distance = true

	if weapon_data.has_effect("pistol_body_pink"):
		result.is_sonar_wave = true
	
	return result


func get_puncture_with_body(is_crit: bool) -> int:
	var punc = get_puncture()

	if weapon_data.has_effect("pistol_body_purple"):
		if is_crit:
			if randf() <= 0.50:
				punc += 75
		else:
			if randf() <= 0.25:
				punc += 50
	
	return punc


func get_damage_with_body() -> int:
	var dmg = get_damage()

	if weapon_data.has_effect("pistol_body_green"):
		dmg = int(dmg * (1.0 + weapon_data.final_magazine_size * 0.01))
	
	return dmg


func on_hit() -> void:
	consecutive_hits += 1
	_process_hit_effects()


func on_miss() -> void:
	consecutive_hits = 0
	_process_miss_effects()


func on_crit_handle() -> void:
	if weapon_data.has_effect("pistol_handle_orange"):
		orange_handle_puncture_stacks += 1


func on_kill() -> void:
	if weapon_data.has_effect("pistol_body_green"):
		var restore = int(weapon_data.final_magazine_size * 0.05)
		restore = max(1, restore)
		current_ammo = min(current_ammo + restore, weapon_data.final_magazine_size)
		print("Kill restored ", restore, " ammo! Ammo: ", current_ammo)
	
	_process_kill_effects()


func on_reload() -> void:
	_reset_runtime_bonuses()
	shots_this_mag = 0
	_process_reload_effects()


func _process_hit_effects() -> void:
	if weapon_data.has_effect("pistol_handle_purple"):
		purple_handle_pierce_stacks += 1


func _process_miss_effects() -> void:
	if weapon_data.has_effect("pistol_handle_blue"):
		puncture_bonus += 3
		damage_bonus += 0.10

	if weapon_data.has_effect("pistol_handle_orange"):
		orange_handle_puncture_stacks = 0

	if weapon_data.has_effect("pistol_handle_purple"):
		purple_handle_pierce_stacks = 0


func _process_kill_effects() -> void:
	pass


func _process_reload_effects() -> void:
	if weapon_data.has_effect("pistol_barrel_red"):
		random_fire_rate_mult = randf_range(0.7, 5.0)
		print("Fire rate randomized to: ", random_fire_rate_mult, "x")

	if weapon_data.has_effect("pistol_mag_white"):
		if randf() <= 0.20:
			mag_broken = true
			mag_broken_timer = 5.0
			current_ammo = int(current_ammo * 0.45)
			print("Magazine BROKE! Ammo reduced to ", current_ammo, ", +55% damage for 5s")


func process_barrel_effects() -> Dictionary:
	var result = {
		"extra_projectiles": 0,
		"delay_fire": false,
		"delay_bullets": 0,
		"portal_bullet": false
	}
	
	shots_this_mag += 1

	if weapon_data.has_effect("pistol_barrel_white"):
		if randf() <= 0.15:
			result.delay_fire = true
			result.delay_bullets = current_ammo

	if weapon_data.has_effect("pistol_barrel_green"):
		if randf() <= 0.33:
			result.extra_projectiles = randi_range(1, 4)

	if weapon_data.has_effect("pistol_barrel_purple"):
		fire_rate_bonus = shots_this_mag * 0.5

	if weapon_data.has_effect("pistol_barrel_pink"):
		if consecutive_hits > 3 and randf() <= 0.25:
			result.portal_bullet = true
			print("PORTAL BULLET!")
	
	return result


func on_crit() -> void:
	if weapon_data.has_effect("pistol_barrel_orange"):
		crit_fire_rate_stacks += 1
		crit_stack_timer = 2.0


func _process(delta: float) -> void:
	if crit_stack_timer > 0:
		crit_stack_timer -= delta
		if crit_stack_timer <= 0:
			crit_fire_rate_stacks = 0

	if mag_broken_timer > 0:
		mag_broken_timer -= delta
		if mag_broken_timer <= 0:
			mag_broken = false
			print("Magazine fixed!")


func get_blue_barrel_damage_bonus() -> float:
	if weapon_data.has_effect("pistol_barrel_blue"):
		var fire_rate_lost = weapon_data.final_fire_rate - 0.5
		if fire_rate_lost > 0:
			var bonus = (fire_rate_lost / 0.5) * 0.77
			return bonus
	return 0.0
