class_name ModifierEffects
extends RefCounted

static func get_display_name(modifier: Enums.EnemyModifier) -> String:
	match modifier:
		Enums.EnemyModifier.BEEG: return "Big Ol'"
		Enums.EnemyModifier.ANGY: return "Angy"
		Enums.EnemyModifier.LIL: return "Lil"
		Enums.EnemyModifier.SAD: return "Sad"
		Enums.EnemyModifier.RETIRED: return "Retired"
		Enums.EnemyModifier.MANIC: return "Manic"
		Enums.EnemyModifier.TANKY: return "Tanky Ahh"
		Enums.EnemyModifier.PSYCHOTIC: return "Psychotic"
		Enums.EnemyModifier.PREPARED: return "Prepared"
		Enums.EnemyModifier.CRYSTALLIC: return "Crystallic"
		Enums.EnemyModifier.HUNGRY: return "Hungry"
		Enums.EnemyModifier.VAMPIRIC: return "Vampiric"
		Enums.EnemyModifier.JUICED: return "Juiced"
		Enums.EnemyModifier.OLYMPIC: return "Olympic"
		Enums.EnemyModifier.INFLAMED: return "Inflamed"
		Enums.EnemyModifier.COLD: return "Cold"
		Enums.EnemyModifier.EVIL: return "Evil"
		Enums.EnemyModifier.HEMMORAGED: return "Hemmoraged"
		Enums.EnemyModifier.ELECTRIFIED: return "Electrified"
		Enums.EnemyModifier.ZOMBIFIED: return "Zombified"
		Enums.EnemyModifier.DUUM_RIDDEN: return "Duum-ridden"
		Enums.EnemyModifier.MONK: return "Monk"
		Enums.EnemyModifier.PARASITIC: return "Parasitic"
		Enums.EnemyModifier.KLEPTOMANIAC: return "Kleptomaniac"
		Enums.EnemyModifier.MILITANT: return "Militant"
		Enums.EnemyModifier.BLOATED: return "Bloated"
		Enums.EnemyModifier.CAPITALIST: return "Capitalist"
		Enums.EnemyModifier.STICKY: return "Stiiiicky"
		Enums.EnemyModifier.SPIKED: return "Spiked"
		Enums.EnemyModifier.ASEXUAL: return "Asexual"
	return "Unknown"


static func get_stat_mods(modifier: Enums.EnemyModifier) -> Dictionary:
	match modifier:
		Enums.EnemyModifier.BEEG:
			return {"health": 1.5, "damage": 1.0, "defense": 1.0, "speed": 1.0, "scale": 1.5}
		Enums.EnemyModifier.ANGY:
			return {"health": 1.0, "damage": 1.5, "defense": 1.0, "speed": 1.0, "scale": 1.0}
		Enums.EnemyModifier.LIL:
			return {"health": 0.5, "damage": 1.0, "defense": 1.0, "speed": 1.5, "scale": 0.5}
		Enums.EnemyModifier.SAD:
			return {"health": 1.25, "damage": 1.0, "defense": 1.25, "speed": 1.0, "scale": 1.0}
		Enums.EnemyModifier.RETIRED:
			return {"health": 1.0, "damage": 1.5, "defense": 1.0, "speed": 0.75, "scale": 1.0}
		Enums.EnemyModifier.MANIC:
			return {"health": 1.0, "damage": 1.5, "defense": 0.5, "speed": 1.5, "scale": 1.0}
		Enums.EnemyModifier.TANKY:
			return {"health": 2.0, "damage": 1.0, "defense": 1.0, "speed": 1.0, "scale": 1.0}
		Enums.EnemyModifier.PSYCHOTIC:
			return {"health": 1.0, "damage": 2.0, "defense": 1.0, "speed": 1.0, "scale": 1.0}
		Enums.EnemyModifier.PREPARED:
			return {"health": 1.0, "damage": 1.0, "defense": 3.0, "speed": 0.5, "scale": 1.0}
		Enums.EnemyModifier.JUICED:
			return {"health": 1.0, "damage": 1.0, "defense": 1.0, "speed": 1.0, "scale": 1.0}
		Enums.EnemyModifier.OLYMPIC:
			return {"health": 1.0, "damage": 1.0, "defense": 1.0, "speed": 2.0, "scale": 1.0}
		Enums.EnemyModifier.VAMPIRIC:
			return {"health": 1.0, "damage": 1.0, "defense": 1.0, "speed": 1.0, "scale": 1.0}
		Enums.EnemyModifier.CAPITALIST:
			return {"health": 2.0, "damage": 1.0, "defense": 2.0, "speed": 1.0, "scale": 1.0}
		_:
			return {"health": 1.0, "damage": 1.0, "defense": 1.0, "speed": 1.0, "scale": 1.0}
