extends Node

const RARITY_WEIGHTS: Dictionary = {
	Enums.Rarity.WHITE: 33.0,
	Enums.Rarity.GREEN: 26.9,
	Enums.Rarity.BLUE: 19.8,
	Enums.Rarity.PURPLE: 10.6,
	Enums.Rarity.ORANGE: 5.5,
	Enums.Rarity.RED: 3.2,
	Enums.Rarity.PINK: 1.0,
}

var weapon_bases: Dictionary = {}

var part_registry: Dictionary = {}


func _ready() -> void:
	_load_weapon_bases()
	_register_parts()


func _load_weapon_bases() -> void:
	weapon_bases[Enums.WeaponType.PISTOL] = preload("res://resources/weapons/pistol_base.tres")
	weapon_bases[Enums.WeaponType.WAND] = preload("res://resources/weapons/wand_base.tres")


func _register_parts() -> void:

	for weapon_type in Enums.WeaponType.values():
		part_registry[weapon_type] = {}
		for part_type in Enums.PartType.values():
			part_registry[weapon_type][part_type] = {}
			for rarity in Enums.Rarity.values():
				part_registry[weapon_type][part_type][rarity] = null

	_register_pistol_parts()
	_register_wand_parts()


func _register_pistol_parts() -> void:
	var pistol = Enums.WeaponType.PISTOL
	
	# BARREL parts (affect fire rate)
	_create_part(pistol, Enums.PartType.BARREL, Enums.Rarity.WHITE,
		"Jammed barrel that fires remaining mag after delay",
		"pistol_barrel_white")
	
	_create_part(pistol, Enums.PartType.BARREL, Enums.Rarity.GREEN,
		"33% chance to fire 2-5 bullets",
		"pistol_barrel_green")
	
	_create_part(pistol, Enums.PartType.BARREL, Enums.Rarity.BLUE,
		"Fire rate locked to 0.5, +45% damage per 0.5 fire rate lost",
		"pistol_barrel_blue")
	
	_create_part(pistol, Enums.PartType.BARREL, Enums.Rarity.PURPLE,
		"Fire rate ramps +0.5 per shot, resets on reload",
		"pistol_barrel_purple")
	
	_create_part(pistol, Enums.PartType.BARREL, Enums.Rarity.ORANGE,
		"Crits give +25% fire rate and +5% crit chance, stacks decay after 2s",
		"pistol_barrel_orange")
	
	_create_part(pistol, Enums.PartType.BARREL, Enums.Rarity.RED,
		"On reload, randomize fire rate from 0.7x to 5x base",
		"pistol_barrel_red")
	
	_create_part(pistol, Enums.PartType.BARREL, Enums.Rarity.PINK,
		"3+ consecutive hits have 75% chance to fire portal bullet",
		"pistol_barrel_pink")
	
	# MAGAZINE parts (affect ammo count)
	_create_part(pistol, Enums.PartType.MAGAZINE, Enums.Rarity.WHITE,
		"Chance to break on reload: +55% damage, -55% ammo",
		"pistol_mag_white")
	
	_create_part(pistol, Enums.PartType.MAGAZINE, Enums.Rarity.GREEN,
		"Hits add 25% mag size to next mag, extra ammo adds 15% damage",
		"pistol_mag_green")
	
	_create_part(pistol, Enums.PartType.MAGAZINE, Enums.Rarity.BLUE,
		"Converge bullets into 2 magnum shots, +20% damage per bullet lost",
		"pistol_mag_blue")
	
	_create_part(pistol, Enums.PartType.MAGAZINE, Enums.Rarity.PURPLE,
		"Consecutive hits add +1 mag, 10 hits upgrades max mag by 1 temporarily",
		"pistol_mag_purple")
	
	_create_part(pistol, Enums.PartType.MAGAZINE, Enums.Rarity.ORANGE,
		"Crits return bullet at double damage, half crit chance",
		"pistol_mag_orange")
	
	_create_part(pistol, Enums.PartType.MAGAZINE, Enums.Rarity.RED,
		"Infinite ammo, but overheats for 3s cooldown",
		"pistol_mag_red")
	
	_create_part(pistol, Enums.PartType.MAGAZINE, Enums.Rarity.PINK,
		"Mag size scales with missing health: +25% per 5 HP lost",
		"pistol_mag_pink")
	
	# BODY parts (affect damage)
	_create_part(pistol, Enums.PartType.BODY, Enums.Rarity.WHITE,
		"Overheats when firing, 10% chance to ignite",
		"pistol_body_white")
	
	_create_part(pistol, Enums.PartType.BODY, Enums.Rarity.GREEN,
		"Kills restore 35% mag, damage scales with 50% mag size",
		"pistol_body_green")
	
	_create_part(pistol, Enums.PartType.BODY, Enums.Rarity.BLUE,
		"Double knockback, +50% damage",
		"pistol_body_blue", 0, 0.5)
	
	_create_part(pistol, Enums.PartType.BODY, Enums.Rarity.PURPLE,
		"3-burst fire, 30 puncture",
		"pistol_body_purple")
	
	_create_part(pistol, Enums.PartType.BODY, Enums.Rarity.ORANGE,
		"Crits ricochet, 3rd ricochet deals triple damage",
		"pistol_body_orange")
	
	_create_part(pistol, Enums.PartType.BODY, Enums.Rarity.RED,
		"Bullets grow over distance, +45% damage per 0.5s travel",
		"pistol_body_red")
	
	_create_part(pistol, Enums.PartType.BODY, Enums.Rarity.PINK,
		"Bullets start slow, speed up, damage scales with speed",
		"pistol_body_pink")
	
	# HANDLE parts (affect accuracy/puncture)
	_create_part(pistol, Enums.PartType.HANDLE, Enums.Rarity.WHITE,
		"Rusted: +2 accuracy score, +5 puncture",
		"pistol_handle_white", 5, 0, 2)
	
	_create_part(pistol, Enums.PartType.HANDLE, Enums.Rarity.GREEN,
		"Puncture scales with 1.5x max magazine size",
		"pistol_handle_green")
	
	_create_part(pistol, Enums.PartType.HANDLE, Enums.Rarity.BLUE,
		"Accuracy +1, hits grant +5 puncture and +15% damage until reload",
		"pistol_handle_blue", 0, 0, 1)
	
	_create_part(pistol, Enums.PartType.HANDLE, Enums.Rarity.PURPLE,
		"Accuracy -1, +1 pierce, hits grant +1 pierce until miss, +25 puncture per pierce",
		"pistol_handle_purple", 0, 0, -1)
	
	_create_part(pistol, Enums.PartType.HANDLE, Enums.Rarity.ORANGE,
		"Crits grant +2 puncture until reload",
		"pistol_handle_orange")
	
	_create_part(pistol, Enums.PartType.HANDLE, Enums.Rarity.RED,
		"Bullets home after 2s idle, homed hits deal +50 puncture",
		"pistol_handle_red")
	
	_create_part(pistol, Enums.PartType.HANDLE, Enums.Rarity.PINK,
		"Accuracy set to 5, bullets become gem shards with +30 puncture",
		"pistol_handle_pink", 10)


func _register_wand_parts() -> void:
	var wand = Enums.WeaponType.WAND
	
	# RUNE parts (element)
	_create_part(wand, Enums.PartType.RUNE, Enums.Rarity.WHITE,
		"Fire: 1% enemy HP per 0.25s for 4s, stacks add instances",
		"wand_rune_fire")
	
	_create_part(wand, Enums.PartType.RUNE, Enums.Rarity.GREEN,
		"Freeze: Slow + 10% more damage for 3s, stacks add 0.5%",
		"wand_rune_freeze")
	
	_create_part(wand, Enums.PartType.RUNE, Enums.Rarity.BLUE,
		"Corrupt: Poison stacks, 150% of stacks as damage every 4s",
		"wand_rune_corrupt")
	
	_create_part(wand, Enums.PartType.RUNE, Enums.Rarity.PURPLE,
		"Bleed: 2.5% HP per second, stacks extend duration, 15% HP burst on expire",
		"wand_rune_bleed")
	
	_create_part(wand, Enums.PartType.RUNE, Enums.Rarity.ORANGE,
		"Shock: Chain lightning for 250% weapon damage, stacks add 5%",
		"wand_rune_shock")
	
	_create_part(wand, Enums.PartType.RUNE, Enums.Rarity.RED,
		"Infected: Enemies attack allies, explode into giblets after 4s",
		"wand_rune_infected")
	
	_create_part(wand, Enums.PartType.RUNE, Enums.Rarity.PINK,
		"Duumitosis: -50% enemy damage, +150% damage taken, 2% HP/s",
		"wand_rune_duumitosis")
	
	# STAFF parts (bolt pattern)
	_create_part(wand, Enums.PartType.STAFF, Enums.Rarity.WHITE,
		"Bolts bounce off walls and pierce enemies",
		"wand_staff_white")
	
	_create_part(wand, Enums.PartType.STAFF, Enums.Rarity.GREEN,
		"3 bolts in shotgun spread",
		"wand_staff_green")
	
	_create_part(wand, Enums.PartType.STAFF, Enums.Rarity.BLUE,
		"Bolts ricochet to nearest enemy after hit",
		"wand_staff_blue")
	
	_create_part(wand, Enums.PartType.STAFF, Enums.Rarity.PURPLE,
		"3-burst fire, 3rd bolt splits into 3 projectiles",
		"wand_staff_purple")
	
	_create_part(wand, Enums.PartType.STAFF, Enums.Rarity.ORANGE,
		"Bolts boomerang back after 1s with 100% crit",
		"wand_staff_orange")
	
	_create_part(wand, Enums.PartType.STAFF, Enums.Rarity.RED,
		"2 helix bolts, slow, pierce, damage every 0.5s",
		"wand_staff_red")
	
	_create_part(wand, Enums.PartType.STAFF, Enums.Rarity.PINK,
		"5 bolts spray then converge, stick and detonate twice",
		"wand_staff_pink")
	
	# GEM parts (damage)
	_create_part(wand, Enums.PartType.GEM, Enums.Rarity.WHITE,
		"Elemental damage has chance to restore bolts",
		"wand_gem_white")
	
	_create_part(wand, Enums.PartType.GEM, Enums.Rarity.GREEN,
		"50% to chain bolt at 75% damage, chains halve each time",
		"wand_gem_green")
	
	_create_part(wand, Enums.PartType.GEM, Enums.Rarity.BLUE,
		"Kills grant +2% damage for 3s, max 50%, increases bolt size",
		"wand_gem_blue")
	
	_create_part(wand, Enums.PartType.GEM, Enums.Rarity.PURPLE,
		"First 3 bolts deal +20% damage and +2 puncture, doubles on all 3 hit",
		"wand_gem_purple")
	
	_create_part(wand, Enums.PartType.GEM, Enums.Rarity.ORANGE,
		"Crits grant +1.5% damage and crit chance, overflow becomes crit damage",
		"wand_gem_orange")
	
	_create_part(wand, Enums.PartType.GEM, Enums.Rarity.RED,
		"25% of stacks transfer to nearest enemy on kill",
		"wand_gem_red")
	
	_create_part(wand, Enums.PartType.GEM, Enums.Rarity.PINK,
		"15% chance to double stack on apply, scales with kills to 100%",
		"wand_gem_pink")


func _create_part(
	weapon_type: Enums.WeaponType,
	part_type: Enums.PartType,
	rarity: Enums.Rarity,
	description: String,
	effect_id: String,
	puncture_mod: int = 0,
	damage_mod: float = 0.0,
	accuracy_mod: int = 0
) -> void:
	var part = WeaponPartData.new()
	part.part_type = part_type
	part.rarity = rarity
	part.effect_description = description
	part.effect_id = effect_id
	part.puncture_modifier = puncture_mod
	part.damage_modifier = damage_mod
	part.accuracy_modifier = accuracy_mod
	
	part_registry[weapon_type][part_type][rarity] = part


func roll_rarity() -> Enums.Rarity:
	var total_weight: float = 0.0
	for weight in RARITY_WEIGHTS.values():
		total_weight += weight
	
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	
	for rarity in RARITY_WEIGHTS.keys():
		cumulative += RARITY_WEIGHTS[rarity]
		if roll <= cumulative:
			return rarity
	
	return Enums.Rarity.WHITE

func get_part(weapon_type: Enums.WeaponType, part_type: Enums.PartType, rarity: Enums.Rarity) -> WeaponPartData:
	return part_registry[weapon_type][part_type][rarity]

func generate_weapon(weapon_type: Enums.WeaponType, weapon_level: int = 1) -> WeaponInstanceData:
	var weapon = WeaponInstanceData.new()
	
	weapon.base = weapon_bases[weapon_type]

	weapon.manufacturer = ManufacturerData.roll_manufacturer()
	weapon.weapon_name = ManufacturerData.get_weapon_name(weapon.manufacturer, weapon_type)

	for part_type in weapon.base.part_types:
		var rarity = roll_rarity()
		var part = get_part(weapon_type, part_type, rarity)
		if part:
			weapon.parts.append(part)

	_apply_manufacturer_stats(weapon)
	weapon.level = weapon_level
	weapon.calculate_stats()
	
	return weapon


func _apply_manufacturer_stats(weapon: WeaponInstanceData) -> void:
	var stat_range = ManufacturerData.get_stat_range(weapon.manufacturer)
	var num_ups = randi_range(stat_range[0], stat_range[1])
	var num_downs = randi_range(stat_range[2], stat_range[3])
	
	var stats = ["damage", "fire_rate", "puncture", "accuracy", "magazine", "crit_chance", "crit_damage", "reload_speed", "lifesteal"]
	
	var stat_ranges = {
		"damage": [15, 30],
		"fire_rate": [5, 30],
		"puncture": [5, 30],
		"accuracy": [-1.5, 1.5],
		"magazine": [15, 45],
		"crit_chance": [5, 25],
		"crit_damage": [35, 55],
		"reload_speed": [5, 75],
		"lifesteal": [1, 10]
	}

	for i in range(num_ups):
		var stat = stats[randi() % stats.size()]
		var value = randi_range(stat_ranges[stat][0], stat_ranges[stat][1])
		if not weapon.stat_modifiers.has(stat):
			weapon.stat_modifiers[stat] = 0
		weapon.stat_modifiers[stat] += value

	for i in range(num_downs):
		var stat = stats[randi() % stats.size()]
		var value = randi_range(stat_ranges[stat][0], stat_ranges[stat][1])
		if not weapon.stat_modifiers.has(stat):
			weapon.stat_modifiers[stat] = 0
		weapon.stat_modifiers[stat] -= value

	var min_values = {
		"damage": -60,
		"fire_rate": -50,
		"puncture": -10,
		"accuracy": -2,
		"magazine": -50,
		"crit_chance": -10,
		"crit_damage": -50,
		"reload_speed": -100,
		"lifesteal": -5
	}
	
	for stat in weapon.stat_modifiers.keys():
		if min_values.has(stat):
			weapon.stat_modifiers[stat] = max(weapon.stat_modifiers[stat], min_values[stat])
