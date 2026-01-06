class_name WeaponInstanceData
extends Resource

@export var base: WeaponBaseData
@export var parts: Array[WeaponPartData] = []

var final_damage: int
var final_puncture: int
var final_accuracy: int
var final_fire_rate: float
var final_magazine_size: int
var final_crit_chance: float
var final_crit_damage: float
var final_projectile_count: int
var final_reload_speed: float
var manufacturer: Enums.Manufacturer
var weapon_name: String
var stat_modifiers: Dictionary = {}

func calculate_stats() -> void:
	if not base:
		return

	final_damage = base.base_damage
	final_puncture = base.base_puncture
	final_accuracy = base.base_accuracy
	final_fire_rate = base.base_fire_rate
	final_magazine_size = base.base_magazine_size
	final_crit_chance = base.base_crit_chance
	final_crit_damage = base.base_crit_damage
	final_projectile_count = base.base_projectile_count
	final_reload_speed = base.base_reload_speed

	for part in parts:
		final_damage += int(base.base_damage * part.damage_modifier)
		final_puncture += part.puncture_modifier
		final_accuracy += part.accuracy_modifier

	if stat_modifiers.has("damage"):
		final_damage += int(base.base_damage * stat_modifiers["damage"] / 100.0)
	if stat_modifiers.has("fire_rate"):
		final_fire_rate += base.base_fire_rate * stat_modifiers["fire_rate"] / 100.0
	if stat_modifiers.has("puncture"):
		final_puncture += int(stat_modifiers["puncture"])
	if stat_modifiers.has("accuracy"):
		final_accuracy += stat_modifiers["accuracy"]
	if stat_modifiers.has("magazine"):
		final_magazine_size += int(base.base_magazine_size * stat_modifiers["magazine"] / 100.0)
	if stat_modifiers.has("crit_chance"):
		final_crit_chance += stat_modifiers["crit_chance"] / 100.0
	if stat_modifiers.has("crit_damage"):
		final_crit_damage += stat_modifiers["crit_damage"] / 100.0
	if stat_modifiers.has("reload_speed"):
		final_reload_speed -= base.base_reload_speed * stat_modifiers["reload_speed"] / 100.0
		final_reload_speed = max(0.5, final_reload_speed)

	final_accuracy = max(1, final_accuracy)

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

func get_quality() -> float:
	
	if parts.is_empty():
		return 0.0
	
	var total_rarity = 0.0
	for part in parts:
		total_rarity += part.rarity

	return (total_rarity / parts.size()) / 6.0

func get_display_name() -> String:
	var prefix = ManufacturerData.get_prefix(manufacturer, get_quality())
	return prefix + " " + weapon_name
