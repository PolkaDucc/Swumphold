class_name WeaponPartData
extends Resource

@export var part_type: Enums.PartType
@export var rarity: Enums.Rarity
@export var manufacturer: String = ""
@export_multiline var effect_description: String = ""

@export var damage_modifier: float = 0.0
@export var fire_rate_modifier: float = 0.0
@export var accuracy_modifier: int = 0
@export var magazine_modifier: int = 0
@export var puncture_modifier: int = 0
@export var crit_chance_modifier: float = 0.0
@export var crit_damage_modifier: float = 0.0
@export var reload_speed_modifier: float = 0.0

@export var effect_id: String = ""
