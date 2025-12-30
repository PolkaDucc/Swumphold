class_name StatusEffect
extends RefCounted

enum Type { FIRE, FREEZE, CORRUPT, BLEED, SHOCK, INFECTED, DUUMITE }

var type: Type
var stacks: int = 1
var duration: float = 4.0
var source_damage: int = 0


func _init(effect_type: Type, weapon_damage: int = 0) -> void:
	type = effect_type
	source_damage = weapon_damage
	
	match type:
		Type.FIRE:
			duration = 4.0
		Type.FREEZE:
			duration = 3.0
		Type.CORRUPT:
			duration = 8.0
		Type.BLEED:
			duration = 4.0
		Type.SHOCK:
			duration = 4.0
		Type.INFECTED:
			duration = 4.0
		Type.DUUMITE:
			duration = 4.0


func add_stack() -> void:
	stacks += 1
	
	if type == Type.BLEED:
		duration += 2.0
