class_name WeaponInstanceData
extends Resource

@export var base: WeaponBaseData
@export var parts: Array[WeaponPartData] = []

#calculats for final stats
var final_damage: int
var final_puncture: int
var final_accuracy_min: int
var final_accuracy_max: int
var final_fire_rate: float
var final_magazine_size: int
var final_crit_chance: float
var final_crit_damage: float
var final_projectile_count: int
var final_reload_speed: float

func calculate_stats() -> void:
	if base == null:
		return
	
	#starts with base stats
	final_damage = base.base_damage
	final_puncture = base.base_puncture
	final_accuracy_min = base.base_accuracy_min
	final_accuracy_max = base.base_accuracy_max
	final_fire_rate = base.base_fire_rate
	final_magazine_size = base.base_magazine_size
	final_crit_chance = base.base_crit_chance
	final_crit_damage = base.base_crit_damage
	final_projectile_count = base.base_projectile_count
	final_reload_speed = base.base_reload_speed
	
	for part in parts:
		final_damage += int(part.damage_modifier)
		final_puncture += part.puncture_modifier
		final_accuracy_min += part.accuracy_modifier
		final_accuracy_max += part.accuracy_modifier
		final_fire_rate += part.fire_rate_modifier
		final_magazine_size += part.magazine_modifier
		final_crit_chance += part.crit_chance_modifier
		final_crit_damage += part.crit_damage_modifier
		final_reload_speed += part.reload_speed_modifier

func get_part_by_type(part_type: Enums.PartType) -> WeaponPartData:
	for part in parts:
		if part.part_type == part_type:
			return part
	return null

func has_effect(effect_id: String) -> bool:
	for part in parts: 
		if part.effect_id == effect_id:
			return true
	return false
