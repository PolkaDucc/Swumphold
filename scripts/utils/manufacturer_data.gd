class_name ManufacturerData
extends RefCounted

const WEIGHTS = {
	Enums.Manufacturer.RABANDIT: 33.0,
	Enums.Manufacturer.FRUG: 26.9,
	Enums.Manufacturer.GATORGUY: 19.8,
	Enums.Manufacturer.QXTECH_WEAPONS: 10.6,
	Enums.Manufacturer.POWERS: 5.5,
	Enums.Manufacturer.QXTECH_RESEARCH: 3.2,
	Enums.Manufacturer.UEO: 1.0
}

const STAT_RANGES = {
	Enums.Manufacturer.RABANDIT: [0, 2, 1, 3],
	Enums.Manufacturer.FRUG: [1, 2, 1, 2],
	Enums.Manufacturer.GATORGUY: [1, 3, 0, 2],
	Enums.Manufacturer.QXTECH_WEAPONS: [2, 3, 0, 1],
	Enums.Manufacturer.POWERS: [2, 3, 0, 1],
	Enums.Manufacturer.QXTECH_RESEARCH: [3, 4, 3, 4],
	Enums.Manufacturer.UEO: [1, 7, 0, 0]
}

const PREFIXES = {
	Enums.Manufacturer.RABANDIT: ["Crappah", "Mid", "Killah"],
	Enums.Manufacturer.FRUG: ["Discounted", "Stock", "Freemium"],
	Enums.Manufacturer.GATORGUY: ["Dull", "Snippy", "Sharp"],
	Enums.Manufacturer.QXTECH_WEAPONS: ["War Torn", "Field Tested", "Factory New"],
	Enums.Manufacturer.POWERS: ["Ancient", "Historic", "Authentic"],
	Enums.Manufacturer.QXTECH_RESEARCH: ["Proof of Concept", "Prototype", "Prerelease"],
	Enums.Manufacturer.UEO: ["Damaged", "Salvaged", "Restored"]
}

const WEAPON_NAMES = {
	Enums.Manufacturer.RABANDIT: {
		Enums.WeaponType.PISTOL: "Shoota",
		Enums.WeaponType.SMG: "Quickah Gun",
		Enums.WeaponType.RIFLE: "Riful",
		Enums.WeaponType.SHOTGUN: "Blammah Gun",
		Enums.WeaponType.SNIPER: "Long Shootah",
		Enums.WeaponType.LMG: "Bigguh Gun",
		Enums.WeaponType.WAND: "Weirdah"
	},
	Enums.Manufacturer.FRUG: {
		Enums.WeaponType.PISTOL: "Handgun",
		Enums.WeaponType.SMG: "Quickgun",
		Enums.WeaponType.RIFLE: "Automatic Blaster",
		Enums.WeaponType.SHOTGUN: "Sluggun",
		Enums.WeaponType.SNIPER: "ScopeShot",
		Enums.WeaponType.LMG: "Shredder",
		Enums.WeaponType.WAND: "Exotigun"
	},
	Enums.Manufacturer.GATORGUY: {
		Enums.WeaponType.PISTOL: "Pistol",
		Enums.WeaponType.SMG: "SMG",
		Enums.WeaponType.RIFLE: "Rifle",
		Enums.WeaponType.SHOTGUN: "Shotgun",
		Enums.WeaponType.SNIPER: "Sniper",
		Enums.WeaponType.LMG: "LMG",
		Enums.WeaponType.WAND: "Oddity"
	},
	Enums.Manufacturer.QXTECH_WEAPONS: {
		Enums.WeaponType.PISTOL: "DefenderX",
		Enums.WeaponType.SMG: "DefenderX Lite",
		Enums.WeaponType.RIFLE: "QX45",
		Enums.WeaponType.SHOTGUN: "Beckholm 777",
		Enums.WeaponType.SNIPER: "SeerX",
		Enums.WeaponType.LMG: "QXT77",
		Enums.WeaponType.WAND: "CosmiX"
	},
	Enums.Manufacturer.POWERS: {
		Enums.WeaponType.PISTOL: "PFA Revolver 12982",
		Enums.WeaponType.SMG: "PFA 9MM",
		Enums.WeaponType.RIFLE: "PFA Rifle 12975",
		Enums.WeaponType.SHOTGUN: "PFA 12G",
		Enums.WeaponType.SNIPER: "PFA Bolt-Action 12934",
		Enums.WeaponType.LMG: "PFA 45MM",
		Enums.WeaponType.WAND: "PFA EXO"
	},
	Enums.Manufacturer.QXTECH_RESEARCH: {
		Enums.WeaponType.PISTOL: "QXTPSTL",
		Enums.WeaponType.SMG: "QXTSMG",
		Enums.WeaponType.RIFLE: "QXTRFL",
		Enums.WeaponType.SHOTGUN: "QXTSHTG",
		Enums.WeaponType.SNIPER: "QXTSNPR",
		Enums.WeaponType.LMG: "QXTLMG",
		Enums.WeaponType.WAND: "QXTWND"
	},
	Enums.Manufacturer.UEO: {
		Enums.WeaponType.PISTOL: "",
		Enums.WeaponType.SMG: "",
		Enums.WeaponType.RIFLE: "",
		Enums.WeaponType.SHOTGUN: "",
		Enums.WeaponType.SNIPER: "",
		Enums.WeaponType.LMG: "",
		Enums.WeaponType.WAND: ""
	}
}

const UEO_SYMBOLS = ["7", "❦", "♼", "⛣", "❡", "☬", "⚶", "✧", "⛤", "☍"]


static func roll_manufacturer() -> Enums.Manufacturer:
	var total_weight = 0.0
	for weight in WEIGHTS.values():
		total_weight += weight
	
	var roll = randf() * total_weight
	var cumulative = 0.0
	
	for manufacturer in WEIGHTS:
		cumulative += WEIGHTS[manufacturer]
		if roll <= cumulative:
			return manufacturer
	
	return Enums.Manufacturer.RABANDIT


static func get_weapon_name(manufacturer: Enums.Manufacturer, weapon_type: Enums.WeaponType) -> String:
	if manufacturer == Enums.Manufacturer.UEO:
		return _generate_ueo_name()
	return WEAPON_NAMES[manufacturer][weapon_type]


static func _generate_ueo_name() -> String:
	var name = ""
	var length = randi_range(4, 7)
	for i in range(length):
		name += UEO_SYMBOLS[randi() % UEO_SYMBOLS.size()]
	return name


static func get_prefix(manufacturer: Enums.Manufacturer, quality: float) -> String:
	var prefixes = PREFIXES[manufacturer]
	if quality < 0.33:
		return prefixes[0]
	elif quality < 0.66:
		return prefixes[1]
	else:
		return prefixes[2]


static func get_stat_range(manufacturer: Enums.Manufacturer) -> Array:
	return STAT_RANGES[manufacturer]
